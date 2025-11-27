---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pagesドメイン 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

[GitLab Pages](../user/project/pages/_index.md)でカスタムドメインとTLS証明書を接続するためのエンドポイント。

これらのエンドポイントを使用するには、GitLab Pages機能を有効にする必要があります。機能の[管理](../administration/pages/_index.md)と[使用](../user/project/pages/_index.md)に関する詳細をご覧ください。

## すべてのPagesドメインをリスト表示 {#list-all-pages-domains}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

すべてのPagesドメインのリストを取得します。

```plaintext
GET /pages/domains
```

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型            | 説明                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 文字列          | GitLab Pagesサイトのカスタムドメイン名。 |
| `url`               | 文字列          | プロトコルを含む、Pagesサイトの完全なURL。 |
| `project_id`        | 整数         | このPagesドメインに関連付けられているGitLabプロジェクトのID。 |
| `verified`          | ブール値         | ドメインが確認されたかどうかを示します。 |
| `verification_code` | 文字列          | ドメインの所有権を確認するために使用される一意のレコード。 |
| `enabled_until`     | 日付            | ドメインが有効になっている日付。これは、ドメインが再検証されると定期的に更新されます。  |
| `auto_ssl_enabled`  | ブール値         | [自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) SSL証明書（Let's Encryptを使用）が、このドメインに対して有効になっているかどうかを示します。 |
| `certificate_expiration` | オブジェクト | SSL証明書の有効期限に関する情報。 |
| `certificate_expiration.expired` | ブール値 | SSL証明書の有効期限が切れているかどうかを示します。 |
| `certificate_expiration.expiration` | 日付 | SSL証明書の有効期限の日時。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/pages/domains"
```

レスポンス例:

```json
[
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "project_id": 1337,
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
    "certificate": {
      "expired": false,
      "expiration": "2020-04-12T14:32:00.000Z"
    }
  }
]
```

## Pagesドメインをリスト表示 {#list-pages-domains}

プロジェクトのPagesドメインのリストを取得します。ユーザーはPagesドメインを表示するための権限を持っている必要があります。

```plaintext
GET /projects/:id/pages/domains
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型            | 説明                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 文字列          | GitLab Pagesサイトのカスタムドメイン名。 |
| `url`               | 文字列          | プロトコルを含む、Pagesサイトの完全なURL。 |
| `verified`          | ブール値         | ドメインが確認されたかどうかを示します。 |
| `verification_code` | 文字列          | ドメインの所有権を確認するために使用される一意のレコード。 |
| `enabled_until`     | 日付            | ドメインが有効になっている日付。これは、ドメインが再検証されると定期的に更新されます。  |
| `auto_ssl_enabled`  | ブール値         | [自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) SSL証明書（Let's Encryptを使用）が、このドメインに対して有効になっているかどうかを示します。 |
| `certificate` | オブジェクト | SSL証明書に関する情報。 |
| `certificate.subject` | 文字列 | SSL証明書のサブジェクト（通常はドメインに関する情報を含む）。 |
| `certificate.expired` | 日付 | SSL証明書の有効期限が切れている（true）か、まだ有効（false）かを示します。 |
| `certificate.certificate` | 文字列 | PEM形式の完全なSSL証明書。 |
| `certificate.certificate_text` | 日付 | 発行者、有効期間、サブジェクト、その他の証明書情報など、SSL証明書を人間が読める形式で表現したテキスト。  |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

レスポンス例:

```json
[
  {
    "domain": "www.domain.example",
    "url": "http://www.domain.example",
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
  },
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
    "certificate": {
      "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
      "expired": false,
      "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
      "certificate_text": "Certificate:\n … \n"
    }
  }
]
```

## 単一のPagesドメイン {#single-pages-domain}

単一のプロジェクトPagesドメインを取得します。ユーザーはPagesドメインを表示するための権限を持っている必要があります。

