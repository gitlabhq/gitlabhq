---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mailgun
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

When you use Mailgun to send emails for your GitLab instance and [Mailgun](https://www.mailgun.com/)
integration is enabled and configured in GitLab, you can receive their webhook for
tracking delivery failures. To set up the integration, you must:

1. [Configure your Mailgun domain](#configure-your-mailgun-domain).
1. [Enable Mailgun integration](#enable-mailgun-integration).

After completing the integration, Mailgun `temporary_failure` and `permanent_failure` webhooks are sent to your GitLab instance.

## Configure your Mailgun domain

> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/359113) the `/-/members/mailgun/permanent_failures` URL in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/359113) the URL to handle both temporary and permanent failures in GitLab 15.0.

Before you can enable Mailgun in GitLab, set up your own Mailgun endpoints to receive the webhooks.

Using the [Mailgun webhook guide](https://www.mailgun.com/blog/product/a-guide-to-using-mailguns-webhooks/):

1. Add a webhook with the **Event type** set to **Permanent Failure**.
1. Enter the URL of your instance and include the `/-/mailgun/webhooks` path.

   For example:

   ```plaintext
   https://myinstance.gitlab.com/-/mailgun/webhooks
   ```

1. Add another webhook with the **Event type** set to **Temporary Failure**.
1. Enter the URL of your instance and use the same `/-/mailgun/webhooks` path.

## Enable Mailgun integration

After configuring your Mailgun domain for the webhook endpoints,
you're ready to enable the Mailgun integration:

1. Sign in to GitLab as an [Administrator](../../user/permissions.md) user.
1. On the left sidebar, at the bottom, select **Admin**.
1. On the left sidebar, go to **Settings > General** and expand the **Mailgun** section.
1. Select the **Enable Mailgun** checkbox.
1. Enter the Mailgun HTTP webhook signing key as described in
   [the Mailgun documentation](https://documentation.mailgun.com/docs/mailgun/user-manual/get-started/) and
   shown in the API security (`https://app.mailgun.com/app/account/security/api_keys`) section for your Mailgun account.
1. Select **Save changes**.
