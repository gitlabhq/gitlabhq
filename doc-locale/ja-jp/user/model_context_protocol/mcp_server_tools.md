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
> この機能に関するフィードバックを提供するには、[イシュー630189](https://gitlab.com/gitlab-org/gitlab/-/issues/630189)にコメントを残してください。

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

## `get_project` {#get_project}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250430)ました。

{{< /history >}}

単一のGitLabプロジェクトのメタデータ（数値ID、フルパス、デフォルトブランチ、表示レベル、およびウェブURL）を返します。

| パラメータ    | タイプ   | 必須 | 説明 |
|--------------|--------|----------|-------------|
| `url`        | 文字列 | いいえ       | プロジェクトのURL。`url`または`project_id`のいずれか一方のみを指定してください。 |
| `project_id` | 文字列 | いいえ       | プロジェクトのIDまたはフルパス。`url`または`project_id`のいずれか一方のみを指定してください。 |

プロジェクトにリポジトリがまだない場合、`default_branch`は`null`です。名前がまだわからないプロジェクトを探すには、`projects`スコープを指定して`search`を使用します。

例: 

```plaintext
What is the default branch of gitlab-org/gitlab?
```

## `add_commit` {#add_commit}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605876)されました。
- `start_sha`および`start_project`パラメータがGitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/621972)されました。

{{< /history >}}

1回で1つ以上のファイルアクションを持つコミットをブランチに追加します。

| パラメータ        | タイプ             | 必須 | 説明 |
|------------------|------------------|----------|-------------|
| `commit_message` | 文字列           | はい      | コミットメッセージ。 |
| `actions`        | オブジェクトの配列 | はい      | 単一のバッチとしてコミットするファイルアクション。 |
| `branch`         | 文字列           | はい      | コミット先のブランチの名前。 |
| `project_id`     | 文字列           | いいえ       | プロジェクトのIDまたはパス。`url`が提供されない場合に必要です。 |
| `url`            | 文字列           | いいえ       | GitLabのプロジェクトのURL。`project_id`が提供されない場合に必要です。 |
| `start_branch`   | 文字列           | いいえ       | 新しいブランチの開始元となるブランチの名前。`branch`が存在しない場合、必須です。 |
| `start_sha`      | 文字列           | いいえ       | 新しいブランチを開始するコミットのSHA。`start_branch`と相互に排他的です。 |
| `start_project`  | 文字列           | いいえ       | コミットを開始するプロジェクトのフルパス。プロジェクト自体、またはフォークしたプロジェクトである必要があります。 |

`actions`内の各オブジェクトは以下のフィールドを受け入れます:

| フィールド              | タイプ    | 必須 | 説明 |
|--------------------|---------|----------|-------------|
| `action`           | 文字列  | はい      | 実行するアクション: `create`、`update`、`delete`、`move`、または`chmod`。 |
| `file_path`        | 文字列  | はい      | ファイルのフルパス。 |
| `content`          | 文字列  | いいえ       | ファイルコンテンツ。`create`、`update`、および`move`で使用されます。`old_str`および`new_str`とは相互排他的です。 |
| `old_str`          | 文字列  | いいえ       | `update`アクションで置換する既存のテキスト。`new_str`が必要です。 |
| `new_str`          | 文字列  | いいえ       | `update`アクションでの`old_str`の置換テキスト。 |
| `previous_path`    | 文字列  | いいえ       | 元のファイルパス。`move`に必須です。 |
| `encoding`         | 文字列  | いいえ       | `content`のエンコード: `text`または`base64`。デフォルトは`text`です。 |
| `last_commit_id`   | 文字列  | いいえ       | ファイルの最後の既知のコミットID。楽観的並行処理に使用されます。 |
| `execute_filemode` | ブール値 | いいえ       | ファイルが実行可能であるかどうか。`chmod`に必須です。 |

部分的な編集は、`old_str`の出現を1つだけ置換します。複数回出現する場合は、より多くの周辺コンテキストを提供してください。部分的な編集はサーバー上の完全なファイルを読み取るため、10 MBより大きいファイルには対応していません。より大きなファイルの場合は、代わりにファイルコンテンツ全体をコミットしてください。

部分的な編集は、バイナリファイルやLFSに保存されているファイルには対応していません。

例: 

```plaintext
In project gitlab-org/gitlab, create README.md on branch "docs-update"
with the content "# New title" and commit message "Add README"
```

