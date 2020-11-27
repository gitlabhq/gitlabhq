---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Integrate your GitLab instance with GitHub

You can integrate your GitLab instance with GitHub.com and GitHub Enterprise to
enable users to import projects from GitHub or sign in to your GitLab instance
with your GitHub account.

## Enabling GitHub OAuth

To enable the GitHub OmniAuth provider, you need an OAuth 2 Client ID and Client Secret from GitHub. To get these credentials, sign into GitHub and follow their procedure for [Creating an OAuth App](https://developer.github.com/apps/building-oauth-apps/creating-an-oauth-app/).

When you create an OAuth 2 app in GitHub, you need the following information:

- The URL of your GitLab instance, such as `https://gitlab.example.com`.
- The authorization callback URL; in this case, `https://gitlab.example.com/users/auth`. Include the port number if your GitLab instance uses a non-default port.

NOTE: **Note:**
To prevent an [OAuth2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/) vulnerability, append `/users/auth` to the end of the GitHub authorization callback URL.

See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings.

After you have configured the GitHub provider, you need the following information, which you must substitute in the GitLab configuration file, in the steps shown next.

| Setting from GitHub  | Substitute in the GitLab configuration file  | Description |
|:---------------------|:---------------------------------------------|:------------|
| Client ID            | `YOUR_APP_ID`                                | OAuth 2 Client ID |
| Client Secret        | `YOUR_APP_SECRET`                            | OAuth 2 Client Secret |
| URL                  | `https://github.example.com/`                | GitHub Deployment URL |

Follow these steps to incorporate the GitHub OAuth 2 app in your GitLab server:

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   For GitHub.com:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       "name" => "github",
       "app_id" => "YOUR_APP_ID",
       "app_secret" => "YOUR_APP_SECRET",
       "args" => { "scope" => "user:email" }
     }
   ]
   ```

   For GitHub Enterprise:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       "name" => "github",
       "app_id" => "YOUR_APP_ID",
       "app_secret" => "YOUR_APP_SECRET",
       "url" => "https://github.example.com/",
       "args" => { "scope" => "user:email" }
     }
   ]
   ```

   **Replace `https://github.example.com/` with your GitHub URL.**

1. Save the file and [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

---

**For installations from source**

1. Navigate to your repository and edit `config/gitlab.yml`:

   For GitHub.com:

   ```yaml
   - { name: 'github', app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { scope: 'user:email' } }
   ```

   For GitHub Enterprise:

   ```yaml
   - { name: 'github',
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       url: "https://github.example.com/",
       args: { scope: 'user:email' } }
   ```

   **Replace `https://github.example.com/` with your GitHub URL.**

1. Save the file and [restart](../administration/restart_gitlab.md#installations-from-source) GitLab for the changes to take effect.

---

1. Refresh the GitLab sign in page. You should now see a GitHub icon below the regular sign in form.

1. Click the icon to begin the authentication process. GitHub asks the user to sign in and authorize the GitLab application.

## GitHub Enterprise with self-signed Certificate

If you are attempting to import projects from GitHub Enterprise with a self-signed
certificate and the imports are failing, you must disable SSL verification.
It should be disabled by adding `verify_ssl` to `false` in the provider configuration
and changing the global Git `sslVerify` option to `false` in the GitLab server.

For Omnibus package:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    "name" => "github",
    "app_id" => "YOUR_APP_ID",
    "app_secret" => "YOUR_APP_SECRET",
    "url" => "https://github.example.com/",
    "verify_ssl" => false,
    "args" => { "scope" => "user:email" }
  }
]
```

You must also disable Git SSL verification on the server hosting GitLab.

```ruby
omnibus_gitconfig['system'] = { "http" => ["sslVerify = false"] }
```

For installation from source:

```yaml
- { name: 'github',
    app_id: 'YOUR_APP_ID',
    app_secret: 'YOUR_APP_SECRET',
    url: "https://github.example.com/",
    verify_ssl: false,
    args: { scope: 'user:email' } }
```

You must also disable Git SSL verification on the server hosting GitLab.

```shell
git config --global http.sslVerify false
```

For the changes to take effect, [reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) if you installed
via Omnibus, or [restart GitLab](../administration/restart_gitlab.md#installations-from-source) if you installed from source.

## Troubleshooting

### Error 500 when trying to sign in to GitLab via GitHub Enterprise

Check the [`production.log`](../administration/logs.md#productionlog)
on your GitLab server to obtain further details. If you are getting the error like
`Faraday::ConnectionFailed (execution expired)` in the log, there may be a connectivity issue
between your GitLab instance and GitHub Enterprise. To verify it, [start the rails console](../administration/operations/rails_console.md#starting-a-rails-console-session)
and run the commands below replacing `<github_url>` with the URL of your GitHub Enterprise instance:

```ruby
uri = URI.parse("https://<github_url>") # replace `GitHub-URL` with the real one here
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = 1
response = http.request(Net::HTTP::Get.new(uri.request_uri))
```

If you are getting a similar `execution expired` error, it confirms the theory about the
network connectivity. In that case, make sure that the GitLab server is able to reach your
GitHub enterprise instance.

### Signing in using your GitHub account without a pre-existing GitLab account is not allowed

If you're getting the message `Signing in using your GitHub account without a pre-existing
GitLab account is not allowed. Create a GitLab account first, and then connect it to your
GitHub account` when signing in, in GitLab:

1. Go to your **Profile > Account**.
1. Under the "Social sign-in" section, click **Connect** near the GitHub icon.

After that, you should be able to sign in via GitHub successfully.
