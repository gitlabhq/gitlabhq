---
owning-stage: "~devops::data stores" # because Tenant Scale is under this
description: 'Cells ADR 002: One GCP Project per Cell'
---

# Cells ADR 002: One GCP Project per Cell

## Context

We discussed whether we should have each Cell in its own GCP project or have all Cells in one GCP project in [this issue](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25067).

## Decision

It was unanimously decided that we should have one GCP project per Cell. Doing so gives us better isolation between Cells, compatibility with current Dedicated tooling, less likelihood of running into per-project quotas, and easier change rollouts (we can roll out changes per-project).

There is no limit to how many projects we can create.

## Consequences

This decision means that inter-Cell networking becomes slightly less straightforward. However, it is not clear at this point if it's actually needed, and it's [being discussed](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25069)

## Alternatives

The choices discussed above are really the only two possible outcomes.
