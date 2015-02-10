# GitHub OAuth2 OmniAuth Provider

To enable the GitHub OmniAuth provider you must register your application with GitHub. GitHub will generate a client ID and secret key for you to use.

1.  Sign in to GitHub.

1.  Navigate to your individual user settings or an organization's settings, depending on how you want the application registered. It does not matter if the application is registered as an individual or an organization - that is entirely up to you.

1.  Select "Applications" in the left menu.

1.  Select "Register new application".

1.  Provide the required details.
    - Application name: This can be anything. Consider something like "\<Organization\>'s GitLab" or "\<Your Name\>'s GitLab" or something else descriptive.
    - Homepage URL: The URL to your GitLab installation. 'https://gitlab.company.com'
    - Application description: Fill this in if you wish.
    - Authorization callback URL: 'https://gitlab.company.com/'
1.  Select "Register application".

1.  You should now see a Client ID and Client Secret near the top right of the page (see screenshot). Keep this page open as you continue configuration. ![GitHub app](github_app.png)

1.  On your GitLab server, open the configuration file.

    ```sh
    cd /home/git/gitlab

    sudo -u git -H editor config/gitlab.yml
    ```

1.  Find the section dealing with OmniAuth. See [Initial OmniAuth Configuration](README.md#initial-omniauth-configuration) for more details.

1.  Under `providers:` uncomment (or add) lines that look like the following:

    ```
        - { name: 'github', app_id: '01723ee0027dd2b496d9',
          app_secret: '7f4b9298d181375e51cd60e25e9f26603a4dd3cc',
          args: {
            scope: 'user:email',
            client_options: {
              site:          'https://api.github.com/',
              authorize_url: 'https://github.com/login/oauth/authorize',
              token_url:     'https://github.com/login/oauth/access_token'
            }
          }
        }
    ```

    

1. If you want to use GitHub Enterprise then your configuration should look like the following:

    ```
        - { name: 'github', app_id: 'a4eaa26df2ff35879923',
          app_secret: '2f9236c341cf8b3dc86a93652554fccd4ef84c55',
          args: {
            scope: 'user:email',
            client_options: {
              site:          'https://github.example.com/api/v3',
              authorize_url: 'https://github.example.com/login/oauth/authorize',
              token_url:     'https://github.example.com/login/oauth/access_token'
            }
          }
        }
    ```


1.  Change 'YOUR APP ID' to the client ID from the GitHub application page from step 7.

1.  Change 'YOUR APP SECRET' to the client secret from the GitHub application page  from step 7.

1.  Save the configuration file.

1.  Restart GitLab for the changes to take effect.

On the sign in page there should now be a GitHub icon below the regular sign in form. Click the icon to begin the authentication process. GitHub will ask the user to sign in and authorize the GitLab application. If everything goes well the user will be returned to GitLab and will be signed in.
