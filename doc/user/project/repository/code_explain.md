---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Explain code in a file
---

DETAILS:
**Tier:** Premium with GitLab Duo Pro, Ultimate with GitLab Duo Pro or Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - Introduced in GitLab 15.11 as an [experiment](../../../policy/development_stages_support.md#experiment) on GitLab.com.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) in GitLab 16.8.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

If you spend a lot of time trying to understand code that others have created, or
you struggle to understand code written in a language you are not familiar with,
you can ask GitLab Duo to explain the code to you.

Prerequisites:

- You must belong to at least one group with the
  [experiment and beta features setting](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
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

- A [merge request](../merge_requests/changes.md#explain-code-in-a-merge-request).
- The [IDE](../../gitlab_duo_chat/examples.md#explain-selected-code).
