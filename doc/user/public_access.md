---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project and group visibility
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Projects and groups in GitLab can be private, internal, or public.

The visibility level of the project or group does not affect whether members of the project or group can see each other.
Projects and groups are intended for collaborative work. This work is only possible if all members know about each other.

Project or group members can see all members of the project or group they belong to.
Project or group members can see the origin of membership (the original project or group) of all members for the projects and groups they have access to.

## Private projects and groups

For private projects, only members of the private project or group can:

- Clone the project.
- View the public access directory (`/public`).

Users with the Guest role cannot clone the project.

Private groups can have only private subgroups and projects.

NOTE:
When you [share a private group with another group](project/members/sharing_projects_groups.md#invite-a-group-to-a-group),
users who don't have access to the private group can view a list of users who have access to the inviting group
through the endpoint `https://gitlab.com/groups/<inviting-group-name>/-/autocomplete_sources/members`.
However, the name and path of the private group are masked, and the users' membership source is not displayed.

## Internal projects and groups

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

For internal projects, any authenticated user, including users with the Guest role, can:

- Clone the project.
- View the public access directory (`/public`).

Only internal members can view internal content.

[External users](../administration/external_users.md) cannot clone the project.

Internal groups can have internal or private subgroups and projects.

## Public projects and groups

For public projects, any user, including unauthenticated users, can:

- Clone the project.
- View the public access directory (`/public`).

Public groups can have public, internal, or private subgroups and projects.

NOTE:
If an administrator restricts the
[**Public** visibility level](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels),
then the public access directory (`/public`) is visible only to authenticated users.

## Change project visibility

You can change the visibility of a project.

Prerequisites:

- You must have the Owner role for a project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. From the **Project visibility** dropdown list, select an option.
   The visibility setting for a project must be at least as restrictive
   as the visibility of its parent group.
1. Select **Save changes**.

## Change the visibility of individual features in a project

You can change the visibility of individual features in a project.

Prerequisites:

- You must have the Owner role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. To enable or disable a feature, turn on or turn off the feature toggle.
1. Select **Save changes**.

## Change group visibility

You can change the visibility of all projects in a group.

Prerequisites:

- You must have the Owner role for a group.
- Projects and subgroups must already have visibility settings that are at least as
  restrictive as the new setting of the parent group. For example, you cannot set a group
  to private if a project or subgroup in that group is public.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Naming, visibility**.
1. For **Visibility level**, select an option.
   The visibility setting for a project must be at least as restrictive
   as the visibility of its parent group.
1. Select **Save changes**.

## Restrict use of public or internal projects

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Administrators can restrict which visibility levels users can choose when they create a project or a snippet.
This setting can help prevent users from publicly exposing their repositories by accident.

For more information, see [Restrict visibility levels](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
