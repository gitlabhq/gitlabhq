---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST APIを使用してGitLab Duo Agent Platformのフローを作成、開始、管理します。
title: GitLab Duo Agent Platform flows API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[フロー](../user/duo_agent_platform/flows/_index.md)を[GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)で作成および管理します。フローは、AIエージェントの組み合わせであり、デベロッパーのタスク（バグの修正、コードの記述、脆弱性の解決など）を完了するために連携して動作します。

## フローを作成する {#create-a-flow}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

新しいフローを作成して開始します。

```plaintext
POST /ai/duo_workflows/workflows
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `additional_context` | オブジェクトの配列 | いいえ | フローの追加コンテキスト。各要素は、少なくとも`Category` (文字列) と`Content` (文字列、シリアライズされたJSON) キーを持つオブジェクトである必要があります。 |
| `agent_privileges` | 整数の配列 | いいえ | エージェントが使用を許可されている特権ID。すべての特権がデフォルトで有効になります。[すべてのエージェント特権をリストする](#list-all-agent-privileges)を参照してください。 |
| `ai_catalog_item_consumer_id` | 整数 | いいえ | どのカタログ項目を実行するかを設定するAIカタログ項目のコンシューマーID。`project_id`が必要です。`workflow_definition`と一緒に使用することはできません。両方が提供された場合、`ai_catalog_item_consumer_id`が優先されます。[コンシューマーIDを検索する](#look-up-the-consumer-id)を参照してください。 |
| `ai_catalog_item_version_id` | 整数 | いいえ | フローの設定のソースとなったAIカタログ項目のバージョンID。 |
| `allow_agent_to_request_user` | ブール値 | いいえ | `true` (デフォルト) の場合、エージェントは続行する前に一時停止してユーザーに質問する可能性があります。`false`の場合、エージェントはユーザーからの入力なしで完了まで実行されます。 |
| `environment` | 文字列 | いいえ | 実行環境。次のいずれか: `ide`, `web`, `chat_partial`, `chat`, `ambient`。 |
| `goal` | 文字列 | いいえ | エージェントが完了するタスクの説明。例: `Fix the failing pipeline`。 |
| `image` | 文字列 | いいえ | CIパイプラインでフローを実行する際に使用するコンテナイメージ。[カスタムイメージ要件](../user/duo_agent_platform/flows/execution.md#custom-image-requirements)を満たす必要があります。例: `registry.gitlab.com/gitlab-org/duo-workflow/custom-image:latest`。 |
| `issue_id` | 整数 | いいえ | フローを関連付けるイシューのIID。`project_id`が必要です。 |
| `merge_request_id` | 整数 | いいえ | フローを関連付けるマージリクエストのIID。`project_id`が必要です。 |
| `namespace_id` | 文字列 | いいえ | フローを関連付けるネームスペースのIDまたはパス。 |
| `pre_approved_agent_privileges` | 整数の配列 | いいえ | ユーザーの承認を要求せずにエージェントが使用できる特権ID。`agent_privileges`のサブセットである必要があります。 |
| `project_id` | 文字列 | いいえ | フローを関連付けるプロジェクトのIDまたはパス。 |
| `shallow_clone` | ブール値 | いいえ | 実行中にリポジトリのシャロークローンを使用するかどうか。デフォルトは`true`です。 |
| `source_branch` | 文字列 | いいえ | CIパイプラインのソースブランチ。デフォルトは、プロジェクトのデフォルトブランチです。 |
| `start_workflow` | ブール値 | いいえ | `true`の場合、作成後すぐにフローを開始します。 |
| `workflow_definition` | 文字列 | いいえ | フロータイプの識別子。例: `developer/v1`。`ai_catalog_item_consumer_id`と一緒に使用することはできません。両方が提供された場合、`ai_catalog_item_consumer_id`が優先されます。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `agent_privileges` | 整数の配列 | エージェントに割り当てられた特権ID。 |
| `agent_privileges_names` | 文字列配列 | `agent_privileges`に対応する名前。 |
| `ai_catalog_item_version_id` | 整数 | AIカタログ項目のバージョンID。`null`が設定されていない場合。 |
| `allow_agent_to_request_user` | ブール値 | `true`の場合、エージェントはユーザーからの入力を待機するために一時停止する可能性があります。 |
| `environment` | 文字列 | 実行環境。`null`が設定されていない場合。 |
| `gitlab_url` | 文字列 | GitLabインスタンスのベースURL。 |
| `id` | 整数 | フローのID。 |
| `image` | 文字列 | CIパイプライン実行用のコンテナイメージ。`null`が設定されていない場合。 |
| `mcp_enabled` | ブール値 | このフローで`MCP` (Model Context Protocol) ツールが有効になっているかどうか。 |
| `namespace_id` | 整数 | 関連付けられたネームスペースのID。`null`が設定されていない場合。 |
| `pre_approved_agent_privileges` | 整数の配列 | エージェントが承認を要求せずに使用できる特権ID。 |
| `pre_approved_agent_privileges_names` | 文字列配列 | `pre_approved_agent_privileges`に対応する名前。 |
| `project_id` | 整数 | 関連付けられたプロジェクトのID。`null`が設定されていない場合。 |
| `status` | 文字列 | 現在のフローの状態。`created`、`running`、`paused`、`finished`、`failed`、`stopped`、`input_required`、`plan_approval_required`、`tool_call_approval_required`のいずれか。 |
| `workflow_definition` | 文字列 | フロータイプの識別子。 |
| `workload` | オブジェクト | ワークロードに関する情報。 |
| `workload.id` | 文字列 | ワークロードのID。 |
| `workload.message` | 文字列 | ワークロードのステータスメッセージ。 |

### コンシューマーIDを検索する {#look-up-the-consumer-id}

`ai_catalog_item_consumer_id`を使用する前に、GraphQL APIを使用して[AIカタログ](../user/duo_agent_platform/ai_catalog.md)からIDを取得する必要があります。項目はすでにプロジェクトに対して有効になっている必要があります。

```graphql
query {
  aiCatalogConfiguredItems(projectId: "gid://gitlab/Project/<project_id>") {
    nodes {
      id
      item { name }
    }
  }
}
```

`id`フィールドは、`gid://gitlab/AiCatalogItemConsumer/<numeric_id>`形式のグローバルIDです。数値サフィックスを`ai_catalog_item_consumer_id`の値として使用します。

