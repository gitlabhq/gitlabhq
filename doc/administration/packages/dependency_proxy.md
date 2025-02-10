---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Dependency Proxy administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.11.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) from GitLab Premium to GitLab Free in 13.6.

GitLab can be used as a dependency proxy for your frequently-accessed upstream images.

This is the administration documentation. If you want to learn how to use the
dependency proxies, see the [user guide](../../user/packages/dependency_proxy/_index.md).

The GitLab Dependency Proxy:

- Is turned on by default.
- Can be turned off by an administrator.

## Turn off the Dependency Proxy

The Dependency Proxy is enabled by default. If you are an administrator, you
can turn off the Dependency Proxy. To turn off the Dependency Proxy, follow the instructions that
correspond to your GitLab installation.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = false
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

:::TabTitle Helm chart (Kubernetes)

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

:::TabTitle Self-compiled (source)

1. After the installation is complete, configure the `dependency_proxy` section in
   `config/gitlab.yml`. Set `enabled` to `false` to turn off the Dependency Proxy:

   ```yaml
   dependency_proxy:
     enabled: false
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations) for the changes to take effect.

::EndTabs

### Multi-node GitLab installations

Follow the steps for Linux package installations for each Web and Sidekiq node.

## Turn on the Dependency Proxy

The Dependency Proxy is turned on by default, but can be turned off by an
administrator. To turn it off manually, follow the instructions in
[Turn off the Dependency Proxy](#turn-off-the-dependency-proxy).

## Changing the storage path

By default, the Dependency Proxy files are stored locally, but you can change the default
local location or even use object storage.

### Changing the local storage path

The Dependency Proxy files for Linux package installations are stored under
`/var/opt/gitlab/gitlab-rails/shared/dependency_proxy/` and for source
installations under `shared/dependency_proxy/` (relative to the Git home directory).

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_storage_path'] = "/mnt/dependency_proxy"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

:::TabTitle Self-compiled (source)

1. Edit the `dependency_proxy` section in `config/gitlab.yml`:

   ```yaml
   dependency_proxy:
     enabled: true
     storage_path: shared/dependency_proxy
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations) for the changes to take effect.

::EndTabs

### Using object storage

Instead of relying on the local storage, you can use the
[consolidated object storage settings](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
This section describes the earlier configuration format. [Migration steps still apply](#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage).

[Read more about using object storage with GitLab](../object_storage.md).

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines (uncomment where
   necessary):

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = true
   gitlab_rails['dependency_proxy_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/dependency_proxy"
   gitlab_rails['dependency_proxy_object_store_enabled'] = true
   gitlab_rails['dependency_proxy_object_store_remote_directory'] = "dependency_proxy" # The bucket name.
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

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

:::TabTitle Self-compiled (source)

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

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations) for the changes to take effect.

::EndTabs

#### Migrate local Dependency Proxy blobs and manifests to object storage

After [configuring object storage](#using-object-storage),
use the following task to migrate existing Dependency Proxy blobs and manifests from local storage
to remote storage. The processing is done in a background worker and requires no downtime.

- For Linux package installations:

  ```shell
  sudo gitlab-rake "gitlab:dependency_proxy:migrate"
  ```

- For self-compiled installations:

  ```shell
  RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:dependency_proxy:migrate
  ```

You can optionally track progress and verify that all Dependency Proxy blobs and manifests migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- `sudo gitlab-rails dbconsole` for Linux package installations running version 14.1 and earlier.
- `sudo gitlab-rails dbconsole --database main` for Linux package installations running version 14.2 and later.
- `sudo -u git -H psql -d gitlabhq_production` for self-compiled instances.

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

## Changing the JWT expiration

The Dependency Proxy follows the [Docker v2 token authentication flow](https://distribution.github.io/distribution/spec/auth/token/),
issuing the client a JWT to use for the pull requests. The token expiration time is a configurable
using the application setting `container_registry_token_expire_delay`. It can be changed from the
rails console:

```ruby
# update the JWT expiration to 30 minutes
ApplicationSetting.update(container_registry_token_expire_delay: 30)
```

The default expiration and the expiration on GitLab.com is 15 minutes.

## Using the dependency proxy behind a proxy

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines:

   ```ruby
   gitlab_workhorse['env'] = {
     "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
     "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
