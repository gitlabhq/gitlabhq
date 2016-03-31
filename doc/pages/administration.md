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
    - [The GitLab Pages daemon and the case of custom domains](#the-gitlab-pages-daemon-and-the-case-of-custom-domains)
    - [Install the Pages daemon](#install-the-pages-daemon)
- [Configuration](#configuration)
    - [Configuration prerequisites](#configuration-prerequisites)
    - [Configuration scenarios](#configuration-scenarios)
    - [DNS configuration](#dns-configuration)
- [Setting up GitLab Pages](#setting-up-gitlab-pages)
    - [Custom domains with HTTPS support](#custom-domains-with-https-support)
    - [Custom domains without HTTPS support](#custom-domains-without-https-support)
    - [Wildcard HTTP domain without custom domains](#wildcard-http-domain-without-custom-domains)
    - [Wildcard HTTPS domain without custom domains](#wildcard-https-domain-without-custom-domains)
- [NGINX configuration](#nginx-configuration)
    - [NGINX configuration files](#nginx-configuration-files)
    - [NGINX configuration for custom domains](#nginx-configuration-for-custom-domains)
    - [NGINX caveats](#nginx-caveats)
- [Set maximum pages size](#set-maximum-pages-size)
- [Change storage path](#change-storage-path)
- [Backup](#backup)
- [Security](#security)
- [Changelog](#changelog)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## The GitLab Pages daemon

Starting from GitLab EE 8.5, GitLab Pages make use of the [GitLab Pages daemon],
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

[gitlab pages daemon]: https://gitlab.com/gitlab-org/gitlab-pages
[pages-readme]: https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md

### The GitLab Pages daemon and the case of custom domains

In the case of custom domains, the Pages daemon needs to listen on ports `80`
and/or `443`. For that reason, there is some flexibility in the way which you
can set it up, so you basically have three choices:

1. Run the pages daemon in the same server as GitLab, listening on a secondary IP
1. Run the pages daemon in a separate server. In that case, the
   [Pages path](#change-storage-path) must also be present in the server that
   the pages daemon is installed, so you will have to share it via network.
1. Run the pages daemon in the same server as GitLab, listening on the same IP
   but on different ports. In that case, you will have to proxy the traffic with
   a loadbalancer. If you choose that route note that you should use TCP load
   balancing for HTTPS. If you use TLS-termination (HTTPS-load balancing) the
   pages will not be able to be served with user provided certificates. For
   HTTP it's OK to use HTTP or TCP load balancing.

In this document, we will proceed assuming the first option. Let's begin by
installing the pages daemon.

### Install the Pages daemon

**Source installations**

```
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
cd gitlab-pages
sudo -u git -H git checkout v0.2.1
sudo -u git -H make
```

**Omnibus installations**

The `gitlab-pages` daemon is included in the Omnibus package.


## Configuration

There are multiple ways to set up GitLab Pages according to what URL scheme you
are willing to support.

### Configuration prerequisites

In the next section you will find all possible scenarios to choose from.

In either scenario, you will need:

1. To use the [GitLab Pages daemon](#the-gitlab-pages-daemon)
1. A separate domain
1. A separate Nginx configuration file which needs to be explicitly added in
   the server under which GitLab EE runs (Omnibus does that automatically)
1. (Optional) A wildcard certificate for that domain if you decide to serve
   pages under HTTPS
1. (Optional but recommended) [Shared runners](../ci/runners/README.md) so that
   your users don't have to bring their own

### Configuration scenarios

Before proceeding with setting up GitLab Pages, you have to decide which route
you want to take.

The possible scenarios are depicted in the table below.

| URL scheme | Option | Wildcard certificate | Custom domain with HTTP support | Custom domain with HTTPS support | Secondary IP |
| --- |:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `http://page.example.io`  | 1 | no  |  no | no | no |
| `https://page.example.io` | 1 | yes |  no | no | no |
| `http://page.example.io` and `http://page.com`   | 2 | no  |  yes    | no  | yes |
| `https://page.example.io` and `https://page.com` | 2 | yes |  redirects to HTTPS | yes | yes |

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
*.example.io. 1800 IN A 1.2.3.4
```

where `example.io` is the domain under which GitLab Pages will be served
and `1.2.3.4` is the IP address of your GitLab instance.

You should not use the GitLab domain to serve user pages. For more information
see the [security section](#security).

[wiki-wildcard-dns]: https://en.wikipedia.org/wiki/Wildcard_DNS_record

## Setting up GitLab Pages

Below are the four scenarios that are described in
[#configuration-scenarios](#configuration-scenarios).

### Custom domains with HTTPS support

**Source installations:**

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

1. Make sure to [configure NGINX](#nginx-configuration) properly.
1. [Restart GitLab][restart]

---

**Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    pages_external_url "https://example.io"
    nginx['listen_addresses'] = ['1.1.1.1']
    pages_nginx['enable'] = false
    gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
    gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
    gitlab_pages['external_http'] = '1.1.1.2:80'
    gitlab_pages['external_https'] = '1.1.1.2:443'
    ```

    where `1.1.1.1` is the primary IP address that GitLab is listening to and
    `1.1.1.2` the secondary IP where the GitLab Pages daemon listens to.
    Read more at the
    [NGINX configuration for custom domains](#nginx-configuration-for-custom-domains)
    section.

1. [Reconfigure GitLab][reconfigure]

### Custom domains without HTTPS support

**Source installations:**

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

1. Make sure to [configure NGINX](#nginx-configuration) properly.
1. [Restart GitLab][restart]

---

**Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    pages_external_url "https://example.io"
    nginx['listen_addresses'] = ['1.1.1.1']
    pages_nginx['enable'] = false
    gitlab_pages['external_http'] = '1.1.1.2:80'
    ```

    where `1.1.1.1` is the primary IP address that GitLab is listening to and
    `1.1.1.2` the secondary IP where the GitLab Pages daemon listens to.
    Read more at the
    [NGINX configuration for custom domains](#nginx-configuration-for-custom-domains)
    section.

1. [Reconfigure GitLab][reconfigure]

### Wildcard HTTP domain without custom domains

**Source installations:**

1. [Install the pages daemon](#install-the-pages-daemon)
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

1. Make sure to [configure NGINX](#nginx-configuration) properly.
1. [Restart GitLab][restart]

---

**Omnibus installations:**

1. Set the external URL for GitLab Pages in `/etc/gitlab/gitlab.rb`:

    ```ruby
    pages_external_url 'http://example.io'
    ```

1. [Reconfigure GitLab][reconfigure]

### Wildcard HTTPS domain without custom domains

**Source installations:**

1. [Install the pages daemon](#install-the-pages-daemon)
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

1. Make sure to [configure NGINX](#nginx-configuration) properly.

---

**Omnibus installations:**

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

1. [Reconfigure GitLab][reconfigure]

## NGINX configuration

Depending on your setup, you will need to make some changes to NGINX.
Specifically you must change the domain name and the IP address where NGINX
listens to. Read the following sections for more details.

### NGINX configuration files

Copy the `gitlab-pages-ssl` Nginx configuration file:

```bash
sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
```

Replace `gitlab-pages-ssl` with `gitlab-pages` if you are not using SSL.

### NGINX configuration for custom domains

> If you are not using custom domains ignore this section.

[In the case of custom domains](#the-gitlab-pages-daemon-and-the-case-of-custom-domains),
if you have the secondary IP address configured on the same server as GitLab,
you need to change **all** NGINX configs to listen on the first IP address.

**Source installations:**

1. Edit all GitLab related configs in `/etc/nginx/site-available/` and replace
   `0.0.0.0` with `1.1.1.1`, where `1.1.1.1` the primary IP where GitLab
   listens to.
1. Restart NGINX

**Omnibus installations:**

1. Edit `/etc/gitlab/gilab.rb`:

    ```
    nginx['listen_addresses'] = ['1.1.1.1']
    ```

1. [Reconfigure GitLab][reconfigure]

### NGINX caveats

Be extra careful when setting up the domain name in the NGINX config. You must
not remove the backslashes.

If your GitLab pages domain is `example.io`, replace:

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

## Set maximum pages size

The maximum size of the unpacked archive per project can be configured in the
Admin area under the Application settings in the **Maximum size of pages (MB)**.
The default is 100MB.

## Change storage path

**Source installations:**

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

**Omnibus installations:**

1. Pages are stored by default in `/var/opt/gitlab/gitlab-rails/shared/pages`.
   If you wish to store them in another location you must set it up in
   `/etc/gitlab/gitlab.rb`:

     ```ruby
     gitlab_rails['pages_path'] = "/mnt/storage/pages"
     ```

1. [Reconfigure GitLab][reconfigure]

## Backup

Pages are part of the [regular backup][backup] so there is nothing to configure.

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
- Documentation was moved to one place

[8-5-docs]: https://gitlab.com/gitlab-org/gitlab-ee/blob/8-5-stable-ee/doc/pages/administration.md
[gitlab-pages]: https://gitlab.com/gitlab-org/gitlab-pages/tree/v0.2.1
[NGINX configs]: https://gitlab.com/gitlab-org/gitlab-ee/tree/8-5-stable-ee/lib/support/nginx

---

**GitLab 8.4**

No new changes.

---

**GitLab 8.3 ([source docs][8-3-docs], [Omnibus docs][8-3-omnidocs])**

- GitLab Pages feature was introduced.

[8-3-docs]: https://gitlab.com/gitlab-org/gitlab-ee/blob/8-3-stable-ee/doc/pages/administration.md
[8-3-omnidocs]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-3-stable-ee/doc/settings/pages.md
[reconfigure]: ../../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: ../../administration/restart_gitlab.md#installations-from-source
[backup]: ../../raketasks/backup_restore.md
