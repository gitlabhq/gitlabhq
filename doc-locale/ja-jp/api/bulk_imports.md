---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループとプロジェクトの直接転送APIによる移行
description: "REST APIを使用して、グループとプロジェクトの移行を開始および表示します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[直接転送](../user/group/import/direct_transfer_migrations.md)によりグループとプロジェクトを移行することができます。

前提条件: 

- [直接転送によるグループ移行の前提条件](../user/group/import/direct_transfer_migrations.md#prerequisites)を参照してください。

## グループまたはプロジェクトの移行を開始 {#start-a-group-or-project-migration}

新しいグループまたはプロジェクトの移行を開始します。プロジェクトを移行するには、`entities[project_entity]`を指定します。

```plaintext
POST /bulk_imports
```

| 属性                         | 型    | 必須 | 説明 |
| --------------------------------- | ------- | -------- | ----------- |
| `configuration`                   | ハッシュ    | はい      | ソースのGitLabインスタンス設定。 |
| `configuration[url]`              | 文字列  | はい      | ソースのGitLabインスタンスURL。 |
| `configuration[access_token]`     | 文字列  | はい      | ソースのGitLabインスタンスへのアクセストークン。 |
| `entities`                        | 配列   | はい      | インポートするエンティティのリスト。 |
| `entities[source_type]`           | 文字列  | はい      | ソースエンティティのタイプ。有効な値は`group_entity`と`project_entity`です。 |
| `entities[source_full_path]`      | 文字列  | はい      | インポートするエンティティのソースのフルパス。例: `gitlab-org/gitlab`。 |
| `entities[destination_slug]`      | 文字列  | はい      | エンティティの宛先slug。GitLabは、エンティティへのURLパスとしてslugを使用します。インポートされたエンティティの名前は、ソースエンティティの名前からコピーされ、slugからはコピーされません。 |
| `entities[destination_namespace]` | 文字列  | はい      | エンティティの宛先グループ[ネームスペース](../user/namespace/_index.md)のフルパス。`project_entity`の場合、この値は宛先インスタンス上の既存のグループである必要があります。`group_entity`の場合、この値は宛先インスタンス上の既存のグループ、または宛先インスタンス上にトップレベルグループを作成するための空の文字列`""`（GitLab Self-ManagedおよびGitLab Dedicatedの場合）のいずれかになります。個人のネームスペースはサポートされていません。 |
| `entities[destination_name]`      | 文字列  | いいえ       | 非推奨: 代わりに`destination_slug`を使用してください。エンティティの宛先slug。 |
| `entities[migrate_memberships]`   | ブール値 | いいえ       | ユーザーメンバーシップをインポートします。`true`がデフォルトです。 |
| `entities[migrate_projects]`      | ブール値 | いいえ       | グループのすべてのネストされたプロジェクトもインポートします（`source_type`が`group_entity`の場合）。`true`がデフォルトです。 |

```shell
curl --request POST \
  --url "https://destination-gitlab-instance.example.com/api/v4/bulk_imports" \
  --header "PRIVATE-TOKEN: <your_access_token_for_destination_gitlab_instance>" \
  --header "Content-Type: application/json" \
  --data '{
    "configuration": {
      "url": "https://source-gitlab-instance.example.com",
      "access_token": "<your_access_token_for_source_gitlab_instance>"
    },
    "entities": [
      {
        "source_full_path": "source/full/path",
        "source_type": "group_entity",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination/namespace/path"
      }
    ]
  }'
```

```json
{
  "id": 1,
  "status": "created",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

## すべてのグループまたはプロジェクトの移行を一覧表示 {#list-all-group-or-project-migrations}

すべてのグループまたはプロジェクトの移行を一覧表示します。

```plaintext
GET /bulk_imports
```

| 属性  | 型    | 必須 | 説明                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | 整数 | いいえ       | ページごとに返すレコード数。                                              |
| `page`     | 整数 | いいえ       | 取得するページ。                                                                  |
| `sort`     | 文字列  | いいえ       | 作成日によって`asc`または`desc`の順序でソートされたレコードを返します。デフォルトは`desc`です。 |
| `status`   | 文字列  | いいえ       | インポートステータス。                                                                     |

ステータスは次のいずれかです:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports?per_page=2&page=1"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z",
        "has_failures": false
    },
    {
        "id": 2,
        "status": "started",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:47:36.581Z",
        "updated_at": "2021-06-18T09:47:58.286Z",
        "has_failures": false
    }
]
```

## すべてのグループまたはプロジェクトの移行エンティティを一覧表示 {#list-all-group-or-project-migration-entities}

すべてのグループまたはプロジェクトの移行エンティティを一覧表示します。

```plaintext
GET /bulk_imports/entities
```

| 属性  | 型    | 必須 | 説明                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | 整数 | いいえ       | ページごとに返すレコード数。                                              |
| `page`     | 整数 | いいえ       | 取得するページ。                                                                  |
| `sort`     | 文字列  | いいえ       | 作成日によって`asc`または`desc`の順序でソートされたレコードを返します。デフォルトは`desc`です。 |
| `status`   | 文字列  | いいえ       | インポートステータス。                                                                     |

ステータスは次のいずれかです:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/entities?per_page=2&page=1&status=started"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    },
    {
        "id": 2,
        "bulk_import_id": 2,
        "status": "failed",
        "entity_type": "group",
        "source_full_path": "another_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "another_slug",
        "destination_namespace": "another_namespace",
        "parent_id": null,
        "namespace_id": null,
        "project_id": null,
        "created_at": "2021-06-24T10:40:20.110Z",
        "updated_at": "2021-06-24T10:40:46.590Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": { }
    }
]
```

## グループまたはプロジェクトの移行を取得 {#retrieve-a-group-or-project-migration}

グループまたはプロジェクトの移行の詳細を取得します。

```plaintext
GET /bulk_imports/:id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```

## グループまたはプロジェクトの移行エンティティを一覧表示 {#list-group-or-project-migration-entities}

特定の移行のグループまたはプロジェクトの移行エンティティを一覧表示します。

```plaintext
GET /bulk_imports/:id/entities
```

| 属性  | 型    | 必須 | 説明                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | 整数 | いいえ       | ページごとに返すレコード数。                                              |
| `page`     | 整数 | いいえ       | 取得するページ。                                                                  |
| `sort`     | 文字列  | いいえ       | 作成日によって`asc`または`desc`の順序でソートされたレコードを返します。デフォルトは`desc`です。 |
| `status`   | 文字列  | いいえ       | インポートステータス。                                                                     |

ステータスは次のいずれかです:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities?per_page=2&page=1&status=finished"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": true,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    }
]
```

