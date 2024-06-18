---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrade GitLab by using the GitLab package

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

You can upgrade GitLab to a new version by using the
GitLab package.

## Prerequisites

- Decide when to upgrade by viewing the [supported upgrade paths](../index.md#upgrade-paths).
  You can't directly skip major versions (for example, go from 10.3 to 12.7 in one step).
- If you are upgrading from a non-package installation to a GitLab package installation, see
  [Upgrading from a non-package installation to a GitLab package installation](https://docs.gitlab.com/omnibus/update/convert_to_omnibus.html).
- Ensure that any
  [background migrations](../background_migrations.md)
  are fully completed. Upgrading
  before background migrations have finished can lead to data corruption.
  We recommend performing upgrades between major and minor releases no more than once per
  week, to allow time for background migrations to finish.
- Gitaly servers must be upgraded to the newer version prior to upgrading the application server.
  This prevents the gRPC client on the application server from sending RPCs that the old Gitaly version
  does not support.

## Downtime

- For single node installations, GitLab is not available to users while an
  upgrade is in progress. The user's web browser shows a `Deploy in progress` message or a `502` error.
- For multi-node installations, see how to perform
  [zero-downtime upgrades](../zero_downtime.md).
- Upgrades to multi-node installations can also be performed
  [with downtime](../with_downtime.md).

## Version-specific changes

Upgrading versions might need some manual intervention. For more information,
check the version you are upgrading to:

- [GitLab 17](../versions/gitlab_17_changes.md)
- [GitLab 16](../versions/gitlab_16_changes.md)
- [GitLab 15](../versions/gitlab_15_changes.md)

### Earlier GitLab versions

For version-specific information for earlier GitLab versions, see the [documentation archives](https://archives.docs.gitlab.com).
The versions of the documentation in the archives contain version-specific information for even earlier versions of GitLab.

For example, the [documentation for GitLab 15.11](https://archives.docs.gitlab.com/15.11/ee/update/package/#version-specific-changes)
contains information on versions back to GitLab 11.

## Back up before upgrading

The GitLab database is backed up before installing a newer GitLab version. You
may skip this automatic database backup by creating an empty file
at `/etc/gitlab/skip-auto-backup`:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

Nevertheless, it is highly recommended to maintain a full up-to-date
[backup](../../administration/backup_restore/index.md) on your own.

## Upgrade using the official repositories

All GitLab packages are posted to the GitLab [package server](https://packages.gitlab.com/gitlab/).
Six repositories are maintained:

- [`gitlab/gitlab-ee`](https://packages.gitlab.com/gitlab/gitlab-ee): The full
  GitLab package that contains all the Community Edition features plus the
  [Enterprise Edition](https://about.gitlab.com/pricing/) ones.
- [`gitlab/gitlab-ce`](https://packages.gitlab.com/gitlab/gitlab-ce): A stripped
  down package that contains only the Community Edition features.
- [`gitlab/gitlab-fips`](https://packages.gitlab.com/gitlab/gitlab-fips): [FIPS-compliant](../../development/fips_compliance.md) builds.
- [`gitlab/unstable`](https://packages.gitlab.com/gitlab/unstable): Release candidates and other unstable versions.
- [`gitlab/nightly-builds`](https://packages.gitlab.com/gitlab/nightly-builds): Nightly builds.
- [`gitlab/raspberry-pi2`](https://packages.gitlab.com/gitlab/raspberry-pi2): Official Community Edition releases built for [Raspberry Pi](https://www.raspberrypi.org) packages.

If you have installed GitLab [Community Edition](https://about.gitlab.com/install/?version=ce)
or [Enterprise Edition](https://about.gitlab.com/install/), then the
official GitLab repository should have already been set up for you.

### Upgrade to the latest version using the official repositories

If you upgrade GitLab regularly, for example once a month, you can upgrade to
the latest version by using your package manager.

To upgrade to the latest GitLab version:

```shell
# Ubuntu/Debian
sudo apt update && sudo apt install gitlab-ee

# RHEL/CentOS 7 and Amazon Linux 2
sudo yum install gitlab-ee

# RHEL/Almalinux 8/9 and Amazon Linux 2023
sudo dnf install gitlab-ee

# SUSE
sudo zypper install gitlab-ee
```

NOTE:
For the GitLab Community Edition, replace `gitlab-ee` with
`gitlab-ce`.

### Upgrade to a specific version using the official repositories

Linux package managers default to installing the latest available version of a
package for installation and upgrades. Upgrading directly to the latest major
version can be problematic for older GitLab versions that require a multi-stage
[upgrade path](../index.md#upgrade-paths). An upgrade path can span multiple
versions, so you must specify the specific GitLab package with each upgrade.

To specify the intended GitLab version number in your package manager's install
or upgrade command:

1. Identify the version number of the installed package:

   ```shell
   # Ubuntu/Debian
   sudo apt-cache madison gitlab-ee

   # RHEL/CentOS 7 and Amazon Linux 2
   yum --showduplicates list gitlab-ee

   # RHEL/Almalinux 8/9 and Amazon Linux 2023
   dnf --showduplicates list gitlab-ee

   # SUSE
   zypper search -s gitlab-ee
   ```

1. Install the specific `gitlab-ee` package by using one of the following commands
   and replacing `<version>` with the next supported version you would like to install
   (make sure to review the [upgrade path](../index.md#upgrade-paths) to confirm the
   version you're installing is part of a supported path):

   ```shell
   # Ubuntu/Debian
   sudo apt install gitlab-ee=<version>-ee.0

   # RHEL/CentOS 7 and Amazon Linux 2
   sudo yum install gitlab-ee-<version>-ee.0.el7

   # RHEL/Almalinux 8/9
   sudo dnf install gitlab-ee-<version>-ee.0.el8

   # Amazon Linux 2023
   sudo dnf install gitlab-ee-<version>-ee.0.amazon2023

   # OpenSUSE Leap 15.5
   sudo zypper install gitlab-ee=<version>-ee.sles15

   # SUSE Enterprise Server 12.2/12.5
   sudo zypper install gitlab-ee=<version>-ee.0.sles12
   ```

NOTE:
For the GitLab Community Edition, replace `ee` with
`ce`.

## Upgrade using a manually-downloaded package

NOTE:
The [package repository](#upgrade-using-the-official-repositories) is recommended over
a manual installation.

If for some reason you don't use the official repositories, you can
download the package and install it manually. This method can be used to either
install GitLab for the first time or upgrade it.

To download and install GitLab:

1. Visit the [official repository](#upgrade-using-the-official-repositories) of your package.
1. Filter the list by searching for the version you want to install (for example 14.1.8).
   Multiple packages may exist for a single version, one for each supported distribution
   and architecture. Next to the filename is a label indicating the distribution,
   as the filenames may be the same.
1. Find the package version you wish to install, and select the filename from the list.
1. In the upper-right corner, select **Download**.
1. After the package is downloaded, install it by using one of the
   following commands and replacing `<package_name>` with the package name
   you downloaded:

   ```shell
   # Debian/Ubuntu
   dpkg -i <package_name>

   # RHEL/CentOS 7 and Amazon Linux 2
   rpm -Uvh <package_name>

   # RHEL/Almalinux 8/9 and Amazon Linux 2023
   dnf install <package_name>

   # SUSE
   zypper install <package_name>
   ```

NOTE:
For the GitLab Community Edition, replace `gitlab-ee` with
`gitlab-ce`.

## Upgrade the product documentation

This is an optional step. If you [installed the product documentation](../../administration/docs_self_host.md),
see how to [upgrade to a later version](../../administration/docs_self_host.md#upgrade-using-docker).

## Troubleshooting

See [troubleshooting](package_troubleshooting.md) for more information.
