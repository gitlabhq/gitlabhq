---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Configure Git LFS for GitLab Self-Managed."
title: GitLab Git Large File Storage (LFS) Administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This page contains information about configuring Git LFS on GitLab Self-Managed.
For user documentation about Git LFS, see [Git Large File Storage](../../topics/git/lfs/_index.md).

Prerequisites:

- Users need to install [Git LFS client](https://git-lfs.com/) version 1.0.1 or later.

## Enable or disable LFS

LFS is enabled by default. To disable it:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Change to true to enable lfs - enabled by default if not defined
   gitlab_rails['lfs_enabled'] = false
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       lfs:
         enabled: false
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['lfs_enabled'] = false
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     lfs:
       enabled: false
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Change local storage path

Git LFS objects can be large in size. By default, they are stored on the server
GitLab is installed on.

NOTE:
For Docker installations, you can change the path where your data is mounted.
For the Helm chart, use
[object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/).

To change the default local storage path location:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # /var/opt/gitlab/gitlab-rails/shared/lfs-objects by default.
   gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   # /home/git/gitlab/shared/lfs-objects by default.
   production: &base
     lfs:
       storage_path: /mnt/storage/lfs-objects
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Storing LFS objects in remote object storage

You can store LFS objects in remote object storage. This allows you
to reduce reads and writes to the local disk, and free up disk space significantly.

You should use the
[consolidated object storage settings](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

### Migrating to object storage

You can migrate the LFS objects from local storage to object storage. The
processing is done in the background and requires **no downtime**.

1. [Configure the object storage](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
1. Migrate the LFS objects:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate
   ```

   :::TabTitle Docker

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate
   ```

   :::TabTitle Self-compiled (source)

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate RAILS_ENV=production
   ```

   ::EndTabs

1. Optional. Track the progress and verify that all job LFS objects migrated
   successfully using the PostgreSQL console.
   1. Open a PostgreSQL console:

      ::Tabs

      :::TabTitle Linux package (Omnibus)

      ```shell
      sudo gitlab-psql
      ```

      :::TabTitle Docker

      ```shell
      sudo docker exec -it <container_name> /bin/bash
      gitlab-psql
      ```

      :::TabTitle Self-compiled (source)

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      ::EndTabs

   1. Verify that all LFS files migrated to object storage with the following
      SQL query. The number of `objectstg` should be the same as `total`:

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM lfs_objects;

      total | filesystem | objectstg
      ------+------------+-----------
       2409 |          0 |      2409
      ```

1. Verify that there are no files on disk in the `lfs-objects` directory:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   :::TabTitle Docker

   Assuming you mounted `/var/opt/gitlab` to `/srv/gitlab`:

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   :::TabTitle Self-compiled (source)

   ```shell
   sudo find /home/git/gitlab/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   ::EndTabs

### Migrating back to local storage

NOTE:
For the Helm chart, you should use
[object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/).

To migrate back to local storage:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Migrate the LFS objects:

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. Edit `/etc/gitlab/gitlab.rb` and
   [disable object storage](../object_storage.md#disable-object-storage-for-specific-features)
   for LFS objects:

   ```ruby
   gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Docker

1. Migrate the LFS objects:

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. Edit `docker-compose.yml` and disable object storage for LFS objects:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Migrate the LFS objects:

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate_to_local RAILS_ENV=production
   ```

1. Edit `/home/git/gitlab/config/gitlab.yml` and disable object storage for LFS objects:

   ```yaml
   production: &base
     object_store:
       objects:
         lfs:
           enabled: false
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Pure SSH transfer protocol

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11872) in GitLab 17.2.
> - [Introduced](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3845) for Helm chart (Kubernetes) in GitLab 17.3.

WARNING:
This feature is affected by [a known issue](https://github.com/git-lfs/git-lfs/issues/5880). If you clone a repository with multiple Git LFS objects using the pure SSH protocol, the client might crash due to a `nil` pointer reference.

[`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021)
released support for using SSH as the transfer protocol instead of HTTP.
SSH is handled transparently by the `git-lfs` command line tool.

When pure SSH protocol support is enabled and `git` is configured to use SSH,
all LFS operations happen over SSH. For example, when the Git remote is
`git@gitlab.com:gitlab-org/gitlab.git`. You can't configure `git` and `git-lfs`
to use different protocols. From version 3.0, `git-lfs` attempts to use the pure
SSH protocol initially and, if support is not enabled or available, it falls back
to using HTTP.

Prerequisites:

- The `git-lfs` version must be [v3.5.1](https://github.com/git-lfs/git-lfs/releases/tag/v3.5.1) or higher.

To switch Git LFS to use pure SSH protocol:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_shell['lfs_pure_ssh_protocol'] = true
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         lfs:
           pureSSHProtocol: true
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_shell['lfs_pure_ssh_protocol'] = true
   ```

1. Save the file and restart GitLab and its services:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab-shell/config.yml`:

   ```yaml
   lfs:
      pure_ssh_protocol: true
   ```

1. Save the file and restart GitLab Shell:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab-shell.target

   # For systems running SysV init
   sudo service gitlab-shell restart
   ```

::EndTabs

## Storage statistics

You can see the total storage used for LFS objects for groups and projects in:

- The **Admin** area
- The [groups](../../api/groups.md) and [projects](../../api/projects.md) APIs

## Related topics

- Blog post: [Getting started with Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- User documentation: [Git Large File Storage (LFS)](../../topics/git/lfs/_index.md)
- [Git LFS developer information](../../development/lfs.md)

## Troubleshooting

### Missing LFS objects

An error about a missing LFS object may occur in either of these situations:

- When migrating LFS objects from disk to object storage, with error messages like:

  ```plaintext
  ERROR -- : Failed to transfer LFS object
  006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  with error: No such file or directory @ rb_sysopen -
  /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  ```

   (Line breaks have been added for legibility.)

- When running the
  [integrity check for LFS objects](../raketasks/check.md#uploaded-files-integrity)
  with the `VERBOSE=1` parameter.

The database can have records for LFS objects which are not on disk. The database entry may
[prevent a new copy of the object from being pushed](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49241).
To delete these references:

1. [Start a rails console](../operations/rails_console.md).
1. Query the object that's reported as missing in the rails console, to return a file path:

   ```ruby
   lfs_object = LfsObject.find_by(oid: '006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7')
   lfs_object.file.path
   ```

1. Check on disk or object storage if it exists:

   ```shell
   ls -al /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
   ```

1. If the file is not present, remove the database records with the Rails console:

   ```ruby
   # First delete the parent records and then destroy the record itself
   lfs_object.lfs_objects_projects.destroy_all
   lfs_object.destroy
   ```

### LFS commands fail on TLS v1.3 server

If you configure GitLab to [disable TLS v1.2](https://docs.gitlab.com/omnibus/settings/nginx.html)
and only enable TLS v1.3 connections, LFS operations require a
[Git LFS client](https://git-lfs.com/) version 2.11.0 or later. If you use
a Git LFS client earlier than version 2.11.0, GitLab displays an error:

```plaintext
batch response: Post https://username:***@gitlab.example.com/tool/releases.git/info/lfs/objects/batch: remote error: tls: protocol version not supported
error: failed to fetch some objects from 'https://username:[MASKED]@gitlab.example.com/tool/releases.git/info/lfs'
```

When using GitLab CI over a TLS v1.3 configured GitLab server, you must
[upgrade to GitLab Runner](https://docs.gitlab.com/runner/install/index.html) 13.2.0
or later to receive an updated Git LFS client version with
the included [GitLab Runner Helper image](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#helper-image).

To check an installed Git LFS client's version, run this command:

```shell
git lfs version
```

### `Connection refused` errors

If you push or mirror LFS objects and receive errors like the following:

- `dial tcp <IP>:443: connect: connection refused`
- `Connection refused - connect(2) for \"<target-or-proxy-IP>\" port 443`

a firewall or proxy rule may be terminating the connection.

If connection checks with standard Unix tools or manual Git pushes are successful,
the rule may be related to the size of the request.

### Error viewing a PDF file

When LFS has been configured with object storage and `proxy_download` set to
`false`, [you may see an error when previewing a PDF file from the Web browser](https://gitlab.com/gitlab-org/gitlab/-/issues/248100):

```plaintext
An error occurred while loading the file. Please try again later.
```

This occurs due to Cross-Origin Resource Sharing (CORS) restrictions:
the browser attempts to load the PDF from object storage, but the object
storage provider rejects the request because the GitLab domain differs
from the object storage domain.

To fix this issue, configure your object storage provider's CORS
settings to allow the GitLab domain. See the following documentation
for more details:

1. [AWS S3](https://repost.aws/knowledge-center/s3-configure-cors)
1. [Google Cloud Storage](https://cloud.google.com/storage/docs/using-cors)
1. [Azure Storage](https://learn.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services).

### Fork operation stuck on `Forking in progress` message

If you are forking a project with multiple LFS files, the operation might get stuck with a `Forking in progress` message.
If you encounter this, follow these steps to diagnose and resolve the issue:

1. Check your [exceptions_json.log](../logs/_index.md#exceptions_jsonlog) file for the following error message:

   ```plaintext
   "error_message": "Unable to fork project 12345 for repository
   @hashed/11/22/encoded-path -> @hashed/33/44/encoded-new-path:
   Source project has too many LFS objects"
   ```

   This error indicates that you've reached the default limit of 100,000 LFS files,
   as described in issue [#476693](https://gitlab.com/gitlab-org/gitlab/-/issues/476693).

1. Increase the value of the `GITLAB_LFS_MAX_OID_TO_FETCH` variable:

   1. Open the configuration file `/etc/gitlab/gitlab.rb`.
   1. Add or update the variable:

      ```ruby
      gitlab_rails['env'] = {
         "GITLAB_LFS_MAX_OID_TO_FETCH" => "NEW_VALUE"
      }
      ```

      Replace `NEW_VALUE` with a number based on your requirements.

1. Apply the changes. Run:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   For additional information, see [Reconfigure a Linux package installation](../restart_gitlab.md#reconfigure-a-linux-package-installation).

1. Repeat the fork operation.

NOTE:
If you are using GitLab Helm Chart, use [extraEnv](https://docs.gitlab.com/charts/charts/globals.html#extraenv) to configure the environment variable `GITLAB_LFS_MAX_OID_TO_FETCH`.

## Known limitations

- Only compatible with the Git LFS client versions 1.1.0 and later, or 1.0.2.
- The storage statistics count each LFS object for
  every project linking to it.
