# Repository Storage Rake Tasks

This is a collection of rake tasks you can use to help you list and migrate
existing projects and attachments associated with it from Legacy storage to
the new Hashed storage type.

You can read more about the storage types [here][storage-types].

## Migrate existing projects to Hashed storage

Before migrating your existing projects, you should
[enable hashed storage][storage-migration] for the new projects as well.

This task will schedule all your existing projects and attachments associated with it to be migrated to the
**Hashed** storage type:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:migrate_to_hashed
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:migrate_to_hashed RAILS_ENV=production
```

They both also accept a range as environment variable:

```bash
# to migrate any non migrated project from ID 20 to 50.
export ID_FROM=20
export ID_TO=50
```

You can monitor the progress in the **Admin Area > Monitoring > Background Jobs** page.
There is a specific Queue you can watch to see how long it will take to finish:
`hashed_storage:hashed_storage_project_migrate`

After it reaches zero, you can confirm every project has been migrated by running the commands bellow.
If you find it necessary, you can run this migration script again to schedule missing projects.

Any error or warning will be logged in Sidekiq's log file.

NOTE: **Note:**
If Geo is enabled, each project that is successfully migrated generates an event to replicate the changes on any **secondary** nodes.

You only need the `gitlab:storage:migrate_to_hashed` rake task to migrate your repositories, but we have additional
commands below that helps you inspect projects and attachments in both legacy and hashed storage.

## Rollback from Hashed storage to Legacy storage

If you need to rollback the storage migration for any reason, you can follow the steps described here.

NOTE: **Note:** Hashed Storage will be required in future version of GitLab.

To prevent new projects from being created in the Hashed storage,
you need to undo the [enable hashed storage][storage-migration] changes.

This task will schedule all your existing projects and associated attachments to be rolled back to the
Legacy storage type.

For Omnibus installations, run the following:

```bash
sudo gitlab-rake gitlab:storage:rollback_to_legacy
```

For source installations, run the following:

```bash
sudo -u git -H bundle exec rake gitlab:storage:rollback_to_legacy RAILS_ENV=production
```

Both commands accept a range as environment variable:

```bash
# to rollback any migrated project from ID 20 to 50.
export ID_FROM=20
export ID_TO=50
```

You can monitor the progress in the **Admin Area > Monitoring > Background Jobs** page.
On the **Queues** tab, you can watch the `hashed_storage:hashed_storage_project_rollback` queue to see how long the process will take to finish.

After it reaches zero, you can confirm every project has been rolled back by running the commands bellow.
If some projects weren't rolled back, you can run this rollback script again to schedule further rollbacks.

Any error or warning will be logged in Sidekiq's log file.

## List projects on Legacy storage

To have a simple summary of projects using **Legacy** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:legacy_projects
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:legacy_projects RAILS_ENV=production
```

---

To list projects using **Legacy** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:list_legacy_projects
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:list_legacy_projects RAILS_ENV=production

```

## List projects on Hashed storage

To have a simple summary of projects using **Hashed** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:hashed_projects
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:hashed_projects RAILS_ENV=production
```

---

To list projects using **Hashed** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:list_hashed_projects
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:list_hashed_projects RAILS_ENV=production
```

## List attachments on Legacy storage

To have a simple summary of project attachments using **Legacy** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:legacy_attachments
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:legacy_attachments RAILS_ENV=production
```

---

To list project attachments using **Legacy** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:list_legacy_attachments
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:list_legacy_attachments RAILS_ENV=production
```

## List attachments on Hashed storage

To have a simple summary of project attachments using **Hashed** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:hashed_attachments
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:hashed_attachments RAILS_ENV=production
```

---

To list project attachments using **Hashed** storage:

**Omnibus Installation**

```bash
sudo gitlab-rake gitlab:storage:list_hashed_attachments
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:storage:list_hashed_attachments RAILS_ENV=production
```

[storage-types]: ../repository_storage_types.md
[storage-migration]: ../repository_storage_types.md#how-to-migrate-to-hashed-storage
