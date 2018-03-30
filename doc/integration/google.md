# Google OAuth2 OmniAuth Provider

To enable the Google OAuth2 OmniAuth provider you must register your application
with Google. Google will generate a client ID and secret key for you to use.

## Enabling Google OAuth

In Google's side:

1. Navigate to the [cloud resource manager](https://console.cloud.google.com/cloud-resource-manager) page
1. Select **Create Project**
1. Provide the project information:
    - **Project name** - "GitLab" works just fine here.
    - **Project ID** - Must be unique to all Google Developer registered applications.
      Google provides a randomly generated Project ID by default. You can use
      the randomly generated ID or choose a new one.
1. Refresh the page and you should see your new project in the list
1. Go to the [Google API Console](https://console.developers.google.com/apis/dashboard)
1. Select the previously created project form the upper left corner
1. Select **Credentials** from the sidebar
1. Select **OAuth consent screen** and fill the form with the required information
1. In the **Credentials** tab, select **Create credentials > OAuth client ID**
1. Fill in the required information
    - **Application type** - Choose "Web Application"
    - **Name** - Use the default one or provide your own
    - **Authorized JavaScript origins** -This isn't really used by GitLab but go
      ahead and put `https://gitlab.example.com`
    - **Authorized redirect URIs** - Enter your domain name followed by the
      callback URIs one at a time:

        ```
        https://gitlab.example.com/users/auth/google_oauth2/callback
        https://gitlab.exampl.com/-/google_api/auth/callback
        ```

1. You should now be able to see a Client ID and Client secret. Note them down
   or keep this page open as you will need them later.
1. From the **Dashboard** select **ENABLE APIS AND SERVICES > Compute > Google Kubernetes Engine API > Enable**

On your GitLab server:

1. Open the configuration file.

    For Omnibus GitLab:

    ```sh
    sudo editor /etc/gitlab/gitlab.rb
    ```

    For installations from source:

    ```sh
    cd /home/git/gitlab
    sudo -u git -H editor config/gitlab.yml
    ```

1. See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings.
1. Add the provider configuration:

    For Omnibus GitLab:

    ```ruby
    gitlab_rails['omniauth_providers'] = [
      {
        "name" => "google_oauth2",
        "app_id" => "YOUR_APP_ID",
        "app_secret" => "YOUR_APP_SECRET",
        "args" => { "access_type" => "offline", "approval_prompt" => '' }
      }
    ]
    ```

    For installations from source:

    ```
    - { name: 'google_oauth2', app_id: 'YOUR_APP_ID',
      app_secret: 'YOUR_APP_SECRET',
      args: { access_type: 'offline', approval_prompt: '' } }
    ```

1. Change `YOUR_APP_ID` to the client ID from the Google Developer page
1. Similarly, change `YOUR_APP_SECRET` to the client secret
1. Make sure that you configure GitLab to use an FQDN as Google will not accept
   raw IP addresses.

    For Omnibus packages:

    ```ruby
    external_url 'https://gitlab.example.com'
    ```

    For installations from source:

    ```yaml
    gitlab:
      host: https://gitlab.example.com
    ```

1.  Save the configuration file.
1.  [Reconfigure][] or [restart GitLab][] for the changes to take effect if you
    installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be a Google icon below the regular sign in
form. Click the icon to begin the authentication process. Google will ask the
user to sign in and authorize the GitLab application. If everything goes well
the user will be returned to GitLab and will be signed in.

[reconfigure]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart GitLab]: ../administration/restart_gitlab.md#installations-from-source
