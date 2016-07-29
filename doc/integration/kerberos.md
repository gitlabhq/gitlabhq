# Kerberos integration

GitLab can be configured to allow your users to sign with their Kerberos credentials.

## Configuration

For GitLab to offer Kerberos token-based authentication, perform the
following prerequisites. You still need to configure your system for
Kerberos usage, such as specifying realms. GitLab will make use of the
system's Kerberos settings.


### GitLab keytab

1. Create a Kerberos Service Principal for the HTTP service on your GitLab server.
   If your GitLab server is `gitlab.example.com` and your Kerberos realm
   `EXAMPLE.COM`, create a Service Principal `HTTP/gitlab.example.com@EXAMPLE.COM`
   in your Kerberos database.
1. Create a keytab on the GitLab server for the above Service Principal, e.g.
   `/etc/http.keytab`.

The keytab is a sensitive file and must be readable by the GitLab user. Set
ownership and protect the file appropriately:

```
sudo chown git /etc/http.keytab
sudo chmod 0600 /etc/http.keytab
```

### Configure GitLab

**Installations from source**

>**Note:**
For source installations, make sure the `kerberos` gem group
[has been installed](../install/installation.md#install-gems).

1. Edit the kerberos section of [gitlab.yml] to enable Kerberos ticket-based
   authentication. In most cases, you only need to enable Kerberos and specify
   the location of the keytab:

    ```yaml
    omniauth:
      enabled: true
      allow_single_sign_on: ['kerberos']

    kerberos:
      # Allow the HTTP Negotiate authentication method for Git clients
      enabled: true

      # Kerberos 5 keytab file. The keytab file must be readable by the GitLab user,
      # and should be different from other keytabs in the system.
      # (default: use default keytab from Krb5 config)
      keytab: /etc/http.keytab
    ```

1. [Restart GitLab] for the changes to take effect.

---

**Omnibus package installations**

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    gitlab_rails['omniauth_enabled'] = true
    gitlab_rails['omniauth_allow_single_sign_on'] = ['kerberos']

    gitlab_rails['kerberos_enabled'] = true
    gitlab_rails['kerberos_keytab'] = "/etc/http.keytab"
    ```

1. [Reconfigure GitLab] for the changes to take effect.

---

GitLab will now offer the `negotiate` authentication method for signing in and
HTTP Git access, enabling Git clients that support this authentication protocol
to authenticate with Kerberos tokens.

## Creating and linking Kerberos accounts

The Administrative user can navigate to **Admin > Users > Example User > Identities**
and attach a Kerberos account. Existing GitLab users can go to **Profile > Account**
and attach a Kerberos account. If you want to allow users without a GitLab
account to login, you should enable the option `allow_single_sign_on` as
described in the [Configure GitLab](#configure-gitlab) section. Then, the first
time a user signs in with Kerberos credentials, GitLab will create a new GitLab
user associated with the email, which is built from the Kerberos username and
realm. User accounts will be created automatically when authentication was
successful.

## HTTP Git access

A linked Kerberos account enables you to `git pull` and `git push` using your
Kerberos account, as well as your standard GitLab credentials.

GitLab users with a linked Kerberos account can also `git pull` and `git push`
using Kerberos tokens, i.e., without having to send their password with each
operation.

### HTTP Git access with Kerberos token (passwordless authentication)

#### Support for Git before 2.4

Until Git version 2.4, the `git` command uses only the `negotiate` authentication
method if the HTTP server offers it, even if this method fails (such as when
the client does not have a Kerberos token). It is thus not possible to fall back
to username/password (also known as `basic`) authentication if Kerberos
authentication fails.

For GitLab users to be able to use either `basic` or `negotiate` authentication
with older Git versions, it is possible to offer Kerberos ticket-based
authentication on a different port (e.g. 8443) while the standard port will
keep offering only `basic` authentication.

**For source installations with HTTPS**

1. Edit the NGINX configuration file for GitLab
   (e.g., `/etc/nginx/sites-available/gitlab-ssl`) and configure NGINX to
   listen to port `8443` in addition to the standard HTTPS port:

    ```conf
    server {
      listen 0.0.0.0:443 ssl;
      listen [::]:443 ipv6only=on ssl default_server;
      listen 0.0.0.0:8443 ssl;
      listen [::]:8443 ipv6only=on ssl;
    ```

1. Update the Kerberos section of [gitlab.yml]:

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

1. [Restart GitLab] and NGINX for the changes to take effect.

---

**For Omnibus package installations**

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    gitlab_rails['kerberos_use_dedicated_port'] = true
    gitlab_rails['kerberos_port'] = 8443
    gitlab_rails['kerberos_https'] = true
    ```

1. [Reconfigure GitLab] for the changes to take effect.

---

After this change, all Git remote URLs will have to be updated to
`https://gitlab.example.com:8443/mygroup/myproject.git` in order to use
Kerberos ticket-based authentication.

## Upgrading from password-based to ticket-based Kerberos sign-ins

Prior to GitLab 8.10 Enterprise Edition, users had to submit their
Kerberos username and password to GitLab when signing in. We will
remove support for password-based Kerberos sign-ins in a future
release, so we recommend that you upgrade to ticket-based sign-ins.

Depending on your existing GitLab configuration, the 'Sign in with:
Kerberos Spnego' button may already be visible on your GitLab sign-in
page. If not, then add the settings [described above](#configuration).

Once you have verified that the 'Kerberos Spnego' button works
without entering any passwords, you can proceed to disable
password-based Kerberos sign-ins. To do this you need only need to
remove the OmniAuth provider named `kerberos` from your `gitlab.yml` /
`gitlab.rb` file.

**For installations from source**

1. Edit [gitlab.yml] and remove the `- { name: 'kerberos' }` line under omniauth
   providers:

    ```yaml
    omniauth:
      # ...
      providers:
        - { name: 'kerberos' } # <-- remove this line
    ```

1. [Restart GitLab] for the changes to take effect.

---

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb` and remove the `{ "name" => "kerberos" }` line
   under `gitlab_rails['omniauth_providers']`:

    ```ruby
    gitlab_rails['omniauth_providers'] = [
      { "name" => "kerberos" } # <-- remove this entry
    ]
    ```

1. [Reconfigure GitLab] for the changes to take effect.

## Support for Active Directory Kerberos environments

When using Kerberos ticket-based authentication in an Active Directory domain,
it may be necessary to increase the maximum header size allowed by NGINX,
as extensions to the Kerberos protocol may result in HTTP authentication headers
larger than the default size of 8kB. Configure `large_client_header_buffers`
to a larger value in [the NGINX configuration][nginx].

## Helpful links to setup development Kerberos environment.

- <https://help.ubuntu.com/community/Kerberos>
- <http://blog.manula.org/2012/04/setting-up-kerberos-server-with-debian.html>

[gitlab.yml]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example
[restart gitlab]: ../administration/restart_gitlab.md#installations-from-source
[reconfigure gitlab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[nginx]: http://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers
