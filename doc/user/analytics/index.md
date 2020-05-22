---
stage: Manage
group: Analytics
To determine the technical writer assigned to the Stage/Group associated with this page, see:
  https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Analytics

## Analytics workspace

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12077) in GitLab 12.2.

The Analytics workspace will make it possible to aggregate analytics across
GitLab, so that users can view information across multiple projects and groups
in one place.

To access the Analytics workspace, click on **More > Analytics** in the top navigation bar.

## Group-level analytics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/195979) in GitLab 12.8.

The following analytics features are available at the group level:

- [Contribution](../group/contribution_analytics/index.md). **(STARTER)**
- [Insights](../group/insights/index.md). **(ULTIMATE)**
- [Issues](../group/issues_analytics/index.md). **(PREMIUM)**
- [Productivity](productivity_analytics.md), enabled with the `productivity_analytics`
  [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-in-development). **(PREMIUM)**
- [Value Stream](value_stream_analytics.md), enabled with the `cycle_analytics`
  [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-in-development). **(PREMIUM)**

## Project-level analytics

The following analytics features are available at the project level:

- [CI/CD](../../ci/pipelines/index.md#pipeline-success-and-duration-charts). **(STARTER)**
- [Code Review](code_review_analytics.md). **(STARTER)**
- [Insights](../group/insights/index.md). **(ULTIMATE)**
- [Issues](../group/issues_analytics/index.md). **(PREMIUM)**
- [Repository](repository_analytics.md).
- [Value Stream](value_stream_analytics.md), enabled with the `cycle_analytics`
  [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-in-development). **(STARTER)**
