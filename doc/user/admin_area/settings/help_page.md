---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Customize the Help and sign-in page messages

In large organizations, it is useful to have information about who to contact or where
to go for help. You can customize and display this information on the GitLab  `/help` page and on
the GitLab sign-in page.

## Add a help message to the Help page

You can add a help message, which is shown at the top of the GitLab `/help` page (for example,
<https://gitlab.com/help>):

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Preferences**, then expand **Help page**.
1. Under **Additional text to show on the Help page**, fill in the information you wish to display on `/help`.
1. Select **Save changes**. You can now see the message on `/help`.

NOTE:
By default, `/help` is visible to unauthenticated users. However, if the
[**Public** visibility level](visibility_and_access_controls.md#restricted-visibility-levels)
is restricted, `/help` is visible only to signed-in users.

## Add a help message to the sign-in page **(STARTER)**

You can add a help message, which is shown on the GitLab sign-in page. The message appears in a new
section titled **Need Help?**, located below the sign-in page message:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Preferences**, then expand **Help page**.
1. Under **Additional text to show on the sign-in page**, fill in the information you wish to
   display on the sign-in page.
1. Select **Save changes**. You can now see the message on the sign-in page.

## Hide marketing-related entries from the Help page

GitLab marketing-related entries are occasionally shown on the Help page. To hide these entries:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Preferences**, then expand **Help page**.
1. Select the **Hide marketing-related entries from the Help page** checkbox.
1. Select **Save changes**.

## Set a custom Support page URL

You can specify a custom URL to which users are directed when they:

- Select **Support** from the Help dropdown.
- Select **See our website for help** on the Help page.

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Preferences**, then expand **Help page**.
1. Enter the URL in the **Support page URL** field.
1. Select **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
