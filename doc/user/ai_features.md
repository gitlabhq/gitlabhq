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

GitLab Duo is a set of AI-assisted features across the GitLab DevSecOps platform. These features aim to help increase velocity and solve key pain points across the software development lifecycle. GitLab Duo features are accessible through the [IDE extension](../editor_extensions/index.md) and the GitLab UI. Some of the features are also accessible through [GitLab Duo Chat](gitlab_duo_chat.md), which is available in both interfaces.

Some features are still in development. [View features in the Experiment phase](ai_experiments.md).

Learn more about how to [turn GitLab Duo features on and off](ai_features_enable.md).

GitLab is [transparent](https://handbook.gitlab.com/handbook/values/#transparency). As GitLab Duo features mature, the documentation will be updated to clearly state how and where you can access these capabilities.

| Goal | Feature | Tier/Offering/Status |
|---|---|---|
| Helps you write code more efficiently by showing code suggestions as you type.<br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=hCAyCTacdAQ) | [Code Suggestions](project/repository/code_suggestions/index.md) | **Tier:** Premium and Ultimate with [GitLab Duo Pro](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com, Self-managed, GitLab Dedicated <br>**Status:** Generally Available |
| Processes and generates text and code in a conversational manner. Helps you quickly identify useful information in large volumes of text in issues, epics, code, and GitLab documentation. | [Chat](gitlab_duo_chat.md) | **Tier:** Freely available for Premium and Ultimate for a limited time<br>**Offering:** GitLab.com, Self-managed, GitLab Dedicated <br>**Status:** Generally Available |
| Helps you discover or recall Git commands when and where you need them. | [Git suggestions](../editor_extensions/gitlab_cli/index.md#gitlab-duo-commands) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com<br>**Status:** Experiment |
| Assists with quickly getting everyone up to speed on lengthy conversations to help ensure you are all on the same page.  <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=IcdxLfTIUgc) | [Discussion summary](ai_experiments.md#summarize-issue-discussions-with-discussion-summary) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Generates issue descriptions. | [Issue description generation](ai_experiments.md#summarize-an-issue-with-issue-description-generation) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Automates repetitive tasks and helps catch bugs early. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=g6MS1JsRWgs) | [Test generation](gitlab_duo_chat.md#write-tests-in-the-ide) | **Tier:** Freely available for Premium and Ultimate for a limited time<br>In the future, will require Premium or Ultimate with [GitLab Duo Pro](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com, Self-managed, GitLab Dedicated <br>**Status:** Beta |
| Generates a description for the merge request based on the contents of the template. | [Merge request template population](project/merge_requests/ai_in_merge_requests.md#fill-in-merge-request-templates) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com<br>**Status:** Experiment |
| Assists in creating faster and higher-quality reviews by automatically suggesting reviewers for your merge request. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=ivwZQgh4Rxw) | [Suggested Reviewers](project/merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers) | **Tier:** Ultimate <br>**Offering:** GitLab.com<br>**Status:** Generally Available |
| Efficiently communicates the impact of your merge request changes. | [Merge request summary](project/merge_requests/ai_in_merge_requests.md#summarize-merge-request-changes) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com <br>**Status:** Beta |
| Helps ease merge request handoff between authors and reviewers and help reviewers efficiently understand suggestions. | [Code review summary](project/merge_requests/ai_in_merge_requests.md#summarize-my-merge-request-review) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Helps you remediate vulnerabilities more efficiently, boost your skills, and write more secure code. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=6sDf73QOav8) | [Vulnerability explanation](application_security/vulnerabilities/index.md#explaining-a-vulnerability) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md) <br>**Offering:** GitLab.com <br>**Status:** Beta |
| Generates a merge request containing the changes required to mitigate a vulnerability. | [Vulnerability resolution](application_security/vulnerabilities/index.md#vulnerability-resolution) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Helps you understand code by explaining it in English language. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=1izKaLmmaCA) | [Code explanation](ai_experiments.md#explain-code-in-the-web-ui-with-code-explanation) | **Tier:** Freely available for Premium and Ultimate for a limited time<br>In the future, will require Premium or Ultimate with [GitLab Duo Pro](../subscriptions/subscription-add-ons.md) <br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Assists you in determining the root cause for a pipeline failure and failed CI/CD build. | [Root cause analysis](ai_experiments.md#root-cause-analysis) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md)<br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Assists you with predicting productivity metrics and identifying anomalies across your software development lifecycle. | [Value stream forecasting](ai_experiments.md#forecast-deployment-frequency-with-value-stream-forecasting) | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md) <br>**Offering:** GitLab.com, Self-managed, GitLab Dedicated <br>**Status:** Experiment |
| Processes and responds to your questions about your application's usage data. | [Product Analytics](analytics/analytics_dashboards.md#generate-a-custom-visualization-with-gitlab-duo)             | **Tier:** Freely available for Ultimate for a limited time<br>In the future, will require Ultimate with [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md) <br>**Offering:** GitLab.com <br>**Status:** Experiment |

## Disable GitLab Duo features for specific groups or projects or an entire instance

Disable GitLab Duo features by [following these instructions](ai_features_enable.md).

## Language models

| Feature | Large Language Model |
|---|---|
| [Git suggestions](https://gitlab.com/gitlab-org/gitlab/-/issues/409636) | Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat) |
| [Discussion summary](ai_experiments.md#summarize-issue-discussions-with-discussion-summary) |Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison) |
| [Issue description generation](ai_experiments.md#summarize-an-issue-with-issue-description-generation) | Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison) |
| [Code Suggestions](project/repository/code_suggestions/index.md) | For Code Completion: Vertex AI Codey [`code-gecko`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-completion)    For Code Generation: Anthropic [`Claude-3-Sonnet`](https://docs.anthropic.com/claude/docs/models-overview) |
| [Test generation](gitlab_duo_chat.md#write-tests-in-the-ide) | Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison) |
| [Merge request template population](project/merge_requests/ai_in_merge_requests.md#fill-in-merge-request-templates) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Suggested Reviewers](project/merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers) | GitLab creates a machine learning model for each project, which is used to generate reviewers    [View the issue](https://gitlab.com/gitlab-org/modelops/applied-ml/applied-ml-updates/-/issues/10) |
| [Merge request summary](project/merge_requests/ai_in_merge_requests.md#summarize-merge-request-changes) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Code review summary](project/merge_requests/ai_in_merge_requests.md#summarize-my-merge-request-review) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Vulnerability explanation](application_security/vulnerabilities/index.md#explaining-a-vulnerability) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text)    Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison) if degraded performance |
| [Vulnerability resolution](application_security/vulnerabilities/index.md#explaining-a-vulnerability) | Vertex AI Codey [`code-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-generation) |
| [Code explanation](ai_experiments.md#explain-code-in-the-web-ui-with-code-explanation) | Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat) |
| [GitLab Duo Chat](gitlab_duo_chat.md) | Anthropic [`Claude-2.1`](https://docs.anthropic.com/claude/docs/models-overview#model-comparison)    Vertex AI Codey [`textembedding-gecko`](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings) |
| [Root cause analysis](ai_experiments.md#root-cause-analysis) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Value stream forecasting](ai_experiments.md#forecast-deployment-frequency-with-value-stream-forecasting) | Statistical forecasting |
| [Product analytics](analytics/analytics_dashboards.md#generate-a-custom-visualization-with-gitlab-duo) | Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat) |
