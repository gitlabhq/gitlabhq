---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 15 changes **(FREE SELF)**

This page contains upgrade information for minor and patch versions of GitLab 15.
Ensure you review these instructions for all versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 6.0](https://docs.gitlab.com/charts/releases/6_0.html).

## 15.11.1

- Many [project importers](../../user/project/import/index.md) and [group importers](../../user/group/import/index.md) now
  require the Maintainer role instead of only requiring the Developer role. For more information, see the documentation
  for any importers you use.
- Geo: Some project imports do not initialize wiki repositories on project creation. Since the migration of project wikis to SSF, [missing wiki repositories are being incorrectly flagged as failing verification](https://gitlab.com/gitlab-org/gitlab/-/issues/409704). This is not a result of an actual replication/verification failure but an invalid internal state for these missing repositories inside Geo and results in errors in the logs and the verification progress reporting a failed state for these wiki repositories. If you have not imported projects you are not impacted by this issue.
  - Impacted versions: GitLab versions 15.11.x, 16.0.x, and 16.1.0 - 16.1.2.
  - Versions containing fix: GitLab 16.1.3 and later.
- Geo: A [bug](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7841) in the built-in `pg-upgrade` tool prevents upgrading the bundled PostgreSQL database to version 13. This leaves the secondary site in a broken state, and prevents upgrading the Geo installation to GitLab 16.x ([PostgreSQL 12 support has removed in 16.0](../deprecations.md#postgresql-12-deprecated) and later releases). This occurs on secondary sites using the bundled PostgreSQL software, running both the secondary main Rails database and tracking database on the same node. There is a manual [workaround](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7841#workaround) for those impacted until a fix is backported to 15.11.
  - Impacted versions: GitLab versions 15.2 - 15.11
  - Versions containing fix: 15.11.12 and later.
  - Version 16.0 and later are not impacted. Note, 15.11 is a mandatory upgrade stop on the way to 16.0.

## 15.11.0

- **Upgrade to patch release 15.11.3 or later**. This avoids [issue 408304](https://gitlab.com/gitlab-org/gitlab/-/issues/408304) when upgrading from 15.5.0 and earlier.
- Geo: Some project imports do not initialize wiki repositories on project creation. Since the migration of project wikis to SSF, [missing wiki repositories are being incorrectly flagged as failing verification](https://gitlab.com/gitlab-org/gitlab/-/issues/409704). This is not a result of an actual replication/verification failure but an invalid internal state for these missing repositories inside Geo and results in errors in the logs and the verification progress reporting a failed state for these wiki repositories. If you have not imported projects you are not impacted by this issue.
  - Impacted versions: GitLab versions 15.11.x, 16.0.x, and 16.1.0 - 16.1.2.
  - Versions containing fix: GitLab 16.1.3 and later.
- Geo: A [bug](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7841) in the built-in `pg-upgrade` tool prevents upgrading the bundled PostgreSQL database to version 13. This leaves the secondary site in a broken state, and prevents upgrading the Geo installation to GitLab 16.x ([PostgreSQL 12 support has removed in 16.0](../deprecations.md#postgresql-12-deprecated) and later releases). This occurs on secondary sites using the bundled PostgreSQL software, running both the secondary main Rails database and tracking database on the same node. There is a manual [workaround](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7841#workaround) for those impacted until a fix is backported to 15.11.
  - Impacted versions: GitLab versions 15.2 - 15.11.11.
  - Versions containing fix: 15.11.12 and later.
  - Version 16.0 and later are not impacted. Note, 15.11 is a mandatory upgrade stop on the way to 16.0.

## 15.11.x

- A [bug](https://gitlab.com/gitlab-org/gitlab/-/issues/411604) can cause new LDAP users signing in for the first time to be assigned a username based on their email address instead of their LDAP username attribute. A manual workaround is to set `gitlab_rails['omniauth_auto_link_ldap_user'] = true`, or upgrade to GitLab 16.1 or later where the bug has been fixed.

## 15.10.5

- A [bug with Elastic Indexer Cron Workers](https://gitlab.com/gitlab-org/gitlab/-/issues/408214) can cause saturation in Sidekiq.
  - When this issue occurs, merge request merges, pipelines, Slack notifications, and other events are not created or take a long time to occur.
  - This issue may not manifest immediately as it can take up to a week before the Sidekiq is saturated enough.
  - Elasticsearch does not need to be enabled for this to occur.
  - To resolve this issue, upgrade to 15.11 or use the workaround in the issue.
- Many [project importers](../../user/project/import/index.md) and [group importers](../../user/group/import/index.md) now
  require the Maintainer role instead of only requiring the Developer role. For more information, see the documentation
  for any importers you use.

## 15.10.0

- A [bug with Elastic Indexer Cron Workers](https://gitlab.com/gitlab-org/gitlab/-/issues/408214) can cause saturation in Sidekiq.
  - When this issue occurs, merge request merges, pipelines, Slack notifications, and other events are not created or take a long time to occur.
  - This issue may not manifest immediately as it can take up to a week before the Sidekiq is saturated enough.
  - Elasticsearch does not need to be enabled for this to occur.
  - To resolve this issue, upgrade to 15.11 or use the workaround in the issue.
- Gitaly configuration changes significantly in Omnibus GitLab 16.0. You can begin migrating to the new structure in Omnibus GitLab 15.10 while backwards compatibility is
  maintained in the lead up to Omnibus GitLab 16.0. [Read more about this change](../index.md#gitaly-omnibus-gitlab-configuration-structure-change).
- You might encounter the following error while upgrading to GitLab 15.10 or later:

  ```shell
  STDOUT: rake aborted!
  StandardError: An error has occurred, all later migrations canceled:
  PG::CheckViolation: ERROR:  check constraint "check_70f294ef54" is violated by some row
  ```

  This error is caused by a [batched background migration introduced in GitLab 15.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107701)
  not being finalized before GitLab 15.10. To resolve this error:

  1. Execute the following SQL statement using the database console (`sudo gitlab-psql` for Linux package installs):

     ```sql
     UPDATE oauth_access_tokens SET expires_in = '7200' WHERE expires_in IS NULL;
     ```

  1. [Re-run database migrations](../../administration/raketasks/maintenance.md#run-incomplete-database-migrations).

- You might also encounter the following error while upgrading to GitLab 15.10 or later:

  ```shell
  "exception.class": "ActiveRecord::StatementInvalid",
  "exception.message": "PG::SyntaxError: ERROR:  zero-length delimited identifier at or near \"\"\"\"\nLINE 1: ...COALESCE(\"lock_version\", 0) + 1 WHERE \"ci_builds\".\"\" IN (SEL...\n
  ```

  This error is caused by a [batched background migration introduced in GitLab 14.9](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81410)
  not being finalized before upgrading to GitLab 15.10 or later. To resolve this error, it is safe to [mark the migration as complete](../background_migrations.md#mark-a-batched-migration-finished):

  ```ruby
  # Start the rails console

  connection = Ci::ApplicationRecord.connection

  Gitlab::Database::SharedModel.using_connection(connection) do
    migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
      Gitlab::Database.gitlab_schemas_for_connection(connection), 'NullifyOrphanRunnerIdOnCiBuilds', :ci_builds, :id, [])

    # mark all jobs completed
    migration.batched_jobs.update_all(status: Gitlab::Database::BackgroundMigration::BatchedJob.state_machine.states[:succeeded].value)
    migration.update_attribute(:status, Gitlab::Database::BackgroundMigration::BatchedMigration.state_machine.states[:finished].value)
  end
  ```

For more information, see [issue 415724](https://gitlab.com/gitlab-org/gitlab/-/issues/415724).

## 15.9.0

- A [bug with Elastic Indexer Cron Workers](https://gitlab.com/gitlab-org/gitlab/-/issues/408214) can cause saturation in Sidekiq.
  - When this issue occurs, merge request merges, pipelines, Slack notifications, and other events are not created or take a long time to occur.
  - This issue may not manifest immediately as it can take up to a week before the Sidekiq is saturated enough.
  - Elasticsearch does not need to be enabled for this to occur.
  - To resolve this issue, upgrade to 15.11 or use the workaround in the issue.
- **Upgrade to patch release 15.9.3 or later**. This provides fixes for two database migration bugs:
  - Patch releases 15.9.0, 15.9.1, 15.9.2 have [a bug that can cause data loss](../index.md#user-profile-data-loss-bug-in-159x) from the user profile fields.
  - The second [bug fix](https://gitlab.com/gitlab-org/gitlab/-/issues/394760) ensures it is possible to upgrade directly from 15.4.x.
- As part of the [CI Partitioning effort](../../architecture/blueprints/ci_data_decay/pipeline_partitioning.md), a [new Foreign Key](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107547) was added to `ci_builds_needs`. On GitLab instances with large CI tables, adding this constraint can take longer than usual.
- Praefect's metadata verifier's [invalid metadata deletion behavior](../../administration/gitaly/praefect.md#enable-deletions) is now enabled by default.

  The metadata verifier processes replica records in the Praefect database and verifies the replicas actually exist on the Gitaly nodes. If the replica doesn't exist, its
  metadata record is deleted. This enables Praefect to fix situations where a replica has a metadata record indicating it's fine but, in reality, it doesn't exist on disk.
  After the metadata record is deleted, Praefect's reconciler schedules a replication job to recreate the replica.

  Because of past issues with the state management logic, there may be invalid metadata records in the database. These could exist, for example, because of incomplete
  deletions of repositories or partially completed renames. The verifier deletes these stale replica records of affected repositories. These repositories may show up as
  unavailable repositories in the metrics and `praefect dataloss` sub-command because of the replica records being removed. If you encounter such repositories, remove
  the repository using `praefect remove-repository` to remove the repository's remaining records.

  You can find repositories with invalid metadata records prior in GitLab 15.0 and later by searching for the log records outputted by the verifier. [Read more about repository verification, and to see an example log entry](../../administration/gitaly/praefect.md#repository-verification).
- Praefect configuration changes significantly in Omnibus GitLab 16.0. You can begin migrating to the new structure in Omnibus GitLab 15.9 while backwards compatibility is
  maintained in the lead up to Omnibus GitLab 16.0. [Read more about this change](../index.md#praefect-omnibus-gitlab-configuration-structure-change).
- For **self-compiled (source) installations**, with the addition of `gitlab-sshd` the Kerberos headers are needed to build GitLab Shell.

  ```shell
  sudo apt install libkrb5-dev
  ```

## 15.8.2

- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.

## 15.8.1

- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.8.0

- Git 2.38.0 and later is required by Gitaly. For self-compiled installations, you should use the [Git version provided by Gitaly](../../install/installation.md#git).
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.

## 15.7.6

- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.7.5

- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.7.4

- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.7.3

- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.7.2

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the upgrades. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.7.1

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.7.0

- This version validates a `NOT NULL DB` constraint on the `issues.work_item_type_id` column.
  To upgrade to this version, no records with a `NULL` `work_item_type_id` should exist on the `issues` table.
  There are multiple `BackfillWorkItemTypeIdForIssues` background migrations that will be finalized with
  the `EnsureWorkItemTypeBackfillMigrationFinished` post-deploy migration.
- GitLab 15.4.0 introduced a [batched background migration](../background_migrations.md#batched-background-migrations) to
  [backfill `namespace_id` values on issues table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91921). This
  migration might take multiple hours or days to complete on larger GitLab instances. Make sure the migration
  has completed successfully before upgrading to 15.7.0.
- A database constraint is added, specifying that the `namespace_id` column on the issues
  table has no `NULL` values.

  - If the `namespace_id` batched background migration from 15.4 failed (see above) then the 15.7 upgrade
    fails with a database migration error.

  - On GitLab instances with large issues tables, validating this constraint causes the upgrade to take
    longer than usual. All database changes need to complete within a one-hour limit:

    ```plaintext
    FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
    [..]
    Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
    ```

    A workaround exists to [complete the data change and the upgrade manually](../package/index.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s).
- The default Sidekiq `max_concurrency` has been changed to 20. This is now
  consistent in our documentation and product defaults.

  For example, previously:

  - Linux package installation default (`sidekiq['max_concurrency']`): 50
  - Self-compiled installation default: 50
  - Helm chart default (`gitlab.sidekiq.concurrency`): 25

  Reference architectures still use a default of 10 as this is set specifically
  for those configurations.

  Sites that have configured `max_concurrency` will not be affected by this change.
  [Read more about the Sidekiq concurrency setting](../../administration/sidekiq/extra_sidekiq_processes.md#concurrency).
- GitLab Runner 15.7.0 introduced a breaking change that affects CI/CD jobs: [Correctly handle expansion of job file variables](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3613).
  Previously, job-defined variables that referred to
  [file type variables](../../ci/variables/index.md#use-file-type-cicd-variables)
  were expanded to the value of the file variable (its content). This behavior did not
  respect the typical rules of shell variable expansion. There was also the potential
  that secrets or sensitive information could leak if the file variable and its
  contents printed. For example, if they were printed in an echo output. For more information,
  see [Understanding the file type variable expansion change in GitLab 15.7](https://about.gitlab.com/blog/2023/02/13/impact-of-the-file-type-variable-change-15-7/).
- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.

## 15.6.7

- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.6.6

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.6.5

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.6.4

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6, and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.6.3

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.6.2

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.6.1

- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.6.0

- You should use one of the [officially supported PostgreSQL versions](../../administration/package_information/postgresql_versions.md). Some database migrations can cause stability and performance issues with older PostgreSQL versions.
- Git 2.37.0 and later is required by Gitaly. For self-compiled installations, you should use the [Git version provided by Gitaly](../../install/installation.md#git).
- A database change to modify the behavior of four indexes fails on instances
  where these indexes do not exist:

  ```plaintext
  Caused by:
  PG::UndefinedTable: ERROR:  relation "index_issues_on_title_trigram" does not exist
  ```

  The other three indexes are: `index_merge_requests_on_title_trigram`, `index_merge_requests_on_description_trigram`,
  and `index_issues_on_description_trigram`.

  This issue was [fixed in GitLab 15.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105375) and backported
  to GitLab 15.6.2. The issue can also be worked around:
  [read about how to create these indexes](https://gitlab.com/gitlab-org/gitlab/-/issues/378343#note_1199863087).
- Geo: [Container registry push events are rejected](https://gitlab.com/gitlab-org/gitlab/-/issues/386389) by the `/api/v4/container_registry_event/events` endpoint resulting in Geo secondary sites not being aware of updates to container registry images and subsequently not replicating the updates. Secondary sites may contain out of date container images after a failover as a consequence. This affects versions 15.6.0 - 15.6.6 and 15.7.0 - 15.7.2. If you're using Geo with container repositories, you are advised to upgrade to GitLab 15.6.7, 15.7.3, or 15.8.0 which contain a fix for this issue and avoid potential data loss after a failover.
- Geo: We discovered an issue where [replication and verification of projects and wikis was not keeping up](https://gitlab.com/gitlab-org/gitlab/-/issues/387980) on small number of Geo installations. Your installation may be affected if you see some projects and/or wikis persistently in the "Queued" state for verification. This can lead to data loss after a failover.
  - Affected versions: GitLab versions 15.6.x, 15.7.x, and 15.8.0 - 15.8.2.
  - Versions containing fix: GitLab 15.8.3 and later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.5.5

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.5.4

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.5.3

- GitLab 15.4.0 introduced a default [Sidekiq routing rule](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) that routes all jobs to the `default` queue. For instances using [queue selectors](../../administration/sidekiq/processing_specific_job_classes.md#queue-selectors-deprecated), this causes [performance problems](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991) as some Sidekiq processes will be idle.
  - The default routing rule has been reverted in 15.5.4, so upgrading to that version or later will return to the previous behavior.
  - If a GitLab instance now listens only to the `default` queue (which is not currently recommended), it will be required to add this routing rule back in `/etc/gitlab/gitlab.rb`:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.5.2

- GitLab 15.4.0 introduced a default [Sidekiq routing rule](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) that routes all jobs to the `default` queue. For instances using [queue selectors](../../administration/sidekiq/processing_specific_job_classes.md#queue-selectors-deprecated), this causes [performance problems](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991) as some Sidekiq processes will be idle.
  - The default routing rule has been reverted in 15.5.4, so upgrading to that version or later will return to the previous behavior.
  - If a GitLab instance now listens only to the `default` queue (which is not currently recommended), it will be required to add this routing rule back in `/etc/gitlab/gitlab.rb`:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.5.1

- GitLab 15.4.0 introduced a default [Sidekiq routing rule](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) that routes all jobs to the `default` queue. For instances using [queue selectors](../../administration/sidekiq/processing_specific_job_classes.md#queue-selectors-deprecated), this causes [performance problems](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991) as some Sidekiq processes will be idle.
  - The default routing rule has been reverted in 15.5.4, so upgrading to that version or later will return to the previous behavior.
  - If a GitLab instance now listens only to the `default` queue (which is not currently recommended), it will be required to add this routing rule back in `/etc/gitlab/gitlab.rb`:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.5.0

- GitLab 15.4.0 introduced a default [Sidekiq routing rule](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) that routes all jobs to the `default` queue. For instances using [queue selectors](../../administration/sidekiq/processing_specific_job_classes.md#queue-selectors-deprecated), this causes [performance problems](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991) as some Sidekiq processes will be idle.
  - The default routing rule has been reverted in 15.5.4, so upgrading to that version or later will return to the previous behavior.
  - If a GitLab instance now listens only to the `default` queue (which is not currently recommended), it will be required to add this routing rule back in `/etc/gitlab/gitlab.rb`:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.4.6

- Due to a [bug introduced in curl in GitLab 15.4.6](https://github.com/curl/curl/issues/10122), the [`no_proxy` environment variable may not work properly](../../administration/geo/replication/troubleshooting.md#secondary-site-returns-received-http-code-403-from-proxy-after-connect). Either downgrade to GitLab 15.4.5, or upgrade to GitLab 15.5.7 or a later version.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.4.5

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.4.4

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.4.3

- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.4.2

- A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:
  - Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
  - Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.4.1

- A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:
  - Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
  - Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.

## 15.4.0

- GitLab 15.4.0 includes a [batched background migration](../background_migrations.md#batched-background-migrations) to [remove incorrect values from `expire_at` in `ci_job_artifacts` table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89318).
  This migration might take hours or days to complete on larger GitLab instances.
- By default, Gitaly and Praefect nodes use the time server at `pool.ntp.org`. If your instance can not connect to `pool.ntp.org`, [configure the `NTP_HOST` variable](../../administration/gitaly/praefect.md#customize-time-server-setting).
- GitLab 15.4.0 introduced a default [Sidekiq routing rule](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) that routes all jobs to the `default` queue. For instances using [queue selectors](../../administration/sidekiq/processing_specific_job_classes.md#queue-selectors-deprecated), this causes [performance problems](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991) as some Sidekiq processes will be idle.
  - The default routing rule has been reverted in 15.4.5, so upgrading to that version or later will return to the previous behavior.
  - If a GitLab instance now listens only to the `default` queue (which is not currently recommended), it will be required to add this routing rule back in `/etc/gitlab/gitlab.rb`:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- New Git repositories created in Gitaly cluster [no longer use the `@hashed` storage path](../index.md#change-to-praefect-generated-replica-paths-in-gitlab-153). Server
  hooks for new repositories must be copied into a different location.
- The structure of `/etc/gitlab/gitlab-secrets.json` was modified in [GitLab 15.4](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6310),
  and new configuration was added to `gitlab_pages`, `grafana`, and `mattermost` sections.
  In a highly available or GitLab Geo environment, secrets need to be the same on all nodes.
  If you're manually syncing the secrets file across nodes, or manually specifying secrets in
  `/etc/gitlab/gitlab.rb`, make sure `/etc/gitlab/gitlab-secrets.json` is the same on all nodes.
- GitLab 15.4.0 introduced a [batched background migration](../background_migrations.md#batched-background-migrations) to
  [backfill `namespace_id` values on issues table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91921). This
  migration might take multiple hours or days to complete on larger GitLab instances. Make sure the migration
  has completed successfully before upgrading to 15.7.0 or later.
- Due to [a bug introduced in GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/390155), if one or more Git repositories in Gitaly Cluster is [unavailable](../../administration/gitaly/recovery.md#unavailable-repositories), then [Repository checks](../../administration/repository_checks.md#repository-checks) and [Geo replication and verification](../../administration/geo/index.md) stop running for all project or project wiki repositories in the affected Gitaly Cluster. The bug was fixed by [reverting the change in GitLab 15.9.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823). Before upgrading to this version, check if you have any "unavailable" repositories. See [the bug issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390155) for more information.
- A redesigned sign-in page is enabled by default in GitLab 15.4 and later, with improvements shipping in later releases. For more information, see [epic 8557](https://gitlab.com/groups/gitlab-org/-/epics/8557).
  It can be disabled with a feature flag. Start [a Rails console](../../administration/operations/rails_console.md) and run:

  ```ruby
  Feature.disable(:restyle_login_page)
  ```

## 15.3.4

A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:

- Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
- Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.3.3

- In GitLab 15.3.3, [SAML Group Links](../../api/groups.md#saml-group-links) API `access_level` attribute type changed to `integer`. See
[the API documentation](../../api/members.md).
- A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:

  - Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
  - Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3

## 15.3.2

A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:

- Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
- Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.3.1

A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:

- Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
- Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.3.0

- [Incorrect deletion of object storage files on Geo secondary sites](https://gitlab.com/gitlab-org/gitlab/-/issues/371397) can occur in certain situations. See [Geo: Incorrect object storage LFS file deletion on secondary site issue in GitLab 15.0.0 to 15.3.2](../index.md#geo-incorrect-object-storage-lfs-file-deletion-on-secondary-sites-in-gitlab-1500-to-1532).
- LFS transfers can [redirect to the primary from secondary site mid-session](https://gitlab.com/gitlab-org/gitlab/-/issues/371571) causing failed pull and clone requests when [Geo proxying](../../administration/geo/secondary_proxy/index.md) is enabled. Geo proxying is enabled by default in GitLab 15.1 and later. See [Geo: LFS transfer redirect to primary from secondary site mid-session issue in GitLab 15.1.0 to 15.3.2](../index.md#geo-lfs-transfers-redirect-to-primary-from-secondary-site-mid-session-in-gitlab-1510-to-1532) for more details.
- New Git repositories created in Gitaly cluster [no longer use the `@hashed` storage path](../index.md#change-to-praefect-generated-replica-paths-in-gitlab-153). Server
  hooks for new repositories must be copied into a different location.
- A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:

  - Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
  - Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3

## 15.2.5

A [license caching issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376706) prevents some premium features of GitLab from working correctly if you add a new license. Workarounds for this issue:

- Restart all Rails, Sidekiq and Gitaly nodes after applying a new license. This clears the relevant license caches and allows all premium features to operate correctly.
- Upgrade to a version that is not affected by this issue. The following upgrade paths are available for affected versions:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.2.0

- GitLab installations that have multiple web nodes should be
  [upgraded to 15.1](#1510) before upgrading to 15.2 (and later) due to a
  configuration change in Rails that can result in inconsistent ETag key
  generation.
- Some Sidekiq workers were renamed in this release. To avoid any disruption, [run the Rake tasks to migrate any pending jobs](../../administration/sidekiq/sidekiq_job_migration.md#migrate-queued-and-future-jobs) before starting the upgrade to GitLab 15.2.0.
- Gitaly now executes its binaries in a [runtime location](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/4670). By default on Omnibus GitLab,
  this path is `/var/opt/gitlab/gitaly/run/`. If this location is mounted with `noexec`, merge requests generate the following error:

  ```plaintext
  fork/exec /var/opt/gitlab/gitaly/run/gitaly-<nnnn>/gitaly-git2go-v15: permission denied
  ```

  To resolve this, remove the `noexec` option from the file system mount. An alternative is to change the Gitaly runtime directory:

  1. Add `gitaly['runtime_dir'] = '<PATH_WITH_EXEC_PERM>'` to `/etc/gitlab/gitlab.rb` and specify a location without `noexec` set.
  1. Run `sudo gitlab-ctl reconfigure`.
- [Incorrect deletion of object storage files on Geo secondary sites](https://gitlab.com/gitlab-org/gitlab/-/issues/371397) can occur in certain situations. See [Geo: Incorrect object storage LFS file deletion on secondary site issue in GitLab 15.0.0 to 15.3.2](../index.md#geo-incorrect-object-storage-lfs-file-deletion-on-secondary-sites-in-gitlab-1500-to-1532).
- LFS transfers can [redirect to the primary from secondary site mid-session](https://gitlab.com/gitlab-org/gitlab/-/issues/371571) causing failed pull and clone requests when [Geo proxying](../../administration/geo/secondary_proxy/index.md) is enabled. Geo proxying is enabled by default in GitLab 15.1 and later. See [Geo: LFS transfer redirect to primary from secondary site mid-session issue in GitLab 15.1.0 to 15.3.2](../index.md#geo-lfs-transfers-redirect-to-primary-from-secondary-site-mid-session-in-gitlab-1510-to-1532) for more details.

## 15.1.0

- If you run external PostgreSQL, particularly AWS RDS,
  [check you have a PostgreSQL bug fix](../index.md#postgresql-segmentation-fault-issue)
  to avoid the database crashing.
- In GitLab 15.1.0, we are switching Rails `ActiveSupport::Digest` to use SHA256 instead of MD5.
  This affects ETag key generation for resources such as raw Snippet file
  downloads. To ensure consistent ETag key generation across multiple
  web nodes when upgrading, all servers must first be upgraded to 15.1.Z before
  upgrading to 15.2.0 or later:

  1. Ensure all GitLab web nodes are running GitLab 15.1.Z.
  1. [Enable the `active_support_hash_digest_sha256` feature flag](../../administration/feature_flags.md#how-to-enable-and-disable-features-behind-flags) to switch `ActiveSupport::Digest` to use SHA256:

     1. [Start the rails console](../../administration/operations/rails_console.md)
     1. Enable the feature flag:

        ```ruby
        Feature.enable(:active_support_hash_digest_sha256)
        ```

  1. Only then, continue to upgrade to later versions of GitLab.
- Unauthenticated requests to the [`ciConfig` GraphQL field](../../api/graphql/reference/index.md#queryciconfig) are no longer supported.
  Before you upgrade to GitLab 15.1, add an [access token](../../api/rest/index.md#authentication) to your requests.
  The user creating the token must have [permission](../../user/permissions.md) to create pipelines in the project.
- [Incorrect deletion of object storage files on Geo secondary sites](https://gitlab.com/gitlab-org/gitlab/-/issues/371397) can occur in certain situations. See [Geo: Incorrect object storage LFS file deletion on secondary site issue in GitLab 15.0.0 to 15.3.2](../index.md#geo-incorrect-object-storage-lfs-file-deletion-on-secondary-sites-in-gitlab-1500-to-1532).
- LFS transfers can [redirect to the primary from secondary site mid-session](https://gitlab.com/gitlab-org/gitlab/-/issues/371571) causing failed pull and clone requests when [Geo proxying](../../administration/geo/secondary_proxy/index.md) is enabled. Geo proxying is enabled by default in GitLab 15.1 and later. See [Geo: LFS transfer redirect to primary from secondary site mid-session issue in GitLab 15.1.0 to 15.3.2](../index.md#geo-lfs-transfers-redirect-to-primary-from-secondary-site-mid-session-in-gitlab-1510-to-1532) for more details.

## 15.0.0

- Elasticsearch 6.8 [is no longer supported](../../integration/advanced_search/elasticsearch.md#version-requirements). Before you upgrade to GitLab 15.0, [update Elasticsearch to any 7.x version](../../integration/advanced_search/elasticsearch.md#upgrade-to-a-new-elasticsearch-major-version).
- If you run external PostgreSQL, particularly AWS RDS,
  [check you have a PostgreSQL bug fix](../index.md#postgresql-segmentation-fault-issue)
  to avoid the database crashing.
- The use of encrypted S3 buckets with storage-specific configuration is no longer supported after [removing support for using `background_upload`](../deprecations.md#background-upload-for-object-storage).
- The [certificate-based Kubernetes integration (DEPRECATED)](../../user/infrastructure/clusters/index.md#certificate-based-kubernetes-integration-deprecated) is disabled by default, but you can be re-enable it through the [`certificate_based_clusters` feature flag](../../administration/feature_flags.md#how-to-enable-and-disable-features-behind-flags) until GitLab 16.0.
- When you use the GitLab Helm Chart project with a custom `serviceAccount`, ensure it has `get` and `list` permissions for the `serviceAccount` and `secret` resources.
- The [`custom_hooks_dir`](../../administration/server_hooks.md#create-global-server-hooks-for-all-repositories) setting for configuring global server hooks is now configured in
  Gitaly. The previous implementation in GitLab Shell was removed in GitLab 15.0. With this change, global server hooks are stored only inside a subdirectory named after the
  hook type. Global server hooks can no longer be a single hook file in the root of the custom hooks directory. For example, you must use `<custom_hooks_dir>/<hook_name>.d/*` rather
  than `<custom_hooks_dir>/<hook_name>`.
  - Use `gitaly['custom_hooks_dir']` in `gitlab.rb` ([introduced in 14.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4208))
    for Omnibus GitLab. This replaces `gitlab_shell['custom_hooks_dir']`.
- [Incorrect deletion of object storage files on Geo secondary sites](https://gitlab.com/gitlab-org/gitlab/-/issues/371397) can occur in certain situations. See [Geo: Incorrect object storage LFS file deletion on secondary site issue in GitLab 15.0.0 to 15.3.2](../index.md#geo-incorrect-object-storage-lfs-file-deletion-on-secondary-sites-in-gitlab-1500-to-1532).
- The `FF_GITLAB_REGISTRY_HELPER_IMAGE` [feature flag](../../administration/feature_flags.md#enable-or-disable-the-feature) is removed and helper images are always pulled from GitLab Registry.
- The `AES256-GCM-SHA384` SSL cipher is no longer allowed by NGINX.
  See how you can [add the cipher back](https://docs.gitlab.com/omnibus/update/gitlab_15_changes.html#aes256-gcm-sha384-ssl-cipher-no-longer-allowed-by-default-by-nginx) to the allow list.
- Support for more than one database has been added to GitLab. For **self-compiled (source) installations**,
  `config/database.yml` must include a database name in the database configuration.
  The `main: database` must be first. If an invalid or deprecated syntax is used, an error is generated
  during application start:

  ```plaintext
  ERROR: This installation of GitLab uses unsupported 'config/database.yml'.
  The main: database needs to be defined as a first configuration item instead of primary. (RuntimeError)
  ```

  Previously, the `config/database.yml` file looked like the following:

  ```yaml
  production:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_production
    ...
  ```

  Starting with GitLab 15.0, it must define a `main` database first:

  ```yaml
  production:
    main:
      adapter: postgresql
      encoding: unicode
      database: gitlabhq_production
      ...
  ```
