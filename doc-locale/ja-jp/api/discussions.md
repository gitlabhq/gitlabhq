---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ディスカッションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して[ディスカッション](../user/discussions/_index.md)を管理します。これには、[コメント、スレッド](../user/discussions/_index.md)、およびオブジェクトへの変更に関するシステムノート（たとえば、マイルストーンが変更されたとき）が含まれます。

ラベルノートを管理するには、[リソースラベルイベントAPI](resource_label_events.md)を使用します。

## APIにおけるノートタイプについて {#understand-note-types-in-the-api}

すべてのディスカッションタイプがAPIで利用できるわけではありません:

- 注: イシュー、マージリクエスト、コミット、またはスニペットの_root_に残されたコメントです。
- ディスカッション: イシュー、マージリクエスト、コミット、またはスニペットにおける_スレッド_と呼ばれる`DiscussionNotes`のコレクション。
- DiscussionNote: イシュー、マージリクエスト、コミット、またはスニペット上のディスカッションにおける個々のアイテム。`DiscussionNote`タイプのアイテムは、Note APIの一部としては返されません。[Events API](events.md)では利用できません。

## ディスカッションのページネーション {#discussions-pagination}

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

## イシュー {#issues}

### すべてのイシューのディスカッションアイテムをリストアップ {#list-all-issue-discussion-items}

プロジェクト内の指定されたイシューのすべてのディスカッションアイテムをリストアップします。

```plaintext
GET /projects/:id/issues/:issue_iid/discussions
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数           | はい      | イシューのIID |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 文字列  | ディスカッションのID。 |
| `individual_note`       | ブール値 | `true`の場合、個別のノートまたはディスカッションの一部。 |
| `notes`                 | 配列   | ディスカッション内のノートオブジェクトの配列。 |
| `notes[].id`            | 整数 | ノートのID。 |
| `notes[].type`          | 文字列  | ノートのタイプ（`DiscussionNote`または`null`）。 |
| `notes[].body`          | 文字列  | ノートのコンテンツ。 |
| `notes[].author`        | オブジェクト  | ノートの作成者。 |
| `notes[].created_at`    | 文字列  | ノートが作成された日時（ISO 8601形式）。 |
| `notes[].updated_at`    | 文字列  | ノートが最後に更新された日時（ISO 8601形式）。 |
| `notes[].system`        | ブール値 | `true`の場合、システムノート。 |
| `notes[].noteable_id`   | 整数 | ノート可能なオブジェクトのID。 |
| `notes[].noteable_type` | 文字列  | ノート可能なオブジェクトのタイプ。 |
| `notes[].project_id`    | 整数 | プロジェクトのID。 |
| `notes[].resolvable`    | ブール値 | `true`の場合、ノートは解決可能です。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions"
```

レスポンス例: 

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### イシューのディスカッションアイテムを取得する {#retrieve-an-issue-discussion-item}

プロジェクトイシューの指定されたディスカッションアイテムを取得する。

```plaintext
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションアイテムのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[イシューディスカッションアイテムのリスト](#list-all-issue-discussion-items)と同じレスポンス属性を返します。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>"
```

### イシュースレッドを作成 {#create-an-issue-thread}

単一のプロジェクトイシューに新しいスレッドを作成します。ノートの作成に似ていますが、後で他のコメント（返信）を追加できます。

