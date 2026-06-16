---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CDジョブトークンスコープAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)のスコープを操作します。

> [!note]
> CI/CDジョブトークンスコープAPIエンドポイントへのすべてのリクエストは、[認証されている](rest/authentication.md)必要があります。認証済みユーザーは、プロジェクトに対してメンテナーまたはオーナーのロールを持っている必要があります。

## プロジェクトのCI/CDジョブトークンアクセス設定を取得する {#retrieve-the-cicd-job-token-access-settings-for-a-project}

指定されたプロジェクトの[CI/CDジョブトークンアクセス設定](../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)（ジョブトークンスコープ）を取得します。

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
| `inbound_enabled`  | ブール値 | [**認証されたグループとプロジェクト**](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)の設定が許可リストに対して有効になっているかどうかを示します。無効になっている場合、[すべてのプロジェクトがアクセスできます](../ci/jobs/ci_job_token.md#allow-any-project-to-access-your-project)。この値は、許可リストが現在アクティブであるかどうかを示します。これは、[**Enforce job token allowlist**](../administration/settings/continuous_integration.md#enforce-job-token-allowlist)インスタンス設定により`true`になる場合があります。 |
| `outbound_enabled` | ブール値 | このプロジェクトで生成されたCI/CDジョブトークンが他のプロジェクトにアクセスできるかどうかを示します。[非推奨であり、GitLab 18.0で削除される予定です](../update/deprecations.md#cicd-job-token---limit-access-from-your-project-setting-removal)。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope"
```

レスポンス例: 

```json
{
  "inbound_enabled": true,
  "outbound_enabled": false
}
```

## プロジェクトのCI/CDジョブトークンアクセス設定を更新します {#update-the-cicd-job-token-access-settings-for-a-project}

{{< history >}}

- [名称が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)（GitLab 16.3で**Allow access to this project with a CI_JOB_TOKEN**から**Limit access to this project**へ）。
- [名称が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)（GitLab 17.2で**Limit access to this project**から**認証されたグループとプロジェクト**へ）。

{{< /history >}}

指定されたプロジェクトの[**認証されたグループとプロジェクト**の設定](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)（ジョブトークンスコープ）を更新します。

```plaintext
PATCH /projects/:id/job_token_scope
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `enabled` | ブール値           | はい      | ジョブトークンアクセスを許可リストに登録されたプロジェクトのみに制限します。`false`に設定すると、すべてのプロジェクトからのアクセスを許可します。このパラメータは、[**Enforce job token allowlist**](../administration/settings/continuous_integration.md#enforce-job-token-allowlist)インスタンス設定によって上書きされる場合があります。 |

成功した場合、[`204`](rest/troubleshooting.md#status-codes)を返し、レスポンスボディはありません。

もし**Enforce job token allowlist**インスタンス設定が有効で、`enabled`を`false`に設定しようとすると、エラーメッセージとともに[`400`](rest/troubleshooting.md#status-codes)が返されます。

リクエスト例: 

```shell
curl --request PATCH \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "enabled": false }'
```

## CI/CDジョブトークン許可リスト内のすべてのプロジェクトを一覧表示する {#list-all-projects-in-a-cicd-job-token-allowlist}

指定されたプロジェクトの[CI/CDジョブトークン許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)内のすべてのプロジェクトを一覧表示します。

```plaintext
GET /projects/:id/job_token_scope/allowlist
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

このエンドポイントは[オフセットベースのページネーション](rest/_index.md#offset-based-pagination)をサポートしています。

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と、各プロジェクトの限られたフィールドを持つプロジェクトのリストが返されます。

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist"
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

## CI/CDジョブトークン許可リストにプロジェクトを追加する {#add-a-project-to-a-cicd-job-token-allowlist}

指定されたプロジェクトの[CI/CDジョブトークン許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)にプロジェクトを追加します。

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

## CI/CDジョブトークン許可リストからプロジェクトを削除する {#delete-a-project-from-a-cicd-job-token-allowlist}

指定されたプロジェクトの[CI/CDジョブトークン許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)からプロジェクトを削除します。

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

## CI/CDジョブトークン許可リスト内のすべてのグループを一覧表示する {#list-all-groups-in-a-cicd-job-token-allowlist}

指定されたプロジェクトの[CI/CDジョブトークン許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)内のすべてのグループを一覧表示します。

```plaintext
GET /projects/:id/job_token_scope/groups_allowlist
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

このエンドポイントは[オフセットベースのページネーション](rest/_index.md#offset-based-pagination)をサポートしています。

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と、各プロジェクトの限られたフィールドを持つグループのリストが返されます。

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist"
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

## CI/CDジョブトークン許可リストにグループを追加する {#add-a-group-to-a-cicd-job-token-allowlist}

指定されたプロジェクトの[CI/CDジョブトークン許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)にグループを追加します。

```plaintext
POST /projects/:id/job_token_scope/groups_allowlist
```

サポートされている属性は以下のとおりです: 

| 属性         | 型           | 必須 | 説明 |
|-------------------|----------------|----------|-------------|
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_group_id` | 整数        | はい      | CI/CDジョブトークングループ許可リストに追加されたグループのID。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `source_project_id` | 整数 | 更新するCI/CDジョブトークン受信許可リストを含むプロジェクトのID。 |
| `target_group_id`   | 整数 | ソースプロジェクトのグループ許可リストに追加されるグループのID。 |

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

## CI/CDジョブトークン許可リストからグループを削除する {#delete-a-group-from-a-cicd-job-token-allowlist}

指定されたプロジェクトの[CI/CDジョブトークン許可リスト](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)からグループを削除します。

```plaintext
DELETE /projects/:id/job_token_scope/groups_allowlist/:target_group_id
```

サポートされている属性は以下のとおりです: 

| 属性         | 型           | 必須 | 説明 |
|-------------------|----------------|----------|-------------|
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_group_id` | 整数        | はい      | CI/CDジョブトークングループ許可リストから削除されるグループのID。 |

成功した場合、[`204`](rest/troubleshooting.md#status-codes)を返し、レスポンスボディはありません。

リクエスト例: 

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```
