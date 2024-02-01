---
owning-stage: "~devops::data stores"
description: 'Cells ADR 001: Routing Technology using Cloudflare Workers'
---

# Cells ADR 001: Routing Technology using Cloudflare Workers

## Context

In <https://gitlab.com/groups/gitlab-org/-/epics/11002> we first brainstormed [multiple options](https://gitlab.com/gitlab-org/gitlab/-/issues/428195#note_1664622245) and investigated our 2 top technologies,
[Cloudflare Worker](https://gitlab.com/gitlab-org/gitlab/-/issues/433471) & [Istio](https://gitlab.com/gitlab-org/gitlab/-/issues/433472).

We favored the Cloudflare Worker PoC and extended the PoC with the [Cell 1.0 proposal](https://gitlab.com/gitlab-org/gitlab/-/issues/437818) to have multiple routing rules.
These PoCs help validate the [routing service blueprint](../routing-service.md),
that got accepted in <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142397>,
and rejected the [request buffering](../rejected/proposal-stateless-router-with-buffering-requests.md),
and [routes learning](../rejected/proposal-stateless-router-with-routes-learning.md)

## Decision

Use [Cloudflare Workers](https://workers.cloudflare.com/) written in JavaScript/TypeScript to route the request to the right cell, following the accepted [routing service blueprint](../routing-service.md).

Cloudflare Workers meets all our [requirments](../routing-service.md#requirements) apart from the `self-managed`, which is a low priority requirment.

You can read a detailed analysis of Cloudflare workers in <https://gitlab.com/gitlab-org/gitlab/-/issues/433471#results>

## Consequences

- We will be choosing a technology stack knowing that it will not support all self-managed customers.
- More vendor locking with Cloudflare, but are already heavily dependent on them.
- Run compute in a new platform, outside of GCP, however we already use Cloudflare.
- We anticipate that we might to rewrite Routing Service if the decision changes.
  We don't expect this to be big risk, since we expect Routing Service to be very small and simple (up to 1000 lines of code).

## Alternatives

- We considered [Istio](https://gitlab.com/gitlab-org/gitlab/-/issues/433472) but concluded that it's not the right fit.
- We considered [Request Buffering](../rejected/proposal-stateless-router-with-buffering-requests.md)
- We considered [Routes Learning](../rejected/proposal-stateless-router-with-routes-learning.md)
- Use WASM for Cloudflare workers which is the wrong choice: <https://blog.cloudflare.com/webassembly-on-cloudflare-workers#whentousewebassembly>
