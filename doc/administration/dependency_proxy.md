# GitLab Dependency Proxy administration **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/7934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.11.

GitLab can be utilized as a dependency proxy for a variety of common package managers.

This is the administration documentation. If you want to learn how to use the
dependency proxies, see the [user guide](../user/group/dependency_proxy/index.md).

## Enabling the Dependency Proxy feature

NOTE: **Note:**
Dependency proxy requires the Puma web server to be enabled.
Puma support is EXPERIMENTAL at this time.

To enable the Dependency proxy feature:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.
1. Enable the [Puma web server](https://docs.gitlab.com/omnibus/settings/puma.html).

**Installations from source**

1. After the installation is complete, you will have to configure the `dependency_proxy`
   section in `config/gitlab.yml`. Set to `true` to enable it:

   ```yaml
   dependency_proxy:
     enabled: true
   ```

1. [Restart GitLab] for the changes to take effect.
1. Enable the [Puma web server](../install/installation.md#using-puma).

## Changing the storage path

By default, the dependency proxy files are stored locally, but you can change the default
local location or even use object storage.

### Changing the local storage path

The dependency proxy files for Omnibus GitLab installations are stored under
`/var/opt/gitlab/gitlab-rails/shared/dependency_proxy/` and for source
installations under `shared/dependency_proxy/` (relative to the git home directory).
To change the local storage path:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['dependency_proxy_storage_path'] = "/mnt/dependency_proxy"
   ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

**Installations from source**

1. Edit the `dependency_proxy` section in `config/gitlab.yml`:

   ```yaml
   dependency_proxy:
     enabled: true
     storage_path: shared/dependency_proxy
   ```
1. [Restart GitLab] for the changes to take effect.

### Using object storage

Instead of relying on the local storage, you can use an object storage to
upload the blobs of the dependency proxy:

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

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

**Installations from source**

1. Edit the `dependency_proxy` section in `config/gitlab.yml` (uncomment where necessary):

   ```yaml
   dependency_proxy:
     enabled: true
     ##
     ## The location where build dependency_proxy are stored (default: shared/dependency_proxy).
     ##
     #storage_path: shared/dependency_proxy
     object_store:
       enabled: false
       remote_directory: dependency_proxy # The bucket name.
       #direct_upload: false      # Use Object Storage directly for uploads instead of background uploads if enabled (Default: false).
       #background_upload: true   # Temporary option to limit automatic upload (Default: true).
       #proxy_download: false     # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
       connection:
         ##
         ## If the provider is AWS S3, uncomment the following
         ##
         #provider: AWS
         #region: us-east-1
         #aws_access_key_id: AWS_ACCESS_KEY_ID
         #aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         ##
         ## If the provider is other than AWS (an S3-compatible one), uncomment the following
         ##
         #host: 's3.amazonaws.com'             # default: s3.amazonaws.com.
         #aws_signature_version: 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
         #endpoint: 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
         #path_style: false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   ```

1. [Restart GitLab] for the changes to take effect.

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
