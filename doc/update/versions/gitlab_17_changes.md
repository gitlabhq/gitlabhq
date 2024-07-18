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

1. [Identify any access tokens without an expiration date](../../security/token_overview.md#find-tokens-with-no-expiration-date).
1. [Give those tokens an expiration date](../../security/token_overview.md#extend-token-lifetime).

For more information, see the:

- [Deprecations and removals documentation](../../update/deprecations.md#non-expiring-access-tokens).
- [Deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369122).

## 17.3.0

- Git 2.45.0 and later is required by Gitaly. For installations from source, you should use the [Git version provided by Gitaly](../../install/installation.md#git).

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
