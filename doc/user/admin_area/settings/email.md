---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Email **(FREE SELF)**

You can customize some of the content in emails sent from your GitLab instance.

## Custom logo

The logo in the header of some emails can be customized, see the [logo customization section](../appearance.md#navigation-bar).

## Include author name in email notification email body **(PREMIUM SELF)**

By default, GitLab overrides the email address in notification emails with the email address
of the issue, merge request, or comment author. Enable this setting to include the author's email
address in the body of the email instead.

To include the author's email address in the email body:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences** (`/admin/application_settings/preferences`).
1. Expand **Email**.
1. Select the **Include author name in email notification email body** checkbox.
1. Select **Save changes**.

## Enable multipart email **(PREMIUM SELF)**

GitLab can send email in multipart format (HTML and plain text) or plain text only.

To enable multipart email:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences** (`/admin/application_settings/preferences`).
1. Expand **Email**.
1. Select **Enable multipart email**.
1. Select **Save changes**.

## Custom hostname for private commit emails **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22560) in GitLab 11.5.

This configuration option sets the email hostname for [private commit emails](../../profile/index.md#use-an-automatically-generated-private-commit-email).
 By default it is set to `users.noreply.YOUR_CONFIGURED_HOSTNAME`.

To change the hostname used in private commit emails:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences** (`/admin/application_settings/preferences`).
1. Expand **Email**.
1. Enter the desired hostname in the **Custom hostname (for private commit emails)** field.
1. Select **Save changes**.

NOTE:
After the hostname is configured, every private commit email using the previous hostname is not
recognized by GitLab. This can directly conflict with certain [Push rules](../../../push_rules/push_rules.md) such as
`Check whether author is a GitLab user` and `Check whether committer is the current authenticated user`.

## Custom additional text **(PREMIUM SELF)**

You can add additional text at the bottom of any email that GitLab sends. This additional text
can be used for legal, auditing, or compliance reasons, for example.

To add additional text to emails:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences** (`/admin/application_settings/preferences`).
1. Expand **Email**.
1. Enter your text in the **Additional text** field.
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
