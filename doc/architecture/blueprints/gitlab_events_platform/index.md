---
status: proposed
creation-date: "2023-03-06"
authors: [ "@grzesiek", "@fabiopitino" ]
coach: "@ayufan"
approvers: [ "@jreporter", "@sgoldstein" ]
owning-stage: "~devops::ops section"
---

# GitLab Events Platform

## Summary

GitLab codebase has grown a lot since the [first commit](https://gitlab.com/gitlab-org/gitlab/-/commit/93efff945215)
made in 2011. We've been able to implement many features that got adopted by
millions of users. There is a demand for more features, but there is also an
opportunity of a paradigm change: instead of delivering features that cover
specific use-cases, we can start building a platform that our users will be
able to extend with automation as they see fit. We can build a flexible and
generic DevSecOps solution that will integrate with external and internal
workflows using a robust eventing system.

In this design document we propose to add a few additional layers of
abstraction to make it possible to:

1. Design a notion of events hierarchy that encodes their origin and schema.
1. Publish events from within the application code using Publishers.
1. Intercept and transform events from external sources using Gateways.
1. Subscribe to internal / external events using Subscribers.
1. Hide queueing and processing implementation details behind an abstraction.

This will allow us to transform GitLab into a generic automation tooling, but
will also reduce the complexity of existing events-like features:

1. [Webhooks](../../../user/project/integrations/webhook_events.md)
1. [Audit Events](../../../administration/audit_event_reports.md)
1. [GitLab CI Events](https://about.gitlab.com/blog/2022/08/03/gitlab-ci-event-workflows/)
1. [Package Events](https://gitlab.com/groups/gitlab-org/-/epics/9677)
1. [GraphQL Events](https://gitlab.com/gitlab-org/gitlab/-/blob/dabf4783f5d758f69d947f5ff2391b4b1fb5f18a/app/graphql/graphql_triggers.rb)

## Goals

Build required abstractions and their implementation needed to better manage
internally and externally published events.

## Challenges

1. There is no solution allowing users to build subscribers and publishers.
1. There is no solution for managing subscriptions outside of the Ruby code.
1. There are many events-like features inside GitLab not using common abstractions.
1. Our current eventing solution `Gitlab::EventStore` is tightly coupled with Sidekiq.
1. There is no unified and resilient way to subscribe to externally published events.
1. Payloads associated with events differ a lot, similarly to how we define schemas.
1. Not all events are strongly typed, there is no solution to manage their hierarchy.
1. Events are not being versioned, it is easy to break schema contracts.
1. We want to build more features based on events, but because of missing
   abstractions the value we could get from the implementations is limited.

## Proposal

### Publishers

Publishing events from within our Rails codebase is an important piece of the
proposed architecture. Events should be strongly typed, ideally using Ruby classes.

For example, we could emit events in the following way:

```ruby
include Gitlab::Events::Emittable

emit Gitlab::Events::Package::Published.new(package)
```

- Publishing events should be a non-blocking, and near zero-cost operation.
- Publishing events should take their origin and identity into the account.
- Publishing events should build their payload based on their lineage.
- `emit` can be a syntactic sugar over mechanism used in `GitLab::EventStore`.

### Subscribers

Subscribers will allow application developers to subscribe to arbitrary events,
published internally or externally. Subscribers could also allow application
developers to build subscription mechanisms that could be used by our users to,
for example, subscribe to project events to trigger pipelines.

Events that subscribers will subscribe to will becomes contracts, hence we
should version them or use backwards-and-forward compatible solution (like
Protobuf).

### Gateways

Gateways can be used to intercept internal and external events and change their
type, augment lineage and transform their payloads.

Gateways can be used, for example, to implement sink endpoints to intercept
Cloud Events, wrap into an internally used Ruby classes and allow developers /
users to subscribe to them.

We also may be able to implement [cross-Cell](../cells) communication through a
generic events bus implemented using Gateways.

There are also ideas around cross-instance communication to improve how GitLab
can coordinate complex deployments that involve multiple instances.

### Processing

Today in order to queue events, we either use PostgreSQL or Sidekiq. Both
mechanisms are being used interchangeably and are tightly coupled with existing
solution.

The main purpose of building an abstraction for queuing and processing is to be
able to switch to a different queuing backend when needed. For example, we
could queue some of the events on Google Pub/Sub, and send those through a
dedicated Gateway on their way back to the application.

### Observability

In order to understand interactions between events, publishers and subscribers
we may need to deliver a proper instrumentation _via_ OpenTelemetry. This will
allow us to visualize these interactions with Distributed Tracing Backends.
