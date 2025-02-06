---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Uploads administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Uploads represent all user data that may be sent to GitLab as a single file. For example, avatars and note attachments are uploads. Uploads are integral to GitLab functionality and therefore cannot be disabled.

NOTE:
Attachments added to comments or descriptions are deleted **only** when the parent project or group
is deleted. Attachments remain in file storage even when the comment or resource (like issue, merge
request, epic) where they were uploaded is deleted.

## Using local storage

This is the default configuration. To change the location where the uploads are
stored locally, use the steps in this section based on your installation method:

NOTE:
For historical reasons, uploads for the whole instance (for example the [favicon](appearance.md#customize-the-favicon)) are stored in a base directory,
which by default is `uploads/-/system`. Changing the base
directory on an existing GitLab installation is strongly discouraged.

For Linux package installations:

_The uploads are stored by default in `/var/opt/gitlab/gitlab-rails/uploads`._

1. To change the storage path, for example to `/mnt/storage/uploads`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['uploads_directory'] = "/mnt/storage/uploads"
   ```

   This setting only applies if you haven't changed the `gitlab_rails['uploads_storage_path']` directory.

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

For self-compiled installations:

_The uploads are stored by default in
`/home/git/gitlab/public/uploads`._

1. To change the storage path, for example to `/mnt/storage/uploads`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   uploads:
     storage_path: /mnt/storage
     base_dir: uploads
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.

## Using object storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

If you don't want to use the local disk where GitLab is installed to store the
uploads, you can use an object storage provider like AWS S3 instead.
This configuration relies on valid AWS credentials to be configured already.

[Read more about using object storage with GitLab](object_storage.md).

### Object Storage Settings

This section describes the storage-specific configuration format.
You should use the
[consolidated object storage settings](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form) instead.

For self-compiled installations, the following settings are nested under `uploads:` and then `object_store:`. On Linux
package installations, they are prefixed by `uploads_object_store_`.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where Uploads are stored| |
| `proxy_download` | Set to `true` to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data | `false` |
| `connection` | Various connection options described below | |

#### Connection settings

See [the available connection settings for different providers](object_storage.md#configure-the-connection-settings).

For Linux package installations:

_The uploads are stored by default in
`/var/opt/gitlab/gitlab-rails/uploads`._

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

   ```ruby
   gitlab_rails['uploads_object_store_enabled'] = true
   gitlab_rails['uploads_object_store_remote_directory'] = "uploads"
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   If you are using AWS IAM profiles, be sure to omit the AWS access key and secret access key/value pairs.

   ```ruby
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. Migrate any existing local uploads to the object storage with the [`gitlab:uploads:migrate:all` Rake task](raketasks/uploads/migrate.md).

For self-compiled installations:

_The uploads are stored by default in
`/home/git/gitlab/public/uploads`._

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines, making sure to use the [appropriate ones for your provider](object_storage.md#configure-the-connection-settings):

   ```yaml
   uploads:
     object_store:
       enabled: true
       remote_directory: "uploads" # The bucket name
       connection: # The lines in this block depend on your provider
         provider: AWS
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.
1. Migrate any existing local uploads to the object storage with the [`gitlab:uploads:migrate:all` Rake task](raketasks/uploads/migrate.md).
