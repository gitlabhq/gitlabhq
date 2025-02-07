---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly and Geo capabilities
---

It is common to want the most available, quickly recoverable, highly performant,
and fully resilient solution for your data. However, there are tradeoffs.

The following tables are intended to guide you to choose the right combination of capabilities based on your requirements.

## Gitaly capabilities

| Capability | Availability | Recoverability | Data Resiliency | Performance | Risks/Trade-offs|
|------------|--------------|----------------|-----------------|-------------|-----------------|
|Gitaly Cluster | Very high - tolerant of node failures | RTO for a single node of 10 s with no manual intervention | Data is stored on multiple nodes | Good - While writes may take slightly longer due to voting, read distribution improves read speeds | **Trade-off** - Slight decrease in write speed for redundant, strongly-consistent storage solution. **Risks** - [Does not support snapshot backups](../gitaly/_index.md#snapshot-backup-and-recovery), GitLab backup task can be slow for large data sets |
|Gitaly Shards | Single storage location is a single point of failure | Would need to restore only shards which failed | Single point of failure | Good - can allocate repositories to shards to spread load | **Trade-off** - Need to manually configure repositories into different shards to balance loads / storage space **Risks** - Single point of failure relies on recovery process when single-node failure occurs |

## Geo capabilities

If your availability needs to span multiple zones or multiple locations, read about [Geo](../geo/_index.md).

| Capability | Availability | Recoverability | Data Resiliency | Performance | Risks/Trade-offs|
|------------|--------------|----------------|-----------------|-------------|-----------------|
|Geo| Depends on the architecture of the Geo site. It is possible to deploy secondaries in single and multiple node configurations. | Eventually consistent. Recovery point depends on replication lag, which depends on a number of factors such as network speeds. Geo supports failover from a primary to secondary site using manual commands that are scriptable. | Geo replicates and verifies 100% of planned data types. See the [replicated data types table](../geo/replication/datatypes.md#replicated-data-types) for more detail. | Improves read/clone times for users of a secondary.  | Geo is not intended to replace other backup/restore solutions. Because of replication lag and the possibility of replicating bad data from a primary, customers should also take regular backups of their primary site and test the restore process. |

## Scenarios for failure modes and available mitigation paths

The following table outlines failure modes and mitigation paths for the product offerings detailed in the tables above. Note - Gitaly Cluster install assumes an odd number replication factor of 3 or greater

| Gitaly Mode | Loss of Single Gitaly Node | Application / Data Corruption | Regional Outage (Loss of Instance) | Notes |
| ----------- | -------------------------- | ----------------------------- | ---------------------------------- | ----- |
| Single Gitaly Node | Downtime - Must restore from backup | Downtime - Must restore from Backup | Downtime - Must wait for outage to end | |
| Single Gitaly Node + Geo Secondary | Downtime - Must restore from backup, can perform a manual failover to secondary | Downtime - Must restore from Backup, errors could have propagated to secondary | Manual intervention - failover to Geo secondary | |
| Sharded Gitaly Install | Partial Downtime - Only repositories on impacted node affected, must restore from backup | Partial Downtime - Only repositories on impacted node affected, must restore from backup | Downtime - Must wait for outage to end | |
| Sharded Gitaly Install + Geo Secondary | Partial Downtime - Only repositories on impacted node affected, must restore from backup, could perform manual failover to secondary for impacted repositories | Partial Downtime - Only repositories on impacted node affected, must restore from backup, errors could have propagated to secondary | Manual intervention - failover to Geo secondary | |
| Gitaly Cluster Install* | No Downtime - swaps repository primary to another node after 10 seconds | Not applicable; All writes are voted on by multiple Gitaly Cluster nodes | Downtime - Must wait for outage to end | Snapshot backups for Gitaly Cluster nodes not supported at this time |
| Gitaly Cluster Install* + Geo Secondary | No Downtime - swaps repository primary to another node after 10 seconds | Not applicable; All writes are voted on by multiple Gitaly Cluster nodes | Manual intervention - failover to Geo secondary | Snapshot backups for Gitaly Cluster nodes not supported at this time |
