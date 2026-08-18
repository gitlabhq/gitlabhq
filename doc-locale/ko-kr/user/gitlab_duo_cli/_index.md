---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Agent Platform을 터미널에 제공하는 명령줄 인터페이스 도구입니다.
title: GitLab Duo CLI (`duo`)
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../duo_agent_platform/model_selection.md#default-models)
- [자가 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- [실험](../../policy/development_stages_support.md#experiment)으로 GitLab 18.9에서 도입되었습니다.
- [GitLab CLI에 추가됨](https://gitlab.com/gitlab-org/cli/-/merge_requests/2838) - `glab` 1.87.0에서 실험으로 추가되었으며, GitLab 18.9 릴리스 중입니다.
- GitLab Duo CLI 8.68.0에서 모델 선택 옵션 및 환경 변수 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0) \- GitLab 18.10 릴리스 중입니다.
- GitLab Duo CLI 8.76.0에서 모델 선택 슬래시 명령 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0) \- GitLab 18.10 릴리스 중입니다.
- GitLab 18.11에서 실험에서 베타로 [변경됨](https://gitlab.com/groups/gitlab-org/-/work_items/19716).
- 사용자 수준 Agent Skills를 활성화하는 환경 변수 및 옵션이 GitLab Duo CLI 8.83.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0) \- GitLab 19.0 릴리스 중 [실험](../../policy/development_stages_support.md#experiment)입니다.
- 세션에 대해 승인 도구 옵션이 GitLab 19.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2129).
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0에 되었습니다.
- `/exit` 슬래시 명령이 GitLab Duo CLI 8.88.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.88.0) - GitLab 19.0 릴리스 중입니다.
- `/doctor` 슬래시 명령이 GitLab Duo CLI 8.94.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0) - GitLab 19.0 릴리스 중입니다.
- `/skills` 슬래시 명령이 GitLab Duo CLI 8.81.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.81.0) - GitLab 19.0 릴리스 중입니다.
- `/mcp` 슬래시 명령이 GitLab Duo CLI 8.95.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) - GitLab 19.0 릴리스 중입니다.
- 설정 패널이 GitLab Duo CLI 8.90.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0) \- GitLab 19.0 릴리스 중입니다.
- `AI_AGENT` 환경 변수가 GitLab Duo CLI 8.95.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) - GitLab 19.0 릴리스 중입니다.
- 패턴 기반 도구 [승인](https://gitlab.com/groups/gitlab-org/-/work_items/21850)이 GitLab 19.1에서 도입되었습니다.
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0) 8.101.0에서 도입되었습니다.
- 시스템 알림이 GitLab Duo CLI 8.105.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0) \- GitLab 19.1 릴리스 중입니다.
- GitLab 19.2에서 GitLab Duo CLI 9.0.0으로 [일반 공급 시작](https://gitlab.com/groups/gitlab-org/-/work_items/19717)됨.
- 패턴 기반 도구 승인이 2026년 7월 10일에 [제거](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3699)되었습니다.
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.3.0) 9.3.0에서 제거되었습니다.

{{< /history >}}

GitLab Duo CLI는 [GitLab Duo 에이전트 채팅](../gitlab_duo_chat/agentic_chat.md)을 터미널에 제공하는 명령줄 인터페이스 도구입니다. 모든 운영 체제 및 편집기에서 사용할 수 있으며, CLI를 사용하여 코드베이스에 대한 복잡한 질문을 하고 자율적으로 귀하를 대신하여 작업을 수행합니다.

GitLab Duo CLI는 다음을 도울 수 있습니다:

- 코드베이스 구조, 파일 간 기능 및 개별 코드 조각을 이해합니다.
- 코드를 빌드, 수정, 리팩터링 및 현대화합니다.
- 오류를 해결하고 코드 문제를 수정합니다.
- CI/CD 구성을 자동화하고, 파이프라인 오류를 해결하며, 파이프라인을 최적화합니다.
- 자율적으로 다단계 개발 작업을 수행합니다.

> [!note]
> GitLab Duo CLI는 현재 일반 공급 중입니다. 완벽한 일반 공급 경험을 위해 GitLab Duo CLI 9.0.0 이상으로 업데이트하세요.

