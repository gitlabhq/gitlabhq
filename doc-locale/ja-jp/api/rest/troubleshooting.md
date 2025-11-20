---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "GitLab REST APIのトラブルシューティング。ステータスコード、エラー応答、スパム検出、およびリバースプロキシの問題について説明します。"
title: REST APIのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

REST APIを使用しているときに、問題が発生する可能性があります。

トラブルシューティングを行うには、REST APIのステータスコードを参照してください。HTTPレスポンスヘッダーと終了コードを含めることも役立ちます。

## ステータスコード {#status-codes}

GitLab REST APIは、コンテキストとアクションに応じて、すべての応答でステータスコードを返します。リクエストによって返されるステータスコードは、トラブルシューティングを行う際に役立ちます。

次の表は、API機能の一般的な動作の概要を示しています。

| リクエストタイプ            | 説明 |
|:------------------------|:------------|
| `GET`                   | 1つ以上のリソースにアクセスし、結果をJSONとして返します。 |
| `POST`                  | リソースが正常に作成された場合は`201 Created`を返し、新しく作成されたリソースをJSONとして返します。 |
| `GET` / `PUT` / `PATCH` | リソースへのアクセスまたは変更が正常に行われた場合は、`200 OK`を返します。(変更された)結果はJSONとして返されます。 |
| `DELETE`                | リソースが正常に削除された場合は`204 No Content`を返し、リソースが削除されるようにスケジュールされている場合は`202 Accepted`を返します。 |

次の表に、APIリクエストで返される可能性のあるコードを示します。

| 戻り値             | 説明 |
|:--------------------------|:------------|
| `200 OK`                  | `GET`、`PUT`、`PATCH`、または`DELETE`リクエストが成功し、リソース自体がJSONとして返されました。 |
| `201 Created`             | `POST`リクエストが成功し、リソースがJSONとして返されました。 |
| `202 Accepted`            | `GET`、`PUT`、または`DELETE`リクエストが成功し、リソースが処理されるようにスケジュールされました。 |
| `204 No Content`          | サーバーはリクエストを正常に実行しましたが、応答ペイロード本文で送信する追加コンテンツはありません。 |
| `301 Moved Permanently`   | リソースは、`Location`ヘッダーによって指定されたURLに明確に移動されました。 |
| `304 Not Modified`        | リソースは、最後のリクエスト以降に変更されていません。 |
| `400 Bad Request`         | APIリクエストに必要な属性がありません。たとえば、イシューのタイトルが指定されていません。 |
| `401 Unauthorized`        | ユーザーが認証されていません。有効な[ユーザートークン](authentication.md)が必要です。 |
| `403 Forbidden`           | リクエストは許可されていません。たとえば、ユーザーはプロジェクトを削除できません。 |
| `404 Not Found`           | リソースにアクセスできませんでした。たとえば、リソースのIDが見つからなかったり、ユーザーがリソースにアクセスする権限がなかったりします。 |
| `405 Method Not Allowed`  | リクエストはサポートされていません。 |
| `409 Conflict`            | 競合するリソースが既に存在します。 |
| `412 Precondition Failed` | リクエストは拒否されました。これは、リソースを削除しようとしたときに`If-Unmodified-Since`ヘッダーが指定されている場合に発生する可能性があります。これは、その間に変更されました。 |
| `422 Unprocessable`       | エンティティを処理できませんでした。 |
| `429 Too Many Requests`   | ユーザーが[アプリケーションレート制限](../../administration/instance_limits.md#rate-limits)を超えました。 |
| `500 Server Error`        | リクエストの処理中に、サーバーで問題が発生しました。 |
| `503 Service Unavailable` | サーバーが一時的にオーバーロードされているため、サーバーはリクエストを処理できません。 |

### ステータスコード400 {#status-code-400}

APIを使用しているときに検証エラーが発生する可能性があり、その場合、APIはHTTP `400`エラーを返します。

このようなエラーは、次の場合に表示されます:

- APIリクエストに必要な属性がありません(イシューのタイトルが指定されていないなど)。
- 属性が検証に合格しませんでした(たとえば、ユーザーの自己紹介が長すぎます)。

属性がない場合は、次のようなものが表示されます:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message":"400 (Bad request) \"title\" not given"
}
```

検証エラーが発生すると、エラーメッセージが異なります。すべての検証エラーの詳細が保持されます:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message": {
        "bio": [
            "is too long (maximum is 255 characters)"
        ]
    }
}
```

これにより、エラーメッセージがよりコンピューターで読み取りやすくなります。形式は次のように記述できます:

