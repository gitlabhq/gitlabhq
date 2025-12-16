---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Discussions API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ディスカッションは以下に添付されます:

- スニペット
- イシュー
- エピック
- マージリクエスト
- コミット

これには、[コメント、スレッド](../user/discussions/_index.md)、システムノートが含まれます。システムノートは、オブジェクトへの変更に関するノートです（例: マイルストーンが変更された場合）。

ラベルノートはこのAPIの一部ではありませんが、[リソースラベルイベント](resource_label_events.md)の個別のイベントとして記録されます。

## APIのノートタイプについて {#understand-note-types-in-the-api}

すべてのディスカッションタイプがAPIで同じように利用できるわけではありません:

- 注: イシュー、マージリクエスト、コミット、またはスニペットの_root_に残されたコメント。
- ディスカッション: イシュー、マージリクエスト、コミット、またはスニペット内の`DiscussionNotes`のコレクション（多くの場合、_スレッド_と呼ばれます）。
- DiscussionNote: イシュー、マージリクエスト、コミット、またはスニペットのディスカッション内の個々のアイテム。タイプ`DiscussionNote`のアイテムは、ノートAPIの一部として返されません。[Events API](events.md)では利用できません。

## ディスカッションのページネーション {#discussions-pagination}

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

## イシュー {#issues}

### プロジェクトイシューディスカッションアイテムの一覧表示 {#list-project-issue-discussion-items}

単一のイシューに対するすべてのディスカッションアイテムのリストを取得します。

```plaintext
GET /projects/:id/issues/:issue_iid/discussions
```

サポートされている属性は以下のとおりです:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数           | はい      | イシューのIID |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 文字列  | ディスカッションのID。 |
| `individual_note`       | ブール値 | `true`の場合、個々のノートまたはディスカッションの一部。 |
| `notes`                 | 配列   | ディスカッション内のノートオブジェクトの配列。 |
| `notes[].id`            | 整数 | ノートのID。 |
| `notes[].type`          | 文字列  | ノートのタイプ（`DiscussionNote`または`null`）。 |
| `notes[].body`          | 文字列  | ノートの内容。 |
| `notes[].author`        | オブジェクト  | ノートの作成者。 |
| `notes[].created_at`    | 文字列  | ノートが作成された日時（ISO 8601形式）。 |
| `notes[].updated_at`    | 文字列  | ノートが最後に更新された日時（ISO 8601形式）。 |
| `notes[].system`        | ブール値 | `true`の場合、システムノート。 |
| `notes[].noteable_id`   | 整数 | ノート可能なオブジェクトのID。 |
| `notes[].noteable_type` | 文字列  | ノート可能なオブジェクトのタイプ。 |
| `notes[].project_id`    | 整数 | プロジェクトのID。 |
| `notes[].resolvable`    | ブール値 | `true`の場合、ノートは解決できます。 |

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

### 単一のイシューディスカッションアイテムを取得 {#get-single-issue-discussion-item}

特定のプロジェクトイシューの単一のディスカッションアイテムを返します。

```plaintext
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションアイテムのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と[プロジェクトイシューディスカッションアイテムの一覧表示](#list-project-issue-discussion-items)と同じレスポンス属性が返されます。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>"
```

### 新規イシュースレッドの作成 {#create-new-issue-thread}

単一のプロジェクトイシューに新しいスレッドを作成します。ノートの作成に似ていますが、他のコメント（返信）を後で追加できます。

