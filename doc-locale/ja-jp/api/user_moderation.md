---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーモデレーションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、ユーザーアカウントをモデレートします。詳細については、[ユーザーのモデレート](../administration/moderate_users.md)を参照してください。

## ユーザーへのアクセスを承認 {#approve-access-to-a-user}

承認待ちの特定のユーザーアカウントへのアクセスを承認します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/approve
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/approve"
```

戻り値:

- 成功した場合は`201 Created`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `403 Forbidden`管理者またはLDAP同期によってブロックされているため、ユーザーを承認できない場合。
- `409 Conflict`ユーザーが無効になっている場合。

レスポンス例:

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "The user you are trying to approve is not pending approval" }
```

## ユーザーへのアクセスを拒否 {#reject-access-to-a-user}

承認待ちの特定のユーザーアカウントへのアクセスを拒否します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/reject
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/reject"
```

戻り値:

- 成功した場合は`200 OK`。
- 管理者として認証されていない場合は`403 Forbidden`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `409 Conflict`ユーザーが承認待ちでない場合。

レスポンス例:

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "User does not have a pending request" }
```

## ユーザーを非アクティブ化 {#deactivate-a-user}

特定のユーザーアカウントを非アクティブ化します。BANされたユーザーの詳細については、[ユーザーのアクティブ化と非アクティブ化](../administration/moderate_users.md#deactivate-and-reactivate-users)を参照してください。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/deactivate
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/deactivate"
```

戻り値:

- 成功した場合は`201 OK`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `403 Forbidden`次のユーザーを非アクティブ化しようとした場合:
  - 管理者またはLDAP同期によってブロックされています。
  - [休止状態](../administration/moderate_users.md#automatically-deactivate-dormant-users)ではありません。
  - 内部。

## ユーザーを再アクティブ化 {#reactivate-a-user}

以前に非アクティブ化された特定のユーザーアカウントを再アクティブ化します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/activate
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/activate"
```

戻り値:

- 成功した場合は`201 OK`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `403 Forbidden`管理者またはLDAP同期によってブロックされているため、ユーザーをアクティブ化できない場合。

## ユーザーへのアクセスをブロック {#block-access-to-a-user}

特定のユーザーアカウントをブロックします。BANされたユーザーの詳細については、[ブロックとブロックの解除](../administration/moderate_users.md#block-and-unblock-users)を参照してください。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/block
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/block"
```

戻り値:

- 成功した場合は`201 OK`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `403 Forbidden`ブロックしようとした場合:
  - LDAP経由でブロックされているユーザー。
  - 内部ユーザー。

## ユーザーへのアクセスをブロック解除 {#unblock-access-to-a-user}

以前にブロックされた特定のユーザーアカウントのブロックを解除します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/unblock
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/unblock"
```

戻り値:

- 成功した場合は`201 OK`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `403 Forbidden` LDAP同期によってブロックされたユーザーのブロックを解除しようとした場合。

## ユーザーをBAN {#ban-a-user}

特定のユーザーアカウントをBANします。BANされたユーザーの詳細については、[BANとBAN解除](../administration/moderate_users.md#ban-and-unban-users)を参照してください。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/ban
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/ban"
```

戻り値:

- 成功した場合は`201 OK`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `403 Forbidden`アクティブでないユーザーをBANしようとした場合。

## ユーザーのBANを解除 {#unban-a-user}

以前にBANされた特定のユーザーアカウントのBANを解除します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/unban
```

サポートされている属性は以下のとおりです:

| 属性  | 型    | 必須 | 説明        |
|------------|---------|----------|--------------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/unban"
```

戻り値:

- 成功した場合は`201 OK`。
- ユーザーが見つからない場合は`404 User Not Found`。
- `403 Forbidden` BANされていないユーザーのBANを解除しようとした場合。

## 関連トピック {#related-topics}

- [不正行為の報告を確認する](../administration/review_abuse_reports.md)
- [スパムログを確認する](../administration/review_spam_logs.md)
