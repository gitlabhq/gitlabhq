---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 公式のGitLab MCPサーバーを使用して、AIツールをGitLabインスタンスに接続します。
title: GitLab MCPサーバー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](../../../administration/feature_flags/_index.md)されました（フラグ名は`mcp_server`と`oauth_dynamic_client_registration`）。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

{{< alert type="warning" >}}

この機能に関するフィードバックを提供するには、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントを残してください。

{{< /alert >}}

GitLab [Model Context Protocol](https://modelcontextprotocol.io/)（MCP）サーバーを使用すると、AIツールとアプリケーションをGitLabインスタンスに安全に接続できます。Claude Desktop、Cursor、その他のMCP互換ツールのようなAIアシスタントは、GitLabデータにアクセスし、ユーザーに代わってアクションを実行できます。

MCPサーバーは、AIツールが以下を実行するための標準化された方法を提供します。

- GitLabプロジェクト情報にアクセスします。
- イシューとマージリクエストのデータを取得する。
- GitLab APIと安全にやり取りします。
- AIアシスタントを介してGitLab固有の操作を実行します。

GitLab MCPサーバーは、[OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)をサポートしており、AIツールはGitLabインスタンスに自身を登録できます。AIツールが初めてGitLab MCPサーバーに接続すると、次のようになります:

1. OAuthアプリケーションとして自身を登録します。
1. GitLabデータへのアクセス認可をリクエストします。
1. 安全なAPIアクセス用のアクセストークンを受信します。

クリックスルーデモについては、[Duo Agent Platform - MCP server](https://gitlab.navattic.com/gitlab-mcp-server)を参照してください。
<!-- Demo published on 2025-09-11 -->

## CursorをGitLab MCPサーバーに接続する {#connect-cursor-to-a-gitlab-mcp-server}

前提要件: 

- Node.jsバージョン20以降をインストールします。

CursorでGitLab MCPサーバーを設定するには:

1. Cursorを開きます。
1. Cursorで、**設定** > **Cursor Settings**（Cursor Settings） > **Tools & Integrations**（Tools & Integrations）に移動します。
1. **MCP Tools**（MCP Tools）で、`New MCP Server`を選択します。
1. この定義を開いている`mcp.json`ファイルの`mcpServers`キーに追加し、必要に応じて編集します:
   - `"command":`パラメータの場合、`npx`がグローバルではなくローカルにインストールされている場合は、`npx`へのフルパスを指定してください。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`GitLab.com`。
   - `--static-oauth-client-metadata`パラメータは、GitLabサーバーで予期されるようにOAuthスコープを`mcp`に設定するために、`mcp-remote`モジュールに必須です。

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp",
           "--static-oauth-client-metadata",
           "{\"scope\": \"mcp\"}"
         ]
       }
     }
   }
   ```

1. ファイルを保存し、ブラウザでOAuth認可ページが開くのを待ちます。

   これが発生しない場合は、Cursorを閉じて再起動します。
1. ブラウザで、認可リクエストを確認して承認します。

新しいチャットを開始し、利用可能なツールに応じて質問をすることができます。

{{< alert type="warning" >}}

これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

{{< /alert >}}

## Claude DesktopをGitLab MCPサーバーに接続する {#connect-claude-desktop-to-a-gitlab-mcp-server}

前提要件: 

- Node.jsバージョン20以降をインストールします。
- Node.jsが`PATH`環境変数（`which -a node`）でグローバルに使用できることを確認します。

Claude DesktopでGitLab MCPサーバーを設定するには:

1. Claude Desktopを開きます。
1. 設定ファイルを編集します。次のいずれかを実行できます:
   - Claude Desktopで、**設定** > **デベロッパー** > **Edit Config**（Edit Config）に移動します。
   - macOSで、`~/Library/Application Support/Claude/claude_desktop_config.json`ファイルを開きます。
1. 必要に応じて編集して、`GitLab` MCPサーバーにこのエントリを追加します:
   - `"command":`パラメータの場合、`npx`がグローバルではなくローカルにインストールされている場合は、`npx`へのフルパスを指定してください。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`GitLab.com`。
   - `--static-oauth-client-metadata`パラメータは、GitLabサーバーで予期されるようにOAuthスコープを`mcp`に設定するために、`mcp-remote`モジュールに必須です。

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "-y",
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp",
           "--static-oauth-client-metadata",
           "{\"scope\": \"mcp\"}"
         ]
       }
     }
   }
   ```

1. 設定を保存して、Claude Desktopを再起動します。
1. 最初の接続時に、Claude DesktopはOAuthのブラウザウィンドウを開きます。リクエストを確認して承認します。
1. **設定** > **デベロッパー**に移動し、新しいGitLab MCP設定を確認します。
1. **設定** > **Connectors**（Connectors）に移動し、接続されているGitLab MCPサーバーを検査します。

新しいチャットを開始し、利用可能なツールに応じて質問をすることができます。

{{< alert type="warning" >}}

これらのツールを使用する際は、プロンプトインジェクションから保護する責任があります。最大限の注意を払うか、信頼できるGitLabオブジェクトでのみMCPツールを使用してください。

{{< /alert >}}

