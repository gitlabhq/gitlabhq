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
> この機能に関するフィードバックを提供するには、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントしてください。

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
| `reviewer_ids`      | 整数の配列 | いいえ       | マージリクエストのレビュアーのIDの配列。すべてのレビュアーの割り当てを解除するには、`0`または空の値を設定します。 |
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
- GitLab 19.3で`url`を受け入れるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/605878)され、関連するデータファセットを返すようになりました。

{{< /history >}}

マージリクエスト、およびオプションでその差分、コミット、ノート、パイプライン、またはディスカッションを取得する。`include`パラメータで関連データを要求しない限り、ベースのマージリクエストのみが返されます。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | GitLabのマージリクエストのURL。これ、または`project_id`と`merge_request_iid`を指定します。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはURLエンコードされたパス。`url`が指定されていない場合は必須。 |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。 |
| `include`           | 配列   | いいえ       | マージリクエストとともに返す関連ファセット。`diffs`、`commits`、`notes`、`pipelines`、`discussions`のいずれかの呼び出しごとに1つのファセットに限定されます。 |
| `notes_after`       | 文字列  | いいえ       | ノートの順方向ページネーションのカーソル。`include`が`["notes"]`の場合にのみ適用されます。 |
| `notes_first`       | 整数 | いいえ       | カーソル以降に返すノートの数（最大100）。`include`が`["notes"]`の場合にのみ適用されます。 |

`diffs`ファセットは、変更統計（合計値とファイルごとの追加および削除）のみを返します。パッチテキストを取得するには、`get_merge_request_diffs`を使用します。

例: 

```plaintext
Get merge request 15 in project gitlab-org/gitlab with its commits
```

## `list_duo_sessions` {#list_duo_sessions}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248587)されました。

{{< /history >}}

GitLab Duo Agent Platformのセッションをリスト表示します（Duo Chatセッションを除く）。各セッションには、個別のステータス、ゴールプレビュー、フロー定義、および作成日時が含まれます。プロジェクトセッションにはセッションURLも含まれます。ゴールプレビューは切り詰められている場合があります。

| パラメータ      | タイプ    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `url`          | 文字列  | いいえ       | GitLabのプロジェクトのURL。セッションをフィルタリングするために使用します。`project_id`と一緒に使用しないでください。 |
| `project_id`   | 文字列  | いいえ       | セッションをフィルタリングするプロジェクトの数値IDまたはフルパス。`url`と一緒に使用しないでください。 |
| `status_group` | 文字列  | いいえ       | セッションステータスグループ。`active`、`paused`、`awaiting_input`、`completed`、`failed`、`canceled`のいずれか。 |
| `after`        | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`        | 整数 | いいえ       | 順方向ページネーションで返すセッションの数。デフォルトは20、最大は100です。 |

`status_group`フィルターは、複数の個別のステータスを持つセッションを返すことができます。呼び出しごとに結果の単一ページが返されます。さらにページが存在する場合、レスポンスには`pageInfo.endCursor`が含まれており、これを`after`として渡すことができます。

例: 

```plaintext
List my active Duo Agent Platform sessions in gitlab-org/gitlab
```

## `list_merge_requests` {#list_merge_requests}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246413)されました。

{{< /history >}}

GitLabプロジェクト内のマージリクエストをリスト表示または検索し、コンパクトなマージリクエストのメタデータを返します。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | プロジェクトのURL。`url`または`project_id`のいずれか一方のみを指定してください。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`または`project_id`のいずれか一方のみを指定してください。 |
| `author_username`   | 文字列  | いいえ       | マージリクエストの作成者のユーザー名でフィルタリングします。 |
| `assignee_username` | 文字列  | いいえ       | 割り当てられたユーザーのユーザー名でフィルタリングします。 |
| `reviewer_username` | 文字列  | いいえ       | レビュアーのユーザー名でフィルタリングします。 |
| `state`             | 文字列  | いいえ       | 状態でフィルターします。`opened`、`closed`、`merged`、`locked`、`all`のいずれかの状態を含めるには省略します。 |
| `scope`             | 文字列  | いいえ       | 認証済みユーザーを基準にフィルタリングします。`created_by_me`、`assigned_to_me`、`review_requested`のいずれかです。そのフィールドでは、明示的なユーザー名が優先されます。 |
| `milestone`         | 文字列  | いいえ       | マイルストーンのタイトルでフィルタリングします。 |
| `labels`            | 文字列  | いいえ       | ラベル名のコンマ区切りリスト。これらのラベルがすべて付いているマージリクエストのみが返されます。 |
| `search`            | 文字列  | いいえ       | マージリクエストのタイトルと説明に対して一致した検索クエリ。 |
| `after`             | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`             | 整数 | いいえ       | 順方向ページネーションで返すマージリクエストの数。デフォルトは20、最大は100です。 |

単一のマージリクエストを詳細に取得するには、`get_merge_request`を使用します。その差分、コミット、およびノートは、`get_merge_request_diffs`、`get_merge_request_commits`、および`get_merge_request_notes`から入手できます。リソースタイプ全体の全文検索には、`search`を使用します。

例: 

```plaintext
List my open merge requests in gitlab-org/gitlab
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

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/597494)されました。

