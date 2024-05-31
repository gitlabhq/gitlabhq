---
status: proposed
creation-date: "2024-02-02"
authors: [ "@igorwwwwwwwwwwwwwwwwwwww", "@reprazent", "@abrandl" ]
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

A Cells deployment is effectively going to use [Instrumentor](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor), which is also used to create and manage GitLab Dedicated environments.
Instrumentor is capable of deploying to AWS and GCP, but for Cells, GCP is the only relevant target.
See the [Deployment Blueprint](deployments.md#deployment-coordinator-and-cell-cluster-coordinator) for more details around how Cell environments are deployed.

### Readiness for first Cell deployment: Basic Observability

The environment created through Instrumentor includes a set of Observability features, which are managed from the [`tenant-observability-stack` module](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor/blob/de8f7220366fc8a284dac14cab708fb55b0c790d/common/modules/tenant-observability-stack/main.tf#L1).
The following features are already supported in an environment created by Instrumentor (in GCP):

1. Cell-local metrics using [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) (Prometheus, Grafana on Kubernetes)
1. A deployment of the GET metrics catalog (dashboards, recording rules, alerts)
1. Exporters (`cert-exporter`, `redis-exporter`)

By default, the GCP-based environment currently uses Cloud Logging for logging.

Once we are ready to deploy a first Cell environment, we can expect these features to be available out of the box.

### Next iteration: Completing Observability Fundamentals

In order to complete support for fundamental Observability in Cells, we plan to take the following steps.

1. OBS0: [Extract tenant-observability-stack into its own module](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3539)
1. OBS1: [Deployment automation to update observability configuration in a Cell independently](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1337)
1. OBS2: [Connect Cell-local Prometheus to global Alertmanager](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1338)
1. OBS3: [Implement Logging in Cells using Elastic Cloud](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1339)

#### OBS0: Extract tenant-observability-stack into its own module

Issue: [#3539](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3539)

In order to set the Scalability::Observability team up for quick iteration cycles, we'd like to split out and extract the observability-related aspects from the Instrumentor codebase and manage that in a separate module.
We create a separate terraform module [observability-cell-stack](https://gitlab.com/gitlab-com/gl-infra/terraform-modules/observability/observability-cell-stack), which carries the Observability implementation for Cells.

We expect to benefit from this from an organisational perspective, because it'll allow us to iterate on changes quicker and without directly relying on code reviews from other teams.
The idea is to provide a cohesive module with a well-defined interface (parameters), which can be used to inject the observability stack e.g. in a Cells environment managed through Instrumentor.
We expect this to also help with testing aspects, as we don't need to go through a full Instrumentor sandbox to test out individual changes in early stages of development.

The idea of extracting modules out of Instrumentor is also more widely applicable as a part of the Cells effort.
We plan to implement a common structure for modules extracted, so that other teams can follow a similar approach.

#### OBS1: Managing observability configuration in a Cell

Epic: [&1337](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1337)

When updating Observability configuration like recording rules, alerts or log index definitions, we need these updates to be applied to a Cell independently of redeploying the entire environment.
In order to update this configuration in a Cell independently, we plan to decouple the configuration lifecycle from Instrumentor and instead use a Kubernetes operator to refresh the configuration.

Currently, in Instrumentor, observability configuration like the [GET metrics catalog](https://gitlab.com/gitlab-com/runbooks/blob/180a5b96670abd6cc2e2ceda395e7eb6752b5bf1/reference-architectures/get-hybrid/README.md#L1) gets vendored into Instrumentor itself.
Instrumentor [can define overrides](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor/-/blob/main/metrics-catalog/gcp/overrides/gitlab-metrics-options.libsonnet) for a limited part of the configuration.
The actual [configuration gets generated and checked in](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor/-/tree/main/metrics-catalog/gcp/config) to be deployed to the environment.

In order to update configuration independently of the entire environment, we plan to implement a mechanic to refresh this configuration on request or upon release of a new version for this configuration.
It's worthwhile to note that the configuration version is independent of the Instrumentor release and the version of the `tenant-observability-stack` module extracted in OBS0.

This section needs to be detailed with specific aspects of how and when configuration will need to be updated.
We can detail this separately for metrics and logging configuration.

#### OBS2: Routing alerts to global Alertmanager

Epic: [&1338](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1338)

In order to handle alerts from a Cell, we need to route these to the global Alertmanager (`alerts.gitlab.net` instance, also related to [#4645](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4645)).
Alerts need to carry a Cell-identifier, so we can distinguish them across Cell environments and they also need to always link back to the correct cell-local monitoring stack (e.g. Grafana links, etc.).

This is also relevant for GitLab Dedicated, see [#4645](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4645).

This section needs to be detailed as we learn more.

#### OBS3: Logging in Cells using Elastic Cloud

Epic: [&1339](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1339)

We aim to use Elastic Cloud and GCS in a similar fashion as we use it for GitLab.com.

As we detail this part more, we need to dive into the following aspects:

1. Provisioning of a Elastic Cloud deployment per Cell
1. Deploy logging pipeline to ingest logs into Elastic Cloud and GCS
1. Coordinate with SIRT to ingest logs into their SIEM using pub-sub

We need to answer the following questions:

- Logging: Which technology do we use for log collection and forwarding (e.g. fluentd, vector)? The goal is to use the same log ingestion/forwarding mechanism for GitLab Dedicated (also see [#5037](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/5037)) and Cells, but potentially support a different destination to persist logs to.

### Questions to be addressed

As we detail the design and execute on the implementation, we should make sure to answer these questions.

- What does the retention policy look like?
- What are scalability, reliability, DR properties?
- What drives the cost of this system?
- How do we integrate with dashboards?
- How does discovery and authentication work?

### Technology choices

We target to use the same technology stack for a Cells environment as we currently use in the GitLab.com production environment.

This means, we're not using the migration to Cells to trial or migrate to different technologies and tools we are not yet using today.
This does not limit our ability to introduce new technology overall, but we don't want the Cells environment to significantly divert from the choices made on .com.

For Cells 1.0, using a less scalable approach than on .com is acceptable to get us started.

## Alternative Solutions

We should consider trade-offs between candidates and state why a particular technology was chosen.
