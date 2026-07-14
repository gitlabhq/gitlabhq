---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab REST API 문제 해결입니다. 상태 코드, 오류 응답, 스팸 감지 및 리버스 프록시 문제를 포함합니다."
title: REST API 문제 해결
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

REST API를 사용할 때 이슈가 발생할 수 있습니다.

문제를 해결하려면 REST API 상태 코드를 참조하세요. HTTP 응답 헤더와 종료 코드를 포함하면 도움이 될 수 있습니다.

## 상태 코드 {#status-codes}

GitLab REST API는 컨텍스트와 작업에 따라 모든 응답과 함께 상태 코드를 반환합니다. 요청으로 반환된 상태 코드는 문제 해결 시 유용할 수 있습니다.

다음 표는 API 함수가 일반적으로 어떻게 작동하는지 개략적으로 설명합니다.

| 요청 유형            | 설명 |
|:------------------------|:------------|
| `GET`                   | 하나 이상의 리소스에 액세스하고 결과를 JSON으로 반환합니다. |
| `POST`                  | 리소스가 성공적으로 생성되면 `201 Created`를 반환하고 새로 생성된 리소스를 JSON으로 반환합니다. |
| `GET` / `PUT` / `PATCH` | 리소스에 성공적으로 액세스하거나 수정되면 `200 OK`을 반환합니다. (수정된) 결과는 JSON으로 반환됩니다. |
| `DELETE`                | 리소스가 성공적으로 삭제되면 `204 No Content`을 반환하거나, 리소스가 삭제되도록 예약된 경우 `202 Accepted`을 반환합니다. |

다음 표는 API 요청의 가능한 반환 코드를 보여줍니다.

| 반환 값             | 설명 |
|:--------------------------|:------------|
| `200 OK`                  | `GET`, `PUT`, `PATCH` 또는 `DELETE` 요청이 성공했고, 리소스 자체가 JSON으로 반환되었습니다. |
| `201 Created`             | `POST` 요청이 성공했고, 리소스가 JSON으로 반환되었습니다. |
| `202 Accepted`            | `GET`, `PUT` 또는 `DELETE` 요청이 성공했고, 리소스가 처리되도록 예약되었습니다. |
| `204 No Content`          | 서버가 요청을 성공적으로 처리했으며, 응답 페이로드 본문에 보낼 추가 콘텐츠가 없습니다. |
| `301 Moved Permanently`   | 리소스가 `Location` 헤더로 지정된 URL로 영구적으로 이동되었습니다. |
| `304 Not Modified`        | 리소스가 마지막 요청 이후로 수정되지 않았습니다. |
| `400 Bad Request`         | API 요청의 필수 속성이 누락되었습니다. 예를 들어, 이슈의 제목이 지정되지 않았습니다. |
| `401 Unauthorized`        | 사용자가 인증되지 않았습니다. 유효한 [사용자 토큰](authentication.md)이 필요합니다. |
| `403 Forbidden`           | 요청이 허용되지 않습니다. 예를 들어, 사용자가 프로젝트를 삭제할 수 없습니다. |
| `404 Not Found`           | 리소스에 액세스할 수 없습니다. 예를 들어, 리소스의 ID를 찾을 수 없거나, 사용자가 리소스에 액세스할 권한이 없습니다. |
| `405 Method Not Allowed`  | 요청이 지원되지 않습니다. |
| `409 Conflict`            | 충돌하는 리소스가 이미 존재합니다. |
| `412 Precondition Failed` | 요청이 거부되었습니다. 이 상황은 리소스를 삭제하려고 할 때 `If-Unmodified-Since` 헤더가 제공된 경우 발생할 수 있습니다. 그 사이에 리소스가 수정되었습니다. |
| `422 Unprocessable`       | 엔티티를 처리할 수 없습니다. |
| `429 Too Many Requests`   | 사용자가 [속도 제한](../../administration/instance_limits.md#rate-limits)을 초과했습니다. |
| `500 Server Error`        | 요청을 처리하는 중에 서버에서 무언가 잘못되었습니다. |
| `503 Service Unavailable` | 서버가 요청을 처리할 수 없습니다. 서버가 일시적으로 과부하 상태입니다. |

### 상태 코드 400 {#status-code-400}

API를 사용할 때 유효성 검사 오류가 발생할 수 있으며, 이 경우 API는 HTTP `400` 오류를 반환합니다.

이러한 오류는 다음과 같은 경우에 나타납니다:

- API 요청의 필수 속성이 누락되었습니다(예: 이슈의 제목이 지정되지 않음).
- 속성이 유효성 검사를 통과하지 못했습니다(예: 사용자 약력이 너무 깁니다).

속성이 누락된 경우 다음과 같은 것을 받습니다:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message":"400 (Bad request) \"title\" not given"
}
```

유효성 검사 오류가 발생하면 오류 메시지는 다릅니다. 이들은 유효성 검사 오류의 모든 세부 사항을 포함합니다:

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

이렇게 하면 오류 메시지를 더 읽기 쉽게 만듭니다. 형식은 다음과 같이 설명할 수 있습니다:

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

## HTTP 응답 헤더 포함 {#include-http-response-headers}

HTTP 응답 헤더는 문제 해결 시 추가 정보를 제공할 수 있습니다.

HTTP 응답 헤더를 응답에 포함하려면 `--include` 옵션을 사용하세요:

```shell
curl --request GET \
  --include \
  --url "https://gitlab.example.com/api/v4/projects"
