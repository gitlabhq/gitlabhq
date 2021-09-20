---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Upgrade GitLab using the GitLab Package **(FREE SELF)**

This section describes how to upgrade GitLab to a new version using the
GitLab package.

We recommend performing upgrades between major and minor releases no more than once per
week, to allow time for background migrations to finish. Decrease the time required to
complete these migrations by increasing the number of
[Sidekiq workers](../../administration/operations/extra_sidekiq_processes.md)
that can process jobs in the `background_migration` queue.

If you don't follow the steps in [zero downtime upgrades](../zero_downtime.md),
your GitLab application will not be available to users while an upgrade is in progress.
They either see a "Deploy in progress" message or a "502" error in their web browser.

Prerequisites:

- [Supported upgrade paths](../index.md#upgrade-paths)
  has suggestions on when to upgrade. Upgrade paths are enforced for version upgrades by
  default. This restricts performing direct upgrades that skip major versions (for
  example 10.3 to 12.7 in one jump) that **can break GitLab
  installations** due to multiple reasons like deprecated or removed configuration
  settings, upgrade of internal tools and libraries, and so on.
- If you are upgrading from a non-Package installation to a GitLab Package installation, see
  [Upgrading from a non-Package installation to a GitLab Package installation](https://docs.gitlab.com/omnibus/convert_to_omnibus.html).
- It's important to ensure that any
  [background migrations](../index.md#checking-for-background-migrations-before-upgrading)
  have been fully completed before upgrading to a new major version. Upgrading
  before background migrations have finished may lead to data corruption.
- Gitaly servers must be upgraded to the newer version prior to upgrading the application server.
  This prevents the gRPC client on the application server from sending RPCs that the old Gitaly version
  does not support.

You can upgrade the GitLab Package using one of the following methods:

- [Using the official repositories](#upgrade-using-the-official-repositories).
- [Using a manually-downloaded package](#upgrade-using-a-manually-downloaded-package).

Both automatically back up the GitLab database before installing a newer
GitLab version. You may skip this automatic database backup by creating an empty file
at `/etc/gitlab/skip-auto-backup`:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

For safety reasons, you should maintain an up-to-date backup on your own if you plan to use this flag.

## Version-specific changes

Updating to major versions might need some manual intervention. For more information,
check the version your are upgrading to:

- [GitLab 14](https://docs.gitlab.com/omnibus/update/gitlab_14_changes.html)
- [GitLab 13](https://docs.gitlab.com/omnibus/update/gitlab_13_changes.html)
- [GitLab 12](https://docs.gitlab.com/omnibus/update/gitlab_12_changes.html)
- [GitLab 11](https://docs.gitlab.com/omnibus/update/gitlab_11_changes.html)

## Upgrade using the official repositories

All GitLab packages are posted to the GitLab [package server](https://packages.gitlab.com/gitlab/).
Five repositories are maintained:

- [GitLab EE](https://packages.gitlab.com/gitlab/gitlab-ee): for official
  [Enterprise Edition](https://about.gitlab.com/pricing/) releases.
- [GitLab CE](https://packages.gitlab.com/gitlab/gitlab-ce): for official Community Edition releases.
- [Unstable](https://packages.gitlab.com/gitlab/unstable): for release candidates and other unstable versions.
- [Nighty Builds](https://packages.gitlab.com/gitlab/nightly-builds): for nightly builds.
- [Raspberry Pi](https://packages.gitlab.com/gitlab/raspberry-pi2): for official Community Edition releases built for [Raspberry Pi](https://www.raspberrypi.org) packages.

If you have installed Omnibus GitLab [Community Edition](https://about.gitlab.com/install/?version=ce)
or [Enterprise Edition](https://about.gitlab.com/install/), then the
official GitLab repository should have already been set up for you.

To upgrade to the newest GitLab version, run:

- For GitLab [Enterprise Edition](https://about.gitlab.com/pricing/):

  ```shell
  # Debian/Ubuntu
  sudo apt-get update
  sudo apt-get install gitlab-ee

  # Centos/RHEL
  sudo yum install gitlab-ee
  ```

- For GitLab Community Edition:

  ```shell
  # Debian/Ubuntu
  sudo apt-get update
  sudo apt-get install gitlab-ce

  # Centos/RHEL
  sudo yum install gitlab-ce
  ```

### Upgrade to a specific version using the official repositories

Linux package managers default to installing the latest available version of a
package for installation and upgrades. Upgrading directly to the latest major
version can be problematic for older GitLab versions that require a multi-stage
[upgrade path](../index.md#upgrade-paths). An upgrade path can span multiple
versions, so you must specify the specific GitLab package with each upgrade.

To specify the intended GitLab version number in your package manager's install
or upgrade command:

1. First, identify the GitLab version number in your package manager:

   ```shell
   # Ubuntu/Debian
   sudo apt-cache madison gitlab-ee
   # RHEL/CentOS 6 and 7
   yum --showduplicates list gitlab-ee
   # RHEL/CentOS 8
   dnf search gitlab-ee*
   ```

1. Then install the specific GitLab package:

   ```shell
   # Ubuntu/Debian
   sudo apt install gitlab-ee=12.0.12-ee.0
   # RHEL/CentOS 6 and 7
   yum install gitlab-ee-12.0.12-ee.0.el7
   # RHEL/CentOS 8
   dnf install gitlab-ee-12.0.12-ee.0.el8
   # SUSE
   zypper install gitlab-ee=12.0.12-ee.0
   ```

## Upgrade using a manually-downloaded package

NOTE:
The [package repository](#upgrade-using-the-official-repositories) is recommended over
a manual installation.

If for some reason you don't use the official repositories, you can
download the package and install it manually. This method can be used to either
install GitLab for the first time or update it.

To download and install GitLab:

1. Visit the [official repository](#upgrade-using-the-official-repositories) of your package.
1. Browse to the repository for the type of package you would like to see the
   list of packages that are available. Multiple packages exist for a
   single version, one for each supported distribution type. Next to the filename
   is a label indicating the distribution, as the file names may be the same.
1. Find the package version you wish to install and click on it.
1. Click the **Download** button in the upper right corner to download the package.
1. After the GitLab package is downloaded, install it using the following commands:

   - For GitLab [Enterprise Edition](https://about.gitlab.com/pricing/):

     ```shell
     # Debian/Ubuntu
     dpkg -i gitlab-ee-<version>.deb

     # CentOS/RHEL
     rpm -Uvh gitlab-ee-<version>.rpm
     ```

   - For GitLab Community Edition:

     ```shell
     # GitLab Community Edition
     # Debian/Ubuntu
     dpkg -i gitlab-ce-<version>.deb

     # CentOS/RHEL
     rpm -Uvh gitlab-ce-<version>.rpm
     ```

## Troubleshooting

### GitLab 13.7 and later unavailable on Amazon Linux 2

Amazon Linux 2 is not an [officially supported operating system](../../administration/package_information/deprecated_os.md#supported-operating-systems).
However, in past the [official package installation script](https://packages.gitlab.com/gitlab/gitlab-ee/install)
installed the `el/6` package repository if run on Amazon Linux. From GitLab 13.7, we no longer
provide `el/6` packages so administrators must run the [installation script](https://packages.gitlab.com/gitlab/gitlab-ee/install)
again to update the repository to `el/7`:

```shell
curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
```

See the [epic on support for GitLab on Amazon Linux 2](https://gitlab.com/groups/gitlab-org/-/epics/2195) for the latest details on official Amazon Linux 2 support.

### Get the status of a GitLab installation

```shell
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

- Information on using `gitlab-ctl` to perform [maintenance tasks](https://docs.gitlab.com/omnibus/maintenance/index.html).
- Information on using `gitlab-rake` to [check the configuration](../../administration/raketasks/maintenance.md#check-gitlab-configuration).

### RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition to GitLab Enterprise Edition you may get an error like this:

```shell
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```shell
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

### Package obsoleted by installed package

CE and EE packages are marked as obsoleting and replacing each other so that both aren't installed and running at the same time.

If you are using local RPM files to switch from CE to EE or vice versa, use `rpm` for installing the package rather than `yum`. If you try to use yum, then you may get an error like this:

```plaintext
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

To avoid this issue, either:

- Use the same instructions provided in the
  [Upgrade using a manually-downloaded package](#upgrade-using-a-manually-downloaded-package) section.
- Temporarily disable this checking in yum by adding `--setopt=obsoletes=0` to the options given to the command.

### 500 error when accessing Project > Settings > Repository

When GitLab is migrated from CE > EE > CE, and then back to EE, you
might get the following error when viewing a project's repository settings:

```shell
Processing by Projects::Settings::RepositoryController#show as HTML
  Parameters: {"namespace_id"=>"<namespace_id>", "project_id"=>"<project_id>"}
Completed 500 Internal Server Error in 62ms (ActiveRecord: 4.7ms | Elasticsearch: 0.0ms | Allocations: 14583)

NoMethodError (undefined method `commit_message_negative_regex' for #<PushRule:0x00007fbddf4229b8>
Did you mean?  commit_message_regex_change):
```

This error is caused by an EE feature being added to a CE instance on the initial move to EE.
After the instance is moved back to CE and then is upgraded to EE again, the
`push_rules` table already exists in the database. Therefore, a migration is
unable to add the `commit_message_regex_change` column.

This results in the [backport migration of EE tables](https://gitlab.com/gitlab-org/gitlab/-/blob/cf00e431024018ddd82158f8a9210f113d0f4dbc/db/migrate/20190402150158_backport_enterprise_schema.rb#L1619) not working correctly.
The backport migration assumes that certain tables in the database do not exist when running CE.

To fix this issue, manually add the missing `commit_message_negative_regex` column and restart GitLab:

```shell
# Access psql
sudo gitlab-rails dbconsole

# Add the missing column
ALTER TABLE push_rules ADD COLUMN commit_message_negative_regex VARCHAR;

# Exit psql
\q

# Restart GitLab
sudo gitlab-ctl restart
```

### Error `Failed to connect to the internal GitLab API` on a separate GitLab Pages server

Please see [GitLab Pages troubleshooting](../../administration/pages/index.md#failed-to-connect-to-the-internal-gitlab-api).
