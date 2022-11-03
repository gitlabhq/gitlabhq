---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Package Registry administration **(FREE SELF)**

GitLab Packages allows organizations to use GitLab as a private repository
for a variety of common package managers. Users are able to build and publish
packages, which can be easily consumed as a dependency in downstream projects.

The Packages feature allows GitLab to act as a repository and supports the following formats:

| Package type                                                      | GitLab version |
|-------------------------------------------------------------------|----------------|
| [Composer](../../user/packages/composer_repository/index.md)      | 13.2+          |
| [Conan](../../user/packages/conan_repository/index.md)            | 12.6+          |
| [Go](../../user/packages/go_proxy/index.md)                       | 13.1+          |
| [Maven](../../user/packages/maven_repository/index.md)            | 11.3+          |
| [npm](../../user/packages/npm_registry/index.md)                  | 11.7+          |
| [NuGet](../../user/packages/nuget_repository/index.md)            | 12.8+          |
| [PyPI](../../user/packages/pypi_repository/index.md)              | 12.10+         |
| [Generic packages](../../user/packages/generic_packages/index.md) | 13.5+          |
| [Helm Charts](../../user/packages/helm_repository/index.md)       | 14.1+          |

## Accepting contributions

The below table lists formats that are not supported, but are accepting Community contributions for. Consider contributing to GitLab. This [development documentation](../../development/packages/index.md)
guides you through the process.

<!-- vale gitlab.Spelling = NO -->

| Format | Status |
| ------ | ------ |
| Chef      | [#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Debian    | [Draft: Merge Request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50438) |
| Opkg      | [#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [#5932](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) |
| RubyGems  | [#803](https://gitlab.com/gitlab-org/gitlab/-/issues/803) |
| SBT       | [#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Terraform | [Draft: Merge Request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834) |
| Vagrant   | [#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab.Spelling = YES -->

## Enabling the Packages feature

NOTE:
After the Packages feature is enabled, the repositories are available
for all new projects by default. To enable it for existing projects, users
explicitly do so in the project's settings.

To enable the Packages feature:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['packages_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

1. After the installation is complete, you configure the `packages`
   section in `config/gitlab.yml`. Set to `true` to enable it:

   ```yaml
   packages:
     enabled: true
   ```

1. [Restart GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Helm Chart installations**

1. After the installation is complete, you configure the `packages`
   section in `global.appConfig.packages`. Set to `true` to enable it:

   ```yaml
   packages:
     enabled: true
   ```

1. [Restart GitLab](../restart_gitlab.md#helm-chart-installations) for the changes to take effect.

## Rate limits

When downloading packages as dependencies in downstream projects, many requests are made through the
Packages API. You may therefore reach enforced user and IP rate limits. To address this issue, you
can define specific rate limits for the Packages API. For more details, see [Package Registry Rate Limits](../../user/admin_area/settings/package_registry_rate_limits.md).

## Changing the storage path

By default, the packages are stored locally, but you can change the default
local location or even use object storage.

### Changing the local storage path

The packages for Omnibus GitLab installations are stored under
`/var/opt/gitlab/gitlab-rails/shared/packages/` and for source
installations under `shared/packages/` (relative to the Git home directory).
To change the local storage path:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['packages_storage_path'] = "/mnt/packages"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

**Installations from source**

1. Edit the `packages` section in `config/gitlab.yml`:

   ```yaml
   packages:
     enabled: true
     storage_path: shared/packages
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Using object storage

Instead of relying on the local storage, you can use an object storage to
store packages.

[Read more about using object storage with GitLab](../object_storage.md).

NOTE:
We recommend using the [consolidated object storage settings](../object_storage.md#consolidated-object-storage-configuration). The following instructions apply to the original configuration format.

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines (uncomment where
   necessary):

   ```ruby
   gitlab_rails['packages_enabled'] = true
   gitlab_rails['packages_object_store_enabled'] = true
   gitlab_rails['packages_object_store_remote_directory'] = "packages" # The bucket name.
   gitlab_rails['packages_object_store_proxy_download'] = false        # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
   gitlab_rails['packages_object_store_connection'] = {
     ##
     ## If the provider is AWS S3, uncomment the following
     ##
     #'provider' => 'AWS',
     #'region' => 'eu-west-1',
     #'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     #'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
     ## If an IAM profile is being used with AWS, omit the aws_access_key_id and aws_secret_access_key and uncomment
     #'use_iam_profile' => true,
     ##
     ## If the provider is other than AWS (an S3-compatible one), uncomment the following
     ##
     #'host' => 's3.amazonaws.com',
     #'aws_signature_version' => 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
     #'endpoint' => 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
     #'path_style' => false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

**Installations from source**

1. Edit the `packages` section in `config/gitlab.yml` (uncomment where necessary):

   ```yaml
   packages:
     enabled: true
     ##
     ## The location where build packages are stored (default: shared/packages).
     ##
     # storage_path: shared/packages
     object_store:
       enabled: false
       remote_directory: packages  # The bucket name.
       # proxy_download: false     # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
       connection:
       ##
       ## If the provider is AWS S3, use the following:
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

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Migrating local packages to object storage

After [configuring the object storage](#using-object-storage), use the following task to
migrate existing packages from the local storage to the remote storage.
The processing is done in a background worker and requires **no downtime**.

For Omnibus GitLab:

```shell
sudo gitlab-rake "gitlab:packages:migrate"
```

For installations from source:

```shell
RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:packages:migrate
```

You can optionally track progress and verify that all packages migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- `sudo gitlab-rails dbconsole` for Omnibus GitLab 14.1 and earlier.
- `sudo gitlab-rails dbconsole --database main` for Omnibus GitLab 14.2 and later.
- `sudo -u git -H psql -d gitlabhq_production` for source-installed instances.

Verify `objectstg` below (where `file_store = '2'`) has count of all packages:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM packages_package_files;

total | filesystem | objectstg
------+------------+-----------
 34   |          0 |        34
```

Verify that there are no files on disk in the `packages` folder:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
```
