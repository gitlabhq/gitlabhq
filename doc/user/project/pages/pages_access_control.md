---
type: reference, howto
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Pages access control **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/33422) in GitLab 11.5.
> - Available on GitLab.com in GitLab 12.4.

You can enable Pages access control on your project
if your administrator has [enabled the access control feature](../../../administration/pages/index.md#access-control)
on your GitLab instance. When enabled, only
[members of your project](../../permissions.md#project-members-permissions)
(at least Guest) can access your website:

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demonstration, see [Pages access controls](https://www.youtube.com/watch?v=tSPAr5mQYc8).

1. Navigate to your project's **Settings > General** and expand **Visibility, project features, permissions**.

1. Toggle the **Pages** button to enable the access control. If you don't see the toggle button,
   that means it isn't enabled. Ask your administrator to [enable it](../../../administration/pages/index.md#access-control).

1. The Pages access control dropdown allows you to set who can view pages hosted
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

1. Click **Save changes**. Note that your changes may not take effect immediately. GitLab Pages uses
   a caching mechanism for efficiency. Your changes may not take effect until that cache is
   invalidated, which usually takes less than a minute.

The next time someone tries to access your website and the access control is
enabled, they're presented with a page to sign into GitLab and verify they
can access the website.

## Terminating a Pages session

To sign out of your GitLab Pages website, revoke the application access token
for GitLab Pages:

1. In the top menu, select your profile, and then select **Settings**.
1. In the left sidebar, select **Applications**.
1. Scroll to the **Authorized applications** section, find the **GitLab Pages**
   entry, and select its **Revoke** button.
