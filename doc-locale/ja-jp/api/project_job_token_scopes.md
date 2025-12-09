---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDジョブトークンスコープAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)スコープを操作します。

{{< alert type="note" >}}

CI/CDジョブトークンスコープAPIエンドポイントに対するすべてのリクエストは、[認証](rest/authentication.md)されている必要があります。認証済みユーザーは、プロジェクトのメンテナーロール以上を持っている必要があります。

{{< /alert >}}

## プロジェクトのCI/CDジョブトークンアクセス設定を取得 {#get-a-projects-cicd-job-token-access-settings}

プロジェクトの[CI/CDジョブトークンアクセス設定](../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)（ジョブトークンスコープ）をフェッチします。

```plaintext
GET /projects/:id/job_token_scope
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性          | 型    | 説明 |
|--------------------|---------|-------------|
| `inbound_enabled`  | ブール値 | [**Limit access to this project**設定](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)が有効になっているかどうかを示します。無効になっている場合、[すべてのプロジェクトがアクセスできます](../ci/jobs/ci_job_token.md#allow-any-project-to-access-your-project)。 |
| `outbound_enabled` | ブール値 | このプロジェクトで生成されたCI/CDジョブトークンが、他のプロジェクトへのアクセス権を持っているかどうかを示します。[非推奨となり、GitLab 18.0で削除される予定です。](../update/deprecations.md#cicd-job-token---limit-access-from-your-project-setting-removal) |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/job_token_scope"
```

レスポンス例:

```json
{
  "inbound_enabled": true,
  "outbound_enabled": false
}
```

## プロジェクトのCI/CDジョブトークンアクセス設定にパッチを適用 {#patch-a-projects-cicd-job-token-access-settings}

{{< history >}}

- GitLab 16.3で、**Allow access to this project with a CI_JOB_TOKEN**（CI_JOB_TOKENでこのプロジェクトへのアクセスを許可する）から**Limit access to this project**（このプロジェクトへのアクセスを制限）に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)されました。
- GitLab 17.2で名前が「**Limit access to this project**」から「**Authorized groups and projects**」に[名称変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)。

{{< /history >}}

プロジェクトの[**認証されたグループとプロジェクト**設定](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)（ジョブトークンスコープ）にパッチを適用します。

```plaintext
PATCH /projects/:id/job_token_scope
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `enabled` | ブール値        | はい      | 選択する[**認証されたグループとプロジェクト**設定](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)の状態。`true`に設定すると、**This project and any groups and projects in the allowlist**（このプロジェクトと許可リスト内のすべてのグループとプロジェクト）オプションが選択され、`false`に設定すると、**全グループとプロジェクト**が選択されます。 |

成功した場合、[`204`](rest/troubleshooting.md#status-codes)を返し、レスポンスボディはありません。

リクエスト例:

```shell
curl --request PATCH \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "enabled": false }'
```

## プロジェクトのCI/CDジョブトークン受信許可リストを取得 {#get-a-projects-cicd-job-token-inbound-allowlist}

プロジェクトの[CI/CDジョブトークン受信許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)（ジョブトークンスコープ）をフェッチします。

```plaintext
GET /projects/:id/job_token_scope/allowlist
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

このエンドポイントは、[オフセットベースのページネーション](rest/_index.md#offset-based-pagination)をサポートしています。

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と、プロジェクトごとに制限されたフィールドを持つプロジェクトのリストを返します。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist"
```

レスポンス例:

```json
[
  {
    "id": 4,
    "description": null,
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "star_count": 0,
    "last_activity_at": "2013-09-30T13:46:02Z",
    "namespace": {
      "id": 2,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/diaspora"
    }
  },
  {
    ...
  }
```

## CI/CDジョブトークン受信許可リストにプロジェクトを追加 {#add-a-project-to-a-cicd-job-token-inbound-allowlist}

プロジェクトの[CI/CDジョブトークン受信許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)にプロジェクトを追加します。

```plaintext
POST /projects/:id/job_token_scope/allowlist
```

サポートされている属性は以下のとおりです:

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_project_id` | 整数        | はい      | CI/CDジョブトークン受信許可リストに追加されたプロジェクトのID。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `source_project_id` | 整数 | 更新するCI/CDジョブトークン受信許可リストを含むプロジェクトのID。 |
| `target_project_id` | 整数 | ソースプロジェクトの受信許可リストに追加されるプロジェクトのID。 |

リクエスト例:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_project_id": 2 }'
```

レスポンス例:

```json
{
  "source_project_id": 1,
  "target_project_id": 2
}
```

## CI/CDジョブトークン受信許可リストからプロジェクトを削除 {#remove-a-project-from-a-cicd-job-token-inbound-allowlist}

プロジェクトの[CI/CDジョブトークン受信許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)からプロジェクトを削除します。

```plaintext
DELETE /projects/:id/job_token_scope/allowlist/:target_project_id
```

サポートされている属性は以下のとおりです:

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_project_id` | 整数        | はい      | CI/CDジョブトークン受信許可リストから削除されるプロジェクトのID。 |

成功した場合、[`204`](rest/troubleshooting.md#status-codes)を返し、レスポンスボディはありません。

リクエスト例:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```

## グループのプロジェクトのCI/CDジョブトークン許可リストを取得 {#get-a-projects-cicd-job-token-allowlist-of-groups}

プロジェクトのグループのCI/CDジョブトークン許可リスト（ジョブトークンスコープ）をフェッチします。

```plaintext
GET /projects/:id/job_token_scope/groups_allowlist
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

このエンドポイントは、[オフセットベースのページネーション](rest/_index.md#offset-based-pagination)をサポートしています。

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と、プロジェクトごとに制限されたフィールドを持つグループのリストを返します。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist"
```

レスポンス例:

```json
[
  {
    "id": 4,
    "web_url": "https://gitlab.example.com/groups/diaspora/diaspora-group",
    "name": "namegroup"
  },
  {
    ...
  }
]
```

## CI/CDジョブトークン許可リストにグループを追加 {#add-a-group-to-a-cicd-job-token-allowlist}

プロジェクトのCI/CDジョブトークン許可リストにグループを追加します。

```plaintext
POST /projects/:id/job_token_scope/groups_allowlist
```

サポートされている属性は以下のとおりです:

| 属性         | 型           | 必須 | 説明 |
|-------------------|----------------|----------|-------------|
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_group_id` | 整数        | はい      | CI/CDジョブトークングループの許可リストに追加されたグループのID。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `source_project_id` | 整数 | 更新するCI/CDジョブトークン受信許可リストを含むプロジェクトのID。 |
| `target_group_id`   | 整数 | ソースプロジェクトのグループの許可リストに追加されるグループのID。 |

リクエスト例:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_group_id": 2 }'
```

レスポンス例:

```json
{
  "source_project_id": 1,
  "target_group_id": 2
}
```

## CI/CDジョブトークン許可リストからグループを削除 {#remove-a-group-from-a-cicd-job-token-allowlist}

プロジェクトのCI/CDジョブトークン許可リストからグループを削除します。

```plaintext
DELETE /projects/:id/job_token_scope/groups_allowlist/:target_group_id
```

サポートされている属性は以下のとおりです:

| 属性         | 型           | 必須 | 説明 |
|-------------------|----------------|----------|-------------|
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_group_id` | 整数        | はい      | CI/CDジョブトークングループの許可リストから削除されるグループのID。 |

成功した場合、[`204`](rest/troubleshooting.md#status-codes)を返し、レスポンスボディはありません。

リクエスト例:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```
