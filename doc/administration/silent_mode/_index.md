---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Silent Mode
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9826) in GitLab 15.11. This feature was an [experiment](../../policy/development_stages_support.md#experiment).
> - Enabling and disabling Silent Mode through the web UI was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131090) in GitLab 16.4.
> - [Generally available](../../policy/development_stages_support.md#generally-available) in GitLab 16.6.

Silent Mode allows you to silence outbound communication, such as emails, from GitLab. Silent Mode is not intended to be used on environments which are in-use. Two use-cases are:

- Validating Geo site promotion. You have a secondary Geo site as part of your
  [disaster recovery](../geo/disaster_recovery/_index.md) solution. You want to
  regularly test promoting it to become a primary Geo site, as a best practice
  to ensure your disaster recovery plan actually works. But you don't want to
  actually perform an entire failover, since the primary site lives in a region
  which provides the lowest latency to your users. And you don't want to take
  downtime during every regular test. So, you let the primary site remain up,
  while you promote the secondary site. You start smoke testing the promoted
  site. But, the promoted site starts emailing users, the push mirrors push
  changes to external Git repositories, etc. This is where Silent Mode comes in.
  You can enable it as part of site promotion, to avoid this issue.
- Validating GitLab backups. You set up a testing instance to test that your
  backups restore successfully. As part of the restore, you enable Silent Mode,
  for example to avoid sending invalid emails to users.

## Enable Silent Mode

Prerequisites:

- You must have administrator access.

There are multiple ways to enable Silent Mode:

- **Web UI**

  1. On the left sidebar, at the bottom, select **Admin**..
  1. On the left sidebar, select **Settings > General**.
  1. Expand **Silent Mode**, and toggle **Enable Silent Mode**.
  1. Changes are saved immediately.

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=true"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: true)
  ```

It may take up to a minute to take effect. [Issue 405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433) proposes removing this delay.

## Disable Silent Mode

Prerequisites:

- You must have administrator access.

There are multiple ways to disable Silent Mode:

- **Web UI**

  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **Silent Mode**, and toggle **Enable Silent Mode**.
  1. Changes are saved immediately.

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=false"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: false)
  ```

It may take up to a minute to take effect. [Issue 405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433) proposes removing this delay.

## Behavior of GitLab features in Silent Mode

This section documents the current behavior of GitLab when Silent Mode is enabled. The work for the first iteration of Silent Mode is tracked by [Epic 9826](https://gitlab.com/groups/gitlab-org/-/epics/9826).

When Silent Mode is enabled, a banner is displayed at the top of the page for all users stating the setting is enabled and **All outbound communications are blocked.**.

### Outbound communications that are silenced

Outbound communications from the following features are silenced by Silent Mode.

| Feature                                                                   | Notes                                                                                                                                                                                                                                                   |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [GitLab Duo](../../user/gitlab_duo_chat/_index.md)                         | GitLab Duo features cannot contact external language model providers. |
| [Project and group webhooks](../../user/project/integrations/webhooks.md) | Triggering webhook tests via the UI results in HTTP status 500 responses.                                                                                                                                                                               |
| [System hooks](../system_hooks.md)                                        |                                                                                                                                                                                                                                                         |
| [Remote mirrors](../../user/project/repository/mirror/_index.md)           | Pushes to remote mirrors are skipped. Pulls from remote mirrors is skipped.                                                                                                                                                                             |
| [Executable integrations](../../user/project/integrations/_index.md)       | The integrations are not executed.                                                                                                                                                                                                                      |
| [Service Desk](../../user/project/service_desk/_index.md)                  | Incoming emails still raise issues, but the users who sent the emails to Service Desk are not notified of issue creation or comments on their issues.                                                                                                   |
| Outbound emails                                                           | At the moment when an email should be sent by GitLab, it is instead dropped. It is not queued anywhere.                                                                                                                                                 |
| Outbound HTTP requests                                                    | Many HTTP requests are blocked where features are not blocked or skipped explicitly. These may produce errors. If a particular error is problematic for testing during Silent Mode, consult [GitLab Support](https://about.gitlab.com/support/). |

### Outbound communications that are not silenced

Outbound communications from the following features are not silenced by Silent Mode.

| Feature                                                                                                     | Notes                                                                                                                                                                                                                                           |
| ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Dependency proxy](../packages/dependency_proxy.md)                                                         | Pulling images that are not cached will fetch from the source as usual. Consider pull rate limits.                                                                                                                                              |
| [File hooks](../file_hooks.md)                                                                              |                                                                                                                                                                                                                                                 |
| [Server hooks](../server_hooks.md)                                                                          |                                                                                                                                                                                                                                                 |
| [Advanced search](../../integration/advanced_search/elasticsearch.md)                                       | If two GitLab instances are using the same Advanced Search instance, then they can both modify Search data. This is a split-brain scenario which can occur for example after promoting a secondary Geo site while the primary Geo site is live. |
| [Snowplow](../../development/internal_analytics/product_analytics.md)                                                           | There is [a proposal to silence these requests](https://gitlab.com/gitlab-org/gitlab/-/issues/409661).                                                                                                                                          |
| [Deprecated Kubernetes Connections](../../user/clusters/agent/_index.md)                                    | There is [a proposal to silence these requests](https://gitlab.com/gitlab-org/gitlab/-/issues/396470).                                                                                                                                          |
| [Container registry webhooks](../packages/container_registry.md#configure-container-registry-notifications) | There is [a proposal to silence these requests](https://gitlab.com/gitlab-org/gitlab/-/issues/409682).                                                                                                                                          |
