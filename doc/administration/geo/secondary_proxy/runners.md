---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Secondary runners
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9779) in GitLab 16.8 [with a flag](../../feature_flags.md) named `geo_proxy_check_pipeline_refs`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/434041) in GitLab 16.9.

With [Geo proxying for secondary sites](_index.md), it is possible to register a `gitlab-runner` with a secondary site. This offloads load from the primary instance.

NOTE:
The jobs that start during the first stage of a pipeline almost always have their Git clone requests forwarded to the primary site. This is because those clones usually occur before the Git data is replicated and verified by the secondary site. Later stages are not guaranteed to be served by the secondary site either, for example if the Git change is large, bandwidth is small, or pipeline stages are short. In most cases, the subsequent stages of the pipeline serve Git data from the secondary site. [Issue 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176) proposes an enhancement to increase the chance of the first stage clone request is served from the secondary site.

## Use secondary runners with a Location Aware public URL (Unified URL)

Using [Location-Aware DNS](_index.md#configure-location-aware-dns), with the feature flag enabled works with no extra configuration. After you install and register a runner in the same location as a secondary site, it automatically talks to the closest site, and only proxies to the primary if the secondary is out of date.

## Use secondary runners with separate URLs

Using separate secondary URLs, the runners should be:

1. Registered with the secondary external URL.
1. Configured with [`clone_url`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-clone_url-works) set to the `external_url` of the secondary instance.

## Handling a Planned Failover with secondary runners

When executing [a planned failover](../disaster_recovery/planned_failover.md), secondary runners try to keep talking to their local instance. This leads to decreased runner capacity, and may need to be accounted for.

### With Location Aware public URL

When using [Location-Aware DNS](_index.md#configure-location-aware-dns), all runners automatically connect to the closest Geo site.

When failing over to a new primary:

- While the old primary is still in the DNS record, any runners previously connected to your old primary still attempt to pick up jobs from the old primary. If it is unreachable, the runners [detect this](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-unhealthy_requests_limit-and-unhealthy_interval-works), and stop requesting for an extended period of time after the instance returns.
- If you have [multiple secondary nodes](../disaster_recovery/_index.md#promoting-secondary-geo-replica-in-multi-secondary-configurations), after the initial failover the remaining secondaries are in an unhealthy state until they are [replicated](../disaster_recovery/_index.md#step-2-initiate-the-replication-process) with the new primary. The runners attached to them are then unable to check in, and their health check also kicks in.
- If you remove any of the unhealthy nodes from the Geo DNS entry, the runners pick the next closest instance. Depending on your architecture, this may not be what you want, as you could overwhelm your site in its reduced state.

To alleviate any of these issues, you can [pause](#pausing-runners) or shutdown some of the runners until the site is back up to 100%.

If you are not concerned about these issues, there is nothing to do here.

### With separate URLs

- If you are returning the old primary to service, you can pause the old primary runners until it is back online. This prevents the health check from kicking in.
- If the old primary is not returning, or you want to avoid temporarily reduced runner capacity, the primary runners should be reconfigured to connect to the new primary.
- If multiple secondaries are being used, the runners should be [paused](#pausing-runners), shutdown, or reconfigured to connect to the new primary while they are being replicated to the new primary.

### Pausing runners

You must have administrator access to use any of the following methods:

- Through the **Admin** area:
  1. On the left sidebar, at the bottom, select **Admin**.
  1. Select **Settings > Runners**.
  1. Identify the runners you would like to pause.
  1. Select the `pause` button next to each runner you would like to pause.
  1. After the failover is complete, unpause the runners you paused in the previous step.
- Use the [Runners API](../../../api/runners.md):
  1. Fetch or create a [personal access token](../../../user/profile/personal_access_tokens.md) with administrator access.
  1. Get the list of runners. You can filter the list [using the API](../../../api/runners.md#list-all-runners).
  1. Identify the runners you would like to pause, and make note of their `id`.
  1. [Follow the API documentation](../../../api/runners.md#pause-a-runner) to pause each runner.
  1. After the failover is complete, unpause the list of runners using the API by setting `paused=false`.