```json
{
    "message": {
        "<property-name>": [
            "<error-message>",
            "<error-message>",
            ...
        ],
        "<embed-entity>": {
            "<property-name>": [
                "<error-message>",
                "<error-message>",
                ...
            ],
        }
    }
}
```

## HTTPレスポンスヘッダーを含める {#include-http-response-headers}

HTTPレスポンスヘッダーは、トラブルシューティング時に追加情報を提供できます。

応答にHTTPレスポンスヘッダーを含めるには、`--include`オプションを使用します:

```shell
curl --request GET \
  --include \
  --url "https://gitlab.example.com/api/v4/projects"
HTTP/2 200
...
```

## HTTP終了コードを含める {#include-http-exit-code}

API応答のHTTP終了コードは、トラブルシューティング時に追加情報を提供できます。

HTTP終了コードを含めるには、`--fail`オプションを含めます:

```shell
curl --request GET \
  --fail \
  --url "https://gitlab.example.com/api/v4/does-not-exist"
curl: (22) The requested URL returned error: 404
```

## スパムとして検出されたリクエスト {#requests-detected-as-spam}

REST APIリクエストはスパムとして検出される可能性があります。リクエストがスパムとして検出され、次の場合は:

- CAPTCHAサービスが設定されていない場合、エラー応答が返されます。例: 

  ```json
  {"message":{"error":"Your snippet has been recognized as spam and has been discarded."}}
  ```

- CAPTCHAサービスが設定されている場合、次の内容の応答が返されます:
  - `needs_captcha_response`が`true`に設定されます。
  - `spam_log_id`フィールドと`captcha_site_key`フィールドが設定されます。

  例: 

  ```json
  {"needs_captcha_response":true,"spam_log_id":42,"captcha_site_key":"REDACTED","message":{"error":"Your snippet has been recognized as spam. Please, change the content or solve the reCAPTCHA to proceed."}}
  ```

  - 適切なCAPTCHA APIを使用して、`captcha_site_key`でCAPTCHAの応答値を取得します。[Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display)のみがサポートされています。
  - `X-GitLab-Captcha-Response`ヘッダーと`X-GitLab-Spam-Log-Id`ヘッダーを設定して、リクエストを再送信します。

    ```shell
    export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
    export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"

    curl --request POST \
      --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
      --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" \
      --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" \
      --url "https://gitlab.example.com/api/v4/snippets?title=Title&file_name=FileName&content=Content&visibility=public"
    ```

## エラー: リバースプロキシの使用時に`404 Not Found` {#error-404-not-found-when-using-a-reverse-proxy}

GitLabインスタンスがリバースプロキシを使用している場合、GitLab [editor拡張機能](../../editor_extensions/_index.md)、GitLab CLI、またはURLエンコードされたパラメータを使用したAPIコールを使用すると、`404 Not Found`エラーが表示されることがあります。

この問題は、リバースプロキシがパラメータをGitLabに渡す前に、`/`、`?`、`@`などの文字をエンコード解除すると発生します。

この問題を解決するには、リバースプロキシの設定を編集します:

- `VirtualHost`セクションで、`AllowEncodedSlashes NoDecode`を追加します。
- `Location`セクションで、`ProxyPass`を編集し、`nocanon`フラグを追加します。

例: 

{{< tabs >}}

{{< tab title="Apacheの設定" >}}

```plaintext
<VirtualHost *:443>
  ServerName git.example.com

  SSLEngine on
  SSLCertificateFile     /etc/letsencrypt/live/git.example.com/fullchain.pem
  SSLCertificateKeyFile  /etc/letsencrypt/live/git.example.com/privkey.pem
  SSLVerifyClient None

  ProxyRequests     Off
  ProxyPreserveHost On
  AllowEncodedSlashes NoDecode

  <Location />
     ProxyPass http://127.0.0.1:8080/ nocanon
     ProxyPassReverse http://127.0.0.1:8080/
     Order deny,allow
     Allow from all
  </Location>
</VirtualHost>
```

{{< /tab >}}

{{< tab title="NGINX構成" >}}

```plaintext
server {
  listen       80;
  server_name  gitlab.example.com;
  location / {
     proxy_pass    http://ip:port;
     proxy_set_header        X-Forwarded-Proto $scheme;
     proxy_set_header        Host              $http_host;
     proxy_set_header        X-Real-IP         $remote_addr;
     proxy_set_header        X-Forwarded-For   $proxy_add_x_forwarded_for;
     proxy_read_timeout    300;
     proxy_connect_timeout 300;
  }
}
```

{{< /tab >}}

{{< /tabs >}}

詳細については、[issue 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775)を参照してください。
