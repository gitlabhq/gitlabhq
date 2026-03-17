---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Recovery objectives, failover process, and regional backup strategies for GitLab Dedicated instances.
title: Disaster recovery for GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated provides automatic disaster recovery to restore your instance if your primary
region becomes unavailable. To be eligible for the full recovery objectives:

- Configure a primary and secondary region when you [create your instance](create_instance/_index.md).
- Select regions [supported by GitLab Dedicated](create_instance/data_residency_high_availability.md#supported-regions).

If no secondary region is configured, recovery is limited to backup restoration.

## Recovery objectives

GitLab Dedicated provides disaster recovery with these recovery objectives:

- Recovery Time Objective (RTO): Service is restored to your secondary region in eight hours
  or less.
- Recovery Point Objective (RPO): Data loss is limited to a maximum of four hours of the most
  recent changes, depending on when the disaster occurs relative to the last backup.

## Geo replication

When you create your instance, you select a primary region and a secondary region for
your environment. Geo continuously replicates data between these regions, including:

- Database content
- Repository storage
- Object storage

## Automated backups

GitLab performs automated backups of all GitLab Dedicated datastores
(including databases and Git repositories) every four hours (six times daily) by creating
snapshots.

Backups are tested, retained for 30 days, and stored in your chosen secondary region.
They are also geographically replicated by AWS for additional protection.

Database backups:

- Use continuous log-based backups in the primary region for point-in-time recovery.
- Stream replication to the secondary region to provide a near-real-time copy.

Object storage backups use geographical replication and versioning to provide backup
protection.

The four-hour backup frequency supports the Recovery Point Objective (RPO) to ensure
you lose no more than four hours of data.

## Disaster coverage

Disaster recovery covers these scenarios with guaranteed recovery objectives:

- Partial region outage (for example, availability zone failure)
- Complete outage of your primary region

These scenarios are covered on a best-effort basis without guaranteed recovery objectives:

- Loss of both primary and secondary regions
- Global internet outages
- Data corruption issues

## Service limitations

Disaster recovery has these service limitations:

- Advanced search indexes are not continuously replicated.
  After failover, these indexes are rebuilt when the secondary region is promoted.
  Basic search remains available during rebuilding.
- ClickHouse Cloud is provisioned only in the primary region.
  Features that require this service might be unavailable if the primary region is completely
  down.
- Production preview environments do not have secondary instances.
- Hosted runners are supported only in the primary region and cannot be rebuilt in the
  secondary instance.
- Some regions have limited feature availability due to AWS service constraints. For more
  information, see [supported regions](create_instance/data_residency_high_availability.md#supported-regions).
  These feature limitations do not affect disaster recovery capabilities or RTO and RPO targets.

GitLab does not provide:

- Programmatic monitoring of failover events
- Customer-initiated disaster recovery testing

## Failover process

When your instance becomes unavailable due to a complete region failure or critical component
failure that cannot be quickly recovered, the GitLab Dedicated team:

1. Gets alerted by monitoring systems.
1. Investigates if failover is required.
1. If failover is required:
   1. Notifies you that failover is in progress.
   1. Promotes the secondary region to primary.
   1. Updates DNS records for `<customer>.gitlab-dedicated.com` to point to the newly
      promoted region.
   1. Notifies you when failover completes.

If you use PrivateLink, you must update your internal networking configuration to target the
PrivateLink endpoint for the secondary region. To minimize downtime, configure equivalent
PrivateLink endpoints in your secondary region before a disaster occurs.

The failover process typically completes in 90 minutes or less. Throughout the process,
GitLab communicates with you through one or more of:

- Your operational contact information in Switchboard
- Slack
- Support tickets

GitLab may establish a temporary Slack channel and Zoom bridge to coordinate with your team
throughout the recovery process.

## Related topics

- [Data residency and high availability](create_instance/data_residency_high_availability.md)
- [GitLab Dedicated architecture](architecture.md)
