---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 자체 호스팅 모델을 GitLab 인스턴스와 통합하는 방법을 알아봅니다
title: 자체 호스팅 모델을 사용하도록 GitLab 구성하기
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/12972) GitLab 17.1 [플래그 포함](../feature_flags/_index.md) 이름 `ai_custom_model`. 기본적으로 비활성화됨.
- [GitLab Self-Managed에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/15176) GitLab 17.6.
- GitLab 17.6 이상에서 GitLab Duo 애드온이 필요하도록 변경되었습니다.
- GitLab 17.8에서 기능 플래그 `ai_custom_model`가 제거되었습니다
- GitLab 17.9에서 UI를 사용하여 AI 게이트웨이 URL을 설정하는 기능이 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/473143)되었습니다.
- GitLab 17.9에서 정식 버전(GA)으로 제공됩니다.
- GitLab 18.0에서 Premium을 포함하도록 변경되었습니다.

{{< /history >}}

전제 조건:

- [GitLab을 17.9 버전 이상으로 업그레이드](../../update/_index.md)합니다.
- 관리자여야 합니다.

GitLab 인스턴스를 구성하여 인프라의 자체 호스팅 모델에 액세스하려면:

1. AI 게이트웨이에 액세스하도록 GitLab 인스턴스를 구성합니다.
1. GitLab 18.4 이상에서는 GitLab Duo Agent Platform 서비스에 액세스하도록 GitLab 인스턴스를 구성합니다.
1. 자체 호스팅 모델을 GitLab 인스턴스에 추가합니다.
1. 기능에 대한 자체 호스팅 모델을 선택합니다.

## 로컬 AI 게이트웨이에 대한 액세스 구성 {#configure-access-to-the-local-ai-gateway}

GitLab 인스턴스와 로컬 AI 게이트웨이 간의 액세스를 구성하려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **로컬 AI 게이트웨이 URL** 아래에 AI 게이트웨이 URL을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

> [!note]
> AI 게이트웨이 URL이 로컬 네트워크 또는 프라이빗 IP 주소(예: `172.31.x.x` 또는 `ip-172-xx-xx-xx.region.compute.internal`와 같은 내부 호스트명)를 가리키는 경우 GitLab은 보안상의 이유로 요청을 차단할 수 있습니다. 이 주소에 대한 요청을 허용하려면 [주소를 IP 허용 목록에 추가](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)합니다.

### AI 게이트웨이에 대한 타임아웃 구성 {#configure-timeout-for-the-ai-gateway}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/567878)되었습니다.

{{< /history >}}

리소스를 절약하고 오래 실행되는 쿼리를 방지하려면 모델 응답을 기다릴 때 GitLab 요청에 대한 AI 게이트웨이 타임아웃을 구성합니다. 큰 컨텍스트 윈도우 또는 복잡한 쿼리를 사용하는 자체 호스팅 모델에 더 긴 타임아웃을 사용합니다.

60초에서 600초(10분) 사이의 타임아웃을 구성할 수 있습니다. 타임아웃을 설정하지 않으면 GitLab은 60초의 기본 타임아웃을 사용합니다.

AI 게이트웨이 타임아웃을 구성하려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **AI 게이트웨이 요청 타임아웃** 아래에 타임아웃 값을 초 단위로 입력합니다(60~600).
1. **변경 사항 저장**을 선택합니다.

### 타임아웃 값 결정 {#determine-the-timeout-value}

타임아웃 값은 특정 배포 및 사용 사례에 따라 다릅니다.

타임아웃 값을 결정하려면:

- 기본 타임아웃인 60초로 시작하여 타임아웃 오류를 모니터링합니다.
- 로그에서 `A1000` 타임아웃 오류를 모니터링합니다. 이러한 오류가 자주 발생하면 타임아웃을 늘리는 것을 고려하세요.
- 사용 사례를 고려합니다. 더 큰 프롬프트, 복잡한 코드 생성 작업 또는 큰 디자인 문서 처리에는 더 긴 타임아웃이 필요할 수 있습니다.
- 인프라를 고려합니다. 모델 성능은 사용 가능한 GPU 리소스, AI 게이트웨이와 모델 엔드포인트 간의 네트워크 지연, 모델의 처리 능력에 따라 달라집니다.
- 점진적으로 증가시킵니다. 타임아웃이 발생하면 값을 점진적으로(예: 30~60초) 늘리고 결과를 모니터링합니다.

