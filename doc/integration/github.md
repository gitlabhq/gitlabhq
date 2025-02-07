---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use GitHub as an OAuth 2.0 authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can integrate your GitLab instance with GitHub.com and GitHub Enterprise.
You can import projects from GitHub, or sign in to GitLab
with your GitHub credentials.

## Create an OAuth app in GitHub

To enable the GitHub OmniAuth provider, you need an OAuth 2.0 client ID and client
secret from GitHub:

1. Sign in to GitHub.
1. [Create an OAuth App](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app)
   and provide the following information:
   - The URL of your GitLab instance, such as `https://gitlab.example.com`.
   - The authorization callback URL, such as, `https://gitlab.example.com/users/auth`.
     Include the port number if your GitLab instance uses a non-default port.

### Check for security vulnerabilities

For some integrations, the [OAuth 2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/)
vulnerability can compromise GitLab accounts.
To mitigate this vulnerability, append `/users/auth` to the authorization
callback URL.

However, as far as we know, GitHub does not validate the subdomain part of the `redirect_uri`.
Therefore, a subdomain takeover, an XSS, or an open redirect on any subdomain of
your website could enable the covert redirect attack.

## Enable GitHub OAuth in GitLab

1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `github` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Edit the GitLab configuration file using the following information:

   | GitHub setting | Value in the GitLab configuration file | Description             |
   |----------------|----------------------------------------|-------------------------|
   | Client ID      | `YOUR_APP_ID`                          | OAuth 2.0 client ID     |
   | Client secret  | `YOUR_APP_SECRET`                      | OAuth 2.0 client secret |
   | URL            | `https://github.example.com/`          | GitHub deployment URL   |

   - For Linux package installations:

     1. Open the `/etc/gitlab/gitlab.rb` file.

        For GitHub.com, update the following section:

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            args: { scope: "user:email" }
          }
        ]
        ```

        For GitHub Enterprise, update the following section and replace
        `https://github.example.com/` with your GitHub URL:

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            url: "https://github.example.com/",
            args: { scope: "user:email" }
          }
        ]
        ```

     1. Save the file and [reconfigure](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)
        GitLab.

   - For self-compiled installations:

     1. Open the `config/gitlab.yml` file.

        For GitHub.com, update the following section:

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            args: { scope: 'user:email' } }
        ```

        For GitHub Enterprise, update the following section and replace
        `https://github.example.com/` with your GitHub URL:

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            url: "https://github.example.com/",
            args: { scope: 'user:email' } }
        ```

     1. Save the file and [restart](../administration/restart_gitlab.md#self-compiled-installations)
        GitLab.

1. Refresh the GitLab sign-in page. A GitHub icon should display below the
   sign-in form.

1. Select the icon. Sign in to GitHub and authorize the GitLab application.

## Troubleshooting

### Imports from GitHub Enterprise with a self-signed certificate fail

When you import projects from GitHub Enterprise using a self-signed
certificate, the imports fail.

To fix this issue, you must disable SSL verification:

1. Set `verify_ssl` to `false` in the configuration file.

   - For Linux package installations:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         name: "github",
         # label: "Provider name", # optional label for login button, defaults to "GitHub"
         app_id: "YOUR_APP_ID",
         app_secret: "YOUR_APP_SECRET",
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: "user:email" }
       }
     ]
     ```

   - For self-compiled installations:

     ```yaml
     - { name: 'github',
         # label: 'Provider name', # optional label for login button, defaults to "GitHub"
         app_id: 'YOUR_APP_ID',
         app_secret: 'YOUR_APP_SECRET',
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: 'user:email' } }
     ```

1. Change the global Git `sslVerify` option to `false` on the GitLab server.

   - For Linux package installations running [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) and later:

     ```ruby
     gitaly['gitconfig'] = [
        {key: "http.sslVerify", value: "false"},
     ]
     ```

   - For Linux package installations running GitLab 15.2 and earlier (legacy method):

     ```ruby
     omnibus_gitconfig['system'] = { "http" => ["sslVerify = false"] }
     ```

   - For self-compiled installations running [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) and later, edit the Gitaly configuration (`gitaly.toml`):

     ```toml
     [[git.config]]
     key = "http.sslVerify"
     value = "false"
     ```

   - For self-compiled installations running GitLab 15.2 and earlier (legacy method):

     ```shell
     git config --global http.sslVerify false
     ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)
   if you installed using the Linux package, or [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations)
   if you self-compiled your installation.

### Signing in using GitHub Enterprise returns a 500 error

This error can occur because of a network connectivity issue between your
GitLab instance and GitHub Enterprise.

To check for a connectivity issue:

1. Go to the [`production.log`](../administration/logs/_index.md#productionlog)
   on your GitLab server and look for the following error:

   ``` plaintext
   Faraday::ConnectionFailed (execution expired)
   ```

1. [Start the rails console](../administration/operations/rails_console.md#starting-a-rails-console-session)
   and run the following commands. Replace `<github_url>` with the URL of your
   GitHub Enterprise instance:

   ```ruby
   uri = URI.parse("https://<github_url>") # replace `GitHub-URL` with the real one here
   http = Net::HTTP.new(uri.host, uri.port)
   http.use_ssl = true
   http.verify_mode = 1
   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

1. If a similar `execution expired` error is returned, this confirms the error is
   caused by a connectivity issue. Make sure the GitLab server can reach
   your GitHub Enterprise instance.

### Signing in using your GitHub account without a pre-existing GitLab account is not allowed

When you sign in to GitLab, you get the following error:

```plaintext
Signing in using your GitHub account without a pre-existing
GitLab account is not allowed. Create a GitLab account first,
and then connect it to your GitHub account
```

To fix this issue, you must activate GitHub sign-in in GitLab:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Service sign-in** section, select **Connect to GitHub**.
