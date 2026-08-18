---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: これらのツールを使用して、GitLab MCPサーバーを介してGitLabとやり取りします。
title: GitLab MCPサーバーツール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

> [!warning]
> この機能に関するフィードバックを提供するには、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントを残してください。

GitLab MCPサーバーは、既存のGitLabワークフローと連携して動作する一連のツールを提供します。これらのツールを使用して、GitLabと直接やり取りし、一般的なGitLabの操作を実行できます。

## `get_mcp_server_version` {#get_mcp_server_version}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200105)されました。

{{< /history >}}

GitLab MCPサーバーの現在のバージョンを返します。

例: 

```plaintext
What version of the GitLab MCP server am I connected to?
```

## `create_issue` {#create_issue}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。

{{< /history >}}

GitLabプロジェクトに新しいイシューを作成します。

| パラメータ      | タイプ              | 必須 | 説明 |
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

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838)されました。

{{< /history >}}

特定のGitLabイシューに関する詳細情報を取得します。

| パラメータ   | タイプ    | 必須 | 説明 |
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

| パラメータ           | タイプ              | 必須 | 説明 |
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

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838)されました。

{{< /history >}}

特定のGitLabマージリクエストに関する詳細情報を取得します。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

例: 

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

## `get_merge_request_commits` {#get_merge_request_commits}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。

{{< /history >}}

特定のGitLabマージリクエスト内のコミットのリストを取得します。

| パラメータ           | タイプ    | 必須 | 説明 |
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

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。

{{< /history >}}

特定のGitLabマージリクエストの差分を取得します。

| パラメータ           | タイプ    | 必須 | 説明 |
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

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。

{{< /history >}}

特定のGitLabマージリクエストのパイプラインを取得します。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

例: 

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `create_merge_request_note` {#create_merge_request_note}

{{< history >}}

- GitLab 19.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/597494)。

{{< /history >}}

GitLabのマージリクエストのディスカッションに、認証済みユーザーとしてコメントまたは返信を追加します。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | GitLabのマージリクエストのURL。`project_id`および`merge_request_iid`が指定されていない場合は必須。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはURLエンコードされたパス。`url`が指定されていない場合は必須。 |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。 |
| `body`              | 文字列  | はい      | ノートの内容。クイックアクションをトリガーするのを避けるため、行を`/`で始めることはできません（例: `/merge`）。 |
| `discussion_id`     | 文字列  | いいえ       | 返信先となるディスカッションのグローバルID（形式は`gid://gitlab/Discussion/<id>`）。指定されていない場合、新しいトップレベルのノートが作成されます。 |

例: 

```plaintext
Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
```

## `get_merge_request_notes` {#get_merge_request_notes}

{{< history >}}

- GitLab 19.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/597494)。

{{< /history >}}

特定のGitLabマージリクエストのノート（コメントおよびシステムノート）を取得する。

| パラメータ           | タイプ    | 必須 | 説明                                                                                    |
|---------------------|---------|----------|--------------------------------------------------------------------------------------------------|
| `url`               | 文字列  | いいえ       | GitLabのマージリクエストのURL。`project_id`および`merge_request_iid`が指定されていない場合は必須。   |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはURLエンコードされたパス。`url`が指定されていない場合は必須。                           |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。                                |
| `after`             | 文字列  | いいえ       | 順方向ページネーションのカーソル。                                                                 |
| `before`            | 文字列  | いいえ       | 逆方向ページネーションのカーソル。                                                                |
| `first`             | 整数 | いいえ       | 順方向ページネーションで返すノート数。                                              |
| `last`              | 整数 | いいえ       | 逆方向ページネーションで返すノート数。                                             |

返される各ノートにはそのディスカッションIDが含まれるため、関連するノートはスレッドにグループ化できます。

例: 

```plaintext
Show me all comments on merge request 5 in project gitlab-org/gitlab
```

## `get_pipeline_jobs` {#get_pipeline_jobs}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。

{{< /history >}}

特定のGitLab CI/CDパイプラインのジョブを取得します。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `id`          | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `pipeline_id` | 整数 | はい      | パイプラインのID。 |
| `per_page`    | 整数 | いいえ       | ページあたりのジョブ数。 |
| `page`        | 整数 | いいえ       | 現在のページ番号。 |

例: 

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

## `get_job_log` {#get_job_log}

特定のCI/CDジョブのトレース（ログ出力）を取得する。

| パラメータ | タイプ    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `job_id`  | 整数 | はい      | ジョブのID。 |

例: 

```plaintext
Show me the log output for job 88 in project gitlab-org/gitlab
```

## `manage_pipeline` {#manage_pipeline}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)されました。

{{< /history >}}

GitLabプロジェクトでCI/CDパイプラインを管理します。

| パラメータ     | タイプ    | 必須    | 説明 |
|---------------|---------|-------------|-------------|
| `id`          | 文字列  | はい         | プロジェクトのIDまたはURLエンコードされたパス。 |
| `list`        | ブール値 | いいえ          | `true`の場合、プロジェクト内のすべてのパイプラインを一覧表示します。 |
| `ref`         | 文字列  | いいえ          | ブランチまたはタグ名。設定されている場合、ブランチまたはタグ上に新しいパイプラインを作成します。リストのフィルタリングではオプションです。 |
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

| パラメータ       | タイプ    | 必須 | 説明 |
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

| パラメータ       | タイプ    | 必須 | 説明 |
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

## `link_work_items` {#link_work_items}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230221)されました。

{{< /history >}}

作業アイテムを、関係タイプを持つ1つまたは複数の他の作業アイテムにリンクします。

