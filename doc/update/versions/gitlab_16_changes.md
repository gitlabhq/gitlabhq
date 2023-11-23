---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 16 changes **(FREE SELF)**

This page contains upgrade information for minor and patch versions of GitLab 16.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 7.0](https://docs.gitlab.com/charts/releases/7_0.html).

## Issues to be aware of when upgrading from 15.11

- Some GitLab installations must upgrade to GitLab 16.0 before upgrading to any other version. For more information, see
  [Long-running user type data change](#long-running-user-type-data-change).
- Other installations can skip 16.0, 16.1, and 16.2 as the first required stop on the upgrade path is 16.3. Review the notes for those intermediate
  versions.
- If your GitLab instance upgraded first to 15.11.0, 15.11.1, or 15.11.2 the database schema is incorrect.
  Recommended: perform the workaround before upgrading to 16.x.
  See [the details and workaround](#undefined-column-error-upgrading-to-162-or-later).
- Linux package installations must change Gitaly and Praefect configuration structure before upgrading to GitLab 16.
  **To avoid data loss** reconfigure Praefect first, and as part of the new configuration, disable metadata verification.
  Read more:

  - [Praefect configuration structure change](#praefect-configuration-structure-change).
  - [Gitaly configuration structure change](#gitaly-configuration-structure-change).

## 16.5.0

- Git 2.42.0 and later is required by Gitaly. For self-compiled installations, you should use the [Git version provided by Gitaly](../../install/installation.md#git).
- A regression may sometimes cause an [HTTP 500 error when navigating a group](https://gitlab.com/gitlab-org/gitlab/-/issues/431659). Upgrading to GitLab 16.6 or later resolves the issue.
- A regression may cause [Unselected Advanced Search facets to not load](https://gitlab.com/gitlab-org/gitlab/-/issues/428246). Upgrading to 16.6 or later resolves the issue.

### Linux package installations

- SSH clone URLs can be customized by setting `gitlab_rails['gitlab_ssh_host']`
  in `/etc/gitlab/gitlab.rb`. This setting must now be a
  [valid hostname](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132238).
  Previously, it could be an arbitrary string that was used to show a
  custom hostname and port in the repository clone URL.

  For example, prior to GitLab 16.5, the following setting worked:

  ```ruby
  gitlab_rails['gitlab_ssh_host'] = "gitlab.example.com:2222"
  ```

  Starting with GitLab 16.5, the hostname and port must be specified separately:

  ```ruby
  gitlab_rails['gitlab_ssh_host'] = "gitlab.example.com"
  gitlab_rails['gitlab_shell_ssh_port'] = 2222
  ```

  After you change the setting, make sure to reconfigure GitLab:

  ```shell
  sudo gitlab-ctl reconfigure
  ```

### Geo installations

Specific information applies to installations using Geo:

- A number of Prometheus metrics were incorrectly removed in 16.3.0, which can break dashboards and alerting:

  | Affected metric                          | Metric restored in 16.5.2 and later  | Replacement available in 16.3+                 |
  | ---------------------------------------- | ------------------------------------ | ---------------------------------------------- |
  | `geo_repositories_synced`                | Yes                                  | `geo_project_repositories_synced`              |
  | `geo_repositories_failed`                | Yes                                  | `geo_project_repositories_failed`              |
  | `geo_repositories_checksummed`           | Yes                                  | `geo_project_repositories_checksummed`         |
  | `geo_repositories_checksum_failed`       | Yes                                  | `geo_project_repositories_checksum_failed`     |
  | `geo_repositories_verified`              | Yes                                  | `geo_project_repositories_verified`            |
  | `geo_repositories_verification_failed`   | Yes                                  | `geo_project_repositories_verification_failed` |
  | `geo_repositories_checksum_mismatch`     | No                                   | None available                                 |
  | `geo_repositories_retrying_verification` | No                                   | None available                                 |

  - Impacted versions:
    - 16.3.0 to 16.5.1
  - Versions containing fix:
    - 16.5.2 and later

  For more information, see [issue 429617](https://gitlab.com/gitlab-org/gitlab/-/issues/429617).

- [Object storage verification](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#geo-verifies-object-storage) was added in GitLab 16.4. Due to an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429242) some Geo installations are reporting high memory usage which can lead to the GitLab application on the primary becoming unresponsive.

  Your installation may be impacted if you have configured it to use [object storage](../../administration/object_storage.md) and have enabled [GitLab-managed object storage replication](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication)

  Until this is fixed, the workaround is to disable object storage verification.
  Run the following command on one of the Rails nodes on the primary site:

  ```shell
  sudo gitlab-rails runner 'Feature.disable(:geo_object_storage_verification)'
  ```

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ------ | ------ | ------ |
  | 16.4   | All    | None   |
  | 16.5   | All    | None   |

## 16.4.0

- Updating a group path [received a bug fix](https://gitlab.com/gitlab-org/gitlab/-/issues/419289) that uses a database index introduced in 16.3.

  If you upgrade to 16.4 from a version lower than 16.3, you must execute `ANALYZE packages_packages;` in the database before you use it.

- You might encounter the following error while upgrading to GitLab 16.4 or later:

  ```plaintext
  main: == 20230830084959 ValidatePushRulesConstraints: migrating =====================
  main: -- execute("SET statement_timeout TO 0")
  main:    -> 0.0002s
  main: -- execute("ALTER TABLE push_rules VALIDATE CONSTRAINT force_push_regex_size_constraint;")
  main:    -> 0.0004s
  main: -- execute("RESET statement_timeout")
  main:    -> 0.0003s
  main: -- execute("ALTER TABLE push_rules VALIDATE CONSTRAINT delete_branch_regex_size_constraint;")
  rails aborted!
  StandardError: An error has occurred, all later migrations canceled:

  PG::CheckViolation: ERROR:  check constraint "delete_branch_regex_size_constraint" of relation "push_rules" is violated by some row
  ```

  These constraints might return an error:

  - `author_email_regex_size_constraint`
  - `branch_name_regex_size_constraint`
  - `commit_message_negative_regex_size_constraint`
  - `commit_message_regex_size_constraint`
  - `delete_branch_regex_size_constraint`
  - `file_name_regex_size_constraint`
  - `force_push_regex_size_constraint`

  To fix the error, find the records in the `push_rules` table that exceed the 511
  character limit.

  ```sql
  ;; replace `delete_branch_regex` with a name of the field used in constraint
  SELECT id FROM push_rules WHERE LENGTH(delete_branch_regex) > 511;
  ```

  To find out if a push rule belongs to a project, group, or instance, run this script
  in the [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  # replace `delete_branch_regex` with a name of the field used in constraint
  long_rules = PushRule.where("length(delete_branch_regex) > 511")

  array = long_rules.map do |lr|
    if lr.project
      "Push rule with ID #{lr.id} is configured in a project #{lr.project.full_name}"
    elsif lr.group
      "Push rule with ID #{lr.id} is configured in a group #{lr.group.full_name}"
    else
      "Push rule with ID #{lr.id} is configured on the instance level"
    end
  end

  puts "Total long rules: #{array.count}"
  puts array.join("\n")
  ```

  Reduce the value length of the regex field for affected push rules records, then
  retry the migration.

  If you have too many affected push rules, and you can't update them through the GitLab UI,
  contact [GitLab support](https://about.gitlab.com/support/).

### Self-compiled installations

- A new method of configuring paths for the GitLab secret and custom hooks is preferred in GitLab 16.4 and later:
  1. Update your configuration `[gitlab] secret_file` to [configure the path](../../administration/gitaly/reference.md#gitlab) to the GitLab secret token.
  1. If you have custom hooks, update your configuration `[hooks] custom_hooks_dir` to [configure the path](../../administration/gitaly/reference.md#custom-hooks) to
     server-side custom hooks.
  1. Remove the `[gitlab-shell] dir` configuration.

### Geo installations

Specific information applies to installations using Geo:

- A number of Prometheus metrics were incorrectly removed in 16.3.0, which can break dashboards and alerting:

  | Affected metric                          | Metric restored in 16.5.2 and later  | Replacement available in 16.3+                 |
  | ---------------------------------------- | ------------------------------------ | ---------------------------------------------- |
  | `geo_repositories_synced`                | Yes                                  | `geo_project_repositories_synced`              |
  | `geo_repositories_failed`                | Yes                                  | `geo_project_repositories_failed`              |
  | `geo_repositories_checksummed`           | Yes                                  | `geo_project_repositories_checksummed`         |
  | `geo_repositories_checksum_failed`       | Yes                                  | `geo_project_repositories_checksum_failed`     |
  | `geo_repositories_verified`              | Yes                                  | `geo_project_repositories_verified`            |
  | `geo_repositories_verification_failed`   | Yes                                  | `geo_project_repositories_verification_failed` |
  | `geo_repositories_checksum_mismatch`     | No                                   | None available                                 |
  | `geo_repositories_retrying_verification` | No                                   | None available                                 |

  - Impacted versions:
    - 16.3.0 to 16.5.1
  - Versions containing fix:
    - 16.5.2 and later

  For more information, see [issue 429617](https://gitlab.com/gitlab-org/gitlab/-/issues/429617).

- [Object storage verification](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#geo-verifies-object-storage) was added in GitLab 16.4. Due to an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429242) some Geo installations are reporting high memory usage which can lead to the GitLab application on the primary becoming unresponsive.

  Your installation may be impacted if you have configured it to use [object storage](../../administration/object_storage.md) and have enabled [GitLab-managed object storage replication](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication)

  Until this is fixed, the workaround is to disable object storage verification.
  Run the following command on one of the Rails nodes on the primary site:

  ```shell
  sudo gitlab-rails runner 'Feature.disable(:geo_object_storage_verification)'
  ```

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ------ | ------ | ------ |
  | 16.4   | All    | None   |
  | 16.5   | All    | None   |

- An [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/419370) with sync states getting stuck in pending state results in replication being stuck indefinitely for impacted items leading to risk of data loss in the event of a failover. This mostly impact repository syncs but can also can also affect container registry syncs. You are advised to upgrade to a fixed version to avoid risk of data loss.

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ------ | ------ | ------ |
  | 16.3   | 16.3.0 - 16.3.5    | 16.3.6   |
  | 16.4   | 16.4.0 - 16.4.1    | 16.4.2   |

## 16.3.0

- **Update to GitLab 16.3.5 or later**. This avoids [issue 425971](https://gitlab.com/gitlab-org/gitlab/-/issues/425971) that causes an excessive use of database disk space for GitLab 16.3.3 and 16.3.4.

- A unique index was added to ensure that there’s no duplicate NPM packages in the database. If you have duplicate NPM packages, you need to upgrade to 16.1 first, or you are likely to run into the following error: `PG::UniqueViolation: ERROR:  could not create unique index "idx_packages_on_project_id_name_version_unique_when_npm"`.

- For Go applications, [`crypto/tls`: verifying certificate chains containing large RSA keys is slow (CVE-2023-29409)](https://github.com/golang/go/issues/61460)
  introduced a hard limit of 8192 bits for RSA keys. In the context of Go applications at GitLab, RSA keys can be configured for:

  - [Container registry](../../administration/packages/container_registry.md)
  - [Gitaly](../../administration/gitaly/tls_support.md)
  - [GitLab Pages](../../user/project/pages/custom_domains_ssl_tls_certification/index.md#manual-addition-of-ssltls-certificates)
  - [Workhorse](../../development/workhorse/configuration.md#tls-support)

  You should check the size of your RSA keys (`openssl rsa -in <your-key-file> -text -noout | grep "Key:"`)
  for any of the applications above before
  upgrading.

- A `BackfillCiPipelineVariablesForPipelineIdBigintConversion` background migration is finalized with
  the `EnsureAgainBackfillForCiPipelineVariablesPipelineIdIsFinished` post-deploy migration.
  GitLab 16.2.0 introduced a [batched background migration](../background_migrations.md#batched-background-migrations) to
  [backfill bigint `pipeline_id` values on the `ci_pipeline_variables` table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123132). This
  migration may take a long time to complete on larger GitLab instances (4 hours to process 50 million rows reported in one case).
  To avoid a prolonged upgrade downtime, make sure the migration has completed successfully before upgrading to 16.3.

  You can check the size of the `ci_pipeline_variables` table in the [database console](../../administration/troubleshooting/postgresql.md#start-a-database-console):

  ```sql
  select count(*) from ci_pipeline_variables;
  ```

### Linux package installations

Specific information applies to Linux package installations:

- In GitLab 16.0, we [announced](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#omnibus-improvements) an upgraded base Docker image,
  which has a new version of OpenSSH Server. An unintended consequence of the new version is that it disables accepting SSH RSA SHA-1 signatures by default. This issue should only
  impact users using very outdated SSH clients.

  To avoid problems with SHA-1 signatures being unavailable, users should update their SSH clients because using SHA-1 signatures is discouraged by the upstream library for security
  reasons.

  To allow for a transition period where users can't immediately upgrade their SSH clients, GitLab 16.3 and later has support for a `GITLAB_ALLOW_SHA1_RSA` environment variable in
  the `Dockerfile`. If `GITLAB_ALLOW_SHA1_RSA` is set to `true`, this deprecated support is reactivated.

  Because we want to foster security best practices and follow the upstream recommendation, this environment variable will only be available until GitLab 17.0, when we plan to
  drop support for it.

  For more information, see:

  - [OpenSSH 8.8 release notes](https://www.openssh.com/txt/release-8.8).
  - [An informal explanation](https://gitlab.com/gitlab-org/gitlab/-/issues/416714#note_1482388504).
  - `omnibus-gitlab` [merge request 7035](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7035), which introduces the environment variable.

### Geo installations

Specific information applies to installations using Geo:

- Git pulls against a secondary Geo site are being proxied to the primary Geo site even when that secondary site is up to date. You are impacted if you are using Geo to accelerate remote users who make Git pull requests against a secondary Geo site.

  - Impacted versions:
    - 16.3.0 to 16.3.3
  - Versions containing fix:
    - 16.3.4 and later

  For more information, see [issue 425224](https://gitlab.com/gitlab-org/gitlab/-/issues/425224).

- A number of Prometheus metrics were incorrectly removed in 16.3.0, which can break dashboards and alerting:

  | Affected metric                          | Metric restored in 16.5.2 and later  | Replacement available in 16.3+                 |
  | ---------------------------------------- | ------------------------------------ | ---------------------------------------------- |
  | `geo_repositories_synced`                | Yes                                  | `geo_project_repositories_synced`              |
  | `geo_repositories_failed`                | Yes                                  | `geo_project_repositories_failed`              |
  | `geo_repositories_checksummed`           | Yes                                  | `geo_project_repositories_checksummed`         |
  | `geo_repositories_checksum_failed`       | Yes                                  | `geo_project_repositories_checksum_failed`     |
  | `geo_repositories_verified`              | Yes                                  | `geo_project_repositories_verified`            |
  | `geo_repositories_verification_failed`   | Yes                                  | `geo_project_repositories_verification_failed` |
  | `geo_repositories_checksum_mismatch`     | No                                   | None available                                 |
  | `geo_repositories_retrying_verification` | No                                   | None available                                 |

  - Impacted versions:
    - 16.3.0 to 16.5.1
  - Versions containing fix:
    - 16.5.2 and later

  For more information, see [issue 429617](https://gitlab.com/gitlab-org/gitlab/-/issues/429617).

- An [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/419370) with sync states getting stuck in pending state results in replication being stuck indefinitely for impacted items leading to risk of data loss in the event of a failover. This mostly impact repository syncs but can also can also affect container registry syncs. You are advised to upgrade to a fixed version to avoid risk of data loss.

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ------ | ------ | ------ |
  | 16.3   | 16.3.0 - 16.3.5    | 16.3.6   |
  | 16.4   | 16.4.0 - 16.4.1    | 16.4.2   |

## 16.2.0

- Legacy LDAP configuration settings may cause
  [`NoMethodError: undefined method 'devise' for User:Class` errors](https://gitlab.com/gitlab-org/gitlab/-/issues/419485).
  This error occurs if you have TLS options (such as `ca_file`) not specified
  in the `tls_options` hash, or use the legacy `gitlab_rails['ldap_host']` option.
  See the [configuration workarounds](https://gitlab.com/gitlab-org/gitlab/-/issues/419485#workarounds)
  for more details.
- If your GitLab database was created by or upgraded via versions 15.11.0 - 15.11.2 inclusive, upgrading to GitLab 16.2 fails with:

  ```plaintext
  PG::UndefinedColumn: ERROR:  column "id_convert_to_bigint" of relation "ci_build_needs" does not exist
  LINE 1: ...db_config_name:main*/ UPDATE "ci_build_needs" SET "id_conver...
  ```

  See [the details and workaround](#undefined-column-error-upgrading-to-162-or-later).

- You might encounter the following error while upgrading to GitLab 16.2 or later:

  ```plaintext
  main: == 20230620134708 ValidateUserTypeConstraint: migrating =======================
  main: -- execute("ALTER TABLE users VALIDATE CONSTRAINT check_0dd5948e38;")
  rake aborted!
  StandardError: An error has occurred, all later migrations canceled:
  PG::CheckViolation: ERROR:  check constraint "check_0dd5948e38" of relation "users" is violated by some row
  ```

  For more information, see [issue 421629](https://gitlab.com/gitlab-org/gitlab/-/issues/421629).

- You might encounter the following error after upgrading to GitLab 16.2 or later:

  ```plaintext
  PG::NotNullViolation: ERROR:  null value in column "source_partition_id" of relation "ci_sources_pipelines" violates not-null constraint
  ```

  Sidekiq and Puma processes must be restarted to resolve this issue.

### Linux package installations

Specific information applies to Linux package installations:

- As of GitLab 16.2, PostgreSQL 13.11 and 14.8 are both shipped with the Linux package.
  During a package upgrade, the database isn't upgraded to PostgreSQL 14. If you
  want to upgrade to PostgreSQL 14, you must do it manually:

  ```shell
  sudo gitlab-ctl pg-upgrade -V 14
  ```

  PostgreSQL 14 isn't supported on Geo deployments and is [planned](https://gitlab.com/groups/gitlab-org/-/epics/9065)
  for future releases.

- In 16.2, we are upgrading Redis from 6.2.11 to 7.0.12. This upgrade is expected to be fully backwards compatible.

  Redis is not automatically restarted as part of `gitlab-ctl reconfigure`.
  Hence, users are manually required to run `sudo gitlab-ctl restart redis` after
  the reconfigure run so that the new Redis version gets used. A warning
  mentioning that the installed Redis version is different than the one running is
  displayed at the end of reconfigure run until the restart is performed.

  If your instance has Redis HA with Sentinel, follow the upgrade steps mentioned in
  [Zero Downtime documentation](../zero_downtime.md#redis-ha-using-sentinel).

### Self-compiled installations

- Git 2.41.0 and later is required by Gitaly. You should use the [Git version provided by Gitaly](../../install/installation.md#git).

### Geo installations

Specific information applies to installations using Geo:

- New job artifacts are not replicated by Geo if job artifacts are configured to be stored in object storage and `direct_upload` is enabled. This bug is fixed in GitLab versions 16.1.4,
  16.2.3, 16.3.0, and later.
  - Impacted versions: GitLab versions 16.1.0 - 16.1.3 and 16.2.0 - 16.2.2.
  - While running an affected version, artifacts which appeared to become synced may actually be missing on the secondary site.
    Affected artifacts are automatically resynced upon upgrade to 16.1.5, 16.2.5, 16.3.1, 16.4.0, or later.
    You can [manually resync affected job artifacts](https://gitlab.com/gitlab-org/gitlab/-/issues/419742#to-fix-data) if needed.

#### Cloning LFS objects from secondary site downloads from the primary site even when secondary is fully synced

A [bug](https://gitlab.com/gitlab-org/gitlab/-/issues/410413) in the Geo proxying logic for LFS objects meant that all LFS clone requests against a secondary site are proxied to the primary even if the secondary site is up-to-date. This can result in increased load on the primary site and longer access times for LFS objects for users cloning from the secondary site.

In GitLab 15.1 proxying was enabled by default.

You are not impacted:

- If your installation is not configured to use LFS objects
- If you do not use Geo to accelerate remote users
- If you are using Geo to accelerate remote users but have disabled proxying

| Affected minor releases | Affected patch releases | Fixed in |
|-------------------------|-------------------------|----------|
| 15.1 - 16.2             | All                     | 16.3 and later    |

Workaround: A possible workaround is to [disable proxying](../../administration/geo/secondary_proxy/index.md#disable-geo-proxying). Note that the secondary site fails to serve LFS files that have not been replicated at the time of cloning.

## 16.1.0

- A `BackfillPreparedAtMergeRequests` background migration is finalized with
  the `FinalizeBackFillPreparedAtMergeRequests` post-deploy migration.
  GitLab 15.10.0 introduced a [batched background migration](../background_migrations.md#batched-background-migrations) to
  [backfill `prepared_at` values on the `merge_requests` table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111865). This
  migration may take multiple days to complete on larger GitLab instances. Make sure the migration
  has completed successfully before upgrading to 16.1.0.
- GitLab 16.1.0 includes a [batched background migration](../background_migrations.md#batched-background-migrations) `MarkDuplicateNpmPackagesForDestruction` to mark duplicate NPM packages for destruction. Make sure the migration has completed successfully before upgrading to 16.3.0 or later.
- A `BackfillCiPipelineVariablesForBigintConversion` background migration is finalized with
  the `EnsureBackfillBigintIdIsCompleted` post-deploy migration.
  GitLab 16.0.0 introduced a [batched background migration](../background_migrations.md#batched-background-migrations) to
  [backfill bigint `id` values on the `ci_pipeline_variables` table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118878). This
  migration may take a long time to complete on larger GitLab instances (4 hours to process 50 million rows reported in one case).
  To avoid a prolonged upgrade downtime, make sure the migration has completed successfully before upgrading to 16.1.

  You can check the size of the `ci_pipeline_variables` table in the [database console](../../administration/troubleshooting/postgresql.md#start-a-database-console):

  ```sql
  select count(*) from ci_pipeline_variables;
  ```

### Self-compiled installations

- You must remove any settings related to Puma worker killer from the `puma.rb` configuration file, because those have been
  [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118645). For more information, see the
  [`puma.rb.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/16-0-stable-ee/config/puma.rb.example) file.

### Geo installations **(PREMIUM SELF)**

Specific information applies to installations using Geo:

- Some project imports do not initialize wiki repositories on project creation. See
  [the details and workaround](#wiki-repositories-not-initialized-on-project-creation).
- Because of the migration of project designs to SSF, [missing design repositories are being incorrectly flagged as failing verification](https://gitlab.com/gitlab-org/gitlab/-/issues/414279).
  This issue is not a result of an actual replication/verification failure but an invalid internal state for these missing
  repositories inside Geo and results in errors in the logs and the verification progress reporting a failed state for
  these design repositories. You could be impacted by this issue even if you have not imported projects.
  - Impacted versions: GitLab versions 16.1.0 - 16.1.2
  - Versions containing fix: GitLab 16.1.3 and later.
- New job artifacts are not replicated by Geo if job artifacts are configured to be stored in object storage and `direct_upload` is enabled. This bug is fixed in GitLab versions 16.1.4,
  16.2.3, 16.3.0, and later.
  - Impacted versions: GitLab versions 16.1.0 - 16.1.3 and 16.2.0 - 16.2.2.
  - While running an affected version, artifacts which appeared to become synced may actually be missing on the secondary site.
    Affected artifacts are automatically resynced upon upgrade to 16.1.5, 16.2.5, 16.3.1, 16.4.0, or later.
    You can [manually resync affected job artifacts](https://gitlab.com/gitlab-org/gitlab/-/issues/419742#to-fix-data) if needed.
  - Cloning LFS objects from secondary site downloads from the primary site even when secondary is fully synced. See [the details and workaround](#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site-even-when-secondary-is-fully-synced).

#### Wiki repositories not initialized on project creation

| Affected minor releases | Affected patch releases | Fixed in |
|-------------------------|-------------------------|----------|
| 15.11                   | All                     | None     |
| 16.0                    | All                     | None     |
| 16.1                    | 16.1.0 - 16.1.2         | 16.1.3 and later |

Some project imports do not initialize wiki repositories on project creation.
Since the migration of project wikis to SSF,
[missing wiki repositories are being incorrectly flagged as failing verification](https://gitlab.com/gitlab-org/gitlab/-/issues/409704).
This is not a result of an actual replication/verification failure but an
invalid internal state for these missing repositories inside Geo and results in
errors in the logs and the verification progress reporting a failed state for
these wiki repositories. If you have not imported projects you are not impacted
by this issue.

## 16.0.0

- Sidekiq crashes if there are non-ASCII characters in the `/etc/gitlab/gitlab.rb` file. You can fix this
  by following the workaround in [issue 412767](https://gitlab.com/gitlab-org/gitlab/-/issues/412767#note_1404507549).
- Sidekiq jobs are only routed to `default` and `mailers` queues by default, and as a result,
  every Sidekiq process also listens to those queues to ensure all jobs are processed across
  all queues. This behavior does not apply if you have configured the [routing rules](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules).
- Docker 20.10.10 or later is required to run the GitLab Docker image. Older versions
  [throw errors on startup](../../install/docker.md#threaderror-cant-create-thread-operation-not-permitted).
- Starting with 16.0, GitLab self-managed installations now have two database connections by default, instead of one. This change doubles the number of PostgreSQL connections. It makes self-managed versions of GitLab behave similarly to GitLab.com, and is a step toward enabling a separate database for CI features for self-managed versions of GitLab. Before upgrading to 16.0, determine if you need to [increase max connections for PostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#configuring-multiple-database-connections).
  - This change applies to installation methods with Linux packages (Omnibus), GitLab Helm chart, GitLab Operator, GitLab Docker images, and self-compiled installations.
- Container registry using Azure storage might be empty with zero tags. You can fix this by following the [breaking change instructions](../deprecations.md#azure-storage-driver-defaults-to-the-correct-root-prefix).

### Linux package installations

Specific information applies to Linux package installations:

- The binaries for PostgreSQL 12 have been removed.

  Prior to upgrading, administrators of Linux package installations must ensure the installation is using
  [PostgreSQL 13](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

- Grafana that was bundled with GitLab is deprecated and is no longer supported. It is
  [removed](../../administration/monitoring/performance/grafana_configuration.md#grafana-bundled-with-gitlab-removed) in
  GitLab 16.3.
- This upgrades `openssh-server` to `1:8.9p1-3`.

  Using `ssh-keyscan -t rsa` with older OpenSSH clients to obtain public key information is no longer viable because of
  the deprecations listed in [OpenSSH 8.7 Release Notes](https://www.openssh.com/txt/release-8.7).

  Workaround is to make use of a different key type, or upgrade the client OpenSSH to a version >= 8.7.

- [Migrate your Praefect configuration to the new structure](#praefect-configuration-structure-change)
  to ensure all your `praefect['..']` settings continue to work in GitLab 16.0 and later.

- [Migrate your Gitaly configuration to the new structure](#gitaly-configuration-structure-change)
  to ensure all your `gitaly['..']` settings continue to work in GitLab 16.0 and later.

### Geo installations **(PREMIUM SELF)**

Specific information applies to installations using Geo:

- Some project imports do not initialize wiki repositories on project creation. See
  [the details and workaround](#wiki-repositories-not-initialized-on-project-creation).
- Cloning LFS objects from secondary site downloads from the primary site even when secondary is fully synced. See [the details and workaround](#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site-even-when-secondary-is-fully-synced).

### Gitaly configuration structure change

The Gitaly configuration structure in the Linux package
[changes](https://gitlab.com/gitlab-org/gitaly/-/issues/4467) in GitLab 16.0
to be consistent with the Gitaly configuration structure used in
self-compiled installations.

As a result of this change, a single hash under `gitaly['configuration']` holds most Gitaly
configuration. Some `gitaly['..']` configuration options continue to be used by GitLab 16.0 and later:

- `enable`
- `dir`
- `bin_path`
- `env_directory`
- `env`
- `open_files_ulimit`
- `consul_service_name`
- `consul_service_meta`

Migrate by moving your existing configuration under the new structure. `git_data_dirs` is supported [until GitLab 17.0](https://gitlab.com/gitlab-org/gitaly/-/issues/5133). The new structure is supported from GitLab 15.10.

**Migrate to the new structure**

WARNING:
If you are running Gitaly cluster, [migrate Praefect to the new configuration structure **first**](#praefect-configuration-structure-change).
Once this change is tested, proceed with your Gitaly nodes.
If Gitaly is misconfigured as part of the configuration structure change, [repository verification](../../administration/gitaly/praefect.md#repository-verification)
will [delete metadata required for Gitaly cluster to work](https://gitlab.com/gitlab-org/gitaly/-/issues/5529).
To protect against configuration mistakes, temporarily disable repository verification in Praefect.

1. If you're running Gitaly Cluster, ensure repository verification is disabled on all Praefect nodes.
   Configure `verification_interval: 0`, and apply with `gitlab-ctl reconfigure`.
1. When applying the new structure to your configuration
   - Replace the `...` with the value from the old key.
   - When configuring `storage` to replace `git_data_dirs`, **you must append `repositories` to the path** as documented below.
     If you miss this out your Git repositories are inaccessible until the configuration is fixed.
     This misconfiguration can cause metadata deletion, and is the reason for disabling repository verification.
   - Skip any keys you haven't configured a value for previously.
   - Recommended. Include a trailing comma for all hash keys so the hash remains valid when keys are re-ordered or additional keys are added.
1. Apply the change with `gitlab-ctl reconfigure`.
1. Test Git repository functionality in GitLab.
1. Remove the old keys from the configuration once migrated, and then re-run `gitlab-ctl reconfigure`.
1. Recommended, if you're running Gitaly Cluster. Reinstate Praefect [repository verification](../../administration/gitaly/praefect.md#repository-verification)
   by removing `verification_interval: 0`.

The new structure is documented below with the old keys described in a comment above the new keys.

```ruby
gitaly['configuration'] = {
  # gitaly['socket_path']
  socket_path: ...,
  # gitaly['runtime_dir']
  runtime_dir: ...,
  # gitaly['listen_addr']
  listen_addr: ...,
  # gitaly['prometheus_listen_addr']
  prometheus_listen_addr: ...,
  # gitaly['tls_listen_addr']
  tls_listen_addr: ...,
  tls: {
    # gitaly['certificate_path']
    certificate_path: ...,
    # gitaly['key_path']
    key_path: ...,
  },
  # gitaly['graceful_restart_timeout']
  graceful_restart_timeout: ...,
  logging: {
    # gitaly['logging_level']
    level: ...,
    # gitaly['logging_format']
    format: ...,
    # gitaly['logging_sentry_dsn']
    sentry_dsn: ...,
    # gitaly['logging_ruby_sentry_dsn']
    ruby_sentry_dsn: ...,
    # gitaly['logging_sentry_environment']
    sentry_environment: ...,
    # gitaly['log_directory']
    dir: ...,
  },
  prometheus: {
    # gitaly['prometheus_grpc_latency_buckets']. The old value was configured as a string
    # such as '[0, 1, 2]'. The new value must be an array like [0, 1, 2].
    grpc_latency_buckets: ...,
  },
  auth: {
    # gitaly['auth_token']
    token: ...,
    # gitaly['auth_transitioning']
    transitioning: ...,
  },
  git: {
    # gitaly['git_catfile_cache_size']
    catfile_cache_size: ...,
    # gitaly['git_bin_path']
    bin_path: ...,
    # gitaly['use_bundled_git']
    use_bundled_binaries: ...,
    # gitaly['gpg_signing_key_path']
    signing_key: ...,
    # gitaly['gitconfig']. This is still an array but the type of the elements have changed.
    config: [
      {
        # Previously the elements contained 'section', and 'subsection' in addition to 'key'. Now
        # these all should be concatenated into just 'key', separated by dots. For example,
        # {section: 'first', subsection: 'middle', key: 'last', value: 'value'}, should become
        # {key: 'first.middle.last', value: 'value'}.
        key: ...,
        value: ...,
      },
    ],
  },
  # Storage could previously be configured through either gitaly['storage'] or 'git_data_dirs'. Migrate
  # the relevant configuration according to the instructions below.
  # For 'git_data_dirs', migrate only the 'path' to the gitaly['configuration'] and leave the rest of it untouched.
  storage: [
    {
      # gitaly['storage'][<index>]['name']
      #
      # git_data_dirs[<name>]. The storage name was configured as a key in the map.
      name: ...,
      # gitaly['storage'][<index>]['path']
      #
      # git_data_dirs[<name>]['path']. Use the value from git_data_dirs[<name>]['path'] and append '/repositories' to it.
      #
      # For example, if the path in 'git_data_dirs' was '/var/opt/gitlab/git-data', use
      # '/var/opt/gitlab/git-data/repositories'. The '/repositories' extension was automatically
      # appended to the path configured in `git_data_dirs`.
      path: ...,
    },
  ],
  hooks: {
    # gitaly['custom_hooks_dir']
    custom_hooks_dir: ...,
  },
  daily_maintenance: {
    # gitaly['daily_maintenance_disabled']
    disabled: ...,
    # gitaly['daily_maintenance_start_hour']
    start_hour: ...,
    # gitaly['daily_maintenance_start_minute']
    start_minute: ...,
    # gitaly['daily_maintenance_duration']
    duration: ...,
    # gitaly['daily_maintenance_storages']
    storages: ...,
  },
  cgroups: {
    # gitaly['cgroups_mountpoint']
    mountpoint: ...,
    # gitaly['cgroups_hierarchy_root']
    hierarchy_root: ...,
    # gitaly['cgroups_memory_bytes']
    memory_bytes: ...,
    # gitaly['cgroups_cpu_shares']
    cpu_shares: ...,
    repositories: {
      # gitaly['cgroups_repositories_count']
      count: ...,
      # gitaly['cgroups_repositories_memory_bytes']
      memory_bytes: ...,
      # gitaly['cgroups_repositories_cpu_shares']
      cpu_shares: ...,
    }
  },
  # gitaly['concurrency']. While the structure is the same, the string keys in the array elements
  # should be replaced by symbols as elsewhere. {'key' => 'value'}, should become {key: 'value'}.
  concurrency: ...,
  # gitaly['rate_limiting']. While the structure is the same, the string keys in the array elements
  # should be replaced by symbols as elsewhere. {'key' => 'value'}, should become {key: 'value'}.
  rate_limiting: ...,
  pack_objects_cache: {
    # gitaly['pack_objects_cache_enabled']
    enabled: ...,
    # gitaly['pack_objects_cache_dir']
    dir: ...,
    # gitaly['pack_objects_cache_max_age']
    max_age: ...,
  }
}
```

### Praefect configuration structure change

The Praefect configuration structure in the Linux package
[changes](https://gitlab.com/gitlab-org/gitaly/-/issues/4467) in GitLab 16.0
to be consistent with the Praefect configuration structure used in
self-compiled installations.

As a result of this change, a single hash under `praefect['configuration']` holds most Praefect
configuration. Some `praefect['..']` configuration options continue to be used by GitLab 16.0 and later:

- `enable`
- `dir`
- `log_directory`
- `env_directory`
- `env`
- `wrapper_path`
- `auto_migrate`
- `consul_service_name`

Migrate by moving your existing configuration under the new structure. The new structure is supported from GitLab 15.9.

**Migrate to the new structure**

WARNING:
Migrate Praefect to the new configuration structure **first**.
Once this change is tested, [proceed with your Gitaly nodes](#gitaly-configuration-structure-change).
If Gitaly is misconfigured as part of the configuration structure change, [repository verification](../../administration/gitaly/praefect.md#repository-verification)
will [delete metadata required for Gitaly cluster to work](https://gitlab.com/gitlab-org/gitaly/-/issues/5529).
To protect against configuration mistakes, temporarily disable repository verification in Praefect.

1. When applying the new structure to your configuration:
   - Replace the `...` with the value from the old key.
   - Disable repository verification using `verification_interval: 0`, as shown below.
   - Skip any keys you haven't configured a value for previously.
   - Recommended. Include a trailing comma for all hash keys so the hash remains valid when keys are re-ordered or additional keys are added.
1. Apply the change with `gitlab-ctl reconfigure`.
1. Test Git repository functionality in GitLab.
1. Remove the old keys from the configuration once migrated, and then re-run `gitlab-ctl reconfigure`.

The new structure is documented below with the old keys described in a comment above the new keys.

```ruby
praefect['configuration'] = {
  # praefect['listen_addr']
  listen_addr: ...,
  # praefect['socket_path']
  socket_path: ...,
  # praefect['prometheus_listen_addr']
  prometheus_listen_addr: ...,
  # praefect['tls_listen_addr']
  tls_listen_addr: ...,
  # praefect['separate_database_metrics']
  prometheus_exclude_database_from_default_metrics: ...,
  auth: {
    # praefect['auth_token']
    token: ...,
    # praefect['auth_transitioning']
    transitioning: ...,
  },
  logging: {
    # praefect['logging_format']
    format: ...,
    # praefect['logging_level']
    level: ...,
  },
  failover: {
    # praefect['failover_enabled']
    enabled: ...,
  },
  background_verification: {
    # praefect['background_verification_delete_invalid_records']
    delete_invalid_records: ...,
    # praefect['background_verification_verification_interval']
    #
    # IMPORTANT:
    # As part of reconfiguring Praefect, disable this feature.
    # Read about this above.
    #
    verification_interval: 0,
  },
  reconciliation: {
    # praefect['reconciliation_scheduling_interval']
    scheduling_interval: ...,
    # praefect['reconciliation_histogram_buckets']. The old value was configured as a string
    # such as '[0, 1, 2]'. The new value must be an array like [0, 1, 2].
    histogram_buckets: ...,
  },
  tls: {
    # praefect['certificate_path']
    certificate_path: ...,
   # praefect['key_path']
    key_path: ...,
  },
  database: {
    # praefect['database_host']
    host: ...,
    # praefect['database_port']
    port: ...,
    # praefect['database_user']
    user: ...,
    # praefect['database_password']
    password: ...,
    # praefect['database_dbname']
    dbname: ...,
    # praefect['database_sslmode']
    sslmode: ...,
    # praefect['database_sslcert']
    sslcert: ...,
    # praefect['database_sslkey']
    sslkey: ...,
    # praefect['database_sslrootcert']
    sslrootcert: ...,
    session_pooled: {
      # praefect['database_direct_host']
      host: ...,
      # praefect['database_direct_port']
      port: ...,
      # praefect['database_direct_user']
      user: ...,
      # praefect['database_direct_password']
      password: ...,
      # praefect['database_direct_dbname']
      dbname: ...,
      # praefect['database_direct_sslmode']
      sslmode: ...,
      # praefect['database_direct_sslcert']
      sslcert: ...,
      # praefect['database_direct_sslkey']
      sslkey: ...,
      # praefect['database_direct_sslrootcert']
      sslrootcert: ...,
    }
  },
  sentry: {
    # praefect['sentry_dsn']
    sentry_dsn: ...,
    # praefect['sentry_environment']
    sentry_environment: ...,
  },
  prometheus: {
    # praefect['prometheus_grpc_latency_buckets']. The old value was configured as a string
    # such as '[0, 1, 2]'. The new value must be an array like [0, 1, 2].
    grpc_latency_buckets: ...,
  },
  # praefect['graceful_stop_timeout']
  graceful_stop_timeout: ...,
  # praefect['virtual_storages']. The old value was a hash map but the new value is an array.
  virtual_storage: [
    {
      # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]. The name was previously the key in
      # the 'virtual_storages' hash.
      name: ...,
      # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]. The old value was a hash map
      # but the new value is an array.
      node: [
        {
          # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]. Use NODE_NAME key as the
          # storage.
          storage: ...,
          # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]['address'].
          address: ...,
          # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]['token'].
          token: ...,
        },
      ],
    }
  ]
}
```

## Long-running user type data change

GitLab 16.0 is a required stop for large GitLab instances with a lot of records in the `users` table.

The threshold is **30,000 users**, which includes:

- Developers and other users in any state, including active, blocked, and pending approval.
- Bot accounts for project and group access tokens.

GitLab 16.0 introduced a [batched background migration](../background_migrations.md#batched-background-migrations) to
[migrate `user_type` values from `NULL` to `0`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115849). This
migration might take multiple days to complete on larger GitLab instances. Make sure the migration
has completed successfully before upgrading to 16.1.0 or later.

GitLab 16.1 introduces the `FinalizeUserTypeMigration` migration which ensures the
16.0 `MigrateHumanUserType` background migration is completed, executing the 16.0 change synchronously
during the upgrade if it's not completed.

GitLab 16.2 [implements a `NOT NULL` database constraint](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122454)
which fails if the 16.0 migration is not complete.

If 16.0 has been skipped (or the 16.0 migration is not complete) subsequent
Linux package (Omnibus) and Docker upgrades might fail
after an hour:

```plaintext
FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
[..]
Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
```

[There is a fix-forward workaround for this issue](../package/index.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s).

While the workaround is completing the database changes, GitLab is likely to be in
an unusable state, generating `500` errors. The errors are caused by Sidekiq and Puma running
application code that is incompatible with the database schema.

At the end of the workaround process, Sidekiq and Puma are restarted to resolve that issue.

## Undefined column error upgrading to 16.2 or later

A bug in GitLab 15.11 incorrectly disabled a database change on self-managed instances.
For more information, see [issue 408835](https://gitlab.com/gitlab-org/gitlab/-/issues/408835).

If your GitLab instance upgraded first to 15.11.0, 15.11.1, or 15.11.2 the database schema is
incorrect and upgrading to GitLab 16.2 or later fails with an error. A database change
requires the earlier modification to be in place:

```plaintext
PG::UndefinedColumn: ERROR:  column "id_convert_to_bigint" of relation "ci_build_needs" does not exist
LINE 1: ...db_config_name:main*/ UPDATE "ci_build_needs" SET "id_conver...
```

GitLab 15.11.3 shipped a fix for this bug, but it doesn't correct the problem on
instances already running the earlier 15.11 releases.

If you're not sure if an instance is affected, check for the column on the
[database console](../../administration/troubleshooting/postgresql.md#start-a-database-console):

```sql
select pg_typeof (id_convert_to_bigint) from public.ci_build_needs limit 1;
```

If you need the workaround, this query fails:

```plaintext
ERROR:  column "id_convert_to_bigintd" does not exist
LINE 1: select pg_typeof (id_convert_to_bigintd) from public.ci_buil...
```

Unaffected instances return:

```plaintext
 pg_typeof
-----------
 bigint
```

The workaround for this issue differs if your GitLab instance's database schema
was recently created:

| Installation version | Workaround |
| -------------------- | ---------- |
| 15.9 or earlier      | [15.9](#workaround-instance-created-with-159-or-earlier) |
| 15.10                | [15.10](#workaround-instance-created-with-1510) |
| 15.11                | [15.11](#workaround-instance-created-with-1511) |

Most instances should use the 15.9 procedure. Only very new instances require the
the 15.10 or 15.11 procedures. If you've migrated GitLab using backup and restore,
the database schema comes from the original instance. Select the workaround based
on the source instance.

The commands in the following sections are for Linux package installations, and
differ for other installation types:

::Tabs

:::TabTitle Docker

- Omit `sudo`
- Shell into the GitLab container and run the same commands:

  ```shell
  docker exec -it <container-id> bash
  ```

:::TabTitle Self-compiled (source)

- Use `sudo -u git -H bundle exec rake RAILS_ENV=production` instead of `sudo gitlab-rake`
- Run the SQL on [your PostgreSQL database console](../../administration/troubleshooting/postgresql.md#start-a-database-console)

:::TabTitle Helm chart (Kubernetes)

- Omit `sudo`.
- Shell into the `toolbox` pod to run the Rake commands: `gitlab-rake` is in `/usr/local/bin` if not in the `PATH`.
  - Refer to our [Kubernetes cheat sheet](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html#gitlab-specific-kubernetes-information) for details.
- Run the SQL on [your PostgreSQL database console](../../administration/troubleshooting/postgresql.md#start-a-database-console)

::EndTabs

### Workaround: instance created with 15.9 or earlier

```shell
# Restore schema
sudo gitlab-psql -c "DELETE FROM schema_migrations WHERE version IN ('20230130175512', '20230130104819');"
sudo gitlab-rake db:migrate:up VERSION=20230130175512
sudo gitlab-rake db:migrate:up VERSION=20230130104819

# Re-schedule background migrations
sudo gitlab-rake db:migrate:down VERSION=20230130202201
sudo gitlab-rake db:migrate:down VERSION=20230130110855
sudo gitlab-rake db:migrate:up VERSION=20230130202201
sudo gitlab-rake db:migrate:up VERSION=20230130110855
```

### Workaround: instance created with 15.10

```shell
# Restore schema for sent_notifications
sudo gitlab-psql -c "DELETE FROM schema_migrations WHERE version = '20230130175512';"
sudo gitlab-rake db:migrate:up VERSION=20230130175512

# Re-schedule background migration for sent_notifications
sudo gitlab-rake db:migrate:down VERSION=20230130202201
sudo gitlab-rake db:migrate:up VERSION=20230130202201

# Restore schema for ci_build_needs
sudo gitlab-rake db:migrate:down VERSION=20230321163547
sudo gitlab-psql -c "INSERT INTO schema_migrations (version) VALUES ('20230321163547');"
```

### Workaround: instance created with 15.11

```shell
# Restore schema for sent_notifications
sudo gitlab-rake db:migrate:down VERSION=20230411153310
sudo gitlab-psql -c "INSERT INTO schema_migrations (version) VALUES ('20230411153310');"

# Restore schema for ci_build_needs
sudo gitlab-rake db:migrate:down VERSION=20230321163547
sudo gitlab-psql -c "INSERT INTO schema_migrations (version) VALUES ('20230321163547');"
```
