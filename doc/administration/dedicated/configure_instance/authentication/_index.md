---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure authentication methods for GitLab Dedicated.
title: Authentication for GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated has two separate authentication contexts:

- Switchboard authentication: How administrators sign in to manage GitLab Dedicated instances.
- Instance authentication: How end users sign in to your GitLab Dedicated instance.

## Switchboard authentication

Administrators use GitLab Dedicated Switchboard to manage instances, users, and configuration.

Switchboard supports these authentication methods:

- Single sign-on (SSO) with SAML or OIDC
- Standard GitLab.com accounts

For information about Switchboard user management, see [manage users and notifications](../users_notifications.md).

### Configure Switchboard SSO

Enable single sign-on (SSO) for Switchboard to integrate with your organization's identity provider.
Switchboard supports both SAML and OIDC protocols.

{{< alert type="note" >}}

This configures SSO for Switchboard administrators who manage your GitLab Dedicated instance.

{{< /alert >}}

To configure SSO for Switchboard:

1. Gather the required information for your chosen protocol:
   - [SAML parameters](#saml-parameters-for-switchboard)
   - [OIDC parameters](#oidc-parameters-for-switchboard)
1. [Submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the information.
1. Configure your identity provider with the information GitLab provides.

#### SAML parameters for Switchboard

When requesting SAML configuration, you must provide:

| Parameter                 | Description |
| ------------------------- | ----------- |
| Metadata URL              | The URL that points to your identity provider's SAML metadata document. This typically ends with `/saml/metadata.xml` or is available in your identity provider's SSO configuration section. |
| Email attribute mapping   | The format your identity provider uses to represent email addresses. For example, in Auth0 this might be `http://schemas.auth0.com/email`. |
| Attributes request method | The HTTP method (GET or POST) that should be used when requesting attributes from your identity provider. Check your identity provider's documentation for the recommended method. |
| User email domain         | The domain portion of your users' email addresses (for example, `gitlab.com`). |

GitLab provides the following information for you to configure in your identity provider:

| Parameter           | Description |
| ------------------- | ----------- |
| Callback/ACS URL    | The URL where your identity provider should send SAML responses after authentication. |
| Required attributes | Attributes that must be included in the SAML response. At minimum, an attribute mapped to `email` is required. |

If you require encrypted responses, GitLab can provide the necessary certificates upon request.

{{< alert type="note" >}}

GitLab Dedicated does not support IdP-initiated SAML.

{{< /alert >}}

#### OIDC parameters for Switchboard

When requesting OIDC configuration, you must provide:

| Parameter       | Description |
| --------------- | ----------- |
| Issuer URL      | The base URL that uniquely identifies your OIDC provider. This URL typically points to your provider's discovery document located at `https://[your-idp-domain]/.well-known/openid-configuration`. |
| Token endpoints | The specific URLs from your identity provider used for obtaining and validating authentication tokens. These endpoints are usually listed in your provider's OpenID Connect configuration documentation. |
| Scopes          | The permission levels requested during authentication that determine what user information is shared. Standard scopes include `openid`, `email`, and `profile`. |
| Client ID       | The unique identifier assigned to Switchboard when you register it as an application in your identity provider. You must create this registration in your identity provider's dashboard first. |
| Client secret   | The confidential security key generated when you register Switchboard in your identity provider. This secret authenticates Switchboard to your IdP and should be kept secure. |

GitLab provides the following information for you to configure in your identity provider:

| Parameter              | Description |
| ---------------------- | ----------- |
| Redirect/callback URLs | The URLs where your identity provider should redirect users after successful authentication. These must be added to your identity provider's allowed redirect URLs list. |
| Required claims        | The specific user information that must be included in the authentication token payload. At minimum, a claim mapped to the user's email address is required. |

Additional configuration details might be required depending on your OIDC provider.

## Instance authentication

Configure how your organization's users authenticate to your GitLab Dedicated instance.

Your GitLab Dedicated instance supports these authentication methods:

- [Configure SAML SSO](saml.md)
- [Configure OIDC](openid_connect.md)
