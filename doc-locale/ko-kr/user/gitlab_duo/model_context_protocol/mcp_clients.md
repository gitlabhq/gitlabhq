---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 모델 컨텍스트 프로토콜과 사용 방법을 설명합니다
title: GitLab MCP 클라이언트
---

{{< details >}}

- 티어:  [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- GitLab 웹 UI의 GitLab Duo 에이전트 채팅을 제외하고 자체 호스팅 모델과 함께 GitLab Duo에서 사용 가능합니다

{{< /collapsible >}}

{{< history >}}

- GitLab 18.1에서 `duo_workflow_mcp_support` [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/519938)되었습니다. 기본적으로 사용 중지됩니다.
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) \- GitLab 18.2 `duo_workflow_mcp_support` 기능 플래그가 제거되었습니다.
- [GitLab 18.3에서 실험에서 베타로 변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/545956)
- GitLab 18.8에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)되었습니다.
- GitLab 18.10부터 GitLab.com의 Free 티어에서 GitLab Credits를 사용하여 이용 가능합니다.
- GitLab 18.11 릴리스 중에 GitLab Duo CLI 8.81.0에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/19716)

{{< /history >}}

모델 컨텍스트 프로토콜(MCP)은 GitLab Duo 기능이 다양한 외부 데이터 원본 및 도구에 안전하게 연결할 수 있는 표준화된 방법을 제공합니다

MCP는 다음 환경에서 지원됩니다:

- Visual Studio Code(VS Code) 및 VSCodium
- JetBrains IDE
- GitLab Duo CLI를 통한 명령줄

동일한 MCP 구성 파일이 지원되는 모든 IDE와 GitLab Duo CLI에서 작동합니다

다음 기능이 MCP 클라이언트로 작동하고 MCP 서버의 외부 도구에 연결할 수 있습니다:

- [GitLab Duo Agentic Chat](../../gitlab_duo_chat/agentic_chat.md)
- [Software Development 플로우](../../duo_agent_platform/flows/foundational_flows/software_development.md)

이러한 기능은 외부 컨텍스트와 정보에 액세스하여 더 강력한 답변을 생성할 수 있습니다

> [!note]
> 자체 호스팅 모델은 GitLab 웹 UI의 GitLab Duo 에이전트 채팅과 함께 MCP에 사용할 수 없습니다 MCP는 IDE, GitLab Duo CLI 및 플로우의 자체 호스팅 모델에서 지원됩니다

MCP와 함께 기능을 사용하려면:

