---
stage: Release
group: Release Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
description: 'Learn how to administer GitLab Pages.'
---

# GitLab Pages administration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80) in GitLab EE 8.3.
> - Custom CNAMEs with TLS support were [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173) in GitLab EE 8.5.
> - GitLab Pages [was ported](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/14605) to Community Edition in GitLab 8.17.
> - Support for subgroup project's websites was
>   [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30548) in GitLab 11.8.

GitLab Pages allows for hosting of static sites. It must be configured by an
administrator. Separate [user documentation](../../user/project/pages/index.md) is available.

NOTE: **Note:**
This guide is for Omnibus GitLab installations. If you have installed
GitLab from source, see
[GitLab Pages administration for source installations](source.md).

## Overview

GitLab Pages makes use of the [GitLab Pages daemon](https://gitlab.com/gitlab-org/gitlab-pages), a simple HTTP server
written in Go that can listen on an external IP address and provide support for
custom domains and custom certificates. It supports dynamic certificates through
SNI and exposes pages using HTTP2 by default.
You are encouraged to read its [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md) to fully understand how
it works.

In the case of [custom domains](#custom-domains) (but not
[wildcard domains](#wildcard-domains)), the Pages daemon needs to listen on
ports `80` and/or `443`. For that reason, there is some flexibility in the way
which you can set it up:

- Run the Pages daemon in the same server as GitLab, listening on a **secondary IP**.
- Run the Pages daemon in a [separate server](#running-gitlab-pages-on-a-separate-server). In that case, the
   [Pages path](#change-storage-path) must also be present in the server that
   the Pages daemon is installed, so you will have to share it via network.
- Run the Pages daemon in the same server as GitLab, listening on the same IP
   but on different ports. In that case, you will have to proxy the traffic with
   a load balancer. If you choose that route note that you should use TCP load
   balancing for HTTPS. If you use TLS-termination (HTTPS-load balancing) the
   pages will not be able to be served with user provided certificates. For
   HTTP it's OK to use HTTP or TCP load balancing.

In this document, we will proceed assuming the first option. If you are not
supporting custom domains a secondary IP is not needed.

## Prerequisites

Before proceeding with the Pages configuration, you will need to:

1. Have an exclusive root domain for serving GitLab Pages. Note that you cannot
   use a subdomain of your GitLab's instance domain.
1. Configure a **wildcard DNS record**.
1. (Optional) Have a **wildcard certificate** for that domain if you decide to
   serve Pages under HTTPS.
1. (Optional but recommended) Enable [Shared runners](../../ci/runners/README.md)
   so that your users don't have to bring their own.
1. (Only for custom domains) Have a **secondary IP**.

NOTE: **Note:**
If your GitLab instance and the Pages daemon are deployed in a private network or behind a firewall, your GitLab Pages websites will only be accessible to devices/users that have access to the private network.

### Add the domain to the Public Suffix List

The [Public Suffix List](https://publicsuffix.org) is used by browsers to
decide how to treat subdomains. If your GitLab instance allows members of the
public to create GitLab Pages sites, it also allows those users to create
subdomains on the pages domain (`example.io`). Adding the domain to the Public
Suffix List prevents browsers from accepting
[supercookies](https://en.wikipedia.org/wiki/HTTP_cookie#Supercookie),
among other things.

Follow [these instructions](https://publicsuffix.org/submit/) to submit your
GitLab Pages subdomain. For instance, if your domain is `example.io`, you should
request that `example.io` is added to the Public Suffix List. GitLab.com
added `gitlab.io` [in 2016](https://gitlab.com/gitlab-com/infrastructure/-/issues/230).

### DNS configuration

GitLab Pages expect to run on their own virtual host. In your DNS server/provider
you need to add a [wildcard DNS A record](https://en.wikipedia.org/wiki/Wildcard_DNS_record) pointing to the
host that GitLab runs. For example, an entry would look like this:

```plaintext
*.example.io. 1800 IN A    192.0.2.1
*.example.io. 1800 IN AAAA 2001::1
```

where `example.io` is the domain under which GitLab Pages will be served
and `192.0.2.1` is the IPv4 address of your GitLab instance and `2001::1` is the
IPv6 address. If you don't have IPv6, you can omit the AAAA record.

NOTE: **Note:**
You should not use the GitLab domain to serve user pages. For more information see the [security section](#security).

## Configuration

Depending on your needs, you can set up GitLab Pages in 4 different ways.

The following examples are listed from the easiest setup to the most
advanced one. The absolute minimum requirement is to set up the wildcard DNS
since that is needed in all configurations.

### Wildcard domains

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)

---

URL scheme: `http://page.example.io`

This is the minimum setup that you can use Pages with. It is the base for all
other setups as described below. NGINX will proxy all requests to the daemon.
The Pages daemon doesn't listen to the outside world.

1. Set the external URL for GitLab Pages in `/etc/gitlab/gitlab.rb`:

   ```ruby
   pages_external_url 'http://example.io'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

Watch the [video tutorial](https://youtu.be/dD8c7WNcc6s) for this configuration.

### Wildcard domains with TLS support

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate

---

URL scheme: `https://page.example.io`

NGINX will proxy all requests to the daemon. Pages daemon doesn't listen to the
outside world.

1. Place the certificate and key inside `/etc/gitlab/ssl`
1. In `/etc/gitlab/gitlab.rb` specify the following configuration:

   ```ruby
   pages_external_url 'https://example.io'

   pages_nginx['redirect_http_to_https'] = true
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

   where `pages-nginx.crt` and `pages-nginx.key` are the SSL cert and key,
   respectively.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Additional configuration for Docker container

The GitLab Pages daemon will not have permissions to bind mounts when it runs
in a Docker container. To overcome this issue you'll need to change the chroot
behavior:

1. Edit `/etc/gitlab/gitlab.rb`.
1. Set the `inplace_chroot` to `true` for GitLab Pages:

   ```ruby
   gitlab_pages['inplace_chroot'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

NOTE: **Note:**
`inplace_chroot` option might not work with the other features, such as [Pages Access Control](#access-control).
The [GitLab Pages README](https://gitlab.com/gitlab-org/gitlab-pages#caveats) has more information about caveats and workarounds.

### Global settings

Below is a table of all configuration settings known to Pages in Omnibus GitLab,
and what they do. These options can be adjusted in `/etc/gitlab/gitlab.rb`,
and will take effect after you [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
Most of these settings don't need to be configured manually unless you need more granular
control over how the Pages daemon runs and serves content in your environment.

| Setting | Description |
| ------- | ----------- |
| `pages_external_url` | The URL where GitLab Pages is accessible, including protocol (HTTP / HTTPS). If `https://` is used, you must also set `gitlab_pages['ssl_certificate']` and `gitlab_pages['ssl_certificate_key']`.
| **gitlab_pages[]** | |
| `access_control` |  Whether to enable [access control](index.md#access-control).
| `api_secret_key`  | Full path to file with secret key used to authenticate with the GitLab API. Auto-generated when left unset.
| `artifacts_server` |  Enable viewing [artifacts](../job_artifacts.md) in GitLab Pages.
| `artifacts_server_timeout` |  Timeout (in seconds) for a proxied request to the artifacts server.
| `artifacts_server_url` |  API URL to proxy artifact requests to. Defaults to GitLab `external URL` + `/api/v4`, for example `https://gitlab.com/api/v4`.
| `auth_redirect_uri` |  Callback URL for authenticating with GitLab. Defaults to project's subdomain of `pages_external_url` + `/auth`.
| `auth_secret` |  Secret key for signing authentication requests. Leave blank to pull automatically from GitLab during OAuth registration.
| `dir` |  Working directory for config and secrets files.
| `enable` |  Enable or disable GitLab Pages on the current system.
| `external_http` |  Configure Pages to bind to one or more secondary IP addresses, serving HTTP requests. Multiple addresses can be given as an array, along with exact ports, for example `['1.2.3.4', '1.2.3.5:8063']`. Sets value for `listen_http`.
| `external_https` |  Configure Pages to bind to one or more secondary IP addresses, serving HTTPS requests. Multiple addresses can be given as an array, along with exact ports, for example `['1.2.3.4', '1.2.3.5:8063']`. Sets value for `listen_https`.
| `gitlab_client_http_timeout`  | GitLab API HTTP client connection timeout in seconds (default: 10s).
| `gitlab_client_jwt_expiry`  | JWT Token expiry time in seconds (default: 30s).
| `gitlab_id` |  The OAuth application public ID. Leave blank to automatically fill when Pages authenticates with GitLab.
| `gitlab_secret` |  The OAuth application secret. Leave blank to automatically fill when Pages authenticates with GitLab.
| `gitlab_server` |  Server to use for authentication when access control is enabled; defaults to GitLab `external_url`.
| `headers` |  Specify any additional http headers that should be sent to the client with each response.
| `http_proxy` |  Configure GitLab Pages to use an HTTP Proxy to mediate traffic between Pages and GitLab. Sets an environment variable `http_proxy` when starting Pages daemon.
| `inplace_chroot` |  On [systems that don't support bind-mounts](index.md#additional-configuration-for-docker-container), this instructs GitLab Pages to chroot into its `pages_path` directory. Some caveats exist when using inplace chroot; refer to the GitLab Pages [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md#caveats) for more information.
| `insecure_ciphers` |  Use default list of cipher suites, may contain insecure ones like 3DES and RC4.
| `internal_gitlab_server` | Internal GitLab server address used exclusively for API requests. Useful if you want to send that traffic over an internal load balancer. Defaults to GitLab `external_url`.
| `listen_proxy` |  The addresses to listen on for reverse-proxy requests. Pages will bind to these addresses' network socket and receives incoming requests from it. Sets the value of `proxy_pass` in `$nginx-dir/conf/gitlab-pages.conf`.
| `log_directory` |  Absolute path to a log directory.
| `log_format` |  The log output format: 'text' or 'json'.
| `log_verbose` |  Verbose logging, true/false.
| `max_connections` |  Limit on the number of concurrent connections to the HTTP, HTTPS or proxy listeners.
| `metrics_address` |  The address to listen on for metrics requests.
| `redirect_http` |  Redirect pages from HTTP to HTTPS, true/false.
| `sentry_dsn` |  The address for sending Sentry crash reporting to.
| `sentry_enabled` |  Enable reporting and logging with Sentry, true/false.
| `sentry_environment` |  The environment for Sentry crash reporting.
| `status_uri` |  The URL path for a status page, for example, `/@status`.
| `tls_max_version` |  Specifies the maximum SSL/TLS version ("ssl3", "tls1.0", "tls1.1" or "tls1.2").
| `tls_min_version` |  Specifies the minimum SSL/TLS version ("ssl3", "tls1.0", "tls1.1" or "tls1.2").
| `use_http2` |  Enable HTTP2 support.
| **gitlab_rails[]** | |
| `pages_domain_verification_cron_worker` | Schedule for verifying custom GitLab Pages domains.
| `pages_domain_ssl_renewal_cron_worker` | Schedule for obtaining and renewing SSL certificates through Let's Encrypt for GitLab Pages domains.
| `pages_domain_removal_cron_worker` | Schedule for removing unverified custom GitLab Pages domains.
| `pages_path` | The directory on disk where pages are stored, defaults to `GITLAB-RAILS/shared/pages`.
| **pages_nginx[]** | |
| `enable` | Include a virtual host `server{}` block for Pages inside NGINX. Needed for NGINX to proxy traffic back to the Pages daemon. Set to `false` if the Pages daemon should directly receive all requests, for example, when using [custom domains](index.md#custom-domains).

---

## Advanced configuration

In addition to the wildcard domains, you can also have the option to configure
GitLab Pages to work with custom domains. Again, there are two options here:
support custom domains with and without TLS certificates. The easiest setup is
that without TLS certificates. In either case, you'll need a **secondary IP**. If
you have IPv6 as well as IPv4 addresses, you can use them both.

### Custom domains

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Secondary IP

---

URL scheme: `http://page.example.io` and `http://domain.com`

In that case, the Pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains are supported, but no TLS.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   pages_external_url "http://example.io"
   nginx['listen_addresses'] = ['192.0.2.1']
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001::2]:80']
   ```

   where `192.0.2.1` is the primary IP address that GitLab is listening to and
   `192.0.2.2` and `2001::2` are the secondary IPs the GitLab Pages daemon
   listens on. If you don't have IPv6, you can omit the IPv6 address.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Custom domains with TLS support

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate
- Secondary IP

---

URL scheme: `https://page.example.io` and `https://domain.com`

In that case, the Pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains and TLS are supported.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   pages_external_url "https://example.io"
   nginx['listen_addresses'] = ['192.0.2.1']
   pages_nginx['enable'] = false
   gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
   gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001::2]:80']
   gitlab_pages['external_https'] = ['192.0.2.2:443', '[2001::2]:443']
   ```

   where `192.0.2.1` is the primary IP address that GitLab is listening to and
   `192.0.2.2` and `2001::2` are the secondary IPs where the GitLab Pages daemon
   listens on. If you don't have IPv6, you can omit the IPv6 address.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Custom domain verification

To prevent malicious users from hijacking domains that don't belong to them,
GitLab supports [custom domain verification](../../user/project/pages/custom_domains_ssl_tls_certification/index.md#steps).
When adding a custom domain, users will be required to prove they own it by
adding a GitLab-controlled verification code to the DNS records for that domain.

If your user base is private or otherwise trusted, you can disable the
verification requirement. Navigate to **Admin Area > Settings > Preferences** and
uncheck **Require users to prove ownership of custom domains** in the **Pages** section.
This setting is enabled by default.

### Let's Encrypt integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28996) in GitLab 12.1.

[GitLab Pages' Let's Encrypt integration](../../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)
allows users to add Let's Encrypt SSL certificates for GitLab Pages
sites served under a custom domain.

To enable it, you'll need to:

1. Choose an email on which you will receive notifications about expiring domains.
1. Navigate to your instance's **Admin Area > Settings > Preferences** and expand **Pages** settings.
1. Enter the email for receiving notifications and accept Let's Encrypt's Terms of Service as shown below.
1. Click **Save changes**.

![Let's Encrypt settings](img/lets_encrypt_integration_v12_1.png)

### Access control

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/33422) in GitLab 11.5.

GitLab Pages access control can be configured per-project, and allows access to a Pages
site to be controlled based on a user's membership to that project.

Access control works by registering the Pages daemon as an OAuth application
with GitLab. Whenever a request to access a private Pages site is made by an
unauthenticated user, the Pages daemon redirects the user to GitLab. If
authentication is successful, the user is redirected back to Pages with a token,
which is persisted in a cookie. The cookies are signed with a secret key, so
tampering can be detected.

Each request to view a resource in a private site is authenticated by Pages
using that token. For each request it receives, it makes a request to the GitLab
API to check that the user is authorized to read that site.

Pages access control is disabled by default. To enable it:

1. Enable it in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Users can now configure it in their [projects' settings](../../user/project/pages/pages_access_control.md).

NOTE: **Important:**
For multi-node setups, in order for this setting to be effective, it has to be applied
to all the App nodes as well as the Sidekiq nodes.

#### Disabling public access to all Pages websites

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32095) in GitLab 12.7.

You can enforce [Access Control](#access-control) for all GitLab Pages websites hosted
on your GitLab instance. By doing so, only logged-in users will have access to them.
This setting overrides Access Control set by users in individual projects.

This can be useful to preserve information published with Pages websites to the users
of your instance only.
To do that:

1. Navigate to your instance's **Admin Area > Settings > Preferences** and expand **Pages** settings.
1. Check the **Disable public access to Pages sites** checkbox.
1. Click **Save changes**.

CAUTION: **Warning:**
This action will not make all currently public web-sites private until they redeployed.
This issue among others will be resolved by
[changing GitLab Pages configuration mechanism](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/282).

### Running behind a proxy

Like the rest of GitLab, Pages can be used in those environments where external
internet connectivity is gated by a proxy. In order to use a proxy for GitLab
pages:

1. Configure in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['http_proxy'] = 'http://example:8080'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

### Using a custom Certificate Authority (CA)

When using certificates issued by a custom CA, [Access Control](../../user/project/pages/pages_access_control.md#gitlab-pages-access-control) and
the [online view of HTML job artifacts](../../ci/pipelines/job_artifacts.md#browsing-artifacts)
will fail to work if the custom CA is not recognized.

This usually results in this error:
`Post /oauth/token: x509: certificate signed by unknown authority`.

For installation from source this can be fixed by installing the custom Certificate
Authority (CA) in the system certificate store.

For Omnibus, normally this would be fixed by [installing a custom CA in Omnibus GitLab](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates)
but a [bug](https://gitlab.com/gitlab-org/gitlab/-/issues/25411) is currently preventing
that method from working. Use the following workaround:

1. Append your GitLab server TLS/SSL certificate to `/opt/gitlab/embedded/ssl/certs/cacert.pem` where `gitlab-domain-example.com` is your GitLab application URL

   ```shell
   printf "\ngitlab-domain-example.com\n===========================\n" | sudo tee --append /opt/gitlab/embedded/ssl/certs/cacert.pem
   echo -n | openssl s_client -connect gitlab-domain-example.com:443  | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | sudo tee --append /opt/gitlab/embedded/ssl/certs/cacert.pem
   ```

1. [Restart](../restart_gitlab.md) the GitLab Pages Daemon. For Omnibus GitLab instances:

   ```shell
   sudo gitlab-ctl restart gitlab-pages
   ```

CAUTION: **Caution:**
Some Omnibus GitLab upgrades will revert this workaround and you'll need to apply it again.

## Activate verbose logging for daemon

Verbose logging was [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/2533) in
Omnibus GitLab 11.1.

Follow the steps below to configure verbose logging of GitLab Pages daemon.

1. By default the daemon only logs with `INFO` level.
   If you wish to make it log events with level `DEBUG` you must configure this in
   `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['log_verbose'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

## Change storage path

Follow the steps below to change the default path where GitLab Pages' contents
are stored.

1. Pages are stored by default in `/var/opt/gitlab/gitlab-rails/shared/pages`.
   If you wish to store them in another location you must set it up in
   `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['pages_path'] = "/mnt/storage/pages"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

## Configure listener for reverse proxy requests

Follow the steps below to configure the proxy listener of GitLab Pages. [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/2533) in
Omnibus GitLab 11.1.

1. By default the listener is configured to listen for requests on `localhost:8090`.

   If you wish to disable it you must configure this in
   `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['listen_proxy'] = nil
   ```

   If you wish to make it listen on a different port you must configure this also in
   `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['listen_proxy'] = "localhost:10080"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

## Set maximum pages size

You can configure the maximum size of the unpacked archive per project in
**Admin Area > Settings > Preferences > Pages**, in **Maximum size of pages (MB)**.
The default is 100MB.

### Override maximum pages size per project or group **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16610) in GitLab 12.7.

To override the global maximum pages size for a specific project:

1. Navigate to your project's **Settings > Pages** page.
1. Edit the **Maximum size of pages**.
1. Click **Save changes**.

To override the global maximum pages size for a specific group:

1. Navigate to your group's **Settings > General** page and expand **Pages**.
1. Edit the **Maximum size of pages**.
1. Click **Save changes**.

## Running GitLab Pages on a separate server

You can run the GitLab Pages daemon on a separate server in order to decrease the load on your main application server.

To configure GitLab Pages on a separate server:

DANGER: **Danger:**
The following procedure includes steps to back up and edit the
`gitlab-secrets.json` file. This file contains secrets that control
database encryption. Proceed with caution.

1. On the **GitLab server**, to enable Pages, add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['enable'] = true
   ```

1. Optionally, to enable [access control](#access-control), add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. [Reconfigure the **GitLab server**](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the
   changes to take effect. The `gitlab-secrets.json` file is now updated with the
   new configuration.

1. Create a backup of the secrets file on the **GitLab server**:

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. Set up a new server. This will become the **Pages server**.

1. Create an [NFS share](../high_availability/nfs_host_client_setup.md) on the new server and configure this share to
   allow access from your main **GitLab server**. For this example, we use the
   default GitLab Pages folder `/var/opt/gitlab/gitlab-rails/shared/pages`
   as the shared folder on the new server and we will mount it to `/mnt/pages`
   on the **GitLab server**.

1. On the **Pages server**, install Omnibus GitLab and modify `/etc/gitlab/gitlab.rb`
   to include:

   ```ruby
   external_url 'http://<ip-address-of-the-server>'
   pages_external_url "http://<your-pages-server-URL>"
   postgresql['enable'] = false
   redis['enable'] = false
   prometheus['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   gitaly['enable'] = false
   alertmanager['enable'] = false
   node_exporter['enable'] = false
   gitlab_rails['auto_migrate'] = false
   ```

1. Create a backup of the secrets file on the **Pages server**:

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the **GitLab server**
   to the **Pages server**.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

1. On the **GitLab server**, make the following changes to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['enable'] = false
   pages_external_url "http://<your-pages-server-URL>"
   gitlab_rails['pages_path'] = "/mnt/pages"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

It is possible to run GitLab Pages on multiple servers if you wish to distribute
the load. You can do this through standard load balancing practices such as
configuring your DNS server to return multiple IPs for your Pages server,
configuring a load balancer to work at the IP level, and so on. If you wish to
set up GitLab Pages on multiple servers, perform the above procedure for each
Pages server.

## Backup

GitLab Pages are part of the [regular backup](../../raketasks/backup_restore.md), so there is no separate backup to configure.

## Security

You should strongly consider running GitLab Pages under a different hostname
than GitLab to prevent XSS attacks.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

## Troubleshooting

### `open /etc/ssl/ca-bundle.pem: permission denied`

GitLab Pages runs inside a chroot jail, usually in a uniquely numbered directory like
`/tmp/gitlab-pages-*`.

Within the jail, a bundle of trusted certificates is
provided at `/etc/ssl/ca-bundle.pem`. It's
[copied there](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/51)
from `/opt/gitlab/embedded/ssl/certs/cacert.pem`
as part of starting up Pages.

If the permissions on the source file are incorrect (they should be `0644`) then
the file inside the chroot jail will also be wrong.

Pages will log errors in `/var/log/gitlab/gitlab-pages/current` like:

```plaintext
x509: failed to load system roots and no roots provided
open /etc/ssl/ca-bundle.pem: permission denied
```

The use of a chroot jail makes this error misleading, as it is not
referring to `/etc/ssl` on the root filesystem.

The fix is to correct the source file permissions and restart Pages:

```shell
sudo chmod 644 /opt/gitlab/embedded/ssl/certs/cacert.pem
sudo gitlab-ctl restart gitlab-pages
```
