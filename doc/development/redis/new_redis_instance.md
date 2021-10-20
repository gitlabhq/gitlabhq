---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Add a new Redis instance

GitLab can make use of multiple [Redis instances](../redis.md#redis-instances).
These instances are functionally partitioned so that, for example, we
can store [CI trace chunks](../../administration/job_logs.md#incremental-logging-architecture)
from one Redis instance while storing sessions in another.

From time to time we might want to add a new Redis instance. Typically this will
be a functional partition split from one of the existing instances such as the
cache or shared state. This document describes an approach
for adding a new Redis instance that handles existing data, based on
prior examples:

- [Dedicated Redis instance for Trace Chunk storage](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/462).
- [Create dedicated Redis instance for Rate Limiting data](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/526).

This document does not cover the operational side of preparing and configuring
the new Redis instance in detail, but the example epics do contain information
on previous approaches to this.

## Step 1: Support configuring the new instance

Before we can switch any features to using the new instance, we have to support
configuring it and referring to it in the codebase. We must support the
main installation types:

- Source installs (including development environments) - [example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62767)
- Omnibus - [example MR](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5316)
- Helm charts - [example MR](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2031)

### Fallback instance

In the application code, we need to define a fallback instance in case the new
instance is not configured. For example, if a GitLab instance has already
configured a separate shared state Redis, and we are partitioning data from the
shared state Redis, our new instance's configuration should default to that of
the shared state Redis when it's not present. Otherwise we could break instances
that don't configure the new Redis instance as soon as it's available.

You can [define a `.config_fallback` method](https://gitlab.com/gitlab-org/gitlab/-/blob/a75471dd744678f1a59eeb99f71fca577b155acd/lib/gitlab/redis/wrapper.rb#L69-87)
in `Gitlab::Redis::Wrapper` (the base class for all Redis instances)
that defines the instance to be used if this one is not configured. If we were
adding a `Foo` instance that should fall back to `SharedState`, we can do that
like this:

```ruby
module Gitlab
  module Redis
    class Foo < ::Gitlab::Redis::Wrapper
      # The data we store on Foo used to be stored on SharedState.
      def self.config_fallback
        SharedState
      end
    end
  end
end
```

We should also add specs like those in
[`trace_chunks_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/gitlab/redis/trace_chunks_spec.rb)
to ensure that this fallback works correctly.

## Step 2: Support writing to and reading from the new instance

When migrating to the new instance, we must account for cases where data is
either on:

- The 'old' (original) instance.
- The new one that we have just added support for.

As a result we may need to support reading from and writing to both
instances, depending on some condition.

The exact condition to use varies depending on the data to be migrated. For
the trace chunks case above, there was already a database column indicating where the
data was stored (as there are other storage options than Redis).

This step may not apply if the data has a very short lifetime (a few minutes at most)
and is not critical. In that case, we
may decide that it is OK to incur a small amount of data loss and switch
over through configuration only.

If there is not a more natural way to mark where the data is stored, using a
[feature flag](../feature_flags/index.md) may be convenient:

- It does not require an application restart to take effect.
- It applies to all application instances (Sidekiq, API, web, etc.) at
  the same time.
- It supports incremental rollout - ideally by actor (project, group,
  user, etc.) - so that we can monitor for errors and roll back easily.

## Step 3: Migrate the data

We then need to configure the new instance for GitLab.com's production and
staging environments. Hopefully it will be possible to test this change
effectively on staging, to at least make sure that basic usage continues to
work.

After that is done, we can roll out the change to production. Ideally this would
be in an incremental fashion, following the
[standard incremental rollout](../feature_flags/controls.md#rolling-out-changes)
documentation for feature flags.

When we have been using the new instance 100% of the time in production for a
while and there are no issues, we can proceed.

## Step 4: clean up after the migration

<!-- markdownlint-disable MD044 -->
We may choose to keep the migration paths or remove them, depending on whether
or not we expect self-managed instances to perform this migration.
[gitlab-com/gl-infra/scalability#1131](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1131#note_603354746)
contains a discussion on this topic for the trace chunks feature flag. It may
be - as in that case - that we decide that the maintenance costs of supporting
the migration code are higher than the benefits of allowing self-managed
instances to perform this migration seamlessly, if we expect self-managed
instances to cope without this functional partition.
<!-- markdownlint-enable MD044 -->

If we decide to keep the migration code:

- We should document the migration steps.
- If we used a feature flag, we should ensure it's an [ops type feature
  flag](../feature_flags/index.md#ops-type), as these are long-lived flags.

Otherwise, we can remove the flags and conclude the project.
