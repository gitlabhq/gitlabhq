---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reduce package registry storage
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Package registries accumulate packages and their assets over time. Without regular cleanup:

- Package lists take longer to fetch, which impacts CI/CD pipeline performance
- Servers allocate more storage space to unused or old packages
- Users might struggle to find relevant packages among numerous outdated package versions

You should implement a regular cleanup strategy to reduce package registry bloat and free up storage.

## Review package registry storage use

To review the storage **Usage breakdown**:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Usage quotas**.
1. From the **Usage quotas** page, review the **Usage breakdown** for packages.

## Delete a package

You cannot edit a package after you publish it in the package registry. Instead, you
must delete the package and republish it.

Prerequisites:

- You must have at least the Maintainer role.

To delete a package:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Deploy** > **Package registry**.
1. From the **Package registry** page, select the package you want to delete.
   - Or, from the **Package registry** page,
   select the vertical ellipsis ({{< icon name="ellipsis_v" >}})
   and select **Delete package**.
1. Select **Delete**.

The package is permanently deleted.

To delete a package, you can also use [the API](../../../api/packages.md#delete-a-project-package).

{{< alert type="note" >}}

You can introduce a [dependency confusion risk](supported_functionality.md#deleting-packages)
if you delete a package while
[request forwarding](supported_functionality.md#forwarding-requests) is enabled.

{{< /alert >}}

## Delete package assets

Delete assets associated with a package to reduce storage.

Prerequisites:

- You must have at least the Developer role.

To delete package assets:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Deploy** > **Package registry**.
1. From the **Package registry** page, select a package to view additional details.
1. From the **Assets** table, find the name of the assets you want to delete.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) and select **Delete asset**.

The package assets are permanently deleted.

To delete a package, you can also use [the API](../../../api/packages.md#delete-a-package-file).

## Cleanup policy

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346153) in GitLab 15.2.

{{< /history >}}

When you upload a package with the same name and version to the package registry,
more assets are added to the package.

To save storage space, you should keep only the most recent assets. Use a cleanup policy
to define rules that automatically delete package assets in a project so you do not
have to delete them manually.

### Enable the cleanup policy

Prerequisites:

- You must have at least the Maintainer role.

By default, the packages cleanup policy is disabled. To enable it:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Packages and registries**.
1. Expand **Package registry**.
1. Under **Manage storage used by package assets**, set the rules appropriately.

### Available rules

- `Number of duplicated assets to keep`: Some package formats support multiple copies of the same asset.
You can set a limit on how many duplicated assets to keep.
When the limit is reached, the oldest assets are automatically deleted.
Unique filenames, like those produced by Maven snapshots, are not counted as duplicated assets.

- `Number of duplicated assets to keep` runs [every 12 hours](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/packages/cleanup/policy.rb).

### Set cleanup limits to conserve resources

A background process executes the package cleanup policies. This process can take a long time to finish and consumes
server resources while it runs.

Use the following setting to limit the number of cleanup workers:

- `package_registry_cleanup_policies_worker_capacity`: the maximum number of cleanup workers running concurrently.
  This number must be greater than or equal to `0`.
  You should start with a low number and increase it after monitoring the resources used by the background workers.
  To remove all workers and not execute the cleanup policies, set this setting to `0`. The default value is `2`.
