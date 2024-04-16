---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Reduce Dependency Proxy Storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

There's no automatic removal process for blobs. Unless you delete them manually, they're stored
indefinitely. Since this impacts your
[storage usage quota](../../usage_quotas.md),
it's important that you clear unused items from the cache. This page covers several options for
doing so.

## Check Dependency Proxy Storage Use

The Usage Quotas page (**Settings > Usage Quotas > Storage**) displays storage usage for Packages, which includes the Dependency Proxy,
however, the storage is not yet displayed.

## Use the API to clear the cache

To reclaim disk space used by image blobs that are no longer needed, use the
[Dependency Proxy API](../../../api/dependency_proxy.md)
to clear the entire cache. If you clear the cache, the next time a pipeline runs it must pull an
image or tag from Docker Hub.

## Cleanup policies

> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/350682) from Developer to Maintainer in GitLab 15.0.

### Enable cleanup policies from within GitLab

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340777) in GitLab 14.6

You can enable an automatic time-to-live (TTL) policy for the Dependency Proxy from the user
interface. To do this, go to your group's **Settings > Packages and registries > Dependency Proxy**
and enable the setting to automatically clear items from the cache after 90 days.

### Enable cleanup policies with GraphQL

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294187) in GitLab 14.4.

The cleanup policy is a scheduled job you can use to clear cached images that are no longer used,
freeing up additional storage space. The policies use time-to-live (TTL) logic:

- The number of days is configured.
- All cached dependency proxy files that have not been pulled in that many days are deleted.

Use the [GraphQL API](../../../api/graphql/reference/index.md#mutationupdatedependencyproxyimagettlgrouppolicy)
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
