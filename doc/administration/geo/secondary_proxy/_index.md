---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo proxying for secondary sites
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - HTTP proxying for secondary sites with separate URLs [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346112) in GitLab 14.5 [with a flag](../../feature_flags.md) named `geo_secondary_proxy_separate_urls`. Disabled by default.
> - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/346112) in GitLab 15.1.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
The `geo_secondary_proxy_separate_urls` feature flag is planned to be deprecated and removed in a future release.
Support for read-only Geo secondary sites is proposed in [issue 366810](https://gitlab.com/gitlab-org/gitlab/-/issues/366810).

Secondary sites behave as full read-write GitLab instances. They transparently proxy all operations to the primary site, with [some notable exceptions](#features-accelerated-by-secondary-geo-sites).

This behavior enables use-cases including:

- Putting all Geo sites behind a single URL, to deliver a consistent, seamless, and comprehensive experience whichever site the user lands on. Users don't need to juggle multiple GitLab URLs.
- Geographically load-balancing traffic without worrying about write access.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Geo proxying for secondary sites](https://www.youtube.com/watch?v=TALLy7__Na8).
<!-- Video published on 2022-01-26 -->

For known issues, see [proxying-related items in the Geo documentation](../_index.md#known-issues).

## Set up a unified URL for Geo sites

Secondary sites can transparently serve read-write traffic. Therefore, you can
use a single external URL so that requests can hit either the primary Geo site
or any secondary Geo sites. This delivers a consistent, seamless, and
comprehensive experience whichever site the user lands on. Users don't need to
juggle multiple URLs or even be aware of the idea of multiple sites.

You can route traffic to Geo sites with:

- Geo-location aware DNS. To route traffic to the closest Geo site, whether primary or secondary. For an example, follow [Configure location-aware DNS](#configure-location-aware-dns).
- Round-robin DNS.
- A load-balancer. It must use sticky sessions to avoid authentication failures and cross-site request errors. DNS routing is inherently sticky so it does not share this caveat.

### Configure location-aware DNS

Follow this example to route traffic to the closest Geo site, whether primary or secondary.

#### Prerequisites

This example creates a `gitlab.example.com` subdomain that automatically directs
requests:

- From Europe to a **secondary** site.
- From all other locations to the **primary** site.

For this example, you need:

- A working Geo **primary** site and **secondary** site, see the [Geo setup instructions](../setup/_index.md).
- A DNS zone managing your domain. Although the following instructions use
  [AWS Route53](https://aws.amazon.com/route53/)
  and [GCP cloud DNS](https://cloud.google.com/dns/), other services such as
  [Cloudflare](https://www.cloudflare.com/) can be used as well.

#### AWS Route53

In this example, you use a Route53 Hosted Zone managing your domain for the Route53 setup.

In a Route53 Hosted Zone, traffic policies can be used to set up a variety of
routing configurations. To create a traffic policy:

1. Go to the
   [Route53 dashboard](https://console.aws.amazon.com/route53/home) and select
   **Traffic policies**.
1. Select **Create traffic policy**.
1. Fill in the **Policy Name** field with `Single Git Host` and select **Next**.
1. Leave **DNS type** as `A: IP Address in IPv4 format`.
1. Select **Connect to**, then select **Geolocation rule**.
1. For the first **Location**:
   1. Leave it as `Default`.
   1. Select **Connect to**, then select **New endpoint**.
   1. Choose **Type** `value` and fill it in with `<your **primary** IP address>`.
1. For the second **Location**:
   1. Choose `Europe`.
   1. Select **Connect to**, then select **New endpoint**.
   1. Choose **Type** `value` and fill it in with `<your **secondary** IP address>`.

   ![Route53 traffic policy editor showing a geolocation rule with two locations - Default and Europe - each connected to endpoints with different IP addresses](img/single_url_add_traffic_policy_endpoints_v14_5.png)

1. Select **Create traffic policy**.
1. Fill in **Policy record DNS name** with `gitlab`.

   ![Create policy records with traffic policy](img/single_url_create_policy_records_with_traffic_policy_v14_5.png)

1. Select **Create policy records**.

You have successfully set up a single host, like `gitlab.example.com`, which
distributes traffic to your Geo sites by geolocation.

#### GCP

In this example, you create a GCP Cloud DNS zone managing your domain.

When creating Geo-Based record sets, GCP applies a nearest match for the source region when the source of the traffic doesn't match any policy items exactly. To create a Geo-Based record set:

1. Select **Network Services** > **Cloud DNS**.
1. Select the Zone configured for your domain.
1. Select **Add Record Set**.
1. Enter the DNS Name for your Location-aware public URL, for example, `gitlab.example.com`.
1. Select the **Routing Policy**: **Geo-Based**.
1. Select **Add Managed RRData**.
   1. Select **Source Region**: **us-central1**.
   1. Enter your `<**primary** IP address>`.
   1. Select **Done**.
1. Select **Add Managed RRData**.
   1. Select **Source Region**: **europe-west1**.
   1. Enter your `<**secondary** IP address>`.
   1. Select **Done**.
1. Select **Create**.

You have successfully set up a single host, like `gitlab.example.com`, which
distributes traffic to your Geo sites using a location-aware URL.

### Configure each site to use the same external URL

After you have set up routing from a single URL to all of your Geo sites, follow
the following steps if your sites use different URLs:

1. On each GitLab site, SSH into **each** node running Rails (Puma, Sidekiq, Log-Cursor)
   and set the `external_url` to that of the single URL:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. Reconfigure the updated nodes for the change to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. To match the new external URL set on the secondary Geo sites, the primary database
   needs to reflect this change.

   In the Geo administration page of the **primary** site, edit each Geo secondary that
   is using the secondary proxying and set the `URL` field to the single URL.
   Make sure the primary site is also using this URL.

   To allow the sites to talk to each other, [make sure the `Internal URL` field is unique for each site](../../geo_sites.md#set-up-the-internal-urls).

In Kubernetes, you can [use the same domain under `global.hosts.domain` as for the primary site](https://docs.gitlab.com/charts/advanced/geo/index.html).

## Set up a separate URL for a secondary Geo site

You can use different external URLs per site. You can use this to offer a specific site to a specific set of users. Alternatively, you can give users control over which site they use, though they must understand the implications of their choice.

NOTE:
GitLab does not support multiple external URLs, see [issue 21319](https://gitlab.com/gitlab-org/gitlab/-/issues/21319). An inherent problem is there are many cases where a site needs to produce an absolute URL outside of the context of an HTTP request, such as when sending emails that were not triggered by a request.

### Configure a secondary Geo site to a different external URL than the primary site

If your secondary site uses the same external URL as the primary site:

1. On the secondary site, SSH into **each** node running Rails (Puma, Sidekiq, Log-Cursor)
   and set the `external_url` to the desired URL for the secondary site:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. Reconfigure the updated nodes for the change to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. To match the new external URL set on the secondary Geo site, the primary database
   needs to reflect this change.

   In the Geo administration page of the **primary** site, edit the target secondary site and set the `URL` field to the desired URL.

   To allow the sites to talk to each other, [make sure the `Internal URL` field is unique for each site](../../geo_sites.md#set-up-the-internal-urls). If the desired URL is unique to this site, then you can clear the `Internal URL` field. On save, it defaults to the external URL.

## Behavior of secondary sites when the primary Geo site is down

Considering that web traffic is proxied to the primary, the behavior of the secondary sites differs when the primary
site is inaccessible:

- UI and API traffic return the same errors as the primary (or fail if the primary is not accessible at all), since they are proxied.
- For repositories that are fully up-to-date on the specific secondary site being accessed, Git read operations still work as expected,
  including authentication through HTTP(s) or SSH. However, Git reads performed by GitLab Runners will fail.
- Git operations for repositories that are not replicated to the secondary site return the same errors
  as the primary site, since they are proxied.
- All Git write operations return the same errors as the primary site, since they are proxied.

## Features accelerated by secondary Geo sites

Most HTTP traffic sent to a secondary Geo site is proxied to the primary Geo site. With this architecture,
secondary Geo sites are able to support write requests, and avoid read-after-write problems. Certain
**read** requests are handled locally by secondary sites for improved latency and bandwidth nearby.

The following table details the components tested through the Geo secondary site Workhorse proxy.
It does not cover all data types.

In this context, accelerated reads refer to read requests served from the secondary site, provided that the data is up to date for the component on the secondary site. If the data on the secondary site is determined to be out of date, the request is forwarded to the primary site. Read requests for components not listed in the table below are always automatically forwarded to the primary site.

| Feature / component                                 | Accelerated reads?     | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| :-------------------------------------------------- | :--------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Project, wiki, design repository (using the web UI) | **{dotted-circle}** No |                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Project, wiki repository (using Git)                | **{check-circle}** Yes | Git reads are served from the local secondary while pushes get proxied to the primary. Selective sync or cases where repositories don't exist locally on the Geo secondary throw a "not found" error.                                                                                                                                                                                                                                                                      |
| Project, Personal Snippet (using the web UI)        | **{dotted-circle}** No |                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Project, Personal Snippet (using Git)               | **{check-circle}** Yes | Git reads are served from the local secondary while pushes get proxied to the primary. Selective sync or cases where repositories don't exist locally on the Geo secondary throw a "not found" error.                                                                                                                                                                                                                                                                      |
| Group wiki repository (using the web UI)            | **{dotted-circle}** No |                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Group wiki repository (using Git)                   | **{check-circle}** Yes | Git reads are served from the local secondary while pushes get proxied to the primary. Selective sync or cases where repositories don't exist locally on the Geo secondary throw a "not found" error.                                                                                                                                                                                                                                                                      |
| User uploads                                        | **{dotted-circle}** No |                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| LFS objects (using the web UI)                      | **{dotted-circle}** No |                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| LFS objects (using Git)                             | **{check-circle}** Yes |                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Pages                                               | **{dotted-circle}** No | Pages can use the same URL (without access control), but must be configured separately and are not proxied.                                                                                                                                                                                                                                                                                                                                                                |
| Advanced search (using the web UI)                  | **{dotted-circle}** No |                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Container registry                                  | **{dotted-circle}** No | The container registry is only recommended for Disaster Recovery scenarios. If the secondary site's container registry is not up to date, the read request is served with old data as the request is not forwarded to the primary site. Accelerating the container registry is planned, please upvote or comment in the [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365864) to indicate your interest or ask your GitLab representative to do so on your behalf. |
| Dependency Proxy                                    | **{dotted-circle}** No | Read requests to a Geo secondary site's Dependency Proxy are always proxied to the primary site.                                                                                                                                                                                                                                                                                                                                                                           |
| All other data                                    | **{dotted-circle}** No | Read requests for components not listed in this table are always automatically forwarded to the primary site.                                                                                                                                                                                                                                                                                                                                                                           |

To request acceleration of a feature, check if an issue already exists in [epic 8239](https://gitlab.com/groups/gitlab-org/-/epics/8239) and upvote or comment on it to indicate your interest or ask your GitLab representative to do so on your behalf. If an applicable issue doesn't exist, open one and mention it in the epic.

## Disable secondary site HTTP proxying

Secondary site HTTP proxying is enabled by default on a secondary site when it uses a unified URL, meaning, it is configured with the same `external_url` as the primary site. Disabling proxying in this case tends not to be helpful due to completely different behavior being served at the same URL, depending on routing.

HTTP proxying is enabled by default in GitLab 15.1 on a secondary site even without a unified URL. If proxying needs to be disabled on all secondary sites, it is easiest to disable the feature flag:

::Tabs

:::TabTitle Linux package (Omnibus)

1. SSH into a node which is running Puma or Sidekiq on your primary Geo site and run:

   ```shell
   sudo gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. Restart Puma on all nodes which are running it on your secondary Geo site:

   ```shell
   sudo gitlab-ctl restart puma
   ```

:::TabTitle Helm chart (Kubernetes)

1. On your primary Geo site, run this command in the Toolbox pod:

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. Restart the Webservice pods on your secondary Geo site:

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

::EndTabs

To revert the changes so secondary site proxying is enabled again:

::Tabs

:::TabTitle Linux package (Omnibus)

1. SSH into a node which is running Puma or Sidekiq on your primary Geo site and run:

   ```shell
   sudo gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. Restart Puma on all nodes which are running it on your secondary Geo site:

   ```shell
   sudo gitlab-ctl restart puma
   ```

:::TabTitle Helm chart (Kubernetes)

1. On your primary Geo site, run this command in the Toolbox pod:

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. Restart the Webservice pods on your secondary Geo site:

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

::EndTabs

### Disable secondary site HTTP proxying per site

If there are multiple secondary sites, you can disable HTTP proxying on each secondary site separately, by following these steps:

::Tabs

:::TabTitle Linux package (Omnibus)

1. SSH into each application node (serving user traffic directly) on your secondary Geo site
   and add the following environment variable:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_workhorse['env'] = {
     "GEO_SECONDARY_PROXY" => "0"
   }
   ```

1. Reconfigure the updated nodes for the change to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

You can use `--set gitlab.webservice.extraEnv.GEO_SECONDARY_PROXY="0"`,
or specify the following in your values file:

```yaml
gitlab:
  webservice:
    extraEnv:
      GEO_SECONDARY_PROXY: "0"
```

::EndTabs

### Disable secondary site Git proxying

It is not possible to disable forwarding of:

- Git push over SSH
- Git pull over SSH when the Git repository is out-of-date on the secondary site
- Git push over HTTP
- Git pull over HTTP when the Git repository is out-of-date on the secondary site
