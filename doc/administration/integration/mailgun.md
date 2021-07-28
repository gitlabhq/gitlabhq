---
stage: Growth
group: Expansion
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Mailgun and GitLab **(FREE SELF)**

When you use Mailgun to send emails for your GitLab instance and [Mailgun](https://www.mailgun.com/)
integration is enabled and configured in GitLab, you can receive their webhook for
permanent invite email failures. To set up the integration, you must:

1. [Configure your Mailgun domain](#configure-your-mailgun-domain).
1. [Enable Mailgun integration](#enable-mailgun-integration).

After completing the integration, Mailgun `permanent_failure` webhooks are sent to your GitLab instance.

## Configure your Mailgun domain

Before you can enable Mailgun in GitLab, set up your own Mailgun permanent failure endpoint to receive the webhooks.

Using the [Mailgun webhook guide](https://www.mailgun.com/blog/a-guide-to-using-mailguns-webhooks/):

1. Add a webhook with the **Event type** set to **Permanent Failure**.
1. Fill in the URL of your instance and include the `/-/members/mailgun/permanent_failures` path.
   - Example: `https://myinstance.gitlab.com/-/members/mailgun/permanent_failures`

## Enable Mailgun integration

After configuring your Mailgun domain for the permanent failures endpoint,
you're ready to enable the Mailgun integration:

1. Sign in to GitLab as an [Administrator](../../user/permissions.md) user.
1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, go to **Settings > General** and expand the **Mailgun** section.
1. Select the **Enable Mailgun** check box.
1. Enter the Mailgun HTTP webhook signing key as described in
   [the Mailgun documentation](https://documentation.mailgun.com/en/latest/user_manual.html#webhooks) and
   shown in the [API security](https://app.mailgun.com/app/account/security/api_keys) section for your Mailgun account.
1. Select **Save changes**.
