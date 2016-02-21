# GitLab Pages Administration

> **Note:**
This feature was [introduced][ee-80] in GitLab EE 8.3.

This document describes how to set up the _latest_ GitLab Pages feature. Make
sure to read the [changelog](#changelog) if you are upgrading to a new GitLab
version as it may include new features and changes needed to be made in your
configuration.

If you are looking for ways to upload your static content in GitLab Pages, you
probably want to read the [user documentation](README.md).

[ee-80]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/80

The NGINX configs have changed to reflect this change.

[gitlab-pages daemon]: https://gitlab.com/gitlab-org/gitlab-pages

## Configuration

There are a couple of things to consider before enabling GitLab pages in your
GitLab EE instance.

1. You need to properly configure your DNS to point to the domain that pages
   will be served
1. Pages use a separate Nginx configuration file which needs to be explicitly
   added in the server under which GitLab EE runs
1. Optionally but recommended, you can add some
   [shared runners](../ci/runners/README.md) so that your users don't have to
   bring their own.

Both of these settings are described in detail in the sections below.

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

See the relevant documentation at <http://doc.gitlab.com/omnibus/settings/pages.html>.

### Installations from source

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
come. Below is a brief changelog. If no changes were introduced, assume that
the documentation is the same as the previous version(s).

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
