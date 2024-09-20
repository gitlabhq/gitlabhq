---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 17 changes

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This page contains upgrade information for minor and patch versions of GitLab 17.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 8.0](https://docs.gitlab.com/charts/releases/8_0.html).

## Issues to be aware of when upgrading from 16.11

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

  This issue occurs because the background migration that got introduced in GitLab 17.0 didn't complete.
  To upgrade, either:

  - Upgrade to GitLab 17.0 and wait until all background migrations are completed.
  - Upgrade to GitLab 17.1 and then manually execute the background job and the migration by
    running the following command:

    ```shell
    sudo gitlab-rake gitlab:background_migrations:finalize[BackfillEpicBasicFieldsToWorkItemRecord,epics,id,'[null]']
    ```

  Now you should be able to complete the migrations in GitLab 17.1 and finish
  the upgrade. This bug has been fixed with GitLab 17.1.2 and upgrading from GitLab 16.x directly to 17.1.2 will not
  cause these issues.

### Linux package installations

Specific information applies to Linux package installations:

- The binaries for PostgreSQL 13 have been removed.

  Prior to upgrading, you must ensure your installation is using
  [PostgreSQL 14](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

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

- [Deprecations and removals documentation](../../update/deprecations.md#non-expiring-access-tokens).
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

## 17.7.0

- The [Linux Package](https://docs.gitlab.com/omnibus/) upgrades OpenSSL from v1.1.1w to v3.0.0.

- Cloud Native GitLab (CNG) already upgraded to OpenSSL 3 in GitLab 16.7.0. If you are using Cloud Native GitLab, no
  action is needed. However, note that [Cloud Native Hybrid](../../administration/reference_architectures/index.md#recommended-cloud-providers-and-services) installations
  use the Linux packages for stateful components, such as Gitaly. For those components, you will need to verify
  the TLS versions, ciphers, and certificates that are used work with the security level changes discussed below.

With the upgrade to OpenSSL version 3:

- GitLab requires TLS 1.2 or higher for all outgoing and incoming TLS connections.
- TLS/SSL certificates must have at least 112 bits of security. RSA, DSA, and DH keys shorter than 2048 bits, and ECC keys shorter than 224 bits are prohibited.

Older services, such as LDAP and Webhook servers, may still use TLS
1.1. However, TLS 1.0 and 1.1 have reached end-of-life and are no longer
considered secure. GitLab will fail to connect to services using TLS
1.0 or 1.1 with a `no protocols available` error message.

In addition, OpenSSL 3 increased the [default security level from level 1 to 2](https://docs.openssl.org/3.0/man3/SSL_CTX_set_security_level/#default-callback-behaviour),
raising the number of bits of security from 80 to 112. For example,
a certificate signed with an RSA key can use RSA-2048 but not RSA-1024. GitLab
will fail to connect to a service that uses a certificate signed with insufficient
bits with a `certificate key too weak` error message.

SSH keys are not affected by this upgrade. OpenSSL sets
security requirements for TLS, not SSH. [OpenSSH](https://www.openssh.com/) and
[`gitlab-sshd`](../../administration/operations/gitlab_sshd.md) have their
own configuration settings for the allowed cryptographic algorithms.

Check the [GitLab documentation for the upgrade to OpenSSL 3](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html) to ensure compatibility with your instance.

## 17.5.0

NOTE:
The OpenSSL 3 upgrade has been postponed to GitLab 17.7.0.

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
- GitLab Runner v17.4.0 also [switched from the MinIO S3 client to the AWS SDK v2 for Go](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4987) for distributed cache access.
  The MinIO client can be enabled again by setting the `FF_USE_LEGACY_S3_CACHE_ADAPTER` [GitLab Runner feature flag](https://docs.gitlab.com/runner/configuration/feature-flags.html) to `true`.

## 17.3.0

- Git 2.45.0 and later is required by Gitaly. For installations from source, you should use the [Git version provided by Gitaly](../../install/installation.md#git).

### Geo installations

- Geo Replication Details pages for a secondary site appear to be empty even if Geo replication is working, see [issue 468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509). There is no known workaround. The bug is fixed in GitLab 17.4.

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
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

### Geo installations

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

### Geo installations

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
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |
  | 17.3                    |  All                    | 17.3.1   |

## 17.0.0

### Geo installations

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
  | 17.0                    |  All                    | 17.0.7   |
  | 17.1                    |  All                    | 17.1.7   |
  | 17.2                    |  All                    | 17.2.5   |
  | 17.3                    |  All                    | 17.3.1   |
