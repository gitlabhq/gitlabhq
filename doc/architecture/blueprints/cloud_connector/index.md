---
status: ongoing
creation-date: "2023-09-28"
authors: [ "@mkaeppler" ]
coach: "@ayufan"
approvers: [ "@rogerwoo", "@pjphillips" ]
owning-stage: "~devops::data stores"
participating-stages: ["~devops::fulfillment", "~devops::ai-powered"]
---

# Cloud Connector architecture evolution

## Summary

This design doc covers architectural decisions and proposed changes to
[Cloud Connector's technical foundations](https://gitlab.com/groups/gitlab-org/-/epics/11417).
Refer to the [official architecture documentation](../../../development/cloud_connector/architecture.md)
for an accurate description of the current status.

## Motivation

Our "big problem to solve" is to bring feature parity to our SaaS and self-managed offerings.
Until now, SaaS and self-managed (SM) GitLab instances consume features only from the [AI gateway](../ai_gateway/index.md),
which also implements an `Access Layer` to verify that a given request is allowed
to access the respective AI feature endpoint.

This approach has served us well because it:

- Required minimal changes from an architectural standpoint to allow SM users to consume AI features hosted by us.
- Caused minimal friction with ongoing development on GitLab.com.
- Reduced time to market.

However, the AI gateway alone does not sufficiently abstract over a wider variety of features,
as by definition it is designed to serve AI features only.

### Goals

We will use this blueprint to make incremental changes to Cloud Connector's technical framework
to enable other backend services to service self-managed/GitLab Dedicated customers in the same way
the AI gateway does today. This will directly support our mission of bringing feature parity
to all GitLab customers.

The major areas we are focused on are:

- [**Provide single access point for customers.**](https://gitlab.com/groups/gitlab-org/-/epics/12405)
  We found that customers are not keen on configuring their web proxies and firewalls
  to allow outbound traffic to an ever growing list of GitLab-hosted services. We therefore decided to
  install a global, load-balanced entry point at `cloud.gitlab.com`. This entry point can make simple
  routing decisions based on the requested path, which allows us to target different backend services
  as we broaden the feature scope covered by Cloud Connector.
  - **Status:** done. The decision was documented as [ADR001](decisions/001_lb_entry_point.md).
- [**Give instance admins control over product usage data.**](https://gitlab.com/groups/gitlab-org/-/epics/12020)
  Telemetry for Cloud Connector services are either instrumented within
  Editor Extensions or the AI gateway. Our approach to AI telemetry is currently independent of our long-term vision of
  [Unified Internal events tracking](https://gitlab.com/groups/gitlab-org/-/epics/9610).
  As Cloud Connector implements additional use cases beyond AI, we want to bring AI-related telemetry into alignment with existing
  technical choices.
  - **Status:** in discovery.
- [**Rate-limiting features.**](https://gitlab.com/groups/gitlab-org/-/epics/12032)
  During periods of elevated traffic, backends integrated with Cloud Connector such as
  AI gateway or TanuKey may experience resource constraints. GitLab should apply a consistent strategy when deciding which instance
  should be prioritized over others. This strategy should be uniform across all Cloud Connector services.
  - **Status:** planned.

## Decisions

- [ADR-001: Use load balancer as single entry point](decisions/001_lb_entry_point.md)
