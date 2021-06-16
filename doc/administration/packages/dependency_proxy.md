---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Dependency Proxy administration **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.11.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) to [GitLab Free](https://about.gitlab.com/pricing/) in GitLab 13.6.

GitLab can be used as a dependency proxy for a variety of common package managers.

This is the administration documentation. If you want to learn how to use the
dependency proxies, see the [user guide](../../user/packages/dependency_proxy/index.md).

## Enabling the Dependency Proxy feature

NOTE:
Dependency proxy requires the Puma web server to be enabled.

To enable the dependency proxy feature:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab") for the changes to take effect.
1. Enable the [Puma web server](https://docs.gitlab.com/omnibus/settings/puma.html).

**Helm chart installations**

1. After the installation is complete, update the global `appConfig` to enable the feature:

   ```yaml
   global:
     appConfig:
       dependencyProxy:
         enabled: true
         bucket: gitlab-dependency-proxy
         connection: {}
          secret:
          key:
   ```

For more information, see [Configure Charts using Globals](https://docs.gitlab.com/charts/charts/globals.html#configure-appconfig-settings).

**Installations from source**

1. After the installation is complete, configure the `dependency_proxy`
   section in `config/gitlab.yml`. Set to `true` to enable it:

   ```yaml
   dependency_proxy:
     enabled: true
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source "How to restart GitLab") for the changes to take effect.

Since Puma is already the default web server for installations from source as of GitLab 12.9,
no further changes are needed.

**Multi-node GitLab installations**

Follow the steps for **Omnibus GitLab installation** for each Web and Sidekiq nodes.

## Changing the storage path

By default, the dependency proxy files are stored locally, but you can change the default
local location or even use object storage.

### Changing the local storage path

The dependency proxy files for Omnibus GitLab installations are stored under
`/var/opt/gitlab/gitlab-rails/shared/dependency_proxy/` and for source
installations under `shared/dependency_proxy/` (relative to the Git home directory).
To change the local storage path:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_storage_path'] = "/mnt/dependency_proxy"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab") for the changes to take effect.

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
store the blobs of the dependency proxy.

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

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab") for the changes to take effect.

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

The ability to disable this feature will be [removed in 13.9](https://gitlab.com/gitlab-org/gitlab/-/issues/276777).
