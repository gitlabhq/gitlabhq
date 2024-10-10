---
stage: AI-Powered
group: Custom Models
description: Set up your self-hosted model infrastructure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Set up your self-hosted model infrastructure

DETAILS:
**Tier:** For a limited time, Ultimate. On October 17, 2024, Ultimate with [GitLab Duo Enterprise](https://about.gitlab.com/gitlab-duo/#pricing).
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

By self-hosting the model, AI Gateway, and GitLab instance, there are no calls to
external architecture, ensuring maximum levels of security.

To set up your self-hosted model infrastructure:

1. Install the large language model (LLM) serving infrastructure.
1. Configure your GitLab instance.
1. Install the GitLab AI Gateway.

## Install large language model serving infrastructure

Install one of the following GitLab-approved LLM models:

<!-- vale gitlab_base.Spelling = NO -->

| Model family | Model                                                                              | Code completion | Code generation | GitLab Duo Chat |
|--------------|------------------------------------------------------------------------------------|-----------------|-----------------|---------|
| Mistral      | [Codestral 22B](https://huggingface.co/mistralai/Codestral-22B-v0.1) (see [setup instructions](litellm_proxy_setup.md#example-setup-for-codestral-with-ollama))                                         | **{check-circle}** Yes               | **{check-circle}** Yes               | **{dotted-circle}** No        |
| Mistral      | [Mistral 7B](https://huggingface.co/mistralai/Mistral-7B-v0.1)                     | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mixtral 8x22B](https://huggingface.co/mistral-community/Mixtral-8x22B-v0.1)       | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mixtral 8x7B](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1)        | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mistral 7B Text](https://huggingface.co/mistralai/Mistral-7B-v0.3)                     | **{check-circle}** Yes                | **{dotted-circle}** No               |**{dotted-circle}** No        |
| Mistral      | [Mixtral 8x22B Text](https://huggingface.co/mistralai/Mixtral-8x22B-v0.1)       | **{check-circle}** Yes                | **{dotted-circle}** No               | **{dotted-circle}** No        |
| Mistral      | [Mixtral 8x7B Text](https://huggingface.co/mistralai/Mixtral-8x7B-v0.1)        | **{check-circle}** Yes                | **{dotted-circle}** No               | **{dotted-circle}** No        |
| Claude 3     | [Claude 3.5 Sonnet](https://www.anthropic.com/news/claude-3-5-sonnet)        | **{check-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |

The following models are under evaluation, and support is limited:

| Model family  | Model                                                                              | Code completion | Code generation | GitLab Duo Chat |
|---------------|---------------------------------------------------------------------|-----------------|-----------------|---------|
| CodeGemma     | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b)                         | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| CodeGemma     | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) (Instruction)     | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| CodeGemma     | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) (Code)             | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| CodeLlama     | [Code-Llama 13b-code](https://huggingface.co/meta-llama/CodeLlama-13b-hf)          | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| CodeLlama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf)      | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| DeepSeekCoder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| DeepSeekCoder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base)        | **{check-circle}** Yes                | **{dotted-circle}** No               | **{dotted-circle}** No        |

<!-- vale gitlab_base.Spelling = YES -->

### Use a serving architecture

To host your models, you should use:

- For non-cloud on-premise deployments, [vLLM](https://docs.vllm.ai/en/stable/).
- For cloud deployments, AWS Bedrock as a cloud provider.

## Configure your GitLab instance

Prerequisites:

- Upgrade to the latest version of GitLab.

1. The GitLab instance must be able to access the AI Gateway.

   1. Where your GitLab instance is installed, update the `/etc/gitlab/gitlab.rb` file.

      ```shell
      sudo vim /etc/gitlab/gitlab.rb
      ```

   1. Add and save the following environment variables.

      ```.rb
      gitlab_rails['env'] = {
      'GITLAB_LICENSE_MODE' => 'production',
      'CUSTOMER_PORTAL_URL' => 'https://customers.gitlab.com',
      'AI_GATEWAY_URL' => '<path_to_your_ai_gateway>:<port>'
      }
      ```

   1. Run reconfigure:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

## GitLab AI Gateway

[Install the GitLab AI Gateway](../../install/install_ai_gateway.md).

## Enable logging

Prerequisites:

- You must be an administrator for your self-managed instance.

To enable logging and access the logs, enable the feature flag:

```ruby
Feature.enable(:expanded_ai_logging)
```

Disabling the feature flag stops logs from being written.

### Logs in your GitLab installation

In your instance log directory, a file called `llm.log` is populated.

For more information on:

- Logged events and their properties, see the [logged event documentation](../../development/ai_features/logged_events.md).
- How to rotate, manage, export and visualize the logs in `llm.log`, see the [log system documentation](../logs/index.md).

### Logs in your AI Gateway container

To specify the location of logs generated by AI Gateway, run:

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -v <your_file_path>:"aigateway.log"
 <image>
```

If you do not specify a file name, logs are streamed to the output.

Additionally, the outputs of the AI Gateway execution can also be useful for debugging issues. To access them:

- When using Docker:

  ```shell
  docker logs <container-id>
  ```

- When using Kubernetes:

  ```shell
  kubectl logs <container-name>
  ```

To ingest these logs into the logging solution, see your logging provider documentation.

### Logs in your inference service provider

GitLab does not manage logs generated by your inference service provider. Please refer to the documentation of your inference service
provider on how to use their logs.

### Cross-referencing logs between AI Gateway and GitLab

The property `correlation_id` is assigned to every request and is carried across different components that respond to a
request. For more information, see the [documentation on finding logs with a correlation ID](../logs/tracing_correlation_id.md).

Correlation ID is not available in your model provider logs.

## Troubleshooting

First, run the [debugging scripts](troubleshooting.md#use-debugging-scripts) to
verify your self-hosted model setup.

For more information on other actions to take, see the
[troubleshooting documentation](troubleshooting.md).