```plaintext
POST /projects/:id/issues/:issue_iid/discussions
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `body`       | 文字列            | はい      | スレッドのコンテンツ。 |
| `id`         | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`  | 整数           | はい      | イシューのIID |
| `created_at` | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と[プロジェクトイシューディスカッションアイテムの一覧表示](#list-project-issue-discussion-items)と同じレスポンス属性が返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment"
```

### 既存のイシュースレッドへのノートの追加 {#add-note-to-existing-issue-thread}

新しいノートをスレッドに追加します。これは、[単一のコメントからスレッドを作成する](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)こともできます。

{{< alert type="warning" >}}

ノートは、システムノートなど、コメント以外のアイテムにも追加でき、スレッドになります。

{{< /alert >}}

```plaintext
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |
| `created_at`    | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes?body=comment"
```

### 既存のイシュースレッドノートの変更 {#modify-existing-issue-thread-note}

イシューの既存のスレッドノートを変更します。

```plaintext
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |
| `note_id`       | 整数           | はい      | スレッドノートのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトが返されます。

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/1108?body=comment"
```

### イシュースレッドノートの削除 {#delete-an-issue-thread-note}

イシューの既存のスレッドノートを削除します。

```plaintext
DELETE /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数           | はい      | イシューのIID |
| `note_id`       | 整数           | はい      | ディスカッションノートのID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/636"
```

## スニペット {#snippets}

### プロジェクトスニペットディスカッションアイテムの一覧表示 {#list-project-snippet-discussion-items}

単一のスニペットに対するすべてのディスカッションアイテムのリストを取得します。

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と[プロジェクトイシューディスカッションアイテムの一覧表示](#list-project-issue-discussion-items)と同じレスポンス属性が返され、`noteable_type`が`Snippet`に設定されます。

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

### 単一のスニペットディスカッションアイテムを取得 {#get-single-snippet-discussion-item}

特定のプロジェクトスニペットの単一のディスカッションアイテムを返します。

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | 整数         | はい      | ディスカッションアイテムのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id`    | 整数        | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と[プロジェクトスニペットディスカッションアイテムの一覧表示](#list-project-snippet-discussion-items)と同じレスポンス属性が返されます。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>"
```

### 新しいスニペットスレッドの作成 {#create-new-snippet-thread}

単一のプロジェクトスニペットに新しいスレッドを作成します。ノートの作成に似ていますが、他のコメント（返信）を後で追加できます。

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `body`       | 文字列            | はい      | ディスカッションのコンテンツ。 |
| `id`         | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | スニペットのID。 |
| `created_at` | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment"
```

### 既存のスニペットスレッドへのノートの追加 {#add-note-to-existing-snippet-thread}

新しいノートをスレッドに追加します。

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id`    | 整数           | はい      | スニペットのID。 |
| `created_at`    | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes?body=comment"
```

### 既存のスニペットスレッドノートの変更 {#modify-existing-snippet-thread-note}

スニペットの既存のスレッドノートを変更します。

```plaintext
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `body`          | 文字列         | はい      | ノートまたは返信のコンテンツ。 |
| `discussion_id` | 整数         | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数        | はい      | スレッドノートのID。 |
| `snippet_id`    | 整数        | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトが返されます。

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/1108?body=comment"
```

### スニペットスレッドノートの削除 {#delete-a-snippet-thread-note}

スニペットの既存のスレッドノートを削除します。

```plaintext
DELETE /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | ディスカッションノートのID。 |
| `snippet_id`    | 整数           | はい      | スニペットのID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/636"
```

## エピック {#epics}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

エピックREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)となり、APIのv5で削除される予定です。これは破壊的な変更です。

代わりに、Work Items APIを使用してください:

- GitLab 17.4から18.0: [エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合に必要です。
- GitLab 18.1以降: すべてのインストールで必須。

詳細については、[API移行ガイド](graphql/epic_work_items_api_migration_guide.md)を参照してください。

{{< /alert >}}

### グループエピックディスカッションアイテムの一覧表示 {#list-group-epic-discussion-items}

単一のエピックに対するすべてのディスカッションアイテムのリストを取得します。

```plaintext
GET /groups/:id/epics/:epic_id/discussions
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `epic_id` | 整数           | はい      | エピックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と[プロジェクトイシューディスカッションアイテムの一覧表示](#list-project-issue-discussion-items)と同じレスポンス属性が返され、`noteable_type`が`Epic`に設定されます。

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

### 単一のエピックディスカッションアイテムを取得 {#get-single-epic-discussion-item}

特定のグループエピックの単一のディスカッションアイテムを返します。

```plaintext
GET /groups/:id/epics/:epic_id/discussions/:discussion_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 整数            | はい      | ディスカッションアイテムのID。 |
| `epic_id`       | 整数           | はい      | エピックのID。 |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と[グループエピックディスカッションアイテムの一覧表示](#list-group-epic-discussion-items)と同じレスポンス属性が返されます。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>"
```

### 新しいエピックスレッドの作成 {#create-new-epic-thread}

単一のグループエピックに新しいスレッドを作成します。ノートの作成に似ていますが、他のコメント（返信）を後で追加できます。

```plaintext
POST /groups/:id/epics/:epic_id/discussions
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `body`       | 文字列            | はい      | スレッドのコンテンツ。 |
| `epic_id`    | 整数           | はい      | エピックのID。 |
| `id`         | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_at` | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions?body=comment"
```

### 既存のエピックスレッドへのノートの追加 {#add-note-to-existing-epic-thread}

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
| `created_at`    | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたノートオブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes?body=comment"
```

### 既存のエピックスレッドノートの変更 {#modify-existing-epic-thread-note}

エピックの既存のスレッドノートを変更します。

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

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたノートオブジェクトが返されます。

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/1108?body=comment"
```

### エピックスレッドノートの削除 {#delete-an-epic-thread-note}

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

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/636"
```

## マージリクエスト {#merge-requests}

### プロジェクトマージリクエストディスカッションアイテムの一覧表示 {#list-project-merge-request-discussion-items}

単一のマージリクエストに対するすべてのディスカッションアイテムのリストを取得します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions
```

サポートされている属性は以下のとおりです:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 文字列  | ディスカッションのID。 |
| `individual_note`       | ブール値 | `true`の場合、個々のノートまたはディスカッションの一部。 |
| `notes`                 | 配列   | ディスカッション内のノートオブジェクトの配列。 |
| `notes[].id`            | 整数 | ノートのID。 |
| `notes[].type`          | 文字列  | ノートのタイプ（`DiscussionNote`、`DiffNote`、または`null`）。 |
| `notes[].body`          | 文字列  | ノートの内容。 |
| `notes[].author`        | オブジェクト  | ノートの作成者。 |
| `notes[].created_at`    | 文字列  | ノートが作成された日時（ISO 8601形式）。 |
| `notes[].updated_at`    | 文字列  | ノートが最後に更新された日時（ISO 8601形式）。 |
| `notes[].system`        | ブール値 | `true`の場合、システムノート。 |
| `notes[].noteable_id`   | 整数 | ノート可能なオブジェクトのID。 |
| `notes[].noteable_type` | 文字列  | ノート可能なオブジェクトのタイプ。 |
| `notes[].project_id`    | 整数 | プロジェクトのID。 |
| `notes[].resolved`      | ブール値 | `true`の場合、ノートは解決されます（マージリクエストのみ）。 |
| `notes[].resolvable`    | ブール値 | `true`の場合、ノートは解決できます。 |
| `notes[].resolved_by`   | オブジェクト  | ノートを解決したユーザー。 |
| `notes[].resolved_at`   | 文字列  | ノートが解決された日時（ISO 8601形式）。 |
| `notes[].position`      | オブジェクト  | 差分ノートの位置情報。 |
| `notes[].suggestions`   | 配列   | ノートのサジェスチョンオブジェクトの配列。 |

差分コメントにも位置情報が含まれています:

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

差分コメントにも位置が含まれています:

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

### 単一のマージリクエストディスカッションアイテムを取得 {#get-single-merge-request-discussion-item}

特定のプロジェクトマージリクエストの単一のディスカッションアイテムを返します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

サポートされている属性は以下のとおりです:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | ディスカッションアイテムのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と[プロジェクトマージリクエストディスカッションアイテムの一覧表示](#list-project-merge-request-discussion-items)と同じレスポンス属性が返されます。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>"
```

### 新しいマージリクエストスレッドを作成する {#create-new-merge-request-thread}

単一のプロジェクトマージリクエストに新しいスレッドを作成します。ノートの作成に似ていますが、他のコメント（返信）を後で追加できます。他の方法については、コミットAPIの[コミットへのコメントの投稿](commits.md#post-comment-to-commit) 、およびノートAPIの[新しいマージリクエストノートの作成](notes.md#create-new-merge-request-note)を参照してください。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions
```

すべてのコメントでサポートされている属性:

| 属性                 | 型              | 必須                             | 説明 |
|---------------------------|-------------------|--------------------------------------|-------------|
| `body`                    | 文字列            | はい                                  | スレッドのコンテンツ。 |
| `id`                      | 整数または文字列 | はい                                  | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`       | 整数           | はい                                  | マージリクエストのIID。 |
| `commit_id`               | 文字列            | いいえ                                   | このディスカッションを開始するコミットを参照するSHA。 |
| `created_at`              | 文字列            | いいえ                                   | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |
| `position`                | ハッシュ              | いいえ                                   | 差分ノートを作成する際の位置。 |
| `position[base_sha]`      | 文字列            | はい（`position*`が指定されている場合）     | ソースブランチのベースコミットSHA。 |
| `position[head_sha]`      | 文字列            | はい（`position*`が指定されている場合）     | このマージリクエストのHEADを参照するSHA。 |
| `position[start_sha]`     | 文字列            | はい（`position*`が指定されている場合）     | ターゲットブランチ内のコミットを参照するSHA。 |
| `position[position_type]` | 文字列            | はい（position\*が指定されている場合）       | ポジション参照のタイプ。使用できる値: `text`、`image`、または`file`。`file`はGitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423046)されました。 |
| `position[new_path]`      | 文字列            | はい（ポジションタイプが`text`の場合） | 変更後のファイルパス。 |
| `position[old_path]`      | 文字列            | はい（ポジションタイプが`text`の場合） | 変更前のファイルパス。 |
| `position[new_line]`      | 整数           | いいえ                                   | `text`差分ノートの場合、変更後の行番号。 |
| `position[old_line]`      | 整数           | いいえ                                   | `text`差分ノートの場合、変更前の行番号。 |
| `position[line_range]`    | ハッシュ              | いいえ                                   | 複数行の差分ノートの行範囲。 |
| `position[width]`         | 整数           | いいえ                                   | `image`差分ノートの場合、画像の幅。 |
| `position[height]`        | 整数           | いいえ                                   | `image`差分ノートの場合、画像の高さ。 |
| `position[x]`             | 浮動小数点数             | いいえ                                   | `image`差分ノートの場合、X座標。 |
| `position[y]`             | 浮動小数点数             | いいえ                                   | `image`差分ノートの場合、Y座標。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトが返されます。

#### 概要ページに新しいスレッドを作成する {#create-a-new-thread-on-the-overview-page}

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions?body=comment"
```

#### マージリクエスト差分に新しいスレッドを作成する {#create-a-new-thread-in-the-merge-request-diff}

- `position[old_path]`と`position[new_path]`の両方が必須であり、変更前後のファイルパスを参照する必要があります。
- 追加された行（マージリクエスト差分で緑色で強調表示）にスレッドを作成するには、`position[new_line]`を使用し、`position[old_line]`を含めないでください。
- 削除された行（マージリクエスト差分で赤色で強調表示）にスレッドを作成するには、`position[old_line]`を使用し、`position[new_line]`を含めないでください。
- 変更されていない行にスレッドを作成するには、その行の`position[new_line]`と`position[old_line]`の両方を含めます。ファイル内の以前の変更で行番号が変更された場合、これらのポジションが同じではない可能性があります。修正に関するディスカッションについては、[イシュー32516](https://gitlab.com/gitlab-org/gitlab/-/issues/325161)を参照してください。
- 正しくない`base`、`head`、`start`、または`SHA`パラメータを指定すると、[イシュー＃296829](https://gitlab.com/gitlab-org/gitlab/-/issues/296829)で説明されているバグが発生する可能性があります。

新しいスレッドを作成するには:

1. [最新のマージリクエストバージョンを取得](merge_requests.md#get-merge-request-diff-versions):

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/versions"
   ```

1. レスポンス配列に最初にリストされている最新バージョンの詳細をメモしておきます。

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

複数行のコメントでサポートされている属性のみ:

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
| `position[line_range][end]`              | ハッシュ    | いいえ       | 複数行の注釈の終了行。 |
| `position[line_range][start]`            | ハッシュ    | いいえ       | 複数行の注釈の開始行。 |

`line_range`属性内の`old_line`および`new_line`パラメータは、複数行のコメントの範囲を表示します。たとえば、「+296～+297行のコメント」などです。

#### 行コード {#line-code}

行コードは`<SHA>_<old>_<new>`の形式です。例: `adc83b19e793491b1c6ea0fd8b46cd9f32e292fc_5_5`

- `<SHA>`は、ファイル名のSHA1ハッシュです。
- `<old>`は、変更前の行番号です。
- `<new>`は、変更後の行番号です。

たとえば、コミット（`<COMMIT_ID>`）がReadmeの463行目を削除する場合、古いファイルの463行目を参照して削除についてコメントできます:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Very clever to remove this unnecessary line!" \
  --form "path=README" \
  --form "line=463" \
  --form "line_type=old" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

たとえば、コミット（`<COMMIT_ID>`）が`hello.rb`に157行目を追加する場合、新しいファイルの157行目を参照して追加についてコメントできます:

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

マージリクエストでディスカッションのスレッドを解決または再度開きます。

前提要件: 

- 少なくともデベロッパーロールを持っているか、レビュー対象の変更の作成者である必要があります。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

サポートされている属性は以下のとおりです:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `resolved`          | ブール値           | はい      | `true`の場合、ディスカッションを解決または再度開きます。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたディスカッションオブジェクトが返されます。

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>?resolved=true"
```

### 既存のマージリクエストスレッドに注記を追加する {#add-note-to-existing-merge-request-thread}

新しい注記をスレッドに追加します。これは、[単一のコメントからスレッドを作成](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)することもできます。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `body`              | 文字列            | はい      | 注記または返信のコンテンツ。 |
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `created_at`        | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成された注記オブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes?body=comment"
```

### 既存のマージリクエストスレッドの注記を変更する {#modify-an-existing-merge-request-thread-note}

マージリクエストの既存のスレッドの注記を変更または解決します。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `note_id`           | 整数           | はい      | スレッドの注記のID。 |
| `body`              | 文字列            | いいえ       | 注記または返信のコンテンツ。`body`または`resolved`のいずれか1つを設定する必要があります。 |
| `resolved`          | ブール値           | いいえ       | 注記を解決または再度開きます。`body`または`resolved`のいずれか1つを設定する必要があります。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新された注記オブジェクトが返されます。

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/1108?body=comment"
```

注記の解決:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/1108?resolved=true"
```

### マージリクエストスレッドの注記を削除する {#delete-a-merge-request-thread-note}

マージリクエストの既存のスレッドノートを削除します。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 文字列            | はい      | スレッドのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `note_id`           | 整数           | はい      | スレッドの注記のID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/636"
```

## コミット {#commits}

### プロジェクトコミットのディスカッションアイテムを一覧表示する {#list-project-commit-discussion-items}

単一のコミットに対するすべてのディスカッションアイテムのリストを取得します。

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions
```

サポートされている属性は以下のとおりです:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `commit_id` | 文字列            | はい      | コミットのSHA。 |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、`noteable_type`が`Commit`に設定された[プロジェクトイシューのディスカッションアイテムのリスト](#list-project-issue-discussion-items)と同じレスポンス属性が返されます。

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

Diffコメントにもポジションが含まれています:

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

### 単一のコミットのディスカッションアイテムを取得する {#get-single-commit-discussion-item}

特定のプロジェクトコミットに対する単一のディスカッションアイテムを返します

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions/:discussion_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | ディスカッションアイテムのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、[プロジェクトコミットのディスカッションアイテムのリスト](#list-project-commit-discussion-items)と同じレスポンス属性が返されます。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>"
```

### 新しいコミットスレッドを作成する {#create-new-commit-thread}

単一のプロジェクトコミットに新しいスレッドを作成します。注記の作成と同様ですが、後で他のコメント（返信）を追加できます。

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions
```

サポートされている属性は以下のとおりです:

| 属性                 | 型              | 必須                         | 説明 |
|---------------------------|-------------------|----------------------------------|-------------|
| `body`                    | 文字列            | はい                              | スレッドのコンテンツ。 |
| `commit_id`               | 文字列            | はい                              | コミットのSHA。 |
| `id`                      | 整数または文字列 | はい                              | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_at`              | 文字列            | いいえ                               | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |
| `position`                | ハッシュ              | いいえ                               | Diff注記を作成するときのポジション。 |
| `position[base_sha]`      | 文字列            | はい（`position*`が指定されている場合） | 親コミットのSHA。 |
| `position[head_sha]`      | 文字列            | はい（`position*`が指定されている場合） | このコミットのSHA。`commit_id`と同じです。 |
| `position[start_sha]`     | 文字列            | はい（`position*`が指定されている場合） | 親コミットのSHA。 |
| `position[position_type]` | 文字列            | はい（`position*`が指定されている場合） | ポジション参照のタイプ。使用できる値: `text`、`image`、または`file`。`file`はGitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423046)されました。 |
| `position[new_path]`      | 文字列            | いいえ                               | 変更後のファイルパス。 |
| `position[new_line]`      | 整数           | いいえ                               | 変更後の行番号。 |
| `position[old_path]`      | 文字列            | いいえ                               | 変更前のファイルパス。 |
| `position[old_line]`      | 整数           | いいえ                               | 変更前の行番号。 |
| `position[height]`        | 整数           | いいえ                               | `image`Diff注記の場合、画像の高さ。 |
| `position[width]`         | 整数           | いいえ                               | `image`Diff注記の場合、画像の幅。 |
| `position[x]`             | 整数           | いいえ                               | `image`Diff注記の場合、X座標。 |
| `position[y]`             | 整数           | いいえ                               | `image`Diff注記の場合、Y座標。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成されたディスカッションオブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions?body=comment"
```

APIリクエストを作成するためのルールは、[マージリクエストの差分に新しいスレッドを作成する](#create-a-new-thread-in-the-merge-request-diff)場合と同じです。例外:

- `base_sha`
- `head_sha`
- `start_sha`

### 既存のコミットスレッドに注記を追加する {#add-note-to-existing-commit-thread}

新しい注記をスレッドに追加します。

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | はい      | 注記または返信のコンテンツ。 |
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_at`    | 文字列            | いいえ       | 日時文字列。`2016-03-11T03:45:40Z`のように、ISO 8601形式で記述します。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と作成された注記オブジェクトが返されます。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes?body=comment"
```

### 既存のコミットスレッドの注記を変更する {#modify-an-existing-commit-thread-note}

コミットの既存のスレッドの注記を変更または解決します。

```plaintext
PUT /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `body`          | 文字列            | いいえ       | ノートのコンテンツ。 |
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | スレッドの注記のID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新された注記オブジェクトが返されます。

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/1108?body=comment"
```

注記の解決:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/1108?resolved=true"
```

### コミットのディスカッション注記を削除する {#delete-a-commit-discussion-note}

コミットの既存のディスカッション注記を削除します。

```plaintext
DELETE /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | 文字列            | はい      | コミットのSHA。 |
| `discussion_id` | 文字列            | はい      | スレッドのID。 |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `note_id`       | 整数           | はい      | スレッドの注記のID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/636"
```
