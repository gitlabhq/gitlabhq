---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AI gateway
---

The AI gateway is a standalone service that gives access to AI-native GitLab Duo features.

GitLab operates an instance of the AI gateway, based in the cloud.
This instance is used by GitLab.com, [GitLab Self-Managed](setup.md), and GitLab Dedicated.

You can also use a self-hosted AI gateway instance on GitLab Self-Managed
through [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md).

## Region support

### GitLab.com

For GitLab.com, the routing mechanism is based on the GitLab instance
location instead of the user's instance location.

Because GitLab.com is single-homed in `us-east1`, requests to the AI gateway
are routed to `us-east4` in almost all cases.
The routing might not always result in the absolute nearest deployment for every user.

### GitLab Self-Managed and GitLab Dedicated

For GitLab Self-Managed and GitLab Dedicated, GitLab manages region selection.
For more information, see [available regions](https://schemas.runway.gitlab.com/RunwayService/#spec_regions)
in the [Runway](https://gitlab.com/gitlab-com/gl-infra/platform/runway) service manifest.

Runway is the GitLab internal developer platform and is not available to external customers.

## Automatic data routing

GitLab uses Cloudflare and Google Cloud Platform (GCP) load balancers to route AI
gateway requests to the nearest available deployment automatically.
This routing mechanism prioritizes low latency and efficient processing of user requests.

You cannot manually control this routing process.
The following factors influence where data is routed:

- Network latency: The primary routing mechanism focuses on minimizing latency.
  Data might be processed in a region other than the nearest one if network conditions dictate.
- Service availability: In case of regional outages or service disruptions,
  requests might be automatically rerouted to ensure uninterrupted service.
- Third-party dependencies: The GitLab AI infrastructure relies on third-party model providers,
  like Google Vertex AI, which have their own data-handling practices.

### Direct and indirect connections

The IDE communicates directly with the AI gateway by default, bypassing the GitLab monolith.
This direct connection improves routing efficiency.

To change this behavior, [configure direct and indirect connections](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections).

### Tracing requests to specific regions

You cannot directly trace your AI requests to specific regions.

If you need assistance with tracing a particular request, GitLab Support can access and
analyze logs that contain Cloudflare headers and instance UUIDs.
These logs provide insights into the routing path and can help
identify the region where a request was processed.

## Data sovereignty

The multi-region AI gateway deployment does not enforce strict data sovereignty.
Requests are not guaranteed to go to or remain in a particular region.

This service is not a data residency solution.

### Deployment regions

GitLab deploys the AI gateway in the following regions:

- North America (`us-east4`)
- Europe (`europe-west2`, `europe-west3`, and `europe-west9`)
- Asia Pacific (`asia-northeast1` and `asia-northeast3`)

For the most current information, see the
[Runway configuration file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/runway.yml?ref_type=heads#L12).

The exact location of the LLM models used by the AI gateway is determined by third-party model providers.
The models are not guaranteed to reside in the same geographical regions as the AI gateway deployments.
Data might flow to other regions where the model provider operates,
even if the AI gateway processes the initial request in a different region.
Data is routed to the most optimal region based on performance and availability.
