---
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Analytics

## Instance-level analytics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12077) in GitLab 12.2.

Instance-level analytics make it possible to aggregate analytics across
GitLab, so that users can view information across multiple projects and groups
in one place.

[Learn more about instance-level analytics](../admin_area/analytics/index.md).

## Group-level analytics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/195979) in GitLab 12.8.

The following analytics features are available at the group level:

- [Contribution](../group/contribution_analytics/index.md). **(STARTER)**
- [Insights](../group/insights/index.md). **(ULTIMATE)**
- [Issue](../group/issues_analytics/index.md). **(PREMIUM)**
- [Productivity](productivity_analytics.md) **(PREMIUM)**
- [Repositories](../group/repositories_analytics/index.md) **(PREMIUM)**
- [Value Stream](value_stream_analytics.md). **(PREMIUM)**

## Project-level analytics

The following analytics features are available at the project level:

- [CI/CD](../../ci/pipelines/index.md#pipeline-success-and-duration-charts). **(STARTER)**
- [Code Review](code_review_analytics.md). **(STARTER)**
- [Insights](../project/insights/index.md). **(ULTIMATE)**
- [Issue](../group/issues_analytics/index.md). **(PREMIUM)**
- [Merge Request](merge_request_analytics.md), enabled with the `project_merge_request_analytics`
  [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-locally-in-development). **(STARTER)**
- [Repository](repository_analytics.md). **(CORE)**
- [Value Stream](value_stream_analytics.md). **(CORE)**
