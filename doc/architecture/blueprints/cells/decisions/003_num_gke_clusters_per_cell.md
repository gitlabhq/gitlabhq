---
owning-stage: "~devops::data stores" # because Tenant Scale is under this
description: 'Cells ADR 003: One GKE Cluster per Cell'
---

# Cells ADR 003: One GKE Cluster per Cell

## Context

In [this issue](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25068) we discussed:

- Whether we should have multiple Cells in one GKE cluster, or just a single one
- Whether a Cell should run on one GKE cluster or multiple clusters

## Decision

It was decided that we should have a single GKE cluster per Cell. The motivating factor behind this decision is simplicity: the Cells tooling will harness the existing Dedicated tooling, which in turn uses the [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) to deploy the [Reference Architectures](../../../../administration/reference_architectures/index.md). None of the Reference Architectures support running a single GitLab instance across multiple GKE clusters.

The decision made in [ADR 002](002_gcp_project_boundary.md) to have one Cell per GCP project, along with the choice made above, precludes the possibility of having multiple GKE clusters serve a single Cell.

## Consequences

Having a single GKE cluster per Cell will provisioning and management of a Cell easier as there will be no need to build in complex routing logic between GKE clusters.

Should we ever hit the limit on nodes per cluster ([currently 15000](https://cloud.google.com/kubernetes-engine/quotas)), we will be limited to vertically scaling nodes rather than being able to spread the workload over multiple clusters. However, since our current production setup for GitLab.com only uses around 300 nodes, this is unlikely to occur for quite some time, if ever.

## Alternatives

Alternatives discussed above would necessitate significant structural changes to GET, such that it would arguably be more efficient (and less disruptive) to simply not use any existing tooling. However, this goes against the overall Cells infrastructure [philosophy](../infrastructure/index.md).