## `create_issue` {#create_issue}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。
- GitLab 19.4で[非掲載](https://gitlab.com/gitlab-org/gitlab/-/work_items/625129)。[`save_work_item`](#save_work_item)に置き換えられました。

{{< /history >}}

マイルストーンのタイトルとラベル名を同じ場所（プロジェクトとその祖先グループ）で解決しますが、見つからない名前に対してはより厳格な[`save_work_item`](#save_work_item)に置き換えられました。`create_issue`は存在しないラベル名を作成し、不明なマイルストーンのタイトルをサイレントに削除する一方、`save_work_item`は見つからない名前に対してエラーを返します。このツールは`tools/list`には表示されなくなりましたが、呼び出し元が移行する間は呼び出し可能です。

GitLabプロジェクトに新しいイシューを作成します。

| パラメータ      | タイプ              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 文字列            | はい      | プロジェクトのIDまたはフルパス。 |
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
- GitLab 19.4で[非掲載](https://gitlab.com/gitlab-org/gitlab/-/work_items/628333)。[`get_work_item`](#get_work_item)に置き換えられました。

{{< /history >}}

イシューやその他の作業アイテムタイプをカバーする[`get_work_item`](#get_work_item)に置き換えられました。このツールは`tools/list`には表示されなくなりましたが、呼び出し元が移行する間は呼び出し可能です。

特定のGitLabイシューに関する詳細情報を取得します。

| パラメータ   | タイプ    | 必須 | 説明 |
|-------------|---------|----------|-------------|
| `id`        | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `issue_iid` | 整数 | はい      | イシューの内部ID。 |

例: 

```plaintext
Get details for issue 42 in project 123
```

## `save_merge_request` {#save_merge_request}

{{< history >}}

- GitLab 18.5で`create_merge_request`として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/571243)されました。
- GitLab 18.8で`assignee_ids`、`reviewer_ids`、`description`、`labels`、`milestone_id`が[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458)されました。
- `save_merge_request`に名称変更され、GitLab 19.3でマージリクエストを更新するように拡張されました。`create_merge_request`および`update_merge_request`の名前はエイリアスとして残ります。

{{< /history >}}

GitLabプロジェクトでマージリクエストを作成または更新します。`merge_request_iid`の有無によって操作が選択されます: これを省略するとマージリクエストが作成され、提供すると既存のマージリクエストが更新されます。

| パラメータ              | タイプ              | 必須 | 説明 |
|------------------------|-------------------|----------|-------------|
| `project_id`           | 文字列            | はい      | プロジェクトのIDまたはフルパス。 |
| `merge_request_iid`    | 整数           | いいえ       | マージリクエストの内部ID。既存のマージリクエストを更新するには提供し、新規作成するには省略します。 |
| `title`                | 文字列            | いいえ       | マージリクエストのタイトル。作成時に必須です。 |
| `source_branch`        | 文字列            | いいえ       | ソースブランチの名前。作成時に必須です。 |
| `target_branch`        | 文字列            | いいえ       | ターゲットブランチの名前。作成時に必須です。 |
| `target_project_id`    | 整数           | いいえ       | ターゲットプロジェクトのID。作成時に適用されます。 |
| `description`          | 文字列            | いいえ       | マージリクエストの説明。 |
| `labels`               | 文字列の配列  | いいえ       | ラベル名。既存のすべてのラベルを置き換えます。空の配列を渡すと、すべてのラベルが削除されます。 |
| `add_labels`           | 文字列の配列  | いいえ       | 追加するラベル名。更新時に適用されます。 |
| `remove_labels`        | 文字列の配列  | いいえ       | 削除するラベル名。更新時に適用されます。 |
| `assignees`            | 文字列の配列  | いいえ       | 割り当てるユーザー名。`assignee_ids`の代替です。いずれか一方を指定してください。空の配列を渡すと、すべての担当者が削除されます。 |
| `assignee_ids`         | 整数の配列 | いいえ       | 割り当てるユーザーID。`assignees`の代替です。いずれか一方を指定してください。空の配列を渡すと、すべての担当者が削除されます。 |
| `reviewers`            | 文字列の配列  | いいえ       | レビューをリクエストするユーザー名。`reviewer_ids`の代替です。いずれか一方を指定してください。空の配列を渡すと、すべてのレビュアーが削除されます。 |
| `reviewer_ids`         | 整数の配列 | いいえ       | レビューをリクエストするユーザーID。`reviewers`の代替です。いずれか一方を指定してください。空の配列を渡すと、すべてのレビュアーが削除されます。 |
| `milestone_id`         | 整数           | いいえ       | マイルストーンのID。 |
| `milestone`            | 文字列            | いいえ       | プロジェクトまたは祖先グループのマイルストーンのタイトル。`milestone_id`と相互に排他的です。 |
| `remove_source_branch` | ブール値           | いいえ       | マージリクエストがマージされたときに、ソースブランチを削除します。 |
| `squash`               | ブール値           | いいえ       | マージ時にコミットを単一のコミットにスカッシュします。 |
| `state_event`          | 文字列            | いいえ       | 実行するステート移行。`close`または`reopen`のいずれか。更新時に適用されます。 |
| `discussion_locked`    | ブール値           | いいえ       | マージリクエストのディスカッションをロックします。更新時に適用されます。 |
| `allow_collaboration`  | ブール値           | いいえ       | ターゲットブランチにマージできるメンバーからのコミットを許可します。更新時に適用されます。 |

例: 

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

```plaintext
Update merge request 42 in project gitlab-org/gitlab to add the "bug" label and close it
```

## `get_merge_request` {#get_merge_request}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838)されました。
- GitLab 19.3で`url`を受け入れるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/605878)され、関連するデータファセットを返すようになりました。

{{< /history >}}

マージリクエスト、およびオプションでその差分、コミット、ノート、パイプライン、ディスカッション、または競合を取得します。`include`パラメータで関連データを要求しない限り、ベースのマージリクエストのみが返されます。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | GitLabのマージリクエストのURL。これ、または`project_id`と`merge_request_iid`を指定します。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が指定されていない場合は必須。 |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。 |
| `include`           | 配列   | いいえ       | マージリクエストとともに返す関連ファセット。`diffs`、`commits`、`notes`、`pipelines`、`discussions`、`conflicts`のいずれか。呼び出しごとに1つのファセットに限定されます。 |
| `notes_after`       | 文字列  | いいえ       | ノートの順方向ページネーションのカーソル。`include`が`["notes"]`の場合にのみ適用されます。 |
| `notes_first`       | 整数 | いいえ       | カーソル以降に返すノートの数（最大100）。`include`が`["notes"]`の場合にのみ適用されます。 |

`diffs`ファセットは、変更統計（合計値とファイルごとの追加および削除）のみを返します。パッチテキストを取得するには、`get_merge_request_diffs`を使用します。

`conflicts`ファセットは、Git競合マーカーを含む生の競合ファイルコンテンツを返します。マージリクエストがマージできず、ソースブランチにプッシュできる場合にのみ利用可能で、マージ可能性がチェックされるまでは`null`です。ベースの`conflicts`フィールドを読んで状態を判断してください。

例: 

```plaintext
Get merge request 15 in project gitlab-org/gitlab with its commits
```

## `list_duo_agents_and_flows` {#list_duo_agents_and_flows}

{{< history >}}

- GitLab 19.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/617173)されました。

{{< /history >}}

プロジェクトで有効になっているGitLab Duoエージェントとフローを一覧表示し、フロー名を推測する代わりに何が利用可能かを発見できるようにします。プロジェクトが提供するエージェントとフローはプロジェクトごとに設定され、そのIDはプロジェクト間で異なります。

各エントリには`can_start_session`が含まれており、これは実行権限のあるフローに対してのみ`true`となります。エージェントと外部エージェントは発見のためにリストされますが、起動することはできません。また、実行できないフロー、未リリースまたはドラフト状態のバージョンを持つフローも起動不可としてリストされます。起動可能なエントリのみが`start_duo_session`が取る`ai_catalog_item_consumer_id`を持ちます。その他のすべてのエントリは`null`に設定されています。説明は切り詰められる場合があります。

このリストには、プロジェクトで設定されたエージェント、フロー、外部エージェントに加えて、基盤となるチャットエージェントが含まれます。チャットエージェントは固定リストであり、ページ分割されたプロジェクト結果の一部ではないため、最初のページでのみ返され、エージェントが含まれていない限り省略されます。これらは`first`に加えて提供されるため、最初のページには要求したよりも多くのエントリが含まれる場合があります。これらは`ai_catalog_item_consumer_id`の代わりに`workflow_definition`を持ち、これにより、表示名`GitLab Duo`を共有する2つのエージェントも区別されます。プロジェクトで設定されたエントリは`workflow_definition`が`null`に設定されています。

基盤となるチャットエージェントは、プロジェクトではなく、GitLab.com上のプロジェクトのトップレベルグループ、およびGitLab Self-Managed上の組織によって管理されます。

| パラメータ    | タイプ    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `project_id` | 文字列  | はい      | エージェントとフローをリストするプロジェクトの数値IDまたはフルパス。 |
| `item_type`  | 文字列  | いいえ       | `agent`、`flow`、または`third_party_flow`のエントリのみを返します。省略するとすべての種類が返されます。 |
| `after`      | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`      | 整数 | いいえ       | 順方向ページネーションで返すエージェントとフローの数。デフォルトは20、最大は100です。 |

呼び出しごとに結果の単一ページが返されます。さらにページが存在する場合、応答には`after`として渡すことができる`pageInfo.endCursor`が含まれます。

設定されているが非アクティブなアイテムはページ取得後に破棄されるため、`pageInfo.hasNextPage`がまだ`true`の間でも、ページには`first`よりも少ないエントリ、またはまったくエントリが含まれない場合があります。空のページで停止する代わりに、`hasNextPage`が`false`になるまでページングを続けてください。

例: 

```plaintext
Which Duo flows can I run in gitlab-org/gitlab?
```

## `start_duo_session` {#start_duo_session}

{{< history >}}

- GitLab 19.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/607619)されました。

{{< /history >}}

AIカタログからフローを実行するGitLab Duo Agent Platformセッションを開始し、セッションIDを返します。カタログフローのみがこの方法で開始できます。これは、これらのセッションのみが後で`send_duo_session_input`で応答できるためです。

セッションは、コミットをプッシュし、マージリクエストを開くことができるCIジョブで実行されます。応答には推奨されるポーリング遅延が含まれます。進行状況を追跡するには、返された`workflow_id`と共に`get_duo_session`を使用します。

| パラメータ                     | タイプ    | 必須 | 説明 |
|-------------------------------|---------|----------|-------------|
| `project_id`                  | 文字列  | はい      | フローが実行されるプロジェクトのIDまたはフルパス。 |
| `ai_catalog_item_consumer_id` | 整数 | はい      | 実行するフローを設定するAIカタログアイテムコンシューマのID。これを見つけるには`list_duo_agents_and_flows`を使用します。 |
| `goal`                        | 文字列  | はい      | エージェントが実行すべきこと。これがフローの開始点となるプロンプトです。 |

例: 

```plaintext
Run the Developer flow in project 42 to add tests for the parser
```

## `list_duo_sessions` {#list_duo_sessions}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248587)されました。
- GitLab 19.5で`statuses`パラメータを受け入れるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256101)されました。

{{< /history >}}

GitLab Duo Agent Platformのセッションをリスト表示します（Duo Chatセッションを除く）。各セッションには、個別のステータス、ゴールプレビュー、フロー定義、および作成日時が含まれます。プロジェクトセッションにはセッションURLも含まれます。ゴールプレビューは切り詰められている場合があります。

| パラメータ      | タイプ    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `url`          | 文字列  | いいえ       | GitLabのプロジェクトのURL。セッションをフィルタリングするために使用します。`project_id`と一緒に使用しないでください。 |
| `project_id`   | 文字列  | いいえ       | セッションをフィルタリングするプロジェクトの数値IDまたはフルパス。`url`と一緒に使用しないでください。 |
| `status_group` | 文字列  | いいえ       | セッションステータスグループ。`active`、`paused`、`awaiting_input`、`completed`、`failed`、`canceled`のいずれか。 |
| `statuses`     | 配列   | いいえ       | セッションのステータス。`created`、`running`、`paused`、`finished`、`failed`、`stopped`、`input_required`、`plan_approval_required`、または`tool_call_approval_required`のいずれか1つ以上。`status_group`と一緒に使用しないでください。 |
| `after`        | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`        | 整数 | いいえ       | 順方向ページネーションで返すセッションの数。デフォルトは20、最大は100です。 |

`status_group`フィルターは、複数の個別のステータスを持つセッションを返すことができます。代わりに`statuses`を使用して、1つ以上の正確なステータスでフィルタリングしてください。呼び出しごとに結果の単一ページが返されます。さらにページが存在する場合、応答には`after`として渡すことができる`pageInfo.endCursor`が含まれます。

例: 

```plaintext
List my active Duo Agent Platform sessions in gitlab-org/gitlab
```

## `get_duo_session` {#get_duo_session}

{{< history >}}

- GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/607634)されました。`get_duo_workflow_status`はエイリアスとしても受け入れられます。

