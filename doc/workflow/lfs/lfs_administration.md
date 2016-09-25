# GitLab Git LFS Administration

Documentation on how to use Git LFS are under [Managing large binary files with Git LFS doc](manage_large_binaries_with_git_lfs.md).

## Requirements

* Git LFS is supported in GitLab starting with version 8.2.
* Users need to install [Git LFS client](https://git-lfs.github.com) version 1.0.1 and up.

## Configuration

Git LFS objects can be large in size. By default, they are stored on the server
GitLab is installed on.

There are two configuration options to help GitLab server administrators:

* Enabling/disabling Git LFS support
* Changing the location of LFS object storage

### Omnibus packages

In `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['lfs_enabled'] = false

# Optionally, change the storage path location. Defaults to
# `#{gitlab_rails['shared_path']}/lfs-objects`. Which evaluates to
# `/var/opt/gitlab/gitlab-rails/shared/lfs-objects` by default.
gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
```

### Installations from source

In `config/gitlab.yml`:

```yaml
  lfs:
    enabled: false
    storage_path: /mnt/storage/lfs-objects
```

## Known limitations

* Currently, storing GitLab Git LFS objects on a non-local storage (like S3 buckets)
  is not supported
* Currently, removing LFS objects from GitLab Git LFS storage is not supported
* LFS authentications via SSH was added with GitLab 8.12
* Only compatible with the GitLFS client versions 1.1.0 and up, or 1.0.2.
