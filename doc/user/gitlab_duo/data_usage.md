---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AI-native features and functionality.
title: GitLab Duo data usage
---

GitLab Duo uses generative AI to help increase your velocity and make you more productive. Each AI-native feature operates independently and is not required for other features to function.

GitLab uses the right large language models (LLMs) for specific tasks.
These LLMs are [Anthropic Claude](https://claude.com/product/overview),
[Fireworks AI-hosted Codestral](https://mistral.ai/news/codestral),
[Google Vertex AI models](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/overview),
and [OpenAI models](https://platform.openai.com/docs/models).

## Progressive enhancement

GitLab Duo AI-native features are designed as a progressive enhancement to existing GitLab features across the DevSecOps platform. These features are designed to fail gracefully and should not prevent the core functionality of the underlying feature. You should note each feature is subject to its expected functionality as defined by the relevant [feature support policy](../../policy/development_stages_support.md).

## Stability and performance

GitLab Duo AI-native features are in a variety of [feature support levels](../../policy/development_stages_support.md#beta). Due to the nature of these features, there may be high demand for usage which may cause degraded performance or unexpected downtime of the feature. We have built these features to gracefully degrade and have controls in place to allow us to mitigate abuse or misuse. GitLab may disable beta and experimental features for any or all customers at any time at our discretion.

## Data privacy

GitLab Duo AI-native features are powered by a generative AI model. The processing of any personal data is in accordance with our [Privacy Statement](https://about.gitlab.com/privacy/). You may also visit the [Sub-Processors page](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors) to see the list of Sub-Processors we use to provide these features.

## Data retention

The below reflects the current retention periods of GitLab AI model
[Sub-Processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors):

For GitLab Duo requests, GitLab has a zero-day data retention policy
with Anthropic, Fireworks AI, AWS, and Google.

These vendors discard model input and output data immediately after the output is
provided and do not store input and output data for abuse monitoring. The exception
to this is when Fireworks AI, Anthropic, and VertexAI prompt caching is enabled for
Code Suggestions and GitLab Duo Chat (agentic).

> [!note]
> For OpenAI models, you cannot turn off prompt caching. If you have turned off prompt caching and you use an OpenAI model, GitLab attempts to invalidate the cache by adding the current timestamp to the prompt. Ensure that you use a model that is suitable for your data retention requirements.

All GitLab AI model Sub-Processors are restricted from using model input and
output to train models and are under data protection agreements with GitLab that
prohibit the use of Customer Content for their own purposes, except to perform
their independent legal obligations.

GitLab Duo Chat and GitLab Duo Agent Platform retain chat history and workflow
history, respectively, to help you return quickly to previously discussed topics and for anti-abuse purposes.
You can delete chats in the GitLab Duo Chat interface. GitLab does not otherwise
retain input and output data unless customers provide consent through a GitLab
[support ticket](https://about.gitlab.com/support/portal/).

When groups or instances enable extended logging for GitLab Duo Agent Platform workflows, trace data is retained. This is separate from the zero-day retention policy with AI model providers.

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

## GitLab Model Context Protocol server

The following information applies to [GitLab Model Context Protocol (MCP) server](model_context_protocol/mcp_server.md) usage in GitLab
Self-Managed instances.

GitLab does not transmit, store, retain, or process any data when the GitLab MCP server is used. All
communication occurs directly between the MCP client and the GitLab MCP server in your environment.

Repository data and metadata are not sent to GitLab.

You control which MCP clients connect to your instance. Each client's own privacy and data retention policies apply.

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

GitLab Duo includes [secret detection and redaction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/docs/developer/secret-redaction.md) during flow execution. Depending on the scenario, GitLab Duo automatically
detects and removes sensitive information like API keys, credentials, and tokens from your
code before processing it with large language models.

Your code goes through a pre-scan security workflow when using GitLab Duo:

1. Your code is scanned for sensitive information using Gitleaks.
1. Any detected secrets are automatically removed from the request.

Secret scanning runs in the following scenarios:

- Code completion context transformation (before the context is sent to AI)
- AI context transformation
- Workflow tool results
- Agentic Chat user input
- Git command logging
- CLI config logging

> [!note]
> Secret scanning does not occur when you interact with GitLab Duo Chat through the web interface.

## Share group usage data with GitLab

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587976) in GitLab 18.9.1.

{{< /history >}}

To help improve service quality, you can share usage data about GitLab Duo Agent Platform features with GitLab.

After you turn on data collection, AI interactions from all projects and subgroups in your namespace are logged with GitLab.
This data is used exclusively for service improvement and debugging, and not for training AI models.

You can also turn on usage data collection [for an instance](../../administration/gitlab_duo/configure/gitlab_self_managed.md#share-usage-data-with-gitlab)

Prerequisites:

- Have GitLab 18.9.1 or later.
- Have the Owner role for a top-level group.
- On GitLab.com, your group must [have GitLab Duo enabled](turn_on_off.md#turn-gitlab-duo-on-or-off).

To turn on data collection for your group:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Data collection**, select the **Collect usage data** checkbox.
1. Select **Save changes**.

### Agent Platform usage data

When you turn on data collection, the following data is logged:

- Full prompt and response text from interactions with GitLab Duo.
- Session context, including sessions that were ongoing at the time the setting is enabled.
- Model metadata (model version, token counts, latency).
- Tool calls and their results.
- Session IDs to correlate with user feedback.

The following information is not included in logs, unless users include it in their own prompts:

- User IDs or usernames.
- Email addresses or personal identifiers.
- Project or namespace identifiers.

GitLab does not remove identifiers that users have included in their prompt.
