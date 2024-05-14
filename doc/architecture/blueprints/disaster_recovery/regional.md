---
status: ongoing
creation-date: "2024-01-29"
authors: [ "@jarv" ]
coach:
approvers: [  ]
---

# Regional Recovery

## Improving the Recovery Time Objective (RTO) and Recovery Point Objective (RPO) for Regional Recovery

The following list the top challenges that limit our ability to drive `RTO` to 48 hours for a regional recovery.

1. We have a large amount of legacy infrastructure managed using Chef. This configuration has been difficult for us to manage and would require a large a mount of manual copying and duplication to create new infrastructure in an alternate region.
1. Operational infrastructure is located in a single region, `us-central1`. For a regional failure in this region, it requires rebuilding the ops infrastructure with only local copies of runbooks and tooling scripts.
1. Observability is hosted in a single region.
1. The infrastructure (`dev.gitlab.org`) that builds Docker images and packages is located in a single region, and is a single point of failure.
1. There is no launch-pad that would allow us to get a head-start on a regional recovery. Our IaC (Infrastructure-as-Code) does not allow us to switch regions for provisioning.
1. We don't have confidence that Google can provide us with the capacity we need in a new region, specifically the large amount of SSD necessary to restore all of our customer Git data.
1. We use [Global DNS](https://cloud.google.com/compute/docs/internal-dns) for internal DNS making it difficult to use multiple instances with the same name across multiple regions, we also don't incorporate regions into DNS names for our internal endpoints (for example dashboards, logs, etc).
1. If we deploy replicas in another region to reduce RPO we are not yet sure of the latency or cloud spend impacts.
1. We have special/negotiated Quota increases for Compute, Network, and API with the Google Cloud Platform only for a single region, we have to match these quotas in a new region, and keep them in sync.
1. We have not standardized a way to divert traffic at the edge from 1 region to another.
1. In monitoring, and configuration we have places where we hardcode the region to `us-east1`.

## Regional recovery work-streams

The first step of our regional recovery plan creates new infrastructure in the recovery region that involves a large number of manual steps.
To give us a head-start on recovery, we propose a "regional bulkhead" deployment in a new GCP region.

A "regional bulkhead" meets the following requirements:

1. A specific region is allocated.
1. Quotas are set and synced so that we can duplicate all of us-east1 in the new region.
1. Subnets are allocated or reserved in the same VPC for us-east1.
1. Some infrastructure is deployed where it makes sense to lower RTO, while keeping cloud-spend low.

The following are work-streams that can be done mostly in parallel.
The end-goal of the regional recovery is to have a bulkhead that has the basic scaffolding for deployment in the alternate region.
This bulkhead can be used as a launching pad for a full data restore from `us-east1` to the alternate region.

### Select an alternate region

We are going with **`us-central1`**. Discussion for this was done in <https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25094>

- Dependencies: none
- Teams: Ops

The following are considerations that need to be made when selecting an alternate region for DR:

1. Ensure there is enough capacity to meet compute usage.
1. Network and network latency requirements, if any.
1. Feature parity between regions.

### Deploy Kubernetes clusters supporting front-end services in a new region with deployments

- Dependencies: [External front-end load balancing](#external-front-end-load-balancing)
- Teams: Ops, Foundations, Delivery

GitLab.com has Web, API, Git, Git HTTPs, Git SSH, Pages, and Registry as front-end services.
All of these services are run in 4 Kubernetes clusters deployed in `us-east1`.
These services are either stateless or use multi-region storage buckets for data.
In the case of a failure in `us-east1`, we would need to rebuild these clusters in the alternate region and set them up for deployments.

### Switch from Global to Zonal DNS

- Dependencies: None
- Teams: Gitaly

Gitaly VMs are single points of failure that are deployed in `us-east1`.
The internal DNS naming of the nodes have the following convention:

```plaintext
gitaly-01-stor-gprd.c.gitlab-gitaly-gprd-ccb0.internal
 ^ name                    ^ project
```

By switching to zonal DNS, we can change the internal DNS entries so they have the zone in the DNS name:

```plaintext
gitaly-01-stor-gprd.c.us-east1-b.gitlab-gitaly-gprd-ccb0.internal
 ^ name                  ^ zone     ^ project
```

Allowing us to keep the same name when recovering into a new region or zone.

```plaintext
gitaly-01-stor-gprd.c.us-east1-b.gitlab-gitaly-gprd-ccb0.internal
gitaly-01-stor-gprd.c.us-east4-a.gitlab-gitaly-gprd-ccb0.internal
```

For fleets of VMs outside of Kubernetes, these names allow us to have the same node names in the recovery region.

### Gitaly

- Dependencies: [Switch from Global to Zonal DNS](#switch-from-global-to-zonal-dns) (optional, but desired)
- Teams: Gitaly, Ops, Foundations

Restoring the entire Gitaly fleet requires a large number of VMs deployed in the alternate region.
It also requires a lot of bandwidth because restore is based on disk snapshots.
To ensure a successful Gitaly restore, quotas need to be synced with us-east1 and there needs to be end-to-end validation.

### PostgreSQL

- Dependencies: [Improve Chef provisioning time by using preconfigured golden OS images](zonal.md#improve-chef-provisioning-time-by-using-preconfigured-golden-os-images) (optional, but desired), local backups in the standby region (data disk snapshot and `WAL` archiving).
- Teams: Database Reliability, Ops

The configuration for Patroni provisioning only allows a single region per cluster.
There is networking infrastructure, Consul, and load balancers that need to be setup in the alternate region.
We may consider setting up a "cascaded cluster" for the databases to improve recovery time for replication.

### Redis

- Dependencies: [Improve Chef provisioning time by using preconfigured golden OS images](zonal.md#improve-chef-provisioning-time-by-using-preconfigured-golden-os-images) (optional, but desired)
- Teams: Ops

To provision Redis subnets need to be allocated in the alternate region with and end-to-end validation of the new deployments.

### External front-end load balancing

- Dependencies: HAProxy replacement, mostly likely [GKE Gateway and Istio](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1157)
- Teams: Ops, Foundations

External front-end load balancing is necessary to validate the deployment in the alternate region.
This requires both external and internal LBs for all front-end-services.

### Monitoring

- Dependencies: [Eliminate X% Chef dependencies in Infra by moving infra away from Chef](zonal.md#eliminate-x-chef-dependencies-in-infra-by-moving-infra-away-from-chef) (migrate Prometheus infra to Kubernetes)
- Teams: Scalability:Observability, Ops, Foundations

Setup an alternate ops Kubernetes cluster in a different region that is scaled down to zero replicas.

### Runners

Dependencies: [Improve Chef provisioning time by using preconfigured golden OS images](zonal.md#improve-chef-provisioning-time-by-using-preconfigured-golden-os-images) (optional, but desired)
Teams: Scalability:Practices, Ops, Foundations

Ensure quotas are set and align with us-east1 in the alternate region for both runner managers and ephemeral VMs.
Setup and validate networking configuration with peering configuration.

### Ops and Packaging

- Dependencies: [Create an HA Chef server configuration to avoid an outage for a single zone failure](zonal.md#create-an-ha-chef-server-configuration-to-avoid-an-outage-for-a-single-zone-failure)
- Teams: Scalability:Practices, Ops, Foundations, Distribution

All image creation and packaging is done on a single VM, our operation tooling is also on a single VM.
Both of these are single points of failures that have data stored locally.
In the case of a regional outage, we would need to rebuild them from snapshot and lose about 4 hours of data.

The following are options to mitigate this risk:

- Move our packaging jobs to `ops.gitlab.net` so we eliminate `dev.gitlab.org` as a single point of failure.
- Use the Geo feature for `ops.gitlab.net`.

### Regional Recovery Gameday

- Dependencies: Recovery improvements
- Teams: Ops

Following the improvements for regional recovery, a Gameday needs to be executed for end-to-end testing of the procedure.
Once validated, it can be added to our existing [disaster recovery runbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/disaster-recovery?ref_type=heads).
