---
type: reference, howto
---

# GitLab Pages Access Control

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/33422) in GitLab 11.5.
> - Available on GitLab.com in GitLab 12.4.

You can enable Pages access control on your project, so that only
[members of your project](../../permissions.md#project-members-permissions)
(at least Guest) can access your website:

1. Navigate to your project's **Settings > General** and expand **Visibility, project features, permissions**.
1. Toggle the **Pages** button to enable the access control.

   NOTE: **Note:**
   If you don't see the toggle button, that means that it's not enabled.
   Ask your administrator to [enable it](../../../administration/pages/index.md#access-control).

1. The Pages access control dropdown allows you to set who can view pages hosted
   with GitLab Pages, depending on your project's visibility:

   - If your project is private:
     - **Only project members**: Only project members will be able to browse the website.
     - **Everyone**: Everyone, both logged into and logged out of GitLab, will be able to browse the website, no matter their project membership.
   - If your project is internal:
     - **Only project members**: Only project members will be able to browse the website.
     - **Everyone with access**: Everyone logged into GitLab will be able to browse the website, no matter their project membership.
     - **Everyone**: Everyone, both logged into and logged out of GitLab, will be able to browse the website, no matter their project membership.
   - If your project is public:
     - **Only project members**: Only project members will be able to browse the website.
     - **Everyone with access**: Everyone, both logged into and logged out of GitLab, will be able to browse the website, no matter their project membership.

1. Click **Save changes**.

The next time someone tries to access your website and the access control is
enabled, they will be presented with a page to sign into GitLab and verify they
can access the website.

## Terminating a Pages session

If you want to log out from your Pages website,
you can do so by revoking application access token for GitLab Pages:

1. Navigate to your profile's **Settings > Applications**.
1. Find **Authorized applications** at the bottom of the page.
1. Find **GitLab Pages** and press the **Revoke** button.
