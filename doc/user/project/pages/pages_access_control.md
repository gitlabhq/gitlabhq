---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages access control
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can enable Pages access control on your project
if your administrator has [enabled the access control feature](../../../administration/pages/_index.md#access-control)
on your GitLab instance. When enabled, only authenticated
[members of your project](../../permissions.md#project-members-permissions)
(at least Guest) can access your website, by default:

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demonstration, see [Pages access controls](https://www.youtube.com/watch?v=tSPAr5mQYc8).

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Toggle the **Pages** button to enable the access control. If you don't see the toggle button,
   that means it isn't enabled. Ask your administrator to [enable it](../../../administration/pages/_index.md#access-control).

1. The Pages access control dropdown list allows you to set who can view pages hosted
   with GitLab Pages, depending on your project's visibility:

   - If your project is private:
     - **Only project members**: Only project members are able to browse the website.
     - **Everyone**: Everyone, both logged into and logged out of GitLab, is able to browse the website, no matter their project membership.
   - If your project is internal:
     - **Only project members**: Only project members are able to browse the website.
     - **Everyone with access**: Everyone logged into GitLab is able to browse the website, no matter their project membership.
     - **Everyone**: Everyone, both logged into and logged out of GitLab, is able to browse the website, no matter their project membership.
   - If your project is public:
     - **Only project members**: Only project members are able to browse the website.
     - **Everyone with access**: Everyone, both logged into and logged out of GitLab, is able to browse the website, no matter their project membership.

1. Select **Save changes**. Your changes may not take effect immediately. GitLab Pages uses
   a caching mechanism for efficiency. Your changes may not take effect until that cache is
   invalidated, which usually takes less than a minute.

The next time someone tries to access your website and the access control is
enabled, they're presented with a page to sign in to GitLab and verify they
can access the website.

## Restrict Pages access to project members

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/254962) in GitLab 17.9.

You can configure a setting for the group to restrict Pages access to only project members.
When enabled, all projects in the group and its subgroups become visible only to members.

Prerequisites

- Public access to Pages must not be [disabled at the instance level.](../../../administration/pages/_index.md#disable-public-access-to-all-pages-sites)
- You must have the Owner role for the group.

To do this:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Pages access control**, select
   **Restrict access to only project members on all group projects**.
1. Select **Save changes**.

GitLab Pages uses a cache for efficiency. Changes to access settings typically take effect within one minute when the cache updates.

## Terminating a Pages session

To sign out of your GitLab Pages website, revoke the application access token
for GitLab Pages:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. Select **Applications**.
1. In the **Authorized applications** section, find the **GitLab Pages**
   entry, and select **Revoke**.