{{< /history >}}

認証済みユーザーとして、GitLabマージリクエストのディスカッションにコメントまたは返信を追加します。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | GitLabマージリクエストのURL。`project_id`および`merge_request_iid`が指定されていない場合は必須。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはURLエンコードされたパス。`url`が指定されていない場合は必須。 |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。 |
| `body`              | 文字列  | はい      | ノートの内容。クイックアクションがトリガーされるのを避けるため、行の先頭に`/`を使用することはできません（例: `/merge`）。 |
| `discussion_id`     | 文字列  | いいえ       | 返信先となるディスカッションのグローバルID（形式は`gid://gitlab/Discussion/<id>`）。指定されていない場合、新しいトップレベルのノートが作成されます。 |

例: 

```plaintext
Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
```

## `get_merge_request_notes` {#get_merge_request_notes}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/597494)されました。

{{< /history >}}

特定のGitLabマージリクエストのノート（コメントおよびシステムノート）を取得します。

| パラメータ           | タイプ    | 必須 | 説明                                                                                    |
|---------------------|---------|----------|--------------------------------------------------------------------------------------------------|
| `url`               | 文字列  | いいえ       | GitLabマージリクエストのURL。`project_id`および`merge_request_iid`が指定されていない場合は必須。   |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはURLエンコードされたパス。`url`が指定されていない場合は必須。                           |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。                                |
| `after`             | 文字列  | いいえ       | 順方向ページネーションのカーソル。                                                                 |
| `before`            | 文字列  | いいえ       | 逆方向ページネーションのカーソル。                                                                |
| `first`             | 整数 | いいえ       | 順方向ページネーションで返すノート数。                                              |
| `last`              | 整数 | いいえ       | 逆方向ページネーションで返すノート数。                                             |

返される各ノートにはディスカッションIDが含まれるため、関連するノートをスレッドにまとめることができます。

例: 

```plaintext
Show me all comments on merge request 5 in project gitlab-org/gitlab
```

## `save_merge_request_review` {#save_merge_request_review}

{{< history >}}

- GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605881)されました。

{{< /history >}}

認証済みユーザーとしてマージリクエストのレビューアーティファクトを書き込みます。各呼び出しは、`method`パラメータで選択された1つの操作のみを実行します:

