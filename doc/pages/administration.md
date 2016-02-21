# GitLab Pages Administration

> **Note:**
> This feature was first [introduced][ee-80] in GitLab EE 8.3.
> Custom CNAMEs with TLS support were [introduced][ee-173] in GitLab EE 8.5.

---

This document describes how to set up the _latest_ GitLab Pages feature. Make
sure to read the [changelog](#changelog) if you are upgrading to a new GitLab
version as it may include new features and changes needed to be made in your
configuration.

If you are looking for ways to upload your static content in GitLab Pages, you
probably want to read the [user documentation](README.md).

[ee-80]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/80
[ee-173]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/173

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [The GitLab Pages daemon](#the-gitlab-pages-daemon)
    - [Install the Pages daemon](#install-the-pages-daemon)
- [Configuration](#configuration)
    - [Configuration scenarios](#configuration-scenarios)
    - [DNS configuration](#dns-configuration)
- [Custom domains without TLS](#custom-domains-without-tls)
- [Custom domains with TLS](#custom-domains-with-tls)
- [Wildcard HTTPS domain without custom domains](#wildcard-https-domain-without-custom-domains)
- [Wildcard HTTP domain without custom domains](#wildcard-http-domain-without-custom-domains)
- [Omnibus package installations](#omnibus-package-installations)
- [Set maximum pages size](#set-maximum-pages-size)
- [Change storage path](#change-storage-path)
- [Backup](#backup)
- [Security](#security)
- [Changelog](#changelog)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## The GitLab Pages daemon

Starting from GitLab EE 8.5, Pages make use of a separate tool ([gitlab-pages]),
a simple HTTP server written in Go that can listen on an external IP address
and provide support for custom domains and custom certificates. The GitLab
Pages Daemon supports dynamic certificates through SNI and exposes pages using
HTTP2 by default.

Here is a brief list with what it is supported when using the pages daemon:

- Multiple domains per-project
- One TLS certificate per-domain
  - Validation of certificate
  - Validation of certificate chain
  - Validation of private key against certificate

You are encouraged to read its [README][pages-readme] to fully understand how
it works.

---

In the case of custom domains, the Pages daemon needs to listen on ports `80`
and/or `443`. For that reason, there is some flexibility in the way which you
can set it up, so you basically have three choices:

1. Run the pages daemon in the same server as GitLab, listening on a secondary IP
1. Run the pages daemon in the same server as GitLab, listening on the same IP
   but on different ports. In that case, you will have to proxy the traffic with
   a loadbalancer.
1. Run the pages daemon in a separate server. In that case, the Pages [`path`]
   must also be present in the server that the pages daemon is installed, so
   you will have to share it via network.

[`path`]: https://gitlab.com/gitlab-org/gitlab-ee/blob/8-5-stable-ee/config/gitlab.yml.example#L155

### Install the Pages daemon

**Install the Pages daemon on a source installation**

```
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
cd gitlab-pages
sudo -u git -H git checkout 0.2.0
sudo -u git -H make
```

**Install the Pages daemon on Omnibus**

The `gitlab-pages` daemon is included in the Omnibus package.

[pages-readme]: https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md

## Configuration

There are multiple ways to set up GitLab Pages according to what URL scheme you
are willing to support. Below you will find all possible scenarios to choose
from.

### Configuration scenarios

Before proceeding you have to decide what Pages scenario you want to use.
Remember that in either scenario, you need:

1. A separate domain
1. A separate Nginx configuration file which needs to be explicitly added in
   the server under which GitLab EE runs (Omnibus does that automatically)
1. (Optional) A wildcard certificate for that domain if you decide to serve
   pages under HTTPS
1. (Optional but recommended) [Shared runners](../ci/runners/README.md) so that
   your users don't have to bring their own.

The possible scenarios are depicted in the table below.

| URL scheme | Option | Wildcard certificate | Pages daemon | Custom domain with HTTP support | Custom domain with HTTPS support | Secondary IP |
| --- |:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `http://page.gitlab.io`  | 1 | no  | no | no | no | no |
| `https://page.gitlab.io` | 1 | yes | no | no | no | no |
| `http://page.gitlab.io` and `http://page.com`   | 2 | no  | yes | yes    | no  | yes |
| `https://page.gitlab.io` and `https://page.com` | 2 | yes | yes | yes/no | yes | yes |

As you see from the table above, each URL scheme comes with an option:

1. Pages enabled, daemon is enabled and NGINX will proxy all requests to the
   daemon. Pages daemon doesn't listen to the outside world.
1. Pages enabled, daemon is enabled AND pages has external IP support enabled.
   In that case, the pages daemon is running, NGINX still proxies requests to
   the daemon but the daemon is also able to receive requests from the outside
   world. Custom domains and TLS are supported.

### DNS configuration

GitLab Pages expect to run on their own virtual host. In your DNS server/provider
you need to add a [wildcard DNS A record][wiki-wildcard-dns] pointing to the
host that GitLab runs. For example, an entry would look like this:

```
*.example.com. 60 IN A 1.2.3.4
```

where `example.com` is the domain under which GitLab Pages will be served
and `1.2.3.4` is the IP address of your GitLab instance.

You should not use the GitLab domain to serve user pages. For more information
see the [security section](#security).

### Omnibus package installations

## Custom domains without TLS

1. [Install the pages daemon](#install-the-pages-daemon)
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

       external_http: 1.1.1.1:80
     ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain` and `-listen-http` must match the `host` and `external_http`
   settings that you set above respectively:

    ```
    gitlab_pages_enabled=true
    gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 1.1.1.1:80"
    ```

1. Copy the `gitlab-pages-ssl` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
    ```

    Make sure to edit the config to add your domain as well as correctly point
    to the right location of the SSL certificate files. Restart Nginx for the
    changes to take effect.

1. [Restart GitLab](../../administration/restart_gitlab.md)

## Custom domains with TLS

1. [Install the pages daemon](#install-the-pages-daemon)
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

       external_http: 1.1.1.1:80
       external_https: 1.1.1.1:443
     ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain`, `-listen-http` and `-listen-https` must match the `host`,
   `external_http` and `external_https` settings that you set above respectively.
   The `-root-cert` and `-root-key` settings are the wildcard TLS certificates
   of the `example.io` domain:

    ```
    gitlab_pages_enabled=true
    gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 1.1.1.1:80 -listen-https 1.1.1.1:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key
    ```

1. Copy the `gitlab-pages-ssl` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
    ```

    Make sure to edit the config to add your domain as well as correctly point
    to the right location of the SSL certificate files. Restart Nginx for the
    changes to take effect.

1. [Restart GitLab](../../administration/restart_gitlab.md)

## Wildcard HTTPS domain without custom domains

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

       # The domain under which the pages are served:
       # http://group.example.com/project
       # or project path can be a group page: group.example.com
       host: example.com
       port: 80 # Set to 443 if you serve the pages with HTTPS
       https: false # Set to true if you serve the pages with HTTPS
     ```

1. Make sure you have copied the new `gitlab-pages` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
    ```

    Don't forget to add your domain name in the Nginx config. For example if
    your GitLab pages domain is `example.com`, replace

    ```bash
    server_name ~^(?<group>.*)\.YOUR_GITLAB_PAGES\.DOMAIN$;
    ```

    with

    ```
    server_name ~^(?<group>.*)\.example\.com$;
    ```

    You must be extra careful to not remove the backslashes. If you are using
    a subdomain, make sure to escape all dots (`.`) with a backslash (\).
    For example `pages.example.com` would be:

    ```
    server_name ~^(?<group>.*)\.pages\.example\.com$;
    ```

1. Restart Nginx and GitLab:

    ```bash
    sudo service nginx restart
    sudo service gitlab restart
    ```

### Running GitLab Pages with HTTPS

If you want the pages to be served under HTTPS, a wildcard SSL certificate is
required.

1. In `gitlab.yml`, set the port to `443` and https to `true`:

     ```bash
     ## GitLab Pages
     pages:
       enabled: true
       # The location where pages are stored (default: shared/pages).
       # path: shared/pages

       # The domain under which the pages are served:
       # http://group.example.com/project
       # or project path can be a group page: group.example.com
       host: example.com
       port: 443 # Set to 443 if you serve the pages with HTTPS
       https: true # Set to true if you serve the pages with HTTPS
     ```

1. Copy the `gitlab-pages-ssl` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
    ```

    Make sure to edit the config to add your domain as well as correctly point
    to the right location of the SSL certificate files. Restart Nginx for the
    changes to take effect.

## Set maximum pages size

The maximum size of the unpacked archive per project can be configured in the
Admin area under the Application settings in the **Maximum size of pages (MB)**.
The default is 100MB.

## Change storage path

Pages are stored by default in `/home/git/gitlab/shared/pages`.
If you wish to store them in another location you must set it up in
`gitlab.yml` under the `pages` section:

```yaml
pages:
  enabled: true
  # The location where pages are stored (default: shared/pages).
  path: /mnt/storage/pages
```

Restart GitLab for the changes to take effect:

```bash
sudo service gitlab restart
```

## Backup

Pages are part of the regular backup so there is nothing to configure.

## Security

You should strongly consider running GitLab pages under a different hostname
than GitLab to prevent XSS attacks.

## Changelog

GitLab Pages were first introduced in GitLab EE 8.3. Since then, many features
where added, like custom CNAME and TLS support, and many more are likely to
come. Below is a brief changelog. If no changes were introduced or a version is
missing from the changelog, assume that the documentation is the same as the
latest previous version.

---

**GitLab 8.5 ([documentation][8-5-docs])**

- In GitLab 8.5 we introduced the [gitlab-pages][] daemon which is now the
  recommended way to set up GitLab Pages.
- The [NGINX configs][] have changed to reflect this change. So make sure to
  update them.
- Custom CNAME and TLS certificates support

[8-5-docs]: https://gitlab.com/gitlab-org/gitlab-ee/blob/8-5-stable-ee/doc/pages/administration.md
[gitlab-pages]: https://gitlab.com/gitlab-org/gitlab-pages/tree/v0.2.0
[NGINX configs]: https://gitlab.com/gitlab-org/gitlab-ee/tree/8-5-stable-ee/lib/support/nginx

---

**GitLab 8.4**

No new changes.

---

**GitLab 8.3 ([documentation][8-3-docs])**

- GitLab Pages feature was introduced.

[8-3-docs]: https://gitlab.com/gitlab-org/gitlab-ee/blob/8-3-stable-ee/doc/pages/administration.md

---
