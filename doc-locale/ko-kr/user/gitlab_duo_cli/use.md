---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo CLI를 대화형 및 헤드리스 모드에서 사용합니다.
title: GitLab Duo CLI 사용
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 설정된 [기본 GitLab Duo 네임스페이스](../profile/preferences.md#namespace-resolution-in-your-local-environment) 또는 GitLab Duo 액세스 권한이 있는 열린 프로젝트입니다.

GitLab Duo CLI는 두 가지 모드에서 사용할 수 있습니다:

- 대화형 모드:  GitLab UI 또는 편집기 확장 프로그램의 GitLab Duo Chat과 유사한 채팅 환경을 제공합니다. 빌드 및 플랜 모드를 지원합니다.
- 헤드리스 모드: 러너, 스크립트 및 기타 자동화된 워크플로우에서 비대화형 사용을 활성화합니다.

## 대화형 모드 {#interactive-mode}

GitLab Duo CLI를 대화형 모드로 사용하려면:

1. 설정을 기준으로 대화형 모드를 시작하는 명령을 입력합니다.

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 프롬프트 `>`이 터미널 창에 나타납니다. 프롬프트 뒤에 질문이나 요청을 입력한 다음 <kbd>Enter</kbd>를 누릅니다.

   예를 들어:

   ```plaintext
   What is this repository about?

   Which issues need my attention?

   Help me implement issue 15.

   The pipelines in MR 23 are failing. Please help me fix them.
   ```

GitLab Duo CLI가 작동 중일 때 응답을 취소하려면 <kbd>Escape</kbd>를 누릅니다. GitLab Duo CLI는 현재 작업을 중지하고 프롬프트로 돌아갑니다.

<kbd>↑</kbd> 키를 사용하여 프롬프트 기록을 보거나 <kbd>Control</kbd>+<kbd>R</kbd>을 사용하여 검색합니다.

### 빌드 및 플랜 모드 간 전환 {#switch-between-build-and-plan-modes}

대화형 모드에서는 작업하면서 GitLab Duo CLI를 두 모드 간에 전환할 수 있습니다.

| 모드                 | 권한 | 작동 방식                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| 빌드 모드(기본값) | 읽기-쓰기  | GitLab Duo는 작업을 실행하고 프로젝트를 변경할 수 있습니다.               |
| 플랜 모드            | 읽기 전용   | GitLab Duo는 프로젝트를 분석하고 변경 사항을 만들지 않고 플랜을 생성할 수 있습니다. |

예를 들어, 플랜 모드에서 GitLab Duo와 함께 문제를 논의하면서 시작합니다. 준비되면 빌드 모드로 전환하고 GitLab Duo에 플랜을 구현하도록 지시합니다.

GitLab Duo CLI는 `>` 프롬프트 아래의 현재 모드를 표시합니다. 모드 간 전환하려면 <kbd>Tab</kbd>을 누릅니다.

### 슬래시 명령 {#slash-commands}

{{< history >}}

- GitLab 19.0 릴리스 중 `/exit` 슬래시 명령이 GitLab Duo CLI 8.88.0에 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.88.0)되었습니다.
- GitLab 19.0 릴리스 중 `/doctor` 슬래시 명령이 GitLab Duo CLI 8.94.0에 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0)되었습니다.
- GitLab 19.0 릴리스 중 `/skills` 슬래시 명령이 GitLab Duo CLI 8.81.0에 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.81.0)되었습니다.
- GitLab 19.0 릴리스 중 `/mcp` 슬래시 명령이 GitLab Duo CLI 8.95.0에 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0)되었습니다.

{{< /history >}}

대화형 모드에서는 슬래시 명령을 사용하여 GitLab Duo CLI를 구성하고 작업을 수행합니다. 프롬프트에서 슬래시 명령을 입력한 다음 <kbd>Enter</kbd>를 누릅니다.

다음 슬래시 명령을 사용할 수 있습니다.

