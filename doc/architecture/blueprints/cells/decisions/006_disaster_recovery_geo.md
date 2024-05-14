---
owning-stage: "~devops::data stores" # because Tenant Scale is under this
description: 'Cells ADR 006: Use Geo for Disaster Recovery'
---

# Cells ADR 006: Use Geo for Disaster Recovery

## Context

We discussed whether we should use Geo for Disaster Recovery in [this issue](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25246).

## Decision

It was decided that for Cells 1.0 we will use Geo for Disaster Recovery.
This is the same approach we take for GitLab Dedicated.

## Consequences

This decision means that it will increase the initial cloud spend for Cells.
We estimate that it will double the spend of our first Cells deployments, which will be limited in number for the first Cells deployment.

## Alternatives

The alternatives we discussed was to come up with a new process specific to Dedicated tooling for restoring from backup.
