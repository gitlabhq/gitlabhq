---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 자체 호스팅 모델에 대한 로깅을 활성화합니다.
title: 자체 호스팅 모델에 대한 로그
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 17.1에서 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/12972) [기능 플래그](../feature_flags/_index.md) `ai_custom_model`이름으로 제공됩니다. 기본적으로 비활성화됨.
- [GitLab Self-Managed에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/15176) GitLab 17.6에서.
- GitLab 17.6 이상에서 GitLab Duo 애드온이 필요하도록 변경되었습니다.
- 기능 플래그 `ai_custom_model` GitLab 17.8에서 제거됨.
- GitLab 17.9에서 정식 버전(GA)으로 제공됩니다.
- GitLab 17.9에서 UI를 통해 로깅을 켜고 끌 수 있는 기능이 추가되었습니다.
- GitLab 18.0에서 Premium을 포함하도록 변경되었습니다.

{{< /history >}}

자세한 로깅을 통해 자체 호스팅 모델 성능을 모니터링하고 이슈를 더 효과적으로 디버깅합니다.

## GitLab Duo에 대한 데이터 수집 활성화 {#turn-on-data-collection-for-gitlab-duo}

전제 조건:

- 관리자여야 합니다.

GitLab Duo의 데이터 수집은 AI Gateway 구성에 따라 다릅니다.

### 자체 호스팅 AI Gateway를 사용하는 GitLab Self-Managed {#on-gitlab-self-managed-with-a-self-hosted-ai-gateway}

데이터 수집을 활성화하면 자세한 AI 로그(프롬프트 및 응답)가 `llm.log` GitLab 인스턴스 및 AI Gateway에 로컬로 저장됩니다. 데이터는 GitLab과 공유되지 않습니다.

데이터 수집을 활성화하려면:

1. 오른쪽 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **수집 데이터** 아래에서 **사용량 데이터 수집**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### GitLab 관리 AI Gateway를 사용하는 GitLab Self-Managed {#gitlab-self-managed-with-a-gitlab-managed-ai-gateway}

**사용량 데이터 수집**을 활성화하면 GitLab과 사용량 데이터를 공유합니다. 이 시나리오에서는 GitLab 관리 AI Gateway의 확장 로깅이 활성화되지 않으므로 민감한 데이터를 보호합니다.

데이터 수집을 활성화하려면:

1. 오른쪽 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **수집 데이터** 아래에서 **사용량 데이터 수집**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## GitLab 설치에서의 로그 {#logs-in-your-gitlab-installation}

로깅 설정은 민감한 정보를 보호하면서 시스템 작동의 투명성을 유지하도록 설계되었으며 다음 구성 요소로 구성됩니다:

- GitLab 인스턴스에 대한 요청을 캡처하는 로그.
- 로깅 제어.
- `llm.log` 파일.

### GitLab 인스턴스에 대한 요청을 캡처하는 로그 {#logs-that-capture-requests-to-the-gitlab-instance}

`application.json`, `production_json.log` 및 `production.log` 파일의 로깅을 포함한 기타 파일은 GitLab 인스턴스에 대한 요청을 캡처합니다:

- **Filtered Requests**:  이러한 파일에서 요청을 로깅하지만 민감한 데이터(예: 입력 매개변수)가 **필터링됨**인지 확인합니다. 이는 요청 메타데이터(예: 요청 유형, 엔드포인트 및 응답 상태)가 캡처되는 동안 실제 입력 데이터(예: 쿼리 매개변수, 변수 및 콘텐츠)는 민감한 정보의 노출을 방지하기 위해 로깅되지 않음을 의미합니다.
- **Example 1**:  코드 제안 완료 요청의 경우 로그는 민감한 정보를 필터링하는 동안 요청 세부사항을 캡처합니다:

  ```json
  {
    "method": "POST",
    "path": "/api/graphql",
    "controller": "GraphqlController",
    "action": "execute",
    "status": 500,
    "params": [
      {"key": "query", "value": "[FILTERED]"},
      {"key": "variables", "value": "[FILTERED]"},
      {"key": "operationName", "value": "chat"}
    ],
    "exception": {
      "class": "NoMethodError",
      "message": "undefined method `id` for {:skip=>true}:Hash"
    },
    "time": "2024-08-28T14:13:50.328Z"
  }
  ```

  표시된 대로 오류 정보 및 요청의 일반적인 구조가 로깅되는 동안 민감한 입력 매개변수는 `[FILTERED]`으로 표시됩니다.

