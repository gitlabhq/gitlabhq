---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages administration for self-compiled installations
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

> [!note]
> Before attempting to enable GitLab Pages, first make sure you have
> [installed GitLab](../../install/self_compiled/_index.md) successfully.

This document explains how to configure GitLab Pages for self-compiled GitLab installations.

For more information about configuring GitLab Pages for Linux package installations (recommended),
see the [Linux package documentation](_index.md). The Linux package installation contains the latest
supported version of GitLab Pages.

## How GitLab Pages works

GitLab Pages uses the GitLab Pages daemon, a
lightweight HTTP server that listens on an external IP address and provides support for custom
domains and certificates. It supports dynamic certificates through `SNI` and exposes pages using HTTP2
by default. For more information, see the
[README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md).

For [custom domains](#custom-domains), the Pages daemon must listen on ports `80` or `443`.
This does not apply to [wildcard domains](#wildcard-domains).
You can set it up in one of these ways:

- On the same server as GitLab, listening on a secondary IP.
- On a separate server. The [Pages path](#change-storage-path) must also be present on that server,
  so you must share it over the network.
- On the same server as GitLab, listening on the same IP but on different ports. In this case, you
  must proxy the traffic with a load balancer. For HTTPS, use TCP load balancing. If you use TLS
  termination (HTTPS load balancing), pages cannot be served with user-provided certificates. For
  HTTP, either HTTP or TCP load balancing is acceptable.

The following sections assume the first option. If you are not supporting custom domains, a secondary
IP is not needed.

## Prerequisites

Before proceeding with the Pages configuration, make sure that:

- You have a separate domain to serve GitLab Pages from. In this document, this domain is
  `example.io`.
- You have configured a **wildcard DNS record** for that domain.
- You have installed the `zip` and `unzip` packages on the same server where GitLab is installed.
  The packages are required to compress and decompress Pages artifacts.
- Optional. You have a **wildcard certificate** for the Pages domain (`*.example.io`) if you decide
  to serve Pages under HTTPS.
- Optional but recommended. You have configured and enabled
  [instance runners](../../ci/runners/_index.md) so your users do not have to bring their own.

### DNS configuration

GitLab Pages must run on their own virtual host. In your DNS server or provider, add a
[wildcard DNS `A` record](https://en.wikipedia.org/wiki/Wildcard_DNS_record) pointing to the host
that GitLab runs on. For example:

```plaintext
*.example.io. 1800 IN A 192.0.2.1
```

Where `example.io` is the domain GitLab Pages is served from, and `192.0.2.1` is the IP address of
your GitLab instance.

> [!note]
> Do not use the GitLab domain to serve user pages. For more information, see the
> [security section](#security).

## Configuration

You can set up GitLab Pages in several ways. The following options are listed from the simplest
setup to the most advanced. The minimum requirement for all configurations is a wildcard DNS record.

### Wildcard domains

Each site gets its own subdomain (for example, `<namespace>.example.io/<project_slug>`).
This subdomain requires a wildcard DNS record (`*.example.io`) and is the recommended setup for most instances.

Prerequisites:

- [Wildcard DNS setup](#dns-configuration)

This setup is the minimum you can use Pages with. It is the base for all
other setups as described below. NGINX proxies all requests to the daemon.
The Pages daemon does not listen to the outside world.

1. Install the Pages daemon:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Go to the GitLab installation directory:

   ```shell
   cd /home/git/gitlab
   ```

1. Edit `gitlab.yml` and under the `pages` setting, set `enabled` to `true` and
   the `host` to the FQDN to serve GitLab Pages from:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     access_control: false
     port: 8090
     https: false
     artifacts_server: false
     external_http: ["127.0.0.1:8090"]
     secret_file: /home/git/gitlab/gitlab-pages-secret
   ```

1. Add the following configuration file to `/home/git/gitlab-pages/gitlab-pages.conf`. Replace
   `example.io` with the FQDN to serve GitLab Pages from and `gitlab.example.com` with the URL of
   your GitLab instance:

   ```ini
   listen-http=:8090
   pages-root=/home/git/gitlab/shared/pages
   api-secret-key=/home/git/gitlab/gitlab-pages-secret
   pages-domain=example.io
   internal-gitlab-server=https://gitlab.example.com

   You can use an `http` address when running GitLab Pages and GitLab on the same host. If you use
   `https` with a self-signed certificate, make your custom CA available to GitLab Pages, for
   example by setting the `SSL_CERT_DIR` environment variable.

1. Add the secret API key:

   ```shell
   sudo -u git -H openssl rand -base64 32 > /home/git/gitlab/gitlab-pages-secret
   ```

1. To enable the pages daemon:

   - If your system uses systemd init, run:

     ```shell
     sudo systemctl edit gitlab.target
     ```

     In the editor, add the following and save the file:

     ```plaintext
     [Unit]
     Wants=gitlab-pages.service
     ```

   - If your system uses SysV init, edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to
     `true`:

     ```ini
     gitlab_pages_enabled=true
     ```

1. Copy the `gitlab-pages` NGINX configuration file:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. Restart NGINX.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

### Wildcard domains with TLS support

Prerequisites:

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate

URL scheme: `https://<namespace>.example.io/<project_slug>`

NGINX proxies all requests to the daemon. The Pages daemon does not listen to the public internet.

To configure wildcard domains with TLS support:

1. Install the Pages daemon:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. In `gitlab.yml`, set the `port` to `443` and `https` to `true`:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true
   ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true`. In `gitlab_pages_options`,
   `-pages-domain` must match the `host` value. The `-root-cert` and `-root-key` settings are the
   wildcard TLS certificates for the `example.io` domain:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. Copy the `gitlab-pages-ssl` NGINX configuration file:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. Restart NGINX.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

## Advanced configuration

In addition to wildcard domains, you can configure GitLab Pages to work with custom domains, with
or without TLS certificates.

### Custom domains

Prerequisites:

- [Wildcard DNS setup](#dns-configuration)
- Secondary IP

URL scheme: `http://<namespace>.example.io/<project_slug>` and `http://custom-domain.com`

In this configuration, the Pages daemon is running and NGINX proxies requests to it, but the daemon
can also receive requests from the public internet. Custom domains are supported without TLS.

To configure custom domains:

1. Install the Pages daemon:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Edit `gitlab.yml`. Set `host` to the FQDN to serve GitLab Pages from, and set `external_http` to
   the secondary IP on which the Pages daemon listens:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 80
     https: false

     external_http: 192.0.2.2:80
   ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true`. In `gitlab_pages_options`:

   - `-pages-domain` must match `host`.
   - `-listen-http` must match `external_http`.
   - `-listen-https` must match `external_https`.

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80"
   ```

1. Copy the `gitlab-pages` NGINX configuration file:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. Edit all GitLab-related configurations in `/etc/nginx/site-available/` and replace `0.0.0.0`
   with `192.0.2.1`, where `192.0.2.1` is the primary IP where GitLab listens.
1. Restart NGINX.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

### Custom domains with TLS support

Prerequisites:

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate
- Secondary IP

URL scheme: `https://<namespace>.example.io/<project_slug>` and `https://custom-domain.com`

In this configuration, the Pages daemon is running and NGINX proxies requests to it, but the daemon
can also receive requests from the public internet. Custom domains and TLS are supported.

To configure custom domains with TLS support:

1. Install the Pages daemon:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Edit `gitlab.yml`. Set `host` to the FQDN to serve GitLab Pages from, and set `external_http`
   and `external_https` to the secondary IP on which the Pages daemon listens:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true

     external_http: 192.0.2.2:80
     external_https: 192.0.2.2:443
   ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true`. In `gitlab_pages_options`:

   - `-pages-domain` must match `host`.
   - `-listen-http` must match `external_http`.
   - `-listen-https` must match `external_https`.

   The `-root-cert` and `-root-key` settings are the wildcard TLS certificates for the `example.io` domain:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80 -listen-https 192.0.2.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. Copy the `gitlab-pages-ssl` NGINX configuration file:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. Edit all GitLab-related configurations in `/etc/nginx/site-available/` and replace `0.0.0.0`
   with `192.0.2.1`, where `192.0.2.1` is the primary IP where GitLab listens.
1. Restart NGINX.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

## NGINX caveats

> [!note]
> The following information applies only to self-compiled installations.

Be careful when setting up the domain name in the NGINX configuration. You must not remove the
backslashes.

If your GitLab Pages domain is `example.io`, replace:

```nginx
server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
```

with:

```nginx
server_name ~^.*\.example\.io$;
```

If you are using a subdomain, escape all dots (`.`) except the first one with a backslash (`\`).
For example, `pages.example.io` would be:

```nginx
server_name ~^.*\.pages\.example\.io$;
```

## Access control

GitLab Pages access control can be configured per project. Access to a Pages
site can be controlled based on a user's membership to that project.

Access control works by registering the Pages daemon as an OAuth application with GitLab. Whenever
an unauthenticated user requests access to a private Pages site, the Pages daemon redirects the user
to GitLab. If authentication is successful, the user is redirected back to Pages with a token, which
is persisted in a cookie. The cookies are signed with a secret key, so tampering can be detected.

Each request to view a resource in a private site is authenticated by Pages using that token. For
each request it receives, Pages makes a request to the GitLab API to check that the user is
authorized to read that site.

Access control parameters for Pages are:

- Set in a configuration file by a convention named
`gitlab-pages-config`.
- Passed to Pages using the `-config` flag or `CONFIG` environment variable.

Pages access control is disabled by default. To enable it:

1. Modify `config/gitlab.yml`:

   ```yaml
   pages:
     access_control: true
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).
1. Create a new
   [system OAuth application](../../integration/oauth_provider.md#create-a-user-owned-application).
   Name it `GitLab Pages` and set the **Redirect URL** to `https://projects.example.io/auth`. It
   does not need to be a trusted application, but it does need the `api` scope.
1. Start the Pages daemon by passing a configuration file with the following arguments:

   ```shell
     auth-client-id=<OAuth Application ID generated by GitLab>
     auth-client-secret=<OAuth code generated by GitLab>
     auth-redirect-uri='http://projects.example.io/auth'
     auth-secret=<40 random hex characters>
     auth-server=<URL of the GitLab instance>
   ```

1. Users can now configure it in their
   [project settings](../../user/project/pages/pages_access_control.md).

## Change storage path

To change the default path where GitLab Pages content is stored:

1. Pages are stored by default in `/home/git/gitlab/shared/pages`. To use a different location,
   edit `gitlab.yml` under the `pages` section:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     path: /mnt/storage/pages
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

## Set maximum Pages size

The default maximum size of unpacked archives per project is 100 MB.

Prerequisites:

- Administrator access.

To change this value:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Pages**.
1. Update the value for **Maximum size of pages (MB)**.

## Backup

Pages are part of the [regular backup](../backup_restore/_index.md) so there is nothing to configure.

## Security

You should strongly consider running GitLab Pages under a different hostname
than GitLab to prevent XSS attacks.