HTTP/2 200
...
```

## HTTP 종료 코드 포함 {#include-http-exit-code}

API 응답의 HTTP 종료 코드는 문제 해결 시 추가 정보를 제공할 수 있습니다.

HTTP 종료 코드를 포함하려면 `--fail` 옵션을 포함하세요:

```shell
curl --request GET \
  --fail \
  --url "https://gitlab.example.com/api/v4/does-not-exist"
curl: (22) The requested URL returned error: 404
```

## 스팸으로 감지된 요청 {#requests-detected-as-spam}

REST API 요청이 스팸으로 감지될 수 있습니다. 요청이 스팸으로 감지되고 다음과 같은 경우:

- CAPTCHA 서비스가 구성되지 않은 경우 오류 응답이 반환됩니다. 예를 들어:

  ```json
  {"message":{"error":"Your snippet has been recognized as spam and has been discarded."}}
  ```

- CAPTCHA 서비스가 구성된 경우 다음과 함께 응답을 받습니다:
  - `needs_captcha_response`을(를) `true`로 설정합니다.
  - `spam_log_id` 및 `captcha_site_key` 필드가 설정됩니다.

  예를 들어:

  ```json
  {"needs_captcha_response":true,"spam_log_id":42,"captcha_site_key":"REDACTED","message":{"error":"Your snippet has been recognized as spam. Please, change the content or solve the reCAPTCHA to proceed."}}
  ```

  - `captcha_site_key`을(를) 사용하여 적절한 CAPTCHA API를 사용하여 CAPTCHA 응답 값을 받으세요. [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display)만 지원됩니다.
  - `X-GitLab-Captcha-Response` 및 `X-GitLab-Spam-Log-Id` 헤더가 설정된 상태로 요청을 다시 제출하세요.

    ```shell
    export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
    export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"

    curl --request POST \
      --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
      --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" \
      --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" \
      --url "https://gitlab.example.com/api/v4/snippets?title=Title&file_name=FileName&content=Content&visibility=public"
    ```

## 오류: `404 Not Found` (리버스 프록시 사용 시) {#error-404-not-found-when-using-a-reverse-proxy}

GitLab 인스턴스가 리버스 프록시를 사용하는 경우 GitLab [편집기 확장](../../editor_extensions/_index.md), GitLab CLI 또는 URL 인코딩 매개 변수를 사용한 API 호출을 사용할 때 `404 Not Found` 오류가 표시될 수 있습니다.

이 문제는 리버스 프록시가 GitLab에 매개 변수를 전달하기 전에 `/`, `?` 및 `@`와 같은 문자를 디코딩할 때 발생합니다.

이 문제를 해결하려면 리버스 프록시의 구성을 편집하세요:

- `VirtualHost` 섹션에서 `AllowEncodedSlashes NoDecode`을(를) 추가하세요.
- `Location` 섹션에서 `ProxyPass`을(를) 편집하고 `nocanon` 플래그를 추가하세요.

예를 들어:

{{< tabs >}}

{{< tab title="Apache 구성" >}}

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

{{< tab title="NGINX 구성" >}}

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

자세한 내용은 [이슈 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775)를 참조하세요.

## 지원 기술 자료 {#support-knowledge-base}

계속 문제가 있으면 [GitLab 지원 기술 자료](https://support.gitlab.com/hc/en-us/)를 참조하세요.
