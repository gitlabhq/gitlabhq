---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのイシューリンクに関するREST APIのドキュメント。
title: イシューリンク 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 単純な「関連」関係は、13.4でGitLab Freeに[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/212329)しました。

{{< /history >}}

## イシュー関係のリスト {#list-issue-relations}

指定されたイシューの[リンクされたイシュー](../user/project/issues/related_issues.md)のリストを、関係の作成日時（昇順）でソートして取得します。イシューは、ユーザー認可に応じてフィルタリングされます。

```plaintext
GET /projects/:id/issues/:issue_iid/links
```

パラメータは以下のとおりです:

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)  |
| `issue_iid` | 整数 | はい      | プロジェクトのイシューの内部ID。 |

```json
[
  {
    "id" : 84,
    "iid" : 14,
    "issue_link_id": 1,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null,
    "link_type": "relates_to",
    "link_created_at": "2016-01-07T12:44:33.959Z",
    "link_updated_at": "2016-01-07T12:44:33.959Z"
  }
]
```

## イシューリンクを取得 {#get-an-issue-link}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88228)されました。

{{< /history >}}

イシューリンクの詳細を取得します。

```plaintext
GET /projects/:id/issues/:issue_iid/links/:issue_link_id
```

サポートされている属性は以下のとおりです:

| 属性       | 型           | 必須               | 説明                                                                 |
|-----------------|----------------|------------------------|-----------------------------------------------------------------------------|
| `id`            | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数        | はい | プロジェクトイシューの内部ID。                                           |
| `issue_link_id` | 整数または文字列 | はい | イシュー関係の                                                |

レスポンスボディの属性:

| 属性      | 型   | 説明                                                                               |
|:---------------|:-------|:------------------------------------------------------------------------------------------|
| `source_issue` | オブジェクト | 関係のソースイシューの詳細。                                          |
| `target_issue` | オブジェクト | 関係のターゲットイシューの詳細。                                          |
| `link_type`    | 文字列 | 関係の種類。使用できる値は、`relates_to`、`blocks`、`is_blocked_by`です。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/84/issues/14/links/1"
```

レスポンス例:

```json
{
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## イシューリンクを作成 {#create-an-issue-link}

2つのイシュー間に双方向の関係を作成します。ユーザーは、成功するために両方のイシューを更新できる必要があります。

```plaintext
POST /projects/:id/issues/:issue_iid/links
```

| 属性           | 型           | 必須 | 説明                          |
|---------------------|----------------|----------|--------------------------------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_iid`         | 整数        | はい      | プロジェクトのイシューの内部ID。 |
| `target_project_id` | 整数または文字列 | はい      | ターゲットプロジェクトのまたは[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)  |
| `target_issue_iid`  | 整数または文字列 | はい      | ターゲットプロジェクトのイシューの内部 |
| `link_type`         | 文字列         | いいえ       | 関係の種類（`relates_to`、`blocks`、`is_blocked_by`）は、`relates_to`がデフォルトです）。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/1/links?target_project_id=5&target_issue_iid=1"
```

レスポンス例:

```json
{
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## イシューリンクを削除 {#delete-an-issue-link}

イシューリンクを削除して、双方向の関係を削除します。

```plaintext
DELETE /projects/:id/issues/:issue_iid/links/:issue_link_id
```

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)  |
| `issue_iid` | 整数 | はい      | プロジェクトのイシューの内部ID。 |
| `issue_link_id` | 整数または文字列 | はい      | イシュー関係の |
| `link_type` | 文字列  | いいえ | 関係の種類（`relates_to`、`blocks`、`is_blocked_by`）は、`relates_to`がデフォルトです。 |

```json
{
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```
