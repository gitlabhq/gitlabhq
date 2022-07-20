---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Reduce Package Registry Storage **(FREE)**

Without cleanup, package registries become large over time. When a large number of packages and
their files are added:

- Fetching the list of packages becomes slower.
- They take up a large amount of storage space on the server, impacting your [storage usage quota](../../usage_quotas.md).

We recommend deleting unnecessary packages and files. This page offers examples of how to do so.

## Check Package Registry Storage Use

The Usage Quotas page (**Settings > Usage Quotas > Storage**) displays storage usage for Packages.

## Delete a package

You cannot edit a package after you publish it in the Package Registry. Instead, you
must delete and recreate it.

To delete a package, you must have suitable [permissions](../../permissions.md).

You can delete packages by using [the API](../../../api/packages.md#delete-a-project-package) or the UI.

To delete a package in the UI, from your group or project:

1. Go to **Packages & Registries > Package Registry**.
1. Find the name of the package you want to delete.
1. Select **Delete**.

The package is permanently deleted.

## Delete files associated with a package

To delete package files, you must have suitable [permissions](../../permissions.md).

You can delete packages by using [the API](../../../api/packages.md#delete-a-package-file) or the UI.

To delete package files in the UI, from your group or project:

1. Go to **Packages & Registries > Package Registry**.
1. Find the name of the package you want to delete.
1. Select the package to view additional details.
1. Find the name of the file you would like to delete.
1. Expand the ellipsis and select **Delete file**.

The package files are permanently deleted.

## Cleanup policy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346153) in GitLab 15.2.

Depending on the number of packages to remove, the process of manually deleting the packages can take a long time to finish.
A cleanup policy defines a set of rules that, applied to a project, defines which package files you can automatically delete.

### Enable the cleanup policy

By default, the packages cleanup policy is disabled. To enable it:

1. Go to your project **Settings > Packages & Registries**.
1. Expand **Manage storage used by package assets**.
1. Set the rules appropriately.

NOTE:
To access these project settings, you must be at least a maintainer on the related project.

### Available rules

- `Number of duplicated assets to keep`. The number of duplicated assets to keep. Some package formats allow you
  to upload more than one copy of an asset. You can limit the number of duplicated assets to keep and automatically
  delete the oldest files once the limit is reached.

### Set cleanup limits to conserve resources

A background process executes the package-cleanup policies. This process can take a long time to finish and consumes
server resources while it is running.

You can use the following setting to limit the number of cleanup workers:

- `package_registry_cleanup_policies_worker_capacity`: the maximum number of cleanup workers running concurrently.
  This number must be greater than or equal to `0`.
  We recommend starting with a low number and increasing it after monitoring the resources used by the background workers.
  To remove all workers and not execute the cleanup policies, set this to `0`. The default value is `2`.