GitLab Duo CLI는 두 가지 모드를 제공합니다:

- 대화형 모드:  GitLab UI 또는 편집기 확장 프로그램의 GitLab Duo Chat과 유사한 채팅 환경을 제공합니다. 빌드 및 플랜 모드를 지원합니다.
- 헤드리스 모드: 러너, 스크립트 및 기타 자동화된 워크플로우에서 비대화형 사용을 활성화합니다.

또한 GitLab Duo Agent Platform에 대해 설정된 [사용자 정의 지침](../duo_agent_platform/customize/_index.md)을 지원하며, `chat-rules.md`, `AGENTS.md` 및 `SKILL.md` 파일을 포함합니다.

## 전제 조건 {#prerequisites}

- GitLab 19.2 이상.
- [GitLab Duo Agent Platform의 필수 조건](../duo_agent_platform/_index.md#prerequisites).

> [!note]
> GitLab 18.11부터 19.1 사이를 사용 중인 경우, [베타 및 실험 기능](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features)을 활성화하여 최신 버전의 GitLab Duo CLI를 사용할 수 있습니다.

## GitLab Duo CLI 억세스 켜기 또는 끄기 {#turn-gitlab-duo-cli-access-on-or-off}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 19.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242250).

{{< /history >}}

기본적으로 GitLab Duo CLI 억세스는 켜져 있습니다.

GitLab Self-Managed 및 GitLab Dedicated에서는 인스턴스에 대해 GitLab Duo CLI 억세스를 켜거나 끌 수 있습니다.

전제 조건:

- 관리자여야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo CLI** 아래에서 **GitLab Duo CLI 억세스 켜기** 체크박스를 선택하거나 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

## GitLab Duo CLI 설정 {#set-up-the-gitlab-duo-cli}

[GitLab CLI](https://docs.gitlab.com/cli/)(`glab`)를 통해 GitLab Duo CLI를 사용할 수 있습니다. GitLab CLI를 사용하면 다른 GitLab 기능에 액세스할 수 있으며 OAuth 및/또는 개인 액세스 토큰을 사용하여 한 번만 인증하면 됩니다.

또는 GitLab Duo CLI(`duo`)를 독립 실행형 AI 도구로 설치 및 사용하고 개인 액세스 토큰으로 별도로 인증할 수 있습니다.

두 설정 모두 대화형 및 헤드리스 모드와 모든 GitLab Duo CLI 옵션, 명령 및 기능을 지원합니다.

### GitLab CLI 사용 {#with-the-gitlab-cli}

전제 조건:

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.107.0 이상.
- GitLab CLI가 [인증됨](https://docs.gitlab.com/cli/#authenticate-with-gitlab).

GitLab CLI를 통해 GitLab Duo CLI를 설정하려면:

1. GitLab Duo CLI에 대해 `glab` 명령을 실행합니다:

   ```shell
   glab duo cli
   ```

1. 프롬프트를 따라 GitLab Duo CLI 바이너리를 설치합니다.

GitLab CLI가 자동으로 인증을 처리하므로 즉시 GitLab Duo CLI를 사용을 시작할 수 있습니다.

### GitLab CLI 없이 {#without-the-gitlab-cli}

GitLab Duo CLI를 독립 실행형 도구로 사용하려면 설치한 다음 인증합니다.

#### 설치 {#install}

GitLab Duo CLI를 컴파일된 바이너리로 설치하려면 설치 스크립트를 다운로드하고 실행합니다.

macOS 및 Linux:

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

Windows:

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

#### 인증 {#authenticate}

> [!note]
> `glab`이 시스템에 이미 설치되고 인증된 경우 처음으로 `duo`을 실행할 때 `duo`는 자동으로 `glab`을 자격 증명 도우미로 사용합니다. 따로 인증할 필요가 없습니다. 이를 위해서는 `glab` 1.85.2 이상 및 `duo` 8.68.0 이상이 필요합니다.
>
> 이 기능을 사용할 수 있기 전에 `duo`을 인증했고 대신 `glab`을 자격 증명 도우미로 사용하려면 `~/.gitlab/storage.json`에서 인증 설정을 삭제합니다.

전제 조건:

- `api` 권한이 있는 [개인 액세스 토큰](../profile/personal_access_tokens.md).

인증하려면:

1. 터미널에서 `duo`을 실행합니다. 처음으로 GitLab Duo CLI를 실행할 때 구성 화면이 나타납니다.
1. **GitLab Instance URL**을 입력한 후 <kbd>Enter</kbd>를 누릅니다:
   - GitLab.com의 경우 `https://gitlab.com`을 입력합니다.
   - GitLab Self-Managed 또는 GitLab Dedicated의 경우 인스턴스 URL을 입력합니다.
1. **GitLab Token**에 개인 액세스 토큰을 입력합니다.
1. CLI를 저장하고 종료하려면 <kbd>Enter</kbd>를 누릅니다.
1. CLI를 다시 시작하려면 터미널에서 `duo`을 실행합니다.

초기 설정 후 구성을 수정하려면 `duo config edit`을 사용합니다.

#### 환경 변수를 사용하여 인증 {#authenticate-with-environment-variables}

전제 조건:

- `api` 권한이 있는 [개인 액세스 토큰](../profile/personal_access_tokens.md).

환경 변수로 인증하려면:

1. `GITLAB_TOKEN` 또는 `GITLAB_OAUTH_TOKEN`을 개인 액세스 토큰으로 설정합니다.

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. 선택 사항. `GITLAB_BASE_URL` 또는 `GITLAB_URL`을 사용자 정의 GitLab 인스턴스 URL로 설정합니다(예: `https://gitlab.example.com`). 기본값은 `https://gitlab.com`입니다.

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

이 방법은 헤드리스 모드, CI/CD 파이프라인 및 대화형 인증이 불가능한 스크립트된 워크플로우에 유용합니다.

## GitLab Duo CLI 사용 {#use-the-gitlab-duo-cli}

전제 조건:

- 설정된 [기본 GitLab Duo 네임스페이스](../profile/preferences.md#namespace-resolution-in-your-local-environment) 또는 GitLab Duo 액세스 권한이 있는 열린 프로젝트입니다.

### 대화형 모드 {#interactive-mode}

GitLab Duo CLI를 대화형 모드로 사용하려면:

1. 설정을 기준으로 대화형 모드를 시작하는 명령을 입력합니다:

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

#### 빌드 및 플랜 모드 간 전환 {#switch-between-build-and-plan-modes}

대화형 모드에서는 작업하면서 GitLab Duo CLI를 두 모드 간에 전환할 수 있습니다:

| 모드                 | 권한 | 작동 방식                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| 빌드 모드(기본값) | 읽기-쓰기  | GitLab Duo는 작업을 실행하고 프로젝트를 변경할 수 있습니다.               |
| 플랜 모드            | 읽기 전용   | GitLab Duo는 프로젝트를 분석하고 변경 사항을 만들지 않고 플랜을 생성할 수 있습니다. |

예를 들어, 플랜 모드에서 GitLab Duo와 함께 문제를 논의하면서 시작합니다. 준비되면 빌드 모드로 전환하고 GitLab Duo에 플랜을 구현하도록 지시합니다.

GitLab Duo CLI는 `>` 프롬프트 아래의 현재 모드를 표시합니다. 모드 간 전환하려면 <kbd>Tab</kbd>을 누릅니다.

#### 슬래시 명령 {#slash-commands}

대화형 모드에서는 슬래시 명령을 사용하여 GitLab Duo CLI를 구성하고 작업을 수행합니다. 프롬프트에서 슬래시 명령을 입력한 다음 <kbd>Enter</kbd>를 누릅니다.

다음 슬래시 명령을 사용할 수 있습니다:

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

또한 고유한 슬래시 명령을 생성할 수 있습니다. 자세한 내용은 [사용자 정의 슬래시 명령](#custom-slash-commands)을 참조하세요.

#### 설정 {#settings}

설정을 변경하려면:

1. 대화형 모드에서 `/settings`을 입력하고 <kbd>Enter</kbd>를 누릅니다.
1. 화살표 키를 사용하여 설정 목록을 탐색합니다.
1. 선택한 설정을 변경하려면 <kbd>Enter</kbd> 또는 <kbd>Space</kbd>를 누릅니다.
1. 패널을 닫으려면 <kbd>Escape</kbd>를 누릅니다.

변경 사항은 세션 전체에 유지됩니다.

다음 설정을 사용할 수 있습니다:

| 설정                  | 설명                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Telemetry**            | GitLab Duo를 개선하기 위해 익명의 사용 데이터를 보냅니다.                                                  |
| **Enable global skills** | (실험) [사용자 수준 Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills)를 `~/.agents/skills/` 및 `~/.gitlab/duo/skills/`에서 검색합니다. 변경 사항이 적용되려면 다시 시작이 필요합니다. |
| **알림**        | [시스템 알림](#system-notifications)을 제어합니다(`auto` 또는 `disabled`).                     |

#### 시스템 알림 {#system-notifications}

GitLab Duo CLI는 세션에 주의가 필요한 경우(예: 작업을 완료했거나 도구 승인이 필요한 경우) 터미널 창이 포커스되지 않은 상태에서 시스템 알림을 보낼 수 있습니다.

**알림**은 [설정 패널](#settings)의 설정으로 제어됩니다:

- `auto`(기본값): 터미널이 포커스되지 않으면 시스템 알림을 보냅니다.
- `disabled`: 시스템 알림을 보내지 않습니다.

#### 도구 승인 {#tool-approvals}

GitLab Duo가 도구를 사용해야 할 때 시작하기 전에 승인을 위해 프롬프트합니다. 예를 들어 파일을 읽거나 명령을 실행해야 할 때입니다.

옵션은 다음과 같습니다:

- **승인**: GitLab Duo는 도구를 한 번 사용할 수 있습니다.
- **세션에 대해 승인**: GitLab Duo는 세션의 나머지 기간 동안 이러한 인수로 도구를 사용할 수 있습니다. 다른 인수는 추가 승인이 필요합니다.
- **거부**: GitLab Duo는 도구를 사용할 수 없습니다.

> [!note]
> **세션에 대해 승인** 옵션을 사용하려면 관리자가 그룹 또는 인스턴스에 대해 이를 활성화해야 합니다. 자세한 내용은 [도구 승인](../gitlab_duo_chat/agentic_chat.md#tool-approvals)을 참조하세요.

### 헤드리스 모드 {#headless-mode}

> [!caution]
> 헤드리스 모드는 신중하게 사용하고 제어된 [샌드박스 환경](../../editor_extensions/security_considerations.md#use-development-containers-for-isolation)에서 사용하세요.

비대화형 모드에서 워크플로우를 실행하려면 설정에 맞는 명령을 사용합니다:

{{< tabs >}}

{{< tab title="glab" >}}

`glab duo cli run`를 사용합니다.

```shell
glab duo cli run --goal "Your goal or prompt here"
```

예를 들어 ESLint 명령을 실행하고 오류를 GitLab Duo CLI로 파이프하여 해결할 수 있습니다:

 ```shell
glab duo cli run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< tab title="duo" >}}

`duo run`를 사용합니다.

```shell
duo run --goal "Your goal or prompt here"
```

예를 들어 ESLint 명령을 실행하고 오류를 GitLab Duo CLI로 파이프하여 해결할 수 있습니다:

 ```shell
duo run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< /tabs >}}

헤드리스 모드를 사용할 때 GitLab Duo CLI:

- 수동 도구 승인을 우회하고 모든 도구를 사용하도록 자동으로 승인합니다.
- 이전 대화의 컨텍스트를 유지하지 않습니다. `run` 명령을 실행할 때마다 새 워크플로우가 시작됩니다.

## 모델 선택 {#select-a-model}

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

   `--model` 옵션을 사용합니다:

   ```shell
   glab duo cli --model <gitlab_identifier_for_the_model>
   ```

   `GITLAB_DUO_MODEL` 환경 변수를 사용합니다:

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

   `--model` 옵션을 사용합니다:

   ```shell
   duo --model <gitlab_identifier_for_the_model>
   ```

   `GITLAB_DUO_MODEL` 환경 변수를 사용합니다:

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

## 모델 컨텍스트 프로토콜 (MCP) 연결 {#model-context-protocol-mcp-connections}

GitLab Duo CLI를 로컬 또는 원격 MCP 서버에 연결하려면 GitLab IDE 확장 프로그램과 동일한 MCP 구성을 사용합니다. 지침은 [MCP 서버 구성](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers)을 참조하세요.

## 훅 {#hooks}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab Duo CLI 8.95.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2209) \- GitLab 19.1 릴리스 중 [실험](../../policy/development_stages_support.md#experiment)입니다.

{{< /history >}}

훅을 사용하여 GitLab Duo CLI 수명 주기의 특정 지점에서 사용자 정의 명령을 실행합니다.

예를 들어 환경에 대한 정보를 수집하는 스크립트를 실행하여 모든 새 채팅 세션에 추가 컨텍스트를 주입할 수 있습니다.

GitLab Duo CLI는 두 수준에서 훅을 지원합니다:

- 사용자 수준(전역): 모든 프로젝트에 적용됩니다.
- 프로젝트 수준: 특정 프로젝트에만 적용됩니다. 프로젝트 수준 훅은 체크아웃된 리포지토리에서 임의 코드 실행을 방지하기 위해 기본적으로 비활성화됩니다.

사용자 수준 및 프로젝트 수준 `hooks.json` 파일이 모두 있으면 CLI는 훅을 병합하고 사용자 수준 훅을 먼저 실행합니다.

> [!note]
> 보안상의 이유로 민감한 환경 변수(`GITLAB_TOKEN`, `GITLAB_OAUTH_TOKEN`, `CI_JOB_TOKEN`)는 훅 프로세스에서 제외됩니다.

### 훅 실행 {#hook-execution}

훅이 실행될 때 GitLab Duo CLI:

1. 세션 메타데이터가 있는 JSON 개체를 명령의 표준 입력으로 보냅니다:

   ```json
   {
     "session_id": "abc-123",
     "cwd": "/path/to/project",
     "transcript_path": "",
     "hook_event_name": "SessionStart",
     "source": "startup"
   }
   ```

1. 훅 프로세스에 대해 환경 변수 `DUO_SESSION_ID` 및 `DUO_PROJECT_DIR`를 설정합니다.
1. 명령의 표준 출력을 세션에 대한 추가 컨텍스트로 수집합니다.

훅은 표준 출력에 일반 텍스트 또는 JSON 개체를 반환할 수 있습니다:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Your context string here"
  }
}
```

훅이 0이 아닌 상태로 종료되거나 시간 초과되면 경고로 기록되지만 세션이 시작되지 않도록 차단하지 않습니다.

### 훅 생성 {#create-hooks}

GitLab Duo CLI는 새 세션이 시작되거나 기존 세션이 다시 시작될 때 실행되는 `SessionStart` 이벤트를 지원합니다.

훅을 생성하려면:

1. `hooks.json` 파일을 생성합니다.
   - 사용자 수준 훅의 경우:
     - Linux 또는 macOS에서 파일을 `~/.gitlab/duo/hooks.json`에서 생성합니다.
     - Windows에서 파일을 `%APPDATA%\GitLab\duo\hooks.json`에서 생성합니다.
   - 프로젝트 수준 훅의 경우 파일을 프로젝트의 루트에 생성합니다: `<project>/.gitlab/duo/hooks.json`.
1. 파일에서 훅을 정의합니다.
   - 훅을 트리거해야 하는 각 `SessionStart` 이벤트 소스(`startup` 또는 `resume`)에 대해 매처 그룹을 생성합니다.
   - 각 매처 그룹에는 선택적 정규식 `matcher` 값과 명령 훅 배열이 있습니다:

     | 필드 | 설명 |
     |-------|-------------|
     | `matcher` | 선택 사항. 이벤트 소스(`startup` 또는 `resume` for `SessionStart`)에 대해 테스트된 정규식입니다. 모두 일치시키려면 생략하세요. |
     | `hooks[].type` | `"command"`이어야 합니다. |
     | `hooks[].command` | 실행할 셸 명령입니다. |
     | `hooks[].timeout` | 선택 사항. 초 단위 시간 초과입니다. 기본값: 30\. |

   - 예를 들어:

     ```json
     {
       "hooks": {
         "SessionStart": [
           {
             "matcher": "startup",
             "hooks": [
               {
                 "type": "command",
                 "command": "cat ~/.my-coding-preferences.md",
                 "timeout": 10
               }
             ]
          }
         ]
       }
     }
     ```

1. 프로젝트 수준 훅이 있는 경우 GitLab Duo CLI를 시작할 때 활성화합니다:

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-project-hooks
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-project-hooks
   ```

   {{< /tab >}}

   {{< /tabs >}}

   또는 환경 변수를 설정합니다:

   ```shell
   export GITLAB_ENABLE_PROJECT_HOOKS=true
   ```

## 사용자 정의 슬래시 명령 {#custom-slash-commands}

{{< history >}}

- GitLab Duo CLI 9.2.0에서 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3617) \- GitLab 19.2 릴리스 중입니다.

{{< /history >}}

자주 사용하는 프롬프트에 대한 사용자 정의 슬래시 명령을 생성합니다.

GitLab Duo CLI는 두 수준에서 사용자 정의 슬래시 명령을 지원합니다:

- 사용자 수준: 모든 프로젝트에 적용됩니다.
- 프로젝트 수준: 특정 프로젝트에만 적용됩니다.

사용자 수준 명령과 프로젝트 수준 명령이 같은 이름을 공유하면 프로젝트 수준 명령이 우선합니다. 사용자 정의 슬래시 명령은 기본 제공 슬래시 명령 또는 [Agent Skills 슬래시 명령](../duo_agent_platform/customize/agent_skills.md#expose-skills-as-slash-commands)을 재정의할 수 없습니다.

### 사용자 정의 슬래시 명령 생성 {#create-a-custom-slash-command}

사용자 정의 슬래시 명령을 생성하려면 Markdown 파일을 생성합니다.

파일 이름은 명령 이름이고 파일 내용은 프롬프트입니다.

예를 들어 `daily.md`이라는 파일은 `/daily` 명령을 생성합니다:

1. `commands` 디렉터리를 생성합니다:
   - 프로젝트 수준 명령의 경우 프로젝트의 루트에 디렉터리를 생성합니다: `<project>/.agents/commands/`.
   - 사용자 수준 명령의 경우 다음 위치 중 하나를 사용합니다:
     - 명령을 다른 GitLab Duo 사용자 정의 파일과 함께 유지하려면:
       - Linux 또는 macOS에서 디렉터리를 `~/.gitlab/duo/commands/`에서 생성합니다.
       - Windows에서 디렉터리를 `%APPDATA%\GitLab\duo\commands\`에서 생성합니다.
       - `GLAB_CONFIG_DIR` 또는 `XDG_CONFIG_HOME`을 설정한 경우 `$GLAB_CONFIG_DIR/commands/` 또는 `$XDG_CONFIG_HOME/gitlab/duo/commands/`을 사용합니다. 둘 다 설정한 경우 `GLAB_CONFIG_DIR`이 우선합니다.
     - 다른 AI 도구와 명령을 공유하려면:
       - Linux 또는 macOS에서 디렉터리를 `~/.agents/commands/`에서 생성합니다.
       - Windows에서 디렉터리를 `%USERPROFILE%\.agents\commands\`에서 생성합니다.
1. 디렉터리에서 Markdown 파일을 생성합니다. 파일 이름으로 명령 이름을 사용합니다. 명령 이름은 문자나 숫자로 시작해야 하며 문자, 숫자, 하이픈 및 밑줄만 포함할 수 있습니다.
1. 파일에 프롬프트를 추가합니다.
1. 선택 사항. 파일 상단의 YAML 머리말에 `description` 필드를 추가합니다. 설명은 슬래시 명령 메뉴에서 명령 옆에 나타납니다.

   예를 들어 `daily.md`에서 정의된 `/daily` 명령:

   ```markdown
   ---
   description: Prepare a daily report
   ---

   Use `glab todo list` to fetch my open TODO items. Give me a concise morning report ranked by priority.
   ```

1. GitLab Duo CLI를 다시 시작합니다. CLI는 시작할 때 사용자 정의 슬래시 명령을 검색합니다.

### 사용자 정의 슬래시 명령 사용 {#use-a-custom-slash-command}

대화형 모드에서 프롬프트에 슬래시 명령을 입력하고 <kbd>Enter</kbd>를 누릅니다. GitLab Duo CLI는 파일 내용을 프롬프트로 보냅니다.

명령 이름 뒤에 입력한 모든 텍스트는 프롬프트 끝에 추가됩니다.

이것을 사용하여 사용자 정의 슬래시 명령이 수행하는 작업을 사용자 정의합니다.

예를 들어, `/daily prioritize my milestone deliverables`입니다.

## 참조 {#reference}

GitLab Duo CLI를 시작하거나 실행할 때 이러한 옵션, 명령 및 환경 변수를 사용합니다.

자세한 내용 및 최신 목록은 [GitLab Duo CLI 참조](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)를 참조하세요.

### 옵션 {#options}

GitLab Duo CLI는 다음 옵션을 지원합니다:

- `-C, --cwd <path>`: 작업 디렉터리를 변경합니다.
- `-h, --help` : GitLab Duo CLI 또는 특정 명령에 대한 도움말을 표시합니다. 예를 들어 `duo --help` 또는 `duo run --help`입니다.
- `--log-level <level>`: 로깅 수준을 설정합니다(`debug`, `info`, `warn`, `error`).
- `-v`, `--version`: 버전 정보를 표시합니다.
- `--enable-global-skills`: (실험) [사용자 수준 Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills)를 활성화합니다.
- `--enable-project-hooks`: (실험) 프로젝트 수준 [훅](#hooks) 로드를 활성화합니다.
- `--model <model>`: 세션에 사용할 AI 모델을 선택합니다.

헤드리스 모드의 추가 옵션:

- `--ai-context-items <contextItems>`: 참조를 위한 추가 컨텍스트 항목의 JSON 인코딩 배열입니다.
- `--existing-session-id <sessionId>`: 다시 시작할 기존 세션의 ID입니다.
- `--gitlab-auth-token <token>`: GitLab 인스턴스에 대한 인증 토큰입니다.
- `--gitlab-base-url <url>`: GitLab 인스턴스의 기본 URL입니다(기본값: `https://gitlab.com`).

### 명령 {#commands}

다음 명령은 각 설정에 대해 사용할 수 있습니다:

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli`: 대화형 모드를 시작합니다.
- `glab duo cli log`: 로그를 보고 관리합니다.
  - `glab duo cli log last`: 마지막 로그 파일을 엽니다.
  - `glab duo cli log list`: 모든 로그 파일을 나열합니다.
  - `glab duo cli log tail <args...>`: 마지막 로그 파일의 끝을 표시합니다. 표준 꼬리 인수를 지원합니다.
  - `glab duo cli log clear`: 기존의 모든 로그 파일을 제거합니다.
- `glab duo cli run`: 헤드리스 모드를 시작합니다.

{{< /tab >}}

{{< tab title="duo" >}}

- `duo`: 대화형 모드를 시작합니다.
- `duo config`: 구성 및 인증 설정을 관리합니다.
- `duo log`: 로그를 보고 관리합니다.
  - `duo log last`: 마지막 로그 파일을 엽니다.
  - `duo log list`: 모든 로그 파일을 나열합니다.
  - `duo log tail <args...>`: 마지막 로그 파일의 끝을 표시합니다. 표준 꼬리 인수를 지원합니다.
  - `duo log clear`: 기존의 모든 로그 파일을 제거합니다.
- `duo run`: 헤드리스 모드를 시작합니다.

{{< /tab >}}

{{< /tabs >}}

### 환경 변수 {#environment-variables}

환경 변수를 사용하여 GitLab Duo CLI를 구성할 수 있습니다:

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP 인증 암호입니다.
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP 인증 사용자 이름입니다.
- `GITLAB_BASE_URL` 또는 `GITLAB_URL`: GitLab 인스턴스 URL입니다.
- `GITLAB_DUO_MODEL`: 세션에 사용할 AI 모델입니다.
- `GITLAB_ENABLE_GLOBAL_SKILLS`: (실험) [사용자 수준 Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills)를 활성화합니다.
- `GITLAB_ENABLE_PROJECT_HOOKS`: (실험) 프로젝트 수준 [훅](#hooks) 로드를 활성화합니다.
- `GITLAB_OAUTH_TOKEN` 또는 `GITLAB_TOKEN`: 인증 토큰입니다.
- `LOG_LEVEL`: 로깅 수준입니다.

GitLab Duo CLI가 귀하를 대신하여 명령을 실행할 때 해당 프로세스에 `AI_AGENT` 환경 변수를 설정합니다. 스크립트 및 도구는 `AI_AGENT`을 읽어 AI 기반 실행 중임을 감지할 수 있습니다.

## 프록시 및 사용자 정의 인증서 구성 {#proxy-and-custom-certificate-configuration}

네트워크에서 HTTPS 가로채기 프록시를 사용하거나 사용자 정의 SSL 인증서가 필요한 경우 추가 구성이 필요할 수 있습니다.

### 프록시 구성 {#proxy-configuration}

GitLab Duo CLI는 표준 프록시 환경 변수를 준수합니다:

- `HTTP_PROXY` 또는 `http_proxy`: HTTP 요청에 대한 프록시 URL입니다.
- `HTTPS_PROXY` 또는 `https_proxy`: HTTPS 요청에 대한 프록시 URL입니다.
- `NO_PROXY` 또는 `no_proxy`: 프록시에서 제외할 호스트의 쉼표로 구분된 목록입니다.

### 사용자 정의 SSL 인증서 {#custom-ssl-certificates}

조직이 사용자 정의 CA(인증 기관)를 사용하는 경우(HTTPS 가로채기 프록시 또는 유사) 인증서 오류가 발생할 수 있습니다.

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

인증서 오류를 해결하려면 다음 방법 중 하나를 사용합니다:

- 시스템 인증서 저장소를 사용합니다(권장):
  - CA 인증서가 운영 체제의 인증서 저장소에 설치되어 있으면 Node.js를 구성하여 사용합니다. Node.js 22.15.0, 23.9.0, 24.0.0 이상이 필요합니다.
  - GitLab Duo CLI를 컨테이너에서 실행하는 경우 호스트 시스템 저장소가 아닌 컨테이너의 시스템 저장소에 CA 인증서를 설치합니다.

  ```shell
  export NODE_OPTIONS="--use-system-ca"
  ```

- CA 인증서 파일을 지정합니다:
  - 이전 Node.js 버전이거나 CA 인증서가 시스템 저장소에 없는 경우 Node.js를 인증서 파일로 직접 가리킵니다. 파일은 PEM 형식이어야 합니다.
  - GitLab Duo CLI를 컨테이너에서 실행하는 경우 경로를 컨테이너의 위치로 설정합니다. 볼륨 마운트를 사용하여 인증서 파일을 제공합니다.

  ```shell
  export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
  ```

### 인증서 오류 무시 {#ignore-certificate-errors}

여전히 인증서 오류가 발생하면 인증서 검증을 비활성화할 수 있습니다.

> [!warning]
> 인증서 검증을 비활성화하는 것은 보안 위험입니다. 프로덕션 환경에서 검증을 비활성화하면 안 됩니다.

인증서 오류는 잠재적인 보안 침해를 경고하므로 안전하다고 확신할 때만 인증서 검증을 비활성화해야 합니다.

전제 조건:

- 브라우저에서 인증서 체인을 확인했거나 관리자가 이 오류를 무시해도 안전하다고 확인했습니다.

인증서 검증을 비활성화하려면:

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

## GitLab Duo CLI 업데이트 {#update-the-gitlab-duo-cli}

GitLab Duo CLI를 최신 버전으로 수동으로 업데이트하려면 설정에 맞는 명령을 실행합니다:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo cli --update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
npm install --global @gitlab/duo-cli@latest
```

{{< /tab >}}

{{< /tabs >}}

## GitLab Duo CLI에 기여 {#contribute-to-the-gitlab-duo-cli}

GitLab Duo CLI에 기여하는 방법에 대한 정보는 [개발 가이드](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/development.md)를 참조하세요.

## 관련 항목 {#related-topics}

- [편집기 확장 프로그램의 보안 고려 사항](../../editor_extensions/security_considerations.md)
- [GitLab Duo CLI 참조](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [GitLab Duo Agent Platform 사용자 정의](../duo_agent_platform/customize/_index.md)
- [GitLab Duo Agent Platform 세션](../duo_agent_platform/sessions/_index.md)
