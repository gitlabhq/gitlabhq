---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 18 upgrade notes
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This page contains upgrade information for minor and patch versions of GitLab 18.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For additional information for Helm chart installations, see
[the Helm chart 9.0 upgrade notes](https://docs.gitlab.com/charts/releases/9_0/).

## Required upgrade stops

To provide a predictable upgrade schedule for instance administrators,
required upgrade stops occur at versions:

- `18.2`
- `18.5`
- `18.8`
- `18.11`

## Issues to be aware of when upgrading from 17.11

- [PostgreSQL 14 is not supported starting from GitLab 18](../deprecations.md#postgresql-14-and-15-no-longer-supported).
  Upgrade PostgreSQL to at least version 16.5 before upgrading to GitLab 18.0 or later. For more information, see
  [installation requirements](../../install/requirements.md#postgresql).

  > [!warning]
  > Automatic database version upgrades only apply to single node instances when using the Linux package.
  > In all other cases, like Geo instances, PostgreSQL with high availability using the
  > Linux package, or using an external PostgreSQL database (like Amazon RDS), you must upgrade PostgreSQL manually. See [upgrading a Geo instance](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-geo-instance) for detailed steps.

- From September 29th, 2025 Bitnami will stop providing tagged PostgreSQL and Redis images. If you deploy GitLab 17.11 or earlier using the
  GitLab chart with bundled Redis or Postgres, you must manually update your values to use the legacy repository to prevent unexpected
  downtime. For more information, see [issue 6089](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6089).

- **Known issue:** The feature flag `ci_only_one_persistent_ref_creation` causes pipeline failures during zero-downtime upgrades when Rails is upgraded but Sidekiq remains on version 17.11 (see details in [issue 558808](https://gitlab.com/gitlab-org/gitlab/-/issues/558808)).

  **Prevention:** Open the Rails console and enable the feature flag before upgrading:

  ```shell
  $ sudo gitlab-rails console
  Feature.enable(:ci_only_one_persistent_ref_creation)
  ```

  **If already affected:** Run this command and retry the failed pipelines:

  ```shell
  $ sudo gitlab-rails console
  Rails.cache.delete_matched("pipeline:*:create_persistent_ref_service")
  ```

## 18.8.2

### Deploy keys and personal access tokens for blocked users are invalidated

GitLab 18.8.2, 18.7.2, and 18.6.4 now reject API requests that use Deploy keys associated with blocked users.
If you have deploy keys associated with blocked users, these no longer work after upgrading to the aforementioned versions.
This is a security fix to prevent blocked users from accessing GitLab resources through their keys and tokens.

You must:

1. Identify any deploy keys or PATs owned by blocked users.
1. Reassign them to billable users, or delete them and
   create new keys/tokens with billable users or service accounts.

The following query can be used to identify all deploy keys associated with blocked accounts and have been used at least once in the past 365 days:

```sql
SELECT
  k.id,
  k.user_id,
  u.username,
  u.state as user_state,
  k.title,
  k.fingerprint,
  k.fingerprint_sha256,
  k.usage_type,
  k.last_used_at,
  k.created_at,
  k.updated_at
FROM keys k
INNER JOIN users u ON k.user_id = u.id
WHERE u.state IN ('blocked', 'ldap_blocked', 'blocked_pending_approval', 'banned')
  AND k.type = 'DeployKey'
  AND k.last_used_at >= NOW() - INTERVAL '365 days'
ORDER BY u.state, u.username, k.last_used_at DESC;
```

## 18.8.0

### Batched background migration for merge request merge data

A [batched background migration](../background_migrations.md) copies merge request merge-related
data from the `merge_requests` table to a new dedicated `merge_requests_merge_data` table.

This migration is part of a database schema optimization initiative to normalize merge-specific
attributes into a separate table, improving query performance and maintainability.

For more details about what data is migrated and how to estimate migration duration, see
[Merge request merge data migration details](#merge-request-merge-data-migration-details).

### ClickHouse dictionary creation error

GitLab Self-Managed customers with [ClickHouse integration](../../integration/clickhouse.md) enabled might
encounter a ClickHouse database migration error during the upgrade process due to a missing
permission (`DB::Exception: gitlab: Not enough privileges`). To resolve this error, see the
[database dictionary read support troubleshooting documentation](../../integration/clickhouse.md#database-dictionary-read-support).

### Batched background migration for CI data

The [batched background migrations](../background_migrations.md) introduced in [18.7.0](#1870) had
to be reintroduced to handle an edge case in the data structure and ensure that they would complete.

## 18.7.2

GitLab 18.8.2, 18.7.2, and 18.6.4 now reject API requests that use Deploy keys associated with blocked users.
For more information, see [Deploy keys and personal access tokens for blocked users are invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-are-invalidated).

## 18.7.0

- A [post deployment migration](../../development/database/post_deployment_migrations.md)
  schedules batched [background migrations](../background_migrations.md) to copy CI builds metadata
  to new optimized tables (`p_ci_job_definitions`). This migration is part of an initiative to
  ultimately reduce CI database size (see [epic 13886](https://gitlab.com/groups/gitlab-org/-/epics/13886)).
  If you have an instance with millions of jobs and want to speed up the migration,
  you can [select what data is migrated](#ci-builds-metadata-migration-details).

### Geo installations 18.7.0

- Added a new `action_cable_allowed_origins` setting to configure allowed origins for ActionCable websocket requests.
  Specify the allowed URLs when configuring the primary site to ensure proper cross-site WebSocket connectivity:

  - [Geo documentation for the Linux package](../../administration/geo/replication/configuration.md#add-primary-and-secondary-urls-as-allowed-actioncable-origins)
  - [Geo documentation for the Helm chart](https://docs.gitlab.com/charts/advanced/geo/#configure-primary-database)

### Geo installations 18.6.5

- Fixed the Geo [issue 587407](https://gitlab.com/gitlab-org/gitlab/-/work_items/587407) where `Geo::VerificationStateBackfillWorker` generated large slow queries for the `merge_request_diff_details` table.

## 18.6.4

GitLab 18.8.2, 18.7.2, and 18.6.4 now reject API requests that use Deploy keys associated with blocked users.
For more information, see [Deploy keys and personal access tokens for blocked users are invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-are-invalidated).

## 18.6.2

GitLab 18.6.2, 18.5.4, and 18.4.6 introduced size and rate limits on requests made to the following endpoints:

- `POST /projects/:id/repository/commits` - [Create a commit](../../api/commits.md#create-a-commit)
- `POST /projects/:id/repository/files/:file_path` - [Create a file in a repository](../../api/repository_files.md#create-a-file-in-a-repository)
- `PUT /projects/:id/repository/files/:file_path` - [Update a file in a repository](../../api/repository_files.md#update-a-file-in-a-repository)

GitLab responds to requests that exceed the size limit with a `413 Entity Too large` status, and requests that exceed the rate limit with a `429 Too Many Requests` status. For more information, see [Commits and Files API limits](../../administration/instance_limits.md#commits-and-files-api-limits)

### Duo Agent Platform

- Some [runner restrictions](../../user/duo_agent_platform/flows/execution.md#configure-runners)
  have been introduced relating to which runners can be used with Duo Agent Platform.

## Geo installations 18.5.2

- The missing Geo [migration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210512) that prevents Geo log cursor on the secondary site to start is fixed.

## 18.5.0

- A [post deployment migration](../../development/database/post_deployment_migrations.md)
  `20250922202128_finalize_correct_design_management_designs_backfill` finalizes a
  batched [background migration](../background_migrations.md) that was scheduled in 18.4.
  If you skipped 18.4 in the upgrade path, the migration is fully executed when
  post deployment migrations are run.
  Execution time is directly related to the size of your `design_management_designs` table.
  For most instances the migration should not take longer than 2 minutes, but for some larger instances,
  it could take up to 10 minutes.
  Please be patient and don't interrupt the migration process.

- NGINX routing changes introduced in GitLab 18.5.0 can cause services to become inaccessible when using non-matching hostnames such as `localhost` or alternative domain names.
  This issue causes:

  - Health check endpoints such as `/-/health` to return `404` errors instead of proper responses.
  - GitLab web interface showing `404` error pages when accessed with hostnames other than the configured FQDN.
  - GitLab Pages potentially receiving traffic intended for other services.
  - Problems with any requests using alternative hostnames that previously worked.

  This issue is resolved in the Linux package by [merge request 8805](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8805), and the fix will be
  available in GitLab 18.5.2 and 18.6.0.

  Git operations such clone, push, and pull are unaffected by this issue.

## Geo installations 18.4.4

- The missing Geo [migration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210512) that prevents Geo log cursor on the secondary site to start is fixed.

## 18.4.2

- Upgrades to `18.4.2` or `18.4.3` might fail with a `no implicit conversion of nil into String` error for these batched background migrations:
  - `FixIncompleteInstanceExternalAuditDestinations`
  - `FinalizeAuditEventDestinationMigrations`

  To resolve this issue, upgrade to the latest patch release or use the [workaround in issue 578938](https://gitlab.com/gitlab-org/gitlab/-/issues/578938#workaround).

### Geo installations 18.4.2

- The Geo [bug](https://gitlab.com/gitlab-org/gitlab/-/issues/571455) that causes replication events to fail with the error message `no implicit conversion of String into
  Array (TypeError)` is fixed.

## 18.4.1

GitLab 18.4.1, 18.3.3, and 18.2.7 introduced limits on JSON inputs to prevent denial of service attacks.
GitLab responds to HTTP requests that exceed these limits with a `400 Bad Request` status.
For more information, see [HTTP request limits](../../administration/instance_limits.md#http-request-limits).

## 18.4.0

- In secondary Geo sites, [a bug](https://gitlab.com/gitlab-org/gitlab/-/issues/571455) causes replication events to fail with the error message `no implicit conversion of String into Array (TypeError)`. Redundancies such as re-verification ensure eventual consistency, but RPO is significantly increased. Versions affected: 18.4.0 and 18.4.1.

## 18.3.0

### GitLab Duo

- A new worker `LdapAddOnSeatSyncWorker` was introduced, which could unintentionally remove all users from
  GitLab Duo seats nightly when LDAP is enabled. This was fixed in GitLab 18.4.0 and 18.3.2. See
  [issue 565064](https://gitlab.com/gitlab-org/gitlab/-/issues/565064) for details.

### Geo installations 18.3.0

- The [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/545533) that caused `rake gitlab:geo:check` to incorrectly report a failure when installing a Geo secondary site has been fixed in 18.3.0.
- GitLab 18.3.0 includes a fix for [issue 559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196) where Geo verification could fail for Pages deployments with long filenames. The fix prevents filename trimming on Geo secondary sites to maintain consistency during replication and verification.

## 18.2.0

### Zero-downtime upgrades

- Upgrades between 18.1.x and 18.2.x are affected by [known issue 567543](https://gitlab.com/gitlab-org/gitlab/-/issues/567543),
  which causes errors with pushing code to existing projects during an upgrade. To ensure no downtime during the
  upgrade between versions 18.1.x and 18.2.x, upgrade directly to version 18.2.6, which includes a fix.

### Geo installations 18.2.0

- This version has a known issue that happens when `VerificationStateBackfillService` runs due to changes in the primary key of `ci_job_artifact_states`. To resolve, upgrade to GitLab 18.2.2 or later.
- GitLab 18.2.0 includes a fix for [issue 559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196) where Geo verification could fail for Pages deployments with long filenames. The fix prevents filename trimming on Geo secondary sites to maintain consistency during replication and verification.

## 18.1.0

- Elasticsearch indexing might fail with `strict_dynamic_mapping_exception` errors for Elasticsearch version 7. To resolve, see the "Possible fixes" section in [issue 566413](https://gitlab.com/gitlab-org/gitlab/-/issues/566413).
- GitLab versions 18.1.0 and 18.1.1 show errors in PostgreSQL logs such as `ERROR:  relation "ci_job_artifacts" does not exist at ...`.
  These errors in the logs can be safely ignored but could trigger monitoring alerts, including on Geo sites. To resolve this issue, update to GitLab 18.1.2 or later.

### Geo installations 18.1.0

- GitLab version 18.1.0 has a known issue where Git operations that are proxied from a secondary Geo site fail with HTTP 500 errors. To resolve, upgrade to GitLab 18.1.1 or later.
- This version has a known issue that happens when `VerificationStateBackfillService` runs due to changes in the primary key of `ci_job_artifact_states`. To resolve, upgrade to GitLab 18.1.4.
- GitLab 18.1.0 includes a fix for [issue 559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196) where Geo verification could fail for Pages deployments with long filenames. The fix prevents filename trimming on Geo secondary sites to maintain consistency during replication and verification.

## 18.0.0

### Migrate Gitaly configuration from `git_data_dirs` to `storage`

In GitLab 18.0 and later, you can no longer use the `git_data_dirs` setting to configure Gitaly storage locations.

If you are still using `git_data_dirs`, you must
[migrate your Gitaly configuration](https://docs.gitlab.com/omnibus/settings/configuration/#migrating-from-git_data_dirs) before upgrading to GitLab 18.0.

### Geo installations 18.0.0

- If you deployed GitLab Enterprise Edition and then reverted to GitLab Community Edition,
  your database schema may deviate from the schema that the GitLab application expects,
  leading to migration errors. Four particular errors can be encountered on upgrade to 18.0.0
  because a migration was added in that version which changes the defaults of those columns.

  The errors are:

  - `No such column: geo_nodes.verification_max_capacity`
  - `No such column: geo_nodes.minimum_reverification_interval`
  - `No such column: geo_nodes.repos_max_capacity`
  - `No such column: geo_nodes.container_repositories_max_capacity`

  This migration was patched in GitLab 18.0.2 to add those columns if they are missing.
  See [issue #543146](https://gitlab.com/gitlab-org/gitlab/-/issues/543146).

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 18.0                    |  18.0.0 - 18.0.1        | 18.0.2   |

- GitLab versions 18.0 through 18.0.2 have a known issue where Git operations that are proxied from a secondary Geo site fail with HTTP 500 errors. To resolve, upgrade to GitLab 18.0.3 or later.
- This version has a known issue that happens when `VerificationStateBackfillService` runs due to changes in the primary key of `ci_job_artifact_states`. To resolve, upgrade to GitLab 18.0.6.

### PRNG is not seeded error on Docker installations

If you run GitLab on a Docker installation with a FIPS-enabled host, you
may see that SSH key generation or the OpenSSH server (`sshd`) fails to
start with the error message:

```plaintext
PRNG is not seeded
```

GitLab 18.0 [updated the base image from Ubuntu 22.04 to 24.04](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8928).
This error occurs because Ubuntu 24.04 no longer [allows a FIPS host to use a non-FIPS OpenSSL provider](https://github.com/dotnet/dotnet-docker/issues/5849#issuecomment-2324943811).

To fix this issue, you have a few options:

- Disable FIPS on the host system.
- Disable the auto-detection of a FIPS-based kernel in the GitLab Docker container.
  This can be done by setting the `OPENSSL_FORCE_FIPS_MODE=0` environment variable with GitLab 18.0.2 or higher.
- Instead of using the GitLab Docker image, install a [native FIPS package](https://packages.gitlab.com/gitlab/gitlab-fips) on the host.

The last option is the recommended one to meet FIPS requirements. For
legacy installations, the first two options can be used as a stopgap.

## CI builds metadata migration details

> [!note]
> Since GitLab 18.6, new pipelines write data exclusively to the new format
> (see [issue 552065](https://gitlab.com/gitlab-org/gitlab/-/issues/552065)).
> This migration only copies existing data from the old format to the new one.
> No data is deleted.

Data not migrated will be removed in a future release (see [epic 18271](https://gitlab.com/groups/gitlab-org/-/epics/18271)).

The migration duration is directly proportional to the total number of CI jobs in your instance.
Jobs are processed from newest to oldest partitions to prioritize recent data.

You can reduce the number of jobs to migrate by enabling
[automatic pipeline cleanup](../../ci/pipelines/settings.md#automatic-pipeline-cleanup)
on larger projects to delete old pipelines before upgrading.

The migration copies two types of data:

- **Jobs processing data**: Job execution configuration from `.gitlab-ci.yml` (such as `script`, `variables`)
  needed only for runners when executing jobs, not for the UI or API.
- **Job data visible to users**: of all the job data, this migration only impacts job timeout value,
  job exit code values, [exposed artifacts](../../ci/jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui),
  and [environment associations](../../ci/yaml/_index.md#environment).

For GitLab Self-Managed and GitLab Dedicated instances with large CI datasets, you can speed up the migration by
reducing the scope of data to migrate. To control the scope use the settings defined below.

### Controlling the scope for jobs processing data

By default, the migration copies processing data for all existing jobs.
You can cut down the scope by using one of the settings described below.

The value of the setting controls how much of jobs processing data you want to retain.
For example, set it to `6mo` if you only expect jobs created in the last 6 months to be executed
(through [retries](../../ci/jobs/_index.md#retry-jobs),
[execution of manual jobs](../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually),
[environment auto-stop](../../ci/environments/_index.md#stopping-an-environment)).

GitLab looks for the setting in order of precedence:

1. [Pipeline archival](../../administration/settings/continuous_integration.md#archive-pipelines) setting (recommended best practice).
   Archived pipelines signal that jobs cannot be manually retried or re-run.
   If this setting is enabled, processing data for archived jobs don't need to be migrated.

   > [!note]
   > If the pipeline archival range is later extended,
   > jobs without processing data will remain unexecutable.

1. `GITLAB_DB_CI_JOBS_PROCESSING_DATA_CUTOFF` [environment variable](../../administration/environment_variables.md),
   if pipeline archival is not configured or needs to be overridden for this migration. It accepts duration strings
   like `1y` (1 year), `6mo` (6 months), `90d` (90 days).
1. `GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF` environment variable, if neither of the above is set. It accepts duration
   strings like `1y` (1 year), `6mo` (6 months), `90d` (90 days).
   See [Controlling the scope for job data visible to users](#controlling-the-scope-for-job-data-visible-to-users).
1. All data is copied if no configuration is found.

### Controlling the scope for job data visible to users

The environment variable `GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF` controls which jobs will have
their visible data migrated.

For example, `GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF=1y` copies affected visible data
(timeout value, environment, exit codes, and metadata for exposed artifacts)
for jobs from the most recent year.

By default, there is no cutoff date and data for all jobs is migrated.

### Estimating migration impact

For reference, for GitLab.com we expect to migrate 400 million rows in about 2 months.

To estimate the migration impact on your instance, you can run the following queries
in the [PostgreSQL console](../../administration/troubleshooting/postgresql.md#start-a-database-console):

{{< tabs >}}

{{< tab title="Table size" >}}

```sql
SELECT n.nspname AS schema_name, c.relname AS partition_name,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM pg_inherits i
JOIN pg_class c ON c.oid = i.inhrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_class p ON p.oid = i.inhparent
WHERE p.relname = 'p_ci_builds_metadata'
ORDER BY pg_total_relation_size(c.oid) DESC;
```

The new tables require approximately 20% of this space.

{{< /tab >}}

{{< tab title="Job count estimate" >}}

This is an estimate from the PostgreSQL statistics table.

```sql
SELECT SUM(c.reltuples)::bigint AS estimated_jobs_count
FROM pg_class c
JOIN pg_inherits i ON c.oid = i.inhrelid
WHERE i.inhparent = 'p_ci_builds'::regclass;
```

{{< /tab >}}

{{< tab title="Jobs by timeframe" >}}

To find the number of jobs created in a specific time frame, we need to query the tables:

```sql
SELECT COUNT(*) FROM p_ci_builds WHERE created_at >= now() - '1 year'::interval;
```

If the query times out, use the [Rails console](../../administration/operations/rails_console.md)
to batch over the data:

```ruby
counts = []
CommitStatus.each_batch(of: 25000) do |batch|
  counts << batch.where(created_at: 1.year.ago...).count
end
counts.sum
```

{{< /tab >}}

{{< /tabs >}}

## Merge request merge data migration details

### What data is migrated

The migration copies the following columns from `merge_requests` to `merge_requests_merge_data`:

- `merge_commit_sha`
- `merged_commit_sha`
- `merge_ref_sha`
- `squash_commit_sha`
- `in_progress_merge_commit_sha`
- `merge_status`
- `auto_merge_enabled`
- `squash`
- `merge_user_id`
- `merge_params`
- `merge_error`
- `merge_jid`

The migration processes the `merge_requests` table, copying data only for merge requests that don't
already have corresponding entries in `merge_requests_merge_data`.

Since GitLab 18.7, new merge requests write data to both tables through dual-write
mechanisms at the application level (see [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/560933)).
This migration only copies existing data that has not been created or touched after the dual-write was implemented.

No data is deleted from the `merge_requests` table during this migration.

The migration is planned to be finalized in GitLab 18.9. For more information, see
[issue](https://gitlab.com/gitlab-org/gitlab/-/issues/584459).

### Estimating migration duration

The migration duration is directly proportional to the number of merge requests in your instance.

To estimate the impact:

**PostgreSQL query:**

```sql
-- Count total merge requests
SELECT COUNT(*) FROM merge_requests;

-- Estimate table size
SELECT pg_size_pretty(pg_total_relation_size('merge_requests')) AS table_size;
```

**Rails console:**

```ruby
# Count total merge requests
MergeRequest.count

# Count remaining merge requests to migrate
MergeRequest.left_joins(:merge_data)
  .where(merge_requests_merge_data: { merge_request_id: nil })
  .count
```

The migration processes merge requests in batches and should complete within hours to days for most instances.
