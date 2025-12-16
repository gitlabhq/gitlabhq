---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リソースイテレーションイベントAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リソースイテレーションイベントは、GitLab [issue](../user/project/issues/_index.md)に発生したことを追跡します。

これらを使用して、どのイテレーションが設定されたか、誰がそれを行ったか、そしてそれがいつ発生したかを追跡します。

## イシュー {#issues}

### プロジェクトイシューイテレーションイベントの一覧表示 {#list-project-issue-iteration-events}

単一のイシューに対するすべてのイテレーションイベントのリストを取得します。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_iteration_events
```

| 属性   | 型           | 必須 | 説明                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid` | 整数        | はい      | イシューのIID                                                             |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_iteration_events"
```

レスポンス例:

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "iteration":   {
      "id": 50,
      "iid": 9,
      "group_id": 5,
      "title": "Iteration I",
      "description": "Ipsum Lorem",
      "state": 1,
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null
    },
    "action": "add"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "iteration":   {
      "id": 53,
      "iid": 13,
      "group_id": 5,
      "title": "Iteration II",
      "description": "Ipsum Lorem ipsum",
      "state": 2,
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null
    },
    "action": "remove"
  }
]
```

### 単一イシューイテレーションイベントの取得 {#get-single-issue-iteration-event}

特定のプロジェクトイシューに対する単一のイテレーションイベントを返します。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_iteration_events/:resource_iteration_event_id
```

パラメータは以下のとおりです:

| 属性                     | 型           | 必須 | 説明                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 整数        | はい      | イシューのIID                                                             |
| `resource_iteration_event_id` | 整数        | はい      | イテレーションイベントのID                                                     |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_iteration_events/143"
```

レスポンス例:

```json
{
  "id": 143,
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2018-08-21T14:38:20.077Z",
  "resource_type": "Issue",
  "resource_id": 253,
  "iteration":   {
    "id": 53,
    "iid": 13,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": null,
    "start_date": null
  },
  "action": "remove"
}
```
