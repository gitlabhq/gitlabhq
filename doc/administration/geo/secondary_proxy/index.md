---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Geo proxying for secondary sites **(PREMIUM SELF)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5914) in GitLab 14.4 [with a flag](../../feature_flags.md) named `geo_secondary_proxy`. Disabled by default.
> - [Enabled by default for unified URLs](https://gitlab.com/gitlab-org/gitlab/-/issues/325732) in GitLab 14.6.
> - [Disabled by default for different URLs](https://gitlab.com/gitlab-org/gitlab/-/issues/325732) in GitLab 14.6 [with a flag](../../feature_flags.md) named `geo_secondary_proxy_separate_urls`.
> - [Enabled by default for different URLs](https://gitlab.com/gitlab-org/gitlab/-/issues/346112) in GitLab 15.1.

FLAG:
On self-managed GitLab, this feature is only available by default for Geo sites using a unified URL. See below to
[set up a unified URL for Geo sites](#set-up-a-unified-url-for-geo-sites).
The feature is not ready for production use with separate URLs.

Use Geo proxying to:

- Have secondary sites serve read-write traffic by proxying to the primary site.
- Selectively accelerate replicated data types by directing read-only operations to the local site instead.

When enabled, users of the secondary site can use the WebUI as if they were accessing the
primary site's UI. This significantly improves the overall user experience of secondary sites.

With secondary proxying, web requests to secondary Geo sites are
proxied directly to the primary, and appear to act as a read-write site.

Proxying is done by the [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse) component.
Traffic usually sent to the Rails application on the Geo secondary site is proxied
to the [internal URL](../index.md#internal-url) of the primary Geo site instead.

Use secondary proxying for use-cases including:

- Having all Geo sites behind a single URL.
- Geographically load-balancing traffic without worrying about write access.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see: [Secondary proxying using geographic load-balancer and AWS Route53](https://www.youtube.com/watch?v=TALLy7__Na8).

## Set up a unified URL for Geo sites

Secondary sites can transparently serve read-write traffic. You can
use a single external URL so that requests can hit either the primary Geo site
or any secondary Geo sites that use Geo proxying.

### Configure an external URL to send traffic to both sites

Follow the [Location-aware public URL](location_aware_external_url.md) steps to create
a single URL used by all Geo sites, including the primary.

### Update the Geo sites to use the same external URL

1. On your Geo sites, SSH **into each node running Rails (Puma, Sidekiq, Log-Cursor)
   and change the `external_url` to that of the single URL:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

1. Reconfigure the updated nodes for the change to take effect if the URL was different than the one already set:

   ```shell
   gitlab-ctl reconfigure
   ```

1. To match the new external URL set on the secondary Geo sites, the primary database
   needs to reflect this change.

   In the Geo administration page of the **primary** site, edit each Geo secondary that
   is using the secondary proxying and set the `URL` field to the single URL.
   Make sure the primary site is also using this URL.

In Kubernetes, you can use the same domain under `global.hosts.domain` as for the primary site.

## Disable Geo proxying

You can disable the secondary proxying on each Geo site, separately, by following these steps with Omnibus-based packages:

1. SSH into each application node (serving user traffic directly) on your secondary Geo site
   and add the following environment variable:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_workhorse['env'] = {
     "GEO_SECONDARY_PROXY" => "0"
   }
   ```

1. Reconfigure the updated nodes for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

In Kubernetes, you can use `--set gitlab.webservice.extraEnv.GEO_SECONDARY_PROXY="0"`,
or specify the following in your values file:

```yaml
gitlab:
  webservice:
    extraEnv:
      GEO_SECONDARY_PROXY: "0"
```

## Geo proxying with Separate URLs

Since GitLab 15.1, Geo secondary proxying is enabled by default for separate URLs also.

There are minor known issues linked in the ["Geo secondary proxying with separate URLs"
epic](https://gitlab.com/groups/gitlab-org/-/epics/6865). You can also add feedback in the epic about any use-cases that
are not possible anymore with proxying enabled.

If you run into issues, to disable this feature, disable the `geo_secondary_proxy_separate_urls` feature flag.
SSH into one node running Rails on your primary Geo site and run:

```shell
sudo gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
```

In Kubernetes, you can run the same command in the toolbox pod. Refer to the
[Kubernetes cheat sheet](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html#gitlab-specific-kubernetes-information)
for details.

## Limitations

- When secondary proxying is used, the asynchronous Geo replication can cause unexpected issues for accelerated
  data types that may be replicated to the Geo secondaries with a delay.

  For example, we found a potential issue where
  [replication lag introduces read-after-write inconsistencies](https://gitlab.com/gitlab-org/gitlab/-/issues/345267).
  If the replication lag is high enough, this can result in Git reads receiving stale data when hitting a secondary.

- Non-Rails requests are not proxied, so other services may need to use a separate, non-unified URL to ensure requests
  are always sent to the primary. These services include:

  - GitLab Container Registry - [can be configured to use a separate domain](../../packages/container_registry.md#configure-container-registry-under-its-own-domain).
  - GitLab Pages - should always use a separate domain, as part of [the prerequisites for running GitLab Pages](../../pages/index.md#prerequisites).

- With a unified URL, Let's Encrypt can't generate certificates unless it can reach both IPs through the same domain.
  To use TLS certificates with Let's Encrypt, you can manually point the domain to one of the Geo sites, generate
  the certificate, then copy it to all other sites.

- [Viewing projects and designs data from a primary site is not possible when using a unified URL](../index.md#view-replication-data-on-the-primary-site).

## Behavior of secondary sites when the primary Geo site is down

Considering that web traffic is proxied to the primary, the behavior of the secondary sites differs when the primary
site is inaccessible:

- UI and API traffic return the same errors as the primary (or fail if the primary is not accessible at all), since they are proxied.
- For repositories that already exist on the specific secondary site being accessed, Git read operations still work as expected,
  including authentication through HTTP(s) or SSH.
- Git operations for repositories that are not replicated to the secondary site return the same errors
  as the primary site, since they are proxied.
- All Git write operations return the same errors as the primary site, since they are proxied.

## Features accelerated by secondary Geo sites

Most HTTP traffic sent to a secondary Geo site can be proxied to the primary Geo site. With this architecture,
secondary Geo sites are able to support write requests. Certain **read** requests are handled locally by secondary
sites for improved latency and bandwidth nearby. All write requests are proxied to the primary site.

The following table details the components currently tested through the Geo secondary site Workhorse proxy.
It does not cover all data types, more will be added in the future as they are tested.

| Feature / component                                 | Accelerated reads?     |
|:----------------------------------------------------|:-----------------------|
| Project, wiki, design repository (using the web UI) | **{dotted-circle}** No |
| Project, wiki repository (using Git)                | **{check-circle}** Yes <sup>1</sup> |
| Project, Personal Snippet (using the web UI)        | **{dotted-circle}** No |
| Project, Personal Snippet (using Git)               | **{check-circle}** Yes <sup>1</sup> |
| Group wiki repository (using the web UI)            | **{dotted-circle}** No |
| Group wiki repository (using Git)                   | **{check-circle}** Yes <sup>1</sup> |
| User uploads                                        | **{dotted-circle}** No |
| LFS objects (using the web UI)                      | **{dotted-circle}** No |
| LFS objects (using Git)                             | **{check-circle}** Yes |
| Pages                                               | **{dotted-circle}** No <sup>2</sup> |
| Advanced search (using the web UI)                  | **{dotted-circle}** No |

1. Git reads are served from the local secondary while pushes get proxied to the primary.
   Selective sync or cases where repositories don't exist locally on the Geo secondary throw a "not found" error.
1. Pages can use the same URL (without access control), but must be configured separately and are not proxied.
