---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Atlassian Crowd as an authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Authenticate to GitLab using the Atlassian Crowd OmniAuth provider. Enabling
this provider also allows Crowd authentication for Git-over-https requests.

## Configure a new Crowd application

1. Choose 'Applications' in the top menu, then 'Add application'.
1. Go through the 'Add application' steps, entering the appropriate details.
   The screenshot below shows an example configuration.

   ![Final confirmation page in Crowd for application configuration](img/crowd_application_v9_0.png)

## Configure GitLab

1. On your GitLab server, open the configuration file.

   - Linux package installations:

     ```shell
       sudo editor /etc/gitlab/gitlab.rb
     ```

   - Self-compiled installations:

     ```shell
       cd /home/git/gitlab

       sudo -u git -H editor config/gitlab.yml
     ```

1. Configure the [common settings](../../integration/omniauth.md#configure-common-settings)
   to add `crowd` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration:

   - Linux package installations:

     ```ruby
       gitlab_rails['omniauth_providers'] = [
         {
           name: "crowd",
           args: {
             crowd_server_url: "CROWD_SERVER_URL",
             application_name: "YOUR_APP_NAME",
             application_password: "YOUR_APP_PASSWORD"
           }
         }
       ]
     ```

   - Self-compiled installations:

     ```yaml
        - { name: 'crowd',
            args: {
              crowd_server_url: 'CROWD_SERVER_URL',
              application_name: 'YOUR_APP_NAME',
              application_password: 'YOUR_APP_PASSWORD' } }
     ```

1. Change `CROWD_SERVER_URL` to the [base URL of your Crowd server](https://confluence.atlassian.com/crowdkb/how-to-change-the-crowd-base-url-245827278.html).
1. Change `YOUR_APP_NAME` to the application name from Crowd applications page.
1. Change `YOUR_APP_PASSWORD` to the application password you've set.
1. Save the configuration file.
1. [Reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation) (Linux package installations) or
   [restart](../restart_gitlab.md#self-compiled-installations) (self-compiled installations) for the changes to take effect.

On the sign in page there should now be a Crowd tab in the sign in form.

## Troubleshooting

### Error: "could not authorize you from Crowd because invalid credentials"

This error sometimes occurs when a user attempts to authenticate with Crowd. The
Crowd administrator should consult the Crowd log file to know the exact cause of
this error message.

Ensure the Crowd users who must sign in to GitLab are authorized to the
[application](#configure-a-new-crowd-application) in the **Authorization** step.
This could be verified by trying "Authentication test" for Crowd (as of 2.11).

![Authorization stage settings in Crowd](img/crowd_application_authorisation_v10_4.png)
