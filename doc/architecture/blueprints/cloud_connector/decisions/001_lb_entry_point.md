---
owning-stage: "~devops::data stores"
description: 'Cloud Connector ADR 001: Use load balancer as single entry point'
---

# Cloud Connector ADR 001: Load balancer as single entry point

## Context

The original iteration of the blueprint suggested to stand up a dedicated Cloud Connector edge service,
through which all traffic that uses features under the Cloud Connector umbrella would pass.

The primary reasons for why we wanted this to be a dedicated service were to:

1. **Provide a single entry point for customers.** We identified the ability for any GitLab instance
   around the world to consume Cloud Connector features through a single endpoint such as
   `cloud.gitlab.com` as a must-have property.
1. **Have the ability to execute custom logic.** There was a desire from product to create a space where we can
   run cross-cutting business logic such as application-level rate limiting, which is hard or impossible to
   do using a traditional load balancer such as HAProxy.

## Decision

We decided to take a smaller incremental step toward having a "smart router" by focusing on
the ability to provide a single endpoint through which Cloud Connector traffic enters our
infrastructure. This can be accomplished using simpler means than deploying dedicated services, specifically
by pulling in a load balancing layer listening at `cloud.gitlab.com` that can also perform simple routing
tasks to forward traffic into feature backends.

Our reasons for this decision were:

1. **Unclear requirements for custom logic to run.** We are still exploring how and to what extent we would
   apply rate limiting logic at the Cloud Connector level. This is being explored in
   [issue 429592](https://gitlab.com/gitlab-org/gitlab/-/issues/429592). Because we need to have a single
   entry point by January, and because we think we will not be ready by then to implement such logic at the
   Cloud Connector level, a web service is not required yet.
1. **New use cases found that are not suitable to run through a dedicated service.** We started to work with
   the Observability group to see how we can bring the GitLab Observability Backend (GOB) to Cloud Connector
   customers in [MR 131577](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131577).
   In this discussion it became clear that due to the large amounts of traffic and data volume passing
   through GOB each day, putting another service in front of this stack does not provide a sensible
   risk/benefit trade-off. Instead, we will probably split traffic and make Cloud Connector components
   available through other means for special cases like these (for example, through a Cloud Connector library).

We are exploring several options for load-balancing this new endpoint in [issue 429818](https://gitlab.com/gitlab-org/gitlab/-/issues/429818)
and are working with the `Infrastructure:Foundations` team to deploy this in [issue 24711](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/24711).

## Consequences

We have not yet discarded the plan to build a smart router eventually, either as a service or
through other means, but have delayed this decision in face of uncertainty at both a product
and technical level. We will reassess how to proceed in Q1 2024.
