---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 17 changes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This page contains upgrade information for minor and patch versions of GitLab 17.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 8.0](https://docs.gitlab.com/charts/releases/8_0.html).

## Issues to be aware of when upgrading from 16.11

- You must remove references to the [now deprecated bundled Grafana](../deprecations.md#bundled-grafana-deprecated-and-disabled) key from `gitlab.rb` before upgrading to GitLab 17.0 or later. After upgrading, any references to the key in `gitlab.rb` will cause `gitlab-ctl reconfigure` to fail.

- You should [migrate to the new runner registration workflow](../../ci/runners/new_creation_workflow.md) before upgrading to GitLab 17.0.

  In GitLab 16.0, we introduced a new runner creation workflow that uses runner authentication tokens to register runners.
  The legacy workflow that uses registration tokens is now disabled by default in GitLab 17.0 and will be removed in GitLab 18.0.
  If registration tokens are still being used, upgrading to GitLab 17.0 will cause runner registration to fail.

- Gitaly storages can no longer share the same path as in this example:

  ```ruby
  gitaly['configuration'] = {
    storage: [
      {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
      },
      {
         name: 'duplicate-path',
         path: '/var/opt/gitlab/git-data/repositories',
      },
    ],
  }
  ```

  In this example, the `duplicate-path` storage must be removed or relocated to a new path. If you have
  more than one Gitaly node, you must ensure only the corresponding storage for that node is listed
  in that node's `gitlab.rb` file.

  If the storage is removed from a node's `gitlab.rb` file, then any projects associated with it must have their storage updated
  in the GitLab database. You can update their storage using the Rails console. For example:

  ```shell
  $ sudo gitlab-rails console
  Project.where(repository_storage: 'duplicate-path').update_all(repository_storage: 'default')
  ```

- Migration failures when upgrading from GitLab 16.x directly to GitLab 17.1.0 or 17.1.1.
  This bug has been fixed with GitLab 17.1.2.
  Upgrading from GitLab 16.x directly to 17.1.2 does not cause these issues.

  Due to a bug in GitLab 17.1.0 and 17.1.1 where a background job completion did not get enforced correctly, there
  can be failures when upgrading directly to GitLab 17.1.0 and 17.1.1.
  The error during the migration of the upgrade looks like the following:

  ```shell
  main: == [advisory_lock_connection] object_id: 55460, pg_backend_pid: 8714
  main: == 20240531173207 ValidateNotNullCheckConstraintOnEpicsIssueId: migrating =====
  main: -- execute("SET statement_timeout TO 0")
  main:    -> 0.0004s
  main: -- execute("ALTER TABLE epics VALIDATE CONSTRAINT check_450724d1bb;")
  main: -- execute("RESET statement_timeout")
  main: == [advisory_lock_connection] object_id: 55460, pg_backend_pid: 8714
  STDERR:
  ```

  To upgrade, either:

  - Upgrade to GitLab 17.0 and wait until all background migrations are completed.
  - Upgrade to GitLab 17.1 and then manually execute the background job and the migration by
    running the following command:

    ```shell
    sudo gitlab-rake gitlab:background_migrations:finalize[BackfillEpicBasicFieldsToWorkItemRecord,epics,id,'[null]']
    ```

  Now you should be able to complete the migrations in GitLab 17.1 and finish
  the upgrade.

- A [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/476542) in the Git versions shipped with
  GitLab 17.0.x and GitLab 17.1.x causes a noticeable increase in CPU usage when under load. The primary cause of
  this regression was resolved in the Git versions shipped with GitLab 17.2 so, for systems that see heavy peak loads,
  you should upgrade to GitLab 17.2.

### Linux package installations

Specific information applies to Linux package installations:

- The binaries for PostgreSQL 13 have been removed.

  Prior to upgrading, you must ensure your installation is using
  [PostgreSQL 14](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

- Packages are no longer built for Ubuntu 18.04

  Ensure that your operating system has been upgraded to Ubuntu 20.04 or later before attempting to upgrade GitLab.

### Non-expiring access tokens

Access tokens that have no expiration date are valid indefinitely, which is a
security risk if the access token is divulged.

When you upgrade to GitLab 16.0 and later, any [personal](../../user/profile/personal_access_tokens.md),
[project](../../user/project/settings/project_access_tokens.md), or
[group](../../user/group/settings/group_access_tokens.md) access
token that does not have an expiration date automatically has an expiration
date set at one year from the date of upgrade.

Before this automatic expiry date is applied, you should do the following to minimize disruption:

1. [Identify any access tokens without an expiration date](../../security/tokens/token_troubleshooting.md#find-tokens-with-no-expiration-date).
1. [Give those tokens an expiration date](../../security/tokens/token_troubleshooting.md#extend-token-lifetime).

For more information, see the:

- [Deprecations and removals documentation](../deprecations.md#non-expiring-access-tokens).
- [Deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369122).

## Issues to be aware of when upgrading from 17.1 and earlier

- If the customer is using GitLab Duo and upgrading to GitLab 17.2.3 or earlier, they must do both of the following:
  - Resynchronize their license.
  - Restart the server after the upgrade.
- If the customer is using GitLab Duo and upgrading to GitLab 17.2.4 or later, they must do either of the following:
  - Resynchronize their license.
  - Wait until the next scheduled license synchronization, which happens every 24 hours.

After the customer has upgraded to GitLab 17.2.4 or later, these steps are not required for future upgrades.

For more information, see [issue 480328](https://gitlab.com/gitlab-org/gitlab/-/issues/480328).

## Issues to be aware of when upgrading from 17.3

- Migration failures when upgrading from GitLab 17.3.

  When upgrading from 17.3 to 17.4, there is a slight chance of encountering an error. During the migration process, you might see an error message like the one below:

  ```shell
  main: == [advisory_lock_connection] object_id: 127900, pg_backend_pid: 76263
  main: == 20240812040748 AddUniqueConstraintToRemoteDevelopmentAgentConfigs: migrating
  main: -- transaction_open?(nil)
  main:    -> 0.0000s
  main: -- view_exists?(:postgres_partitions)
  main:    -> 0.0181s
  main: -- index_exists?(:remote_development_agent_configs, :cluster_agent_id, {:name=>"index_remote_development_agent_configs_on_unique_agent_id", :unique=>true, :algorithm=>:concurrently})
  main:    -> 0.0026s
  main: -- execute("SET statement_timeout TO 0")
  main:    -> 0.0004s
  main: -- add_index(:remote_development_agent_configs, :cluster_agent_id, {:name=>"index_remote_development_agent_configs_on_unique_agent_id", :unique=>true, :algorithm=>:concurrently})
  main: -- execute("RESET statement_timeout")
  main:    -> 0.0002s
  main: == [advisory_lock_connection] object_id: 127900, pg_backend_pid: 76263
  rake aborted!
  StandardError: An error has occurred, all later migrations canceled:

  PG::UniqueViolation: ERROR:  could not create unique index "index_remote_development_agent_configs_on_unique_agent_id"
  DETAIL:  Key (cluster_agent_id)=(1000141) is duplicated.
  ```

  This error occurs because the migration adds a unique constraint on the `cluster_agent_id` column in the `remote_development_agent_configs` table, but there are still duplicate entries. The previous migration is supposed to remove these duplicates, but in rare cases, new duplicates may be inserted between the two migrations.

  To safely resolve this issue, follow these steps:

  1. Open the Rails console where the migrations are being run.
  1. Copy and paste the script below into the console and execute it.
  1. Re-run the migrations, and they should complete successfully.

   ```Ruby
   # Get the IDs to keep for each cluster_agent_id; if there are duplicates, only the row with the latest updated_at will be kept.
   latest_ids = ::RemoteDevelopment::RemoteDevelopmentAgentConfig.select("DISTINCT ON (cluster_agent_id) id")
     .order("cluster_agent_id, updated_at DESC")
     .map(&:id)

   # Get the list of remote_development_agent_configs to be removed.
   agent_configs_to_remove = ::RemoteDevelopment::RemoteDevelopmentAgentConfig.where.not(id: latest_ids)

   # Delete all duplicated agent_configs.
   agent_configs_to_remove.delete_all
   ```

## Issues to be aware of when upgrading from 17.5

- Migration failures when upgrading from GitLab 17.5.

  When upgrading from 17.5 to 17.6, there is a slight chance of encountering an error. During the migration process, you might see an error message like the one below:

  ```shell
  rake aborted!
  StandardError: An error has occurred, all later migrations canceled:

  PG::CheckViolation: ERROR: new row for relation "ci_deleted_objects" violates check constraint "check_98f90d6c53"
  ```

  This error occurs because the migration tries to update some of the rows from the `ci_deleted_objects` table so that they will be processed, but they could be old records with a missing value for a required check constraint.

  To safely resolve this issue, follow these steps:

  1. Run only the following migration to fix the records affected by the check constraint.
  1. Re-run the migrations, and they should complete successfully.

   ```shell
   gitlab-rake db:migrate:up:ci VERSION=20241028085044
   ```

## 17.8.0

- In GitLab 17.8.0, GitLab agent server for Kubernetes (KAS) does not start with the default settings on the GitLab Linux package (Omnibus) and Docker installations.
  To resolve this issue, edit `/etc/gitlab/gitlab.rb`:

  ```ruby
  gitlab_kas['env'] = { 'OWN_PRIVATE_API_URL' => 'grpc://127.0.0.1:8155' }
  ```

  Multiple node installations should use the settings described in the [documentation](../../administration/clusters/kas.md).

- S3 object storage uploads in Workhorse now only use [AWS SDK v2 for Go](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164597).
The `workhorse_use_aws_sdk_v2` feature flag has been removed. The AWS SDK v2
[sets `Accept-Encoding: identity` and includes it as a signed header](https://github.com/aws/aws-sdk-go-v2/issues/2848).
However, some proxy services, such as Cloudflare, [alter this header, causing a signature mismatch error](https://gitlab.com/gitlab-org/gitlab/-/issues/492973#note_2312726631).
If you see [SignatureDoesNotMatch errors](https://repost.aws/knowledge-center/s3-presigned-url-signature-mismatch)
ensure that your proxy server does not alter or remove signed HTTP headers.

## 17.7.0

- Git 2.47.0 and later is required by Gitaly. For installations from source, you should use the [Git version provided by Gitaly](../../install/installation.md#git).
- FIPS Linux packages now use the system Libgcrypt, except FIPS Linux packages for AmazonLinux 2. Previous versions of the FIPS Linux packages used the
  same Libgcrypt used by the regular Linux packages, which was a bug. For more information, see
  [the FIPS documentation](../../development/fips_gitlab.md#system-libgcrypt).
- Linux `gitlab-runner` packages have broken out `gitlab-runner-helper-images` as a new required dependency. If you manually install `gitlab-runner` packages for upgrades,
  be sure to also [download the helper images manually](https://docs.gitlab.com/runner/install/linux-manually/#download).

### OpenSSL 3 upgrade

NOTE:
Before upgrading to GitLab 17.7, use the [OpenSSL 3 guide](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html)
to identify and assess the compatibility of your external integrations.

- The Linux package upgrades OpenSSL from v1.1.1w to v3.0.0.
- Cloud Native GitLab (CNG) already upgraded to OpenSSL 3 in GitLab 16.7.0. If you are using Cloud Native GitLab, no
  action is needed. However, note that [Cloud Native Hybrid](../../administration/reference_architectures/_index.md#recommended-cloud-providers-and-services) installations
  use the Linux packages for stateful components, such as Gitaly. For those components, you will need to verify
  the TLS versions, ciphers, and certificates that are used work with the security level changes discussed below.

With the upgrade to OpenSSL 3:

- GitLab requires TLS 1.2 or higher for all outgoing and incoming TLS connections.
- TLS/SSL certificates must have at least 112 bits of security. RSA, DSA, and DH keys shorter than 2048 bits, and ECC keys shorter than 224 bits are prohibited.

Older services, such as LDAP and Webhook servers, may still use TLS
1.1. However, TLS 1.0 and 1.1 have reached end-of-life and are no longer
considered secure. GitLab will fail to connect to services using TLS
1.0 or 1.1 with a `no protocols available` error message.

In addition, OpenSSL 3 increased the [default security level from level 1 to 2](https://docs.openssl.org/3.0/man3/SSL_CTX_set_security_level/#default-callback-behaviour),
raising the minimum number of bits of security from 80 to 112. As a result,
certificates signed with RSA and DSA keys shorter than 2048 bits and ECC keys
shorter than 224 bits are prohibited.

GitLab will fail to connect to a service that uses a certificate signed with
insufficient bits with a `certificate key too weak` error message. For more
information, see the [certificate requirements](../../security/tls_support.md#certificate-requirements).

All components that are shipped with the Linux package are compatible with
OpenSSL 3. Therefore, you only need to verify the services and integrations that
are not part of the GitLab package and are ["external"](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html#identifying-external-integrations).

SSH keys are not affected by this upgrade. OpenSSL sets
security requirements for TLS, not SSH. [OpenSSH](https://www.openssh.com/) and
[`gitlab-sshd`](../../administration/operations/gitlab_sshd.md) have their
own configuration settings for the allowed cryptographic algorithms.

Check the [GitLab documentation on securing your installation](../../security/_index.md)
for more details.

## 17.5.0

NOTE:
The OpenSSL 3 upgrade has been postponed to GitLab 17.7.0.

- S3 object storage access for the GitLab Runner distributed cache is now handled by the
  [AWS SDK v2 for Go](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4987) instead of the MinIO client.
  You can enable the MinIO client again by setting the `FF_USE_LEGACY_S3_CACHE_ADAPTER`
  [GitLab Runner feature flag](https://docs.gitlab.com/runner/configuration/feature-flags.html) to `true`.
- The token used by Gitaly to authenticate with GitLab is now [its own setting](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8688).
  This means Gitaly doesn't need GitLab Rails and Shell recipes to run and populate the default secret file inside the shell directory,
  and can have its own secret file. Some customized environments may need to
  [update their authentication configuration](../../administration/gitaly/configure_gitaly.md#configure-authentication)
  to avoid secrets mismatches.

## 17.4.0

- Starting with GitLab 17.4, new GitLab installations have a different database schema regarding ID columns.
  - All previous integer (32 bits) ID columns (for example columns like `id`, `%_id`, `%_ids`) are now created as `bigint` (64 bits).
  - Existing installations will migrate from 32 bit to 64 bit integers in later releases when database migrations ship to perform this change.
  - If you are building a new GitLab environment to test upgrades, install GitLab 17.3 or earlier to get
    the same integer types as your existing environments. You can then upgrade to later releases to run the same
    database migrations as your existing environments. This isn't necessary if you're restoring from backup into the
    new environment as the database restore removes the existing database schema definition and uses the definition
    that's stored as part of the backup.
- Git 2.46.0 and later is required by Gitaly. For installations from source, you should use the [Git version provided by Gitaly](../../install/installation.md#git).
- S3 object storage uploads in Workhorse are now handled by default using the [AWS SDK v2 for Go](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164597). If you experience issues
  with S3 object storage uploads, you can downgrade to v1 of by disabling the `workhorse_use_aws_sdk_v2` [feature flag](../../administration/feature_flags.md#enable-or-disable-the-feature).
- When you upgrade to GitLab 17.4, an OAuth application is generated for the Web IDE.
  If your GitLab server's external URL configuration in the `GitLab.rb` file contains uppercase letters, the Web IDE might fail to load.
  To resolve this issue, see [update the OAuth callback URL](../../user/project/web_ide/_index.md#update-the-oauth-callback-url).
- In accordance with [RFC 7540](https://datatracker.ietf.org/doc/html/rfc7540#section-3.3),
  Gitaly and Praefect reject TLS connections that do not support ALPN.
  If you use a load balancer in front of Praefect with
  TLS enabled, you may encounter `FAIL: 14:connections to all backends failing` errors
  if ALPN is not used. You can disable this enforcement by setting `GRPC_ENFORCE_ALPN_ENABLED=false` in the
  Praefect environment. With the Linux package, edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    praefect['env'] = { 'GRPC_ENFORCE_ALPN_ENABLED' => 'false' }
    ```

  Then run `gitlab-ctl reconfigure`.

  ALPN enforcement has been disabled again in [GitLab 17.5.5 and other versions](../../administration/gitaly/praefect.md#alpn-enforcement).
  Upgrading to one of those versions removes the need to set `GRPC_ENFORCE_ALPN_ENABLED`.

## 17.3.0

- Git 2.45.0 and later is required by Gitaly. For installations from source, you should use the [Git version provided by Gitaly](../../install/installation.md#git).

### Geo installations 17.3.0

- Geo Replication Details pages for a secondary site appear to be empty even if Geo replication is working, see [issue 468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509). There is no known workaround. The bug is fixed in GitLab 17.4.

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | None     |
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |
  | 17.3                    |  All                    | 17.3.1   |

## 17.2.1

- Upgrades to GitLab 17.2.1 can fail because of [unknown sequences in the database](https://gitlab.com/gitlab-org/gitlab/-/issues/474293). This issue has
  been fixed in GitLab 17.2.2.

- Upgrades to [GitLab 17.2.1 may fail with the error](https://gitlab.com/gitlab-org/gitlab/-/issues/473337):

  ```plaintext
  PG::DependentObjectsStillExist: ERROR: cannot drop desired object(s) because other objects depend on them
  ```

  As [described in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/474525#note_2045274993),
  this database sequence ownership issue has been fixed in GitLab
  17.2.1. However, you might encounter this if the migrations in 17.2.0
  did not complete, but the Linux package prevents the upgrade to 17.2.1 or later because of a malformed
  JSON file. For example, you might see this error:

  ```plaintext
  Malformed configuration JSON file found at /opt/gitlab/embedded/nodes/gitlab.example.com.json.
  This usually happens when your last run of `gitlab-ctl reconfigure` didn't complete successfully.
  This file is used to check if any of the unsupported configurations are enabled,
  and hence require a working reconfigure before upgrading.
  Please run `sudo gitlab-ctl reconfigure` to fix it and try again.
  ```

  The current workaround is to:

  1. Remove the JSON files in `/opt/gitlab/embedded/nodes`:

     ```shell
     rm /opt/gitlab/embedded/nodes/*.json
     ```

  1. Upgrade to GitLab 17.2.1 or higher.

### Geo installations 17.2.1

- In GitLab 16.11 through GitLab 17.2, a missing PostgreSQL index can cause high CPU usage, slow job artifact verification progress, and slow or timed out Geo metrics status updates. The index was added in GitLab 17.3. To manually add the index, see [Geo Troubleshooting - High CPU usage on primary during job artifact verification](../../administration/geo/replication/troubleshooting/common.md#high-cpu-usage-on-primary-during-object-verification).

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  All                    | None     |
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |

- Geo Replication Details pages for a secondary site appear to be empty even if Geo replication is working, see [issue 468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509). There is no known workaround. The bug is fixed in GitLab 17.4.

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | None     |
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |
  | 17.3                    |  All                    | 17.3.1   |

## 17.1.0

- Bitbucket identities with untrusted `extern_uid` are deleted.
  For more information, see [issue 452426](https://gitlab.com/gitlab-org/gitlab/-/issues/452426).
- The default [changelog](../../user/project/changelogs.md) template generates links as full URLs instead of GitLab specific references.
  For more information, see [merge request 155806](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155806).
- Git 2.44.0 and later is required by Gitaly. For self-compiled installations,
  you should use the [Git version provided by Gitaly](../../install/installation.md#git).
- Upgrading to GitLab 17.1.0 or 17.1.1 or having unfinished background migrations from GitLab 17.0 can result
  in a failure when running the migrations.
  This is due to a bug.
  [Issue 468875](https://gitlab.com/gitlab-org/gitlab/-/issues/468875) has been fixed with GitLab 17.1.2.

### Long-running pipeline messages data change

GitLab 17.1 is a required stop for large GitLab instances with a lot of records in the `ci_pipeline_messages` table.

A data change might take many hours to complete on larger GitLab instances, at a rate of 1.5-2 million records
processed per hour. If your instance is affected:

1. Upgrade to 17.1.
1. [Make sure all batched migrations have completed successfully](../background_migrations.md#batched-background-migrations).
1. Upgrade to 17.2 or 17.3.

To check if you are affected:

1. Start a [database console](../../administration/troubleshooting/postgresql.md#start-a-database-console)
1. Run:

   ```sql
   SELECT relname as table,n_live_tup as rows FROM pg_stat_user_tables
   WHERE relname='ci_pipeline_messages' and n_live_tup>1500000;
   ```

1. If the query returns output with a count for `ci_pipeline_messages` then your
   instance meets the threshold for this required stop. Instances reporting `0 rows` can skip
   the 17.1 upgrade stop.

GitLab 17.1 introduced a [batched background migration](../background_migrations.md#batched-background-migrations)
that ensures every record in the `ci_pipeline_messages` table has the [correct partitioning key](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153391).
Partitioning CI tables is expected to provide performance improvements for instances with large amounts of CI data.

The upgrade to GitLab 17.2 runs a `Finalize` migration which ensures the 17.1 background migration is completed,
executing the 17.1 change synchronously during the upgrade if required.

GitLab 17.2 also [adds foreign key database constraints](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158065)
which require the partitioning key to be populated. The constraints [are validated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159571)
as part of the upgrade to GitLab 17.3.

If 17.1 is omitted from the upgrade path (or the 17.1 migration is not complete):

- There is extended downtime for affected instances while the upgrade completes.
- Fixing forward is safe.
- To make the environment available sooner, a Rake task can be used to run the migration:

  ```shell
  sudo gitlab-rake gitlab:background_migrations:finalize[BackfillPartitionIdCiPipelineMessage,ci_pipeline_messages,id,'[]']
  ```

Until all database migrations are complete, GitLab is likely to be unusable, generating `500` errors, caused by incompatibility between the partly upgraded database schema and the running Sidekiq and Puma processes.

The Linux package (Omnibus) or Docker upgrade is likely to fail
with a time out after an hour:

```plaintext
FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
[..]
Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
```

To fix this:

1. Run the Rake task above to complete the batched migration.
1. [Complete the rest of the timed-out operation](../package/package_troubleshooting.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s). At the end of this process, Sidekiq and Puma are restarted to fix the `500` errors.

Feedback about this conditional stop on the upgrade path can be provided [in the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/503891).

### Geo installations 17.1.0

- In GitLab 16.11 through GitLab 17.2, a missing PostgreSQL index can cause high CPU usage, slow job artifact verification progress, and slow or timed out Geo metrics status updates. The index was added in GitLab 17.3. To manually add the index, see [Geo Troubleshooting - High CPU usage on primary during job artifact verification](../../administration/geo/replication/troubleshooting/common.md#high-cpu-usage-on-primary-during-object-verification).

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  All                    | None     |
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |

- Geo Replication Details pages for a secondary site appear to be empty even if Geo replication is working, see [issue 468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509). There is no known workaround. The bug is fixed in GitLab 17.4.

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | None     |
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |
  | 17.3                    |  All                    | 17.3.1   |

## 17.0.0

### Geo installations 17.0.0

- In GitLab 16.11 through GitLab 17.2, a missing PostgreSQL index can cause high CPU usage, slow job artifact verification progress, and slow or timed out Geo metrics status updates. The index was added in GitLab 17.3. To manually add the index, see [Geo Troubleshooting - High CPU usage on primary during job artifact verification](../../administration/geo/replication/troubleshooting/common.md#high-cpu-usage-on-primary-during-object-verification).

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  All                    | None     |
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |

- Geo Replication Details pages for a secondary site appear to be empty even if Geo replication is working, see [issue 468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509). There is no known workaround. The bug is fixed in GitLab 17.4.

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | None     |
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |
  | 17.3                    |  All                    | 17.3.1   |
