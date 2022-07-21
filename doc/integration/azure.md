---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Use Microsoft Azure as an authentication provider **(FREE SELF)**

You can enable the Microsoft Azure OAuth 2.0 OmniAuth provider and sign in to
GitLab with your Microsoft Azure credentials. You can configure the provider that uses
[the earlier Azure Active Directory v1.0 endpoint](https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-protocols-oauth-code),
or the provider that uses the v2.0 endpoint.

NOTE:
For new projects, Microsoft suggests you use the
[OpenID Connect protocol](../administration/auth/oidc.md#microsoft-azure),
which uses the Microsoft identity platform (v2.0) endpoint.

## Register an Azure application

To enable the Microsoft Azure OAuth 2.0 OmniAuth provider, you must register
an Azure application and get a client ID and secret key.

1. Sign in to the [Azure portal](https://portal.azure.com).
1. If you have multiple Azure Active Directory tenants, switch to the desired tenant.
1. [Register an application](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
   and provide the following information:
   - The redirect URI, which requires the URL of the Azure OAuth callback of your GitLab
     installation. For example:
     - For the v1.0 endpoint: `https://gitlab.example.com/users/auth/azure_oauth2/callback`.
     - For the v2.0 endpoint: `https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback`.
   - The application type, which must be set to **Web**.
1. Save the client ID and client secret. The client secret is only
   displayed once.

   If required, you can [create a new application secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-2-create-a-new-application-secret).

`client ID` and `client secret` are terms associated with OAuth 2.0.
In some Microsoft documentation, the terms are named `Application ID` and
`Application Secret`.

## Add API permissions (scopes)

If you're using the v2.0 endpoint, after you create the application, [configure it to expose a web API](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-expose-web-apis).
Add the following delegated permissions under the Microsoft Graph API:

- `email`
- `openid`
- `profile`

Alternatively, add the `User.Read.All` application permission.

## Enable Microsoft OAuth in GitLab

1. On your GitLab server, open the configuration file.

   - **For Omnibus installations**

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - **For installations from source**

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. [Configure the initial settings](omniauth.md#configure-initial-settings).

1. Add the provider configuration. Replace `CLIENT ID`, `CLIENT SECRET`, and `TENANT ID`
   with the values you got when you registered the Azure application.

   - **For Omnibus installations**

     For the v1.0 endpoint:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         name: "azure_oauth2",
         # label: "Provider name", # optional label for login button, defaults to "Azure AD"
         args: {
           client_id: "CLIENT ID",
           client_secret: "CLIENT SECRET",
           tenant_id: "TENANT ID",
         }
       }
     ]
     ```

     For the v2.0 endpoint:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "CLIENT ID",
           "client_secret" => "CLIENT SECRET",
           "tenant_id" => "TENANT ID",
         }
       }
     ]
     ```

     For [alternative Azure clouds](https://docs.microsoft.com/en-us/azure/active-directory/develop/authentication-national-cloud),
     configure `base_azure_url` under the `args` section. For example, for Azure Government Community Cloud (GCC):

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "CLIENT ID",
           "client_secret" => "CLIENT SECRET",
           "tenant_id" => "TENANT ID",
           "base_azure_url" => "https://login.microsoftonline.us"
         }
       }
     ]
     ```

   - **For installations from source**

     For the v1.0 endpoint:

     ```yaml
     - { name: 'azure_oauth2',
         # label: 'Provider name', # optional label for login button, defaults to "Azure AD"
         args: { client_id: 'CLIENT ID',
                 client_secret: 'CLIENT SECRET',
                 tenant_id: 'TENANT ID' } }
     ```

     For the v2.0 endpoint:

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "CLIENT ID",
                 client_secret: "CLIENT SECRET",
                 tenant_id: "TENANT ID" } }
     ```

     For [alternative Azure clouds](https://docs.microsoft.com/en-us/azure/active-directory/develop/authentication-national-cloud),
     configure `base_azure_url` under the `args` section. For example, for Azure Government Community Cloud (GCC):

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "CLIENT ID",
                 client_secret: "CLIENT SECRET",
                 tenant_id: "TENANT ID",
                 base_azure_url: "https://login.microsoftonline.us" } }
     ```

   In addition, you can optionally add the following parameters to the `args` section:

   - `scope` for [OAuth2 scopes](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow). The default is `openid profile email`.

1. Save the configuration file.

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   if you installed using Omnibus, or [restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   if you installed from source.

1. Refresh the GitLab sign-in page. A Microsoft icon should display below the
   sign-in form.

1. Select the icon. Sign in to Microsoft and authorize the GitLab application.

Read [Enable OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user)
for information on how existing GitLab users can connect to their new Azure AD accounts.
