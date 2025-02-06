---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Microsoft Azure as an OAuth 2.0 authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can enable the Microsoft Azure OAuth 2.0 OmniAuth provider and sign in to
GitLab with your Microsoft Azure credentials.

NOTE:
If you're integrating GitLab with Azure/Entra ID for the first time,
configure the [OpenID Connect protocol](../administration/auth/oidc.md#configure-microsoft-azure),
which uses the Microsoft identity platform (v2.0) endpoint.

## Migrate to Generic OpenID Connect configuration

In GitLab 17.0 and later, instances using `azure_oauth2` must migrate to the Generic OpenID Connect configuration. For more information, see [Migrating to the OpenID Connect protocol](../administration/auth/oidc.md#migrate-to-generic-openid-connect-configuration).

## Register an Azure application

To enable the Microsoft Azure OAuth 2.0 OmniAuth provider, you must register
an Azure application and get a client ID and secret key.

1. Sign in to the [Azure portal](https://portal.azure.com).
1. If you have multiple Azure Active Directory tenants, switch to the desired tenant. Note the tenant ID.
1. [Register an application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
   and provide the following information:
   - The redirect URI, which requires the URL of the Azure OAuth callback of your GitLab
     installation. `https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback`.
   - The application type, which must be set to **Web**.
1. Save the client ID and client secret. The client secret is only
   displayed once.

   If required, you can [create a new application secret](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#option-3-create-a-new-client-secret).

`client ID` and `client secret` are terms associated with OAuth 2.0.
In some Microsoft documentation, the terms are named `Application ID` and
`Application Secret`.

## Add API permissions (scopes)

After you create the application, [configure it to expose a web API](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis).
Add the following delegated permissions under the Microsoft Graph API:

- `email`
- `openid`
- `profile`

Alternatively, add the `User.Read.All` application permission.

## Enable Microsoft OAuth in GitLab

NOTE:
For new projects, you should use the
[OpenID Connect protocol](../administration/auth/oidc.md#configure-microsoft-azure),
which uses the Microsoft identity platform (v2.0) endpoint.

1. On your GitLab server, open the configuration file.

   - For Linux package installations:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - For self-compiled installations:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `azure_activedirectory_v2` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration. Replace `<client_id>`, `<client_secret>`, and `<tenant_id>`
   with the values you got when you registered the Azure application.

   - For Linux package installations:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "<client_id>",
           "client_secret" => "<client_secret>",
           "tenant_id" => "<tenant_id>",
         }
       }
     ]

     ```

   - For [alternative Azure clouds](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud),
     configure `base_azure_url` under the `args` section. For example, for Azure Government Community Cloud (GCC):

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "<client_id>",
           "client_secret" => "<client_secret>",
           "tenant_id" => "<tenant_id>",
           "base_azure_url" => "https://login.microsoftonline.us"
         }
       }
     ]
     ```

   - For self-compiled installations:

     For the v2.0 endpoint:

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>" } }
     ```

     For [alternative Azure clouds](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud),
     configure `base_azure_url` under the `args` section. For example, for Azure Government Community Cloud (GCC):

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>",
                 base_azure_url: "https://login.microsoftonline.us" } }
     ```

   You can also optionally add the `scope` for [OAuth 2.0 scopes](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow) parameter to the `args` section. The default is `openid profile email`.

1. Save the configuration file.

1. [Reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)
   if you installed using the Linux package, or [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations)
   if you self-compiled your installation.

1. Refresh the GitLab sign-in page. A Microsoft icon should display below the
   sign-in form.

1. Select the icon. Sign in to Microsoft and authorize the GitLab application.

Read [Enable OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user)
for information on how existing GitLab users can connect to their new Azure AD accounts.

## Troubleshooting

### User sign in banner message: Extern UID has already been taken

When signing in, you might get an error that states `Extern UID has already been taken`.

To resolve this, use the [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session) to check if there is an existing user tied to the account:

1. Find the `extern_uid`:

   ```ruby
   id = Identity.where(extern_uid: '<extern_uid>')
   ```

1. Print the content to find the username attached to that `extern_uid`:

   ```ruby
   pp id
   ```

If the `extern_uid` is attached to an account, you can use the username to sign in.

If the `extern_uid` is not attached to any username, this might be because of a deletion error resulting in a ghost record.

Run the following command to delete the identity to release the `extern uid`:

```ruby
 Identity.find('<id>').delete
```