```plaintext
POST /projects/:id/issues/:issue_iid/discussions
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `body`       | 文字列            | はい      | スレッドのコンテンツ。 |
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`  | 整数           | はい      | イシューのIID |
| `created_at` | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と、[イシューディスカッションアイテムのリスト](#list-all-issue-discussion-items)と同じレスポンス属性を返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment"
```

### イシュースレッドにノートを追加 {#add-a-note-to-an-issue-thread}

新しいノートをスレッドに追加します。これは、[単一のコメントからスレッドを作成する](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)こともできます。

> [!note]
> システムノートにはノートを追加できません。これを行おうとすると、`400 Bad Request`エラーが返されます。

```plaintext
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |
| `created_at`    | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes?body=comment"
```

### イシュースレッドのノートを更新 {#update-an-issue-thread-note}

イシューの既存のスレッドノートを更新します。

```plaintext
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |
| `note_id`       | 整数           | はい      | スレッドノートのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### イシュースレッドのノートを削除 {#delete-an-issue-thread-note}

イシューの既存のスレッドノートを削除します。

```plaintext
DELETE /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |
| `note_id`       | 整数           | はい      | ディスカッションノートのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/<note_id>"
```

## スニペット {#snippets}

### すべてのスニペットのディスカッションアイテムをリストアップ {#list-all-snippet-discussion-items}

プロジェクト内の指定されたスニペットのすべてのディスカッションアイテムをリストアップします。

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[イシューディスカッションアイテムのリスト](#list-all-issue-discussion-items)と同じレスポンス属性を返します（`noteable_type`は`Snippet`に設定されます）。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions"
```

レスポンス例: 

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### スニペットのディスカッションアイテムを取得する {#retrieve-a-snippet-discussion-item}

プロジェクトスニペットの指定されたディスカッションアイテムを取得する。

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | 整数         | はい      | ディスカッションアイテムのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id`    | 整数        | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[スニペットディスカッションアイテムのリスト](#list-all-snippet-discussion-items)と同じレスポンス属性を返します。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>"
```

### スニペットスレッドを作成 {#create-a-snippet-thread}

単一のプロジェクトスニペットに新しいスレッドを作成します。ノートの作成に似ていますが、後で他のコメント（返信）を追加できます。

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `body`       | 文字列            | はい      | ディスカッションのコンテンツ。 |
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | スニペットのID。 |
| `created_at` | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment"
```

### スニペットスレッドにノートを追加 {#add-a-note-to-a-snippet-thread}

新しいノートをスレッドに追加します。

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id`    | 整数           | はい      | スニペットのID。 |
| `created_at`    | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes?body=comment"
```

### スニペットスレッドのノートを更新 {#update-a-snippet-thread-note}

スニペットの既存のスレッドノートを更新します。

```plaintext
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `body`          | 文字列         | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数         | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数        | はい      | スレッドノートのID。 |
| `snippet_id`    | 整数        | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### スニペットスレッドのノートを削除 {#delete-a-snippet-thread-note}

スニペットの既存のスレッドノートを削除します。

```plaintext
DELETE /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | ディスカッションノートのID。 |
| `snippet_id`    | 整数           | はい      | スニペットのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/<note_id>"
```

## エピック {#epics}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> エピックREST APIはGitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)になり、APIのv5で削除される予定です。これは破壊的な変更です。
>
> 代わりに作業アイテムAPIを使用してください:
>
> - GitLab 17.4から18.0: [エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合に必須です。
> - GitLab 18.1以降: すべてのインストールで必須です。
>
> 詳細については、[APIの移行ガイド](graphql/epic_work_items_api_migration_guide.md)を参照してください。

### すべてのエピックのディスカッションアイテムをリストアップ {#list-all-epic-discussion-items}

単一のエピックのすべてのディスカッションアイテムをリストアップします。

```plaintext
GET /groups/:id/epics/:epic_id/discussions
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `epic_id` | 整数           | はい      | エピックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[イシューディスカッションアイテムのリスト](#list-all-issue-discussion-items)と同じレスポンス属性を返します（`noteable_type`は`Epic`に設定されます）。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions"
```

レスポンス例: 

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### エピックのディスカッションアイテムを取得する {#retrieve-an-epic-discussion-item}

グループエピックの指定されたディスカッションアイテムを取得する。

```plaintext
GET /groups/:id/epics/:epic_id/discussions/:discussion_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションアイテムのID。 |
| `epic_id`       | 整数           | はい      | エピックのID。 |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[エピックディスカッションアイテムのリスト](#list-all-epic-discussion-items)と同じレスポンス属性を返します。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>"
```

### エピックスレッドを作成 {#create-an-epic-thread}

単一のグループエピックに新しいスレッドを作成します。ノートの作成に似ていますが、後で他のコメント（返信）を追加できます。

```plaintext
POST /groups/:id/epics/:epic_id/discussions
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `body`       | 文字列            | はい      | スレッドのコンテンツ。 |
| `epic_id`    | 整数           | はい      | エピックのID。 |
| `id`         | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_at` | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions?body=comment"
```

### エピックスレッドにノートを追加 {#add-a-note-to-an-epic-thread}

新しいノートをスレッドに追加します。これは、[単一のコメントからスレッドを作成する](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)こともできます。

```plaintext
POST /groups/:id/epics/:epic_id/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `epic_id`       | 整数           | はい      | エピックのID。 |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_at`    | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes?body=comment"
```

### エピックスレッドのノートを更新 {#update-an-epic-thread-note}

エピックの既存のスレッドノートを更新します。

```plaintext
PUT /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `epic_id`       | 整数           | はい      | エピックのID。 |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | スレッドノートのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### エピックスレッドのノートを削除 {#delete-an-epic-thread-note}

エピックの既存のスレッドノートを削除します。

```plaintext
DELETE /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `epic_id`       | 整数           | はい      | エピックのID。 |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | スレッドノートのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/<note_id>"
```

## マージリクエスト {#merge-requests}

### すべてのマージリクエストのディスカッションアイテムをリストアップ {#list-all-merge-request-discussion-items}

指定されたマージリクエストのすべてのディスカッションアイテムをリストアップします。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 文字列  | ディスカッションのID。 |
| `individual_note`       | ブール値 | `true`の場合、個別のノートまたはディスカッションの一部。 |
| `notes`                 | 配列   | ディスカッション内のノートオブジェクトの配列。 |
| `notes[].id`            | 整数 | ノートのID。 |
| `notes[].type`          | 文字列  | ノートのタイプ（`DiscussionNote`、`DiffNote`、または`null`）。 |
| `notes[].body`          | 文字列  | ノートのコンテンツ。 |
| `notes[].author`        | オブジェクト  | ノートの作成者。 |
| `notes[].created_at`    | 文字列  | ノートが作成された日時（ISO 8601形式）。 |
| `notes[].updated_at`    | 文字列  | ノートが最後に更新された日時（ISO 8601形式）。 |
| `notes[].system`        | ブール値 | `true`の場合、システムノート。 |
| `notes[].noteable_id`   | 整数 | ノート可能なオブジェクトのID。 |
| `notes[].noteable_type` | 文字列  | ノート可能なオブジェクトのタイプ。 |
| `notes[].project_id`    | 整数 | プロジェクトのID。 |
| `notes[].resolved`      | ブール値 | `true`の場合、ノートは解決済みです（マージリクエストのみ）。 |
| `notes[].resolvable`    | ブール値 | `true`の場合、ノートは解決可能です。 |
| `notes[].resolved_by`   | オブジェクト  | ノートを解決したユーザー。 |
| `notes[].resolved_at`   | 文字列  | ノートが解決された日時（ISO 8601形式）。 |
| `notes[].position`      | オブジェクト  | 差分ノートの位置情報。 |
| `notes[].suggestions`   | 配列   | ノートの提案オブジェクトの配列。 |

差分コメントにも位置情報が含まれます:

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
```

レスポンス例: 

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null,
        "resolved_at": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  }
]
```

差分コメントにも位置が含まれます:

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "commit_id": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27,
          "line_range": {
            "start": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_10_10",
              "type": "new",
              "old_line": null,
              "new_line": 10
            },
            "end": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_11_11",
              "type": "old",
              "old_line": 11,
              "new_line": 11
            }
          }
        },
        "resolved": false,
        "resolvable": true,
        "resolved_by": null,
        "suggestions": [
          {
            "id": 1,
            "from_line": 27,
            "to_line": 27,
            "appliable": true,
            "applied": false,
            "from_content": "x",
            "to_content": "b"
          }
        ]
      }
    ]
  }
]
```

### マージリクエストのディスカッションアイテムを取得する {#retrieve-a-merge-request-discussion-item}

プロジェクトマージリクエストの指定されたディスカッションアイテムを取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | ディスカッションアイテムのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[マージリクエストのディスカッションアイテムのリスト](#list-all-merge-request-discussion-items)と同じレスポンス属性を返します。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>"
```

