---
status: proposed
creation-date: "2024-02-02"
authors: [ "@igorwwwwwwwwwwwwwwwwwwww", "@reprazent" ]
coach: ""
approvers: [ "@nduff", "@stejacks-gitlab", "@abrandl" ]
owning-stage: "~devops::platforms"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Cells: Observability for Cells in a fleet

## Summary

When we deploy multiple Cells, we need to be able to know how a single
cell is doing, but we also need to have an aggregate view of the
entire fleet and how it is performing. We need to have sufficient isolation
between the observability of cells so we can continue to monitor a
cell even if global or cell-local monitoring stack is
struggling.

The monitoring tools we deploy for this need to be consistent across
cells, and any changes we make should be applicable to all cells
regardless of their size or number.

This document will discuss the requirements for such a system. It targets
the [Cells 1.0](../iterations/cells-1.0.md) iteration.

## Motivation

### Goals

1. Provide stakeholders with access to alerts and observability data (logs and metrics).
1. Provision cell-local observability stack.

### Non-Goals

1. We will not provide users of a Cell (e.g. Organization admins) with observability data, it is for operational purposes only.

## Proposal

### Requirements

1. Each cells has an entirely local observability stack that is
   independently accessible and operates independently.

   1. Separate access to logs (e.g. BigQuery, Google's log explorer,
      Elasticsearch, GCS archive).
   1. Separate access to metrics.
   1. Alerting is evaluated per cell.
   1. Capacity planning.
   1. Error budget metrics.
   1. SIRT: Logs delivery to Devo (e.g. Application Logs, Syslogs, Cloud & Infrastructure Audit logs)
   1. Osquery on VMs
   1. Wiz Runtime Agent on all VMs & Kubernetes nodes

1. Cell metrics configuration uses defaults based on the architecture
   and expected workload of the Cell. This is part of the
   configuration of the Cell.
1. Provisioning and change management of cell-local observability stack must be
   integrated with the standard Cells deployment process. This ensures repeatability.
   A deployment may include only changes to observability configuration and infrastructure.
1. Observability for global components (e.g. Cells Router, AI Gateway) is managed
   by the existing global observability stack.
1. The way observability is configured in a Cell should be the same as
   it is for a Dedicated Tenant: using the metrics catalog.

### Nice-to-have

The following are nice-to-have in the scope of Cells 1.0. They may become hard requirements as we broaden our Cells deployment.

1. Unified global (cross-cell) view that fans out to each cell, avoiding
   duplicate data storage. Stakeholders will initially have access to Cell-local
   observability data on a per-Cell basis.
1. Error budget reporting is out of scope for the initial implementation.
   While metrics will be recorded, they will not yet be included in the
   error budget reports for stage groups.
1. This will pave the way for making GitLab Dedicated metrics available
   in our global observability stack. But as we are focusing on cell-local access
   first, this is not in scope of this iteration of observability for Cells.

   **Reason:** Since we need global observability, it means that all
   of the metrics from GitLab-dedicated would be available to everyone
   with access to our Dashboards. This might not be allowed for all
   metrics from Dedicated. So we'll need to go through how we tackle
   that before incorporating those metrics into our global stack which
   includes error budgets for stage groups.

## Design and implementation details

When we discuss implementation details of the solution, we should make sure to answer these questions.

- How and where do we deploy the cell-local stack, do we use Kubernetes?
- How do we manage configuration?
- What does the retention policy look like?
- What are scalability, reliability, DR properties?
- What drives the cost of this system?
- How do we integrate with dashboards?
- How does discovery and authentication work?

### Metrics

- Which technology do we use for metrics scraping, storage, rule evaluation, alerting?
  - e.g. GCP managed vs self-hosted Prometheus, Mimir, etc.
- How do we expose these metrics to users?
- How do we expose these metrics for tooling and automation?

### Logging

- Which technology do we use for log collection and forwarding?
  - e.g. fluentd, vector
- Which technology do we use for log ingestion and storage?
  - e.g. Stackdriver, Beats, ELK, etc.

## Alternative Solutions

We should consider trade-offs between candidates and state why a particular technology was chosen.
