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

## Custom additional text **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/5031) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.7.

The additional text appears at the bottom of any email and can be used for
legal/auditing/compliance reasons.

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences** (`/admin/application_settings/preferences`).
1. Expand **Email**.
1. Enter your text in the **Additional text** field.
1. Click **Save**.

## Custom hostname for private commit emails

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22560) in GitLab 11.5.

This configuration option sets the email hostname for [private commit emails](../../profile/index.md#use-an-automatically-generated-private-commit-email).
 By default it is set to `users.noreply.YOUR_CONFIGURED_HOSTNAME`.

In order to change this option:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences** (`/admin/application_settings/preferences`).
1. Expand **Email**.
1. Enter the desired hostname in the **Custom hostname (for private commit emails)** field.
1. Select **Save changes**.

NOTE:
After the hostname gets configured, every private commit email using the previous hostname is not
recognized by GitLab. This can directly conflict with certain [Push rules](../../../push_rules/push_rules.md) such as
`Check whether author is a GitLab user` and `Check whether committer is the current authenticated user`.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
