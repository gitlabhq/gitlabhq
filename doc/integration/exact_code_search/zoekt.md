---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Zoekt
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 15.9 [with flags](../../administration/feature_flags.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) in GitLab 16.6.
> - Feature flags `index_code_with_zoekt` and `search_code_with_zoekt` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) in GitLab 17.1.

WARNING:
This feature is in [beta](../../policy/development_stages_support.md#beta) and subject to change without notice.
For more information, see [epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404).

Zoekt is an open-source search engine designed specifically to search for code.

With this integration, you can use [exact code search](../../user/search/exact_code_search.md)
instead of [advanced search](../../user/search/advanced_search.md) to search for code in GitLab.
You can use exact match and regular expression modes to search for code in a group or repository.

## Install Zoekt

Prerequisites:

- You must have administrator access to the instance.

To [enable exact code search](#enable-exact-code-search) in GitLab,
you must have at least one Zoekt node connected to the instance.
The following installation methods are supported for Zoekt:

- [Zoekt chart](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/)
  (as a standalone chart or subchart of the GitLab Helm chart)
- [GitLab Operator](https://docs.gitlab.com/operator/) (with `gitlab-zoekt.install=true`)
- [Docker Compose](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/tree/main/example/docker-compose)
- [Ansible playbook](https://gitlab.com/johnmason/ansible-gitlab-zoekt) (experiment)

## Enable exact code search

Prerequisites:

- You must have administrator access to the instance.
- You must [install Zoekt](#install-zoekt).

To enable [exact code search](../../user/search/exact_code_search.md) in GitLab:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Exact code search configuration**.
1. Select the **Enable indexing for exact code search** and **Enable exact code search** checkboxes.
1. Select **Save changes**.

## Delete offline nodes automatically

Prerequisites:

- You must have administrator access to the instance.

You can automatically delete Zoekt nodes that are offline for more than 12 hours
and their related indices, repositories, and tasks.

To delete offline nodes automatically:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Exact code search configuration**.
1. Select the **Delete offline nodes automatically after 12 hours** checkbox.
1. Select **Save changes**.

## Index root namespaces automatically

Prerequisites:

- You must have administrator access to the instance.

You can index both existing and new root namespaces automatically.
To index all root namespaces automatically:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Exact code search configuration**.
1. Select the **Index root namespaces automatically** checkbox.
1. Select **Save changes**.

When you disable this setting:

- Existing root namespaces remain indexed.
- New root namespaces are no longer indexed.

## Pause indexing

Prerequisites:

- You must have administrator access to the instance.

To pause indexing for [exact code search](../../user/search/exact_code_search.md):

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Exact code search configuration**.
1. Select the **Pause indexing for exact code search** checkbox.
1. Select **Save changes**.

When you pause indexing for exact code search, all changes in your repository are queued.
To resume indexing, clear the **Pause indexing for exact code search** checkbox.

## Set concurrent indexing tasks

Prerequisites:

- You must have administrator access to the instance.

You can set the number of concurrent indexing tasks for a Zoekt node relative to its CPU capacity.

A higher multiplier means more tasks can run concurrently, which would
improve indexing throughput at the cost of increased CPU usage.
The default value is `1.0` (one task per CPU core).

You can adjust this value based on the node's performance and workload.
To set the number of concurrent indexing tasks:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Exact code search configuration**.
1. In the **Indexing CPU to tasks multiplier** text box, enter a value.

   For example, if a Zoekt node has `4` CPU cores and the multiplier is `1.5`,
   the number of concurrent tasks for the node is `6`.

1. Select **Save changes**.

## Troubleshooting

When working with Zoekt, you might encounter the following issues.

### Namespace is not indexed

When you [enable the setting](#index-root-namespaces-automatically), new namespaces get indexed automatically.
If a namespace is not indexed automatically, inspect the Sidekiq logs to see if the jobs are being processed.
`Search::Zoekt::SchedulingWorker` is responsible for indexing namespaces.

In a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session), you can check:

- Namespaces where Zoekt is not enabled:

  ```ruby
  Namespace.group_namespaces.root_namespaces_without_zoekt_enabled_namespace
  ```

- The status of Zoekt indices:

  ```ruby
  Search::Zoekt::Index.all.pluck(:state, :namespace_id)
  ```

To index a namespace manually, run this command:

```ruby
namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
```