{{< /history >}}

GitLab Duo Agent Platformセッションのステータスをチェックします。実行中のセッションには、推奨されるポーリング遅延が含まれます。完了したセッションと完了したチャットのやり取りには、最新のエージェントの回答が含まれます。承認を待っているセッションには、セッションを続行するための指示が含まれます。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `workflow_id` | 整数 | はい      | `trigger_duo_flow`または`ask_duo_agent`によって返されるワークフローID。 |

例: 

```plaintext
Check the status of Duo session 42
```

## `send_duo_session_input` {#send_duo_session_input}

{{< history >}}

- GitLab 19.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/617171)されました。

{{< /history >}}

入力を待っているGitLab Duo Agent Platformセッションに回答します。保留中のプランまたはツール呼び出しを承認または拒否するか、エージェントが尋ねた質問に返信します。セッションは、最後のCIジョブが完了すると入力を受け入れます。ステータスが`input_required`、`plan_approval_required`、または`tool_call_approval_required`のいずれであっても同様です。

セッションはCIジョブで継続されます。応答には推奨されるポーリング遅延が含まれます。進行状況を追跡するには、同じ`workflow_id`と共に`get_duo_session`を使用します。

| パラメータ        | タイプ    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `workflow_id`    | 整数 | はい      | `list_duo_sessions`または`get_duo_session`によって返されるDuoセッションのID。 |
| `human_approval` | ブール値 | はい      | `true`は保留中のプランまたはツール呼び出しを承認します。`true`と共に`human_message`を含めないでください。そうしないと、ツールはセッションを再開する代わりに呼び出しを拒否します。`false`はそれを拒否します: エージェントがあなたのフィードバックを元に続行するように`human_message`を含めてください。これがなければ、エージェントは続行しないように指示され、セッションは継続されます。 |
| `human_message`  | 文字列  | いいえ       | エージェントへのフィードバック、またはセッションが質問した際の回答（2000文字以内）。`human_approval=false`と共に提供してください。`human_approval=true`の場合、ツールはセッションを再開する代わりに呼び出しを拒否します。 |

例: 

```plaintext
Approve the plan for Duo session 42
```

```plaintext
Reject the plan for Duo session 42 and ask it to also add tests
```

## `list_merge_requests` {#list_merge_requests}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246413)されました。
- `group_id`パラメータとグループスコープがGitLab 19.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/work_items/606934)されました。

{{< /history >}}

GitLabプロジェクトまたはグループ内のマージリクエストをリストまたは検索し、コンパクトなマージリクエストのメタデータを返します。グループスコープには、常にグループとそのサブグループ内のすべてのプロジェクトからのマージリクエストが含まれますが、アーカイブされたプロジェクトからのマージリクエストは除外されます。グループの結果には、各マージリクエストの所有プロジェクトパスも含まれており、`get_merge_request`と共に使用できます。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | プロジェクトまたはグループのGitLab URL。`url`、`project_id`、または`group_id`のいずれか一方のみを指定してください。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`、`project_id`、または`group_id`のいずれか一方のみを指定してください。 |
| `group_id`          | 文字列  | いいえ       | グループのIDまたはフルパス。`url`、`project_id`、または`group_id`のいずれか一方のみを指定してください。 |
| `author_username`   | 文字列  | いいえ       | マージリクエストの作成者のユーザー名でフィルタリングします。 |
| `assignee_username` | 文字列  | いいえ       | 割り当てられたユーザーのユーザー名でフィルタリングします。 |
| `reviewer_username` | 文字列  | いいえ       | レビュアーのユーザー名でフィルタリングします。 |
| `state`             | 文字列  | いいえ       | 状態でフィルターします。`opened`、`closed`、`merged`、`locked`、`all`のいずれか。いずれかの状態を含めるには省略します。 |
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
| `id`                | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
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
| `id`                | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
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
| `id`                | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

例: 

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `get_merge_request_conflicts` {#get_merge_request_conflicts}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221941)されました。

{{< /history >}}

マージできないマージリクエストのマージコンフリクトコンテンツを取得します。競合するファイルに表示されるとおりのraw Git競合マーカー（`<<<<<<<`、`=======`、および`>>>>>>>`）を返します。各ファイルのコンテンツは`# File:`見出しの下にグループ化されます。名前変更されたファイルの場合、見出しには各ブランチ内のパスが表示されます。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `project_id`        | 文字列  | はい      | プロジェクトのIDまたはフルパス（例: `gitlab-org/gitlab`）。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

マージリクエストのソースブランチにプッシュする権限が必要です。このツールは、マージリクエストに競合がない場合、マージ可能性がまだチェックされていない場合、またはブランチや差分参照が欠落している場合にエラーを返します。

例: 

```plaintext
Show the conflicts for merge request 42 in project gitlab-org/gitlab
```

## `save_note` {#save_note}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241114)されました。
- GitLab 19.4で`create_merge_request_note`および`create_workitem_note`ツールを[置き換えました](https://gitlab.com/gitlab-org/gitlab/-/work_items/605848)。元のツール名は両方ともエイリアスとして引き続き機能します。

{{< /history >}}

認証済みユーザーとして、GitLabマージリクエストまたは作業アイテムにコメントを追加するか、既存のディスカッションスレッドに返信します。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `url`               | 文字列  | いいえ       | マージリクエストまたは作業アイテムのURL。URLがターゲットタイプを決定します。 |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはパス。`merge_request_iid`と共に、およびプロジェクトレベルの作業アイテムの場合は`work_item_iid`と共に必須です。 |
| `group_id`          | 文字列  | いいえ       | グループのIDまたはパス。グループレベルの作業アイテムの場合は`work_item_iid`と共に必須です。 |
| `merge_request_iid` | 整数 | いいえ       | マージリクエストの内部ID。`project_id`と共に提供してください。`work_item_iid`と相互に排他的です。 |
| `work_item_iid`     | 整数 | いいえ       | 作業アイテムの内部ID。`project_id`または`group_id`と共に提供してください。`merge_request_iid`と相互に排他的です。 |
| `body`              | 文字列  | はい      | ノートの内容。クイックアクションがトリガーされるのを避けるため、行の先頭に`/`を使用することはできません（例: `/merge`）。 |
| `internal`          | ブール値 | いいえ       | ノートを内部用としてマークします（レポーターロール以上のメンバーにのみ表示されます）。デフォルトは`false`です。 |
| `discussion_id`     | 文字列  | いいえ       | 返信先となるディスカッションのグローバルID（形式は`gid://gitlab/Discussion/<id>`）。指定されていない場合、新しいトップレベルのノートが作成されます。 |

例: 

- マージリクエストにコメント:

  ```plaintext
  Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
  ```

- 作業アイテムにコメント:

  ```plaintext
  Add a comment "This looks good to me" to work item 42 in project gitlab-org/gitlab
  ```

## `get_merge_request_notes` {#get_merge_request_notes}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/597494)されました。

{{< /history >}}

特定のGitLabマージリクエストのノート（コメントおよびシステムノート）を取得します。

| パラメータ           | タイプ    | 必須 | 説明                                                                                    |
|---------------------|---------|----------|--------------------------------------------------------------------------------------------------|
| `url`               | 文字列  | いいえ       | GitLabマージリクエストのURL。`project_id`および`merge_request_iid`が指定されていない場合は必須。   |
| `project_id`        | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が指定されていない場合は必須。                                  |
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

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/605881)ました。

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
| `approve`            | マージリクエストを承認します。すでに承認されている呼び出しは、ステータス`already_approved`で成功します。 |
| `unapprove`          | あなたの承認を削除します。事前の承認がない呼び出しは、ステータス`not_approved`で成功します。 |

`post_duo_review`、`approve`、および`unapprove`からの応答には、マージリクエストの現在の`diff_head_sha`が含まれているため、既存の承認またはレビューが最新のコミットをまだカバーしているかどうかを判断できます。

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
| `sha`               | 文字列  | いいえ       | `approve`の場合、ヘッドSHAガード。指定され、マージリクエストのヘッドと一致しなくなった場合、承認は拒否されます。`get_merge_request`によって返される完全な40文字の`diff_head_sha`を渡してください。 |

例: 

```plaintext
Review merge request 42 in project gitlab-org/gitlab and leave your findings as diff comments with a summary
```

## `list_project_members` {#list_project_members}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251379)ました。

{{< /history >}}

