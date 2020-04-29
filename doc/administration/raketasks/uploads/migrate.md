# Uploads migrate Rake tasks **(CORE ONLY)**

`gitlab:uploads:migrate` migrates uploads between different storage types.

## Migrate to object storage

After [configuring the object storage](../../uploads.md#using-object-storage-core-only) for GitLab's
uploads, use this task to migrate existing uploads from the local storage to the remote storage.

Read more about using [object storage with GitLab](../../object_storage.md).

NOTE: **Note:**
All of the processing will be done in a background worker and requires **no downtime**.

### All-in-one Rake task

GitLab provides a wrapper Rake task that migrates all uploaded files (for example avatars, logos,
attachments, and favicon) to object storage in one step. The wrapper task invokes individual Rake
tasks to migrate files falling under each of these categories one by one.

These [individual Rake tasks](#individual-rake-tasks) are described in the next section.

To migrate all uploads from local storage to object storage, run:

**Omnibus Installation**

```shell
gitlab-rake "gitlab:uploads:migrate:all"
```

**Source Installation**

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate:all
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

NOTE: **Note:**
These parameters are mainly internal to GitLab's structure, you may want to refer to the task list
instead below.

This task also accepts an environment variable which you can use to override
the default batch size:

| Variable | Type    | Description                                       |
|:---------|:--------|:--------------------------------------------------|
| `BATCH`  | integer | Specifies the size of the batch. Defaults to 200. |

The following shows how to run `gitlab:uploads:migrate` for individual types of uploads.

**Omnibus Installation**

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

# Design Management design thumbnails (EE)
gitlab-rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action, :image_v432x230]"
```

**Source Installation**

NOTE: **Note:**
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

# Design Management design thumbnails (EE)
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action]"
```

## Migrate to local storage

If you need to disable [object storage](../../object_storage.md) for any reason, you must first
migrate your data out of object storage and back into your local storage.

CAUTION: **Warning:**
**Extended downtime is required** so no new files are created in object storage during
the migration. A configuration setting will be added soon to allow migrating
from object storage to local files with only a brief moment of downtime for configuration changes.
To follow progress, see the [relevant issue](https://gitlab.com/gitlab-org/gitlab/issues/30979).

### All-in-one Rake task

GitLab provides a wrapper Rake task that migrates all uploaded files (for example, avatars, logos,
attachments, and favicon) to local storage in one step. The wrapper task invokes individual Rake
tasks to migrate files falling under each of these categories one by one.

For details on these Rake tasks, refer to [Individual Rake tasks](#individual-rake-tasks),
keeping in mind the task name in this case is `gitlab:uploads:migrate_to_local`.

To migrate uploads from object storage to local storage:

1. Disable both `direct_upload` and `background_upload` under `uploads` settings in `gitlab.rb`.
1. Run the Rake task:

   **Omnibus Installation**

   ```shell
   gitlab-rake "gitlab:uploads:migrate_to_local:all"
   ```

   **Source Installation**

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate_to_local:all
   ```

After running the Rake task, you can disable object storage by undoing the changes described
in the instructions to [configure object storage](../../uploads.md#using-object-storage-core-only).
