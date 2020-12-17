---
stage: Create
group: Gitaly
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Gitaly timeouts **(CORE ONLY)**

[Gitaly](../../../administration/gitaly/index.md) timeouts are configurable. The timeouts can be
configured to make sure that long running Gitaly calls don't needlessly take up resources.

To access Gitaly timeout settings:

1. Go to **Admin Area > Settings > Preferences**.
1. Expand the **Gitaly** section.

## Available timeouts

The following timeouts can be modified:

- **Default Timeout Period**. This timeout is the default for most Gitaly calls. It should be shorter than the
  worker timeout that can be configured for [Puma](https://docs.gitlab.com/omnibus/settings/puma.html#puma-settings)
  or [Unicorn](https://docs.gitlab.com/omnibus/settings/unicorn.html). Used to make sure that Gitaly
  calls made within a web request cannot exceed the entire request timeout.
  Defaults to 55 seconds.

- **Fast Timeout Period**. This is the timeout for very short Gitaly calls. Defaults to 10 seconds.
- **Medium Timeout Period**. This timeout should be between the default and the fast timeout.
  Defaults to 30 seconds.
