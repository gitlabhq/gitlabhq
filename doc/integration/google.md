---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Google OAuth 2.0 as an OAuth 2.0 authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To enable the Google OAuth 2.0 OmniAuth provider you must register your application
with Google. Google generates a client ID and secret key for you to use.

To enable Google OAuth, you must configure the:

- Google Cloud Resource Manager
- Google API Console
- GitLab server

## Configure the Google Cloud Resource Manager

1. Go to the [Google Cloud Resource Manager](https://console.cloud.google.com/cloud-resource-manager).
1. Select **CREATE PROJECT**.
1. In **Project name**, enter `GitLab`.
1. In **Project ID**, Google provides a randomly generated project ID by default.
   You can use this randomly generated ID or create a new one. If you create a new
   ID, it must be unique to all Google Developer registered applications.

To see your new project in the list, refresh the page.

## Configure the Google API Console

1. Go to the [Google API Console](https://console.developers.google.com/apis/dashboard).
1. In the upper-left corner, select your previously created project.
1. Select **OAuth consent screen** and complete the fields.
1. Select **Credentials > Create credentials > OAuth client ID**.
1. Complete the fields:
   - **Application type**: Select **Web application**.
   - **Name**: Use the default name or enter your own.
   - **Authorized JavaScript origins**: Enter `https://gitlab.example.com`.
   - **Authorized redirect URIs**: Enter your domain name followed by the
     callback URIs one at a time:

     ```plaintext
     https://gitlab.example.com/users/auth/google_oauth2/callback
     https://gitlab.example.com/-/google_api/auth/callback
     ```

1. You should see a client ID and client secret. Note them down
   or keep this page open as you need them later.
1. To enable projects to access [Google Kubernetes Engine](../user/infrastructure/clusters/_index.md),
   you must also enable the:
   - Google Kubernetes Engine API
   - Cloud Resource Manager API
   - Cloud Billing API

   To do so:

   1. Go to the [Google API Console](https://console.developers.google.com/apis/dashboard).
   1. Select **ENABLE APIS AND SERVICES** at the top of the page.
   1. Find each of the above APIs. On the page for the API, select **ENABLE**.
      It may take a few minutes for the API to be fully functional.

## Configure the GitLab server

1. Open the configuration file.

   For Linux package installations:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For self-compiled installations:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `google_oauth2` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. Add the provider configuration.

   For Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "google_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Google"
       app_id: "<YOUR_APP_ID>",
       app_secret: "<YOUR_APP_SECRET>",
       args: { access_type: "offline", approval_prompt: "" }
     }
   ]
   ```

   For self-compiled installations:

   ```yaml
   - { name: 'google_oauth2',
       # label: 'Provider name', # optional label for login button, defaults to "Google"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { access_type: 'offline', approval_prompt: '' } }
   ```

1. Replace `<YOUR_APP_ID>` with the client ID from the Google Developer page.
1. Replace `<YOUR_APP_SECRET>` with the client secret from the Google Developer page.
1. Make sure that you configure GitLab to use a fully-qualified domain name, as
   Google doesn't accept raw IP addresses.

   For Linux package installations:

   ```ruby
   external_url 'https://gitlab.example.com'
   ```

   For self-compiled installations:

   ```yaml
   gitlab:
     host: https://gitlab.example.com
   ```

1. Save the configuration file.
1. For the changes to take effect:
   - If you installed using the Linux package, [reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - If you self-compiled your installation, [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations).

On the sign in page there should now be a Google icon below the regular sign in
form. Select the icon to begin the authentication process. Google asks the
user to sign in and authorize the GitLab application. If everything goes well
the user is returned to GitLab and is signed in.
