# GitLab Git LFS Administration

Documentation on how to use Git LFS are under [Managing large binary files with Git LFS doc](manage_large_binaries_with_git_lfs.md).

## Requirements

* Git LFS is supported in GitLab starting with version 8.2.
* Support for object storage, such as AWS S3, was introduced in 10.0.
* Users need to install [Git LFS client](https://git-lfs.github.com) version 1.0.1 and up.

## Configuration

Git LFS objects can be large in size. By default, they are stored on the server
GitLab is installed on.

There are various configuration options to help GitLab server administrators:

* Enabling/disabling Git LFS support
* Changing the location of LFS object storage
* Setting up AWS S3 compatible object storage

### Omnibus packages

In `/etc/gitlab/gitlab.rb`:

```ruby
# Change to true to enable lfs
gitlab_rails['lfs_enabled'] = false

# Optionally, change the storage path location. Defaults to
# `#{gitlab_rails['shared_path']}/lfs-objects`. Which evaluates to
# `/var/opt/gitlab/gitlab-rails/shared/lfs-objects` by default.
gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
```

### Installations from source

In `config/gitlab.yml`:

```yaml
# Change to true to enable lfs
  lfs:
    enabled: false
    storage_path: /mnt/storage/lfs-objects
```

## Setting up S3 compatible object storage

> **Note:** [Introduced][ee-2760] in [GitLab Premium][eep] 10.0.
> Available in [GitLab CE][ce] 10.7

It is possible to store LFS objects on remote object storage instead of on a local disk.

This allows you to offload storage to an external AWS S3 compatible service, freeing up disk space locally. You can also host your own S3 compatible storage decoupled from GitLab, with with a service such as [Minio](https://www.minio.io/).

Object storage currently transfers files first to GitLab, and then on the object storage in a second stage. This can be done either by using a rake task to transfer existing objects, or in a background job after each file is received.

### Object Storage Settings

For source installations the following settings are nested under `lfs:` and then `object_store:`. On omnibus installs they are prefixed by `lfs_object_store_`.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where LFS objects will be stored| |
| `direct_upload` | Set to true to enable direct upload of LFS without the need of local shared storage. Option may be removed once we decide to support only single storage for all files. | `false` |
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


### From source

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

	```yaml
	lfs:
	enabled: true
	object_store:
	  enabled: false
	  remote_directory: lfs-objects # Bucket name
	  connection:
	    provider: AWS
	    aws_access_key_id: 1ABCD2EFGHI34JKLM567N
	    aws_secret_access_key: abcdefhijklmnopQRSTUVwxyz0123456789ABCDE
	    region: eu-central-1
	    # Use the following options to configure an AWS compatible host such as Minio
	    host: 'localhost'
	    endpoint: 'http://127.0.0.1:9000'
	    path_style: true
	```

1. Save the file and [restart GitLab][] for the changes to take effect.
1. Migrate any existing local LFS objects to the object storage:

	```bash
	sudo -u git -H bundle exec rake gitlab:lfs:migrate RAILS_ENV=production
	```

	This will migrate existing LFS objects to object storage. New LFS objects
	will be forwarded to object storage unless
	`gitlab_rails['lfs_object_store_background_upload']` is set to false.

### In Omnibus

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

	```ruby
	gitlab_rails['lfs_object_store_enabled'] = true
	gitlab_rails['lfs_object_store_remote_directory'] = "lfs-objects"
	gitlab_rails['lfs_object_store_connection'] = {
	  'provider' => 'AWS',
	  'region' => 'eu-central-1',
	  'aws_access_key_id' => '1ABCD2EFGHI34JKLM567N',
	  'aws_secret_access_key' => 'abcdefhijklmnopQRSTUVwxyz0123456789ABCDE',
	  # The below options configure an S3 compatible host instead of AWS
	  'host' => 'localhost',
	  'endpoint' => 'http://127.0.0.1:9000',
	  'path_style' => true
	}
	```

1. Save the file and [reconfigure GitLab]s for the changes to take effect.
1. Migrate any existing local LFS objects to the object storage:

      ```bash
      gitlab-rake gitlab:lfs:migrate
      ```

      This will migrate existing LFS objects to object storage. New LFS objects
      will be forwarded to object storage unless
      `gitlab_rails['lfs_object_store_background_upload']` is set to false.

## Storage statistics

You can see the total storage used for LFS objects on groups and projects
in the administration area, as well as through the [groups](../../api/groups.md)
and [projects APIs](../../api/projects.md).

## Known limitations

* Support for removing unreferenced LFS objects was added in 8.14 onwards.
* LFS authentications via SSH was added with GitLab 8.12
* Only compatible with the GitLFS client versions 1.1.0 and up, or 1.0.2.
* The storage statistics currently count each LFS object multiple times for
  every project linking to it

[reconfigure gitlab]: ../../administration/restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: ../../administration/restart_gitlab.md#installations-from-source "How to restart GitLab"
[eep]: https://about.gitlab.com/products/ "GitLab Premium"
[ee-2760]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/2760
