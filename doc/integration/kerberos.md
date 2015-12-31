# Kerberos integration

GitLab can be configured to allow your users to sign with their Kerberos credentials.
Kerberos integration can be enabled as a regular omniauth provider, edit [gitlab.rb (omnibus-gitlab)`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#omniauth-google-twitter-github-login) or [gitlab.yml (source installations)](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example) on your GitLab server and restart GitLab. You only need to specify the provider name. For example:

```
{ name: 'kerberos'}
```

NB: for source installations, make sure the `kerberos` gem group [has been installed](../install/installation.md#install-gems).

You still need to configure your system for Kerberos usage, such as specifying realms. GitLab will make use of the system's Kerberos settings.

Existing GitLab users can go to profile > account and attach a Kerberos account. if you want to allow users without a GitLab account to login you should enable the option `omniauth_allow_single_sign_on` in config file (default: false). Then, the first time a user signs in with Kerberos credentials, GitLab will create a new GitLab user associated with the email, which is built from the kerberos username and realm.
User accounts will be created automatically when authentication was successful.

### HTTP git access

A linked Kerberos account enables you to `git pull` and `git push` using your Kerberos account, as well as your standard GitLab credentials.

### HTTP git access with Kerberos token (passwordless authentication)

GitLab users with a linked Kerberos account can also `git pull` and `git push` using Kerberos tokens, i.e. without having to send their password with each operation.

For GitLab to offer Kerberos token-based authentication, perform the following prerequisites:

1. Create a Kerberos Service Principal for the HTTP service on your GitLab server. If your GitLab server is gitlab.example.com and your Kerberos realm EXAMPLE.COM, create a Service Principal `HTTP/gitlab.example.com@EXAMPLE.COM` in your Kerberos database.

1. Create a keytab for the above Service Principal, e.g. `/etc/http.keytab`.

The keytab is a sensitive file and must be readable by the GitLab user. Set ownership and protect the file appropriately:

```
$ sudo chown git /etc/http.keytab
$ sudo chmod 0700 /etc/http.keytab
```

#### Installations from source

Edit the kerberos section of [gitlab.yml](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example) to enable Kerberos ticket-based authentication. In most cases, you only need to enable Kerberos and specify the location of the keytab:

```yaml
  kerberos:
    # Allow the HTTP Negotiate authentication method for Git clients
    enabled: true

    # Kerberos 5 keytab file. The keytab file must be readable by the GitLab user,
    # and should be different from other keytabs in the system.
    # (default: use default keytab from Krb5 config)
    keytab: /etc/http.keytab
```

Restart GitLab to apply the changes. GitLab will now offer the `negotiate` authentication method for HTTP git access, enabling git clients that support this authentication protocol to authenticate with Kerberos tokens.

##### Omnibus package installations

In `/etc/gitlab/gitlab.rb`:

```ruby

gitlab_rails['kerberos_enabled'] = true
gitlab_rails['kerberos_keytab'] = "/etc/http.keytab"
```

and run `sudo gitlab-ctl reconfigure` for changes to take effect.

#### Support for Git before 2.4

Until version 2.4, the `git` command uses only the `negotiate` authentication method if the HTTP server offers it, even if this method fails (such as when the client does not have a Kerberos token).
It is thus not possible to fall back to username/password (also known as `basic`) authentication if Kerberos authentication fails.

For GitLab users to be able to use either `basic` or `negotiate` authentication with older git versions, it is possible to offer Kerberos ticket-based authentication on a different port (e.g. 8443) while the standard port will keep offering only `basic` authentication.

* For source installations with HTTPS:

1. Edit the nginx configuration file for GitLab (e.g. `/etc/nginx/sites-available/gitlab-ssl`) and configure nginx to listen to port 8443 in addition to the standard HTTPS port

    ```yaml
    server {
      listen 0.0.0.0:443 ssl;
      listen [::]:443 ipv6only=on ssl default_server;
      listen 0.0.0.0:8443 ssl;
      listen [::]:8443 ipv6only=on ssl;
    ```

1. Update the kerberos section of [gitlab.yml](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example)

    ```yaml
      kerberos:
        # Dedicated port: Git before 2.4 does not fall back to Basic authentication if Negotiate fails.
        # To support both Basic and Negotiate methods with older versions of Git, configure
        # nginx to proxy GitLab on an extra port (e.g. 8443) and uncomment the following lines
        # to dedicate this port to Kerberos authentication. (default: false)
        use_dedicated_port: true
        port: 8443
        https: true
    ```

1. Restart nginx and gitlab

* For Omnibus package installations, in `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['kerberos_use_dedicated_port'] = true
gitlab_rails['kerberos_port'] = 8443
gitlab_rails['kerberos_https'] = true
```
and run `sudo gitlab-ctl reconfigure` for changes to take effect.


Git remote URLs will have to be updated to `https://gitlab.example.com:8443/mygroup/myproject.git` in order to use Kerberos ticket-based authentication.

#### Support for Active Directory Kerberos environments

When using Kerberos ticket-based authentication in an Active Directory domain, it may be necessary to increase the maximum header size allowed by nginx, as extensions to the Kerberos protocol may result in HTTP authentication headers larger than the default size of 8kB. Configure `large_client_header_buffers` to a larger value in [the nginx configuration](http://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers).

### Helpful links to setup development kerberos environment.

https://help.ubuntu.com/community/Kerberos

http://blog.manula.org/2012/04/setting-up-kerberos-server-with-debian.html
