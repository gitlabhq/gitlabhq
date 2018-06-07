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

You can monitor the progress in the _Admin > Monitoring > Background jobs_ screen.
There is a specific Queue you can watch to see how long it will take to finish: **project_migrate_hashed_storage**

After it reaches zero, you can confirm every project has been migrated by running the commands bellow. 
If you find it necessary, you can run this migration script again to schedule missing projects.

Any error or warning will be logged in the sidekiq's log file.

You only need the `gitlab:storage:migrate_to_hashed` rake task to migrate your repositories, but we have additional
commands below that helps you inspect projects and attachments in both legacy and hashed storage.

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

------

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

------

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

------

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

------

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
