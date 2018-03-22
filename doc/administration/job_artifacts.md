# Jobs artifacts administration

>**Notes:**
>- Introduced in GitLab 8.2 and GitLab Runner 0.7.0.
>- Starting with GitLab 8.4 and GitLab Runner 1.0, the artifacts archive format
   changed to `ZIP`.
>- Starting with GitLab 8.17, builds are renamed to jobs.
>- This is the administration documentation. For the user guide see
   [pipelines/job_artifacts](../user/project/pipelines/job_artifacts.md).

Artifacts is a list of files and directories which are attached to a job
after it completes successfully. This feature is enabled by default in all
GitLab installations. Keep reading if you want to know how to disable it.

## Disabling job artifacts

To disable artifacts site-wide, follow the steps below.

---

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['artifacts_enabled'] = false
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

    ```yaml
    artifacts:
      enabled: false
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

## Storing job artifacts

After a successful job, GitLab Runner uploads an archive containing the job
artifacts to GitLab.

### Using local storage

To change the location where the artifacts are stored locally, follow the steps
below.

---

**In Omnibus installations:**

_The artifacts are stored by default in
`/var/opt/gitlab/gitlab-rails/shared/artifacts`._

1. To change the storage path for example to `/mnt/storage/artifacts`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

_The artifacts are stored by default in
`/home/git/gitlab/shared/artifacts`._

1. To change the storage path for example to `/mnt/storage/artifacts`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

    ```yaml
    artifacts:
      enabled: true
      path: /mnt/storage/artifacts
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

### Using object storage

>**Notes:**
- [Introduced][ee-1762] in [GitLab Premium][eep] 9.4.
- Since version 9.5, artifacts are [browsable], when object storage is enabled. 
  9.4 lacks this feature.
