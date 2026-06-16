---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ユーザーモデレーションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用してユーザーアカウントをモデレートします。詳細については、[ユーザーのモデレート](../administration/moderate_users.md)を参照してください。

## ユーザーへのアクセスを承認 {#approve-access-to-a-user}

承認待ちの指定されたユーザーアカウントへのアクセスを承認します。

前提条件: 

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
- `403 Forbidden`は、ユーザーが管理者またはLDAP同期によってブロックされているため承認できない場合です。
- ユーザーが無効化されている場合は`409 Conflict`です。

応答例:

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

承認待ちの指定されたユーザーアカウントへのアクセスを拒否します。

前提条件: 

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
- ユーザーが承認待ちでない場合は`409 Conflict`です。

応答例:

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "User does not have a pending request" }
```

## ユーザーを無効化 {#deactivate-a-user}

指定されたユーザーアカウントを無効化します。禁止されたユーザーの詳細については、[ユーザーのアクティブ化と非アクティブ化](../administration/moderate_users.md#deactivate-and-reactivate-users)を参照してください。

前提条件: 

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
- 以下のユーザーを非アクティブ化しようとした場合は`403 Forbidden`:
  - 管理者またはLDAP同期によってブロックされている。
  - [休止状態](../administration/moderate_users.md#automatically-deactivate-dormant-users)ではない。
  - 内部ユーザー。

## ユーザーを再アクティブ化 {#reactivate-a-user}

以前に無効化された指定のユーザーアカウントを再アクティブ化します。

前提条件: 

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
- ユーザーが見つからない場合は`404 User Not Found`です。
- `403 Forbidden`は、ユーザーが管理者またはLDAP同期によってブロックされているためアクティブ化できない場合です。

## ユーザーへのアクセスをブロック {#block-access-to-a-user}

指定されたユーザーアカウントをブロックします。禁止されたユーザーの詳細については、[ユーザーをブロックおよびブロック解除](../administration/moderate_users.md#block-and-unblock-users)を参照してください。

前提条件: 

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
- 以下のユーザーをブロックしようとした場合は`403 Forbidden`:
  - LDAP経由でブロックされているユーザー。
  - 内部ユーザー。

## ユーザーへのアクセスをブロック解除 {#unblock-access-to-a-user}

以前にブロックされた指定のユーザーアカウントのブロックを解除します。

前提条件: 

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
- LDAP同期によってブロックされたユーザーのブロック解除を試みた場合は`403 Forbidden`です。

## ユーザーをBAN {#ban-a-user}

指定されたユーザーアカウントをBANします。禁止されたユーザーの詳細については、[ユーザーをBANおよびBAN解除](../administration/moderate_users.md#ban-and-unban-users)を参照してください。

前提条件: 

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
- アクティブではないユーザーをBANしようとした場合は`403 Forbidden`です。

## ユーザーのBANを解除 {#unban-a-user}

以前にBANされた指定のユーザーアカウントのBANを解除します。

前提条件: 

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
- ユーザーが見つからない場合は`404 User Not Found`です。
- BANされていないユーザーのBAN解除を試みた場合は`403 Forbidden`です。

## 関連トピック {#related-topics}

- [不正行為の報告を確認する](../administration/review_abuse_reports.md)
- [スパムログを確認する](../administration/review_spam_logs.md)
