---
type: reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Atlassian OmniAuth Provider **(FREE SELF)**

To enable the Atlassian OmniAuth provider for passwordless authentication you must register an application with Atlassian.

## Atlassian application registration

1. Go to <https://developer.atlassian.com/console/myapps/> and sign-in with the Atlassian
   account that will administer the application.

1. Click **Create a new app**.

1. Choose an App Name, such as 'GitLab', and click **Create**.

1. Note the `Client ID` and `Secret` for the [GitLab configuration](#gitlab-configuration) steps.

1. In the left sidebar under **APIS AND FEATURES**, click **OAuth 2.0 (3LO)**.

1. Enter the GitLab callback URL using the format `https://gitlab.example.com/users/auth/atlassian_oauth2/callback` and click **Save changes**.

1. Click **+ Add** in the left sidebar under **APIS AND FEATURES**.

1. Click **Add** for **Jira platform REST API** and then **Configure**.

1. Click **Add** next to the following scopes:
    - **View Jira issue data**
    - **View user profiles**
    - **Create and manage issues**

## GitLab configuration

1. On your GitLab server, open the configuration file:

   For Omnibus GitLab installations:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. See [Initial OmniAuth Configuration](../../integration/omniauth.md#initial-omniauth-configuration) for initial settings to enable single sign-on and add `atlassian_oauth2` as an OAuth provider.

1. Add the provider configuration for Atlassian:

   For Omnibus GitLab installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "atlassian_oauth2",
       app_id: "YOUR_CLIENT_ID",
       app_secret: "YOUR_CLIENT_SECRET",
       args: { scope: 'offline_access read:jira-user read:jira-work', prompt: 'consent' }
     }
   ]
   ```

   For installations from source:

   ```yaml
   - name: "atlassian_oauth2",
     app_id: "YOUR_CLIENT_ID",
     app_secret: "YOUR_CLIENT_SECRET",
     args: { scope: 'offline_access read:jira-user read:jira-work', prompt: 'consent' }
   ```

1. Change `YOUR_CLIENT_ID` and `YOUR_CLIENT_SECRET` to the Client credentials you received in [application registration](#atlassian-application-registration) steps.

1. Save the configuration file.

1. [Reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect if you installed GitLab via Omnibus or from source respectively.

On the sign-in page there should now be an Atlassian icon below the regular sign in form. Click the icon to begin the authentication process.

If everything goes right, the user is signed in to GitLab using their Atlassian credentials.
