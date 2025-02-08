---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Shibboleth as an authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

NOTE:
Use the [GitLab SAML integration](saml.md) to integrate specific Shibboleth identity providers (IdPs). For Shibboleth federation support (Discovery Service), use this document.

To enable Shibboleth support in GitLab, use Apache instead of NGINX. Apache uses the `mod_shib2` module for Shibboleth authentication, and can pass attributes as headers to the OmniAuth Shibboleth provider.

You can use the bundled NGINX provided in the Linux package to run a Shibboleth service provider on a different instance using a reverse proxy setup. However if you are not doing this, the bundled NGINX is difficult to configure.

To enable the Shibboleth OmniAuth provider, you must:

- [Install the Apache module](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335062/Apache).
- [Configure the Apache module](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache).

To enable Shibboleth:

1. Protect the OmniAuth Shibboleth callback URL:

   ```apache
   <Location /users/auth/shibboleth/callback>
     AuthType shibboleth
     ShibRequestSetting requireSession 1
     ShibUseHeaders On
     require valid-user
   </Location>

   Alias /shibboleth-sp /usr/share/shibboleth
   <Location /shibboleth-sp>
     Satisfy any
   </Location>

   <Location /Shibboleth.sso>
     SetHandler shib
   </Location>
   ```

1. Exclude Shibboleth URLs from rewriting. Add `RewriteCond %{REQUEST_URI} !/Shibboleth.sso` and `RewriteCond %{REQUEST_URI} !/shibboleth-sp`. An example configuration:

   ```apache
   # Apache equivalent of Nginx try files
   RewriteEngine on
   RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_URI} !/Shibboleth.sso
   RewriteCond %{REQUEST_URI} !/shibboleth-sp
   RewriteRule .* http://127.0.0.1:8080%{REQUEST_URI} [P,QSA]
   RequestHeader set X_FORWARDED_PROTO 'https'
   ```

1. Add Shibboleth to `/etc/gitlab/gitlab.rb` as an OmniAuth provider.
   User attributes are sent from the Apache reverse proxy to GitLab as headers with the names from the Shibboleth attribute mapping.
   Therefore the values of the `args` hash should be in the form of `"HTTP_ATTRIBUTE"`.
   The keys in the hash are arguments to the [OmniAuth::Strategies::Shibboleth class](https://github.com/omniauth/omniauth-shibboleth-redux/blob/master/lib/omniauth/strategies/shibboleth.rb) and are documented by the [`omniauth-shibboleth-redux`](https://github.com/omniauth/omniauth-shibboleth-redux) gem (take care to note the version of the gem packaged with GitLab).

   The file should look like this:

   ```ruby
   external_url 'https://gitlab.example.com'
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   # disable Nginx
   nginx['enable'] = false

   gitlab_rails['omniauth_allow_single_sign_on'] = true
   gitlab_rails['omniauth_block_auto_created_users'] = false
   gitlab_rails['omniauth_providers'] = [
     {
       "name"  => "shibboleth",
       "label" => "Text for Login Button",
       "args"  => {
           "shib_session_id_field"     => "HTTP_SHIB_SESSION_ID",
           "shib_application_id_field" => "HTTP_SHIB_APPLICATION_ID",
           "uid_field"                 => 'HTTP_EPPN',
           "name_field"                => 'HTTP_CN',
           "info_fields"               => { "email" => 'HTTP_MAIL'}
       }
     }
   ]
   ```

   If some of your users appear to be authenticated by Shibboleth and Apache, but GitLab rejects their account with a URI that contains "e-mail is invalid" then your Shibboleth Identity Provider or Attribute Authority may be asserting multiple email addresses. In this instance, consider setting the `multi_values` argument to `first`.
1. For the changes to take effect:
   - For Linux package installations, [reconfigure](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab.
   - For self-compiled installations, [restart](../administration/restart_gitlab.md#self-compiled-installations) GitLab.

On the sign in page, there should now be a **Sign in with: Shibboleth** icon below the regular sign-in form. Select the icon to begin the authentication process. You are redirected to the appropriate IdP server for your Shibboleth module configuration. If everything goes well, you are returned to GitLab and signed in.
