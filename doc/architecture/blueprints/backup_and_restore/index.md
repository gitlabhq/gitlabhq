---
status: ongoing
creation-date: "2024-06-04"
authors: [ "@aakriti.gupta", "@brodock", "@ibaum", "@kyetter" ]
coach: ""
approvers: []
owning-stage: "~devops::systems"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# Backup and Restore GitLab

## Summary

[The Unified Backups project](https://gitlab.com/groups/gitlab-org/-/epics/11577) provides a single command-line tool that will handle the application backup and recovery needs of GitLab installations across supported [reference architectures](../../../administration/reference_architectures/index.md). It will be packaged separately from the main GitLab code base to keep it decoupled from specific release versions but will be shipped along with GitLab releases.

This tool will be aware of the nuances of each runtime environment configuration and it will make adaptations to capture and restore data appropriately. It will stand as the primary recommended solution for most customers going forward.

Early development on this tool will focus on providing value to self-hosted customers of GitLab by supporting the variety of installation types and common architectures. For these customers, we will focus on simplifying the disaster recovery process into a common set of recommendations. Additionally, we will work to resolve scalability problems with current backup solutions by supporting the cloud service integration capabilities of large high-usage GitLab instances.

However, we will quickly move into the next phase of the project, which will focus on the specialized needs of [GitLab Dedicated](https://about.gitlab.com/dedicated/). This will provide value to the Dedicated Group in terms of automating and streamlining backup creation and restoration with our standard dedicated architectures on Google and Amazon cloud services.

## Background

### Disaster Recovery

High-usage business-critical applications are vulnerable to a variety of potentially disastrous incidents. Bad actors may exploit security vulnerabilities to hold business data hostage in ransomware attacks. Software bugs may cause massive unexpected data corruption. Cloud providers may experience unexpected outages that inadvertently cause different types of application data to fall out of sync. This is why organizations that run important high-usage applications generally implement disaster recovery (DR) plans. DR plans allow restoring full operation of the target application regardless of whether there is a major failure or a significant mistake in day to day use.

A reliable application data backup is crucial to any disaster recovery plan. A backup captures the state of application data at a particular point in time so that it may be restored at a later time when performing disaster recovery. The captured data is usually stored as a set of one or more files kept in a location that is distinct from the machine where the application typically runs.

### System Administration and Maintenance Purposes

While DR is the primary motivation for creating tooling around backup creation and restoration, we also acknowledge that administrators of self-hosted installations often need to use backup and restoration for configuration and maintenance purposes. The administrator may need to upgrade versions of a crucial component of the system such as PostgreSQL or object storage appliance. In such cases, it is often best to take down their GitLab application temporarily to prevent further updates. Then, the admin may capture a point-in-time backup of their installation. The admin then performs the necessary changes to the system such as upgrading PostgreSQL to a more recent version. When complete, the captured backup data may be restored to ensure GitLab is close to the same state as it was in prior to the maintenance work. Finally, the site may be brought back online for general use again.

Alternatively, an admin may need to migrate their current GitLab production architecture to new infrastructure. For example, an organization may be running a simple GitLab 1K [reference architecture](../../../administration/reference_architectures) on a single machine the organization manages. However, over time, this organization has usage that has grown beyond the parameters of a simple 1K architecture, and now an admin has been charged with setting up a cloud-based 3K multi-node reference architecture hosted through Amazon Web Services (AWS). This is a common use case for backup and restoration tooling. The admin builds out their 3K deployment on AWS. Then, the admin takes a backup of the running 1K deployment. Finally, the admin restores the backup on the 3K architecture to ensure the organization can seamlessly switch from the small architecture to this new high-usage one.

In this last example, we are indicating how backup tools can facilitate customers to move their GitLab installations to different architectures. However, we need to discuss an important limitation for this use case. We only permit restoring a backup archive on the exact same version number of GitLab upon which the backup was created. We have seen many situations in the past where customers attempt to use GitLab backup tools to transfer their application data between different release versions of GitLab itself. As an example, a customer may have primarily used a version 15.10 installation without managing incremental releases updates over time. Now, the customer wants to jump to a much more recent version like 16.10. That customer may believe they can just use the Rake backup creation task to get a tarball of their older site data, setup a new location with the more recent version of GitLab, and then just use the Rake backup restoration task to populate the newer version installation with the same data. However, our current backup tooling does not support restorations on a different GitLab version than the one under which the backup was created.

Currently, we plan on making the new unified backup tool also uphold this restriction; backup restoration will only take place on the same version of GitLab that created the target backup archive. This is essential to make sure the database schema is exactly in line with what is expected by that version. Otherwise, there may be any degree of bugs and data corruptions that may occur when the code is programmed against a different data schema than what has been restored. We do intend to explore some degree of cross-version restoration support in later iterations of the project.

### Current GitLab Backup Offering

Currently GitLab provides recommendations for [how to create application backups](../../../administration/backup_restore/backup_gitlab.md) across different installation types and different hosting architectures. We provide a fairly rudimentary set of tools to create a point-in-time application backup, as well as specialized documentation for how to handle more complex cloud backup situations. You can read more on [how GitLab backups work here](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158058).

These are based on [Rake tasks](../../../raketasks) in the GitLab repository.

#### Drawbacks of the current approach

1. Current Backup Process Is Not Scalable
1. Backups Do Not Support Cloud-Provider Managed Services
1. Rake Tasks Are Not Suitably Maintainable
1. Invocation Differs Between Installation Types and Architectures: Depending on the installation type, the way you invoke the tasks changes. Depending on which reference architecture and whether it's an on-premise or cloud installation, the required option flags and configurations are different. This duplication and divergence makes the knowledge of running backups difficult to transfer between different installation types or different reference architectures.
1. Manual Restoration for Cloud Services: To leverage certain backup features of cloud providers, such as AWS Backup's continuous, point-in-time backup of object storage, you must currently configure it yourself. Even worse, you must also perform restoration manually. GitLab does not provide any tooling to help automate the process.

## Project Goals

With Unified Backups we have the following goals:

- Have a single codebase with all the required logic to backup and restore GitLab Installations
- Create the Unified Backup CLI tool that will:
  - Control backup and restore regardless of architecture or installation type
  - Have a simple interface with self-documented options
  - Have a configuration file where credentials and other stable parameters can be stored
  - Have an optional machine-readable outputs in JSON format
- Support two different Backup formats with a similar UX:
  - Portable Backup
    - Ideal for the smallest reference architectures, 1K and 2K
    - Should work for larger on-premise installations (but may become too slow until depending on nature and quantity of data)
    - Could also be used for cloud-based installations where no managed services is being used
  - Cloud-based Backup
    - Relies solely on the Cloud provider APIs and backup capabilities
    - Support for the major cloud providers like: AWS, GCP and Azure
    - It should not require significant disk-space or permanent storage on the machine/container executing it.
    - It should be simple to extend support for additional cloud providers.
- Support for the following installation types with a consistent UX:
  - Source
  - Linux Package (Omnibus)
  - Docker
  - Kubernetes

### Non-Goals

- This is not a solution for users to backup/export their GitLab.com group or project data
- The Unified Backup CLI will not handle lifecycle management:
  - It will not handle backup retention policies
  - It will not handle backup rotation
  - It will not handle backup scheduling
- The Unified Backup CLI will not accept ENV variables as way to:
  - Provide options
  - Provide configurations
  - Provide credentials
  - Override settings or configurations from dependent tools
- The Unified Backup CLI will not integrate Deployment / Infrastructure functionality:
  - It will not run GET or Terraform
  - It will not make any change to existing infrastructure
  - It will not deploy new infrastructure

## Design and implementation details

### Design Decisions

**A centralized codebase**

By centralizing the codebase into a single project, we aim to simplify the implementation for the permutations of environments and installation types we support. Having everything in a single location makes it easier to test and extend the code.

**Supporting multiple cloud providers**

Adding support to new cloud providers will follow an approach similar to the adapter pattern, where we have a generic business logic on how to backup each data-type, and a specialized version for each cloud provider.

**Installation type based configuration handling**

To support the differences in each installation type, a wrapper may be used which provides the tool with the necessary information about the environment it is running on.

**Differentiating between Portable and Cloud Backups**

The clear separation between Portable and Cloud backups aims at simplifying the implementation, and allows for specific strategies to be explored in the future to take consistent backups without downtime.

The main difference between the two is that Portable backups are stored locally. Both styles of backups allow mixed data storage, e.g. application data split between local and cloud storage.

**Consistency in backups**

Consistent backups can be taken during downtime.

Online Consistent Backups will be explored through [epic 12043](https://gitlab.com/groups/gitlab-org/-/epics/12043).

**On-going design discussions**

The results of the following on-going [technical design discussions](https://gitlab.com/groups/gitlab-org/-/epics/14081) will be added to the blueprint.

- [Investigate scaling backups](https://gitlab.com/gitlab-org/gitlab/-/issues/468677)
- [How to limit concurrency of backup processes?](https://gitlab.com/gitlab-org/gitlab/-/issues/468313)
- [How to restore a cloud backup with the `gitlab-backup-cli`?](https://gitlab.com/gitlab-org/gitlab/-/issues/465999)
- [Add how distribution will work with this tool](https://gitlab.com/gitlab-org/gitlab/-/issues/466040)
- [Investigate how to handle mixed Portable and Cloud backups](https://gitlab.com/gitlab-org/gitlab/-/issues/465529)
- [Investigate what is required to support Kubernetes and large reference architectures](https://gitlab.com/gitlab-org/gitlab/-/issues/427359)
- [Investigate how to support backing up Omnibus configuration and secrets](https://gitlab.com/gitlab-org/gitlab/-/issues/428515)
- [What infra provisioning is needed for each type of datatype being backed up in the cloud?](https://gitlab.com/gitlab-org/gitlab/-/issues/466038)
- [How to handle Redis data (not backed up)?](https://gitlab.com/gitlab-org/gitlab/-/issues/466000)
- [Investigate Gitaly improvements to Backup](https://gitlab.com/gitlab-org/gitlab/-/issues/465534)

### Limitations

- We don't support the data in a Cloud-based Backup to be exportable to a Portable Backup format or vice-versa.
- We do not support backing up data in the cache store (Redis) which includes the [Sidekiq state](../../../administration/backup_restore/backup_gitlab.md#other-data). TODO: [More research on Redis stored data](https://gitlab.com/gitlab-org/gitlab/-/issues/466000)

### Backup types

We provide two different approaches to create a Backup: Portable and Cloud-based.

#### Portable Backup

A Portable Backup behaves similar to the existing Rake-task approach. It relies on direct access to data-types and dependent services. It is the most compatible solution, as it does not rely on Cloud specific functionality.

A Portable Backup could be executed in all supported installation types and works on both physical and virtual machines.

With Portable Backup, the data is transferred to the machine running the backup context, stored and compressed in a specific location. A metadata file is created and the final archive can be stored locally or in a remote location (including in an Object Storage Bucket).

Each data type can be backed up in sequence or in parallel. Similarly, each one can be restored in sequence or in parallel.

Multiple Backups can be executed simultaneously, without one overwriting the other. (This is intended to support executing a backup from a cron job)

Backing up the database works the same, and require no additional configuration, no matter if using Omnibus-managed database, Patroni, an externally managed instance or whether PgBouncer is enabled.

[Future work](#future-iterations) will look into improving the consistency of Portable Backups without downtime, which may rely on using specific file-systems that can provide snapshotting capabilities.

Portable Backups have inherent limitations in scale, depending on the infrastructure, the data, and DR needs.

#### Cloud-based Backup

A Cloud-based Backup relies entirely on a Cloud Provider specific APIs and Services to perform and store the data. It is triggered by the CLI tool which orchestrates the required API calls.

Each time a Backup is started, a JSON file containing the necessary information (Backup Metadata) to find each data type is stored in the Backup Bucket, under the same prefix used to store existing Blobs.

The Backup Metadata will be used as the SSOT to specify what data is part of a Backup. In order to list or process a Backup, the tool will fetch the JSON files from the Backup Bucket. Based on the IDS and references stored there, the tool will be able to execute the restore-actions in the Cloud Provider API.

As we rely on the Backup Metadata, we primarily support listing and restoring data that was created by triggering the Unified Backup tool. This gives us the control and the foundation to build the necessary features and improvements for a Consistent Backup.

The tool will *not* rely on Cloud Provider specific scheduled backups functionality. To achieve regular scheduled backups, the tool will need to be invoked by an external service like a Cronjob.

Multiple backups may be supported to run simultaneously (unless there is a specific Cloud Provider limitation). A backup could include all supported data-types or specific ones only.

For each supported Cloud Provider, specific capabilities may be available, but we will support at least the following for each data-type:

- Databases:
  - On-Demand Database Backup or Snapshot
- Blobs in Object Storage
  - A copy of all Blobs in a new Backup Bucket
- Git repositories
  - A disk snapshot for all running Gitaly instances (Gitaly Cluster is not supported)

As Gitaly releases its planned new backup related functionality we will evaluate integrating them.

See [#future-iterations] for information regarding scheduling backups.

##### Google Cloud Platform

For GitLab installations hosted on Google Cloud Platform (GCP) we will support the following application data types
and their corresponding backup mechanism:

| Data Type               | GCP Service Component                | GCP backup mechanism                                            |
|-------------------------|--------------------------------------|-----------------------------------------------------------------|
| PostgreSQL Databases    | Cloud SQL for PostgreSQL             | On-demand database snapshots                                    |
| Blob/Files              | Cloud Storage (Object Storage)       | On-demand regional data transfer using Storage Transfer Service |
| Repositories            | Compute Engine with Persistent disks | On-demand disk snapshots                                        |

As we proceed with the implementation we will consider implementation details on how to use their APIs, including the differences between synchronous and asynchronous operations, support for Batching / Parallelization, Cloud Logging the use of Pub/Sub notifications, etc.

###### Cloud SQL for Postgres (Backup)

Cloud SQL supports the following methods to perform a Backup:

- [Automated (scheduled)](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups#automated-backups)
  - Can be scheduled to a specific starting time (execution happens with a 4 hour window)
  - [Retention of automated backups](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups#what_backups_cost):
    - **Cloud SQL Enterprise edition**: Minimum 7 units (usually days) max: 365 units
    - **Cloud SQL Enterprise Plus edition**: Minimum 15 units (usually days) max: 365 units
  - [Retention of WAL logs](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups#retention)
    - **Cloud SQL Enterprise edition**: From 1 to 7 days (default: 7 days)
    - **Cloud SQL Enterprise Plus edition**: From 1 to 35 days (default: 35 days)
    - WAL logs can be stored on disk in the same instance or in Cloud Storage
- [On-Demand Backups](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups)
  - Are not automatically deleted (can be stored for long time)

We will provide initial Backup support relying on On-Demand Backups to support long-term retention periods.

During the implementation phase we will investigate how to support and expose additional options like:

- Ability to choose a custom region to store Backups (default: same region as the instance)
- Ability to customize Automated Backup retention policy (normally managed by Terraform or as part of instance configuration)

###### Cloud SQL for Postgres (Restore)

Initial Restore support will be based on On-Demand Backups. We will rely on the IDs stored as part of the Backup Metadata file read from the Backup Bucket.

During the implementation phase we will investigate how to support and expose additional options like:

- Ability to use [Point In Time Recovery](https://cloud.google.com/sql/docs/postgres/backup-recovery/restore#tips-pitr) based on Automated Backups WAL logs (when in range)
- Restore Backup in a different instance then the current being used (we will not handle instance provisioning)
- How to expose the information necessary for data be restored as part of an external infrastructure integration (E.g. provide data for a Terraform script to create a new deployment)

###### Blobs

*Backup*

GCP backups currently use [the Storage Transfer Service](https://cloud.google.com/storage-transfer/docs/overview).
Storage Transfer Service jobs are created that copy from the individual buckets (Uploads, LFS, etc) to one bucket, under the path `/backups/$BACKUP_ID/$TARGET`.

*Restore*

- Restores should create Storage Transfer Service jobs that copy from the backup bucket path, to the individual buckets.
- We will not create or configure the buckets, that is out of scope for the tool.
- We (probably) should not empty the buckets first. Leave that up to the users to do if they want to.
- So at its most basic, a user would run something like `gitlab-backup-cli restore all $BACKUP_ID`, and the tool would create the necessary jobs to copy data from the backup bucket path, to the individual buckets, then monitor them for success/failure.

## Integrating with the Unified Backup CLI

In order to make the tool easy to integrate with external tools, we will provide optional machine-readable output in JSON format.

As an example, in order to restore from a disk snapshot, as the tool will not handle that operation itself, we will provide a command that can list the resources that should be restored in JSON format. That can be read by any external integration tool.

This type of interface is intended to decouple the Backup CLI from any other specific tool.

### Distribution

- Omnibus
- Kubernetes

We will work on Omnibus before Kubernetes for a quicker first iteration.

#### Impact

- Currently, the Distribution team owns and maintains [backup-utility](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitlab-toolbox/scripts/bin/backup-utility) which is used for backups in Kubernetes enabled environments. We will need to work with them to replace that tool, with `gitlab-backup-cli`
- For the [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab), it does create the `gitlab-backup` wrapper around the backup Rake tasks. Deprecation of the previous tool is TBD.
- The new tool (`gitlab-backup-cli`) will be distributed as part of the main GitLab codebase as one of the [bundled gems](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-backup-cli?ref_type=heads).
- In the future, the new tool will be decouple from that codebase and may be distributed independently from the main package, to allow for supporting backing up and restoring from distinct (compatible) GitLab versions.

#### Stable Counterpart

[Robert Marshall](https://gitlab.com/rmarshall)

### Dedicated/Cells Deployment

As we proceed with the implementation and initial releaess, we will work together with internal teams to ensure the tool provides the necessary machine-readable information necessary to integrate with their existing tools.

Specific to Kubernetes we will explore how to integrate with its native Cronjob functionality to provide scheduled executions.

# Milestones

## 1st Milestone: [Create backup cli: support 1K Linux package reference architecture with local storage](https://gitlab.com/groups/gitlab-org/-/epics/11635)

- Targeting Linux package installations
- Behaves similar to the existing backup Rake tool, with a small feature-set

## 2nd Milestone: [Implement Cloud Backups: support 10K CNH reference architectures on GCP](https://gitlab.com/groups/gitlab-org/-/epics/11911)

For the initial Cloud Backup implementation:

- Google Cloud Provider only (other Cloud Providers will be added at a later stage)
  - Database Backups using [Cloud SQL Backups](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups) (on demand backups only, initially)
  - Object Storage Backups using [Storage Transfer Service](https://cloud.google.com/storage-transfer-service?hl=en)
  - [GCE disk snapshots](https://cloud.google.com/compute/docs/disks/snapshots) initially for repository backups.
    - We will revisit [Gitaly server side backups](../../../administration/gitaly/configure_gitaly.md#configure-server-side-backups) with [WAL partition archives](https://gitlab.com/groups/gitlab-org/-/epics/13907) when the technology has matured.
- Only support data/snapshots managed by the Backup tool
- Not relying on automated/scheduled Backup implementation (like AWS Backup or Google Cloud Backup)

In this iteration, we are NOT aiming to solve backup consistency:

- When backing up the multiple components, what is in the database may point to something that was removed before it could have been included in the backup
- The Cloud Providers may not provide a reliable way to match each data to a specific point-in-time (that could be used to synchronize with the database snapshot)

## 3rd Milestone: [Extend support to 25+K reference architectures](https://gitlab.com/groups/gitlab-org/-/epics/12042)

TBD

## Future iterations

Investigate integration with continuous database backup (WAL log based) with a rollback to point-in-time as a Restore mechanism. Each cloud provide may implement this in different ways, with different retention policies.

We haven't planned yet any integration with AWS Backup or equivalent, but this is something we will revisit in the future.

Improvements to the Portable Backup:

- [Scalable Database solution](https://gitlab.com/gitlab-org/gitlab/-/issues/458382)
- [Encryption at Rest (relying on .7z format)](https://gitlab.com/gitlab-org/gitlab/-/issues/470570)
- [File-system snapshot support](https://gitlab.com/gitlab-org/gitlab/-/issues/428520)
- Integrated GitLab configuration files and on-disk secrets in separate backup archive

Backup Management solution, that will be composed of:

- A Web UI (decoupled from the main application)
- A REST API to control and manage Backup/Restore related operations
- Observability over Disaster Recovery operation
- Additional Service Orchestration (possible integration with GET)
- Backup Lifecycle management (as e.g.):
  - Backup retention policies
  - Backup execution policies
  - Optional granularity for different types of data
  - Notifications
- Support for both Portable and Cloud-Based backups
