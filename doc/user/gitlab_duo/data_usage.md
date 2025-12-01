---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AI-native features and functionality.
title: GitLab Duo data usage
---

GitLab Duo uses generative AI to help increase your velocity and make you more productive. Each AI-native feature operates independently and is not required for other features to function.

GitLab uses the right large language models (LLMs) for specific tasks. These LLMs are [Anthropic Claude](https://www.anthropic.com/product), [Fireworks AI-hosted Codestral](https://mistral.ai/news/codestral-2501), and [Google Vertex AI Models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/overview#genai-models).

## Progressive enhancement

GitLab Duo AI-native features are designed as a progressive enhancement to existing GitLab features across the DevSecOps platform. These features are designed to fail gracefully and should not prevent the core functionality of the underlying feature. You should note each feature is subject to its expected functionality as defined by the relevant [feature support policy](../../policy/development_stages_support.md).

## Stability and performance

GitLab Duo AI-native features are in a variety of [feature support levels](../../policy/development_stages_support.md#beta). Due to the nature of these features, there may be high demand for usage which may cause degraded performance or unexpected downtime of the feature. We have built these features to gracefully degrade and have controls in place to allow us to mitigate abuse or misuse. GitLab may disable beta and experimental features for any or all customers at any time at our discretion.

## Data privacy

GitLab Duo AI-native features are powered by a generative AI model. The processing of any personal data is in accordance with our [Privacy Statement](https://about.gitlab.com/privacy/). You may also visit the [Sub-Processors page](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors) to see the list of Sub-Processors we use to provide these features.

## Data retention

The below reflects the current retention periods of GitLab AI model
[Sub-Processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors):

GitLab has arranged zero-day data retention with Anthropic, Fireworks AI, AWS,
and Google for GitLab Duo requests.

These vendors discard model input and output data immediately after the output is
provided and do not store input and output data for abuse monitoring. The exception
to this is when Fireworks AI, Anthropic, and VertexAI prompt caching is enabled for
Code Suggestions and GitLab Duo Chat (Agentic).

For more information on how to turn off prompt caching, see
[prompt caching](../project/repository/code_suggestions/_index.md#prompt-caching).

{{< alert type="note" >}}

For OpenAI models, you cannot turn off prompt caching. Ensure that you use a model that is suitable for your data retention requirements.

{{< /alert >}}

All GitLab AI model Sub-Processors are restricted from using model input and
output to train models and are under data protection agreements with GitLab that
prohibit the use of Customer Content for their own purposes, except to perform
their independent legal obligations.

GitLab Duo Chat and GitLab Duo Agent Platform retain chat history and workflow
history, respectively, to help you return quickly to previously discussed topics.
You can delete chats in the GitLab Duo Chat interface. GitLab does not otherwise
retain input and output data unless customers provide consent through a GitLab
[support ticket](https://about.gitlab.com/support/portal/).

For more information, see [AI feature logging](../../administration/logs/_index.md).

## Training data

GitLab does not train generative AI models.

For more information on our AI [sub-processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors), see:

- Google Vertex AI models API [data governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance), [responsible AI](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/responsible-ai), [details about foundation model training](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance#foundation_model_training), Google [Secure AI Framework (SAIF)](https://safety.google/cybersecurity-advancements/saif/), and [release notes](https://cloud.google.com/vertex-ai/docs/release-notes).
- Anthropic Claude's [constitution](https://www.anthropic.com/news/claudes-constitution), training data [FAQ](https://support.anthropic.com/en/articles/7996885-how-do-you-use-personal-data-in-model-training), [models overview](https://docs.anthropic.com/en/docs/about-claude/models), and [data recency article](https://support.anthropic.com/en/articles/8114494-how-up-to-date-is-claude-s-training-data).

## Telemetry

GitLab Duo collects aggregated or de-identified first-party usage data through a Snowplow collector. This usage data includes the following metrics:

- Number of unique users
- Number of unique instances
- Prompt and suffix lengths
- Model used
- Status code responses
- API responses times
- Code Suggestions also collects:
  - Language the suggestion was in (for example, Python)
  - Editor being used (for example, VS Code)
  - Number of suggestions shown, accepted, rejected, or that had errors
  - Duration of time that a suggestion was shown

## Model accuracy and quality

Generative AI may produce unexpected results that may be:

- Low-quality
- Incoherent
- Incomplete
- Produce failed pipelines
- Insecure code
- Offensive or insensitive
- Out of date information

GitLab is actively iterating on all our AI-assisted capabilities to improve the quality of the generated content. We improve the quality through prompt engineering, evaluating new AI/ML models to power these features, and through novel heuristics built into these features directly.

## Secret detection and redaction

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/632) in GitLab 17.9.

{{< /history >}}

GitLab Duo includes secret detection and redaction, powered by Gitleaks. It automatically
detects and removes sensitive information like API keys, credentials, and tokens from your
code before processing it with large language models. This security feature is particularly
important for compliance with data protection regulations, like GDPR.

Your code goes through a pre-scan security workflow when using GitLab Duo:

1. Your code is scanned for sensitive information using Gitleaks.
1. Any detected secrets are automatically removed from the request.

## GitLab Duo Self-Hosted

When you are using [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)
and the self-hosted AI gateway, you do not share any data with GitLab.

GitLab Self-Managed administrators can use [Service Ping](../../administration/settings/usage_statistics.md#service-ping)
to send usage statistics to GitLab. This is separate to the [telemetry data](#telemetry).
