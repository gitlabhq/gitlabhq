# Integrate your server with Bitbucket

Import projects from Bitbucket and login to your GitLab instance with your Bitbucket account.

To enable the Bitbucket OmniAuth provider you must register your application with Bitbucket. 
Bitbucket will generate an application ID and secret key for you to use.

1.  Sign in to Bitbucket.

1.  Navigate to your individual user settings or a team's settings, depending on how you want the application registered. It does not matter if the application is registered as an individual or a team - that is entirely up to you.

1.  Select "OAuth" in the left menu.

1.  Select "Add consumer".

1.  Provide the required details.
    - Name: This can be anything. Consider something like "\<Organization\>'s GitLab" or "\<Your Name\>'s GitLab" or something else descriptive.
    - Application description: Fill this in if you wish.
    - URL: The URL to your GitLab installation. 'https://gitlab.company.com'
1.  Select "Save".

1.  You should now see a Key and Secret in the list of OAuth customers. 
    Keep this page open as you continue configuration. 

1.  On your GitLab server, open the configuration file.

    For omnibus package:

    ```sh
      sudo editor /etc/gitlab/gitlab.rb
    ```

    For instalations from source:

    ```sh
      cd /home/git/gitlab

      sudo -u git -H editor config/gitlab.yml
    ```

1.  See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings.

1.  Add the provider configuration:

    For omnibus package:

    ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          "name" => "bitbucket",
          "app_id" => "YOUR_KEY",
          "app_secret" => "YOUR_APP_SECRET",
          "url" => "https://bitbucket.org/"
        }
      ]
    ```

    For installation from source:

    ```
      - { name: 'bitbucket', app_id: 'YOUR_KEY',
        app_secret: 'YOUR_APP_SECRET' }
    ```

1.  Change 'YOUR_APP_ID' to the key from the Bitbucket application page from step 7.

1.  Change 'YOUR_APP_SECRET' to the secret from the Bitbucket application page from step 7.

1.  Save the configuration file.

1.  Restart GitLab for the changes to take effect.

On the sign in page there should now be a Bitbucket icon below the regular sign in form. 
Click the icon to begin the authentication process. Bitbucket will ask the user to sign in and authorize the GitLab application. 
If everything goes well the user will be returned to GitLab and will be signed in.

## Bitbucket project import

To allow projects to be imported directly into GitLab, Bitbucket requires one extra setup step compared to GitHub and GitLab.com. 

Bitbucket doesn't allow OAuth applications to clone repositories over HTTPS, and instead requires GitLab to use SSH and identify itself using your GitLab server's SSH key.

GitLab will automatically register your public key with Bitbucket as a deploy key for the repositories to be imported. Your public key needs to be at `~/.ssh/id_rsa.pub`, which will expand to `/home/git/.ssh/id_rsa.pub` in most configurations.

If you have that file in place, you're all set and should see the "Import projects from Bitbucket" option enabled. If you don't, do the following:

1. Create a new SSH key:

    ```sh
        sudo -u git -H ssh-keygen
    ```

    Make sure to use an **empty passphrase**.

2. Restart GitLab to allow it to find the new public key.

You should now see the "Import projects from Bitbucket" option on the New Project page enabled.