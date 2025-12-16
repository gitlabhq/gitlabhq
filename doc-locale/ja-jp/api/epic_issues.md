---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: エピックイシューAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

エピックREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)となり、APIのv5で削除される予定です。GitLab 17.4から18.0までのバージョンで、[エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合は、GitLab 18.1以降で、代わりに作業アイテムAPIを使用してください。詳細については、[作業アイテムにエピックAPIを移行する](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

{{< /alert >}}

エピックイシューAPIエンドポイントへのすべてのAPIコールは、認証される必要があります。

ユーザーがグループのメンバーではなく、グループがプライベートである場合、そのグループに対する`GET`リクエストの結果として、`404`ステータスコードが返されます。

エピックは、GitLab [Premium](https://about.gitlab.com/pricing/)とUltimateでのみ利用可能です。エピック機能が利用できない場合、`403`ステータスコードが返されます。

## エピックのページネーション {#epic-issues-pagination}

APIの結果は[ページ分割されています](rest/_index.md#pagination)。複数のイシューを返すリクエストは、デフォルトで一度に20件の結果を返します。

## エピックのイシューを一覧表示 {#list-issues-for-an-epic}

エピックに割り当てられていて、認証済みユーザーがアクセスできるすべてのイシューを取得します。

```plaintext
GET /groups/:id/epics/:epic_iid/issues
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID。  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues"
```

レスポンス例:

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "epic_issue_id": 2
  }
]
```

{{< alert type="note" >}}

`assignee`列は非推奨になりました。これはシングルサイズの`assignees`配列になりました。

{{< /alert >}}

## イシューをエピックに割り当てる {#assign-an-issue-to-the-epic}

エピックとイシューの関連付けを作成します。問題のイシューが別のエピックに属している場合、そのエピックから割り当て解除されます。

```plaintext
POST /groups/:id/epics/:epic_iid/issues/:issue_id
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID。  |
| `issue_id`          | 整数または文字列   | はい        | イシューのID          |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/55"
```

レスポンス例:

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 55,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

{{< alert type="note" >}}

`assignee`列は非推奨になりました。これはシングルサイズの`assignees`配列になりました。

{{< /alert >}}

## エピックからイシューを削除 {#remove-an-issue-from-the-epic}

エピックとイシューの関連付けを削除します。

```plaintext
DELETE /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| 属性           | 型             | 必須   | 説明                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID。                |
| `epic_issue_id`     | 整数または文字列   | はい        | イシューとエピックの関連付けのID。     |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11"

```

レスポンス例:

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 223,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

{{< alert type="note" >}}

`assignee`列は非推奨になりました。これはシングルサイズの`assignees`配列になりました。

{{< /alert >}}

## エピックとイシューの関連付けを更新 {#update-epic---issue-association}

エピックとイシューの関連付けを更新します。

```plaintext
PUT /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| 属性           | 型             | 必須   | 説明                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID。                |
| `epic_issue_id`     | 整数または文字列   | はい        | イシューとエピックの関連付けのID。     |
| `move_before_id`    | 整数または文字列   | いいえ         | 質問のリンクの前に配置する必要があるイシューとエピックの関連付けのID。     |
| `move_after_id`     | 整数または文字列   | いいえ         | 質問のリンクの後に配置する必要があるイシューとエピックの関連付けのID。     |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11?move_before_id=20"
```

レスポンス例:

```json
[
  {
    "id": 30,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "subscribed": true,
    "epic_issue_id": 11,
    "relative_position": 55
  }
]
```
