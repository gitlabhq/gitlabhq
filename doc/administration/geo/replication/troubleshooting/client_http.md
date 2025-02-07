---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Geo client and HTTP response code errors
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

## Fixing client errors

### Authorization errors from LFS HTTP(S) client requests

You may have problems if you're running a version of [Git LFS](https://git-lfs.com/) before 2.4.2.
As noted in [this authentication issue](https://github.com/git-lfs/git-lfs/issues/3025),
requests redirected from the secondary to the primary site do not properly send the
Authorization header. This may result in either an infinite `Authorization <-> Redirect`
loop, or Authorization error messages.

### Error: Net::ReadTimeout when pushing through SSH on a Geo secondary

When you push large repositories through SSH on a Geo secondary site, you may encounter a timeout.
This is because Rails proxies the push to the primary and has a 60 second default timeout,
[as described in this Geo issue](https://gitlab.com/gitlab-org/gitlab/-/issues/7405).

Current workarounds are:

- Push through HTTP instead, where Workhorse proxies the request to the primary (or redirects to the primary if Geo proxying is not enabled).
- Push directly to the primary.

Example log (`gitlab-shell.log`):

```plaintext
Failed to contact primary https://primary.domain.com/namespace/push_test.git\\nError: Net::ReadTimeout\",\"result\":null}" code=500 method=POST pid=5483 url="http://127.0.0.1:3000/api/v4/geo/proxy_git_push_ssh/push"
```

### Repair OAuth authorization between Geo sites

When upgrading a Geo site, you might not be able to sign into a secondary site that only uses OAuth for authentication. In that case, start a [Rails console](../../../operations/rails_console.md) session on your primary site and perform the following steps:

1. To find the affected node, first list all the Geo Nodes you have:

   ```ruby
   GeoNode.all
   ```

1. Repair the affected Geo node by specifying the ID:

   ```ruby
   GeoNode.find(<id>).repair
   ```

## HTTP response code errors

### Secondary site returns 502 errors with Geo proxying

When [Geo proxying for secondary sites](../../secondary_proxy/_index.md) is enabled, and the secondary site user interface returns
502 errors, it is possible that the response header proxied from the primary site is too large.

Check the NGINX logs for errors similar to this example:

```plaintext
2022/01/26 00:02:13 [error] 26641#0: *829148 upstream sent too big header while reading response header from upstream, client: 10.0.2.2, server: geo.staging.gitlab.com, request: "POST /users/sign_in HTTP/2.0", upstream: "http://unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket:/users/sign_in", host: "geo.staging.gitlab.com", referrer: "https://geo.staging.gitlab.com/users/sign_in"
```

To resolve this issue:

1. Set `nginx['proxy_custom_buffer_size'] = '8k'` in `/etc/gitlab.rb` on all web nodes on the secondary site.
1. Reconfigure the **secondary** using `sudo gitlab-ctl reconfigure`.

If you still get this error, you can further increase the buffer size by repeating the steps above
and changing the `8k` size, for example by doubling it to `16k`.

### Geo Admin area shows `Unknown` for health status and 'Request failed with status code 401'

If using a load balancer, ensure that the load balancer's URL is set as the `external_url` in the
`/etc/gitlab/gitlab.rb` of the nodes behind the load balancer.

On the primary site, go to **Admin > Geo > Settings** and find the **Allowed Geo IP** field. Ensure the IP address of the secondary site is listed.

### Primary site returns 500 error when accessing `/admin/geo/replication/projects`

Navigating to **Admin > Geo > Replication** (or `/admin/geo/replication/projects`) on a primary Geo site, shows a 500 error, while that same link on the secondary works fine. The primary's `production.log` has a similar entry to the following:

```plaintext
Geo::TrackingBase::SecondaryNotConfigured: Geo secondary database is not configured
  from ee/app/models/geo/tracking_base.rb:26:in `connection'
  [..]
  from ee/app/views/admin/geo/projects/_all.html.haml:1
```

On a Geo primary site this error can be ignored.

This happens because GitLab is attempting to display registries from the [Geo tracking database](../../../geo/_index.md#geo-tracking-database) which doesn't exist on the primary site (only the original projects exist on the primary; no replicated projects are present, therefore no tracking database exists).

### Secondary site returns 400 error "Request header or cookie too large"

This error can happen when the internal URL of the primary site is incorrect.

For example, when you use a unified URL and the primary site's internal URL is also equal to the external URL. This causes a loop when a secondary site proxies requests to the primary site's internal URL.

To fix this issue, set the primary site's internal URL to a URL that is:

- Unique to the primary site.
- Accessible from all secondary sites.

1. Visit the primary site.
1. [Set up the internal URLs](../../../geo_sites.md#set-up-the-internal-urls).

### Secondary site returns `Received HTTP code 403 from proxy after CONNECT`

If you have installed GitLab using the Linux package (Omnibus) and have configured the `no_proxy` [custom environment variable](https://docs.gitlab.com/omnibus/settings/environment-variables.html) for Gitaly, you may experience this issue. Affected versions:

- `15.4.6`
- `15.5.0`-`15.5.6`
- `15.6.0`-`15.6.3`
- `15.7.0`-`15.7.1`

This is due to [a bug introduced in the included version of cURL](https://github.com/curl/curl/issues/10122) shipped with
the Linux package 15.4.6 and later. You should upgrade to a later version where this has been
[fixed](https://about.gitlab.com/releases/2023/01/09/security-release-gitlab-15-7-2-released/).

The bug causes all wildcard domains (`.example.com`) to be ignored except for the last on in the `no_proxy` environment variable list. Therefore, if for any reason you cannot upgrade to a newer version, you can work around the issue by moving your wildcard domain to the end of the list:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitaly['env'] = {
     "no_proxy" => "sever.yourdomain.org, .yourdomain.com",
   }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

You can have only one wildcard domain in the `no_proxy` list.

### Geo Admin area returns 404 error for a secondary site

Sometimes `sudo gitlab-rake gitlab:geo:check` indicates that **Rails nodes of the secondary** sites are
healthy, but a 404 Not Found error message for the **secondary** site is returned in the Geo **Admin** area on the web interface for
the **primary** site.

To resolve this issue:

- Try restarting **each Rails, Sidekiq and Gitaly nodes on your secondary site** using `sudo gitlab-ctl restart`.
- Check `/var/log/gitlab/gitlab-rails/geo.log` on Sidekiq nodes to see if the **secondary** site is
  using IPv6 to send its status to the **primary** site. If it is, add an entry to
  the **primary** site using IPv4 in the `/etc/hosts` file. Alternatively, you should
  [enable IPv6 on the **primary** site](https://docs.gitlab.com/omnibus/settings/nginx.html#setting-the-nginx-listen-address-or-addresses).
