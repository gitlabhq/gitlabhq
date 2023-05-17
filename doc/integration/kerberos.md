---
stage: Manage
group: Authentication and Authorization
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Kerberos integration **(PREMIUM SELF)**

GitLab can integrate with [Kerberos](https://web.mit.edu/kerberos/) as an authentication mechanism.

- You can configure GitLab so your users can sign in with their Kerberos credentials.
- You can use Kerberos to [prevent](https://web.mit.edu/sipb/doc/working/guide/guide/node20.html) anyone from intercepting or eavesdropping on the transmitted password.

WARNING:
GitLab CI/CD doesn't work with a Kerberos-enabled GitLab instance unless the integration is
[set to use a dedicated port](#http-git-access-with-kerberos-token-passwordless-authentication).

## Configuration

For GitLab to offer Kerberos token-based authentication, perform the
following prerequisites. You still need to configure your system for
Kerberos usage, such as specifying realms. GitLab makes use of the
system's Kerberos settings.

### GitLab keytab

1. Create a Kerberos Service Principal for the HTTP service on your GitLab server.
   If your GitLab server is `gitlab.example.com` and your Kerberos realm
   `EXAMPLE.COM`, create a Service Principal `HTTP/gitlab.example.com@EXAMPLE.COM`
   in your Kerberos database.
1. Create a keytab on the GitLab server for the above Service Principal. For example,
   `/etc/http.keytab`.

The keytab is a sensitive file and must be readable by the GitLab user. Set
ownership and protect the file appropriately:

```shell
sudo chown git /etc/http.keytab
sudo chmod 0600 /etc/http.keytab
```

### Configure GitLab

#### Installations from source

NOTE:
For source installations, make sure the `kerberos` gem group
[has been installed](../install/installation.md#install-gems).

1. Edit the `kerberos` section of [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example) to enable Kerberos ticket-based
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

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source) for the changes to take effect.

#### Omnibus package installations

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['kerberos']

   gitlab_rails['kerberos_enabled'] = true
   gitlab_rails['kerberos_keytab'] = "/etc/http.keytab"
   ```

   To avoid GitLab creating users automatically on their first sign in through Kerberos,
   don't set `kerberos` for `gitlab_rails['omniauth_allow_single_sign_on']`.

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

GitLab now offers the `negotiate` authentication method for signing in and
HTTP Git access, enabling Git clients that support this authentication protocol
to authenticate with Kerberos tokens.

#### Enable single sign-on

Configure the [common settings](omniauth.md#configure-common-settings)
to add `kerberos` as a single sign-on provider. This enables Just-In-Time
account provisioning for users who do not have an existing GitLab account.

## Create and link Kerberos accounts

You can either link a Kerberos account to an existing GitLab account, or
set up GitLab to create a new account when a Kerberos user tries to sign in.

### Link a Kerberos account to an existing GitLab account

> Kerberos SPNEGO [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96335) to Kerberos in GitLab 15.4.

If you're an administrator, you can link a Kerberos account to an
existing GitLab account. To do so:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select a user, then select the **Identities** tab.
1. From the **Provider** dropdown list, select **Kerberos**.
1. Make sure the **Identifier** corresponds to the Kerberos username.
1. Select **Save changes**.

If you're not an administrator:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Service sign-in** section, select **Connect Kerberos**.
   If you don't see a **Service sign-in** Kerberos option, follow the
   requirements in [Enable single sign-on](#enable-single-sign-on).

In either case, you should now be able to sign in to your GitLab account
with your Kerberos credentials.

### Create accounts on first sign-in

The first time users sign in to GitLab with their Kerberos accounts,
GitLab creates a matching account.
Before you continue, review the [common configuration settings](omniauth.md#configure-common-settings)
options in Omnibus and GitLab source. You must also include `kerberos`.

With that information at hand:

1. Include `'kerberos'` with the `allow_single_sign_on` setting.
1. For now, accept the default `block_auto_created_users` option, true.
1. When a user tries to sign in with Kerberos credentials, GitLab
   creates a new account.
   1. If `block_auto_created_users` is true, the Kerberos user may see
      a message like:

      ```shell
      Your account has been blocked. Please contact your GitLab
      administrator if you think this is an error.
      ```

      1. As an administrator, you can confirm the new, blocked account:
         1. On the top bar, select **Main menu > Admin**.
         1. On the left sidebar, select **Overview > Users** and review the **Blocked** tab.
      1. You can enable the user.
   1. If `block_auto_created_users` is false, the Kerberos user is
      authenticated and is signed in to GitLab.

WARNING:
We recommend that you retain the default for `block_auto_created_users`.
Kerberos users who create accounts on GitLab without administrator
knowledge can be a security risk.

## Link Kerberos and LDAP accounts together

If your users sign in with Kerberos, but you also have [LDAP integration](../administration/auth/ldap/index.md)
enabled, your users are linked to their LDAP accounts on their first sign-in.
For this to work, some prerequisites must be met:

The Kerberos username must match the LDAP user's UID. You can choose which LDAP
attribute is used as the UID in the GitLab [LDAP configuration](../administration/auth/ldap/index.md#configure-ldap)
but for Active Directory, this should be `sAMAccountName`.

The Kerberos realm must match the domain part of the LDAP user's Distinguished
Name. For instance, if the Kerberos realm is `AD.EXAMPLE.COM`, then the LDAP
user's Distinguished Name should end in `dc=ad,dc=example,dc=com`.

Taken together, these rules mean that linking only works if your users'
Kerberos usernames are of the form `foo@AD.EXAMPLE.COM` and their
LDAP Distinguished Names look like `sAMAccountName=foo,dc=ad,dc=example,dc=com`.

### Custom allowed realms

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9962) in GitLab 13.5.

You can configure custom allowed realms when the user's Kerberos realm doesn't
match the domain from the user's LDAP DN. The configuration value must specify
all domains that users may be expected to have. Any other domains are
ignored and an LDAP identity is not linked.

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['kerberos_simple_ldap_linking_allowed_realms'] = ['example.com','kerberos.example.com']
   ```

1. Save the file and [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   GitLab for the changes to take effect.

---

**For installations from source**

1. Edit `config/gitlab.yml`:

   ```yaml
   kerberos:
     simple_ldap_linking_allowed_realms: ['example.com','kerberos.example.com']
   ```

1. Save the file and [restart](../administration/restart_gitlab.md#installations-from-source)
   GitLab for the changes to take effect.

## HTTP Git access

A linked Kerberos account enables you to `git pull` and `git push` using your
Kerberos account, as well as your standard GitLab credentials.

GitLab users with a linked Kerberos account can also `git pull` and `git push`
using Kerberos tokens. That is, without having to send their password with each
operation.

WARNING:
There is a [known issue](https://github.com/curl/curl/issues/1261) with `libcurl`
older than version 7.64.1 wherein it doesn't reuse connections when negotiating.
This leads to authorization issues when push is larger than `http.postBuffer`
configuration. Ensure that Git is using at least `libcurl` 7.64.1 to avoid this. To
know the `libcurl` version installed, run `curl-config --version`.

### HTTP Git access with Kerberos token (passwordless authentication)

Because of [a bug in current Git versions](https://lore.kernel.org/git/YKNVop80H8xSTCjz@coredump.intra.peff.net/T/#mab47fd7dcb61fee651f7cc8710b8edc6f62983d5),
the `git` CLI command uses only the `negotiate` authentication
method if the HTTP server offers it, even if this method fails (such as when
the client does not have a Kerberos token). It is thus not possible to fall back
to an embedded username and password (also known as `basic`) authentication if Kerberos
authentication fails.

For GitLab users to be able to use either `basic` or `negotiate` authentication
with current Git versions, it is possible to offer Kerberos ticket-based
authentication on a different port (for example, `8443`) while the standard port
offers only `basic` authentication.

NOTE:
[Git 2.4 and later](https://github.com/git/git/blob/master/Documentation/RelNotes/2.4.0.txt#L225-L228) supports falling back to `basic` authentication if the
username and password is passed interactively or through a credentials manager. It fails to fall back when the username and password is passed as part of the URL instead. For example,
this can happen in GitLab CI/CD jobs that [authenticate with the CI/CD job token](../ci/jobs/ci_job_token.md).

**For source installations with HTTPS**

1. Edit the NGINX configuration file for GitLab
   (for example, `/etc/nginx/sites-available/gitlab-ssl`) and configure NGINX to
   listen to port `8443` in addition to the standard HTTPS port:

   ```conf
   server {
     listen 0.0.0.0:443 ssl;
     listen [::]:443 ipv6only=on ssl default_server;
     listen 0.0.0.0:8443 ssl;
     listen [::]:8443 ipv6only=on ssl;
   ```

1. Update the `kerberos` section of [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example):

   ```yaml
   kerberos:
     # Dedicated port: Git before 2.4 does not fall back to Basic authentication if Negotiate fails.
     # To support both Basic and Negotiate methods with older versions of Git, configure
     # nginx to proxy GitLab on an extra port (for example: 8443) and uncomment the following lines
     # to dedicate this port to Kerberos authentication. (default: false)
     use_dedicated_port: true
     port: 8443
     https: true
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source) and NGINX for the changes to take effect.

**For Omnibus package installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['kerberos_use_dedicated_port'] = true
   gitlab_rails['kerberos_port'] = 8443
   gitlab_rails['kerberos_https'] = true
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

After this change, Git remote URLs have to be updated to
`https://gitlab.example.com:8443/mygroup/myproject.git` to use
Kerberos ticket-based authentication.

## Upgrading from password-based to ticket-based Kerberos sign-ins

In previous versions of GitLab users had to submit their
Kerberos username and password to GitLab when signing in.

We [deprecated](../update/deprecations.md#omniauth-kerberos-gem) password-based
Kerberos sign-ins in GitLab 14.3 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/2908)
it in GitLab 15.0. You must switch to ticket-based sign in.

Depending on your existing GitLab configuration, **Sign in with:
Kerberos** may already be visible on your GitLab sign-in page.
If not, then add the settings [described above](#configuration).

To disable password-based Kerberos sign-ins, remove the OmniAuth provider
`kerberos` from your `gitlab.yml`/`gitlab.rb` file.

**For installations from source**

1. Edit [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example) and remove the `- { name: 'kerberos' }` line under OmniAuth
   providers:

   ```yaml
   omniauth:
     # Rest of configuration omitted
     # ...
     providers:
       - { name: 'kerberos' }  # <-- remove this line
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source) for the changes to take effect.

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb` and remove the `{ "name" => "kerberos" }` line
   under `gitlab_rails['omniauth_providers']`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { "name" => "kerberos" } # <-- remove this entry
   ]
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

NOTE:
Removing the `kerberos` OmniAuth provider can also resolve a rare
`Krb5Auth::Krb5::Exception (No credentials cache found)` error (`500` error in GitLab)
when trying to clone via HTTPS.

## Support for Active Directory Kerberos environments

When using Kerberos ticket-based authentication in an Active Directory domain,
it may be necessary to increase the maximum header size allowed by NGINX,
as extensions to the Kerberos protocol may result in HTTP authentication headers
larger than the default size of 8 kB. Configure `large_client_header_buffers`
to a larger value in [the NGINX configuration](https://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers).

### Use Keytabs created using AES-only encryption with Windows AD

When you create a keytab with Advanced Encryption Standard (AES)-only encryption, you must select the **This account supports Kerberos AES <128/256> bit encryption** checkbox for that account in the AD server. Whether the checkbox is 128 or 256 bit depends on the encryption strength used when you created the keytab. To check this, on the Active Directory server:

1. Open the **Users and Groups** tool.
1. Locate the account that you used to create the keytab.
1. Right-click the account and select **Properties**.
1. In **Account Options** on the **Account** tab, select the appropriate AES encryption support checkbox.
1. Save and close.

## Troubleshooting

### Using Google Chrome with Kerberos authentication against Windows AD

When you use Google Chrome to sign in to GitLab with Kerberos, you must enter your full username. For example, `username@domain.com`.

If you do not enter your full username, the sign-in fails. Check the logs to see the following event message as evidence of this sign-in failure:

```plain
"message":"OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested\nUnknown error"`.
```

### Test connectivity between the GitLab and Kerberos servers

You can use utilities like [`kinit`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/kinit.html) and [`klist`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/klist.html) to test connectivity between the GitLab server
and the Kerberos server. How you install these depends on your specific OS.

Use `klist` to see the service principal names (SPN) available in your `keytab` file and the encryption type for each SPN:

```shell
klist -ke /etc/http.keytab
```

On an Ubuntu server, the output would look similar to the following:

```shell
Keytab name: FILE:/etc/http.keytab
KVNO Principal
---- --------------------------------------------------------------------------
   3 HTTP/my.gitlab.domain@MY.REALM (des-cbc-crc)
   3 HTTP/my.gitlab.domain@MY.REALM (des-cbc-md5)
   3 HTTP/my.gitlab.domain@MY.REALM (arcfour-hmac)
   3 HTTP/my.gitlab.domain@MY.REALM (aes256-cts-hmac-sha1-96)
   3 HTTP/my.gitlab.domain@MY.REALM (aes128-cts-hmac-sha1-96)
```

Use `kinit` in verbose mode to test whether GitLab can use the keytab file to connect to the Kerberos server:

```shell
KRB5_TRACE=/dev/stdout kinit -kt /etc/http.keytab HTTP/my.gitlab.domain@MY.REALM
```

This command shows a detailed output of the authentication process.

### Unsupported GSSAPI mechanism

With Kerberos SPNEGO authentication, the browser is expected to send a list of
mechanisms it supports to GitLab. If it doesn't support any of the mechanisms
GitLab supports, authentication fails with a message like this in the log:

```plaintext
OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested Unknown error
```

There are a number of potential causes and solutions for this error message.

#### Kerberos integration not using a dedicated port

GitLab CI/CD doesn’t work with a Kerberos-enabled GitLab instance unless the Kerberos integration
is configured to [use a dedicated port](kerberos.md#http-git-access-with-kerberos-token-passwordless-authentication).

#### Lack of connectivity between client machine and Kerberos server

This is usually seen when the browser is unable to contact the Kerberos server
directly. It falls back to an unsupported mechanism known as
[`IAKERB`](https://k5wiki.kerberos.org/wiki/Projects/IAKERB), which tries to use
the GitLab server as an intermediary to the Kerberos server.

If you're experiencing this error, ensure there is connectivity between the
client machine and the Kerberos server - this is a prerequisite! Traffic may be
blocked by a firewall, or the DNS records may be incorrect.

#### Mismatched forward and reverse DNS records for GitLab instance hostname

Another failure mode occurs when the forward and reverse DNS records for the
GitLab server do not match. Often, Windows clients work in this case while
Linux clients fail. They use reverse DNS while detecting the Kerberos
realm. If they get the wrong realm then ordinary Kerberos mechanisms fail,
so the client falls back to attempting to negotiate `IAKERB`, leading to the
above error message.

To fix this, ensure that the forward and reverse DNS for your GitLab server
match. So for instance, if you access GitLab as `gitlab.example.com`, resolving
to IP address `1.2.3.4`, then `4.3.2.1.in-addr.arpa` must be a `PTR` record for
`gitlab.example.com`.

#### Missing Kerberos libraries on browser or client machine

Finally, it's possible that the browser or client machine lack Kerberos support
completely. Ensure that the Kerberos libraries are installed and that you can
authenticate to other Kerberos services.

### HTTP Basic: Access denied when cloning

```shell
remote: HTTP Basic: Access denied
fatal: Authentication failed for '<KRB5 path>'
```

If you are using Git v2.11 or newer and see the above error when cloning, you can
set the `http.emptyAuth` Git option to `true` to fix this:

```shell
git config --global http.emptyAuth true
```

See also: [Git v2.11 release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.txt#L482-L486)

## Helpful links

- <https://help.ubuntu.com/community/Kerberos>
- <https://blog.manula.org/2012/04/setting-up-kerberos-server-with-debian.html>
- <https://www.roguelynn.com/words/explain-like-im-5-kerberos/>
