# Shibboleth OmniAuth Provider

This documentation is for enabling shibboleth with omnibus-gitlab package.

In order to enable Shibboleth support in gitlab we need to use Apache instead of Nginx (It may be possible to use Nginx, however this is difficult to configure using the bundled Nginx provided in the omnibus-gitlab package). Apache uses mod_shib2 module for shibboleth authentication and can pass attributes as headers to omniauth-shibboleth provider.

To enable the Shibboleth OmniAuth provider you must configure Apache shibboleth module.
The installation and configuration of the module itself is out of the scope of this document.
Check <https://wiki.shibboleth.net/confluence/display/SP3/Apache> for more info.

You can find Apache config in gitlab-recipes (<https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache>).

The following changes are needed to enable Shibboleth:

1. Protect omniauth-shibboleth callback URL:

   ```
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

1. Exclude shibboleth URLs from rewriting. Add `RewriteCond %{REQUEST_URI} !/Shibboleth.sso` and `RewriteCond %{REQUEST_URI} !/shibboleth-sp`. Config should look like this:

   ```
   # Apache equivalent of Nginx try files
   RewriteEngine on
   RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_URI} !/Shibboleth.sso
   RewriteCond %{REQUEST_URI} !/shibboleth-sp
   RewriteRule .* http://127.0.0.1:8080%{REQUEST_URI} [P,QSA]
   RequestHeader set X_FORWARDED_PROTO 'https'
   ```

1. Edit `/etc/gitlab/gitlab.rb` configuration file to enable OmniAuth and add
   Shibboleth as an OmniAuth provider. User attributes will be sent from the
   Apache reverse proxy to GitLab as headers with the names from the Shibboleth
   attribute mapping. Therefore the values of the `args` hash
   should be in the form of `"HTTP_ATTRIBUTE"`. The keys in the hash are arguments
   to the [OmniAuth::Strategies::Shibboleth class](https://github.com/toyokazu/omniauth-shibboleth/blob/master/lib/omniauth/strategies/shibboleth.rb)
   and are documented by the [omniauth-shibboleth gem](https://github.com/toyokazu/omniauth-shibboleth)
   (take care to note the version of the gem packaged with GitLab). If some of
   your users appear to be authenticated by Shibboleth and Apache, but GitLab
   rejects their account with a URI that contains "e-mail is invalid" then your
   Shibboleth Identity Provider or Attribute Authority may be asserting multiple
   e-mail addresses. In this instance, you might consider setting the
   `multi_values` argument to `first`.

   The file should look like this:

   ```
   external_url 'https://gitlab.example.com'
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   # disable Nginx
   nginx['enable'] = false

   gitlab_rails['omniauth_allow_single_sign_on'] = true
   gitlab_rails['omniauth_block_auto_created_users'] = false
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [
     {
       "name"  => "'shibboleth"',
       "label" => "Text for Login Button",
       "args"  => {
           "shib_session_id_field"     => "HTTP_SHIB_SESSION_ID",
           "shib_application_id_field" => "HTTP_SHIB_APPLICATION_ID",
           "uid_field"                 => 'HTTP_EPPN',
           "name_field"                => 'HTTP_CN',
           "info_fields" => { "email" => 'HTTP_MAIL'}
       }
     }
   ]

   ```

1. [Reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart](../administration/restart_gitlab.md#installations-from-source) GitLab for the changes to take effect if you
   installed GitLab via Omnibus or from source respectively.

On the sign in page, there should now be a "Sign in with: Shibboleth" icon below the regular sign in form. Click the icon to begin the authentication process. You will be redirected to IdP server (depends on your Shibboleth module configuration). If everything goes well the user will be returned to GitLab and will be signed in.

## Apache 2.4 / GitLab 8.6 update

The order of the first 2 Location directives is important. If they are reversed,
you will not get a shibboleth session!

```
<Location />
  Require all granted
  ProxyPassReverse http://127.0.0.1:8181
  ProxyPassReverse http://YOUR_SERVER_FQDN/
</Location>

<Location /users/auth/shibboleth/callback>
  AuthType shibboleth
  ShibRequestSetting requireSession 1
  ShibUseHeaders On
  Require shib-session
</Location>

Alias /shibboleth-sp /usr/share/shibboleth

<Location /shibboleth-sp>
  Require all granted
</Location>

<Location /Shibboleth.sso>
  SetHandler shib
</Location>

RewriteEngine on

#Don't escape encoded characters in api requests
RewriteCond %{REQUEST_URI} ^/api/v4/.*
RewriteCond %{REQUEST_URI} !/Shibboleth.sso
RewriteCond %{REQUEST_URI} !/shibboleth-sp
RewriteRule .* http://127.0.0.1:8181%{REQUEST_URI} [P,QSA,NE]

#Forward all requests to gitlab-workhorse except existing files
RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f [OR]
RewriteCond %{REQUEST_URI} ^/uploads/.*
RewriteCond %{REQUEST_URI} !/Shibboleth.sso
RewriteCond %{REQUEST_URI} !/shibboleth-sp
RewriteRule .* http://127.0.0.1:8181%{REQUEST_URI} [P,QSA]

RequestHeader set X_FORWARDED_PROTO 'https'
RequestHeader set X-Forwarded-Ssl on
```
