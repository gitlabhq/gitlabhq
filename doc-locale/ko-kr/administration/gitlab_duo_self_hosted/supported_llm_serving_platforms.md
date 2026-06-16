---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 지원되는 LLM 서빙 플랫폼.
title: LLM 플랫폼 구성
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/12972) GitLab 17.1 [플래그 포함](../feature_flags/_index.md) 이름 `ai_custom_model`. 기본적으로 비활성화됨.
- [GitLab Self-Managed에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/15176) GitLab 17.6.
- GitLab 17.6 이상에서 GitLab Duo 애드온이 필요하도록 변경되었습니다.
- `ai_custom_model` 기능 플래그 GitLab 17.8에서 제거되었습니다.
- GitLab 17.9에서 정식 버전(GA)으로 제공됩니다.
- GitLab 18.0에서 Premium을 포함하도록 변경되었습니다.

{{< /history >}}

AI Gateway는 [LiteLLM](https://docs.litellm.ai/docs/providers)을 통해 여러 LLM 공급자를 지원합니다. 각 플랫폼은 다양한 요구 사항에 맞출 수 있는 고유한 기능과 이점이 있습니다. 다음 설명서는 당사가 검증하고 테스트한 공급자를 요약합니다. 이 설명서에 사용하려는 플랫폼이 없으면 [플랫폼 요청 이슈(이슈 526144)](https://gitlab.com/gitlab-org/gitlab/-/issues/526144)에서 피드백을 제공하세요.

## 여러 모델 및 플랫폼 사용 {#use-multiple-models-and-platforms}

동일한 GitLab 인스턴스에서 여러 모델 및 플랫폼을 사용할 수 있습니다.

예를 들어 한 기능은 Azure OpenAI를 사용하도록 구성하고 다른 기능은 AWS Bedrock 또는 vLLM으로 제공되는 자체 호스팅 모델을 사용하도록 구성할 수 있습니다.

이 설정으로 각 사용 사례에 최적의 모델과 플랫폼을 선택할 수 있는 유연성을 얻을 수 있습니다. 모델은 호환되는 플랫폼을 통해 지원되고 제공되어야 합니다.

## 자체 호스팅 모델 배포 {#self-hosted-model-deployments}

### vLLM {#vllm}

[vLLM](https://docs.vllm.ai/en/latest/index.html)은 메모리 효율성을 위해 최적화된 높은 성능의 추론 서버입니다. 모델 병렬화를 지원하며 기존 워크플로우와 쉽게 통합됩니다.

vLLM을 설치하려면 [vLLM 설치 가이드](https://docs.vllm.ai/en/latest/getting_started/installation.html)를 참조하세요. [v0.18.1 버전](https://github.com/vllm-project/vllm/releases/tag/v0.18.1) 이상을 설치해야 합니다.

vLLM으로 GPT OSS 120B를 제공하는 규정적 설정 가이드는 [vLLM으로 GPT OSS 120B 제공](vllm_gpt_oss_120b.md)을 참조하세요.

#### 엔드포인트 URL 구성 {#configuring-the-endpoint-url}

GitLab에서 OpenAI API 호환 플랫폼(예: vLLM)의 엔드포인트 URL을 구성할 때:

- URL은 `/v1`로 접미사가 붙어야 합니다.
- 기본 vLLM 구성을 사용하는 경우 엔드포인트 URL은 `https://<hostname>:8000/v1`입니다.
- 서버가 프록시 또는 로드 밸런서 뒤에 구성되어 있으면 포트를 지정할 필요가 없을 수 있습니다. 이 경우 URL은 `https://<hostname>/v1`입니다.

#### 모델 이름 찾기 {#find-the-model-name}

모델이 배포된 후 GitLab의 모델 식별자 필드에 대한 모델 이름을 가져오려면 vLLM 서버의 `/v1/models` 엔드포인트를 쿼리하세요:

```shell
curl \
  --header "Authorization: Bearer API_KEY" \
  --header "Content-Type: application/json" \
  http://your-vllm-server:8000/v1/models
```

모델 이름은 응답의 `data.id` 필드의 값입니다.

응답 예시:

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

이 예시에서 모델의 `id`이 `Mixtral-8x22B-Instruct-v0.1`이면 GitLab에서 모델 식별자를 `custom_openai/Mixtral-8x22B-Instruct-v0.1`으로 설정합니다.

자세한 내용은 다음 설명서를 참조하세요:

- vLLM 지원 모델은 [vLLM 지원 모델 설명서](https://docs.vllm.ai/en/latest/models/supported_models.html)를 참조하세요.
- vLLM을 사용하여 모델을 실행할 때 사용 가능한 옵션은 [vLLM 엔진 인수 설명서](https://docs.vllm.ai/en/stable/configuration/engine_args.html)를 참조하세요.

#### Mistral-7B-Instruct-v0.2 {#mistral-7b-instruct-v02}

1. HuggingFace에서 모델을 다운로드합니다:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mistral-7B-Instruct-v0.3
   ```

1. 서버를 실행합니다:

   ```shell
   vllm serve <path-to-model>/Mistral-7B-Instruct-v0.3 \
      --served_model_name <choose-a-name-for-the-model>  \
      --tokenizer_mode mistral \
      --tensor_parallel_size <number-of-gpus> \
      --load_format mistral \
      --config_format mistral \
      --tokenizer <path-to-model>/Mistral-7B-Instruct-v0.3
   ```

#### Mixtral-8x7B-Instruct-v0.1 {#mixtral-8x7b-instruct-v01}

1. HuggingFace에서 모델을 다운로드합니다:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1
   ```

1. 토큰 구성의 이름을 변경합니다:

   ```shell
   cd <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   cp tokenizer.model tokenizer.model.v3
   ```

1. 모델을 실행합니다:

   ```shell
   vllm serve <path-to-model>/Mixtral-8x7B-Instruct-v0.1 \
     --tensor_parallel_size 4 \
     --served_model_name <choose-a-name-for-the-model> \
     --tokenizer_mode mistral \
     --load_format safetensors \
     --tokenizer <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   ```

#### 지연 시간을 줄이기 위해 요청 로깅 비활성화 {#disable-request-logging-to-reduce-latency}

프로덕션에서 vLLM을 실행할 때 `--disable-log-requests` 플래그를 사용하여 요청 로깅을 비활성화하면 지연 시간을 크게 줄일 수 있습니다.

> [!note]
> 상세한 요청 로깅이 필요하지 않을 때만 이 플래그를 사용하세요.

요청 로깅을 비활성화하면 특히 높은 부하에서 상세한 로그로 인한 오버헤드가 최소화되므로 성능 수준을 향상시키는 데 도움이 됩니다.

```shell
vllm serve <path-to-model>/<model-version> \
--served_model_name <choose-a-name-for-the-model>  \
--disable-log-requests
```

이러한 변경으로 인해 내부 벤치마크에서 응답 시간이 눈에 띄게 향상되었습니다.

## 클라우드 호스팅 모델 배포 {#cloud-hosted-model-deployments}

GitLab은 다음 공급자를 검증하고 테스트했습니다. AI Gateway는 [LiteLLM](https://docs.litellm.ai/docs/providers)과 호환되는 LLM 공급자를 지원합니다.

- [AWS Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [Google Vertex AI](https://cloud.google.com/vertex-ai)
- [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure%2Cglobal-standard%2Cstandard-chat-completions)
- [Anthropic](https://platform.claude.com/docs/en/about-claude/models/overview)
- [OpenAI](https://developers.openai.com/api/docs/models)

### AWS Bedrock으로 인증 구성 {#configure-authentication-with-aws-bedrock}

AI Gateway를 사용하여 AWS Bedrock을 인증하는 여러 가지 방법을 사용할 수 있습니다.

전제 조건:

- 모델은 Bedrock에서 처음 호출될 때 자동으로 활성화됩니다. 자세한 내용은 [Bedrock 모델 액세스](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html)를 참조하세요.
- 적절한 IAM 권한으로 구성된 AWS 자격증명이 필요합니다.

#### Amazon EKS with Helm Chart(권장) {#amazon-eks-with-helm-chart-recommended}

AI Gateway 포드에 IRSA(IAM Roles for Service Accounts)를 사용하여 정적 자격증명을 저장하지 않고 AWS Bedrock에 인증합니다.

Amazon EKS를 IRSA로 인증한 후 AI Gateway는 IRSA 역할에서 자동으로 임시 자격증명을 가져옵니다.

IRSA를 사용하여 Amazon EKS를 인증하려면:

1. Bedrock 모델에 대한 액세스를 허용하는 IAM 정책을 만듭니다. 보안을 강화하려면 이를 특정 모델로 범위를 지정할 수 있습니다:

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
         "Resource": "arn:aws:bedrock:*::foundation-model/*"
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

1. 선택사항. 더 엄격한 액세스 제어를 위해 와일드카드 리소스를 특정 모델 Amazon Resource Name(ARN)으로 바꿉니다. GitLab 구성이 변경되더라도 승인된 모델만 액세스할 수 있도록 보장합니다. 사용 가능한 모델 ARN은 [Amazon Bedrock 모델 ID](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)를 참조하세요.

   ```json
   "Resource": [
     "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
     "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
   ]
   ```

   > [!note]
   > 일부 모델은 다른 ARN 형식을 사용할 수 있습니다. 예를 들어 최신 모델은 기초 모델 ARN 외에 추론 프로필 ARN이 필요할 수 있습니다. 특정 모델의 ARN 형식을 확인하려면 [Amazon Bedrock 모델 ID](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)를 참조하세요.

1. Amazon EKS 서비스 계정에서 사용할 신뢰 정책을 포함한 IAM 역할을 만듭니다. 다음 값을 바꿉니다:

   - `YOUR_ACCOUNT_ID`:  AWS 계정 ID입니다.
   - `REGION`:  Amazon EKS 클러스터 지역(예: `us-east-1`).
   - `YOUR_OIDC_ID`:  Amazon EKS 클러스터의 OIDC 공급자 ID입니다.
   - `NAMESPACE`:  AI Gateway가 배포된 Kubernetes 네임스페이스입니다.

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

1. Bedrock IAM 정책을 이 역할에 연결합니다.

   ```shell
   # Attach the role
   aws iam attach-role-policy \
     --role-name eks-ai-gateway-bedrock \
     --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/bedrock-ai-gateway-access
   ```

1. Helm 차트를 구성하려면 IAM 역할 주석을 포함하여 AI Gateway를 설치합니다:

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

자세한 내용은 [서비스 계정의 IAM 역할](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)을 참조하세요.

#### Docker 배포 {#docker-deployments}

AI Gateway 컨테이너를 시작할 때 환경 변수를 통해 IAM 자격증명을 구성합니다:

```shell
docker run -d \
  -e AWS_ACCESS_KEY_ID=your-access-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret-key \
  -e AWS_REGION=us-east-1 \
  -p 5052:5052 \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-vX.Y.Z-ee
```

IAM 사용자 또는 역할은 Amazon EKS with Helm Chart에서 설정할 정책과 유사한 정책을 가져야 합니다.

#### Kubernetes 배포 {#kubernetes-deployments}

Amazon EKS가 아닌 다른 Kubernetes 클러스터의 경우 Kubernetes 보안을 사용하여 AWS 자격증명을 저장할 수 있습니다:

1. Kubernetes 보안을 만듭니다:

   ```shell
   kubectl create secret generic aws-credentials \
     --from-literal=access-key-id=YOUR_ACCESS_KEY_ID \
     --from-literal=secret-access-key=YOUR_SECRET_ACCESS_KEY \
     -n YOUR_NAMESPACE
   ```

1. Helm 차트를 구성하여 보안을 참조합니다:

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

#### AWS Bedrock API 키 {#aws-bedrock-api-keys}

IAM 자격증명의 대안으로 AWS Bedrock API 키를 사용하려면:

1. [Bedrock API 키 만들기](https://docs.aws.amazon.com/bedrock/latest/userguide/api-keys-generate.html)
1. API 키를 사용하여 Kubernetes 보안을 만듭니다:

   ```shell
   kubectl create secret generic bedrock-api-key \
     --from-literal=token=YOUR_BEDROCK_API_KEY \
     -n YOUR_NAMESPACE
   ```

1. AI Gateway를 구성합니다(`values.yaml`에 추가):

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

#### Private VPC 엔드포인트 {#private-vpc-endpoints}

VPC에서 개인 Bedrock 엔드포인트를 사용하려면 `AWS_BEDROCK_RUNTIME_ENDPOINT` 환경 변수를 설정합니다.

Helm 배포의 경우:

```yaml
extraEnvironmentVariables:
  - name: AWS_BEDROCK_RUNTIME_ENDPOINT
    value: https://bedrock-runtime.us-east-1.amazonaws.com
```

Docker 배포의 경우:

```shell
docker run -d \
  -e AWS_BEDROCK_RUNTIME_ENDPOINT=https://bedrock-runtime.us-east-1.amazonaws.com \
  -e AWS_REGION=us-east-1 \
  # ... other configuration
```

VPC 엔드포인트의 경우 형식을 사용하십시오: `https://vpce-{vpc-endpoint-id}-{service-name}.{region}.vpce.amazonaws.com`

#### Bedrock 가드레일 {#bedrock-guardrails}

{{< history >}}

- GitLab 19.0에서 [도입됨](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/4715).

{{< /history >}}

Amazon Bedrock 가드레일을 사용하여 Bedrock 모델 요청에 대한 안전 및 개인 정보 보호 제어를 제공할 수 있습니다.

`AIGW_BEDROCK_GUARDRAIL_CONFIG` 환경 변수 값을 다음 필드를 포함하는 JSON 객체로 설정하여 이러한 가드레일을 적용합니다:

| 필드                 | 설명 |
|-----------------------|-------------|
| `guardrailIdentifier` | AWS 계정의 가드레일 ID입니다. 간단한 ID(`abc123`) 또는 전체 ARN(`arn:aws:bedrock:us-east-1:123456789012:guardrail/abc123`)일 수 있습니다. |
| `guardrailVersion`    | 적용할 가드레일의 버전입니다. `1`로 설정합니다. |
| `trace`               | 응답에 추적 정보를 포함할지 여부입니다. `enabled` 또는 `disabled`로 설정할 수 있습니다. |

> [!note]
> 가드레일이 요청을 차단하면 사용자에게 반환되는 메시지는 GitLab에서 제공한 메시지가 아니라 AWS Bedrock 가드레일에 구성된 사용자 지정 차단 메시지입니다. 사용자가 적절한 지침을 받도록 AWS 콘솔에서 가드레일의 차단 메시징을 구성합니다.

Helm 배포의 경우 다음과 같이 환경 변수를 설정합니다:

```yaml
extraEnvironmentVariables:
  - name: AIGW_BEDROCK_GUARDRAIL_CONFIG
    value: '{"guardrailIdentifier": "<guardrail_id>", "guardrailVersion": "1", "trace": "disabled"}'
```

Docker 배포의 경우:

```shell
docker run -d \
  -e AIGW_BEDROCK_GUARDRAIL_CONFIG='{"guardrailIdentifier": "<guardrail_id>", "guardrailVersion": "1", "trace": "disabled"}' \
  # ... other configuration
```

자세한 내용은 [Amazon Bedrock 가드레일](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html)을 참조하세요.

### Google Vertex AI로 인증 구성 {#configure-authentication-with-google-vertex-ai}

Google Vertex AI의 모델을 사용하려면 AI Gateway 인스턴스를 인증해야 합니다. 다음 메커니즘 중 하나를 사용할 수 있습니다:

- Docker 컨테이너를 시작할 때 환경 변수를 내보냅니다. AI Gateway 컨테이너를 실행할 때 다음 환경 변수를 설정합니다:

  ```shell
  GOOGLE_APPLICATION_CREDENTIALS=/path/to/application_default_credentials.json
  VERTEXAI_PROJECT=<gcp-project-id>
  VERTEXAI_LOCATION=global # or any specific location, e.g., "europe-west1"
  ```

- Google Cloud Run에서 AI Gateway 컨테이너를 실행하고 Vertex AI 액세스를 위해 [Cloud Run 서비스 계정](https://docs.litellm.ai/docs/providers/vertex#using-gcp-service-account)을 사용합니다.

## 관련 항목 {#related-topics}

- [지원되는 모델 및 하드웨어 요구 사항 설명서](supported_models_and_hardware_requirements.md).
- [Amazon Bedrock 지원 기초 모델](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [AWS IAM 모범 사례](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Amazon Bedrock 보안](https://docs.aws.amazon.com/bedrock/latest/userguide/security.html)
- 구성 정보는 다음 설명서를 참조하세요:
  - [Anthropic API 개요](https://platform.claude.com/docs/en/api/overview)
  - [OpenAI API 개요](https://developers.openai.com/api/docs)
  - [Azure OpenAI 모델 사용](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/working-with-models?tabs=powershell)
