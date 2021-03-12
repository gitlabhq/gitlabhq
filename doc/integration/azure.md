---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Microsoft Azure OAuth2 OmniAuth Provider **(FREE)**

NOTE:
Per Microsoft, this provider uses the [older Azure Active Directory v1.0 endpoint](https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-protocols-oauth-code).
Microsoft documentation suggests that you should use the [OpenID Connect protocol to use the v2 endpoints](../administration/auth/oidc.md#microsoft-azure) for new projects.
To use v2 endpoints via OmniAuth, please follow [Microsoft Azure OAuth2 OmniAuth Provider v2 instructions](#microsoft-azure-oauth2-omniauth-provider-v2).

To enable the Microsoft Azure OAuth2 OmniAuth provider, you must register your application with Azure. Azure generates a client ID and secret key for you to use.

Sign in to the [Azure Portal](https://portal.azure.com), and follow the instructions in
the [Microsoft Quickstart documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app).

As you go through the Microsoft procedure, keep the following in mind:

- If you have multiple instances of Azure Active Directory, you can switch to the desired tenant.
- You're setting up a Web application.
- The redirect URI requires the URL of the Azure OAuth callback of your GitLab
  installation. For example, `https://gitlab.mycompany.com/users/auth/azure_oauth2/callback`.
  The type dropdown should be set to **Web**.
- The `client ID` and `client secret` are terms associated with OAuth 2. In some Microsoft documentation,
  the terms may be listed as `Application ID` and `Application Secret`.
- If you need to generate a new client secret, follow the Microsoft documentation
  for [creating a new application secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret).
- Save the client ID and client secret for your new app, as the client secret is only
  displayed one time.

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

1. Refer to [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration)
   for initial settings.

1. Add the provider configuration:

   For Omnibus GitLab:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       "name" => "azure_oauth2",
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
   - { name: 'azure_oauth2',
     args: { client_id: "CLIENT ID",
     client_secret: "CLIENT SECRET",
     tenant_id: "TENANT ID" } }
   ```

   The `base_azure_url` is optional and can be added for different locales;
   such as `base_azure_url: "https://login.microsoftonline.de"`.

1. Replace `CLIENT ID`, `CLIENT SECRET` and `TENANT ID` with the values you got above.

1. Save the configuration file.

1. Reconfigure or restart GitLab, depending on your installation method:

   - *If you installed from Omnibus GitLab,*
     [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab.
   - *If you installed from source,*
     [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

On the sign-in page, you should now see a Microsoft icon below the regular sign-in form.
Click the icon to begin the authentication process. Microsoft then asks you to
sign in and authorize the GitLab application. If successful, you are returned to GitLab and signed in.

Read [Enable OmniAuth for an Existing User](omniauth.md#enable-omniauth-for-an-existing-user)
for information on how existing GitLab users can connect to their newly-available Azure AD accounts.

## Microsoft Azure OAuth2 OmniAuth Provider v2

In order to use v2 endpoints provided by Microsoft Azure Active Directory you must to configure it via Azure OAuth2 OmniAuth Provider v2.

### Registering an Azure application

To enable the Microsoft Azure OAuth2 OmniAuth provider, you must register your application with Azure. Azure generates a client ID and secret key for you to use.

Sign in to the [Azure Portal](https://portal.azure.com), and follow the instructions in
the [Microsoft Quickstart documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app).

As you go through the Microsoft procedure, keep the following in mind:

- If you have multiple instances of Azure Active Directory, you can switch to the desired tenant.
- You're setting up a Web application.
- The redirect URI requires the URL of the Azure OAuth callback of your GitLab
  installation. For example, `https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback`.
  The type dropdown should be set to **Web**.
- The `client ID` and `client secret` are terms associated with OAuth 2. In some Microsoft documentation,
  the terms may be listed as `Application ID` and `Application Secret`.
- If you need to generate a new client secret, follow the Microsoft documentation
  for [creating a new application secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret).
- Save the client ID and client secret for your new app, as the client secret is only
  displayed one time.

### Adding API permissions (scopes)

Once you have created an application, follow the [Microsoft Quickstart documentation to expose a web API](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-expose-web-apis). Be sure to add the following delegated permissions under the Microsoft Graph API:

- `email`
- `openid`
- `profile`

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

1. Refer to [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration)
   for initial settings.

1. Add the provider configuration:

   For Omnibus GitLab:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       "name" => "azure_activedirectory_v2",
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
     args: { client_id: "CLIENT ID",
     client_secret: "CLIENT SECRET",
     tenant_id: "TENANT ID" } }
   ```

   The `base_azure_url` is optional and can be added for different locales;
   such as `base_azure_url: "https://login.microsoftonline.de"`.

   The `scope` parameter is optional and can be added to `args`. Default `scope` is: `openid profile email`.

1. Replace `CLIENT ID`, `CLIENT SECRET`, and `TENANT ID` with the values you got above.

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
