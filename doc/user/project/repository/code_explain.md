---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Explain code in a file

DETAILS:
**Tier:** Freely available for Premium and Ultimate for a limited time. In the future, will require [GitLab Duo Pro or Enterprise](../../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - Introduced in GitLab 15.11 as an [experiment](../../../policy/experiment-beta-support.md#experiment) on GitLab.com.

GitLab Duo Code explanation is an [experiment](../../../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](../../../user/ai_features_enable.md#turn-on-beta-and-experimental-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](../../../user/ai_features_enable.md#turn-on-beta-and-experimental-features) enabled.
  - Have sufficient permissions to view the project.

GitLab can help you get up to speed faster if you:

- Spend a lot of time trying to understand pieces of code that others have created, or
- Struggle to understand code written in a language that you are not familiar with.

By using a large language model, GitLab can explain the code in natural language.

To explain your code in a file:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select any file in your project that contains code.
1. On the file, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the first line of your selection to view it. This sends the selected code, together with a prompt, to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.
1. Provide feedback about how satisfied you are with the explanation, so we can improve the results.

![How to use the Explain Code Experiment](../../../user/img/explain_code_experiment.png)

We cannot guarantee that the large language model produces results that are correct. Use the explanation with caution.

You can also explain code in:

- A [merge request](../../../user/project/merge_requests/changes.md#explain-code-in-a-merge-request).
- The [IDE](../../../user/gitlab_duo_chat_examples.md#explain-code-in-the-ide).
