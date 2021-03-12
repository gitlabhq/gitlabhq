---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Uploads administration **(FREE SELF)**

Uploads represent all user data that may be sent to GitLab as a single file. As an example, avatars and notes' attachments are uploads. Uploads are integral to GitLab functionality, and therefore cannot be disabled.

## Using local storage

This is the default configuration. To change the location where the uploads are
stored locally, use the steps in this section based on your installation method:

NOTE:
For historical reasons, instance level uploads (for example the [favicon](../user/admin_area/appearance.md#favicon)) are stored into a base directory,
which by default is `uploads/-/system`. It is strongly discouraged to change the base
directory on an existing GitLab installation.

**In Omnibus GitLab installations:**

_The uploads are stored by default in `/var/opt/gitlab/gitlab-rails/uploads`._

1. To change the storage path for example to `/mnt/storage/uploads`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['uploads_directory'] = "/mnt/storage/uploads"
   ```

   This setting only applies if you haven't changed the `gitlab_rails['uploads_storage_path']` directory.

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

_The uploads are stored by default in
`/home/git/gitlab/public/uploads`._

1. To change the storage path for example to `/mnt/storage/uploads`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   uploads:
     storage_path: /mnt/storage
     base_dir: uploads
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

## Using object storage **(FREE SELF)**

> **Notes:**
>
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/3867) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.5.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17358) in [GitLab Free](https://about.gitlab.com/pricing/) 10.7.
> - Since version 11.1, we support direct_upload to S3.

If you don't want to use the local disk where GitLab is installed to store the
uploads, you can use an object storage provider like AWS S3 instead.
This configuration relies on valid AWS credentials to be configured already.

[Read more about using object storage with GitLab](object_storage.md).

We recommend using the [consolidated object storage settings](object_storage.md#consolidated-object-storage-configuration). The following instructions apply to the original configuration format.

### Object Storage Settings

For source installations the following settings are nested under `uploads:` and then `object_store:`. On Omnibus GitLab installs they are prefixed by `uploads_object_store_`.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where Uploads will be stored| |
| `direct_upload` | Set to `true` to remove Puma from the Upload path. Workhorse handles the actual Artifact Upload to Object Storage while Puma does minimal processing to keep track of the upload. There is no need for local shared storage. The option may be removed if support for a single storage type for all files is introduced. Read more on [direct upload](../development/uploads.md#direct-upload). | `false` |
| `background_upload` | Set to `false` to disable automatic upload. Option may be removed once upload is direct to S3 (if `direct_upload` is set to `true` it will override `background_upload`) | `true` |
| `proxy_download` | Set to `true` to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data | `false` |
| `connection` | Various connection options described below | |

#### Connection settings

See [the available connection settings for different providers](object_storage.md#connection-settings).

**In Omnibus installations:**

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

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Migrate any existing local uploads to the object storage using [`gitlab:uploads:migrate` Rake task](raketasks/uploads/migrate.md).
1. Optional: Verify all files migrated properly.
   From [PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)
   (`sudo gitlab-psql -d gitlabhq_production`) verify `objectstg` below (where `store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
   ```

**In installations from source:**

_The uploads are stored by default in
`/home/git/gitlab/public/uploads`._

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   uploads:
     object_store:
       enabled: true
       remote_directory: "uploads" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.
1. Migrate any existing local uploads to the object storage using [`gitlab:uploads:migrate:all` Rake task](raketasks/uploads/migrate.md).
1. Optional: Verify all files migrated properly.
   From PostgreSQL console (`sudo -u git -H psql -d gitlabhq_production`) verify `objectstg` below (where `file_store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
   ```

#### OpenStack example

**In Omnibus installations:**

_The uploads are stored by default in
`/var/opt/gitlab/gitlab-rails/uploads`._

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

   ```ruby
   gitlab_rails['uploads_object_store_remote_directory'] = "OPENSTACK_OBJECT_CONTAINER_NAME"
   gitlab_rails['uploads_object_store_connection'] = {
    'provider' => 'OpenStack',
    'openstack_username' => 'OPENSTACK_USERNAME',
    'openstack_api_key' => 'OPENSTACK_PASSWORD',
    'openstack_temp_url_key' => 'OPENSTACK_TEMP_URL_KEY',
    'openstack_auth_url' => 'https://auth.cloud.ovh.net/v2.0/',
    'openstack_region' => 'DE1',
    'openstack_tenant' => 'TENANT_ID',
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Migrate any existing local uploads to the object storage using [`gitlab:uploads:migrate:all` Rake task](raketasks/uploads/migrate.md).
1. Optional: Verify all files migrated properly.
   From [PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)
   (`sudo gitlab-psql -d gitlabhq_production`) verify `objectstg` below (where `store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
   ```

---

**In installations from source:**

_The uploads are stored by default in
`/home/git/gitlab/public/uploads`._

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   uploads:
     object_store:
       enabled: true
       direct_upload: false
       background_upload: true
       proxy_download: false
       remote_directory: OPENSTACK_OBJECT_CONTAINER_NAME
       connection:
         provider: OpenStack
         openstack_username: OPENSTACK_USERNAME
         openstack_api_key: OPENSTACK_PASSWORD
         openstack_temp_url_key: OPENSTACK_TEMP_URL_KEY
         openstack_auth_url: 'https://auth.cloud.ovh.net/v2.0/'
         openstack_region: DE1
         openstack_tenant: 'TENANT_ID'
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Migrate any existing local uploads to the object storage using [`gitlab:uploads:migrate:all` Rake task](raketasks/uploads/migrate.md).
1. Optional: Verify all files migrated properly.
   From PostgreSQL console (`sudo -u git -H psql -d gitlabhq_production`) verify `objectstg` below (where `file_store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
   ```
