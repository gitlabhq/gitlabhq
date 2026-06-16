---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: データベース移行API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123408)されました。

{{< /history >}}

このAPIを使用して、GitLabデータベースの移行を管理します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

## 移行を成功としてマークする {#mark-a-migration-as-successful}

保留中の移行を正常に実行されたものとしてマークし、`db:migrate`タスクによる実行を防ぎます。このAPIを使用して、失敗した移行がスキップしても安全であると判断された後でスキップします。

```plaintext
POST /api/v4/admin/migrations/:version/mark
```

| 属性       | 型           | 必須 | 説明                                                                                                                                                                                      |
|-----------------|----------------|----------|----------------------------------------------------------------------------------|
| `version`       | 整数        | はい      | スキップする移行のバージョンタイムスタンプ                                 |
| `database`      | 文字列         | いいえ       | 移行がスキップされるデータベース名。`main`がデフォルトです。        |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/:version/mark"
```

## 保留中の移行をリストする {#list-pending-migrations}

指定されたデータベースの、保留中の（まだ実行されていない）すべての移行のリストを返します。

```plaintext
GET /api/v4/admin/migrations/pending
```

| 属性       | 型           | 必須 | 説明                                                                      |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------|
| `database`      | 文字列         | いいえ       | クエリするデータベース名。`main`がデフォルトです。                                  |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/pending?database=main"
```

レスポンス例: 

```json
{
  "pending_migrations": [
    {
      "version": 20240101120000,
      "name": "create_users_table",
      "filename": "20240101120000_create_users_table.rb",
      "status": "pending"
    },
    {
      "version": 20240102150000,
      "name": "add_email_to_users",
      "filename": "20240102150000_add_email_to_users.rb",
      "status": "pending"
    }
  ],
  "database": "main",
  "total_pending": 2
}
```
