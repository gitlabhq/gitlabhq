---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Real-Time Features

This guide contains instructions on how to safely roll out new real-time
features.

Real-time features are implemented using GraphQL Subscriptions.
[Developer documentation](api_graphql_styleguide.md#subscriptions) is available.

WebSockets are a relatively new technology at GitLab, and supporting them at
scale introduces some challenges. For that reason, new features should be rolled
out using the instructions below.

## Reuse an existing WebSocket connection

Features reusing an existing connection incur minimal risk. Feature flag rollout
is recommended in order to give more control to self-hosting customers. However,
it is not necessary to roll out in percentages, or to estimate new connections for
GitLab.com.

## Introduce a new WebSocket connection

Any change that introduces a WebSocket connection to part of the GitLab application
incurs some scalability risk, both to nodes responsible for maintaining open
connections and on downstream services; such as Redis and the primary database.

### Estimate peak connections

The first real-time feature to be fully enabled on GitLab.com was
[real-time assignees](https://gitlab.com/gitlab-org/gitlab/-/issues/17589). By comparing
peak throughput to the issue page against peak simultaneous WebSocket connections it is
possible to crudely estimate that each 1 request per second adds
approximately 4200 WebSocket connections.

To understand the impact a new feature might have, sum the peak throughput (RPS)
to the pages it originates from (`n`) and apply the formula:

```ruby
(n * 4200) / peak_active_connections
```

Current active connections are visible on
[this Grafana chart](https://dashboards.gitlab.net/d/websockets-main/websockets-overview?viewPanel=1357460996&orgId=1).

This calculation is crude, and should be revised as new features are
deployed. It yields a rough estimate of the capacity that must be
supported, as a proportion of existing capacity.

### Graduated roll-out

New capacity may need to be provisioned to support your changes, depending on
current saturation and the proportion of new connections required. While
Kubernetes makes this relatively easy in most cases, there remains a risk to
downstream services.

To mitigate this, ensure that the code establishing the new WebSocket connection
is feature flagged and defaulted to `off`. A careful, percentage-based roll-out
of the feature flag ensures that effects can be observed on the [WebSocket
dashboard](https://dashboards.gitlab.net/d/websockets-main/websockets-overview?orgId=1)

1. Create a
   [feature flag roll-out](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md)
   issue.
1. Add the estimated new connections required under the **What are we expecting to happen** section.
1. Copy in a member of the Plan and Scalability teams to estimate a percentage-based
   roll-out plan.

## Backward compatibility

For the duration of the feature flag roll-out and indefinitely thereafter,
real-time features must be backward-compatible, or at least degrade
gracefully. Not all customers have Action Cable enabled, and further work
needs to be done before Action Cable can be enabled by default.

Making real-time a requirement represents a breaking change, so the next
opportunity to do this is version 15.0.

## Enable Real-Time by default

Mounting the Action Cable library adds minimal memory footprint. However,
serving WebSocket requests introduces additional memory requirements. For this
reason, enabling Action Cable by default requires additional work; perhaps
to reduce overall memory usage, including a known issue with Workhorse, but at
least to revise Reference Architectures.

## Real-time infrastructure on GitLab.com

On GitLab.com, WebSocket connections are served from dedicated infrastructure,
entirely separate from the regular Web fleet and deployed with Kubernetes. This
limits risk to nodes handling requests but not to shared services. For more
information on the WebSockets Kubernetes deployment see
[this epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/355).
