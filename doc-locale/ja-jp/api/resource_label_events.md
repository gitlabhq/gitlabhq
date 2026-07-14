---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: リソースラベルイベントAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、イシュー、マージリクエスト、またはエピックにいつ誰がどの[ラベル](../user/project/labels.md)を追加または削除したかを示すリソースラベルイベントを取得することができます。

## イシュー {#issues}

### プロジェクトイシューラベルイベントをリスト表示 {#list-project-issue-label-events}

単一のイシューのすべてのラベルイベントをリスト表示します。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events
```

| 属性           | 型             | 必須   | 説明  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid`         | 整数          | はい        | イシューのIID |

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
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
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
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "remove"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events"
```

### 単一のイシューラベルイベントを取得する {#retrieve-a-single-issue-label-event}

特定のプロジェクトイシューの単一のラベルイベントを取得する。

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events/:resource_label_event_id
```

パラメータは以下のとおりです:

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid`     | 整数        | はい      | イシューのIID |
| `resource_label_event_id` | 整数        | はい      | ラベルイベントのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events/1"
```

## エピック {#epics}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> エピックのREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)となり、APIのv5で削除される予定です。GitLab 17.4から18.0までのバージョンで、[エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合は、GitLab 18.1以降で、代わりに作業アイテムAPIを使用してください。詳細については、[作業アイテムにエピックAPIを移行する](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

### グループエピックラベルイベントをリスト表示 {#list-group-epic-label-events}

単一のエピックのすべてのラベルイベントをリスト表示します。

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events
```

| 属性           | 型             | 必須   | 説明  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `epic_id`           | 整数          | はい        | エピックのID |

```json
[
  {
    "id": 106,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
    },
    "action": "add"
  },
  {
    "id": 107,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 37,
      "name": "glabel2",
      "color": "#A8D695",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events"
```

### 単一のエピックラベルイベントを取得する {#retrieve-a-single-epic-label-event}

特定のグループエピックの単一のラベルイベントを取得する。

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events/:resource_label_event_id
```

パラメータは以下のとおりです:

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `epic_id`       | 整数        | はい      | エピックのID |
| `resource_label_event_id` | 整数        | はい      | ラベルイベントのID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events/107"
```

## マージリクエスト {#merge-requests}

### プロジェクトマージリクエストラベルイベントをリスト表示 {#list-project-merge-request-label-events}

単一のマージリクエストのすべてのラベルイベントをリスト表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events
```

| 属性           | 型             | 必須   | 説明  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数          | はい        | マージリクエストのIID |

```json
[
  {
    "id": 119,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "add"
  },
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
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 41,
      "name": "project",
      "color": "#D1D100",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events"
```

### 単一のマージリクエストラベルイベントを取得する {#retrieve-a-single-merge-request-label-event}

特定のプロジェクトマージリクエストの単一のラベルイベントを取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events/:resource_label_event_id
```

パラメータは以下のとおりです:

| 属性           | 型           | 必須 | 説明 |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数        | はい      | マージリクエストのIID |
| `resource_label_event_id`     | 整数        | はい      | ラベルイベントのID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events/120"
```
