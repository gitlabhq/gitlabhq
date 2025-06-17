---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AI gateway
---

The AI gateway is a standalone service that gives access to AI-native GitLab Duo features.

GitLab operates an instance of AI gateway that is used by GitLab Self-Managed, GitLab Dedicated, and GitLab.com through the Cloud Connector.

On GitLab Self-Managed, this GitLab instance of AI gateway applies regardless of whether you are using the
cloud-based AI gateway hosted by GitLab, or using [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md) to self-host the AI gateway.

This page describes where the AI gateway is deployed, and answers questions about region selection, data routing, and data sovereignty.

## Region support

For GitLab Self-Managed and Dedicated customers, the ability to choose the region is planned for future implementation. Currently, the process for region selection is managed internally by GitLab.

Runway, is currently not available to external customers. GitLab is working on expanding support to include GitLab Self-Managed instances in the future (Epic: [Expand Platform Engineering to more runtimes](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1330)).

[View the available regions](https://gitlab-com.gitlab.io/gl-infra/platform/runway/runwayctl/manifest.schema.html#spec_regions).

For GitLab.com customers, the current routing mechanism is based on the location of the GitLab instance, not the user's location. As GitLab.com is currently single-homed in `us-east1`, requests to the AI gateway are routed to us-east4 in almost all cases. This means that the routing may not always result in the absolute nearest deployment for every user.

The IDE communicates directly with the AI gateway by default, bypassing the GitLab monolith. This direct connection improves routing efficiency. To change this, you can [configure direct and indirect connections](../project/repository/code_suggestions/_index.md#direct-and-indirect-connections).

### Automatic routing

GitLab leverages Cloudflare and Google Cloud Platform (GCP) load balancers to route AI
gateway requests to the nearest available deployment automatically. This routing
mechanism prioritizes low latency and efficient processing of user requests.

You cannot manually control this routing process. The system dynamically selects the optimal region based on factors like network conditions and server load.

### Tracing requests to specific regions

You cannot directly trace your AI requests to specific regions at this time.

If you need assistance with tracing a particular request, GitLab Support can access and
analyze logs that contain Cloudflare headers and instance UUIDs. These logs provide
insights into the routing path and can help identify the region where a request was processed.

## Data sovereignty

It's important to acknowledge the current limitations regarding strict data sovereignty enforcement in our multi-region AI gateway deployment. Currently, we cannot guarantee requests will go to or remain within a particular region and therefore is not a data residency solution.

### Factors that influence data routing

The following factors influence where data is routed.

- **Network latency**: The primary routing mechanism focuses on minimizing latency, meaning data might be processed in a region other than the nearest one if network conditions dictate.
- **Service availability**: In case of regional outages or service disruptions, requests might be automatically rerouted to ensure uninterrupted service.
- **Third-Party dependencies**: The GitLab AI infrastructure relies on third-party model providers, like Google Vertex AI, which have their own data handling practices.

### AI gateway deployment regions

For the most up-to-date information on AI gateway deployment regions, refer to the [AI-assist runway configuration file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/runway.yml?ref_type=heads#L12).

As of the last update (2023-11-21), GitLab deploys the AI gateway in the following regions:

- North America (`us-east4`)
- Europe (`europe-west2`, `europe-west3`, `europe-west9`)
- Asia Pacific (`asia-northeast1`, `asia-northeast3`)

Deployment regions may change frequently. For the most current information, always check the
previously linked configuration file.

The exact location of the LLM models used by the AI gateway is determined by the third-party model providers. Currently, there is no guarantee that the models reside in the same geographical regions as the AI gateway deployments. This implies that data may flow back to the US or other regions where the model provider operates, even if the AI gateway processes the initial request in a different region.

### Data Flow and LLM model locations

GitLab is working closely with LLM providers to understand their regional data handling practices fully.
Currently, there might be instances where data is transmitted to regions outside the one closest to the user due to the factors mentioned in the previous section.

### Future enhancements

GitLab is actively working to let customers specify data residency requirements more granularly in the future. The proposed functionality can provide greater control over data processing locations and help meet specific compliance needs.

## Specific regional questions

### Data routing post-Brexit

The UK's exit from the EU does not directly impact data routing preferences or decisions for AI gateway. Data will continue to be routed to the most optimal region based on performance and availability. Data can still flow freely between the EU and UK.
