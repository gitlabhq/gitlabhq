---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: これらのツールを使用して、GitLab MCPサーバーを介してGitLabとやり取りします。
title: GitLab MCPサーバーツール
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

> [!warning]
> この機能に関するフィードバックを提供するには、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントしてください。

GitLab MCPサーバーは、既存のGitLabワークフローと連携して動作する一連のツールを提供します。これらのツールを使用して、GitLabと直接やり取りし、一般的なGitLabの操作を実行できます。

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
- GitLab 18.8で`assignee_ids`、`reviewer_ids`、`description`、`labels`、`milestone_id`が[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458)されました。

{{< /history >}}

GitLabプロジェクトにマージリクエストを作成します。

| パラメータ           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 文字列            | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `title`             | 文字列            | はい      | マージリクエストのタイトル。 |
| `source_branch`     | 文字列            | はい      | ソースブランチの名前。 |
| `target_branch`     | 文字列            | はい      | ターゲットブランチの名前。 |
| `target_project_id` | 整数           | いいえ       | ターゲットプロジェクトのID。 |
| `assignee_ids`      | 整数の配列 | いいえ       | マージリクエスト担当者のIDの配列。すべての担当者の割り当てを解除するには、`0`または空の値を設定します。 |
| `reviewer_ids`      | 整数の配列 | いいえ       | マージリクエストレビュアーのIDの配列。すべてのレビュアーの割り当てを解除するには、`0`または空の値を設定します。 |
| `description`       | 文字列            | いいえ       | マージリクエストの説明。 |
| `labels`            | 文字列の配列  | いいえ       | ラベル名の配列。すべてのラベルの割り当てを解除するには、空の文字列を設定します。 |
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

## `manage_pipeline` {#manage_pipeline}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)されました。

{{< /history >}}

GitLabプロジェクトでCI/CDパイプラインを管理します。

| パラメータ     | 型    | 必須    | 説明 |
|---------------|---------|-------------|-------------|
| `id`          | 文字列  | はい         | プロジェクトのIDまたはURLエンコードされたパス。 |
| `list`        | ブール値 | いいえ          | `true`の場合、プロジェクト内のすべてのパイプラインを一覧表示します。 |
| `ref`         | 文字列  | いいえ          | ブランチまたはタグ名。設定されている場合、ブランチまたはタグ上に新しいパイプラインを作成します。リストのフィルタリングにオプションです。 |
| `pipeline_id` | 整数 | いいえ          | パイプラインのID。このパラメータのみが設定されている場合、パイプラインと関連するすべてのデータを削除します。 |
| `retry`       | ブール値 | いいえ          | `true`と`pipeline_id`が設定されている場合、失敗またはキャンセルされたパイプラインジョブを再試行します。 |
| `cancel`      | ブール値 | いいえ          | `true`と`pipeline_id`が設定されている場合、実行中のパイプライン内のすべてのジョブをキャンセルします。 |
| `name`        | 文字列  | いいえ          | パイプラインの名前。このパラメータと`pipeline_id`が設定されている場合、パイプラインのメタデータを更新します。 |
| `variables`   | 配列   | いいえ          | 配列形式のパイプライン変数（`[{key, value, variable_type}]`）。 |
| `inputs`      | ハッシュ    | いいえ          | キー/バリューペアとしてのパイプライン入力パラメータ。 |
| `page`        | 整数 | いいえ          | 現在のページ番号。デフォルトは`1`です。 |
| `per_page`    | 整数 | いいえ          | 1ページあたりの項目数。デフォルトは`20`です。 |

例: 

- パイプラインの一覧:

  ```plaintext
  List all pipelines for project gitlab-org/gitlab
  ```

