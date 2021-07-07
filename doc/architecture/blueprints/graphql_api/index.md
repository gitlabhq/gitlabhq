---
stage: none
group: unassigned
comments: false
description: 'GraphQL API architecture foundation'
---

# GraphQL API

[GraphQL](https://graphql.org/) is a data query and manipulation language for
APIs, and a runtime for fulfilling queries with existing data.

At GitLab we want to adopt GraphQL to make it easier for the wider community to
interact with GitLab in a reliable way, but also to advance our own product by
modeling communication between backend and frontend components using GraphQL.

We've recently increased the pace of the adoption by defining quarterly OKRs
related to GraphQL migration. This resulted in us spending more time on the
GraphQL development and helped to surface the need of improving tooling we use
to extend the new API.

This document describes the work that is needed to build a stable foundation that
will support our development efforts and a large-scale usage of the [GraphQL
API](https://docs.gitlab.com/ee/api/graphql/index.html).

## Summary

The GraphQL initiative at GitLab [started around three years ago](https://gitlab.com/gitlab-org/gitlab/-/commit/9c6c17cbcdb8bf8185fc1b873dcfd08f723e4df5).
Most of the work around the GraphQL ecosystem has been done by volunteers that are
[GraphQL experts](https://gitlab.com/groups/gitlab-org/graphql-experts/-/group_members?with_inherited_permissions=exclude).

The [retrospective on our progress](https://gitlab.com/gitlab-org/gitlab/-/issues/235659)
surfaced a few opportunities to streamline our GraphQL development efforts and
to reduce the risk of performance degradations and possible outages that may
be related to the gaps in the essential mechanisms needed to make the GraphQL
API observable and operable at scale.

Amongst small improvements to the GraphQL engine itself we want to build a
comprehensive monitoring dashboard, that will enable team members to make sense
of what is happening inside our GraphQL API. We want to make it possible to define
SLOs, triage breached SLIs and to be able to zoom into relevant details using
Grafana and Elastic. We want to see historical data and predict future usage.

It is an opportunity to learn from our experience in evolving the REST API, for
the scale, and to apply this knowledge onto the GraphQL development efforts. We
can do that by building query-to-feature correlation mechanisms, adding
scalable state synchronization support and aligning GraphQL with other
architectural initiatives being executed in parallel, like [the support for
direct uploads](https://gitlab.com/gitlab-org/gitlab/-/issues/280819).

GraphQL should be secure by default. We can avoid common security mistakes by
building mechanisms that will help us to enforce [OWASP GraphQL
recommendations](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
that are relevant to us.

Understanding what are the needs of the wider community will also allow us to
plan deprecation policies better and to design parity between GraphQL and REST
API that suits their needs.

## Challenges

### Make sense of what is happening in GraphQL

Being able to see how GraphQL performs in a production environment is a
prerequisite for improving performance and reliability of that service.

We do not yet have tools that would make it possible for us to answer a
question of how GraphQL performs and what the bottlenecks we should optimize
are. This, combined with a pace of GraphQL adoption and the scale in which we
expect it operate, imposes a risk of an increased rate of production incidents
what will be difficult to resolve.

We want to build a comprehensive Grafana dashboard that will focus on
delivering insights of how GraphQL endpoint performs, while still empowering
team members with capability of zooming in into details. We want to improve
logging to make it possible to better correlate GraphQL queries with feature
using Elastic and to index them in a way that performance problems can be
detected early.

- Build a comprehensive Grafana dashboard for GraphQL
- Build a GraphQL query-to-feature correlation mechanisms
- Improve logging GraphQL queries in Elastic
- Redesign error handling on frontend to surface warnings

### Manage volatile GraphQL data structures

Our GraphQL API will evolve with time. GraphQL has been designed to make such
evolution easier. GraphQL APIs are easier to extend because of how composable
GraphQL is. On the other hand this is also a reason why versioning of GraphQL
APIs is considered unnecessary. Instead of versioning the API we want to mark
some fields as deprecated, but we need to have a way to understand what is the
usage of deprecated fields, types and a way to visualize it in a way that is
easy to understand. We might want to detect usage of deprecated fields and
notify users that we plan to remove them.

- Define a data-informed deprecation policy that will serve our users better
- Build a dashboard showing usage frequency of deprecated GraphQL fields
- Build mechanisms required to send deprecated fields usage in Service Ping

### Ensure consistency with the rest of the codebase

GraphQL is not the only thing we work on, but it cuts across the entire
application. It is being used to expose data collected and processed in almost
every part of our product. It makes it tightly coupled with our monolithic
codebase.

We need to ensure that how we use GraphQL is consistent with other mechanisms
we've designed to improve performance and reliability of GitLab.

We have extensive experience with evolving our REST API. We want to apply
this knowledge onto GraphQL and make it performant and secure by default.

- Design direct uploads for GraphQL
- Build GraphQL query depth and complexity histograms
- Visualize the amount of GraphQL queries reaching limits
- Add support for GraphQL ETags for existing features

### Design GraphQL interoperability with REST API

We do not plan to deprecate our REST API. It is a simple way to interact with
GitLab, and GraphQL might never become a full replacement of a traditional REST
API. The two APIs will need to coexist together. We will need to remove
duplication between them to make their codebases maintainable. This symbiosis,
however, is not only a technical challenge we need to resolve on the backend.
Users might want to use the two APIs interchangeably or even at the same time.
Making it interoperable by exposing a common scheme for resource identifiers is
a prerequisite for interoperability.

- Make GraphQL and REST API interoperable
- Design common resource identifiers for both APIs

### Design scalable state synchronization mechanisms

One of the most important goals related to GraphQL adoption at GitLab is using
it to model interactions between GitLab backend and frontend components. This
is an ongoing process that has already surfaced the need of building better
state synchronization mechanisms and hooking into existing ones.

- Design a scalable state synchronization mechanism
- Evaluate state synchronization through pub/sub and websockets
- Build a generic support for GraphQL feature correlation and feature ETags
- Redesign frontend code responsible for managing shared global state

## Iterations

### In the scope of the blueprint

1. [GraphQL API architecture](https://gitlab.com/groups/gitlab-org/-/epics/5842)
    1. [Build comprehensive Grafana dashboard for GraphQL](https://gitlab.com/groups/gitlab-org/-/epics/5841)
    1. [Improve logging of GraphQL requests in Elastic](https://gitlab.com/groups/gitlab-org/-/epics/4646)
    1. [Build GraphQL query correlation mechanisms](https://gitlab.com/groups/gitlab-org/-/epics/5320)
    1. [Design a better data-informed deprecation policy](https://gitlab.com/groups/gitlab-org/-/epics/5321)

### Future iterations

1. [Build a scalable state synchronization for GraphQL](https://gitlab.com/groups/gitlab-org/-/epics/5319)
1. [Add support for direct uploads for GraphQL](https://gitlab.com/gitlab-org/gitlab/-/issues/280819)
1. [Review GraphQL design choices related to security](https://gitlab.com/gitlab-org/security/gitlab/-/issues/339)

## Status

Current status: in progress.

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Grzegorz Bizon          |
| Architecture Evolution Coach | Kamil Trzciński         |
| Engineering Leader           | Darva Satcher           |
| Product Manager              | Patrick Deuley          |
| Domain Expert / GraphQL      | Charlie Ablett          |
| Domain Expert / GraphQL      | Alex Kalderimis         |
| Domain Expert / GraphQL      | Natalia Tepluhina       |
| Domain Expert / Scalability  | Bob Van Landuyt         |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Leadership                   | Darva Satcher          |
| Product                      | Patrick Deuley         |
| Engineering                  | Paul Slaughter         |

Domain Experts:

| Area                         | Who
|------------------------------|------------------------|
| Domain Expert / GraphQL      | Charlie Ablett         |
| Domain Expert / GraphQL      | Alex Kalderimis        |
| Domain Expert / GraphQL      | Natalia Tepluhina      |
| Domain Expert / Scalability  | Bob Van Landuyt        |

<!-- vale gitlab.Spelling = YES -->
