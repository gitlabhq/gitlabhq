---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Atlassian as an OAuth 2.0 authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To enable the Atlassian OmniAuth provider for passwordless authentication you must register an application with Atlassian.

## Atlassian application registration

1. Go to the [Atlassian developer console](https://developer.atlassian.com/console/myapps/) and sign-in with the Atlassian
   account to administer the application.
1. Select **Create a new app**.
1. Choose an App Name, such as 'GitLab', and select **Create**.
1. Note the `Client ID` and `Secret` for the [GitLab configuration](#gitlab-configuration) steps.
1. On the left sidebar under **APIS AND FEATURES**, select **OAuth 2.0 (3LO)**.
1. Enter the GitLab callback URL using the format `https://gitlab.example.com/users/auth/atlassian_oauth2/callback` and select **Save changes**.
1. Select **+ Add** in the left sidebar under **APIS AND FEATURES**.
1. Select **Add** for **Jira platform REST API** and then **Configure**.
1. Select **Add** next to the following scopes:
   - **View Jira issue data**
   - **View user profiles**
   - **Create and manage issues**

## GitLab configuration

1. On your GitLab server, open the configuration file:

   For Linux package installations:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For self-compiled installations:

   ```shell
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Configure the [common settings](../../integration/omniauth.md#configure-common-settings)
   to add `atlassian_oauth2` as a single sign-on provider. This enables
   Just-In-Time account provisioning for users who do not have an existing
   GitLab account.
1. Add the provider configuration for Atlassian:

   For Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
     }
   ]
   ```

   For self-compiled installations:

   ```yaml
   - { name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
    }
   ```

1. Change `<your_client_id>` and `<your_client_secret>` to the Client credentials you received during [application registration](#atlassian-application-registration).
1. Save the configuration file.

1. For the changes to take effect:
   - If you installed using the Linux package, [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
   - If you self-compiled your installation, [restart GitLab](../restart_gitlab.md#self-compiled-installations).

On the sign-in page there should now be an Atlassian icon below the regular sign in form. Select the icon to begin the authentication process.

If everything goes right, the user is signed in to GitLab using their Atlassian credentials.
