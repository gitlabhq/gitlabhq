---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use OpenID Connect as an authentication provider
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can use GitLab as a client application with [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html)
as an OmniAuth provider.

To enable the OpenID Connect OmniAuth provider, you must register your application
with an OpenID Connect provider.
The OpenID Connect provider provides you with a client's details and secret for you to use.

1. On your GitLab server, open the configuration file.

   For Linux package installations:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For self-compiled installations:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configure the [common settings](../../integration/omniauth.md#configure-common-settings)
   to add `openid_connect` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration.

   For Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect", # do not change this parameter
       label: "Provider name", # optional label for login button, defaults to "Openid Connect"
       icon: "<custom_provider_icon>",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         send_scope_to_token_endpoint: "false",
         pkce: true,
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

   For Linux package installations with multiple identity providers:

   ```ruby
   { 'name' => 'openid_connect',
     'label' => '...',
     'icon' => '...',
     'args' => {
       'name' => 'openid_connect',
       'strategy_class': 'OmniAuth::Strategies::OpenIDConnect',
       'scope' => ['openid', 'profile', 'email'],
       'discovery' => true,
       'response_type' => 'code',
       'issuer' => 'https://...',
       'client_auth_method' => 'query',
       'uid_field' => '...',
       'client_options' => {
         `identifier`: "<your_oidc_client_id>",
         `secret`: "<your_oidc_client_secret>",
         'redirect_uri' => 'https://.../users/auth/openid_connect/callback'
      }
    }
   },
   { 'name' => 'openid_connect_2fa',
     'label' => '...',
     'icon' => '...',
     'args' => {
       'name' => 'openid_connect_2fa',
       'strategy_class': 'OmniAuth::Strategies::OpenIDConnect',
       'scope' => ['openid', 'profile', 'email'],
       'discovery' => true,
       'response_type' => 'code',
       'issuer' => 'https://...',
       'client_auth_method' => 'query',
       'uid_field' => '...',
       'client_options' => {
        ...
        'redirect_uri' => 'https://.../users/auth/openid_connect_2fa/callback'
      }
    }
   }
   ```

   For self-compiled installations:

   ```yaml
     - { name: 'openid_connect', # do not change this parameter
         label: 'Provider name', # optional label for login button, defaults to "Openid Connect"
         icon: '<custom_provider_icon>',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           send_scope_to_token_endpoint: false,
           pkce: true,
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
           }
         }
       }
   ```

   {{< alert type="note" >}}

   For more information on each configuration option, refer to the [OmniAuth OpenID Connect usage documentation](https://github.com/omniauth/omniauth_openid_connect#usage) and [OpenID Connect Core 1.0 specification](https://openid.net/specs/openid-connect-core-1_0.html).

   {{< /alert >}}

1. For the provider configuration, change the values for the provider to match your
   OpenID Connect client setup. Use the following as a guide:

   - `<your_oidc_label>` is the label that appears on the login page.
   - `<custom_provider_icon>` (optional) is the icon that appears on the login page.
     Icons for the major social login platforms are built into GitLab,
     but you can override these icons by specifying this parameter. GitLab accepts both
     local paths and absolute URLs.
     GitLab includes icons for most major social login platforms,
     but you can override these icons by specifying an external URL or
     an absolute or relative path to your own icon file.
     - For local absolute paths, configure the provider settings as `icon: <path>/<to>/<your-icon>`.
       - Store the icon file in `/opt/gitlab/embedded/service/gitlab-rails/public/<path>/<to>/<your-icon>`.
       - Access the icon file at `https://gitlab.example/<path>/<to>/<your-icon>`.
     - For local relative paths, configure the provider settings as `icon: <your-icon>`.
       - Store the icon file in `/opt/gitlab/embedded/service/gitlab-rails/public/images/<your-icon>`.
       - Access the icon file at `https://gitlab.example.com/images/<your-icon>`.
   - `<your_oidc_url>` (optional) is the URL that points to the OpenID Connect
     provider (for example, `https://example.com/auth/realms/your-realm`).
     If this value is not provided, the URL is constructed from `client_options`
     in the following format: `<client_options.scheme>://<client_options.host>:<client_options.port>`.
   - If `discovery` is set to `true`, the OpenID Connect provider attempts to automatically
     discover the client options using `<your_oidc_url>/.well-known/openid-configuration`.
     Defaults to `false`.
   - `client_auth_method` (optional) specifies the method used for authenticating
     the client with the OpenID Connect provider.
     - Supported values are:
       - `basic` - HTTP Basic Authentication.
       - `jwt_bearer` - JWT-based authentication (private key and client secret signing).
       - `mtls` - Mutual TLS or X.509 certificate validation.
       - Any other value posts the client ID and secret in the request body.
     - If not specified, this value defaults to `basic`.
   - `<uid_field>` (optional) is the field name from `user_info.raw_attributes`
     that defines the value for `uid` (for example, `preferred_username`).
     If you do not provide this value, or the field with the configured value is missing
     from the `user_info.raw_attributes` details, `uid` uses the `sub` field.
   - `send_scope_to_token_endpoint` is `true` by default, so the `scope` parameter
     is usually included in requests to the token endpoint.
     However, if your OpenID Connect provider does not accept the `scope` parameter
     in such requests, set this to `false`.
   - `pkce` (optional): Enable [Proof Key for Code Exchange](https://www.rfc-editor.org/rfc/rfc7636). Available in [GitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109557).
   - `client_options` are the OpenID Connect client-specific options. Specifically:
     - `identifier` is the client identifier as configured in the OpenID Connect service provider.
     - `secret` is the client secret as configured in the OpenID Connect service provider. For example,
       [OmniAuth OpenID Connect](https://github.com/omniauth/omniauth_openid_connect) requires this. If the service provider doesn't require a secret,
       provide any value and it is ignored.
     - `redirect_uri` is the GitLab URL to redirect the user to after successful login
       (for example, `http://example.com/users/auth/openid_connect/callback`).
     - `end_session_endpoint` (optional) is the URL to the endpoint that ends the
       session. You can provide this URL if auto-discovery is disabled or unsuccessful.
     - The following `client_options` are optional unless auto-discovery is disabled or unsuccessful:
       - `authorization_endpoint` is the URL to the endpoint that authorizes the end user.
       - `token_endpoint` is the URL to the endpoint that provides Access Token.
       - `userinfo_endpoint` is the URL to the endpoint that provides the user information.
       - `jwks_uri` is the URL to the endpoint where the Token signer publishes its keys.

1. Save the configuration file.
1. For changes to take effect, if you:

   - Used the Linux package to install GitLab, [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Self-compiled your GitLab installation, [restart GitLab](../restart_gitlab.md#self-compiled-installations).

On the sign in page, you have an OpenID Connect option below the regular sign in form.
Select this option to begin the authentication process. The OpenID Connect provider
asks you to sign in and authorize the GitLab application if confirmation is required
by the client. You are redirected to GitLab and signed in.

## Example configurations

The following configurations illustrate how to set up OpenID with
different providers when using the Linux package installation.

### Configure Google

See the [Google documentation](https://developers.google.com/identity/openid-connect/openid-connect)
for more details:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Google OpenID", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer: "https://accounts.google.com",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR PROJECT CLIENT ID>",
        secret: "<YOUR PROJECT CLIENT SECRET>",
        redirect_uri: "https://example.com/users/auth/openid_connect/callback",
       }
     }
  }
]
```

### Configure Microsoft Azure

The OpenID Connect (OIDC) protocol for Microsoft Azure uses the [Microsoft identity platform (v2) endpoints](https://learn.microsoft.com/en-us/previous-versions/azure/active-directory/azuread-dev/azure-ad-endpoint-comparison).
To get started, sign in to the [Azure Portal](https://portal.azure.com). For your app,
you need the following information:

- A tenant ID. You may already have one. For more information, see the
  [Microsoft Azure Tenant](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant) documentation.
- A client ID and a client secret. Follow the instructions in the
  [Microsoft Quickstart Register an Application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) documentation
  to obtain the tenant ID, client ID, and client secret for your app.

When you register a Microsoft Azure application, you must grant API permissions to allow GitLab to 
retrieve required details. You must provide at least the `openid`, `profile`, and `email` permissions.
For more information, see the [Microsoft documentation for configuring app permissions for a web API](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-access-web-apis#add-permissions-to-access-microsoft-graph).

{{< alert type="note" >}}

All accounts provisioned by Azure must have an email address defined. If an email address is not defined, Azure assigns a randomly generated address. If you've configured [domain sign-up restrictions](../settings/sign_up_restrictions.md#allow-or-deny-sign-ups-using-specific-email-domains), this random address might prevent the account from being created.

{{< /alert >}}

Example configuration block for Linux package installations:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

Microsoft has documented how its platform works with [the OIDC protocol](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc).

#### Microsoft Entra custom signing keys

If your application has custom signing keys because you use the
[SAML claims-mapping feature](https://learn.microsoft.com/en-us/entra/identity-platform/saml-claims-customization),
you must configure the OpenID provider in the following ways:

- Disable OpenID Connect Discovery by omitting `args.discovery`, or setting it to `false`.
- In `client_options`, specify the following:
  - A `jwks_uri` with the `appid` query parameter: `https://login.microsoftonline.com/<YOUR-TENANT-ID>/discovery/v2.0/keys?appid=<YOUR APP CLIENT ID>`.
  - `end_session_endpoint`.
  - `authorization_endpoint`.
  - `userinfo_endpoint`.

Example configuration for Linux package installations:

```ruby
gitlab_rails['omniauth_providers'] = [
 {
    name: "openid_connect", # do not change this parameter
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "basic",
      discovery: false,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback",
        end_session_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/logout",
        authorization_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/authorize",
        token_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/token",
        userinfo_endpoint: "https://graph.microsoft.com/oidc/userinfo",
        jwks_uri: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/discovery/v2.0/keys?appid=<YOUR APP CLIENT ID>"
      }
    }
  }
]
```

If you see authentication failures with a `KidNotFound` message, this
is probably because of a missing or incorrect `appid` query
parameter. GitLab raises that error if the ID token returned by
Microsoft cannot be validated with the keys provided by the `jwks_uri`
endpoint.

For more information, see the [Microsoft Entra documentation on validating tokens](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens#validate-tokens).

#### Migrate to Generic OpenID Connect configuration

You can migrate to the Generic OpenID Connect configuration from both `azure_activedirectory_v2` and `azure_oauth2`.

First, set the `uid_field`. Both the `uid_field` and the `sub` claim that you can select as a `uid_field` vary depending on the provider. Signing in without setting the `uid_field` results in additional identities being created within GitLab that have to be manually modified:

| Provider                                                                                                        | `uid_field` | Supporting information  |
|-----------------------------------------------------------------------------------------------------------------|-------|-----------------------------------------------------------------------|
| [`omniauth-azure-oauth2`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/omniauth-azure-oauth2) | `sub` | Additional attributes `oid` and `tid` are offered within the `info` object. |
| [`omniauth-azure-activedirectory-v2`](https://github.com/RIPAGlobal/omniauth-azure-activedirectory-v2/)         | `oid` | You must configure `oid` as `uid_field` when migrating. |
| [`omniauth_openid_connect`](https://github.com/omniauth/omniauth_openid_connect/)                               | `sub` | Specify `uid_field` to use another field. |

To migrate to the Generic OpenID Connect configuration, you must update the configuration.

For Linux package installations, update the configuration as follows:

{{< tabs >}}

{{< tab title="Azure OAuth 2.0" >}}

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "azure_oauth2",
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "azure_oauth2", # this matches the existing azure_oauth2 provider name, and only the strategy_class immediately below configures OpenID Connect
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "sub",
      send_scope_to_token_endpoint: "false",
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/azure_oauth2/callback"
      }
    }
  }
]
```

{{< /tab >}}

{{< tab title="Azure Active Directory v2" >}}

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "azure_activedirectory_v2",
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "azure_activedirectory_v2",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "oid",
      send_scope_to_token_endpoint: "false",
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback"
      }
    }
  }
]
```

{{< /tab >}}

{{< /tabs >}}

For Helm installations:

Add the [provider's configuration](https://docs.gitlab.com/charts/charts/globals.html#providers) in a YAML file (for example, `provider.yaml`):

{{< tabs >}}

{{< tab title="Azure OAuth 2.0" >}}

```ruby
{
  "name": "azure_oauth2",
  "args": {
    "name": "azure_oauth2",
    "strategy_class": "OmniAuth::Strategies::OpenIDConnect",
    "scope": [
      "openid",
      "profile",
      "email"
    ],
    "response_type": "code",
    "issuer": "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
    "client_auth_method": "query",
    "discovery": true,
    "uid_field": "sub",
    "send_scope_to_token_endpoint": false,
    "client_options": {
      "identifier": "<YOUR APP CLIENT ID>",
      "secret": "<YOUR APP CLIENT SECRET>",
      "redirect_uri": "https://gitlab.example.com/users/auth/azure_oauth2/callback"
    }
  }
}
```

{{< /tab >}}

{{< tab title="Azure Active Directory v2" >}}

```ruby
{
  "name": "azure_activedirectory_v2",
  "args": {
    "name": "azure_activedirectory_v2",
    "strategy_class": "OmniAuth::Strategies::OpenIDConnect",
    "scope": [
      "openid",
      "profile",
      "email"
    ],
    "response_type": "code",
    "issuer": "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
    "client_auth_method": "query",
    "discovery": true,
    "uid_field": "sub",
    "send_scope_to_token_endpoint": false,
    "client_options": {
      "identifier": "<YOUR APP CLIENT ID>",
      "secret": "<YOUR APP CLIENT SECRET>",
      "redirect_uri": "https://gitlab.example.com/users/auth/activedirectory_v2/callback"
    }
  }
}
```

{{< /tab >}}

{{< /tabs >}}

As you migrate from `azure_oauth2` to `omniauth_openid_connect` as part of upgrading to GitLab 17.0 or later, the `sub` claim value set for your organization can vary. `azure_oauth2` uses Microsoft V1 endpoint while `azure_activedirectory_v2` and `omniauth_openid_connect` both use Microsoft V2 endpoint with a common `sub` value.

- **For users with an email address in Entra ID**, to allow falling back to email address and updating the user's identity,
  configure the following:
  - In a Linux package installation, [`omniauth_auto_link_user`](../../integration/omniauth.md#link-existing-users-to-omniauth-users).
  - In a Helm installation, [`autoLinkUser`](https://docs.gitlab.com/charts/charts/globals.html#omniauth).

- **For users with no email address**, administrators must take one of the following actions:

  - Set up another authentication method or enable sign-in using GitLab username and password. The user can then sign in and link their Azure identity manually using their profile.
  - Implement OpenID Connect as a new provider alongside the existing `azure_oauth2` so the user can sign in through OAuth2, and link their OpenID Connect identity (similar to the previous method). This method would also work for users with email addresses, as long as `auto_link_user` is enabled.
  - Update `extern_uid` manually. To do this, use the [API or Rails console](../../integration/omniauth.md#change-apps-or-configuration) to update the `extern_uid` for each user.
    This method may be required if the instance has already been upgraded to 17.0 or later, and users have attempted to sign in.

{{< alert type="note" >}}

`azure_oauth2` might have used Entra ID's `upn` claim as the email address, if the `email` claim was missing or blank when provisioning GitLab accounts.

{{< /alert >}}

### Configure Microsoft Azure Active Directory B2C

GitLab requires special
configuration to work with [Azure Active Directory B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/overview). To get started, sign in to the [Azure Portal](https://portal.azure.com).
For your app, you need the following information from Azure:

- A tenant ID. You may already have one. For more information, review the
  [Microsoft Azure Tenant](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant) documentation.
- A client ID and a client secret. Follow the instructions in the
  [Microsoft tutorial](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga) documentation to obtain the
  client ID and client secret for your app.
- The user flow or policy name. Follow the instructions in the [Microsoft tutorial](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-user-flow).

Configure the app:

1. Set the app `Redirect URI`. For example, If your GitLab domain is `gitlab.example.com`,
   set the app `Redirect URI` to `https://gitlab.example.com/users/auth/openid_connect/callback`.

1. [Enable the ID tokens](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga#enable-id-token-implicit-grant).

1. Add the following API permissions to the app:

   - `openid`
   - `offline_access`

#### Configure custom policies

Azure B2C [offers two ways of defining the business logic for logging in a user](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview):

- [User flows](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#user-flows)
- [Custom policies](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#custom-policies)

Custom policies are required because standard Azure B2C user flows
[do not send the OpenID `email` claim](https://github.com/MicrosoftDocs/azure-docs/issues/16566).
Therefore, the standard user flows do not work with the
[`allow_single_sign_on` or `auto_link_user` parameters](../../integration/omniauth.md#configure-common-settings).
With a standard Azure B2C policy, GitLab cannot create a new account or
link to an existing account with an email address.

First, [create a custom policy](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy).

The Microsoft instructions use `SocialAndLocalAccounts` in the [custom policy starter pack](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#custom-policy-starter-pack),
but `LocalAccounts` authenticates against local Active Directory accounts. Before you [upload the polices](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies), do the following:

1. To export the `email` claim, modify the `SignUpOrSignin.xml`. Replace the following line:

   ```xml
   <OutputClaim ClaimTypeReferenceId="email" />
   ```

   with:

   ```xml
   <OutputClaim ClaimTypeReferenceId="signInNames.emailAddress" PartnerClaimType="email" />
   ```

1. For OIDC discovery to work with B2C, configure the policy with an issuer compatible with the
   [OIDC specification](https://openid.net/specs/openid-connect-discovery-1_0.html#rfc.section.4.3).
   See the [token compatibility settings](https://learn.microsoft.com/en-us/azure/active-directory-b2c/configure-tokens?pivots=b2c-custom-policy#token-compatibility-settings).
   In `TrustFrameworkBase.xml` under `JwtIssuer`, set `IssuanceClaimPattern` to `AuthorityWithTfp`:

   ```xml
   <ClaimsProvider>
     <DisplayName>Token Issuer</DisplayName>
     <TechnicalProfiles>
       <TechnicalProfile Id="JwtIssuer">
         <DisplayName>JWT Issuer</DisplayName>
         <Protocol Name="None" />
         <OutputTokenFormat>JWT</OutputTokenFormat>
         <Metadata>
           <Item Key="IssuanceClaimPattern">AuthorityWithTfp</Item>
           ...
   ```

1. [Upload the policy](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies). Overwrite
   the existing files if you are updating an existing policy.

1. To determine the issuer URL, use the sign-in policy. The issuer URL is in the form:

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/
   ```

   The policy name is lowercase in the URL. For example, `B2C_1A_signup_signin`
   policy appears as `b2c_1a_signup_sigin`.

   Ensure you include the trailing forward slash.

1. Verify the operation of the OIDC discovery URL and issuer URL and append
   `.well-known/openid-configuration` to the issuer URL:

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/.well-known/openid-configuration
   ```

   For example, if `domain` is `example.b2clogin.com` and tenant ID is
   `fc40c736-476c-4da1-b489-ee48cee84386`, you can use `curl` and `jq` to extract the issuer:

   ```shell
   $ curl --silent "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/.well-known/openid-configuration" | jq .issuer
   "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/"
   ```

1. Configure the issuer URL with the custom policy used for `signup_signin`. For example, this is
   the configuration with a custom policy for `b2c_1a_signup_signin` for Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
   {
     name: "openid_connect", # do not change this parameter
     label: "Azure B2C OIDC", # optional label for login button, defaults to "Openid Connect"
     args: {
       name: "openid_connect",
       scope: ["openid"],
       response_mode: "query",
       response_type: "id_token",
       issuer:  "https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/b2c_1a_signup_signin/v2.0/",
       client_auth_method: "query",
       discovery: true,
       send_scope_to_token_endpoint: true,
       pkce: true,
       client_options: {
         identifier: "<YOUR APP CLIENT ID>",
         secret: "<YOUR APP CLIENT SECRET>",
         redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
       }
     }
   }]
   ```

#### Troubleshooting Azure B2C

- Ensure all occurrences of `yourtenant.onmicrosoft.com`, `ProxyIdentityExperienceFrameworkAppId`, and `IdentityExperienceFrameworkAppId` match your B2C tenant hostname and
  the respective client IDs in the XML policy files.
- Add `https://jwt.ms` as a redirect URI to the app, and use the [custom policy tester](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#test-the-custom-policy).
  Ensure the payload includes `email` that matches the user's email access.
- After you enable the custom policy, users might see `Invalid username or password`
  after they try to sign in. This might be a configuration issue with the `IdentityExperienceFramework`
  app. See [this Microsoft comment](https://learn.microsoft.com/en-us/answers/questions/50355/unable-to-sign-on-using-custom-policy?childtoview=122370#comment-122370) that suggests you check that the app manifest
  contains these settings:

  - `"accessTokenAcceptedVersion": null`
  - `"signInAudience": "AzureADMyOrg"`

This configuration corresponds with the `Supported account types` setting used when
creating the `IdentityExperienceFramework` app.

### Configure Keycloak

GitLab works with OpenID providers that use HTTPS. Although you can set up a
Keycloak server that uses HTTP, GitLab can only communicate with a Keycloak server
that uses HTTPS.

Configure Keycloak to use public key encryption algorithms (for example,
RSA256 or RSA512) instead of symmetric key encryption algorithms (for example,
HS256 or HS358) to sign tokens. Public key encryption algorithms are:

- Easier to configure.
- More secure because leaking the private key has severe security consequences.

1. Open the Keycloak administration console.
1. Select **Realm Settings > Tokens > Default Signature Algorithm**.
1. Configure the signature algorithm.

Example configuration block for Linux package installations:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://keycloak.example.com/realms/myrealm",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR CLIENT ID>",
        secret: "<YOUR CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

#### Configure Keycloak with a symmetric key algorithm

{{< alert type="warning" >}}

The following instructions are included for completeness, but only use symmetric key
encryption if absolutely necessary.

{{< /alert >}}

To use symmetric key encryption:

1. Extract the secret key from the Keycloak database. Keycloak does not expose this
   value in the web interface. The client secret seen in the web interface is the
   OAuth 2.0 client secret, which is different from the secret used to sign JSON Web Tokens.

   For example, if you use PostgreSQL as the backend database for Keycloak:

   - Sign in to the database console.
   - Run the following SQL query to extract the key:

     ```sql
     $ psql -U keycloak
     psql (13.3 (Debian 13.3-1.pgdg100+1))
     Type "help" for help.

     keycloak=# SELECT c.name, value FROM component_config CC INNER JOIN component C ON(CC.component_id = C.id) WHERE C.realm_id = 'master' and provider_id = 'hmac-generated' AND CC.name = 'secret';
     -[ RECORD 1 ]---------------------------------------------------------------------------------
     name  | hmac-generated
     value | lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g
     -[ RECORD 2 ]---------------------------------------------------------------------------------
     name  | fallback-HS384
     value | UfVqmIs--U61UYsRH-NYBH3_mlluLONpg_zN7CXEwkJcO9xdRNlzZfmfDLPtf2xSTMvqu08R2VhLr-8G-oZ47A
     ```

     In this example, there are two private keys: one for HS256 (`hmac-generated`)
     and another for HS384 (`fallback-HS384`). We use the first `value` to configure GitLab.

1. Convert `value` to standard base64. As discussed in the [**Invalid signature with HS256 token** post](https://keycloak.discourse.group/t/invalid-signature-with-hs256-token/3228/9),
   `value` is encoded in the [**Base 64 Encoding with URL and Filename Safe Alphabet** section](https://datatracker.ietf.org/doc/html/rfc4648#section-5) of RFC 4648.
   This must be converted to [standard base64 as defined in RFC 2045](https://datatracker.ietf.org/doc/html/rfc2045).
   The following Ruby script does this:

   ```ruby
   require 'base64'

   value = "lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g"
   Base64.encode64(Base64.urlsafe_decode64(value))
   ```

   This results in the following value:

   ```markdown
   lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62+sqGc8drp3XW+wr93zru8PFsQokH\nZZuJJbaUXvmiOftCZM3C4KW3+g==\n
   ```

1. Specify this base64-encoded secret in `jwt_secret_base64`. For example:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect", # do not change this parameter
       label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
       args: {
         name: "openid_connect",
         scope: ["openid", "profile", "email"],
         response_type: "code",
         issuer:  "https://keycloak.example.com/auth/realms/myrealm",
         client_auth_method: "query",
         discovery: true,
         uid_field: "preferred_username",
         jwt_secret_base64: "<YOUR BASE64-ENCODED SECRET>",
         pkce: true,
         client_options: {
           identifier: "<YOUR CLIENT ID>",
           secret: "<YOUR CLIENT SECRET>",
           redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

If you see a `JSON::JWS::VerificationFailed` error,
you have specified the wrong secret.

### Casdoor

GitLab works with OpenID providers that use HTTPS. Use HTTPS to connect to GitLab
through OpenID with Casdoor.

For your app, complete the following steps on Casdoor:

1. Get a client ID and a client secret.
1. Add your GitLab redirect URL. For example, if your GitLab domain is `gitlab.example.com`,
   ensure the Casdoor app has the following
   `Redirect URI`: `https://gitlab.example.com/users/auth/openid_connect/callback`.

See the [Casdoor documentation](https://casdoor.org/docs/integration/ruby/gitlab/) for more details.

Example configuration for Linux package installations (file path: `/etc/gitlab/gitlab.rb`):

```ruby
gitlab_rails['omniauth_providers'] = [
    {
        name: "openid_connect", # do not change this parameter
        label: "Casdoor", # optional label for login button, defaults to "Openid Connect"
        args: {
            name: "openid_connect",
            scope: ["openid", "profile", "email"],
            response_type: "code",
            issuer:  "https://<CASDOOR_HOSTNAME>",
            client_auth_method: "query",
            discovery: true,
            uid_field: "sub",
            client_options: {
                identifier: "<YOUR CLIENT ID>",
                secret: "<YOUR CLIENT SECRET>",
                redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
            }
        }
    }
]
```

Example configuration for self-compiled installations (file path: `config/gitlab.yml`):

```yaml
  - { name: 'openid_connect', # do not change this parameter
      label: 'Casdoor', # optional label for login button, defaults to "Openid Connect"
      args: {
        name: 'openid_connect',
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: 'https://<CASDOOR_HOSTNAME>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: 'sub',
        client_options: {
          identifier: '<YOUR CLIENT ID>',
          secret: '<YOUR CLIENT SECRET>',
          redirect_uri: 'https://gitlab.example.com/users/auth/openid_connect/callback'
        }
      }
    }
```

## Configure multiple OpenID Connect providers

You can configure your application to use multiple OpenID Connect (OIDC) providers. You do this by explicitly setting the `strategy_class` in your configuration file.

You should do this in either of the following scenarios:

- [Migrating to the OpenID Connect protocol](#migrate-to-generic-openid-connect-configuration).
- Offering different levels of authentication.

The following example configurations show how to offer different levels of authentication, one option with 2FA and one without 2FA.

For Linux package installations:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Provider name", # optional label for login button, defaults to "Openid Connect"
    icon: "<custom_provider_icon>",
    args: {
      name: "openid_connect",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid","profile","email"],
      response_type: "code",
      issuer: "<your_oidc_url>",
      discovery: true,
      client_auth_method: "query",
      uid_field: "<uid_field>",
      send_scope_to_token_endpoint: "false",
      pkce: true,
      client_options: {
        identifier: "<your_oidc_client_id>",
        secret: "<your_oidc_client_secret>",
        redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback"
      }
    }
  },
  {
    name: "openid_connect_2fa",
    label: "Provider name 2FA", # optional label for login button, defaults to "Openid Connect"
    icon: "<custom_provider_icon>",
    args: {
      name: "openid_connect_2fa",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid","profile","email"],
      response_type: "code",
      issuer: "<your_oidc_url>",
      discovery: true,
      client_auth_method: "query",
      uid_field: "<uid_field>",
      send_scope_to_token_endpoint: "false",
      pkce: true,
      client_options: {
        identifier: "<your_oidc_client_id>",
        secret: "<your_oidc_client_secret>",
        redirect_uri: "<your_gitlab_url>/users/auth/openid_connect_2fa/callback"
      }
    }
  }
]
```

For self-compiled installations:

```yaml
  - { name: 'openid_connect',
      label: 'Provider name', # optional label for login button, defaults to "Openid Connect"
      icon: '<custom_provider_icon>',
      args: {
        name: 'openid_connect',
        strategy_class: "OmniAuth::Strategies::OpenIDConnect",
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: '<your_oidc_url>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: '<uid_field>',
        send_scope_to_token_endpoint: false,
        pkce: true,
        client_options: {
          identifier: '<your_oidc_client_id>',
          secret: '<your_oidc_client_secret>',
          redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
        }
      }
    }
  - { name: 'openid_connect_2fa',
      label: 'Provider name 2FA', # optional label for login button, defaults to "Openid Connect"
      icon: '<custom_provider_icon>',
      args: {
        name: 'openid_connect_2fa',
        strategy_class: "OmniAuth::Strategies::OpenIDConnect",
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: '<your_oidc_url>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: '<uid_field>',
        send_scope_to_token_endpoint: false,
        pkce: true,
        client_options: {
          identifier: '<your_oidc_client_id>',
          secret: '<your_oidc_client_secret>',
          redirect_uri: '<your_gitlab_url>/users/auth/openid_connect_2fa/callback'
        }
      }
    }
```

In this use case, you might want to synchronize the `extern_uid` across the
different providers based on an existing known identifier in your
corporate directory.

To do this, you set the `uid_field`. The following example code shows how to
do this:

```python
def sync_missing_provider(self, user: User, extern_uid: str)
  existing_identities = []
  for identity in user.identities:
      existing_identities.append(identity.get("provider"))

  local_extern_uid = extern_uid.lower()
  for provider in ("openid_connect_2fa", "openid_connect"):
      identity = [
          identity
          for identity in user.identities
          if identity.get("provider") == provider
          and identity.get("extern_uid").lower() != local_extern_uid
      ]
      if provider not in existing_identities or identity:
          if identity and identity[0].get("extern_uid") != "":
              logger.error(f"Found different identity for provider {provider} for user {user.id}")
              continue
          else:
              logger.info(f"Add identity 'provider': {provider}, 'extern_uid': {extern_uid} for user {user.id}")
              user.provider = provider
              user.extern_uid = extern_uid
              user = self.save_user(user)
  return user
```

For more information, see the [GitLab API user method documentation](https://python-gitlab.readthedocs.io/en/stable/gl_objects/users.html#examples).

## Configure users based on OIDC group membership

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/209898) in GitLab 15.10.

{{< /history >}}

You can configure OIDC group membership to:

- Require users to be members of a certain group.
- Assign users [external](../external_users.md), administrator or
  [auditor](../auditor_users.md) roles based on group membership.

GitLab checks these groups on each sign in and updates user attributes as necessary.
This feature **does not** allow you to automatically add users to GitLab
[groups](../../user/group/_index.md).

### Required groups

Your identity provider (IdP) must pass group information to GitLab in the OIDC response. To use this
response to require users to be members of a certain group, configure GitLab to identify:

- Where to look for the groups in the OIDC response, using the `groups_attribute` setting.
- Which group membership is required to sign in, using the `required_groups` setting.

If you do not set `required_groups` or leave the setting empty, any user authenticated by the IdP through OIDC can use GitLab.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             required_groups: ["Developer"]
           }
         }
       }
     }
   ]
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               required_groups: ["Developer"]
             }
           }
         }
       }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}

### External groups

Your IdP must pass group information to GitLab in the OIDC response. To use this
response to identify users as [external users](../external_users.md)
based on group membership, configure GitLab to identify:

- Where to look for the groups in the OIDC response, using the `groups_attribute` setting.
- Which group memberships should identify a user as an
  [external user](../external_users.md), using the
 `external_groups` setting.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             external_groups: ["Freelancer"]
           }
         }
       }
     }
   ]
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               external_groups: ["Freelancer"]
             }
           }
         }
       }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}

### Auditor groups

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Your IdP must pass group information to GitLab in the OIDC response. To use this
response to assign users as auditors based on group membership, configure GitLab to identify:

- Where to look for the groups in the OIDC response, using the `groups_attribute` setting.
- Which group memberships grant the user auditor access, using the `auditor_groups`
  setting.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email","groups"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             auditor_groups: ["Auditor"]
           }
         }
       }
     }
   ]
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email','groups'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               auditor_groups: ["Auditor"]
             }
           }
         }
       }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}

### Administrator groups

Your IdP must pass group information to GitLab in the OIDC response. To use this
response to assign users as administrator based on group membership, configure GitLab to identify:

- Where to look for the groups in the OIDC response, using the `groups_attribute` setting.
- Which group memberships grant the user administrator access, using the
  `admin_groups` setting.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             admin_groups: ["Admin"]
           }
         }
       }
     }
   ]
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               admin_groups: ["Admin"]
             }
           }
         }
       }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}

### Configure a custom duration for ID Tokens

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/377654) in GitLab 17.8.

{{< /history >}}

By default, GitLab ID tokens expire after 120 seconds.

To configure a custom duration for your ID tokens:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['oidc_provider_openid_id_token_expire_in_seconds'] = 3600
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     oidc_provider:
      openid_id_token_expire_in_seconds: 3600
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}

## Step-up authentication for Admin Mode

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/474650) in GitLab 17.11 [with a flag](../feature_flags/_index.md) named `omniauth_step_up_auth_for_admin_mode`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

In some cases, default authentication methods don't sufficiently protect critical resources or
high-risk actions. Step-up authentication adds an extra authentication layer for privileged actions
or sensitive operations, such as accessing the Admin area.

With step-up authentication, users must provide additional credentials before they can access
certain features or perform specific actions. These additional methods can include methods such
as two-factor authentication (2FA), biometric authentication, or one-time passwords (OTP).

The OIDC standard includes authentication context class references (`ACR`). The `ACR` concept
helps configure and implement step-up authentication for different scenarios, such as Admin Mode.

This feature is an [experiment](../../policy/development_stages_support.md) and subject to change without notice. This feature is not ready for production use. If you want to use this feature, you should test outside of production first.

### Enable step-up authentication for Admin Mode

To enable step-up authentication for Admin Mode:

1. Edit your GitLab configuration file (`gitlab.yml` or `/etc/gitlab/gitlab.rb`) to enable
   step-up authentication for an specific OmniAuth provider.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Provider name',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"], # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             admin_mode: {
               # The `id_token` field defines the claims that must be included with the token.
               # You can specify claims in one or both of the `required` or `included` fields.
               # The token must include matching values for every claim you define in these fields.
               id_token: {
                 # The `required` field defines key-value pairs that must be included with the ID token.
                 # The values must match exactly what is defined.
                 # In this example, the 'acr' (Authentication Context Class Reference) claim
                 # must have the value 'gold' to pass the step-up authentication challenge.
                 # This ensures a specific level of authentication assurance.
                 required: {
                   acr: 'gold'
                 },
                 # The `included` field also defines key-value pairs that must be included with the ID token.
                 # Multiple accepted values can be defined in an array. If an array is not used, the value must match exactly.
                 # In this example, the 'amr' (Authentication Method References) claim 
                 # must have a value of either 'mfa' or 'fpt' to pass the step-up authentication challenge.
                 # This is useful for scenarios where the user must provide additional authentication factors.
                 included: {
                   amr: ['mfa', 'fpt']
                 },
               },
               # The `params` field defines any additional parameters that are sent during the authentication process.
               # In this example, the `claims` parameter is added to the authorization request and instructs the
               # identity provider to include an 'acr' claim with the value 'gold' in the ID token.
               # The 'essential: true' indicates that this claim is required for successful authentication.
               params: {
                 claims: {
                   id_token: {
                     acr: {
                       essential: true,
                       values: ['gold']
                     }
                   }
                 }
               }
             },
           }
         }
   ```

1. Save the configuration file and restart GitLab for the changes to take effect.

{{< alert type="note" >}}

Although OIDC is standardized, different Identity Providers (IdPs) might have unique requirements.
The `params` setting allows a flexible hash to define necessary parameters for step-up authentication.
These values can vary based on the requirements for each IdP.

{{< /alert >}}

#### Enable step-up authentication for Admin Mode using Keycloak

Keycloak supports step-up authentication by defining levels of authentication and custom browser login flows.

To configure step-up authentication for Admin Mode in GitLab using Keycloak:

1. [Configure Keycloak](#configure-keycloak) in GitLab.

1. Follow the steps in the Keycloak documentation to [create a browser login flow with step-up authentication in Keycloak](https://www.keycloak.org/docs/latest/server_admin/#_step-up-flow).

1. Edit your GitLab configuration file (`gitlab.yml` or `/etc/gitlab/gitlab.rb`) to enable
   step-up authentication in the Keycloak OIDC provider configuration.

   Keycloak defines two different authentication levels: `silver` and `gold`. The following example
   uses `gold` to represent the increased security level.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Keycloak',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"] # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             admin_mode: {
               id_token: {
                 # In this example, the 'acr' claim must have the value 'gold' that is also defined in the Keycloak documentation.
                 required: {
                   acr: 'gold'
                 }
               },
               params: {
                 claims: { id_token: { acr: { essential: true, values: ['gold'] } } }
               }
             },
           }
         }
   ```

1. Save the configuration file and restart GitLab for the changes to take effect.

#### Enable step-up authentication for Admin Mode using Microsoft Entra ID

Microsoft Entra ID (formerly known as Azure Active Directory) supports step-up authentication
through [conditional access authentication context](https://learn.microsoft.com/en-us/entra/identity-platform/developer-guide-conditional-access-authentication-context).
You should work with your Microsoft Entra ID administrators to define the correct configuration.

Consider the following aspects:

- Authentication context IDs are requested through the `acrs` claim only, not through the ID token
  claim `acr` used for other identity providers.
- Authentication context IDs use fixed values from `c1` to `c99`, each representing a specific
  authentication context with conditional access policies.
- By default, Microsoft Entra ID does not include the `acrs` claim in the ID token. To enable this, you must
[configure optional claims](https://learn.microsoft.com/en-us/entra/identity-platform/optional-claims?tabs=appui#configure-optional-claims-in-your-application).
- When step-up authentication succeeds, the response returns the [`acrs` claim](https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference#payload-claims) as a JSON array
  of strings. For example: `acrs: ["c1", "c2", "c3"]`.

To configure step-up authentication for Admin Mode in GitLab using Microsoft Entra ID:

1. [Configure Microsoft Entra ID](#configure-microsoft-azure) in GitLab.

1. Follow the steps in the Microsoft Entra ID documentation to
[define conditional access authentication contexts in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity-platform/developer-guide-conditional-access-authentication-context).

1. In Microsoft Entra ID, define [the optional claim `acrs` to include in the ID token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

1. Edit your GitLab configuration file (`gitlab.yml` or `/etc/gitlab/gitlab.rb`) to enable
   step-up authentication in the Microsoft Entra ID provider configuration:

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
         label: 'Azure OIDC',
         args: {
           name: 'openid_connect',
           # ...
           allow_authorize_params: ["claims"] # Match this to the parameters defined in `step_up_auth => admin_mode => params`
         },
         step_up_auth: {
           admin_mode: {
             id_token: {
               # In this example, the Microsoft Entra ID administrators have definded `c20`
               # as the authentication context ID with the desired security level and
               # an optional claim `acrs` to be included in the ID token.
               # The `included` field declares that the id token claim `acrs` must include the value `c20`.
               included: {
                 acrs: ["c20"],
               },
             },
             params: {
               claims: {
                 id_token: {
                   acrs: { essential: true, value: 'c20' }
                 }
               },
             }
           },
         }
       }
   ```

1. Save the configuration file and restart GitLab for the changes to take effect.

## Troubleshooting

1. Ensure `discovery` is set to `true`. If you set it to `false`, you must
   specify all the URLs and keys required to make OpenID work.

1. Check your system clock to ensure the time is synchronized properly.

1. As mentioned in [the OmniAuth OpenID Connect documentation](https://github.com/omniauth/omniauth_openid_connect),
   make sure `issuer` corresponds to the base URL of the Discovery URL. For
   example, `https://accounts.google.com` is used for the URL
   `https://accounts.google.com/.well-known/openid-configuration`.

1. The OpenID Connect client uses HTTP Basic Authentication to send the
   OAuth 2.0 access token if `client_auth_method` is not defined or if set to `basic`.
   If you see 401 errors when retrieving the `userinfo` endpoint, check
   your OpenID web server configuration. For example, for
   [`oauth2-server-php`](https://github.com/bshaffer/oauth2-server-php), you may have to
   [add a configuration parameter to Apache](https://github.com/bshaffer/oauth2-server-php/issues/926#issuecomment-387502778).

1. **Step-up authentication only**: Ensure that any parameters defined in
   `step_up_auth => admin_mode => params` are also defined in `args => allow_authorize_params`.
   This includes the parameters in the request query parameters used to
   redirect to the IdP authorization endpoint.
