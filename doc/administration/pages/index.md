---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: 'Learn how to administer GitLab Pages.'
---

# GitLab Pages administration **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80) in GitLab EE 8.3.
> - Custom CNAMEs with TLS support were [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173) in GitLab EE 8.5.
> - GitLab Pages [was ported](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/14605) to Community Edition in GitLab 8.17.
> - Support for subgroup project's websites was
>   [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30548) in GitLab 11.8.

GitLab Pages allows for hosting of static sites. It must be configured by an
administrator. Separate [user documentation](../../user/project/pages/index.md) is available.

NOTE:
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
   the Pages daemon is installed, so you must share it through the network.
- Run the Pages daemon in the same server as GitLab, listening on the same IP
   but on different ports. In that case, you must proxy the traffic with
   a load balancer. If you choose that route note that you should use TCP load
   balancing for HTTPS. If you use TLS-termination (HTTPS-load balancing), the
   pages can't be served with user-provided certificates. For
   HTTP it's OK to use HTTP or TCP load balancing.

In this document, we proceed assuming the first option. If you are not
supporting custom domains a secondary IP is not needed.

## Prerequisites

Before proceeding with the Pages configuration, you must:

1. Have a domain for Pages that is not a subdomain of your GitLab instance domain.

   | GitLab domain | Pages domain | Does it work? |
   | :---: | :---: | :---: |
   | `example.com` | `example.io` | **{check-circle}** Yes |
   | `example.com` | `pages.example.com` | **{dotted-circle}** No |
   | `gitlab.example.com` | `pages.example.com` | **{check-circle}** Yes |

1. Configure a **wildcard DNS record**.
1. (Optional) Have a **wildcard certificate** for that domain if you decide to
   serve Pages under HTTPS.
1. (Optional but recommended) Enable [Shared runners](../../ci/runners/index.md)
   so that your users don't have to bring their own.
1. (Only for custom domains) Have a **secondary IP**.

NOTE:
If your GitLab instance and the Pages daemon are deployed in a private network or behind a firewall, your GitLab Pages websites are only accessible to devices/users that have access to the private network.

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
*.example.io. 1800 IN AAAA 2001:db8::1
```

Where `example.io` is the domain GitLab Pages is served from,
`192.0.2.1` is the IPv4 address of your GitLab instance, and `2001:db8::1` is the
IPv6 address. If you don't have IPv6, you can omit the AAAA record.

#### Custom domains

If support for custom domains is needed, the Pages root domain and its subdomains should point to
the secondary IP (which is dedicated for the Pages daemon). `<namespace>.<pages root domain>` should
point at Pages directly. Without this, users aren't able to use `CNAME` records to point their
custom domains to their GitLab Pages.

For example, an entry could look like this:

```plaintext
example.com   1800 IN A    192.0.2.1
*.example.io. 1800 IN A    192.0.2.2
```

This example contains the following:

- `example.com`: The GitLab domain.
- `example.io`: The domain GitLab Pages is served from.
- `192.0.2.1`: The primary IP of your GitLab instance.
- `192.0.2.2`: The secondary IP, which is dedicated to GitLab Pages. It must be different than the primary IP.

NOTE:
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

URL scheme: `http://<namespace>.example.io/<project_slug>`

This is the minimum setup that you can use Pages with. It is the base for all
other setups as described below. NGINX proxies all requests to the daemon.
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

URL scheme: `https://<namespace>.example.io/<project_slug>`

NGINX proxies all requests to the daemon. Pages daemon doesn't listen to the
outside world.

1. Place the `example.io` certificate and key inside `/etc/gitlab/ssl`.
1. In `/etc/gitlab/gitlab.rb` specify the following configuration:

   ```ruby
   pages_external_url 'https://example.io'

   pages_nginx['redirect_http_to_https'] = true
   ```

