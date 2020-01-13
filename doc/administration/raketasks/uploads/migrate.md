# Uploads Migrate Rake Tasks

## Migrate to Object Storage

After [configuring the object storage](../../uploads.md#using-object-storage-core-only) for GitLab's uploads, you may use this task to migrate existing uploads from the local storage to the remote storage.

>**Note:**
All of the processing will be done in a background worker and requires **no downtime**.

### All-in-one rake task

GitLab provides a wrapper rake task that migrates all uploaded files - avatars,
logos, attachments, favicon, etc. - to object storage in one go. Under the hood,
it invokes individual rake tasks to migrate files falling under each of this
category one by one. The specifications of these individual rake tasks are
described in the next section.

**Omnibus Installation**

```bash
gitlab-rake "gitlab:uploads:migrate:all"
```

**Source Installation**

```bash
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate:all
```

### Individual rake tasks

>**Note:**
If you already ran the rake task mentioned above, no need to run these individual rake tasks as that has been done automatically.

The rake task uses 3 parameters to find uploads to migrate.

Parameter | Type | Description
--------- | ---- | -----------
`uploader_class` | string | Type of the uploader to migrate from
`model_class` | string | Type of the model to migrate from
`mount_point` | string/symbol | Name of the model's column on which the uploader is mounted on.

>**Note:**
These parameters are mainly internal to GitLab's structure, you may want to refer to the task list instead below.

This task also accepts some environment variables which you can use to override
certain values:

Variable | Type | Description
-------- | ---- | -----------
`BATCH`   | integer  | Specifies the size of the batch. Defaults to 200.

**Omnibus Installation**

```bash
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
```

**Source Installation**

>**Note:**
Use `RAILS_ENV=production` for every task.

```bash
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

```

## Migrate legacy uploads out of deprecated paths

> Introduced in GitLab 12.3.

To migrate all uploads created by legacy uploaders, run:

**Omnibus Installation**

```bash
gitlab-rake gitlab:uploads:legacy:migrate
```

**Source Installation**

```bash
bundle exec rake gitlab:uploads:legacy:migrate
```

## Migrate from object storage to local storage

If you need to disable Object Storage for any reason, first you need to migrate
your data out of Object Storage and back into your local storage.

**Before proceeding, it is important to disable both `direct_upload` and `background_upload` under `uploads` settings in `gitlab.rb`**

CAUTION: **Warning:**
**Extended downtime is required** so no new files are created in object storage during
the migration. A configuration setting will be added soon to allow migrating
from object storage to local files with only a brief moment of downtime for configuration changes.
To follow progress, see the [relevant issue](https://gitlab.com/gitlab-org/gitlab/issues/30979).

### All-in-one rake task

GitLab provides a wrapper rake task that migrates all uploaded files - avatars,
logos, attachments, favicon, etc. - to local storage in one go. Under the hood,
it invokes individual rake tasks to migrate files falling under each of this
category one by one. For details on these rake tasks please [refer to the section above](#individual-rake-tasks),
keeping in mind the task name in this case is `gitlab:uploads:migrate_to_local`.

**Omnibus Installation**

```bash
gitlab-rake "gitlab:uploads:migrate_to_local:all"
```

**Source Installation**

```bash
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate_to_local:all
```

After this is done, you may disable Object Storage by undoing the changes described
in the instructions to [configure object storage](../../uploads.md#using-object-storage-core-only)