### マージリクエストスレッドを作成 {#create-a-merge-request-thread}

単一のプロジェクトマージリクエストに新しいスレッドを作成します。ノートの作成に似ていますが、後で他のコメント（返信）を追加できます。他のアプローチについては、Commits APIの[コミットへのコメント投稿](commits.md#post-comment-to-commit) 、およびNotes APIの[マージリクエストノートの作成](notes.md#create-a-merge-request-note)を参照してください。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions
```

すべてのコメントでサポートされている属性:

| 属性                 | 型              | 必須                             | 説明 |
|---------------------------|-------------------|--------------------------------------|-------------|
| `body`                    | 文字列            | はい                                  | スレッドのコンテンツ。 |
| `id`                      | 整数または文字列 | はい                                  | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`       | 整数           | はい                                  | マージリクエストのIID。 |
| `commit_id`               | 文字列            | いいえ                                   | このディスカッションを開始するコミットを参照するSHA。 |
| `created_at`              | 文字列            | いいえ                                   | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |
| `position`                | ハッシュ              | いいえ                                   | 差分ノートを作成する際のポジション。 |
| `position[base_sha]`      | 文字列            | はい（`position*`が提供されている場合）     | ソースブランチのベースコミットSHA。 |
| `position[head_sha]`      | 文字列            | はい（`position*`が提供されている場合）     | このマージリクエストのHEADを参照するSHA。 |
| `position[start_sha]`     | 文字列            | はい（`position*`が提供されている場合）     | ターゲットブランチのコミットを参照するSHA。 |
| `position[position_type]` | 文字列            | はい（position* が提供されている場合）       | ポジション参照のタイプ。許可される値: `text`、`image`、または`file`。`file`はGitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/423046)。 |
| `position[new_path]`      | 文字列            | はい（位置タイプが`text`の場合） | 変更後のファイルパス。 |
| `position[old_path]`      | 文字列            | はい（位置タイプが`text`の場合） | 変更前のファイルパス。 |
| `position[new_line]`      | 整数           | いいえ                                   | `text`差分ノートの場合、変更後の行番号。 |
| `position[old_line]`      | 整数           | いいえ                                   | `text`差分ノートの場合、変更前の行番号。 |
| `position[line_range]`    | ハッシュ              | いいえ                                   | 複数行差分ノートの行範囲。 |
| `position[width]`         | 整数           | いいえ                                   | `image`差分ノートの場合、画像の幅。 |
| `position[height]`        | 整数           | いいえ                                   | `image`差分ノートの場合、画像の高さ。 |
| `position[x]`             | 浮動小数点数             | いいえ                                   | `image`差分ノートの場合、X座標。 |
| `position[y]`             | 浮動小数点数             | いいえ                                   | `image`差分ノートの場合、Y座標。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトを返します。

