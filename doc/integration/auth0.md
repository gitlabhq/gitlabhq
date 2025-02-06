---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Auth0 as an OAuth 2.0 authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To enable the Auth0 OmniAuth provider, you must create an Auth0 account, and an
application.

1. Sign in to the [Auth0 Console](https://auth0.com/auth/login). You can also
   create an account using the same link.
1. Select **New App/API**.
1. Enter the **Application Name**. For example, 'GitLab'.
1. After creating the application, you should see the **Quick Start** options.
   Disregard these options and select **Settings** instead.
1. At the top of the Settings screen, you should see your **Domain**, **Client ID**, and
   **Client Secret** in the Auth0 Console. Note these settings to complete the configuration
   file later. For example:
   - Domain: `test1234.auth0.com`
   - Client ID: `t6X8L2465bNePWLOvt9yi41i`
   - Client Secret: `KbveM3nqfjwCbrhaUy_gDu2dss8TIlHIdzlyf33pB7dEK5u_NyQdp65O_o02hXs2`
1. Fill in the **Allowed Callback URLs**:
   - `http://<your_gitlab_url>/users/auth/auth0/callback` (or)
   - `https://<your_gitlab_url>/users/auth/auth0/callback`
1. Fill in the **Allowed Origins (CORS)**:
   - `http://<your_gitlab_url>` (or)
   - `https://<your_gitlab_url>`
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
   to add `auth0` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration:

   For Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "auth0",
       # label: "Provider name", # optional label for login button, defaults to "Auth0"
       args: {
         client_id: "<your_auth0_client_id>",
         client_secret: "<your_auth0_client_secret>",
         domain: "<your_auth0_domain>",
         scope: "openid profile email"
       }
     }
   ]
   ```

   For self-compiled installations:

   ```yaml
   - { name: 'auth0',
       # label: 'Provider name', # optional label for login button, defaults to "Auth0"
       args: {
         client_id: '<your_auth0_client_id>',
         client_secret: '<your_auth0_client_secret>',
         domain: '<your_auth0_domain>',
         scope: 'openid profile email' }
     }
   ```

1. Replace `<your_auth0_client_id>` with the client ID from the Auth0 Console page.
1. Replace `<your_auth0_client_secret>` with the client secret from the Auth0 Console page.
1. Replace `<your_auth0_domain>` with the domain from the Auth0 Console page.
1. Reconfigure or restart GitLab, depending on your installation method:
   - If you installed using the Linux package,
     [reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - If you self-compiled your installation,
     [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations).

On the sign-in page there should now be an Auth0 icon below the regular sign-in
form. Select the icon to begin the authentication process. Auth0 asks the
user to sign in and authorize the GitLab application. If the user authenticates
successfully, the user is returned to GitLab and signed in.
