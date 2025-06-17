---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ノートAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ノートAPIは、GitLabコンテンツにアタッチされたコメントとシステムレコードを管理します。ノートAPIの機能は次のとおりです。

- イシュー、マージリクエスト、エピック、スニペット、コミットに関するコメントを作成したり、変更したりします。
- オブジェクトの変更に関する[システム生成ノート](../user/project/system_notes.md)を取得します。
- ソートとページネーションのオプションを提供します。
- 非公開フラグと内部フラグにより可視性を制御します。
- 不正利用を防ぐために、レート制限をサポートします。

一部のシステム生成ノートは、個別のリソースイベントとして追跡されます。

- [リソースラベルイベント](resource_label_events.md)
- [リソース状態イベント](resource_state_events.md)
- [リソースマイルストーンイベント](resource_milestone_events.md)
- [リソースウェイトイベント](resource_weight_events.md)
- [リソースイテレーションイベント](resource_iteration_events.md)

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

## リソースイベント

一部のシステムノートはこのAPIの一部ではありませんが、個別のイベントとして記録されます。

- [リソースラベルイベント](resource_label_events.md)
- [リソース状態イベント](resource_state_events.md)
- [リソースマイルストーンイベント](resource_milestone_events.md)
- [リソースウェイトイベント](resource_weight_events.md)
- [リソースイテレーションイベント](resource_iteration_events.md)

## ノートのページネーション

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

## レート制限

不正利用を防ぐため、ユーザーに対して、1分あたりの`Create`リクエストを特定の数に制限できます。[ノートのレート制限](../administration/settings/rate_limit_on_notes_creation.md)を参照してください。

## イシュー

### プロジェクトイシューノートをリストする

単一のイシューの全ノートのリストを取得します。

