---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Project and group visibility **(FREE)**

A project in GitLab can be private, internal, or public.

## Private projects and groups

For private projects, only project members can:

- Clone the project.
- View the public access directory (`/public`).

Users with the Guest role cannot clone the project.

Private groups can have private subgroups only.

## Internal projects and groups **(FREE SELF)**

For internal projects, **any authenticated user**, including users with the Guest role, can:

- Clone the project.
- View the public access directory (`/public`).

[External users](admin_area/external_users.md) cannot clone the project.

Internal groups can have internal or private subgroups.

NOTE:
From July 2019, the `Internal` visibility setting is disabled for new projects, groups,
and snippets on GitLab.com. Existing projects, groups, and snippets using the `Internal`
visibility setting keep this setting. For more information, see
[issue 12388](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

## Public projects and groups

For public projects, **users who are not authenticated**, including users with the Guest role, can:

- Clone the project.
- View the public access directory (`/public`).

Public groups can have public, internal, or private subgroups.

NOTE:
If an administrator restricts the
[**Public** visibility level](admin_area/settings/visibility_and_access_controls.md#restrict-visibility-levels),
then `/public` is visible only to authenticated users.

## Change project visibility

You can change the visibility of a project.

Prerequisite:

- You must have the Owner role for a project.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Change **Project visibility** to either **Private**, **Internal**, or **Public**.
   The visibility setting for a project must be at least as restrictive
   as the visibility of its parent group.
1. Select **Save changes**.

## Change group visibility

You can change the visibility of all projects in a group.

Prerequisites:

- You must have the Owner role for a group.
- Subgroups and projects must already have visibility settings that are at least as
  restrictive as the new setting of the parent group. For example, you cannot set a group
  to private if a subgroup or project in that group is public.

1. On the top bar, select **Main menu > Groups** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Naming, visibility**.
1. Under **Visibility level** select either **Private**, **Internal**, or **Public**.
   The visibility setting for a project must be at least as restrictive
   as the visibility of its parent group.
1. Select **Save changes**.

## Restrict use of public or internal projects **(FREE SELF)**

Administrators can restrict which visibility levels users can choose when they create a project or a snippet.
This setting can help prevent users from publicly exposing their repositories by accident.

For more information, see [Restrict visibility levels](admin_area/settings/visibility_and_access_controls.md#restrict-visibility-levels).

## Related topics

- [Change the visibility of features](project/working_with_projects.md#change-the-visibility-of-individual-features-in-a-project)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
