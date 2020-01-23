# Analytics workspace

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/12077) in GitLab 12.2.

The Analytics workspace will make it possible to aggregate analytics across
GitLab, so that users can view information across multiple projects and groups
in one place.

To access the centralized analytics workspace, enable at least
[one of the features](#available-analytics) under the workspace.

Once enabled, click on **Analytics** from the top navigation bar.

## Available analytics

From the centralized analytics workspace, the following analytics are available:

- [Code Review Analytics](code_review_analytics.md). **(STARTER)**
- [Cycle Analytics](cycle_analytics.md), enabled with the `cycle_analytics`
  [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-in-development). **(PREMIUM)**
- [Productivity Analytics](productivity_analytics.md), enabled with the `productivity_analytics`
  [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-in-development). **(PREMIUM)**

NOTE: **Note:**
Project-level Cycle Analytics are still available at a project's **Project > Cycle Analytics**.

## Other analytics tools

In addition to the tools available in the Analytics workspace, GitLab provides:

- [Contribution analytics](../group/contribution_analytics/index.md). **(STARTER)**
- [Issue analytics](../group/issues_analytics/index.md). **(PREMIUM)**
