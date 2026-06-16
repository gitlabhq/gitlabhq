---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab To-DoリストAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

APIを使用して、[To-Do項目](../user/todos.md)を操作します。

## すべてのTo-Do項目を一覧表示 {#list-all-to-do-items}

すべてのTo-Do項目を一覧表示します。フィルターが適用されていない場合、現在のユーザーの保留中のすべてのTo-Do項目が返されます。異なるフィルターにより、ユーザーはリクエストを絞り込むことができます。

```plaintext
GET /todos
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明                                                                                                                                                                                        |
| --------- | ---- | -------- |----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `action` | 文字列 | いいえ | フィルタリングするアクション。`assigned`、`mentioned`、`build_failed`、`marked`、`approval_required`、`unmergeable`、`directly_addressed`、`merge_train_removed`、または`member_access_requested`です。 |
| `author_id` | 整数 | いいえ | 作成者のID                                                                                                                                                                                |
| `project_id` | 整数 | いいえ | プロジェクトのID                                                                                                                                                                                |
| `group_id` | 整数 | いいえ | グループのID                                                                                                                                                                                  |
| `state` | 文字列 | いいえ | To-Do項目の状態。`pending`または`done`のいずれかになります                                                                                                                                     |
| `type` | 文字列 | いいえ | To-Do項目のタイプ。`Issue`、`MergeRequest`、`Commit`、`Epic`、`DesignManagement::Design`、`AlertManagement::Alert`、`Project`、`Namespace`、`Vulnerability`、または`WikiPage::Meta`のいずれかです。  |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/todos"
```

レスポンス例:

```json
[
  {
    "id": 102,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
    },
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "action_name": "marked",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:52:35.225Z",
    "updated_at": "2016-06-17T07:52:35.225Z"
  },
  {
    "id": 98,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
    },
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/craig_rutherford"
    },
    "action_name": "assigned",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:49:24.624Z",
    "updated_at": "2016-06-17T07:49:24.624Z"
  }
]
```

## to-do項目を完了としてマークする {#mark-a-to-do-item-as-done}

現在のユーザーの、指定されたIDを持つ保留中の単一のTo-Do項目を完了としてマークします。完了とマークされたTo-Do項目は応答で返されます。

```plaintext
POST /todos/:id/mark_as_done
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | To-Do項目のID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/todos/130/mark_as_done"
```

レスポンス例:

```json
{
    "id": 102,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
    },
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "action_name": "marked",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "subscribed": true,
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "done",
    "created_at": "2016-06-17T07:52:35.225Z",
    "updated_at": "2016-06-17T07:52:35.225Z"
}
```

## すべてのTo-Do項目を完了としてマークする {#mark-all-to-do-items-as-done}

現在のユーザーの保留中のすべてのTo-Do項目を完了としてマークします。空の応答とともにHTTPステータスコード`204`を返します。

```plaintext
POST /todos/mark_as_done
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/todos/mark_as_done"
```