1. 그룹에 대해 MCP를 켭니다
1. 기능을 연결할 MCP 서버를 구성합니다

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [GitLab Duo Chat(에이전트) - MCP 도구 호출 승인](https://www.youtube.com/watch?v=_cHoTmG8Yj8)을 참조하세요
<!-- Video published on 2025-06-24 -->

클릭 스루 데모는 [GitLab Duo 에이전트 플랫폼 - MCP 클라이언트](https://gitlab.navattic.com/mcp)를 참조하세요
<!-- Demo published on 2025-08-05 -->

## 사전 요구 사항 {#prerequisites}

- [GitLab Duo Agent Platform 사전 요구 사항](../../duo_agent_platform/_index.md#prerequisites)을 충족합니다.
- Visual Studio Code(VS Code) 또는 VSCodium의 경우:
  - [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.35.6 이상을 설치하고 설정합니다
- JetBrains IDE의 경우:
  - [JetBrains IDE용 GitLab Duo 플러그인](../../../editor_extensions/jetbrains_ide/setup.md) 3.14.0 이상을 설치하고 설정합니다
- 명령줄의 경우:
  - [GitLab Duo CLI의 필수 사항](../../gitlab_duo_cli/set_up.md#prerequisites)을 충족합니다
  - [GitLab Duo CLI](../../gitlab_duo_cli/set_up.md) 8.81.0 이상을 설치하고 구성합니다

확장 프로그램 지원에 대한 자세한 내용은 [버전 호환성](#version-compatibility)을 참조하세요

## 외부 MCP 도구 허용 {#allow-external-mcp-tools}

GitLab Duo가 구성된 최상위 그룹에서 IDE가 외부 MCP 도구에 액세스할 수 있도록 허용합니다

> [!note]
> 그룹 및 프로젝트 소유자는 MCP 레지스트리를 사용하여 특정 MCP 서버의 모든 도구를 차단할 수도 있습니다 차단된 서버는 도구 승인 설정과 관계없이 개별 사용자가 차단을 해제할 수 없습니다 자세한 내용은 [MCP 서버 차단](../../ai-governance/tool-governance.md#block-model-context-protocol-mcp-servers)을 참조하세요 GitLab Self-Managed에서 관리자는 사용자 지정 에이전트와 플로우가 외부 MCP 도구를 사용할 수 있도록 `mcp_client` [기능 플래그](../../../administration/feature_flags/_index.md)를 활성화해야 합니다

### GitLab.com {#on-gitlabcom}

GitLab.com에서 로컬 환경이 외부 MCP 도구에 액세스할 수 있도록 하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **외부 MCP 도구** 아래에서 **외부 MCP 도구 허용** 확인란을 선택합니다
1. **변경 사항 저장**을 선택합니다.

### GitLab Self-Managed {#on-gitlab-self-managed}

GitLab Self-Managed에서 로컬 환경이 외부 MCP 도구에 액세스할 수 있도록 하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **외부 MCP 도구** 아래에서 **외부 MCP 도구 허용** 확인란을 선택합니다
1. **변경 사항 저장**을 선택합니다.

## MCP 서버 구성 {#configure-mcp-servers}

MCP를 언어 서버와 통합하려면 워크스페이스 구성, 사용자 구성 또는 둘 다를 설정합니다 GitLab 언어 서버가 구성 파일을 로드하고 병합합니다

> [!note]
> 워크스페이스 구성은 IDE 워크스페이스 폴더 또는 GitLab Duo CLI를 사용할 때의 현재 작업 디렉토리에 적용됩니다 이것은 가상 개발 환경인 [GitLab 워크스페이스](../../workspace/_index.md)와는 별개입니다

### 버전 호환성 {#version-compatibility}

| MCP 지원 | GitLab for VS Code | GitLab Duo 플러그인 <br>JetBrains IDE용 | GitLab Duo CLI |
|------------------------|-----------------------------------|------------------------|------------------------|
| 기본(워크스페이스 또는 사용자 구성 없음) | 6.28.2 이상 | 3.10.0 이상 |  |
| 전체(워크스페이스 및 사용자 구성 포함) | 6.35.6 이상 | 3.14.0 이상 | 8.81.0 이상 |

### 워크스페이스 구성 생성 {#create-workspace-configuration}

워크스페이스 구성은 IDE 워크스페이스 폴더 또는 현재 작업 디렉토리에 적용되며 동일한 서버에 대한 사용자 구성을 재정의합니다

워크스페이스 구성을 설정하려면:

1. IDE 워크스페이스 폴더 또는 현재 작업 디렉토리에서 `.gitlab/duo/mcp.json` 파일을 만듭니다
1. [구성 형식](#configuration-format)을 사용하여 기능이 연결할 MCP 서버에 대한 정보를 추가합니다
1. 파일을 저장합니다.
1. IDE 또는 GitLab Duo CLI를 다시 시작합니다

### 사용자 구성 생성 {#create-user-configuration}

사용자 구성 설정은 개인 도구 및 일반적으로 사용되는 서버에 적합합니다 이러한 설정은 모든 워크스페이스 구성에 적용되지만 동일한 서버에 대한 워크스페이스 구성이 우선합니다

사용자 구성을 설정하려면:

1. 구성 파일을 만듭니다:

   {{< tabs >}}

   {{< tab title="VS Code 또는 VSCodium" >}}

   1. IDE에서 명령 팔레트를 엽니다:
      - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다
      - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다
   1. `GitLab MCP: Open User Settings (JSON)` 명령을 실행합니다

   {{< /tab >}}

   {{< tab title="JetBrains IDE" >}}

   - 홈 디렉토리에 `mcp.json` 파일을 만듭니다:
     - Linux 또는 macOS의 경우 `~/.gitlab/duo/mcp.json`에서
     - Windows의 경우 `%APPDATA%\GitLab\duo\mcp.json`에서

       예를 들어, `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`입니다.

   다음 환경 변수 중 하나를 설정한 경우 다른 위치에 파일을 만듭니다:

   - `GLAB_CONFIG_DIR`의 경우 `$GLAB_CONFIG_DIR/duo/mcp.json`에서
   - `XDG_CONFIG_HOME`의 경우 `$XDG_CONFIG_HOME/gitlab/duo/mcp.json`에서

   {{< /tab >}}

   {{< tab title="GitLab Duo CLI" >}}

   - 홈 디렉토리에 `mcp.json` 파일을 만듭니다:
     - Linux 또는 macOS의 경우 `~/.gitlab/duo/mcp.json`에서
     - Windows의 경우 `%APPDATA%\GitLab\duo\mcp.json`에서

       예를 들어, `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`입니다.

   다음 환경 변수 중 하나를 설정한 경우 다른 위치에 파일을 만듭니다:

   - `GLAB_CONFIG_DIR`의 경우 `$GLAB_CONFIG_DIR/duo/mcp.json`에서
   - `XDG_CONFIG_HOME`의 경우 `$XDG_CONFIG_HOME/gitlab/duo/mcp.json`에서

   {{< /tab >}} {{< /tabs >}}

1. [구성 형식](#configuration-format)을 사용하여 기능이 연결할 MCP 서버에 대한 정보를 추가합니다
1. 파일을 저장합니다.
1. IDE 또는 GitLab Duo CLI를 다시 시작합니다

### 구성 형식 {#configuration-format}

두 구성 파일 모두 `mcpServers` 키의 세부 정보와 동일한 JSON 형식을 사용합니다:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "path/to/server",
      "args": ["--arg1", "value1"],
      "env": {
        "ENV_VAR": "value"
      },
      "approvedTools": true
    },
    "http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "search"]
    },
    "sse-server": {
      "type": "sse",
      "url": "http://localhost:3000/mcp/sse"
    }
  }
}
```

> [!note]
> 다른 MCP 클라이언트의 경우 Atlassian 문서에서 샘플 구성 파일에 `mcp.servers`을 사용합니다 GitLab의 경우 `mcpServers`을 대신 사용합니다

### 도구 승인 구성 {#configure-tool-approval}

기본적으로 각 세션에서 서버의 모든 MCP 도구를 수동으로 승인해야 합니다

대신 구성 파일에서 MCP 도구를 미리 승인하여 수동 승인 프롬프트를 건너뛸 수 있습니다

이렇게 하려면 `approvedTools` 필드를 서버 구성에 추가합니다:

- `"approvedTools": true` - 이 서버의 현재 및 향후 모든 도구를 자동으로 승인합니다
- `"approvedTools": ["tool1", "tool2"]` - 지정한 도구만 승인합니다

이 필드를 포함하지 않으면 세션에서 모든 도구를 수동으로 승인해야 합니다(기본 동작).

> [!warning]
> 완전히 신뢰하는 서버에만 `"approvedTools": true`을 사용합니다

예를 들어:

```json
{
  "mcpServers": {
    "trusted-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["my-trusted-mcp-server"],
      "approvedTools": true
    },
    "selective-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "search"]
    },
    "untrusted-server": {
      "type": "sse",
      "url": "http://example.com/mcp/sse"
    }
  }
}
```

#### 도구 승인 작동 방식 {#how-tool-approval-works}

GitLab은 MCP 도구에 대해 2단계 승인 시스템을 사용합니다:

- 구성 기반 승인(영구): `mcp.json`에서 `approvedTools` 필드를 사용하여 승인된 도구 이러한 승인은 모든 세션에 걸쳐 지속됩니다
- 세션 기반 승인(임시): 현재 워크플로우 세션을 위해 런타임 중에 승인된 도구 IDE를 닫거나 워크플로우를 종료하면 이러한 승인이 지워집니다

한 가지 조건이 충족되면 도구가 승인됩니다

### MCP 서버 구성 예 {#example-mcp-server-configurations}

다음 코드 예를 사용하여 MCP 서버 구성 파일을 만들 수 있습니다

자세한 내용과 예는 [MCP 예제 서버 설명서](https://modelcontextprotocol.io/examples)를 참조하세요 다른 예제 서버는 [Smithery.ai](https://smithery.ai/) 및 [Awesome MCP 서버](https://mcpservers.org/)입니다

#### 로컬 서버 {#local-server}

```json
{
  "mcpServers": {
    "enterprise-data-v2": {
      "type": "stdio",
      "command": "node",
      "args": ["src/server.js"],
      "cwd": "</path/to/your-mcp-server>",
      "approvedTools": ["query_database", "fetch_metrics"]
    }
  }
}
```

#### GitLab 지식 그래프 서버 {#gitlab-knowledge-graph-server}

[GitLab 지식 그래프](https://gitlab-org.gitlab.io/rust/knowledge-graph/)는 MCP를 통한 코드 인텔리전스를 제공합니다 모든 도구 또는 특정 도구를 승인할 수 있습니다:

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "type": "sse",
      "url": "http://localhost:27495/mcp/sse",
      "approvedTools": true
    }
  }
}
```

또는 특정 도구만 승인합니다:

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "type": "sse",
      "url": "http://localhost:27495/mcp/sse",
      "approvedTools": ["list_projects", "search_codebase_definitions", "get_references", "get_definition"]
    }
  }
}
```

사용 가능한 도구에 대한 자세한 내용은 [지식 그래프 MCP 도구 설명서](https://gitlab-org.gitlab.io/rust/knowledge-graph/mcp/tools/)를 참조하세요

#### HTTP 서버 {#http-server}

```json
{
  "mcpServers": {
    "local-http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "write_file"]
    }
  }
}
```

## MCP 서버의 상태 보기 {#view-the-status-of-mcp-servers}

{{< history >}}

- GitLab for VS Code 확장 프로그램 6.55.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2155)

{{< /history >}}

사전 요구 사항:

- GitLab for VS Code 확장 프로그램 6.55.0 이상
- 사용자 또는 워크스페이스 구성에 구성된 MCP 서버 1개 이상

구성된 MCP 서버의 상태를 보려면:

1. VS Code 또는 VSCodium에서 명령 팔레트를 엽니다:
   - macOS에서 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
   - Windows 또는 Linux에서 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
1. `GitLab: Show MCP Dashboard`를 입력하고 <kbd>Enter</kbd>를 누릅니다.

MCP 대시보드가 새 편집기 탭에서 열립니다 대시보드를 사용하여:

- MCP 서버가 올바르게 구성되고 실행 중인지 확인합니다
- GitLab Duo 기능을 사용하기 전에 연결 문제를 파악합니다
- 각 서버에서 사용 가능한 도구를 봅니다
- 서버 구성 문제를 해결합니다

### MCP 구성 파일 열기 {#open-mcp-configuration-files}

MCP 구성 파일을 열려면:

1. VS Code 또는 VSCodium에서 명령 팔레트를 엽니다:
   - macOS에서 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
   - Windows 또는 Linux에서 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
1. 구성 파일을 엽니다:
   - 사용자 구성의 경우 `GitLab MCP: Open User Settings (JSON)`을 입력하고 <kbd>Enter</kbd>를 누릅니다
   - 워크스페이스 구성의 경우 `GitLab MCP: Open Workspace Settings (JSON)`을 입력하고 <kbd>Enter</kbd>를 누릅니다

## MCP 서버를 통해 다시 인증 {#re-authenticate-with-mcp-servers}

MCP 구성 파일에서 인증 세부 정보를 업데이트한 후 관련 MCP 서버를 통해 다시 인증해야 합니다

다시 인증을 트리거하려면:

- GitLab Duo에 해당 MCP 서버의 데이터가 필요한 질문을 합니다(예: Atlassian의 경우 `What are the issues in my Jira project?`). 인증 흐름이 자동으로 시작됩니다

## MCP와 함께 GitLab Duo 기능 사용 {#use-gitlab-duo-features-with-mcp}

{{< history >}}

- 전체 세션에 대한 외부 도구 승인이 GitLab 18.4에서 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/556045)

{{< /history >}}

GitLab Duo 기능이 외부 도구를 호출하여 질문에 답할 때 전체 세션에 대해 승인하지 않은 경우 해당 도구를 검토해야 합니다:

1. VS Code를 엽니다.
1. 왼쪽 사이드바에서 **GitLab Duo Agent Platform**({{< icon name="duo-agentic-chat" >}})을 선택합니다.
1. **채팅** 또는 **플로우** 탭을 선택합니다
1. 텍스트 상자에 질문을 입력하거나 코드 작업을 지정합니다
1. 질문 또는 코드 작업을 제출합니다
1. **도구에 대한 승인이 요구됨** 대화 상자가 다음 경우에 나타납니다:

   - GitLab Duo가 세션에서 처음으로 해당 도구를 호출하고 있습니다
   - 전체 세션에 대해 해당 도구를 승인하지 않았습니다

1. 도구를 승인하거나 거부합니다:

   - 도구를 승인하면 기능이 도구에 연결하고 답변을 생성합니다
     - 선택 사항입니다. 전체 세션에 대해 도구를 승인하려면 **승인** 드롭다운 목록에서 **세션에 대해 승인**을 선택합니다

       세션에 대해서는 MCP 서버 제공 도구만 승인할 수 있습니다 터미널 또는 CLI 명령은 승인할 수 없습니다

   - 채팅의 경우 도구를 거부하면 **거부 사유를 입력하세요** 대화 상자가 나타납니다 거부 사유를 입력한 다음 **거부 제출**을 선택합니다

     채팅은 제공한 사유에 따라 조치를 취할 수 있습니다. 예를 들어 새로운 접근 방식을 제안하거나 이슈를 생성합니다

## 문제 해결 {#troubleshooting}

### MCP 인증 캐시 삭제 {#delete-the-mcp-authentication-cache}

GitLab은 MCP 인증을 `~/.mcp-auth/`에서 로컬로 캐시합니다 문제 해결 중에 거짓 양성을 방지하려면 캐시 디렉토리를 삭제합니다:

```shell
rm -rf ~/.mcp-auth/
```

### `Error starting server filesystem: Error: spawn ... ENOENT` {#error-starting-server-filesystem-error-spawn--enoent}

이 오류는 상대 경로(예: `node` 대신 `/usr/bin/node`)를 사용하여 명령을 지정할 때 발생하며 해당 명령을 GitLab 언어 서버에 전달된 `PATH` 환경 변수에서 찾을 수 없습니다

`PATH` 해결에 대한 개선 사항이 [이슈 1345](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1345)에서 추적됩니다

### VS Code의 MCP 문제 해결 {#troubleshooting-mcp-in-vs-code}

문제 해결 정보는 [GitLab for VS Code 확장 프로그램 문제 해결](../../../editor_extensions/visual_studio_code/troubleshooting.md)을 참조하세요
