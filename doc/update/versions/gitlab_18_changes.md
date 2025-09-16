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
[the Helm chart 9.0 upgrade notes](https://docs.gitlab.com/charts/releases/9_0.html).

## Issues to be aware of when upgrading from 16.11

- [PostgreSQL 14 is not supported starting from GitLab 18](../deprecations.md#postgresql-14-and-15-no-longer-supported). Upgrade PostgreSQL to at least version 16.8 before upgrading to GitLab 18.0 or later.

## Issues to be aware of when upgrading from 17.11

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

## 18.3.0

### GitLab Duo

A new worker `LdapAddOnSeatSyncWorker` was introduced, which could unintentionally remove all users from
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

### Geo installations 18.1.0

- GitLab version 18.1.0 has a known issue where Git operations that are proxied from a secondary Geo site fail with HTTP 500 errors. To resolve, upgrade to GitLab 18.1.1 or later.
- This version has a known issue that happens when `VerificationStateBackfillService` runs due to changes in the primary key of `ci_job_artifact_states`. To resolve, upgrade to GitLab 18.1.4.
- GitLab 18.1.0 includes a fix for [issue 559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196) where Geo verification could fail for Pages deployments with long filenames. The fix prevents filename trimming on Geo secondary sites to maintain consistency during replication and verification.

## 18.0.0

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
