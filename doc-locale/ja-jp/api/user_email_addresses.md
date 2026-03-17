---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ユーザーメールアドレスAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーアカウントのメールアドレスとやり取りするために、このAPIを使用します。詳細については、[ユーザーアカウント](../user/profile/_index.md)を参照してください。

## すべてのメールアドレスをリスト表示 {#list-all-email-addresses}

ユーザーアカウントのすべてのメールアドレスをリスト表示します。

前提条件: 

- 認証済みである必要があります。

```plaintext
GET /user/emails
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "email": "email@example.com",
    "confirmed_at" : "2021-03-26T19:07:56.248Z"
  },
  {
    "id": 3,
    "email": "email2@example.com",
    "confirmed_at" : null
  }
]
```

## ユーザーのすべてのメールアドレスをリスト表示 {#list-all-email-addresses-for-a-user}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定したユーザーアカウントのすべてのメールアドレスをリスト表示します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
GET /users/:id/emails
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |

## メールアドレスの詳細を取得する {#retrieve-details-on-an-email-address}

ユーザーアカウントの指定したメールアドレスの詳細を取得します。

```plaintext
GET /user/emails/:email_id
```

サポートされている属性は以下のとおりです: 

| 属性  | 型    | 必須 | 説明 |
|:-----------|:--------|:---------|:------------|
| `email_id` | 整数 | はい      | メールアドレスのID |

レスポンス例: 

```json
{
  "id": 1,
  "email": "email@example.com",
  "confirmed_at" : "2021-03-26T19:07:56.248Z"
}
```

## メールアドレスを追加 {#add-an-email-address}

ユーザーアカウントにメールアドレスを追加します。

```plaintext
POST /user/emails
```

サポートされている属性は以下のとおりです: 

| 属性 | 型   | 必須 | 説明 |
|:----------|:-------|:---------|:------------|
| `email`   | 文字列 | はい      | メールアドレス |

```json
{
  "id": 4,
  "email": "email@example.com",
  "confirmed_at" : "2021-03-26T19:07:56.248Z"
}
```

成功した場合、ステータス`201 Created`のメールが作成され返されます。エラーが発生した場合は、エラーを説明するメッセージとともに`400 Bad Request`が返されます:

```json
{
  "message": {
    "email": [
      "has already been taken"
    ]
  }
}
```

## ユーザーのメールアドレスを追加 {#add-an-email-address-for-a-user}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定したユーザーアカウントにメールアドレスを追加します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/emails
```

サポートされている属性は以下のとおりです: 

| 属性           | 型    | 必須 | 説明 |
|:--------------------|:--------|:---------|:------------|
| `id`                | 文字列  | はい      | ユーザーアカウントのID|
| `email`             | 文字列  | はい      | メールアドレス |
| `skip_confirmation` | ブール値 | いいえ       | 確認をスキップし、メールが検証済みであると仮定します。可能な値: `true`, `false`。デフォルト値: `false`。 |

## メールアドレスを削除 {#delete-an-email-address}

ユーザーアカウントのメールアドレスを削除します。プライマリメールアドレスは削除できません。

削除されたメールアドレスに送信される将来のメールは、代わりにプライマリメールアドレスに送信されます。

前提条件: 

- 認証済みである必要があります。

```plaintext
DELETE /user/emails/:email_id
```

サポートされている属性は以下のとおりです: 

| 属性  | 型    | 必須 | 説明 |
|:-----------|:--------|:---------|:------------|
| `email_id` | 整数 | はい      | メールアドレスのID |

戻り値:

- 操作が成功した場合の`204 No Content`。
- リソースが見つからなかった場合は`404`。

## ユーザーのメールアドレスを削除 {#delete-an-email-address-for-a-user}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定したユーザーアカウントのメールアドレスを削除します。プライマリメールアドレスは削除できません。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
DELETE /users/:id/emails/:email_id
```

サポートされている属性は以下のとおりです: 

| 属性  | 型    | 必須 | 説明 |
|:-----------|:--------|:---------|:------------|
| `id`       | 整数 | はい      | ユーザーアカウントのID |
| `email_id` | 整数 | はい      | メールアドレスのID |
