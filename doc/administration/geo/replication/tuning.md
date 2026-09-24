---
stage: GitLab Dedicated
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Tuning Geo
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can limit the number of concurrent operations the sites can run
in the background.

## Changing the sync/verification concurrency values

On the primary site:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Geo** > **Sites**.
1. Select **Edit** of the secondary site you want to tune.
1. Under **Tuning settings**, there are several variables that can be tuned to
   improve the performance of Geo:

   - Repository synchronization concurrency limit
   - File synchronization concurrency limit
   - Container repositories synchronization concurrency limit
   - Verification concurrency limit

Increasing the concurrency values increases the number of jobs that are scheduled.
However, this may not lead to more downloads in parallel unless the number of
available Sidekiq threads is also increased. For example, if repository synchronization
concurrency is increased from 25 to 50, you may also want to increase the number
of Sidekiq threads from 25 to 50. See the
[Sidekiq concurrency documentation](../../sidekiq/extra_sidekiq_processes.md#concurrency)
for more details.

> [!note]
> The **Verification concurrency limit** is a single global limit on the total number of
> verification jobs that run concurrently on a site, across all data types combined. The
> effective concurrency equals the value you configure.
>
> In GitLab 19.2 and earlier, GitLab divided the configured value by the number of data
> types before applying it, so the effective concurrency was lower than the value you set.
> When you upgrade to GitLab 19.3, GitLab rescales each site's stored value so the effective
> concurrency stays roughly the same as before the upgrade. As a result, the stored value
> might be lower after upgrading. Review and re-tune it as needed.

## Tuning low default settings

To avoid excessive load when setting up new Geo sites, starting with GitLab 18.0,
Geo's concurrency settings are set to low defaults for most environments.
To increase these settings:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Geo** > **Sites**.
1. Decide which data types are progressing too slowly.
1. Watch load metrics of the primary and secondary sites.
1. Increase concurrency limits by 10 to be conservative.
1. Watch changes in progress and load metrics for at least 3 minutes.
1. Repeat increasing the limits until either load metrics reach your desired maximum, or syncing and verification is progressing as quickly as desired.

## Reduce the amount of replicated data

Every file retained on the primary site must be stored, synced, and verified on
every secondary site, and counted by Geo metrics collection. Deleting data that
provides no value is often more effective than increasing concurrency, and it
also shortens the initial sync when you add or rebuild a secondary site.

CI/CD job artifacts are usually the largest contributor. To reduce their volume:

- Make sure artifacts expire. Artifacts are deleted automatically after the
  [default artifacts expiration](../../settings/continuous_integration.md#set-default-artifacts-expiration)
  (30 days by default), or after the duration set per job with
  [`artifacts:expire_in`](../../../ci/yaml/_index.md#artifactsexpire_in).
  When an artifact expires, GitLab permanently deletes the file and its database
  records, and publishes Geo delete events so that each secondary site removes
  its synced copy and its registry entry. Smaller tables directly reduce sync,
  verification, and
  [Geo metrics collection](troubleshooting/common.md#excessive-database-io-from-geo-metrics-collection)
  load.
- Review the
  [Keep artifacts from latest successful pipelines setting](../../settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines).
  When enabled, artifacts of the most recent successful pipeline for each Git
  ref never expire. On instances with many active branches and tags, this
  setting can retain a large number of artifacts indefinitely.
- Clean up artifacts that have no expiry. Artifacts created before an expiry
  policy was in place have no expiration date and are never deleted by the
  expiry workers. To find and remove them, see
  [list projects and builds with artifacts with a specific expiration (or no expiration)](../../cicd/job_artifacts_troubleshooting.md#list-projects-and-builds-with-artifacts-with-a-specific-expiration-or-no-expiration)
  and
  [delete old builds and artifacts](../../cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts).
  To remove artifact files left on disk without database records, use the
  [orphan artifact file cleanup Rake task](../../raketasks/cleanup.md#remove-orphan-artifact-files).

The same principle applies to other replicated data types, such as LFS objects
and package files. For container registry images, use
[cleanup policies](../../../user/packages/container_registry/reduce_container_registry_storage.md#cleanup-policy).

## Repository re-verification

See
[Automatic background verification](../disaster_recovery/background_verification.md).
