---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Supported LLM Serving Platforms.
title: Supported platforms for self-hosted models
---

{{< details >}}

- Tier: Premium, Ultimate
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

The AI Gateway supports multiple LLM providers through [LiteLLM](https://docs.litellm.ai/docs/providers). Each platform has unique features and benefits that can cater to different needs. The following documentation summarises the providers we have validated and tested. If the platform you want to use is not in this documentation, provide feedback in the [platform request issue (issue 526144)](https://gitlab.com/gitlab-org/gitlab/-/issues/526144).

## For self-hosted model deployments

### vLLM

[vLLM](https://docs.vllm.ai/en/latest/index.html) is a high-performance inference server optimized for serving LLMs with memory efficiency. It supports model parallelism and integrates easily with existing workflows.

To install vLLM, see the [vLLM Installation Guide](https://docs.vllm.ai/en/latest/getting_started/installation.html). You should install [version v0.6.4.post1](https://github.com/vllm-project/vllm/releases/tag/v0.6.4.post1) or later.

#### Endpoint Configuration

When configuring the endpoint URL for any OpenAI API compatible platforms (such as vLLM) in GitLab:

- The URL must be suffixed with `/v1`
- If using the default vLLM configuration, the endpoint URL would be `https://<hostname>:8000/v1`
- If your server is configured behind a proxy or load balancer, you might not need to specify the port, in which case the URL would be `https://<hostname>/v1`

#### Find the model name

After the model has been deployed, to get the model name for the model identifier field in GitLab, query the vLLM server's `/v1/models` endpoint:

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
- Available options when using vLLM to run a model, see the [vLLM documentation on engine arguments](https://docs.vllm.ai/en/stable/configuration/engine_args.html).
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

> [!note]
> Use this flag only when you do not need detailed request logging.

Disabling request logging minimizes the overhead introduced by verbose logs, especially under high load, and can help improve performance levels.

```shell
vllm serve <path-to-model>/<model-version> \
--served_model_name <choose-a-name-for-the-model>  \
--disable-log-requests
```

This change has been observed to notably improve response times in internal benchmarks.

## For cloud-hosted model deployments

GitLab has validated and tested the following providers. The AI Gateway supports LLM providers that are compatible with [LiteLLM](https://docs.litellm.ai/docs/providers).

- [AWS Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure%2Cglobal-standard%2Cstandard-chat-completions)
- [Anthropic](https://platform.claude.com/docs/en/about-claude/models/overview)
- [OpenAI](https://developers.openai.com/api/docs/models)

For configuration information, see the following provider documentation:

- [Anthropic API overview](https://platform.claude.com/docs/en/api/overview)
- [OpenAI API overview](https://developers.openai.com/api/docs)
- [Working with Azure OpenAI models](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/working-with-models?tabs=powershell)

### Configure authentication with AWS Bedrock

You can use several methods to authenticate AWS Bedrock with your AI Gateway.

Prerequisites:

- Models are automatically enabled in Bedrock when first invoked. For more information,
see [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html).
- Have AWS credentials configured with appropriate IAM permissions.

#### Amazon EKS with Helm Chart (Recommended)

Use IRSA (IAM Roles for Service Accounts) for your AI Gateway pods to authenticate
to AWS Bedrock, without storing static credentials.

After you authenticate Amazon EKS with IRSA,
the AI Gateway automatically obtains temporary credentials from the IRSA role.

To use IRSA to authenticate Amazon EKS:

1. Create an IAM policy that grants access to Bedrock models. You can scope this to specific models if you require more security:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "bedrock:InvokeModel",
           "bedrock:InvokeModelWithResponseStream"
         ],
         "Resource": "arn:aws:bedrock:*:*:foundation-model/*"
       }
     ]
   }
   ```

   ```shell
   aws iam create-policy \
     --policy-name bedrock-ai-gateway-access \
     --policy-document file://bedrock-policy.json \
     --description "Bedrock access for AI Gateway"
   ```

1. Optional. For stricter access control, replace the wildcard resource with specific model Amazon Resource Name (ARN).
   This ensures only approved models can be accessed, even if GitLab configuration changes. For
   available model ARNs, see [Amazon Bedrock model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html).

  ```json
  "Resource": [
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
  ]
  ```

  > [!note]
  Some models might use different ARN formats. For example, newer models might
  require inference profile ARNs in addition to foundation model ARNs. To check the
  the ARN format for your specific model, see the [Amazon Bedrock model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html).

1. Create an IAM role with a trust policy for your Amazon EKS service account to use. Replace the following values:

   - `YOUR_ACCOUNT_ID`: Your AWS account ID.
   - `REGION`: Your Amazon EKS cluster region (for example, `us-east-1`).
   - `YOUR_OIDC_ID`: Your Amazon EKS cluster's OIDC provider ID.
   - `NAMESPACE`: Kubernetes namespace where AI Gateway is deployed.

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID:sub": "system:serviceaccount:NAMESPACE:ai-gateway",
             "oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID:aud": "sts.amazonaws.com"
           }
         }
       }
     ]
   }
   ```

   ```shell
   # Create the role
   aws iam create-role \
     --role-name eks-ai-gateway-bedrock \
     --assume-role-policy-document file://trust-policy.json \
     --description "EKS IRSA role for AI Gateway to access Bedrock"
   ```

1. Attach the Bedrock IAM policy to this role.

   ```shell
   # Attach the role
   aws iam attach-role-policy \
     --role-name eks-ai-gateway-bedrock \
     --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/bedrock-ai-gateway-access
   ```

1. To configure the Helm chart, install the AI Gateway with the IAM role annotation:

   ```yaml
   serviceAccount:
     create: true
     name: ai-gateway
     annotations:
       eks.amazonaws.com/role-arn: arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE_NAME
   extraEnvironmentVariables:
     - name: AWS_REGION
       value: us-east-1
   ```

For more information, see [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

#### Docker deployments

Configure IAM credentials through environment variables when starting the AI Gateway container:

```shell
docker run -d \
  -e AWS_ACCESS_KEY_ID=your-access-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret-key \
  -e AWS_REGION=us-east-1 \
  -p 5052:5052 \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/ai-gateway:vX.Y.Z-ee
```

The IAM user or role must have a policy similar to the one you would set in Amazon EKS with Helm Chart.

#### Kubernetes deployments

For Kubernetes clusters other than Amazon EKS, you can use Kubernetes secrets to store AWS credentials:

1. Create a Kubernetes secret:

   ```shell
   kubectl create secret generic aws-credentials \
     --from-literal=access-key-id=YOUR_ACCESS_KEY_ID \
     --from-literal=secret-access-key=YOUR_SECRET_ACCESS_KEY \
     -n YOUR_NAMESPACE
   ```

1. Configure the Helm chart to reference the secret:

   ```yaml
   extraEnvironmentVariables:
     - name: AWS_ACCESS_KEY_ID
       valueFrom:
         secretKeyRef:
           name: aws-credentials
           key: access-key-id
     - name: AWS_SECRET_ACCESS_KEY
       valueFrom:
         secretKeyRef:
           name: aws-credentials
           key: secret-access-key
     - name: AWS_REGION
       value: us-east-1
   ```

#### AWS Bedrock API keys

To use AWS Bedrock API keys as an alternative to IAM credentials:

1. [Create a Bedrock API key](https://docs.aws.amazon.com/bedrock/latest/userguide/api-keys-generate.html)

1. Create a Kubernetes secret with the API key:

   ```shell
   kubectl create secret generic bedrock-api-key \
     --from-literal=token=YOUR_BEDROCK_API_KEY \
     -n YOUR_NAMESPACE
   ```

1. Configure the AI Gateway (add to your `values.yaml`):

   ```yaml
   extraEnvironmentVariables:
     - name: AWS_BEARER_TOKEN_BEDROCK
       valueFrom:
         secretKeyRef:
           name: bedrock-api-key
           key: token
     - name: AWS_REGION
       value: us-east-1
   ```

#### Private VPC endpoints

To use a private Bedrock endpoint in a VPC, set the `AWS_BEDROCK_RUNTIME_ENDPOINT` environment variable.

For Helm deployments:

```yaml
extraEnvironmentVariables:
  - name: AWS_BEDROCK_RUNTIME_ENDPOINT
    value: https://bedrock-runtime.us-east-1.amazonaws.com
```

For Docker deployments:

```shell
docker run -d \
  -e AWS_BEDROCK_RUNTIME_ENDPOINT=https://bedrock-runtime.us-east-1.amazonaws.com \
  -e AWS_REGION=us-east-1 \
  # ... other configuration
```

For VPC endpoints, use the format: `https://vpce-{vpc-endpoint-id}-{service-name}.{region}.vpce.amazonaws.com`

## Use multiple models and platforms

You can use multiple models and platforms in the same GitLab instance.

For example, you can configure one feature to use Azure OpenAI, and another feature to use AWS Bedrock, or self-hosted models served with vLLM.

This setup gives you flexibility to choose the best model and platform for each use case. Models must be supported and served through a compatible platform.

For more information on setting up different providers, see [Supported models and hardware requirements](supported_models_and_hardware_requirements.md).

## Related topics

- [Amazon Bedrock supported foundation models](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [AWS IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Amazon Bedrock Security](https://docs.aws.amazon.com/bedrock/latest/userguide/security.html)
