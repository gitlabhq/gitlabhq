---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループイシューボードAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[グループイシューボード](../user/project/issue_board.md#group-issue-boards)へのすべてのAPIコールは、認証を行う必要があります。

ユーザーがグループのメンバーではなく、グループが非公開の場合、そのグループに対する`GET`リクエストの結果として、`404`ステータスコードが返されます。

## グループ内のすべてのグループイシューボードをリストします {#list-all-group-issue-boards-in-a-group}

指定されたグループのイシューボードをリストします。

```plaintext
GET /groups/:id/boards
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
]
```

[GitLab Premium](https://about.gitlab.com/pricing/)またはUltimateのユーザーには、複数のグループボードを持つ機能があるため、異なるパラメータが表示されます。

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
]
```

## 単一グループイシューボード {#single-group-issue-board}

単一グループイシューボードを取得します。

```plaintext
GET /groups/:id/boards/:board_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

レスポンス例:

```json
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、複数のグループイシューボードを持つ機能があるため、異なるパラメータが表示されます。

レスポンス例:

```json
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
```

## グループイシューボードの作成 {#create-a-group-issue-board}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループイシューボードを作成します。

```plaintext
POST /groups/:id/boards
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name` | 文字列 | はい | 新しいボードの名前。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards?name=newboard"
```

レスポンス例:

```json
  {
    "id": 1,
    "name": "newboard",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": null,
    "lists" : [],
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone": null,
    "assignee" : null,
    "labels" : [],
    "weight" : null
  }
```

## グループイシューボードの更新 {#update-a-group-issue-board}

グループイシューボードを更新します。

```plaintext
PUT /groups/:id/boards/:board_id
```

| 属性                    | 型           | 必須 | 説明 |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id`                   | 整数        | はい      | ボードのID。 |
| `name`                       | 文字列         | いいえ       | ボードの新しい名前。 |
| `hide_backlog_list`          | ブール値        | いいえ       | [開く]リストを非表示にします。 |
| `hide_closed_list`           | ブール値        | いいえ       | [閉じる]リストを非表示にします。 |
| `assignee_id`                | 整数        | いいえ       | ボードのスコープを設定する担当者。PremiumおよびUltimateのみです。 |
| `milestone_id`               | 整数        | いいえ       | ボードのスコープを設定するマイルストーン。PremiumおよびUltimateのみです。 |
| `labels`                     | 文字列         | いいえ       | ボードのスコープを設定するラベル名のカンマ区切りリスト。PremiumおよびUltimateのみです。 |
| `weight`                     | 整数        | いいえ       | ボードのスコープを設定する0〜9のウェイト範囲。PremiumおよびUltimateのみです。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1?name=new_name&milestone_id=44&assignee_id=1&labels=GroupLabel&weight=4"
```

レスポンス例:

```json
  {
    "id": 1,
    "name": "new_name",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": null,
    "lists": [],
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone": {
      "id": 44,
      "iid": 1,
      "group_id": 5,
      "title": "Group Milestone",
      "description": "Group Milestone Desc",
      "state": "active",
      "created_at": "2018-07-03T07:15:19.271Z",
      "updated_at": "2018-07-03T07:15:19.271Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://example.com/groups/documentcloud/-/milestones/1"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://example.com/root"
    },
    "labels": [{
      "id": 11,
      "name": "GroupLabel",
      "color": "#428BCA",
      "description": ""
    }],
    "weight": 4
  }
```

## グループイシューボードの削除 {#delete-a-group-issue-board}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループイシューボードを削除します。

```plaintext
DELETE /groups/:id/boards/:board_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

## グループイシューボードリストをリストします {#list-group-issue-board-lists}

ボードのリストのリストを取得します。`open`と`closed`のリストは含まれません

```plaintext
GET /groups/:id/boards/:board_id/lists
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1/lists"
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
    "position" : 1
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3
  }
]
```

## 単一グループイシューボードリスト {#single-group-issue-board-list}

単一ボードリストを取得します。

```plaintext
GET /groups/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードのリストのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
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
  "position" : 1
}
```

## 新規グループイシューボードリスト {#new-group-issue-board-list}

イシューボードリストを作成します。

```plaintext
POST /groups/:id/boards/:board_id/lists
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `label_id` | 整数 | いいえ | ラベルのID。 |
| `assignee_id` | 整数 | いいえ | ユーザーのIDPremiumおよびUltimateのみです。 |
| `milestone_id` | 整数 | いいえ | マイルストーンのID。PremiumおよびUltimateのみです。 |
| `iteration_id` | 整数 | いいえ | イテレーションのID。PremiumおよびUltimateのみです。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/12/lists?milestone_id=7"
```

レスポンス例:

```json
{
  "id": 9,
  "label": null,
  "position": 0,
  "milestone": {
    "id": 7,
    "iid": 3,
    "group_id": 12,
    "title": "Milestone with due date",
    "description": "",
    "state": "active",
    "created_at": "2017-09-03T07:16:28.596Z",
    "updated_at": "2017-09-03T07:16:49.521Z",
    "due_date": null,
    "start_date": null,
    "web_url": "https://gitlab.example.com/groups/issue-reproduce/-/milestones/3"
  }
}
```

## グループイシューボードリストの編集 {#edit-group-issue-board-list}

既存のイシューボードリストを更新します。この呼び出しは、リストの位置を変更するために使用されます。

```plaintext
PUT /groups/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`            | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードのリストのID。 |
| `position` | 整数 | はい | リストの位置 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/group/5/boards/1/lists/1?position=2"
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
  "position" : 1
}
```

## グループイシューボードリストの削除 {#delete-a-group-issue-board-list}

管理者とグループオーナーのみが対象です。問題となっているボードリストを削除します。

```plaintext
DELETE /groups/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードのリストのID。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
```
