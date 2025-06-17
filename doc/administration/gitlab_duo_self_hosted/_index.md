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

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags.md) named `ai_custom_model`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- Feature flag `ai_custom_model` removed in GitLab 17.8.
- Generally available in GitLab 17.9.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

To maintain full control over your data privacy, security, and the deployment of large language models (LLMs) in your own infrastructure, use GitLab Duo Self-Hosted.

By deploying GitLab Duo Self-Hosted, you can manage the entire lifecycle of requests made to LLM backends for GitLab Duo features, ensuring that all requests stay in your enterprise network, and avoiding external dependencies.

For a click-through demo, see [GitLab Duo Self-Hosted product tour](https://gitlab.navattic.com/gitlab-duo-self-hosted).
<!-- Demo published on 2025-02-13 -->

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab Duo Self-Hosted: AI in your private environment](https://youtu.be/TQoO3sFnb28?si=uD-ps6aRnE28xNv3).
<!-- Video published on 2025-02-20 -->

## Why use GitLab Duo Self-Hosted

With GitLab Duo Self-Hosted, you can:

- Choose any GitLab-supported LLM.
- Retain full control over data by keeping all request/response logs in your domain, ensuring complete privacy and security with no external API calls.
- Isolate the GitLab instance, AI gateway, and models in your own environment.
- Select specific GitLab Duo features tailored to your users.
- Eliminate reliance on the shared GitLab AI gateway.

This setup ensures enterprise-level privacy and flexibility, allowing seamless integration of your LLMs with GitLab Duo features.

### Supported GitLab Duo features

The following tables state:

- The GitLab Duo features and whether those features are available on GitLab Duo Self-Hosted.
- Which version of GitLab is needed to use those features on GitLab Duo Self-Hosted.
- The status of those features. A feature's status on GitLab Duo Self-Hosted can be
  different to [that same feature's status when it is hosted on GitLab](../../user/gitlab_duo/feature_summary.md).

{{< alert type="note" >}}

To use these features with GitLab Duo Self-Hosted, you must have the Duo Enterprise add-on. This applies regardless
of whether you can use these features with Duo Core or Duo Pro when
[GitLab hosts the models and connects to those models through the cloud-based AI gateway](../../user/gitlab_duo/gateway.md).

{{< /alert >}}

#### Code Suggestions

| Feature                                                                      | Available on GitLab Duo Self-Hosted         | GitLab version        | Status  |
| ---------------------------------------------------------------------------- | ------------------------------------------- | --------------------- | --- |
| [Code Suggestions](../../user/project/repository/code_suggestions/_index.md) | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later | Generally available |

#### Chat

| Feature                                                                                                           | Available on GitLab Duo Self-Hosted         | GitLab version         | Status  |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [General](../../user/gitlab_duo_chat/_index.md)                                                                   | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Explain Code](../../user/gitlab_duo_chat/examples.md#explain-selected-code)                                      | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Write Test](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                       | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Refactor Code](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                  | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Fix Code](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                            | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Generally available |
| [Troubleshoot Job](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.10 and later | Beta |
| [Explain Vulnerability](../../user/application_security/vulnerabilities/_index.md#explaining-a-vulnerability)     | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1 and later | Beta |

For more examples of a question you can ask, see
[Ask about GitLab](../../user/gitlab_duo_chat/examples.md).

#### GitLab Duo in merge requests

| Feature                                                                                                                                      | Available on GitLab Duo Self-Hosted         | GitLab version         | Status |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [Generate Commit Message](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)                        | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1 and later | Beta |
| [Summarize New Merge Request](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1 and later | Beta |
| [Code Review](../../user/project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code)                                   | {{< icon name="dash-circle" >}} No | Not applicable         | Not applicable |
| [Code Review Summary](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)                                    | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1 and later | Experiment |

#### GitLab Duo in issues

| Feature                                                                                                                          | Available on GitLab Duo Self-Hosted         | GitLab version         | Status |
| -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [Issue Description Generation](../../user/project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< icon name="dash-circle" >}} No  | Not applicable   | Not applicable |
| [Issue Discussion Summary](../../user/discussions/_index.md#summarize-issue-discussions-with-duo-chat)                           | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1 and later | Beta |

#### Other features

| Feature                                                                                                        | Available on GitLab Duo Self-Hosted         | GitLab version         | Status |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [GitLab Duo for the CLI](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli)                  | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1 and later | Beta |
| [GitLab Duo Workflow](../../user/duo_workflow/_index.md)                                                       | {{< icon name="dash-circle" >}} No  | GitLab 17.4 and later  | Not applicable |
| [Vulnerability Resolution](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) | {{< icon name="check-circle-filled" >}} Yes | GitLab 18.1 and later | Beta |
| [AI Impact Dashboard](../../user/analytics/ai_impact_analytics.md)                                             | {{< icon name="check-circle-filled" >}} Yes | GitLab 17.9 and later  | Beta |

### Prerequisites

Before setting up the GitLab Duo Self-Hosted infrastructure, you must have:

- A [supported model](supported_models_and_hardware_requirements.md) (either cloud-based or on-premises).
- A [supported serving platform](supported_llm_serving_platforms.md) (either cloud-based or on-premises).
- A [locally hosted AI gateway](../../install/install_ai_gateway.md).
- [Premium or Ultimate with GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?toggle=gitlab-duo-pro).
- GitLab 17.9 or later.

## Decide on your configuration type

GitLab Self-Managed customers can implement AI-native features using either of the following options:

- [**Self-hosted AI gateway and LLMs**](#self-hosted-ai-gateway-and-llms): Full control over your AI infrastructure.
- [**GitLab.com AI gateway with default GitLab external vendor LLMs**](#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms): Use GitLab managed AI infrastructure.

The differences between these options are:

| Feature                     | Self-hosted AI gateway                                                        | GitLab.com AI gateway                        |
| --------------------------- | ----------------------------------------------------------------------------- | -------------------------------------------- |
| Infrastructure requirements | Requires hosting your own AI gateway and models                               | No additional infrastructure needed          |
| Model options               | Choose from [supported models](supported_models_and_hardware_requirements.md) | Uses the default GitLab external vendor LLMs |
| Network requirements        | Can operate in fully isolated networks                                        | Requires internet connectivity               |
| Responsibilities            | You set up your infrastructure, and do your own maintenance                   | GitLab does the set up and maintenance       |

### Self-hosted AI gateway and LLMs

In a fully self-hosted configuration, you deploy your own AI gateway and use any [supported LLMs](supported_models_and_hardware_requirements.md) in your infrastructure, without relying on external public services. This gives you full control over your data and security.

While this configuration is fully self-hosted and you can use models like Mistral that are hosted on your own infrastructure, you can still use cloud-based LLM services like [AWS Bedrock](https://aws.amazon.com/bedrock/) or [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) as your model backend.

If you have an offline environment with physical barriers or security policies that prevent or limit internet access, and comprehensive LLM controls, you can use GitLab Duo Self-Hosted.

For licensing, you must have a GitLab Premium or Ultimate subscription, and [GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial). Offline Enterprise licenses are available for those customers with fully isolated offline environments. To get access to your purchased subscription, request a license through the [Customers Portal](../../subscriptions/customers_portal.md).

For more information, see:

- [Set up a GitLab Duo Self-Hosted infrastructure](#set-up-a-gitlab-duo-self-hosted-infrastructure)
- The [self-hosted AI gateway configuration diagram](configuration_types.md#self-hosted-ai-gateway).

### GitLab.com AI gateway with default GitLab external vendor LLMs

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

For licensing, you must have a GitLab Premium or Ultimate subscription, and [GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial). To get access to your purchased subscription, request a license through the [Customers Portal](../../subscriptions/customers_portal.md)

For more information, see the
[GitLab.com AI gateway configuration diagram](configuration_types.md#gitlabcom-ai-gateway).

To set up this infrastructure, see [how to configure GitLab Duo on a GitLab Self-Managed instance](../../user/gitlab_duo/setup.md).

## Set up a GitLab Duo Self-Hosted infrastructure

To set up a fully isolated GitLab Duo Self-Hosted infrastructure:

1. **Install a Large Language Model (LLM) Serving Infrastructure**

   - We support various platforms for serving and hosting your LLMs, such as vLLM, AWS Bedrock, and Azure OpenAI. To help you choose the most suitable option for effectively deploying your models, see the [supported LLM platforms documentation](supported_llm_serving_platforms.md) for more information on each platform's features.

   - We provide a comprehensive matrix of supported models along with their specific features and hardware requirements. To help select models that best align with your infrastructure needs for optimal performance, see the [supported models and hardware requirements documentation](supported_models_and_hardware_requirements.md).

1. **Install the GitLab AI gateway**
   [Install the AI gateway](../../install/install_ai_gateway.md) to efficiently configure your AI infrastructure.

1. **Configure GitLab Duo features**
   See the [Configure GitLab Duo features documentation](configure_duo_features.md) for instructions on how to customize your environment to effectively meet your operational needs.

1. **Enable logging**
   You can find configuration details for enabling logging in your environment. For help in using logs to track and manage your system's performance effectively, see the [logging documentation](logging.md).

## Related topics

- [Troubleshooting](troubleshooting.md)
