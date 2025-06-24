---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Manage Switchboard users and configure notification preferences, including SMTP email service settings.
title: GitLab Dedicated users and notifications
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

## Add Switchboard users

Administrators can add two types of Switchboard users to manage and view their GitLab Dedicated instance:

- **Read only**: Users can only view instance data.
- **Admin**: Users can edit the instance configuration and manage users.

To add a new user to Switchboard for your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. From the top of the page, select **Users**.
1. Select **New user**.
1. Enter the **Email** and select a **Role** for the user.
1. Select **Create**.

An invitation to use Switchboard is sent to the user.

There is no direct link between the users in Switchboard and the users in the GitLab Dedicated instance.

## Email notifications

Switchboard sends email notifications about instance incidents, maintenance, performance issues, and security updates.

Notifications are sent to:

- Switchboard users: Receive notifications based on their notification settings.
- Operational email addresses: Receive notifications for important instance events and service updates,
  regardless of their notification settings.

Operational email addresses receive customer notifications, even if recipients:

- Are not Switchboard users.
- Have not signed in to Switchboard.
- Turn off email notifications.

To stop receiving operational email notifications, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

### Manage notification preferences

To receive email notifications, you must first:

- Receive an email invitation and sign in to Switchboard.
- Set up a password and two-factor authentication (2FA).

To turn your personal notifications on or off:

1. Select the dropdown list next to your user name.
1. Select **Toggle email notifications off** or **Toggle email notifications on**.

An alert confirms that your notification preferences have been updated.

## Reset a Switchboard user password

To reset your Switchboard password, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). The support team will help you regain access to your account.

## SMTP email service

You can configure an [SMTP](../../../subscriptions/gitlab_dedicated/_index.md#email-service) email service for your GitLab Dedicated instance.

To configure an SMTP email service, submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the credentials and settings for your SMTP server.

## Configure single sign-on for Switchboard

Enable single sign-on (SSO) for Switchboard to integrate with your organization's identity provider. Switchboard
supports both SAML and OIDC protocols.

To configure SSO for Switchboard:

1. Gather the required information for your chosen protocol (see the information required for [SAML](#saml-configuration) and [OIDC](#oidc-configuration)).
1. [Submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the information.
1. Configure your identity provider with the information GitLab provides.

{{< alert type="note" >}}

These instructions apply only to SSO for Switchboard. For GitLab Dedicated instances, see [SAML single sign-on for GitLab Dedicated](saml.md).

{{< /alert >}}

### SAML configuration

When requesting SAML configuration, you must provide:

| Information | Description |
|------------------------|-------------|
| Metadata URL | The URL that points to your identity provider's SAML metadata document. This typically ends with `/saml/metadata.xml` or is available in your identity provider's SSO configuration section. |
| Email attribute mapping | The format your identity provider uses to represent email addresses. For example, in Auth0 this might be `http://schemas.auth0.com/email`. |
| Attributes request method | The HTTP method (GET or POST) that should be used when requesting attributes from your identity provider. Check your identity provider's documentation for the recommended method. |
| User email domain | The domain portion of your users' email addresses (for example, `gitlab.com`). |

GitLab provides you with the following information to configure in your identity provider:

| Information | Description |
|-------------|-------------|
| Callback/ACS URL | The URL where your identity provider should send SAML responses after authentication. |
| Required attributes | Attributes that must be included in the SAML response. At minimum, an attribute mapped to `email` is required. |

If you require encrypted responses, GitLab can provide the necessary certificates upon request.

{{< alert type="note" >}}

GitLab Dedicated does not support IdP-initiated SAML.

{{< /alert >}}

### OIDC configuration

When requesting OIDC configuration, you must provide:

| Information | Description |
|------------------------|-------------|
| Issuer URL | The base URL that uniquely identifies your OIDC provider. This URL typically points to your provider's discovery document located at `https://[your-idp-domain]/.well-known/openid-configuration`. |
| Token endpoints | The specific URLs from your identity provider used for obtaining and validating authentication tokens. These endpoints are usually listed in your provider's OpenID Connect configuration documentation. |
| Scopes | The permission levels requested during authentication that determine what user information is shared. Standard scopes include `openid`, `email`, and `profile`. |
| Client ID | The unique identifier assigned to Switchboard when you register it as an application in your identity provider. You must create this registration in your identity provider's dashboard first. |
| Client secret | The confidential security key generated when you register Switchboard in your identity provider. This secret authenticates Switchboard to your IdP and should be kept secure. |

GitLab provides you with the following information to configure in your identity provider:

| Information | Description |
|-------------|-------------|
| Redirect/callback URLs | The URLs where your identity provider should redirect users after successful authentication. These must be added to your identity provider's allowed redirect URLs list. |
| Required claims | The specific user information that must be included in the authentication token payload. At minimum, a claim mapped to the user's email address is required. |

Additional configuration details might be required depending on your specific OIDC provider.
