---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo data usage

GitLab Duo uses generative AI to help increase your velocity and make you more productive. Each AI-powered feature operates independently and is not required for other features to function.

GitLab uses best-in-class large language models (LLMs) for specific tasks. These LLMs are
[Google Vertex AI Models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/overview#genai-models)
and [Anthropic Claude](https://www.anthropic.com/product).

## Progressive enhancement

GitLab Duo AI-powered features are designed as a progressive enhancement to existing GitLab features across the DevSecOps platform. These features are designed to fail gracefully and should not prevent the core functionality of the underlying feature. You should note each feature is subject to its expected functionality as defined by the relevant [feature support policy](../../policy/experiment-beta-support.md).

## Stability and performance

GitLab Duo AI-powered features are in a variety of [feature support levels](../../policy/experiment-beta-support.md#beta). Due to the nature of these features, there may be high demand for usage which may cause degraded performance or unexpected downtime of the feature. We have built these features to gracefully degrade and have controls in place to allow us to mitigate abuse or misuse. GitLab may disable beta and experimental features for any or all customers at any time at our discretion.

## Data privacy

GitLab Duo AI-powered features are powered by a generative AI model. The processing of any personal data is in accordance with our [Privacy Statement](https://about.gitlab.com/privacy/). You may also visit the [Sub-Processors page](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors) to see the list of Sub-Processors we use to provide these features.

## Data retention

The below reflects the current retention periods of GitLab AI model [Sub-Processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors):

- Anthropic discards model input and output data immediately after the output is provided. Anthropic currently does not store data for abuse monitoring. Model input and output is not used to train models. GitLab has arranged [zero data retention](https://support.anthropic.com/en/articles/8956058-i-have-a-zero-retention-agreement-with-anthropic-what-products-does-it-apply-to) with Anthropic for GitLab Duo requests.
- [Google discards model input and output data](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance#prediction) immediately after the output is provided. Google currently does not store data for abuse monitoring. Model input and output is not used to train models. Additionally, GitLab [has disabled caching](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/multimodal-faqs#caching) for GitLab Duo requests. 

All of these AI providers are under data protection agreements with GitLab that prohibit the use of Customer Content for their own purposes, except to perform their independent legal obligations.

GitLab retains input and output for up to 30 days for the purpose of troubleshooting, debugging, and addressing latency issues.

## Training data

GitLab does not train generative AI models based on private (non-public) data. The vendors we work with also do not train models based on private data.

For more information on our AI [sub-processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors), see:

- Google Vertex AI models API [data governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance), [responsible AI](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/responsible-ai), [details about foundation model training](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance#foundation_model_training), Google [Secure AI Framework (SAIF)](https://safety.google/cybersecurity-advancements/saif/), and [release notes](https://cloud.google.com/vertex-ai/docs/release-notes).
- Anthropic Claude's [constitution](https://www.anthropic.com/news/claudes-constitution), training data [FAQ](https://support.anthropic.com/en/articles/7996885-how-do-you-use-personal-data-in-model-training), [models overview](https://docs.anthropic.com/claude/docs/models-overview), and [data recency article](https://support.anthropic.com/en/articles/8114494-how-up-to-date-is-claude-s-training-data).

## Telemetry

GitLab Duo collects aggregated or de-identified first-party usage data through a [Snowplow collector](https://handbook.gitlab.com/handbook/business-technology/data-team/platform/snowplow/). This usage data includes the following metrics:

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
