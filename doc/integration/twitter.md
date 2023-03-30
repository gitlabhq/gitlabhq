---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Twitter OAuth 1.0a OmniAuth Provider **(FREE SELF)**

NOTE:
Twitter OAuth 2.0 support is [not supported](https://gitlab.com/gitlab-org/gitlab/-/issues/366213).

To enable the Twitter OmniAuth provider you must register your application with
Twitter. Twitter generates a client ID and secret key for you to use.

## Create a new Twitter application

1. Sign in to [Twitter Application Management](https://developer.twitter.com/apps).

1. Select **Create new app**.

1. Fill in the application details.
   - **Name**: This can be anything. Consider something like `<Organization>'s GitLab`, `<Your Name>'s GitLab` or
   something else descriptive.
   - **Description**: Create a description.
   - **Website**: The URL to your GitLab installation. For example, `https://gitlab.example.com`
   - **Callback URL**: `https://gitlab.example.com/users/auth/twitter/callback`
   - **Developer Agreement**: Select **Yes, I agree**.

   ![Twitter App Details](img/twitter_app_details.png)

1. Select **Create your Twitter application**.

## Configure the application settings

1. Select the **Settings** tab.

1. Underneath the **Callback URL**, select the **Allow this application to be used to Sign in with Twitter** checkbox.

1. Select **Update settings** to save the changes.

1. Select the **Keys and Access Tokens** tab.

1. Find your **API key** and **API secret**. Keep this tab open as you continue configuration.

   ![Twitter app](img/twitter_app_api_keys.png)

## Configure your application on the GitLab server

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

1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `twitter` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration.

   For Omnibus package:

   ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         name: "twitter",
         # label: "Provider name", # optional label for login button, defaults to "Twitter"
         app_id: "<your_api_key>",
         app_secret: "<your_api_secret>"
       }
     ]
   ```

   For installations from source:

   ```yaml
   - { name: 'twitter',
       # label: 'Provider name', # optional label for login button, defaults to "Twitter"
       app_id: '<your_api_key>',
       app_secret: '<your_api_secret>' }
   ```

1. Change `<your_api_key>` to the API key from the Twitter **Keys and Access Tokens** tab.

1. Change `<your_api_secret>` to the API secret from the Twitter **Keys and Access Tokens** tab.

1. Save the configuration file.

1. For the changes to take effect, if you installed:

   - Using Omnibus, [reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure).
   - From source, [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

On the sign-in page, find the Twitter option below the regular sign-in form. Select the option to begin the authentication process. Twitter asks you to sign in and authorize the GitLab application. After authorization,
you are returned to GitLab and signed in.
