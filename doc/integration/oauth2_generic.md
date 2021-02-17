---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sign into GitLab with (almost) any OAuth2 provider **(FREE)**

The `omniauth-oauth2-generic` gem allows Single Sign-On between GitLab and your own OAuth2 provider
(or any OAuth2 provider compatible with this gem)

This strategy is designed to allow configuration of the simple OmniAuth SSO process outlined below:

1. Strategy directs client to your authorization URL (**configurable**), with specified ID and key
1. OAuth provider handles authentication of request, user, and (optionally) authorization to access user's profile
1. OAuth provider directs client back to GitLab where Strategy handles retrieval of access token
1. Strategy requests user information from a **configurable** "user profile" URL (using the access token)
1. Strategy parses user information from the response, using a **configurable** format
1. GitLab finds or creates the returned user and logs them in

## Limitations of this Strategy

- It can only be used for Single Sign on, and doesn't provide any other access granted by any OAuth provider
  (importing projects or users, etc)
- It only supports the Authorization Grant flow (most common for client-server applications, like GitLab)
- It is not able to fetch user information from more than one URL
- It has not been tested with user information formats other than JSON

## Configuration Instructions

1. Register your application in the OAuth2 provider you wish to authenticate with.

   The redirect URI you provide when registering the application should be:

   ```plaintext
   http://your-gitlab.host.com/users/auth/oauth2_generic/callback
   ```

1. You should now be able to get a Client ID and Client Secret.
   Where this shows up differs for each provider.
   This may also be called Application ID and Secret

1. On your GitLab server, open the configuration file.

   For Omnibus package:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings

1. Add the provider-specific configuration for your provider, as [described in the gem's README](https://gitlab.com/satorix/omniauth-oauth2-generic#gitlab-config-example)

1. Save the configuration file

1. Restart GitLab for the changes to take effect

On the sign in page there should now be a new button below the regular sign in form.
Click the button to begin your provider's authentication process. This directs
the browser to your OAuth2 Provider's authentication page. If everything goes well
the user is returned to your GitLab instance and is signed in.
