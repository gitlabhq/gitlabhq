---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 자체 호스팅 배포 문제 해결 팁
title: 자체 호스팅 모델 문제 해결
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

문제 해결을 시작하기 전에 다음을 수행해야 합니다:

- [`gitlab-rails` 콘솔](../operations/rails_console.md)에 액세스할 수 있어야 합니다.
- AI Gateway Docker 이미지에서 셸을 엽니다.
- 다음의 엔드포인트를 알고 있어야 합니다:
  - AI Gateway가 호스팅되는 위치입니다.
  - 모델이 호스팅되는 위치입니다.
- [로깅을 활성화](logging.md#turn-on-data-collection-for-gitlab-duo) 하여 GitLab에서 AI Gateway로의 요청 및 응답이 [`llm.log`](../logs/_index.md#llmlog)에 기록되는지 확인합니다.

GitLab Duo 문제 해결에 대한 자세한 내용은 다음을 참조하세요:

- [GitLab Duo 문제 해결](../../user/gitlab_duo/troubleshooting.md).
- [코드 제안 문제 해결](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections).
- [GitLab Duo Chat 문제 해결](../../user/gitlab_duo_chat/troubleshooting.md).

## 디버깅 스크립트 사용 {#use-debugging-scripts}

관리자가 자체 호스팅 모델 구성을 확인할 수 있도록 두 가지 디버깅 스크립트를 제공합니다.

1. GitLab에서 AI Gateway로의 연결을 디버깅합니다. GitLab 인스턴스에서 [Rake 작업](../raketasks/_index.md)을 실행합니다:

   ```shell
   gitlab-rake "gitlab:duo:verify_self_hosted_setup[<username>]"
   ```

   선택 사항:  할당된 사용자가 있는 `<username>`을(를) 포함합니다. 사용자 이름 매개변수를 포함하지 않으면 Rake 작업에서 루트 사용자를 사용합니다.

1. AI Gateway 설정을 디버깅합니다. AI Gateway 컨테이너의 경우:

   - 다음을 설정하여 인증을 비활성화한 상태로 AI Gateway 컨테이너를 다시 시작합니다:

     ```shell
     -e AIGW_AUTH__BYPASS_EXTERNAL=true
     ```

     이 설정은 **System Exchange test**를 실행하기 위해 문제 해결 명령에 필요합니다. 문제 해결이 완료된 후 이 설정을 제거해야 합니다.

   - AI Gateway 컨테이너에서 다음을 실행합니다:

     ```shell
     docker exec -it <ai-gateway-container> sh
     poetry run troubleshoot [options]
     ```

     `troubleshoot` 명령은 다음 옵션을 지원합니다:

     | 옵션               | 기본값          | 예                                                       | 설명 |
     |----------------------|------------------|---------------------------------------------------------------|-------------|
     | `--endpoint`         | `localhost:5052` | `--endpoint=localhost:5052`                                   | AI Gateway 엔드포인트 |
     | `--model-family`     | -                | `--model-family=mistral`                                      | 테스트할 모델 제품군입니다. 가능한 값은 `mistral`, `mixtral`, `gpt` 또는 `claude_3`입니다. |
     | `--model-endpoint`   | -                | `--model-endpoint=http://localhost:4000/v1`                   | 모델 엔드포인트입니다. vLLM에서 호스팅되는 모델의 경우 `/v1` 접미사를 추가합니다. |
     | `--model-identifier` | -                | `--model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1` | 모델 식별자입니다. |
     | `--api-key`          | -                | `--api-key=your-api-key`                                      | 모델 API 키입니다. |

     **Examples**:

     AWS Bedrock에서 실행되는 `claude_3` 모델의 경우:

     ```shell
     poetry run troubleshoot \
       --model-family=claude_3 \
       --model-identifier=bedrock/anthropic.claude-3-5-sonnet-20240620-v1:0
     ```

     vLLM에서 실행되는 `mixtral` 모델의 경우:

     ```shell
     poetry run troubleshoot \
       --model-family=mixtral \
       --model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1 \
       --api-key=your-api-key \
       --model-endpoint=http://<your-model-endpoint>/v1
     ```

문제 해결이 완료되면 AI Gateway 컨테이너를 **without**합니다. `AIGW_AUTH__BYPASS_EXTERNAL=true` 없이 진행합니다.

> [!warning]
> 프로덕션에서는 인증을 우회해서는 안 됩니다.

명령의 출력을 확인하고 이에 따라 수정합니다.

두 명령이 모두 성공했지만 GitLab Duo 코드 제안이 여전히 작동하지 않으면 이슈 추적기에서 이슈를 제출합니다.

## GitLab Duo 상태 확인이 작동하지 않음 {#gitlab-duo-health-check-is-not-working}

[GitLab Duo에 대한 상태 확인을 실행](../gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo)할 때 `401 response from the AI Gateway`와 같은 오류가 발생할 수 있습니다.

해결하려면 먼저 GitLab Duo 기능이 올바르게 작동하는지 확인합니다. 예를 들어 GitLab Duo Chat에 메시지를 보냅니다.

이것이 작동하지 않으면 오류는 GitLab Duo 상태 확인의 알려진 문제로 인한 것일 수 있습니다. 자세한 내용은 [이슈 517097](https://gitlab.com/gitlab-org/gitlab/-/issues/517097)을(를) 참조하세요.

## GitLab이 모델에 요청을 할 수 있는지 확인 {#check-if-gitlab-can-make-a-request-to-the-model}

GitLab Rails 콘솔에서 다음을 실행하여 GitLab이 모델에 요청을 할 수 있는지 확인합니다:

```ruby
model_name = "<your_model_name>"
model_endpoint = "<your_model_endpoint>"
model_api_key = "<your_model_api_key>"
body = {:prompt_components=>[{:type=>"prompt", :metadata=>{:source=>"GitLab EE", :version=>"17.3.0"}, :payload=>{:content=>[{:role=>:user, :content=>"Hello"}], :provider=>:litellm, :model=>model_name, :model_endpoint=>model_endpoint, :model_api_key=>model_api_key}}]}
ai_gateway_url = Ai::Setting.instance.ai_gateway_url # Verify that the AI Gateway URL is set in the database
client = Gitlab::Llm::AiGateway::Client.new(User.find_by_id(1), unit_primitive_name: :self_hosted_models)
client.complete(url: "#{ai_gateway_url}/v1/chat/agent", body: body)
```

모델에서 다음 형식의 응답을 반환해야 합니다:

```ruby
{"response"=> "<Model response>",
 "metadata"=>
  {"provider"=>"litellm",
   "model"=>"<>",
   "timestamp"=>1723448920}}
```

그렇지 않으면 다음 중 하나일 수 있습니다:

- 사용자가 코드 제안에 액세스하지 못할 수도 있습니다. 해결하려면 [사용자가 코드 제안을 요청할 수 있는지 확인](#check-if-a-user-can-request-code-suggestions)하세요.
- GitLab 환경 변수가 올바르게 구성되지 않았습니다. 해결하려면 [GitLab 환경 변수가 올바르게 설정되어 있는지 확인](#check-that-the-ai-gateway-environment-variables-are-set-up-correctly)하세요.
- GitLab 인스턴스가 자체 호스팅 모델을(를) 사용하도록 구성되지 않았습니다. 해결하려면 [GitLab 인스턴스가 자체 호스팅 모델을 사용하도록 구성되어 있는지 확인](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models)하세요.
- AI Gateway에 도달할 수 없습니다. 해결하려면 [GitLab이 AI Gateway에 HTTP 요청을 할 수 있는지 확인](#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway)하세요.
- LLM 서버가 AI Gateway 컨테이너와 동일한 인스턴스에 설치되어 있으면 로컬 요청이 작동하지 않을 수 있습니다. 해결하려면 [Docker 컨테이너에서 로컬 요청 허용](#llm-server-is-not-available-inside-the-ai-gateway-container)을(를) 참조하세요.

## 사용자가 코드 제안을(를) 요청할 수 있는지 확인 {#check-if-a-user-can-request-code-suggestions}

GitLab Rails 콘솔에서 다음을 실행하여 사용자가 코드 제안을 요청할 수 있는지 확인합니다:

```ruby
User.find_by_id("<user_id>").can?(:access_code_suggestions)
```

`false`을(를) 반환하면 일부 구성이 누락되었으며 사용자가 코드 제안에 액세스할 수 없습니다.

이 누락된 구성은 다음 중 하나로 인한 것일 수 있습니다:

- 라이선스가 유효하지 않습니다. 해결하려면 [라이선스를 확인하거나 업데이트](../license_file.md#see-current-license-information)하세요.
- GitLab Duo가 자체 호스팅 모델을(를) 사용하도록 구성되지 않았습니다. 해결하려면 [GitLab 인스턴스가 자체 호스팅 모델을 사용하도록 구성되어 있는지 확인](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models)하세요.

## GitLab 인스턴스가 자체 호스팅 모델을(를) 사용하도록 구성되어 있는지 확인 {#check-if-gitlab-instance-is-configured-to-use-self-hosted-models}

전제 조건:

- 관리자 액세스 권한입니다.

GitLab Duo가 올바르게 구성되었는지 확인하려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **자체 호스팅 모델**을(를) 선택합니다.
1. **AI-네이티브 기능**을(를) 확장합니다.
1. **기능** 아래에서 **코드 제안**과 **Code generation**이(가) **자체 호스팅 모델**로 설정되어 있는지 확인합니다.

## AI Gateway URL이 올바르게 설정되어 있는지 확인 {#check-that-the-ai-gateway-url-is-set-up-correctly}

AI Gateway URL이 올바른지 확인하려면 GitLab Rails 콘솔에서 다음을 실행하세요:

```ruby
Ai::Setting.instance.ai_gateway_url == "<your-ai-gateway-instance-url>"
```

AI Gateway가 설정되지 않은 경우 [GitLab 인스턴스를 AI Gateway에 액세스하도록 구성](configure_duo_features.md#configure-access-to-the-local-ai-gateway)합니다.

## GitLab Duo Agent Platform 서비스 URL 유효성 검사 {#validate-the-gitlab-duo-agent-platform-service-url}

Agent Platform 서비스의 URL이 올바른지 확인하려면 GitLab Rails 콘솔에서 다음을 실행하세요:

```ruby
Ai::Setting.instance.duo_agent_platform_service_url == "<your-duo-agent-platform-instance-url>"
```

Agent Platform 서비스의 URL은 TCP URL이며 `http://` 또는 `https://` 접두사를 가질 수 없습니다.

Agent Platform의 URL이 설정되지 않은 경우 [GitLab 인스턴스를 URL에 액세스하도록 구성](configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)해야 합니다.

## GitLab이 AI Gateway에 HTTP 요청을 할 수 있는지 확인 {#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway}

GitLab Rails 콘솔에서 다음을 실행하여 GitLab이 AI Gateway에 HTTP 요청을 할 수 있는지 확인합니다:

```ruby
HTTParty.get('<your-aigateway-endpoint>/monitoring/healthz', headers: { 'accept' => 'application/json' }).code
```

응답이 `200`이 아니면 다음 중 하나를 의미합니다:

- 네트워크가 GitLab이 AI Gateway 컨테이너에 도달할 수 있도록 제대로 구성되지 않았습니다. 네트워크 관리자에게 문의하여 설정을 확인합니다.
- AI Gateway가 요청을 처리할 수 없습니다. 이 문제를 해결하려면 [AI Gateway가 모델에 요청을 할 수 있는지 확인](#check-if-the-ai-gateway-can-make-a-request-to-the-model)하세요.

## AI Gateway가 모델에 요청을 할 수 있는지 확인 {#check-if-the-ai-gateway-can-make-a-request-to-the-model}

AI Gateway 컨테이너에서 AI Gateway API에 대한 HTTP 요청을 만들어 코드 제안을 합니다. 다음을 바꿉니다:

- `<your_model_name>`을(를) 사용 중인 모델의 이름으로 바꿉니다. 예를 들어 `mistral` 또는 `codegemma`입니다.
- `<your_model_endpoint>`을(를) 모델이 호스팅되는 엔드포인트로 바꿉니다.

```shell
docker exec -it <ai-gateway-container> sh
curl --request POST "http://localhost:5052/v1/chat/agent" \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --data '{ "prompt_components": [ { "type": "string", "metadata": { "source": "string", "version": "string" }, "payload": { "content": "Hello", "provider": "litellm", "model": "<your_model_name>", "model_endpoint": "<your_model_endpoint>" } } ], "stream": false }'
```

요청이 실패하면:

- AI Gateway가 자체 호스팅 모델을(를) 사용하도록 제대로 구성되지 않았을 수 있습니다. 이를 해결하려면 [AI Gateway URL이 올바르게 설정되어 있는지 확인](#check-that-the-ai-gateway-url-is-set-up-correctly)하세요.
- AI Gateway가 모델에 액세스하지 못할 수 있습니다. 해결하려면 [AI Gateway에서 모델에 도달할 수 있는지 확인](#check-if-the-model-is-reachable-from-ai-gateway)하세요.
- 모델 이름 또는 엔드포인트가 올바르지 않을 수 있습니다. 값을 확인하고 필요한 경우 수정합니다.

## AI Gateway가 요청을 처리할 수 있는지 확인 {#check-if-ai-gateway-can-process-requests}

```shell
docker exec -it <ai-gateway-container> sh
curl '<your-aigateway-endpoint>/monitoring/healthz'
```

응답이 `200`이 아니면 AI Gateway가 올바르게 설치되지 않았습니다. 해결하려면 [AI Gateway를 설치하는 방법에 대한 설명서](../../install/install_ai_gateway.md)를 따르세요.

## AI Gateway 환경 변수가 올바르게 설정되어 있는지 확인 {#check-that-the-ai-gateway-environment-variables-are-set-up-correctly}

AI Gateway 환경 변수가 올바르게 설정되어 있는지 확인하려면 AI Gateway 컨테이너의 콘솔에서 다음을 실행하세요:

```shell
docker exec -it <ai-gateway-container> sh
echo $AIGW_CUSTOM_MODELS__ENABLED # must be true
```

환경 변수가 올바르게 설정되지 않은 경우 [컨테이너를 만듭니다](../../install/install_ai_gateway.md#ai-gateway-images).

## 모델이 AI Gateway에서 도달 가능한지 확인 {#check-if-the-model-is-reachable-from-ai-gateway}

AI Gateway 컨테이너에서 셸을 만들고 모델에 curl 요청을 만듭니다. AI Gateway가 해당 요청을 할 수 없다는 것을 발견하면 다음으로 인한 것일 수 있습니다:

1. 모델 서버가 제대로 작동하지 않습니다.
1. 컨테이너 주변의 네트워크 설정이 모델이 호스팅되는 위치로의 요청을 허용하도록 제대로 구성되지 않았습니다.

이를 해결하려면 네트워크 관리자에게 문의합니다.

## AI Gateway가 GitLab 인스턴스에 요청을 할 수 있는지 확인 {#check-if-ai-gateway-can-make-requests-to-your-gitlab-instance}

`AIGW_GITLAB_URL`에 정의된 GitLab 인스턴스는 요청 인증을 위해 AI Gateway 컨테이너에서 액세스 가능해야 합니다. 인스턴스에 도달할 수 없으면(예: 프록시 구성 오류로 인해) 다음과 같은 오류로 요청이 실패할 수 있습니다:

- ```shell
  jose.exceptions.JWTError: Signature verification failed
  ```

- ```shell
  gitlab_cloud_connector.providers.CompositeProvider.CriticalAuthError: No keys founds in JWKS; are OIDC providers up?
  ```

이 시나리오에서 `AIGW_GITLAB_URL`과(와) `$AIGW_GITLAB_API_URL`이(가) 컨테이너에 제대로 설정되어 있고 액세스 가능한지 확인합니다. 다음 명령은 컨테이너에서 실행할 때 성공해야 합니다:

```shell
poetry run troubleshoot
curl "$AIGW_GITLAB_API_URL/projects"
```

성공하지 못하면 네트워크 구성을 확인합니다.

## 이미지의 플랫폼이 호스트와 일치하지 않음 {#the-images-platform-does-not-match-the-host}

[AI Gateway 이미지를 사용](../../install/install_ai_gateway.md#ai-gateway-images)할 때 `The requested image's platform (linux/amd64) does not match the detected host`과(와) 같은 오류가 발생할 수 있습니다.

이 오류를 해결하려면 `--platform linux/amd64`을(를) `docker run` 명령에 추가합니다:

```shell
docker run --platform linux/amd64 -e AIGW_GITLAB_URL=<your-gitlab-endpoint> <image>
```

## LLM 서버는 AI Gateway 컨테이너 내에서 사용할 수 없음 {#llm-server-is-not-available-inside-the-ai-gateway-container}

LLM 서버가 AI Gateway 컨테이너와 동일한 인스턴스에 설치되어 있으면 로컬 호스트를 통해 액세스하지 못할 수 있습니다.

이를 해결하려면:

1. `--network host`을(를) `docker run` 명령에 포함하여 AI Gateway 컨테이너에서 로컬 요청을 활성화합니다.
1. `-e AIGW_FASTAPI__METRICS_PORT=8083` 플래그를 사용하여 포트 충돌을 해결합니다.

```shell
docker run --network host -e AIGW_GITLAB_URL=<your-gitlab-endpoint> -e AIGW_FASTAPI__METRICS_PORT=8083 <image>
```

## vLLM 404 오류 {#vllm-404-error}

vLLM을 사용할 때 **404 error**가 발생하면 다음 단계에 따라 문제를 해결합니다:

1. `chat_template.jinja` 이름의 채팅 템플릿 파일을 만들고 다음 내용을 입력합니다:

   ```jinja
   {%- for message in messages %}
     {%- if message["role"] == "user" %}
       {{- "[INST] " + message["content"] + "[/INST]" }}
     {%- elif message["role"] == "assistant" %}
       {{- message["content"] }}
     {%- elif message["role"] == "system" %}
       {{- bos_token }}{{- message["content"] }}
     {%- endif %}
   {%- endfor %}
   ```

1. vLLM 명령을 실행할 때 `--served-model-name`을(를) 지정했는지 확인합니다. 예를 들어:

   ```shell
   vllm serve "mistralai/Mistral-7B-Instruct-v0.3" --port <port> --max-model-len 17776 --served-model-name mistral --chat-template chat_template.jinja
   ```

1. GitLab UI에서 vLLM 서버 URL을 확인하여 URL이 `/v1` 접미사를 포함하는지 확인합니다. 올바른 형식은:

   ```shell
   http(s)://<your-host>:<your-port>/v1
   ```

## 코드 제안 액세스 오류 {#code-suggestions-access-error}

설정 후 코드 제안 액세스에 문제가 있으면 다음 단계를 시도하세요:

1. Rails 콘솔에서 라이선스 매개변수를 확인하고 검증합니다:

   ```shell
   sudo gitlab-rails console
   user = User.find(id) # Replace id with the user provisioned with GitLab Duo Enterprise seat
   Ability.allowed?(user, :access_code_suggestions) # Must return true
   ```

1. 필요한 기능이 활성화되고 사용 가능한지 확인합니다:

   ```shell
   ::Ai::FeatureSetting.exists?(feature: [:code_generations, :code_completions], provider: :self_hosted) # Should be true
   ```

## 오류 A1000 {#error-a1000}

자체 호스팅 모델과 함께 GitLab Duo 기능을 사용할 때 다음 오류가 발생할 수 있습니다:

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`

이 문제는 모델에 대한 요청이 구성된 시간 초과 기간보다 오래 걸릴 수 있을 때 발생합니다.

일반적인 원인은 다음과 같습니다:

- 큰 컨텍스트 윈도우 또는 복잡한 프롬프트
- 모델 성능 제한
- AI Gateway와 모델 엔드포인트 간의 네트워크 지연
- 교차 지역 추론 지연(AWS Bedrock 배포의 경우)

시간 초과 오류를 해결하려면:

1. [더 높은 AI Gateway 시간 초과 값 구성](configure_duo_features.md#configure-timeout-for-the-ai-gateway). 시간 초과를 60~600초(10분) 사이로 설정할 수 있습니다.
1. 시간 초과를 조정한 후 로그를 모니터링하여 오류가 해결되었는지 확인합니다.
1. 더 높은 시간 초과 값을 사용해도 시간 초과 오류가 계속되면:
   - 모델의 성능 및 리소스 할당을 확인합니다.
   - AI Gateway와 모델 엔드포인트 간의 네트워크 연결을 확인합니다.
   - 더 성능이 좋은 모델 또는 배포 구성을 사용하는 것을 고려하세요.

## GitLab 설정 확인 {#verify-gitlab-setup}

GitLab Self-Managed 설정을 확인하려면 다음 명령을 실행하세요:

```shell
gitlab-rake gitlab:duo:verify_self_hosted_setup
```

## AI Gateway 서버에서 생성된 로그가 없음 {#no-logs-generated-in-the-ai-gateway-server}

AI Gateway 서버에서 로그가 생성되지 않으면 다음 단계에 따라 문제를 해결하세요:

1. [AI 로그가 활성화](logging.md#turn-on-data-collection-for-gitlab-duo)되었는지 확인합니다.
1. 다음 명령을 실행하여 GitLab Rails 로그에서 오류를 확인합니다:

   ```shell
   sudo gitlab-ctl tail
   sudo gitlab-ctl tail sidekiq
   ```

1. "Error" 또는 "Exception"과 같은 키워드를 로그에서 찾아 기본 문제를 파악합니다.

## AI Gateway 컨테이너의 SSL 인증서 오류 및 키 역직렬화 문제 {#ssl-certificate-errors-and-key-de-serialization-issues-in-the-ai-gateway-container}

AI Gateway 컨테이너 내에서 GitLab Duo Chat을 시작하려고 할 때 SSL 인증서 오류 및 키 역직렬화 문제가 발생할 수 있습니다.

시스템에서 PEM 파일을 로드할 때 문제가 발생할 수 있으며 다음과 같은 오류가 발생합니다:

```plaintext
JWKError: Could not deserialize key data. The data may be in an incorrect format, the provided password may be incorrect, or it may be encrypted with an unsupported algorithm.
```

SSL 인증서 오류를 해결하려면:

- 다음 환경 변수를 사용하여 Docker 컨테이너에서 적절한 인증서 번들 경로를 설정합니다:
  - `SSL_CERT_FILE=/path/to/ca-bundle.pem`
  - `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

## 오류:  모델 ID meta의 호출이 지원되지 않음 {#error-invocation-of-model-id-meta-isnt-supported}

AIGW 로그에서 모델 식별자의 형식이 잘못되면 다음 오류가 표시됩니다:

```plaintext
Invocation of model ID meta.llama3-3-70b-instruct-v1:0 with on-demand throughput isn\u2019t supported. Retry your request with the ID or ARN of an inference profile that contains this model
```

`model identifier`의 형식이 `bedrock/<region>.<model-id>`인지 확인하세요. 여기서:

- `<region>`은(는) AWS 지역입니다(예: `us`).
- `<model-id>`은(는) 전체 모델 식별자입니다.

예: `bedrock/us.meta.llama3-3-70b-instruct-v1:0`. 모델 구성을 업데이트하여 올바른 형식을 사용합니다.

## 기능에 액세스할 수 없거나 기능 버튼이 표시되지 않음 {#feature-not-accessible-or-feature-button-not-visible}

기능이 작동하지 않거나 기능 버튼(예: **`/troubleshoot`**)이 표시되지 않으면:

1. 기능의 `unit_primitive`이(가) [`gitlab-cloud-connector` gem 구성의 자체 호스팅 모델 단위 기본 목록](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/blob/main/config/services/self_hosted_models.yml)에 나열되어 있는지 확인합니다.

   기능이 이 파일에서 누락된 경우 액세스할 수 없는 이유일 수 있습니다.

1. 선택사항. 기능이 나열되지 않은 경우 GitLab 인스턴스에서 다음을 설정하여 이것이 문제의 원인인지 확인할 수 있습니다:

   ```shell
   CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
   ```

   GitLab을 다시 시작하고 기능이 액세스 가능한지 확인합니다.

   **Important**:  문제 해결 후 이 플래그를 설정하지 **without** GitLab을 다시 시작합니다.

   > [!warning]
   > **`CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1`을(를) 프로덕션에서 사용하지 마세요**. 개발 환경은 프로덕션과 밀접하게 미러링되어야 하며 숨겨진 플래그나 내부 전용 해결 방법이 없어야 합니다.

1. 이 문제를 해결하려면:
   - GitLab 팀 구성원이면 [`#g_custom_models` Slack 채널](https://gitlab.enterprise.slack.com/archives/C06DCB3N96F)을(를) 통해 Custom Models 팀에 문의합니다.
   - 고객이면 [GitLab Support](https://about.gitlab.com/support/)를 통해 문제를 보고합니다.

## 오류:  이 워크플로우에 대한 인증 토큰을 가져오는 중에 오류가 발생했습니다 {#error-an-error-occurred-while-fetching-an-authentication-token-for-this-workflow}

이 오류는 GitLab 또는 로컬 환경에서 에이전트 Chat을 사용하려고 할 때 발생할 수 있습니다.

IDE의 [GitLab Language Server](../../editor_extensions/language_server/_index.md) 로그에서 다음을 볼 수도 있습니다:

```shell
2026-01-09T20:17:43:419 [error]: [WorkflowRailsService] Failed to fetch the workflow token
    Error: Fetching direct_access from https://gitlab.example.com/api/v4/ai/duo_workflows/direct_access failed.
{"message":"400 Bad request - 14:failed to connect to all addresses; last error: UNKNOWN: ipv4:172.x.x.x:50052: Ssl handshake failed (TSI_PROTOCOL_FAILURE): SSL_ERROR_SSL: error:100000f7:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER: Invalid certificate verification context. debug_error_string:{UNKNOWN:Error received from peer  {grpc_status:14, grpc_message:\"failed to connect to all addresses; last error: UNKNOWN: ipv4:172.x.x.x:50052: Ssl handshake failed (TSI_PROTOCOL_FAILURE): SSL_ERROR_SSL: error:100000f7:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER: Invalid certificate verification context\"}}"}
2026-01-09T20:17:43:433 [error]: Max retries exceeded or non-retryable error: An error occurred while fetching an authentication token for this workflow.
2026-01-09T20:17:43:435 [error]: Workflow failed with status code "50": An error occurred while fetching an authentication token for this workflow.
```

이는 언어 서버가 인증서 문제로 인해 JWT 토큰을 생성하기 위해 `direct_access` 엔드포인트와 통신할 수 없음을 의미합니다.

자체 호스팅 모델을 Agent Platform과 연결하기 위해 TLS를 사용하지 않는 경우 이 문제를 해결하려면 [TLS 연결을 끕니다](configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform): GitLab Duo Agent Platform 서비스.

## 에이전트 Chat의 응답이 UI에 표시되지 않음 {#response-from-agentic-chat-does-not-display-in-the-ui}

채팅 응답은 브라우저와 GitLab 간의 지속적인 WebSocket 연결이 필요합니다. 역방향 프록시가 WebSocket 업그레이드를 지원하지 않으면 응답이 성공적으로 생성되지만 GitLab UI의 채팅에 표시되지 않습니다.

### 증상 {#symptoms}

- `llm.log`에 `chunk_received`, `streaming_finished`, `final_answer_received`가 오류 없이 표시됩니다.
- AI Gateway 로그는 성공적인 모델 응답을 보여줍니다.
- GitLab Duo Chat UI는 요청을 처리하는 것처럼 보이지만 응답을 표시하지 않습니다.

이 문제를 해결하려면 역방향 프록시가 [인바운드 연결 요구 사항](../gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)을(를) 충족하도록 구성되어 있는지 확인합니다.
