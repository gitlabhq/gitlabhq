---
stage: AI-Powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Supported LLM Serving Platforms.
title: GitLab Duo Self-Hosted supported platforms
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

There are multiple platforms available to host your self-hosted Large Language Models (LLMs). Each platform has unique features and benefits that can cater to different needs. The following documentation summarises the currently supported options:

## For self-hosted model deployments

### vLLM

[vLLM](https://docs.vllm.ai/en/latest/index.html) is a high-performance inference server optimized for serving LLMs with memory efficiency. It supports model parallelism and integrates easily with existing workflows.

To install vLLM, see the [vLLM Installation Guide](https://docs.vllm.ai/en/latest/getting_started/installation.html). You should install [version v0.6.4.post1](https://github.com/vllm-project/vllm/releases/tag/v0.6.4.post1) or later.

#### Endpoint Configuration

When configuring the endpoint URL for any OpenAI API compatible platforms (such as vLLM) in GitLab:

- The URL must be suffixed with `/v1`
- If using the default vLLM configuration, the endpoint URL would be `https://<hostname>:8000/v1`
- If your server is configured behind a proxy or load balancer, you might not need to specify the port, in which case the URL would be `https://<hostname>/v1`

#### Finding the model name

After the model has been deployed, you can obtain the model name for the model identifier field in GitLab by querying the vLLM server's `/v1/models` endpoint:

```shell
curl \
  --header "Authorization: Bearer API_KEY" \
  --header "Content-Type: application/json" \
  http://your-vllm-server:8000/v1/models
```

The model name is the value of the `data.id` field in the response.

Example response:

```json
{
  "object": "list",
  "data": [
    {
      "id": "Mixtral-8x22B-Instruct-v0.1",
      "object": "model",
      "created": 1739421415,
      "owned_by": "vllm",
      "root": "mistralai/Mixtral-8x22B-Instruct-v0.1",
      // Additional fields removed for readability
    }
  ]
}
```

In this example, if the model's `id` is `Mixtral-8x22B-Instruct-v0.1`, you would set the model identifier in GitLab as `custom_openai/Mixtral-8x22B-Instruct-v0.1`.

For more information on:

- vLLM supported models, see the [vLLM Supported Models documentation](https://docs.vllm.ai/en/latest/models/supported_models.html).
- Available options when using vLLM to run a model, see the [vLLM documentation on engine arguments](https://docs.vllm.ai/en/stable/usage/engine_args.html).
- The hardware needed for the models, see the [Supported models and Hardware requirements documentation](supported_models_and_hardware_requirements.md).

Examples:

#### Mistral-7B-Instruct-v0.2

1. Download the model from HuggingFace:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mistral-7B-Instruct-v0.3
   ```

1. Run the server:

   ```shell
   vllm serve <path-to-model>/Mistral-7B-Instruct-v0.3 \
      --served_model_name <choose-a-name-for-the-model>  \
      --tokenizer_mode mistral \
      --tensor_parallel_size <number-of-gpus> \
      --load_format mistral \
      --config_format mistral \
      --tokenizer <path-to-model>/Mistral-7B-Instruct-v0.3
   ```

#### Mixtral-8x7B-Instruct-v0.1

1. Download the model from HuggingFace:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1
   ```

1. Rename the token config:

   ```shell
   cd <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   cp tokenizer.model tokenizer.model.v3
   ```

1. Run the model:

   ```shell
   vllm serve <path-to-model>/Mixtral-8x7B-Instruct-v0.1 \
     --tensor_parallel_size 4 \
     --served_model_name <choose-a-name-for-the-model> \
     --tokenizer_mode mistral \
     --load_format safetensors \
     --tokenizer <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   ```

#### Disable request logging to reduce latency

When running vLLM in production, you can significantly reduce latency by using the `--disable-log-requests` flag to disable request logging.

{{< alert type="note" >}}

Use this flag only when you do not need detailed request logging.

{{< /alert >}}

Disabling request logging minimizes the overhead introduced by verbose logs, especially under high load, and can help improve performance levels.

```shell
vllm serve <path-to-model>/<model-version> \
--served_model_name <choose-a-name-for-the-model>  \
--disable-log-requests
```

This change has been observed to notably improve response times in internal benchmarks.

## For cloud-hosted model deployments

1. [AWS Bedrock](https://aws.amazon.com/bedrock/).
   A fully managed service that allows developers to build and scale generative AI applications using pre-trained models from leading AI companies. It seamlessly integrates with other AWS services and offers a pay-as-you-go pricing model.

   You must configure the GitLab instance with your appropriate AWS IAM permissions before accessing Bedrock models. You cannot do this in the GitLab Duo Self-Hosted UI. For example, you can authenticate the AI Gateway instance by defining the [`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_REGION_NAME`](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) when starting the Docker image. For more information, see the [AWS Identity and Access Management (IAM) Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html).

   - [Supported foundation models in Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)

1. [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/).
   Provides access to OpenAI's powerful models, enabling developers to integrate advanced AI capabilities into their applications with robust security and scalable infrastructure.
   - [Working with Azure OpenAI models](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/working-with-models?tabs=powershell)
   - [Azure OpenAI Service models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure%2Cglobal-standard%2Cstandard-chat-completions)

## Use multiple models and platforms

With GitLab Duo Self-Hosted, you can use multiple models and platforms in the same GitLab instance.

For example, you can configure one feature to use Azure OpenAI, and another feature to use AWS Bedrock or self-hosted models served with vLLM.

This setup gives you flexibility to choose the best model and platform for each use case. Models must be supported and served through a compatible platform.

For more information on setting up different providers, see:

- [Configure GitLab Duo Self-Hosted features](configure_duo_features.md)
- [Supported GitLab Duo Self-Hosted models and hardware requirements](supported_models_and_hardware_requirements.md)
