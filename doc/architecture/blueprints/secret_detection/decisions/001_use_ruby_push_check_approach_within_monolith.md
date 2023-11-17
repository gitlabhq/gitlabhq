---
owning-stage: "~devops::secure"
description: "GitLab Secret Detection ADR 001: Use Ruby Push Check approach within monolith"
---

# GitLab Secret Detection ADR 001: Use Ruby Push Check approach within monolith

## Context

There are a number of concerns around the performance of secret detection using a regex-based approach at scale. The primary considerations include transfer latency between nodes and both CPU and memory bloat. These concerns manifested in two ways: the language to be used for performing regex matching and the deployment architecture.

The original discussion in [the exploration issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428499) covers many of these concerns and background.

### Implementation language

The two primary languages considered were Ruby and Go.

The choice to use other languages (such as C++) for implementation was discarded in favour of Ruby and Go due to team familiarity, speed of deployment, and portability. See [this benchmarking issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423832) for performance comparisons between the two.

### Deployment architecture

Several options were considered for deployments: directly embedding the logic within the Rails monolith's Push Check execution path, placement as a sidecar within a Rails node deployment, placement as a sidecar within a Gitaly node as a [server-side hook](../../../../administration/server_hooks.md), and deployment as a standalone service.

## Decision

For the initial iteration around blocking push events using a prereceive integration, the decision was made to proceed with Ruby-based approach, leveraging `re2` for performant regex processing. Additionally, the decision was made to integrate the logic directly into the monolith rather than as a discrete service or server-side hook within Gitaly.

A Gitaly server-side hook would have performance benefits around minimal transfer latency for Git blobs between scanning service and Gitaly blob storage. However, an extra request would be needed between Gitaly and the Rails application to contextualize the scan. Additionally, the current hook architecture is [discouraged and work is planned to migrate towards a new plugin architecture in the near future](https://gitlab.com/gitlab-org/gitaly/-/issues/5642).

The Ruby Push Check approach follows a clear execution plan to achieve delivery by anticipated timeline and is more closely aligned with the long-term direction of platform-wide scanning. For example, future scanning of issuables will require execution within the trust boundary of the Rails application rather than Gitaly context. This approach, however, has raised concerns around elevated memory usage within the Rails application leading to availability concerns. This direction may also require migrating towards Gitaly's new plugin architecture in the future once the timeline is known.

A standalone service may be considered in the future but requires considerations of a technical approach that should be better informed by data gathered during [pre-production profiling](https://gitlab.com/gitlab-org/gitlab/-/issues/428499).