#### 概要ページに新しいスレッドを作成 {#create-a-new-thread-on-the-overview-page}

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions?body=comment"
```

#### マージリクエスト差分に新しいスレッドを作成 {#create-a-new-thread-in-the-merge-request-diff}

- `position[old_path]`と`position[new_path]`は必須であり、変更前と変更後のファイルパスを参照する必要があります。
- 追加された行（マージリクエスト差分で緑色にハイライト表示）にスレッドを作成するには、`position[new_line]`を使用し、`position[old_line]`を含めないでください。
- 削除された行（マージリクエスト差分で赤色にハイライト表示）にスレッドを作成するには、`position[old_line]`を使用し、`position[new_line]`を含めないでください。
- 変更されていない行にスレッドを作成するには、その行に`position[new_line]`と`position[old_line]`の両方を含めてください。ファイル内の以前の変更によって行番号が変わった場合、これらの位置は同じではない可能性があります。修正に関するディスカッションについては、[イシュー32516](https://gitlab.com/gitlab-org/gitlab/-/issues/325161)を参照してください。
- 誤った`base`、`head`、`start`、または`SHA`パラメータを指定すると、[イシュー #296829](https://gitlab.com/gitlab-org/gitlab/-/issues/296829)で説明されているバグに遭遇する可能性があります。

新しいスレッドを作成するには:

1. 最新のマージリクエストバージョンを[取得](merge_requests.md#retrieve-merge-request-diff-versions):

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/versions"
   ```

1. レスポンス配列の最初にリストされている最新バージョンの詳細に注意してください。

   ```json
   [
     {
       "id": 164560414,
       "head_commit_sha": "f9ce7e16e56c162edbc9e480108041cf6b0291fe",
       "base_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "start_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "created_at": "2021-03-30T09:18:27.351Z",
       "merge_request_id": 93958054,
       "state": "collected",
       "real_size": "2"
     },
     "previous versions are here"
   ]
   ```