## 利用可能なツール {#available-tools}

GitLab MCPサーバーは、次のツールを提供します。

### `get_mcp_server_version` {#get_mcp_server_version}

GitLab MCPサーバーの現在のバージョンを返します。

例: 

```plaintext
What version of the GitLab MCP server am I connected to?
```

### `create_issue` {#create_issue}

GitLabプロジェクトに新しいイシューを作成します。

| パラメータ      | 型    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `id`           | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `title`        | 文字列  | はい      | イシューのタイトル。 |
| `description`  | 文字列  | いいえ       | イシューの説明。 |
| `assignee_ids` | 配列   | いいえ       | 割り当てられたユーザーのID。 |
| `milestone_id` | 整数 | いいえ       | マイルストーンのID。 |
| `labels`       | 文字列  | いいえ       | ラベル名のコンマ区切りリスト。 |
| `confidential` | ブール値 | いいえ       | イシューを機密に設定します。デフォルトは`false`です。 |
| `epic_id`      | 整数 | いいえ       | リンクされたエピックのID。 |

例: 

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description
"Users cannot log in with special characters in password"
```

### `get_issue` {#get_issue}

特定のGitLabイシューに関する詳細情報を取得する。

| パラメータ   | 型    | 必須 | 説明 |
|-------------|---------|----------|-------------|
| `id`        | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `issue_iid` | 整数 | はい      | イシューの内部ID。 |

例: 

```plaintext
Get details for issue 42 in project 123
```

### `create_merge_request` {#create_merge_request}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/571243)されました。

{{< /history >}}

プロジェクトにマージリクエストを作成します。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `title`             | 文字列  | はい      | マージリクエストのタイトル。 |
| `source_branch`     | 文字列  | はい      | ソースブランチの名前。 |
| `target_branch`     | 文字列  | はい      | ターゲットブランチの名前。 |
| `target_project_id` | 整数 | いいえ       | ターゲットプロジェクトのID（数値）。 |

例: 

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

### `get_merge_request` {#get_merge_request}

特定のGitLabマージリクエストに関する詳細情報を取得する。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

例: 

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

### `get_merge_request_commits` {#get_merge_request_commits}

特定のマージリクエスト内のコミットのリストを取得する。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |
| `per_page`          | 整数 | いいえ       | ページあたりのコミット数。 |
| `page`              | 整数 | いいえ       | 現在のページ番号。 |

例: 

```plaintext
Show me all commits in merge request 42 from project 123
```

### `get_merge_request_diffs` {#get_merge_request_diffs}

特定のマージリクエストの差分を取得する。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |
| `per_page`          | 整数 | いいえ       | ページあたりの差分の数。 |
| `page`              | 整数 | いいえ       | 現在のページ番号。 |

例: 

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

### `get_merge_request_pipelines` {#get_merge_request_pipelines}

特定のマージリクエストのパイプラインを取得する。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

例: 

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

### `get_pipeline_jobs` {#get_pipeline_jobs}

特定のCI/CDパイプラインのジョブを取得する。

| パラメータ     | 型    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `id`          | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `pipeline_id` | 整数 | はい      | パイプラインのID。 |
| `per_page`    | 整数 | いいえ       | ページあたりのジョブ数。 |
| `page`        | 整数 | いいえ       | 現在のページ番号。 |

例: 

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

### `gitlab_search` {#gitlab_search}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/566143)されました。

{{< /history >}}

検索APIを使用して、GitLabインスタンス全体で用語を検索します。このツールは、グローバル検索でのみ使用できます。

| パラメータ      | 型    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `scope`        | 文字列  | はい      | 検索スコープ（`issues`、`merge_requests`、または`projects`など）。 |
| `search`       | 文字列  | はい      | 検索語句。 |
| `state`        | 文字列  | いいえ       | 検索結果の状態。 |
| `confidential` | ブール値 | いいえ       | 機密性で結果をフィルタリングします。デフォルトは`false`です。 |
| `per_page`     | 整数 | いいえ       | ページあたりの結果数。 |
| `page`         | 整数 | いいえ       | 現在のページ番号。 |
| `fields`       | 文字列  | いいえ       | 検索するフィールドのコンマ区切りリスト。 |

例: 

```plaintext
Search issues for "flaky test" across GitLab
```

### `get_code_context` {#get_code_context}

{{< history >}}

- GitLab 18.5で`code_snippet_search_graphqlapi`という名前の[フラグ](../../../administration/feature_flags/_index.md)により[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/569624)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

プロジェクト内の関連するコードスニペットを検索します。

| パラメータ        | 型    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `search_term`    | 文字列  | はい      | 検索語句。 |
| `project_id`     | 整数 | はい      | プロジェクトのID。 |
| `directory_path` | 文字列  | いいえ       | ディレクトリのパス（`app/services/`など）。 |
| `knn`            | 整数 | いいえ       | 類似のコードスニペットを検出するために使用される最近傍の数。デフォルトは`64`です。 |
| `limit`          | 整数 | いいえ       | 返す結果の最大数。デフォルトは`20`です。 |

例: 

```plaintext
Search for relevant code snippets that show how authorizations are managed in GitLab
```
