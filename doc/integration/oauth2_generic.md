---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Generic OAuth2 provider **(FREE SELF)**

The `omniauth-oauth2-generic` gem allows single sign-on (SSO) between GitLab
and your OAuth2 provider (or any OAuth2 provider compatible with this gem).

This strategy allows for the configuration of this OmniAuth SSO process:

1. Strategy directs the client to your authorization URL (**configurable**), with
   the specified ID and key.
1. The OAuth2 provider handles authentication of the request, user, and (optionally)
   authorization to access user's profile.
1. The OAuth2 provider directs the client back to GitLab where Strategy handles
   the retrieval of the access token.
1. Strategy requests user information from a **configurable** "user profile"
   URL (using the access token).
1. Strategy parses user information from the response, using a **configurable**
   format.
1. GitLab finds or creates the returned user and signs them in.

## Limitations of this strategy

- It can only be used for single sign-on, and doesn't provide any other access
  granted by any OAuth2 provider (like importing projects or users).
- It supports only the Authorization Grant flow (most common for client-server
  applications, like GitLab).
- It can't fetch user information from more than one URL.
- It hasn't been tested with user information formats, other than JSON.

## Configure the OAuth2 provider

To configure the provider:

1. Register your application in the OAuth2 provider you want to authenticate with.

   The redirect URI you provide when registering the application should be:

   ```plaintext
   http://your-gitlab.host.com/users/auth/oauth2_generic/callback
   ```

   You should now be able to get a Client ID and Client Secret. Where this
   appears differs for each provider. This may also be called Application ID
   and Secret.

1. On your GitLab server, open the appropriate configuration file.

   For Omnibus GitLab:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. See [Configure initial settings](omniauth.md#configure-initial-settings) for
   initial settings.

1. Add the provider-specific configuration for your provider. For example:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "oauth2_generic",
       label: "Provider name", # optional label for login button, defaults to "Oauth2 Generic"
       app_id: "<your_app_client_id>",
       app_secret: "<your_app_client_secret>",
       args: {
         client_options: {
           site: "<your_auth_server_url>",
           user_info_url: "/oauth2/v1/userinfo",
           authorize_url: "/oauth2/v1/authorize",
           token_url: "/oauth2/v1/token"
         },
         user_response_structure: {
           root_path: [],
           id_path: ["sub"],
           attributes: {
             email: "email",
             name: "name"
           }
         },
         authorize_params: {
           scope: "openid profile email"
         },
         strategy_class: "OmniAuth::Strategies::OAuth2Generic"
       }
     }
   ]
   ```

   For more information about these settings, see [the gem's README](https://gitlab.com/satorix/omniauth-oauth2-generic#gitlab-config-example).

1. Save the configuration file.

1. [Restart](../administration/restart_gitlab.md#installations-from-source)
   GitLab for the changes to take effect.

On the sign-in page there should now be a new button below the regular sign-in
form. Select the button to begin your provider's authentication process. This
directs the browser to your OAuth2 provider's authentication page. If
everything goes well, you are returned to your GitLab instance and are
signed in.
