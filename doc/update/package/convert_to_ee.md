---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Convert Community Edition to Enterprise Edition **(FREE SELF)**

To convert an existing GitLab Community Edition (CE) server installed using the Omnibus GitLab
packages to GitLab [Enterprise Edition](https://about.gitlab.com/pricing/) (EE), you install the EE
package on top of CE.

Converting from the same version of CE to EE is not explicitly necessary, and any standard upgrade
(for example, CE 12.0 to EE 12.1) should work. However, in the following steps we assume that
you are upgrading the same version (for example, CE 12.1 to EE 12.1), which is **recommended**.

WARNING:
When updating to EE from CE, avoid reverting back to CE if you plan to go to EE again in the
future. Reverting back to CE can cause
[database issues](index.md#500-error-when-accessing-project--settings--repository)
that may require Support intervention.

The steps can be summed up to:

1. Make a [GitLab backup](../../raketasks/backup_gitlab.md).

1. Find the currently installed GitLab version:

   **For Debian/Ubuntu**

   ```shell
   sudo apt-cache policy gitlab-ce | grep Installed
   ```

   The output should be similar to: `Installed: 13.0.4-ce.0`. In that case,
   the equivalent Enterprise Edition version is: `13.0.4-ee.0`. Write this
   value down.

   **For CentOS/RHEL**

   ```shell
   sudo rpm -q gitlab-ce
   ```

   The output should be similar to: `gitlab-ce-13.0.4-ce.0.el8.x86_64`. In that
   case, the equivalent Enterprise Edition version is:
   `gitlab-ee-13.0.4-ee.0.el8.x86_64`. Write this value down.

1. Add the `gitlab-ee` [Apt or Yum repository](https://packages.gitlab.com/gitlab/gitlab-ee/install):

   **For Debian/Ubuntu**

   ```shell
   curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   **For CentOS/RHEL**

   ```shell
   curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   ```

   The above command finds your OS version and automatically set up the
   repository. If you are not comfortable installing the repository through a
   piped script, you can first
   [check its contents](https://packages.gitlab.com/gitlab/gitlab-ee/install).

   NOTE:
   If you want to use `dpkg`/`rpm` instead of `apt-get`/`yum`, go through the first
   step to find the current GitLab version, then follow
   [Upgrade using a manually-downloaded package](index.md#upgrade-using-a-manually-downloaded-package),
   and then [add your license](../../user/admin_area/license.md).

1. Install the `gitlab-ee` package. The install automatically
   uninstalls the `gitlab-ce` package on your GitLab server. `reconfigure`
   Omnibus right after the `gitlab-ee` package is installed. **Make sure that you
   install the exact same GitLab version**:

   **For Debian/Ubuntu**

   ```shell
   ## Make sure the repositories are up-to-date
   sudo apt-get update

   ## Install the package using the version you wrote down from step 1
   sudo apt-get install gitlab-ee=13.0.4-ee.0

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

   **For CentOS/RHEL**

   ```shell
   ## Install the package using the version you wrote down from step 1
   sudo yum install gitlab-ee-13.0.4-ee.0.el8.x86_64

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

1. Now activate GitLab Enterprise Edition by [adding your license](../../user/admin_area/license.md).

1. After you confirm that GitLab is working as expected, you may remove the old
   Community Edition repository:

   **For Debian/Ubuntu**

   ```shell
   sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ce.list
   ```

   **For CentOS/RHEL**

   ```shell
   sudo rm /etc/yum.repos.d/gitlab_gitlab-ce.repo
   ```

1. Optional. [Set up the Elasticsearch integration](../../integration/advanced_search/elasticsearch.md) to enable [advanced search](../../user/search/advanced_search.md).

That's it! You can now use GitLab Enterprise Edition! To upgrade to a newer
version, follow [Upgrade using the official repositories](index.md#upgrade-using-the-official-repositories).
