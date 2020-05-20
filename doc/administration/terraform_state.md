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
   gitlab_rails['terraform_state_enabled'] = true
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
| `remote_directory` | The bucket name where Terraform state files will be stored | |
| `connection` | Various connection options described below | |

### S3-compatible connection settings

The connection settings match those provided by [Fog](https://github.com/fog), and are as follows:

| Setting | Description | Default |
|---------|-------------|---------|
| `provider` | Always `AWS` for compatible hosts | `AWS` |
| `aws_access_key_id` | Credentials for AWS or compatible provider | |
| `aws_secret_access_key` | Credentials for AWS or compatible provider | |
| `aws_signature_version` | AWS signature version to use. 2 or 4 are valid options. Digital Ocean Spaces and other providers may need 2. | 4 |
| `enable_signature_v4_streaming` | Set to true to enable HTTP chunked transfers with [AWS v4 signatures](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html). Oracle Cloud S3 needs this to be false | `true` |
| `region` | AWS region | us-east-1 |
| `host` | S3-compatible host when not using AWS. For example, `localhost` or `storage.example.com` | `s3.amazonaws.com` |
| `endpoint` | Can be used when configuring an S3-compatible service such as [MinIO](https://min.io), by entering a URL such as `http://127.0.0.1:9000` | (optional) |
| `path_style` | Set to true to use `host/bucket_name/object` style paths instead of `bucket_name.host/object`. Leave as false for AWS S3 | `false` |
| `use_iam_profile` | For AWS S3, set to true to use an IAM profile instead of access keys | `false` |

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines; replacing with
   the values you want:

   ```ruby
   gitlab_rails['terraform_state_enabled'] = true
   gitlab_rails['terraform_state_object_store_enabled'] = true
   gitlab_rails['terraform_state_object_store_remote_directory'] = "terraform_state"
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
       remote_directory: "terraform_state" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.