1. If you haven't named your certificate and key `example.io.crt` and `example.io.key`
then you'll need to also add the full paths as shown below:

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. If you're using [Pages Access Control](#access-control), update the redirect URI in the GitLab Pages
[System OAuth application](../../integration/oauth_provider.md#instance-wide-applications)
to use the HTTPS protocol.

WARNING:
Multiple wildcards for one instance is not supported. Only one wildcard per instance can be assigned.

### Additional configuration for Docker container

The GitLab Pages daemon doesn't have permissions to bind mounts when it runs
in a Docker container. To overcome this issue, you must change the `chroot`
behavior:

1. Edit `/etc/gitlab/gitlab.rb`.
1. Set the `inplace_chroot` to `true` for GitLab Pages:

   ```ruby
   gitlab_pages['inplace_chroot'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

NOTE:
`inplace_chroot` option might not work with the other features, such as [Pages Access Control](#access-control).
The [GitLab Pages README](https://gitlab.com/gitlab-org/gitlab-pages#caveats) has more information about caveats and workarounds.

### Global settings

Below is a table of all configuration settings known to Pages in Omnibus GitLab,
and what they do. These options can be adjusted in `/etc/gitlab/gitlab.rb`,
and take effect after you [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
Most of these settings don't need to be configured manually unless you need more granular
control over how the Pages daemon runs and serves content in your environment.

| Setting                                 | Description |
|-----------------------------------------|-------------|
| `pages_external_url`                    | The URL where GitLab Pages is accessible, including protocol (HTTP / HTTPS). If `https://` is used, additional configuration is required. See [Wildcard domains with TLS support](#wildcard-domains-with-tls-support) and [Custom domains with TLS support](#custom-domains-with-tls-support) for details. |
| **`gitlab_pages[]`**                    |  |
| `access_control`                        | Whether to enable [access control](index.md#access-control). |
| `api_secret_key`                        | Full path to file with secret key used to authenticate with the GitLab API. Auto-generated when left unset. |
| `artifacts_server`                      | Enable viewing [artifacts](../job_artifacts.md) in GitLab Pages. |
| `artifacts_server_timeout`              | Timeout (in seconds) for a proxied request to the artifacts server. |
| `artifacts_server_url`                  | API URL to proxy artifact requests to. Defaults to GitLab `external URL` + `/api/v4`, for example `https://gitlab.com/api/v4`. When running a [separate Pages server](#running-gitlab-pages-on-a-separate-server), this URL must point to the main GitLab server's API. |
| `auth_redirect_uri`                     | Callback URL for authenticating with GitLab. Defaults to project's subdomain of `pages_external_url` + `/auth`. |
| `auth_secret`                           | Secret key for signing authentication requests. Leave blank to pull automatically from GitLab during OAuth registration. |
| `dir`                                   | Working directory for configuration and secrets files. |
| `enable`                                | Enable or disable GitLab Pages on the current system. |
| `external_http`                         | Configure Pages to bind to one or more secondary IP addresses, serving HTTP requests. Multiple addresses can be given as an array, along with exact ports, for example `['1.2.3.4', '1.2.3.5:8063']`. Sets value for `listen_http`. |
| `external_https`                        | Configure Pages to bind to one or more secondary IP addresses, serving HTTPS requests. Multiple addresses can be given as an array, along with exact ports, for example `['1.2.3.4', '1.2.3.5:8063']`. Sets value for `listen_https`. |
| `gitlab_client_http_timeout`            | GitLab API HTTP client connection timeout in seconds (default: 10s). |
| `gitlab_client_jwt_expiry`              | JWT Token expiry time in seconds (default: 30s). |
| `gitlab_cache_expiry`                   | The maximum time a domain's configuration is stored in the cache (default: 600s). |
| `gitlab_cache_refresh`                  | The interval at which a domain's configuration is set to be due to refresh (default: 60s). |
| `gitlab_cache_cleanup`                  | The interval at which expired items are removed from the cache (default: 60s). |
| `gitlab_retrieval_timeout`              | The maximum time to wait for a response from the GitLab API per request (default: 30s). |
| `gitlab_retrieval_interval`             | The interval to wait before retrying to resolve a domain's configuration via the GitLab API (default: 1s). |
| `gitlab_retrieval_retries`              | The maximum number of times to retry to resolve a domain's configuration via the API (default: 3). |
| `domain_config_source`                  | This parameter was removed in 14.0, on earlier versions it can be used to enable and test API domain configuration source |
| `gitlab_id`                             | The OAuth application public ID. Leave blank to automatically fill when Pages authenticates with GitLab. |
| `gitlab_secret`                         | The OAuth application secret. Leave blank to automatically fill when Pages authenticates with GitLab. |
| `auth_scope`                            | The OAuth application scope to use for authentication. Must match GitLab Pages OAuth application settings. Leave blank to use `api` scope by default. |
| `gitlab_server`                         | Server to use for authentication when access control is enabled; defaults to GitLab `external_url`. |
| `headers`                               | Specify any additional http headers that should be sent to the client with each response. Multiple headers can be given as an array, header and value as one string, for example `['my-header: myvalue', 'my-other-header: my-other-value']` |
| `inplace_chroot`                        | On [systems that don't support bind-mounts](index.md#additional-configuration-for-docker-container), this instructs GitLab Pages to `chroot` into its `pages_path` directory. Some caveats exist when using in-place `chroot`; refer to the GitLab Pages [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md#caveats) for more information. |
| `enable_disk`                           | Allows the GitLab Pages daemon to serve content from disk. Shall be disabled if shared disk storage isn't available. |
| `insecure_ciphers`                      | Use default list of cipher suites, may contain insecure ones like 3DES and RC4. |
| `internal_gitlab_server`                | Internal GitLab server address used exclusively for API requests. Useful if you want to send that traffic over an internal load balancer. Defaults to GitLab `external_url`. |
| `listen_proxy`                          | The addresses to listen on for reverse-proxy requests. Pages binds to these addresses' network sockets and receives incoming requests from them. Sets the value of `proxy_pass` in `$nginx-dir/conf/gitlab-pages.conf`. |
| `log_directory`                         | Absolute path to a log directory. |
| `log_format`                            | The log output format: `text` or `json`. |
| `log_verbose`                           | Verbose logging, true/false. |
| `propagate_correlation_id`              | Set to true (false by default) to re-use existing Correlation ID from the incoming request header `X-Request-ID` if present. If a reverse proxy sets this header, the value is propagated in the request chain. |
| `max_connections`                       | Limit on the number of concurrent connections to the HTTP, HTTPS or proxy listeners. |
| `metrics_address`                       | The address to listen on for metrics requests. |
| `redirect_http`                         | Redirect pages from HTTP to HTTPS, true/false. |
| `sentry_dsn`                            | The address for sending Sentry crash reporting to. |
| `sentry_enabled`                        | Enable reporting and logging with Sentry, true/false. |
| `sentry_environment`                    | The environment for Sentry crash reporting. |
| `status_uri`                            | The URL path for a status page, for example, `/@status`. |
| `tls_max_version`                       | Specifies the maximum SSL/TLS version ("ssl3", "tls1.0", "tls1.1" or "tls1.2"). |
| `tls_min_version`                       | Specifies the minimum SSL/TLS version ("ssl3", "tls1.0", "tls1.1" or "tls1.2"). |
| `use_http2`                             | Enable HTTP2 support. |
| **`gitlab_pages['env'][]`**             |  |
| `http_proxy`                            | Configure GitLab Pages to use an HTTP Proxy to mediate traffic between Pages and GitLab. Sets an environment variable `http_proxy` when starting Pages daemon. |
| **`gitlab_rails[]`**                    |  |
| `pages_domain_verification_cron_worker` | Schedule for verifying custom GitLab Pages domains. |
| `pages_domain_ssl_renewal_cron_worker`  | Schedule for obtaining and renewing SSL certificates through Let's Encrypt for GitLab Pages domains. |
| `pages_domain_removal_cron_worker`      | Schedule for removing unverified custom GitLab Pages domains. |
| `pages_path`                            | The directory on disk where pages are stored, defaults to `GITLAB-RAILS/shared/pages`. |
| **`pages_nginx[]`**                     |  |
| `enable`                                | Include a virtual host `server{}` block for Pages inside NGINX. Needed for NGINX to proxy traffic back to the Pages daemon. Set to `false` if the Pages daemon should directly receive all requests, for example, when using [custom domains](index.md#custom-domains). |
| `FF_ENABLE_REDIRECTS`                   | Feature flag to disable redirects (enabled by default). Read the [redirects documentation](../../user/project/pages/redirects.md#disable-redirects) for more information. |
| `use_legacy_storage`                    | Temporarily-introduced parameter allowing to use legacy domain configuration source and storage. [Will be removed in GitLab 14.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6166). |

---

## Advanced configuration

In addition to the wildcard domains, you can also have the option to configure
GitLab Pages to work with custom domains. Again, there are two options here:
support custom domains with and without TLS certificates. The easiest setup is
that without TLS certificates. In either case, you need a **secondary IP**. If
you have IPv6 as well as IPv4 addresses, you can use them both.

### Custom domains

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Secondary IP

---

URL scheme: `http://<namespace>.example.io/<project_slug>` and `http://custom-domain.com`

In that case, the Pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains are supported, but no TLS.

1. In `/etc/gitlab/gitlab.rb` specify the following configuration:

   ```ruby
   pages_external_url "http://example.io"
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   ```

   If you don't have IPv6, you can omit the IPv6 address.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Custom domains with TLS support

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate
- Secondary IP

---

URL scheme: `https://<namespace>.example.io/<project_slug>` and `https://custom-domain.com`

In that case, the Pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains and TLS are supported.

1. Place the `example.io` certificate and key inside `/etc/gitlab/ssl`.
1. In `/etc/gitlab/gitlab.rb` specify the following configuration:

   ```ruby
   pages_external_url "https://example.io"
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['external_https'] = ['192.0.2.2:443', '[2001:db8::2]:443'] # The secondary IPs for the GitLab Pages daemon
   # Redirect pages from HTTP to HTTPS
   gitlab_pages['redirect_http'] = true
   ```

   If you don't have IPv6, you can omit the IPv6 address.

1. If you haven't named your certificate and key `example.io.crt` and `example.io.key` respectively,
then you need to also add the full paths as shown below:

   ```ruby
   gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
   gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. If you're using [Pages Access Control](#access-control), update the redirect URI in the GitLab Pages
[System OAuth application](../../integration/oauth_provider.md#instance-wide-applications)
to use the HTTPS protocol.

### Custom domain verification

To prevent malicious users from hijacking domains that don't belong to them,
GitLab supports [custom domain verification](../../user/project/pages/custom_domains_ssl_tls_certification/index.md#steps).
When adding a custom domain, users are required to prove they own it by
adding a GitLab-controlled verification code to the DNS records for that domain.

If your user base is private or otherwise trusted, you can disable the
verification requirement:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Pages**.
1. Clear the **Require users to prove ownership of custom domains** checkbox.
   This setting is enabled by default.

### Let's Encrypt integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28996) in GitLab 12.1.

[GitLab Pages' Let's Encrypt integration](../../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)
allows users to add Let's Encrypt SSL certificates for GitLab Pages
sites served under a custom domain.

To enable it, you must:

1. Choose an email address on which you want to receive notifications about expiring domains.
1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Pages**.
1. Enter the email address for receiving notifications and accept Let's Encrypt's Terms of Service as shown below.
1. Select **Save changes**.

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

NOTE:
For this setting to be effective with multi-node setups, it has to be applied to
all the App nodes and Sidekiq nodes.

#### Using Pages with reduced authentication scope

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/423) in GitLab 13.10.

By default, the Pages daemon uses the `api` scope to authenticate. You can configure this. For
example, this reduces the scope to `read_api` in `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_pages['auth_scope'] = 'read_api'
```

The scope to use for authentication must match the GitLab Pages OAuth application settings. Users of
pre-existing applications must modify the GitLab Pages OAuth application. Follow these steps to do
this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Applications**.
1. Expand **GitLab Pages**.
1. Clear the `api` scope's checkbox and select the desired scope's checkbox (for example,
   `read_api`).
1. Select **Save changes**.

#### Disabling public access to all Pages websites

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32095) in GitLab 12.7.

You can enforce [Access Control](#access-control) for all GitLab Pages websites hosted
on your GitLab instance. By doing so, only logged-in users have access to them.
This setting overrides Access Control set by users in individual projects.

This can be useful to preserve information published with Pages websites to the users
of your instance only.
To do that:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Pages**.
1. Select the **Disable public access to Pages sites** checkbox.
1. Select **Save changes**.

WARNING:
For self-managed installations, all public websites remain private until they are
redeployed. Resolve this issue by
[sourcing domain configuration from the GitLab API](https://gitlab.com/gitlab-org/gitlab/-/issues/218357).

### Running behind a proxy

Like the rest of GitLab, Pages can be used in those environments where external
internet connectivity is gated by a proxy. To use a proxy for GitLab Pages:

1. Configure in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['env']['http_proxy'] = 'http://example:8080'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

### Using a custom Certificate Authority (CA)

When using certificates issued by a custom CA, [Access Control](../../user/project/pages/pages_access_control.md#gitlab-pages-access-control) and
the [online view of HTML job artifacts](../../ci/pipelines/job_artifacts.md#download-job-artifacts)
fails to work if the custom CA is not recognized.

This usually results in this error:
`Post /oauth/token: x509: certificate signed by unknown authority`.

For installation from source, this can be fixed by installing the custom Certificate
Authority (CA) in the system certificate store.

For Omnibus, this is fixed by [installing a custom CA in Omnibus GitLab](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).

### Zip serving and cache configuration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/392) in GitLab 13.7.

WARNING:
These are advanced settings. The recommended default values are set inside GitLab Pages. You should
change these settings only if absolutely necessary. Use extreme caution.

GitLab Pages can serve content from zip archives through object storage (an
[issue](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/485) exists for supporting disk storage
as well). It uses an in-memory cache to increase the performance when serving content from a zip
archive. You can modify the cache behavior by changing the following configuration flags.

| Setting | Description |
| ------- | ----------- |
| `zip_cache_expiration` | The cache expiration interval of zip archives. Must be greater than zero to avoid serving stale content. Default is 60s. |
| `zip_cache_cleanup` | The interval at which archives are cleaned from memory if they have already expired. Default is 30s. |
| `zip_cache_refresh` | The time interval in which an archive is extended in memory if accessed before `zip_cache_expiration`. This works together with `zip_cache_expiration` to determine if an archive is extended in memory. See the [example below](#zip-cache-refresh-example) for important details. Default is 30s. |
| `zip_open_timeout` | The maximum time allowed to open a zip archive. Increase this time for big archives or slow network connections, as doing so may affect the latency of serving Pages. Default is 30s. |

#### Zip cache refresh example

Archives are refreshed in the cache (extending the time they are held in memory) if they're accessed
before `zip_cache_expiration`, and the time left before expiring is less than or equal to
`zip_cache_refresh`. For example, if `archive.zip` is accessed at time 0s, it expires in 60s (the
default for `zip_cache_expiration`). In the example below, if the archive is opened again after 15s
it is **not** refreshed because the time left for expiry (45s) is greater than `zip_cache_refresh`
(default 30s). However, if the archive is accessed again after 45s (from the first time it was
opened) it's refreshed. This extends the time the archive remains in memory from
`45s + zip_cache_expiration (60s)`, for a total of 105s.

After an archive reaches `zip_cache_expiration`, it's marked as expired and removed on the next
`zip_cache_cleanup` interval.

![Zip cache configuration](img/zip_cache_configuration.png)

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

## Propagating the correlation ID

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/438) in GitLab 13.10.

Setting the `propagate_correlation_id` to true allows installations behind a reverse proxy to generate
and set a correlation ID to requests sent to GitLab Pages. When a reverse proxy sets the header value `X-Request-ID`,
the value propagates in the request chain.
Users [can find the correlation ID in the logs](../troubleshooting/tracing_correlation_id.md#identify-the-correlation-id-for-a-request).

To enable the propagation of the correlation ID:

1. Set the parameter to true in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['propagate_correlation_id'] = true
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

Alternatively, if you have existing Pages deployed you can follow
the below steps to do a no downtime transfer to a new storage location.

1. Pause Pages deployments by setting the following in `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['queue_selector'] = true
   sidekiq['queue_groups'] = [
     "feature_category!=pages"
   ]
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. `rsync` contents from the current storage location to the new storage location: `sudo rsync -avzh --progress /var/opt/gitlab/gitlab-rails/shared/pages/ /mnt/storage/pages`
1. Set the new storage location in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['pages_path'] = "/mnt/storage/pages"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Verify Pages are still being served up as expected.
1. Resume Pages deployments by removing from `/etc/gitlab/gitlab.rb` the `sidekiq` setting set above.
1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Trigger a new Pages deployment and verify it's working as expected.
1. Remove the old Pages storage location: `sudo rm -rf /var/opt/gitlab/gitlab-rails/shared/pages`
1. Verify Pages are still being served up as expected.

## Configure listener for reverse proxy requests

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/2533) in Omnibus GitLab 11.1.

Follow the steps below to configure the proxy listener of GitLab Pages.

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

### Override maximum pages size per project or group **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16610) in GitLab 12.7.

NOTE:
Only GitLab admin users are able to view and override the **Maximum size of Pages** setting.

To override the global maximum pages size for a specific project:

1. Go to your project's **Settings > Pages** page.
1. Edit the **Maximum size of pages**.
1. Click **Save changes**.

To override the global maximum pages size for a specific group:

1. Go to your group's **Settings > General** page and expand **Pages**.
1. Edit the **Maximum size of pages**.
1. Click **Save changes**.

## Running GitLab Pages on a separate server

You can run the GitLab Pages daemon on a separate server to decrease the load on
your main application server.

To configure GitLab Pages on a separate server:

WARNING:
The following procedure includes steps to back up and edit the
`gitlab-secrets.json` file. This file contains secrets that control
database encryption. Proceed with caution.

1. Create a backup of the secrets file on the **GitLab server**:

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. On the **GitLab server**, to enable Pages, add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   ```

1. Optionally, to enable [access control](#access-control), add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. Configure [the object storage and migrate pages data to it](#using-object-storage).

1. [Reconfigure the **GitLab server**](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the
   changes to take effect. The `gitlab-secrets.json` file is now updated with the
   new configuration.

1. Set up a new server. This becomes the **Pages server**.

1. On the **Pages server**, install Omnibus GitLab and modify `/etc/gitlab/gitlab.rb`
   to include:

   ```ruby
   roles ['pages_role']

   pages_external_url "http://<pages_server_URL>"

   gitlab_pages['gitlab_server'] = 'http://<gitlab_server_IP_or_URL>'
   ```

1. Create a backup of the secrets file on the **Pages server**:

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the **GitLab server**
   to the **Pages server**.

   ```shell
   # On the GitLab server
   cp /etc/gitlab/gitlab-secrets.json /mnt/pages/gitlab-secrets.json

   # On the Pages server
   mv /var/opt/gitlab/gitlab-rails/shared/pages/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

1. On the **GitLab server**, make the following changes to `/etc/gitlab/gitlab.rb`:

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   gitlab_pages['enable'] = false
   pages_nginx['enable'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

It's possible to run GitLab Pages on multiple servers if you wish to distribute
the load. You can do this through standard load balancing practices such as
configuring your DNS server to return multiple IPs for your Pages server,
configuring a load balancer to work at the IP level, and so on. If you wish to
set up GitLab Pages on multiple servers, perform the above procedure for each
Pages server.

## Domain source configuration

When GitLab Pages daemon serves pages requests it firstly needs to identify which project should be used to
serve the requested URL and how its content is stored.

Before GitLab 13.3, all pages content was extracted to the special shared directory,
and each project had a special configuration file.
The Pages daemon was reading these configuration files and storing their content in memory.

This approach had several disadvantages and was replaced with GitLab Pages using the internal GitLab API
every time a new domain is requested.
The domain information is also cached by the Pages daemon to speed up subsequent requests.

From [GitLab 13.3 to GitLab 13.12](#domain-source-configuration-before-140) GitLab Pages supported both ways of obtaining domain information.

Starting from [GitLab 14.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5993) GitLab Pages uses API
by default and fails to start if it can't connect to it.
For common issues, see the [troubleshooting section](#failed-to-connect-to-the-internal-gitlab-api).

For more details see this [blog post](https://about.gitlab.com/blog/2020/08/03/how-gitlab-pages-uses-the-gitlab-api-to-serve-content/).

### Domain source configuration before 14.0

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217912) in GitLab 13.3.

WARNING:
`domain_config_source` parameter is removed and has no effect starting from [GitLab 14.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5993)

From [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/217912) to [GitLab 13.12](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5993) GitLab Pages can either use `disk` or `gitlab` domain configuration source.

We highly advise you to use `gitlab` configuration source as it will make transition to newer versions easier.

To explicitly enable API source:

1. Add the following to your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_pages['domain_config_source'] = "gitlab"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

Or if you want to use legacy configuration source you can:

1. Add the following to your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_pages['domain_config_source'] = "disk"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

### GitLab API cache configuration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/520) in GitLab 13.10.

API-based configuration uses a caching mechanism to improve performance and reliability of serving Pages.
The cache behavior can be modified by changing the cache settings, however, the recommended values are set for you and should only be modified if needed.
Incorrect configuration of these values may result in intermittent
or persistent errors, or the Pages Daemon serving old content.

NOTE:
Expiry, interval and timeout flags use [Golang's duration formatting](https://golang.org/pkg/time/#ParseDuration).
A duration string is a possibly signed sequence of decimal numbers,
each with optional fraction and a unit suffix, such as `300ms`, `1.5h` or `2h45m`.
Valid time units are `ns`, `us` (or `µs`), `ms`, `s`, `m`, `h`.

Examples:

- Increasing `gitlab_cache_expiry` allows items to exist in the cache longer.
This setting might be useful if the communication between GitLab Pages and GitLab Rails
is not stable.

- Increasing `gitlab_cache_refresh` reduces the frequency at which GitLab Pages
requests a domain's configuration from GitLab Rails. This setting might be useful
GitLab Pages generates too many requests to GitLab API and content does not change frequently.

- Decreasing `gitlab_cache_cleanup` removes expired items from the cache more frequently,
reducing the memory usage of your Pages node.

- Decreasing `gitlab_retrieval_timeout` allows you to stop the request to GitLab Rails
more quickly. Increasing it allows more time to receive a response from the API,
useful in slow networking environments.

- Decreasing `gitlab_retrieval_interval` makes requests to the API more frequently,
only when there is an error response from the API, for example a connection timeout.

- Decreasing `gitlab_retrieval_retries` reduces the number of times a domain's
configuration is tried to be resolved automatically before reporting an error.

## Using object storage

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5577) in GitLab 13.6.

[Read more about using object storage with GitLab](../object_storage.md).

### Object storage settings

The following settings are:

- Nested under `pages:` and then `object_store:` on source installations.
- Prefixed by `pages_object_store_` on Omnibus GitLab installations.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Whether object storage is enabled. | `false` |
| `remote_directory` | The name of the bucket where Pages site content is stored. | |
| `connection` | Various connection options described below. | |

NOTE:
If you want to stop using and disconnect the NFS server, you need to [explicitly disable
local storage](#disable-pages-local-storage), and it's only possible after upgrading to GitLab 13.11.

#### S3-compatible connection settings

See [the available connection settings for different providers](../object_storage.md#connection-settings).

In Omnibus installations:

1. Add the following lines to `/etc/gitlab/gitlab.rb` and replace the values with the ones you want:

   ```ruby
   gitlab_rails['pages_object_store_enabled'] = true
   gitlab_rails['pages_object_store_remote_directory'] = "pages"
   gitlab_rails['pages_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   If you use AWS IAM profiles, be sure to omit the AWS access key and secret access key/value
   pairs:

   ```ruby
   gitlab_rails['pages_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

1. [Migrate existing Pages deployments to object storage.](#migrate-pages-deployments-to-object-storage)

In installations from source:

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   pages:
     object_store:
       enabled: true
       remote_directory: "pages" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source)
   for the changes to take effect.

1. [Migrate existing Pages deployments to object storage.](#migrate-pages-deployments-to-object-storage)

## ZIP storage

In GitLab 14.0 the underlying storage format of GitLab Pages is changing from
files stored directly in disk to a single ZIP archive per project.

These ZIP archives can be stored either locally on disk storage or on [object storage](#using-object-storage) if it is configured.

[Starting from GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/245308) ZIP archives are stored every time pages site is updated.

### Migrate legacy storage to ZIP storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59003) in GitLab 13.11.

GitLab tries to
[automatically migrate](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54578)
the old storage format to the new ZIP-based one when you upgrade to GitLab 13.11 or further.
However, some projects may fail to be migrated for different reasons.
To verify that all projects have been migrated successfully, you can manually run the migration:

```shell
gitlab-rake gitlab:pages:migrate_legacy_storage
```

It's safe to interrupt this task and run it multiple times.

There are two most common problems this task can report:

- `Missing public directory` error:

  ```txt
  E, [2021-04-09T13:11:52.534768 #911919] ERROR -- : project_id: 1 /home/vlad/gdk/gitlab/shared/pages/gitlab-org/gitlab-test failed to be migrated in 0.07 seconds: Archive not created. Missing public directory in /home/vlad/gdk/gitlab/shared/pages/gitlab-org/gitlab-test
  ```

  In this case, you should verify that these projects don't have pages deployed, and re-run the migration with an additional flag to mark those projects as not deployed with GitLab Pages:

  ```shell
  sudo PAGES_MIGRATION_MARK_PROJECTS_AS_NOT_DEPLOYED=true gitlab-rake gitlab:pages:migrate_legacy_storage
  ```

- File `is invalid` error:

  ```txt
  E, [2021-04-09T14:43:05.821767 #923322] ERROR -- : project_id: 1 /home/vlad/gdk/gitlab/shared/pages/gitlab-org/gitlab-test failed to be migrated: /home/vlad/gdk/gitlab/shared/pages/gitlab-org/gitlab-test/public/link is invalid, input_dir: /home/vlad/gdk/gitlab/shared/pages/gitlab-org/gitlab-test
  ```

  This error indicates invalid files on disk storage, most commonly symlinks leading outside of the `public` directory.
  You can manually remove these files, or just ignore them during migration:

  ```shell
  sudo PAGES_MIGRATION_IGNORE_INVALID_ENTRIES=true gitlab-rake gitlab:pages:migrate_legacy_storage
  ```

### Rolling back ZIP migration

If you find that migrated data is invalid, you can remove all migrated data by running:

```shell
sudo gitlab-rake gitlab:pages:clean_migrated_zip_storage
```

This does not remove any data from the legacy disk storage and the GitLab Pages daemon automatically falls back
to using that.

### Migrate Pages deployments to object storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325285) in GitLab 13.11.

Existing Pages deployment objects (which store [ZIP archives](#zip-storage)) can similarly be
migrated to [object storage](#using-object-storage).

Migrate your existing Pages deployments from local storage to object storage:

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_object_storage
```

### Rolling Pages deployments back to local storage

After the migration to object storage is performed, you can choose to move your Pages deployments back to local storage:

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_local
```

### Disable Pages local storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301159) in GitLab 13.11.

If you use [object storage](#using-object-storage), you can disable local storage:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['pages_local_store_enabled'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

Starting from GitLab 13.12, this setting also disables the [legacy storage](#migrate-legacy-storage-to-zip-storage), so if you were using NFS to serve Pages, you can completely disconnect from it.

## Migrate GitLab Pages to 14.0

In GitLab 14.0 a number of breaking changes were introduced which may require some user intervention.
The steps below describe the best way to migrate without causing any downtime for your GitLab instance.

If you run GitLab on a single server, then most likely the upgrade process to 14.0 will go smoothly for you
and you will not notice any problem after upgrading.
Regardless, we recommend everyone follow the migration steps to ensure a successful upgrade.
If at any point you run into issues, consult the [troubleshooting section](#troubleshooting).

If your current GitLab version is lower than 13.12, then you first need to update to 13.12.
Updating directly to 14.0 is [not supported](../../update/index.md#upgrade-paths)
and may cause downtime for some web-sites hosted on GitLab Pages. Once you update to 13.12,
migrate GitLab Pages to prepare them for GitLab 14.0:

1. Set [`domain_config_source` to `gitlab`](#domain-source-configuration-before-140), which
is the default starting from GitLab 14.0. Skip this step if you're already running GitLab 14.0 or above.
1. If you want to store your pages content in [object storage](#using-object-storage), make sure to configure it.
If you want to store the pages content locally or continue using an NFS server, skip this step.
1. [Migrate legacy storage to ZIP storage.](#migrate-legacy-storage-to-zip-storage)
1. Upgrade GitLab to 14.0.

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

### How to see GitLab Pages logs

You can see Pages daemon logs by running:

```shell
sudo gitlab-ctl tail gitlab-pages
```

You can also find the log file in `/var/log/gitlab/gitlab-pages/current`.

### `open /etc/ssl/ca-bundle.pem: permission denied`

GitLab Pages runs inside a `chroot` jail, usually in a uniquely numbered directory like
`/tmp/gitlab-pages-*`.

Within the jail, a bundle of trusted certificates is
provided at `/etc/ssl/ca-bundle.pem`. It's
[copied there](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/51)
from `/opt/gitlab/embedded/ssl/certs/cacert.pem`
as part of starting up Pages.

If the permissions on the source file are incorrect (they should be `0644`), then
the file inside the `chroot` jail is also wrong.

Pages logs errors in `/var/log/gitlab/gitlab-pages/current` like:

```plaintext
x509: failed to load system roots and no roots provided
open /etc/ssl/ca-bundle.pem: permission denied
```

The use of a `chroot` jail makes this error misleading, as it is not
referring to `/etc/ssl` on the root file system.

The fix is to correct the source file permissions and restart Pages:

```shell
sudo chmod 644 /opt/gitlab/embedded/ssl/certs/cacert.pem
sudo gitlab-ctl restart gitlab-pages
```

### `dial tcp: lookup gitlab.example.com` and `x509: certificate signed by unknown authority`

When setting both `inplace_chroot` and `access_control` to `true`, you might encounter errors like:

```plaintext
dial tcp: lookup gitlab.example.com on [::1]:53: dial udp [::1]:53: connect: cannot assign requested address
```

Or:

```plaintext
open /opt/gitlab/embedded/ssl/certs/cacert.pem: no such file or directory
x509: certificate signed by unknown authority
```

The reason for those errors is that the files `resolv.conf`, `/etc/hosts/`, `/etc/nsswitch.conf` and `ca-bundle.pem` are missing inside the `chroot`.
The fix is to copy these files inside the `chroot`:

```shell
sudo mkdir -p /var/opt/gitlab/gitlab-rails/shared/pages/etc/ssl
sudo mkdir -p /var/opt/gitlab/gitlab-rails/shared/pages/opt/gitlab/embedded/ssl/certs/

sudo cp /etc/resolv.conf /var/opt/gitlab/gitlab-rails/shared/pages/etc/
sudo cp /etc/hosts /var/opt/gitlab/gitlab-rails/shared/pages/etc/
sudo cp /etc/nsswitch.conf /var/opt/gitlab/gitlab-rails/shared/pages/etc/
sudo cp /opt/gitlab/embedded/ssl/certs/cacert.pem /var/opt/gitlab/gitlab-rails/shared/pages/opt/gitlab/embedded/ssl/certs/
sudo cp /opt/gitlab/embedded/ssl/certs/cacert.pem /var/opt/gitlab/gitlab-rails/shared/pages/etc/ssl/ca-bundle.pem
```

### `unsupported protocol scheme \"\""`

If you see the following error:

```plaintext
{"error":"failed to connect to internal Pages API: Get \"/api/v4/internal/pages/status\": unsupported protocol scheme \"\"","level":"warning","msg":"attempted to connect to the API","time":"2021-06-23T20:03:30Z"}
```

It means you didn't set the HTTP(S) protocol scheme in the Pages server settings.
To fix it:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['gitlab_server'] = "https://<your_pages_domain_name>"
   gitlab_pages['internal_gitlab_server'] = "https://<your_pages_domain_name>"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 502 error when connecting to GitLab Pages proxy when server does not listen over IPv6

In some cases, NGINX might default to using IPv6 to connect to the GitLab Pages
service even when the server does not listen over IPv6. You can identify when
this is happening if you see something similar to the log entry below in the
`gitlab_pages_error.log`:

```plaintext
2020/02/24 16:32:05 [error] 112654#0: *4982804 connect() failed (111: Connection refused) while connecting to upstream, client: 123.123.123.123, server: ~^(?<group>.*)\.pages\.example\.com$, request: "GET /-/group/project/-/jobs/1234/artifacts/artifact.txt HTTP/1.1", upstream: "http://[::1]:8090//-/group/project/-/jobs/1234/artifacts/artifact.txt", host: "group.example.com"
```

To resolve this, set an explicit IP and port for the GitLab Pages `listen_proxy` setting
to define the explicit address that the GitLab Pages daemon should listen on:

```ruby
gitlab_pages['listen_proxy'] = '127.0.0.1:8090'
```

### Intermittent 502 errors or after a few days

If you run Pages on a system that uses `systemd` and
[`tmpfiles.d`](https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html),
you may encounter intermittent 502 errors trying to serve Pages with an error similar to:

```plaintext
dial tcp: lookup gitlab.example.com on [::1]:53: dial udp [::1]:53: connect: no route to host"
```

GitLab Pages creates a [bind mount](https://man7.org/linux/man-pages/man8/mount.8.html)
inside `/tmp/gitlab-pages-*` that includes files like `/etc/hosts`.
However, `systemd` may clean the `/tmp/` directory on a regular basis so the DNS
configuration may be lost.

To stop `systemd` from cleaning the Pages related content:

1. Tell `tmpfiles.d` to not remove the Pages `/tmp` directory:

   ```shell
   echo 'x /tmp/gitlab-pages-*' >> /etc/tmpfiles.d/gitlab-pages-jail.conf
   ```

1. Restart GitLab Pages:

   ```shell
   sudo gitlab-ctl restart gitlab-pages
   ```

### 404 error after transferring the project to a different group or user, or changing project path

If you encounter a `404 Not Found` error a Pages site after transferring a project to
another group or user, or changing project path, you must trigger a domain configuration
update for Pages. To do so, write something in the `.update` file. The Pages daemon
monitors for changes to this file, and reloads the configuration when changes occur.

Use this example to fix a `404 Not Found` error after transferring a project or changing
a project path with Pages:

```shell
date > /var/opt/gitlab/gitlab-rails/shared/pages/.update
```

If you've customized the Pages storage path, adjust the command above to use your custom path.

### 404 error after promoting a Geo secondary to a primary node

These are due to the Pages files not being among the
[supported data types](../geo/replication/datatypes.md#limitations-on-replicationverification).

It is possible to copy the subfolders and files in the [Pages path](#change-storage-path)
to the new primary node to resolve this.
For example, you can adapt the `rsync` strategy from the
[moving repositories documentation](../operations/moving_repositories.md).
Alternatively, run the CI pipelines of those projects that contain a `pages` job again.

### Failed to connect to the internal GitLab API

If you see the following error:

```plaintext
ERRO[0010] Failed to connect to the internal GitLab API after 0.50s  error="failed to connect to internal Pages API: HTTP status: 401"
```

If you are [Running GitLab Pages on a separate server](#running-gitlab-pages-on-a-separate-server)
you must copy the `/etc/gitlab/gitlab-secrets.json` file
from the **GitLab server** to the **Pages server** after upgrading to GitLab 13.3,
as described in that section.

Other reasons may include network connectivity issues between your
**GitLab server** and your **Pages server** such as firewall configurations or closed ports.
For example, if there is a connection timeout:

```plaintext
error="failed to connect to internal Pages API: Get \"https://gitlab.example.com:3000/api/v4/internal/pages/status\": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)"
```

### Pages cannot communicate with an instance of the GitLab API

If you use the default value for `domain_config_source=auto` and run multiple instances of GitLab
Pages, you may see intermittent 502 error responses while serving Pages content. You may also see
the following warning in the Pages logs:

```plaintext
WARN[0010] Pages cannot communicate with an instance of the GitLab API. Please sync your gitlab-secrets.json file https://gitlab.com/gitlab-org/gitlab-pages/-/issues/535#workaround. error="pages endpoint unauthorized"
```

This can happen if your `gitlab-secrets.json` file is out of date between GitLab Rails and GitLab
Pages. Follow steps 8-10 of [Running GitLab Pages on a separate server](#running-gitlab-pages-on-a-separate-server),
in all of your GitLab Pages instances.

### 500 error with `securecookie: failed to generate random iv` and `Failed to save the session`

This problem most likely results from an [out-dated operating system](https://docs.gitlab.com/omnibus/package-information/deprecated_os.html).
The [Pages daemon uses the `securecookie` library](https://gitlab.com/search?group_id=9970&project_id=734943&repository_ref=master&scope=blobs&search=securecookie&snippets=false) to get random strings via [`crypto/rand` in Go](https://golang.org/pkg/crypto/rand/#pkg-variables).
This requires the `getrandom` system call or `/dev/urandom` to be available on the host OS.
Upgrading to an [officially supported operating system](https://about.gitlab.com/install/) is recommended.

### The requested scope is invalid, malformed, or unknown

This problem comes from the permissions of the GitLab Pages OAuth application. To fix it:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Applications > GitLab Pages**.
1. Edit the application.
1. Under **Scopes**, ensure that the `api` scope is selected.
1. Save your changes.

When running a [separate Pages server](#running-gitlab-pages-on-a-separate-server),
this setting needs to be configured on the main GitLab server.

### Workaround in case no wildcard DNS entry can be set

If the wildcard DNS [prerequisite](#prerequisites) can't be met, you can still use GitLab Pages in a limited fashion:

1. [Move](../../user/project/settings/index.md#transferring-an-existing-project-into-another-namespace)
   all projects you need to use Pages with into a single group namespace, for example `pages`.
1. Configure a [DNS entry](#dns-configuration) without the `*.`-wildcard, for example `pages.example.io`.
1. Configure `pages_external_url http://example.io/` in your `gitlab.rb` file.
   Omit the group namespace here, because it automatically is prepended by GitLab.

### Pages daemon fails with permission denied errors

If `/tmp` is mounted with `noexec`, the Pages daemon fails to start with an error like:

```plaintext
{"error":"fork/exec /gitlab-pages: permission denied","level":"fatal","msg":"could not create pages daemon","time":"2021-02-02T21:54:34Z"}
```

In this case, change `TMPDIR` to a location that is not mounted with `noexec`. Add the following to
`/etc/gitlab/gitlab.rb`:

```ruby
gitlab_pages['env'] = {'TMPDIR' => '<new_tmp_path>'}
```

Once added, reconfigure with `sudo gitlab-ctl reconfigure` and restart GitLab with
`sudo gitlab-ctl restart`.

### `The redirect URI included is not valid.` when using Pages Access Control

Verify that the **Callback URL**/Redirect URI in the GitLab Pages [System OAuth application](../../integration/oauth_provider.md#instance-wide-applications)
is using the protocol (HTTP or HTTPS) that `pages_external_url` is configured to use.

### 500 error `cannot serve from disk`

If you get a 500 response from Pages and encounter an error similar to:

```plaintext
ERRO[0145] cannot serve from disk                        error="gitlab: disk access is disabled via enable-disk=false" project_id=27 source_path="file:///shared/pages/@hashed/67/06/670671cd97404156226e507973f2ab8330d3022ca96e0c93bdbdb320c41adcaf/pages_deployments/14/artifacts.zip" source_type=zip
```

It means that GitLab Rails is telling GitLab Pages to serve content from a location on disk,
however, GitLab Pages was configured to disable disk access.

To enable disk access:

1. Enable disk access for GitLab Pages in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['enable_disk'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### `httprange: new resource 403`

If you see an error similar to:

```plaintext
{"error":"httprange: new resource 403: \"403 Forbidden\"","host":"root.pages.example.com","level":"error","msg":"vfs.Root","path":"/pages1/","time":"2021-06-10T08:45:19Z"}
```

And you run pages on the separate server syncing files via NFS, it may mean that
the shared pages directory is mounted on a different path on the main GitLab server and the
GitLab Pages server.

In that case, it's highly recommended you to configure
[object storage and migrate any existing pages data to it](#using-object-storage).

Alternatively, you can mount the GitLab Pages shared directory to the same path on
both servers.

### GitLab Pages doesn't work after upgrading to GitLab 14.0 or above

GitLab 14.0 introduces a number of changes to GitLab Pages which may require manual intervention.

1. Firstly [follow the migration guide](#migrate-gitlab-pages-to-140).
1. If it doesn't work, see [GitLab Pages logs](#how-to-see-gitlab-pages-logs), and if you see any errors there then search them on this page.

The most common problem is when using [`inplace_chroot`](#dial-tcp-lookup-gitlabexamplecom-and-x509-certificate-signed-by-unknown-authority).

WARNING:
As the last resort you can temporarily enable legacy storage and configuration mechanisms. Support for them [will be removed in GitLab 14.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6166), so GitLab Pages will stop working if don't resolve the underlying issue.

To do that:

1. Please describe the issue you're seeing in [here](https://gitlab.com/gitlab-org/gitlab/-/issues/331699).

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['use_legacy_storage'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