GitLabプロジェクトのメンバーをそのロールとアクセスレベルと共に一覧表示します。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `project_id`        | 文字列  | はい      | プロジェクトのフルパスまたは数値ID（例: `gitlab-org/gitlab`または`278964`）。 |
| `include_inherited` | ブール値 | いいえ       | 親グループまたはプロジェクトのサブグループからロールを継承するメンバーも返します。`false`がデフォルトです。 |
| `query`             | 文字列  | いいえ       | 名前またはユーザー名にこのテキストを含むメンバーのみを返します。 |
| `first`             | 整数 | いいえ       | 順方向ページネーションで返すメンバー数（デフォルト20、最大100）。 |
| `after`             | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |

各メンバーについて、応答はユーザーID、ユーザー名、名前、数値`access_level`、一致する`access_level_name`（例: `Maintainer`）、およびメンバーシップの`expires_at`日付を返します。メールで招待されたものの、まだ招待を承諾していないメンバーは返されません。

呼び出しごとに結果の単一ページが返されます。さらにページが存在する場合、応答の`metadata`には、次のページをフェッチするために`after`として渡すことができる`end_cursor`が含まれます。

例: 

```plaintext
Who are the maintainers of gitlab-org/gitlab?
```

## `get_user` {#get_user}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253176)ました。

{{< /history >}}

単一のGitLabユーザーを取得します。このツールを使用して、ユーザー名または自身のアカウントを数値ユーザーIDに解決します。たとえば、他のツールで担当者やレビュアーを設定する前に使用してください。

`username`、`id`、または`me`のいずれか一方のみを指定してください。

| パラメータ  | タイプ    | 必須 | 説明 |
|------------|---------|----------|-------------|
| `username` | 文字列  | いいえ       | 検索するユーザーのユーザー名。 |
| `id`       | 整数 | いいえ       | 検索するユーザーの数値ID。 |
| `me`       | ブール値 | いいえ       | 認証済みユーザーを検索するには`true`に設定します。提供されている場合、`true`である必要があります。`username`と`id`を省略します。 |

応答は、ユーザーの数値`id`、`username`、`name`、`state`、および`web_url`を返します。

例: 

```plaintext
What is my GitLab user ID?
```

## `accept_merge_request` {#accept_merge_request}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/617968)ました。

{{< /history >}}

マージリクエストをマージするか、自動的にマージするようスケジュールします。`strategy`がない場合、マージはすぐに開始され、非同期で完了します。`strategy`がある場合、自動マージが有効になり、マージリクエストはチェックが完了するとマージされます。代わりにマージリクエストを承認するには、`save_merge_request_review`ツールを使用します。

すでにマージされたマージリクエストに対する呼び出しは、ステータス`already_merged`で成功し、すでにスケジュールされているマージリクエストに対する`strategy`を伴う呼び出しは、ステータス`already_scheduled`で成功します。

| パラメータ                     | タイプ    | 必須 | 説明 |
|-------------------------------|---------|----------|-------------|
| `url`                         | 文字列  | いいえ       | GitLabのマージリクエストのURL。これ、または`project_id`と`merge_request_iid`を指定します。 |
| `project_id`                  | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`が指定されていない場合は必須。 |
| `merge_request_iid`           | 整数 | いいえ       | マージリクエストの内部ID。`url`が指定されていない場合は必須。 |
| `sha`                         | 文字列  | はい      | ヘッドSHAガード。それがマージリクエストのヘッドと一致しなくなった場合、マージは拒否されます。`get_merge_request`によって返される`diff_head_sha`を渡してください。 |
| `strategy`                    | 文字列  | いいえ       | 自動マージ戦略。例: `merge_when_checks_pass`。指定された場合、すぐにマージする代わりに自動マージを有効にします。 |
| `squash`                      | ブール値 | いいえ       | マージ時にコミットを単一のコミットにスカッシュします。 |
| `commit_message`              | 文字列  | いいえ       | カスタムGitLab Duoマージコミットメッセージ。 |
| `squash_commit_message`       | 文字列  | いいえ       | カスタムスカッシュコミットメッセージ。`squash`が`true`の場合に適用されます。 |
| `should_remove_source_branch` | ブール値 | いいえ       | マージ後にソースブランチを削除します。 |

例: 

```plaintext
Merge merge request 42 in project gitlab-org/gitlab once its checks pass, and remove the source branch
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

## `fork_repository` {#fork_repository}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/597680)ました。

{{< /history >}}

GitLabプロジェクトをネームスペースにフォークします。

フォークは非同期で作成されます。応答には、フォークの進行状況を示す`scheduled`のような`import_status`フィールドを含む、新しいプロジェクト属性が含まれます。

以下のステータスに基づく理由により、呼び出しは失敗します:

- ネームスペースにすでにプロジェクトのフォークがある場合の`409`ステータス。
- プロジェクトまたはネームスペースが存在しない場合、またはプロジェクトをフォークする権限がない場合の`404`ステータス。

| パラメータ        | タイプ    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `id`             | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `namespace_id`   | 整数 | いいえ       | プロジェクトをフォークするネームスペースのID。 |
| `namespace_path` | 文字列  | いいえ       | プロジェクトをフォークするネームスペースのパス。 |
| `name`           | 文字列  | いいえ       | フォークに割り当てる名前。 |
| `path`           | 文字列  | いいえ       | フォークに割り当てるパス。 |
| `description`    | 文字列  | いいえ       | フォークに割り当てる説明。 |
| `visibility`     | 文字列  | いいえ       | フォークの表示レベル。 |

例: 

```plaintext
Fork gitlab-org/gitlab-test into my personal namespace
```

## `list_branches` {#list_branches}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/605849)ました。

{{< /history >}}

GitLabプロジェクトのブランチを、オプションで名前によってフィルタリングして一覧表示します。

| パラメータ  | タイプ    | 必須 | 説明 |
|------------|---------|----------|-------------|
| `id`       | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `search`   | 文字列  | いいえ       | 名前でブランチをフィルタリングします。 |
| `page`     | 整数 | いいえ       | 現在のページ番号。デフォルトは`1`です。 |
| `per_page` | 整数 | いいえ       | 1ページあたりのアイテム数。デフォルトは`20`です。 |

例: 

```plaintext
List branches in gitlab-org/gitlab whose names contain "release"
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
| `project_id` | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が提供されない場合に必要です。`url`も提供されている場合、両方は同じプロジェクトを参照する必要があります。 |
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

## `list_repository_tree` {#list_repository_tree}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/605873)ました。

{{< /history >}}

指定されたパスと参照にあるGitLabリポジトリ内のファイルとディレクトリを一覧表示します。エントリのメタデータのみを返し、ファイルの内容は返しません。ファイルの内容を読み取るには、[`get_repository_file`](#get_repository_file)を使用します。

| パラメータ    | タイプ    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `url`        | 文字列  | いいえ       | GitLabのプロジェクトのURL。`url`または`project_id`のいずれか一方のみを指定してください。 |
| `project_id` | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`または`project_id`のいずれか一方のみを指定してください。 |
| `path`       | 文字列  | いいえ       | リポジトリルートからの相対パスで、リストするディレクトリのパス。デフォルトはルートです。 |
| `ref`        | 文字列  | いいえ       | ブランチ名、タグ名、またはコミットSHA。デフォルトはデフォルトブランチです。 |
| `recursive`  | ブール値 | いいえ       | すべてのサブディレクトリのエントリを再帰的に一覧表示します。デフォルトは`false`です。 |
| `after`      | 文字列  | いいえ       | 順方向ページネーションのカーソル。前の応答からの`endCursor`を使用します。 |

各呼び出しは最大100のエントリを返します。`pageInfo.hasNextPage`が`true`の場合、`pageInfo.endCursor`を`after`として渡して次のページをフェッチします。

例: 

```plaintext
List the files under app/services in gitlab-org/gitlab on the default branch
```

## `get_commit` {#get_commit}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/605874)されました。

{{< /history >}}

単一のコミットのメタデータ、およびオプションでその差分またはノートを取得する。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `url`         | 文字列  | いいえ       | GitLabのコミットのURL。`project_id`と`commit_sha`が提供されない場合に必要です。 |
| `project_id`  | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が提供されない場合に必要です。 |
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

## `list_commits` {#list_commits}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/605875)ました。

{{< /history >}}