| 方法               | Action |
|----------------------|--------|
| `create_note`        | トップレベルのコメントを追加します。 |
| `reply_discussion`   | 既存のディスカッションに返信します。 |
| `create_diff_note`   | 特定の差分行にコメントします。 |
| `resolve_discussion` | ディスカッションを解決するか未解決にするか。 |
| `submit_review`      | 複数の差分コメントとオプションの要約を1回の呼び出しで投稿します。 |
| `post_duo_review`    | GitLab Duoにマージリクエストのレビューを依頼します。GitLab Duoコードレビューが必要です。 |

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | GitLabマージリクエストのURL。`project_id`および`merge_request_iid`が指定されていない場合は必須。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`が指定されていない場合は必須。 |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。 |
| `method`            | 文字列  | はい      | 実行する操作。別のメソッドに属するパラメータは拒否されます。 |
| `body`              | 文字列  | いいえ       | ノートテキスト。`create_note`、`reply_discussion`、および`create_diff_note`に必要です。クイックアクションがトリガーされるのを避けるため、行の先頭に`/`を使用することはできません（例: `/merge`）。 |
| `discussion_id`     | 文字列  | いいえ       | 処理対象のディスカッション。`reply_discussion`と`resolve_discussion`に必要です。グローバルIDまたは裸のディスカッションIDを受け入れます。 |
| `internal`          | ブール値 | いいえ       | `create_note`の場合、ノートを内部としてマークします。 |
| `resolved`          | ブール値 | いいえ       | `resolve_discussion`の場合: `true`は解決する、`false`は未解決にする。そのメソッドに必要です。 |
| `old_path`          | 文字列  | いいえ       | `create_diff_note`の場合、変更前のファイルパス。`old_path`または`new_path`、あるいはその両方を指定します。 |
| `new_path`          | 文字列  | いいえ       | `create_diff_note`の場合、変更後のファイルパス。 |
| `old_line`          | 整数 | いいえ       | `create_diff_note`の場合、古いバージョンの行番号。`old_line`または`new_line`、あるいはその両方を指定します。 |
| `new_line`          | 整数 | いいえ       | `create_diff_note`の場合、新しいバージョンの行番号。 |
| `comments`          | 配列   | いいえ       | `submit_review`の場合、1〜20個の差分コメント。各エントリは`file`と`body`（必須）、および`old_line`、`new_line`、`suggestion`（オプション）を取ります。そのメソッドに必要です。`file`は変更後のパスです。ファイル名を変更した場合は、代わりに`create_diff_note`を使用してください。 |
| `verdict`           | 文字列  | いいえ       | `submit_review`の場合、要約ノートの前にプレフィックスとして付けられる全体的な評決。 |
| `summary`           | 文字列  | いいえ       | `submit_review`の場合、差分コメントの後に投稿される要約ノート。 |
| `summary_internal`  | ブール値 | いいえ       | `submit_review`の場合、要約ノートを内部としてマークします。 |

例: 

```plaintext
Review merge request 42 in project gitlab-org/gitlab and leave your findings as diff comments with a summary
```

## `add_branch` {#add_branch}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605877)されました。`create_branch`もエイリアスとして受け入れられます。

{{< /history >}}

GitLabプロジェクトにソース参照からブランチを追加します。

| パラメータ    | タイプ   | 必須 | 説明 |
|--------------|--------|----------|-------------|
| `url`        | 文字列 | いいえ       | GitLabのプロジェクトのURL。これ、または`project_id`を指定します。 |
| `project_id` | 文字列 | いいえ       | プロジェクトのIDまたはパス。`url`が提供されない場合に必要です。 |
| `branch`     | 文字列 | はい      | 新しいブランチの名前。 |
| `ref`        | 文字列 | はい      | 新しいブランチを作成する元のブランチ名またはコミットSHA。 |

例: 

```plaintext
Create a branch named feature/x from main in project gitlab-org/gitlab
```

## `get_repository_file` {#get_repository_file}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248744)されました。

{{< /history >}}

特定のrefにあるリポジトリから単一ファイルのコンテンツを取得する。

コンテンツはリポジトリから取得され、ローカルファイルシステムからは取得されません。ファイルは`ref`でコミットされた状態で返されるため、ローカルのチェックアウトにおける未コミットの変更は含まれません。

| パラメータ    | タイプ    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `url`        | 文字列  | いいえ       | ファイルのURL。`https://gitlab.example.com/my-group/my-project/-/blob/main/app/models/user.rb`など。これ、または`project_id`、`file_path`、および`ref`を指定します。 |
| `project_id` | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が提供されない場合に必要です。 |
| `file_path`  | 文字列  | いいえ       | リポジトリのルートからの相対ファイルパス。`url`が提供されない場合に必要です。 |
| `ref`        | 文字列  | いいえ       | ブランチ名、タグ名、またはコミットSHA。デフォルトブランチには`HEAD`を使用します。`url`が提供されない場合に必要です。 |
| `offset`     | 整数 | いいえ       | 読み取りを開始するゼロベースの行（オフセット）。デフォルトは`0`です。 |
| `limit`      | 整数 | いいえ       | 返される行の最大数。デフォルトおよび最大値は`2000`です。 |

