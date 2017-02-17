# GitLab Pages administration for source installations

This is the documentation for configuring a GitLab Pages when you have installed
GitLab from source and not using the Omnibus packages.

You are encouraged to read the [Omnibus documentation](index.md) as it provides
some invaluable information to the configuration of GitLab Pages. Please proceed
to read it before going forward with this guide.

We also highly recommend that you use the Omnibus GitLab packages, as we
optimize them specifically for GitLab, and we will take care of upgrading GitLab
Pages to the latest supported version.

## Overview

[Read the Omnibus overview section.](index.md#overview)

## Prerequisites

[Read the Omnibus prerequisites section.](index.md#prerequisites)

## Configuration

Depending on your needs, you can install GitLab Pages in four different ways.

### Option 1. Custom domains with HTTPS support

| URL scheme | Wildcard certificate | Custom domain with HTTP support | Custom domain with HTTPS support | Secondary IP |
| --- |:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `https://page.example.io` and `https://page.com` | yes |  redirects to HTTPS | yes | yes |

Pages enabled, daemon is enabled AND pages has external IP support enabled.
In that case, the pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains and TLS are supported.

1. Install the Pages daemon:

    ```
    cd /home/git
    sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
    cd gitlab-pages
    sudo -u git -H git checkout v0.2.4
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

       external_http: 1.1.1.2:80
       external_https: 1.1.1.2:443
     ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain`, `-listen-http` and `-listen-https` must match the `host`,
   `external_http` and `external_https` settings that you set above respectively.
   The `-root-cert` and `-root-key` settings are the wildcard TLS certificates
   of the `example.io` domain:

    ```
    gitlab_pages_enabled=true
    gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 1.1.1.2:80 -listen-https 1.1.1.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key
    ```

1. Copy the `gitlab-pages-ssl` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
    ```

      Replace `gitlab-pages-ssl` with `gitlab-pages` if you are not using SSL.

1. Edit all GitLab related configs in `/etc/nginx/site-available/` and replace
   `0.0.0.0` with `1.1.1.1`, where `1.1.1.1` the primary IP where GitLab
   listens to.
1. Restart NGINX
1. [Restart GitLab][restart]

### Option 2. Custom domains without HTTPS support

| URL scheme |  Wildcard certificate | Custom domain with HTTP support | Custom domain with HTTPS support | Secondary IP |
| --- |:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `http://page.example.io` and `http://page.com` | no  |  yes    | no  | yes |

Pages enabled, daemon is enabled AND pages has external IP support enabled.
In that case, the pages daemon is running, NGINX still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains and TLS are supported.

1. Install the Pages daemon:

    ```
    cd /home/git
    sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
    cd gitlab-pages
    sudo -u git -H git checkout v0.2.4
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

       external_http: 1.1.1.2:80
     ```

1. Edit `/etc/default/gitlab` and set `gitlab_pages_enabled` to `true` in
   order to enable the pages daemon. In `gitlab_pages_options` the
   `-pages-domain` and `-listen-http` must match the `host` and `external_http`
   settings that you set above respectively:

    ```
    gitlab_pages_enabled=true
    gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 1.1.1.2:80"
    ```

1. Copy the `gitlab-pages-ssl` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
    ```

      Replace `gitlab-pages-ssl` with `gitlab-pages` if you are not using SSL.

1. Edit all GitLab related configs in `/etc/nginx/site-available/` and replace
   `0.0.0.0` with `1.1.1.1`, where `1.1.1.1` the primary IP where GitLab
   listens to.
1. Restart NGINX
1. [Restart GitLab][restart]

### Option 3. Wildcard HTTPS domain without custom domains

| URL scheme | Wildcard certificate | Custom domain with HTTP support | Custom domain with HTTPS support | Secondary IP |
| --- |:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `https://page.example.io` | yes |  no | no | no |

Pages enabled, daemon is enabled and NGINX will proxy all requests to the
daemon. Pages daemon doesn't listen to the outside world.

1. Install the Pages daemon:

    ```
    cd /home/git
    sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
    cd gitlab-pages
    sudo -u git -H git checkout v0.2.4
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

1. Copy the `gitlab-pages-ssl` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
    ```

      Replace `gitlab-pages-ssl` with `gitlab-pages` if you are not using SSL.

1. Restart NGINX
1. [Restart GitLab][restart]

### Option 4. Wildcard HTTP domain without custom domains

| URL scheme | Wildcard certificate | Custom domain with HTTP support | Custom domain with HTTPS support | Secondary IP |
| --- |:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `http://page.example.io`  | no  |  no | no | no |

Pages enabled, daemon is enabled and NGINX will proxy all requests to the
daemon. Pages daemon doesn't listen to the outside world.

1. Install the Pages daemon:

    ```
    cd /home/git
    sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
    cd gitlab-pages
    sudo -u git -H git checkout v0.2.4
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

1. Copy the `gitlab-pages-ssl` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
    ```

      Replace `gitlab-pages-ssl` with `gitlab-pages` if you are not using SSL.

1. Restart NGINX
1. [Restart GitLab][restart]

## NGINX caveats

>**Note:**
The following information applies only for installations from source.

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

The maximum size of the unpacked archive per project can be configured in the
Admin area under the Application settings in the **Maximum size of pages (MB)**.
The default is 100MB.

## Backup

Pages are part of the [regular backup][backup] so there is nothing to configure.

## Security

You should strongly consider running GitLab pages under a different hostname
than GitLab to prevent XSS attacks.

[backup]: ../raketasks/backup_restore.md
[ee-80]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/80
[ee-173]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/173
[gitlab pages daemon]: https://gitlab.com/gitlab-org/gitlab-pages
[NGINX configs]: https://gitlab.com/gitlab-org/gitlab-ee/tree/8-5-stable-ee/lib/support/nginx
[pages-readme]: https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md
[pages-userguide]: ../../user/project/pages/index.md
[reconfigure]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: ../administration/restart_gitlab.md#installations-from-source
[gitlab-pages]: https://gitlab.com/gitlab-org/gitlab-pages/tree/v0.2.4
