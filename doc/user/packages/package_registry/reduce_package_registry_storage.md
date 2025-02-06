---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reduce package registry storage
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Without cleanup, package registries become large over time. When a large number of packages and
their assets are added:

- Fetching the list of packages becomes slower.
- They take up a large amount of storage space on the server.

We recommend deleting unnecessary packages and assets. This page offers examples of how to do so.

## Check package registry storage use

The Usage Quotas page (**Settings > Usage Quotas > Storage**) displays storage usage for Packages.

## Delete a package

You cannot edit a package after you publish it in the package registry. Instead, you
must delete and recreate it.

To delete a package, you must have suitable [permissions](../../permissions.md).

You can delete packages by using [the API](../../../api/packages.md#delete-a-project-package) or the UI.

To delete a package in the UI, from your group or project:

1. Go to **Deploy > Package Registry**.
1. Find the name of the package you want to delete.
1. Select **Delete**.

The package is permanently deleted.

If [request forwarding](supported_functionality.md#forwarding-requests) is enabled,
deleting a package can introduce a [dependency confusion risk](supported_functionality.md#deleting-packages).

## Delete assets associated with a package

To delete package assets, you must have suitable [permissions](../../permissions.md).

You can delete packages by using [the API](../../../api/packages.md#delete-a-package-file) or the UI.

To delete package assets in the UI, from your group or project:

1. Go to **Deploy > Package Registry**.
1. Find the name of the package you want to delete.
1. Select the package to view additional details.
1. Find the name of the assets you would like to delete.
1. Expand the ellipsis and select **Delete asset**.

The package assets are permanently deleted.

## Cleanup policy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346153) in GitLab 15.2.

Depending on the number of packages to remove, the process of manually deleting the packages can take a long time to finish.
A cleanup policy defines a set of rules that, applied to a project, defines which package assets you can automatically delete.

### Enable the cleanup policy

By default, the packages cleanup policy is disabled. To enable it:

1. Go to your project **Settings > Packages and registries**.
1. Expand **Package registry**.
1. Under **Manage storage used by package assets**, set the rules appropriately.

NOTE:
To access these project settings, you must be at least a maintainer on the related project.

### Available rules

- `Number of duplicated assets to keep`: The number of duplicated assets to keep. Some package formats allow you
  to upload more than one copy of an asset. You can limit the number of duplicated assets to keep and automatically
  delete the oldest assets once the limit is reached. Unique filenames, such as those produced by Maven snapshots, are not considered when evaluating the number of duplicated assets to keep.

  `Number of duplicated assets to keep` has a [fixed cadence of 12 hours](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/packages/cleanup/policy.rb).

### Set cleanup limits to conserve resources

A background process executes the package-cleanup policies. This process can take a long time to finish and consumes
server resources while it is running.

You can use the following setting to limit the number of cleanup workers:

- `package_registry_cleanup_policies_worker_capacity`: the maximum number of cleanup workers running concurrently.
  This number must be greater than or equal to `0`.
  We recommend starting with a low number and increasing it after monitoring the resources used by the background workers.
  To remove all workers and not execute the cleanup policies, set this to `0`. The default value is `2`.
