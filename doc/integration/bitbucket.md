---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Integrate your GitLab server with Bitbucket Cloud
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can set up Bitbucket.org as an OAuth 2.0 provider to use your Bitbucket.org
account credentials to sign in to GitLab. You can also import your projects from
Bitbucket.org.

- To use Bitbucket.org as an OmniAuth provider, follow the
  [Bitbucket OmniAuth provider](#use-bitbucket-as-an-oauth-20-authentication-provider) section.
- To import projects from Bitbucket, follow both the
  [Bitbucket OmniAuth provider](#use-bitbucket-as-an-oauth-20-authentication-provider) and
  [Bitbucket project import](#bitbucket-project-import) sections.

## Use Bitbucket as an OAuth 2.0 authentication provider

To enable the Bitbucket OmniAuth provider you must register your application
with Bitbucket.org. Bitbucket generates an application ID and secret key for
you to use.

1. Sign in to [Bitbucket.org](https://bitbucket.org).
1. Go to your individual user settings (**Bitbucket settings**) or a team's
   settings (**Manage team**), depending on how you want to register the application.
   It does not matter if the application is registered as an individual or a
   team, that is entirely up to you.
1. In the left menu under **Access Management**, select **OAuth**.
1. Select **Add consumer**.
1. Provide the required details:

   - **Name:** This can be anything. Consider something like `<Organization>'s GitLab`
     or `<Your Name>'s GitLab` or something else descriptive.
   - **Application description:** Optional. Fill this in if you wish.
   - **Callback URL:** (Required in GitLab versions 8.15 and greater)
     The URL to your GitLab installation, such as
     `https://gitlab.example.com/users/auth`.
     Leaving this field empty
     results in an `Invalid redirect_uri` message.

     WARNING:
     To help prevent an [OAuth 2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/)
     vulnerability in which users' GitLab accounts could be compromised, append `/users/auth`
     to the end of the Bitbucket authorization callback URL.

   - **URL:** The URL to your GitLab installation, such as `https://gitlab.example.com`.

1. Grant at least the following permissions:

   ```plaintext
   Account: Email, Read
   Projects: Read
   Repositories: Read
   Pull Requests: Read
   Issues: Read
   Wiki: Read and Write
   ```

   ![Bitbucket OAuth settings page](img/bitbucket_oauth_settings_page_v8_15.png)

1. Select **Save**.
1. Select your newly created OAuth consumer, and you should now see a **Key** and
   **Secret** in the list of OAuth consumers. Keep this page open as you continue
   the configuration.

   ![Bitbucket OAuth key](img/bitbucket_oauth_keys_v8_12.png)

1. On your GitLab server, open the configuration file:

   ```shell
   # For Omnibus packages
   sudo editor /etc/gitlab/gitlab.rb

   # For installations from source
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Add the Bitbucket provider configuration:

   For Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "bitbucket",
       # label: "Provider name", # optional label for login button, defaults to "Bitbucket"
       app_id: "<bitbucket_app_key>",
       app_secret: "<bitbucket_app_secret>",
       url: "https://bitbucket.org/",
       args: { redirect_uri: "https://gitlab.example.com/users/auth/" },
     }
   ]
   ```

   For self-compiled installations:

   ```yaml
   omniauth:
     enabled: true
     providers:
       - { name: 'bitbucket',
           # label: 'Provider name', # optional label for login button, defaults to "Bitbucket"
           app_id: '<bitbucket_app_key>',
           app_secret: '<bitbucket_app_secret>',
           url: 'https://bitbucket.org/',
           args: { redirect_uri: "https://gitlab.example.com/users/auth/" },
         }
   ```

   Where `<bitbucket_app_key>` is the **Key** and `<bitbucket_app_secret>` the **Secret**
   from the Bitbucket application page.

1. Save the configuration file.
1. For the changes to take effect, [reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)
   if you installed using the Linux package, or [restart](../administration/restart_gitlab.md#self-compiled-installations)
   if you self-compiled your installation.

On the sign-in page there should now be a Bitbucket icon below the regular
sign-in form. Select the icon to begin the authentication process. Bitbucket asks
the user to sign in and authorize the GitLab application. If successful, the user
is returned to GitLab and signed in.

NOTE:
For multi-node architectures, the Bitbucket provider configuration must also be included on the Sidekiq nodes to be able to import projects.

## Bitbucket project import

After the above configuration is set up, you can use Bitbucket to sign in to
GitLab and [start importing your projects](../user/project/import/bitbucket.md).

If you want to import projects from Bitbucket, but don't want to enable signing in,
you can [disable Sign-Ins in the **Admin** area](omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources).
