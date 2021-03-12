---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Auth0 OmniAuth Provider **(FREE SELF)**

To enable the Auth0 OmniAuth provider, you must create an Auth0 account, and an
application.

1. Sign in to the [Auth0 Console](https://auth0.com/auth/login). If you need to
   create an account, you can do so at the same link.

1. Select **New App/API**.

1. Provide the Application Name ('GitLab' works fine).

1. After creating, you should see the **Quick Start** options. Disregard them and
   select **Settings** above the **Quick Start** options.

1. At the top of the Settings screen, you should see your **Domain**, **Client ID**, and
   **Client Secret**. These values are needed in the configuration file. For example:
   - Domain: `test1234.auth0.com`
   - Client ID: `t6X8L2465bNePWLOvt9yi41i`
   - Client Secret: `KbveM3nqfjwCbrhaUy_gDu2dss8TIlHIdzlyf33pB7dEK5u_NyQdp65O_o02hXs2`

1. Fill in the **Allowed Callback URLs**:
   - `http://YOUR_GITLAB_URL/users/auth/auth0/callback` (or)
   - `https://YOUR_GITLAB_URL/users/auth/auth0/callback`

1. Fill in the **Allowed Origins (CORS)**:
   - `http://YOUR_GITLAB_URL` (or)
   - `https://YOUR_GITLAB_URL`

1. On your GitLab server, open the configuration file.

   For Omnibus GitLab:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Read [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration)
   for initial settings.

1. Add the provider configuration:

   For Omnibus GitLab:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       "name" => "auth0",
       "args" => { client_id: 'YOUR_AUTH0_CLIENT_ID',
                   client_secret: 'YOUR_AUTH0_CLIENT_SECRET',
                   domain: 'YOUR_AUTH0_DOMAIN',
                   scope: 'openid profile email'
                 }
     }
   ]
   ```

   For installations from source:

   ```yaml
   - { name: 'auth0',
       args: {
         client_id: 'YOUR_AUTH0_CLIENT_ID',
         client_secret: 'YOUR_AUTH0_CLIENT_SECRET',
         domain: 'YOUR_AUTH0_DOMAIN',
         scope: 'openid profile email' }
     }
   ```

1. Change `YOUR_AUTH0_CLIENT_ID` to the client ID from the Auth0 Console page
   from step 5.

1. Change `YOUR_AUTH0_CLIENT_SECRET` to the client secret from the Auth0 Console
   page from step 5.

1. Reconfigure or restart GitLab, depending on your installation method:

   - *If you installed from Omnibus GitLab,*
     [Reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab.
   - *If you installed from source,*
     [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

On the sign-in page there should now be an Auth0 icon below the regular sign-in
form. Click the icon to begin the authentication process. Auth0 asks the
user to sign in and authorize the GitLab application. If the user authenticates
successfully, the user is returned to GitLab and signed in.
