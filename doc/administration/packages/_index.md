---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab package registry administration
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To use GitLab as a private repository for a variety of common package managers, use the package registry.
You can build and publish
packages, which can be consumed as dependencies in downstream projects.

## Supported formats

The package registry supports the following formats:

| Package type                                                       | GitLab version |
|--------------------------------------------------------------------|----------------|
| [Composer](../../user/packages/composer_repository/_index.md)      | 13.2+          |
| [Conan 1](../../user/packages/conan_1_repository/_index.md)        | 12.6+          |
| [Conan 2](../../user/packages/conan_2_repository/_index.md)        | 18.1+          |
| [Go](../../user/packages/go_proxy/_index.md)                       | 13.1+          |
| [Maven](../../user/packages/maven_repository/_index.md)            | 11.3+          |
| [npm](../../user/packages/npm_registry/_index.md)                  | 11.7+          |
| [NuGet](../../user/packages/nuget_repository/_index.md)            | 12.8+          |
| [PyPI](../../user/packages/pypi_repository/_index.md)              | 12.10+         |
| [Generic packages](../../user/packages/generic_packages/_index.md) | 13.5+          |
| [Helm Charts](../../user/packages/helm_repository/_index.md)       | 14.1+          |

The package registry is also used to store [model registry data](../../user/project/ml/model_registry/_index.md).

## Accepting contributions

The following table lists package formats that are not supported.
Consider contributing to GitLab to add support for these formats.

<!-- vale gitlab_base.Spelling = NO -->

| Format | Status |
| ------ | ------ |
| Chef      | [#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Debian    | [Draft: Merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50438) |
| Opkg      | [#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [#5932](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) |
| RubyGems  | [#803](https://gitlab.com/gitlab-org/gitlab/-/issues/803) |
| SBT       | [#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Terraform | [Draft: Merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834) |
| Vagrant   | [#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab_base.Spelling = YES -->

## Rate limits

When downloading packages as dependencies in downstream projects, many requests are made through the
Packages API. You may therefore reach enforced user and IP rate limits. To address this issue, you
can define specific rate limits for the Packages API. For more details, see [package registry rate limits](../settings/package_registry_rate_limits.md).

## Enable or disable the package registry

The package registry is enabled by default. To disable it:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Change to true to enable packages - enabled by default if not defined
   gitlab_rails['packages_enabled'] = false
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       packages:
         enabled: false
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['packages_enabled'] = false
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     packages:
       enabled: false
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Change the storage path

By default, the packages are stored locally, but you can change the default
local location or even use object storage.

### Change the local storage path

By default, the packages are stored in a local path, relative to the GitLab
installation:

- Linux package (Omnibus): `/var/opt/gitlab/gitlab-rails/shared/packages/`
- Self-compiled (source): `/home/git/gitlab/shared/packages/`

To change the local storage path:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['packages_storage_path'] = "/mnt/packages"
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     packages:
       enabled: true
       storage_path: /mnt/packages
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

If you already had packages stored in the old storage path, move everything
from the old to the new location to ensure existing packages stay accessible:

```shell
mv /var/opt/gitlab/gitlab-rails/shared/packages/* /mnt/packages/
```

Docker and Kubernetes do not use local storage.

- For the Helm chart (Kubernetes): Use object storage instead.
- For Docker: The `/var/opt/gitlab/` directory is already
  mounted in a directory on the host. There's no need to change the local
  storage path inside the container.

### Use object storage

Instead of relying on the local storage, you can use an object storage to store
packages.

For more information, see how to use the
[consolidated object storage settings](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

### Migrate packages between object storage and local storage

After configuring object storage, you can use the following tasks to migrate packages between local and remote storage. The processing is done in a background worker and requires **no downtime**.

#### Migrate to object storage

1. Migrate the packages to object storage:

   {{< tabs >}}
   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate"
   ```

   {{< /tab >}}
   {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:packages:migrate
   ```

   {{< /tab >}}
   {{< /tabs >}}

1. Track the progress and verify that all packages migrated successfully using the PostgreSQL console:

   {{< tabs >}}
   {{< tab title="Linux package (Omnibus) 14.1 and earlier" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}}
   {{< tab title="Linux package (Omnibus) 14.2 and later" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}}
   {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}}
   {{< /tabs >}}

1. Verify that all packages migrated to object storage with the following SQL query. The number of `objectstg` should be the same as `total`:

   ```sql
   SELECT count(*) AS total, 
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem, 
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg 
   FROM packages_package_files;
   ```

   Example output:

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |          0 |        34
   ```

1. Finally, verify that there are no files on disk in the `packages` directory:

   {{< tabs >}}
   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}
   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}
   {{< /tabs >}}

#### Migrate from object storage to local storage

1. Migrate the packages from object storage to local storage:

   {{< tabs >}}
   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}}
   {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}}
   {{< /tabs >}}

1. Track the progress and verify that all packages migrated successfully using the PostgreSQL console:

   {{< tabs >}}
   {{< tab title="Linux package (Omnibus) 14.1 and earlier" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}}
   {{< tab title="Linux package (Omnibus) 14.2 and later" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}}
   {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}}
   {{< /tabs >}}

1. Verify that all packages migrated to local storage with the following SQL query. The number of `filesystem` should be the same as `total`:

   ```sql
   SELECT count(*) AS total, 
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem, 
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg 
   FROM packages_package_files;
   ```

   Example output:

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |         34 |         0
   ```

1. Finally, verify that the files exist in the `packages` directory:

   {{< tabs >}}
   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}
   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}
   {{< /tabs >}}
