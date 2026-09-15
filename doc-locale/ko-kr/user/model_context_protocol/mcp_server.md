---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab MCP 서버를 사용하여 AI 도구를 GitLab 인스턴스에 연결합니다.
title: GitLab MCP 서버
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- `mcp_server` 및 `oauth_dynamic_client_registration`라는 [기능 플래그](../../administration/feature_flags/_index.md)로 GitLab 18.3에서 [실험적](../../policy/development_stages_support.md#experiment)으로 도입되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 18.6에서 실험에서 [베타](../../policy/development_stages_support.md#beta)로 변경되었습니다. 기능 플래그 [`mcp_server`](https://gitlab.com/gitlab-org/gitlab/-/issues/556448) 및 [`oauth_dynamic_client_registration`](https://gitlab.com/gitlab-org/gitlab/-/issues/555942)가 제거되었습니다.
- `2025-03-26` 및 `2025-06-18` MCP 프로토콜 사양에 대한 지원이 GitLab 18.7에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/581459)되었습니다.
- GitLab 19.2에서 별도 설정으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/work_items/590729)되었으며 GitLab Premium에서 GitLab Free로 [이동](https://gitlab.com/groups/gitlab-org/-/work_items/21183)되었습니다.

{{< /history >}}

> [!warning]
> 이 기능에 대한 피드백을 제공하려면 [이슈 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)에 댓글을 남기세요.

GitLab [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) 서버를 사용하면 AI 도구 및 애플리케이션을 GitLab 인스턴스에 안전하게 연결할 수 있습니다. Claude Desktop, Claude Code, Cursor 및 기타 MCP 호환 도구와 같은 AI 어시스턴트는 GitLab 데이터에 액세스하고 사용자를 대신하여 작업을 수행할 수 있습니다.

GitLab MCP 서버는 AI 도구를 위한 표준화된 방법을 제공합니다.

- GitLab 프로젝트 정보에 액세스합니다.
- 이슈 및 병합 요청 데이터를 검색합니다.
- GitLab API와 안전하게 상호작용합니다.
- AI 어시스턴트를 통해 GitLab 특화 작업을 수행합니다.

GitLab MCP 서버는 [OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)을 지원하므로 AI 도구가 GitLab 인스턴스에 등록할 수 있습니다. AI 도구가 처음으로 GitLab MCP 서버에 연결할 때:

1. OAuth 애플리케이션으로 등록합니다.
1. GitLab 데이터에 액세스할 권한을 요청합니다.
1. 안전한 API 액세스를 위한 액세스 토큰을 수신합니다.

클릭 스루 데모는 [GitLab Duo Agent Platform - GitLab MCP 서버](https://gitlab.navattic.com/gitlab-mcp-server)를 참조합니다.
<!-- Demo published on 2025-09-11 -->

## 사전 요구 사항 {#prerequisites}

- GitLab Duo 가용성을 **항상 켜짐** 또는 **기본적으로 켜짐**으로 설정합니다.
  - GitLab.com에서 [최상위 그룹에 대해](../gitlab_duo/turn_on_off.md#for-a-top-level-group) 설정합니다.
  - GitLab Self-Managed 및 GitLab Dedicated에서 [인스턴스에 대해](../gitlab_duo/turn_on_off.md#for-an-instance) 설정합니다.
- 베타 및 실험 기능을 켭니다.
  - GitLab.com에서 [최상위 그룹에 대해](../gitlab_duo/turn_on_off.md#on-gitlabcom-2) 설정합니다.
  - GitLab Self-Managed 및 GitLab Dedicated에서 [인스턴스에 대해](../gitlab_duo/turn_on_off.md#on-gitlab-self-managed-2) 설정합니다.
- MCP 서버에 대한 액세스를 허용합니다.
  - GitLab.com에서 [최상위 그룹에 대해](../group/access_and_permissions.md#allow-access-to-the-mcp-server) 설정합니다.
  - GitLab Self-Managed 및 GitLab Dedicated에서 [인스턴스에 대해](../../administration/settings/visibility_and_access_controls.md#allow-access-to-the-mcp-server) 설정합니다.

## 클라이언트를 GitLab MCP 서버에 연결 {#connect-a-client-to-the-gitlab-mcp-server}

GitLab MCP 서버는 두 가지 전송 유형을 지원합니다.

- **HTTP transport (recommended)**: 추가 종속성 없이 직접 연결합니다.
- **`mcp-remote`을 사용한 stdio 전송**: 프록시를 통한 연결(Node.js 필수)입니다.

일반적인 AI 도구는 `mcpServers` 키에 대한 JSON 구성 형식을 지원하며 GitLab MCP 서버 설정을 구성하는 다양한 방법을 제공합니다.

### HTTP 전송 (권장) {#http-transport-recommended}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/577575)되었습니다.
- 도구 접두사가 GitLab 18.11에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230406)되었습니다.

{{< /history >}}

HTTP 전송을 사용하여 GitLab MCP 서버를 구성하려면 다음 형식을 사용합니다.

- `<gitlab.example.com>`을 다음으로 바꿉니다.
  - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
  - GitLab.com에서 `gitlab.com`입니다.

```json
{
  "mcpServers": {
    "GitLab": {
      "type": "http",
      "url": "https://<gitlab.example.com>/api/v4/mcp"
    }
  }
}
```

`X-Gitlab-Mcp-Server-Tool-Name-Prefix` HTTP 헤더를 구성하여 도구 이름에 접두사를 추가할 수 있습니다. 접두사를 지정하면 다른 MCP 서버 또는 구성의 여러 GitLab 인스턴스와 도구 이름 충돌을 방지할 수 있습니다.

접두사가 이 제한을 초과하면 처음 32자로 잘립니다.

```json
{
  "mcpServers": {
    "GitLab": {
      "type": "http",
      "url": "https://<gitlab.example.com>/api/v4/mcp",
      "headers": {
        "X-Gitlab-Mcp-Server-Tool-Name-Prefix": "gitlab_"
      }
    }
  }
}
```

### `mcp-remote`을 사용한 stdio 전송 {#stdio-transport-with-mcp-remote}

사전 요구 사항:

- Node.js 버전 20 이상을 설치합니다.

stdio 전송을 사용하여 GitLab MCP 서버를 구성하려면 다음 형식을 사용합니다.

- `"command":` 매개변수의 경우 `npx`가 전역 대신 로컬로 설치된 경우 `npx`에 대한 전체 경로를 제공합니다.
- `<gitlab.example.com>`을 다음으로 바꿉니다.
  - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
  - GitLab.com에서 `gitlab.com`입니다.

```json
{
  "mcpServers": {
    "GitLab": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://<gitlab.example.com>/api/v4/mcp"
      ]
    }
  }
}
```

## Cursor를 GitLab MCP 서버에 연결 {#connect-cursor-to-the-gitlab-mcp-server}

Cursor는 HTTP 전송을 사용하여 추가 종속성 없이 직접 연결합니다. Cursor에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. Cursor에서 **설정** > **Cursor Settings** > **Tools & MCP**로 이동합니다.
1. **Installed MCP Servers** 아래에서 **New MCP Server**를 선택합니다.
1. 열린 `mcp.json` 파일의 `mcpServers` 키에 다음 정의를 추가합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `gitlab.com`입니다.

   ```json
   {
     "mcpServers": {
       "GitLab": {
          "type": "http",
          "url": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. 파일을 저장하고 브라우저에서 OAuth 승인 페이지를 열 때까지 기다립니다.

   이 작업이 수행되지 않으면 Cursor를 닫고 다시 시작합니다.
1. 브라우저에서 승인 요청을 검토하고 승인합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## Claude Code를 GitLab MCP 서버에 연결 {#connect-claude-code-to-the-gitlab-mcp-server}

Claude Code는 HTTP 전송을 사용하여 추가 종속성 없이 직접 연결합니다. Claude Code에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. 터미널에서 CLI를 사용하여 GitLab MCP 서버를 추가합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `gitlab.com`입니다.

   ```shell
   claude mcp add --transport http GitLab https://<gitlab.example.com>/api/v4/mcp
   ```

1. Claude Code를 시작합니다.

   ```shell
   claude
   ```

1. GitLab MCP 서버로 인증합니다.
   - 채팅에서 `/mcp`을 입력합니다.
   - 목록에서 GitLab 서버를 선택합니다.
   - 브라우저에서 승인 요청을 검토하고 승인합니다.

1. 선택 사항입니다. 연결을 확인하려면 `/mcp`을 다시 입력합니다. GitLab 서버가 연결됨으로 표시되어야 합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## Claude Desktop을 GitLab MCP 서버에 연결 {#connect-claude-desktop-to-the-gitlab-mcp-server}

사전 요구 사항:

- Node.js 버전 20 이상을 설치합니다.
- `PATH` 환경 변수에서 Node.js를 전역으로 사용할 수 있습니다(`which -a node`).

Claude Desktop에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. Claude Desktop을 엽니다.
1. 구성 파일을 편집합니다. 다음 중 하나를 수행할 수 있습니다.
   - Claude Desktop에서 **설정** > **개발자** > **Edit Config**로 이동합니다.
   - macOS에서 `~/Library/Application Support/Claude/claude_desktop_config.json` 파일을 엽니다.
1. GitLab MCP 서버에 대해 이 항목을 추가하고 필요에 따라 편집합니다.
   - `"command":` 매개변수의 경우 `npx`가 전역 대신 로컬로 설치된 경우 `npx`에 대한 전체 경로를 제공합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `GitLab.com`입니다.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "-y",
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp"
         ]
       }
     }
   }
   ```

1. 구성을 저장하고 Claude Desktop을 다시 시작합니다.
1. 처음 연결할 때 Claude Desktop은 OAuth를 위해 브라우저 창을 엽니다. 요청을 검토하고 승인합니다.
1. **설정** > **개발자**로 이동하여 새 GitLab MCP 구성을 확인합니다.
1. **설정** > **Connectors**로 이동하여 연결된 GitLab MCP 서버를 검사합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## Gemini Code Assist 및 Gemini CLI를 GitLab MCP 서버에 연결 {#connect-gemini-code-assist-and-gemini-cli-to-the-gitlab-mcp-server}

Gemini Code Assist 및 Gemini CLI는 HTTP 전송을 사용하여 추가 종속성 없이 직접 연결합니다. Gemini Code Assist 또는 Gemini CLI에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. `~/.gemini/settings.json`을 편집하고 GitLab MCP 서버를 추가합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `gitlab.com`입니다.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "httpUrl": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. Gemini Code Assist 또는 Gemini CLI에서 `/mcp auth GitLab` 명령을 실행합니다.

   OAuth 승인 페이지가 나타나야 합니다. 그렇지 않으면 Gemini Code Assist 또는 Gemini CLI를 다시 시작합니다.

1. 브라우저에서 승인 요청을 검토하고 승인합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## GitHub Copilot in VS Code를 GitLab MCP 서버에 연결 {#connect-github-copilot-in-vs-code-to-the-gitlab-mcp-server}

GitHub Copilot은 HTTP 전송을 사용하여 추가 종속성 없이 직접 연결합니다. GitHub Copilot in VS Code에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. VS Code에서 Command Palette를 엽니다.
   - macOS에서 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
   - Windows 또는 Linux에서 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
1. `MCP: Add Server`을 입력하고 <kbd>Enter</kbd>를 누릅니다.
1. 서버 유형으로 **HTTP**를 선택합니다.
1. 서버 URL로 `https://<gitlab.example.com>/api/v4/mcp`을 입력합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `gitlab.com`입니다.
1. 서버 ID로 `GitLab`을 입력합니다.
1. 구성을 전역으로 또는 `vscode/mcp.json` 워크스페이스에 저장합니다.

   OAuth 승인 페이지가 나타나야 합니다. 그렇지 않으면 Command Palette를 열고 **MCP: List Servers**를 검색하여 상태를 확인하거나 서버를 다시 시작합니다.

1. 브라우저에서 승인 요청을 검토하고 승인합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## Kiro IDE 및 CLI를 GitLab MCP 서버에 연결 {#connect-kiro-ide-and-cli-to-the-gitlab-mcp-server}

Kiro IDE 및 CLI는 HTTP 전송을 사용하여 추가 종속성 없이 직접 연결합니다. Kiro IDE 또는 CLI에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. `~/.kiro/settings/mcp.json`을 편집하고 GitLab MCP 서버를 추가합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `gitlab.com`입니다.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "type": "http",
         "url": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. 구성을 저장합니다.

   OAuth 승인 페이지가 나타나야 합니다. 그렇지 않으면 Kiro CLI를 열고 `/mcp` 명령을 실행합니다.

1. 브라우저에서 승인 요청을 검토하고 승인합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## OpenAI Codex를 GitLab MCP 서버에 연결 {#connect-openai-codex-to-the-gitlab-mcp-server}

OpenAI Codex는 HTTP 전송을 사용하여 추가 종속성 없이 직접 연결합니다. OpenAI Codex에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. 터미널에서 CLI를 사용하여 GitLab MCP 서버를 추가합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `gitlab.com`입니다.

   ```shell
   codex mcp add GitLab --url "https://<gitlab.example.com>/api/v4/mcp"
   ```

1. `~/.codex/config.toml`을 편집하고 `[features]` 섹션에서 `rmcp_client` 기능 플래그를 사용으로 설정합니다.

   ```toml
   [features]
   "rmcp_client" = true

   [mcp_servers.GitLab]
   url = "https://<gitlab.example.com>/api/v4/mcp"
   ```

1. 로그인 플로우을 실행하고 GitLab 인스턴스로 인증합니다.

   ```shell
   codex mcp login GitLab
   ```

1. 브라우저에서 승인 요청을 검토하고 승인합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## Zed를 GitLab MCP 서버에 연결 {#connect-zed-to-the-gitlab-mcp-server}

사전 요구 사항:

- Node.js 버전 20 이상을 설치합니다.
- `PATH` 환경 변수에서 Node.js를 전역으로 사용할 수 있습니다(`which -a node`).

Zed에서 GitLab MCP 서버를 구성하려면 다음을 수행합니다.

1. Zed에서 Command Palette를 엽니다.
   - macOS에서 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
   - Windows 또는 Linux에서 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누릅니다.
1. `agent: open settings`을 입력하고 <kbd>Enter</kbd>를 누릅니다.
1. **Model Context Protocol (MCP) Servers** 섹션에서 **Add Server**를 선택합니다.
1. `args`의 서버 URL로 `https://<gitlab.example.com>/api/v4/mcp`을 사용합니다.
   - `<gitlab.example.com>`을 다음으로 바꿉니다.
     - GitLab Self-Managed에서 GitLab 인스턴스 URL입니다.
     - GitLab.com에서 `gitlab.com`입니다.

   ```json
   {
     /// The name of your MCP server
     "GitLab": {
       /// The command which runs the MCP server
       "command": "npx",
       /// The arguments to pass to the MCP server
       "args": ["-y","mcp-remote@latest","https://<gitlab.example.com>/api/v4/mcp"],
       /// The environment variables to set
       "env": {}
     }
   }
   ```

1. 구성을 저장합니다.

   OAuth 승인 페이지가 나타나야 합니다. 그렇지 않으면 **GitLab** 토글을 끄고 다시 켭니다.

1. 브라우저에서 승인 요청을 검토하고 승인합니다.

이제 새 채팅을 시작하고 [사용 가능한 도구](mcp_server_tools.md)에 따라 질문을 할 수 있습니다.

> [!warning]
> 이러한 도구를 사용할 때 프롬프트 인젝션으로부터 보호할 책임이 있습니다. 극도의 주의를 기울이거나 신뢰할 수 있는 GitLab 객체에만 MCP 도구를 사용합니다.

## 단일 OAuth 애플리케이션 재사용 {#reuse-a-single-oauth-application}

{{< history >}}

- 관리자 UI를 통한 OAuth 애플리케이션 만들기는 GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245979)되었습니다.
- 그룹 및 사용자 UI를 통한 OAuth 애플리케이션 만들기는 GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247698)되었습니다.

{{< /history >}}

MCP 클라이언트가 GitLab MCP 서버에 연결할 때 OAuth 2.0 Dynamic Client Registration (DCR)을 사용하여 GitLab 인스턴스에 새 OAuth 애플리케이션을 만듭니다.

사전 등록된 OAuth 애플리케이션을 재사용하여 DCR의 다음 문제를 방지합니다.

- GitLab Self-Managed 및 GitLab Dedicated에서 많은 사용자 또는 반복적으로 연결하는 클라이언트는 인스턴스에 많은 수의 OAuth 애플리케이션을 만들 수 있습니다.
- IP 주소는 DCR 요청을 시간당 10개 등록으로 속도 제한합니다. 회사 네트워크 또는 VPN과 같이 송신 IP 주소를 공유하는 사용자는 이 제한을 초과하고 MCP 서버에 대한 인증에 실패할 수 있습니다.

모든 사용자는 여전히 OAuth로 인증하고 자신의 액세스 토큰을 받습니다. 공유 애플리케이션은 OAuth 클라이언트 ID이지 공유 자격증명이 아닙니다.

누가 다시 사용하는지에 따라 다음 범위 중 하나에 대한 OAuth 애플리케이션을 만듭니다.

- 인스턴스: 인스턴스의 모든 사용자가 공유합니다.
- 그룹: 그룹의 구성원이 공유합니다.
- 사용자: 사용자 자신의 계정입니다.

사전 요구 사항:

- 다음을 지원하는 MCP 클라이언트:
  - 사전 구성된 OAuth 자격증명
  - 해당 구성의 `clientId` 필드
- 인스턴스에 대해 애플리케이션을 만드는 경우 관리자 액세스 권한을 보유합니다.
- 그룹에 대해 애플리케이션을 만드는 경우 그룹의 소유자 역할을 보유합니다.

OAuth 애플리케이션을 만들려면 다음을 수행합니다.

1. [인스턴스](../../integration/oauth_provider.md#create-an-instance-wide-application), [그룹](../../integration/oauth_provider.md#create-a-group-owned-application) 또는 [사용자](../../integration/oauth_provider.md#create-a-user-owned-application)에 대한 OAuth 애플리케이션을 만듭니다.
1. 범위의 경우 **mcp**를 선택하고 **기밀** 확인란을 선택 해제합니다.
1. 애플리케이션을 저장합니다.
1. 애플리케이션 ID로 MCP 클라이언트를 구성하거나 애플리케이션 ID를 애플리케이션을 재사용하는 사용자에게 제공합니다. 애플리케이션 ID는 `clientId`입니다. 구성 키는 클라이언트에 따라 다르지만 일반적으로 GitLab MCP 서버의 OAuth 구성에서 이름이 `clientId` 또는 `client_id`이며 일반적으로 `mcp.json` 파일에 있습니다.

인스턴스 및 사용자 애플리케이션의 경우 [REST API](../../api/applications.md#create-an-application)를 사용하여 애플리케이션을 만들 수도 있습니다. 그룹 소유 애플리케이션에는 REST API가 없으므로 그룹 UI를 사용해야 합니다.

> [!note]
> OAuth 애플리케이션에 등록된 리디렉션 URI는 OAuth 플로우 중에 MCP 클라이언트가 보내는 리디렉션 URI와 정확히 일치해야 합니다. 사용 중인 리디렉션 URI에 대해 클라이언트의 설명서를 확인합니다. 단일 공유 OAuth 애플리케이션은 다른 리디렉션 URI를 사용하는 MCP 클라이언트를 제공할 수 없습니다. 사용자가 다른 리디렉션 URI를 사용하는 MCP 클라이언트를 사용하는 경우 각 클라이언트 유형에 대해 별도의 공유 OAuth 애플리케이션을 만듭니다.

### 보안 고려 사항 {#security-considerations}

클라이언트 ID로 인증하는 사용자는 여전히 자신의 GitLab 자격증명으로 OAuth 승인을 완료해야 합니다. 자신에게 허용된 데이터에만 액세스할 수 있습니다.

GitLab은 `clientId`를 제시하는 MCP 클라이언트 애플리케이션을 확인하지 않습니다. 특정 MCP 클라이언트에 대한 OAuth 애플리케이션을 만들려면 사전 등록을 지원하는 다른 MCP 클라이언트도 동일한 `clientId`를 사용하여 인증할 수 있습니다. `clientId`은 어떤 클라이언트 소프트웨어를 허용하는지가 아니라 어떤 OAuth 애플리케이션을 사용할지를 제어합니다.

REST API로 만든 미리 등록된 애플리케이션은 PKCE(Proof Key for Code Exchange)를 적용하지 않습니다. PKCE는 공개 클라이언트에 대해 권한 부여 코드 도용으로부터 방어합니다.

PKCE를 적용하려면 MCP 클라이언트가 OAuth 플로우 중에 `code_challenge` 및 `code_challenge_method` 매개 변수를 보내는지 확인합니다. GitLab은 사전 등록된 애플리케이션에 대한 PKCE 매개변수를 수락하지만 요구하지 않습니다.

## 관련 항목 {#related-topics}

- [AI 카탈로그의 MCP 서버](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md)
