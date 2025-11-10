---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Host your own AI gateway and language models.
title: GitLab Duo Self-Hosted
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags/_index.md) named `ai_custom_model`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- Feature flag `ai_custom_model` removed in GitLab 17.8.
- Generally available in GitLab 17.9.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

Use GitLab Duo Self-Hosted to integrate your own large language models (LLMs)
with GitLab Duo features and control your data privacy and security.

With GitLab Duo Self-Hosted, you can:

- Choose any GitLab-supported LLM or your own compatible model.
- Choose specific GitLab Duo features for your users.
- Keep all request/response logs in your domain with no external API calls.
- Isolate the GitLab instance, AI gateway, and models in your own environment.
- Eliminate reliance on the shared GitLab AI gateway.
- Manage the lifecycle of requests to LLM backends for GitLab Duo features,
and avoid external dependencies so that requests stay in your enterprise network.

For a click-through demo, see [GitLab Duo Self-Hosted product tour](https://gitlab.navattic.com/gitlab-duo-self-hosted).
<!-- Demo published on 2025-02-13 -->

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab Duo Self-Hosted: AI in your private environment](https://youtu.be/TQoO3sFnb28?si=uD-ps6aRnE28xNv3).
<!-- Video published on 2025-02-20 -->

## Prerequisites

To use GitLab Duo Self-Hosted you must have:

- A cloud-based or on-premise supported model
- A cloud-based or on-premise supported serving platform
- A locally hosted AI gateway

## Supported GitLab Duo features

The following tables state:

- The GitLab Duo features and whether those features are available on GitLab Duo Self-Hosted.
- Which version of GitLab is needed to use those features on GitLab Duo Self-Hosted.
- The status of those features. A feature's status on GitLab Duo Self-Hosted can be
  different to [that same feature's status when it is hosted on GitLab](../../user/gitlab_duo/feature_summary.md).

{{< alert type="note" >}}

You must have the GitLab Duo Enterprise add-on to use these features with GitLab Duo Self-Hosted.
This applies even if you can use these features with GitLab Duo Core or GitLab Duo Pro
when GitLab hosts and connects to those models through the cloud-based [AI gateway](../../user/gitlab_duo/gateway.md).

{{< /alert >}}

### Code Suggestions

| Feature                                                                      | Available on GitLab Duo Self-Hosted         | GitLab version        | Status  |
| ---------------------------------------------------------------------------- | ------------------------------------------- | --------------------- | --- |
| [Code Suggestions](../../user/project/repository/code_suggestions/_index.md) | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later | Generally available |

### Chat

| Feature                                                                                                           | Available on GitLab Duo Self-Hosted         | GitLab version         | Status  |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [General](../../user/gitlab_duo_chat/_index.md)                                                                   | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Code Explanation](../../user/gitlab_duo_chat/examples.md#explain-selected-code)                                      | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Test Generation](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                       | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Refactor Code](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                  | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Fix Code](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                            | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Root Cause Analysis](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.10 and later | Beta |
| [Vulnerability Explanation](../../user/application_security/vulnerabilities/_index.md#vulnerability-explanation)     | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1.2 and later | Beta |

For more examples of a question you can ask, see
[Ask about GitLab](../../user/gitlab_duo_chat/examples.md).

### GitLab Duo in merge requests

| Feature                                                                                                                                      | Available on GitLab Duo Self-Hosted         | GitLab version         | Status |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [Merge Commit Message Generation](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)                        | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1.2 and later | Beta |
| [Merge Request Summary](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1.2 and later | Beta |
| [Code Review](../../user/project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code)                                   | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.3 and later         | Generally available |
| [Code Review Summary](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)                                    | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1.2 and later | Experiment |

### GitLab Duo in issues

| Feature                                                                                                                          | Available on GitLab Duo Self-Hosted         | GitLab version         | Status |
| -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [Issue Description Generation](../../user/project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< icon name="dash-circle" >}} No  | Not applicable   | Not applicable |
| [Discussion Summary](../../user/discussions/_index.md#summarize-issue-discussions-with-duo-chat)                           | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1.2 and later | Beta |

### Other features

| Feature                                                                                                        | Available on GitLab Duo Self-Hosted         | GitLab version         | Status |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [GitLab Duo for the CLI](https://docs.gitlab.com/cli/)                  | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1.2 and later | Beta |
| [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)                                                       | {{< icon name="check-circle-filled" >}} Yes  | GitLab 18.4 and later | Beta |
| [Vulnerability Resolution](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1.2 and later | Beta |
| [GitLab Duo and SDLC trends Dashboard](../../user/analytics/duo_and_sdlc_trends.md)                                             | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Beta |

## Configuration types

Use one of the following options to implement AI-native features:

- **Self-hosted AI gateway and LLMs**: Use your own AI gateway and models for full control over your AI infrastructure.
- **Hybrid AI gateway and model configuration**: For each feature, use either your self-hosted AI gateway with self-hosted models, or the GitLab.com AI gateway with GitLab AI vendor models.
- **GitLab.com AI gateway with default GitLab external vendor LLMs**: Use GitLab managed AI infrastructure.

| Configuration                     | Self-hosted AI gateway                                                        | Hybrid AI gateway and model configuration | GitLab.com AI gateway                        |
| --------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------- | -------------------------------------------- |
| Infrastructure requirements | Requires hosting your own AI gateway and models                               | Requires hosting your own AI gateway and models | No additional infrastructure needed          |
| Model options               | Choose from [supported self-hosted models](supported_models_and_hardware_requirements.md) | Choose from [supported self-hosted models](supported_models_and_hardware_requirements.md) or GitLab AI vendor models for each GitLab Duo feature | Uses the default GitLab AI vendor models |
| Network requirements        | Can operate in fully isolated networks                                        | Requires internet connectivity for GitLab Duo features that use GitLab AI vendor models | Requires internet connectivity               |
| Responsibilities            | You set up your infrastructure, and do your own maintenance                   | You set up your infrastructure, do your own maintenance, and choose which features use GitLab AI vendor models and AI gateway | GitLab does the set up and maintenance       |

### Self-hosted AI gateway and LLMs

In a fully self-hosted configuration, you deploy your own AI gateway and use only [supported LLMs](supported_models_and_hardware_requirements.md) in your infrastructure, without using GitLab infrastructure or AI vendor models. This gives you full control over your data and security.

{{< alert type="note" >}}

This configuration only includes models configured through your self-hosted AI gateway. If you use [GitLab AI vendor models](configure_duo_features.md#configure-a-feature-to-use-a-gitlab-ai-vendor-model) for any features, those features will connect to the GitLab-hosted AI gateway instead of your self-hosted gateway, making it a hybrid configuration rather than fully self-hosted.

{{< /alert >}}

While you deploy your own AI gateway, you can still use cloud-based LLM services like [AWS Bedrock](https://aws.amazon.com/bedrock/) or [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) as your model backend and they will continue to connect through your self-hosted AI gateway.

If you have an offline environment with physical barriers or security policies that prevent or limit internet access, and comprehensive LLM controls, you should use this fully self-hosted configuration.

For more information, see:

- [Set up a GitLab Duo Self-Hosted infrastructure](#set-up-a-gitlab-duo-self-hosted-infrastructure)
- The [self-hosted AI gateway configuration diagram](configuration_types.md#self-hosted-ai-gateway).

### Hybrid AI gateway and model configuration

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17192) in GitLab 18.3 as a [beta](../../policy/development_stages_support.md#beta) with a [feature flag](../feature_flags/_index.md) named `ai_self_hosted_vendored_features`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

In this hybrid configuration, you deploy your own AI gateway and self-hosted models for most features, but configure specific features to use GitLab AI vendor models. When a feature is configured to use a GitLab AI vendor model, requests for that feature are sent to the GitLab-hosted AI gateway instead of your self-hosted AI gateway.

This option provides flexibility by allowing you to:

- Use your own self-hosted models for features where you want full control.
- Use GitLab-managed vendor models for specific features where you prefer the models GitLab has curated.

{{< alert type="warning" >}}

When features are configured to use GitLab AI vendor models:

- All calls to those features use the GitLab-hosted AI gateway, not the self-hosted AI gateway.
- Internet connectivity is required for these features.
- This is not a fully self-hosted or isolated configuration.

{{< /alert >}}

For licensing, you must have a GitLab Premium or Ultimate subscription, and [GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial). Offline licenses are not supported to use this configuration. To get access to your purchased subscription, request a license through the [Customers Portal](../../subscriptions/billing_account.md).

For more information, see:

- [Configure GitLab AI vendor models](configure_duo_features.md#configure-a-feature-to-use-a-gitlab-ai-vendor-model)

#### GitLab managed models

Use GitLab managed models to connect to AI models without the need to self-host infrastructure. These models are managed entirely by GitLab.

You can select the default GitLab model to use with an AI-native feature. For the default model, GitLab uses the best model based on availability, quality, and reliability. The model used for a feature can change without notice.

When you select a specific GitLab managed model, all requests for that feature use that model exclusively. If the model becomes unavailable, requests to the AI gateway fail and users cannot use that feature until another model is selected.

{{< alert type="note" >}}

When you configure a feature to use GitLab managed models:

- Calls to those features use the GitLab-hosted AI gateway, not the self-hosted AI gateway.
- Internet connectivity is required for these features.
- The configuration is not fully self-hosted or isolated.

{{< /alert >}}

### GitLab.com AI gateway with default GitLab external vendor LLMs

{{< details >}}

- Add-on: GitLab Duo Core, Pro, or Enterprise

{{< /details >}}

If you do not meet the use case criteria for GitLab Duo Self-Hosted, you can use the
GitLab.com AI gateway with default GitLab external vendor LLMs.

The GitLab.com AI gateway is the default Enterprise offering and is not self-hosted. In this configuration,
you connect your instance to the GitLab-hosted AI gateway, which
integrates with external vendor LLM providers, including:

- [Anthropic](https://www.anthropic.com/)
- [Fireworks AI](https://fireworks.ai/)
- [Google Vertex](https://cloud.google.com/vertex-ai/)

These LLMs communicate through the GitLab Cloud Connector,
offering a ready-to-use AI solution without the need for on-premise infrastructure.

For more information, see the [GitLab.com AI gateway configuration diagram](configuration_types.md#gitlabcom-ai-gateway).

To set up this infrastructure, see [how to configure GitLab Duo on a GitLab Self-Managed instance](../../user/gitlab_duo/setup.md).

## Set up a GitLab Duo Self-Hosted infrastructure

To set up a fully isolated GitLab Duo Self-Hosted infrastructure:

1. Install a Large Language Model (LLM) serving infrastructure.

   - GitLab supports various platforms for serving and hosting your LLMs, such as vLLM, AWS Bedrock,
   and Azure OpenAI. For more information about each platform, see [supported LLM platforms documentation](supported_llm_serving_platforms.md).

   - GitLab provides a matrix of supported models with their specific features and hardware requirements. For more information,
   see the [supported models and hardware requirements documentation](supported_models_and_hardware_requirements.md).

1. [Install the AI gateway](../../install/install_ai_gateway.md) to access AI-native GitLab Duo features.

1. [Configure your GitLab instance](configure_duo_features.md) for features to access self-hosted models.

1. [Enable logging](logging.md) to track and manage your system's performance.

## Related topics

- [Troubleshooting](troubleshooting.md)
- [Install the GitLab AI gateway](../../install/install_ai_gateway.md)
- [Supported models](supported_models_and_hardware_requirements.md)
- [GitLab Duo Self-Hosted supported platforms](supported_llm_serving_platforms.md)