- **Example 2**:  코드 제안 완료 요청의 경우 로그도 민감한 정보를 필터링하는 동안 요청 세부사항을 캡처합니다:

  ```json
  {
    "method": "POST",
    "path": "/api/v4/code_suggestions/completions",
    "status": 200,
    "params": [
      {"key": "prompt_version", "value": 1},
      {"key": "current_file", "value": {"file_name": "/test.rb", "language_identifier": "ruby", "content_above_cursor": "[FILTERED]", "content_below_cursor": "[FILTERED]"}},
      {"key": "telemetry", "value": []}
    ],
    "time": "2024-10-15T06:51:09.004Z"
  }
  ```

  표시된 대로 요청의 일반적인 구조가 로깅되는 동안 `content_above_cursor` 및 `content_below_cursor` 같은 민감한 입력 매개변수는 `[FILTERED]`으로 표시됩니다.

### 로깅 제어 {#logging-control}

로그의 부분 집합을 제어하려면 GitLab Duo 설정 페이지에서 데이터 수집을 켜고 끕니다. 데이터 수집을 끄면 특정 작업에 대한 로깅이 비활성화됩니다.

### `llm.log` 파일 {#llmlog-file}

자체 호스팅 AI Gateway 구성에서 데이터 수집이 활성화되면 GitLab Self-Managed 인스턴스를 통해 발생하는 코드 생성 및 GitLab Duo Chat 이벤트가 [`llm.log` 파일](../logs/_index.md#llmlog)에 캡처됩니다. 로그 파일은 활성화되지 않으면 아무것도 캡처하지 않습니다.

코드 완료 로그는 AI Gateway에서 캡처됩니다. 이러한 로그는 GitLab으로 전송되지 않습니다. GitLab Self-Managed 인프라에서만 볼 수 있습니다.

- [`llm.log`의 로그를 회전, 관리, 내보내기 및 시각화](../logs/_index.md)합니다.
- [로그 파일 위치 보기(예: 로그를 삭제할 수 있도록)](../logs/_index.md#llm-input-and-output-logging).

### AI Gateway 컨테이너의 로그 {#logs-in-your-ai-gateway-container}

AI Gateway 및 GitLab Duo Agent Platform에서 생성한 로그의 위치를 지정하려면 다음을 실행하세요:

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="your-signing-key" \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -e DUO_WORKFLOW_LOGGING__TO_FILE="duo_agent_platform.log" \
 -v <your_aigateway_file_path>:aigateway.log \
 -v <your_duo_agent_platform_file_path>:duo_agent_platform.log \
 <image>
```

기본적으로 로깅 수준은 `INFO`으로 설정됩니다. 로깅 수준을 `DEBUG`로 변경하려면 다음을 실행하세요:

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="your-signing-key" \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -e DUO_WORKFLOW_LOGGING__TO_FILE="duo_agent_platform.log" \
 -e AIGW_LOGGING__LEVEL="DEBUG" \
 -e DUO_WORKFLOW_LOGGING__LEVEL="DEBUG" \
 -v <your_aigateway_file_path>:aigateway.log \
 -v <your_duo_agent_platform_file_path>:duo_agent_platform.log \
 <image>
```

또한 `litellm`의 모든 디버그 문을 로깅하려면 다음 환경 변수를 추가하세요:

```shell
-e AIGW_LOGGING__ENABLE_LITELLM_LOGGING=true
```

파일 이름을 지정하지 않으면 로그가 출력으로 스트리밍되며 Docker 로그를 사용하여 관리할 수도 있습니다. 자세한 내용은 [Docker 로그 설명서](https://docs.docker.com/reference/cli/docker/container/logs/)를 참조하세요.

또한 AI Gateway 실행의 출력은 이슈 디버깅에 도움이 될 수 있습니다. 이에 액세스하려면:

- Docker를 사용할 때:

  ```shell
  docker logs <container-id>
  ```

- Kubernetes를 사용할 때:

  ```shell
  kubectl logs <container-name>
  ```

이러한 로그를 로깅 솔루션에 수집하려면 로깅 제공자 설명서를 참조하세요.

### 로그 구조 {#logs-structure}

POST 요청이 만들어질 때(예: `/chat/completions` 엔드포인트에) 서버는 요청을 로깅합니다:

- 페이로드
- 헤더
- 메타데이터

#### 1\. 요청 페이로드 {#1-request-payload}

JSON 페이로드는 일반적으로 다음 필드를 포함합니다:

- `messages`:  메시지 객체의 배열.
  - 각 메시지 객체에는 다음이 포함됩니다:
    - `content`:  사용자 입력 또는 쿼리를 나타내는 문자열.
    - `role`:  메시지 발신자의 역할을 나타냅니다(예: `user`).
- `model`:  사용할 모델을 지정하는 문자열(예: `mistral`).
- `max_tokens`:  응답에서 생성할 최대 토큰 수를 지정하는 정수.
- `n`:  생성할 완료 수를 나타내는 정수.
- `stop`:  생성된 텍스트의 중지 시퀀스를 나타내는 문자열 배열.
- `stream`:  응답을 스트리밍할지 여부를 나타내는 부울.
- `temperature`:  출력의 무작위성을 제어하는 부동 소수점 수.

##### 요청 예시 {#example-request}

```json
{
    "messages": [
        {
            "content": "<s>[SUFFIX]None[PREFIX]# # build a hello world ruby method\n def say_goodbye\n    puts \"Goodbye, World!\"\n  end\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain",
            "role": "user"
        }
    ],
    "model": "mistral",
    "max_tokens": 128,
    "n": 1,
    "stop": ["[INST]", "[/INST]", "[PREFIX]", "[MIDDLE]", "[SUFFIX]"],
    "stream": false,
    "temperature": 0.0
}
```

#### 2\. 요청 헤더 {#2-request-headers}

요청 헤더는 요청하는 클라이언트에 대한 추가 컨텍스트를 제공합니다. 주요 헤더에는 다음이 포함될 수 있습니다:

- `Authorization`:  API 액세스를 위한 Bearer 토큰을 포함합니다.
- `Content-Type`:  리소스의 미디어 유형을 나타냅니다(예: `JSON`).
- `User-Agent`:  요청하는 클라이언트 소프트웨어에 대한 정보.
- `X-Stainless-` 헤더:  클라이언트 환경에 대한 추가 메타데이터를 제공하는 다양한 헤더.

##### 요청 헤더 예시 {#example-request-headers}

```json
{
    "host": "0.0.0.0:4000",
    "accept-encoding": "gzip, deflate",
    "connection": "keep-alive",
    "accept": "application/json",
    "content-type": "application/json",
    "user-agent": "AsyncOpenAI/Python 1.51.0",
    "authorization": "Bearer <TOKEN>",
    "content-length": "364"
}
```

#### 3\. 요청 메타데이터 {#3-request-metadata}

메타데이터는 요청의 컨텍스트를 설명하는 다양한 필드를 포함합니다:

- `requester_metadata`:  요청자에 대한 추가 메타데이터.
- `user_api_key`:  요청에 사용된 API 키(익명화).
- `api_version`:  사용 중인 API의 버전.
- `request_timeout`:  요청의 제한 시간 기간.
- `call_id`:  호출의 고유 식별자.

##### 메타데이터 예시 {#example-metadata}

```json
{
    "user_api_key": "<ANONYMIZED_KEY>",
    "api_version": "1.48.18",
    "request_timeout": 600,
    "call_id": "e1aaa316-221c-498c-96ce-5bc1e7cb63af"
}
```

### 응답 예시 {#example-response}

서버는 구조화된 모델 응답으로 응답합니다. 예를 들어:

```python
Response: ModelResponse(
    id='chatcmpl-5d16ad41-c130-4e33-a71e-1c392741bcb9',
    choices=[
        Choices(
            finish_reason='stop',
            index=0,
            message=Message(
                content=' Here is the corrected Ruby code for your function:\n\n```ruby\ndef say_hello\n  puts "Hello, World!"\nend\n\ndef say_goodbye\n    puts "Goodbye, World!"\nend\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain\n```\n\nIn your original code, the method names were misspelled as `say_hell` and `say_gobdye`. I corrected them to `say_hello` and `say_goodbye`. Also, there was no need for the prefix',
                role='assistant',
                tool_calls=None,
                function_call=None
            )
        )
    ],
    created=1728983827,
    model='mistral',
    object='chat.completion',
    system_fingerprint=None,
    usage=Usage(
        completion_tokens=128,
        prompt_tokens=69,
        total_tokens=197,
        completion_tokens_details=None,
        prompt_tokens_details=None
    )
)
```

### 추론 서비스 제공자의 로그 {#logs-in-your-inference-service-provider}

GitLab은 추론 서비스 제공자가 생성한 로그를 관리하지 않습니다. 추론 서비스 제공자의 설명서에서 로그 사용 방법을 확인하세요.

## GitLab 및 AI Gateway 환경의 로깅 동작 {#logging-behavior-in-gitlab-and-ai-gateway-environments}

GitLab은 `llm.log`의 사용을 통해 AI 관련 활동에 대한 로깅 기능을 제공하며, 이는 입력, 출력 및 기타 관련 정보를 캡처합니다. 그러나 로깅 동작은 GitLab 인스턴스 및 AI Gateway가 **self-hosted**인지 **cloud-connected**인지에 따라 다릅니다.

기본적으로 로그에는 AI 기능 데이터의 [데이터 보존 정책](../../user/gitlab_duo/data_usage.md#data-retention)을 지원하기 위해 LLM 프롬프트 입력 및 응답 출력이 포함되지 않습니다.

## 로깅 시나리오 {#logging-scenarios}

### GitLab Self-Managed 및 자체 호스팅 AI Gateway {#gitlab-self-managed-and-self-hosted-ai-gateway}

이 구성에서 GitLab 및 AI Gateway는 모두 고객이 호스팅합니다.

- **Logging Behavior**:  전체 로깅이 활성화되고 모든 프롬프트, 입력 및 출력이 인스턴스의 `llm.log`로 로깅됩니다.
- **사용량 데이터 수집**이 활성화되면 다음을 포함한 추가 디버깅 정보가 로깅됩니다:
  - 전처리된 프롬프트.
  - 최종 프롬프트.
  - 추가 컨텍스트.
- **개인정보**:  GitLab 및 AI Gateway가 모두 자체 호스팅되므로:
  - 고객은 데이터 처리에 완전한 제어권을 가집니다.
  - 민감한 정보의 로깅은 고객의 재량에 따라 활성화 또는 비활성화될 수 있습니다.

  > [!note]
  > AI 기능이 GitLab 관리 모델을 사용하는 경우 데이터 수집이 활성화되어 있어도 GitLab 관리 AI Gateway에서 자세한 로그가 생성되지 않습니다. 이는 민감한 정보의 의도하지 않은 유출을 방지합니다.

### GitLab Self-Managed 및 GitLab 관리 AI Gateway(클라우드 연결) {#gitlab-self-managed-and-gitlab-managed-ai-gateway-cloud-connected}

이 시나리오에서 고객은 GitLab을 호스팅하지만 AI 처리를 위해 GitLab 관리 AI Gateway에 의존합니다.

- 로깅 동작:  클라우드 연결 AI Gateway를 사용할 때 GitLab이 AI 프롬프트 및 응답 데이터를 처리하는 방법에 대한 정보는 [GitLab Duo 데이터 사용](../../user/gitlab_duo/data_usage.md#data-retention)을 참조하세요.
- 확장 로깅:  **사용량 데이터 수집**이 활성화되어 있어도 민감한 정보의 의도하지 않은 유출을 피하기 위해 GitLab 관리 AI Gateway에서 자세한 로그가 생성되지 않습니다.
  - 로깅은 이 설정에서 최소한으로 유지되며 확장 로깅 기능은 기본적으로 비활성화됩니다.
- 개인정보:  이 구성은 민감한 데이터가 클라우드 환경에서 로깅되지 않도록 보장하도록 설계되었습니다.

## 클라우드 연결 AI Gateway의 로깅 {#logging-in-cloud-connected-ai-gateways}

클라우드 연결 AI Gateway를 사용할 때 GitLab이 AI 프롬프트 및 응답 데이터를 처리하는 방법에 대한 정보는 [GitLab Duo 데이터 사용](../../user/gitlab_duo/data_usage.md#data-retention)을 참조하세요.

## AI Gateway와 GitLab 간 로그의 상호 참조 {#cross-referencing-logs-between-the-ai-gateway-and-gitlab}

`correlation_id` 속성은 모든 요청에 할당되고 요청에 응답하는 다양한 구성 요소 간에 전달됩니다. 자세한 내용은 [상관 ID로 로그를 찾는 방법에 대한 설명서](../logs/tracing_correlation_id.md)를 참조하세요.

상관 ID는 AI Gateway 및 GitLab 로그에서 찾을 수 있습니다. 그러나 모델 제공자 로그에는 없습니다.

### 관련 항목 {#related-topics}

- [jq를 사용하여 GitLab 로그 구문 분석](../logs/log_parsing.md)
- [상관 ID의 로그 검색](../logs/tracing_correlation_id.md#searching-your-logs-for-the-correlation-id)