レスポンスには、`total_lines`、`returned_lines`、`truncated`、および`size_bytes`を含む`metadata`オブジェクトが含まれています。レスポンスがファイルの一部のみをカバーする場合、`system_instruction`は次の呼び出しで使用する`offset`（オフセット）を示します。

このツールはテキストのみを返します。バイナリファイルおよびGit LFSに保存されているファイルはエラーを返します。プロジェクトがGitLab Duoコンテキストから除外するファイルもエラーを返します。

例: 

```plaintext
Show me app/models/user.rb from the main branch of my-group/my-project
```

## `get_commit` {#get_commit}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/605874)されました。

{{< /history >}}

単一のコミットのメタデータ、およびオプションでその差分またはノートを取得する。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `url`         | 文字列  | いいえ       | GitLabのコミットのURL。`project_id`と`commit_sha`が提供されない場合に必要です。 |
| `project_id`  | 文字列  | いいえ       | プロジェクトのIDまたはURLエンコードされたパス。`url`が提供されない場合に必要です。 |
| `commit_sha`  | 文字列  | いいえ       | コミットを検索します。フルまたはショートSHA、ブランチ名、またはタグ名を受け入れます。`url`が提供されない場合に必要です。 |
| `include`     | 配列   | いいえ       | 関連するファセットをフェッチしてインラインで表示します。呼び出しごとに1つ（`diff`または`notes`）。ベースメタデータは常に返されます。 |
| `diff_detail` | 文字列  | いいえ       | コミット差分の詳細レベル。`include`に`diff`が含まれる場合にのみ適用されます。`stats`または`full_patch`のいずれかになります。デフォルトは`stats`です。 |
| `notes_after` | 文字列  | いいえ       | 次のノートページをフェッチするためのトークン。`include`に`notes`が含まれる場合にのみ適用されます。 |
| `notes_first` | 整数 | いいえ       | 1ページあたりに返すノートの数（最大100）。`include`に`notes`が含まれる場合にのみ適用されます。 |

`diff_detail`を`stats`に設定すると、差分ファセットはファイルごとおよび要約の行数を返します。`full_patch`を使用すると、パッチテキストを返します。

例: 

```plaintext
Show me commit abc123 in gitlab-org/gitlab with its diff stats
```

## `get_pipeline` {#get_pipeline}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605853)されました。

{{< /history >}}

パイプライン、およびオプションでそのジョブ、ダウンストリームパイプライン、またはブリッジ（トリガー）ジョブを取得する。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `id`          | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `pipeline_id` | 整数 | はい      | パイプラインのID。 |
| `include`     | 配列   | いいえ       | パイプラインに含めるファセット（呼び出しごとに1つ）：`jobs`、`downstream_pipelines`、または`bridge_jobs`。 |
| `job_status`  | 文字列  | いいえ       | `jobs`ファセットをステータスでフィルタリングします（例: `failed`）。`include`が`jobs`の場合にのみ適用されます。 |
| `first`       | 整数 | いいえ       | 選択された`include`ファセットに対して返すアイテムの数。デフォルトは`20`、最大は`100`です。 |
| `after`       | 文字列  | いいえ       | 選択された`include`ファセットの順方向ページネーションのカーソル。以前のレスポンスの`page_info.end_cursor`を使用します。 |

ブリッジジョブの`downstream_pipeline`は、トリガージョブがまだダウンストリームパイプラインをトリガーしていない場合と、そのパイプラインにアクセスできない場合の両方で省略されます（`null`）。

ダウンストリームパイプラインは別のプロジェクトに属する可能性があるため、各ダウンストリームパイプラインには`project_full_path`が含まれます。その値を後続の呼び出しの`id`として使用します。

例: 

- パイプラインを取得する:

  ```plaintext
  Get the status of pipeline 12345 in project gitlab-org/gitlab
  ```

