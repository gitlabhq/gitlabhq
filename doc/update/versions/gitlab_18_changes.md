---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Review the GitLab 18 upgrade notes.
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

## Upgrade notes reference

The following is a reference list of upgrade notes for each minor GitLab version.
Each list item points to a specific section that holds more information.

Items marked with an installation method, like `(Geo)` or `(Linux package)`,
apply only to that method. All other items apply to all installation methods.

### Upgrade to 18.11

Before upgrading to GitLab 18.11, review the following:

- [18.11.0 - 18.11.2] - [Geo blob sync failures with `log_error` NoMethodError on file storage](#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage) (Geo)
- [18.11.0 - 18.11.1] - [CI job token regression pulling container images from internal and public projects](#ci-job-token-regression-pulling-container-images-from-internal-and-public-projects)
- [18.11.0] - [Upgrading to 18.11 triggers a PostgreSQL 17.7 version upgrade](#postgresql-version-177-upgrade-on-gitlab-1811) (Linux package, Docker, Geo)
- [18.11.0] - [Mattermost and Spamcheck removed from SLES 12.5 packages](#mattermost-and-spamcheck-removed-from-sles-125-packages) (Linux package)

### Upgrade to 18.10

Before upgrading to GitLab 18.10, review the following:

- [18.10.0 - 18.10.3] - [SLES 12.5 RPM package installation failure](#sles-125-rpm-package-installation-failure) (Linux package)
- [18.10.0 - 18.10.5] - [Geo blob sync failures with `log_error` NoMethodError on file storage](#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage) (Geo)
- [18.10.0 - 18.10.3] - [Geo site URL blocked when using outbound filtering](#geo-site-url-blocked-when-using-outbound-filtering) (Geo)
- [18.10.0 - 18.10.4] - [Geo blob download failures](#geo-blob-download-failures) (Geo)
- [18.10.0 - 18.10.3] - [Geo secondary throttled jobs not draining](#geo-secondary-throttled-jobs-not-draining) (Geo)
- [18.10.0 - 18.10.3] - [Sidekiq concurrency limiter causes job backlogs on Helm chart and Operator deployments](#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments) (Helm chart, Operator)

### Upgrade to 18.9

Before upgrading to GitLab 18.9, review the following:

- [18.9.1 - 18.9.5] - [SLES 12.5 RPM package installation failure](#sles-125-rpm-package-installation-failure) (Linux package)
- [18.9.0 - 18.9.5] - [Geo site URL blocked when using outbound filtering](#geo-site-url-blocked-when-using-outbound-filtering) (Geo)
- [18.9.0 - 18.9.5] - [Geo secondary throttled jobs not draining](#geo-secondary-throttled-jobs-not-draining) (Geo)
- [18.9.0 - 18.9.5] - [Sidekiq concurrency limiter causes job backlogs on Helm chart and Operator deployments](#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments) (Helm chart, Operator)
- [18.9.0] - [Upgrade to 18.9 fails with PostgreSQL CheckViolation](#upgrade-to-189-fails-with-postgresql-checkviolation)

### Upgrade to 18.8

Before upgrading to GitLab 18.8, review the following:

- [18.8.2] - [Deploy keys and personal access tokens for blocked users invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.8.0] - [Batched background migration for merge request merge data](#batched-background-migration-for-merge-request-merge-data)
- [18.8.0] - [ClickHouse dictionary creation error](#clickhouse-dictionary-creation-error)
- [18.8.0] - [Batched background migration for CI data reintroduced](#batched-background-migration-for-ci-data-reintroduced)

### Upgrade to 18.7

Before upgrading to GitLab 18.7, review the following:

- [18.7.2] - [Deploy keys and personal access tokens for blocked users invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.7.0] - [CI builds metadata migration](#ci-builds-metadata-migration)
- [18.7.0] - [Geo ActionCable allowed origins setting](#geo-actioncable-allowed-origins-setting) (Geo)

### Upgrade to 18.6

Before upgrading to GitLab 18.6, review the following:

- [18.6.5] - [Geo VerificationStateBackfillWorker slow queries fix](#geo-verificationstatebackfillworker-slow-queries-fix) (Geo)
- [18.6.4] - [Deploy keys and personal access tokens for blocked users invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.6.2] - [Commits and Files API size and rate limits](#commits-and-files-api-size-and-rate-limits)
- [18.6.2] - [Duo Agent Platform runner restrictions](#duo-agent-platform-runner-restrictions)

### Upgrade to 18.5

Before upgrading to GitLab 18.5, review the following:

- [18.5.4] - [Commits and Files API size and rate limits](#commits-and-files-api-size-and-rate-limits)
- [18.5.0 - 18.5.1] - [Geo log cursor migration fix](#geo-log-cursor-migration-fix) (Geo)
- [18.5.0] - [Finalize design management designs backfill](#finalize-design-management-designs-backfill)
- [18.5.0] - [NGINX routing changes cause 404 errors](#nginx-routing-changes-cause-404-errors) (Linux package)

### Upgrade to 18.4

Before upgrading to GitLab 18.4, review the following:

- [18.4.6] - [Commits and Files API size and rate limits](#commits-and-files-api-size-and-rate-limits)
- [18.4.2 - 18.4.3] - [Batched background migration nil error](#batched-background-migration-nil-error)
- [18.4.1] - [JSON input limits for denial of service prevention](#json-input-limits-for-denial-of-service-prevention)
- [18.4.0 - 18.4.3] - [Geo log cursor migration fix](#geo-log-cursor-migration-fix) (Geo)
- [18.4.0 - 18.4.1] - [Geo replication TypeError](#geo-replication-typeerror) (Geo)

### Upgrade to 18.3

Before upgrading to GitLab 18.3, review the following:

- [18.3.3] - [JSON input limits for denial of service prevention](#json-input-limits-for-denial-of-service-prevention)
- [18.3.0] - [LdapAddOnSeatSyncWorker removes Duo seats](#ldapaddonseatsyncworker-removes-duo-seats)
- [18.3.0] - [Geo Rake check fix](#geo-rake-check-fix) (Geo)
- [18.3.0 - 18.3.2] - [Geo Pages filename fix](#geo-pages-filename-fix) (Geo)

### Upgrade to 18.2

Before upgrading to GitLab 18.2, review the following:

- [18.2.7] - [JSON input limits for denial of service prevention](#json-input-limits-for-denial-of-service-prevention)
- [18.2.0] - [Zero-downtime upgrade push errors between 18.1 and 18.2](#zero-downtime-upgrade-push-errors-between-181-and-182)
- [18.2.0 - 18.2.1] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.2.0 - 18.2.6] - [Geo Pages filename fix](#geo-pages-filename-fix) (Geo)

### Upgrade to 18.1

Before upgrading to GitLab 18.1, review the following:

- [18.1.0] - [Elasticsearch `strict_dynamic_mapping_exception`](#elasticsearch-strict_dynamic_mapping_exception)
- [18.1.0 - 18.1.1] - [PostgreSQL `ci_job_artifacts` error](#postgresql-ci_job_artifacts-error)
- [18.1.0] - [Merge request almost ready bug](#merge-request-almost-ready-bug)
- [18.1.0] - [Geo HTTP 500 proxy errors](#geo-http-500-proxy-errors) (Geo)
- [18.1.0 - 18.1.3] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.1.0] - [Geo Pages filename fix](#geo-pages-filename-fix) (Geo)

### Upgrade to 18.0

Before upgrading to GitLab 18.0, review the following:

- [18.0.0] - [PostgreSQL 14 not supported](#postgresql-14-not-supported)
- [18.0.0] - [`pg_dump` binary compatibility](#pg_dump-binary-compatibility)
- [18.0.0] - [Pipeline failures during zero-downtime upgrades from 17.11](#pipeline-failures-during-zero-downtime-upgrades-from-1711)
- [18.0.0] - [Migrate Gitaly configuration from `git_data_dirs` to storage](#migrate-gitaly-configuration-from-git_data_dirs-to-storage) (Linux package)
- [18.0.0 - 18.0.1] - [Geo CE to EE revert migration errors](#geo-ce-to-ee-revert-migration-errors) (Geo)
- [18.0.0 - 18.0.2] - [Geo HTTP 500 proxy errors](#geo-http-500-proxy-errors) (Geo)
- [18.0.0 - 18.0.5] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.0.0] - [PRNG is not seeded error on Docker installations](#prng-is-not-seeded-error-on-docker-installations) (Docker)
- [17.11.0] - [Bitnami PostgreSQL and Redis image deprecation](#bitnami-postgresql-and-redis-image-deprecation) (Helm chart)

## Upgrade notes

Specific upgrade notes for GitLab 18.

### Geo blob sync failures with `log_error` NoMethodError on file storage

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo (file storage only)
- Affected versions:

  | Release           | Affected patch releases | Fixed patch level |
  | ----------------- |-------------------------|-------------------|
  | 18.11             | 18.11.0 - 18.11.2       | 18.11.3           |
  | 18.10             | 18.10.0 - 18.10.5       | 18.10.6           |
  | 18.0 - 18.9       | All patch releases      | Not fixed         |

On Geo secondary sites that store blobs on **file storage** (rather than object
storage), blob replication (such as Pipeline Artifacts, LFS objects, uploads,
and job artifacts) can fail with a misleading error:

```plaintext
Error while attempting to sync: undefined method `log_error' for an instance of Gitlab::Geo::Replication::BlobDownloader
```

For more information, see [issue 598565](https://gitlab.com/gitlab-org/gitlab/-/work_items/598565).

### CI job token regression pulling container images from internal and public projects

- Affects: All installation methods
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  | ------- | ----------------------- | ----------------- |
  | 18.11   | 18.11.0 - 18.11.1       | 18.11.2           |

> [!warning]
> Do not upgrade to GitLab 18.11.0 or 18.11.1 if CI jobs rely on `CI_JOB_TOKEN`
> to pull container images from internal or public projects.

A regression in GitLab 18.11.0 prevents CI jobs from pulling container images
from internal or public projects using `CI_JOB_TOKEN`. Affected pipelines fail
with `denied: requested access to the resource is denied`. The fix was
backported to `18-11-stable-ee` but landed after the 18.11.1 tag was cut, so
both 18.11.0 and 18.11.1 are affected.

Available workarounds for operators who have already upgraded:

1. Add each consuming project to the source project's CI job token allowlist.
   See [CI/CD job token security](../../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security).
1. Authenticate the container pull with a personal, group, or project access
   token instead of `CI_JOB_TOKEN`.
1. Apply the backport commit
   [`e3c0f308`](https://gitlab.com/gitlab-org/gitlab/-/commit/e3c0f30800f803b8f519e9b937296b068d8f4cca)
   to the GitLab instance.

For more information, see [issue 597223](https://gitlab.com/gitlab-org/gitlab/-/work_items/597223).

### SLES 12.5 RPM package installation failure

- Affects: Linux package
- Affected versions:

  | Release | Affected patch releases          | Installable patch level |
  | ------- | -------------------------------- | ----------------------- |
  | 18.10   | 18.10.0 - 18.10.3                | 18.10.4 - 18.10.5       |
  | 18.9    | 18.9.1 - 18.9.5                  | 18.9.0, 18.9.6          |

> [!warning]
> On SLES 12.5, only GitLab 18.9.0, 18.10.4, and 18.11.2 can be installed successfully.
> All other patch releases in the affected range fail to install.

GitLab Linux packages for SLES 12.5 fail to install with `error: install failed`
when using the `rpm` or `zypper` commands. The root cause is a 16 MiB RPM header
data size limitation (`HEADER_DATA_MAX`) in RPM 4.11.2, which is the version
shipped with SLES 12 SP5. As the number of files in the GitLab package grew,
the serialized RPM header exceeded this limit, causing the RPM database
transaction to fail silently during installation.

The issue was resolved in specific patch releases by reducing the file count
in the Linux package
(see [merge request 9215](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9215)).
However, subsequent patch releases may regress if the file count grows again.
To install GitLab on SLES 12.5, use only the installable patch levels listed above.

SUSE distributions are
[deprecated in GitLab 18.9 and scheduled for removal in GitLab 19.0](../deprecations.md#linux-package-support-for-suse-distributions).
Consider migrating to a supported operating system.

For more information, see [issue 9647](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/9647).

### Mattermost and Spamcheck removed from SLES 12.5 packages

- Affects: Linux package
- Affected versions: 18.11.0 and later

Due to [RPM package size constraints](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9716),
Mattermost and Spamcheck have been removed from SLES 12.5 Linux packages.

SUSE distributions are
[deprecated in GitLab 18.9 and scheduled for removal in GitLab 19.0](../deprecations.md#linux-package-support-for-suse-distributions),
and both [Mattermost](../deprecations.md#mattermost-bundled-with-linux-package) and
[Spamcheck](../deprecations.md#spamcheck-support-in-the-linux-package-and-gitlab-helm-chart)
are scheduled for removal from all distributions in GitLab 19.0.

If you rely on Mattermost on SLES 12.5, you can
[migrate Mattermost to a standalone deployment](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html).
If you use Spamcheck on SLES 12.5, you can
[deploy it using Docker](../../administration/reporting/spamcheck.md).

### Geo secondary throttled jobs not draining

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3       | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5         | 18.9.6            |

Geo secondary sites disabled `ConcurrencyLimit::ResumeWorker`, causing throttled
`Geo::EventWorker` and `Geo::SyncWorker` jobs to accumulate in Redis without
draining. This could stall Geo replication and increase Redis memory usage.

For more information, see [issue 595824](https://gitlab.com/gitlab-org/gitlab/-/work_items/595824).

### Geo site URL blocked when using outbound filtering

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3       | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5         | 18.9.6            |

When outbound request filtering is enabled, Geo site URLs are incorrectly blocked.
This causes validation errors when saving Geo sites with messages like
`Url is blocked: Requests to hosts and IP addresses not on the Allow List are denied`.

The issue occurs because Geo site URLs are not automatically added to the outbound
local requests allowlist when outbound filtering is configured.

For more information, see [issue 544821](https://gitlab.com/gitlab-org/gitlab/-/issues/544821).

### Geo blob download timeout setting

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions: 18.10.0

The current 8-hour (28,800 seconds) hardcoded Geo blob download timeout causes sync failures for very large LFS objects (5+ GB) that require longer transfer times, leaving them stuck in "started" state. A new `blob_download_timeout` setting controls the per-site timeout (in seconds) for blob replication (LFS objects, uploads, job artifacts, etc.). Configurable through the [Geo Sites API](../../api/geo_sites.md).

- Default: `28800` (8 hours).
- Maximum: `86400` (24 hours).

### Geo blob download failures

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  | ------- | ----------------------- | ----------------- |
  | 18.10   |  18.10.0 - 18.10.4      | 18.10.5           |

All Geo blob types (uploads, LFS objects, job artifacts, and others) may
persistently fail to sync on secondaries. Unlike transient network errors,
these failures affect all blob records and do not recover on retry.
Affected secondaries show blobs in "failed" state, and Sidekiq logs may
contain segfaults, `HPE_USER Span callback error in on_header_field`
errors, or unexpected HTTP status codes (for example, `status_code: 32`
or `status_code: 34`).

The root cause is a symbol collision between `rugged` 1.9.0 (upgraded in
GitLab 18.10) and the `llhttp-ffi` gem. The statically linked `llhttp`
symbols in `rugged.so` override `llhttp-ffi` callbacks, corrupting HTTP
response parsing. For more information, see
[issue 598564](https://gitlab.com/gitlab-org/gitlab/-/issues/598564).

In GitLab 18.10.5, `rugged` is downgraded to 1.7.2, which does not
contain the conflicting symbols. No action is required after upgrading.

#### Feature flag workaround for GitLab 18.10.4

If you are on GitLab 18.10.4 and cannot upgrade to GitLab 18.10.5, enable
the `geo_blob_download_with_gitlab_http` feature flag. This flag switches
blob downloads to use `Gitlab::HTTP` (`Net::HTTP`) instead of the
FFI-dependent `http` gem:

1. Enable the feature flag:

   ```shell
   sudo gitlab-rails console
   Feature.enable(:geo_blob_download_with_gitlab_http)
   exit
   ```

1. Restart Sidekiq:

   ```shell
   sudo gitlab-ctl restart sidekiq
   ```

> [!note]
> The feature flag workaround has known limitations:
>
> - Large blob transfers that exceed 60 seconds may time out
>   ([issue 598020](https://gitlab.com/gitlab-org/gitlab/-/issues/598020)).
> - Container registry replication is not covered by this flag.
> - Environments with outbound request filtering (`deny_all_requests_except_allowed`)
>   may require additional configuration
>   ([issue 598514](https://gitlab.com/gitlab-org/gitlab/-/issues/598514)).

For more information, see [issue 595139](https://gitlab.com/gitlab-org/gitlab/-/issues/595139).

### Upgrade to 18.9 fails with PostgreSQL CheckViolation

- Affects: All installation methods
- Affected versions: 18.9.0, 18.9.1

When upgrading a self-managed GitLab instance to GitLab 18.9.0 or 18.9.1, the upgrade fails during database migrations with:

```plaintext
PG::CheckViolation: ERROR: check constraint "check_xxxxxxxx" of relation "tablename" is violated by some row
```

This issue was caused by a bug fixed in GitLab 18.10 (see [merge request 224446](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224446)). The fix was also backported and should be included in the next GitLab 18.9 patch release (see [merge request 225026](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225026)).

However, the bug can cause batched background migrations to be skipped silently due to the single-record bug. When upgrading to v18.8,batched background migrations targeting tables with a single record were incorrectly marked as `finished` without ever executing. This left data unbackfilled, causing upgrade failures on self-managed instances.

A proposed fix (see [merge request 225461](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225461)) resets affected batched background migrations from `finished`/`finalized` back to `paused` so the scheduler re-executes them. It scopes to migrations with `queued_migration_version` between 18.5 and 18.8 where `min_value = max_value` or `min_cursor = max_cursor`.

You have two options:

- Apply the workaround now to complete your upgrade immediately.
- Wait for the complete fix and upgrade after a release contains it.

The following Knowledge Base articles describe workarounds for five known symptoms:

- [`PG::CheckViolation: ERROR: check constraint "check_96233d37c0" of relation "pool_repositories" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25929006135068-PG-CheckViolation-ERROR-check-constraint-check-96233d37c0-of-relation-pool-repositories-is-violated-by-some-row)
- [`PG::CheckViolation: ERROR: check constraint "check_f6590fe2c1" of relation "gpg_key_subkeys" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25756021007004-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-gpg-key-subkeys)
- [`PG::CheckViolation: ERROR: check constraint "check_17a3a18e31" of relation "user_agent_details" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25994671144348-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-user-agent-details)
- [`PG::CheckViolation: ERROR: check constraint "check_ddd6f289f4" of relation "commit_user_mentions" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25992549646364-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-commit-user-mentions)
- [`PG::CheckViolation: ERROR: check constraint "check_e69372e45f" of relation "suggestions" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25771198648732-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-suggestions)

### Deploy keys and personal access tokens for blocked users invalidated

- Affects: All installation methods
- Affected versions:

  | Release | Affected patch levels | Fixed patch level        |
  |---------|-----------------------|--------------------------|
  | 18.8    | 18.8.2 and later      | N/A (intentional change) |
  | 18.7    | 18.7.2 and later      | N/A (intentional change) |
  | 18.6    | 18.6.4 and later      | N/A (intentional change) |

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

### ClickHouse dictionary creation error

- Affects: All installation methods
- Affected versions: 18.8.0

GitLab Self-Managed customers with [ClickHouse integration](../../integration/clickhouse.md) enabled might
encounter a ClickHouse database migration error during the upgrade process due to a missing
permission (`DB::Exception: gitlab: Not enough privileges`). To resolve this error, see the
[database dictionary read support troubleshooting documentation](../../integration/clickhouse.md#database-dictionary-read-support).

### Batched background migration for CI data reintroduced

- Affects: All installation methods
- Affected versions: 18.8.0

The [batched background migrations](../background_migrations.md) introduced in
[CI builds metadata migration](#ci-builds-metadata-migration) had
to be reintroduced to handle an edge case in the data structure and ensure that they would complete.

### CI builds metadata migration

- Affects: All installation methods
- Affected versions: 18.7.0

A [post deployment migration](../../development/database/post_deployment_migrations.md)
schedules batched [background migrations](../background_migrations.md) to copy CI builds metadata
to new optimized tables (`p_ci_job_definitions`). This migration is part of an initiative to
ultimately reduce CI database size (see [epic 13886](https://gitlab.com/groups/gitlab-org/-/epics/13886)).
If you have an instance with millions of jobs and want to speed up the migration,
you can [select what data is migrated](#ci-builds-metadata-migration-details).

### Geo ActionCable allowed origins setting

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions: 18.7.0

Added a new `action_cable_allowed_origins` setting to configure allowed origins for ActionCable websocket requests.
Specify the allowed URLs when configuring the primary site to ensure proper cross-site WebSocket connectivity:

- [Geo documentation for the Linux package](../../administration/geo/replication/configuration.md#add-primary-and-secondary-urls-as-allowed-actioncable-origins)
- [Geo documentation for the Helm chart](https://docs.gitlab.com/charts/advanced/geo/#configure-primary-database)

### Geo VerificationStateBackfillWorker slow queries fix

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions: 18.6.5

Fixed the Geo [issue 587407](https://gitlab.com/gitlab-org/gitlab/-/work_items/587407) where `Geo::VerificationStateBackfillWorker` generated large slow queries for the `merge_request_diff_details` table.

### Commits and Files API size and rate limits

- Affects: All installation methods
- Affected versions:

  | Release | Affected patch levels | Fixed patch level        |
  |---------|-----------------------|--------------------------|
  | 18.6    | 18.6.2 and later      | N/A (intentional change) |
  | 18.5    | 18.5.4 and later      | N/A (intentional change) |
  | 18.4    | 18.4.6 and later      | N/A (intentional change) |

GitLab 18.6.2, 18.5.4, and 18.4.6 introduced size and rate limits on requests made to the following endpoints:

- `POST /projects/:id/repository/commits` - [Create a commit](../../api/commits.md#create-a-commit)
- `POST /projects/:id/repository/files/:file_path` - [Create a file in a repository](../../api/repository_files.md#create-a-file-in-a-repository)
- `PUT /projects/:id/repository/files/:file_path` - [Update a file in a repository](../../api/repository_files.md#update-a-file-in-a-repository)

GitLab responds to requests that exceed the size limit with a `413 Entity Too large` status, and requests that exceed the rate limit with a `429 Too Many Requests` status. For more information, see [Commits and Files API limits](../../administration/instance_limits.md#commits-and-files-api-limits)

### Duo Agent Platform runner restrictions

- Affects: All installation methods
- Affected versions: 18.6.2

Some [runner restrictions](../../user/duo_agent_platform/flows/execution.md#configure-runners)
have been introduced relating to which runners can be used with Duo Agent Platform.

### Geo log cursor migration fix

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  |---------|-------------------------|-------------------|
  | 18.5    | 18.5.0 - 18.5.1         | 18.5.2            |
  | 18.4    | 18.4.0 - 18.4.3         | 18.4.4            |

The missing Geo [migration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210512) that prevents Geo log cursor on the secondary site to start is fixed.

### Finalize design management designs backfill

- Affects: All installation methods
- Affected versions: 18.5.0

A [post deployment migration](../../development/database/post_deployment_migrations.md)
`20250922202128_finalize_correct_design_management_designs_backfill` finalizes a
batched [background migration](../background_migrations.md) that was scheduled in 18.4.
If you skipped 18.4 in the upgrade path, the migration is fully executed when
post deployment migrations are run.
Execution time is directly related to the size of your `design_management_designs` table.
For most instances the migration should not take longer than 2 minutes, but for some larger instances,
it could take up to 10 minutes.
Please be patient and don't interrupt the migration process.

### NGINX routing changes cause 404 errors

- Affects: Linux package
- Affected versions: 18.5.0

NGINX routing changes introduced in GitLab 18.5.0 can cause services to become inaccessible when using non-matching hostnames such as `localhost` or alternative domain names.
This issue causes:

- Health check endpoints such as `/-/health` to return `404` errors instead of proper responses.
- GitLab web interface showing `404` error pages when accessed with hostnames other than the configured FQDN.
- GitLab Pages potentially receiving traffic intended for other services.
- Problems with any requests using alternative hostnames that previously worked.

This issue is resolved in the Linux package by [merge request 8805](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8805), and the fix will be
available in GitLab 18.5.2 and 18.6.0.

Git operations such clone, push, and pull are unaffected by this issue.

### Batched background migration nil error

- Affects: All installation methods
- Affected versions: 18.4.2, 18.4.3

Upgrades to `18.4.2` or `18.4.3` might fail with a `no implicit conversion of nil into String` error for these batched background migrations:

- `FixIncompleteInstanceExternalAuditDestinations`
- `FinalizeAuditEventDestinationMigrations`

To resolve this issue, upgrade to the latest patch release or use the [workaround in issue 578938](https://gitlab.com/gitlab-org/gitlab/-/issues/578938#workaround).

### Geo replication TypeError

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  |---------|-------------------------|-------------------|
  | 18.4    | 18.4.0 - 18.4.1         | 18.4.2            |

In secondary Geo sites, [a bug](https://gitlab.com/gitlab-org/gitlab/-/issues/571455) causes replication events to fail with the error message `no implicit conversion of String into Array (TypeError)`. Redundancies such as re-verification ensure eventual consistency, but RPO is significantly increased.

### JSON input limits for denial of service prevention

- Affects: All installation methods
- Affected versions:

  | Release | Affected patch levels | Fixed patch level        |
  |---------|-----------------------|--------------------------|
  | 18.4    | 18.4.1 and later      | N/A (intentional change) |
  | 18.3    | 18.3.3 and later      | N/A (intentional change) |
  | 18.2    | 18.2.7 and later      | N/A (intentional change) |

GitLab 18.4.1, 18.3.3, and 18.2.7 introduced limits on JSON inputs to prevent denial of service attacks.
GitLab responds to HTTP requests that exceed these limits with a `400 Bad Request` status.
For more information, see [HTTP request limits](../../administration/instance_limits.md#http-request-limits).

### LdapAddOnSeatSyncWorker removes Duo seats

- Affects: All installation methods
- Affected versions: 18.3.0

A new worker `LdapAddOnSeatSyncWorker` was introduced, which could unintentionally remove all users from
GitLab Duo seats nightly when LDAP is enabled. This was fixed in GitLab 18.4.0 and 18.3.2. See
[issue 565064](https://gitlab.com/gitlab-org/gitlab/-/issues/565064) for details.

### Geo Rake check fix

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions: 18.3.0

The [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/545533) that caused `rake gitlab:geo:check` to incorrectly report a failure when installing a Geo secondary site has been fixed in 18.3.0.

### Geo Pages filename fix

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch levels  | Fixed patch level |
  |---------|------------------------|-------------------|
  | 18.3    | 18.3.0 - 18.3.2        | 18.3.3            |
  | 18.2    | 18.2.0 - 18.2.6        | 18.2.7            |
  | 18.1    | 18.1.0 and later       | Not fixed in 18.1 |

GitLab 18.3.3 and 18.2.7 and later include a fix for [issue 559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196), where Geo verification could fail for Pages deployments with long filenames. The fix prevents filename trimming on Geo secondary sites to maintain consistency during replication and verification.

### Zero-downtime upgrade push errors between 18.1 and 18.2

- Affects: All installation methods
- Affected versions: 18.2.0

Upgrades between 18.1.x and 18.2.x are affected by [known issue 567543](https://gitlab.com/gitlab-org/gitlab/-/issues/567543),
which causes errors with pushing code to existing projects during an upgrade. To ensure no downtime during the
upgrade between versions 18.1.x and 18.2.x, upgrade directly to version 18.2.6, which includes a fix.

### Geo VerificationStateBackfillService `ci_job_artifact_states`

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch levels | Fixed patch level |
  |---------|------------------------|-------------------|
  | 18.2    | 18.2.0 - 18.2.1        | 18.2.2            |
  | 18.1    | 18.1.0 - 18.1.3        | 18.1.4            |
  | 18.0    | 18.0.0 - 18.0.5        | 18.0.6            |

The affected versions have a known issue that happens when `VerificationStateBackfillService` runs due to changes in the primary key of `ci_job_artifact_states`. To resolve, upgrade to a fixed patch level release.

### Elasticsearch `strict_dynamic_mapping_exception`

- Affects: All installation methods
- Affected versions: 18.1.0

Elasticsearch indexing might fail with `strict_dynamic_mapping_exception` errors for Elasticsearch version 7. To resolve, see the "Possible fixes" section in [issue 566413](https://gitlab.com/gitlab-org/gitlab/-/issues/566413).

### PostgreSQL `ci_job_artifacts` error

- Affects: All installation methods
- Affected versions: 18.1.0, 18.1.1

GitLab versions 18.1.0 and 18.1.1 show errors in PostgreSQL logs such as `ERROR:  relation "ci_job_artifacts" does not exist at ...`.
These errors in the logs can be safely ignored but could trigger monitoring alerts, including on Geo sites. To resolve this issue, update to GitLab 18.1.2 or later.

### Merge request almost ready bug

- Affects: All installation methods
- Affected versions: 18.1.0

Merge requests with commits by some users might not progress and continuously show `Your merge request is almost ready`. See [issue 554613](https://gitlab.com/gitlab-org/gitlab/-/issues/554613).
Additionally, [the `sidekiq/current` log](../../administration/logs/_index.md#sidekiq-logs) shows `undefined method 'id' for nil:NilClass` errors for `merge_request_diff_commit.rb`.
To fix this:

1. Start a [database console](../../administration/troubleshooting/postgresql.md#start-a-database-console).
1. Run the following command:

   ```sql
   REINDEX TABLE CONCURRENTLY public.merge_request_diff_commit_users;
   ```

1. Close and re-open the affected merge requests.

### Geo HTTP 500 proxy errors

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  |---------|-------------------------|-------------------|
  | 18.1    | 18.1.0                  | 18.1.1            |
  | 18.0    | 18.0.0 - 18.0.2         | 18.0.3            |

The GitLab versions in the table above have a known issue where Git operations that are proxied from a secondary Geo site fail with HTTP 500 errors. To resolve, upgrade to fixed patch level release.

### PostgreSQL 14 not supported

- Affects: All installation methods
- Affected versions: 18.0.0

[PostgreSQL 14 is not supported starting from GitLab 18](../deprecations.md#postgresql-14-and-15-no-longer-supported).
Upgrade PostgreSQL to at least version 16.5 before upgrading to GitLab 18.0 or later. For more information, see
[installation requirements](../../install/requirements.md#postgresql).

> [!warning]
> Automatic database version upgrades only apply to single node instances when using the Linux package.
> In all other cases, like Geo instances, PostgreSQL with high availability using the
> Linux package, or using an external PostgreSQL database (like Amazon RDS), you must upgrade PostgreSQL manually. See [upgrading a Geo instance](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-geo-instance) for detailed steps.

### `pg_dump` binary compatibility

- Affects: All installation methods
- Affected versions: 18.0.0

GitLab bundles the `pg_dump` binary. When using an external PostgreSQL server, ensure the `pg_dump` client version is compatible with the PostgreSQL server, for both creating and restoring GitLab database backups.

### Bitnami PostgreSQL and Redis image deprecation

- Affects: Helm chart
- Affected versions: 17.11.0 and earlier

From September 29th, 2025 Bitnami will stop providing tagged PostgreSQL and Redis images. If you deploy GitLab 17.11 or earlier using the
GitLab chart with bundled Redis or Postgres, you must manually update your values to use the legacy repository to prevent unexpected
downtime. For more information, see [issue 6089](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6089).

### Pipeline failures during zero-downtime upgrades from 17.11

- Affects: All installation methods
- Affected versions: 18.0.0

The feature flag `ci_only_one_persistent_ref_creation` causes pipeline failures during zero-downtime upgrades when Rails is upgraded but Sidekiq remains on version 17.11 (see details in [issue 558808](https://gitlab.com/gitlab-org/gitlab/-/issues/558808)).

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

### Migrate Gitaly configuration from `git_data_dirs` to storage

- Affects: Linux package
- Affected versions: 18.0.0

In GitLab 18.0 and later, you can no longer use the `git_data_dirs` setting to configure Gitaly storage locations.

If you are still using `git_data_dirs`, you must
[migrate your Gitaly configuration](https://docs.gitlab.com/omnibus/settings/configuration/#migrating-from-git_data_dirs) before upgrading to GitLab 18.0.

### Geo CE to EE revert migration errors

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo
- Affected versions: 18.0.0

If you deployed GitLab Enterprise Edition and then reverted to GitLab Community Edition,
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

### PRNG is not seeded error on Docker installations

- Affects: Docker
- Affected versions: 18.0.0

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
- Instead of using the GitLab Docker image, install a [native FIPS package](https://packages.gitlab.com/ui/browse/gitlab/gitlab-fips) on the host.

The last option is the recommended one to meet FIPS requirements. For
legacy installations, the first two options can be used as a stopgap.

### CI builds metadata migration details

- Affects: All installation methods
- Affected versions: 18.7.0

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

#### Controlling the scope for jobs processing data

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

#### Controlling the scope for job data visible to users

The environment variable `GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF` controls which jobs will have
their visible data migrated.

For example, `GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF=1y` copies affected visible data
(timeout value, environment, exit codes, and metadata for exposed artifacts)
for jobs from the most recent year.

By default, there is no cutoff date and data for all jobs is migrated.

#### Estimating migration impact

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

### Batched background migration for merge request merge data

- Affects: All installation methods
- Affected versions: 18.8.0

A [batched background migration](../background_migrations.md) copies merge request merge-related
data from the `merge_requests` table to a new dedicated `merge_requests_merge_data` table.

This migration is part of a database schema optimization initiative to normalize merge-specific
attributes into a separate table, improving query performance and maintainability.

#### What data is migrated

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

#### Estimating migration duration

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

### PostgreSQL version 17.7 upgrade on GitLab 18.11

- Affects: Linux package, Docker, Geo
- Affected versions: 18.11.0

Upgrading to GitLab 18.11 triggers an automatic upgrade to [PostgreSQL 17.7](../../administration/package_information/postgresql_versions.md) for single-node Linux package installations.

> [!warning]
> Automatic database version upgrades only apply to single-node instances when using the Linux package.
> For Geo deployments, PostgreSQL upgrades must be [deliberately scheduled and planned](../../administration/geo/replication/upgrading_the_geo_sites.md)
> because a major version upgrade requires re-initializing PostgreSQL replication to Geo secondaries.
> This may result in larger than expected downtime.

### Sidekiq concurrency limiter causes job backlogs on Helm chart and Operator deployments

- Affects: Helm chart, Operator
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3      | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5        | 18.9.6            |

In GitLab 18.9, the GitLab Helm chart began setting `GITLAB_SIDEKIQ_MAX_REPLICAS` by default
([charts/GitLab merge request 4348](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4348)).
On GitLab Self-Managed and GitLab Dedicated environments that do not use KEDA-based autoscaling,
this causes the Sidekiq concurrency limiter to become active unexpectedly and defer jobs into
Redis-backed throttled queues.

This can result in:

- Sidekiq job backlogs.
- Redis memory growth.
- Delayed job execution.
- Impact to workers such as `WebHookWorker`, `AuditEvents::AuditEventStreamingWorker`,
  and Geo replication workers (`Geo::EventWorker`, `Geo::SyncWorker`).

If you are affected, you can use one of the following temporary mitigations until you upgrade to a fixed version:

- **Disable the concurrency limiter for a specific worker** by enabling a feature flag.
  Open a Rails console by running `exec` on a Sidekiq pod:

  ```shell
  kubectl exec -it <sidekiq-pod-name> -- gitlab-rails console
  ```

  Then enable the flag for the affected worker:

  ```ruby
  Feature.enable(:"disable_sidekiq_concurrency_limit_middleware_<WorkerClass>")
  ```

  Replace `<WorkerClass>` with the affected worker name (for example, `WebHookWorker`).

- **Disable all default concurrency limits** by setting `GITLAB_SIDEKIQ_MAX_REPLICAS=0`
  in your Sidekiq pod environment configuration. This disables the default concurrency limit
  calculation entirely.

> [!warning]
> If you use Geo, already-throttled jobs on secondary sites might not drain automatically
> because `ConcurrencyLimit::ResumeWorker` does not run on Geo secondaries. You may need to
> manually intervene to clear the throttled queues.

A fix that gates the default concurrency limit calculation behind a feature flag was merged in
[merge request 230713](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230713) and
backported to 18.10.4 ([merge request 231085](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231085))
and 18.9.6 ([merge request 231297](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231297)).
