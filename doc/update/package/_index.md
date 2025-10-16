---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade Linux package instances
description: Upgrade a Linux package-based instance.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The instructions for upgrading a Linux package instance depend on whether you have a single-node or multi-node
GitLab instance. To upgrade a multi-node instance, see:

- [Upgrade a multi-node instance with downtime](../with_downtime.md).
- [Upgrade a multi-node instance with zero downtime](../zero_downtime.md).

To upgrade a single-node GitLab instance:

1. [Complete the initial steps](../upgrade.md#upgrade-gitlab) in the main GitLab upgrade documentation.
1. Continue the upgrade by following the next sections.
1. After upgrading, if you host the product documentation, you can
   [upgrade to a later version](../../administration/docs_self_host.md#upgrade-the-product-documentation-to-a-later-version).

## Prerequisites

Before you upgrade a Linux package instance:

- Consult [information you need before you upgrade](../plan_your_upgrade.md).
- If required, upgrade to a [supported operating system](../../install/package/_index.md).
- When upgrading the operating system, if your `glibc` version changes, you must follow
  [upgrading operating systems for PostgreSQL](../../administration/postgresql/upgrading_os.md) to avoid corrupted indexes.
- Ensure PostgreSQL, Redis, and Gitaly are running.

The GitLab database is backed up before installing a newer GitLab version. You can skip this automatic database backup
by creating an empty file at `/etc/gitlab/skip-auto-backup`:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

Nevertheless, you should maintain a full up-to-date [backup](../../administration/backup_restore/_index.md) on your own.

## Upgrade by using the official repositories (recommended)

All GitLab packages are posted to the GitLab [package server](https://packages.gitlab.com/gitlab/).

| Repository                                                                             | Description |
|:---------------------------------------------------------------------------------------|:------------|
| [`gitlab/gitlab-ce`](https://packages.gitlab.com/gitlab/gitlab-ce)                     | Stripped down package that contains only the Community Edition features. |
| [`gitlab/gitlab-ee`](https://packages.gitlab.com/gitlab/gitlab-ee)                     | Full GitLab package that contains all the Community Edition and Enterprise Edition features. |
| [`gitlab/nightly-builds`](https://packages.gitlab.com/gitlab/nightly-builds)           | Nightly builds. |
| [`gitlab/nightly-fips-builds`](https://packages.gitlab.com/gitlab/nightly-fips-builds) | Nightly FIPS-compliant builds. |
| [`gitlab/gitlab-fips`](https://packages.gitlab.com/gitlab/gitlab-fips)                 | FIPS-compliant builds. |

By default, Linux distribution package managers install the latest available version of a package. You can't upgrade directly to the
latest major version of GitLab if your [upgrade path](../upgrade_paths.md) requires multiple stops. If your upgrade
path includes multiple versions, you must specify the specific GitLab package version with each upgrade.

If your upgrade path has no interim steps, you can upgrade directly to the latest version.

{{< tabs >}}

{{< tab title="Ubuntu/Debian" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo apt update && sudo apt install gitlab-ee=<version>-ee.0

# GitLab Community Edition (specific version)
sudo apt update && sudo apt install gitlab-ce=<version>-ce.0

# GitLab Enterprise Edition (latest version)
sudo apt update && sudo apt install gitlab-ee

# GitLab Community Edition (latest version)
sudo apt update && sudo apt install gitlab-ce
```

{{< /tab >}}

{{< tab title="Amazon Linux 2" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo yum install gitlab-ee-<version>-ee.0.amazon2

# GitLab Community Edition (specific version)
sudo yum install gitlab-ce-<version>-ce.0.amazon2

# GitLab Enterprise Edition (latest version)
sudo yum install gitlab-ee

# GitLab Community Edition (latest version)
sudo yum install gitlab-ce
```

{{< /tab >}}

{{< tab title="RHEL/Oracle Linux/AlmaLinux 8/9" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo dnf install gitlab-ee-<version>-ee.0.el9

# GitLab Enterprise Edition (specific version)
sudo dnf install gitlab-ee-<version>-ee.0.el8

# GitLab Community Edition (specific version)
sudo dnf install gitlab-ce-<version>-ce.0.el9

# GitLab Community Edition (specific version)
sudo dnf install gitlab-ce-<version>-ce.0.el8

# GitLab Enterprise Edition (latest version)
sudo dnf install gitlab-ee

# GitLab Community Edition (latest version)
sudo dnf install gitlab-ce
```

{{< /tab >}}

{{< tab title="Amazon Linux 2023" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo dnf install gitlab-ee-<version>-ee.0.amazon2023

# GitLab Community Edition (specific version)
sudo dnf install gitlab-ce-<version>-ce.0.amazon2023

# GitLab Enterprise Edition (latest version)
sudo dnf install gitlab-ee

# GitLab Community Edition (latest version)
sudo dnf install gitlab-ce
```

{{< /tab >}}

{{< tab title="OpenSUSE Leap 15.5" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo zypper install gitlab-ee=<version>-ee.sles15

# GitLab Community Edition (specific version)
sudo zypper install gitlab-ce=<version>-ce.sles15

# GitLab Enterprise Edition (latest version)
sudo zypper install gitlab-ee

# GitLab Community Edition (latest version)
sudo zypper install gitlab-ce
```

{{< /tab >}}

{{< tab title="SUSE Enterprise Server 12.2/12.5" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo zypper install gitlab-ee=<version>-ee.0.sles12

# GitLab Community Edition (specific version)
sudo zypper install gitlab-ce=<version>-ce.0.sles12

# GitLab Enterprise Edition (latest version)
sudo zypper install gitlab-ee

# GitLab Community Edition (latest version)
sudo zypper install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

## Upgrade by using a downloaded package

If you don't want to use the official repositories, you can
download the package and install it manually. This method can be used to either
install GitLab for the first time or upgrade it.

To download and install or upgrade GitLab:

1. Go to the [official repository](#upgrade-by-using-the-official-repositories-recommended) of your package.
1. Filter the list by searching for the version you want to install. For example, `18.4.1`. Multiple packages might
   exist for a single version, one for each supported distribution and architecture. Because some files are
   relevant to more than one distribution, there is a label next to the filename that indicates the distribution.
1. Find the package version you wish to install, and select the filename from the list.
1. In the upper-right corner, select **Download**.
1. After the package is downloaded, install it by using one of the
   following commands and replacing `<package_name>` with the package name
   you downloaded:

   {{< tabs >}}

   {{< tab title="Ubuntu/Debian" >}}

   ```shell
   dpkg -i <package_name>
   ```

   {{< /tab >}}

   {{< tab title="Amazon Linux 2" >}}

   ```shell
   rpm -Uvh <package_name>
   ```

   {{< /tab >}}

   {{< tab title="RHEL/Oracle Linux/AlmaLinux 8/9 and Amazon Linux 2023" >}}

   ```shell
   dnf install <package_name>
   ```

   {{< /tab >}}

   {{< tab title="SUSE and OpenSUSE" >}}

   ```shell
   zypper install <package_name>
   ```

   {{< /tab >}}

   {{< /tabs >}}
