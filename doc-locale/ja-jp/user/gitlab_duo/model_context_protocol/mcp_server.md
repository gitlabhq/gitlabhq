---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIツールをGitLab Model Context Protocol（MCP）サーバーと接続します。
title: GitLab MCPサーバー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.3で[実験](../../../policy/development_stages_support.md#experiment)として[フラグ](../../../administration/feature_flags/_index.md)`mcp_server`および`oauth_dynamic_client_registration`として導入されました。デフォルトでは無効になっています。
- GitLab 18.6で実験から[ベータ](../../../policy/development_stages_support.md#beta)に変更されました。機能フラグ[`mcp_server`](https://gitlab.com/gitlab-org/gitlab/-/issues/556448)および[`oauth_dynamic_client_registration`](https://gitlab.com/gitlab-org/gitlab/-/issues/555942)は削除されました。
- GitLab 18.7で`2025-03-26`および`2025-06-18`のMCPプロトコル仕様への[サポートが追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/581459)。

{{< /history >}}

> [!warning]
> この機能に関するフィードバックを提供するには、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントしてください。

GitLab [Model Context Protocol](https://modelcontextprotocol.io/)（MCP）サーバーを使用すると、AIツールとアプリケーションをGitLabインスタンスに安全に接続できます。Claude Desktop、Claude Code、CursorなどのAIアシスタントやその他のMCP互換ツールは、GitLabデータにアクセスし、ユーザーに代わってアクションを実行できます。

GitLab MCPサーバーは、AIツールが次のことを標準化する方法を提供します:

- GitLabプロジェクト情報にアクセスします。
- イシューとマージリクエストのデータを取得します。
- GitLab APIと安全にやり取りします。
- AIアシスタントを介してGitLab固有の操作を実行します。

GitLab MCPサーバーは、[OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)をサポートしており、AIツールはGitLabインスタンスに自身を登録できます。AIツールが初めてGitLab MCPサーバーに接続すると、次を実行します:

1. OAuthアプリケーションとして自身を登録します。
1. GitLabデータへのアクセス認可をリクエストします。
1. 安全なAPIアクセス用のアクセストークンを受信します。

クリックスルーデモについては、[GitLab Duo Agent Platform - GitLab MCPサーバー](https://gitlab.navattic.com/gitlab-mcp-server)を参照してください。
<!-- Demo published on 2025-09-11 -->

## 前提条件 {#prerequisites}

- [GitLab Duo](../../duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off)および[ベータ版と実験的機能](../../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features)が有効になっていることを確認します。

## クライアントをGitLab MCPサーバーに接続する {#connect-a-client-to-the-gitlab-mcp-server}

GitLab MCPサーバーは2つのトランスポートタイプをサポートしています:

- **HTTPトランスポート（推奨）**: 追加の依存関係なしに直接接続します。
- **`mcp-remote`を使用したstdioトランスポート**: プロキシ経由の接続（Node.jsが必要）。

一般的なAIツールは、`mcpServers`キーのJSON設定形式をサポートしており、GitLab MCPサーバーの設定を設定するためのさまざまな方法を提供します。

### HTTPトランスポート（推奨） {#http-transport-recommended}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/577575)されました。

{{< /history >}}

HTTPトランスポートを使用してGitLab MCPサーバーを設定するには、この形式を使用します:

- `<gitlab.example.com>`を以下に置き換えます:
  - GitLab Self-Managedでは、GitLabインスタンスのURL。
  - GitLab.comでは、`gitlab.com`。

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

### stdioトランスポートと`mcp-remote` {#stdio-transport-with-mcp-remote}

前提条件: 

- Node.jsバージョン20以降をインストールします。

stdioトランスポートを使用してGitLab MCPサーバーを設定するには、この形式を使用します:

- `"command":`パラメータの場合、`npx`がグローバルではなくローカルにインストールされている場合は、`npx`へのフルパスを指定してください。
- `<gitlab.example.com>`を以下に置き換えます:
  - GitLab Self-Managedでは、GitLabインスタンスのURL。
  - GitLab.comでは、`gitlab.com`。

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

## CursorをGitLab MCPサーバーに接続する {#connect-cursor-to-the-gitlab-mcp-server}

Cursorは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。CursorでGitLab MCPサーバーを設定するには:

1. Cursorで、**設定** > **Cursor Settings** > **Tools & MCP**に移動します。
1. **Installed MCP Servers**の下で、**New MCP Server**を選択します。
1. 開いている`mcp.json`ファイル内の`mcpServers`キーにこの定義を追加します:
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。

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

1. ファイルを保存し、ブラウザでOAuth認可ページが開くのを待ちます。

   ページが開かない場合は、Cursorを閉じて再起動します。
1. ブラウザで、認可リクエストを確認して承認します。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## Claude CodeをGitLab MCPサーバーに接続する {#connect-claude-code-to-the-gitlab-mcp-server}

Claude Codeは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。Claude CodeでGitLab MCPサーバーを設定するには:

1. ターミナルで、CLIを使用してGitLab MCPサーバーを追加します:
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。

   ```shell
   claude mcp add --transport http GitLab https://<gitlab.example.com>/api/v4/mcp
   ```

1. Claude Codeを開始します:

   ```shell
   claude
   ```

1. GitLab MCPサーバーで認証するします:
   - チャットで、`/mcp`と入力します。
   - リストからGitLabサーバーを選択します。
   - ブラウザで、認可リクエストを確認して承認します。

1. オプション。接続を確認するには、再度`/mcp`と入力します。GitLabサーバーが接続済みとして表示されるはずです。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## Claude DesktopをGitLab MCPサーバーに接続する {#connect-claude-desktop-to-the-gitlab-mcp-server}

前提条件: 

- Node.jsバージョン20以降をインストールします。
- `PATH`環境変数（`which -a node`）にNode.jsがグローバルで利用可能であることを確認します。

Claude DesktopでGitLab MCPサーバーを設定するには:

1. Claude Desktopを開きます。
1. 設定ファイルを編集します。次のいずれかを実行します:
   - Claude Desktopで、**Setting** > **Developer** > **Edit Config**に移動します。
   - macOSで、`~/Library/Application Support/Claude/claude_desktop_config.json`ファイルを開きます。
1. 必要に応じて編集し、GitLab MCPサーバーにこのエントリを追加します:
   - `"command":`パラメータの場合、`npx`がグローバルではなくローカルにインストールされている場合は、`npx`へのフルパスを指定してください。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`GitLab.com`。

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

1. 設定を保存して、Claude Desktopを再起動します。
1. 最初の接続時に、Claude DesktopはOAuthのブラウザウィンドウを開きます。リクエストを確認して承認します。
1. **Settings** > **Developer**に移動し、新しいGitLab MCP設定を確認します。
1. **設定** > **Connectors**に移動し、接続されているGitLab MCPサーバーを検査します。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## Gemini codeアシストとGemini CLIをGitLab MCPサーバーに接続する {#connect-gemini-code-assist-and-gemini-cli-to-the-gitlab-mcp-server}

Gemini codeアシストとGemini CLIは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。Gemini codeアシストまたはGemini CLIでGitLab MCPサーバーを設定するには:

1. `~/.gemini/settings.json`を編集し、GitLab MCPサーバーを追加します。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "httpUrl": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. Gemini Code AssistまたはGemini CLIで、`/mcp auth GitLab`コマンドを実行します。

   OAuthの認可ページが表示されるはずです。そうでない場合は、Gemini Code AssistまたはGemini CLIを再起動してください。

1. ブラウザで、認可リクエストを確認して承認します。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## VS CodeでGitHub CopilotをGitLab MCPサーバーに接続する {#connect-github-copilot-in-vs-code-to-the-gitlab-mcp-server}

GitHub Copilotは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。VS CodeのGitHub CopilotでGitLab MCPサーバーを設定するには:

1. VS Codeでコマンドパレットを開きます。
   - macOSでは、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `MCP: Add Server`と入力して<kbd>Enter</kbd>キーを押します。
1. サーバータイプとして**HTTP**を選択します。
1. サーバーURLには、`https://<gitlab.example.com>/api/v4/mcp`を入力します。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。
1. サーバーIDには、`GitLab`を入力します。
1. 設定をグローバルに、または`vscode/mcp.json`ワークスペースに保存します。

   OAuthの認可ページが表示されるはずです。そうでない場合は、コマンドパレットを開き、**MCP: List Servers**のステータスを確認するか、サーバーを再起動します。

1. ブラウザで、認可リクエストを確認して承認します。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## VS CodeでContinueをGitLab MCPサーバーに接続する {#connect-continue-in-vs-code-to-the-gitlab-mcp-server}

前提条件: 

- Node.jsバージョン20以降をインストールします。
- `PATH`環境変数（`which -a node`）にNode.jsがグローバルで利用可能であることを確認します。

VS CodeのContinueでGitLab MCPサーバーを設定するには:

1. VS Codeのアクティビティバーで、Continue拡張機能を選択します。
1. 設定を開き、**ツール**を選択します。
1. **MCP Servers**の横に、新しいサーバーを追加します。
1. 設定ファイル`.continue/mcpServers/new-mcp-server.yaml`を編集します:
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。

   ```yaml
   name: GitLab MCP server
   version: 0.0.1
   schema: v1
   mcpServers:
     - name: GitLab MCP server
       type: stdio
       command: npx
       args:
         - mcp-remote
         - https://<gitlab.example.com>/api/v4/mcp
   ```

1. 設定を保存します。

   OAuthの認可ページが表示されるはずです。

1. ブラウザで、認可リクエストを確認して承認します。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## OpenAI CodexをGitLab MCPサーバーに接続する {#connect-openai-codex-to-the-gitlab-mcp-server}

OpenAI Codexは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。OpenAI CodexでGitLab MCPサーバーを設定するには:

1. ターミナルで、CLIを使用してGitLab MCPサーバーを追加します:
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。

   ```shell
   codex mcp add --url "https://<gitlab.example.com>/api/v4/mcp" GitLab
   ```

1. `~/.codex/config.toml`を編集し、`[features]`セクションで`rmcp_client`機能フラグを有効にします。

   ```toml
   [features]
   "rmcp_client" = true

   [mcp_servers.GitLab]
   url = "https://<gitlab.example.com>/api/v4/mcp"
   ```

1. ログインフローを実行し、GitLabインスタンスで認証するします。

   ```shell
   codex mcp login GitLab
   ```

1. ブラウザで、認可リクエストを確認して承認します。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## ZedをGitLab MCPサーバーに接続する {#connect-zed-to-the-gitlab-mcp-server}

前提条件: 

- Node.jsバージョン20以降をインストールします。
- `PATH`環境変数（`which -a node`）にNode.jsがグローバルで利用可能であることを確認します。

ZedでGitLab MCPサーバーを設定するには:

1. Zedで、コマンドパレットを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `agent: open settings`と入力して<kbd>Enter</kbd>キーを押します。
1. **Model Context Protocol (MCP) Servers**セクションで、**Add Server**を選択します。
1. `args`のサーバーURLには、`https://<gitlab.example.com>/api/v4/mcp`を使用します。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。

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

1. 設定を保存します。

   OAuthの認可ページが表示されるはずです。そうでない場合は、**GitLab**切替をオフにしてから再度オンにします。

1. ブラウザで、認可リクエストを確認して承認します。

これで、[利用可能なツール](mcp_server_tools.md)に応じて新しいチャットを開始し、質問することができます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションに対する防御に責任を負います。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。
