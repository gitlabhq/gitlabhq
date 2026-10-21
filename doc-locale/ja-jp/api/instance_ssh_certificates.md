---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: インスタンスSSH証明書API
description: インスタンスSSH認証局の公開鍵を一覧表示、追加、削除するREST API。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.5で`instance_ssh_certificates`[機能フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/611314)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

このAPIを使用して、インスタンスが信頼するSSH認証局（CA）の公開鍵を管理します。GitLabは各CA公開鍵をデータベースに保存し、インスタンス全体でそれを信頼するため、`sshd_config`や`gitlab-sshd`設定ファイルを変更する代わりに、APIコールでCAをローテーションします。ファイルベースの代替方法については、[インスタンスレベルのSSH証明書（`gitlab-sshd`を使用）](../administration/operations/gitlab_sshd_ssh_certificates.md)を参照してください。

`key`属性には、秘密鍵や署名済みユーザー証明書ではなく、CA公開鍵が含まれます。

## 認証と可用性 {#authentication-and-availability}

すべてのエンドポイントでは、[REST API](rest/authentication.md)で認証された管理者が必要です。インスタンスで管理者モードが有効になっている場合、既存の[管理者モードの要件](../administration/settings/sign_in_restrictions.md#admin-mode)が適用され、個人アクセストークンまたはOAuthトークンの`admin_mode`スコープも含まれます。

GitLabは、機能の可用性を確認する前に、認証と管理者アクセスを確認します。次のエラーは、機能フラグが無効になっている場合でも、すべてのエンドポイントに適用されます:

| ステータス | 説明 |
|--------|-------------|
| `401 Unauthorized` | リクエストが認証されていません。 |
| `403 Forbidden` | 認証済みユーザーが管理者アクセス権を持っていません。 |
| `404 Not Found` | ユーザーは管理者アクセス権を持っていますが、機能が利用できません。 |

## すべてのインスタンスSSH証明書を一覧表示する {#list-all-instance-ssh-certificates}

すべてのインスタンスSSH CA公開鍵レコードをID降順で一覧表示します。

```plaintext
GET /admin/ssh_certificates
```

このエンドポイントは、標準の[ページネーション](rest/_index.md#offset-based-pagination)をサポートしています。

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `page` | 整数 | いいえ | 取得するページ。デフォルト: `1`。 |
| `per_page` | 整数 | いいえ | ページごとのレコード数。デフォルト: `20`。最大: `100`。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と、以下のレスポンス属性を持つオブジェクトの配列を返します:

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `created_at` | 文字列 | レコードが作成された日時（ISO 8601形式）。 |
| `fingerprint` | 文字列 | SSH CA公開鍵のSHA256フィンガープリント。 |
| `id` | 整数 | インスタンスSSH証明書レコードのID。 |
| `key` | 文字列 | SSH CA公開鍵。 |
| `title` | 文字列 | レコードのタイトル。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates?page=1&per_page=20"
```

レスポンス例（`<ca_public_key>`は完全なSSH CA公開鍵を表します）:

```json
[
  {
    "id": 2,
    "title": "Engineering CA",
    "key": "<ca_public_key>",
    "fingerprint": "<ca_public_key_fingerprint>",
    "created_at": "2026-09-08T12:39:00.172Z"
  },
  {
    "id": 1,
    "title": "Operations CA",
    "key": "<ca_public_key>",
    "fingerprint": "<ca_public_key_fingerprint>",
    "created_at": "2026-09-08T11:30:00.000Z"
  }
]
```

結果が空の場合は、`[]`が返されます。

## インスタンスSSH証明書を追加する {#add-an-instance-ssh-certificate}

インスタンスSSH CA公開鍵レコードを追加します。

```plaintext
POST /admin/ssh_certificates
```

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `key` | 文字列 | はい | SSH CA公開鍵。空白にしないでください。最大: 5,000文字。 |
| `title` | 文字列 | はい | レコードのタイトル。空白にしないでください。最大: 255文字。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `created_at` | 文字列 | レコードが作成された日時（ISO 8601形式）。 |
| `fingerprint` | 文字列 | SSH CA公開鍵のSHA256フィンガープリント。 |
| `id` | 整数 | インスタンスSSH証明書レコードのID。 |
| `key` | 文字列 | SSH CA公開鍵。 |
| `title` | 文字列 | レコードのタイトル。 |

CA公開鍵が`/path/to/ca_key.pub`にあるリクエストの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "title=Engineering CA" \
  --data-urlencode "key@/path/to/ca_key.pub" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates"
```

レスポンス例: 

```json
{
  "id": 2,
  "title": "Engineering CA",
  "key": "<ca_public_key>",
  "fingerprint": "<ca_public_key_fingerprint>",
  "created_at": "2026-09-08T12:39:00.172Z"
}
```

共通の認証および可用性エラーに加えて、このエンドポイントは以下を返す場合があります:

| ステータス | 説明 |
|--------|-------------|
| `400 Bad Request` | 必須パラメータが不足しているか、`title`または`key`が最大長を超えています。 |
| `422 Unprocessable Entity` | 値が空か無効です。重複した鍵フィンガープリントの場合、または[SSH鍵の制限](../security/ssh_keys_restrictions.md)もしくは連邦情報処理規格（FIPS）の制限によって拒否された鍵の場合にも返されます。 |

## インスタンスSSH証明書を削除する {#delete-an-instance-ssh-certificate}

指定されたインスタンスSSH CA公開鍵レコードを削除します。

```plaintext
DELETE /admin/ssh_certificates/:id
```

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `id` | 整数 | はい | インスタンスSSH証明書レコードのID。 |

成功した場合は、[`204 No Content`](rest/troubleshooting.md#status-codes)を返し、レスポンス本文は空で、レスポンス属性はありません。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates/2"
```

共通の認証および可用性エラーに加えて、このエンドポイントは以下を返す場合があります:

| ステータス | 説明 |
|--------|-------------|
| `404 Not Found` | 指定されたIDを持つインスタンスSSH証明書レコードがありません。 |
| `422 Unprocessable Entity` | GitLabはレコードを削除できませんでした。 |