1. 新しい差分スレッドを作成します。この例では、追加された行にスレッドを作成します:

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --form 'position[position_type]=text' \
     --form 'position[base_sha]=<use base_commit_sha from the versions response>' \
     --form 'position[head_sha]=<use head_commit_sha from the versions response>' \
     --form 'position[start_sha]=<use start_commit_sha from the versions response>' \
     --form 'position[new_path]=file.js' \
     --form 'position[old_path]=file.js' \
     --form 'position[new_line]=18' \
     --form 'body=test comment body' \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
   ```

#### 複数行のコメントのパラメータ {#parameters-for-multiline-comments}

複数行のコメントのみでサポートされている属性:

| 属性                                | 型    | 必須 | 説明 |
|------------------------------------------|---------|----------|-------------|
| `position[line_range][end][line_code]`   | 文字列  | はい      | 終了行の[行コード](#line-code)。 |
| `position[line_range][end][type]`        | 文字列  | はい      | このコミットによって追加された行には`new`を使用し、それ以外の場合は`old`を使用します。 |
| `position[line_range][end][old_line]`    | 整数 | いいえ       | 終了行の古い行番号。 |
| `position[line_range][end][new_line]`    | 整数 | いいえ       | 終了行の新しい行番号。 |
| `position[line_range][start][line_code]` | 文字列  | はい      | 開始行の[行コード](#line-code)。 |
| `position[line_range][start][type]`      | 文字列  | はい      | このコミットによって追加された行には`new`を使用し、それ以外の場合は`old`を使用します。 |
| `position[line_range][start][old_line]`  | 整数 | いいえ       | 開始行の古い行番号。 |
| `position[line_range][start][new_line]`  | 整数 | いいえ       | 開始行の新しい行番号。 |
| `position[line_range][end]`              | ハッシュ    | いいえ       | 複数行ノートの終了行。 |
| `position[line_range][start]`            | ハッシュ    | いいえ       | 複数行ノートの開始行。 |

`line_range`属性内の`old_line`および`new_line`パラメータは、複数行のコメントの範囲を表示します。例えば、「+296行から+297行へのコメント」。

#### 行コード {#line-code}

行コードは`<SHA>_<old>_<new>`の形式で、例として`adc83b19e793491b1c6ea0fd8b46cd9f32e292fc_5_5`のようになります。

- `<SHA>`はファイル名のSHA1ハッシュです。
- `<old>`は変更前の行番号です。
- `<new>`は変更後の行番号です。

例えば、コミット（`<COMMIT_ID>`）がReadmeの463行目を削除した場合、古いファイルの463行目を参照してその削除にコメントできます:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Very clever to remove this unnecessary line!" \
  --form "path=README" \
  --form "line=463" \
  --form "line_type=old" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

コミット（`<COMMIT_ID>`）が`hello.rb`に157行目を追加した場合、新しいファイルの157行目を参照してその追加にコメントできます:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=This is brilliant!" \
  --form "path=hello.rb" \
  --form "line=157" \
  --form "line_type=new" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

### マージリクエストスレッドを解決する {#resolve-a-merge-request-thread}

マージリクエスト内のディスカッションスレッドを解決するか再オープンします。

前提条件: 

- デベロッパー、メンテナー、またはオーナーのロールを持っているか、レビューされる変更の作成者である必要があります。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `resolved`          | ブール値           | はい      | `true`の場合、ディスカッションを解決するか再オープンします。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたディスカッションオブジェクトを返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>?resolved=true"
```

### マージリクエストスレッドにノートを追加 {#add-note-to-a-merge-request-thread}

新しいノートをスレッドに追加します。これは、[単一のコメントからスレッドを作成する](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)こともできます。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `body`              | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `created_at`        | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes?body=comment"
```

### マージリクエストスレッドのノートを更新 {#update-a-merge-request-thread-note}

マージリクエストの指定されたスレッドノートを更新または解決する。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `note_id`           | 整数           | はい      | スレッドノートのID。 |
| `body`              | 文字列            | いいえ       | ノートまたは返信のコンテンツ。`body`または`resolved`のいずれか1つのみを設定する必要があります。 |
| `resolved`          | ブール値           | いいえ       | ノートを解決するか再オープンします。`body`または`resolved`のいずれか1つのみを設定する必要があります。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

ノートの解決:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>?resolved=true"
```

