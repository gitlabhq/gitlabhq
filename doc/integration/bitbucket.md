# Integrate your GitLab server with Bitbucket Cloud

NOTE: **Note:**
You need to [enable OmniAuth](omniauth.md) in order to use this.

Import projects from Bitbucket.org and login to your GitLab instance with your
Bitbucket.org account.

## Overview

You can set up Bitbucket.org as an OAuth2 provider so that you can use your
credentials to authenticate into GitLab or import your projects from
Bitbucket.org.

- To use Bitbucket.org as an OmniAuth provider, follow the [Bitbucket OmniAuth
  provider](#bitbucket-omniauth-provider) section.
- To import projects from Bitbucket, follow both the
  [Bitbucket OmniAuth provider](#bitbucket-omniauth-provider) and
  [Bitbucket project import](#bitbucket-project-import) sections.

## Bitbucket OmniAuth provider

> **Note:**
GitLab 8.15 significantly simplified the way to integrate Bitbucket.org with
GitLab. You are encouraged to upgrade your GitLab instance if you haven't done so
already. If you're using GitLab 8.14 or below, [use the previous integration
docs](https://gitlab.com/gitlab-org/gitlab/blob/8-14-stable-ee/doc/integration/bitbucket.md).

To enable the Bitbucket OmniAuth provider you must register your application
with Bitbucket.org. Bitbucket will generate an application ID and secret key for
you to use.

1. Sign in to [Bitbucket.org](https://bitbucket.org).
1. Navigate to your individual user settings (**Bitbucket settings**) or a team's
   settings (**Manage team**), depending on how you want the application registered.
   It does not matter if the application is registered as an individual or a
   team, that is entirely up to you.
1. Select **OAuth** in the left menu under "Access Management".
1. Select **Add consumer**.
1. Provide the required details:

   | Item | Description |
   | :--- | :---------- |
   | **Name** | This can be anything. Consider something like `<Organization>'s GitLab` or `<Your Name>'s GitLab` or something else descriptive. |
   | **Application description** | Fill this in if you wish. |
   | **Callback URL** | The URL to your GitLab installation, e.g., `https://gitlab.example.com/users/auth`. |
   | **URL** | The URL to your GitLab installation, e.g., `https://gitlab.example.com`. |

   NOTE: Be sure to append `/users/auth` to the end of the callback URL
   to prevent a [OAuth2 convert
   redirect](http://tetraph.com/covert_redirect/) vulnerability.

   NOTE: Starting in GitLab 8.15, you MUST specify a callback URL, or you will
   see an "Invalid redirect_uri" message. For more details, see [the
   Bitbucket documentation](https://confluence.atlassian.com/bitbucket/oauth-faq-338365710.html).

   And grant at least the following permissions:

   ```
   Account: Email, Read
   Projects: Read
   Repositories: Read
   Pull Requests: Read
   Issues: Read
   Wiki: Read and Write
   ```

   ![Bitbucket OAuth settings page](img/bitbucket_oauth_settings_page.png)

1. Select **Save**.
1. Select your newly created OAuth consumer and you should now see a Key and
   Secret in the list of OAuth consumers. Keep this page open as you continue
   the configuration.

   ![Bitbucket OAuth key](img/bitbucket_oauth_keys.png)

1. On your GitLab server, open the configuration file:

   ```
   # For Omnibus packages
   sudo editor /etc/gitlab/gitlab.rb

   # For installations from source
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Add the Bitbucket provider configuration:

   For Omnibus packages:

   ```ruby
   gitlab_rails['omniauth_enabled'] = true

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

   ---

   Where `BITBUCKET_APP_KEY` is the Key and `BITBUCKET_APP_SECRET` the Secret
   from the Bitbucket application page.

1. Save the configuration file.
1. For the changes to take effect, [reconfigure GitLab][] if you installed via
   Omnibus, or [restart][] if installed from source.

On the sign in page there should now be a Bitbucket icon below the regular sign
in form. Click the icon to begin the authentication process. Bitbucket will ask
the user to sign in and authorize the GitLab application. If everything goes
well, the user will be returned to GitLab and will be signed in.

## Bitbucket project import

Once the above configuration is set up, you can use Bitbucket to sign into
GitLab and [start importing your projects][bb-import].

If you want to import projects from Bitbucket, but don't want to enable signing in,
you can [disable Sign-Ins in the admin panel](omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources).

[bb-import]: ../user/project/import/bitbucket.md
[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: ../administration/restart_gitlab.md#installations-from-source
