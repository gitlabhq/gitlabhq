---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Explain code in a file

DETAILS:
**Tier:** For a limited time, Premium and Ultimate. In the future, [GitLab Duo Pro or Enterprise](../../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

> - Introduced in GitLab 15.11 as an [experiment](../../../policy/experiment-beta-support.md#experiment) on GitLab.com.

If you spend a lot of time trying to understand code that others have created, or
you struggle to understand code written in a language you are not familiar with,
you can ask GitLab Duo to explain the code to you.

Prerequisites:

- You must belong to at least one group with the
  [experiment and beta features setting](../../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
- You must have access to view the project.

To explain the code in a file:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select a file that contains code.
1. Select the lines you want explained.
1. On the left side, select the question mark (**{question}**).
   You might have to scroll to the first line of your selection to view it.

   ![explain code in a file](img/explain_code_v17_1.png)

Duo Chat explains the code. It might take a moment for the explanation to be generated.

If you'd like, you can provide feedback about the quality of the explanation.

We cannot guarantee that the large language model produces results that are correct. Use the explanation with caution.

You can also explain code in:

- A [merge request](../../../user/project/merge_requests/changes.md#explain-code-in-a-merge-request).
- The [IDE](../../../user/gitlab_duo_chat/examples.md#explain-code-in-the-ide).
