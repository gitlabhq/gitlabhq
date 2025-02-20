---
stage: AI-Powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Get started with GitLab Duo Self-Hosted.
title: GitLab Duo Self-Hosted
---

{{< details >}}

- Tier: Ultimate with GitLab Duo Enterprise - [Start a GitLab Duo Enterprise trial on a paid Ultimate subscription](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags.md) named `ai_custom_model`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- Feature flag `ai_custom_model` removed in GitLab 17.8
- Generally available in GitLab 17.9

{{< /history >}}

To maintain full control over your data privacy, security, and the deployment of large language models (LLMs) in your own infrastructure, use GitLab Duo Self-Hosted.

By deploying GitLab Duo Self-Hosted, you can manage the entire lifecycle of requests made to LLM backends for GitLab Duo features, ensuring that all requests stay in your enterprise network, and avoiding external dependencies.

For a click-through demo, see [GitLab Duo Self-Hosted product tour](https://gitlab.navattic.com/gitlab-duo-self-hosted).
<!-- Demo published on 2025-02-13 -->

## Why use GitLab Duo Self-Hosted

With GitLab Duo Self-Hosted, you can:

- Choose any GitLab-approved LLM.
- Retain full control over data by keeping all request/response logs in your domain, ensuring complete privacy and security with no external API calls.
- Isolate the GitLab instance, AI gateway, and models in your own environment.
- Select specific GitLab Duo features tailored to your users.
- Eliminate reliance on the shared GitLab AI gateway.

This setup ensures enterprise-level privacy and flexibility, allowing seamless integration of your LLMs with GitLab Duo features.

### Supported GitLab Duo features

#### Supported Code Suggestions features

For GitLab Duo Code Suggestions, you can use both [code generation and code completion](../../user/project/repository/code_suggestions/_index.md#code-completion-and-generation) with GitLab Duo Self-Hosted.

#### Supported Duo Chat features

You can use the following GitLab Duo Chat features with GitLab Duo Self-Hosted:

- [Ask about GitLab](../../user/gitlab_duo_chat/examples.md#ask-about-gitlab)
- [Ask about a specific issue](../../user/gitlab_duo_chat/examples.md#ask-about-a-specific-issue)
- [Ask about a specific epic](../../user/gitlab_duo_chat/examples.md#ask-about-a-specific-epic)
- [Explain selected code](../../user/gitlab_duo_chat/examples.md#explain-selected-code)
- [Ask about or generate code](../../user/gitlab_duo_chat/examples.md#ask-about-or-generate-code)
- [Ask follow up questions](../../user/gitlab_duo_chat/examples.md#ask-follow-up-questions)
- [Ask about errors](../../user/gitlab_duo_chat/examples.md#ask-about-errors)
- [Ask about specific files](../../user/gitlab_duo_chat/examples.md#ask-about-specific-files)
- [Refactor code in the IDE](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)
- [Fix code in the IDE](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)
- [Write tests in the IDE](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)
- [Ask about CI/CD](../../user/gitlab_duo_chat/examples.md#ask-about-cicd)
- [Use universal and IDE slash commands](../../user/gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands)

### Prerequisites

Before setting up the GitLab Duo Self-Hosted infrastructure, you must have:

- A [supported model](../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) (either cloud-based or on-premises).
- A [supported serving platform](../gitlab_duo_self_hosted/supported_llm_serving_platforms.md) (either cloud-based or on-premises).
- A [locally hosted AI gateway](../../install/install_ai_gateway.md).
- [Ultimate with GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?toggle=gitlab-duo-pro).
- GitLab 17.9 or later.

## Decide on your configuration type

The configuration for GitLab Duo Self-Hosted is different to the default configuration
that uses GitLab external AI vendors.

{{< alert type="note" >}}

Both of the following configuration types are for GitLab Self-Managed instances.

{{< /alert >}}

### Self-hosted AI gateway and LLMs

In a fully self-hosted configuration, you deploy your own AI gateway and LLMs in your infrastructure, without relying on external public services. This gives you full control over your data and security.

If you have an offline environment with physical barriers or security policies that prevent or limit internet access, and comprehensive LLM controls, you can use GitLab Duo Self-Hosted.

For licensing, you must have a GitLab Ultimate subscription and GitLab Duo Enterprise. Offline Enterprise licenses are available for those customers with fully isolated offline environments. To get access to your purchased subscription, request a license through the [Customers Portal](../../subscriptions/customers_portal.md).

For more information, see:

- [Set up a GitLab Duo Self-Hosted infrastructure](#set-up-a-gitlab-duo-self-hosted-infrastructure)
- The [self-hosted AI gateway configuration diagram](configuration_types.md#self-hosted-ai-gateway).

### GitLab.com AI gateway with default GitLab external vendor LLMs

If you do not meet the use case criteria for GitLab Duo Self-Hosted, you can use the
GitLab.com AI gateway with default GitLab external vendor LLMs.

The GitLab.com AI gateway is the default Enterprise offering and is not self-hosted. In this configuration,
you connect your instance to the GitLab-hosted AI gateway, which
integrates with external vendor LLM providers (such as Google Vertex or Anthropic).

These LLMs communicate through the [GitLab Cloud Connector](../../development/cloud_connector/_index.md),
offering a ready-to-use AI solution without the need for on-premise infrastructure.

For licensing, you must have a GitLab Ultimate subscription, and either [GitLab Duo Pro](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial) or [GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial). To get access to your purchased subscription, request a license through the [Customers Portal](../../subscriptions/customers_portal.md)

For more information, see the
[GitLab.com AI gateway configuration diagram](configuration_types.md#gitlabcom-ai-gateway).

To set up this infrastructure, see [how to configure GitLab Duo on a GitLab Self-Managed instance](../../user/gitlab_duo/setup.md).

## Set up a GitLab Duo Self-Hosted infrastructure

To set up a fully isolated GitLab Duo Self-Hosted infrastructure:

1. **Install a Large Language Model (LLM) Serving Infrastructure**

   - We support various platforms for serving and hosting your LLMs, such as vLLM, AWS Bedrock, and Azure OpenAI. To help you choose the most suitable option for effectively deploying your models, see the [supported LLM platforms documentation](../gitlab_duo_self_hosted/supported_llm_serving_platforms.md) for more information on each platform's features.

   - We provide a comprehensive matrix of supported models along with their specific features and hardware requirements. To help select models that best align with your infrastructure needs for optimal performance, see the [supported models and hardware requirements documentation](../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md).

1. **Install the GitLab AI gateway**
   [Install the AI gateway](../../install/install_ai_gateway.md) to efficiently configure your AI infrastructure.

1. **Configure GitLab Duo features**
   See the [Configure GitLab Duo features documentation](../gitlab_duo_self_hosted/configure_duo_features.md) for instructions on how to customize your environment to effectively meet your operational needs.

1. **Enable logging**
   You can find configuration details for enabling logging in your environment. For help in using logs to track and manage your system's performance effectively, see the [logging documentation](../gitlab_duo_self_hosted/logging.md).

## Related topics

- [Troubleshooting](../gitlab_duo_self_hosted/troubleshooting.md)
