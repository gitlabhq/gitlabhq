---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages access control
description: Restrict access to a GitLab Pages site to authenticated project members.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Group SAML SSO support for Pages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326288) in GitLab 18.2 [with a feature flag](../../../administration/feature_flags/_index.md) named `ff_oauth_redirect_to_sso_login`. Disabled by default.
- Group SAML SSO support for OAuth applications [enabled on GitLab.com, GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682) in GitLab 18.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/561778) in GitLab 18.5. Feature flag `ff_oauth_redirect_to_sso_login` removed.

{{< /history >}}

You can turn on Pages access control for your project
if your administrator has [turned on the access control feature](../../../administration/pages/_index.md#access-control)
on your GitLab instance. When turned on, only authenticated
[members of your project](../../permissions.md#project-permissions)
(at least Guest) can access your website, by default:

<i class="fa-youtube-play" aria-hidden="true"></i>
For a demonstration, see [Pages access controls](https://www.youtube.com/watch?v=tSPAr5mQYc8).

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. To turn on access control, turn on the **Pages** toggle. If you don't see the toggle,
   that means it isn't turned on. Ask your administrator to [turn it on](../../../administration/pages/_index.md#access-control).

1. Use the Pages access control dropdown list to set who can view pages hosted
   with GitLab Pages, depending on your project's visibility:

   - If your project is private:
     - **Only project members**: Only [project members](../members/_index.md) can browse the website.
     - **Everyone**: Everyone, both logged into and logged out of GitLab, can browse the website, no matter their project membership.
   - If your project is internal:
     - **Only project members**: Only project members can browse the website.
     - **Everyone with access**: Everyone logged into GitLab can browse the website, no matter their project membership. [External users](../../../administration/external_users.md) can access the website only if they have a membership in the project.
     - **Everyone**: Everyone, both logged into and logged out of GitLab, can browse the website, no matter their project membership.
   - If your project is public:
     - **Only project members**: Only project members can browse the website.
     - **Everyone with access**: Everyone, both logged into and logged out of GitLab, can browse the website, no matter their project membership.

1. Select **Save changes**. Your changes might not take effect immediately. GitLab Pages uses
   a caching mechanism for efficiency. Your changes may not take effect until that cache is
   invalidated, which usually takes less than a minute.

The next time someone tries to access your website and the access control is
turned on, they're presented with a page to sign in to GitLab and verify they
can access the website.

When [SAML SSO](../../group/saml_sso/_index.md) is configured for the associated group
and access control is turned on, users must authenticate using SSO before accessing the website.

When public access is turned off at the [instance](../../../administration/pages/_index.md#disable-public-access-to-all-pages-sites)
or [group](#remove-public-access-for-group-pages) level, projects lose the **Everyone**
visibility level option and are restricted to project members or everyone with access,
depending on the project's visibility setting.

## Remove public access for group Pages

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/254962) in GitLab 17.9.

{{< /history >}}

Configure a setting for the group to remove the public visibility option for Pages.
When turned on, all projects in the group and its subgroups lose the option to use the "Everyone" visibility
level and are restricted to project members or everyone with access, depending on the project's visibility setting.

Prerequisites

- Public access to Pages must not be [turned off for the instance](../../../administration/pages/_index.md#disable-public-access-to-all-pages-sites).
- You must have the Owner role for the group.

To do this:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Under **Pages public access**, select the **Remove public access** checkbox.
1. Select **Save changes**.

GitLab Pages uses a cache for efficiency. Changes to access settings typically take effect in one minute when the cache updates.

## Authenticate with an access token

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/388) in GitLab 17.10.

{{< /history >}}

To authenticate against a restricted GitLab Pages site, you can provide the `Authorization` header with an access token.

Prerequisites:

- You must have one of the following access tokens with the `read_api` scope:
  - [Personal access token](../../profile/personal_access_tokens.md#create-a-personal-access-token)
  - [Project access token](../settings/project_access_tokens.md#create-a-project-access-token)
  - [Group access token](../../group/settings/group_access_tokens.md#create-a-group-access-token)
  - [OAuth 2.0 token](../../../api/oauth2.md)

For example, to use an access token with OAuth-compliant headers:

```shell
curl --header "Authorization: Bearer <your_access_token>" <published_pages_url>
```

For invalid or unauthorized access tokens, returns [`404`](../../../api/rest/troubleshooting.md#status-codes).

## Terminating a Pages session

To sign out of your GitLab Pages website, revoke the application access token
for GitLab Pages:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access** > **Applications**.
1. In the **Authorized applications** section, find the **GitLab Pages**
   entry, and select **Revoke**.
