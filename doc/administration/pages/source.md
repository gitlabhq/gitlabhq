---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages administration for self-compiled installations
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

NOTE:
Before attempting to enable GitLab Pages, first make sure you have
[installed GitLab](../../install/installation.md) successfully.

This document explains how to configure GitLab Pages for self-compiled GitLab installations.

For more information about configuring GitLab Pages for Linux Package installations (recommended), see the [Linux package documentation](_index.md).

The advantage of using the Linux package installation is that it contains the latest supported version of GitLab Pages.

## How GitLab Pages works

GitLab Pages makes use of the [GitLab Pages daemon](https://gitlab.com/gitlab-org/gitlab-pages), a lightweight HTTP server that listens on an external IP address and provides support for
custom domains and certificates. It supports dynamic certificates through
`SNI` and exposes pages using HTTP2 by default.
You are encouraged to read its [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md)
to fully understand how it works.

In the case of [custom domains](#custom-domains) (but not
[wildcard domains](#wildcard-domains)), the Pages daemon needs to listen on
ports `80` and/or `443`. For that reason, there is some flexibility in the way
which you can set it up:

- Run the Pages daemon in the same server as GitLab, listening on a secondary
  IP.
- Run the Pages daemon in a separate server. In that case, the
  [Pages path](#change-storage-path) must also be present in the server that
  the Pages daemon is installed, so you must share it through the network.
- Run the Pages daemon in the same server as GitLab, listening on the same IP
  but on different ports. In that case, you must proxy the traffic with a load
  balancer. If you choose that route, you should use TCP load balancing for
  HTTPS. If you use TLS-termination (HTTPS-load balancing), the pages aren't
  able to be served with user-provided certificates. For HTTP, you can use HTTP
  or TCP load balancing.

In this document, we proceed assuming the first option. If you aren't
supporting custom domains, a secondary IP isn't needed.

## Prerequisites

Before proceeding with the Pages configuration, make sure that:

- You have a separate domain to serve GitLab Pages from. In this document we
  assume that to be `example.io`.
- You have configured a **wildcard DNS record** for that domain.
- You have installed the `zip` and `unzip` packages in the same server that
  GitLab is installed because they are needed to compress and decompress the
  Pages artifacts.
- Optional. You have a **wildcard certificate** for the Pages domain if you
  decide to serve Pages (`*.example.io`) under HTTPS.
- Optional but recommended. You have configured and enabled the [instance runners](../../ci/runners/_index.md)
  so your users don't have to bring their own.

### DNS configuration

GitLab Pages expect to run on their own virtual host. In your DNS server/provider
you need to add a [wildcard DNS `A` record](https://en.wikipedia.org/wiki/Wildcard_DNS_record) pointing to the
host that GitLab runs. For example, an entry would look like this:

```plaintext
*.example.io. 1800 IN A 192.0.2.1
```

Where `example.io` is the domain to serve GitLab Pages from,
and `192.0.2.1` is the IP address of your GitLab instance.

NOTE:
You should not use the GitLab domain to serve user pages. For more information
see the [security section](#security).

## Configuration

Depending on your needs, you can set up GitLab Pages in 4 different ways.
The following options are listed from the easiest setup to the most
advanced one. The absolute minimum requirement is to set up the wildcard DNS
because that is needed in all configurations.

### Wildcard domains

Prerequisites:

- [Wildcard DNS setup](#dns-configuration)

URL scheme: `http://<namespace>.example.io/<project_slug>`

This setup is the minimum you can use Pages with. It is the base for all
other setups as described below. NGINX proxies all requests to the daemon.
The Pages daemon doesn't listen to the outside world.

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

1. Add the following configuration file to
   `/home/git/gitlab-pages/gitlab-pages.conf`, and be sure to change
   `example.io` to the FQDN from which you want to serve GitLab Pages and
   `gitlab.example.com` to the URL of your GitLab instance:

   ```ini
   listen-http=:8090
   pages-root=/home/git/gitlab/shared/pages
   api-secret-key=/home/git/gitlab/gitlab-pages-secret
   pages-domain=example.io
   internal-gitlab-server=https://gitlab.example.com
   ```

   You may use an `http` address, when running GitLab Pages and GitLab on the
   same host. If you use `https` and use a self-signed certificate, be sure to
   make your custom CA available to GitLab Pages. For example, you can do this
   by setting the `SSL_CERT_DIR` environment variable.

1. Add the secret API key:

   ```shell
   sudo -u git -H openssl rand -base64 32 > /home/git/gitlab/gitlab-pages-secret
   ```

1. To enable the pages daemon:

   - If your system uses systemd as init, run:

     ```shell
     sudo systemctl edit gitlab.target
     ```

     In the editor that opens, add the following and save the file:

     ```plaintext
     [Unit]
     Wants=gitlab-pages.service
     ```

   - If your system uses SysV init instead, edit `/etc/default/gitlab` and set
     `gitlab_pages_enabled` to `true`:

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

NGINX proxies all requests to the daemon. Pages daemon doesn't listen to the
outside world.

1. Install the Pages daemon:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. In `gitlab.yml`, set the port to `443` and https to `true`:

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

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain` must match the `host` setting that you set above.
   The `-root-cert` and `-root-key` settings are the wildcard TLS certificates
   of the `example.io` domain:

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

In addition to the wildcard domains, you can also have the option to configure
GitLab Pages to work with custom domains. Again, there are two options here:
support custom domains with and without TLS certificates. The easiest setup is
that without TLS certificates.

### Custom domains

Prerequisites:

- [Wildcard DNS setup](#dns-configuration)
- Secondary IP

URL scheme: `http://<namespace>.example.io/<project_slug>` and `http://custom-domain.com`

In that case, the pages daemon is running. NGINX still proxies requests to
the daemon, but the daemon is also able to receive requests from the outside
world. Custom domains are supported, but no TLS.

1. Install the Pages daemon:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Edit `gitlab.yml` to look like the example below. You need to change the
   `host` to the FQDN to serve GitLab Pages from. Set
   `external_http` to the secondary IP on which the pages daemon listens
   for connections:

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

1. To enable the daemon, edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true`.
   In `gitlab_pages_options`, the value for `-pages-domain` must match the `host` and `-listen-http` must match
   the `external_http`:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80"
   ```

1. Copy the `gitlab-pages-ssl` NGINX configuration file:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. Edit all GitLab related configurations in `/etc/nginx/site-available/` and replace
   `0.0.0.0` with `192.0.2.1`, where `192.0.2.1` the primary IP where GitLab
   listens to.
1. Restart NGINX.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

### Custom domains with TLS support

Prerequisites:

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate
- Secondary IP

URL scheme: `https://<namespace>.example.io/<project_slug>` and `https://custom-domain.com`

In that case, the pages daemon is running. NGINX still proxies requests to
the daemon, but the daemon is also able to receive requests from the outside
world. Custom domains and TLS are supported.

1. Install the Pages daemon:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Edit `gitlab.yml` to look like the example below. You need to change the
   `host` to the FQDN to serve GitLab Pages from. Set
   `external_http` and `external_https` to the secondary IP on which the pages
   daemon listens for connections:

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

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options`, you must match the
   `-pages-domain` with `host`, `-listen-http` with `external_http`, and `-listen-https` with `external_https` settings.
   The `-root-cert` and `-root-key` settings are the wildcard TLS certificates
   of the `example.io` domain:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80 -listen-https 192.0.2.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. Copy the `gitlab-pages-ssl` NGINX configuration file:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. Edit all GitLab related configurations in `/etc/nginx/site-available/` and replace
   `0.0.0.0` with `192.0.2.1`, where `192.0.2.1` the primary IP where GitLab
   listens to.
1. Restart NGINX.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

## NGINX caveats

NOTE:
The following information applies only to self-compiled installations.

Be extra careful when setting up the domain name in the NGINX configuration. You must
not remove the backslashes.

If your GitLab Pages domain is `example.io`, replace:

```nginx
server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
```

with:

```nginx
server_name ~^.*\.example\.io$;
```

If you are using a subdomain, make sure to escape all dots (`.`) except from
the first one with a backslash (\). For example `pages.example.io` would be:

```nginx
server_name ~^.*\.pages\.example\.io$;
```

## Access control

GitLab Pages access control can be configured per project. Access to a Pages
site can be controlled based on a user's membership to that project.

Access control works by registering the Pages daemon as an OAuth application
with GitLab. Whenever a request to access a private Pages site is made by an
unauthenticated user, the Pages daemon redirects the user to GitLab. If
authentication is successful, the user is redirected back to Pages with a token,
which is persisted in a cookie. The cookies are signed with a secret key, so
tampering can be detected.

Each request to view a resource in a private site is authenticated by Pages
using that token. For each request it receives, it makes a request to the GitLab
API to check that the user is authorized to read that site.

Access Control parameters for Pages are set in a configuration file, which
by convention is named `gitlab-pages-config`. The configuration file is passed to
pages using the `-config flag` or `CONFIG` environment variable.

Pages access control is disabled by default. To enable it:

1. Modify your `config/gitlab.yml` file:

   ```yaml
   pages:
     access_control: true
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).
1. Create a new [system OAuth application](../../integration/oauth_provider.md#create-a-user-owned-application).
   This should be called `GitLab Pages` and have a `Redirect URL` of
   `https://projects.example.io/auth`. It does not need to be a "trusted"
   application, but it does need the `api` scope.
1. Start the Pages daemon by passing a configuration file with the following arguments:

   ```shell
     auth-client-id=<OAuth Application ID generated by GitLab>
     auth-client-secret=<OAuth code generated by GitLab>
     auth-redirect-uri='http://projects.example.io/auth'
     auth-secret=<40 random hex characters>
     auth-server=<URL of the GitLab instance>
   ```

1. Users can now configure it in their [projects' settings](../../user/project/pages/pages_access_control.md).

## Change storage path

Follow the steps below to change the default path where GitLab Pages' contents
are stored.

1. Pages are stored by default in `/home/git/gitlab/shared/pages`.
   If you wish to store them in another location you must set it up in
   `gitlab.yml` under the `pages` section:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     path: /mnt/storage/pages
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations).

## Set maximum Pages size

The default for the maximum size of unpacked archives per project is 100 MB.

To change this value:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Pages**.
1. Update the value for **Maximum size of pages (MB)**.

## Backup

Pages are part of the [regular backup](../backup_restore/_index.md) so there is nothing to configure.

## Security

You should strongly consider running GitLab Pages under a different hostname
than GitLab to prevent XSS attacks.
