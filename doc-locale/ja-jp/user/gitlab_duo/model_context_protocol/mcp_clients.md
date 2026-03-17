---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Model Context Protocolとその使用方法について説明します
title: GitLab MCPクライアント
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- セルフホストモデル対応のGitLab Duoでは利用不可

{{< /collapsible >}}

{{< history >}}

- GitLab 18.1で`duo_workflow_mcp_support`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519938)されました。デフォルトでは無効になっています。
- GitLab 18.2の[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/545956)で有効になりました。機能フラグ`duo_workflow_mcp_support`は削除されました。
- GitLab 18.3で実験的機能から[ベータ](https://gitlab.com/gitlab-org/gitlab/-/issues/545956)に変更されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

Model Context Protoco（MCP）lは、GitLab Duoの各機能がさまざまな外部データソースやツールに安全に接続するための標準化された方法を提供します。

MCPは以下をサポートしています:

- Visual Studio Code（VS Code）およびVSCodium
- JetBrains IDE

同じMCP設定ファイルは、サポートされているすべてのIDEで機能します。

次の機能はMCPクライアントとして動作し、MCPサーバーから外部ツールに接続できます:

- [GitLab Duo Chat（エージェント）](../../../user/gitlab_duo_chat/agentic_chat.md)
- [ソフトウェア開発フロー](../../../user/duo_agent_platform/flows/foundational_flows/software_development.md)

これらの機能は、外部コンテキストと情報にアクセスして、より強力な回答を生成できます。

MCPで機能を使用するには、次の手順に従います:

1. グループのMCPをオンにします。
1. 機能を接続するMCPサーバーを構成します。

クリックスルーデモについては、[GitLab Duo Agent Platform - MCPインテグレーション](https://gitlab.navattic.com/mcp)を参照してください。
<!-- Demo published on 2025-08-05 -->

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしてください。

Visual Studio Code（VS Code）またはVSCodiumの場合:

- [VS Code](https://code.visualstudio.com/download)または[VSCodium](https://vscodium.com/)をインストールします。
- GitLab for VS Code拡張機能を[Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow)または[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)からインストールしてセットアップします。
  - MCPサポートについては、バージョン6.28.2以降をインストールします。
  - ワークスペースおよびユーザー設定については、バージョン6.35.6以降をインストールします。

JetBrainsIDEの場合:

- JetBrainsIDEをインストールします。
- [GitLab Duoプラグインfor JetBrainsIDE](../../../editor_extensions/jetbrains_ide/setup.md)をインストールしてセットアップします。

## 外部のMCPツールを許可する {#allow-external-mcp-tools}

IDEが外部のMCPツールにアクセスできるようにするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **外部のMCPツール**で、**外部のMCPツールを許可**チェックボックスを選択します。
1. **変更を保存**を選択します。

## MCPサーバーを設定する {#configure-mcp-servers}

MCPを言語サーバーと統合するには、ワークスペースの設定、ユーザー設定、またはその両方をセットアップします。GitLab言語サーバーは、設定ファイルを読み込み、マージします。

### バージョンの互換性 {#version-compatibility}

| GitLab for VS Codeバージョン | 利用可能なMCP機能 |
|-----------------------------------|------------------------|
| 6.28.2〜6.35.5  | ワークスペースまたはユーザー設定のない基本的なMCPサポート |
| 6.35.6以降 | ワークスペースとユーザー設定を含む、完全なMCPサポート |

### ワークスペース設定を作成する {#create-workspace-configuration}

ワークスペースの設定は、このプロジェクトにのみ適用され、同じサーバーのユーザー設定をオーバーライドします。

ワークスペースの設定を行うには、次の手順に従います:

1. プロジェクトのワークスペースで、`<workspace>/.gitlab/duo/mcp.json`ファイルを作成します。
1. [設定形式](#configuration-format)を使用して、機能が接続するMCPサーバーに関する情報を追加します。
1. ファイルを保存します。
1. IDEを再起動します。

### ユーザー設定を作成する {#create-user-configuration}

ユーザー設定は、個人用ツールおよび一般的に使用されるサーバーに適しています。これらはすべてのワークスペースに適用されますが、同じサーバーのワークスペースの設定はユーザー設定をオーバーライドします。

ユーザー設定を行うには、次の手順に従います:

1. VSCodiumまたはVS Codeで、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーまたは<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押してコマンドパレットを開きます。
1. コマンド`GitLab MCP: Open User Settings (JSON)`を実行して、ユーザー設定ファイルを作成して開きます。
1. [設定形式](#configuration-format)を使用して、機能が接続するMCPサーバーに関する情報を追加します。
1. ファイルを保存します。
1. IDEを再起動します。

JetBrainsIDEの場合、またはVS Codeでファイルを手動で作成するには、この場所を使用します:

- Windows: `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`
- その他すべてのオペレーティングシステム: `~/.gitlab/duo/mcp.json`

### 設定形式 {#configuration-format}

両方の設定ファイルは同じJSON形式を使用し、詳細は`mcpServers`キーに記述されています:

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
> 他のMCPクライアントの場合、Atlassianのドキュメントではサンプル設定ファイルで`mcp.servers`を使用します。GitLabでは代わりに`mcpServers`を使用します。

### ツール承認を設定する {#configure-tool-approval}

デフォルトでは、各セッションでサーバーからのすべてのMCPツールを手動で承認する必要があります。

代わりに、設定ファイルでMCPツールを事前承認して、手動の承認プロンプトをスキップできます。

そのためには、`approvedTools`フィールドを任意のサーバー設定に追加します:

- `"approvedTools": true` - このサーバーからの現在および将来のすべてのツールを自動的に承認します。
- `"approvedTools": ["tool1", "tool2"]` - 指定したツールのみを承認します。

このフィールドを含めない場合、セッション内のすべてのツールを手動で承認する必要があります（これがデフォルトの動作です）。

> [!warning]
> 完全に信頼するサーバーに対してのみ`"approvedTools": true`を使用してください。

例: 

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

#### ツール承認の仕組み {#how-tool-approval-works}

GitLabは、MCPツールに2層の承認システムを使用します:

- 設定に基づく承認（永続的）: `mcp.json`で`approvedTools`フィールドを使用して承認されたツール。これらの承認は、すべてのセッションで永続的に有効です。
- セッションベースの承認（一時的）: 現在のワークフローセッションのランタイム中に承認されたツール。これらの承認は、IDEを閉じるか、ワークフローを終了するとクリアされます。

いずれかの条件が満たされた場合、ツールは承認されます。

### MCPサーバー設定の例 {#example-mcp-server-configurations}

次のコード例を参考にして、MCPサーバーの設定ファイルを作成してください。

詳細と例については、[MCPサーバー例のドキュメント](https://modelcontextprotocol.io/examples)を参照してください。その他のサーバー例としては、[Smithery.ai](https://smithery.ai/)と[Awesome MCP Servers](https://mcpservers.org/)があります。

#### ローカルサーバー {#local-server}

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

#### GitLabナレッジグラフサーバー {#gitlab-knowledge-graph-server}

[GitLabナレッジグラフ](https://gitlab-org.gitlab.io/rust/knowledge-graph)は、MCPを通じてコードインテリジェンスを提供します。すべてのツールを承認するか、特定のツールを承認することができます:

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

または、特定のツールのみを承認します:

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

利用可能なツールに関する詳細は、[Knowledge Graph MCPツールのドキュメント](https://gitlab-org.gitlab.io/rust/knowledge-graph/mcp/tools/)を参照してください。

#### HTTPサーバー {#http-server}

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

## MCPサーバーのステータスを表示する {#view-the-status-of-mcp-servers}

{{< history >}}

- GitLab for VS Code拡張機能6.55.0で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2155)されました。

{{< /history >}}

前提条件: 

- GitLab for VS Code拡張機能6.55.0以降をインストール済みであること。
- ユーザーまたはワークスペース設定で、少なくとも1つのMCPサーバーを設定済みであること。

設定されているMCPサーバーのステータスを表示するには:

1. VS CodeまたはVSCodiumで、コマンドパレットを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `GitLab: Show MCP Dashboard`と入力して<kbd>Enter</kbd>キーを押します。

MCPダッシュボードが新しいエディタタブで開きます。ダッシュボードを使用して以下を実行します:

- MCPサーバーが正しく設定され、実行されていることを確認します。
- GitLab Duo機能を使用する前に、接続の問題を特定します。
- 各サーバーで利用可能なツールを表示します。
- サーバー設定の問題をトラブルシューティングします。

### MCP設定ファイルを開く {#open-mcp-configuration-files}

MCP設定ファイルを開くには:

1. VS CodeまたはVSCodiumで、コマンドパレットを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. 設定ファイルを開きます:
   - ユーザー設定については、`GitLab MCP: Open User Settings (JSON)`と入力して<kbd>Enter</kbd>を押します。
   - ワークスペース設定については、`GitLab MCP: Open Workspace Settings (JSON)`と入力して<kbd>Enter</kbd>を押します。

## MCPサーバーで再認証する {#re-authenticate-with-mcp-servers}

MCP設定ファイル内の認証詳細を更新した後、関連するMCPサーバーで再認証する必要があります。

再認証をトリガーするには:

- GitLab Duoに、そのMCPサーバーからのデータを必要とする質問をします（例: Atlassianの場合は`What are the issues in my Jira project?`）。認証フローが自動的に開始されます。

## MCPでGitLab Duo機能を使用する {#use-gitlab-duo-features-with-mcp}

{{< history >}}

- セッション全体の外部ツールを承認する機能が、GitLab 18.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/556045)されました。

{{< /history >}}

GitLab Duo機能が質問に回答するために外部ツールを呼び出す場合、セッション全体で承認されていない限り、そのツールをレビューする必要があります:

1. VS Codeを開きます。
1. 左側のサイドバーで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **Chat**または**Flows**タブを選択します。
1. テキストボックスに、質問を入力するか、コードタスクを指定します。
1. 質問またはコードタスクを送信します。
1. 次の場合に、**Tool Approval Required**（ツール承認が必要）ダイアログが表示されます:

   - GitLab Duoがセッションで初めてそのツールを呼び出す場合。
   - セッション全体でそのツールを承認していない場合。

1. ツールを承認または拒否します:

   - ツールを承認すると、機能がツールに接続して回答を生成します。
     - オプション。セッション全体でツールを承認するには、**Approve**ドロップダウンリストから**Approve for Session**を選択します。

       MCPサーバーが提供するツールのみをセッションで承認できます。ターミナルまたはCLIコマンドは承認できません。

   - チャットの場合、ツールを拒否すると、**Provide Rejection Reason**ダイアログが表示されます。拒否理由を入力し、**Submit Rejection**を選択します。

     チャットは、新しいアプローチの提案やイシューの作成など、提供された理由に基づいてアクションを実行する場合があります。

## 関連トピック {#related-topics}

- [Model Context Protocolのスタートガイド](https://modelcontextprotocol.io/introduction)
- [Demo - Agentic Chat MCP Tool Call Approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8)

## トラブルシューティング {#troubleshooting}

### MCP認証キャッシュを削除する {#delete-the-mcp-authentication-cache}

GitLabは、`~/.mcp-auth/`にMCP認証をローカルでキャッシュします。トラブルシューティング中に誤検出を防ぐため、キャッシュディレクトリを削除します:

```shell
rm -rf ~/.mcp-auth/
```

### `Error starting server filesystem: Error: spawn ... ENOENT` {#error-starting-server-filesystem-error-spawn--enoent}

このエラーは、（`node`の代わりに`/usr/bin/node`のように）相対パスを使用してコマンドを指定し、そのコマンドがGitLab言語サーバーに渡された`PATH`環境変数で見つからない場合に発生します。

`PATH`を解決するための改善策は、[イシュー1345](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1345)で追跡されています。

### VS CodeでのMCPのトラブルシューティング {#troubleshooting-mcp-in-vs-code}

トラブルシューティング情報については、[GitLab for VS Code拡張機能のトラブルシューティング](../../../editor_extensions/visual_studio_code/troubleshooting.md)を参照してください。