### マージリクエストスレッドのノートを削除 {#delete-a-merge-request-thread-note}

マージリクエストの既存のスレッドノートを削除します。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `note_id`           | 整数           | はい      | スレッドノートのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>"
```

## コミット {#commits}

### すべてのコミットディスカッションアイテムをリストアップ {#list-all-commit-discussion-items}

指定されたコミットのすべてのディスカッションアイテムをリストアップします。

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `commit_id` | 文字列            | はい      | コミットのSHA。 |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[イシューディスカッションアイテムのリスト](#list-all-issue-discussion-items)と同じレスポンス属性を返します（`noteable_type`は`Commit`に設定されます）。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions"
```

レスポンス例: 

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

差分コメントにも位置が含まれます:

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27
        },
        "resolvable": false
      }
    ]
  }
]
```

### コミットディスカッションアイテムを取得する {#retrieve-a-commit-discussion-item}

プロジェクトコミットの指定されたディスカッションアイテムを取得する。

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions/:discussion_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | ディスカッションアイテムのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[コミットディスカッションアイテムのリスト](#list-all-commit-discussion-items)と同じレスポンス属性を返します。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>"
```

### コミットスレッドを作成 {#create-a-commit-thread}

単一のプロジェクトコミットに新しいスレッドを作成します。ノートの作成に似ていますが、後で他のコメント（返信）を追加できます。

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions
```

サポートされている属性は以下のとおりです: 

| 属性                 | 型              | 必須                         | 説明 |
|---------------------------|-------------------|----------------------------------|-------------|
| `body`                    | 文字列            | はい                              | スレッドのコンテンツ。 |
| `commit_id`               | 文字列            | はい                              | コミットのSHA。 |
| `id`                      | 整数または文字列 | はい                              | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_at`              | 文字列            | いいえ                               | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |
| `position`                | ハッシュ              | いいえ                               | 差分ノートを作成する際のポジション。 |
| `position[base_sha]`      | 文字列            | はい（`position*`が提供されている場合） | 親コミットのSHA。 |
| `position[head_sha]`      | 文字列            | はい（`position*`が提供されている場合） | このコミットのSHA。`commit_id`と同じです。 |
| `position[start_sha]`     | 文字列            | はい（`position*`が提供されている場合） | 親コミットのSHA。 |
| `position[position_type]` | 文字列            | はい（`position*`が提供されている場合） | ポジション参照のタイプ。許可される値: `text`、`image`、または`file`。`file`はGitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/423046)。 |
| `position[new_path]`      | 文字列            | いいえ                               | 変更後のファイルパス。 |
| `position[new_line]`      | 整数           | いいえ                               | 変更後の行番号。 |
| `position[old_path]`      | 文字列            | いいえ                               | 変更前のファイルパス。 |
| `position[old_line]`      | 整数           | いいえ                               | 変更前の行番号。 |
| `position[height]`        | 整数           | いいえ                               | `image`差分ノートの場合、画像の高さ。 |
| `position[width]`         | 整数           | いいえ                               | `image`差分ノートの場合、画像の幅。 |
| `position[x]`             | 整数           | いいえ                               | `image`差分ノートの場合、X座標。 |
| `position[y]`             | 整数           | いいえ                               | `image`差分ノートの場合、Y座標。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions?body=comment"
```

APIリクエストを作成するルールは、[マージリクエスト差分に新しいスレッドを作成する](#create-a-new-thread-in-the-merge-request-diff)場合と同じです。例外:

- `base_sha`
- `head_sha`
- `start_sha`

### コミットスレッドにノートを追加 {#add-note-to-a-commit-thread}

新しいノートをスレッドに追加します。

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_at`    | 文字列            | いいえ       | 日付時刻文字列、ISO 8601形式（例: `2016-03-11T03:45:40Z`）。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes?body=comment"
```

### コミットスレッドのノートを更新 {#update-a-commit-thread-note}

コミットの指定されたスレッドノートを更新または解決する。

```plaintext
PUT /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | いいえ       | ノートのコンテンツ。 |
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | スレッドノートのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトを返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

ノートの解決:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>?resolved=true"
```

### コミットディスカッションノートを削除 {#delete-a-commit-discussion-note}

コミットの既存のディスカッションノートを削除します。

```plaintext
DELETE /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | スレッドノートのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>"
```
