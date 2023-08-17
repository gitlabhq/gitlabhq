---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 16 changes

This page contains upgrade information for minor and patch versions of GitLab 16.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

Some GitLab installations must upgrade to GitLab 16.0 before upgrading to any other version. For more information, see
[Long-running user type data change](#long-running-user-type-data-change).

For more information about upgrading GitLab Helm Chart, see [the release notes for 7.0](https://docs.gitlab.com/charts/releases/7_0.html).

## 16.3.0

- For Go applications, [`crypto/tls`: verifying certificate chains containing large RSA keys is slow (CVE-2023-29409)](https://github.com/golang/go/issues/61460)
  introduced a hard limit of 8192 bits for RSA keys. In the context of Go applications at GitLab, RSA keys can be configured for:

  - [Container Registry](../../administration/packages/container_registry.md)
  - [Gitaly](../../administration/gitaly/configure_gitaly.md#enable-tls-support)
  - [GitLab Pages](../../user/project/pages/custom_domains_ssl_tls_certification/index.md#manual-addition-of-ssltls-certificates)
  - [Workhorse](../../development/workhorse/configuration.md#tls-support)

  You should check the size of your RSA keys (`openssl rsa -in <your-key-file> -text -noout | grep "Key:"`)
  for any of the applications above before
  upgrading.

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

## 16.2.0

- Legacy LDAP configuration settings may cause
  [`NoMethodError: undefined method 'devise' for User:Class` errors](https://gitlab.com/gitlab-org/gitlab/-/issues/419485).
  This error occurs if you have TLS options (such as `ca_file`) not specified
  in the `tls_options` hash, or use the legacy `gitlab_rails['ldap_host']` option.
  See the [configuration workarounds](https://gitlab.com/gitlab-org/gitlab/-/issues/419485#workarounds)
  for more details.
- New job artifacts are not replicated if job artifacts are configured to be stored in object storage and `direct_upload` is enabled. This bug is fixed in GitLab versions 16.1.4,
  16.2.3, 16.3.0, and later.
  - Impacted versions: GitLab versions 16.1.0 - 16.1.3 and 16.2.0 - 16.2.2.
  - If you deployed an affected version, after upgrading to a fixed GitLab version, follow [these instructions](https://gitlab.com/gitlab-org/gitlab/-/issues/419742#to-fix-data)
    to resync the affected job artifacts.
- You might encounter the following error while upgrading to GitLab 16.2 or later:

  ```plaintext
  main: == 20230620134708 ValidateUserTypeConstraint: migrating =======================
  main: -- execute("ALTER TABLE users VALIDATE CONSTRAINT check_0dd5948e38;")
  rake aborted!
  StandardError: An error has occurred, all later migrations canceled:
  PG::CheckViolation: ERROR:  check constraint "check_0dd5948e38" of relation "users" is violated by some row
  ```

  For more information, see [issue 421629](https://gitlab.com/gitlab-org/gitlab/-/issues/421629).

### Linux package installations

Specific information applies to Linux package installations:

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

## 16.1.0

- A `BackfillPreparedAtMergeRequests` background migration is finalized with
  the `FinalizeBackFillPreparedAtMergeRequests` post-deploy migration.
  GitLab 15.10.0 introduced a [batched background migration](../background_migrations.md#batched-background-migrations) to
  [backfill `prepared_at` values on the `merge_requests` table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111865). This
  migration may take multiple days to complete on larger GitLab instances. Make sure the migration
  has completed successfully before upgrading to 16.1.0.
- New job artifacts are not replicated if job artifacts are configured to be stored in object storage and `direct_upload` is enabled. This bug is fixed in GitLab versions 16.1.4,
  16.2.3, 16.3.0, and later.
  - Impacted versions: GitLab versions 16.1.0 - 16.1.3 and 16.2.0 - 16.2.2.
  - If you deployed an affected version, after upgrading to a fixed GitLab version, follow [these instructions](https://gitlab.com/gitlab-org/gitlab/-/issues/419742#to-fix-data)
    to resync the affected job artifacts.

### Self-compiled installations

- You must remove any settings related to Puma worker killer from the `puma.rb` configuration file, because those have been
  [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118645). For more information, see the
  [`puma.rb.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/16-0-stable-ee/config/puma.rb.example) file.

### Geo installations

Specific information applies to installations using Geo:

- Some project imports do not initialize wiki repositories on project creation. Because of the migration of project wikis to
  SSF, [missing wiki repositories are being incorrectly flagged as failing verification](https://gitlab.com/gitlab-org/gitlab/-/issues/409704).
  This issue is not a result of an actual replication/verification failure but an invalid internal state for these missing
  repositories inside Geo and results in errors in the logs and the verification progress reporting a failed state for
  these wiki repositories. If you have not imported projects you are not impacted by this issue.
  - Impacted versions: GitLab versions 15.11.x, 16.0.x, and 16.1.0 - 16.1.2.
  - Versions containing fix: GitLab 16.1.3 and later.
- Because of the migration of project designs to SSF, [missing design repositories are being incorrectly flagged as failing verification](https://gitlab.com/gitlab-org/gitlab/-/issues/414279).
  This issue is not a result of an actual replication/verification failure but an invalid internal state for these missing
  repositories inside Geo and results in errors in the logs and the verification progress reporting a failed state for
  these design repositories. You could be impacted by this issue even if you have not imported projects.
  - Impacted versions: GitLab versions 16.1.x.
  - Versions containing fix: GitLab 16.2.0 and later.

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

### Linux package installations

Specific information applies to Linux package installations:

- The binaries for PostgreSQL 12 have been removed.

  Prior to upgrading, administrators of Linux package installations must ensure the installation is using
  [PostgreSQL 13](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

- Bundled Grafana is deprecated and is no longer supported. It is removed in GitLab 16.3.

  For more information, see [deprecation notes](../../administration/monitoring/performance/grafana_configuration.md#deprecation-of-bundled-grafana).

- This upgrades `openssh-server` to `1:8.9p1-3`.

  Using `ssh-keyscan -t rsa` with older OpenSSH clients to obtain public key information is no longer viable because of
  the deprecations listed in [OpenSSH 8.7 Release Notes](https://www.openssh.com/txt/release-8.7).

  Workaround is to make use of a different key type, or upgrade the client OpenSSH to a version >= 8.7.

### Geo installations

Specific information applies to installations using Geo:

- Some project imports do not initialize wiki repositories on project creation. Because of the migration of project wikis to
  SSF, [missing wiki repositories are being incorrectly flagged as failing verification](https://gitlab.com/gitlab-org/gitlab/-/issues/409704).
  This issue is not a result of an actual replication/verification failure but an invalid internal state for these missing
  repositories inside Geo and results in errors in the logs and the verification progress reporting a failed state for
  these wiki repositories. If you have not imported projects you are not impacted by this issue.

  - Impacted versions: GitLab versions 15.11.x, 16.0.x, and 16.1.0 - 16.1.2.
  - Versions containing fix: GitLab 16.1.3 and later.

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
16.0 `MigrateHumanUserType` background migration is completed, making the 16.0 changes synchronously
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
