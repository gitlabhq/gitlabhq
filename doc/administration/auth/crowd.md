---
type: reference
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Atlassian Crowd OmniAuth provider (deprecated) **(FREE SELF)**

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369117) in GitLab 15.3 and is planned for
removal in 17.0.

Authenticate to GitLab using the Atlassian Crowd OmniAuth provider. Enabling
this provider also allows Crowd authentication for Git-over-https requests.

## Configure a new Crowd application

1. Choose 'Applications' in the top menu, then 'Add application'.
1. Go through the 'Add application' steps, entering the appropriate details.
   The screenshot below shows an example configuration.

   ![Example Crowd application configuration](img/crowd_application.png)

## Configure GitLab

1. On your GitLab server, open the configuration file.

   **Omnibus:**

   ```shell
     sudo editor /etc/gitlab/gitlab.rb
   ```

   **Source:**

   ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
   ```

1. Configure the [common settings](../../integration/omniauth.md#configure-common-settings)
   to add `crowd` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration:

   **Omnibus:**

   ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         name: "crowd",
         # label: "Provider name", # optional label for login button, defaults to "Crowd"
         args: {
           crowd_server_url: "CROWD_SERVER_URL",
           application_name: "YOUR_APP_NAME",
           application_password: "YOUR_APP_PASSWORD"
         }
       }
     ]
   ```

   **Source:**

   ```yaml
      - { name: 'crowd',
          # label: 'Provider name', # optional label for login button, defaults to "Crowd"
          args: {
            crowd_server_url: 'CROWD_SERVER_URL',
            application_name: 'YOUR_APP_NAME',
            application_password: 'YOUR_APP_PASSWORD' } }
   ```

1. Change `CROWD_SERVER_URL` to the [base URL of your Crowd server](https://confluence.atlassian.com/crowdkb/how-to-change-the-crowd-base-url-245827278.html).
1. Change `YOUR_APP_NAME` to the application name from Crowd applications page.
1. Change `YOUR_APP_PASSWORD` to the application password you've set.
1. Save the configuration file.
1. [Reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) (Omnibus GitLab) or [restart](../restart_gitlab.md#installations-from-source) (source installations) for
   the changes to take effect.

On the sign in page there should now be a Crowd tab in the sign in form.

## Troubleshooting

### Error: "could not authorize you from Crowd because invalid credentials"

This error sometimes occurs when a user attempts to authenticate with Crowd. The
Crowd administrator should consult the Crowd log file to know the exact cause of
this error message.

Ensure the Crowd users who must sign in to GitLab are authorized to the
[application](#configure-a-new-crowd-application) in the **Authorization** step.
This could be verified by trying "Authentication test" for Crowd (as of 2.11).

![Example Crowd application authorization configuration](img/crowd_application_authorisation.png)
