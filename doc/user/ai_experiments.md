---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo experiments

The following GitLab Duo features are
[experiments](../policy/experiment-beta-support.md#experiment).

## Explain code in the Web UI with Code explanation

DETAILS:
**Tier:** Freely available for Premium and Ultimate for a limited time. In the future, will require [GitLab Duo Pro or Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - Introduced in GitLab 15.11 as an [experiment](../policy/experiment-beta-support.md#experiment) on GitLab.com.

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the project.

GitLab can help you get up to speed faster if you:

- Spend a lot of time trying to understand pieces of code that others have created, or
- Struggle to understand code written in a language that you are not familiar with.

By using a large language model, GitLab can explain the code in natural language.

To explain your code:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select any file in your project that contains code.
1. On the file, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the first line of your selection to view it. This sends the selected code, together with a prompt, to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.
1. Provide feedback about how satisfied you are with the explanation, so we can improve the results.

You can also have code explained in the context of a merge request. To explain
code in a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**, then select your merge request.
1. On the secondary menu, select **Changes**.
1. On the file you would like explained, select the three dots (**{ellipsis_v}**) and select **View File @ $SHA**.

   A separate browser tab opens and shows the full file with the latest changes.

1. On the new tab, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the first line of your selection to view it. This sends the selected code, together with a prompt, to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.
1. Provide feedback about how satisfied you are with the explanation, so we can improve the results.

![How to use the Explain Code Experiment](img/explain_code_experiment.png)

We cannot guarantee that the large language model produces results that are correct. Use the explanation with caution.

## Summarize issue discussions with Discussion summary

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10344) in GitLab 16.0 as an [experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the issue must:
  - Enable the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features) enabled.
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
**Tier:** Freely available for Ultimate for a limited time for self-managed and GitLab.com. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md). For GitLab Dedicated, you must have GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10228) in GitLab 16.2 as an [experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features) enabled.
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
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123692) in GitLab 16.2 as an [experiment](../policy/experiment-beta-support.md#experiment).

You can learn more about failed CI/CD jobs by using GitLab Duo Root cause analysis.

Prerequisites:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the CI/CD job.

To view root cause analysis:

1. Open a merge request.
1. On the **Pipelines** tab, select the failed CI/CD job.
1. Above the job output, select **Troubleshoot**.

An analysis of the reasons for the failure is displayed.

## Summarize an issue with Issue description generation

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10762) in GitLab 16.3 as an [experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](ai_features_enable.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the issue.

You can generate the description for an issue from a short summary.

1. Create a new issue.
1. Above the **Description** field, select **AI actions > Generate issue description**.
1. Write a short description and select **Submit**.

The issue description is replaced with AI-generated text.

Provide feedback on this experimental feature in [issue 409844](https://gitlab.com/gitlab-org/gitlab/-/issues/409844).

**Data usage**: When you use this feature, the text you enter is sent to the large
language model referenced above.
