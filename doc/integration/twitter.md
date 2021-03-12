---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Twitter OAuth2 OmniAuth Provider **(FREE)**

To enable the Twitter OmniAuth provider you must register your application with Twitter. Twitter generates a client ID and secret key for you to use.

1. Sign in to [Twitter Application Management](https://developer.twitter.com/apps).

1. Select "Create new app"

1. Fill in the application details.
   - Name: This can be anything. Consider something like `<Organization>'s GitLab` or `<Your Name>'s GitLab` or
   something else descriptive.
   - Description: Create a description.
   - Website: The URL to your GitLab installation. `https://gitlab.example.com`
   - Callback URL: `https://gitlab.example.com/users/auth/twitter/callback`
   - Agree to the "Developer Agreement".

   ![Twitter App Details](img/twitter_app_details.png)

1. Select "Create your Twitter application."

1. Select the "Settings" tab.

1. Underneath the Callback URL check the box next to "Allow this application to be used to Sign in with Twitter."

1. Select "Update settings" at the bottom to save changes.

1. Select the "Keys and Access Tokens" tab.

1. You should now see an API key and API secret (see screenshot). Keep this page open as you continue configuration.

   ![Twitter app](img/twitter_app_api_keys.png)

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
         "name" => "twitter",
         "app_id" => "YOUR_APP_ID",
         "app_secret" => "YOUR_APP_SECRET"
       }
     ]
   ```

   For installations from source:

   ```yaml
   - { name: 'twitter',
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET' }
   ```

1. Change 'YOUR_APP_ID' to the API key from Twitter page in step 11.

1. Change 'YOUR_APP_SECRET' to the API secret from the Twitter page in step 11.

1. Save the configuration file.

1. [Reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart GitLab](../administration/restart_gitlab.md#installations-from-source) for the changes to take effect if you
   installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be a Twitter icon below the regular sign in form. Click the icon to begin the authentication process. Twitter asks the user to sign in and authorize the GitLab application. If everything goes well the user is returned to GitLab and signed in.
