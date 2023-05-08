---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Pages administration **(FREE SELF)**

GitLab Pages allows for hosting of static sites. It must be configured by an
administrator. Separate [user documentation](../../user/project/pages/index.md) is available.

NOTE:
This guide is for Omnibus GitLab installations. If you have installed
GitLab from source, see
[GitLab Pages administration for source installations](source.md).

## The GitLab Pages daemon

GitLab Pages makes use of the [GitLab Pages daemon](https://gitlab.com/gitlab-org/gitlab-pages), a basic HTTP server
written in Go that can listen on an external IP address and provide support for
custom domains and custom certificates. It supports dynamic certificates through
Server Name Indication (SNI) and exposes pages using HTTP2 by default.
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
   a load balancer. If you choose that route, you should use TCP load
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
1. Optional. Have a **wildcard certificate** for that domain if you decide to
   serve Pages under HTTPS.
1. Optional but recommended. Enable [Shared runners](../../ci/runners/index.md)
   so that your users don't have to bring their own.
1. For custom domains, have a **secondary IP**.

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
added `gitlab.io` [in 2016](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/230).

### DNS configuration

GitLab Pages expect to run on their own virtual host. In your DNS server/provider
add a [wildcard DNS `A` record](https://en.wikipedia.org/wiki/Wildcard_DNS_record) pointing to the
host that GitLab runs. For example, an entry would look like this:

```plaintext
*.example.io. 1800 IN A    192.0.2.1
*.example.io. 1800 IN AAAA 2001:db8::1
```

Where `example.io` is the domain GitLab Pages is served from,
`192.0.2.1` is the IPv4 address of your GitLab instance, and `2001:db8::1` is the
IPv6 address. If you don't have IPv6, you can omit the `AAAA` record.

#### DNS configuration for custom domains

If support for custom domains is needed, all subdomains of the Pages root domain should point to the
secondary IP (which is dedicated for the Pages daemon). Without this configuration, users can't use
`CNAME` records to point their custom domains to their GitLab Pages.

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
because that is needed in all configurations.

### Wildcard domains

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)

---

URL scheme: `http://<namespace>.example.io/<project_slug>`

The following is the minimum setup that you can use Pages with. It is the base for all
other setups as described below. NGINX proxies all requests to the daemon.
The Pages daemon doesn't listen to the outside world.

1. Set the external URL for GitLab Pages in `/etc/gitlab/gitlab.rb`:

   ```ruby
   external_url "http://gitlab.example.com" # external_url here is only for reference
   pages_external_url "http://pages.example.com" # not a subdomain of external_url
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

Watch the [video tutorial](https://youtu.be/dD8c7WNcc6s) for this configuration.

### Wildcard domains with TLS support

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- TLS certificate. Can be either Wildcard, or any other type meeting the [requirements](../../user/project/pages/custom_domains_ssl_tls_certification/index.md#manual-addition-of-ssltls-certificates).

---

URL scheme: `https://<namespace>.example.io/<project_slug>`

NGINX proxies all requests to the daemon. Pages daemon doesn't listen to the
outside world.

1. Place the `example.io` certificate and key inside `/etc/gitlab/ssl`.
1. In `/etc/gitlab/gitlab.rb` specify the following configuration:

   ```ruby
   external_url "https://gitlab.example.com" # external_url here is only for reference
   pages_external_url "https://pages.example.com" # not a subdomain of external_url

   pages_nginx['redirect_http_to_https'] = true
   ```

1. If you haven't named your certificate and key `example.io.crt` and `example.io.key`,
you must also add the full paths as shown below:

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. If you're using [Pages Access Control](#access-control), update the redirect URI in the GitLab Pages
[System OAuth application](../../integration/oauth_provider.md#create-an-instance-wide-application)
to use the HTTPS protocol.

WARNING:
Multiple wildcards for one instance is not supported. Only one wildcard per instance can be assigned.

WARNING:
GitLab Pages does not update the OAuth application if changes are made to the redirect URI.
Before you reconfigure, remove the `gitlab_pages` section from `/etc/gitlab/gitlab-secrets.json`,
then run `gitlab-ctl reconfigure`. For more information, read
[GitLab Pages does not regenerate OAuth](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947).

### Wildcard domains with TLS-terminating Load Balancer

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- [TLS-terminating load balancer](../../install/aws/manual_install_aws.md#load-balancer)

---

URL scheme: `https://<namespace>.example.io/<project_slug>`

This setup is primarily intended to be used when [installing a GitLab POC on Amazon Web Services](../../install/aws/manual_install_aws.md). This includes a TLS-terminating [classic load balancer](../../install/aws/manual_install_aws.md#load-balancer) that listens for HTTPS connections, manages TLS certificates, and forwards HTTP traffic to the instance.

1. In `/etc/gitlab/gitlab.rb` specify the following configuration:

   ```ruby
   external_url "https://gitlab.example.com" # external_url here is only for reference
   pages_external_url "https://pages.example.com" # not a subdomain of external_url

   pages_nginx['enable'] = true
   pages_nginx['listen_port'] = 80
   pages_nginx['listen_https'] = false
   pages_nginx['redirect_http_to_https'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Global settings

Below is a table of all configuration settings known to Pages in Omnibus GitLab,
and what they do. These options can be adjusted in `/etc/gitlab/gitlab.rb`,
and take effect after you [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
Most of these settings don't have to be configured manually unless you need more granular
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
| `server_shutdown_timeout`               | GitLab Pages server shutdown timeout in seconds (default: `30s`). |
| `gitlab_client_http_timeout`            | GitLab API HTTP client connection timeout in seconds (default: `10s`). |
| `gitlab_client_jwt_expiry`              | JWT Token expiry time in seconds (default: `30s`). |
| `gitlab_cache_expiry`                   | The maximum time a domain's configuration is stored in the cache (default: `600s`). |
| `gitlab_cache_refresh`                  | The interval at which a domain's configuration is set to be due to refresh (default: `60s`). |
| `gitlab_cache_cleanup`                  | The interval at which expired items are removed from the cache (default: `60s`). |
| `gitlab_retrieval_timeout`              | The maximum time to wait for a response from the GitLab API per request (default: `30s`). |
| `gitlab_retrieval_interval`             | The interval to wait before retrying to resolve a domain's configuration via the GitLab API (default: `1s`). |
| `gitlab_retrieval_retries`              | The maximum number of times to retry to resolve a domain's configuration via the API (default: 3). |
| `domain_config_source`                  | This parameter was removed in 14.0, on earlier versions it can be used to enable and test API domain configuration source |
| `gitlab_id`                             | The OAuth application public ID. Leave blank to automatically fill when Pages authenticates with GitLab. |
| `gitlab_secret`                         | The OAuth application secret. Leave blank to automatically fill when Pages authenticates with GitLab. |
| `auth_scope`                            | The OAuth application scope to use for authentication. Must match GitLab Pages OAuth application settings. Leave blank to use `api` scope by default. |
| `auth_cookie_session_timeout`           | Authentication cookie session timeout in seconds (default: `10m`). A value of `0` means the cookie is deleted after the browser session ends. |
| `gitlab_server`                         | Server to use for authentication when access control is enabled; defaults to GitLab `external_url`. |
| `headers`                               | Specify any additional http headers that should be sent to the client with each response. Multiple headers can be given as an array, header and value as one string, for example `['my-header: myvalue', 'my-other-header: my-other-value']` |
| `enable_disk`                           | Allows the GitLab Pages daemon to serve content from disk. Shall be disabled if shared disk storage isn't available. |
| `insecure_ciphers`                      | Use default list of cipher suites, may contain insecure ones like 3DES and RC4. |
| `internal_gitlab_server`                | Internal GitLab server address used exclusively for API requests. Useful if you want to send that traffic over an internal load balancer. Defaults to GitLab `external_url`. |
| `listen_proxy`                          | The addresses to listen on for reverse-proxy requests. Pages binds to these addresses' network sockets and receives incoming requests from them. Sets the value of `proxy_pass` in `$nginx-dir/conf/gitlab-pages.conf`. |
| `log_directory`                         | Absolute path to a log directory. |
| `log_format`                            | The log output format: `text` or `json`. |
| `log_verbose`                           | Verbose logging, true/false. |
| `propagate_correlation_id`              | Set to true (false by default) to re-use existing Correlation ID from the incoming request header `X-Request-ID` if present. If a reverse proxy sets this header, the value is propagated in the request chain. |
| `max_connections`                       | Limit on the number of concurrent connections to the HTTP, HTTPS or proxy listeners. |
| `max_uri_length`                        | The maximum length of URIs accepted by GitLab Pages. Set to 0 for unlimited length. [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5729) in GitLab 14.5.
| `metrics_address`                       | The address to listen on for metrics requests. |
| `redirect_http`                         | Redirect pages from HTTP to HTTPS, true/false. |
| `redirects_max_config_size`             | The maximum size of the `_redirects` file, in bytes (default: 65536). |
| `redirects_max_path_segments`           | The maximum number of path segments allowed in `_redirects` rules URLs (default: 25). |
| `redirects_max_rule_count`              | The maximum number of rules allowed in `_redirects` (default: 1000). |
| `sentry_dsn`                            | The address for sending Sentry crash reporting to. |
| `sentry_enabled`                        | Enable reporting and logging with Sentry, true/false. |
| `sentry_environment`                    | The environment for Sentry crash reporting. |
| `status_uri`                            | The URL path for a status page, for example, `/@status`. |
| `tls_max_version`                       | Specifies the maximum TLS version ("tls1.2" or "tls1.3"). |
| `tls_min_version`                       | Specifies the minimum TLS version ("tls1.2" or "tls1.3"). |
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
| `FF_ENABLE_PLACEHOLDERS`                | Feature flag for rewrites (enabled by default). See [Rewrites](../../user/project/pages/redirects.md#rewrites) for more information.  |
| `use_legacy_storage`                    | Temporarily-introduced parameter allowing to use legacy domain configuration source and storage. [Removed in 14.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6166). |
| `rate_limit_source_ip`                  | Rate limit per source IP in number of requests per second. Set to `0` to disable this feature. |
| `rate_limit_source_ip_burst`            | Rate limit per source IP maximum burst allowed per second. |
| `rate_limit_domain`                     | Rate limit per domain in number of requests per second. Set to `0` to disable this feature. |
| `rate_limit_domain_burst`               | Rate limit per domain maximum burst allowed per second. |
| `rate_limit_tls_source_ip`              | Rate limit per source IP in number of TLS connections per second. Set to `0` to disable this feature. |
| `rate_limit_tls_source_ip_burst`        | Rate limit per source IP maximum TLS connections burst allowed per second. |
| `rate_limit_tls_domain`                 | Rate limit per domain in number of TLS connections per second. Set to `0` to disable this feature. |
| `rate_limit_tls_domain_burst`           | Rate limit per domain maximum TLS connections burst allowed per second. |
| `server_read_timeout`                   | Maximum duration to read the request headers and body. For no timeout, set to `0` or a negative value. Default: `5s` |
| `server_read_header_timeout`            | Maximum duration to read the request headers. For no timeout, set to `0` or a negative value. Default: `1s` |
| `server_write_timeout`                  | Maximum duration to write all files in the response. Larger files require more time. For no timeout, set to `0` or a negative value. Default: `0` |
| `server_keep_alive`                     | The `Keep-Alive` period for network connections accepted by this listener. If `0`, `Keep-Alive` is enabled if supported by the protocol and operating system. If negative, `Keep-Alive` is disabled. Default: `15s` |

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
   external_url "http://gitlab.example.com" # external_url here is only for reference
   pages_external_url "http://pages.example.com" # not a subdomain of external_url
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
   external_url "https://gitlab.example.com" # external_url here is only for reference
   pages_external_url "https://pages.example.com" # not a subdomain of external_url
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['external_https'] = ['192.0.2.2:443', '[2001:db8::2]:443'] # The secondary IPs for the GitLab Pages daemon
   # Redirect pages from HTTP to HTTPS
   gitlab_pages['redirect_http'] = true
   ```

   If you don't have IPv6, you can omit the IPv6 address.

1. If you haven't named your certificate `example.io.crt` and your key `example.io.key`,
then you need to also add the full paths as shown below:

   ```ruby
   gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
   gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. If you're using [Pages Access Control](#access-control), update the redirect URI in the GitLab Pages
[System OAuth application](../../integration/oauth_provider.md#create-an-instance-wide-application)
to use the HTTPS protocol.

### Custom domain verification

To prevent malicious users from hijacking domains that don't belong to them,
GitLab supports [custom domain verification](../../user/project/pages/custom_domains_ssl_tls_certification/index.md#steps).
When adding a custom domain, users are required to prove they own it by
adding a GitLab-controlled verification code to the DNS records for that domain.

WARNING:
Disabling domain verification is unsafe and can lead to various vulnerabilities.
If you *do* disable it, either ensure that the Pages root domain itself does not point to the
secondary IP or add the root domain as custom domain to a project; otherwise, any user can add this
domain as a custom domain to their project.

If your user base is private or otherwise trusted, you can disable the
verification requirement:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Pages**.
1. Clear the **Require users to prove ownership of custom domains** checkbox.
   This setting is enabled by default.

### Let's Encrypt integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28996) in GitLab 12.1.

[GitLab Pages' Let's Encrypt integration](../../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)
allows users to add Let's Encrypt SSL certificates for GitLab Pages
sites served under a custom domain.

To enable it:

1. Choose an email address on which you want to receive notifications about expiring domains.
1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Pages**.
1. Enter the email address for receiving notifications and accept Let's Encrypt's Terms of Service.
1. Select **Save changes**.

### Access control

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

1. Enable [access control](#access-control).
1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Applications**.
1. Expand **GitLab Pages**.
1. Clear the `api` scope's checkbox and select the desired scope's checkbox (for example,
   `read_api`).
1. Select **Save changes**.

#### Disable public access to all Pages sites

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32095) in GitLab 12.7.

You can enforce [Access Control](#access-control) for all GitLab Pages websites hosted
on your GitLab instance. By doing so, only authenticated users have access to them.
This setting overrides Access Control set by users in individual projects.

This can be helpful to restrict information published with Pages websites to the users
of your instance only.
To do that:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Pages**.
1. Select the **Disable public access to Pages sites** checkbox.
1. Select **Save changes**.

### Running behind a proxy

Like the rest of GitLab, Pages can be used in those environments where external
internet connectivity is gated by a proxy. To use a proxy for GitLab Pages:

1. Configure in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['env']['http_proxy'] = 'http://example:8080'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

### Using a custom Certificate Authority (CA)

When using certificates issued by a custom CA, [Access Control](../../user/project/pages/pages_access_control.md) and
the [online view of HTML job artifacts](../../ci/jobs/job_artifacts.md#download-job-artifacts)
fails to work if the custom CA is not recognized.

This usually results in this error:
`Post /oauth/token: x509: certificate signed by unknown authority`.

For installation from source, this can be fixed by installing the custom Certificate
Authority (CA) in the system certificate store.

For Omnibus, this is fixed by [installing a custom CA in Omnibus GitLab](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates).

### ZIP serving and cache configuration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/392) in GitLab 13.7.

WARNING:
These instructions deal with some advanced settings of your GitLab instance. The recommended default values are set inside GitLab Pages. You should
change these settings only if absolutely necessary. Use extreme caution.

GitLab Pages can serve content from ZIP archives through object storage (an
[issue](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/485) exists for supporting disk storage
as well). It uses an in-memory cache to increase the performance when serving content from a ZIP
archive. You can modify the cache behavior by changing the following configuration flags.

| Setting | Description |
| ------- | ----------- |
| `zip_cache_expiration` | The cache expiration interval of ZIP archives. Must be greater than zero to avoid serving stale content. Default is `60s`. |
| `zip_cache_cleanup` | The interval at which archives are cleaned from memory if they have already expired. Default is `30s`. |
| `zip_cache_refresh` | The time interval in which an archive is extended in memory if accessed before `zip_cache_expiration`. This works together with `zip_cache_expiration` to determine if an archive is extended in memory. See the [example below](#zip-cache-refresh-example) for important details. Default is `30s`. |
| `zip_open_timeout` | The maximum time allowed to open a ZIP archive. Increase this time for big archives or slow network connections, as doing so may affect the latency of serving Pages. Default is 30 s. |
| `zip_http_client_timeout` | The maximum time for the ZIP HTTP client. Default is `30m`. |

#### ZIP cache refresh example

Archives are refreshed in the cache (extending the time they are held in memory) if they're accessed
before `zip_cache_expiration`, and the time left before expiring is less than or equal to
`zip_cache_refresh`. For example, if `archive.zip` is accessed at time `0s`, it expires in `60s` (the
default for `zip_cache_expiration`). In the example below, if the archive is opened again after `15s`
it is **not** refreshed because the time left for expiry (`45s`) is greater than `zip_cache_refresh`
(default `30s`). However, if the archive is accessed again after `45s` (from the first time it was
opened) it's refreshed. This extends the time the archive remains in memory from
`45s + zip_cache_expiration (60s)`, for a total of `105s`.

After an archive reaches `zip_cache_expiration`, it's marked as expired and removed on the next
`zip_cache_cleanup` interval.

![ZIP cache configuration](img/zip_cache_configuration.png)

### HTTP Strict Transport Security (HSTS) support

HTTP Strict Transport Security (HSTS) can be enabled through the `gitlab_pages['headers']` configuration option. HSTS informs browsers that the website they are visiting should always provide its content over HTTPS to ensure that attackers cannot force subsequent connections to happen unencrypted. It can also improve loading speed of pages as it prevents browsers from attempting to connect over an unencrypted HTTP channel before being redirected to HTTPS.

```ruby
gitlab_pages['headers'] = ['Strict-Transport-Security: max-age=63072000']
```

### Pages project redirects limits

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/778) in GitLab 15.2.

GitLab Pages comes with a set of default limits for the [`_redirects` file](../../user/project/pages/redirects.md)
to minimize the impact on performance. You can configure these limits if you'd like to increase or decrease the limits.

```ruby
gitlab_pages['redirects_max_config_size'] = 131072
gitlab_pages['redirects_max_path_segments'] = 50
gitlab_pages['redirects_max_rule_count'] = 2000
```

## Activate verbose logging for daemon

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
Users [can find the correlation ID in the logs](../logs/tracing_correlation_id.md#identify-the-correlation-id-for-a-request).

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

## Configure listener for reverse proxy requests

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

## Set global maximum size of each GitLab Pages site **(FREE SELF)**

Prerequisite:

- You must have administrator access to the instance.

To set the global maximum pages size for a project:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Pages**.
1. In **Maximum size of pages**, enter a value. The default is `100`.
1. Select **Save changes**.

## Set maximum size of each GitLab Pages site in a group **(PREMIUM SELF)**

Prerequisite:

- You must have administrator access to the instance.

To set the maximum size of each GitLab Pages site in a group, overriding the inherited setting:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Pages**.
1. Enter a value under **Maximum size** in MB.
1. Select **Save changes**.

## Set maximum size of GitLab Pages site in a project **(PREMIUM SELF)**

Prerequisite:

- You must have administrator access to the instance.

To set the maximum size of GitLab Pages site in a project, overriding the inherited setting:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Pages**.

   If this path is not visible, select **Deployments > Pages**.
   [This location is part of an experiment](../../user/project/pages/index.md#menu-position-test).
1. In **Maximum size of pages**, enter the size in MB.
1. Select **Save changes**.

## Set maximum number of GitLab Pages custom domains for a project

Prerequisite:

- You must have administrator access to the instance.

To set the maximum number of GitLab Pages custom domains for a project:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Preferences**, and expand **Pages**.
1. Enter a value for **Maximum number of custom domains per project**. Use `0` for unlimited domains.
1. Select **Save changes**.

## Set maximum number of files per GitLab Pages website

The total number of file entries (including directories and symlinks) is limited to `200,000` per GitLab Pages website.

You can update the limit in your self-managed instance using the
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).

For more information, see [GitLab application limits](../instance_limits.md#number-of-files-per-gitlab-pages-website).

## Running GitLab Pages on a separate server

You can run the GitLab Pages daemon on a separate server to decrease the load on
your main application server. This configuration does not support mutual TLS (mTLS). See the [corresponding feature proposal](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548) for more information.

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

   ## If access control was enabled on step 3
   gitlab_pages['access_control'] = true
   ```

1. If you have custom UID/GID settings on the **GitLab server**, add them to the **Pages server** `/etc/gitlab/gitlab.rb` as well,
   otherwise running a `gitlab-ctl reconfigure` on the **GitLab server** can change file ownership and cause Pages requests to fail.

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

1. [Reconfigure the **Pages server**](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

1. On the **GitLab server**, make the following changes to `/etc/gitlab/gitlab.rb`:

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   gitlab_pages['enable'] = false
   pages_nginx['enable'] = false
   ```

1. [Reconfigure the **GitLab server**](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

It's possible to run GitLab Pages on multiple servers if you wish to distribute
the load. You can do this through standard load balancing practices such as
configuring your DNS server to return multiple IPs for your Pages server, or
configuring a load balancer to work at the IP level. If you wish to
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
For common issues, see [troubleshooting](troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api).

For more details see this [blog post](https://about.gitlab.com/blog/2020/08/03/how-gitlab-pages-uses-the-gitlab-api-to-serve-content/).

### Domain source configuration before 14.0

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217912) in GitLab 13.3.

WARNING:
`domain_config_source` parameter is removed and has no effect starting from [GitLab 14.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5993)

From [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/217912) to [GitLab 13.12](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5993) GitLab Pages can either use `disk` or `gitlab` domain configuration source.

We highly advise you to use `gitlab` configuration source as it makes transitions to newer versions easier.

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
Expiry, interval and timeout flags use [Go duration formatting](https://pkg.go.dev/time#ParseDuration).
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

For more information, see [object storage](../object_storage.md).

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
If you want to stop using and disconnect the NFS server, you need to
[explicitly disable local storage](#disable-pages-local-storage), and it's only possible after upgrading to GitLab 13.11.

#### S3-compatible connection settings

In GitLab 13.2 and later, you should use the
[consolidated object storage settings](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
This section describes the earlier configuration format.

See [the available connection settings for different providers](../object_storage.md#configure-the-connection-settings).

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
sudo gitlab-rake gitlab:pages:migrate_legacy_storage
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

You can track progress and verify that all Pages deployments migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- `sudo gitlab-rails dbconsole` for Omnibus GitLab 14.1 and earlier.
- `sudo gitlab-rails dbconsole --database main` for Omnibus GitLab 14.2 and later.
- `sudo -u git -H psql -d gitlabhq_production` for source-installed instances.

Verify `objectstg` below (where `store=2`) has count of all Pages deployments:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM pages_deployments;

total | filesystem | objectstg
------+------------+-----------
   10 |          0 |        10
```

After verifying everything is working correctly,
[disable Pages local storage](#disable-pages-local-storage).

### Rolling Pages deployments back to local storage

After the migration to object storage is performed, you can choose to move your Pages deployments back to local storage:

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_local
```

### Disable Pages local storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301159) in GitLab 13.11.

If you use [object storage](#using-object-storage), you can disable local storage to avoid unnecessary disk usage/writes:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['pages_local_store_enabled'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

Starting from GitLab 13.12, this setting also disables the [legacy storage](#migrate-legacy-storage-to-zip-storage), so if you were using NFS to serve Pages, you can completely disconnect from it.

## Prepare GitLab Pages for 14.0

In GitLab 14.0 a number of breaking changes were introduced which may require some user intervention.
The steps below describe the best way to migrate without causing any downtime for your GitLab instance.

A GitLab instance running on a single server typically upgrades to 14.0 smoothly, and there should be minimal issues after the upgrade is complete.
Regardless, you should follow the migration steps to ensure a successful upgrade.
For common issues, see [troubleshooting](troubleshooting.md).

If your current GitLab version is lower than 13.12, then you must first update to 13.12.
Updating directly to 14.0 is [not supported](../../update/index.md#upgrade-paths)
and may cause downtime for some web-sites hosted on GitLab Pages. After you update to 13.12,
migrate GitLab Pages to prepare them for GitLab 14.0:

1. Set [`domain_config_source` to `gitlab`](#domain-source-configuration-before-140), which
is the default starting from GitLab 14.0. Skip this step if you're already running GitLab 14.0 or above.
1. If you want to store your pages content in [object storage](#using-object-storage), make sure to configure it.
If you want to store the pages content locally or continue using an NFS server, skip this step.
1. [Migrate legacy storage to ZIP storage.](#migrate-legacy-storage-to-zip-storage)
1. If you have configured GitLab to store your pages content in [object storage](#using-object-storage),
   [migrate Pages deployments to object storage](#migrate-pages-deployments-to-object-storage)
1. Upgrade GitLab to 14.0.

## Backup

GitLab Pages are part of the [regular backup](../../raketasks/backup_restore.md), so there is no separate backup to configure.

## Security

You should strongly consider running GitLab Pages under a different hostname
than GitLab to prevent XSS attacks.

### Rate limits

You can enforce rate limits to help minimize the risk of a Denial of Service (DoS) attack. GitLab Pages
uses a [token bucket algorithm](https://en.wikipedia.org/wiki/Token_bucket) to enforce rate limiting. By default,
requests or TLS connections that exceed the specified limits are reported but not rejected.

GitLab Pages supports the following types of rate limiting:

- Per `source_ip`. It limits how many requests or TLS connections are allowed from the single client IP address.
- Per `domain`. It limits how many requests or TLS connections are allowed per domain hosted on GitLab Pages. It can be a custom domain like `example.com`, or group domain like `group.gitlab.io`.

HTTP request-based rate limits are enforced using the following:

- `rate_limit_source_ip`: Set the maximum threshold in number of requests per client IP per second. Set to 0 to disable this feature.
- `rate_limit_source_ip_burst`: Sets the maximum threshold of number of requests allowed in an initial outburst of requests per client IP.
  For example, when you load a web page that loads a number of resources at the same time.
- `rate_limit_domain`: Set the maximum threshold in number of requests per hosted pages domain per second. Set to 0 to disable this feature.
- `rate_limit_domain_burst`: Sets the maximum threshold of number of requests allowed in an initial outburst of requests per hosted pages domain.

TLS connection-based rate limits are enforced using the following:

- `rate_limit_tls_source_ip`: Set the maximum threshold in number of TLS connections per client IP per second. Set to 0 to disable this feature.
- `rate_limit_tls_source_ip_burst`: Sets the maximum threshold of number of TLS connections allowed in an initial outburst of TLS connections per client IP.
  For example, when you load a web page from different web browsers at the same time.
- `rate_limit_tls_domain`: Set the maximum threshold in number of TLS connections per hosted pages domain per second. Set to 0 to disable this feature.
- `rate_limit_tls_domain_burst`: Sets the maximum threshold of number of TLS connections allowed in an initial outburst of TLS connections per hosted pages domain.

#### Enable HTTP requests rate limits by source-IP

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/631) in GitLab 14.5.

1. Set rate limits in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['rate_limit_source_ip'] = 20.0
   gitlab_pages['rate_limit_source_ip_burst'] = 600
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

#### Enable HTTP requests rate limits by domain

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/630) in GitLab 14.7.

1. Set rate limits in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['rate_limit_domain'] = 1000
   gitlab_pages['rate_limit_domain_burst'] = 5000
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

#### Enable TLS connections rate limits by source-IP

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/632) in GitLab 14.9.

1. Set rate limits in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['rate_limit_tls_source_ip'] = 20.0
   gitlab_pages['rate_limit_tls_source_ip_burst'] = 600
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

#### Enable TLS connections rate limits by domain

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/632) in GitLab 14.9.

1. Set rate limits in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_pages['rate_limit_tls_domain'] = 1000
   gitlab_pages['rate_limit_tls_domain_burst'] = 5000
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

## Related topics

- [Troubleshooting GitLab Pages administration](troubleshooting.md)