| 명령     | 설명                                          |
|-------------|------------------------------------------------------|
| `/copy`     | 마지막 GitLab Duo 응답을 클립보드에 복사합니다.  |
| `/doctor`   | GitLab Duo CLI 환경에 대한 진단을 표시합니다. |
| `/exit`     | GitLab Duo CLI를 종료합니다.                             |
| `/feedback` | 버그 보고서 또는 기능 요청을 제출합니다.              |
| `/help`     | 사용 가능한 슬래시 명령의 목록을 표시합니다.          |
| `/mcp`      | 구성된 MCP 서버 및 상태를 확인합니다.        |
| `/model`    | 현재 세션에 대한 AI 모델을 전환합니다.         |
| `/new`      | 새 채팅 세션을 시작합니다.                            |
| `/sessions` | 세션을 검색, 검색 및 전환합니다.                 |
| `/settings` | 설정 패널을 엽니다.                             |
| `/skills`   | 현재 프로젝트에서 사용 가능한 Agent Skills를 나열합니다.  |

또한 고유한 슬래시 명령을 생성할 수 있습니다. 자세한 내용은 [사용자 정의 슬래시 명령](customize.md#custom-slash-commands)을 참조하세요.

### 설정 {#settings}

{{< history >}}

- GitLab 19.0 릴리스 중 설정 패널이 GitLab Duo CLI 8.90.0에 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0)되었습니다.

{{< /history >}}

설정을 변경하려면:

1. 대화형 모드에서 `/settings`을 입력하고 <kbd>Enter</kbd>를 누릅니다.
1. 화살표 키를 사용하여 설정 목록을 탐색합니다.
1. 선택한 설정을 변경하려면 <kbd>Enter</kbd> 또는 <kbd>Space</kbd>를 누릅니다.
1. 패널을 닫으려면 <kbd>Escape</kbd>를 누릅니다.

변경 사항은 세션 전체에 유지됩니다.

다음 설정을 사용할 수 있습니다.

| 설정                  | 설명                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Telemetry**            | GitLab Duo를 개선하기 위해 익명의 사용 데이터를 보냅니다.                                                  |
| **Enable global skills** | (실험) [사용자 수준 Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills)를 `~/.agents/skills/` 및 `~/.gitlab/duo/skills/`에서 검색합니다. 변경 사항이 적용되려면 다시 시작이 필요합니다. |
| **알림**        | [시스템 알림](#system-notifications)을 제어합니다(`auto` 또는 `disabled`).                     |

### 시스템 알림 {#system-notifications}

{{< history >}}

- GitLab 19.1 릴리스 중 시스템 알림이 GitLab Duo CLI 8.105.0에 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0)되었습니다.

{{< /history >}}

GitLab Duo CLI는 세션에 주의가 필요한 경우(예: 작업을 완료했거나 도구 승인이 필요한 경우) 터미널 창이 포커스되지 않은 상태에서 시스템 알림을 보낼 수 있습니다.

**알림**은 [설정 패널](#settings)의 설정으로 제어됩니다.

- `auto`(기본값): 터미널이 포커스되지 않으면 시스템 알림을 보냅니다.
- `disabled`: 시스템 알림을 보내지 않습니다.

### 도구 승인 {#tool-approvals}

{{< history >}}

- GitLab 19.0에서 세션에 대한 승인 도구 옵션이 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2129)되었습니다.
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0에 되었습니다.
- 패턴 기반 도구 승인이 GitLab 19.1에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/21850)되었습니다.
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0) 8.101.0에서 도입되었습니다.
- 패턴 기반 도구 승인이 2026년 7월 10일에 [제거](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3699)되었습니다.
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.3.0) 9.3.0에서 제거되었습니다.

{{< /history >}}

GitLab Duo가 도구를 사용해야 할 때 시작하기 전에 승인을 위해 프롬프트합니다. 예를 들어 파일을 읽거나 명령을 실행해야 할 때입니다.

옵션은 다음과 같습니다.

- **승인**: GitLab Duo는 도구를 한 번 사용할 수 있습니다.
- **세션에 대해 승인**: GitLab Duo는 세션의 나머지 기간 동안 이러한 인수로 도구를 사용할 수 있습니다. 다른 인수는 추가 승인이 필요합니다.
- **거부**: GitLab Duo는 도구를 사용할 수 없습니다.

