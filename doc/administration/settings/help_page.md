---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Customize the Help and sign-in page messages

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

In large organizations, it is useful to have information about who to contact or where
to go for help. You can customize and display this information on the GitLab `/help` page and on
the GitLab sign-in page.

## Add a help message to the Help page

You can add a help message, which is shown at the top of the GitLab `/help` page (for example,
<https://gitlab.com/help>):

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Preferences**.
1. Expand **Sign-in and Help page**.
1. In **Additional text to show on the Help page**, enter the information you want to display on `/help`.
1. Select **Save changes**.

You can now see the message on `/help`.

NOTE:
By default, `/help` is visible to unauthenticated users. However, if the
[**Public** visibility level](visibility_and_access_controls.md#restrict-visibility-levels)
is restricted, `/help` is visible only to authenticated users.

## Add a help message to the sign-in page

You can add a help message, which is shown on the GitLab sign-in page. The message appears on the sign-in page:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Preferences**.
1. Expand **Sign-in and Help page**.
1. In **Additional text to show on the sign-in page**, enter the information you want to
   display on the sign-in page.
1. Select **Save changes**.

You can now see the message on the sign-in page.

## Hide marketing-related entries from the Help page

GitLab marketing-related entries are occasionally shown on the Help page. To hide these entries:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Preferences**.
1. Expand **Sign-in and Help page**.
1. Select the **Hide marketing-related entries from the Help page** checkbox.
1. Select **Save changes**.

## Set a custom Support page URL

You can specify a custom URL to which users are directed when they:

- Select **Help > Support**.
- Select **See our website for help** on the Help page.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Preferences**.
1. Expand **Sign-in and Help page**.
1. In the **Support page URL** field, enter the URL.
1. Select **Save changes**.

## Redirect `/help` pages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43157) in GitLab 13.5.
> - [Feature flag `help_page_documentation_redirect`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71737) removed in GitLab 14.4.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71737) in GitLab 14.4.

You can redirect all `/help` links to a destination that meets the [necessary requirements](#destination-requirements).

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Preferences**.
1. Expand **Sign-in and Help page**.
1. In the **Documentation pages URL** field, enter the URL.
1. Select **Save changes**.

If the **Documentation pages URL** field is empty, the GitLab instance displays a basic version of the documentation
sourced from the [`doc` directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc) of GitLab.

### Destination requirements

When redirecting `/help`, GitLab:

- Redirects requests to the specified URL.
- Appends `ee` and the documentation path, which includes the version number, to the URL.
- Appends `.html` to the URL, and removes `.md` if necessary.

For example, if the URL is set to `https://docs.gitlab.com`, requests for
`/help/administration/settings/help_page.md` redirect to:
`https://docs.gitlab.com/${VERSION}/ee/administration/settings/help_page.html`.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
