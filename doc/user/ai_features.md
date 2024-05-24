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

GitLab Duo features are available in [IDE extensions](../editor_extensions/index.md) and the GitLab UI.
Some features are also available as part of [GitLab Duo Chat](gitlab_duo_chat_examples.md).

GitLab is [transparent](https://handbook.gitlab.com/handbook/values/#transparency).
As GitLab Duo features mature, the documentation will be updated to clearly state
how and where you can access these features.

## Generally available features

### Code Suggestions

DETAILS:
**Tier:** Premium and Ultimate with [GitLab Duo Pro](../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Helps you write code more efficiently by showing code suggestions as you type.
- Large language model (LLM) for code completion: Vertex AI Codey [`code-gecko`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-completion)
- LLM for code generation: Anthropic [`claude-3-sonnet-20240229`](https://docs.anthropic.com/claude/docs/models-overview)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://youtu.be/ds7SG1wgcVM)
- [View documentation](project/repository/code_suggestions/index.md).

### GitLab Duo Chat

DETAILS:
**Tier:** Freely available for Premium and Ultimate for a limited time for GitLab.com and self-managed. In the future, will require [GitLab Duo Pro or Enterprise](../subscriptions/subscription-add-ons.md). For GitLab Dedicated, you must have GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Processes and generates text and code in a conversational manner.
  Help you write and understand code faster, get up to speed on the status of projects,
  and quickly learn about GitLab.
- LLM: Anthropic [`claude-3-sonnet-20240229`](https://docs.anthropic.com/en/docs/models-overview#claude-3-a-new-generation-of-ai),
  Anthropic [`claude-3-haiku-20240307`](https://docs.anthropic.com/en/docs/models-overview#claude-3-a-new-generation-of-ai),
  [`claude-2.1`](https://docs.anthropic.com/en/docs/legacy-model-guide#anthropics-legacy-models),
  and [Vertex AI Search](https://cloud.google.com/enterprise-search).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=ZQBAuf-CTAY&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](gitlab_duo_chat.md).

NOTE:
The LLM for GitLab Duo Chat depends on the question asked. For more information, see
the [Duo Chat examples](gitlab_duo_chat_examples.md).
For self-managed, the models also depend on your GitLab version.
For the most benefit, use the latest GitLab version whenever possible.

### Suggested Reviewers

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

- Assists in creating faster and higher-quality reviews by automatically suggesting reviewers for your merge request.
- LLM: GitLab creates a machine learning model for each project, which is used to generate reviewers. [View the issue](https://gitlab.com/gitlab-org/modelops/applied-ml/applied-ml-updates/-/issues/10).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=ivwZQgh4Rxw)
- [View documentation](project/merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers).

### Test generation

DETAILS:
**Tier:** Freely available for Premium and Ultimate for a limited time for GitLab.com and self-managed. In the future, will require [GitLab Duo Pro or Enterprise](../subscriptions/subscription-add-ons.md). For GitLab Dedicated, you must have GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Automates repetitive tasks and helps catch bugs early.
- LLM: Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=zWhwuixUkYU&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](gitlab_duo_chat_examples.md#write-tests-in-the-ide).

## Beta features

### Merge request summary

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Efficiently communicates the impact of your merge request changes.
- LLM: Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text)
- [View documentation](project/merge_requests/ai_in_merge_requests.md#generate-a-description-by-summarizing-code-changes).

### Merge request template population

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Generates a description for the merge request based on the contents of the template.
- LLM: Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text)
- [View documentation](project/merge_requests/ai_in_merge_requests.md#generate-a-description-from-a-template).

### Vulnerability explanation

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Helps you remediate vulnerabilities more efficiently, boost your skills, and write more secure code.
- LLM: Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text). If degraded performance, then Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://youtu.be/ctD_qcVpIJY)
- [View documentation](application_security/vulnerabilities/index.md#explaining-a-vulnerability).

## Experimental features

### Git suggestions

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Helps you discover or recall Git commands when and where you need them.
- LLM: Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat)
- [View documentation](../editor_extensions/gitlab_cli/index.md#git-suggestions).

### Discussion summary

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Assists with quickly getting everyone up to speed on lengthy conversations to help ensure you are all on the same page.
- LLM: Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=IcdxLfTIUgc)
- [View documentation](ai_experiments.md#summarize-issue-discussions-with-discussion-summary).

### Issue description generation

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Generates issue descriptions.
- LLM: Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison)
- [View documentation](ai_experiments.md#summarize-an-issue-with-issue-description-generation).

### Code review summary

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Helps ease merge request handoff between authors and reviewers and help reviewers efficiently understand suggestions.
- LLM: Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=Bx6Zajyuy9k&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](project/merge_requests/ai_in_merge_requests.md#summarize-a-code-review).

### Vulnerability resolution

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Generates a merge request containing the changes required to mitigate a vulnerability.
- LLM: Vertex AI Codey [`code-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-generation)
- [View documentation](application_security/vulnerabilities/index.md#vulnerability-resolution).

### Code explanation

DETAILS:
**Tier:** Freely available for Premium and Ultimate for a limited time. In the future, will require [GitLab Duo Pro or Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Helps you understand code by explaining it in English language.
- LLM: Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=1izKaLmmaCA)
- [View documentation](ai_experiments.md#explain-code-in-the-web-ui-with-code-explanation).

### Root cause analysis

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Assists you in determining the root cause for a CI/CD job failure by analyzing the logs.
- LLM: Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text)
- [View documentation](ai_experiments.md#root-cause-analysis).

### Value stream forecasting

DETAILS:
**Tier:** Freely available for Ultimate for a limited time for GitLab.com and self-managed. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md). For GitLab Dedicated, you must have GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

- Assists you with predicting productivity metrics and identifying anomalies across your software development lifecycle.
- LLM: Statistical forecasting
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=6u8_8QQ5pEQ&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
- [View documentation](ai_experiments.md#forecast-deployment-frequency-with-value-stream-forecasting).

### Product Analytics

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Processes and responds to your questions about your application's usage data.
- LLM: Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat)
- [View documentation](analytics/analytics_dashboards.md#generate-a-custom-visualization-with-gitlab-duo).

### Merge and squash commit generation

DETAILS:
**Tier:** Freely available for Ultimate for a limited time. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md).
**Offering:** GitLab.com

- Helps users generate meaningful commit messages for merge and squash commits.
- LLM: Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text).
- [View documentation](project/merge_requests/ai_in_merge_requests.md#generate-a-merge-or-squash-commit-message).

## Disable GitLab Duo features for specific groups or projects or an entire instance

Disable GitLab Duo features by [following these instructions](ai_features_enable.md).