> Available in [GitLab Premium](https://about.gitlab.com/products/) and
[GitLab.com Silver](https://about.gitlab.com/gitlab-com/).
> Since version 10.6, available in [GitLab CE](https://about.gitlab.com/products/)

If you don't want to use the local disk where GitLab is installed to store the
artifacts, you can use an object storage like AWS S3 instead.
This configuration relies on valid AWS credentials to be configured already.
Use an [Object storage option][os] like AWS S3 to store job artifacts.

### Object Storage Settings

For source installations the following settings are nested under `artifacts:` and then `object_store:`. On omnibus installs they are prefixed by `artifacts_object_store_`.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where Artfacts will be stored| |
| `background_upload` | Set to false to disable automatic upload. Option may be removed once upload is direct to S3 | `true` |
| `proxy_download` | Set to true to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data | `false` |
| `connection` | Various connection options described below | |

#### S3 compatible connection settings

The connection settings match those provided by [Fog](https://github.com/fog), and are as follows:

| Setting | Description | Default |
|---------|-------------|---------|
| `provider` | Always `AWS` for compatible hosts | AWS |
| `aws_access_key_id` | AWS credentials, or compatible | |
| `aws_secret_access_key` | AWS credentials, or compatible | |
| `region` | AWS region | us-east-1 |
| `host` | S3 compatible host for when not using AWS, e.g. `localhost` or `storage.example.com` | s3.amazonaws.com |
| `endpoint` | Can be used when configuring an S3 compatible service such as [Minio](https://www.minio.io), by entering a URL such as `http://127.0.0.1:9000` | (optional) |
| `path_style` | Set to true to use `host/bucket_name/object` style paths instead of `bucket_name.host/object`. Leave as false for AWS S3 | false |

**In Omnibus installations:**

_The artifacts are stored by default in
`/var/opt/gitlab/gitlab-rails/shared/artifacts`._

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

    ```ruby
    gitlab_rails['artifacts_enabled'] = true
    gitlab_rails['artifacts_object_store_enabled'] = true
    gitlab_rails['artifacts_object_store_remote_directory'] = "artifacts"
    gitlab_rails['artifacts_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-central-1',
      'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
      'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
    }
    ```

    NOTE: For GitLab 9.4+, if you are using AWS IAM profiles, be sure to omit the
    AWS access key and secret acces key/value pairs. For example:

    ```ruby
    gitlab_rails['artifacts_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-central-1',
      'use_iam_profile' => true
    }
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

      ```bash
      gitlab-rake gitlab:artifacts:migrate
      ```

      Currently this has to be executed manually and it will allow you to
      migrate the existing artifacts to the object storage, but all new
      artifacts will still be stored on the local disk. In the future
      you will be given an option to define a default storage artifacts for all
      new files.

---

**In installations from source:**

_The artifacts are stored by default in
`/home/git/gitlab/shared/artifacts`._

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

    ```yaml
    artifacts:
      enabled: true
      object_store:
        enabled: true
        remote_directory: "artifacts" # The bucket name
        connection:
          provider: AWS # Only AWS supported at the moment
          aws_access_key_id: AWS_ACESS_KEY_ID
          aws_secret_access_key: AWS_SECRET_ACCESS_KEY
          region: eu-central-1
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

      ```bash
      sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
      ```

      Currently this has to be executed manually and it will allow you to
      migrate the existing artifacts to the object storage, but all new
      artifacts will still be stored on the local disk. In the future
      you will be given an option to define a default storage artifacts for all
      new files.

## Expiring artifacts

If an expiry date is used for the artifacts, they are marked for deletion
right after that date passes. Artifacts are cleaned up by the
`expire_build_artifacts_worker` cron job which is run by Sidekiq every hour at
50 minutes (`50 * * * *`).

To change the default schedule on which the artifacts are expired, follow the
steps below.

---

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and comment out or add the following line

    ```ruby
    gitlab_rails['expire_build_artifacts_worker_cron'] = "50 * * * *"
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

    ```yaml
    expire_build_artifacts_worker:
      cron: "50 * * * *"
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

## Validation for dependencies

> Introduced in GitLab 10.3.

To disable [the dependencies validation](../ci/yaml/README.md#when-a-dependent-job-will-fail),
you can flip the feature flag from a Rails console.

---

**In Omnibus installations:**

1. Enter the Rails console:

    ```sh
    sudo gitlab-rails console
    ```

1. Flip the switch and disable it:

    ```ruby
    Feature.enable('ci_disable_validates_dependencies')
    ```
---

**In installations from source:**

1. Enter the Rails console:

    ```sh
    cd /home/git/gitlab
    RAILS_ENV=production sudo -u git -H bundle exec rails console
    ```

1. Flip the switch and disable it:

    ```ruby
    Feature.enable('ci_disable_validates_dependencies')
    ```

## Set the maximum file size of the artifacts

Provided the artifacts are enabled, you can change the maximum file size of the
artifacts through the [Admin area settings](../user/admin_area/settings/continuous_integration.md#maximum-artifacts-size).

## Storage statistics

You can see the total storage used for job artifacts on groups and projects
in the administration area, as well as through the [groups](../api/groups.md)
and [projects APIs](../api/projects.md).

## Implementation details

When GitLab receives an artifacts archive, an archive metadata file is also
generated by [GitLab Workhorse]. This metadata file describes all the entries
that are located in the artifacts archive itself.
The metadata file is in a binary format, with additional GZIP compression.

GitLab does not extract the artifacts archive in order to save space, memory
and disk I/O. It instead inspects the metadata file which contains all the
relevant information. This is especially important when there is a lot of
artifacts, or an archive is a very large file.

When clicking on a specific file, [GitLab Workhorse] extracts it
from the archive and the download begins. This implementation saves space,
memory and disk I/O.

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#installations-from-source "How to restart GitLab"
[gitlab workhorse]: https://gitlab.com/gitlab-org/gitlab-workhorse "GitLab Workhorse repository"
[os]: https://docs.gitlab.com/administration/job_artifacts.html#using-object-storage
