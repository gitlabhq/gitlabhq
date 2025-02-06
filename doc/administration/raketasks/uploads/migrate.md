---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Uploads migrate Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

There is a Rake task for migrating uploads between different storage types.

- Migrate all uploads with [`gitlab:uploads:migrate:all`](#all-in-one-rake-task) or
- To only migrate specific upload types, use [`gitlab:uploads:migrate`](#individual-rake-tasks).

## Migrate to object storage

After [configuring the object storage](../../uploads.md#using-object-storage) for uploads
to GitLab, use this task to migrate existing uploads from the local storage to the remote storage.

All of the processing is done in a background worker and requires **no downtime**.

Read more about using [object storage with GitLab](../../object_storage.md).

### All-in-one Rake task

GitLab provides a wrapper Rake task that migrates all uploaded files (for example avatars, logos,
attachments, and favicon) to object storage in one step. The wrapper task invokes individual Rake
tasks to migrate files falling under each of these categories one by one.

These [individual Rake tasks](#individual-rake-tasks) are described in the next section.

To migrate all uploads from local storage to object storage, run:

- Linux package installations:

  ```shell
  gitlab-rake "gitlab:uploads:migrate:all"
  ```

- Self-compiled installations:

  ```shell
  sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate:all
  ```

You can optionally track progress and verify that all uploads migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- `sudo gitlab-rails dbconsole --database main` for Linux package installations.
- `sudo -u git -H psql -d gitlabhq_production` for self-compiled installations.

Verify `objectstg` below (where `store=2`) has count of all artifacts:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

total | filesystem | objectstg
------+------------+-----------
   2409 |          0 |      2409
```

Verify that there are no files on disk in the `uploads` folder:

```shell
sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
```

### Individual Rake tasks

If you already ran the [all-in-one Rake task](#all-in-one-rake-task), there is no need to run these
individual tasks.

The Rake task uses three parameters to find uploads to migrate:

| Parameter        | Type          | Description                                            |
|:-----------------|:--------------|:-------------------------------------------------------|
| `uploader_class` | string        | Type of the uploader to migrate from.                  |
| `model_class`    | string        | Type of the model to migrate from.                     |
| `mount_point`    | string/symbol | Name of the model's column the uploader is mounted on. |

NOTE:
These parameters are mainly internal to the structure of GitLab, you may want to refer to the task list
instead below. After running these individual tasks, we recommend that you run the [all-in-one Rake task](#all-in-one-rake-task)
to migrate any uploads not included in the listed types.

This task also accepts an environment variable which you can use to override
the default batch size:

| Variable | Type    | Description                                       |
|:---------|:--------|:--------------------------------------------------|
| `BATCH`  | integer | Specifies the size of the batch. Defaults to 200. |

The following shows how to run `gitlab:uploads:migrate` for individual types of uploads.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
# gitlab-rake gitlab:uploads:migrate[uploader_class, model_class, mount_point]

# Avatars
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Note, :attachment]"
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
gitlab-rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
gitlab-rake "gitlab:uploads:migrate[FileUploader, Project]"
gitlab-rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
gitlab-rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action, :image_v432x230]"
```

:::TabTitle Self-compiled (source)

Use `RAILS_ENV=production` for every task.

```shell
# sudo -u git -H bundle exec rake gitlab:uploads:migrate

# Avatars
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Note, :attachment]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, Project]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action]"
```

::EndTabs

## Migrate to local storage

If you need to disable [object storage](../../object_storage.md) for any reason, you must first
migrate your data out of object storage and back into your local storage.

WARNING:
**Extended downtime is required** so no new files are created in object storage during
the migration. A configuration setting to allow migrating
from object storage to local files with only a brief moment of downtime for configuration changes
is tracked [in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/30979).

### All-in-one Rake task

GitLab provides a wrapper Rake task that migrates all uploaded files (for example, avatars, logos,
attachments, and favicon) to local storage in one step. The wrapper task invokes individual Rake
tasks to migrate files falling under each of these categories one by one.

For details on these Rake tasks, refer to [Individual Rake tasks](#individual-rake-tasks).
Keep in mind the task name in this case is `gitlab:uploads:migrate_to_local`.

To migrate uploads from object storage to local storage, run the following Rake task:

- Linux package installations:

  ```shell
  gitlab-rake "gitlab:uploads:migrate_to_local:all"
  ```

- Self-compiled installations:

  ```shell
  sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate_to_local:all
  ```

After running the Rake task, you can disable object storage by undoing the changes described
in the instructions to [configure object storage](../../uploads.md#using-object-storage).
