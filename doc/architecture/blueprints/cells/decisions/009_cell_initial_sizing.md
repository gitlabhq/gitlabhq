---
owning-stage: "~devops::data stores"
description: 'Cells ADR 009: Initial Cell Sizes'
---

<!-- vale gitlab.FutureTense = NO -->
# Initial Cell Sizes

## Context

When we provision a Cell we have to choose a [Reference Architectures](../../../../administration/reference_architectures/index.md) to start with,
then go on to scale accordingly to the workloads based upon [flexible architecture](005_flexible_reference_architectures.md) to scale accordingly to the workloads.

In <https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2838> we did some research on which reference architecture to choose initially.

## Decision

### Ring 0

For Ring 0 we will only run QA Jobs and it will not serve any customer traffic,
for cost efficiency reasons we will go with a [3k reference architecture](../../../../administration/reference_architectures/3k_users.md).

### Ring 2 and above

The first Cell will be used for [internal customers only/ GitLab Inc](007_internal_customers.md) only, and it will be done gradually so that not all of GitLab Inc repositories will be moved at once.
The time between when we first provision this Cell vs when we on-board all of GitLab Inc is still unknown,
so we'll start with a medium sized Cell [25k reference architecture](../../../../administration/reference_architectures/25k_users.md) sized Cell, and then scale it up to a [50k reference architecture](../../../../administration/reference_architectures/50k_users.md).

The other Cells that we'll provision in this ring and other outer rings will start with a [50k reference architecture](../../../../administration/reference_architectures/50k_users.md).

## Consequences

For the Cell in `Ring 0`, we don't see any consequences yet.

For the Cell serving GitLab Inc we might need to be scale it from 25k to 50k which can result [in downtime](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/blob/main/runbooks/upgrading-tenant-reference-architectures.md?ref_type=heads)
because we need to resize stateful services like Gitaly, Database, and Redis.
The duration of this downtime is still unknown and untested,
but for Dedicated on AWS this is around 20-40 minutes.
If we have to take this downtime it will be only internally,
and can be done over the weekend for minimal impact.

## Alternatives

For the first Cell serving GitLab Inc. we can go with a 50k reference architecture from the start but:

- We don't know if we'll need all these resources when we onboard everyone.
- We still don't know when we'll onboard everyone resulting in a lot of wasted compute.
- We can use [flexible reference architectures](005_flexible_reference_architectures.md) to fix specific hot spots in the architecture first.
