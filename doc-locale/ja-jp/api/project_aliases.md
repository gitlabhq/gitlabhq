---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトエイリアスAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[プロジェクトエイリアス](../user/project/working_with_projects.md#project-aliases)を管理します。プロジェクトにエイリアスを作成すると、ユーザーはエイリアスを使用してリポジトリをクローンできます。これは、リポジトリの移行時に役立ちます。

すべてのメソッドには管理者認可が必要です。

## すべてのプロジェクトエイリアスをリスト表示 {#list-all-project-aliases}

すべてのプロジェクトエイリアスのリストを取得します:

```plaintext
GET /project_aliases
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性    | 型    | 説明 |
|--------------|---------|-------------|
| `id`         | 整数 | プロジェクトエイリアスのID。 |
| `name`       | 文字列  | エイリアスの名前。 |
| `project_id` | 整数 | 関連付けられたプロジェクトのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "project_id": 1,
    "name": "gitlab-foss"
  },
  {
    "id": 2,
    "project_id": 2,
    "name": "gitlab"
  }
]
```

## プロジェクトエイリアスを取得する {#retrieve-a-project-alias}

プロジェクトエイリアスの詳細を取得する:

```plaintext
GET /project_aliases/:name
```

サポートされている属性は以下のとおりです: 

| 属性 | 型   | 必須 | 説明           |
|-----------|--------|----------|-----------------------|
| `name`    | 文字列 | はい      | エイリアスの名前。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性    | 型    | 説明 |
|--------------|---------|-------------|
| `id`         | 整数 | プロジェクトエイリアスのID。 |
| `name`       | 文字列  | エイリアスの名前。 |
| `project_id` | 整数 | 関連付けられたプロジェクトのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## プロジェクトエイリアスを作成する {#create-a-project-alias}

プロジェクトに新しいエイリアスを追加します:

```plaintext
POST /project_aliases
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `name`       | 文字列            | はい      | エイリアスの名前。一意である必要があります。 |
| `project_id` | 整数または文字列 | はい      | プロジェクトのIDまたはパス。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性    | 型    | 説明 |
|--------------|---------|-------------|
| `id`         | 整数 | プロジェクトエイリアスのID。 |
| `name`       | 文字列  | エイリアスの名前。 |
| `project_id` | 整数 | 関連付けられたプロジェクトのID。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=1" \
  --form "name=gitlab"
```

プロジェクトパスを使用することもできます:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=gitlab-org/gitlab" \
  --form "name=gitlab"
```

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## プロジェクトエイリアスを削除する {#delete-a-project-alias}

プロジェクトエイリアスを削除します:

```plaintext
DELETE /project_aliases/:name
```

サポートされている属性は以下のとおりです: 

| 属性 | 型   | 必須 | 説明           |
|-----------|--------|----------|-----------------------|
| `name`    | 文字列 | はい      | エイリアスの名前。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```
