---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Dependency Proxy administration **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.11.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) from GitLab Premium to GitLab Free in 13.6.

GitLab can be used as a dependency proxy for a variety of common package managers.

This is the administration documentation. If you want to learn how to use the
dependency proxies, see the [user guide](../../user/packages/dependency_proxy/index.md).

The GitLab Dependency Proxy:

- Is turned on by default.
- Can be turned off by an administrator.
- Requires the [Puma web server](../operations/puma.md)
  to be enabled. Puma is enabled by default in GitLab 13.0 and later.

## Turn off the Dependency Proxy

The Dependency Proxy is enabled by default. If you are an administrator, you
can turn off the Dependency Proxy. To turn off the Dependency Proxy, follow the instructions that
correspond to your GitLab installation:

- [Omnibus GitLab installations](#omnibus-gitlab-installations)
- [Helm chart installations](#helm-chart-installations)
- [Installations from source](#installations-from-source)

### Omnibus GitLab installations

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = false
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

### Helm chart installations

After the installation is complete, update the global `appConfig` to turn off the Dependency Proxy:

```yaml
global:
  appConfig:
    dependencyProxy:
      enabled: false
      bucket: gitlab-dependency-proxy
      connection: {}
       secret:
       key:
```

For more information, see [Configure Charts using Globals](https://docs.gitlab.com/charts/charts/globals.html#configure-appconfig-settings).

### Installations from source

1. After the installation is complete, configure the `dependency_proxy` section in
   `config/gitlab.yml`. Set `enabled` to `false` to turn off the Dependency Proxy:

   ```yaml
   dependency_proxy:
     enabled: false
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source "How to restart GitLab")
   for the changes to take effect.

### Multi-node GitLab installations

Follow the steps for [Omnibus GitLab installations](#omnibus-gitlab-installations)
for each Web and Sidekiq node.

## Turn on the Dependency Proxy

The Dependency Proxy is turned on by default, but can be turned off by an
administrator. To turn on the Dependency Proxy, follow the instructions in
[Turn off the Dependency Proxy](#turn-off-the-dependency-proxy),
but set the `enabled` fields to `true`.

## Changing the storage path

By default, the Dependency Proxy files are stored locally, but you can change the default
local location or even use object storage.

### Changing the local storage path

The Dependency Proxy files for Omnibus GitLab installations are stored under
`/var/opt/gitlab/gitlab-rails/shared/dependency_proxy/` and for source
installations under `shared/dependency_proxy/` (relative to the Git home directory).
To change the local storage path:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_storage_path'] = "/mnt/dependency_proxy"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

1. Edit the `dependency_proxy` section in `config/gitlab.yml`:

   ```yaml
   dependency_proxy:
     enabled: true
     storage_path: shared/dependency_proxy
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source "How to restart GitLab") for the changes to take effect.

### Using object storage

Instead of relying on the local storage, you can use an object storage to
store the blobs of the Dependency Proxy.

[Read more about using object storage with GitLab](../object_storage.md).

NOTE:
In GitLab 13.2 and later, we recommend using the
[consolidated object storage settings](../object_storage.md#consolidated-object-storage-configuration).
This section describes the earlier configuration format.

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines (uncomment where
   necessary):

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = true
   gitlab_rails['dependency_proxy_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/dependency_proxy"
   gitlab_rails['dependency_proxy_object_store_enabled'] = true
   gitlab_rails['dependency_proxy_object_store_remote_directory'] = "dependency_proxy" # The bucket name.
   gitlab_rails['dependency_proxy_object_store_direct_upload'] = false         # Use Object Storage directly for uploads instead of background uploads if enabled (Default: false).
   gitlab_rails['dependency_proxy_object_store_background_upload'] = true      # Temporary option to limit automatic upload (Default: true).
   gitlab_rails['dependency_proxy_object_store_proxy_download'] = false        # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
   gitlab_rails['dependency_proxy_object_store_connection'] = {
     ##
     ## If the provider is AWS S3, uncomment the following
     ##
     #'provider' => 'AWS',
     #'region' => 'eu-west-1',
     #'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     #'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
     ##
     ## If the provider is other than AWS (an S3-compatible one), uncomment the following
     ##
     #'host' => 's3.amazonaws.com',
     #'aws_signature_version' => 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
     #'endpoint' => 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
     #'path_style' => false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

1. Edit the `dependency_proxy` section in `config/gitlab.yml` (uncomment where necessary):

   ```yaml
   dependency_proxy:
     enabled: true
     ##
     ## The location where build dependency_proxy are stored (default: shared/dependency_proxy).
     ##
     # storage_path: shared/dependency_proxy
     object_store:
       enabled: false
       remote_directory: dependency_proxy  # The bucket name.
       #  direct_upload: false      # Use Object Storage directly for uploads instead of background uploads if enabled (Default: false).
       #  background_upload: true   # Temporary option to limit automatic upload (Default: true).
       #  proxy_download: false     # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
       connection:
       ##
       ## If the provider is AWS S3, use the following
       ##
         provider: AWS
         region: us-east-1
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         ##
         ## If the provider is other than AWS (an S3-compatible one), comment out the previous 4 lines and use the following instead:
         ##
         #  host: 's3.amazonaws.com'             # default: s3.amazonaws.com.
         #  aws_signature_version: 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
         #  endpoint: 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
         #  path_style: false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source "How to restart GitLab") for the changes to take effect.

#### Migrate local Dependency Proxy blobs and manifests to object storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79663) in GitLab 14.8.

After [configuring object storage](#using-object-storage),
use the following task to migrate existing Dependency Proxy blobs and manifests from local storage
to remote storage. The processing is done in a background worker and requires no downtime.

For Omnibus GitLab:

```shell
sudo gitlab-rake "gitlab:dependency_proxy:migrate"
```

For installations from source:

```shell
RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:dependency_proxy:migrate
```

You can optionally track progress and verify that all packages migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- For Omnibus GitLab instances: `sudo gitlab-rails dbconsole`
- For installations from source: `sudo -u git -H psql -d gitlabhq_production`

Verify that `objectstg` (where `file_store = '2'`) has the count of all Dependency Proxy blobs and
manifests for each respective query:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_blobs;

total | filesystem | objectstg
------+------------+-----------
 22   |          0 |        22

gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_manifests;

total | filesystem | objectstg
------+------------+-----------
 10   |          0 |        10
```

Verify that there are no files on disk in the `dependency_proxy` folder:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/dependency_proxy -type f | grep -v tmp | wc -l
```

## Disabling Authentication

Authentication was introduced in 13.7 as part of [enabling private groups to use the
Dependency Proxy](https://gitlab.com/gitlab-org/gitlab/-/issues/11582). If you
previously used the Dependency Proxy without authentication and need to disable
this feature while you update your workflow to [authenticate with the Dependency
Proxy](../../user/packages/dependency_proxy/index.md#authenticate-with-the-dependency-proxy),
the following commands can be issued in a Rails console:

```ruby
# Disable the authentication
Feature.disable(:dependency_proxy_for_private_groups)

# Re-enable the authentication
Feature.enable(:dependency_proxy_for_private_groups)
```
