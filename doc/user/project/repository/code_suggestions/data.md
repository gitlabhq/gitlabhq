---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions data usage

DETAILS:
**Tier:** Premium or Ultimate with GitLab Duo Pro
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code Suggestions is powered by a generative AI model.

Your personal access token enables a secure API connection to GitLab.com or to your GitLab instance.
This API connection securely transmits a context window from your IDE/editor to the [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), a GitLab hosted service. The [gateway](../../../../development/ai_architecture.md) calls the large language model APIs, and then the generated suggestion is transmitted back to your IDE/editor.

GitLab selects the best-in-class large-language models for specific tasks. We use [Google Vertex AI Code Models](https://cloud.google.com/vertex-ai/generative-ai/docs/code/code-models-overview) and [Anthropic Claude](https://www.anthropic.com/product) for Code Suggestions.

[View data retention policies](../../../ai_features.md#data-retention).

## Telemetry

For self-managed instances that have enabled Code Suggestions and for SaaS accounts, we collect aggregated or de-identified first-party usage data through our [Snowplow collector](https://handbook.gitlab.com/handbook/business-technology/data-team/platform/snowplow/). This usage data includes the following metrics:

- Language the code suggestion was in (for example, Python)
- Editor being used (for example, VS Code)
- Number of suggestions shown, accepted, rejected, or that had errors
- Duration of time that a suggestion was shown
- Prompt and suffix lengths
- Model used
- Number of unique users
- Number of unique instances

## Inference window context

Code Suggestions inferences against the currently opened file, the content before and after the cursor, the filename, and the extension type. For more information on possible future context expansion to improve the quality of suggestions, see [epic 11669](https://gitlab.com/groups/gitlab-org/-/epics/11669).

## Training data

GitLab does not train generative AI models based on private (non-public) data. The vendors we work with also do not train models based on private data.

For more information on GitLab Code Suggestions data [sub-processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors), see:

- Google Vertex AI Codey APIs [data governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance) and [responsible AI](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/responsible-ai).
- Anthropic Claude's [constitution](https://www.anthropic.com/news/claudes-constitution).
