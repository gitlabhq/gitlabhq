---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: トピックAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトのトピックを操作します。詳細については、[プロジェクトトピック](../user/project/project_topics.md)を参照してください。

## トピック一覧 {#list-topics}

関連付けられたプロジェクトの数で順序付けられた、GitLabインスタンス内のプロジェクトのトピックの一覧を返します。

```plaintext
GET /topics
```

サポートされている属性は以下のとおりです:

| 属性          | 型    | 必須               | 説明 |
| ------------------ | ------- | ---------------------- | ----------- |
| `page`             | 整数 | いいえ | 取得するページ。`1`がデフォルトです。                      |
| `per_page`         | 整数 | いいえ | ページごとに返すレコード数。`20`がデフォルトです。 |
| `search`           | 文字列  | いいえ | `name`に対してトピックを検索します。                     |
| `without_projects` | ブール値 | いいえ | 割り当てられたプロジェクトがないトピックに結果を制限します。      |

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

## トピックの取得 {#get-a-topic}

IDでプロジェクトのトピックを取得します。

```plaintext
GET /topics/:id
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須               | 説明         |
| --------- | ------- | ---------------------- | ------------------- |
| `id`      | 整数 | はい | プロジェクトのトピックのID |

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

## トピックに割り当てられたプロジェクトの一覧 {#list-projects-assigned-to-a-topic}

トピックに割り当てられたすべてのプロジェクトを一覧表示するには、[Projects API](projects.md#list-all-projects)を使用します。

```plaintext
GET /projects?topic=<topic_name>
```

## トピックを作成する {#create-a-project-topic}

新しいプロジェクトのトピックを作成します。管理者のみが使用できます。

```plaintext
POST /topics
```

サポートされている属性は以下のとおりです:

| 属性         | 型    | 必須 | 説明                                                                                                                                                                                    |
|-------------------|---------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`            | 文字列  | はい      | Slug (名前)                                                                                                                                                                                    |
| `title`           | 文字列  | はい      | タイトル                                                                                                                                                                                          |
| `avatar`          | ファイル    | いいえ       | アバター                                                                                                                                                                                         |
| `description`     | 文字列  | いいえ       | 説明                                                                                                                                                                                    |
| `organization_id` | 整数 | いいえ       | トピックの組織ID。警告：この引数は実験段階であり、将来変更される可能性があります。組織の詳細については、[Organizations API](organizations.md)を参照してください |

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

## プロジェクトのトピックの更新 {#update-a-project-topic}

プロジェクトのトピックを更新します。管理者のみが使用できます。

```plaintext
PUT /topics/:id
```

サポートされている属性は以下のとおりです:

| 属性     | 型    | 必須 | 説明         |
|---------------|---------|----------|---------------------|
| `id`          | 整数 | はい      | プロジェクトのトピックのID |
| `avatar`      | ファイル    | いいえ       | アバター              |
| `description` | 文字列  | いいえ       | 説明         |
| `name`        | 文字列  | いいえ       | Slug (名前)         |
| `title`       | 文字列  | いいえ       | タイトル               |

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

### トピックアバターのアップロード {#upload-a-topic-avatar}

ファイルシステムからアバターファイルをアップロードするには、`--form`引数を使用します。この引数により、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1" \
    --form "avatar=@/tmp/example.png"
```

### トピックアバターの削除 {#remove-a-topic-avatar}

トピックアバターを削除するには、`avatar`属性に空白値を指定します。

リクエスト例:

```shell
curl --request PUT \
    --data "avatar=" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## トピックを削除 {#delete-a-project-topic}

プロジェクトのトピックを削除するには、管理者である必要があります。プロジェクトのトピックを削除すると、プロジェクトのトピックの割り当ても削除されます。

```plaintext
DELETE /topics/:id
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数 | はい      | プロジェクトのトピックのID |

リクエスト例:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## トピックをマージする {#merge-topics}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95501)されました。

{{< /history >}}

ソーストピックをターゲットトピックにマージするには、管理者である必要があります。トピックをマージすると、ソーストピックが削除され、割り当てられたすべてのプロジェクトがターゲットトピックに移動されます。

```plaintext
POST /topics/merge
```

サポートされている属性は以下のとおりです:

| 属性         | 型    | 必須 | 説明                |
|-------------------|---------|----------|----------------------------|
| `source_topic_id` | 整数 | はい      | ソースプロジェクトのトピックのID |
| `target_topic_id` | 整数 | はい      | ターゲットプロジェクトのトピックのID |

{{< alert type="note" >}}

`source_topic_id`と`target_topic_id`は同じ組織に属している必要があります。

{{< /alert >}}

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
