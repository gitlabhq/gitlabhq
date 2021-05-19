---
type: reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# JWT OmniAuth provider **(FREE SELF)**

To enable the JWT OmniAuth provider, you must register your application with JWT.
JWT will provide you with a secret key for you to use.

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

1. See [Initial OmniAuth Configuration](../../integration/omniauth.md#initial-omniauth-configuration) for initial settings.
1. Add the provider configuration.

   For Omnibus GitLab:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'jwt',
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
   ]
   ```

   For installation from source:

   ```yaml
   - { name: 'jwt',
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

1. Change `YOUR_APP_SECRET` to the client secret and set `auth_url` to your redirect URL.
1. Save the configuration file.
1. [Reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect if you
   installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be a JWT icon below the regular sign in form.
Click the icon to begin the authentication process. JWT will ask the user to
sign in and authorize the GitLab application. If everything goes well, the user
will be redirected to GitLab and will be signed in.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
