---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Terraform state administration **(FREE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2673) in GitLab 12.10.

GitLab can be used as a backend for [Terraform](../user/infrastructure/index.md) state
files. The files are encrypted before being stored. This feature is enabled by default.

The storage location of these files defaults to:

- `/var/opt/gitlab/gitlab-rails/shared/terraform_state` for Omnibus GitLab installations.
- `/home/git/gitlab/shared/terraform_state` for source installations.

These locations can be configured using the options described below.

Use [external object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-pseudonymizer-terraform-state-dependency-proxy) configuration for [GitLab Helm chart](https://docs.gitlab.com/charts/) installations.

## Disabling Terraform state

To disable terraform state site-wide, follow the steps below.
A GitLab administrator may want to disable Terraform state to reduce disk space or if Terraform is not used in your instance.
To do so, follow the steps below according to your installation's type.

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

Instead of storing Terraform state files on disk, we recommend the use of [one of the supported object
storage options](object_storage.md#options). This configuration relies on valid credentials to
be configured already.

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

### S3-compatible connection settings

See [the available connection settings for different providers](object_storage.md#connection-settings).

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
1. Migrate any existing local states to the object storage (GitLab 13.9 and later):

   ```shell
   gitlab-rake gitlab:terraform_states:migrate
   ```

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
1. Migrate any existing local states to the object storage (GitLab 13.9 and later):

   ```shell
   sudo -u git -H bundle exec rake gitlab:terraform_states:migrate RAILS_ENV=production
   ```