| パラメータ        | タイプ             | 必須 | 説明 |
|------------------|------------------|----------|-------------|
| `work_items_ids` | 文字列の配列 | はい      | リンクする作業アイテムのグローバルID（`gid://gitlab/WorkItem/<id>`の形式）。最大10アイテム。 |
| `url`            | 文字列           | いいえ       | ソース作業アイテムのURL。`group_id`または`project_id`と`work_item_iid`が指定されていない場合は必須。 |
| `group_id`       | 文字列           | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`     | 文字列           | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `work_item_iid`  | 整数          | いいえ       | ソース作業アイテムの内部ID。`url`が指定されていない場合は必須。 |
| `link_type`      | 文字列           | いいえ       | 関係のタイプ。`relates_to`、`blocks`、`blocked_by`のいずれかです。デフォルトは`relates_to`です。`blocks`および`blocked_by`タイプには、PremiumまたはUltimateが必要です。 |

例: 

```plaintext
Mark work item 42 in project gitlab-org/gitlab as blocked by work item 40
```

## `get_saved_view_work_items` {#get_saved_view_work_items}

{{< history >}}

- GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227911)されました。

{{< /history >}}

ネームスペースから保存されたビューと、その作業アイテムのリストを取得する。このツールは、保存されたビューのフィルターとソート順を、返された作業アイテムに適用します。

| パラメータ       | タイプ    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `saved_view_id` | 文字列  | はい      | 保存されたビューのグローバルID（`gid://gitlab/WorkItems::SavedViews::SavedView/<id>`の形式）。 |
| `url`           | 文字列  | いいえ       | ネームスペース（プロジェクトまたはグループ）のURL。`group_id`または`project_id`が指定されていない場合は必須です。 |
| `group_id`      | 文字列  | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`    | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `after`         | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`         | 整数 | いいえ       | 返される作業アイテムの数。最大100。 |

例: 

```plaintext
Show me the work items in this saved view: <URL>
```

## `search` {#search}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/566143)されました。
- GitLab 18.6で、グループおよびプロジェクトの検索、結果の順序および並べ替えが[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/571132)されました。
- GitLab 18.8で`gitlab_search`から`search`に[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734)されました。

{{< /history >}}

検索APIを使用して、GitLabインスタンス全体で用語を検索します。このツールは、グローバル、グループ、プロジェクトの検索に使用できます。利用可能なスコープは、[検索タイプ](../search/_index.md)によって異なります。

| パラメータ      | タイプ             | 必須 | 説明 |
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

| パラメータ    | タイプ    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `full_path`  | 文字列  | はい      | プロジェクトまたはグループのフルパス（例: `group/project`）。 |
| `is_project` | ブール値 | はい      | プロジェクト（`true`）またはグループ（`false`）で検索するかどうか。 |
| `search`     | 文字列  | いいえ       | ラベルをタイトルでフィルタリングするための検索語句。 |

グループラベルを検索すると、祖先グループおよび子孫グループからのラベルが結果に含まれます。

例: 

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `semantic_code_search` {#semantic_code_search}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.5で、`code_snippet_search_graphqlapi`という名前の[機能フラグ](../../administration/feature_flags/_index.md)と共に、[実験](../../policy/development_stages_support.md#experiment)として[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/569624)。デフォルトでは無効になっています。
- GitLab 18.6でプロジェクトパスでの検索が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/575234)されました。
- GitLab 18.7で実験的機能から[ベータ版](../../policy/development_stages_support.md#beta)に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568359)されました。機能フラグ`code_snippet_search_graphqlapi`は削除されました。
- [GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/581105) 18.7で、GitLabのUIに機能フラグ`mcp_client`とともに[追加](../../administration/feature_flags/_index.md)されました。デフォルトでは無効になっています。
- [GitLab](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228569) 18.11で[REST API](../../api/search.md#semantic-search)を使用するように[更新](../../administration/feature_flags/_index.md)され、機能フラグ`mcp_semantic_code_search_use_rest_api`が追加されました。デフォルトでは無効になっています。
- REST APIの使用は[GitLab](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239364) 19.1で一般提供されました。機能フラグ`mcp_semantic_code_search_use_rest_api`は削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLabプロジェクト内の関連するコードスニペットを検索します。セットアップおよびイネーブルメントを含む詳細については、[セマンティックコード検索](../gitlab_duo/semantic_code_search.md)を参照してください。

| パラメータ        | タイプ    | 必須 | 説明 |
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

## `attach_scan_profile` {#attach_scan_profile}

{{< history >}}

- GitLab 19.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240685)。

{{< /history >}}

指定されたセキュリティスキャンプロファイルを、指定されたプロジェクト、または指定されたグループ配下のすべてのプロジェクトにアタッチします。

| パラメータ                  | タイプ             | 必須 | 説明 |
|----------------------------|------------------|----------|-------------|
| `security_scan_profile_id` | 文字列           | はい      | セキュリティスキャンプロファイルのグローバルID（例: `gid://gitlab/Security::ScanProfile/1`）。 |
| `project_ids`              | 文字列の配列 | いいえ       | プロジェクトのグローバルIDの配列（例: `[gid://gitlab/Project/1]`）。`group_ids`が指定されていない限り、これは必須です。 |
| `group_ids`                | 文字列の配列 | いいえ       | グループのグローバルIDの配列（例: `[gid://gitlab/Group/1]`）。`project_ids`が指定されていない限り、これは必須です。 |

例: 

```plaintext
Attach `gid://gitlab/Security::ScanProfile/1` to all projects under `gid://gitlab/Group/1`.
```
