---
owning-stage: "~devops::create"
description: 'AI Gateway ADR 001: Allow direct connections'
---

# AI Gateway ADR 001: Allow direct connections

NOTE:
This decision is scoped to code completion requests. Code completion requests are a type of [code suggestion request](../../../../user/project/repository/code_suggestions/index.md).

## Summary

Code completion requests will be sent directly from client to AI Gateway, while code generation requests will still be sent indirectly through GitLab Rails.

## Context

The original iteration of the blueprint suggested to route all code suggestion requests to AI Gateway indirectly through GitLab Rails.
There were multiple reasons for this:

- the decision if a code suggestion request is a completion or generation request was done on GitLab Rails side
- Simpler authentication of requests could be used. For example, we could use instance JWT tokens to authenticate requests from self-managed instances.

In [epic 12224](https://gitlab.com/groups/gitlab-org/-/epics/12224), we discussed various
options to decrease request latency which would decrease also overall response
time.

## Decision

In the epic we decided to use different request flows for code completion and code generation requests. The reason is that both request types are slightly different:

- Code completion requests are much more sensitive to latency and from the request [timing breakdown](https://gitlab.com/groups/gitlab-org/-/epics/12224#latency-breakdown-by-components), more than 50% of time is spent connecting to the AI provider.
- Code generation requests are not so sensitive to latency. Most of the request time is spent on AI provider side and latency optimization would have marginal effect in the overall response time. Also we enrich these requests with additional data in GitLab Rails so it's still important to route these requests through GitLab Rails.

For code completion requests we decided that these requests can be sent by clients directly to AI Gateway. This will decrease latency by 150ms. We will benefit from this also when AI Gateway supports [multi-region deployments](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1206) because then code completion requests can be handled inside the same region. GitLab Rails does not support multi-region deployment, so with having completion requests routed through GitLab Rails we cannot eliminate long-distance connection hops which increases latency as well.

Usage of direct connection will be optional optimization. If a client does not recognize that a request is of type "completion", then it can still send the request through GitLab Rails as is now.

We considered also using the websocket protocol, but for now we will keep using HTTP. The plan is to use short-term JWTs to authenticate direct connections. This should be a fast operation (we use this already for requests sent indirectly) and it duplicates the major advantage of websocket. With websocket, we can authenticate users only once when opening the connection. So although with websocket, the connection might be faster by a few milliseconds, it does not outweighs downsides. This means mainly much more work both on AI Gateway and client side to switch to a different protocol. Also websocket is a stateful protocol which would complicate AI Gateway multi-region support.

Latency will improve even further for non-US GitLab users when multi-region deployment of AI-gateway is supported. We then avoid long-distance connection hop client<->GitLab Rails.

## Consequences

- No pre-processing for code completions requests by GitLab Rails. We currently do not do any special pre-processing of code completion requests on GitLab Rails side. If we want to do it in future, a possible approach would be to pre-fetch GitLab-specific data and do this enrichment on the client side as outlined in [this comment](https://gitlab.com/groups/gitlab-org/-/epics/12224#note_1744581116).
- Cloud Connector needs to be able to authenticate these direct connections. We will use short-term JWTs issued for end users. As decided in [issue 168](https://gitlab.com/gitlab-org/cloud-connector-team/team-tasks/-/issues/168) that AI Gateway will issue these short-term tokens.
- To fully leverage this optimization, we will need to support request type recognition (completion vs generation) on the client side. This is already supported for some clients and languages, but ideally we should support it for most of frequently used editors and programming languages.
- Client initialization process needs to be updated. Clients will receive short-term token with other direct connection details from GitLab Rails instance. For more information, see [issue 66](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/66)
- AI Gateway should support monitoring and rate-limiting which is now handled by GitLab Rails.