> [!note]
> **세션에 대해 승인** 옵션을 사용하려면 관리자가 그룹 또는 인스턴스에 대해 이를 활성화해야 합니다. 자세한 내용은 [도구 승인](../gitlab_duo_chat/agentic_chat.md#tool-approvals)을 참조하세요.

## 헤드리스 모드 {#headless-mode}

> [!caution]
> 헤드리스 모드는 신중하게 사용하고 제어된 [샌드박스 환경](../../editor_extensions/security_considerations.md#use-development-containers-for-isolation)에서 사용하십시오.

비대화형 모드에서 워크플로우를 실행하려면 설정에 맞는 명령을 사용합니다.

{{< tabs >}}

{{< tab title="glab" >}}

`glab duo cli run`를 사용합니다.

```shell
glab duo cli run --goal "Your goal or prompt here"
```

예를 들어 ESLint 명령을 실행하고 오류를 GitLab Duo CLI로 파이프하여 해결할 수 있습니다.

```shell
glab duo cli run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< tab title="duo" >}}

`duo run`를 사용합니다.

```shell
duo run --goal "Your goal or prompt here"
```

예를 들어 ESLint 명령을 실행하고 오류를 GitLab Duo CLI로 파이프하여 해결할 수 있습니다.

```shell
duo run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< /tabs >}}

헤드리스 모드를 사용할 때 GitLab Duo CLI:

- 수동 도구 승인을 우회하고 모든 도구를 사용하도록 자동으로 승인합니다.
- 이전 대화의 컨텍스트를 유지하지 않습니다. `run` 명령을 실행할 때마다 새 워크플로우가 시작됩니다.

## 모델 선택 {#select-a-model}

{{< history >}}

- GitLab 18.10 릴리스 중 GitLab Duo CLI 8.68.0에서 모델 선택 옵션 및 환경 변수가 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0)되었습니다.
- GitLab 18.10 릴리스 중 GitLab Duo CLI 8.76.0에서 모델 선택 슬래시 명령이 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0)되었습니다.

{{< /history >}}

대화형 모드 또는 헤드리스 모드에 대해 모델을 선택할 수 있습니다.

### 대화형 모드의 경우 {#for-interactive-mode}

선택한 모델은 세션 전체에 유지되며 컨텍스트를 잃지 않고 대화 중에 모델을 전환할 수 있습니다.

전제 조건:

- GitLab Duo CLI 8.76.0 이상.

대화형 모드에 대해 모델을 선택하려면:

1. 대화형 모드에서 `/model`을 입력하고 <kbd>Enter</kbd>를 누릅니다.
1. 화살표 키를 사용하여 사용 가능한 모델 목록을 스크롤하거나 모델 이름을 입력하여 목록을 필터링합니다.
1. 모델을 선택하고 <kbd>Enter</kbd>를 눌러 전환합니다.

### 헤드리스 모드의 경우 {#for-headless-mode}

선택한 모델은 세션 전체에 유지되지 않습니다.

전제 조건:

- GitLab Duo CLI 8.68.0 이상.

헤드리스 모드에 대해 모델을 선택하려면:

1. 모델에 대한 [`gitlab_identifier`를 찾습니다](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml).
1. GitLab Duo CLI를 실행할 때 `--model` 옵션 또는 `GITLAB_DUO_MODEL` 환경 변수를 `gitlab_identifier` 값으로 설정합니다.

   {{< tabs >}}

   {{< tab title="glab" >}}

   `--model` 옵션을 사용합니다.

   ```shell
   glab duo cli --model <gitlab_identifier_for_the_model>
   ```

   `GITLAB_DUO_MODEL` 환경 변수를 사용합니다.

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> glab duo cli
   ```

   예를 들어 [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448)를 사용하려면:

   ```shell
   glab duo cli --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   `--model` 옵션을 사용합니다.

   ```shell
   duo --model <gitlab_identifier_for_the_model>
   ```

   `GITLAB_DUO_MODEL` 환경 변수를 사용합니다.

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> duo
   ```

   예를 들어 [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448)를 사용하려면:

   ```shell
   duo --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

