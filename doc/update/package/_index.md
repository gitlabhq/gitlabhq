---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrading Linux package instances
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Upgrading Linux package instances to a later version of GitLab requires several steps, many specific to Linux package
installations.

## Downtime

- For single node installations, GitLab is not available to users while an
  upgrade is in progress. The user's web browser shows a **Deploy in progress** message or a `502` error.
- For multi-node installations, see how to perform
  [zero-downtime upgrades](../zero_downtime.md).
- Upgrades to multi-node installations can also be performed
  [with downtime](../with_downtime.md).

## Earlier GitLab versions

For version-specific information for earlier GitLab versions, see the [documentation archives](https://archives.docs.gitlab.com).
The versions of the documentation in the archives contain version-specific information for even earlier versions of GitLab.

For example, the [documentation for GitLab 15.11](https://archives.docs.gitlab.com/15.11/ee/update/package/#version-specific-changes)
contains information on versions back to GitLab 11.

## Skip automatic database backups

The GitLab database is backed up before installing a newer GitLab version. You
may skip this automatic database backup by creating an empty file
at `/etc/gitlab/skip-auto-backup`:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

Nevertheless, you should maintain a full up-to-date
[backup](../../administration/backup_restore/_index.md) on your own.

## Upgrade a Linux package instance

To upgrade a Linux package instance:

1. [Complete the initial steps](../_index.md#upgrade-gitlab) in the main GitLab upgrade documentation.
1. If you are upgrading from a non-package installation to a GitLab package installation, follow the steps in
   [Upgrading from a non-package installation to a GitLab package installation](https://docs.gitlab.com/omnibus/update/convert_to_omnibus.html).
1. Continue the upgrade by following the sections below.

### Required services

You can perform upgrades with the GitLab instance online. When you execute the upgrade command, PostgreSQL, Redis, and Gitaly must be running.

### By using the official repositories (recommended)

All GitLab packages are posted to the GitLab [package server](https://packages.gitlab.com/gitlab/).
Six repositories are maintained:

- [`gitlab/gitlab-ee`](https://packages.gitlab.com/gitlab/gitlab-ee): The full
  GitLab package that contains all the Community Edition features plus the
  [Enterprise Edition](https://about.gitlab.com/pricing/) ones.
- [`gitlab/gitlab-ce`](https://packages.gitlab.com/gitlab/gitlab-ce): A stripped
  down package that contains only the Community Edition features.
- [`gitlab/gitlab-fips`](https://packages.gitlab.com/gitlab/gitlab-fips): [FIPS-compliant](../../development/fips_gitlab.md) builds.
- [`gitlab/unstable`](https://packages.gitlab.com/gitlab/unstable): Release candidates and other unstable versions.
- [`gitlab/nightly-builds`](https://packages.gitlab.com/gitlab/nightly-builds): Nightly builds.
- [`gitlab/raspberry-pi2`](https://packages.gitlab.com/gitlab/raspberry-pi2): Official Community Edition releases built for [Raspberry Pi](https://www.raspberrypi.org) packages.

If you have installed GitLab [Community Edition](https://about.gitlab.com/install/?version=ce)
or [Enterprise Edition](https://about.gitlab.com/install/), then the
official GitLab repository should have already been set up for you.

#### Upgrade to the latest version

If you upgrade GitLab regularly (for example, every month), you can upgrade to
the latest version by using the package manager for your Linux distribution.

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

#### Upgrade to a specific version

Linux package managers default to installing the latest available version of a
package for installation and upgrades. Upgrading directly to the latest major
version can be problematic for older GitLab versions that require a multi-stage
[upgrade path](../upgrade_paths.md). An upgrade path can span multiple
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
   (make sure to review the [upgrade path](../upgrade_paths.md) to confirm the
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

### By using a downloaded package

If you don't want to use the official repositories, you can
download the package and install it manually. This method can be used to either
install GitLab for the first time or upgrade it.

To download and install or upgrade GitLab:

1. Go to the [official repository](#by-using-the-official-repositories-recommended) of your package.
1. Filter the list by searching for the version you want to install. For example, `14.1.8`.
   Multiple packages might exist for a single version, one for each supported distribution
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
For the GitLab Community Edition, replace `gitlab-ee` with `gitlab-ce`.

## Upgrade the product documentation (optional)

If you [installed the product documentation](../../administration/docs_self_host.md),
see how to [upgrade to a later version](../../administration/docs_self_host.md#upgrade-using-docker).

## Troubleshooting

See [troubleshooting](package_troubleshooting.md) for more information.
