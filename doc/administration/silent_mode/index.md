---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Silent Mode (Experiment) **(FREE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9826) in GitLab 15.11. This feature is an [Experiment](../../policy/alpha-beta-support.md#experiment).

Silent Mode allows you to suppress outbound communication, such as emails, from GitLab. Silent Mode is not intended to be used on environments which are in-use. Two use-cases are:

- Validating Geo site promotion. You have a secondary Geo site as part of your [disaster recovery](../geo/disaster_recovery/index.md) solution. You want to regularly test promoting it to become a primary Geo site, as a best practice to ensure your disaster recovery plan actually works. But you don't want to actually perform an entire failover, since the primary site lives in a region which provides the lowest latency to your users. And you don't want to take downtime during every regular test. So, you let the primary site remain up, while you promote the secondary site. You start smoke testing the promoted site. But, the promoted site starts emailing users, the push mirrors push changes to external Git repositories, etc. This is where Silent Mode comes in. You can enable it as part of site promotion, to avoid this issue.
- Validating GitLab backups. You set up a testing instance to test that your backups restore successfully. As part of the restore, you enable Silent Mode, for example to avoid sending invalid emails to users.

## Enable Silent Mode

Prerequisites:

- You must have administrator access.

There are two ways to enable Silent Mode:

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=true"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: true)
  ```

## Disable Silent Mode

Prerequisites:

- You must have administrator access.

There are two ways to disable Silent Mode:

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=false"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: false)
  ```

## Behavior of GitLab features in Silent Mode

### Service Desk

Incoming emails still raise issues, but the users who sent the emails to [Service Desk](../../user/project/service_desk.md) are not notified of issue creation or comments on their issues.

### Outbound emails

Outbound emails are suppressed. It may take up to a minute to take effect after enabling Silent Mode. [Issue 405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433) proposes removing this delay.