## 세션 전환 {#switch-sessions}

GitLab Duo Chat 세션은 대화 기록과 워크플로우 데이터를 저장하며 GitLab Duo CLI, GitLab UI 및 편집기 확장 프로그램 전체에서 공유됩니다.

예를 들어, 브라우저에서 대화를 시작하고 터미널에서 계속할 수 있습니다.

세션을 검색하고 전환하려면:

1. 대화형 모드에서 `/sessions`을 입력하고 <kbd>Enter</kbd>를 누릅니다.
1. 화살표 키를 사용하여 사용 가능한 세션 목록을 스크롤하거나 텍스트를 입력하여 목록을 필터링합니다.
1. 세션을 선택하고 <kbd>Enter</kbd>를 누릅니다.

헤드리스 모드에서 세션으로 전환하려면 `--existing-session-id` 옵션을 사용합니다.

## 모델 컨텍스트 프로토콜(MCP) 연결 {#model-context-protocol-mcp-connections}

GitLab Duo CLI를 로컬 또는 원격 MCP 서버에 연결하려면 GitLab IDE 확장 프로그램과 동일한 MCP 구성을 사용합니다. 지침은 [MCP 서버 구성](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers)을 참조하세요.

## 관련 항목 {#related-topics}

- [GitLab Duo CLI 완전 참조](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [편집기 확장 프로그램의 보안 고려 사항](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [GitLab Duo Agent Platform 사용자 정의](../duo_agent_platform/customize/_index.md)
- [GitLab Duo Agent Platform 세션](../duo_agent_platform/sessions/_index.md)

## 문제 해결 {#troubleshooting}

GitLab Duo CLI로 작업할 때 다음과 같은 문제가 발생할 수 있습니다.

### 인증서 오류 {#certificate-errors}

인증서 오류가 발생할 수 있습니다:

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

조직에서 HTTPS 가로채기 프록시 또는 유사한 용도로 사용자 지정 CA(인증 기관)를 사용하는 경우 이러한 오류가 발생합니다.

인증서 오류를 해결하려면 다음 방법 중 하나를 사용합니다.

- 시스템 인증서 저장소를 사용합니다(권장):
  1. CA 인증서가 운영 체제의 인증서 저장소에 설치되어 있으면 Node.js를 구성하여 사용합니다. Node.js 22.15.0, 23.9.0, 24.0.0 이상이 필요합니다.
  1. GitLab Duo CLI를 컨테이너에서 실행하는 경우 호스트 시스템 저장소가 아닌 컨테이너의 시스템 저장소에 CA 인증서를 설치합니다.

     ```shell
     export NODE_OPTIONS="--use-system-ca"
     ```

- CA 인증서 파일을 지정합니다.
  1. 이전 Node.js 버전이거나 CA 인증서가 시스템 저장소에 없는 경우 Node.js를 인증서 파일로 직접 가리킵니다. 파일은 PEM 형식이어야 합니다.
  1. GitLab Duo CLI를 컨테이너에서 실행하는 경우 경로를 컨테이너의 위치로 설정합니다. 볼륨 마운트를 사용하여 인증서 파일을 제공합니다.

     ```shell
     export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
     ```

### 인증서 오류 무시 {#ignore-certificate-errors}

여전히 인증서 오류가 발생하면 인증서 검증을 비활성화할 수 있습니다.

> [!warning]
> 인증서 검증을 비활성화하는 것은 보안 위험입니다. 프로덕션 환경에서 검증을 비활성화하면 안 됩니다.

인증서 오류는 잠재적 보안 침해를 경고하므로, 인증서 검증을 비활성화하는 것이 안전하다고 확신할 때만 인증서 검증을 비활성화해야 합니다.

전제 조건:

- 브라우저에서 인증서 체인을 확인했거나 관리자가 이 오류를 무시해도 안전하다고 확인했습니다.

인증서 검증을 비활성화하려면:

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```
