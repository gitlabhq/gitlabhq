---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pages API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[GitLab Pages](../user/project/pages/_index.md)を管理するためのエンドポイント。

これらのエンドポイントを使用するには、GitLab Pages機能を有効にする必要があります。この機能の[管理](../administration/pages/_index.md)と[使用](../user/project/pages/_index.md)について、詳細はこちらをご覧ください。

## Pagesの公開を停止 {#unpublish-pages}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/498658)GitLab 17.9で、最小要件ロールが管理者アクセスからメンテナーロールに変更されました

{{< /history >}}

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

Pagesを削除します。

```plaintext
DELETE /projects/:id/pages
```

| 属性 | 型           | 必須 | 説明                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/2/pages"
```

## プロジェクトのPages設定を取得 {#get-pages-settings-for-a-project}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436932)されました。

{{< /history >}}

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

プロジェクトのPages設定を一覧表示します。

```plaintext
GET /projects/:id/pages
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                                 | 型       | 説明                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | 文字列     | このプロジェクトのPagesにアクセスするためのURL。                                                                                            |
| `is_unique_domain_enabled`                | ブール値    | [ユニークドメイン](../user/project/pages/introduction.md)が有効になっている場合。                                                        |
| `force_https`                             | ブール値    | プロジェクトがHTTPSを強制するように設定されている場合は`true`。                                                                                      |
| `deployments[]`                           | 配列      | 現在アクティブなデプロイの一覧。                                                                                          |
| `primary_domain`                          | 文字列     | すべてのPagesリクエストをリダイレクトするプライマリドメイン。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)されました。 |

| `deployments[]`属性                 | 型       | 説明                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | 日付       | デプロイが作成された日付。                                                                                                  |
| `url`                                     | 文字列     | このデプロイのURL。                                                                                                      |
| `path_prefix`                             | 文字列     | [並列デプロイ](../user/project/pages/_index.md#parallel-deployments)を使用する場合の、このデプロイのプレフィックスパス。 |
| `root_directory`                          | 文字列     | ルートディレクトリ。                                                                                                               |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/2/pages"
```

レスポンス例:

```json
{
  "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010",
  "is_unique_domain_enabled": true,
  "force_https": false,
  "deployments": [
    {
      "created_at": "2024-01-05T18:58:14.916Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/",
      "path_prefix": "",
      "root_directory": null
    },
    {
      "created_at": "2024-01-05T18:58:46.042Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/mr3",
      "path_prefix": "mr3",
      "root_directory": null
    }
  ],
  "primary_domain": null
}
```

## プロジェクトのPages設定を更新 {#update-pages-settings-for-a-project}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147227)されました。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/498658)GitLab 17.9で、最小要件ロールが管理者アクセスからメンテナーロールに変更されました

{{< /history >}}

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

プロジェクトのPages設定を更新します。

```plaintext
PATCH /projects/:id/pages
```

サポートされている属性は以下のとおりです:

| 属性                       | 型           | 必須 | 説明                                                                                                         |
| --------------------------------| -------------- | -------- | --------------------------------------------------------------------------------------------------------------------|
| `id`                            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                                 |
| `pages_unique_domain_enabled`   | ブール値        | いいえ       | ユニークドメインを使用するかどうか                                                                                        |
| `pages_https_only`              | ブール値        | いいえ       | HTTPSを強制するかどうか                                                                                              |
| `pages_primary_domain`          | 文字列         | いいえ       | すべてのPagesリクエストをリダイレクトするために、既存の割り当てられたドメインからプライマリドメインを設定します。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)されました。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                                 | 型       | 説明                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | 文字列     | このプロジェクトのPagesにアクセスするためのURL。                                                                                            |
| `is_unique_domain_enabled`                | ブール値    | [ユニークドメイン](../user/project/pages/introduction.md)が有効になっている場合。                                                        |
| `force_https`                             | ブール値    | プロジェクトがHTTPSを強制するように設定されている場合は`true`。                                                                                      |
| `deployments[]`                           | 配列      | 現在アクティブなデプロイの一覧。                                                                                          |
| `primary_domain`                          | 文字列     | すべてのPagesリクエストをリダイレクトするプライマリドメイン。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)されました。 |

| `deployments[]`属性                 | 型       | 説明                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | 日付       | デプロイが作成された日付。                                                                                                  |
| `url`                                     | 文字列     | このデプロイのURL。                                                                                                      |
| `path_prefix`                             | 文字列     | [並列デプロイ](../user/project/pages/_index.md#parallel-deployments)を使用する場合の、このデプロイのプレフィックスパス。 |
| `root_directory`                          | 文字列     | ルートディレクトリ。                                                                                                               |

リクエスト例:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/pages" \
  --form 'pages_unique_domain_enabled=true' \
  --form 'pages_https_only=true' \
  --form 'pages_primary_domain=https://custom.example.com'
```

レスポンス例:

```json
{
  "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010",
  "is_unique_domain_enabled": true,
  "force_https": false,
  "deployments": [
    {
      "created_at": "2024-01-05T18:58:14.916Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/",
      "path_prefix": "",
      "root_directory": null
    },
    {
      "created_at": "2024-01-05T18:58:46.042Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/mr3",
      "path_prefix": "mr3",
      "root_directory": null
    }
  ],
  "primary_domain": null
}
```
