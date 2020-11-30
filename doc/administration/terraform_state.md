---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Terraform state administration (alpha)

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2673) in GitLab 12.10.

GitLab can be used as a backend for [Terraform](../user/infrastructure/index.md) state
files. The files are encrypted before being stored. This feature is enabled by default.

The storage location of these files defaults to:

- `/var/opt/gitlab/gitlab-rails/shared/terraform_state` for Omnibus GitLab installations.
- `/home/git/gitlab/shared/terraform_state` for source installations.

These locations can be configured using the options described below.

## Using local storage

NOTE: **Note:**
This is the default configuration

To change the location where Terraform state files are stored locally, follow the steps
below.

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

## Using object storage **(CORE ONLY)**

Instead of storing Terraform state files on disk, we recommend the use of an object
store that is S3-compatible instead. This configuration relies on valid credentials to
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

   NOTE: **Note:**
   If you are using AWS IAM profiles, be sure to omit the AWS access key and secret access key/value pairs.

   ```ruby
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

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
         aws_access_key_id: AWS_ACESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.
