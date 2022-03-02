---
stage: Ecosystem
group: Integrations
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
     installation. For example, `https://gitlab.mycompany.com/users/auth/azure_oauth2/callback`.
   - The application type, which must be set to **Web**.
1. Save the client ID and client secret. The client secret is only
   displayed once.

   If required, you can [create a new application secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-2-create-a-new-application-secret).

`client ID` and `client secret` are terms associated with OAuth 2.0.
In some Microsoft documentation, the terms are named `Application ID` and
`Application Secret`.

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

   - **For installations from source**

     ```yaml
     - { name: 'azure_oauth2',
         # label: 'Provider name', # optional label for login button, defaults to "Azure AD"
         args: { client_id: 'CLIENT ID',
         client_secret: 'CLIENT SECRET',
         tenant_id: 'TENANT ID' } }
     ```

     You can optionally add `base_azure_url` for different locales,
     for example, `base_azure_url: "https://login.microsoftonline.de"`.

1. Save the configuration file.

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   if you installed using Omnibus, or [restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   if you installed from source.

1. Refresh the GitLab sign-in page. A Microsoft icon should display below the
   sign-in form.

1. Select the icon. Sign in to Microsoft and authorize the GitLab application.

Read [Enable OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user)
for information on how existing GitLab users can connect to their new Azure AD accounts.

## Microsoft Azure OAuth 2.0 OmniAuth Provider v2

To use v2 endpoints provided by Microsoft Azure Active Directory you must to
configure it via Azure OAuth 2.0 OmniAuth Provider v2.

### Registering an Azure application

To enable the Microsoft Azure OAuth 2.0 OmniAuth provider, you must register
your application with Azure. Azure generates a client ID and secret key for you
to use.

Sign in to the [Azure Portal](https://portal.azure.com), and follow the
instructions in the [Microsoft Quickstart documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app).

As you go through the Microsoft procedure, keep the following in mind:

- If you have multiple instances of Azure Active Directory, you can switch to
  the desired tenant.
- You're setting up a Web application.
- The redirect URI requires the URL of the Azure OAuth callback of your GitLab
  installation. For example, `https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback`.
  The type dropdown should be set to **Web**.
- The `client ID` and `client secret` are terms associated with OAuth 2.0. In some Microsoft documentation,
  the terms may be listed as `Application ID` and `Application Secret`.
- If you have to generate a new client secret, follow the Microsoft documentation
  for [creating a new application secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret).
- Save the client ID and client secret for your new app, as the client secret is only
  displayed one time.

### Adding API permissions (scopes)

After you have created an application, follow the [Microsoft Quickstart documentation to expose a web API](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-expose-web-apis). Be sure to add the following delegated permissions under the Microsoft Graph API:

- `email`
- `openid`
- `profile`

Alternatively, add the `User.Read.All` application permission.

### Configuring GitLab

1. On your GitLab server, open the configuration file.

   For Omnibus GitLab:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H editor config/gitlab.yml
   ```

1. Refer to [Configure initial settings](omniauth.md#configure-initial-settings)
   for initial settings.

1. Add the provider configuration:

   For Omnibus GitLab:

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

   For installations from source:

   ```yaml
   - { name: 'azure_activedirectory_v2',
       label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
       args: { client_id: "CLIENT ID",
       client_secret: "CLIENT SECRET",
       tenant_id: "TENANT ID" } }
   ```

   The `base_azure_url` is optional and can be added for different locales;
   such as `base_azure_url: "https://login.microsoftonline.de"`.

   The `scope` parameter is optional and can be added to `args`. Default `scope` is: `openid profile email`.

1. Replace `CLIENT ID`, `CLIENT SECRET`, and `TENANT ID` with the values you got
   above.

1. Save the configuration file.

1. Reconfigure or restart GitLab, depending on your installation method:

   - *If you installed from Omnibus GitLab,*
     [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab.
   - *If you installed from source,*
     [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

On the sign-in page, you should now see a Microsoft icon below the regular sign-in form.
Select the icon to begin the authentication process. Microsoft then asks you to
sign in and authorize the GitLab application. If successful, you are returned to GitLab and signed in.

Read [Enable OmniAuth for an Existing User](omniauth.md#enable-omniauth-for-an-existing-user)
for information on how existing GitLab users can connect to their newly available Azure AD accounts.
