---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Chat 문제 해결
---

GitLab Duo Chat를 사용할 때 다음 문제가 발생할 수 있습니다.

## **GitLab Duo Chat** 버튼이 표시되지 않음 {#the-gitlab-duo-chat-button-is-not-displayed}

버튼이 UI의 오른쪽 위에 표시되지 않으면 GitLab Duo Chat이 [활성화](../gitlab_duo/turn_on_off.md)되어 있는지 확인합니다.

**GitLab Duo Chat** 버튼은 [GitLab Duo 기능이 비활성화된 그룹 및 프로젝트](../gitlab_duo/turn_on_off.md)에서 표시되지 않습니다.

GitLab Duo Chat을 활성화한 후 버튼이 표시되는 데 몇 분이 걸릴 수 있습니다.

이것이 작동하지 않으면 다음 문제 해결 설명서를 확인할 수 있습니다:

- [GitLab Duo 코드 제안](../project/repository/code_suggestions/troubleshooting.md).
- [VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md).
- [Microsoft Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md).
- [JetBrains IDE](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md).
- [Neovim](../../editor_extensions/neovim/neovim_troubleshooting.md).
- [Eclipse](../../editor_extensions/eclipse/troubleshooting.md).
- [GitLab Duo 문제 해결](../gitlab_duo/troubleshooting.md).
- [GitLab Duo Self-Hosted 문제 해결](../../administration/gitlab_duo_self_hosted/troubleshooting.md).

## `Error M2000` {#error-m2000}

`I'm sorry, I couldn't find any documentation to answer your question. Error code: M2000`라는 오류가 표시될 수 있습니다.

이 오류는 Chat이 질문에 답변할 관련 설명서를 찾을 수 없을 때 발생합니다. 검색 쿼리가 사용 가능한 문서와 일치하지 않거나 문서 검색 기능에 문제가 있을 수 있습니다.

다시 시도하거나 [GitLab Duo Chat 모범 사례 설명서](best_practices.md)를 참조하여 질문을 개선하세요.

## `Error M3002` {#error-m3002}

`I am sorry, I cannot access the information you are asking about. A group or project owner has turned off Duo features in this group or project. Error code: M3002`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo가 [꺼져 있는](../gitlab_duo/turn_on_off.md) 프로젝트 또는 그룹에 속한 항목을 묻는 경우에 발생합니다.

GitLab Duo이 켜져 있지 않으면 그룹 또는 프로젝트의 항목(예: 이슈, 에픽 및 머지 리퀘스트)에 대한 정보를 GitLab Duo Chat에서 처리할 수 없습니다.

## `Error M3003` {#error-m3003}

`I'm sorry, I can't generate a response. You might want to try again. You could also be getting this error because the items you're asking about either don't exist, you don't have access to them, or your session has expired. Error code: M3003`라는 오류가 표시될 수 있습니다.

이 오류는 다음과 같은 경우에 발생합니다:

- 액세스할 수 없는 항목(예: 이슈, 에픽 및 머지 리퀘스트) 또는 존재하지 않는 항목에 대해 GitLab Duo Chat에 묻습니다.
- 세션이 만료되었습니다.

다시 시도하면서 액세스할 수 있는 항목을 물어봅니다. 계속 문제가 발생하면 세션이 만료되었을 수 있습니다. GitLab Duo Chat을 계속 사용하려면 다시 로그인합니다. 자세한 내용은 [GitLab Duo 가용성 제어](../gitlab_duo/turn_on_off.md)를 참조하세요.

## `Error M3004` {#error-m3004}

`I'm sorry, I can't generate a response. You do not have access to GitLab Duo Chat. Error code: M3004`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo Chat에 액세스하려고 하지만 필요한 액세스 권한이 없을 때 발생합니다.

[GitLab Duo Chat을 사용할 액세스 권한](../gitlab_duo/turn_on_off.md)이 있는지 확인합니다.

## `Error M3005` {#error-m3005}

`I'm sorry, this question is not supported in your Duo Pro subscription. You might consider upgrading to Duo Enterprise. Error code: M3005`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo 구독 티어에 포함되지 않은 GitLab Duo Chat 도구에 액세스하려고 할 때 발생합니다.

