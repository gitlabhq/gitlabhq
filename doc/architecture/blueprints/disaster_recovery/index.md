---
status: ongoing
creation-date: "2024-01-29"
authors: [ "@jarv" ]
coach:
approvers: [  ]
---

# Disaster Recovery

This document is a work-in-progress and proposes architecture changes for the GitLab.com SaaS.
The goal of these changes are to maintain GitLab.com service continuity in the case a regional or zonal outage.

- A **zonal recovery** is required when all resources are unavailable in one of the three availability zones in `us-east1` or `us-central1`.
- A **regional recovery** is required when all resources become unavailable in one of the regions critical to operation of GitLab.com, either `us-east1` or `us-central1`.

## Services not included in the current DR strategy for FY24 and FY25

We have limited the scope of DR to services that support primary services (Web, API, Git, Pages, Sidekiq, CI, and Registry).
These services tie directly into our overall [availability score](https://dashboards.gitlab.net/d/general-slas/general3a-slas?orgId=1) (internal link) for GitLab.com.

For example, DR does not include the following:

- AI services including code suggestions
- Error tracking and other observability services like tracing
- CustomersDot, responsible for billing and new subscriptions
- Advanced Search

## DR Implementation Targets

The FY24 targets were:

|              | Recovery Time Objective (RTO) | Recovery Point Objective (RPO) |
|--------------|-------------------------------|--------------------------------|
| **Zonal**    | 2 hours                       | 1 hour                         |
| **Regional** | 96 hours                      | 2 hours                        |

The FY25 targets before cell architecture are:

|              | Recovery Time Objective (RTO) | Recovery Point Objective (RPO) |
|--------------|-------------------------------|--------------------------------|
| **Zonal**    | 0 minutes                     | 0 minutes                      |
| **Regional** | 48 hours                      | 0 minutes                      |

**Note**: While the RPO values are targets, they cannot be met exactly due to the limitations of regional bucket replication and replication lag of Gitaly and PostgreSQL.

## Current Recovery Time Objective (RTO) and Recovery Point Objective (RPO) for Zonal Recovery

We have not yet simulated a full zonal outage on GitLab.com.
The following are RTO/RPO estimates based on what we have been able to test using the [disaster recovery runbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/disaster-recovery?ref_type=heads).
It is assumed that each service can be restored in parallel.
A parallel restore is the only way we are able to meet the FY24 RTO target of 2 hours for a zonal recovery.

| Service | RTO | RPO |
| --- | --- | --- |
| PostgreSQL | 1.5 hr | <=5 min |
| Redis [^1] | 0 | 0 |
| Gitaly | 30 min | <=1 hr |
| CI | 30 min | not applicable |
| Load balancing (HAProxy) | 30 min | not applicable |
| Frontend services (Web, API, Git, Pages, Registry) [^2] | 15 min | 0 |
| Monitoring (Prometheus, Thanos, Grafana, Alerting) | 0 | not applicable |
| Operations (Deployments, runbooks, operational tooling, Chef) [^3] | 30 min | 4 hr |
| PackageCloud (distribution of packages for self-managed) | 0 | 0 |

## Current Recovery Time Objective (RTO) and Recovery Point Objective (RPO) for Regional Recovery

Regional recovery requires a complete rebuild of GitLab.com using backups that are stored in multi-region buckets.
The recovery has not yet been validated end-to-end, so we don't know how long the RTO is for a regional failure.
Our target RTO for FY25 is to have a procedure to recover from a regional outage in under 48 hours.

The following are considerations for choosing multi-region buckets over dual-region buckets:

- We operate out of a single region so multi-region storage is only used for disaster recovery.
- Although Google recommends dual-region for disaster recovery, dual-region is [not an available storage type for disk snapshots](https://cloud.google.com/compute/docs/disks/snapshots#selecting_a_storage_location).
- To mitigate the bandwidth limitation of multi-region buckets, we spread Gitaly VMs infra across multiple projects.

## Proposals for Regional and Zonal Recovery

- [Regional](regional.md)
- [Zonal](zonal.md)

---

   [^1]: Most of the Redis load is on the primary node, so losing replicas should not cause any service interruption
   [^2]: We setup maximum replicas in our Kubernetes clusters servicing front-end traffic, this is done to avoid saturating downstream dependencies. For a zonal failure, a cluster reconfiguration is necessary to increase these maximums.
   [^3]: There is a 4 hr RPO for Operations because Chef is an single point of failure in a single availability zone and our restore method uses disk snapshots, taken every 4 hours. While most of our Chef configuration is also stored in Git, some data (like node registrations) are only stored on the server.
