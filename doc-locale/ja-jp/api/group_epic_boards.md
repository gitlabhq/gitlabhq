---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループエピックボードAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385903)されました。

{{< /history >}}

[グループエピックボード](../user/group/epics/epic_boards.md)へのすべてのAPIコールは、認証されなければなりません。

ユーザーがグループのメンバーではなく、グループがプライベートである場合、そのグループに対する`GET`リクエストの結果として、`404`ステータスコードが返されます。

## グループ内のすべてのエピックボードをリスト表示 {#list-all-epic-boards-in-a-group}

指定されたグループ内のエピックボードをリスト表示します。

```plaintext
GET /groups/:id/epic_boards
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | 認証済みユーザーがアクセスできるグループのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "group epic board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "labels": [
      {
        "id": 1,
        "title": "Board Label",
        "color": "#c21e56",
        "description": "label applied to the epic board",
        "group_id": 5,
        "project_id": null,
        "template": false,
        "text_color": "#FFFFFF",
        "created_at": "2023-01-27T10:40:59.738Z",
        "updated_at": "2023-01-27T10:40:59.738Z"
      }
    ],
    "lists": [
      {
        "id": 1,
        "label": {
          "id": 69,
          "name": "Testing",
          "color": "#F0AD4E",
          "description": null
        },
        "position": 1,
        "list_type": "label"
      },
      {
        "id": 2,
        "label": {
          "id": 70,
          "name": "Ready",
          "color": "#FF0000",
          "description": null
        },
        "position": 2,
        "list_type": "label"
      },
      {
        "id": 3,
        "label": {
          "id": 71,
          "name": "Production",
          "color": "#FF5F00",
          "description": null
        },
        "position": 3,
        "list_type": "label"
      }
    ]
  }
]
```

## 単一のグループエピックボード {#single-group-epic-board}

単一のグループエピックボードを取得します。

```plaintext
GET /groups/:id/epic_boards/:board_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーがアクセスできるグループのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | エピックボードのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards/1"
```

レスポンス例:

```json
  {
    "id": 1,
    "name": "group epic board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "labels": [
      {
        "id": 1,
        "title": "Board Label",
        "color": "#c21e56",
        "description": "label applied to the epic board",
        "group_id": 5,
        "project_id": null,
        "template": false,
        "text_color": "#FFFFFF",
        "created_at": "2023-01-27T10:40:59.738Z",
        "updated_at": "2023-01-27T10:40:59.738Z"
      }
    ],
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "id": 69,
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1,
        "list_type": "label"
      },
      {
        "id" : 2,
        "label" : {
          "id": 70,
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "list_type": "label"
      },
      {
        "id" : 3,
        "label" : {
          "id": 71,
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "list_type": "label"
      }
    ]
  }
```

## グループエピックボードのリストをリスト表示 {#list-group-epic-board-lists}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385904)されました。

{{< /history >}}

エピックボードのリストのリストを取得します。`open`および`closed`リストは含まれません。

```plaintext
GET /groups/:id/epic_boards/:board_id/lists
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーがアクセスできるグループのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | エピックボードのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists"
```

レスポンス例:

```json
[
  {
    "id" : 1,
    "label" : {
      "name" : "Testing",
      "color" : "#F0AD4E",
      "description" : null
    },
    "position" : 1,
    "list_type" : "label",
    "collapsed" : false
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2,
    "list_type" : "label",
    "collapsed" : false
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3,
    "list_type" : "label",
    "collapsed" : false
  }
]
```

## 単一グループエピックボードリスト {#single-group-epic-board-list}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385904)されました。

{{< /history >}}

単一ボードリストを取得します。

```plaintext
GET /groups/:id/epic_boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーがアクセスできるグループのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | エピックボードのID |
| `list_id` | 整数 | はい | エピックボードのリストのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists/1"
```

レスポンス例:

```json
{
  "id" : 1,
  "label" : {
    "name" : "Testing",
    "color" : "#F0AD4E",
    "description" : null
  },
  "position" : 1,
  "list_type" : "label",
  "collapsed" : false
}
```
