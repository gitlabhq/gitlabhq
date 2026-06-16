---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループイシューボードAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[グループイシューボード](../user/project/issue_board.md#group-issue-boards)を管理します。このAPIへのすべての呼び出しには認証が必要です。

ユーザーがグループのメンバーではなく、そのグループがプライベートである場合、`GET`リクエストは`404`ステータスコードになります。

## グループ内のすべてのグループイシューボードをリストします {#list-all-group-issue-boards-in-a-group}

指定されたグループのすべてのグループイシューボードをリストします。

```plaintext
GET /groups/:id/boards
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards"
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

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーは、複数のグループボードを持つことができるため、異なるパラメータが表示されます。

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

## 取得するグループイシューボード {#retrieve-a-group-issue-board}

指定されたグループイシューボードを取得する。

```plaintext
GET /groups/:id/boards/:board_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1"
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

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーは、複数のグループイシューボードを持つことができるため、異なるパラメータが表示されます。

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

## グループイシューボードを作成する {#create-a-group-issue-board}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定されたグループにグループイシューボードを作成します。

```plaintext
POST /groups/:id/boards
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name` | 文字列 | はい | 新しいボードの名前。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards?name=newboard"
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

## グループイシューボードを更新する {#update-a-group-issue-board}

指定されたグループイシューボードを更新します。

```plaintext
PUT /groups/:id/boards/:board_id
```

| 属性                    | 型           | 必須 | 説明 |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id`                   | 整数        | はい      | ボードのID。 |
| `name`                       | 文字列         | いいえ       | ボードの新しい名前。 |
| `hide_backlog_list`          | ブール値        | いいえ       | Openリストを非表示にします。 |
| `hide_closed_list`           | ブール値        | いいえ       | Closedリストを非表示にします。 |
| `assignee_id`                | 整数        | いいえ       | ボードのスコープとするassignee。PremiumおよびUltimateのみです。 |
| `milestone_id`               | 整数        | いいえ       | ボードのスコープとするマイルストーン。PremiumおよびUltimateのみです。 |
| `labels`                     | 文字列         | いいえ       | ボードのスコープとするラベル名のカンマ区切りリスト。PremiumおよびUltimateのみです。 |
| `weight`                     | 整数        | いいえ       | ボードのスコープとする0から9までのウェイト範囲。PremiumおよびUltimateのみです。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1?name=new_name&milestone_id=44&assignee_id=1&labels=GroupLabel&weight=4"
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

## グループイシューボードを削除する {#delete-a-group-issue-board}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定されたグループイシューボードを削除します。

```plaintext
DELETE /groups/:id/boards/:board_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

## グループイシューボードイシューボードリストをリストする {#list-group-issue-board-lists}

指定されたボードのすべてのグループイシューボードイシューボードリストをリストします。`open`と`closed`のリストは含まれません。

```plaintext
GET /groups/:id/boards/:board_id/lists
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists"
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

## 取得するグループイシューボードイシューボードリスト {#retrieve-a-group-issue-board-list}

指定されたグループイシューボードイシューボードリストを取得する。

```plaintext
GET /groups/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードのリストのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
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

## グループイシューボードイシューボードリストを作成する {#create-a-group-issue-board-list}

指定されたボードにグループイシューボードイシューボードリストを作成します。

```plaintext
POST /groups/:id/boards/:board_id/lists
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `label_id` | 整数 | いいえ | ラベルのID。 |
| `assignee_id` | 整数 | いいえ | ユーザーのID。PremiumおよびUltimateのみです。 |
| `milestone_id` | 整数 | いいえ | マイルストーンのID。PremiumおよびUltimateのみです。 |
| `iteration_id` | 整数 | いいえ | イテレーションのID。PremiumおよびUltimateのみです。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/12/lists?milestone_id=7"
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

## グループイシューボードイシューボードリストを更新する {#update-a-group-issue-board-list}

指定されたグループイシューボードイシューボードリストを更新します。この呼び出しはリストの位置を変更するために使用されます。

```plaintext
PUT /groups/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`            | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードのリストのID。 |
| `position` | 整数 | はい | リストの位置。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1?position=2"
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

## グループイシューボードイシューボードリストを削除する {#delete-a-group-issue-board-list}

指定されたグループイシューボードイシューボードリストを削除します。管理者およびグループオーナーのみ。

```plaintext
DELETE /groups/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードのリストのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
```
