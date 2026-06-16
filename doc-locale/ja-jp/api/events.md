---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: イベントAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3で`epics`ターゲットタイプが[導入](https://gitlab.com/groups/gitlab-org/-/epics/13056)されました。

{{< /history >}}

このAPIを使用してイベントアクティビティをレビューします。イベントには、プロジェクトへの参加、イシューへのコメント、MRへの変更のプッシュ、エピックのクローズなど、幅広いアクションが含まれます。

アクティビティ保持制限の詳細については、以下を参照してください:

- [ユーザーアクティビティ期間制限](../user/profile/contributions_calendar.md#event-time-period-limit)
- [プロジェクトアクティビティ期間制限](../user/project/working_with_projects.md#view-project-activity)

このAPIには、エピック、マージリクエスト、およびバルクプッシュイベントに関する制限があります:

- 子項目、リンクされた項目、開始日、期日、ヘルスステータスなどの一部のエピック機能は、APIによって返されません。
- 一部のマージリクエストノートは、代わりに`DiscussionNote`タイプを使用する場合があります。このターゲットタイプはAPIでは[サポートされていません](discussions.md#understand-note-types-in-the-api)。
- プッシュが[プッシュイベントアクティビティ制限](../administration/settings/push_event_activities_limit.md)を超過したときに作成されたバルクプッシュイベントは、限られた詳細で返されます: `commit_count: 0`、refsのプッシュ数を示す`ref_count`、および個々のコミット属性（`commit_from`、`commit_to`、`ref`、`commit_title`）に対する`null`値。

## すべてのイベントを一覧表示 {#list-all-events}

認証済みユーザーのすべてのイベントを一覧表示します。エピックまたはマージリクエストに関連付けられたイベントは返されません。限られたコミット詳細のバルクプッシュイベントを返します。

前提条件: 

- あなたのアクセストークンには、`read_user`または`api`スコープのいずれかが必要です。

```plaintext
GET /events
```

パラメータは以下のとおりです:

| パラメータ     | 型            | 必須 | 説明 |
| ------------- | --------------- | -------- | ----------- |
| `action`      | 文字列          | いいえ       | 定義されている場合、指定された[アクションタイプ](../user/profile/contributions_calendar.md#user-contribution-events)のイベントを返します。 |
| `target_type` | 文字列          | いいえ       | 定義されている場合、指定されたイベントを返します。可能な値: `epic`、`issue`、`merge_request`、`milestone`、`note`、`project`、`snippet`、および`user`。 |
| `before`      | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より前に作成されたイベントを返します。 |
| `after`       | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より後に作成されたイベントを返します。 |
| `scope`       | 文字列          | いいえ       | ユーザーのすべてのプロジェクトのイベントを含めます。 |
| `sort`        | 文字列          | いいえ       | 作成日によって結果を並べ替える方向。可能な値: `asc`、`desc`。デフォルトは`desc`です。 |

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

## ユーザーのコントリビュートイベントを取得する {#retrieve-contribution-events-for-a-user}

指定されたユーザーのコントリビュートイベントを取得します。エピックまたはマージリクエストに関連付けられたイベントは返されません。限られたコミット詳細のバルクプッシュイベントを返します。

前提条件: 

- あなたのアクセストークンには、`read_user`または`api`スコープのいずれかが必要です。

```plaintext
GET /users/:id/events
```

パラメータは以下のとおりです:

| パラメータ     | 型            | 必須 | 説明 |
| ------------- | --------------- | -------- | ----------- |
| `id`          | 整数         | はい      | ユーザーのIDまたはユーザー名。 |
| `action`      | 文字列          | いいえ       | 定義されている場合、指定された[アクションタイプ](../user/profile/contributions_calendar.md#user-contribution-events)のイベントを返します。 |
| `target_type` | 文字列          | いいえ       | 定義されている場合、指定されたイベントを返します。可能な値: `epic`、`issue`、`merge_request`、`milestone`、`note`、`project`、`snippet`、および`user`。 |
| `before`      | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より前に作成されたイベントを返します。 |
| `after`       | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より後に作成されたイベントを返します。 |
| `sort`        | 文字列          | いいえ       | 作成日によって結果を並べ替える方向。可能な値: `asc`、`desc`。デフォルトは`desc`です。 |
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

## プロジェクトの表示可能なすべてのイベントを一覧表示 {#list-all-visible-events-for-a-project}

指定されたプロジェクトの表示可能なすべてのイベントを一覧表示します。プッシュが[プッシュイベントアクティビティ制限](../administration/settings/push_event_activities_limit.md)を超過したときに作成されたバルクプッシュイベントは、限られたコミット詳細で返されます: `commit_count: 0`、refsのプッシュ数を示す`ref_count`、および個々のコミット属性の`null`値。

```plaintext
GET /projects/:project_id/events
```

パラメータは以下のとおりです:

| パラメータ     | 型            | 必須 | 説明 |
| ------------- | --------------- | -------- | ----------- |
| `project_id`  | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `action`      | 文字列          | いいえ       | 定義されている場合、指定された[アクションタイプ](../user/profile/contributions_calendar.md#user-contribution-events)のイベントを返します。 |
| `target_type` | 文字列          | いいえ       | 定義されている場合、指定されたイベントを返します。可能な値: `epic`、`issue`、`merge_request`、`milestone`、`note`、`project`、`snippet`、および`user`。 |
| `before`      | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より前に作成されたイベントを返します。 |
| `after`       | 日付（ISO 8601） | いいえ       | 定義されている場合、指定された日付より後に作成されたイベントを返します。 |
| `sort`        | 文字列          | いいえ       | 作成日によって結果を並べ替える方向。可能な値: `asc`、`desc`。デフォルトは`desc`です。 |

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
