---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Virtual registry
description: Use the GitLab virtual registry to proxy, cache, and distribute packages from multiple upstream registries.
---

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14137) in GitLab 18.0 [with a flag](../../../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

{{< alert type="note" >}}

The GitLab virtual registry is available as part of the GitLab [beta](../../../policy/development_stages_support.md#beta) program. While it is currently available on Premium and Ultimate, final availability and pricing will be announced when the virtual registry is generally available.

{{< /alert >}}
Use the GitLab virtual registry to proxy, cache, and distribute packages from multiple upstream registries behind a single, well-known URL.

With this approach, you can configure your applications to use one virtual registry instead of multiple upstream registries.

## Prerequisites

To configure the virtual registry:

- You need a top-level group with at least the Maintainer role.
- Make sure you enable the virtual registries setting. It's enabled by default, but [administrators can turn it off](#turn-off-the-virtual-registry).
- Make sure you enable the dependency proxy setting. It's enabled by default, but [administrators can turn it off](../../../administration/packages/dependency_proxy.md).
- You must configure authentication for your supported [package format](#supported-package-formats).

## Turn off the virtual registry

The virtual registry is turned on by default.

Prerequisites:

- To turn off the virtual registry, you must be an administrator.

To turn off the virtual registry:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Settings** > **Packages and registries**.
1. Under **Virtual Registry**, turn off the **Enable Virtual Registry** toggle.

## Supported package formats

- [Maven packages](maven/_index.md)

## Virtual registry workflows

When you create a virtual registry:

- The registry is hosted at a top-level Group for a given package format. Projects and subgroups are not supported.
- The virtual registry object links to an ordered list of available upstreams (up to 20). Each upstream points to an external registry.
- External registries can be public or private. Credentials for private registries are stored in the upstream itself, so you do not need to store them in the package manager configuration.

When a virtual registry receives a request for a package:

- The registry walks through the ordered list of upstreams to find one that can fulfill the request.
- If the requested file is found in an upstream, the virtual registry returns that file and caches it for future requests. [Caching](#caching-system) increases the availability of dependencies if you've pulled them at least once through the virtual registry.

## Caching system

All upstream registries have a caching system that:

- Stores requests in a cache entry
- Serves the responses for identical requests from the GitLab virtual registry

This way, the virtual registry does not have to contact the upstream again when the same package is requested.

If a requested path has not been cached in any of the available upstreams:

1. The virtual registry walks through the ordered list of upstreams to find one that can fulfill the request.
1. When an upstream is found that can fulfill the request, the virtual registry pulls the response from the upstream with the provided credentials if necessary.

If the requested path has been cached in any of the available upstreams:

1. The virtual registry checks the [cache validity period](#cache-validity-period) to see if the cache entry needs to be refreshed before forwarding the response.
1. If the cache is valid, the cache entry of the upstream fulfills the request.
   - If a lower priority upstream has the request in its cache, and a higher priority contains the file but has not cached the request, the lower priority upstream fulfills the request. The virtual registry does not walk the ordered list of upstreams again.

The virtual registry returns a `404 Not Found` error if it cannot find an upstream to fulfill the request.

### Cache validity period

The cache validity period sets the amount of time, in hours,
that a cache entry is considered valid to fulfill a request.

Before the virtual registry pulls from an existing cache entry,
it checks the cache validity period to determine if the entry must be refreshed or not.

If the entry is outside the validity period, the virtual registry checks
if the upstream response is identical to the one in the cache. If:

- The response is identical, the entry is used to fulfill the request.
- The response is not identical, the response is downloaded again from the upstream to overwrite the upstream cache entry.

If the virtual registry cannot connect to an upstream due to network conditions,
the upstream serves the request with the available cache entry.

As long as the virtual registry has the response related to
a request in the cache, that request is fulfilled,
even when outside the validity period.

#### Set the cache validity period

The cache validity period is important in the overall performance of the virtual registry to fulfill requests. Contacting external registries is a costly operation. Smaller validity periods increase the amount of checks, and longer periods decrease them.

You can turn off cache validity checks by setting it to `0`.

The default value of the cache validity period is `24` hours.

You should set the cache validity period to `0` when the external registry targeted by the upstream is known to have immutable responses. This is often the case with official public registries. For more information, check your [supported package format](#supported-package-formats).

### Object storage usage

Cache entries save their files in object storage in the [`dependency_proxy` bucket](../../../administration/object_storage.md#configure-the-parameters-of-each-object).

Object storage usage counts towards the top-level group [object storage usage limit](../../storage_usage_quotas.md#view-storage).

## Cleanup policies

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) in GitLab 18.6 [with a flag](../../../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Virtual registries cache packages from upstream registries to improve performance and availability. Over time, these cached entries can accumulate and consume significant storage space. Use cleanup policies to automatically manage cached content and reduce storage usage.

A cleanup policy is a scheduled job that removes cached entries based on configurable rules. When a cleanup policy runs, it identifies cached entries that haven't been downloaded recently and removes them from storage.

### Cleanup policies workflow

In the virtual registry, cleanup policies:

1. Identify cached entries that have not been downloaded within the specified retention period.
1. Remove unused cached entries from object storage.
1. Preserve frequently accessed cached entries to maintain performance.

A cleanup policy affects only cached content from upstream registries. It does not affect:

- Virtual registry configurations
- Upstream registry settings
- Packages stored in your project's package registry

### Manage cleanup policies

Prerequisites:

- You must have the Owner role for the top-level group.
- The virtual registry must be turned on for the group.

Each top-level group can have only one cleanup policy.
The cleanup policy applies to all virtual registries in that group.

You can manage cleanup policies using the [Virtual registries cleanup policies API](../../../api/virtual_registries_cleanup_policies.md).

### Cleanup policy settings

Use the following settings to control a cleanup policy:

- **Cadence**: Controls how frequently the cleanup policy runs. Available options include daily, weekly, and monthly intervals.
- **Retention period**: Determines how long cached entries are kept after their last download. Entries that haven't been downloaded within this period are eligible for removal.

### Monitor cleanup policy execution

After a cleanup policy runs, you can view the following execution metrics:

- When the policy last ran.
- When the policy is scheduled to run next.
- How many cached entries were removed.
- Total storage space freed.
- Any errors that occurred during execution.

These metrics help you understand the effectiveness of your cleanup policy
so you can adjust settings as needed.

## Performance considerations

Virtual registry performance might vary based on factors like:

- Whether or not a requested file is cached from an upstream registry
- How quickly upstream registries can respond if a file exists or not
- Which client is pulling dependencies, and the proximity of the client to the GitLab instance

### Tradeoffs

Virtual registries are more advanced than public registries.
When you pull dependencies with a virtual registry,
it might take longer than other registries, such as public, official registries.

Compared with public registries, virtual registries
also support multiple upstream registries and authentication.

### Upstream prioritization

Upstream registries are organized in ordered lists. Whenever a request is not
found in a cache, the virtual registry walks the ordered list to find the
upstream with the highest priority that can fulfill the request.
This system noticeably impacts the performance of a virtual registry.

When you manage a list of private upstream registries:

- You should prioritize registries with the most packages at the top of the list. This approach:
  - Increases the chances that a high-priority registry can fulfill the request
  - Prevents walking the entire ordered list to find a valid upstream registry
- You should put registries with the least amount of packages at the bottom of the list.

### Performance improvements with usage

When you create a virtual registry, the cache of each configured upstream is empty. Each request requires the virtual registry to walk the list of available upstream registries to fulfill a request. These initial requests take longer to fulfill.

When an upstream registry caches a request, the time to fulfill an identical request decreases. Over time, the overall performance of the virtual registry improves as more upstream registries cache more requests.

### Use the CI/CD cache

You can use [caching in GitLab CI/CD](../../../ci/caching/_index.md#common-use-cases-for-caches) so that jobs do not have to download dependencies from the virtual registry.

This method improves execution time, but also duplicates storage for each dependency (dependencies are stored in the CI/CD cache and virtual registry).
