---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: リソースステートイベントAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

イシュー、マージリクエスト、およびエピックのステート変更イベントを操作するには、このAPIを使用します。

このAPIは、リソースの初期状態（`created`または`opened`）を追跡しません。クローズまたは再オープンされなかったリソースの場合、空のリストが返されます。

## イシュー {#issues}

### プロジェクトイシューのステートイベントを一覧表示 {#list-project-issue-state-events}

単一のイシューのすべてのステートイベントを一覧表示します。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events
```

| 属性   | 型           | 必須 | 説明                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid` | 整数        | はい      | イシューのIID                                                             |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### 単一のイシューステートイベントを取得する {#retrieve-a-single-issue-state-event}

特定のプロジェクトイシューの単一のステートイベントを取得します。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events/:resource_state_event_id
```

パラメータは以下のとおりです:

| 属性                     | 型           | 必須 | 説明                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 整数        | はい      | イシューのIID                                                             |
| `resource_state_event_id`     | 整数        | はい      | ステートイベントのID                                                     |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events/143"
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
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```

## マージリクエスト {#merge-requests}

### プロジェクトマージリクエストのステートイベントを一覧表示 {#list-project-merge-request-state-events}

単一のマージリクエストのすべてのステートイベントを一覧表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events
```

| 属性           | 型           | 必須 | 説明                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数        | はい      | マージリクエストのIID                                                      |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### 単一のマージリクエストステートイベントを取得する {#retrieve-a-single-merge-request-state-event}

特定のプロジェクトマージリクエストの単一のステートイベントを取得します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events/:resource_state_event_id
```

パラメータは以下のとおりです:

| 属性                     | 型           | 必須 | 説明                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | 整数        | はい      | マージリクエストのIID                                                      |
| `resource_state_event_id`     | 整数        | はい      | ステートイベントのID                                                     |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events/120"
```

レスポンス例: 

```json
{
  "id": 120,
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
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```

## エピック {#epics}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97554)されました。

{{< /history >}}

> [!warning]
> エピックREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)になり、APIのv5で削除される予定です。GitLab 17.4から18.0までのバージョンで、[エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合は、GitLab 18.1以降で、代わりに作業アイテムAPIを使用してください。詳細については、[作業アイテムにエピックAPIを移行する](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

### グループエピックステートイベントを一覧表示 {#list-group-epic-state-events}

単一のエピックのすべてのステートイベントを一覧表示します。

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events
```

| 属性   | 型           | 必須 | 説明                                                                    |
|-------------| -------------- | -------- |--------------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。   |
| `epic_id`   | 整数        | はい      | エピックのID。                                                              |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events"
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
    "resource_type": "Epic",
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_type": "Epic",
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### 単一のエピックステートイベントを取得する {#retrieve-a-single-epic-state-event}

単一のエピックステートイベントを取得します。

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events/:resource_state_event_id
```

パラメータは以下のとおりです:

| 属性                 | 型           | 必須 | 説明                                                                   |
|---------------------------| -------------- | -------- |-------------------------------------------------------------------------------|
| `id`                      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `epic_id`                 | 整数        | はい      | エピックのID。                                                           |
| `resource_state_event_id` | 整数        | はい      | ステートイベントのID。                                                       |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events/143"
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
  "resource_type": "Epic",
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```