[GitLab Duo 구독 티어](https://about.gitlab.com/gitlab-duo/#pricing)에 선택한 도구가 포함되어 있는지 확인합니다.

## `Error M3006` {#error-m3006}

`I'm sorry, you don't have the GitLab Duo subscription required to use Duo Chat. Please contact your administrator. Error code: M3006`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo 구독에 GitLab Duo Chat이 포함되지 않을 때 발생합니다.

[GitLab Duo 구독 티어](https://about.gitlab.com/gitlab-duo/#pricing)에 GitLab Duo Chat이 포함되어 있는지 확인합니다.

구독 티어에 이미 GitLab Duo Chat이 포함되어 있지만 여전히 이 오류가 표시되면 사용자 환경설정에서 [기본 GitLab Duo 네임스페이스](../profile/preferences.md#set-a-default-gitlab-duo-namespace)를 선택했는지 확인합니다. 기본 GitLab Duo 네임스페이스를 구성하지 않으면 [오류 G3002](#error-g3002) 대신 오류 M3006을 만날 수 있습니다.

## `Error M4000` {#error-m4000}

`I'm sorry, I can't generate a response. Please try again. Error code: M4000`라는 오류가 표시될 수 있습니다.

이 오류는 슬래시 명령 요청 처리 중 예상치 못한 문제가 발생할 때 발생합니다. 요청을 다시 시도합니다. 문제가 지속되면 명령의 구문이 올바른지 확인합니다.

슬래시 명령에 대한 자세한 내용은 설명서를 참조하세요:

- [/tests](examples.md#write-tests-in-the-ide)
- [/refactor](examples.md#refactor-code-in-the-ide)
- [/fix](examples.md#fix-code-in-the-ide)
- [/explain](examples.md#explain-selected-code)

## `Error M4001` {#error-m4001}

`I'm sorry, I can't generate a response. Please try again. Error code: M4001`라는 오류가 표시될 수 있습니다.

이 오류는 요청을 완료하기 위해 필요한 정보를 찾는 데 문제가 있을 때 발생합니다. 요청을 다시 시도합니다.

## `Error M4002` {#error-m4002}

`I'm sorry, I can't generate a response. Please try again. Error code: M4002`라는 오류가 표시될 수 있습니다.

이 오류는 [CI/CD 관련 질문](examples.md#ask-about-cicd)에 답변하는 데 문제가 있을 때 발생합니다. 요청을 다시 시도합니다.

## `Error M4003` {#error-m4003}

`This command is used for explaining vulnerabilities and can only be invoked from a vulnerability detail page.` 또는 `Vulnerability Explanation currently only supports vulnerabilities reported by SAST. Error code: M4003`를 명시하는 오류가 발생할 수 있습니다.

이 오류는 [`Explain Vulnerability`](examples.md#explain-a-vulnerability) 기능을 사용할 때 문제가 있을 때 발생합니다.

## `Error M4004` {#error-m4004}

`This resource has no comments to summarize`라는 오류가 표시될 수 있습니다.

이 오류는 `Summarize Discussion` 기능을 사용할 때 문제가 있을 때 발생합니다.

## `Error M4005` {#error-m4005}

`There is no job log to troubleshoot.` 또는 `This command is used for troubleshooting jobs and can only be invoked from a failed job log page.`를 명시하는 오류가 발생할 수 있습니다.

이 오류는 [`Troubleshoot job`](examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) 기능을 사용할 때 문제가 있을 때 발생합니다.

## `Error M5000` {#error-m5000}

`I'm sorry, I can't generate a response. Please try again. Error code: M5000`라는 오류가 표시될 수 있습니다.

이 오류는 항목(예: 이슈, 에픽 및 머지 리퀘스트)과 관련된 콘텐츠 처리 중 문제가 있을 때 발생합니다. 요청을 다시 시도합니다.

## `Error A1000` {#error-a1000}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`라는 오류가 표시될 수 있습니다.

이 오류는 처리 중 시간 초과가 발생할 때 발생합니다. 요청을 다시 시도합니다.

## `Error A1001` {#error-a1001}

`I'm sorry, I can't generate a response. Please try again. Error code: A1001`라는 오류가 표시될 수 있습니다.

이 오류 메시지는 요청을 처리한 AI 서비스에서 문제가 발생했음을 의미합니다.

가능한 몇 가지 이유:

- GitLab 코드의 버그로 인한 클라이언트 측 오류입니다.
- Anthropic 코드의 버그로 인한 서버 측 오류입니다.
- AI 게이트웨이에 도달하지 못한 HTTP 요청입니다.

[오류의 이유를 더 명확하게 지정하기 위해 이슈가 존재합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/479465).

문제를 해결하려면 요청을 다시 시도합니다.

오류가 지속되면 `/new` 또는 `/reset` 명령을 사용하여 새 대화를 시작합니다. 문제가 계속되면 GitLab 지원 팀에 문제를 보고합니다.

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

GitLab Duo Self-Hosted에서 Chat을 사용할 때 이 오류가 발생하면 AI 게이트웨이에 연결하는 데 문제가 있었습니다.

이를 해결하려면 [셀프 호스팅 디버깅 스크립트](../../administration/gitlab_duo_self_hosted/troubleshooting.md#use-debugging-scripts)를 사용하여 AI 게이트웨이가 GitLab 인스턴스에서 액세스 가능하고 예상대로 작동하는지 확인합니다.

문제가 지속되면 GitLab 지원 팀에 문제를 보고합니다.

## `Error A1002` {#error-a1002}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1002`라는 오류가 표시될 수 있습니다.

이 오류는 AI 게이트웨이에서 반환된 이벤트가 없거나 GitLab이 이벤트를 구문 분석하지 못했을 때 발생합니다.

요청을 다시 시도하거나 오류가 있는지 [AI 게이트웨이 로그](../../administration/gitlab_duo_self_hosted/logging.md)를 확인합니다.

## `Error A1003` {#error-a1003}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1003`라는 오류가 표시될 수 있습니다.

이 오류는 AI 게이트웨이의 스트리밍 응답이 실패했을 때 발생합니다. 요청을 다시 시도합니다.

오류 없이 긴 응답이 중간에 멈추면 프록시, 로드 밸런서 또는 방화벽이 연결을 끊었을 수 있습니다. 자세한 정보는 다음을 참조하세요.

- [GitLab 인스턴스에서 GitLab Duo로의 아웃바운드 연결 허용](../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo).
- GitLab Duo Self-Hosted의 경우 [오류 없이 응답이 잘렸습니다](../../administration/gitlab_duo_self_hosted/troubleshooting.md#responses-are-truncated-without-an-error).

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted-1}

GitLab Duo Self-Hosted에서 Chat을 사용할 때 이 문제가 발생하면 스트리밍이 작동하는지 확인합니다:

1. AI 게이트웨이 컨테이너에서 다음 명령을 실행합니다:

   ```shell
   curl --request 'POST' \
   'http://localhost:5052/v2/chat/agent' \
   --header 'accept: application/json' \
   --header 'Content-Type: application/json' \
   --header 'x-gitlab-enabled-feature-flags: expanded_ai_logging' \
   --data '{
     "messages": [
       {
         "role": "user",
         "content": "Hello",
         "context": null,
         "current_file": null,
         "additional_context": []
       }
     ],
     "model_metadata": {
       "provider": "custom_openai",
       "name": "mistral",
       "endpoint": "<change here>",
       "api_key": "<change here>",
       "identifier": "<change here>"
     },
     "unavailable_resources": [],
     "options": {
       "agent_scratchpad": {
         "agent_type": "react",
         "steps": []
       }
     }
   }'
   ```

   스트리밍이 작동하면 청크된 응답이 표시됩니다. 작동하지 않으면 응답이 비워집니다.

1. 이것이 모델 배포 문제인지 확인하려면 특정 오류 메시지에 대해 [AI 게이트웨이 로그](../../administration/gitlab_duo_self_hosted/logging.md)를 확인합니다.

1. 연결을 검증하려면 AI 게이트웨이 컨테이너에서 `AIGW_CUSTOM_MODELS__DISABLE_STREAMING` 환경 변수를 설정하여 스트리밍을 비활성화합니다:

   ```shell
   docker run .... -e AIGW_CUSTOM_MODELS__DISABLE_STREAMING=true ...
   ```

## `Error A1004` {#error-a1004}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1004`라는 오류가 표시될 수 있습니다.

이 오류는 AI 게이트웨이 프로세스에서 오류가 발생했을 때 발생합니다. 요청을 다시 시도합니다.

## `Error A1005` {#error-a1005}

`I'm sorry, you've entered too many prompts. Please run /clear or /reset before asking the next question. Error code: A1005`라는 오류가 표시될 수 있습니다.

이 오류는 프롬프트의 길이가 LLM의 최대 토큰 제한을 초과할 때 발생합니다. `/new` 명령으로 새 대화를 시작하고 요청을 다시 시도합니다.

## `Error A1006` {#error-a1006}

`I'm sorry, Duo Chat agent reached the limit before finding an answer for your question. Please try a different prompt or clear your conversation history with /clear. Error code: A1006`라는 오류가 표시될 수 있습니다.

이 오류는 ReAct 에이전트가 쿼리에 대한 솔루션을 찾지 못했을 때 발생합니다. 다른 프롬프트를 시도하거나 `/new` 또는 `/reset`로 새 대화를 시작합니다.

## `Error A1007` {#error-a1007}

`There was an error processing your request. Please try again or contact support if the issue persists. Error code: A1007`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo 에이전트 플랫폼에서 요청을 처리하는 중 예상치 못한 오류가 발생했을 때 발생합니다.

## `Error A1008` {#error-a1008}

`There was an error processing your request. Please try again or contact support if the issue persists. Error code: A1008`라는 오류가 표시될 수 있습니다.

이 오류는 요청이 GitLab Duo 에이전트 플랫폼에서 사용하는 업스트림 LLM 제공자에게 제출되었을 때 발생합니다.

## `Error A6000` {#error-a6000}

`I'm sorry, I couldn't respond in time. Please try a more specific request or enter /clear to start a new chat. Error code: A6000`라는 오류가 표시될 수 있습니다.

이것은 GitLab Duo Chat에 문제가 있을 때 발생하는 폴백 오류입니다. 더 구체적인 요청을 시도하거나 `/new`을 입력하여 새 Chat을 시작하거나 피드백을 남겨 개선하도록 도와주세요.

## `Error A9999` {#error-a9999}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A9999`라는 오류가 표시될 수 있습니다.

이 오류는 ReAct 에이전트에서 알 수 없는 오류가 발생할 때 발생합니다. 요청을 다시 시도합니다.

문제가 계속되면 [GitLab 지원 팀에 문제를 보고합니다](https://support.gitlab.com/).

## `Error G3001` {#error-g3001}

`I'm sorry, but answering this question requires a different Duo subscription. Please contact your administrator.`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo Chat을 구독에서 사용할 수 없을 때 발생합니다. 다른 요청을 시도하고 관리자에게 문의합니다.

## `Error G3002` {#error-g3002}

`I'm sorry, you have not selected a default GitLab Duo namespace. Please select a default GitLab Duo namespace in your user preferences.`라는 오류가 표시될 수 있습니다.

이 오류는 여러 GitLab Duo 네임스페이스에 속하거나 GitLab 원격이 구성되지 않은 로컬 프로젝트에서 작업할 때 발생합니다.

이 문제를 해결하려면 [기본 GitLab Duo 네임스페이스를 설정](../profile/preferences.md#set-a-default-gitlab-duo-namespace)하세요.

## Chat 응답의 링크를 선택할 수 없음 {#links-in-chat-responses-are-not-selectable}

GitLab Duo Chat은 외부 웹 사이트 및 타사 도메인의 URL을 응답에서 선택 가능한 링크로 표시하지 않습니다.

Chat은 대신 이러한 유형의 URL을 링크 텍스트만 표시하는 코드 형식의 텍스트로 변환합니다. 대상 URL이 표시되지 않습니다.

이 제한은 AI 응답에서 생성될 수 있는 잠재적으로 악의적인 링크로부터 사용자를 보호하는 데 도움이 됩니다.

Chat은 다음 유형의 링크를 응답에서 선택 가능한 것으로 표시합니다:

- `docs.gitlab.com`에서 GitLab 설명서로의 링크.
- `gitlab.com`로의 링크(GitLab 프로젝트, 이슈 및 머지 리퀘스트 포함 제한 없음).
- GitLab 인스턴스의 상대 URL.

## GitLab Duo Agentic Chat 관련 문제 {#issues-specific-to-gitlab-duo-agentic-chat}

### GitLab Credits 부족 {#not-enough-gitlab-credits}

GitLab Credits가 부족하면 Chat에 액세스할 수 없을 수 있습니다.

이 문제를 해결하려면 다음 중 하나를 수행할 수 있습니다:

- [더 많은 GitLab Credits 구매](../../subscriptions/gitlab_credits.md#buy-gitlab-credits).
- 비-에이전트 Chat으로 전환합니다. 전환하면 새 대화가 시작됩니다. 이전 에이전트 Chat 대화를 계속 볼 수 있지만 읽기 전용입니다.

### 응답 시간 늦음 {#slow-response-times}

Agentic Chat은 요청을 처리하고 응답하는 데 비-에이전트 Chat보다 느릴 수 있습니다.

이 문제는 에이전트 Chat이 정보를 수집하기 위해 여러 API 호출을 수행하기 때문에 응답이 훨씬 더 오래 걸릴 수 있습니다.

### 제한된 권한 {#limited-permissions}

Agentic Chat은 GitLab 사용자가 액세스할 수 있는 권한이 있는 동일한 리소스에 액세스할 수 있습니다. 에이전트 Chat이 요청에 답변하기 위해 필요한 리소스에 액세스할 수 없는 경우 [사용자 권한](../permissions.md)을 확인합니다.

### 검색 제한 {#search-limitations}

Agentic Chat은 의미론적 검색 대신 키워드 기반 검색을 사용합니다. Agentic Chat은 검색에 사용된 정확한 키워드를 포함하지 않는 관련 콘텐츠를 놓칠 수 있습니다.

## 헤더 불일치 문제 {#header-mismatch-issue}

`I'm sorry, I can't generate a response. Please try again`을 명시하는 오류가 발생할 수 있으며, 특정 오류 코드가 없습니다.

Sidekiq 로그를 확인하여 다음 오류가 있는지 확인합니다: `Header mismatch 'X-Gitlab-Instance-Id'`.

이 오류가 표시되면 이를 해결하기 위해 GitLab 지원 팀에 연락하여 라이선스에 대한 새 정품 인증 코드를 보내달라고 요청합니다.

자세한 내용은 [이슈 103](https://gitlab.com/gitlab-com/enablement-sub-department/section-enable-request-for-help/-/issues/103)을 참조하세요.

## Cloud Connector의 상태 확인 {#check-the-health-of-the-cloud-connector}

Cloud Connector와 관련된 다양한 구성 요소의 상태를 확인하는 스크립트를 만들었습니다(예:

- 액세스 데이터
- 토큰
- 라이선스
- 호스트 연결
- 기능 접근성

더 자세한 출력을 위해 디버그 모드에서 이 스크립트를 실행하고 보고서 파일을 생성할 수 있습니다.

1. 단일 노드 인스턴스에 SSH로 접속하여 스크립트를 다운로드합니다:

   ```shell
   wget https://gitlab.com/gitlab-org/gitlab/-/snippets/3734617/raw/main/health_check.rb
   ```

1. Rails Runner를 사용하여 스크립트를 실행합니다.

   스크립트의 전체 경로를 사용해야 합니다.

   ```ruby
   Usage: gitlab-rails runner full_path/to/health_check.rb
          --debug                     Enable debug mode
          --output-file <file_path>   Write a report to a specified file
          --username <username>       Provide a username to test seat assignments
          --skip [CHECK]              Skip specific checks (options: access_data, token, license, host, features, end_to_end)
   ```