- パイプラインを作成:

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- パイプラインを更新:

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
  ```

- パイプラインを再試行:

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- パイプラインをキャンセル:

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

- パイプラインを削除:

  ```plaintext
  Delete pipeline 12345 in project gitlab-org/gitlab
  ```

## `create_workitem_note` {#create_workitem_note}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581890)されました。

{{< /history >}}

GitLab作業アイテムに新しいノート（コメント）を作成します。

| パラメータ       | 型    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `body`          | 文字列  | はい      | ノートの内容。 |
| `url`           | 文字列  | いいえ       | 作業アイテムのURL。`group_id`または`project_id`と`work_item_iid`が指定されていない場合は必須。 |
| `group_id`      | 文字列  | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`    | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `work_item_iid` | 整数 | いいえ       | 作業アイテムの内部ID。`url`が指定されていない場合は必須。 |
| `internal`      | ブール値 | いいえ       | メモを内部向けとしてマークします（プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみに表示）。デフォルトは`false`です。 |
| `discussion_id` | 文字列  | いいえ       | 返信先となるディスカッションのグローバルID（形式は`gid://gitlab/Discussion/<id>`）。 |

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
| `url`           | 文字列  | いいえ       | 作業アイテムのURL。`group_id`または`project_id`と`work_item_iid`が指定されていない場合は必須。 |
| `group_id`      | 文字列  | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`    | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `work_item_iid` | 整数 | いいえ       | 作業アイテムの内部ID。`url`が指定されていない場合は必須。 |
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
- GitLab 18.6で、グループおよびプロジェクトの検索、結果の順序および並べ替えが[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/571132)されました。
- GitLab 18.8で`gitlab_search`から`search`に[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734)されました。

{{< /history >}}

検索APIを使用して、GitLabインスタンス全体で用語を検索します。このツールは、グローバル、グループ、プロジェクトの検索に使用できます。利用可能なスコープは、[検索タイプ](../../search/_index.md)によって異なります。

| パラメータ      | 型             | 必須 | 説明 |
|----------------|------------------|----------|-------------|
| `scope`        | 文字列           | はい      | 検索スコープ（`issues`、`merge_requests`、`projects`など）。 |
| `search`       | 文字列           | はい      | 検索語句。 |
| `group_id`     | 文字列           | いいえ       | 検索するグループのIDまたはURLエンコードされたパス。 |
| `project_id`   | 文字列           | いいえ       | 検索するプロジェクトのIDまたはURLエンコードされたパス。 |
| `state`        | 文字列           | いいえ       | 検索結果のステータス（`issues`、`merge_requests`の場合）。 |
| `confidential` | ブール値          | いいえ       | （`issues`の場合）機密性で結果をフィルタリングします。デフォルトは`false`です。 |
| `fields`       | 文字列の配列 | いいえ       | 検索するフィールドの配列（`issues`、`merge_requests`の場合）。 |
| `order_by`     | 文字列           | いいえ       | 結果の並び替えに使用する属性。デフォルトは、基本的な検索の場合は`created_at`、高度な検索の場合はrelevance（関連度）です。 |
| `sort`         | 文字列           | いいえ       | 結果の並び替え方向。デフォルトは`desc`です。 |
| `per_page`     | 整数          | いいえ       | ページあたりの結果数。デフォルトは`20`です。 |
| `page`         | 整数          | いいえ       | 現在のページ番号。デフォルトは`1`です。 |

例: 

```plaintext
Search issues for "flaky test" across GitLab
```

## `search_labels` {#search_labels}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218121)されました。

{{< /history >}}

GitLabプロジェクトまたはグループ内のラベルを検索します。

| パラメータ    | 型    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `full_path`  | 文字列  | はい      | プロジェクトまたはグループのフルパス（例: `group/project`）。 |
| `is_project` | ブール値 | はい      | プロジェクト（`true`）またはグループ（`false`）で検索するかどうか。 |
| `search`     | 文字列  | いいえ       | ラベルをタイトルでフィルタリングするための検索語。 |

グループラベルを検索すると、祖先グループおよび子孫グループからのラベルが結果に含まれます。

例: 

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `semantic_code_search` {#semantic_code_search}

{{< history >}}

- GitLab 18.5で`code_snippet_search_graphqlapi`[フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/569624)されました。デフォルトでは無効になっています。
- GitLab 18.6でプロジェクトパスでの検索が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/575234)されました。
- GitLab 18.7で実験的機能から[ベータ版](../../../policy/development_stages_support.md#beta)に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568359)されました。機能フラグ`code_snippet_search_graphqlapi`は削除されました。
- GitLab 18.7で`mcp_client`[フラグ](../../../administration/feature_flags/_index.md)とともにGitLab UIに[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/581105)されました。デフォルトでは無効になっています。

{{< /history >}}

GitLabプロジェクト内の関連するコードスニペットを検索します。セットアップおよびイネーブルメントを含む詳細については、[セマンティックコード検索](../semantic_code_search.md)を参照してください。

| パラメータ        | 型    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `semantic_query` | 文字列  | はい      | コードの検索クエリ。 |
| `project_id`     | 文字列  | はい      | プロジェクトのIDまたはパス。 |
| `directory_path` | 文字列  | いいえ       | ディレクトリのパス（`app/services/`など）。 |
| `knn`            | 整数 | いいえ       | 類似のコードスニペットを検出するために使用される最近傍の数。デフォルトは`64`です。 |
| `limit`          | 整数 | いいえ       | 返す結果の最大数。デフォルトは`20`です。 |

最良の結果を得るには、一般的なキーワードや特定の関数名または変数名を使用するのではなく、関心のある機能または動作について記述してください。

例: 

```plaintext
How are authorizations managed in this project?
```
