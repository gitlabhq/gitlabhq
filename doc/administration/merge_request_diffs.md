# Merge request diffs storage **(CORE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/52568) in GitLab 11.8.

Merge request diffs are size-limited copies of diffs associated with merge
requests. When viewing a merge request, diffs are sourced from these copies
wherever possible as a performance optimization.

By default, merge request diffs are stored in the database, in a table named
`merge_request_diff_files`. Larger installations may find this table grows too
large, in which case, switching to external storage is recommended.

### Using external storage

Merge request diffs can be stored on disk, or in object storage. In general, it
is better to store the diffs in the database than on disk.

To enable external storage of merge request diffs, follow the instructions below.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['external_diffs_enabled'] = true
    ```

1. _The external diffs will be stored in in
   `/var/opt/gitlab/gitlab-rails/shared/external-diffs`._ To change the path,
   for example, to `/mnt/storage/external-diffs`, edit `/etc/gitlab/gitlab.rb`
   and add the following line:

    ```ruby
    gitlab_rails['external_diffs_storage_path'] = "/mnt/storage/external-diffs"
    ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

    ```yaml
    external_diffs:
      enabled: true
    ```

1. _The external diffs will be stored in 
   `/home/git/gitlab/shared/external-diffs`._ To change the path, for example,
   to `/mnt/storage/external-diffs`, edit `/home/git/gitlab/config/gitlab.yml`
   and add or amend the following lines:

    ```yaml
    external_diffs:
      enabled: true
      storage_path: /mnt/storage/external-diffs
    ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

### Using object storage

Instead of storing the external diffs on disk, we recommended the use of an object
store like AWS S3 instead. This configuration relies on valid AWS credentials to
be configured already.

### Object Storage Settings

For source installations, these settings are nested under `external_diffs:` and
then `object_store:`. On Omnibus installations, they are prefixed by
`external_diffs_object_store_`.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where external diffs will be stored| |
| `direct_upload` | Set to true to enable direct upload of external diffs without the need of local shared storage. Option may be removed once we decide to support only single storage for all files. | `false` |
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
| `aws_signature_version` | AWS signature version to use. 2 or 4 are valid options. Digital Ocean Spaces and other providers may need 2. | 4 |
| `region` | AWS region | us-east-1 |
| `host` | S3 compatible host for when not using AWS, e.g. `localhost` or `storage.example.com` | s3.amazonaws.com |
| `endpoint` | Can be used when configuring an S3 compatible service such as [Minio](https://www.minio.io), by entering a URL such as `http://127.0.0.1:9000` | (optional) |
| `path_style` | Set to true to use `host/bucket_name/object` style paths instead of `bucket_name.host/object`. Leave as false for AWS S3 | false |
| `use_iam_profile` | Set to true to use IAM profile instead of access keys | false

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

    ```ruby
    gitlab_rails['external_diffs_enabled'] = true
    gitlab_rails['external_diffs_object_store_enabled'] = true
    gitlab_rails['external_diffs_object_store_remote_directory'] = "external-diffs"
    gitlab_rails['external_diffs_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-central-1',
      'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
      'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
    }
    ```

    Note that, if you are using AWS IAM profiles, be sure to omit the
    AWS access key and secret access key/value pairs. For example:

    ```ruby
    gitlab_rails['external_diffs_object_store_connection'] = {
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
    external_diffs:
      enabled: true
      object_store:
        enabled: true
        remote_directory: "external-diffs" # The bucket name
        connection:
          provider: AWS # Only AWS supported at the moment
          aws_access_key_id: AWS_ACCESS_KEY_ID
          aws_secret_access_key: AWS_SECRET_ACCESS_KEY
          region: eu-central-1
    ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

### Alternative in-database storage

Enabling external diffs may reduce the performance of merge requests, as they
must be retrieved in a separate operation to other data. A compromise may be
reached by only storing outdated diffs externally, while keeping current diffs
in the database.

To enable this feature, perform the following steps:

**In Omnibus installations:**

1.  Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['external_diffs_when'] = 'outdated'
    ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

    ```yaml
    external_diffs:
      enabled: true
      when: outdated
    ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

With this feature enabled, diffs will initially stored in the database, rather
than externally. They will be moved to external storage once any of these
conditions become true:

- A newer version of the merge request diff exists
- The merge request was merged more than seven days ago
- The merge request was closed more than seven day ago

These rules strike a balance between space and performance by only storing
frequently-accessed diffs in the database. Diffs that are less likely to be
accessed are moved to external storage instead.
