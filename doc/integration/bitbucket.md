---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Integrate your GitLab server with Bitbucket Cloud **(FREE)**

NOTE:
Starting from GitLab 11.4, OmniAuth is enabled by default. If you're using an
earlier version, you must explicitly enable it.

You can set up Bitbucket.org as an OAuth2 provider to use your
Bitbucket.org account credentials to sign in to GitLab, or import your projects from
Bitbucket.org.

- To use Bitbucket.org as an OmniAuth provider, follow the
  [Bitbucket OmniAuth provider](#bitbucket-omniauth-provider) section.
- To import projects from Bitbucket, follow both the
  [Bitbucket OmniAuth provider](#bitbucket-omniauth-provider) and
  [Bitbucket project import](#bitbucket-project-import) sections.

## Bitbucket OmniAuth provider

To enable the Bitbucket OmniAuth provider you must register your application
with Bitbucket.org. Bitbucket generates an application ID and secret key for
you to use.

WARNING:
To help prevent an [OAuth 2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/)
vulnerability in which users' GitLab accounts could be compromised, append `/users/auth`
to the end of the Bitbucket authorization callback URL.

1. Sign in to [Bitbucket.org](https://bitbucket.org).
1. Navigate to your individual user settings (**Bitbucket settings**) or a team's
   settings (**Manage team**), depending on how you want the application registered.
   It does not matter if the application is registered as an individual or a
   team, that is entirely up to you.
1. In the left menu under **Access Management**, select **OAuth**.
1. Select **Add consumer**.
1. Provide the required details:

   - **Name:** This can be anything. Consider something like `<Organization>'s GitLab`
     or `<Your Name>'s GitLab` or something else descriptive.
   - **Application description:** *(Optional)* Fill this in if you wish.
   - **Callback URL:** (Required in GitLab versions 8.15 and greater)
     The URL to your GitLab installation, such as
     `https://gitlab.example.com/users/auth`.
     Leaving this field empty
     [results in an `Invalid redirect_uri` message](https://confluence.atlassian.com/bitbucket/oauth-faq-338365710.html).
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

   ![Bitbucket OAuth settings page](img/bitbucket_oauth_settings_page.png)

1. Select **Save**.
1. Select your newly created OAuth consumer, and you should now see a **Key** and
   **Secret** in the list of OAuth consumers. Keep this page open as you continue
   the configuration.

   ![Bitbucket OAuth key](img/bitbucket_oauth_keys.png)

1. On your GitLab server, open the configuration file:

   ```shell
   # For Omnibus packages
   sudo editor /etc/gitlab/gitlab.rb

   # For installations from source
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Add the Bitbucket provider configuration:

   For Omnibus packages:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       "name" => "bitbucket",
       "app_id" => "BITBUCKET_APP_KEY",
       "app_secret" => "BITBUCKET_APP_SECRET",
       "url" => "https://bitbucket.org/"
     }
   ]
   ```

   For installations from source:

   ```yaml
   omniauth:
     enabled: true
     providers:
       - { name: 'bitbucket',
           app_id: 'BITBUCKET_APP_KEY',
           app_secret: 'BITBUCKET_APP_SECRET',
           url: 'https://bitbucket.org/' }
   ```

   Where `BITBUCKET_APP_KEY` is the Key and `BITBUCKET_APP_SECRET` the Secret
   from the Bitbucket application page.

1. Save the configuration file.
1. For the changes to take effect, [reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   if you installed using Omnibus GitLab, or [restart](../administration/restart_gitlab.md#installations-from-source)
   if you installed from source.

On the sign-in page there should now be a Bitbucket icon below the regular
sign-in form. Click the icon to begin the authentication process. Bitbucket asks
the user to sign in and authorize the GitLab application. If successful, the user
is returned to GitLab and signed in.

## Bitbucket project import

After the above configuration is set up, you can use Bitbucket to sign into
GitLab and [start importing your projects](../user/project/import/bitbucket.md).

If you want to import projects from Bitbucket, but don't want to enable signing in,
you can [disable Sign-Ins in the admin panel](omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources).
