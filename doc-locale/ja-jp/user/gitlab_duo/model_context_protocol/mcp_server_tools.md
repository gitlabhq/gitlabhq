---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: これらのツールを使用して、GitLab MCPサーバーを介してGitLabとやり取りします。
title: GitLab MCPサーバーツール
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

> [!warning]この機能に関するフィードバックを提供するには、[issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントを残してください。

GitLab MCPサーバーは、既存のGitLabワークフローと統合する一連のツールを提供します。これらのツールを使用して、GitLabと直接やり取りし、一般的なGitLab操作を実行できます。

## `get_mcp_server_version` {#get_mcp_server_version}

GitLab MCPサーバーの現在のバージョンを返します。

例: 

```plaintext
What version of the GitLab MCP server am I connected to?
```

## `create_issue` {#create_issue}

GitLabプロジェクトに新しいイシューを作成します。

| パラメータ      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 文字列            | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `title`        | 文字列            | はい      | イシューのタイトル。 |
| `description`  | 文字列            | いいえ       | イシューの説明。 |
| `assignee_ids` | 整数の配列 | いいえ       | 割り当てられたユーザーのIDの配列。 |
| `milestone_id` | 整数           | いいえ       | マイルストーンのID。 |
| `labels`       | 文字列の配列  | いいえ       | ラベル名の配列。 |
| `confidential` | ブール値           | いいえ       | イシューを機密に設定します。デフォルトは`false`です。 |
| `epic_id`      | 整数           | いいえ       | リンクされたエピックのID。 |

例: 

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description
"Users cannot log in with special characters in password"
```

## `get_issue` {#get_issue}

特定のGitLabイシューに関する詳細情報を取得します。

| パラメータ   | 型    | 必須 | 説明 |
|-------------|---------|----------|-------------|
| `id`        | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `issue_iid` | 整数 | はい      | イシューの内部ID。 |

例: 

```plaintext
Get details for issue 42 in project 123
```

## `create_merge_request` {#create_merge_request}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/571243)されました。
- `assignee_ids`、`reviewer_ids`、`description`、`labels`、および`milestone_id`がGitLab 18.8で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458)されました。

{{< /history >}}

GitLabプロジェクトにマージリクエストを作成します。

| パラメータ           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 文字列            | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `title`             | 文字列            | はい      | マージリクエストのタイトル。 |
| `source_branch`     | 文字列            | はい      | ソースブランチの名前。 |
| `target_branch`     | 文字列            | はい      | ターゲットブランチの名前。 |
| `target_project_id` | 整数           | いいえ       | ターゲットプロジェクトのID。 |
| `assignee_ids`      | 整数の配列 | いいえ       | マージリクエストのアサイニーのIDの配列。すべてのアサイニーの割り当てを解除するには、`0`または空の値を設定します。 |
| `reviewer_ids`      | 整数の配列 | いいえ       | マージリクエストのレビュアーのIDの配列。すべてのレビュアーの割り当てを解除するには、`0`または空の値を設定します。 |
| `description`       | 文字列            | いいえ       | マージリクエストの説明。 |
| `labels`            | 文字列の配列  | いいえ       | ラベル名の配列。すべてのラベルの割り当てを解除するには、空の文字列に設定します。 |
| `milestone_id`      | 整数           | いいえ       | マイルストーンのID。 |

例: 

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

## `get_merge_request` {#get_merge_request}

特定のGitLabマージリクエストに関する詳細情報を取得します。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

例: 

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

## `get_merge_request_commits` {#get_merge_request_commits}

特定のGitLabマージリクエスト内のコミットのリストを取得します。

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

## `get_merge_request_diffs` {#get_merge_request_diffs}

特定のGitLabマージリクエストの差分を取得します。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |
| `per_page`          | 整数 | いいえ       | ページあたりの差分数。 |
| `page`              | 整数 | いいえ       | 現在のページ番号。 |

例: 

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

## `get_merge_request_pipelines` {#get_merge_request_pipelines}

特定のGitLabマージリクエストのパイプラインを取得します。

| パラメータ           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

例: 

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `get_pipeline_jobs` {#get_pipeline_jobs}

特定のGitLab CI/CDパイプラインのジョブを取得します。

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

## `create_workitem_note` {#create_workitem_note}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581890)されました。

{{< /history >}}

GitLab作業アイテムに新しいノート（コメント）を作成します。

| パラメータ       | 型    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `body`          | 文字列  | はい      | ノートの内容。 |
| `url`           | 文字列  | いいえ       | 作業アイテムのURL。`group_id`または`project_id`と`work_item_iid`がない場合は必須。 |
| `group_id`      | 文字列  | いいえ       | グループのIDまたはパス。`url`と`project_id`がない場合は必須。 |
| `project_id`    | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`と`group_id`がない場合は必須。 |
| `work_item_iid` | 整数 | いいえ       | 作業アイテムの内部ID。`url`がない場合は必須。 |
| `internal`      | ブール値 | いいえ       | （少なくともプロジェクトのレポーターロールを持つユーザーにのみ表示される）ノートを内部としてマークします。デフォルトは`false`です。 |
| `discussion_id` | 文字列  | いいえ       | 返信するディスカッションのグローバルID（`gid://gitlab/Discussion/<id>`形式）。 |

例: 

```plaintext
Add a comment "This looks good to me" to work item 42 in project gitlab-org/gitlab
```

## `get_workitem_notes` {#get_workitem_notes}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581892)されました。

{{< /history >}}

特定のGitLab作業アイテムのすべてのノート（コメント）を取得します。

| パラメータ       | 型    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `url`           | 文字列  | いいえ       | 作業アイテムのURL。`group_id`または`project_id`と`work_item_iid`がない場合は必須。 |
| `group_id`      | 文字列  | いいえ       | グループのIDまたはパス。`url`と`project_id`がない場合は必須。 |
| `project_id`    | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`と`group_id`がない場合は必須。 |
| `work_item_iid` | 整数 | いいえ       | 作業アイテムの内部ID。`url`がない場合は必須。 |
| `after`         | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `before`        | 文字列  | いいえ       | 逆方向ページネーションのカーソル。 |
| `first`         | 整数 | いいえ       | 順方向ページネーションで返すノート数。 |
| `last`          | 整数 | いいえ       | 逆方向ページネーションで返すノート数。 |

例: 

```plaintext
Show me all comments on work item 42 in project gitlab-org/gitlab
```

## `search` {#search}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/566143)されました。
- グループとプロジェクトの検索、および結果の順序と並べ替えがGitLab 18.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/571132)されました。
- [名前が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734)されました。`gitlab_search`から`search`（GitLab 18.8）。

{{< /history >}}

検索APIを使用して、GitLabインスタンス全体で用語を検索します。このツールは、グローバル、グループ、およびプロジェクトの検索に使用できます。利用可能なスコープは、[search type](../../search/_index.md)によって異なります。

| パラメータ      | 型             | 必須 | 説明 |
|----------------|------------------|----------|-------------|
| `scope`        | 文字列           | はい      | 検索スコープ（`issues`、`merge_requests`、`projects`など）。 |
| `search`       | 文字列           | はい      | 検索語句。 |
| `group_id`     | 文字列           | いいえ       | 検索するグループのIDまたはURLエンコードされたパス。 |
| `project_id`   | 文字列           | いいえ       | 検索するプロジェクトのIDまたはURLエンコードされたパス。 |
| `state`        | 文字列           | いいえ       | 検索結果の状態（`issues`および`merge_requests`の場合）。 |
| `confidential` | ブール値          | いいえ       | （`issues`の）機密性で結果をフィルタリングします。デフォルトは`false`です。 |
| `fields`       | 文字列の配列 | いいえ       | 検索するフィールドの配列（`issues`および`merge_requests`の場合）。 |
| `order_by`     | 文字列           | いいえ       | 結果の順序付けに使用する属性。デフォルトは、基本的な検索の場合は`created_at`、高度な検索の場合は関連性です。 |
| `sort`         | 文字列           | いいえ       | 結果の並べ替え方向。デフォルトは`desc`です。 |
| `per_page`     | 整数          | いいえ       | ページあたりの結果数。デフォルトは`20`です。 |
| `page`         | 整数          | いいえ       | 現在のページ番号。デフォルトは`1`です。 |

例: 

```plaintext
Search issues for "flaky test" across GitLab
```

## `semantic_code_search` {#semantic_code_search}

{{< history >}}

- `code_snippet_search_graphqlapi`という名前の[flag](../../../administration/feature_flags/_index.md)を持つGitLab 18.5の[実験](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/569624)。デフォルトでは無効になっています。
- プロジェクトパスでの検索がGitLab 18.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/575234)されました。
- GitLab 18.7で実験的機能から[ベータ版](../../../policy/development_stages_support.md#beta)に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568359)されました。機能フラグ`code_snippet_search_graphqlapi`は削除されました。
- GitLab 18.7で`mcp_client`[フラグ](../../../administration/feature_flags/_index.md)とともにGitLab UIに[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/581105)されました。デフォルトでは無効になっています。

{{< /history >}}

GitLabプロジェクト内の関連するコードスニペットを検索します。詳細については、[semantic code search](../semantic_code_search.md)を参照してください。

| パラメータ        | 型    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `semantic_query` | 文字列  | はい      | コードの検索クエリ。 |
| `project_id`     | 文字列  | はい      | プロジェクトのIDまたはパス。 |
| `directory_path` | 文字列  | いいえ       | ディレクトリのパス（`app/services/`など）。 |
| `knn`            | 整数 | いいえ       | 類似のコードスニペットを検出するために使用される最近傍の数。デフォルトは`64`です。 |
| `limit`          | 整数 | いいえ       | 返す結果の最大数。デフォルトは`20`です。 |

最適な結果を得るには、一般的なキーワードや特定の関数名または変数名を使用するのではなく、関心のある機能または動作について記述してください。

例: 

```plaintext
How are authorizations managed in this project?
```
