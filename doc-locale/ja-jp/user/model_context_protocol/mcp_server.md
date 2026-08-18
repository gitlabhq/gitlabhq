---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIツールをGitLabインスタンスに接続して、GitLab MCPサーバーで利用できるようにします。
title: GitLab MCPサーバー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.3で[実験](../../policy/development_stages_support.md#experiment)として、`mcp_server`および`oauth_dynamic_client_registration`という名前の[機能フラグ](../../administration/feature_flags/_index.md)と共に導入されました。デフォルトでは無効になっています。
- 実験からGitLab 18.6で[ベータ](../../policy/development_stages_support.md#beta)に変わりました。機能フラグ[`mcp_server`](https://gitlab.com/gitlab-org/gitlab/-/issues/556448)および[`oauth_dynamic_client_registration`](https://gitlab.com/gitlab-org/gitlab/-/issues/555942)は削除されました。
- `2025-03-26`および`2025-06-18` MCPプロトコル仕様のサポートがGitLab 18.7で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/581459)されました。
- [別々の設定に変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/590729)され、GitLab 19.2でGitLab PremiumからFreeに[移行](https://gitlab.com/groups/gitlab-org/-/work_items/21183)されました。

{{< /history >}}

> [!warning]
> この機能に関するフィードバックを提供するには、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントしてください。

GitLab [Model Context Protocol](https://modelcontextprotocol.io/)（MCP）サーバーを使用すると、AIツールとアプリケーションをGitLabインスタンスに安全に接続できます。Claude Desktop、Claude Code、CursorなどのAIアシスタントやその他のMCP互換ツールは、GitLabデータにアクセスし、ユーザーに代わってアクションを実行できます。

GitLab MCPサーバーは、AIツールが以下のことを行うための標準化された方法を提供します:

- GitLabプロジェクト情報にアクセスします。
- イシューとマージリクエストのデータを取得します。
- GitLab APIと安全にやり取りします。
- AIアシスタントを介してGitLab固有の操作を実行します。

GitLab MCPサーバーは、[OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)をサポートしており、AIツールはGitLabインスタンスに自身を登録できます。AIツールが初めてGitLab MCPサーバーに接続すると、次を実行します:

1. OAuthアプリケーションとして自身を登録します。
1. GitLabデータへのアクセス認可をリクエストします。
1. 安全なAPIアクセス用のアクセストークンを受信します。

クリック操作のデモについては、[GitLab Duo Agent Platform - GitLab MCPサーバー](https://gitlab.navattic.com/gitlab-mcp-server)を参照してください。
<!-- Demo published on 2025-09-11 -->

## 前提条件 {#prerequisites}

- GitLab Duoの利用可能性を**常にオン**または**デフォルトでオン**に設定します:
  - GitLab.comでは、[トップレベルグループの場合](../../user/gitlab_duo/turn_on_off.md#for-a-top-level-group)。
  - GitLab Self-ManagedおよびGitLab Dedicatedでは、[インスタンスの場合](../../user/gitlab_duo/turn_on_off.md#for-an-instance)。
- ベータ版機能と実験的機能を有効にします:
  - GitLab.comでは、[トップレベルグループの場合](../../user/gitlab_duo/turn_on_off.md#on-gitlabcom-2)。
  - GitLab Self-ManagedおよびGitLab Dedicatedでは、[インスタンスの場合](../../user/gitlab_duo/turn_on_off.md#on-gitlab-self-managed-2)。
- MCPサーバーへのアクセスを許可します:
  - GitLab.comでは、[トップレベルグループの場合](../group/access_and_permissions.md#allow-access-to-the-mcp-server)。
  - GitLab Self-ManagedおよびGitLab Dedicatedでは、[インスタンスの場合](../../administration/settings/visibility_and_access_controls.md#allow-access-to-the-mcp-server)。

## GitLab MCPサーバーにクライアントを接続する {#connect-a-client-to-the-gitlab-mcp-server}

GitLab MCPサーバーは2つのトランスポートタイプをサポートしています:

- **HTTPトランスポート（推奨）**: 追加の依存関係なしでの直接接続。
- **stdio transport with `mcp-remote`**: プロキシ経由での接続（Node.jsが必要）。

一般的なAIツールは、`mcpServers`キーのJSON設定形式をサポートしており、GitLab MCPサーバーの設定を行うためのさまざまな方法を提供します。

### HTTPトランスポート（推奨） {#http-transport-recommended}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/577575)されました。
- ツールのプレフィックスがGitLab 18.11で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230406)されました。

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

`X-Gitlab-Mcp-Server-Tool-Name-Prefix` HTTPヘッダーを設定することで、ツール名にプレフィックスを追加できます。プレフィックスを付けることで、他のMCPサーバーや設定内の複数のGitLabインスタンスとのツール名衝突を回避できます。

プレフィックスがこの制限を超えた場合、最初の32文字に切り詰められます。

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

### `mcp-remote`を使用したstdioトランスポート {#stdio-transport-with-mcp-remote}

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
1. 開いた`mcp.json`ファイル内の`mcpServers`キーに、この定義を追加します:
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

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## Claude CodeをGitLab MCPサーバーに接続する {#connect-claude-code-to-the-gitlab-mcp-server}

Claude Codeは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。Claude CodeでGitLab MCPサーバーを設定するには:

1. ターミナルで、CLIを使用してGitLab MCPサーバーを追加します:
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。

   ```shell
   claude mcp add --transport http GitLab https://<gitlab.example.com>/api/v4/mcp
   ```

1. Claude Codeを起動します:

   ```shell
   claude
   ```

1. GitLab MCPサーバーで認証します:
   - チャットで、`/mcp`と入力します。
   - リストからGitLabサーバーを選択します。
   - ブラウザで、認可リクエストを確認して承認します。

1. オプション。接続を確認するには、もう一度`/mcp`と入力します。お使いのGitLabサーバーが接続済みとして表示されるはずです。

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## Claude DesktopをGitLab MCPサーバーに接続する {#connect-claude-desktop-to-the-gitlab-mcp-server}

前提条件: 

- Node.jsバージョン20以降をインストールします。
- Node.jsが`PATH`環境変数（`which -a node`）でグローバルに利用できる状態であること。

Claude DesktopでGitLab MCPサーバーを設定するには:

1. Claude Desktopを開きます。
1. 設定ファイルを編集します。次のいずれかを実行します:
   - Claude Desktopで、**Settings** > **Developer** > **Edit Config**に移動します。
   - macOSで、`~/Library/Application Support/Claude/claude_desktop_config.json`ファイルを開きます。
1. GitLab MCPサーバーのこのエントリを、必要に応じて編集して追加します:
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
1. **設定** > **Connectors**に移動し、接続されているGitLab MCPサーバーを調べます。

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## Gemini Code AssistとGemini CLIをGitLab MCPサーバーに接続する {#connect-gemini-code-assist-and-gemini-cli-to-the-gitlab-mcp-server}

Gemini Code AssistとGemini CLIは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。Gemini Code AssistまたはGemini CLIでGitLab MCPサーバーを設定するには:

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

   OAuth認可ページが表示されるはずです。そうでない場合は、Gemini Code AssistまたはGemini CLIを再起動してください。

1. ブラウザで、認可リクエストを確認して承認します。

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## VS CodeのGitHub CopilotをGitLab MCPサーバーに接続する {#connect-github-copilot-in-vs-code-to-the-gitlab-mcp-server}

GitHub Copilotは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。VS CodeのGitHub CopilotでGitLab MCPサーバーを設定するには:

1. VS Codeでコマンドパレットを開きます。
   - macOSで、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   - WindowsまたはLinuxで、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `MCP: Add Server`と入力して<kbd>Enter</kbd>キーを押します。
1. サーバータイプには、**HTTP**を選択します。
1. サーバーURLには、`https://<gitlab.example.com>/api/v4/mcp`と入力します。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`gitlab.com`。
1. サーバーIDには、`GitLab`と入力します。
1. 設定をグローバルに、または`vscode/mcp.json`ワークスペースに保存します。

   OAuth認可ページが表示されるはずです。そうでない場合は、コマンドパレットを開いて**MCPを検索します: List Servers**でステータスを確認するか、サーバーを再起動してください。

1. ブラウザで、認可リクエストを確認して承認します。

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## Kiro IDEおよびCLIをGitLab MCPサーバーに接続する {#connect-kiro-ide-and-cli-to-the-gitlab-mcp-server}

Kiro IDEおよびCLIは、追加の依存関係なしに直接接続するためにHTTPトランスポートを使用します。Kiro IDEまたはCLIでGitLab MCPサーバーを設定するには:

1. `~/.kiro/settings/mcp.json`を編集し、GitLab MCPサーバーを追加します。
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

1. 設定を保存します。

   OAuth認可ページが表示されるはずです。そうでない場合は、Kiro CLIを開いて`/mcp`コマンドを実行してください。

1. ブラウザで、認可リクエストを確認して承認します。

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

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

1. ログインフローを実行し、GitLabインスタンスで認証します。

   ```shell
   codex mcp login GitLab
   ```

1. ブラウザで、認可リクエストを確認して承認します。

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## ZedをGitLab MCPサーバーに接続する {#connect-zed-to-the-gitlab-mcp-server}

前提条件: 

- Node.jsバージョン20以降をインストールします。
- Node.jsが`PATH`環境変数（`which -a node`）でグローバルに利用できる状態であること。

ZedでGitLab MCPサーバーを設定するには:

1. Zedで、コマンドパレットを開きます:
   - macOSで、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   - WindowsまたはLinuxで、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `agent: open settings`と入力して<kbd>Enter</kbd>キーを押します。
1. **Model Context Protocol（MCP）Servers**セクションで、**Add Server**を選択します。
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

   OAuth認可ページが表示されるはずです。表示されない場合は、**GitLab**切替をオフにしてからもう一度オンにします。

1. ブラウザで、認可リクエストを確認して承認します。

これで、新しいチャットを開始し、[利用可能なツール](mcp_server_tools.md)に応じて質問できます。

> [!warning]
> これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

## 単一のOAuthアプリケーションを再利用する {#reuse-a-single-oauth-application}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- UIを介したOAuthアプリケーションの作成がGitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245979)されました。

{{< /history >}}

MCPクライアントがGitLab MCPサーバーに接続すると、OAuth 2.0 Dynamic Client Registration（DCR）を使用して、GitLabインスタンスに新しいOAuthアプリケーションを作成します。多数のユーザーまたは頻繁な再接続がある環境では、これによりインスタンス上に多数のOAuthアプリケーションが作成される可能性があります。

多数のOAuthアプリケーションを避けるには、単一の共有OAuthアプリケーションを作成し、そのクライアントIDをユーザーに提供します。

ユーザーがこのクライアントIDでMCPクライアントを設定すると、すべての接続が新しいOAuthアプリケーションを作成する代わりに、同じOAuthアプリケーションを再利用します。

ユーザーが共有された`clientId`で認証すると、GitLabは同じ設定を持つどのユーザーからの後続の認証に対しても同じOAuthアプリケーションを再利用します。ユーザーはOAuthで認可し、独自のアクセストークンを受け取ります。共有アプリケーションはOAuthクライアントの識別情報であり、共有認証情報ではありません。

前提条件: 

- 管理者である必要があります。
- 以下をサポートするMCPクライアント:
  - 事前設定済みのOAuth認証情報
  - 設定内の`clientId`フィールド

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**アプリケーション** > **新しいアプリケーション**を選択します。
1. フィールドに入力します。**mcp**スコープを選択し、**非公開**チェックボックスをクリアします。
1. **アプリケーションを保存**を選択します。
1. アプリケーションIDをユーザーに提供します。これは、ユーザーがMCPクライアントで設定する`clientId`です。設定キーはクライアントによって異なりますが、通常、GitLab MCPサーバーのOAuth設定では`clientId`または`client_id`という名前です。これは通常、`mcp.json`ファイル内にあります。

[REST API](../../api/applications.md#create-an-application)を使用してアプリケーションを作成することもできます。

> [!note]
> OAuthアプリケーションに登録されたリダイレクトURIは、MCPクライアントがOAuthフロー中に送信するリダイレクトURIと完全に一致する必要があります。クライアントのドキュメントで、使用するリダイレクトURIを確認してください。単一の共有OAuthアプリケーションは、異なるリダイレクトURIを使用するMCPクライアントにサービスを提供できません。ユーザーが異なるリダイレクトURIを使用するMCPクライアントを使用している場合は、クライアントタイプごとに個別の共有OAuthアプリケーションを作成してください。

### セキュリティに関する考慮事項 {#security-considerations}

クライアントIDで認証するユーザーは、引き続き独自のGitLab認証情報でOAuth認可を完了する必要があります。彼らは許可されたデータのみにアクセスできます。

GitLabは、どのMCPクライアントアプリケーションが`clientId`を提示するかを検証しません。特定のMCPクライアント用にOAuthアプリケーションを作成した場合、事前登録をサポートする他のどのMCPクライアントも同じ`clientId`を使用して認証できます。`clientId`は、どのOAuthアプリケーションが使用されるかを制御し、どのクライアントソフトウェアが許可されるかを制御するものではありません。

REST APIで作成された事前登録済みアプリケーションは、証明キーfor Code Exchange（PKCE）を強制しません。PKCEは、パブリッククライアントに対する認可コードの傍受を防ぎます。

PKCEを強制するには、MCPクライアントがOAuthフロー中に`code_challenge`と`code_challenge_method`パラメータを送信することを確認してください。GitLabは事前登録済みアプリケーションのPKCEパラメータを受け入れますが、必須ではありません。

## 関連トピック {#related-topics}

- [AIカタログ内のMCPサーバー](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md)
