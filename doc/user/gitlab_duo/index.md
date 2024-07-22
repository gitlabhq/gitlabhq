---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo

> - [First GitLab Duo features introduced](https://about.gitlab.com/blog/2023/05/03/gitlab-ai-assisted-features/) in GitLab 16.0.
> - [Removed third-party AI setting](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136144) in GitLab 16.6.
> - [Removed support for OpenAI from all GitLab Duo features](https://gitlab.com/groups/gitlab-org/-/epics/10964) in GitLab 16.6.

GitLab Duo is a suite of AI-powered features that assist you while you work in GitLab.
These features aim to help increase velocity and solve key pain points across the software development lifecycle.

GitLab Duo features are available in [IDE extensions](../../editor_extensions/index.md) and the GitLab UI.
Some features are also available as part of [GitLab Duo Chat](../gitlab_duo_chat_examples.md).

GitLab is [transparent](https://handbook.gitlab.com/handbook/values/#transparency).
As GitLab Duo features mature, the documentation will be updated to clearly state
how and where you can access these features.

## Generally available features

### GitLab Duo Chat

DETAILS:
**Tier:** GitLab.com and Self-managed: For a limited time, Premium and Ultimate. In the future, [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). <br>GitLab Dedicated: GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Help you write and understand code faster, get up to speed on the status of projects,
  and quickly learn about GitLab by answering your questions in a chat window.
  Anthropic [`claude-3-5-sonnet-20240620`](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet),
  Anthropic [`claude-3-haiku-20240307`](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-haiku),
  and [Vertex AI Search](https://cloud.google.com/enterprise-search).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=ZQBAuf-CTAY&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](../gitlab_duo_chat.md).

NOTE:
The LLM for GitLab Duo Chat depends on the question asked. For more information, see
the [Duo Chat examples](../gitlab_duo_chat_examples.md).
For self-managed, the models also depend on your GitLab version.
For the most benefit, use the latest GitLab version whenever possible.

### Code Suggestions

DETAILS:
**Tier:** Premium and Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Helps you write code more efficiently by generating code and showing suggestions as you type.
- Large language model (LLM) for code completion: Vertex AI Codey [`code-gecko`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/code-gecko)
- LLM for code generation: Anthropic [`claude-3-5-sonnet-20240620`](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://youtu.be/ds7SG1wgcVM)
- [View documentation](../project/repository/code_suggestions/index.md).

### Code explanation in the IDE

DETAILS:
**Tier:** GitLab.com and Self-managed: For a limited time, Premium and Ultimate. In the future, [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). <br>GitLab Dedicated: GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Helps you understand the selected code by explaining it more clearly.
- LLM: Anthropic: [`claude-3-haiku-20240307`](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-haiku)
- View documentation for [explaining code in the IDE](../gitlab_duo_chat/examples.md#explain-code-in-the-ide).

### Test generation

DETAILS:
**Tier:** GitLab.com and Self-managed: For a limited time, Premium and Ultimate. In the future, [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). <br>GitLab Dedicated: GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Helps catch bugs early by generating tests for the selected code.
- LLM: Anthropic [`Claude-2.1`](https://docs.anthropic.com/en/docs/about-claude/models#legacy-models)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=zWhwuixUkYU&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide).

### GitLab Duo for the CLI

DETAILS:
**Tier:** Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment, Self-managed, GitLab Dedicated

- `glab duo ask` helps you discover or recall `git` commands when and where you need them.
- LLM: Vertex AI Codey [`codechat-bison`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/codechat-bison)
- [View documentation](../../editor_extensions/gitlab_cli/index.md#gitlab-duo-for-the-cli).

### Suggested Reviewers

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

- Helps create faster and higher-quality reviews by automatically suggesting reviewers for your merge request.
- LLM: GitLab creates a machine learning model for each project, which is used to generate reviewers. [View the issue](https://gitlab.com/gitlab-org/modelops/applied-ml/applied-ml-updates/-/issues/10).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=ivwZQgh4Rxw)
- [View documentation](../project/merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers).

### Merge commit message generation

DETAILS:
**Tier:** Premium and Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Helps you merge more quickly by generating meaningful commit messages.
- LLM: Vertex AI Codey [`text-bison`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/text-bison).
- [View documentation](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message).

### Vulnerability explanation

DETAILS:
**Tier:** Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Helps you understand vulnerabilities, how they can be exploited, and how to fix them.
- LLM: Anthropic's [`claude-3-haiku`](https://docs.anthropic.com/en/docs/about-claude/models#claude-3-a-new-generation-of-ai).
- [View documentation](../application_security/vulnerabilities/index.md#explaining-a-vulnerability).

## Beta features

### Merge request template population

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Beta

- Helps populate a merge request more quickly by generating a description based on the contents of the template.
- LLM: Vertex AI Codey [`text-bison`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/text-bison)
- [View documentation](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-from-a-template).

### Merge request summary

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Beta

- Helps populate a merge request more quickly by generating a description based on the code changes.
- LLM: Vertex AI Codey [`text-bison`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/text-bison)
- [View documentation](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes).

## Experimental features

### Issue description generation

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

- Helps populate an issue more quickly by generating a more in-depth description, based on a short summary you provide.
- LLM: Anthropic [`Claude-2.1`](https://docs.anthropic.com/en/docs/about-claude/models#legacy-models)
- [View documentation](experiments.md#summarize-an-issue-with-issue-description-generation).

### Discussion summary

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

- Helps everyone get up to speed by summarizing the lengthy conversations in an issue.
- LLM: Anthropic [`Claude-2.1`](https://docs.anthropic.com/en/docs/about-claude/models#legacy-models)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=IcdxLfTIUgc)
- [View documentation](experiments.md#summarize-issue-discussions-with-discussion-summary).

### Code explanation in a file or merge request

DETAILS:
**Tier:** For a limited time, Premium and Ultimate. In the future, [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

- Helps you understand the selected code by explaining it more clearly.
- LLM: Anthropic: [`claude-3-haiku-20240307`](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-haiku)
- View documentation for explaining code in:
  - [A file](../../user/project/repository/code_explain.md).
  - [A merge request](../../user/project/merge_requests/changes.md#explain-code-in-a-merge-request).

### Code review summary

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

- Helps make merge request handover to reviewers easier by summarizing all the comments in a merge request review.
- LLM: Vertex AI Codey [`text-bison`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/text-bison)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=Bx6Zajyuy9k&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review).

### Root cause analysis

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

- Helps you determine the root cause for a CI/CD job failure by analyzing the logs.
- LLM: Vertex AI Codey [`text-bison`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/text-bison)
- [View documentation](experiments.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).

### Vulnerability resolution

DETAILS:
**Tier:** Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com
**Status:** Experiment

- Help resolve a vulnerability by generating a merge request that addresses it.
- LLM: Anthropic's [`claude-3.5-sonnet`](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet).
- [View documentation](../application_security/vulnerabilities/index.md#vulnerability-resolution).

### Product Analytics

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com
**Status:** Experiment

- Processes and responds to your questions about your application's usage data.
- LLM: Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat)
- [View documentation](../analytics/analytics_dashboards.md#generate-a-custom-visualization-with-gitlab-duo).

### Value stream forecasting

DETAILS:
**Tier:** GitLab.com and Self-managed: For a limited time, Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md). <br>GitLab Dedicated: GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

- Helps you improve planning and decision-making by predicting productivity metrics and identifying anomalies across your software development lifecycle.
- LLM: Statistical forecasting
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=6u8_8QQ5pEQ&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](experiments.md#forecast-deployment-frequency-with-value-stream-forecasting).

## Disable GitLab Duo features for specific groups or projects or an entire instance

Disable GitLab Duo features by [following these instructions](turn_on_off.md).
