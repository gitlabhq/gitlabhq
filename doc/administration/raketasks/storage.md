---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Repository storage Rake tasks **(FREE SELF)**

This is a collection of Rake tasks to help you list and migrate
existing projects and their attachments to the new
[hashed storage](../repository_storage_types.md) that GitLab
uses to organize the Git data.

## List projects and attachments

The following Rake tasks will list the projects and attachments that are
available on legacy and hashed storage.

### On legacy storage

To have a summary and then a list of projects and their attachments using legacy storage:

- **Omnibus installation**

  ```shell
  # Projects
  sudo gitlab-rake gitlab:storage:legacy_projects
  sudo gitlab-rake gitlab:storage:list_legacy_projects

  # Attachments
  sudo gitlab-rake gitlab:storage:legacy_attachments
  sudo gitlab-rake gitlab:storage:list_legacy_attachments
  ```

- **Source installation**

  ```shell
  # Projects
  sudo -u git -H bundle exec rake gitlab:storage:legacy_projects RAILS_ENV=production
  sudo -u git -H bundle exec rake gitlab:storage:list_legacy_projects RAILS_ENV=production

  # Attachments
  sudo -u git -H bundle exec rake gitlab:storage:legacy_attachments RAILS_ENV=production
  sudo -u git -H bundle exec rake gitlab:storage:list_legacy_attachments RAILS_ENV=production
  ```

### On hashed storage

To have a summary and then a list of projects and their attachments using hashed storage:

- **Omnibus installation**

  ```shell
  # Projects
  sudo gitlab-rake gitlab:storage:hashed_projects
  sudo gitlab-rake gitlab:storage:list_hashed_projects

  # Attachments
  sudo gitlab-rake gitlab:storage:hashed_attachments
  sudo gitlab-rake gitlab:storage:list_hashed_attachments
  ```

- **Source installation**

  ```shell
  # Projects
  sudo -u git -H bundle exec rake gitlab:storage:hashed_projects RAILS_ENV=production
  sudo -u git -H bundle exec rake gitlab:storage:list_hashed_projects RAILS_ENV=production

  # Attachments
  sudo -u git -H bundle exec rake gitlab:storage:hashed_attachments RAILS_ENV=production
  sudo -u git -H bundle exec rake gitlab:storage:list_hashed_attachments RAILS_ENV=production
  ```

## Migrate to hashed storage

WARNING:
In GitLab 13.0, [hashed storage](../repository_storage_types.md#hashed-storage)
is enabled by default and the legacy storage is deprecated.
GitLab 14.0 eliminates support for legacy storage. If you're on GitLab
13.0 and later, switching new projects to legacy storage is not possible.
The option to choose between hashed and legacy storage in the admin area has
been disabled.

This task must be run on any machine that has Rails/Sidekiq configured and will
schedule all your existing projects and attachments associated with it to be
migrated to the **Hashed** storage type:

- **Omnibus installation**

  ```shell
  sudo gitlab-rake gitlab:storage:migrate_to_hashed
  ```

- **Source installation**

  ```shell
  sudo -u git -H bundle exec rake gitlab:storage:migrate_to_hashed RAILS_ENV=production
  ```

If you have any existing integration, you may want to do a small rollout first,
to validate. You can do so by specifying an ID range with the operation by using
the environment variables `ID_FROM` and `ID_TO`. For example, to limit the rollout
to project IDs 50 to 100 in an Omnibus GitLab installation:

```shell
sudo gitlab-rake gitlab:storage:migrate_to_hashed ID_FROM=50 ID_TO=100
```

To monitor the progress in GitLab:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Monitoring > Background Jobs**.
1. Watch how long the `hashed_storage:hashed_storage_project_migrate` queue
   will take to finish. After it reaches zero, you can confirm every project
   has been migrated by running the commands above.

If you find it necessary, you can run the previous migration script again to schedule missing projects.

Any error or warning is logged in Sidekiq's log file.

If [Geo](../geo/index.md) is enabled, each project that is successfully migrated
generates an event to replicate the changes on any **secondary** nodes.

You only need the `gitlab:storage:migrate_to_hashed` Rake task to migrate your repositories, but there are
[additional commands](#list-projects-and-attachments) to help you inspect projects and attachments in both legacy and hashed storage.

## Rollback from hashed storage to legacy storage

WARNING:
In GitLab 13.0, [hashed storage](../repository_storage_types.md#hashed-storage)
is enabled by default and the legacy storage is deprecated.
GitLab 14.0 eliminates support for legacy storage. If you're on GitLab
13.0 and later, switching new projects to legacy storage is not possible.
The option to choose between hashed and legacy storage in the admin area has
been disabled.

This task schedules all your existing projects and associated attachments to be rolled back to the
legacy storage type.

- **Omnibus installation**

  ```shell
  sudo gitlab-rake gitlab:storage:rollback_to_legacy
  ```

- **Source installation**

  ```shell
  sudo -u git -H bundle exec rake gitlab:storage:rollback_to_legacy RAILS_ENV=production
  ```

If you have any existing integration, you may want to do a small rollback first,
to validate. You can do so by specifying an ID range with the operation by using
the environment variables `ID_FROM` and `ID_TO`. For example, to limit the rollout
to project IDs 50 to 100 in an Omnibus GitLab installation:

```shell
sudo gitlab-rake gitlab:storage:rollback_to_legacy ID_FROM=50 ID_TO=100
```

You can monitor the progress in the **Admin Area > Monitoring > Background Jobs** page.
On the **Queues** tab, you can watch the `hashed_storage:hashed_storage_project_rollback` queue to see how long the process will take to finish.

After it reaches zero, you can confirm every project has been rolled back by running the commands above.
If some projects weren't rolled back, you can run this rollback script again to schedule further rollbacks.
Any error or warning is logged in Sidekiq's log file.

If you have a Geo setup, the rollback will not be reflected automatically
on the **secondary** node. You may need to wait for a backfill operation to kick-in and remove
the remaining repositories from the special `@hashed/` folder manually.
