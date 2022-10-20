---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Repository storage Rake tasks **(FREE SELF)**

This is a collection of Rake tasks to help you list and migrate
existing projects and their attachments to the new
[hashed storage](../repository_storage_types.md) that GitLab
uses to organize the Git data.

## List projects and attachments

The following Rake tasks lists the projects and attachments that are
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
The option to choose between hashed and legacy storage in the Admin Area has
been disabled.

This task must be run on any machine that has Rails/Sidekiq configured, and the task
schedules all your existing projects and attachments associated with it to be
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

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Monitoring > Background Jobs**.
1. Watch how long the `hashed_storage:hashed_storage_project_migrate` queue
   takes to finish. After it reaches zero, you can confirm every project
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
The option to choose between hashed and legacy storage in the Admin Area has
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
On the **Queues** tab, you can watch the `hashed_storage:hashed_storage_project_rollback` queue to see how long the process takes to finish.

After it reaches zero, you can confirm every project has been rolled back by running the commands above.
If some projects weren't rolled back, you can run this rollback script again to schedule further rollbacks.
Any error or warning is logged in Sidekiq's log file.

If you have a Geo setup, the rollback is not reflected automatically
on the **secondary** node. You may need to wait for a backfill operation to kick-in and remove
the remaining repositories from the special `@hashed/` folder manually.

## Troubleshooting

The Rake task might not be able to complete the migration to hashed storage.
Checks on the instance will continue to report that there is legacy data:

```plaintext
* Found 1 projects using Legacy Storage
- janedoe/testproject (id: 1234)
```

If you have a subscription, [raise a ticket with GitLab support](https://support.gitlab.com)
as most of the fixes are relatively high risk, involving running code on the Rails console.

### Read only projects

If you have set projects as read only they might fail to migrate.

1. [Start a Rails console](../operations/rails_console.md#starting-a-rails-console-session).

1. Check if the project is read only:

   ```ruby
   project = Project.find_by_full_path('janedoe/testproject')
   project.repository_read_only
   ```

1. If it returns `true` (not `nil` or `false`), set it writable:

   ```ruby
   project.update!(repository_read_only: false)
   ```

1. [Re-run the migration Rake task](#migrate-to-hashed-storage).

1. Set the project read-only again:

   ```ruby
   project.update!(repository_read_only: true)
   ```

### Projects pending deletion

Check the project details in the Admin Area. If deleting the project failed
it will show as `Marked For Deletion At ..`, `Scheduled Deletion At ..` and
`pending removal`, but the dates will not be recent.

Delete the project using the Rails console:

1. [Start a Rails console](../operations/rails_console.md#starting-a-rails-console-session).

1. With the following code, select the project to be deleted and account to action it:

   ```ruby
   project = Project.find_by_full_path('janedoe/testproject')
   user = User.find_by_username('admin_handle')
   puts "\nproject selected for deletion is:\nID: #{project.id}\nPATH: #{project.full_path}\nNAME: #{project.name}\n\n"
   ```

   - Replace `janedoe/testproject` with your project path from the Rake take output or from the Admin Area.
   - Replace `admin_handle` with the handle of an instance administrator or with `root`.
   - Verify the output before proceeding. **There are no other checks performed**.

1. [Destroy the project](../../user/project/working_with_projects.md#delete-a-project-using-console) **immediately**:

   ```ruby
   Projects::DestroyService.new(project, user).execute
   ```

If destroying the project generates a stack trace relating to encryption or the error `OpenSSL::Cipher::CipherError`:

1. [Verify your GitLab secrets](check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

1. If the affected projects have secrets that cannot be decrypted it will be necessary to remove those specific secrets.
   [Our documentation for dealing with lost secrets](../../raketasks/backup_restore.md#when-the-secrets-file-is-lost)
   is for loss of all secrets, but it's possible for specific projects to be affected. For example,
   to [reset specific runner registration tokens](../../raketasks/backup_restore.md#reset-runner-registration-tokens)
   for a specific project ID:

   ```sql
   UPDATE projects SET runners_token = null, runners_token_encrypted = null where id = 1234;
   ```

### `Repository cannot be moved from` errors in Sidekiq log

Projects might fail to migrate with errors in the Sidekiq log:

```shell
# grep 'Repository cannot be moved' /var/log/gitlab/sidekiq/current
{"severity":"ERROR","time":"2021-02-29T02:29:02.021Z","message":"Repository cannot be moved from 'janedoe/testproject' to '@hashed<value>' (PROJECT_ID=1234)"}
```

This might be caused by [a bug](https://gitlab.com/gitlab-org/gitlab/-/issues/259605) in the original code for hashed storage migration.

[There is a workaround for projects still affected by this issue](https://gitlab.com/-/snippets/2039252).