- パイプラインの失敗したジョブを取得する:

  ```plaintext
  Show me the failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- パイプラインのダウンストリームパイプラインを取得する:

  ```plaintext
  Show me the downstream pipelines triggered by pipeline 12345 in project gitlab-org/gitlab
  ```

## `get_pipeline_jobs` {#get_pipeline_jobs}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。

{{< /history >}}

特定のGitLab CI/CDパイプラインのジョブを取得します。ジョブをパイプラインの他のデータとともに単一の呼び出しで取得するには、代わりに`include: jobs`を指定して`get_pipeline`ツールを使用します。

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

## `get_job` {#get_job}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856)されました。
- GitLab 19.3で`get_job_log`から[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856)されました。`get_job_log`はエイリアスとして機能し続け、常に`byte_limit`で上限が設定された`log`ファセットを返します。

{{< /history >}}

CI/CDジョブのメタデータ、およびオプションでそのトレース/ログを取得する。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `id`          | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `job_id`      | 整数 | はい      | ジョブのID。 |
| `include`     | 配列   | いいえ       | ジョブに含めるファセット（呼び出しごとに1つ）：`log`。 |
| `byte_offset` | 整数 | いいえ       | ジョブのログの読み取りを開始するバイトオフセット。`include`が`log`の場合にのみ適用されます。デフォルトは`0`です。 |
| `byte_limit`  | 整数 | いいえ       | ジョブのログで返すバイトの最大数。`include`が`log`の場合にのみ適用されます。デフォルトおよび最大値は`512000`です。 |

ログが`byte_limit`より長い場合、レスポンスは合計サイズを報告し、次のウィンドウで使用する`byte_offset`（オフセット）を通知します。

例: 

- ジョブのメタデータを取得する:

  ```plaintext
  Get the status of job 88 in project gitlab-org/gitlab
  ```

- ジョブのログを取得する:

  ```plaintext
  Show me the log output for job 88 in project gitlab-org/gitlab
  ```

## `list_pipelines` {#list_pipelines}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605854)されました。

{{< /history >}}

GitLabプロジェクト内のパイプラインを、オプションのフィルターでリスト表示します。

| パラメータ        | タイプ    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `id`             | 文字列  | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `ref`            | 文字列  | いいえ       | ブランチまたはタグ名。パイプラインをrefでフィルタリングします。 |
| `status`         | 文字列  | いいえ       | パイプラインをステータスでフィルタリングします（例: `running`、`success`、`failed`）。 |
| `source`         | 文字列  | いいえ       | パイプラインをソースでフィルタリングします（例: `push`、`web`、`schedule`）。 |
| `created_after`  | 文字列  | いいえ       | 指定された日付時刻（ISO 8601形式）以降に作成されたパイプラインを返します。 |
| `created_before` | 文字列  | いいえ       | 指定された日付時刻（ISO 8601形式）より前に作成されたパイプラインを返します。 |
| `order_by`       | 文字列  | いいえ       | パイプラインを`id`、`status`、`ref`、`updated_at`、または`user_id`で並べ替えます。デフォルトは`id`です。 |
| `sort`           | 文字列  | いいえ       | ソート方向。`asc`または`desc`。デフォルトは`desc`です。 |
| `page`           | 整数 | いいえ       | 現在のページ番号。デフォルトは`1`です。 |
| `per_page`       | 整数 | いいえ       | 1ページあたりのアイテム数。デフォルトは`20`です。 |

子パイプラインはデフォルトで結果から除外されます。子パイプラインのみを返すには、`source`を`parent_pipeline`に設定します。

デフォルトの順序（`id`、`desc`）では、IDが最も大きいパイプラインが最初に返されます。IDの順序は通常作成順序と一致しますが、両者が一致することは保証されません。明示的な時間境界でフィルタリングするには、`created_after`または`created_before`を使用します。呼び出し元は結果をページングし、対象範囲外の最初のパイプラインで停止できます。

例: 

```plaintext
List all failed pipelines on the main branch for project gitlab-org/gitlab
```

## `save_pipeline` {#save_pipeline}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855)されました。

{{< /history >}}

GitLabプロジェクトでCI/CDパイプラインを実行、再試行、またはキャンセルします。パイプラインのメタデータを更新するか、パイプラインを削除するには、代わりに`manage_pipeline`ツールを使用します。パイプラインをリスト表示するには、代わりに`list_pipelines`ツールを使用します。

| パラメータ     | タイプ    | 必須    | 説明 |
|---------------|---------|-------------|-------------|
| `url`         | 文字列  | いいえ          | GitLabのプロジェクトのURL。パイプラインの作成にのみ使用されます。これ、または`project_id`を指定します。 |
| `project_id`  | 文字列  | いいえ          | プロジェクトのIDまたはフルパス。パイプラインの作成にのみ使用されます。これ、または`url`を指定します。 |
| `pipeline_id` | 整数 | いいえ          | ターゲットとする既存のパイプラインのID。設定されている場合、`action`が必要です。新しいパイプラインを作成するには省略します。 |
| `action`      | 文字列  | いいえ          | `pipeline_id`に対して実行するライフサイクルアクション: `retry`または`cancel`。`pipeline_id`が設定されている場合に必要です。 |
| `ref`         | 文字列  | いいえ          | ブランチまたはタグ名。パイプラインを作成する際に必要です（`pipeline_id`が存在しない場合）。 |
| `variables`   | 配列   | いいえ          | 配列形式のパイプライン変数（`[{key, value, variable_type}]`）。 |
| `inputs`      | ハッシュ    | いいえ          | キー/バリューペアで指定するパイプラインインプットパラメータ。 |

例: 

- パイプラインを作成:

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- パイプラインを再試行:

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- パイプラインをキャンセル:

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

## `manage_pipeline` {#manage_pipeline}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)されました。
- GitLab 19.3で`list_pipelines`ツールを優先して`list`アクションを[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247806)しました。
- GitLab 19.3で`save_pipeline`ツールを優先して`create`、`retry`、および`cancel`アクションを[削除](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855)しました。

{{< /history >}}

GitLabプロジェクト内のパイプラインのメタデータを更新するか、パイプラインを削除します。パイプラインを作成、再試行、またはキャンセルするには、代わりに`save_pipeline`ツールを使用します。パイプラインをリスト表示するには、代わりに`list_pipelines`ツールを使用します。

| パラメータ     | タイプ    | 必須    | 説明 |
|---------------|---------|-------------|-------------|
| `id`          | 文字列  | はい         | プロジェクトのIDまたはURLエンコードされたパス。 |
| `pipeline_id` | 整数 | はい         | パイプラインのID。このパラメータのみが設定されている場合、パイプラインおよびすべての関連データを削除します。 |
| `name`        | 文字列  | いいえ          | パイプラインの名前。このパラメータと`pipeline_id`が設定されている場合、パイプラインのメタデータを更新します。 |

例: 

- パイプラインを更新:

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
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
| `internal`      | ブール値 | いいえ       | ノートを内部ノートとしてマークします（プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみに表示）。デフォルトは`false`です。 |
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

関係タイプを指定して、作業アイテムを1つ以上の他の作業アイテムにリンクします。

| パラメータ        | タイプ             | 必須 | 説明 |
|------------------|------------------|----------|-------------|
| `work_items_ids` | 文字列の配列 | はい      | リンク先の作業アイテムのグローバルID（形式は`gid://gitlab/WorkItem/<id>`）。最大10アイテム。 |
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