## グループまたはプロジェクトの移行エンティティを取得 {#retrieve-a-group-or-project-migration-entity}

グループまたはプロジェクトの移行エンティティの詳細を取得します。

```plaintext
GET /bulk_imports/:id/entities/:entity_id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2"
```

```json
{
    "id": 1,
    "bulk_import_id": 1,
    "status": "finished",
    "entity_type": "group",
    "source_full_path": "source_group",
    "destination_full_path": "destination/full_path",
    "destination_name": "destination_slug",
    "destination_slug": "destination_slug",
    "destination_namespace": "destination_path",
    "parent_id": null,
    "namespace_id": 1,
    "project_id": null,
    "created_at": "2021-06-18T09:47:37.390Z",
    "updated_at": "2021-06-18T09:47:51.867Z",
    "failures": [
        {
            "relation": "group",
            "step": "extractor",
            "exception_message": "Error!",
            "exception_class": "Exception",
            "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
            "created_at": "2021-06-24T10:40:46.495Z",
            "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
            "pipeline_step": "extractor"
        }
    ],
    "migrate_projects": true,
    "migrate_memberships": true,
    "has_failures": true,
    "stats": {
        "labels": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        },
        "milestones": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        }
    }
}
```

## 移行エンティティのインポート失敗レコードを一覧表示 {#list-failed-import-records-for-a-migration-entity}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428016)されました。

{{< /history >}}

グループまたはプロジェクトの移行エンティティのインポート失敗レコードを一覧表示します。

```plaintext
GET /bulk_imports/:id/entities/:entity_id/failures
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2/failures"
```

```json
{
  "relation": "issues",
  "exception_message": "Error!",
  "exception_class": "StandardError",
  "correlation_id_value": "06289e4b064329a69de7bb2d7a1b5a97",
  "source_url": "https://gitlab.example/project/full/path/-/issues/1",
  "source_title": "Issue title"
}
```

## 移行をキャンセル {#cancel-a-migration}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438281)されました。

{{< /history >}}

直接転送移行をキャンセルします。

```plaintext
POST /bulk_imports/:id/cancel
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/cancel"
```

```json
{
  "id": 1,
  "status": "canceled",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

返される可能性のある応答のステータスコードは次のとおりです。

| ステータス | 説明                     |
|--------|---------------------------------|
| 200    | 移行が正常にキャンセルされました |
| 401    | 認証されていません                    |
| 403    | 禁止されています                       |
| 404    | 移行が見つかりません             |
| 503    | サービスが利用できません             |