```plaintext
GET /projects/:id/pages/domains/:domain
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `domain`  | 文字列         | はい      | ユーザーが指定したカスタムドメイン  |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型            | 説明                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 文字列          | GitLab Pagesサイトのカスタムドメイン名。 |
| `url`               | 文字列          | プロトコルを含む、Pagesサイトの完全なURL。 |
| `verified`          | ブール値         | ドメインが確認されたかどうかを示します。 |
| `verification_code` | 文字列          | ドメインの所有権を確認するために使用される一意のレコード。 |
| `enabled_until`     | 日付            | ドメインが有効になっている日付。これは、ドメインが再検証されると定期的に更新されます。  |
| `auto_ssl_enabled`  | ブール値         | [自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) SSL証明書（Let's Encryptを使用）が、このドメインに対して有効になっているかどうかを示します。 |
| `certificate` | オブジェクト | SSL証明書に関する情報。 |
| `certificate.subject` | 文字列 | SSL証明書のサブジェクト（通常はドメインに関する情報を含む）。 |
| `certificate.expired` | 日付 | SSL証明書の有効期限が切れている（true）か、まだ有効（false）かを示します。 |
| `certificate.certificate` | 文字列 | PEM形式の完全なSSL証明書。 |
| `certificate.certificate_text` | 日付 | 発行者、有効期間、サブジェクト、その他の証明書情報など、SSL証明書を人間が読める形式で表現したテキスト。  |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

レスポンス例:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "verified": true,
  "verification_code": "1234567890abcdef",
  "enabled_until": "2020-04-12T14:32:00.000Z",
  "auto_ssl_enabled": false,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## 新しいPagesドメインを作成 {#create-new-pages-domain}

新しいPagesドメインを作成します。ユーザーは新しいPagesドメインを作成するための権限を持っている必要があります。

```plaintext
POST /projects/:id/pages/domains
```

サポートされている属性は以下のとおりです:

| 属性          | 型           | 必須 | 説明                              |
| -------------------| -------------- | -------- | ---------------------------------------- |
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `domain`           | 文字列         | はい      | ユーザーが指定したカスタムドメイン  |
| `auto_ssl_enabled` | ブール値        | いいえ       | Let's Encryptによって発行されたSSL証明書の[自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)をカスタムドメインに対して有効にします。 |
| `certificate`      | ファイル/文字列    | いいえ       | 最も限定的な順序で中間証明書が続くPEM形式の証明書。|
| `key`              | ファイル/文字列    | いいえ       | PEM形式の証明書キー。       |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型            | 説明                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 文字列          | GitLab Pagesサイトのカスタムドメイン名。 |
| `url`               | 文字列          | プロトコルを含む、Pagesサイトの完全なURL。 |
| `verified`          | ブール値         | ドメインが確認されたかどうかを示します。 |
| `verification_code` | 文字列          | ドメインの所有権を確認するために使用される一意のレコード。 |
| `enabled_until`     | 日付            | ドメインが有効になっている日付。これは、ドメインが再検証されると定期的に更新されます。  |
| `auto_ssl_enabled`  | ブール値         | [自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) SSL証明書（Let's Encryptを使用）が、このドメインに対して有効になっているかどうかを示します。 |
| `certificate` | オブジェクト | SSL証明書に関する情報。 |
| `certificate.subject` | 文字列 | SSL証明書のサブジェクト（通常はドメインに関する情報を含む）。 |
| `certificate.expired` | 日付 | SSL証明書の有効期限が切れている（true）か、まだ有効（false）かを示します。 |
| `certificate.certificate` | 文字列 | PEM形式の完全なSSL証明書。 |
| `certificate.certificate_text` | 日付 | 発行者、有効期間、サブジェクト、その他の証明書情報など、SSL証明書を人間が読める形式で表現したテキスト。  |

リクエストの例:

`.pem`ファイルから証明書を使用して、新しいPagesドメインを作成します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains" \
  --form "domain=ssl.domain.example" \
  --form "certificate=@/path/to/cert.pem" \
  --form "key=@/path/to/key.pem"
```

証明書を含む変数を使用して、新しいPagesドメインを作成します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains" \
  --form "domain=ssl.domain.example" \
  --form "certificate=$CERT_PEM" \
  --form "key=$KEY_PEM"
