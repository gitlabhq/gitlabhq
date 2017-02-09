# Crowd OmniAuth Provider

To enable the Crowd OmniAuth provider you must register your application with Crowd. To configure Crowd integration you need an application name and password.  

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

    ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          "name" => "crowd",
          "args" => { 
            "crowd_server_url" => "CROWD",
            "application_name" => "YOUR_APP_NAME",
            "application_password" => "YOUR_APP_PASSWORD"
          }
        }
      ]
    ```

    For installations from source:

    ```
       - { name: 'crowd',
           args: {
             crowd_server_url: 'CROWD SERVER URL',
             application_name: 'YOUR_APP_NAME',
             application_password: 'YOUR_APP_PASSWORD' } }
    ```

1.  Change 'YOUR_APP_NAME' to the application name from Crowd applications page.

1.  Change 'YOUR_APP_PASSWORD' to the application password you've set.

1.  Save the configuration file.

1.  [Reconfigure][] or [restart GitLab][] for the changes to take effect if you
    installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be a Crowd tab in the sign in form.

[reconfigure]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart GitLab]: ../administration/restart_gitlab.md#installations-from-source

