# Shibboleth OmniAuth Provider

This documentation is for enabling shibboleth with gitlab-omnibus package.

In order to enable Shibboleth support in gitlab we need to use Apache instead of Nginx (It may be possible to use Nginx, however I did not found way to easily configure nginx that is bundled in gitlab-omnibus package). Apache uses mod_shib2 module for shibboleth authentication and can pass attributes as headers to omniauth-shibboleth provider. 


To enable the Shibboleth OmniAuth provider you must:

1. Configure Apache shibboleth module. Installation and configuration of module it self is out of scope of this document. 
Check https://wiki.shibboleth.net/ for more info.

1. Here is my Apache config for gitlab with shibboleth, I have used gitlab-ssl.conf from gitlab-reciepes
```
#This configuration has been tested on GitLab 6.0.0 and GitLab 6.0.1
#Note this config assumes unicorn is listening on default port 8080.
#Module dependencies
#  mod_rewrite
#  mod_ssl
#  mod_proxy
#  mod_proxy_http
#  mod_headers

# This section is only needed if you want to redirect http traffic to https.
# You can live without it but clients will have to type in https:// to reach gitlab.

<VirtualHost *:80>
  ServerName gitlab.example.com
  ServerSignature Off

  RewriteEngine on
  RewriteCond %{HTTPS} !=on
  RewriteRule .* https://%{SERVER_NAME}%{REQUEST_URI} [NE,R,L]
</VirtualHost>

<VirtualHost *:443>
  SSLEngine on
  #strong encryption ciphers only
  #see ciphers(1) http://www.openssl.org/docs/apps/ciphers.html
  SSLCipherSuite SSLv3:TLSv1:+HIGH:!SSLv2:!MD5:!MEDIUM:!LOW:!EXP:!ADH:!eNULL:!aNULL

  SSLCertificateFile	/etc/gitlab/ssl/gitlab.example.com.crt
  SSLCertificateKeyFile	/etc/gitlab/ssl/gitlab.example.com.key
  SSLCACertificateFile  /etc/gitlab/ssl/your-ca.crt

  ServerName gitlab.example.com
  ServerSignature Off

  ProxyPreserveHost On

  AllowEncodedSlashes NoDecode

  <Location />
    Order deny,allow
    Allow from all

    ProxyPassReverse http://127.0.0.1:8080
    ProxyPassReverse http://gitlab.example.com/
  </Location>

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

  #apache equivalent of nginx try files
  RewriteEngine on
  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_URI} !/Shibboleth.sso 
  RewriteCond %{REQUEST_URI} !/shibboleth-sp 
  RewriteRule .* http://127.0.0.1:8080%{REQUEST_URI} [P,QSA]
  RequestHeader set X_FORWARDED_PROTO 'https'

  # needed for downloading attachments
  DocumentRoot /opt/gitlab/embedded/service/gitlab-rails/public

  #Set up apache error documents, if back end goes down (i.e. 503 error) then a maintenance/deploy page is thrown up.
  ErrorDocument 404 /404.html
  ErrorDocument 422 /422.html
  ErrorDocument 500 /500.html
  ErrorDocument 503 /deploy.html

  LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b" common_forwarded
  ErrorLog  /var/log/apache2/gitlab.example.com_error.log
  CustomLog /var/log/apache2/gitlab.example.com_forwarded.log common_forwarded
  CustomLog /var/log/apache2/gitlab.example.com_access.log combined env=!dontlog
  CustomLog /var/log/apache2/gitlab.example.com.log combined

</VirtualHost>

```

1.  Edit /etc/gitlab/gitlab.rb configuration file, your shibboleth attributes should be in form of "HTTP_ATTRIBUTE" and you should addjust them to your need and environment. Add any other configuration you need. 

File it should look like this:
```
external_url 'https://gitlab.example.com'
gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

# disable nginx
nginx['enable'] = false

gitlab_rails['omniauth_allow_single_sign_on'] = true
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_providers'] = [
  {
    "name" => 'shibboleth',
        "args" => {
        "shib_session_id_field" => "HTTP_SHIB_SESSION_ID",
        "shib_application_id_field" => "HTTP_SHIB_APPLICATION_ID",
        "uid_field" => 'HTTP_EPPN',
        "name_field" => 'HTTP_CN',
        "info_fields" => { "email" => 'HTTP_MAIL'}
        }
  }
]

```
1. Save changes and reconfigure gitlab: 
```
sudo gitlab-ctl reconfigure
```

On the sign in page there should now be a "Sign in with: Shibboleth" icon below the regular sign in form. Click the icon to begin the authentication process. You will be redirected to IdP server (Depends on your Shibboleth module configuration). If everything goes well the user will be returned to GitLab and will be signed in.