```plaintext
GET /projects/:id/issues/:issue_iid/notes
GET /projects/:id/issues/:issue_iid/notes?sort=asc&order_by=updated_at
```

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid` | 整数           | はい      | イシューのIID |
| `sort`      | 文字列            | いいえ       | `asc`または`desc`の順序でソートされたイシューノートを返します。デフォルトは`desc`です |
| `order_by`  | 文字列            | いいえ       | `created_at`フィールドまたは`updated_at`フィールドで順序付けられたイシューノートを返します。デフォルトは`created_at`です |

```json
[
  {
    "id": 302,
    "body": "closed",
    "attachment": null,
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:22:45Z",
    "updated_at": "2013-10-02T10:22:45Z",
    "system": true,
    "noteable_id": 377,
    "noteable_type": "Issue",
    "project_id": 5,
    "noteable_iid": 377,
    "resolvable": false,
    "confidential": false,
    "internal": false,
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 305,
    "body": "Text of the comment\r\n",
    "attachment": null,
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:56:03Z",
    "updated_at": "2013-10-02T09:56:03Z",
    "system": true,
    "noteable_id": 121,
    "noteable_type": "Issue",
    "project_id": 5,
    "noteable_iid": 121,
    "resolvable": false,
    "confidential": true,
    "internal": true,
    "imported": false,
    "imported_from": "none"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes"
```

### 単一のイシューノートを取得する

特定のプロジェクトイシューの単一のノートを返します

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id
```

パラメーター:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid` | 整数           | はい      | プロジェクトイシューのIID |
| `note_id`   | 整数           | はい      | イシューノートのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/1"
```

### 新しいイシューノートを作成する

単一のプロジェクトイシューに新しいノートを作成します。

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

パラメーター:

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`    | 整数           | はい      | イシューのIID。 |
| `body`         | 文字列            | はい      | ノートのコンテンツ。1,000,000文字に制限されています。 |
| `confidential` | ブール値           | いいえ       | **非推奨:**GitLab 16.0で削除され、`internal`に名称変更される予定です。ノートの非公開フラグ。デフォルトはfalseです。 |
| `internal`     | ブール値           | いいえ       | ノートの内部フラグ。両方のパラメーターが送信された場合、`confidential`を上書きします。デフォルトはfalseです。 |
| `created_at`   | 文字列            | いいえ       | 日時文字列（ISO 8601形式）。1970-01-01以降である必要があります。例: `2016-03-11T03:45:40Z`（管理者権限またはプロジェクト/グループオーナー権限が必要です） |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note"
```

### 既存のイシューノートを変更する

イシューの既存のノートを変更します。

```plaintext
PUT /projects/:id/issues/:issue_iid/notes/:note_id
```

パラメーター:

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`    | 整数           | はい      | イシューのIID。 |
| `note_id`      | 整数           | はい      | ノートのID。 |
| `body`         | 文字列            | いいえ       | ノートのコンテンツ。1,000,000文字に制限されています。 |
| `confidential` | ブール値           | いいえ       | **非推奨:**GitLab 16.0で削除される予定です。ノートの非公開フラグ。デフォルトはfalseです。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636?body=note"
```

### イシューノートを削除する

イシューの既存のノートを削除します。

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id
```

パラメーター:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid` | 整数           | はい      | イシューのIID |
| `note_id`   | 整数           | はい      | ノートのID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636"
```

## スニペット

スニペットノートAPIは、プロジェクトレベルのスニペットを対象としており、パーソナルスニペットを対象としていません。

### すべてのスニペットノートをリストする

単一のスニペットの全ノートのリストを取得します。スニペットノートは、ユーザーがスニペットに投稿できるコメントです。

```plaintext
GET /projects/:id/snippets/:snippet_id/notes
GET /projects/:id/snippets/:snippet_id/notes?sort=asc&order_by=updated_at
```

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `snippet_id` | 整数           | はい      | プロジェクトスニペットのID |
| `sort`       | 文字列            | いいえ       | `asc`または`desc`の順序でソートされたスニペットノートを返します。デフォルトは`desc`です |
| `order_by`   | 文字列            | いいえ       | `created_at`フィールドまたは`updated_at`フィールドで順序付けられたスニペットノートを返します。デフォルトは`created_at`です |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes"
```

### 単一のスニペットノートを取得する

指定されたスニペットの単一のノートを返します。

```plaintext
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

パラメーター:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `snippet_id` | 整数           | はい      | プロジェクトスニペットのID |
| `note_id`    | 整数           | はい      | スニペットノートのID |

```json
{
  "id": 302,
  "body": "closed",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T09:22:45Z",
  "updated_at": "2013-10-02T10:22:45Z",
  "system": true,
  "noteable_id": 377,
  "noteable_type": "Issue",
  "project_id": 5,
  "noteable_iid": 377,
  "resolvable": false,
  "confidential": false,
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/11"
```

### 新しいスニペットノートを作成する

単一のスニペットの新しいノートを作成します。スニペットノートは、スニペットに対するユーザーコメントです。本文に絵文字リアクションのみが含まれるノートを作成すると、GitLabはこのオブジェクトを返します。

```plaintext
POST /projects/:id/snippets/:snippet_id/notes
```

パラメーター:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `snippet_id` | 整数           | はい      | スニペットのID |
| `body`       | 文字列            | はい      | ノートのコンテンツ。1,000,000文字に制限されています。 |
| `created_at` | 文字列            | いいえ       | 日時文字列（ISO 8601形式）。例: `2016-03-11T03:45:40Z`（管理者権限またはプロジェクト/グループオーナー権限が必要です） |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note"
```

### 既存のスニペットノートを変更する

スニペットの既存のノートを変更します。

```plaintext
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

パラメーター:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `snippet_id` | 整数           | はい      | スニペットのID |
| `note_id`    | 整数           | はい      | スニペットノートのID |
| `body`       | 文字列            | はい      | ノートのコンテンツ。1,000,000文字に制限されています。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/1659?body=note"
```

### スニペットノートを削除する

スニペットの既存のノートを削除します。

```plaintext
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

パラメーター:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `snippet_id` | 整数           | はい      | スニペットのID |
| `note_id`    | 整数           | はい      | ノートのID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/52/notes/1659"
```

## マージリクエスト

### すべてのマージリクエストノートをリストする

単一のマージリクエストの全ノートのリストを取得します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes
GET /projects/:id/merge_requests/:merge_request_iid/notes?sort=asc&order_by=updated_at
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID |
| `sort`              | 文字列            | いいえ       | `asc`または`desc`の順序でソートされたマージリクエストノートを返します。デフォルトは`desc`です |
| `order_by`          | 文字列            | いいえ       | `created_at`フィールドまたは`updated_at`フィールドで順序付けられたマージリクエストノートを返します。デフォルトは`created_at`です |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes"
```

### 単一のマージリクエストノートを取得する

指定されたマージリクエストの単一のノートを返します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

パラメーター:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID |
| `note_id`           | 整数           | はい      | マージリクエストノートのID |

```json
{
  "id": 301,
  "body": "Comment for MR",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T08:57:14Z",
  "updated_at": "2013-10-02T08:57:14Z",
  "system": false,
  "noteable_id": 2,
  "noteable_type": "MergeRequest",
  "project_id": 5,
  "noteable_iid": 2,
  "resolvable": false,
  "confidential": false,
  "internal": false
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1"
```

### 新しいマージリクエストノートを作成する

単一のマージリクエストの新しいノートを作成します。ノートは、マージリクエスト内の特定の行にアタッチされません。よりきめ細かい制御を行うための他の方法については、コミットAPIの[コメントをコミットに投稿する](commits.md#post-comment-to-commit)とディスカッションAPIの [マージリクエスト差分に新しいスレッドを作成する](discussions.md#create-a-new-thread-in-the-merge-request-diff)を参照してください。

本文に絵文字リアクションのみが含まれるノートを作成すると、GitLabはこのオブジェクトを返します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

パラメーター:

| 属性                     | 型              | 必須 | 説明 |
|-------------------------------|-------------------|----------|-------------|
| `body`                        | 文字列            | はい      | ノートのコンテンツ。1,000,000文字に制限されています。 |
| `id`                          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | 整数           | はい      | プロジェクトマージリクエストのIID |
| `created_at`                  | 文字列            | いいえ       | 日時文字列（ISO 8601形式）。例: `2016-03-11T03:45:40Z`（管理者権限またはプロジェクト/グループオーナー権限が必要です） |
| `internal`                    | ブール値           | いいえ       | ノートの内部フラグ。デフォルトはfalseです。 |
| `merge_request_diff_head_sha` | 文字列            | いいえ       | `/merge`[クイックアクション](../user/project/quick_actions.md)に必要です。ヘッドコミットのSHA。APIリクエストの送信後にマージリクエストが更新されないようにします。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes?body=note"
```

### 既存のマージリクエストノートを変更する

マージリクエストの既存のノートを変更します。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

パラメーター:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID |
| `note_id`           | 整数           | いいえ       | ノートのID |
| `body`              | 文字列            | はい      | ノートのコンテンツ。1,000,000文字に制限されています。 |
| `confidential`      | ブール値           | いいえ       | **非推奨:**GitLab 16.0で削除される予定です。ノートの非公開フラグ。デフォルトはfalseです。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1?body=note"
```

### マージリクエストノートを削除する

マージリクエストの既存のノートを削除します。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

パラメーター:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID |
| `note_id`           | 整数           | はい      | ノートのID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/7/notes/1602"
```

## エピック

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

エピックREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)となり、APIのv5で削除される予定です。GitLab 17.4以降で、[エピックの新しい外観](../user/group/epics/epic_work_items.md)が有効になっている場合は、代わりに[作業アイテムAPI](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items/)を使用してください。詳細については、[既存のAPIを移行する方法のガイド](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

{{< /alert >}}

### すべてのエピックノートをリストする

単一のエピックの全ノートのリストを取得します。エピックノートは、ユーザーがエピックに投稿できるコメントです。

{{< alert type="note" >}}

エピックノートAPIは、エピックIIDの代わりにエピックIDを使用します。エピックのIIDを使用すると、GitLabは、404エラー、または間違ったエピックのノートを返します。[イシューノートAPI](#issues)や[マージリクエストノートAPI](#merge-requests)とは異なります。

{{< /alert >}}

```plaintext
GET /groups/:id/epics/:epic_id/notes
GET /groups/:id/epics/:epic_id/notes?sort=asc&order_by=updated_at
```

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `epic_id`  | 整数           | はい      | グループエピックのID |
| `sort`     | 文字列            | いいえ       | `asc`または`desc`の順序でソートされたエピックノートを返します。デフォルトは`desc`です |
| `order_by` | 文字列            | いいえ       | `created_at`フィールドまたは`updated_at`フィールドで順序付けられたエピックノートを返します。デフォルトは`created_at`です |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes"
```

### 単一のエピックノートを取得する

指定されたエピックの単一のノートを返します。

```plaintext
GET /groups/:id/epics/:epic_id/notes/:note_id
```

パラメーター:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `epic_id` | 整数           | はい      | エピックのID |
| `note_id` | 整数           | はい      | ノートのID |

```json
{
  "id": 302,
  "body": "Epic note",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T09:22:45Z",
  "updated_at": "2013-10-02T10:22:45Z",
  "system": true,
  "noteable_id": 11,
  "noteable_type": "Epic",
  "project_id": 5,
  "noteable_iid": 11,
  "resolvable": false,
  "confidential": false,
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1"
```

### 新しいエピックノートを作成する

単一のエピックの新しいノートを作成します。エピックノートは、ユーザーがエピックに投稿できるコメントです。本文に絵文字リアクションのみが含まれるノートを作成すると、GitLabはこのオブジェクトを返します。

```plaintext
POST /groups/:id/epics/:epic_id/notes
```

パラメーター:

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `body`         | 文字列            | はい      | ノートのコンテンツ。1,000,000文字に制限されています。 |
| `epic_id`      | 整数           | はい      | エピックのID |
| `id`           | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `confidential` | ブール値           | いいえ       | **非推奨:**GitLab 16.0で削除され、`internal`に名称変更される予定です。ノートの非公開フラグ。デフォルトは`false`です。 |
| `internal`     | ブール値           | いいえ       | ノートの内部フラグ。両方のパラメーターが送信された場合、`confidential`を上書きします。デフォルトは`false`です。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes?body=note"
```

### 既存のエピックノートを変更する

エピックの既存のノートを変更します。

```plaintext
PUT /groups/:id/epics/:epic_id/notes/:note_id
```

パラメーター:

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `epic_id`      | 整数           | はい      | エピックのID |
| `note_id`      | 整数           | はい      | ノートのID |
| `body`         | 文字列            | はい      | ノートのコンテンツ。1,000,000文字に制限されています。 |
| `confidential` | ブール値           | いいえ       | **非推奨:**GitLab 16.0で削除される予定です。ノートの非公開フラグ。デフォルトはfalseです。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1?body=note"
```

### エピックノートを削除する

エピックの既存のノートを削除します。

```plaintext
DELETE /groups/:id/epics/:epic_id/notes/:note_id
```

パラメーター:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `epic_id` | 整数           | はい      | エピックのID |
| `note_id` | 整数           | はい      | ノートのID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/52/notes/1659"
```
