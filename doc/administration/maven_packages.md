# GitLab Maven repository administration

>
[Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/5811)
in GitLab 11.3. To learn how to use

When the GitLab Maven repository is enabled, every project in GitLab will have
its own space to store [Maven](https://maven.apache.org/) packages.

To learn how to use it, see the [user documentation](../user/project/packages/maven.md).

## Enabling the Packages repository

NOTE: **Note:**
Once enabled, newly created projects will have the Packages feature enabled by
default. Existing projects will need to
[explicitly enabled it](../user/project/packages/maven.md#enabling-the-packages-repository).

To enable the Packages repository:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['packages_enabled'] = true
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

**Installations from source**

1. After the installation is complete, you will have to configure the `packages`
   section in `config/gitlab.yml`. Set to `true` to enable it:

      ```yaml
      packages:
        enabled: true
      ```
1. [Restart GitLab] for the changes to take effect.

## Changing the storage path

By default, the packages are stored locally, but you can change the default
local location or even use object storage.

### Changing the local storage path

The packages for Omnibus GitLab installations are stored under
`/var/opt/gitlab/gitlab-rails/shared/packages/` and for source
installations under `shared/packages/` (relative to the git homedir).
To change the local storage path:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['packages_storage_path'] = "/mnt/maven"
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

**Installations from source**

1. Edit the `packages` section in `config/gitlab.yml`:

      ```yaml
      packages:
        enabled: true
        storage_path: shared/packages
      ```
1. [Restart GitLab] for the changes to take effect.

### Using object storage

Instead of relying on the local storage, you can use an object storage to
upload the maven packages:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines (uncomment where
   necessary):

    ```ruby
    gitlab_rails['packages_enabled'] = true
    gitlab_rails['packages_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/packages"
    gitlab_rails['packages_object_store_enabled'] = true
    gitlab_rails['packages_object_store_remote_directory'] = "packages" # The bucket name.
    gitlab_rails['packages_object_store_direct_upload'] = false         # Use Object Storage directly for uploads instead of background uploads if enabled (Default: false).
    gitlab_rails['packages_object_store_background_upload'] = true      # Temporary option to limit automatic upload (Default: true).
    gitlab_rails['packages_object_store_proxy_download'] = false        # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
    gitlab_rails['packages_object_store_connection'] = {
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

1. Edit the `packages` section in `config/gitlab.yml` (uncomment where necessary):

    ```yaml
      packages:
        enabled: true
        ##
        ## The location where build packages are stored (default: shared/packages).
        ##
        #storage_path: shared/packages
        object_store:
          enabled: false
          remote_directory: packages # The bucket name.
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
