---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo experiments

The following GitLab Duo features are
[experiments](../../policy/experiment-beta-support.md#experiment).

## Summarize issue discussions with Discussion summary

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10344) in GitLab 16.0 as an [experiment](../../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the issue must:
  - Enable the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the issue.

You can generate a summary of discussions on an issue:

1. In an issue, scroll to the **Activity** section.
1. Select **View summary**.

The comments in the issue are summarized in as many as 10 list items.
The summary is displayed only for you.

Provide feedback on this experimental feature in [issue 407779](https://gitlab.com/gitlab-org/gitlab/-/issues/407779).

**Data usage**: When you use this feature, the text of all comments on the issue are sent to the large
language model referenced above.

## Forecast deployment frequency with Value stream forecasting

DETAILS:
**Tier:** GitLab.com and Self-managed: For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md). <br>GitLab Dedicated: GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10228) in GitLab 16.2 as an [experiment](../../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the CI/CD analytics.

In CI/CD Analytics, you can view a forecast of deployment frequency:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > CI/CD analytics**.
1. Select the **Deployment frequency** tab.
1. Turn on the **Show forecast** toggle.
1. On the confirmation dialog, select **Accept testing terms**.

The forecast is displayed as a dotted line on the chart. Data is forecasted for a duration that is half of the selected date range.
For example, if you select a 30-day range, a forecast for the following 15 days is displayed.

![Forecast deployment frequency](img/forecast_deployment_frequency.png)

Provide feedback on this experimental feature in [issue 416833](https://gitlab.com/gitlab-org/gitlab/-/issues/416833).

## Root cause analysis

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123692) in GitLab 16.2 as an [experiment](../../policy/experiment-beta-support.md#experiment).

You can learn more about failed CI/CD jobs by using GitLab Duo Root cause analysis.

Prerequisites:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the CI/CD job.

To view root cause analysis:

1. Open a merge request.
1. On the **Pipelines** tab, select the failed CI/CD job.
1. Above the job output, select **Troubleshoot**.

An analysis of the reasons for the failure is displayed.

## Summarize an issue with Issue description generation

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10762) in GitLab 16.3 as an [experiment](../../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the issue.

You can generate the description for an issue from a short summary.

1. Create a new issue.
1. Above the **Description** field, select **GitLab Duo** (**{tanuki-ai}**) **> Generate issue description**.
1. Write a short description and select **Submit**.

The issue description is replaced with AI-generated text.

Provide feedback on this experimental feature in [issue 409844](https://gitlab.com/gitlab-org/gitlab/-/issues/409844).

**Data usage**: When you use this feature, the text you enter is sent to the large
language model referenced above.