```

[自動証明書](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md#enabling-lets-encrypt-integration-for-your-custom-domain)を使用して、新しいPagesドメインを作成します:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "domain=ssl.domain.example" \
     --form "auto_ssl_enabled=true" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

レスポンス例:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": true,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Pagesドメインを更新 {#update-pages-domain}

既存のプロジェクトPagesドメインを更新します。ユーザーは既存のPagesドメインを変更するための権限を持っている必要があります。

```plaintext
PUT /projects/:id/pages/domains/:domain
```

サポートされている属性は以下のとおりです:

| 属性          | 型           | 必須 | 説明                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `domain`           | 文字列         | はい      | ユーザーが指定したカスタムドメイン  |
| `auto_ssl_enabled` | ブール値        | いいえ       | Let's Encryptによって発行されたSSL証明書の[自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)をカスタムドメインに対して有効にします。 |
| `certificate`      | ファイル/文字列    | いいえ       | 最も限定的な順序で中間証明書が続くPEM形式の証明書。|
| `key`              | ファイル/文字列    | いいえ       | PEM形式の証明書キー。       |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型            | 説明                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 文字列          | GitLab Pagesサイトのカスタムドメイン名。 |
| `url`               | 文字列          | プロトコルを含む、Pagesサイトの完全なURL。 |
| `verified`          | ブール値         | ドメインが確認されたかどうかを示します。 |
| `verification_code` | 文字列          | ドメインの所有権を確認するために使用される一意のレコード。 |
| `enabled_until`     | 日付            | ドメインが有効になっている日付。これは、ドメインが再検証されると定期的に更新されます。  |
| `auto_ssl_enabled`  | ブール値         | [自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) SSL証明書（Let's Encryptを使用）が、このドメインに対して有効になっているかどうかを示します。 |
| `certificate` | オブジェクト | SSL証明書に関する情報。 |
| `certificate.subject` | 文字列 | SSL証明書のサブジェクト（通常はドメインに関する情報を含む）。 |
| `certificate.expired` | 日付 | SSL証明書の有効期限が切れている（true）か、まだ有効（false）かを示します。 |
| `certificate.certificate` | 文字列 | PEM形式の完全なSSL証明書。 |
| `certificate.certificate_text` | 日付 | 発行者、有効期間、サブジェクト、その他の証明書情報など、SSL証明書を人間が読める形式で表現したテキスト。  |

### 証明書を追加 {#adding-certificate}

`.pem`ファイルから証明書をPagesドメインに追加します:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=@/path/to/cert.pem" \
  --form "key=@/path/to/key.pem"
```

証明書を含む変数を使用して、Pagesドメインの証明書を追加します:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=$CERT_PEM" \
  --form "key=$KEY_PEM"
```

レスポンス例:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

### PagesカスタムドメインのLet's Encryptインテグレーションを有効にする {#enabling-lets-encrypt-integration-for-pages-custom-domains}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "auto_ssl_enabled=true"
```

レスポンス例:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": true
}
```

### 証明書を削除 {#removing-certificate}

Pagesドメインに添付されているSSL証明書を削除するには、次を実行します:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=" \
  --form "key="
```

レスポンス例:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false
}
```

## Pagesドメインを確認 {#verify-pages-domain}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/21261)されました。

{{< /history >}}

既存のプロジェクトPagesドメインを確認します。ユーザーはPagesドメインを更新するための権限を持っている必要があります。

```plaintext
PUT /projects/:id/pages/domains/:domain/verify
```

サポートされている属性は以下のとおりです:

| 属性          | 型           | 必須 | 説明                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたはURLエンコードされたパス |
| `domain` | 文字列 | はい | 確認するカスタムドメイン |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型            | 説明                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 文字列          | GitLab Pagesサイトのカスタムドメイン名。 |
| `url`               | 文字列          | プロトコルを含む、Pagesサイトの完全なURL。 |
| `verified`          | ブール値         | ドメインが確認されたかどうかを示します。 |
| `verification_code` | 文字列          | ドメインの所有権を確認するために使用される一意のレコード。 |
| `enabled_until`     | 日付            | ドメインが有効になっている日付。これは、ドメインが再検証されると定期的に更新されます。  |
| `auto_ssl_enabled`  | ブール値         | [自動生成](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) SSL証明書（Let's Encryptを使用）が、このドメインに対して有効になっているかどうかを示します。 |
| `certificate` | オブジェクト | SSL証明書に関する情報。 |
| `certificate.subject` | 文字列 | SSL証明書のサブジェクト（通常はドメインに関する情報を含む）。 |
| `certificate.expired` | 日付 | SSL証明書の有効期限が切れている（true）か、まだ有効（false）かを示します。 |
| `certificate.certificate` | 文字列 | PEM形式の完全なSSL証明書。 |
| `certificate.certificate_text` | 日付 | 発行者、有効期間、サブジェクト、その他の証明書情報など、SSL証明書を人間が読める形式で表現したテキスト。  |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example/verify"
```

レスポンス例:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false,
  "verified": true,
  "verification_code": "1234567890abcdef",
  "enabled_until": "2020-04-12T14:32:00.000Z"
}
```

## Pagesドメインを削除 {#delete-pages-domain}

既存のプロジェクトPagesドメインを削除します。

```plaintext
DELETE /projects/:id/pages/domains/:domain
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `domain`  | 文字列         | はい      | ユーザーが指定したカスタムドメイン  |

成功した場合、空の本体を持つ`204 No Content` HTTPレスポンスが予期されます。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```
