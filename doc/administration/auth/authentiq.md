# Authentiq OmniAuth Provider

To enable the Authentiq OmniAuth provider for passwordless authentication you must register an application with Authentiq.

Authentiq will generate a Client ID and the accompanying Client Secret for you to use.

1. Get your Client credentials (Client ID and Client Secret) at [Authentiq](https://www.authentiq.com/developers).

2. On your GitLab server, open the configuration file:

    For omnibus installation
    ```sh
    sudo editor /etc/gitlab/gitlab.rb
    ```

    For installations from source:

    ```sh
    sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
    ```
    
3. See [Initial OmniAuth Configuration](../../integration/omniauth.md#initial-omniauth-configuration) for initial settings to enable single sign-on and add Authentiq as an OAuth provider. 

4. Add the provider configuration for Authentiq:
    
    For Omnibus packages:

    ```ruby
    gitlab_rails['omniauth_providers'] = [
      {
        "name" => "authentiq",
        "app_id" => "YOUR_CLIENT_ID",
        "app_secret" => "YOUR_CLIENT_SECRET",
        "args" => { 
               "scope": 'aq:name email~rs address aq:push'
         }
      }
    ]
    ```
    
    For installations from source:
    
    ```yaml
    - { name: 'authentiq',
        app_id: 'YOUR_CLIENT_ID',
        app_secret: 'YOUR_CLIENT_SECRET',
        args: {
               scope: 'aq:name email~rs address aq:push'
              }
      }
    ```
    
    
5. The `scope` is set to request the user's name, email (required and signed), and permission to send push notifications to sign in on subsequent visits.
See [OmniAuth Authentiq strategy](https://github.com/AuthentiqID/omniauth-authentiq/wiki/Scopes,-callback-url-configuration-and-responses) for more information on scopes and modifiers.

6. Change `YOUR_CLIENT_ID` and `YOUR_CLIENT_SECRET` to the Client credentials you received in step 1.

7. Save the configuration file.

8. [Reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect if you installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be an Authentiq icon below the regular sign in form. Click the icon to begin the authentication process. 

- If the user has the Authentiq ID app installed in their iOS or Android device, they can scan the QR code, decide what personal details to share and sign in to your GitLab installation. 
- If not they will be prompted to download the app and then follow the procedure above. 

If everything goes right, the user will be returned to GitLab and will be signed in.