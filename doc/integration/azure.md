# Microsoft Azure OAuth2 OmniAuth Provider

To enable the Microsoft Azure OAuth2 OmniAuth provider you must register your application with Azure. Azure will generate a client ID and secret key for you to use.

1. Sign in to the [Azure Portal](https://portal.azure.com).

1. Select "All Services" from the hamburger menu located top left and select "Azure Active Directory" or use the search bar at the top of the page to search for "Azure Active Directory".
   1. You can select alternative directories by clicking the "switch tenant" button at the top of the Azure AD page.

1. Select "App registrations" from the left hand menu, then select "New registration" from the top of the page.

1. Provide the required information and click the "Register" button.
   - Name: 'GitLab' works just fine here.
   - Supported account types: Select the appropriate choice based on the descriptions provided.
   - Redirect URI: Enter the URL to the Azure OAuth callback of your GitLab installation (e.g. `https://gitlab.mycompany.com/users/auth/azure_oauth2/callback`), the type dropdown should be set to "Web".

1. On the "App Registration" page for the app you've created. Select "Certificates & secrets" on the left.
   - Create a new Client secret by clicking "New client secret" and selecting a duration. Provide a description if required to help identify the secret.
   - Copy the secret and note it securely, this is shown when you click the "add" button. (You will not be able to retrieve the secret when you perform the next step or leave that blade in the Azure Portal.)

1. Select "Overview" in the left hand menu.

1. Note the "Application (client) ID" from the section at the top of the displayed page.

1. Note the "Directory (tenant) ID" from the section at the top of the page.

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

1. See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings.

1. Add the provider configuration:

   For Omnibus package:

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
   e.g. `base_azure_url: "https://login.microsoftonline.de"`.

1. Replace 'CLIENT ID', 'CLIENT SECRET' and 'TENANT ID' with the values you got above.

1. Save the configuration file.

1. [Reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart GitLab](../administration/restart_gitlab.md#installations-from-source) for the changes to take effect if you
   installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be a Microsoft icon below the regular sign in form. Click the icon to begin the authentication process. Microsoft will ask the user to sign in and authorize the GitLab application. If everything goes well the user will be returned to GitLab and will be signed in. See [Enable OmniAuth for an Existing User](omniauth.md#enable-omniauth-for-an-existing-user) for information on how existing GitLab users can connect their newly available Azure AD accounts to their existing GitLab users.
