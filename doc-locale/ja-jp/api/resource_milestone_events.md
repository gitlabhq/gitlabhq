---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リソースマイルストーンイベントAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リソース[マイルストーン](../user/project/milestones/_index.md)イベントは、 [issue](../user/project/issues/_index.md)と[マージリクエスト](../user/project/merge_requests/_index.md)で何が起こるかを追跡します。

それらを使用して、どのマイルストーンが追加または削除されたか、誰がそれを行ったか、そしてそれがいつ起こったかを追跡します。

## イシュー {#issues}

### プロジェクトイシューマイルストーンイベントの一覧 {#list-project-issue-milestone-events}

単一のイシューに対するすべてのマイルストーンイベントのリストを取得します。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events
```

| 属性   | 型           | 必須 | 説明                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid` | 整数        | はい      | イシューのIID                                                             |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events"
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
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
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
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### 単一イシューマイルストーンイベントを取得 {#get-single-issue-milestone-event}

特定のプロジェクトイシューの単一マイルストーンイベントを返します

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events/:resource_milestone_event_id
```

パラメータは以下のとおりです:

| 属性                     | 型           | 必須 | 説明                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 整数        | はい      | イシューのIID                                                             |
| `resource_milestone_event_id` | 整数        | はい      | マイルストーンイベントのID                                                     |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events/1"
```

## マージリクエスト {#merge-requests}

### プロジェクトマージリクエストマイルストーンイベントの一覧 {#list-project-merge-request-milestone-events}

単一のマージリクエストに対するすべてのマイルストーンイベントのリストを取得します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events
```

| 属性           | 型           | 必須 | 説明                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数        | はい      | マージリクエストのIID                                                      |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events"
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
    "resource_type": "MergeRequest",
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
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
    "resource_type": "MergeRequest",
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### 単一マージリクエストマイルストーンイベントを取得 {#get-single-merge-request-milestone-event}

特定のプロジェクトマージリクエストに対する単一マイルストーンイベントを返します

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events/:resource_milestone_event_id
```

パラメータは以下のとおりです:

| 属性                     | 型           | 必須 | 説明                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | 整数        | はい      | マージリクエストのIID                                                      |
| `resource_milestone_event_id` | 整数        | はい      | マイルストーンイベントのID                                                     |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events/120"
```