GitLabプロジェクトのコミットを、オプションで参照、作成者、パス、または日付によってフィルタリングして一覧表示します。コンパクトなコミットメタデータを返します。単一のコミットの差分またはノートを取得するには、[`get_commit`](#get_commit)を使用します。

| パラメータ      | タイプ    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `url`          | 文字列  | いいえ       | GitLabのプロジェクトのURL。`url`または`project_id`のいずれか一方のみを指定してください。 |
| `project_id`   | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`または`project_id`のいずれか一方のみを指定してください。 |
| `ref_name`     | 文字列  | いいえ       | コミットをリストするブランチまたはタグ。デフォルトはデフォルトブランチです。 |
| `author`       | 文字列  | いいえ       | コミット作成者の名前またはメールでフィルタリングします。 |
| `path`         | 文字列  | いいえ       | このファイルパスに影響するコミットのみを返します。 |
| `since`        | 文字列  | いいえ       | このISO 8601形式の日付または時刻以降にコミットされたコミットのみを返します。 |
| `until`        | 文字列  | いいえ       | このISO 8601形式の日付または時刻より前にコミットされたコミットのみを返します。 |
| `order`        | 文字列  | いいえ       | 順序付け戦略。`topo`または`date`を指定できます。デフォルトは逆時系列順です。 |
| `first_parent` | ブール値 | いいえ       | マージコミットの最初の親のみをたどります。 |
| `with_stats`   | ブール値 | いいえ       | コミットごとの行数統計（追加、削除、変更されたファイル）を含みます。 |
| `after`        | 文字列  | いいえ       | 順方向ページネーションのカーソル。前の応答からの`endCursor`を使用します。 |
| `first`        | 整数 | いいえ       | 返すコミットの数。デフォルトは`20`、最大は`100`です。 |

`with_stats`が`true`の場合、各コミットはGitaly呼び出しコストがかかるため、`first`はデフォルトで`10`になり、`with_stats`が設定されている場合は`10`を超えてはなりません。

例: 

```plaintext
List commits to app/models in gitlab-org/gitlab since 2026-08-01 by Alex
```

## `list_releases` {#list_releases}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/618494)ました。

{{< /history >}}

GitLabプロジェクトのリリースを、最新リリースが最初になるように一覧表示します。

| パラメータ    | タイプ    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `url`        | 文字列  | いいえ       | GitLabのプロジェクトのURL。`project_id`が提供されない場合に必要です。 |
| `project_id` | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が提供されない場合に必要です。 |
| `page`       | 整数 | いいえ       | 取得するページ番号。デフォルトは`1`です。 |
| `per_page`   | 整数 | いいえ       | 1ページあたりに返すリリース数。デフォルトは`20`、最大は`100`です。 |
| `state`      | 文字列  | いいえ       | リリースステートでフィルタリング: `released`、`upcoming`、または`all`。デフォルトは`released`です。 |

`url`または`project_id`のいずれか一方のみを指定してください。

各エントリはリリースメタデータのみを返します: `tag_name`、`name`、`released_at`、`upcoming`、および`assets`。`assets`には、リリースの資産リンクの`count`と、そのうち最大5つの`links`が含まれます。リリースに5つを超えるものがある場合、`count`が実際の合計を報告します。ソースアーカイブはタグから派生可能であるため、除外されます。

応答には、`page`、`per_page`、および`has_more`を含む`metadata`オブジェクトも含まれます。次のページをリクエストするかどうかを決定するには`has_more`を使用します。

リリースノートは意図的にこの応答では返されません。

将来の`released_at`を持つリリースは公開ではなくスケジュールされたものであり、公開されたリリースよりも上位にソートされます。取得するものを制御するには`state`を使用します。スケジュールされたリリースには`upcoming`が`true`に設定されています。

リリースが構築されたコミットを読み取るには、その`tag_name`を`get_commit`ツールに渡します。資産をダウンロードするには、`assets.links`の`url`を使用します。

例: 

```plaintext
List the most recent releases for project gitlab-org/gitlab
```

## `list_tags` {#list_tags}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/618493)ました。

{{< /history >}}

GitLabプロジェクトのタグを、更新日時が新しい順に一覧表示します。`search`がタグ名に正確に一致する場合、GitLabはそのタグを最初にリストします。

| パラメータ    | タイプ    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `url`        | 文字列  | いいえ       | GitLabのプロジェクトのURL。`project_id`が提供されない場合に必要です。 |
| `project_id` | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が提供されない場合に必要です。 |
| `search`     | 文字列  | いいえ       | 名前でタグをフィルタリングします。先頭を固定する`^`、末尾を固定する`$`、およびワイルドカードとして`*`をサポートします。 |
| `first`      | 整数 | いいえ       | 返すタグの数。デフォルトは`20`、最大は`100`です。 |
| `after`      | 文字列  | いいえ       | 順方向ページネーションのカーソル。前の応答からの`metadata.end_cursor`を使用します。 |

`url`または`project_id`のいずれか一方のみを指定してください。

各エントリは`name`と`commit`を返します。ここで`commit`はタグの先端コミット`sha`と`title`を保持します。`commit`はコミット以外のものを指すタグの場合`null`です。

タグメッセージは意図的にこの応答では返されません。

応答には、`has_next_page`および`end_cursor`を含む`metadata`オブジェクトも含まれます。`has_next_page`が`true`の場合、`end_cursor`を`after`として渡して次のページをフェッチします。

タグが指す完全なコミットを読み取るには、`get_commit`ツールを使用します。

例: 

```plaintext
List the most recent tags for the gitlab-org/gitlab project
```

## `get_pipeline` {#get_pipeline}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605853)されました。
- `artifacts`ファセットがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/585022)されました。

{{< /history >}}

パイプライン、およびオプションでそのジョブ、ダウンストリームパイプライン、ブリッジ（トリガー）ジョブ、またはそのジョブが生成したアーティファクトを取得します。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `id`          | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `pipeline_id` | 整数 | はい      | パイプラインのID。 |
| `include`     | 配列   | いいえ       | パイプラインと共に含めるファセット（呼び出しごとに1つ）: `jobs`、`downstream_pipelines`、`bridge_jobs`、または`artifacts`。 |
| `job_status`  | 文字列  | いいえ       | `jobs`ファセットをステータスでフィルタリングします（例: `failed`）。`include`が`jobs`の場合にのみ適用されます。 |
| `first`       | 整数 | いいえ       | 選択された`include`ファセットに対して返すアイテムの数。`artifacts`ファセットの場合、これはアーティファクトが返されるジョブの数です。デフォルトは`20`、最大は`100`です。 |
| `after`       | 文字列  | いいえ       | 選択された`include`ファセットの順方向ページネーションのカーソル。前の応答からの`page_info.end_cursor`を使用します。 |

ブリッジジョブの`downstream_pipeline`は、トリガージョブがまだダウンストリームパイプラインをトリガーしていない場合と、そのパイプラインにアクセスできない場合の両方で省略されます（`null`）。

ダウンストリームパイプラインは別のプロジェクトに属する可能性があるため、各ダウンストリームパイプラインには`project_full_path`が含まれます。その値を後続の呼び出しの`id`として使用します。

`artifacts`ファセットは、アーティファクトのフラットなリストを返します。各アーティファクトは、その`name`、`size`、`file_type`、有効期限情報、およびそれを生成したジョブの`job_id`と`job_name`を運びます。ページネーションはパイプラインのジョブを対象とし、アーティファクトは対象としません。

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

- パイプラインが生成したアーティファクトを取得:

  ```plaintext
  List the artifacts of pipeline 12345 in project gitlab-org/gitlab
  ```

## `get_pipeline_jobs` {#get_pipeline_jobs}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)されました。

{{< /history >}}

特定のGitLab CI/CDパイプラインのジョブを取得します。ジョブをパイプラインの他のデータとともに単一の呼び出しで取得するには、代わりに`include: jobs`を指定して`get_pipeline`ツールを使用します。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `id`          | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
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
- `artifacts`ファセットがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/585022)されました。

{{< /history >}}

CI/CDジョブのメタデータ、およびオプションでそのトレース/ログまたは生成されたアーティファクトを取得します。

| パラメータ     | タイプ    | 必須 | 説明 |
|---------------|---------|----------|-------------|
| `id`          | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `job_id`      | 整数 | はい      | ジョブのID。 |
| `include`     | 配列   | いいえ       | ジョブと共に含めるファセット（呼び出しごとに1つ）: `log`または`artifacts`。 |
| `byte_offset` | 整数 | いいえ       | ジョブのログの読み取りを開始するバイトオフセット。`include`が`log`の場合にのみ適用されます。デフォルトは`0`です。 |
| `byte_limit`  | 整数 | いいえ       | ジョブのログで返すバイトの最大数。`include`が`log`の場合にのみ適用されます。デフォルトおよび最大値は`512000`です。 |

ログが`byte_limit`より長い場合、レスポンスは合計サイズを報告し、次のウィンドウで使用する`byte_offset`（オフセット）を通知します。

`artifacts`ファセットは、ジョブが生成したすべてのアーティファクトを、その`name`、`size`、`file_type`、および有効期限情報と共に一覧表示します。

例: 

- ジョブのメタデータを取得する:

  ```plaintext
  Get the status of job 88 in project gitlab-org/gitlab
  ```

- ジョブのログを取得する:

  ```plaintext
  Show me the log output for job 88 in project gitlab-org/gitlab
  ```

- ジョブのアーティファクトを取得:

  ```plaintext
  What artifacts did job 88 in project gitlab-org/gitlab produce?
  ```

## `get_artifact_file` {#get_artifact_file}

{{< history >}}

- GitLab 19.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/585022)されました。

{{< /history >}}

CI/CDジョブのアーティファクトアーカイブ内のファイルをテキストとして読み取ります。ジョブまたはパイプラインが何を生み出したかを発見するには、`get_job`または`get_pipeline`ツールを`include: artifacts`と共に使用します。

| パラメータ       | タイプ    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `url`           | 文字列  | いいえ       | ジョブのURL。これ、または`project_id`と`job_id`を指定します。 |
| `project_id`    | 文字列  | いいえ       | プロジェクトのIDまたはフルパス。`url`が提供されない場合に必要です。 |
| `job_id`        | 整数 | いいえ       | ジョブのID。`url`が提供されない場合に必要です。 |
| `artifact_path` | 文字列  | はい      | アーティファクトアーカイブ内のファイルのパス。例: `coverage/index.html`。 |
| `byte_offset`   | 整数 | いいえ       | ファイルを読み取る開始バイトオフセット。デフォルトは`0`です。 |
| `byte_limit`    | 整数 | いいえ       | 返すバイトの最大数。デフォルトおよび最大は`1048576`（1 MB）です。 |

このツールはアーカイブアーティファクトからのみ読み取ります。`junit`や`dotenv`アーティファクトのように個別のファイルとして保存されたレポートアーティファクトは、アーカイブの一部ではないため、このツールでは読み取れません。

ファイルが`byte_limit`より長い場合、応答は合計サイズを報告し、次のウィンドウに使用する`byte_offset`を通知します。バイナリファイルは返されません。エラーはファイル名、サイズ、タイプ、およびブラウザで表示する場所を示します。

例: 

- ジョブのアーティファクトからテストレポートを読み取る:

  ```plaintext
  Read coverage/index.html from the artifacts of job 88 in project gitlab-org/gitlab
  ```

- 失敗したエンドツーエンドテストを調査:

  ```plaintext
  Find the JUnit report in the artifacts of job 88 in gitlab-org/gitlab and summarize the failures
  ```

## `list_pipelines` {#list_pipelines}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/605854)されました。

{{< /history >}}

GitLabプロジェクト内のパイプラインを、オプションのフィルターでリスト表示します。

| パラメータ        | タイプ    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `id`             | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
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
- `update`アクションがGitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/619469)されました。

{{< /history >}}

GitLabプロジェクトでCI/CDパイプラインを実行、再試行、キャンセル、または名前変更します。パイプラインを削除するには、代わりに`manage_pipeline`ツールを使用します。パイプラインをリスト表示するには、代わりに`list_pipelines`ツールを使用します。

| パラメータ     | タイプ    | 必須    | 説明 |
|---------------|---------|-------------|-------------|
| `url`         | 文字列  | いいえ          | GitLabのプロジェクトのURL。パイプラインの作成にのみ使用されます。これ、または`project_id`を指定します。 |
| `project_id`  | 文字列  | いいえ          | プロジェクトのIDまたはフルパス。パイプラインの作成にのみ使用されます。これ、または`url`を指定します。 |
| `pipeline_id` | 整数 | いいえ          | ターゲットとする既存のパイプラインのID。設定されている場合、`action`が必要です。新しいパイプラインを作成するには省略します。 |
| `action`      | 文字列  | いいえ          | `pipeline_id`に対して実行するライフサイクルアクション: `retry`、`cancel`、または`update`。`pipeline_id`が設定されている場合、必須です。 |
| `ref`         | 文字列  | いいえ          | ブランチまたはタグ名。パイプラインを作成する際に必要です（`pipeline_id`が存在しない場合）。 |
| `name`        | 文字列  | いいえ          | 新しいパイプライン名。`action: "update"`に必須です。 |
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

- パイプラインの名前を変更:

  ```plaintext
  Rename pipeline 12345 to "Nightly security scan" in project gitlab-org/gitlab
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
| `id`          | 文字列  | はい         | プロジェクトのIDまたはフルパス。 |
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

## `get_work_item` {#get_work_item}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/605882)ました。

{{< /history >}}

タイプ、日付、担当者、ラベル、マイルストーン、および親を含む単一の作業アイテム（イシュー、エピック、タスク、インシデント、目標、または主な成果）を取得します。オプションで、そのノートまたはそれに関連するマージリクエストを含みます。作業アイテムタイプがサポートしないウィジェットは省略されます。

| パラメータ                       | タイプ    | 必須 | 説明 |
|---------------------------------|---------|----------|-------------|
| `url`                           | 文字列  | いいえ       | 作業アイテムのGitLab URL（`/-/work_items/`、`/-/issues/`、または`/-/epics/` URL）。これを、または`group_id`または`project_id`と共に`work_item_iid`を提供してください。 |
| `group_id`                      | 文字列  | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`                    | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `work_item_iid`                 | 整数 | いいえ       | 作業アイテムの内部ID。`url`が指定されていない場合は必須。 |
| `include`                       | 配列   | いいえ       | 返す関連データ。`notes`または`related_merge_requests`のいずれか1つ（呼び出しごとに1つのファセット）。最新のノートについては、`notes_first`または`notes_after`なしで`notes_last`を使用します。 |
| `notes_first`                   | 整数 | いいえ       | カーソル以降に返すノートの数（順方向ページネーション）。デフォルト100、最大100。 |
| `notes_after`                   | 文字列  | いいえ       | ノートの順方向ページネーションのカーソル。前の応答からの`pageInfo.endCursor`を使用します。 |
| `notes_last`                    | 整数 | いいえ       | カーソルより前に返すノートの数（逆方向ページネーション）。デフォルト100、最大100。 |
| `notes_before`                  | 文字列  | いいえ       | ノートの逆方向ページネーション用のカーソル。前の応答からの`pageInfo.startCursor`を使用します。 |
| `related_merge_requests_first`  | 整数 | いいえ       | 関連するマージリクエストの数。デフォルト20、最大100。 |
| `related_merge_requests_after`  | 文字列  | いいえ       | 関連するマージリクエストの順方向ページネーション用のカーソル。 |
| `mr_page_size`                  | 整数 | いいえ       | 非推奨: 代わりに`related_merge_requests_first`を使用してください。 |
| `mr_pagination_cursor`          | 文字列  | いいえ       | 非推奨: 代わりに`related_merge_requests_after`を使用してください。 |

`notes`ファセットは、呼び出しごとに最大100個のノートを返し、`notes_*`パラメータを使用して両方向にページネーションします。グループレベルの作業アイテム（エピックなど）の場合、`related_merge_requests`ファセットは空です。

例: 

```plaintext
Get issue 42 in project gitlab-org/gitlab with its related merge requests
```

## `get_workitem_notes` {#get_workitem_notes}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581892)されました。
- GitLab 19.4で[非掲載](https://gitlab.com/gitlab-org/gitlab/-/work_items/625128)。[`get_work_item`](#get_work_item)の`notes`ファセットに置き換えられました。

{{< /history >}}

両方向にノートをページ分割する`include: ["notes"]`を持つ[`get_work_item`](#get_work_item)に置き換えられました。このツールは`tools/list`には表示されなくなりましたが、呼び出し元が移行する間は呼び出し可能です。

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
- `work_items_ids`のプレーンなIIDがGitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254551)されました。

{{< /history >}}

関係タイプを指定して、作業アイテムを1つ以上の他の作業アイテムにリンクします。

| パラメータ        | タイプ             | 必須 | 説明 |
|------------------|------------------|----------|-------------|
| `work_items_ids` | 配列            | はい      | リンクする作業アイテム: ソースと同じプロジェクトまたはグループで解決されるプレーンなIID、または他のプロジェクトやグループ内の作業アイテムのグローバルID（`gid://gitlab/WorkItem/<id>`）。最大10アイテム。 |
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

## `list_vulnerabilities` {#list_vulnerabilities}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251243)ました。

{{< /history >}}

GitLabプロジェクト内のセキュリティ脆弱性を、オプションのフィルターとカーソルページネーションで一覧表示します。ページ分割された脆弱性メタデータを返します。単一の脆弱性の詳細を取得するには、[`get_vulnerability`](#get_vulnerability)を使用します。

セキュリティダッシュボード機能を有効にする必要があります。

| パラメータ            | タイプ             | 必須 | 説明 |
|----------------------|------------------|----------|-------------|
| `project_full_path`  | 文字列           | はい      | プロジェクトのフルパス（例: `namespace/project`または`group/subgroup/project`）。 |
| `severity`           | 文字列の配列 | いいえ       | 重大度レベルでフィルタリングします。任意の重大度の脆弱性を含めるには省略します。`CRITICAL`、`HIGH`、`MEDIUM`、`LOW`、`INFO`、または`UNKNOWN`のいずれか1つ以上。 |
| `report_type`        | 文字列の配列 | いいえ       | セキュリティレポートタイプでフィルタリングします。すべてのレポートタイプを含めるには省略します。たとえば、`SAST`、`DAST`、`DEPENDENCY_SCANNING`などです。 |
| `state`              | 文字列の配列 | いいえ       | 脆弱性ステートでフィルタリングします。任意のステートの脆弱性を含めるには省略します。`CONFIRMED`、`DETECTED`、`DISMISSED`、または`RESOLVED`のいずれか1つ以上。 |
| `first`              | 整数          | いいえ       | 順方向ページネーションで返す脆弱性の数。デフォルトは`20`、最大は`100`です。 |
| `after`              | 文字列           | いいえ       | 順方向ページネーションのカーソル。前の応答からの`pageInfo.endCursor`を使用します。 |

例: 

```plaintext
List critical and high severity vulnerabilities in project gitlab-org/gitlab
```

## `get_vulnerability` {#get_vulnerability}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251243)ました。

{{< /history >}}

単一の脆弱性に関する詳細情報（タイトル、ステート、説明、重大度、および識別子を含む）を返します。

| パラメータ          | タイプ   | 必須 | 説明 |
|--------------------|--------|----------|-------------|
| `vulnerability_id` | 文字列 | はい      | 脆弱性の数値ID（例: `567`）。 |

例: 

```plaintext
Get full details for vulnerability 567
```

## `save_vulnerability` {#save_vulnerability}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/613026)ました。

{{< /history >}}

GitLabプロジェクトの脆弱性に対して書き込み操作を実行します。

| パラメータ            | タイプ   | 必須 | 説明 |
|----------------------|--------|----------|-------------|
| `action`             | 文字列 | はい      | 実行する操作。`dismiss`、`confirm`、`revert_to_detected`、`update_severity`、`create_issue`のいずれか。 |
| `vulnerability_id`   | 文字列 | はい      | 脆弱性の数値ID（例: `567`）。 |
| `comment`            | 文字列 | いいえ       | アクションの説明。`action`が`update_severity`の場合に必須です。 |
| `dismissal_reason`   | 文字列 | いいえ       | 無視する理由。`ACCEPTABLE_RISK`、`FALSE_POSITIVE`、`MITIGATING_CONTROL`、`USED_IN_TESTS`、`NOT_APPLICABLE`のいずれか。`action`が`dismiss`の場合にのみ使用してください。 |
| `severity`           | 文字列 | いいえ       | 新しい重大度レベル。`INFO`、`UNKNOWN`、`LOW`、`MEDIUM`、`HIGH`、`CRITICAL`のいずれか。`action`が`update_severity`の場合に必須です。 |
| `project_full_path`  | 文字列 | いいえ       | プロジェクトのフルパス（例: `namespace/project`）。`action`が`create_issue`の場合に必須です。 |

例: 

- 脆弱性を無視する:

  ```plaintext
  Dismiss vulnerability 123 with reason FALSE_POSITIVE
  ```

- 脆弱性を確認する:

  ```plaintext
  Mark vulnerability 456 as confirmed
  ```

- 検出された状態に戻す:

  ```plaintext
  Revert vulnerability 789 back to detected state
  ```

- 重大度を更新:

  ```plaintext
  Change severity of vulnerability 321 to CRITICAL with comment "Reassessed based on new intel"
  ```

- イシューを作成:

  ```plaintext
  Create an issue for vulnerability 654 in project gitlab-org/gitlab
  ```

## `save_work_item` {#save_work_item}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/605852)ました。
- `labels`、`add_labels`、`remove_labels`、`milestone_id`、および`milestone`パラメータがGitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/622711)されました。

{{< /history >}}

GitLab作業アイテム（イシュー、タスク、エピックなど）を作成または更新します。新しい作業アイテムを作成するには`work_item_iid`を省略します。既存の作業アイテムを更新するには、`work_item_iid`または作業アイテムのURLを指定します。設定する意図のあるフィールドのみを送信し、残りは省略してください。ツール名`create_work_item`と`update_work_item`は、このツールのエイリアスです。

| パラメータ          | タイプ              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `url`              | 文字列            | いいえ       | プロジェクト、グループ、または作業アイテムのGitLab URL。`url`、`project_id`、または`group_id`のいずれか一方のみを指定してください。 |
| `group_id`         | 文字列            | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`       | 文字列            | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `work_item_iid`    | 整数           | いいえ       | 更新する作業アイテムの正の内部ID。新しい作業アイテムを作成するには省略します。 |
| `title`            | 文字列            | いいえ       | 作業アイテムのタイトル。作業アイテムを作成する際に必要です。 |
| `type_name`        | 文字列            | いいえ       | 作業アイテムのタイプ名。`Issue`、`Task`、または`Epic`など。作業アイテムを作成する際に必要です。有効なタイプは、ネームスペースとライセンスによって異なります。 |
| `description`      | 文字列            | いいえ       | GitLab Flavored Markdownでの説明。最大1,048,576文字。 |
| `assignee_ids`     | 整数の配列 | いいえ       | 作業アイテムに割り当てるユーザーID。最大100アイテム。 |
| `label_ids`        | 文字列の配列  | いいえ       | ラベルIDまたはグローバルID。作成のみ。更新時には`add_label_ids`または`remove_label_ids`を使用します。最大100アイテム。 |
| `labels`           | 文字列の配列  | いいえ       | プロジェクトまたはグループとその祖先グループで解決される、設定するラベルの名前。作成のみ。更新時には`add_labels`または`remove_labels`を使用します。最大100アイテム。 |
| `add_label_ids`    | 文字列の配列  | いいえ       | 更新のみ。追加するラベルIDまたはグローバルID。最大100アイテム。 |
| `add_labels`       | 文字列の配列  | いいえ       | 更新のみ。追加するラベルの名前。最大100アイテム。 |
| `remove_label_ids` | 文字列の配列  | いいえ       | 更新のみ。削除するラベルIDまたはグローバルID。最大100アイテム。 |
| `remove_labels`    | 文字列の配列  | いいえ       | 更新のみ。削除するラベルの名前。最大100アイテム。 |
| `milestone_id`     | 文字列            | いいえ       | プロジェクトまたはグループとその祖先グループに対して検証される、割り当てるマイルストーンのIDまたはグローバルID。両方が指定された場合、`milestone`よりも優先されます。 |
| `milestone`        | 文字列            | いいえ       | プロジェクトまたはグループとその祖先グループのマイルストーンの中から解決される、割り当てるマイルストーンのタイトル。 |
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
| `readiness_score`  | 整数           | いいえ       | エージェントプランの準備スコア（0～100）。Ultimateのみです。`workplan_score`機能フラグが必要です。フラグが無効な場合、エラーを返します。 |

例: 

```plaintext
Create a task "Update the onboarding guide" in project gitlab-org/gitlab and assign it to me
```

## `list_work_items` {#list_work_items}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/605850)ました。

{{< /history >}}

グループまたはプロジェクト内の作業アイテム（イシュー、インシデント、テストケース、要件、タスク、チケット、目標、主な成果、エピック）をリストまたは検索します。グループスコープには、子孫プロジェクトおよびサブグループの作業アイテムが含まれます。各結果には、ID、IID、タイトル、ステート、ウェブURL、完全な参照、作成および更新タイムスタンプ、および作業アイテムタイプのみが含まれ、カーソルページネーションが適用されます。1つの作業アイテムを詳細に読み取るには`get_work_item`を使用します。

| パラメータ               | タイプ    | 必須 | 説明 |
|-------------------------|---------|----------|-------------|
| `url`                   | 文字列  | いいえ       | プロジェクトまたはグループのGitLab URL。`url`、`group_id`、または`project_id`のいずれか一方のみを指定してください。 |
| `group_id`              | 文字列  | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id`            | 文字列  | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |
| `state`                 | 文字列  | いいえ       | ステートでフィルタリング: `opened`、`closed`、または`all`（デフォルト）。 |
| `search`                | 文字列  | いいえ       | タイトルと説明のフリーテキスト検索。 |
| `author_username`       | 文字列  | いいえ       | 作成者のユーザー名。 |
| `assignee_usernames`    | 配列   | いいえ       | 担当者のユーザー名。作業アイテムはこれらすべてに一致する必要があります。最大100個の値。 |
| `label_name`            | 配列   | いいえ       | ラベル名。作業アイテムはこれらすべてを持っている必要があります。最大100個の値。 |
| `milestone_title`       | 配列   | いいえ       | マイルストーンのタイトル。`milestone_wildcard_id`と組み合わせることはできません。最大100個の値。 |
| `milestone_wildcard_id` | 文字列  | いいえ       | `NONE`、`ANY`、`STARTED`、または`UPCOMING`。`milestone_title`と組み合わせることはできません。 |
| `types`                 | 配列   | いいえ       | 含める作業アイテムタイプ。例: `["ISSUE", "TASK"]`。 |
| `created_after`         | 文字列  | いいえ       | この時刻以降に作成（ISO 8601; 日付のみの場合は日初めを意味し、オフセットを考慮）。 |
| `created_before`        | 文字列  | いいえ       | この時刻より前に作成（ISO 8601; 日付のみの場合は日初めを意味し、オフセットを考慮）。 |
| `updated_after`         | 文字列  | いいえ       | この時刻以降に更新（ISO 8601; 日付のみの場合は日初めを意味し、オフセットを考慮）。 |
| `updated_before`        | 文字列  | いいえ       | この時刻より前に更新（ISO 8601; 日付のみの場合は日初めを意味し、オフセットを考慮）。 |
| `due_after`             | 文字列  | いいえ       | この時刻以降が期日（ISO 8601; 日付のみの場合は日初めを意味し、オフセットを考慮）。 |
| `due_before`            | 文字列  | いいえ       | この時刻より前が期日（ISO 8601; 日付のみの場合は日初めを意味し、オフセットを考慮）。 |
| `sort`                  | 文字列  | いいえ       | ソート順。例: `UPDATED_DESC`。デフォルトは`CREATED_DESC`です。 |
| `first`                 | 整数 | いいえ       | 返される作業アイテムの数。デフォルト20、最大100。 |
| `after`                 | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `health_status_filter`  | 文字列  | いいえ       | Ultimateのみ。`onTrack`、`needsAttention`、または`atRisk`。 |
| `status`                | オブジェクト  | いいえ       | Ultimateのみです。カスタムステータス名でフィルタリング。例: `{"name": "In progress"}`。 |

例: 

```plaintext
List my open tasks in the gitlab-org group updated this month.
```

## `get_work_item_types` {#get_work_item_types}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237071)されました。

{{< /history >}}

ネームスペース（グループまたはプロジェクト）で利用可能な作業アイテムタイプ（イシュー、エピック、タスクなどのシステム定義タイプおよびカスタムタイプを含む）を一覧表示します。返される各タイプには、そのグローバルID、名前、アイコン、および有効になっているウィジェットタイプが含まれるため、タイプがサポートしないフィールドを設定することを回避できます。

| パラメータ    | タイプ   | 必須 | 説明 |
|--------------|--------|----------|-------------|
| `url`        | 文字列 | いいえ       | ネームスペース（プロジェクトまたはグループ）のGitLab URL。`group_id`および`project_id`が指定されていない場合は必須。 |
| `group_id`   | 文字列 | いいえ       | グループのIDまたはパス。`url`および`project_id`が指定されていない場合は必須。 |
| `project_id` | 文字列 | いいえ       | プロジェクトのIDまたはパス。`url`および`group_id`が指定されていない場合は必須。 |

例: 

```plaintext
List the work item types available in the gitlab-org group
```

## `list_projects` {#list_projects}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250301)ました。

{{< /history >}}

`group_id`がない場合、デフォルトでゲストロール以上の権限を持つプロジェクトを一覧表示します。`min_access_level`を渡してしきい値を上げることができます。`group_id`がある場合、そのグループとそのサブグループ内のすべてのプロジェクトをアクセスレベルに関係なく一覧表示します。`min_access_level`または`visibility`を追加すると、サブグループのトラバーサルとこれらのフィルターをグループのプロジェクトリストと組み合わせることがGitLabでサポートされていないため、そのグループのみにリストが絞り込まれます。

| パラメータ          | タイプ    | 必須 | 説明 |
|--------------------|---------|----------|-------------|
| `group_id`         | 文字列  | いいえ       | グループのIDまたはフルパス。インスタンス全体をリストするには省略します。デフォルトでは、ゲストロール以上の権限を持つプロジェクトが対象となります。 |
| `min_access_level` | 文字列  | いいえ       | プロジェクトが含まれるために必要な最小アクセスレベル。`guest`、`planner`、`reporter`、`developer`、`maintainer`、`owner`のいずれか。 |
| `search`           | 文字列  | いいえ       | 名前、パス、または説明でプロジェクトを検索します。 |
| `visibility`       | 文字列  | いいえ       | 表示レベルでフィルタリング: `public`、`internal`、または`private`。 |
| `archived`         | 文字列  | いいえ       | アーカイブ状態でフィルタリング: `only`、`include`、または`exclude`（デフォルト）。 |
| `after`            | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`            | 整数 | いいえ       | 順方向ページネーションで返すプロジェクト数。デフォルトは20、最大は100です。 |

`group_id`を提供すると、応答には`subgroupsIncluded`が含まれます: リストがグループのサブグループをカバーする場合は`true`、`min_access_level`または`visibility`がリストをそのグループのみに絞り込んだ場合は`false`。

例: 

```plaintext
List my projects
```

## `list_groups` {#list_groups}

{{< history >}}

- GitLab 19.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/work_items/607719)ました。

{{< /history >}}

グループを一覧表示し、グループ階層をナビゲートし、他のツールで使用するグループIDとフルパスを発見できるようにします。`group_id`がない場合、このツールはあなたがメンバーであるトップレベルグループを一覧表示します。`group_id`がある場合、メンバーシップに関係なく、そのグループの直接のサブグループを一覧表示します。すべての子孫サブグループを再帰的に探すには、`include_subgroups`を`true`に設定します。`group_id`がない場合、あらゆる深さであなたのグループを一覧表示します。アーカイブされたグループおよび削除保留中のグループは除外されます。

| パラメータ           | タイプ    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `group_id`         | 文字列  | いいえ       | サブグループをリストする親グループのIDまたはフルパス。あなたがメンバーであるトップレベルグループをリストするには省略します。 |
| `search`            | 文字列  | いいえ       | 名前またはフルパスでグループを検索します。 |
| `visibility`        | 文字列  | いいえ       | 表示レベルでフィルタリング: `public`、`internal`、または`private`。 |
| `include_subgroups` | ブール値 | いいえ       | 直接の子のみではなく、すべての子孫サブグループを再帰的に含めます。 |
| `after`             | 文字列  | いいえ       | 順方向ページネーションのカーソル。 |
| `first`             | 整数 | いいえ       | 順方向ページネーションで返すグループの数。デフォルトは20、最大は100です。 |

例: 

```plaintext
List the subgroups of gitlab-org
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
| `group_id`     | 文字列           | いいえ       | 検索したいグループのIDまたはフルパス。 |
| `project_id`   | 文字列           | いいえ       | 検索したいプロジェクトのIDまたはフルパス。 |
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

## `semantic_search` {#semantic_search}

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
- GitLab 19.4で`semantic_code_search`から[名称変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/606755)されました。`semantic_code_search`はエイリアスとして引き続き機能します。
- `scope`パラメータがGitLab 19.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/work_items/606755)されました。
- `semantic_query`パラメータがGitLab 19.4で`q`に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/606755)されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

