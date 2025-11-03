---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize the Help page message
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

In large organizations, it is useful to have information about who to contact or where
to go for help. You can customize and display this information on the GitLab `/help` page.

## Add a help message to the Help page

You can add a help message, which is shown at the top of the GitLab `/help` page (for example,
<https://gitlab.com/help>):

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Help page**.
1. In **Additional text to show on the Help page**, enter the information you want to display on `/help`.
1. Select **Save changes**.

You can now see the message on `/help`.

{{< alert type="note" >}}

By default, `/help` is visible to unauthenticated users. However, if the
[**Public** visibility level](visibility_and_access_controls.md#restrict-visibility-levels)
is restricted, `/help` is visible only to authenticated users.

{{< /alert >}}

## Add a help message to the sign-in page

{{< history >}}

- Additional text to show on the sign-in page [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/410885) in GitLab 17.0.

{{< /history >}}

To add a help message to the sign-in page, [customize your sign-in and register pages](../appearance.md#customize-your-sign-in-and-register-pages).

## Hide marketing-related entries from the Help page

GitLab marketing-related entries are occasionally shown on the Help page. To hide these entries:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Help page**.
1. Select the **Hide marketing-related entries from the Help page** checkbox.
1. Select **Save changes**.

## Set a custom Support page URL

You can specify a custom URL to which users are directed when they:

- Select **Help** > **Support**.
- Select **See our website for help** on the Help page.

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Help page**.
1. In the **Support page URL** field, enter the URL.
1. Select **Save changes**.

## Redirect `/help` pages

You can redirect all `/help` links to a destination that meets the [necessary requirements](#destination-requirements).

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Help page**.
1. In the **Documentation pages URL** field, enter the URL.
1. Select **Save changes**.

If the **Documentation pages URL** field is empty, the GitLab instance displays a basic version of the documentation
sourced from the [`doc` directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc) of GitLab.

### Destination requirements

When redirecting `/help`, GitLab:

- Uses the specified URL as the base URL for the redirect.
- Constructs the full URL by:
  - Adding the version number (`${VERSION}`).
  - Adding the documentation path.
  - Removing any `.md` file extensions.

For example, if the URL is set to `https://docs.gitlab.com`, requests for
`/help/administration/settings/help_page.md` redirect to:
`https://docs.gitlab.com/${VERSION}/administration/settings/help_page`.
