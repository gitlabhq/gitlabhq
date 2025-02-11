---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Email
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can customize some of the content in emails sent from your GitLab instance.

## Custom logo

The logo in the header of some emails can be customized, see the [logo customization section](../appearance.md#customize-your-homepage-button).

## Include author name in email notification email body

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

By default, GitLab overrides the email address in notification emails with the email address
of the issue, merge request, or comment author. Enable this setting to include the author's email
address in the body of the email instead.

To include the author's email address in the email body:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Email**.
1. Select the **Include author name in email notification email body** checkbox.
1. Select **Save changes**.

## Enable multipart email

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab can send email in multipart format (HTML and plain text) or plain text only.

To enable multipart email:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Email**.
1. Select **Enable multipart email**.
1. Select **Save changes**.

## Custom hostname for private commit emails

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This configuration option sets the email hostname for [private commit emails](../../user/profile/_index.md#use-an-automatically-generated-private-commit-email).
 By default it is set to `users.noreply.YOUR_CONFIGURED_HOSTNAME`.

To change the hostname used in private commit emails:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Email**.
1. Enter the desired hostname in the **Custom hostname (for private commit emails)** field.
1. Select **Save changes**.

NOTE:
After the hostname is configured, every private commit email using the previous hostname is not
recognized by GitLab. This can directly conflict with certain [Push rules](../../user/project/repository/push_rules.md) such as
`Check whether author is a GitLab user` and `Check whether committer is the current authenticated user`.

## Custom additional text

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

You can add additional text at the bottom of any email that GitLab sends. This additional text
can be used for legal, auditing, or compliance reasons, for example.

To add additional text to emails:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Email**.
1. Enter your text in the **Additional text** field.
1. Select **Save changes**.

## User deactivation emails

GitLab sends email notifications to users when their account has been deactivated.

To disable these notifications:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Email**.
1. Clear the **Enable user deactivation emails** checkbox.
1. Select **Save changes**.

### Custom additional text in deactivation emails

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355964) in GitLab 15.9 [with a flag](../feature_flags.md) named `deactivation_email_additional_text`. Disabled by default.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111882) in GitLab 15.9.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/392761) in GitLab 16.5. Feature flag `deactivation_email_additional_text` removed.

You can add additional text at the bottom of the email that GitLab sends to users when their account
is deactivated. This email text is separate from the [custom additional text](#custom-additional-text)
setting.

To add additional text to deactivation emails:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Email**.
1. Enter your text in the **Additional text for deactivation email** field.
1. Select **Save changes**.

## Group and project access token expiry emails to inherited members

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - Notifications to inherited group members [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463016) in GitLab 17.7 [with a flag](../feature_flags.md) named `pat_expiry_inherited_members_notification`. Disabled by default.

FLAG:
The availability of emails to inherited project and group members is controlled by a feature flag. For more information, see the history.

In GitLab 17.7 and later, the following inherited group and project members can receive emails about group and project access tokens that are expiring soon, in addition to direct group and project members:

- For groups, members who inherit the Owner role for those groups.
- For projects, project members who inherit the Owner or Maintainer role for projects that belong to those groups.

To enable token expiration emails to inherited group and project members:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Email**.
1. Under **Expiry notification emails about group and project access tokens should be sent to:**, select **All direct and inherited members of the group or project**.
1. Select the **Enforce this setting for all groups on this instance** checkbox.
1. Select **Save changes**.

For more information on token expiration emails, see:

- For groups, the [group access token expiry emails documentation](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails).
- For projects, the [project access token expiry emails documentation](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