キーワードではなく意味によってGitLabプロジェクト内の関連コンテンツを検索します。正確なシンボル名やファイル名がわからない場合、またはコードベース全体で動作がどのように実装されているかを発見するために、このツールを使用してください。セットアップおよびイネーブルメントを含む詳細については、[セマンティックコード検索](../gitlab_duo/semantic_code_search.md)を参照してください。

| パラメータ        | タイプ    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `scope`          | 文字列  | はい      | 検索するコンテンツのタイプ。`code`のみがサポートされています。 |
| `q`              | 文字列  | はい      | 自然言語検索クエリ。 |
| `project_id`     | 文字列  | はい      | プロジェクトのIDまたはフルパス。 |
| `directory_path` | 文字列  | いいえ       | 検索をこのディレクトリパス（例: `app/services/`）下のファイルに制限します。先頭のスラッシュや`..`セグメントを含まない相対パスである必要があります。`scope`が`code`の場合にのみ適用されます。 |
| `knn`            | 整数 | いいえ       | 内部的に取得される最近傍の数。デフォルトは`64`、最大は`100`です。値が高いほど、レイテンシーを犠牲にしてリコールが向上します。`scope`が`code`の場合にのみ適用されます。 |
| `limit`          | 整数 | いいえ       | 返す結果の最大数。デフォルトは`20`、最大は`100`です。`scope`が`code`の場合にのみ適用されます。 |

結果はファイル単位でグループ化されます。各ファイルには、コンテンツと関連性スコアを持つマージされた行範囲が含まれます。最良の結果を得るには、一般的なキーワードや特定の関数名または変数名を使用するのではなく、関心のある機能または動作について記述してください。

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
