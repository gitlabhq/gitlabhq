---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraform state administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab can be used as a backend for [Terraform](../user/infrastructure/_index.md) state
files. The files are encrypted before being stored. This feature is enabled by default.

The storage location of these files defaults to:

- `/var/opt/gitlab/gitlab-rails/shared/terraform_state` for Linux package installations.
- `/home/git/gitlab/shared/terraform_state` for self-compiled installations.

These locations can be configured using the options described below.

Use [external object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy) configuration for [GitLab Helm chart](https://docs.gitlab.com/charts/) installations.

## Disabling Terraform state

You can disable Terraform state across the entire instance. You might want to disable Terraform to reduce disk space,
or because your instance doesn't use Terraform.

When Terraform state administration is disabled:

- On the left sidebar, you cannot select **Operate > Terraform states**.
- Any CI/CD jobs that access the Terraform state fail with this error:

  ```shell
  Error refreshing state: HTTP remote state endpoint invalid auth
  ```

To disable Terraform administration, follow the steps below according to your installation.

Prerequisites:

- You must be an administrator.

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['terraform_state_enabled'] = false
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

For self-compiled installations:

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   terraform_state:
     enabled: false
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.

## Using local storage

The default configuration uses local storage. To change the location where
Terraform state files are stored locally, follow the steps below.

For Linux package installations:

1. To change the storage path for example to `/mnt/storage/terraform_state`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['terraform_state_storage_path'] = "/mnt/storage/terraform_state"
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

For self-compiled installations:

1. To change the storage path for example to `/mnt/storage/terraform_state`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   terraform_state:
     enabled: true
     storage_path: /mnt/storage/terraform_state
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.

## Using object storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Instead of storing Terraform state files on disk, we recommend the use of
[one of the supported object storage options](object_storage.md#supported-object-storage-providers).
This configuration relies on valid credentials to be configured already.

[Read more about using object storage with GitLab](object_storage.md).

### Object storage settings

The following settings are:

- Prefixed by `terraform_state_object_store_` on Linux package installations.
- Nested under `terraform_state:` and then `object_store:` on self-compiled installations.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where Terraform state files are stored | |
| `connection` | Various connection options described below | |

### Migrate to object storage

WARNING:
It's not possible to migrate Terraform state files from object storage back to local storage,
so proceed with caution. [An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/350187)
to change this behavior.

To migrate Terraform state files to object storage:

- For Linux package installations:

  ```shell
  gitlab-rake gitlab:terraform_states:migrate
  ```

- For self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:terraform_states:migrate RAILS_ENV=production
  ```

You can optionally track progress and verify that all Terraform state files migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- `sudo gitlab-rails dbconsole --database main` for Linux package installations.
- `sudo -u git -H psql -d gitlabhq_production` for self-compiled installations.

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

You should use the
[consolidated object storage settings](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
This section describes the earlier configuration format.

See [the available connection settings for different providers](object_storage.md#configure-the-connection-settings).

::Tabs

:::TabTitle Linux package (Omnibus)

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

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. [Migrate any existing local states to the object storage](#migrate-to-object-storage)

:::TabTitle Self-compiled (source)

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

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.
1. [Migrate any existing local states to the object storage](#migrate-to-object-storage)

::EndTabs

### Find a Terraform state file path

Terraform state files are stored in the hashed directory path of the relevant project.

The format of the path is `/var/opt/gitlab/gitlab-rails/shared/terraform_state/<path>/<to>/<projectHashDirectory>/<UUID>/0.tfstate`, where [UUID](https://gitlab.com/gitlab-org/gitlab/-/blob/dcc47a95c7e1664cb15bef9a70f2a4eefa9bd99a/app/models/terraform/state.rb#L33) is randomly defined.

To find a state file path:

1. Add `get-terraform-path` to your shell:

   ```shell
   get-terraform-path() {
       PROJECT_HASH=$(echo -n $1 | openssl dgst -sha256 | sed 's/^.* //')
       echo "${PROJECT_HASH:0:2}/${PROJECT_HASH:2:2}/${PROJECT_HASH}"
   }
   ```

1. Run `get-terraform-path <project_id>`.

   ```shell
   $ get-terraform-path 650
   20/99/2099a9b5f777e242d1f9e19d27e232cc71e2fa7964fc988a319fce5671ca7f73
   ```

The relative path is displayed.

## Restoring Terraform state files from backups

To restore Terraform state files from backups, you must have access to the encrypted state files and the GitLab database.

### Database tables

The following database table helps trace the S3 path back to specific projects:

- `terraform_states`: Contains the base state information, including the universally unique ID (UUID) for each state.

### File structure and path composition

The state files are stored in a specific directory structure, where:

- The first three segments of the path are derived from the SHA-2 hash value of the project ID.
- Each state has a UUID stored on the `terraform_states` database table that forms part of the path.  

For example, for a project where the:

- Project ID is `12345`
- State UUID is `example-uuid`

If the SHA-2 hash value of `12345` is `5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5`, the folder structure would be:

```plaintext
terraform/                                                                 <- configured Terraform storage directory
├─ 59/                                                                     <- first and second character of project ID hash
|  ├─ 94/                                                                  <- third and fourth character of project ID hash
|  |  ├─ 5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5/ <- full project ID hash
|  |  |  ├─ example-uuid/                                                  <- state UUID
|  |  |  |  ├─ 1.tf                                                        <- individual state versions
|  |  |  |  ├─ 2.tf
|  |  |  |  ├─ 3.tf
```

### Decryption process

The state files are encrypted using Lockbox and require the following information for decryption:

- The `db_key_base` [application secret](../development/application_secrets.md#secret-entries)
- The project ID

The encryption key is derived from both the `db_key_base` and the project ID. If you can't access `db_key_base`, decryption is not possible.

To learn how to manually decrypt files, see the documentation from [Lockbox](https://github.com/ankane/lockbox).

To view the encryption key generation process, see the [state uploader code](https://gitlab.com/gitlab-org/gitlab/-/blob/e0137111fbbd28316f38da30075aba641e702b98/app/uploaders/terraform/state_uploader.rb#L43).