ネームスペースから、保存済みのビューとその作業アイテムのリストを取得します。このツールは、保存済みのビューのフィルターと並び順を、返される作業アイテムに適用します。

| パラメータ       | タイプ    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `saved_view_id` | 文字列  | はい      | 保存済みのビューのグローバルID（形式は`gid://gitlab/WorkItems::SavedViews::SavedView/<id>`）。 |
| `url`           | 文字列  | いいえ       | ネームスペース（プロジェクトまたはグループ）のURL。`group_id`または`project_id`が指定されていない場合は必須です。 |
| `group_id`      | 文字列  | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`    | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `after`         | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`         | 整数 | いいえ       | 返される作業アイテムの数。最大値は100。 |

例: 

```plaintext
Show me the work items in this saved view: <URL>
```

## `save_work_item` {#save_work_item}

{{< history >}}

- GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605852)されました。

{{< /history >}}

GitLab作業アイテム（イシュー、タスク、エピックなど）を作成または更新します。新しい作業アイテムを作成するには`work_item_iid`を省略します。既存の作業アイテムを更新するには、`work_item_iid`または作業アイテムのURLを指定します。ツール名`create_work_item`と`update_work_item`は、このツールのエイリアスです。

| パラメータ          | タイプ              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `url`              | 文字列            | いいえ       | プロジェクト、グループ、または作業アイテムのGitLab URL。`url`、`project_id`、または`group_id`のいずれか一方のみを指定してください。 |
| `group_id`         | 文字列            | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`       | 文字列            | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `work_item_iid`    | 整数           | いいえ       | 更新する作業アイテムの内部ID。新しい作業アイテムを作成するには省略します。 |
| `title`            | 文字列            | いいえ       | 作業アイテムのタイトル。作業アイテムを作成する際に必要です。 |
| `type_name`        | 文字列            | いいえ       | 作業アイテムのタイプ名。`Issue`、`Task`、または`Epic`など。作業アイテムを作成する際に必要です。有効なタイプは、ネームスペースとライセンスによって異なります。 |
| `description`      | 文字列            | いいえ       | GitLab Flavored Markdownでの説明。最大1,048,576文字。 |
| `assignee_ids`     | 整数の配列 | いいえ       | 作業アイテムに割り当てるユーザーID。最大100アイテム。 |
| `label_ids`        | 文字列の配列  | いいえ       | ラベルIDまたはグローバルID。作成のみ。更新時には`add_label_ids`または`remove_label_ids`を使用します。最大100アイテム。 |
| `add_label_ids`    | 文字列の配列  | いいえ       | 更新のみ。追加するラベルIDまたはグローバルID。最大100アイテム。 |
| `remove_label_ids` | 文字列の配列  | いいえ       | 更新のみ。削除するラベルIDまたはグローバルID。最大100アイテム。 |
| `confidential`     | ブール値           | いいえ       | 作業アイテムの機密性を設定します。 |
| `start_date`       | 文字列            | いいえ       | 開始日（`YYYY-MM-DD`形式）。 |
| `due_date`         | 文字列            | いいえ       | 期日（`YYYY-MM-DD`形式）。 |
| `state`            | 文字列            | いいえ       | 更新のみ。`closed`は作業アイテムを閉じ、`opened`は再オープンします。 |
| `parent_id`        | 文字列            | いいえ       | 親作業アイテムのグローバルIDまたは数値ID。 |
| `todo_action`      | 文字列            | いいえ       | 更新のみ。`add`は現在のユーザーのTo-Doを追加し、`mark_as_done`はTo-Doを完了としてマークします。 |
| `todo_id`          | 文字列            | いいえ       | 更新のみ。To-DoのグローバルIDまたは数値ID。作業アイテム上のすべてのTo-Doを更新するには省略します。 |
| `health_status`    | 文字列            | いいえ       | ヘルスステータス。`onTrack`、`needsAttention`、`atRisk`のいずれかです。Ultimateのみです。 |
| `weight`           | 整数           | いいえ       | 作業アイテムのウェイト。0以上である必要があります。PremiumおよびUltimateのみです。 |
| `clear_weight`     | ブール値           | いいえ       | 更新のみ。ウェイトを削除します。`weight`よりも優先されます。PremiumおよびUltimateのみです。 |
| `status_id`        | 文字列            | いいえ       | 設定するステータスのグローバルID。PremiumおよびUltimateのみです。 |
| `is_fixed`         | ブール値           | いいえ       | 開始日と期日が固定されているかどうか。`false`の場合、日付は子アイテムから繰り上がり、`start_date`と`due_date`は無視されます。PremiumおよびUltimateのみです。 |
| `agent_plan`       | 文字列            | いいえ       | エージェントプランのMarkdownコンテンツ。Ultimateのみです。ワークプラン機能が必要です。 |

例: 

```plaintext
Create a task "Update the onboarding guide" in project gitlab-org/gitlab and assign it to me
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
| `scope`        | 文字列           | はい      | 検索スコープ（`work_items`、`merge_requests`、`projects`など）。 |
| `search`       | 文字列           | はい      | 検索語句。 |
| `group_id`     | 文字列           | いいえ       | 検索するグループのIDまたはURLエンコードされたパス。 |
| `project_id`   | 文字列           | いいえ       | 検索するプロジェクトのIDまたはURLエンコードされたパス。 |
| `state`        | 文字列           | いいえ       | 検索結果のステータス（`work_items`、`merge_requests`の場合）。 |
| `confidential` | ブール値          | いいえ       | （`work_items`の場合）機密性で結果をフィルタリングします。デフォルトは`false`です。 |
| `fields`       | 文字列の配列 | いいえ       | 検索するフィールドの配列（`work_items`、`merge_requests`の場合）。 |
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

