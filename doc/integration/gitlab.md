---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Integrate your server with GitLab.com
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Import projects from GitLab.com and login to your GitLab instance with your GitLab.com account.

To enable the GitLab.com OmniAuth provider you must register your application with GitLab.com.
GitLab.com generates an application ID and secret key for you to use.

1. Sign in to GitLab.com.
1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Applications**.
1. Provide the required details for **Add new application**.
   - Name: This can be anything. Consider something like `<Organization>'s GitLab` or `<Your Name>'s GitLab` or something else descriptive.
   - Redirect URI:

     ```plaintext
     # You can also use a non-SSL URL, but you should use SSL URLs.
     https://your-gitlab.example.com/import/gitlab/callback
     https://your-gitlab.example.com/users/auth/gitlab/callback
     ```

   The first link is required for the importer and second for authentication.

   If you:

   - Plan to use the importer, you can leave scopes as they are.
   - Only want to use this application for authentication, we recommend using a more minimal set of scopes. `read_user` is sufficient.

1. Select **Save application**.
1. You should now see an **Application ID** and **Secret**. Keep this page open as you continue
   configuration.
1. On your GitLab server, open the configuration file.

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
   to add `gitlab` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. Add the provider configuration:

   For Linux package installations authenticating against **GitLab.com**:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       # label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user" } # optional: defaults to the scopes of the application
     }
   ]
   ```

   Or, for Linux package installations authenticating against a different GitLab instance:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user", # optional: defaults to the scopes of the application
               client_options: { site: "https://gitlab.example.com" } }
     }
   ]
   ```

   For self-compiled installations authenticating against **GitLab.com**:

   ```yaml
   - { name: 'gitlab',
       # label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
   ```

   Or, for self-compiled installations to authenticate against a different GitLab instance:

   ```yaml
   - { name: 'gitlab',
       label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { "client_options": { "site": 'https://gitlab.example.com' } }
   ```

   NOTE:
   In GitLab 15.1 and earlier, the `site` parameter requires an `/api/v4` suffix.
   We recommend you drop this suffix after you upgrade to GitLab 15.2 or later.

1. Change `'YOUR_APP_ID'` to the Application ID from the GitLab.com application page.
1. Change `'YOUR_APP_SECRET'` to the secret from the GitLab.com application page.
1. Save the configuration file.
1. Implement these changes by using the appropriate method:
   - For Linux package installations, [reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - For self-compiled installations, [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations).

On the sign-in page, there should now be a GitLab.com icon following the
regular sign-in form. Select the icon to begin the authentication process.
GitLab.com asks the user to sign in and authorize the GitLab application. If
everything goes well, the user is returned to your GitLab instance and is
signed in.

## Reduce access privileges on sign in

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/337663) in GitLab 14.8 [with a flag](../administration/feature_flags.md) named `omniauth_login_minimal_scopes`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/351331) in GitLab 14.9.
> - [Feature flag `omniauth_login_minimal_scopes`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83453) removed in GitLab 15.2

If you use a GitLab instance for authentication, you can reduce access rights when an OAuth application is used for sign in.

Any OAuth application can advertise the purpose of the application with the
authorization parameter: `gl_auth_type=login`. If the application is
configured with `api` or `read_api`, the access token is issued with
`read_user` for login, because no higher permissions are needed.

The GitLab OAuth client is configured to pass this parameter, but other
applications can also pass it.
