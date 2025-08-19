---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure OpenID Connect single sign-on (SSO) authentication for GitLab Dedicated.
title: OpenID Connect SSO for GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Configure OpenID Connect (OIDC) single sign-on (SSO) for your GitLab Dedicated instance
to authenticate users with your identity provider.

Use OIDC SSO when you want to:

- Centralize user authentication through your existing identity provider.
- Reduce password management overhead for users.
- Implement consistent access controls across your organization's applications.
- Use a modern authentication protocol with broad industry support.

{{< alert type="note" >}}

This configures OIDC for end users of your GitLab Dedicated instance.
To configure SSO for Switchboard administrators, see [configure Switchboard SSO](_index.md#configure-switchboard-sso).

{{< /alert >}}

## Configure OpenID Connect

Prerequisites:

- Set up your identity provider. You can use a temporary callback URL, as GitLab provides the callback URL after configuration.
- Make sure your identity provider supports the OpenID Connect specification.

To configure OIDC for your GitLab Dedicated instance:

1. [Create a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. In your support ticket, provide the following configuration:

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true
   }
   ```

1. Provide your Client ID and Client Secret securely using a temporary link to a secrets manager that the support team can access.
1. If your identity provider does not support auto discovery, include the client endpoint options. For example:

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://example.com/accounts",
     "discovery": false,
     "client_options": {
       "end_session_endpoint": "https://example.com/logout",
       "authorization_endpoint": "https://example.com/authorize",
       "token_endpoint": "https://example.com/token",
       "userinfo_endpoint": "https://example.com/userinfo",
       "jwks_uri": "https://example.com/jwks"
     }
   }
   ```

After GitLab configures OIDC for your instance:

1. You receive the callback URL in your support ticket.
1. Update your identity provider with this callback URL.
1. Verify the configuration by checking for the SSO login button on your instance's sign-in page.

## Configure users based on OIDC group membership

You can configure GitLab to assign user roles and access based on OIDC group membership.

Prerequisites:

- Your identity provider must include group information in the `ID token` or `userinfo` endpoint.
- You must have already configured basic OIDC authentication.

To configure users based on OIDC group membership:

1. Add the `groups_attribute` parameter to specify where GitLab should look for group information.
1. Configure the appropriate group arrays as needed.
1. In your support ticket, include the group configuration in your OIDC block. For example:

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true,
     "groups_attribute": "groups",
     "required_groups": [
       "gitlab-users"
     ],
     "external_groups": [
       "external-contractors"
     ],
     "auditor_groups": [
       "auditors"
     ],
     "admin_groups": [
       "gitlab-admins"
     ]
   }
   ```

## Configuration parameters

The following parameters are available to configure OIDC for GitLab Dedicated instances.
For more information, see [use OpenID Connect as an authentication provider](../../../../administration/auth/oidc.md).

### Required parameters

| Parameter | Description |
|-----------|-------------|
| `issuer` | The OpenID Connect issuer URL of your identity provider. |
| `label` | Display name for the login button. |
| `discovery` | Whether to use OpenID Connect discovery (recommended: `true`). |

### Optional parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `admin_groups` | Groups with administrator access. | `[]` |
| `auditor_groups` | Groups with auditor access. | `[]` |
| `client_auth_method` | Client authentication method. | `"basic"` |
| `external_groups` | Groups marked as external users. | `[]` |
| `groups_attribute` | Where to look for groups in the OIDC response. | None |
| `pkce` | Enable PKCE (Proof Key for Code Exchange). | `false` |
| `required_groups` | Groups required for access. | `[]` |
| `response_mode` | How the authorization response is delivered. | None |
| `response_type` | OAuth 2.0 response type. | `"code"` |
| `scope` | OpenID Connect scopes to request. | `["openid"]` |
| `send_scope_to_token_endpoint` | Include scope parameter in token endpoint requests. | `true` |
| `uid_field` | Field to use as the unique identifier. | `"sub"` |

### Provider-specific examples

#### Google

```json
{
  "label": "Google",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://accounts.google.com",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Microsoft Azure AD

```json
{
  "label": "Azure AD",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://login.microsoftonline.com/your-tenant-id/v2.0",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Okta

```json
{
  "label": "Okta",
  "scope": ["openid", "profile", "email", "groups"],
  "response_type": "code",
  "issuer": "https://your-domain.okta.com/oauth2/default",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

## Troubleshooting

If you encounter issues with your OpenID Connect configuration:

- Verify that your identity provider is correctly configured and accessible.
- Check that the client ID and secret provided to support are correct.
- Ensure the redirect URI in your identity provider matches the one provided in your support ticket.
- Verify that the issuer URL is correct and accessible.
