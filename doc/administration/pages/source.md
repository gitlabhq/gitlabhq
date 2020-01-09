# GitLab Pages administration for source installations

>**Note:**
Before attempting to enable GitLab Pages, first make sure you have
[installed GitLab](../../install/installation.md) successfully.

This is the documentation for configuring a GitLab Pages when you have installed
GitLab from source and not using the Omnibus packages.

You are encouraged to read the [Omnibus documentation](index.md) as it provides
some invaluable information to the configuration of GitLab Pages. Please proceed
to read it before going forward with this guide.

We also highly recommend that you use the Omnibus GitLab packages, as we
optimize them specifically for GitLab, and we will take care of upgrading GitLab
Pages to the latest supported version.

## Overview

GitLab Pages makes use of the [GitLab Pages daemon], a simple HTTP server
written in Go that can listen on an external IP address and provide support for
custom domains and custom certificates. It supports dynamic certificates through
SNI and exposes pages using HTTP2 by default.
You are encouraged to read its [README][pages-readme] to fully understand how
it works.

In the case of [custom domains](#custom-domains) (but not
[wildcard domains](#wildcard-domains)), the Pages daemon needs to listen on
ports `80` and/or `443`. For that reason, there is some flexibility in the way
which you can set it up:

1. Run the Pages daemon in the same server as GitLab, listening on a secondary IP.
1. Run the Pages daemon in a separate server. In that case, the
   [Pages path](#change-storage-path) must also be present in the server that
   the Pages daemon is installed, so you will have to share it via network.
1. Run the Pages daemon in the same server as GitLab, listening on the same IP
   but on different ports. In that case, you will have to proxy the traffic with
   a loadbalancer. If you choose that route note that you should use TCP load
   balancing for HTTPS. If you use TLS-termination (HTTPS-load balancing) the
   pages will not be able to be served with user provided certificates. For
   HTTP it's OK to use HTTP or TCP load balancing.

In this document, we will proceed assuming the first option. If you are not
supporting custom domains a secondary IP is not needed.

## Prerequisites

Before proceeding with the Pages configuration, make sure that:

1. You have a separate domain under which GitLab Pages will be served. In
   this document we assume that to be `example.io`.
1. You have configured a **wildcard DNS record** for that domain.
1. You have installed the `zip` and `unzip` packages in the same server that
   GitLab is installed since they are needed to compress/uncompress the
   Pages artifacts.
1. (Optional) You have a **wildcard certificate** for the Pages domain if you
   decide to serve Pages (`*.example.io`) under HTTPS.
1. (Optional but recommended) You have configured and enabled the [Shared Runners][]
   so that your users don't have to bring their own.

### DNS configuration

GitLab Pages expect to run on their own virtual host. In your DNS server/provider
you need to add a [wildcard DNS A record][wiki-wildcard-dns] pointing to the
host that GitLab runs. For example, an entry would look like this:

```
*.example.io. 1800 IN A 192.0.2.1
```

where `example.io` is the domain under which GitLab Pages will be served
and `192.0.2.1` is the IP address of your GitLab instance.

> **Note:**
You should not use the GitLab domain to serve user pages. For more information
see the [security section](#security).

[wiki-wildcard-dns]: https://en.wikipedia.org/wiki/Wildcard_DNS_record

## Configuration

Depending on your needs, you can set up GitLab Pages in 4 different ways.
The following options are listed from the easiest setup to the most
advanced one. The absolute minimum requirement is to set up the wildcard DNS
since that is needed in all configurations.

### Wildcard domains

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)

URL scheme: `http://page.example.io`

This is the minimum setup that you can use Pages with. It is the base for all
other setups as described below. NGINX will proxy all requests to the daemon.
The Pages daemon doesn't listen to the outside world.

1. Install the Pages daemon:

   ```
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Go to the GitLab installation directory:

   ```bash
   cd /home/git/gitlab
   ```

1. Edit `gitlab.yml` and under the `pages` setting, set `enabled` to `true` and
   the `host` to the FQDN under which GitLab Pages will be served:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 80
     https: false
   ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain` must match the `host` setting that you set above.

   ```
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090"
   ```

1. Copy the `gitlab-pages` NGINX configuration file:

   ```bash
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. Restart NGINX
1. [Restart GitLab][restart]

### Wildcard domains with TLS support

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate

URL scheme: `https://page.example.io`

NGINX will proxy all requests to the daemon. Pages daemon doesn't listen to the
outside world.

1. Install the Pages daemon:

   ```
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. In `gitlab.yml`, set the port to `443` and https to `true`:

   ```bash
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

   ```
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key
   ```

1. Copy the `gitlab-pages-ssl` NGINX configuration file:

   ```bash
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. Restart NGINX
1. [Restart GitLab][restart]

## Advanced configuration

In addition to the wildcard domains, you can also have the option to configure
GitLab Pages to work with custom domains. Again, there are two options here:
support custom domains with and without TLS certificates. The easiest setup is
that without TLS certificates.

### Custom domains

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Secondary IP

URL scheme: `http://page.example.io` and `http://domain.com`

In that case, the pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains are supported, but no TLS.

1. Install the Pages daemon:

   ```
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Edit `gitlab.yml` to look like the example below. You need to change the
   `host` to the FQDN under which GitLab Pages will be served. Set
   `external_http` to the secondary IP on which the pages daemon will listen
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

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain` and `-listen-http` must match the `host` and `external_http`
   settings that you set above respectively:

   ```
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80"
   ```

1. Copy the `gitlab-pages-ssl` NGINX configuration file:

   ```bash
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. Edit all GitLab related configs in `/etc/nginx/site-available/` and replace
   `0.0.0.0` with `192.0.2.1`, where `192.0.2.1` the primary IP where GitLab
   listens to.
1. Restart NGINX
1. [Restart GitLab][restart]

### Custom domains with TLS support

**Requirements:**

- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate
- Secondary IP

URL scheme: `https://page.example.io` and `https://domain.com`

In that case, the pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains and TLS are supported.

1. Install the Pages daemon:

   ```
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Edit `gitlab.yml` to look like the example below. You need to change the
   `host` to the FQDN under which GitLab Pages will be served. Set
   `external_http` and `external_https` to the secondary IP on which the pages
   daemon will listen for connections:

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
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain`, `-listen-http` and `-listen-https` must match the `host`,
   `external_http` and `external_https` settings that you set above respectively.
   The `-root-cert` and `-root-key` settings are the wildcard TLS certificates
   of the `example.io` domain:

   ```
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80 -listen-https 192.0.2.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key
   ```

1. Copy the `gitlab-pages-ssl` NGINX configuration file:

   ```bash
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. Edit all GitLab related configs in `/etc/nginx/site-available/` and replace
   `0.0.0.0` with `192.0.2.1`, where `192.0.2.1` the primary IP where GitLab
   listens to.
1. Restart NGINX
1. [Restart GitLab][restart]

## NGINX caveats

>**Note:**
The following information applies only for installations from source.

Be extra careful when setting up the domain name in the NGINX config. You must
not remove the backslashes.

If your GitLab Pages domain is `example.io`, replace:

```bash
server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
```

with:

```
server_name ~^.*\.example\.io$;
```

If you are using a subdomain, make sure to escape all dots (`.`) except from
the first one with a backslash (\). For example `pages.example.io` would be:

```
server_name ~^.*\.pages\.example\.io$;
```

## Access control

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/33422) in GitLab 11.5.

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

1. Modify your `config/gitlab.yml` file:

   ```yaml
   pages:
     access_control: true
   ```

1. [Restart GitLab][restart].
1. Create a new [system OAuth application](../../integration/oauth_provider.md#adding-an-application-through-the-profile).
   This should be called `GitLab Pages` and have a `Redirect URL` of
   `https://projects.example.io/auth`. It does not need to be a "trusted"
   application, but it does need the `api` scope.
1. Start the Pages daemon with the following additional arguments:

   ```shell
     -auth-client-secret <OAuth code generated by GitLab> \
     -auth-redirect-uri http://projects.example.io/auth \
     -auth-secret <40 random hex characters> \
     -auth-server <URL of the GitLab instance>
   ```

1. Users can now configure it in their [projects' settings](../../user/project/pages/introduction.md#gitlab-pages-access-control-core).

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

1. [Restart GitLab][restart]

## Set maximum Pages size

The maximum size of the unpacked archive per project can be configured in
**Admin Area > Settings > Preferences > Pages**, in **Maximum size of pages (MB)**.
The default is 100MB.

## Backup

Pages are part of the [regular backup][backup] so there is nothing to configure.

## Security

You should strongly consider running GitLab Pages under a different hostname
than GitLab to prevent XSS attacks.

[backup]: ../../raketasks/backup_restore.md
[ee-80]: https://gitlab.com/gitlab-org/gitlab/merge_requests/80
[ee-173]: https://gitlab.com/gitlab-org/gitlab/merge_requests/173
[gitlab pages daemon]: https://gitlab.com/gitlab-org/gitlab-pages
[NGINX configs]: https://gitlab.com/gitlab-org/gitlab/tree/8-5-stable-ee/lib/support/nginx
[pages-readme]: https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md
[pages-userguide]: ../../user/project/pages/index.md
[restart]: ../restart_gitlab.md#installations-from-source
[gitlab-pages]: https://gitlab.com/gitlab-org/gitlab-pages/tree/v0.4.0
[gl-example]: https://gitlab.com/gitlab-org/gitlab/blob/master/lib/support/init.d/gitlab.default.example
[shared runners]: ../../ci/runners/README.md
