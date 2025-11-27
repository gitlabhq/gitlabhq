---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リソースグループAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[resource groups](../ci/resource_groups/_index.md)を操作します。

## プロジェクトのすべてのresource groupsを取得します {#get-all-resource-groups-for-a-project}

```plaintext
GET /projects/:id/resource_groups
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数または文字列     | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/resource_groups"
```

レスポンス例

```json
[
  {
    "id": 3,
    "key": "production",
    "process_mode": "unordered",
    "created_at": "2021-09-01T08:04:59.650Z",
    "updated_at": "2021-09-01T08:04:59.650Z"
  }
]
```

## 特定のリソースグループを取得します {#get-a-specific-resource-group}

```plaintext
GET /projects/:id/resource_groups/:key
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数または文字列     | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`     | 文字列  | はい      | URLエンコードされたキーのリソースグループ。たとえば、`resource%5Fa`の代わりに`resource_a`を使用します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

レスポンス例

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "unordered",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:04:59.650Z"
}
```

## 特定のリソースグループの現在のジョブを取得します {#get-current-job-for-a-specific-resource-group}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/572135) GitLab 18.6。

{{< /history >}}

```plaintext
GET /projects/:id/resource_groups/:key/current_job
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数または文字列     | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`     | 文字列  | はい      | URLエンコードされたキーのリソースグループ。たとえば、`resource%5Fa`の代わりに`resource_a`を使用します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/50/resource_groups/production/current_job"
```

レスポンス例

```json
{
  "id": 1154,
  "status": "waiting_for_resource",
  "stage": "deploy",
  "name": "deploy_to_production",
  "ref": "main",
  "tag": false,
  "coverage": null,
  "allow_failure": false,
  "created_at": "2022-09-28T09:57:04.590Z",
  "started_at": null,
  "finished_at": null,
  "duration": null,
  "queued_duration": null,
  "user": {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/2d691a4d0427ca8db6efc3924a6408ba?s=80\u0026d=identicon",
    "web_url": "http://gitlab.example.com/john_smith",
    "created_at": "2022-05-27T19:19:17.526Z",
    "bio": "",
    "location": null,
    "public_email": null,
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null
  },
  "commit": {
    "id": "3177f39064891bbbf5124b27850c339da331f02f",
    "short_id": "3177f390",
    "created_at": "2022-09-27T17:55:31.000+02:00",
    "parent_ids": [
      "18059e45a16eaaeaddf6fc0daf061481549a89df"
    ],
    "title": "List upcoming jobs",
    "message": "List upcoming jobs",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2022-09-27T17:55:31.000+02:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2022-09-27T17:55:31.000+02:00",
    "trailers": {},
    "web_url": "https://gitlab.example.com/test/gitlab/-/commit/3177f39064891bbbf5124b27850c339da331f02f"
  },
  "pipeline": {
    "id": 274,
    "iid": 9,
    "project_id": 50,
    "sha": "3177f39064891bbbf5124b27850c339da331f02f",
    "ref": "main",
    "status": "waiting_for_resource",
    "source": "web",
    "created_at": "2022-09-28T09:57:04.538Z",
    "updated_at": "2022-09-28T09:57:13.537Z",
    "web_url": "https://gitlab.example.com/test/gitlab/-/pipelines/274"
  },
  "web_url": "https://gitlab.example.com/test/gitlab/-/jobs/1154",
  "project": {
    "ci_job_token_scope_enabled": false
  }
}
```

## 特定のリソースグループの今後のジョブを一覧表示します {#list-upcoming-jobs-for-a-specific-resource-group}

```plaintext
GET /projects/:id/resource_groups/:key/upcoming_jobs
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数または文字列     | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`     | 文字列  | はい      | URLエンコードされたキーのリソースグループ。たとえば、`resource%5Fa`の代わりに`resource_a`を使用します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/50/resource_groups/production/upcoming_jobs"
```

レスポンス例

```json
[
  {
    "id": 1154,
    "status": "waiting_for_resource",
    "stage": "deploy",
    "name": "deploy_to_production",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "allow_failure": false,
    "created_at": "2022-09-28T09:57:04.590Z",
    "started_at": null,
    "finished_at": null,
    "duration": null,
    "queued_duration": null,
    "user": {
      "id": 1,
      "username": "john_smith",
      "name": "John Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/2d691a4d0427ca8db6efc3924a6408ba?s=80\u0026d=identicon",
      "web_url": "http://gitlab.example.com/john_smith",
      "created_at": "2022-05-27T19:19:17.526Z",
      "bio": "",
      "location": null,
      "public_email": null,
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": null,
      "job_title": "",
      "pronouns": null,
      "bot": false,
      "work_information": null,
      "followers": 0,
      "following": 0,
      "local_time": null
    },
    "commit": {
      "id": "3177f39064891bbbf5124b27850c339da331f02f",
      "short_id": "3177f390",
      "created_at": "2022-09-27T17:55:31.000+02:00",
      "parent_ids": [
        "18059e45a16eaaeaddf6fc0daf061481549a89df"
      ],
      "title": "List upcoming jobs",
      "message": "List upcoming jobs",
      "author_name": "Example User",
      "author_email": "user@example.com",
      "authored_date": "2022-09-27T17:55:31.000+02:00",
      "committer_name": "Example User",
      "committer_email": "user@example.com",
      "committed_date": "2022-09-27T17:55:31.000+02:00",
      "trailers": {},
      "web_url": "https://gitlab.example.com/test/gitlab/-/commit/3177f39064891bbbf5124b27850c339da331f02f"
    },
    "pipeline": {
      "id": 274,
      "iid": 9,
      "project_id": 50,
      "sha": "3177f39064891bbbf5124b27850c339da331f02f",
      "ref": "main",
      "status": "waiting_for_resource",
      "source": "web",
      "created_at": "2022-09-28T09:57:04.538Z",
      "updated_at": "2022-09-28T09:57:13.537Z",
      "web_url": "https://gitlab.example.com/test/gitlab/-/pipelines/274"
    },
    "web_url": "https://gitlab.example.com/test/gitlab/-/jobs/1154",
    "project": {
      "ci_job_token_scope_enabled": false
    }
  }
]
```

## 既存のresource groupsを編集します {#edit-an-existing-resource-group}

既存のresource groupsのプロパティを更新します。

resource groupsが正常に更新された場合は、`200`が返されます。エラーが発生した場合は、ステータスコード`400`が返されます。

```plaintext
PUT /projects/:id/resource_groups/:key
```

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`          | 文字列            | はい      | URLエンコードされたキーのリソースグループ。たとえば、`resource%5Fa`の代わりに`resource_a`を使用します。 |
| `process_mode` | 文字列            | いいえ       | resource groupsの処理モード。`unordered`、`oldest_first`、`newest_first`、`newest_ready_first`のいずれかです。詳細については、[process modes](../ci/resource_groups/_index.md#process-modes)をお読みください。 |

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "process_mode=oldest_first" \
     --url "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

レスポンス例:

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "oldest_first",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:13:38.679Z"
}
```
