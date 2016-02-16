# GitLab Pages Administration

_**Note:** This feature was [introduced][ee-80] in GitLab EE 8.3_

If you are looking for ways to upload your static content in GitLab Pages, you
probably want to read the [user documentation](README.md).

## Configuration

There are a couple of things to consider before enabling GitLab pages in your
GitLab EE instance.

1. You need to properly configure your DNS to point to the domain that pages
   will be served
1. Decide whether the Pages should be served on separate IP address
   or with the shared IP address in single Nginx server
1. Optionally but recommended, you can add some
   [shared runners](../ci/runners/README.md) so that your users don't have to
   bring their own.

Both of these settings are described in detail in the sections below.

## Serving Pages on shared IP address on single Nginx server

This is the most basic method of operation.
It allows you to serve the GitLab Pages on some predefined domain.
This method also doesn't require the separate IP address for only the Pages feature.

## Serving Pages on separate IP address

If you have a spare IP address or you can setup the separate load balancer to serve the GitLab Pages.
With this method of operation you can use additional features like: custom domains and support for custom certificates.
When configured in this mode the Pages daemon listen exclusively on ports that you do specify.

This is also a advised method of operation.

### DNS configuration

GitLab Pages expect to run on their own virtual host. In your DNS server/provider
you need to add a [wildcard DNS A record][wiki-wildcard-dns] pointing to the
the IP address that will be used for GitLab Pages.
It can be an address of GitLab server or a separate IP address.
For example, an entry would look like this:

```
*.example.com. 60 IN A 1.2.3.4
```

where `example.com` is the domain under which GitLab Pages will be served
and `1.2.3.4` is the IP address of your GitLab instance.

You should not use the GitLab domain to serve user pages. For more information
see the [security section](#security).

### Omnibus package installations

See the relevant documentation at <http://doc.gitlab.com/omnibus/settings/pages.html>.

### Installations from source for shared IP address using Nginx server

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
     
1. Update the `/etc/default/gitlab` specifying the `-pages-domain` in `gitlab_pages_options`:
   
     ```bash
     gitlab_pages_options="-pages-domain example.com -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8282"
     ```

1. Make sure you have copied the new `gitlab-pages` Nginx configuration file:

    ```bash
    sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
    sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
    ```

    Don't forget to add your domain name in the Nginx config. For example if
    your GitLab pages domain is `example.com`, replace

    ```bash
    server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
    ```

    with

    ```
    server_name ~^.*\.example\.com$;
    ```

    You must be extra careful to not remove the backslashes. If you are using
    a subdomain, make sure to escape all dots (`.`) with a backslash (\).
    For example `pages.example.com` would be:

    ```
    server_name ~^.*\.pages\.example\.com$;
    ```

1. Restart Nginx and GitLab:

    ```bash
    sudo service nginx restart
    sudo service gitlab restart
    ```

#### Running GitLab Pages with HTTPS on Nginx

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

### Installations from source using the separate IP address

1. Go to the GitLab installation directory:

     ```bash
     cd /home/git/gitlab
     ```

1. Edit `gitlab.yml` and under the `pages` setting, set `enabled` to `true` and
   the `host` to the FQDN and specify the `external_http` and `external_https`
   under which GitLab Pages will be served:

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

       external_http: "1.1.1.1:80" # external IP address with port on which the HTTP is served
       external_http: "1.1.1.1:443" # external IP address with port on which the HTTPS is served
     ```

1. Update the `/etc/default/gitlab` adding the `-pages-domain`, `-listen-http` and `-listen-https` to `gitlab_pages_options`:

     ```yaml
     gitlab_pages_options="-pages-domain example.com -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8282 -listen-http 1.1.1.1:80 -listen-https 1.1.1.1:443"
     ```

1. Restart Nginx and GitLab:

    ```bash
    sudo service gitlab restart
    ```

#### Running GitLab Pages with HTTPS

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
       
       external_http: "1.1.1.1:80" # external IP address with port on which the HTTP is served
       external_http: "1.1.1.1:443" # external IP address with port on which the HTTPS is served
     ```


1. Update the `/etc/default/gitlab` adding the `-root-cert` and `-root-key` to `gitlab_pages_options`:

     ```yaml
     gitlab_pages_options="... -root-cert /path/to/example.com.crt -root-key /path/to/example.com/key"
     ```

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

[ee-80]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/80
[wiki-wildcard-dns]: https://en.wikipedia.org/wiki/Wildcard_DNS_record
