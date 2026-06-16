---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトイシューボードAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[イシューボード](../user/project/issue_board.md)を管理します。このAPIへのすべての呼び出しには認証が必要です。

ユーザーが非公開プロジェクトのメンバーでない場合、そのプロジェクトに対する`GET`リクエストの結果はステータスコード`404`になります。

## すべてのプロジェクトイシューボードをリスト表示 {#list-all-project-issue-boards}

指定されたプロジェクト内のすべてのイシューボードをリスト表示します。

```plaintext
GET /projects/:id/boards
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards"
```

レスポンス例: 

```json
[
  {
    "id" : 1,
    "name": "board1",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
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
        "position" : 1,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric": null
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      }
    ]
  }
]
```

プロジェクトでボードがアクティベートされていないか、存在しない場合の別の応答例:

```json
[]
```

## イシューボードを取得する {#retrieve-an-issue-board}

プロジェクト内の指定されたイシューボードを取得します。

```plaintext
GET /projects/:id/boards/:board_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

レスポンス例: 

```json
  {
    "id": 1,
    "name": "project issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
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
        "position" : 1,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      }
    ]
  }
```

## イシューボードを作成する {#create-an-issue-board}

指定されたプロジェクトにイシューボードを作成します。

```plaintext
POST /projects/:id/boards
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name` | 文字列 | はい | 新しいボードの名前。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards" \
  --data "name=newboard"
```

レスポンス例: 

```json
  {
    "id": 1,
    "name": "newboard",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
    },
    "lists" : [],
    "group": null,
    "milestone": null,
    "assignee" : null,
    "labels" : [],
    "weight" : null
  }
```

## イシューボードを更新する {#update-an-issue-board}

プロジェクト内の指定されたイシューボードを更新します。

```plaintext
PUT /projects/:id/boards/:board_id
```

| 属性                    | 型           | 必須 | 説明 |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id`                   | 整数        | はい      | ボードのID。 |
| `name`                       | 文字列         | いいえ       | 新しいボードの名前。 |
| `hide_backlog_list`          | ブール値        | いいえ       | Openリストを非表示にします。 |
| `hide_closed_list`           | ブール値        | いいえ       | Closedリストを非表示にします。 |
| `assignee_id`                | 整数        | いいえ       | ボードのスコープとする担当者。PremiumおよびUltimateのみです。 |
| `milestone_id`               | 整数        | いいえ       | ボードのスコープとするマイルストーン。PremiumおよびUltimateのみです。 |
| `labels`                     | 文字列         | いいえ       | ボードのスコープとする、コンマ区切りのラベル名リスト。PremiumおよびUltimateのみです。 |
| `weight`                     | 整数        | いいえ       | ボードのスコープとする0から9までのウェイト範囲。PremiumおよびUltimateのみです。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1" \
  --data "name=new_name&milestone_id=43&assignee_id=1&labels=Doing&weight=4"
```

レスポンス例: 

```json
  {
    "id": 1,
    "name": "new_name",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "created_at": "2018-07-03T05:48:49.982Z",
      "default_branch": null,
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "ssh_url_to_repo": "ssh://user@example.com/diaspora/diaspora-project-site.git",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site",
      "readme_url": null,
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "last_activity_at": "2018-07-03T05:48:49.982Z"
    },
    "lists": [],
    "group": null,
    "milestone": {
      "id": 43,
      "iid": 1,
      "project_id": 15,
      "title": "Milestone 1",
      "description": "Milestone 1 desc",
      "state": "active",
      "created_at": "2018-07-03T06:36:42.618Z",
      "updated_at": "2018-07-03T06:36:42.618Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://example.com/root/board1/milestones/1"
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
      "id": 10,
      "name": "Doing",
      "color": "#5CB85C",
      "description": null
    }],
    "weight": 4
  }
```

## イシューボードを削除する {#delete-an-issue-board}

プロジェクト内の指定されたイシューボードを削除します。

```plaintext
DELETE /projects/:id/boards/:board_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

## イシューボード内のすべてのボードリストをリスト表示 {#list-all-board-lists-in-an-issue-board}

指定されたイシューボード内のすべてのリストをリスト表示します。`open`および`closed`リストは含まれません。

```plaintext
GET /projects/:id/boards/:board_id/lists
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists"
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
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2,
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3,
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  }
]
```

## ボードリストを取得する {#retrieve-a-board-list}

イシューボードから指定されたリストを取得します。

```plaintext
GET /projects/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id`| 整数 | はい | ボードリストのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## ボードリストを作成する {#create-a-board-list}

新しいイシューボードリストを作成します。

```plaintext
POST /projects/:id/boards/:board_id/lists
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `label_id` | 整数 | いいえ | ラベルのID。 |
| `assignee_id` | 整数 | いいえ | ユーザーのID。PremiumおよびUltimateのみです。 |
| `milestone_id` | 整数 | いいえ | マイルストーンのID。PremiumおよびUltimateのみです。 |
| `iteration_id` | 整数 | いいえ | イテレーションのID。PremiumおよびUltimateのみです。 |

> [!note]
> ラベル、assignee、およびマイルストーンの引数は相互に排他的であり、リクエストではそのうちの1つのみが受け入れられます。各リストタイプに必要なライセンスに関する詳細は、[イシューボードドキュメント](../user/project/issue_board.md)を確認してください。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists" \
  --data "label_id=5"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## ボードリストを更新する {#update-a-board-list}

イシューボードから指定されたリストの位置を更新します。

```plaintext
PUT /projects/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードリストのID。 |
| `position` | 整数 | はい | リストの位置。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1" \
  --data "position=2"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## ボードからボードリストを削除する {#delete-a-board-list-from-a-board}

イシューボードから指定されたリストを削除します。

前提条件: 

- 次のいずれかの操作を行います:
  - プロジェクトのプランナー、レポーター、セキュリティマネージャー、デベロッパー、メンテナー、またはオーナーロール。
  - 管理者アクセス権が必要です。

```plaintext
DELETE /projects/:id/boards/:board_id/lists/:list_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `board_id` | 整数 | はい | ボードのID。 |
| `list_id` | 整数 | はい | ボードリストのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
```
