---
stage: Manage
group: Organization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Project and group visibility **(FREE)**

If you have the Owner role, you can set a project's or group's visibility as:

- **Public**
- **[Internal](#internal-projects-and-groups)**
- **Private**

These visibility levels affect who can see the project in the public access directory
(for example, <https://gitlab.com/public>).

For more granular control, you can determine
[which features in a project are visible](project/working_with_projects.md#change-the-visibility-of-individual-features-in-a-project).

The visibility setting of a project must be at least as restrictive
as the visibility of its parent group.
For example, a private group can include only private projects,
while a public group can include private, internal, and public projects.

## Public projects and groups

Public projects can be cloned **without any** authentication over HTTPS.

They are listed in the public access directory (`/public`) for all users.

Public groups can have public, internal, or private subgroups.

**Any signed-in user** has the Guest role on the repository.

NOTE:
By default, `/public` is visible to unauthenticated users. However, if the
[**Public** visibility level](admin_area/settings/visibility_and_access_controls.md#restrict-visibility-levels)
is restricted, `/public` is visible only to signed-in users.

## Internal projects and groups **(FREE SELF)**

Internal projects can be cloned by any signed-in user except
[external users](admin_area/external_users.md).

They are also listed in the public access directory (`/public`), but only for signed-in users.

Internal groups can have internal or private subgroups.

Any signed-in users except [external users](admin_area/external_users.md) have the
Guest role on the repository.

NOTE:
From July 2019, the `Internal` visibility setting is disabled for new projects, groups,
and snippets on GitLab.com. Existing projects, groups, and snippets using the `Internal`
visibility setting keep this setting. You can read more about the change in the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

## Private projects and groups

Private projects can only be cloned and viewed by project members (except for guests).

They appear in the public access directory (`/public`) for project members only.

Private groups can only have private subgroups.

## Change project visibility

You can change the visibility of a project.

Prerequisite:

- You must have the Owner role for a project.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Change **Project visibility** to either **Private**, **Internal**, or **Public**.
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
1. Select **Save changes**.

## Restrict use of public or internal projects **(FREE SELF)**

You can restrict the use of visibility levels for users when they create a project or a snippet.
This is useful to prevent users from publicly exposing their repositories by accident. The
restricted visibility settings do not apply to administrators.

For details, see [Restricted visibility levels](admin_area/settings/visibility_and_access_controls.md#restrict-visibility-levels).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
