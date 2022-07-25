---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# OmniAuth **(FREE SELF)**

Users can sign in to GitLab by using their credentials from Twitter, GitHub, and other popular services.
[OmniAuth](https://rubygems.org/gems/omniauth/) is the Rack framework that GitLab uses to provide this authentication.

When configured, additional sign-in options are displayed on the sign-in page.

## Supported providers

GitLab supports the following OmniAuth providers.

| Provider documentation                                              | OmniAuth provider name     |
|---------------------------------------------------------------------|----------------------------|
| [AliCloud](alicloud.md)                                             | `alicloud`                 |
| [Atlassian Crowd](../administration/auth/crowd.md)                  | `crowd`                    |
| [Atlassian](../administration/auth/atlassian.md)                    | `atlassian_oauth2`         |
| [Auth0](auth0.md)                                                   | `auth0`                    |
| [Authentiq](../administration/auth/authentiq.md)                    | `authentiq`                |
| [AWS Cognito](../administration/auth/cognito.md)                    | `cognito`                  |
| [Azure v2](azure.md)                                                | `azure_activedirectory_v2` |
| [Azure v1](azure.md)                                                | `azure_oauth2`             |
| [Bitbucket Cloud](bitbucket.md)                                     | `bitbucket`                |
| [CAS](cas.md)                                                       | `cas3`                     |
| [DingTalk](ding_talk.md)                                            | `dingtalk`                |
| [Facebook](facebook.md)                                             | `facebook`                 |
| [Generic OAuth 2.0](oauth2_generic.md)                              | `oauth2_generic`           |
| [GitHub](github.md)                                                 | `github`                   |
| [GitLab.com](gitlab.md)                                             | `gitlab`                   |
| [Google](google.md)                                                 | `google_oauth2`            |
| [JWT](../administration/auth/jwt.md)                                | `jwt`                      |
| [Kerberos](kerberos.md)                                             | `kerberos`                 |
| [OpenID Connect](../administration/auth/oidc.md)                    | `openid_connect`           |
| [Salesforce](salesforce.md)                                         | `salesforce`               |
| [SAML](saml.md)                                                     | `saml`                     |
| [Twitter](twitter.md)                                               | `twitter`                  |

## Configure initial settings

Before you configure the OmniAuth provider,
configure the settings that are common for all providers.

Setting                    | Description | Default value
---------------------------|-------------|--------------
`allow_single_sign_on`     | Enables you to list the providers that automatically create a GitLab account. The provider names are available in the **OmniAuth provider name** column in the [supported providers table](#supported-providers). | The default is `false`. If `false`, users must be created manually, or they can't sign in using OmniAuth.
`auto_link_ldap_user`      | If enabled, creates an LDAP identity in GitLab for users that are created through an OmniAuth provider. You can enable this setting if you have the [LDAP (ActiveDirectory)](../administration/auth/ldap/index.md) integration enabled. Requires the `uid` of the user to be the same in both LDAP and the OmniAuth provider. | The default is `false`.
`block_auto_created_users` | If enabled, blocks users that are automatically created from signing in until they are approved by an administrator. | The default is `true`. If you set the value to `false`, make sure you only define providers for `allow_single_sign_on` that you can control, like SAML, Crowd, or Google. Otherwise, any user on the internet can sign in to GitLab without an administrator's approval.

To change these settings:

- **For Omnibus package**

  1. Open the configuration file:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

  1. Update the following section:

     ```ruby
     # CAUTION!
     # This allows users to sign in without having a user account first. Define the allowed providers
     # using an array, for example, ["saml", "twitter"], or as true/false to allow all providers or none.
     # User accounts will be created automatically when authentication was successful.
     gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'twitter']
     gitlab_rails['omniauth_auto_link_ldap_user'] = true
     gitlab_rails['omniauth_block_auto_created_users'] = true
     ```

- **For installations from source**

  1. Open the configuration file:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

  1. Update the following section:

     ```yaml
     ## OmniAuth settings
     omniauth:
       # Allow sign-in by using Twitter, Google, etc. using OmniAuth providers
       # Versions prior to 11.4 require this to be set to true
       # enabled: true

       # CAUTION!
       # This allows users to sign in without having a user account first. Define the allowed providers
       # using an array, for example, ["saml", "twitter"], or as true/false to allow all providers or none.
       # User accounts will be created automatically when authentication was successful.
       allow_single_sign_on: ["saml", "twitter"]

       auto_link_ldap_user: true

       # Locks down those users until they have been cleared by the admin (default: true).
       block_auto_created_users: true
     ```

After configuring these settings, you can configure
your chosen [provider](#supported-providers).

### Passwords for users created via OmniAuth

The [Generated passwords for users created through integrated authentication](../security/passwords_for_integrated_authentication_methods.md)
guide provides an overview about how GitLab generates and sets passwords for
users created with OmniAuth.

## Enable OmniAuth for an existing user

If you're an existing user, after your GitLab account is
created, you can activate an OmniAuth provider. For example, if you originally signed in with LDAP, you can enable an OmniAuth
provider like Twitter.

1. Sign in to GitLab with your GitLab credentials, LDAP, or another OmniAuth provider.
1. On the top bar, in the top right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Connected Accounts** section, select the OmniAuth provider, such as Twitter.
1. You are redirected to the provider. After you authorize GitLab,
   you are redirected back to GitLab.

You can now use your chosen OmniAuth provider to sign in to GitLab.

## Enable or disable sign-in with an OmniAuth provider without disabling import sources

Administrators can enable or disable sign-in for some OmniAuth providers.

NOTE:
By default, sign-in is enabled for all the OAuth providers configured in `config/gitlab.yml`.

To enable or disable an OmniAuth provider:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings**.
1. Expand **Sign-in restrictions**.
1. In the **Enabled OAuth authentication sources** section, select or clear the checkbox for each provider you want to enable or disable.

## Disable OmniAuth

OmniAuth is enabled by default. However, OmniAuth only works
if providers are configured and [enabled](#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources).

If OmniAuth providers are causing problems even when individually disabled, you
can disable the entire OmniAuth subsystem by modifying the configuration file:

- **For Omnibus installations**

  ```ruby
  gitlab_rails['omniauth_enabled'] = false
  ```

- **For installations from source**

  ```yaml
  omniauth:
    enabled: false
  ```

## Link existing users to OmniAuth users

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36664) in GitLab 13.4.

You can automatically link OmniAuth users with existing GitLab users if their email addresses match.

The following example enables automatic linking
for the OpenID Connect provider and the Twitter OAuth provider.

- **For Omnibus installations**

  ```ruby
  gitlab_rails['omniauth_auto_link_user'] = ["openid_connect", "twitter"]
  ```

- **For installations from source**

  ```yaml
  omniauth:
    auto_link_user: ["openid_connect", "twitter"]
  ```

This method of enabling automatic linking works for all providers
[except SAML](https://gitlab.com/gitlab-org/gitlab/-/issues/338293).
To enable automatic linking for SAML, see the [SAML setup instructions](saml.md#general-setup).

## Create an external providers list

You can define a list of external OmniAuth providers.
Users who create accounts or sign in to GitLab through the listed providers do not get access to [internal projects](../user/public_access.md#internal-projects-and-groups).

To define the external providers list, use the full name of the provider,
for example, `google_oauth2` for Google. For provider names, see the
**OmniAuth provider name** column in the [supported providers table](#supported-providers).

NOTE:
If you remove an OmniAuth provider from the external providers list,
you must manually update the users that use this sign-in method so their
accounts are upgraded to full internal accounts.

- **For Omnibus installations**

  ```ruby
  gitlab_rails['omniauth_external_providers'] = ['twitter', 'google_oauth2']
  ```

- **For installations from source**

  ```yaml
  omniauth:
    external_providers: ['twitter', 'google_oauth2']
  ```

## Use a custom OmniAuth provider

NOTE:
The following information only applies to installations from source.

If you have to integrate with an authentication solution other than the [OmniAuth](https://github.com/omniauth/omniauth) providers included with GitLab,
you can use a custom OmniAuth provider.

These steps are general. Read the OmniAuth provider's documentation for the exact
implementation details.

1. Stop GitLab:

   ```shell
   sudo service gitlab stop
   ```

1. Add the gem to your [`Gemfile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/Gemfile):

   ```shell
   gem "omniauth-your-auth-provider"
   ```

1. Install the new OmniAuth provider gem:

   ```shell
   sudo -u git -H bundle install --without development test mysql --path vendor/bundle --no-deployment
   ```

   These commands are the same as the commands for [installing gems](../install/installation.md#install-gems)
   during initial installation, with `--path vendor/bundle --no-deployment` instead of `--deployment`.

1. Start GitLab:

   ```shell
   sudo service gitlab start
   ```

### Custom OmniAuth provider examples

If you have successfully set up a provider that is not already integrated with GitLab,
let us know.

We can't officially support every possible authentication mechanism available,
but we'd like to at least help those with specific needs.

## Keep OmniAuth user profiles up to date

You can enable profile syncing from selected OmniAuth providers. You can sync
all or specific user information.

When authenticating using LDAP, the user's name and email are always synced.

- **For Omnibus installations**

  ```ruby
  gitlab_rails['omniauth_sync_profile_from_provider'] = ['twitter', 'google_oauth2']
  gitlab_rails['omniauth_sync_profile_attributes'] = ['name', 'email', 'location']
  ```

- **For installations from source**

  ```yaml
  omniauth:
    sync_profile_from_provider: ['twitter', 'google_oauth2']
    sync_profile_attributes: ['email', 'location']
  ```

## Bypass two-factor authentication

> Introduced in GitLab 12.3.

With certain OmniAuth providers, users can sign in without using two-factor authentication (2FA).

Because of a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/196131) users must
[set up 2FA](../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication) on their GitLab
account to bypass 2FA. Otherwise, they are prompted to set up 2FA when they sign in to GitLab.

To bypass 2FA, you can either:

- Define the allowed providers using an array (for example, `['twitter', 'google_oauth2']`).
- Specify `true` to allow all providers, or `false` to allow none.

This option should be configured only for providers that already have 2FA. The default is `false`.

This configuration doesn't apply to SAML.

- **For Omnibus package**

  ```ruby
  gitlab_rails['omniauth_allow_bypass_two_factor'] = ['twitter', 'google_oauth2']
  ```

- **For installations from source**

  ```yaml
  omniauth:
    allow_bypass_two_factor: ['twitter', 'google_oauth2']
  ```

## Sign in with a provider automatically

You can add the `auto_sign_in_with_provider` setting to your GitLab
configuration to redirect login requests to your OmniAuth provider for
authentication. This removes the need to select the provider before signing in.

For example, to enable automatic sign-in for the
[Azure v2 integration](azure.md):

- **For Omnibus package**

  ```ruby
  gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'azure_activedirectory_v2'
  ```

- **For installations from source**

  ```yaml
  omniauth:
    auto_sign_in_with_provider: azure_activedirectory_v2
  ```

Keep in mind that every sign-in attempt is redirected to the OmniAuth
provider, so you can't sign in using local credentials. Ensure at least
one of the OmniAuth users is an administrator.

You can also bypass automatic sign-in by browsing to
`https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

## Use a custom OmniAuth provider icon

Most supported providers include a built-in icon for the rendered sign-in button.

To use your own icon, ensure your image is optimized for rendering at 64 x 64 pixels,
then override the icon in one of two ways:

- **Provide a custom image path**:

  1. If you are hosting the image outside of your GitLab server domain, ensure
     your [content security policies](https://docs.gitlab.com/omnibus/settings/configuration.html#content-security-policy)
     are configured to allow access to the image file.
  1. Depending on your method of installing GitLab, add a custom `icon` parameter
     to your GitLab configuration file. Read [OpenID Connect OmniAuth provider](../administration/auth/oidc.md)
     for an example for the OpenID Connect provider.

- **Embed an image directly in a configuration file**: This example creates a Base64-encoded
  version of your image you can serve through a
  [Data URL](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs):

  1. Encode your image file with a GNU `base64` command (such as `base64 -w 0 <logo.png>`)
     which returns a single-line `<base64-data>` string.
  1. Add the Base64-encoded data to a custom `icon` parameter in your GitLab
     configuration file:

     ```yaml
     omniauth:
       providers:
         - { name: '...'
             icon: 'data:image/png;base64,<base64-data>'
             ...
           }
     ```

## Limitations

Most supported OmniAuth providers don't support Git over HTTP password authentication.
The only exception is [Atlassian Crowd](../administration/auth/crowd.md) (since GitLab [13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46935)).
As a workaround, you can authenticate using a [personal access token](../user/profile/personal_access_tokens.md).
