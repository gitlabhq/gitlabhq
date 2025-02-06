---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use JWT as an authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To enable the JWT OmniAuth provider, you must register your application with JWT.
JWT provides you with a secret key for you to use.

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

1. Configure the [common settings](../../integration/omniauth.md#configure-common-settings)
   to add `jwt` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. Add the provider configuration.

   For Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: "jwt",
       label: "Provider name", # optional label for login button, defaults to "Jwt"
       args: {
         secret: "YOUR_APP_SECRET",
         algorithm: "HS256", # Supported algorithms: "RS256", "RS384", "RS512", "ES256", "ES384", "ES512", "HS256", "HS384", "HS512"
         uid_claim: "email",
         required_claims: ["name", "email"],
         info_map: { name: "name", email: "email" },
         auth_url: "https://example.com/",
         valid_within: 3600 # 1 hour
       }
     }
   ]
   ```

   For self-compiled installations:

   ```yaml
   - { name: 'jwt',
       label: 'Provider name', # optional label for login button, defaults to "Jwt"
       args: {
         secret: 'YOUR_APP_SECRET',
         algorithm: 'HS256', # Supported algorithms: 'RS256', 'RS384', 'RS512', 'ES256', 'ES384', 'ES512', 'HS256', 'HS384', 'HS512'
         uid_claim: 'email',
         required_claims: ['name', 'email'],
         info_map: { name: 'name', email: 'email' },
         auth_url: 'https://example.com/',
         valid_within: 3600 # 1 hour
       }
     }
   ```

   NOTE:
   For more information on each configuration option refer to
   the [OmniAuth JWT usage documentation](https://github.com/mbleigh/omniauth-jwt#usage).

   WARNING:
   Incorrectly configuring these settings can result in an insecure instance.

1. Change `YOUR_APP_SECRET` to the client secret and set `auth_url` to your redirect URL.
1. Save the configuration file.
1. For changes to take effect, if you:
   - Used the Linux package to install GitLab, [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Self-compiled your GitLab installation, [restart GitLab](../restart_gitlab.md#self-compiled-installations).

On the sign in page there should now be a JWT icon below the regular sign in form.
Select the icon to begin the authentication process. JWT asks the user to
sign in and authorize the GitLab application. If everything goes well, the user
is redirected to GitLab and signed in.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
