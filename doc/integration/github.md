# Integrate your server with GitHub

Import projects from GitHub and login to your GitLab instance with your GitHub account.

To enable the GitHub OmniAuth provider you must register your application with GitHub.
GitHub will generate an application ID and secret key for you to use.

1.  Sign in to GitHub.

1.  Navigate to your individual user settings or an organization's settings, depending on how you want the application registered. It does not matter if the application is registered as an individual or an organization - that is entirely up to you.

1.  Select "OAuth applications" in the left menu.

1.  If you already have applications listed, switch to the "Developer applications" tab.

1.  Select "Register new application".

1.  Provide the required details.
    - Application name: This can be anything. Consider something like `<Organization>'s GitLab` or `<Your Name>'s GitLab` or something else descriptive.
    - Homepage URL: The URL to your GitLab installation. 'https://gitlab.company.com'
    - Application description: Fill this in if you wish.
    - Authorization callback URL is 'http(s)://${YOUR_DOMAIN}'. Please make sure the port is included if your Gitlab instance is not configured on default port.
1.  Select "Register application".

1.  You should now see a Client ID and Client Secret near the top right of the page (see screenshot).
    Keep this page open as you continue configuration.
    ![GitHub app](img/github_app.png)

1.  On your GitLab server, open the configuration file.

    For omnibus package:

    ```sh
      sudo editor /etc/gitlab/gitlab.rb
    ```

    For installations from source:

    ```sh
      cd /home/git/gitlab

      sudo -u git -H editor config/gitlab.yml
    ```

1.  See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings.

1.  Add the provider configuration:

    For omnibus package:

    For GitHub.com:

    ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          "name" => "github",
          "app_id" => "YOUR_APP_ID",
          "app_secret" => "YOUR_APP_SECRET",
          "args" => { "scope" => "user:email" }
        }
      ]
    ```

    For GitHub Enterprise:

    ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          "name" => "github",
          "app_id" => "YOUR_APP_ID",
          "app_secret" => "YOUR_APP_SECRET",
          "url" => "https://github.example.com/",
          "args" => { "scope" => "user:email" }
        }
      ]
    ```

    For installation from source:

    For GitHub.com:

    ```
      - { name: 'github', app_id: 'YOUR_APP_ID',
        app_secret: 'YOUR_APP_SECRET',
        args: { scope: 'user:email' } }
    ```


    For GitHub Enterprise:

    ```
      - { name: 'github', app_id: 'YOUR_APP_ID',
        app_secret: 'YOUR_APP_SECRET',
        url: "https://github.example.com/",
        args: { scope: 'user:email' } }
    ```

    __Replace `https://github.example.com/` with your GitHub URL.__

1.  Change 'YOUR_APP_ID' to the client ID from the GitHub application page from step 7.

1.  Change 'YOUR_APP_SECRET' to the client secret from the GitHub application page  from step 7.

1.  Save the configuration file.

1.  [Reconfigure GitLab][] or [restart GitLab][] for the changes to take effect if you
    installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be a GitHub icon below the regular sign in form.
Click the icon to begin the authentication process. GitHub will ask the user to sign in and authorize the GitLab application.
If everything goes well the user will be returned to GitLab and will be signed in.

### GitHub Enterprise with Self-Signed Certificate

If you are attempting to import projects from GitHub Enterprise with a self-signed
certificate and the imports are failing, you will need to disable SSL verification.
It should be disabled by adding `verify_ssl` to `false` in the provider configuration
and changing the global Git `sslVerify` option to `false` in the GitLab server.

For omnibus package:

```ruby
  gitlab_rails['omniauth_providers'] = [
    {
      "name" => "github",
      "app_id" => "YOUR_APP_ID",
      "app_secret" => "YOUR_APP_SECRET",
      "url" => "https://github.example.com/",
      "verify_ssl" => false,
      "args" => { "scope" => "user:email" }
    }
  ]
```

You will also need to disable Git SSL verification on the server hosting GitLab.

```ruby
omnibus_gitconfig['system'] = { "http" => ["sslVerify = false"] }
```

For installation from source:

```
  - { name: 'github', app_id: 'YOUR_APP_ID',
    app_secret: 'YOUR_APP_SECRET',
    url: "https://github.example.com/",
    verify_ssl: false,
    args: { scope: 'user:email' } }
```

You will also need to disable Git SSL verification on the server hosting GitLab.

```
$ git config --global http.sslVerify false
```

For the changes to take effect, [reconfigure Gitlab] if you installed
via Omnibus, or [restart GitLab] if you installed from source.

[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart GitLab]: ../administration/restart_gitlab.md#installations-from-source
