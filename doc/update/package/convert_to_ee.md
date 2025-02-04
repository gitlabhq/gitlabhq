---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Convert a Linux package CE instance to EE
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can convert an existing Linux package instance from Community Edition (CE) to Enterprise Edition (EE).
To convert the instance, you install the EE Linux package on top of the CE instance.

You don't need the same version of CE to EE. For example, CE 17.0 to EE 17.1 should work. However, upgrading the same
version (for example, CE 17.1 to EE 17.1) is **recommended**.

WARNING:
After you convert from EE from CE, don't revert back to CE if you plan to go to EE again. Reverting back to CE can cause
[database issues](package_troubleshooting.md#500-error-when-accessing-project-repository-settings) that may require
Support intervention.

## Convert from CE to EE

To convert a Linux package CE instance to EE:

1. Make a [GitLab backup](../../administration/backup_restore/backup_gitlab.md).
1. Find the installed GitLab version:

   ::Tabs

   :::TabTitle Debian/Ubuntu

   ```shell
   sudo apt-cache policy gitlab-ce | grep Installed
   ```

   Note down the returned version.

   :::TabTitle CentOS/RHEL

   ```shell
   sudo rpm -q gitlab-ce
   ```

   Note down the returned version.

   ::EndTabs

1. Add the `gitlab-ee` [Apt or Yum repository](https://packages.gitlab.com/gitlab/gitlab-ee/install). These commands
   find your OS version and automatically set up the repository. If you are not comfortable installing the repository
   through a piped script, you can first [check the script's contents](https://packages.gitlab.com/gitlab/gitlab-ee/install).

   ::Tabs

   :::TabTitle Debian/Ubuntu

   ```shell
   curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   :::TabTitle CentOS/RHEL

   ```shell
   curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   ```

   ::EndTabs

   To use `dpkg` or `rpm` instead of using `apt-get` or `yum` follow
   [Upgrade using a manually downloaded package](_index.md#by-using-a-downloaded-package).

1. Install the `gitlab-ee` Linux package. The install automatically uninstalls the `gitlab-ce` package on your GitLab.

   ::Tabs

   :::TabTitle Debian/Ubuntu

   ```shell
   ## Make sure the repositories are up-to-date
   sudo apt-get update

   ## Install the package using the version you wrote down from step 1
   sudo apt-get install gitlab-ee=17.1.0-ee.0

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

   :::TabTitle CentOS/RHEL

   ```shell
   ## Install the package using the version you wrote down from step 1
   sudo yum install gitlab-ee-17.1.0-ee.0.el9.x86_64

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

   ::EndTabs

1. [Add your license](../../administration/license.md) to activate Enterprise Edition.
1. Confirm that GitLab is working as expected, then you can remove the old Community Edition repository:

   ::Tabs

   :::TabTitle Debian/Ubuntu

   ```shell
   sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ce.list
   ```

   :::TabTitle CentOS/RHEL

   ```shell
   sudo rm /etc/yum.repos.d/gitlab_gitlab-ce.repo
   ```

   ::EndTabs

1. Optional. [Set up the Elasticsearch integration](../../integration/advanced_search/elasticsearch.md) to enable
   [advanced search](../../user/search/advanced_search.md).

That's it! You can now use GitLab Enterprise Edition! To upgrade to a newer
version, follow [Upgrading Linux package instances](_index.md).
