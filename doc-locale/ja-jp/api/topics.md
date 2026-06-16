---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: トピックAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

プロジェクトトピックを操作するためにこのAPIを使用します。詳細については、[プロジェクトトピック](../user/project/project_topics.md)を参照してください。

## すべてのトピックを一覧表示 {#list-all-topics}

GitLabインスタンス内のプロジェクトトピックのリストを、関連するプロジェクトの数でソートして返します。

```plaintext
GET /topics
```

サポートされている属性は以下のとおりです: 

| 属性          | 型    | 必須               | 説明 |
| ------------------ | ------- | ---------------------- | ----------- |
| `page`             | 整数 | いいえ | 取得するページ。`1`がデフォルトです。                      |
| `per_page`         | 整数 | いいえ | ページごとに返すレコード数。`20`がデフォルトです。 |
| `search`           | 文字列  | いいえ | `name`に対してトピックを検索します。                     |
| `without_projects` | ブール値 | いいえ | 結果を、割り当てられたプロジェクトがないトピックに制限します。      |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/topics?search=git"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "gitlab",
    "title": "GitLab",
    "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
    "total_projects_count": 1000,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
  },
  {
    "id": 3,
    "name": "git",
    "title": "Git",
    "description": "Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.",
    "total_projects_count": 900,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
  },
  {
    "id": 2,
    "name": "git-lfs",
    "title": "Git LFS",
    "description": null,
    "total_projects_count": 300,
    "organization_id": 1,
    "avatar_url": null
  }
]
```

## トピックを取得する {#retrieve-a-topic}

IDでプロジェクトトピックを取得します。

```plaintext
GET /topics/:id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須               | 説明         |
| --------- | ------- | ---------------------- | ------------------- |
| `id`      | 整数 | はい | プロジェクトトピックのID |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/topics/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "gitlab",
  "title": "GitLab",
  "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
  "total_projects_count": 1000,
  "organization_id": 1,
  "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
}
```

## トピックに割り当てられたすべてのプロジェクトを一覧表示 {#list-all-projects-assigned-to-a-topic}

[Projects API](projects.md#list-all-projects)を使用して、特定のトピックに割り当てられたすべてのプロジェクトを一覧表示します。

```plaintext
GET /projects?topic=<topic_name>
```

## プロジェクトトピックを作成 {#create-a-project-topic}

新しいプロジェクトトピックを作成します。管理者のみが利用可能です。

```plaintext
POST /topics
```

サポートされている属性は以下のとおりです: 

| 属性         | 型    | 必須 | 説明                                                                                                                                                                                    |
|-------------------|---------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`            | 文字列  | はい      | Slug (名前)                                                                                                                                                                                    |
| `title`           | 文字列  | はい      | Title                                                                                                                                                                                          |
| `avatar`          | ファイル    | いいえ       | アバター                                                                                                                                                                                         |
| `description`     | 文字列  | いいえ       | 説明                                                                                                                                                                                    |
| `organization_id` | 整数 | いいえ       | トピックの組織ID。警告: この属性は実験的なものであり、将来変更される可能性があります。組織に関する詳細については、[Organizations API](organizations.md)を参照してください。 |

リクエスト例: 

```shell
curl --request POST \
    --data "name=topic1&title=Topic 1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

## プロジェクトトピックを更新 {#update-a-project-topic}

プロジェクトトピックを更新します。管理者のみが利用可能です。

```plaintext
PUT /topics/:id
```

サポートされている属性は以下のとおりです: 

| 属性     | 型    | 必須 | 説明         |
|---------------|---------|----------|---------------------|
| `id`          | 整数 | はい      | プロジェクトトピックのID |
| `avatar`      | ファイル    | いいえ       | アバター              |
| `description` | 文字列  | いいえ       | 説明         |
| `name`        | 文字列  | いいえ       | Slug (名前)         |
| `title`       | 文字列  | いいえ       | Title               |

リクエスト例: 

```shell
curl --request PUT \
    --data "name=topic1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

### トピックのアバターをアップロード {#upload-a-topic-avatar}

ファイルシステムからアバターファイルをアップロードするには、`--form`引数を使用します。この引数により、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを投稿します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1" \
    --form "avatar=@/tmp/example.png"
```

### トピックのアバターを削除 {#remove-a-topic-avatar}

トピックのアバターを削除するには、`avatar`属性に空白の値を指定します。

リクエスト例: 

```shell
curl --request PUT \
    --data "avatar=" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## プロジェクトトピックを削除 {#delete-a-project-topic}

プロジェクトトピックを削除するには、管理者である必要があります。プロジェクトトピックを削除すると、プロジェクトのトピックの割り当ても削除されます。

```plaintext
DELETE /topics/:id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数 | はい      | プロジェクトトピックのID |

リクエスト例: 

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## トピックをマージする {#merge-topics}

ソーストピックをターゲットトピックにマージするには、管理者である必要があります。トピックをマージすると、ソーストピックは削除され、割り当てられているすべてのプロジェクトがターゲットトピックに移動します。

```plaintext
POST /topics/merge
```

サポートされている属性は以下のとおりです: 

| 属性         | 型    | 必須 | 説明                |
|-------------------|---------|----------|----------------------------|
| `source_topic_id` | 整数 | はい      | ソースプロジェクトトピックのID |
| `target_topic_id` | 整数 | はい      | ターゲットプロジェクトトピックのID |

> [!note]
> `source_topic_id`と`target_topic_id`は同じ組織に属している必要があります。

リクエスト例: 

```shell
curl --request POST \
    --data "source_topic_id=2&target_topic_id=1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/merge"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```
