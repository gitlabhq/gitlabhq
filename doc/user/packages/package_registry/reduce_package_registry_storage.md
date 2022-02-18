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
1. Click **Delete**.

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
