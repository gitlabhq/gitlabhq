---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reduce dependency proxy storage for container images
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

There's no automatic removal process for blobs. Unless you delete them manually, they're stored
indefinitely. This page covers several options for clearing unused items from the cache.

## Check dependency proxy storage use

The [**Usage Quotas**](../../storage_usage_quotas.md) page displays storage usage for the dependency proxy for container images.

## Use the API to clear the cache

To reclaim disk space used by image blobs that are no longer needed, use the
[dependency proxy API](../../../api/dependency_proxy.md)
to clear the entire cache. If you clear the cache, the next time a pipeline runs it must pull an
image or tag from Docker Hub.

## Cleanup policies

> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/350682) from Developer to Maintainer in GitLab 15.0.
> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) from Maintainer to Owner in GitLab 17.0.

### Enable cleanup policies from within GitLab

You can enable an automatic time-to-live (TTL) policy for the dependency proxy for container images from the user
interface. To do this, go to your group's **Settings > Packages and registries > Dependency Proxy**
and enable the setting to automatically clear items from the cache after 90 days.

### Enable cleanup policies with GraphQL

The cleanup policy is a scheduled job you can use to clear cached images that are no longer used,
freeing up additional storage space. The policies use time-to-live (TTL) logic:

- The number of days is configured.
- All cached dependency proxy files that have not been pulled in that many days are deleted.

Use the [GraphQL API](../../../api/graphql/reference/_index.md#mutationupdatedependencyproxyimagettlgrouppolicy)
to enable and configure cleanup policies:

```graphql
mutation {
  updateDependencyProxyImageTtlGroupPolicy(input:
    {
      groupPath: "<your-full-group-path>",
      enabled: true,
      ttl: 90
    }
  ) {
    dependencyProxyImageTtlPolicy {
      enabled
      ttl
    }
    errors
  }
}
```

See the [Getting started with GraphQL](../../../api/graphql/getting_started.md)
guide to learn how to make GraphQL queries.

When the policy is initially enabled, the default TTL setting is 90 days. Once enabled, stale
dependency proxy files are queued for deletion each day. Deletion may not occur right away due to
processing time. If the image is pulled after the cached files are marked as expired, the expired
files are ignored and new files are downloaded and cached from the external registry.
