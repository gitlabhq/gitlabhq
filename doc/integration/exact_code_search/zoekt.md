---
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Zoekt

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) as a [beta](../../policy/experiment-beta-support.md#beta) in GitLab 15.9 [with flags](../../administration/feature_flags.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) in GitLab 16.6.
> - Feature flags `index_code_with_zoekt` and `search_code_with_zoekt` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) in GitLab 17.1.

WARNING:
This feature is in [beta](../../policy/experiment-beta-support.md#beta) and subject to change without notice.
For more information, see [epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404).

Zoekt is an open-source search engine designed specifically to search for code.

With this integration, you can use [exact code search](../../user/search/exact_code_search.md)
instead of [advanced search](../../user/search/advanced_search.md) to search for code in GitLab.
You can use regular expression and exact match modes to search for code in a group or repository.

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

## Index root namespaces automatically

Prerequisites:

- You must have administrator access to the instance.

You can index both existing and new root namespaces automatically. To index all root namespaces automatically:

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
