---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Terraform state administration **(FREE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2673) in GitLab 12.10.

GitLab can be used as a backend for [Terraform](../user/infrastructure/index.md) state
files. The files are encrypted before being stored. This feature is enabled by default.

The storage location of these files defaults to:

- `/var/opt/gitlab/gitlab-rails/shared/terraform_state` for Omnibus GitLab installations.
- `/home/git/gitlab/shared/terraform_state` for source installations.

These locations can be configured using the options described below.

Use [external object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy) configuration for [GitLab Helm chart](https://docs.gitlab.com/charts/) installations.

## Disabling Terraform state

You can disable Terraform state across the entire instance. You might want to disable Terraform to reduce disk space,
or because your instance doesn't use Terraform.

When Terraform state administration is disabled:

- On the left sidebar, you cannot select **Infrastructure > Terraform**.
- Any CI/CD jobs that access the Terraform state fail with this error:

    ```shell
    Error refreshing state: HTTP remote state endpoint invalid auth
    ```

To disable Terraform administration, follow the steps below according to your installation.

Prerequisite:

- You must be an administrator.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['terraform_state_enabled'] = false
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   terraform_state:
     enabled: false
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

## Using local storage

The default configuration uses local storage. To change the location where
Terraform state files are stored locally, follow the steps below.

**In Omnibus installations:**

1. To change the storage path for example to `/mnt/storage/terraform_state`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['terraform_state_storage_path'] = "/mnt/storage/terraform_state"
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. To change the storage path for example to `/mnt/storage/terraform_state`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   terraform_state:
     enabled: true
     storage_path: /mnt/storage/terraform_state
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

## Using object storage **(FREE SELF)**

Instead of storing Terraform state files on disk, we recommend the use of
[one of the supported object storage options](object_storage.md#supported-object-storage-providers).
This configuration relies on valid credentials to be configured already.

[Read more about using object storage with GitLab](object_storage.md).

### Object storage settings

The following settings are:

- Nested under `terraform_state:` and then `object_store:` on source installations.
- Prefixed by `terraform_state_object_store_` on Omnibus GitLab installations.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where Terraform state files are stored | |
| `connection` | Various connection options described below | |

### Migrate to object storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/247042) in GitLab 13.9.

WARNING:
It's not possible to migrate Terraform state files from object storage back to local storage,
so proceed with caution. [An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/350187)
to change this behavior.

To migrate Terraform state files to object storage, follow the instructions below.

- For Omnibus package installations:

  ```shell
  gitlab-rake gitlab:terraform_states:migrate
  ```

- For source installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:terraform_states:migrate RAILS_ENV=production
  ```

For GitLab 13.8 and earlier versions, you can use a workaround for the Rake task:

1. Open the GitLab [Rails console](operations/rails_console.md).
1. Run the following commands:

   ```ruby
   Terraform::StateUploader.alias_method(:upload, :model)

   Terraform::StateVersion.where(file_store: ::ObjectStorage::Store::LOCAL).   find_each(batch_size: 10) do |terraform_state_version|
     puts "Migrating: #{terraform_state_version.inspect}"

     terraform_state_version.file.migrate!(::ObjectStorage::Store::REMOTE)
   end
   ```

You can optionally track progress and verify that all Terraform state files migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- `sudo gitlab-rails dbconsole` for Omnibus GitLab 14.1 and earlier.
- `sudo gitlab-rails dbconsole --database main` for Omnibus GitLab 14.2 and later.
- `sudo -u git -H psql -d gitlabhq_production` for source-installed instances.

Verify `objectstg` below (where `file_store=2`) has count of all states:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM terraform_state_versions;

total | filesystem | objectstg
------+------------+-----------
   15 |          0 |      15
```

Verify that there are no files on disk in the `terraform_state` folder:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/terraform_state -type f | grep -v tmp | wc -l
```

### S3-compatible connection settings

In GitLab 13.2 and later, you should use the
[consolidated object storage settings](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
This section describes the earlier configuration format.

See [the available connection settings for different providers](object_storage.md#configure-the-connection-settings).

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines; replacing with
   the values you want:

   ```ruby
   gitlab_rails['terraform_state_object_store_enabled'] = true
   gitlab_rails['terraform_state_object_store_remote_directory'] = "terraform"
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   NOTE:
   If you are using AWS IAM profiles, be sure to omit the AWS access key and secret access key/value pairs.

   ```ruby
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. [Migrate any existing local states to the object storage](#migrate-to-object-storage)

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   terraform_state:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "terraform" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.
1. [Migrate any existing local states to the object storage](#migrate-to-object-storage)
