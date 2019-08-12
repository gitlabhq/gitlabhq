---
type: reference
---

# OpenID Connect OmniAuth provider

GitLab can use [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html) as an OmniAuth provider.

To enable the OpenID Connect OmniAuth provider, you must register your application with an OpenID Connect provider.
The OpenID Connect will provide you with a client details and secret for you to use.

1. On your GitLab server, open the configuration file.

   For Omnibus GitLab:

   ```sh
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```sh
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

   See [Initial OmniAuth Configuration](../../integration/omniauth.md#initial-omniauth-configuration) for initial settings.

1. Add the provider configuration.

   For Omnibus GitLab:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { 'name' => 'openid_connect',
       'label' => '<your_oidc_label>',
       'args' => {
         "name' => 'openid_connect',
         'scope' => ['openid','profile'],
         'response_type' => 'code',
         'issuer' => '<your_oidc_url>',
         'discovery' => true,
         'client_auth_method' => 'query',
         'uid_field' => '<uid_field>',
         'client_options' => {
           'identifier' => '<your_oidc_client_id>',
           'secret' => '<your_oidc_client_secret>',
           'redirect_uri' => '<your_gitlab_url>/users/auth/openid_connect/callback'
         }
       }
     }
   ]
   ```

   For installation from source:

   ```yaml
     - { name: 'openid_connect',
         label: '<your_oidc_label>',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
           }
         }
       }
   ```

   NOTE: **Note:**
   For more information on each configuration option refer to the [OmniAuth OpenID Connect usage documentation](https://github.com/m0n9oose/omniauth_openid_connect#usage)
   and the [OpenID Connect Core 1.0 specification](https://openid.net/specs/openid-connect-core-1_0.html).

1. For the configuration above, change the values for the provider to match your OpenID Connect client setup. Use the following as a guide:
   - `<your_oidc_label>` is the label that will be displayed on the login page.
   - `<your_oidc_url>` (optional) is the URL that points to the OpenID Connect provider. For example, `https://example.com/auth/realms/your-realm`.
     If this value is not provided, the URL is constructed from the `client_options` in the following format: `<client_options.scheme>://<client_options.host>:<client_options.port>`.
   - If `discovery` is set to `true`, the OpenID Connect provider will try to auto discover the client options using `<your_oidc_url>/.well-known/openid-configuration`. Defaults to `false`.
   - `client_auth_method` (optional) specifies the method used for authenticating the client with the OpenID Connect provider.
     - Supported values are:
       - `basic` - HTTP Basic Authentication
       - `jwt_bearer` - JWT based authentication (private key and client secret signing)
       - `mtls` - Mutual TLS or X.509 certificate validation
       - Any other value will POST the client id and secret in the request body
     - If not specified, defaults to `basic`.
   - `<uid_field>` (optional) is the field name from the `user_info` details that will be used as `uid` value. For example, `preferred_username`.
     If this value is not provided or the field with the configured value is missing from the `user_info` details, the `uid` will use the `sub` field.
   - `client_options` are the OpenID Connect client-specific options. Specifically:
     - `identifier` is the client identifier as configured in the OpenID Connect service provider.
     - `secret` is the client secret as configured in the OpenID Connect service provider.
     - `redirect_uri` is the GitLab URL to redirect the user to after successful login. For example, `http://example.com/users/auth/openid_connect/callback`.
     - `end_session_endpoint` (optional) is the URL to the endpoint that end the session (logout). Can be provided if auto-discovery disabled or unsuccessful.
     - The following `client_options` are optional unless auto-discovery is disabled or unsuccessful:
       - `authorization_endpoint` is the URL to the endpoint that authorizes the end user.
       - `token_endpoint` is the URL to the endpoint that provides Access Token.
       - `userinfo_endpoint` is the URL to the endpoint that provides the user information.
       - `jwks_uri` is the URL to the endpoint where the Token signer publishes its keys.

1. Save the configuration file.
1. [Reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart GitLab](../restart_gitlab.md#installations-from-source)
   for the changes to take effect if you installed GitLab via Omnibus or from source respectively.

On the sign in page, there should now be an OpenID Connect icon below the regular sign in form.
Click the icon to begin the authentication process. The OpenID Connect provider will ask the user to
sign in and authorize the GitLab application (if confirmation required by the client). If everything goes well, the user
will be redirected to GitLab and will be signed in.

## Example configurations

The following configurations illustrate how to set up OpenID with
different providers with Omnibus GitLab.

### Google

See the [Google
documentation](https://developers.google.com/identity/protocols/OpenIDConnect)
for more details:

```ruby
 gitlab_rails['omniauth_providers'] = [
 {
   'name' => 'openid_connect',
   'label' => 'Google OpenID',
   'args' => {
     'name' => 'openid_connect',
     'scope' => ['openid', 'profile', 'email'],
     'response_type' => 'code',
     'issuer' => 'https://accounts.google.com',
     'client_auth_method' => 'query',
     'discovery' => true,
     'uid_field' => 'preferred_username',
     'client_options' => {
       'identifier' => '<YOUR PROJECT CLIENT ID>',
       'secret' => '<YOUR PROJECT CLIENT SECRET>',
       'redirect_uri' => 'https://example.com/users/auth/openid_connect/callback',
     }
   }
 }
```

## Troubleshooting

If you're having trouble, here are some tips:

1. Ensure `discovery` is set to `true`. Setting it to `false` requires
   specifying all the URLs and keys required to make OpenID work.

1. Check your system clock to ensure the time is synchronized properly.

1. As mentioned in [the
   documentation](https://github.com/m0n9oose/omniauth_openid_connect),
   make sure `issuer` corresponds to the base URL of the Discovery URL. For
   example, `https://accounts.google.com` is used for the URL
   `https://accounts.google.com/.well-known/openid-configuration`.

1. The OpenID Connect client uses HTTP Basic Authentication to send the
   OAuth2 access token if `client_auth_method` is not defined or if set to `basic`.
   If you are seeing 401 errors upon retrieving the `userinfo` endpoint, you may
   want to check your OpenID Web server configuration. For example, for
   [oauth2-server-php](https://github.com/bshaffer/oauth2-server-php), you
   may need to [add a configuration parameter to
   Apache](https://github.com/bshaffer/oauth2-server-php/issues/926#issuecomment-387502778).
