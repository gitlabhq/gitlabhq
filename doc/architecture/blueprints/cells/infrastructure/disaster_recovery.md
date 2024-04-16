---
stage: core platform
group: Tenant Scale
description: 'Cells: Disaster Recovery'
status: proposed
---

# Cells 1.0 Disaster Recovery

## Terms used

1. Primary Cell: GitLab.com SaaS which is the current GitLab.com deployment. A special purpose Cell that serves as a cluster-wide service in this architecture.
1. Secondary Cells: A Cell that connects to the Primary Cell to ensure cluster-wide uniqueness.
1. Global Service: A service to keep global uniqueness, manage database sequences across the cluster, and help classify which resources belong to which Cell.
1. Routing Service: The Routing Service depends on the Global Service and is for managing routing rules to different cells.
1. RTO: [Recovery Time Objective]
1. RPO: [Recovery Point Objective]
1. WAL: [Write-ahead logging]

## Goals

Cells 1.0 is the first iteration of cells where multiple Secondary Cells can be operated independently of the Primary Cell.
Though it can be operated independently it has a dependency on the Global Service and Routing Service.
For Disaster Recovery, the Global Service might still have dependencies on the Primary Cell in Cells 1.0. [^cells-1.0]
A decision on whether or not we use Geo for Cells DR is pending in the [Using Geo for Cells 1.0 tracking issue](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25246).

This document focuses only on defining the strategy for recovering secondary Cells.
It does not cover recovering the Global Service, Routing Service, Primary Cell, or any other external service.

Disaster Recovery for Cells creates a fork in our existing recovery process because cells are provisioned with different tooling.
For example:

1. Different processes, runbooks, and tooling to recover a Cell.
1. Different RPO/RTO for primary Cell and the other cells.

Due to this, there are different goals for RPO/RTO for the Primary and Secondary Cells.

- Meet or exceed the RTO and RPO FY24 targets that have been validated for zonal outages which are covered in the [GitLab.com Disaster Recovery Blueprint](../../disaster_recovery/index.md).
- Take into account the FY25 plans for regional recovery on the Primary Cell including regional recovery and alternate region selection.
- Leverage the same DR for procedure we use for Dedicated for Cells.

### RTO/RPO Targets

NOTE:
FY25 targets have not yet been validated on the Primary Cell.

**Zonal Outages**:

|                                      | RTO       | RPO |
|--------------------------------------|-----------|-----|
| Primary Cell (current)               | 2 hours   | 1 hour |
| Primary Cell (FY25 Target)           | <1 minute | <1 minute |
| Cells 1.0 (without the primary cell) | _unknown_ | _unknown_ |

**Regional Outages**:

|                                      | RTO       | RPO |
|--------------------------------------|-----------|-----|
| Primary Cell (current)               | 96 hours  | 2 hours |
| Primary Cell (FY25 Target)           | 48 hours  | <1 minute [^object-storage] |
| Cells 1.0 (without the primary cell) | _unknown_ | _unknown_ |

## Disaster Recovery Overview

NOTE:
The services below are taken from the [Cells 1.0 Architecture Overview].

Zonal recovery refers to a disaster, outage, or deletion that is limited in scope to a single availability zone.
The outage might affect the entire zone, or a subset of infrastructure in a zone.
Regional recovery refers to a disaster, outage, or deletion that is limited in scope to an entire region.
The outage might affect the entire region, or a subset of infrastructure that affects more than one zone.

| Service | Zonal Disaster Recovery | Estimated RTO | Estimated RPO |
| --- | --- | --- | --- |
| GitLab Rails            | All services running in a cell are redundant across zones. There is no data stored for this service. | <=1 minute | not applicable |
| Gitaly Cluster          | Gitaly Cluster consists of a single SPOF (single point of failure) node and remains so for Cells 1.0. It requires a restore from backup in the case of a zonal failure. | <=30 min | <=1 hr for snapshot restore until WAL is available for restore. [^blueprint-dr] |
| Redis Cluster           | Redis is deployed in multiple availability zones and be capable of recovering automatically from a service interruption in a single zone. | <=1 minute | <=1 minute |
| PostgreSQL Cluster      | PostgreSQL cluster is deployed in multiple availability zones and be capable of recovering automatically from a service interruption in a single zone. A small amount of data-loss might occur on failover. | <=1 minute | <=1 minute |

| Service | Regional Disaster Recovery | Estimated RTO | Estimated RPO |
| --- | --- | --- | --- |
| GitLab Rails            | All services running in a cell are local to a region and require a rebuild on a regional failure. There is no data stored for this service. | <=12 hours | not applicable |
| Gitaly Cluster          | Initially, Gitaly Cluster consists of a single SPOF node and remains so for Cells 1.0. It requires a rebuild in the case of a regional failure. | _Unknown_ | <=1 hr for snapshot restore until WAL is available for restore. [^blueprint-dr] |
| Redis Cluster           | Redis is deployed in a single region and requires a rebuild in the case of a regional failure. In flight jobs, session data and cache can not be recovered. | _Unknown_ | not applicable |
| PostgreSQL Cluster      | The PostgreSQL cluster is deployed in a single region and requires a rebuild in the case of a regional failure. Recovery is from backups and WAL files. A small amount of data-loss might occur on failover. | _Unknown_ | <=5 minutes |

NOTE:
For data stored in Object storage in Cells multi-region buckets are used. For restoring data due to accidental deletion we rely on object versioning for recovery.

## Disaster Recovery Validation

Disaster Recovery for Cells needs to be validated through periodic restore testing.
This recovery should be done on a Cell in the Production environment.
This testing is done once a quarter and is completed by running game-days using the disaster recovery runbook.

## Risks

1. The Primary Cell is not using Dedicated for deployment and operation where the Secondary Cells are. This might split our processes and runbooks and add to our RTO.
1. The current plan is to run Secondary Cells using Dedicated. The process for Disaster Recovery on Dedicated has a large number of manual steps and is not yet automated.[^dedicated-dr]
1. The Dedicated DR runbook has guidance, but is not structured in a way that can be followed by an SRE in the event of a Disaster. [^dedicated-dr-final-update]

---

   [Cells 1.0 Architecture Overview]: https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/architecture/blueprints/cells/iterations/cells-1.0.md#architecture-overview
   [Recovery Time Objective]: https://en.wikipedia.org/wiki/Disaster_recovery#Recovery_Time_Objective
   [Recovery Point Objective]: https://en.wikipedia.org/wiki/Disaster_recovery#Recovery_Point_Objective
   [Write-ahead logging]: https://en.wikipedia.org/wiki/Write-ahead_logging

   [^cells-1.0]: See the [Cells 1.0 blueprint](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/architecture/blueprints/cells/iterations/cells-1.0.md)
   [^blueprint-dr]: See the [DR Blueprint](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/architecture/blueprints/disaster_recovery?ref_type=heads#current-recovery-time-objective-rto-and-recovery-point-objective-rpo-for-zonal-recovery)
   [^object-storage]: On the Primary cell and Cells 1.0 backups and data are stored on Google Object Storage which makes no RPO guarantees for regional failure. At this time, there are no plans to use dual-region buckets which have a 15 minute RPO guarantee.
   [^dedicated-dr]: See [this tracking epic](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/292) for the work that was done to validate DR on Dedicated and [this issue](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/3948) for future plans to improve the Dedicated runbooks.
   [^dedicated-dr-final-update]: See [this note](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/292#note_1751653953) on why this is the case and that Dedicated and how Geo is the preferred method for Disaster Recovery.
