---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ウェイトイベントAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リソースのウェイトイベントは、GitLab [イシュー](../user/project/issues/_index.md)に何が起こったかを追跡します。

それらを使用して、どのウェイトが設定されたか、誰がそれを行ったか、そしてそれがいつ発生したかを追跡します。

## イシュー {#issues}

### プロジェクトイシューのウェイトイベントの一覧を表示 {#list-project-issue-weight-events}

単一のイシューに対するすべてのウェイトイベントのリストを取得します。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events
```

| 属性   | 型           | 必須 | 説明                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid` | 整数        | はい      | イシューのIID                                                             |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events"
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
    "issue_id": 253,
    "weight": 3
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
    "issue_id": 253,
    "weight": 2
  }
]
```

### 単一イシューウェイトイベントを取得 {#get-single-issue-weight-event}

特定のプロジェクトイシューに対する単一のウェイトイベントを返します

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events/:resource_weight_event_id
```

パラメータは以下のとおりです:

| 属性                     | 型           | 必須 | 説明                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 整数        | はい      | イシューのIID                                                             |
| `resource_weight_event_id`    | 整数        | はい      | ウェイトイベントのID                                                     |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events/143"
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
"issue_id": 253,
"weight": 2
}
```