타임아웃 오류 문제 해결에 대한 자세한 내용은 [오류 A1000](troubleshooting.md#error-a1000)을 참조하세요.

## GitLab Duo Agent Platform에 대한 액세스 구성 {#configure-access-to-the-gitlab-duo-agent-platform}

{{< history >}}

- GitLab 18.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/19213) 되었으며 [실험](../../policy/development_stages_support.md#experiment) 으로 [기능 플래그](../feature_flags/_index.md) `self_hosted_agent_platform`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.5에서 실험에서 베타로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/558083)되었습니다.
- GitLab 18.7에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)되었습니다.
- GitLab 18.8에서 [정식 버전(GA)으로 제공됩니다](https://gitlab.com/groups/gitlab-org/-/work_items/19125).
- 기능 플래그 `self_hosted_agent_platform`이 GitLab 18.9에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589)되었습니다.
- GitLab 18.7 및 18.8에서 이 기능은 온라인 라이선스가 있는 고객을 위한 베타입니다. 이 기능을 사용하려면 자체 호스팅 베타 모델 및 기능을 [켜야](#turn-on-self-hosted-beta-models-and-features) 합니다.

{{< /history >}}

전제 조건:

- 인스턴스에 오프라인 라이선스가 있는 경우 [GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md) 추가 기능이 있어야 합니다.

GitLab 인스턴스에서 Agent Platform 서비스에 액세스하려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo Agent Platform 서비스의 로컬 URL** 아래에 로컬 Agent Platform 서비스의 URL을 입력합니다.
   - URL은 일반적으로 **로컬 AI 게이트웨이 URL**과 동일하지만 gRPC 포트 :50052에 있습니다.
   - `http://` 또는 `https://`과 같은 URL 접두사를 포함하지 않습니다.
   - [권장되는 NGINX 역방향 프록시](../../install/install_ai_gateway.md#set-up-docker-with-nginx-and-ssl) 로 SSL을 설정했거나 [Ingress가 활성화된 Helm 차트](../../install/install_ai_gateway.md#install-by-using-helm-chart)를 사용하는 경우 포트를 지정하지 않습니다. NGINX Ingress는 포트 포워딩을 처리합니다.
1. 선택사항. 로컬 GitLab Duo Agent Platform 엔드포인트가 TLS를 사용하는 경우 **보안** 아래에서 **Use secure connection (TLS) for GitLab Duo Agent Platform service** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 자체 호스팅 모델 추가 {#add-a-self-hosted-model}

GitLab Duo 기능과 함께 사용하려면 자체 호스팅 모델을 GitLab 인스턴스에 추가해야 합니다.

자체 호스팅 모델을 추가하려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **GitLab Duo 모델 구성**을 선택합니다.
   - **GitLab Duo 모델 구성**을 사용할 수 없는 경우 구매 후 구독을 동기화합니다:
     1. 왼쪽 사이드바에서 **구독**을 선택합니다.
     1. **구독 세부정보**의 **마지막 동기화** 오른쪽에서 구독 동기화({{< icon name="retry" >}})를 선택합니다.
1. **자체 호스팅 모델 추가**를 선택합니다.
1. 필드를 완성합니다:
   - **배포 이름**:  모델 배포를 고유하게 식별하는 이름을 입력합니다. 예: `Mixtral-8x7B-it-v0.1 on GCP`
   - **모델 패밀리**:  배포가 속한 모델 패밀리를 선택합니다. 지원되는 모델 또는 호환 가능한 모델을 선택할 수 있습니다.
   - **엔드포인트**:  모델이 호스팅되는 URL을 입력합니다.
   - **API 키**:  선택사항. 모델에 액세스하려면 API 키가 필요한 경우 추가합니다.
   - **모델 식별자**:  배포 방법에 따라 모델 식별자를 입력합니다. 모델 식별자는 다음 형식과 일치해야 합니다:

     | 배포 방법 | 형식 | 예 |
     |-------------|---------|---------|
     | [vLLM](supported_llm_serving_platforms.md#find-the-model-name)        | `custom_openai/<name of the model served through vLLM>` | `custom_openai/Mixtral-8x7B-Instruct-v0.1` |
     | [Amazon Bedrock](#set-the-model-identifier-for-amazon-bedrock-models) | `bedrock/<model ID of the model>`                       | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | [Google Vertex AI](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-claude) | `vertex_ai/<model ID of the model>` | `vertex_ai/claude-sonnet-4-6@default` |
     | [Anthropic](https://platform.claude.com/docs/en/about-claude/models/overview)                                                             | `anthropic/<model ID of the model>`                     | `anthropic/claude-opus-4-6` |
     | [OpenAI](https://developers.openai.com/api/docs/models)                                                                | `openai/<model ID of the model>`                        | `openai/gpt-5` |
     | Azure OpenAI                                                          | `azure/<model ID of the model>`                         | `azure/gpt-35-turbo` |

1. **자체 호스팅 모델 추가**를 선택합니다.

### Amazon Bedrock 모델에 대한 모델 식별자 설정 {#set-the-model-identifier-for-amazon-bedrock-models}

Amazon Bedrock 모델의 모델 식별자를 설정하려면:

1. `AWS_REGION`을(를) 설정합니다. AI 게이트웨이 Docker 구성에서 해당 지역의 모델에 액세스할 수 있는지 확인합니다.
1. 크로스 지역 추론을 위해 모델의 추론 프로필 ID에 지역 접두사를 추가합니다.
1. `bedrock/` 접두사 지역을 모델 식별자의 접두사로 사용합니다.

   예를 들어 도쿄 지역의 Anthropic Claude 4.0 모델의 경우:

   - `AWS_REGION`은(는) `ap-northeast-1`입니다.
   - 크로스 지역 추론 접두사는 `apac.`입니다.
   - 모델 식별자는 `bedrock/apac.anthropic.claude-sonnet-4-20250514-v1:0`입니다.

일부 지역은 크로스 지역 추론에서 지원되지 않습니다. 이 지역의 경우 모델 식별자에 지역 접두사를 지정하지 않습니다. 예를 들어:

- `AWS_REGION`은(는) `eu-west-2`입니다.
- 모델 식별자는 `anthropic.claude-sonnet-4-5-20250929-v1:0`입니다.

## 자체 호스팅 베타 모델 및 기능 켜기 {#turn-on-self-hosted-beta-models-and-features}

> [!note]
> 베타 자체 호스팅 모델 및 기능을 켜면 [GitLab 테스트 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)도 허용됩니다.

자체 호스팅 베타 모델 및 기능을 활성화하려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **자체 호스팅 베타 모델과 기능** 아래에서 **GitLab Duo 셀프 호스팅에서 베타 모델과 기능을 사용하세요** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 자체 호스팅 모델을 사용하도록 GitLab Duo 기능 구성 {#configure-gitlab-duo-features-to-use-self-hosted-models}

### 구성된 기능 보기 {#view-configured-features}

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **GitLab Duo 모델 구성**을 선택합니다.
   - **GitLab Duo 모델 구성**을 사용할 수 없는 경우 구매 후 구독을 동기화합니다:
     1. 왼쪽 사이드바에서 **구독**을 선택합니다.
     1. **구독 세부정보**의 **마지막 동기화** 오른쪽에서 구독 동기화({{< icon name="retry" >}})를 선택합니다.
1. **AI-네이티브 기능** 탭을 선택합니다.

### 기능에 대한 자체 호스팅 모델 선택 {#select-a-self-hosted-model-for-a-feature}

자체 호스팅 모델을 선택하려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **GitLab Duo 모델 구성**을 선택합니다.
1. **AI-네이티브 기능** 탭을 선택합니다.
1. 자체 호스팅 모델을 선택할 기능의 경우 드롭다운 목록에서 모델을 선택합니다.

> [!note]
> GitLab Duo Chat 하위 기능에 대해 모델을 지정하지 않으면 **General Chat**에 대해 구성된 모델이 자동으로 사용됩니다. 이렇게 하면 각 하위 기능에 대해 개별 모델을 선택할 필요 없이 모든 Chat 기능이 작동합니다.

### 기능에 대한 GitLab 관리 모델 선택 {#select-a-gitlab-managed-model-for-a-feature}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/17192) 되었으며 [베타](../../policy/development_stages_support.md#beta) 로 [기능 플래그](../feature_flags/_index.md) `ai_self_hosted_vendored_features`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.7에서 [기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030)되었습니다
- GitLab 18.9에서 일반적으로 사용 가능합니다. 기능 플래그 `ai_self_hosted_vendored_features`이(가) [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595)되었습니다.

{{< /history >}}

자체 호스팅 AI 게이트웨이 및 자체 호스팅 모델을 사용하는 경우에도 기능에 대해 GitLab 관리 모델을 선택할 수 있습니다.

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **GitLab Duo 모델 구성**을 선택합니다.
1. **AI-네이티브 기능** 탭을 선택합니다.
1. 구성할 기능 및 하위 기능의 경우 드롭다운 목록에서 **GitLab-managed model**을 선택합니다.

### GitLab Duo 기능 끄기 {#turn-off-gitlab-duo-features}

기능에 대해 모델을 선택하지 않았더라도 GitLab Duo 기능은 계속 켜져 있습니다.

GitLab Duo 기능을 끄려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **GitLab Duo 모델 구성**을 선택합니다.
1. **AI-네이티브 기능** 탭을 선택합니다.
1. 끌 기능의 경우 드롭다운 목록에서 **비활성화됨**을 선택합니다.

### GitLab 문서 자체 호스팅 {#self-host-the-gitlab-documentation}

설정 때문에 `docs.gitlab.com`에서 GitLab 문서에 액세스하지 못하는 경우 문서를 자체 호스팅할 수 있습니다. 자세한 내용은 [GitLab 제품 문서 호스팅](../docs_self_host.md)을 참조하세요.

## 관련 항목 {#related-topics}

- [지원되는 모델](supported_models_and_hardware_requirements.md#supported-models)
- [호환 가능한 모델](supported_models_and_hardware_requirements.md#compatible-models)
- [AI 게이트웨이 구성 유형](_index.md#ai-gateway-configurations)
