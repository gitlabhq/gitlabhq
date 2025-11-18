---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Model Context Protocolについてと、その使用方法について説明します。
title: GitLab Model Context Protocolクライアント
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- GitLab Duoとセルフホストモデルで利用可能: サポートされていません

{{< /collapsible >}}

{{< history >}}

- GitLab 18.1で`duo_workflow_mcp_support`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519938)されました。デフォルトでは無効になっています。
- GitLab 18.2の[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/545956)で有効になりました。機能フラグ`duo_workflow_mcp_support`は削除されました。
- GitLab 18.3で実験から[ベータ](https://gitlab.com/gitlab-org/gitlab/-/issues/545956)に変更されました。

{{< /history >}}

Model Context Protocolは、GitLab Duoの各機能がさまざまな外部データソースやツールに安全に接続するための標準化された方法を提供します。

以下の機能はMCPクライアントとして動作し、MCPサーバーから外部ツールに接続できます。:

- [GitLab Duo Agentic Chat](../../../user/gitlab_duo_chat/agentic_chat.md)
- [ソフトウェア開発フロー](../../../user/duo_agent_platform/flows/software_development.md)

これらの機能は、外部コンテキストと情報にアクセスして、より強力な回答を生成できます。

MCPで機能を使用するには、次の手順に従います。:

1. グループのMCPをオンにします。
1. 機能を接続するMCPサーバーを構成します。

クリック操作のデモについては、[Duo Agent Platform - MCP integration](https://gitlab.navattic.com/mcp)を参照してください。
<!-- Demo published on 2025-08-05 -->

## 前提要件 {#prerequisites}

MCPでGitLab Duo機能を使用する前に、以下を行う必要があります。:

- [VSCodium](https://vscodium.com/)または[Visual Studio Code](https://code.visualstudio.com/download)（VS Code）をインストールします。
- [Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow)または[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)からGitLab Workflow拡張機能を設定します。
  - MCPサポートには、バージョン6.28.2以降が必要です。
  - ワークスペースおよびユーザー設定機能には、バージョン6.35.6以降が必要です。
- [GitLab Duo Agent Platformの前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしていること。

## グループのMCPをオンにする {#turn-on-mcp-for-your-group}

グループのMCPをオンまたはオフにするには、次の手順に従います。:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **Model Context Protocol**の**Model Context Protocol (MCP)サポートを有効にする**チェックボックスをオンまたはオフにします。
1. **変更を保存**を選択します。

## MCPサーバーの設定 {#configure-mcp-servers}

MCPを言語サーバーと統合するには、ワークスペースの設定、ユーザー設定、またはその両方をセットアップします。GitLab言語サーバーは、設定ファイルを読み込み、マージします。

### バージョンの互換性 {#version-compatibility}

| GitLab Workflow拡張機能バージョン | 利用可能なMCP機能 |
|-----------------------------------|------------------------|
| 6.28.2 - 6.35.5  | ワークスペースまたはユーザー設定のない基本的なMCPサポート |
| 6.35.6以降 | ワークスペースとユーザー設定を含む、完全なMCPサポート |

### ワークスペース構成を作成 {#create-workspace-configuration}

ワークスペースの設定は、このプロジェクトにのみ適用され、同じサーバーのユーザー設定をオーバーライドします。

ワークスペースの設定を行うには、次の手順に従います。:

1. プロジェクトのワークスペースで、`<workspace>/.gitlab/duo/mcp.json`ファイルを作成します。
1. [構成形式](#configuration-format)を使用して、機能が接続するMCPサーバーに関する情報を追加します。
1. ファイルを保存します。
1. IDEを再起動します。

### ユーザー設定を作成する {#create-user-configuration}

ユーザー設定は、個人用ツールおよび一般的に使用されるサーバーに適しています。これらはすべてのワークスペースに適用されますが、同じサーバーのワークスペースの設定はユーザー設定をオーバーライドします。

ユーザー設定を行うには、次の手順に従います。:

1. VSCodiumまたはVS Codeで、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーまたは<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押してコマンドパレットを開きます。
1. コマンド`GitLab MCP: Open User Settings (JSON)`を実行して、ユーザー設定ファイルを作成して開きます。
1. [構成形式](#configuration-format)を使用して、機能が接続するMCPサーバーに関する情報を追加します。
1. ファイルを保存します。
1. IDEを再起動します。

または、次の場所に手動でファイルを作成します。:

- Windows: `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`
- その他すべてのオペレーティングシステム: `~/.gitlab/duo/mcp.json`

### 設定形式 {#configuration-format}

両方の設定ファイルは同じJSON形式を使用します。:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "path/to/server",
      "args": ["--arg1", "value1"],
      "env": {
        "ENV_VAR": "value"
      }
    },
    "http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    },
    "sse-server": {
      "type": "sse",
      "url": "http://localhost:3000/mcp/sse"
    }
  }
}
```

### MCPサーバー構成の例 {#example-mcp-server-configurations}

次のコード例を参考にして、MCPサーバーの設定ファイルを作成してください。

詳細と例については、[MCP example servers documentation](https://modelcontextprotocol.io/examples)を参照してください。その他のサーバー例としては、[Smithery.ai](https://smithery.ai/)と[Awesome MCP Servers](https://mcpservers.org/)があります。

#### ローカルサーバー {#local-server}

```json
{
  "mcpServers": {
    "enterprise-data-v2": {
      "type": "stdio",
      "command": "node",
      "args": ["src/server.js"],
      "cwd": "</path/to/your-mcp-server>"
    }
  }
}
```

#### `mcp-remote`を使用したリモートサーバー {#remote-server-with-mcp-remote}

```json
{
  "mcpServers": {
    "aws-knowledge": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://knowledge-mcp.global.api.aws"
      ]
    }
  }
}
```

#### HTTPサーバー {#http-server}

```json
{
  "mcpServers": {
    "local-http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

#### SSEサーバー {#sse-server}

```json
{
  "mcpServers": {
    "remote-sse-server": {
      "type": "sse",
      "url": "http://public.domain:3000/mcp/sse"
    }
  }
}
```

## MCPでGitLab Duo機能を使用する {#use-gitlab-duo-features-with-mcp}

{{< history >}}

- セッション全体の外部ツールを承認する機能が、GitLab 18.4で[added](https://gitlab.com/gitlab-org/gitlab/-/issues/556045)されました。

{{< /history >}}

GitLab Duo機能が質問に回答するために外部ツールを呼び出す場合、セッション全体で承認されていない限り、そのツールをレビューする必要があります。:

1. VS Codeを開きます。
1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（GitLab Duo Agent Platform (ベータ)）（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **チャット**または**フロー**タブを選択します。
1. テキストボックスに、質問を入力するか、コードタスクを指定します。
1. 質問またはコードタスクを送信します。
1. 次の場合に、**Tool Approval Required**（ツール承認が必要です）ダイアログが表示されます。:

   - GitLab Duoがセッションで初めてそのツールを呼び出す場合。
   - セッション全体でそのツールを承認していません。

1. ツールを承認または拒否します。:

   - ツールを承認すると、機能がツールに接続して回答を生成します。
     - オプション。セッション全体でツールを承認するには、**承認する**ドロップダウンリストから**Approve for Session**（セッションを承認する）を選択します。

       MCPサーバーが提供するツールのみをセッションで承認できます。ターミナルまたはCLIコマンドは承認できません。

   - チャットの場合、ツールを拒否すると、**Provide Rejection Reason**（拒否理由の提供）ダイアログが表示されます。拒否理由を入力し、**Submit Rejection**（拒否を送信）を選択します。

## 関連トピック {#related-topics}

- [Model Context Protocolの使用を開始する](https://modelcontextprotocol.io/introduction)
- [デモ - Agentic Chat MCP Tool Call Approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8)

## トラブルシューティング {#troubleshooting}

### `Error starting server filesystem: Error: spawn ... ENOENT` {#error-starting-server-filesystem-error-spawn--enoent}

このエラーは、（`node`の代わりに`/usr/bin/node`のように）相対パスを使用してコマンドを指定し、そのコマンドがGitLab言語サーバーに渡された`PATH`環境変数で見つからない場合に発生します。

`PATH`の解決の改善は、[イシュー1345](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1345)で追跡されています。

### VS CodeでのMCPのトラブルシューティング {#troubleshooting-mcp-in-vs-code}

トラブルシューティング情報については、[VS Code用GitLab Workflow拡張機能のトラブルシューティング](../../../editor_extensions/visual_studio_code/troubleshooting.md)を参照してください。
