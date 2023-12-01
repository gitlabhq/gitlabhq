---
stage: core platform
group: Tenant Scale
description: 'Cells: Routing Service'
---

# Cells: Routing Service

This document describes design goals and architecture of Routing Service
used by Cells. To better understand where the Routing Service fits
into architecture take a look at [Deployment Architecture](deployment-architecture.md).

## Goals

The routing layer is meant to offer a consistent user experience where all Cells are presented under a single domain (for example, `gitlab.com`), instead of having to navigate to separate domains.

The user will be able to use `https://gitlab.com` to access Cell-enabled GitLab.
Depending on the URL access, it will be transparently proxied to the correct Cell that can serve this particular information.
For example:

- All requests going to `https://gitlab.com/users/sign_in` are randomly distributed to all Cells.
- All requests going to `https://gitlab.com/gitlab-org/gitlab/-/tree/master` are always directed to Cell 5, for example.
- All requests going to `https://gitlab.com/my-username/my-project` are always directed to Cell 1.

1. **Technology.**

    We decide what technology the routing service is written in.
    The choice is dependent on the best performing language, and the expected way and place of deployment of the routing layer.
    If it is required to make the service multi-cloud it might be required to deploy it to the CDN provider.
    Then the service needs to be written using a technology compatible with the CDN provider.

1. **Cell discovery.**

    The routing service needs to be able to discover and monitor the health of all Cells.

1. **User can use single domain to interact with many Cells.**

    The routing service will intelligently route all requests to Cells based on the resource being
    accessed versus the Cell containing the data.

1. **Router endpoints classification.**

    The stateless routing service will fetch and cache information about endpoints from one of the Cells.
    We need to implement a protocol that will allow us to accurately describe the incoming request (its fingerprint), so it can be classified by one of the Cells, and the results of that can be cached.
    We also need to implement a mechanism for negative cache and cache eviction.

1. **GraphQL and other ambiguous endpoints.**

    Most endpoints have a unique sharding key: the Organization, which directly or indirectly (via a Group or Project) can be used to classify endpoints.
    Some endpoints are ambiguous in their usage (they don't encode the sharding key), or the sharding key is stored deep in the payload.
    In these cases, we need to decide how to handle endpoints like `/api/graphql`.

1. **Small.**

    The Routing Service is configuration-driven and rules-driven, and does not implement any business logic.
    The maximum size of the project source code in initial phase is 1_000 lines without tests.
    The reason for the hard limit is to make the Routing Service to not have any special logic,
    and could be rewritten into any technology in a matter of a few days.

## Requirements

| Requirement   | Description                                                       | Priority |
|---------------|-------------------------------------------------------------------|----------|
| Discovery     | needs to be able to discover and monitor the health of all Cells. | high     |
| Security      | only authorized cells can be routed to                            | high     |
| Single domain | e.g. GitLab.com                                                   | high     |
| Caching       | can cache routing information for performance                     | high     |
| Low latency   | small overhead for user requests                                  | high     |
| Path-based    | can make routing decision based on path                           | high     |
| Complexity    | the routing service should be configuration-driven and small      | high     |
| Stateless     | does not need database, Cells provide all routing information     | medium   |
| Secrets-based | can make routing decision based on secret (e.g. JWT)              | medium   |
| Observability | can use existing observability tooling                            | low      |
| Self-managed  | can be eventually used by [self-managed](goals.md#self-managed)   | low      |
| Regional      | can route requests to different [regions](goals.md#regions)       | low       |

## Non-Goals

Not yet defined.

## Proposal

TBD

## Technology

TBD

## Alternatives

TBD

## Links

- [Cells - Routing: Technology](https://gitlab.com/groups/gitlab-org/-/epics/11002)
- [Classify endpoints](https://gitlab.com/gitlab-org/gitlab/-/issues/430330)