グループラベルを検索すると、祖先グループおよび子孫グループにあるラベルが結果に含まれます。

例: 

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `list_wiki_pages` {#list_wiki_pages}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240973)されました。

{{< /history >}}

GitLabプロジェクトまたはグループ内のWikiページをリスト表示します。

| パラメータ    | タイプ    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `project_id` | 文字列  | いいえ       | プロジェクトのフルパスまたは数値ID（例: `gitlab-org/gitlab`または`278964`）。 |
| `group_id`   | 文字列  | いいえ       | グループのフルパスまたは数値ID（例: `gitlab-org`または`9970`）。 |
| `first`      | 整数 | いいえ       | 順方向ページネーションで返すWikiページの数（最大100）。 |
| `after`      | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |

`project_id`または`group_id`のいずれか一方のみを指定してください。呼び出しごとに結果の単一ページが返されます。さらにページが存在する場合、レスポンスには`end_cursor`が含まれており、これを`after`として渡して次のページをフェッチできます。

例: 

```plaintext
List the wiki pages in gitlab-org/gitlab
```

## `semantic_code_search` {#semantic_code_search}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.5で`code_snippet_search_graphqlapi`[機能フラグ](../../administration/feature_flags/_index.md)とともに[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/569624)されました。デフォルトでは無効になっています。
- GitLab 18.6でプロジェクトパスでの検索が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/575234)されました。
- GitLab 18.7で実験的機能から[ベータ版](../../policy/development_stages_support.md#beta)に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568359)されました。機能フラグ`code_snippet_search_graphqlapi`は削除されました。
- GitLab 18.7で`mcp_client`[機能フラグ](../../administration/feature_flags/_index.md)とともにGitLab UIに[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/581105)されました。デフォルトでは無効になっています。
- GitLab 18.11で、`mcp_semantic_code_search_use_rest_api`[機能フラグ](../../administration/feature_flags/_index.md)とともに、[REST API](../../api/search.md#semantic-search)を使用するように[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228569)されました。デフォルトでは無効になっています。
- GitLab 19.1でREST APIの使用が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239364)になりました。機能フラグ`mcp_semantic_code_search_use_rest_api`は削除されました。

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

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240685)されました。

{{< /history >}}

指定したセキュリティスキャンプロファイルを、指定したプロジェクト、または指定したグループ配下のすべてのプロジェクトに関連付けます。

| パラメータ                  | タイプ             | 必須 | 説明 |
|----------------------------|------------------|----------|-------------|
| `security_scan_profile_id` | 文字列           | はい      | セキュリティスキャンプロファイルのグローバルID（例: `gid://gitlab/Security::ScanProfile/1`）。 |
| `project_ids`              | 文字列の配列 | いいえ       | プロジェクトのグローバルIDの配列（例: `[gid://gitlab/Project/1]`）。`group_ids`が指定されていない限り、これは必須です。 |
| `group_ids`                | 文字列の配列 | いいえ       | グループのグローバルIDの配列（例: `[gid://gitlab/Group/1]`）。`project_ids`が指定されていない限り、これは必須です。 |

例: 

```plaintext
Attach `gid://gitlab/Security::ScanProfile/1` to all projects under `gid://gitlab/Group/1`.
```
