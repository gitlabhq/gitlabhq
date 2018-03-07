# GitLab Pages administration

> **Notes:**
- [Introduced][ee-80] in GitLab EE 8.3.
- Custom CNAMEs with TLS support were [introduced][ee-173] in GitLab EE 8.5.
- GitLab Pages [were ported][ce-14605] to Community Edition in GitLab 8.17.
- This guide is for Omnibus GitLab installations. If you have installed
  GitLab from source, follow the [Pages source installation document](source.md).
- To learn how to use GitLab Pages, read the [user documentation][pages-userguide].

---

This document describes how to set up the _latest_ GitLab Pages feature. Make
sure to read the [changelog](#changelog) if you are upgrading to a new GitLab
version as it may include new features and changes needed to be made in your
configuration.

## Overview

GitLab Pages makes use of the [GitLab Pages daemon], a simple HTTP server
written in Go that can listen on an external IP address and provide support for
custom domains and custom certificates. It supports dynamic certificates through
SNI and exposes pages using HTTP2 by default.
You are encouraged to read its [README][pages-readme] to fully understand how
it works.

---

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

Before proceeding with the Pages configuration, you will need to:

1. Have a separate domain under which the GitLab Pages will be served. In this
   document we assume that to be `example.io`.
1. Configure a **wildcard DNS record**.
1. (Optional) Have a **wildcard certificate** for that domain if you decide to
   serve Pages under HTTPS.
1. (Optional but recommended) Enable [Shared runners](../../ci/runners/README.md)
   so that your users don't have to bring their own.
1. (Only for custom domains) Have a **secondary IP**.

NOTE: **Note:**
If your GitLab instance and the Pages daemon are deployed in a private network or behind a firewall, your GitLab Pages websites will only be accessible to devices/users that have access to the private network.

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
request that `*.example.io` is added to the Public Suffix List. GitLab.com
added `*.gitlab.io` [in 2016](https://gitlab.com/gitlab-com/infrastructure/issues/230).

### DNS configuration

GitLab Pages expect to run on their own virtual host. In your DNS server/provider
you need to add a [wildcard DNS A record][wiki-wildcard-dns] pointing to the
host that GitLab runs. For example, an entry would look like this:

```
*.example.io. 1800 IN A    1.1.1.1
*.example.io. 1800 IN AAAA 2001::1
```

where `example.io` is the domain under which GitLab Pages will be served
and `1.1.1.1` is the IPv4 address of your GitLab instance and `2001::1` is the
IPv6 address. If you don't have IPv6, you can omit the AAAA record.

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

>**Requirements:**
- [Wildcard DNS setup](#dns-configuration)
>
>---
>
URL scheme: `http://page.example.io`

This is the minimum setup that you can use Pages with. It is the base for all
other setups as described below. Nginx will proxy all requests to the daemon.
The Pages daemon doesn't listen to the outside world.

1. Set the external URL for GitLab Pages in `/etc/gitlab/gitlab.rb`:

    ```ruby
    pages_external_url 'http://example.io'
    ```

1. [Reconfigure GitLab][reconfigure]

Watch the [video tutorial][video-admin] for this configuration.

### Wildcard domains with TLS support

>**Requirements:**
- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate
>
>---
>
URL scheme: `https://page.example.io`

Nginx will proxy all requests to the daemon. Pages daemon doesn't listen to the
outside world.

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

## Advanced configuration

In addition to the wildcard domains, you can also have the option to configure
GitLab Pages to work with custom domains. Again, there are two options here:
support custom domains with and without TLS certificates. The easiest setup is
that without TLS certificates. In either case, you'll need a secondary IP. If
you have IPv6 as well as IPv4 addresses, you can use them both.

### Custom domains

>**Requirements:**
- [Wildcard DNS setup](#dns-configuration)
- Secondary IP
>
---
>
URL scheme: `http://page.example.io` and `http://domain.com`

In that case, the Pages daemon is running, Nginx still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains are supported, but no TLS.

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    pages_external_url "http://example.io"
    nginx['listen_addresses'] = ['1.1.1.1']
    pages_nginx['enable'] = false
    gitlab_pages['external_http'] = ['1.1.1.2:80', '[2001::2]:80']
    ```

    where `1.1.1.1` is the primary IP address that GitLab is listening to and
    `1.1.1.2` and `2001::2` are the secondary IPs the GitLab Pages daemon
    listens on. If you don't have IPv6, you can omit the IPv6 address.

1. [Reconfigure GitLab][reconfigure]

### Custom domains with TLS support

>**Requirements:**
- [Wildcard DNS setup](#dns-configuration)
- Wildcard TLS certificate
- Secondary IP
>
---
>
URL scheme: `https://page.example.io` and `https://domain.com`

In that case, the Pages daemon is running, Nginx still proxies requests to
the daemon but the daemon is also able to receive requests from the outside
world. Custom domains and TLS are supported.

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    pages_external_url "https://example.io"
    nginx['listen_addresses'] = ['1.1.1.1']
    pages_nginx['enable'] = false
    gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
    gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
    gitlab_pages['external_http'] = ['1.1.1.2:80', '[2001::2]:80']
    gitlab_pages['external_https'] = ['1.1.1.2:443', '[2001::2]:443']
    ```

    where `1.1.1.1` is the primary IP address that GitLab is listening to and
    `1.1.1.2` and `2001::2` are the secondary IPs where the GitLab Pages daemon
    listens on. If you don't have IPv6, you can omit the IPv6 address.

1. [Reconfigure GitLab][reconfigure]

### Custom domain verification

To prevent malicious users from hijacking domains that don't belong to them,
GitLab supports [custom domain verification](../../user/project/pages/getting_started_part_three.md#dns-txt-record).
When adding a custom domain, users will be required to prove they own it by
adding a GitLab-controlled verification code to the DNS records for that domain.

If your userbase is private or otherwise trusted, you can disable the
verification requirement. Navigate to `Admin area ➔ Settings` and uncheck
**Require users to prove ownership of custom domains** in the Pages section.
This setting is enabled by default.

## Change storage path

Follow the steps below to change the default path where GitLab Pages' contents
are stored.

1. Pages are stored by default in `/var/opt/gitlab/gitlab-rails/shared/pages`.
   If you wish to store them in another location you must set it up in
   `/etc/gitlab/gitlab.rb`:

     ```ruby
     gitlab_rails['pages_path'] = "/mnt/storage/pages"
     ```

1. [Reconfigure GitLab][reconfigure]

## Set maximum pages size

The maximum size of the unpacked archive per project can be configured in the
Admin area under the Application settings in the **Maximum size of pages (MB)**.
The default is 100MB.

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

**GitLab 8.17 ([documentation][8-17-docs])**

- GitLab Pages were ported to Community Edition in GitLab 8.17.
- Documentation was refactored to be more modular and easy to follow.

**GitLab 8.5 ([documentation][8-5-docs])**

- In GitLab 8.5 we introduced the [gitlab-pages][] daemon which is now the
  recommended way to set up GitLab Pages.
- The [NGINX configs][] have changed to reflect this change. So make sure to
  update them.
- Custom CNAME and TLS certificates support.
- Documentation was moved to one place.

**GitLab 8.3 ([documentation][8-3-docs])**

- GitLab Pages feature was introduced.

[8-3-docs]: https://gitlab.com/gitlab-org/gitlab-ee/blob/8-3-stable-ee/doc/pages/administration.md
[8-5-docs]: https://gitlab.com/gitlab-org/gitlab-ee/blob/8-5-stable-ee/doc/pages/administration.md
[8-17-docs]: https://gitlab.com/gitlab-org/gitlab-ce/blob/8-17-stable-ce/doc/administration/pages/index.md
[backup]: ../../raketasks/backup_restore.md
[ce-14605]: https://gitlab.com/gitlab-org/gitlab-ce/issues/14605
[ee-80]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/80
[ee-173]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/173
[gitlab pages daemon]: https://gitlab.com/gitlab-org/gitlab-pages
[NGINX configs]: https://gitlab.com/gitlab-org/gitlab-ee/tree/8-5-stable-ee/lib/support/nginx
[pages-readme]: https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md
[pages-userguide]: ../../user/project/pages/index.md
[reconfigure]: ../restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: ../restart_gitlab.md#installations-from-source
[gitlab-pages]: https://gitlab.com/gitlab-org/gitlab-pages/tree/v0.2.4
[video-admin]: https://youtu.be/dD8c7WNcc6s
