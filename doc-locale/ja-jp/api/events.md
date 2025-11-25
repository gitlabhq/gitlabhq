---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イベント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、イベントのアクティビティーをレビューします。イベントには、プロジェクトへの参加、イシューへのコメント、MRへの変更のプッシュ、エピックのクローズなど、幅広いアクションが含まれる場合があります。

アクティビティーの保持制限については、以下を参照してください:

- [ユーザーアクティビティーの期間制限](../user/profile/contributions_calendar.md#event-time-period-limit)
- [プロジェクトアクティビティーの期間制限](../user/project/working_with_projects.md#view-project-activity)

## すべてのイベントをリスト表示 {#list-all-events}

現在認証済みユーザーのすべてのイベントをリスト表示します。エピックに関連付けられたイベントは返しません。

前提要件: 

- お使いのアクセストークンには、`read_user`または`api`スコープが必要です。

```plaintext
GET /events
```

パラメータは以下のとおりです:

| パラメータ     | 型            | 必須 | 説明 |
| ------------- | --------------- | -------- | ----------- |
| `action`      | 文字列          | いいえ       | 定義されている場合、指定された[アクションタイプ](../user/profile/contributions_calendar.md#user-contribution-events)のイベントを返します。 |
| `target_type` | 文字列          | いいえ       | 定義されている場合、指定された[対象タイプ](#target-type)のイベントを返します。 |
| `before`      | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より前に作成されたトークンを返します。 |
| `after`       | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より後に作成されたトークンを返します。 |
| `scope`       | 文字列          | いいえ       | ユーザーのプロジェクト全体のすべてのイベントを含めます。 |
| `sort`        | 文字列          | いいえ       | 作成日順に結果をソートする方向。使用可能な値: `asc`、`desc`。デフォルトは`desc`です。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01&scope=all"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 160,
    "target_iid": 53,
    "target_type": "Issue",
    "author_id": 25,
    "target_title": "Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at": "2017-02-09T10:43:19.667Z",
    "author": {
      "name": "User 3",
      "username": "user3",
      "id": 25,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user3"
    },
    "author_username": "user3",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 2,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 159,
    "target_iid": 14,
    "target_type": "Issue",
    "author_id": 21,
    "target_title": "Nostrum enim non et sed optio illo deleniti non.",
    "created_at": "2017-02-09T10:43:19.426Z",
    "author": {
      "name": "Test User",
      "username": "ted",
      "id": 21,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/ted"
    },
    "author_username": "ted",
    "imported": false,
    "imported_from": "none"
  }
]
```

## ユーザーのコントリビュートイベントを取得 {#get-contribution-events-for-a-user}

指定されたユーザーのコントリビュートイベントを取得します。エピックに関連付けられたイベントは返しません。

前提要件: 

- お使いのアクセストークンには、`read_user`または`api`スコープが必要です。

```plaintext
GET /users/:id/events
```

パラメータは以下のとおりです:

| パラメータ     | 型            | 必須 | 説明 |
| ------------- | --------------- | -------- | ----------- |
| `id`          | 整数         | はい      | ユーザーのIDまたはユーザー名。 |
| `action`      | 文字列          | いいえ       | 定義されている場合、指定された[アクションタイプ](../user/profile/contributions_calendar.md#user-contribution-events)のイベントを返します。 |
| `target_type` | 文字列          | いいえ       | 定義されている場合、指定された[対象タイプ](#target-type)のイベントを返します。 |
| `before`      | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より前に作成されたトークンを返します。 |
| `after`       | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より後に作成されたトークンを返します。 |
| `sort`        | 文字列          | いいえ       | 作成日順に結果をソートする方向。使用可能な値: `asc`、`desc`。デフォルトは`desc`です。 |
| `page`        | 整数         | いいえ       | 指定された結果ページを返します。デフォルトは`1`です。 |
| `per_page`    | 整数         | いいえ       | ページあたりの結果数。デフォルトは`20`です。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/:id/events"
```

レスポンス例:

```json
[
  {
    "id": 3,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 830,
    "target_iid": 82,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Public project search field",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 4,
    "title": null,
    "project_id": 15,
    "action_name": "pushed",
    "target_id": null,
    "target_iid": null,
    "target_type": null,
    "author_id": 1,
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "john",
    "imported": false,
    "imported_from": "none",
    "push_data": {
      "commit_count": 1,
      "action": "pushed",
      "ref_type": "branch",
      "commit_from": "50d4420237a9de7be1304607147aec22e4a14af7",
      "commit_to": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "ref": "main",
      "commit_title": "Add simple search to projects in public area"
    },
    "target_title": null
  },
  {
    "id": 5,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 840,
    "target_iid": 11,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Finish & merge Code search PR",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 7,
    "title": null,
    "project_id": 15,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 61,
    "target_type": "Note",
    "author_id": 1,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "http://localhost:3000/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue"
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```

## プロジェクトの可視イベントをすべてリスト表示 {#list-all-visible-events-for-a-project}

指定されたプロジェクトの可視イベントをすべてリスト表示します。

```plaintext
GET /projects/:project_id/events
```

パラメータは以下のとおりです:

| パラメータ     | 型            | 必須 | 説明 |
| ------------- | --------------- | -------- | ----------- |
| `project_id`  | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `action`      | 文字列          | いいえ       | 定義されている場合、指定された[アクションタイプ](../user/profile/contributions_calendar.md#user-contribution-events)のイベントを返します。 |
| `target_type` | 文字列          | いいえ       | 定義されている場合、指定された[対象タイプ](#target-type)のイベントを返します。 |
| `before`      | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より前に作成されたトークンを返します。 |
| `after`       | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より後に作成されたトークンを返します。 |
| `sort`        | 文字列          | いいえ       | 作成日順に結果をソートする方向。使用可能な値: `asc`、`desc`。デフォルトは`desc`です。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:project_id/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01"
```

レスポンス例:

```json
[
  {
    "id": 8,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 160,
    "target_iid": 160,
    "target_type": "Issue",
    "author_id": 25,
    "target_title": "Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at": "2017-02-09T10:43:19.667Z",
    "author": {
      "name": "User 3",
      "username": "user3",
      "id": 25,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user3"
    },
    "author_username": "user3",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 9,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 159,
    "target_iid": 159,
    "target_type": "Issue",
    "author_id": 21,
    "target_title": "Nostrum enim non et sed optio illo deleniti non.",
    "created_at": "2017-02-09T10:43:19.426Z",
    "author": {
      "name": "Test User",
      "username": "ted",
      "id": 21,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/ted"
    },
    "author_username": "ted",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 10,
    "title": null,
    "project_id": 1,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 1312,
    "target_type": "Note",
    "author_id": 1,
    "data": null,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "https://gitlab.example.com/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue",
      "noteable_iid": 377
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "https://gitlab.example.com/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```

## ターゲットのタイプ {#target-type}

{{< history >}}

- [追加](https://gitlab.com/groups/gitlab-org/-/epics/13056) GitLab 17.3の`epics`。

{{< /history >}}

結果をフィルタリングして、特定の対象タイプからのイベントを返すことができます。使用できる値は次のとおりです:

- `epic`<sup>1</sup>
- `issue`
- `merge_request`
- `milestone`
- `note`<sup>2</sup>
- `project`
- `snippet`
- `user`

補足説明:

1. エピックの子アイテム、リンクされたアイテム、開始日、期日、ヘルスステータスなどの一部の機能は、APIによって返されません。
1. 一部のマージリクエストノートでは、代わりに`DiscussionNote`タイプが使用される場合があります。この対象タイプは[APIでサポートされていません](discussions.md#understand-note-types-in-the-api)。
