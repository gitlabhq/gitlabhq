---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo experiments

The following GitLab Duo features are
[experiments](../../policy/experiment-beta-support.md#experiment).

## Forecast deployment frequency with Value stream forecasting

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Ultimate. In the future, Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10228) in GitLab 16.2 as an [experiment](../../policy/experiment-beta-support.md#experiment).

Improve your planning and decision-making by predicting productivity metrics and
identifying anomalies across your software development lifecycle.

Prerequisites:

- You must belong to at least one group with the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
- You must have permission to view the CI/CD analytics.

To view a forecast of deployment frequency in CI/CD Analytics:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > CI/CD analytics**.
1. Select the **Deployment frequency** tab.
1. Turn on the **Show forecast** toggle.
1. On the confirmation dialog, select **Accept testing terms**.

The forecast is displayed as a dotted line on the chart. Data is forecasted for
a duration that is half of the selected date range.

For example, if you select a 30-day range, a forecast for the following 15 days
is displayed.

![Forecast deployment frequency](img/forecast_deployment_frequency.png)

Provide feedback on this experimental feature in [issue 416833](https://gitlab.com/gitlab-org/gitlab/-/issues/416833).

## Populate an issue with Issue description generation

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10762) in GitLab 16.3 as an [experiment](../../policy/experiment-beta-support.md#experiment).

Generate a detailed description for an issue based on a short summary you provide.

Prerequisites:

- You must belong to at least one group with the [experiment and beta features setting](turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
- You must have permission to view the issue.
- Only available for the plain text editor.

To generate an issue description:

1. Create a new issue.
1. Above the **Description** field, select **GitLab Duo** (**{tanuki-ai}**) **> Generate issue description**.
1. Write a short description and select **Submit**.

The issue description is replaced with AI-generated text.

Provide feedback on this experimental feature in [issue 409844](https://gitlab.com/gitlab-org/gitlab/-/issues/409844).

**Data usage**: When you use this feature, the text you enter is sent to
the large [language model listed on the GitLab Duo page](index.md#issue-description-generation).