組み込みフロータイプを使用したリクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

カタログ設定済みフローを使用したリクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "ai_catalog_item_consumer_id": 12,
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 5,
  "namespace_id": null,
  "agent_privileges": [1, 2, 3, 4, 5, 6],
  "agent_privileges_names": [
    "read_write_files",
    "read_only_gitlab",
    "read_write_gitlab",
    "run_commands",
    "use_git",
    "run_mcp_tools"
  ],
  "pre_approved_agent_privileges": [],
  "pre_approved_agent_privileges_names": [],
  "workflow_definition": "developer/v1",
  "status": "running",
  "allow_agent_to_request_user": true,
  "image": null,
  "environment": null,
  "ai_catalog_item_version_id": null,
  "workload": {
    "id": "abc-123",
    "message": "Workflow started"
  },
  "mcp_enabled": false,
  "gitlab_url": "https://gitlab.example.com"
}
```

## すべてのエージェント特権をリストする {#list-all-agent-privileges}

利用可能なすべてのエージェント特権を、そのID、名前、説明、およびそれぞれがデフォルトで有効になっているかどうかとともにリストします。

```plaintext
GET /ai/duo_workflows/workflows/agent_privileges
```

このエンドポイントには、サポートされている属性がありません。

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `all_privileges` | オブジェクトの配列 | 利用可能なすべてのエージェント特権。 |
| `all_privileges[].default_enabled` | ブール値 | 特権がデフォルトで有効になっているかどうか。 |
| `all_privileges[].description` | 文字列 | その特権が許可する内容の人間が判読できる説明。 |
| `all_privileges[].id` | 整数 | 特権ID。 |
| `all_privileges[].name` | 文字列 | 機械が判読できる特権名。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows/agent_privileges"
```

レスポンス例: 

```json
{
  "all_privileges": [
    {
      "id": 1,
      "name": "read_write_files",
      "description": "Allow local filesystem read/write access",
      "default_enabled": true
    },
    {
      "id": 2,
      "name": "read_only_gitlab",
      "description": "Allow read only access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 3,
      "name": "read_write_gitlab",
      "description": "Allow write access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 4,
      "name": "run_commands",
      "description": "Allow running any commands",
      "default_enabled": true
    },
    {
      "id": 5,
      "name": "use_git",
      "description": "Allow git commits, push and other git commands",
      "default_enabled": true
    },
    {
      "id": 6,
      "name": "run_mcp_tools",
      "description": "Allow running MCP tools",
      "default_enabled": true
    }
  ]
}
```
