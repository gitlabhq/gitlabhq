---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secondary runners **(PREMIUM SELF EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415179) in GitLab 16.7 [with a flag](../../feature_flags.md) named `geo_proxy_check_pipeline_refs`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can [enable the feature flag](../../feature_flags.md) named `geo_proxy_check_pipeline_refs`. On GitLab.com, this feature is not available.  

With [Geo proxying for secondary sites](index.md), it is possible to register a `gitlab-runner` with a secondary site. This offloads load from the primary instance.

## Enable or disable secondary runners

To enable secondary runners, SSH into a Rails node on the **primary** Geo site and run:

```ruby
sudo gitlab-rails runner 'Feature.enable(:geo_proxy_check_pipeline_refs)'
```

To disable secondary runners, SSH into a Rails node on the **primary** Geo site and run:

```ruby
sudo gitlab-rails runner `Feature.disable(:geo_proxy_check_pipeline_refs)`
```

## Use secondary runners with a Location Aware public URL (Unified URL)

Using a [Location Aware public URL](location_aware_external_url.md), with the feature flag enabled works with no extra configuration. After you install and register a runner in the same location as a secondary site, it automatically talks to the closest site, and only proxies to the primary if the secondary is out of date.

## Use secondary runners with separate URLs

Using separate secondary URLs, the runners should be:

1. Registered with the secondary external URL.
1. Configured with [`clone_url`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-clone_url-works) set to the `external_url` of the secondary instance.
