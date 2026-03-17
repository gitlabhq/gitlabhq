---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ユーザーSSHおよびGPGキーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、ユーザーのSSHおよびGPGキーを操作します。詳細については、[SSHキー](../user/ssh.md)および[GPGキー](../user/project/repository/signed_commits/gpg.md)を参照してください。

## すべてのSSHキーを一覧表示 {#list-all-ssh-keys}

ユーザーアカウントのすべてのSSHキーを一覧表示します。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

前提条件: 

- 認証済みである必要があります。

```plaintext
GET /user/keys
```

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "auth"
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "signing"
  }
]
```

## ユーザーのすべてのSSHキーを一覧表示 {#list-all-ssh-keys-for-a-user}

指定されたユーザーアカウントのすべてのSSHキーを一覧表示します。このエンドポイントでは認証は不要です。

```plaintext
GET /users/:id_or_username/keys
```

サポートされている属性は以下のとおりです: 

| 属性        | 型   | 必須 | 説明 |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | 文字列 | はい      | ユーザーアカウントのIDまたはユーザー名 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1/keys"
```

## SSHキーを取得する {#retrieve-an-ssh-key}

ユーザーアカウントのSSHキーを取得します。

前提条件: 

- 認証済みである必要があります。

```plaintext
GET /user/keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型   | 必須 | 説明 |
|:----------|:-------|:---------|:------------|
| `key_id`  | 文字列 | はい      | 既存のキーのID |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## ユーザーのSSHキーを取得する {#retrieve-an-ssh-key-for-a-user}

指定されたユーザーアカウントのSSHキーを取得します。このエンドポイントでは認証は不要です。

```plaintext
GET /users/:id/keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのIDまたはユーザー名 |
| `key_id`  | 整数 | はい      | 既存のキーのID  |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/1/keys/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## SSHキーを追加 {#add-an-ssh-key}

{{< history >}}

- `usage_type`パラメータはGitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551)。

{{< /history >}}

ユーザーアカウントにSSHキーを追加します。

前提条件: 

- 認証済みである必要があります。

```plaintext
POST /user/keys
```

サポートされている属性は以下のとおりです: 

| 属性    | 型   | 必須 | 説明 |
|:-------------|:-------|:---------|:------------|
| `title`      | 文字列 | はい      | キーのタイトル |
| `key`        | 文字列 | はい      | 公開キーの値 |
| `expires_at` | 文字列 | いいえ       | キーのISO形式（`YYYY-MM-DD`）での有効期限。 |
| `usage_type` | 文字列 | いいえ       | キーの利用スコープ。指定可能な値: `auth`、`signing`、または`auth_and_signing`。デフォルト値: `auth_and_signing` |

以下を返します:

- 成功した場合は、ステータスが`201 Created`の作成されたキー。
- エラーを説明するメッセージを含む`400 Bad Request`エラー:

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

レスポンス例: 

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## ユーザーのSSHキーを追加 {#add-an-ssh-key-for-a-user}

{{< history >}}

- `usage_type`パラメータはGitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551)。

{{< /history >}}

指定されたユーザーアカウントにSSHキーを追加します。

> [!note]これは監査イベントも追加します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/keys
```

サポートされている属性は以下のとおりです: 

| 属性    | 型    | 必須 | 説明 |
|:-------------|:--------|:---------|:------------|
| `id`         | 整数 | はい      | ユーザーアカウントのID |
| `title`      | 文字列  | はい      | キーのタイトル |
| `key`        | 文字列  | はい      | 公開キーの値  |
| `expires_at` | 文字列  | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。 |
| `usage_type` | 文字列  | いいえ       | キーの利用スコープ。指定可能な値: `auth`、`signing`、または`auth_and_signing`。デフォルト値: `auth_and_signing` |

以下を返します:

- 成功した場合は、ステータスが`201 Created`の作成されたキー。
- エラーを説明するメッセージを含む`400 Bad Request`エラー:

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

レスポンス例: 

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## SSHキーを削除する {#delete-an-ssh-key}

ユーザーアカウントからSSHキーを削除します。

前提条件: 

- 認証済みである必要があります。

```plaintext
DELETE /user/keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `key_id`  | 整数 | はい      | 既存のキーのID  |

以下を返します:

- 操作が成功した場合は`204 No Content`ステータスコード。
- リソースが見つからなかった場合は`404`ステータスコード。

## ユーザーのSSHキーを削除 {#delete-an-ssh-key-for-a-user}

指定されたユーザーアカウントからSSHキーを削除します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
DELETE /users/:id/keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |
| `key_id`  | 整数 | はい      | 既存のキーのID  |

## すべてのGPGキーを一覧表示 {#list-all-gpg-keys}

ユーザーアカウントのすべてのGPGキーを一覧表示します。

前提条件: 

- 認証済みである必要があります。

```plaintext
GET /user/gpg_keys
```

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## ユーザーのすべてのGPGキーを一覧表示 {#list-all-gpg-keys-for-a-user}

指定されたユーザーアカウントのすべてのGPGキーを一覧表示します。このエンドポイントでは認証は不要です。

```plaintext
GET /users/:id/gpg_keys
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## GPGキーを取得する {#retrieve-a-gpg-key}

ユーザーアカウントのGPGキーを取得します。

前提条件: 

- 認証済みである必要があります。

```plaintext
GET /user/gpg_keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `key_id`  | 整数 | はい      | 既存のキーのID |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## ユーザーのGPGキーを取得する {#retrieve-a-gpg-key-for-a-user}

指定されたユーザーアカウントのGPGキーを取得します。このエンドポイントでは認証は不要です。

```plaintext
GET /users/:id/gpg_keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |
| `key_id`  | 整数 | はい      | 既存のキーのID |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## GPGキーを追加 {#add-a-gpg-key}

ユーザーアカウントにGPGキーを追加します。

前提条件: 

- 認証済みである必要があります。

```plaintext
POST /user/gpg_keys
```

サポートされている属性は以下のとおりです: 

| 属性 | 型   | 必須 | 説明 |
|:----------|:-------|:---------|:------------|
| `key`     | 文字列 | はい      | 公開キーの値 |

リクエスト例: 

```shell
export KEY="$(gpg --armor --export <your_gpg_key_id>)"

curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/gpg_keys"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## ユーザーのGPGキーを追加 {#add-a-gpg-key-for-a-user}

指定されたユーザーアカウントにGPGキーを追加します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:id/gpg_keys
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |
| `key`     | 整数 | はい      | 公開キーの値 |

リクエスト例: 

```shell
curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## GPGキーを削除 {#delete-a-gpg-key}

ユーザーアカウントからGPGキーを削除します。

前提条件: 

- 認証済みである必要があります。

```plaintext
DELETE /user/gpg_keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `key_id`  | 整数 | はい      | 既存のキーのID |

以下を返します:

- 成功した場合は`204 No Content`。
- キーが見つからない場合は`404 Not Found`。

## ユーザーのGPGキーを削除 {#delete-a-gpg-key-for-a-user}

指定されたユーザーアカウントからGPGキーを削除します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
DELETE /users/:id/gpg_keys/:key_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |
| `key_id`  | 整数 | はい      | 既存のキーのID |
