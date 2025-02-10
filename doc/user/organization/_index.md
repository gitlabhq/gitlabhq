---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Organization
---

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409913) in GitLab 16.1 [with a flag](../../administration/feature_flags.md) named `ui_for_organizations`. Disabled by default.

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `ui_for_organizations`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject to change or delay and remain at the
sole discretion of GitLab Inc.

NOTE:
Organization is in development.

Organization will be above the [top-level namespaces](../namespace/_index.md) for you to manage
everything you do as a GitLab administrator, including:

- Defining and applying settings to all of your groups, subgroups, and projects.
- Aggregating data from all your groups, subgroups, and projects.

For more information about the state of organization development,
see [epic 9265](https://gitlab.com/groups/gitlab-org/-/epics/9265).

## View organizations

To view the organizations you have access to:

- On the left sidebar, select **Organizations**.

## Create an organization

NOTE:
In [Cells 1.0](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/iterations/cells-1.0/) organizations can be only private.

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New organization**.
1. In the **Organization name** text box, enter a name for the organization.
1. In the **Organization URL** text box, enter a path for the organization.
1. In the **Organization description** text box, enter a description for the organization. Supports a [limited subset of Markdown](#supported-markdown-for-organization-description).
1. In the **Organization avatar** field, select **Upload** or drag and drop an avatar.
1. Select **Create organization**.

## Edit an organization's name

1. On the left sidebar, select **Organizations** and find the organization you want to edit.
1. Select **Settings > General**.
1. In the **Organization name** text box, edit the name.
1. In the **Organization description** text box, edit the description. Supports a [limited subset of Markdown](#supported-markdown-for-organization-description).
1. In the **Organization avatar** field, if an avatar is:
   - Selected, select **Remove avatar** to remove.
   - Not selected, select **Upload** or drag and drop an avatar.
1. Select **Save changes**.

## Change an organization's URL

1. On the left sidebar, select **Organizations** and find the organization whose URL you want to change.
1. Select **Settings > General**.
1. Expand the **Advanced** section.
1. In the **Organization URL** text box, edit the URL.
1. Select **Change organization URL**.

## View an organization's visibility level

NOTE:
In [Cells 1.0](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/iterations/cells-1.0/) organizations can be only private.

1. On the left sidebar, select **Organizations** and find your organization.
1. Select **Settings > General**.
1. Expand the **Visibility** section.

## Switch organizations

NOTE:
Switching between organizations is not supported in [Cells 1.0](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/iterations/cells-1.0/),
but is supported in [Cells 1.5](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/iterations/cells-1.5/).

To switch organizations:

- On the left sidebar, in the upper corner, from the **Current organization** dropdown list select the organization you want to switch to.

## Manage groups and projects

1. On the left sidebar, select **Organizations** and find the organization you want to manage.
1. Select **Manage > Groups and projects**.
1. Optional. Filter the results:
   - To search for specific groups or projects, in the search box enter your search term (minimum three characters).
   - To view only groups or projects, from the **Display** dropdown list select an option.
1. Optional. To sort the results by name, date created, or date updated, from the dropdown list select an option. Then select ascending (**{sort-lowest}**) or descending (**{sort-highest}**) order.

## Create a group in an organization

1. On the left sidebar, select **Organizations** and find the organization you want to create a group in.
1. Select **Manage > Groups and projects**.
1. Select **New group**.
1. In the **Group name** text box, enter the name of the group. For a list of words that cannot be used as group names, see
   [reserved names](../reserved_names.md).
1. In the **Group URL** text box, enter the path for the group used for the [namespace](../namespace/_index.md).
1. Select the [**Visibility level**](../public_access.md) of the group.
1. Select **Create group**.

## View users

1. On the left sidebar, select **Organizations** and find the organization you want to view.
1. Select **Manage > Users**.

## Change a user's role

Prerequisites:

- You must have the Owner role for the organization.

To change a user's role:

1. On the left sidebar, select **Organizations** and find the organization you want to manage.
1. Select **Manage > Users**.
1. Find the user whose role you want to update.
1. From the **Organization role** dropdown list, select a role.

NOTE:
If you cannot select from the **Organization role** dropdown list, this user is the organization's only Owner. To change this user's role, first assign the Owner role to another user.

## Supported Markdown for Organization description

The Organization description field supports a limited subset of [GitLab Flavored Markdown](../markdown.md), including:

- [Emphasis](../markdown.md#emphasis)
- [Links](../markdown.md#links)
- [Superscripts / Subscripts](../markdown.md#superscripts-and-subscripts)

## Related topics

- [Organization developer documentation](../../development/organization/_index.md)
- [Organization design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/)
