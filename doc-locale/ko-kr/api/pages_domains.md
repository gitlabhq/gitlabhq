---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Pages 도메인 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

이 API를 사용하여 [GitLab Pages 도메인](../user/project/pages/custom_domains_ssl_tls_certification/_index.md)을(를) 관리합니다.

GitLab Pages 기능을 활성화해야 이 엔드포인트를 사용할 수 있습니다. [관리](../administration/pages/_index.md) 및 기능 [사용](../user/project/pages/_index.md)에 대해 자세히 알아봅니다.

## 모든 Pages 도메인 나열 {#list-all-pages-domains}

인스턴스의 모든 Pages 도메인을 나열합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
GET /pages/domains
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명                                       |
| --------- | -------------- | -------- | ------------------------------------------------- |
| `domain`  | 문자열         | 아니요       | 필터링할 GitLab Pages 사이트의 도메인입니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형            | 설명                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 문자열          | GitLab Pages 사이트의 사용자 지정 도메인 이름입니다. |
| `url`               | 문자열          | 프로토콜을 포함한 Pages 사이트의 전체 URL입니다. |
| `project_id`        | 정수         | 이 Pages 도메인과 연결된 GitLab 프로젝트의 ID입니다. |
| `verified`          | 부울         | 도메인이 확인되었는지 여부를 나타냅니다. |
| `verification_code` | 문자열          | 도메인 소유권을 확인하는 데 사용되는 고유 레코드입니다. |
| `enabled_until`     | 날짜            | 도메인이 활성화될 때까지의 날짜입니다. 도메인을 다시 확인할 때마다 정기적으로 업데이트됩니다.  |
| `auto_ssl_enabled`  | 부울         | [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)이 Let's Encrypt를 사용하는 SSL 인증서에 대해 이 도메인에 대해 활성화되어 있는지 나타냅니다. |
| `certificate_expiration` | 객체 | SSL 인증서 만료에 대한 정보입니다. |
| `certificate_expiration.expired` | 부울 | SSL 인증서가 만료되었는지 여부를 나타냅니다. |
| `certificate_expiration.expiration` | 날짜 | SSL 인증서의 만료 날짜 및 시간입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/pages/domains"
```

응답 예시:

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

## 프로젝트의 모든 Pages 도메인 나열 {#list-all-pages-domains-in-a-project}

지정된 프로젝트의 모든 Pages 도메인을 나열합니다. 사용자는 Pages 도메인을 볼 수 있는 권한이 있어야 합니다.

```plaintext
GET /projects/:id/pages/domains
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형            | 설명                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 문자열          | GitLab Pages 사이트의 사용자 지정 도메인 이름입니다. |
| `url`               | 문자열          | 프로토콜을 포함한 Pages 사이트의 전체 URL입니다. |
| `verified`          | 부울         | 도메인이 확인되었는지 여부를 나타냅니다. |
| `verification_code` | 문자열          | 도메인 소유권을 확인하는 데 사용되는 고유 레코드입니다. |
| `enabled_until`     | 날짜            | 도메인이 활성화될 때까지의 날짜입니다. 도메인을 다시 확인할 때마다 정기적으로 업데이트됩니다.  |
| `auto_ssl_enabled`  | 부울         | [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)이 Let's Encrypt를 사용하는 SSL 인증서에 대해 이 도메인에 대해 활성화되어 있는지 나타냅니다. |
| `certificate` | 객체 | SSL 인증서에 대한 정보입니다. |
| `certificate.subject` | 문자열 | SSL 인증서의 주체로, 일반적으로 도메인에 대한 정보를 포함합니다. |
| `certificate.expired` | 날짜 | SSL 인증서가 만료되었는지(true) 또는 여전히 유효한지(false)를 나타냅니다. |
| `certificate.certificate` | 문자열 | PEM 형식의 전체 SSL 인증서입니다. |
| `certificate.certificate_text` | 날짜 | 발급자, 유효 기간, 주체 및 기타 인증서 정보와 같은 세부 정보를 포함하는 SSL 인증서의 사람이 읽을 수 있는 텍스트 표현입니다.  |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

응답 예시:

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

## Pages 도메인 검색 {#retrieve-a-pages-domain}

지정된 프로젝트에서 Pages 도메인을 검색합니다. 사용자는 Pages 도메인을 볼 수 있는 권한이 있어야 합니다.

```plaintext
GET /projects/:id/pages/domains/:domain
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `domain`  | 문자열         | 예      | 사용자가 표시한 사용자 지정 도메인입니다  |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형            | 설명                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 문자열          | GitLab Pages 사이트의 사용자 지정 도메인 이름입니다. |
| `url`               | 문자열          | 프로토콜을 포함한 Pages 사이트의 전체 URL입니다. |
| `verified`          | 부울         | 도메인이 확인되었는지 여부를 나타냅니다. |
| `verification_code` | 문자열          | 도메인 소유권을 확인하는 데 사용되는 고유 레코드입니다. |
| `enabled_until`     | 날짜            | 도메인이 활성화될 때까지의 날짜입니다. 도메인을 다시 확인할 때마다 정기적으로 업데이트됩니다.  |
| `auto_ssl_enabled`  | 부울         | [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)이 Let's Encrypt를 사용하는 SSL 인증서에 대해 이 도메인에 대해 활성화되어 있는지 나타냅니다. |
| `certificate` | 객체 | SSL 인증서에 대한 정보입니다. |
| `certificate.subject` | 문자열 | SSL 인증서의 주체로, 일반적으로 도메인에 대한 정보를 포함합니다. |
| `certificate.expired` | 날짜 | SSL 인증서가 만료되었는지(true) 또는 여전히 유효한지(false)를 나타냅니다. |
| `certificate.certificate` | 문자열 | PEM 형식의 전체 SSL 인증서입니다. |
| `certificate.certificate_text` | 날짜 | 발급자, 유효 기간, 주체 및 기타 인증서 정보와 같은 세부 정보를 포함하는 SSL 인증서의 사람이 읽을 수 있는 텍스트 표현입니다.  |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

응답 예시:

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

## 새 Pages 도메인 생성 {#create-new-pages-domain}

지정된 프로젝트에서 Pages 도메인을 생성합니다. 사용자는 새로운 Pages 도메인을 생성할 수 있는 권한이 있어야 합니다.

```plaintext
POST /projects/:id/pages/domains
```

지원되는 속성:

| 속성          | 유형           | 필수 | 설명                              |
| -------------------| -------------- | -------- | ---------------------------------------- |
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `domain`           | 문자열         | 예      | 사용자가 표시한 사용자 지정 도메인입니다  |
| `auto_ssl_enabled` | 부울        | 아니요       | 사용자 지정 도메인에 대해 Let's Encrypt에서 발급한 SSL 인증서의 [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)을(를) 활성화합니다. |
| `certificate`      | 파일/문자열    | 아니요       | 가장 구체적인 것부터 가장 구체적이지 않은 순서로 따르는 중간 체인이 있는 PEM 형식의 인증서입니다.|
| `key`              | 파일/문자열    | 아니요       | PEM 형식의 인증서 키입니다.       |

성공하면 [`201`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형            | 설명                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 문자열          | GitLab Pages 사이트의 사용자 지정 도메인 이름입니다. |
| `url`               | 문자열          | 프로토콜을 포함한 Pages 사이트의 전체 URL입니다. |
| `verified`          | 부울         | 도메인이 확인되었는지 여부를 나타냅니다. |
| `verification_code` | 문자열          | 도메인 소유권을 확인하는 데 사용되는 고유 레코드입니다. |
| `enabled_until`     | 날짜            | 도메인이 활성화될 때까지의 날짜입니다. 도메인을 다시 확인할 때마다 정기적으로 업데이트됩니다.  |
| `auto_ssl_enabled`  | 부울         | [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)이 Let's Encrypt를 사용하는 SSL 인증서에 대해 이 도메인에 대해 활성화되어 있는지 나타냅니다. |
| `certificate` | 객체 | SSL 인증서에 대한 정보입니다. |
| `certificate.subject` | 문자열 | SSL 인증서의 주체로, 일반적으로 도메인에 대한 정보를 포함합니다. |
| `certificate.expired` | 날짜 | SSL 인증서가 만료되었는지(true) 또는 여전히 유효한지(false)를 나타냅니다. |
| `certificate.certificate` | 문자열 | PEM 형식의 전체 SSL 인증서입니다. |
| `certificate.certificate_text` | 날짜 | 발급자, 유효 기간, 주체 및 기타 인증서 정보와 같은 세부 정보를 포함하는 SSL 인증서의 사람이 읽을 수 있는 텍스트 표현입니다.  |

예제 요청:

`.pem` 파일에서 Pages 도메인의 인증서를 가져옵니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains" \
  --form "domain=ssl.domain.example" \
  --form "certificate=@/path/to/cert.pem" \
  --form "key=@/path/to/key.pem"
```

인증서를 포함하는 변수를 사용하여 새로운 Pages 도메인을 생성합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains" \
  --form "domain=ssl.domain.example" \
  --form "certificate=$CERT_PEM" \
  --form "key=$KEY_PEM"
```

[자동 인증서](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md#enabling-lets-encrypt-integration-for-your-custom-domain)를 사용하여 새로운 Pages 도메인을 생성합니다:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "domain=ssl.domain.example" \
     --form "auto_ssl_enabled=true" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

응답 예시:

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

## Pages 도메인 업데이트 {#update-pages-domain}

프로젝트의 지정된 Pages 도메인을 업데이트합니다. 사용자는 기존 Pages 도메인을 변경할 수 있는 권한이 있어야 합니다.

```plaintext
PUT /projects/:id/pages/domains/:domain
```

지원되는 속성:

| 속성          | 유형           | 필수 | 설명                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `domain`           | 문자열         | 예      | 사용자가 표시한 사용자 지정 도메인입니다  |
| `auto_ssl_enabled` | 부울        | 아니요       | 사용자 지정 도메인에 대해 Let's Encrypt에서 발급한 SSL 인증서의 [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)을(를) 활성화합니다. |
| `certificate`      | 파일/문자열    | 아니요       | 가장 구체적인 것부터 가장 구체적이지 않은 순서로 따르는 중간 체인이 있는 PEM 형식의 인증서입니다.|
| `key`              | 파일/문자열    | 아니요       | PEM 형식의 인증서 키입니다.       |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형            | 설명                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 문자열          | GitLab Pages 사이트의 사용자 지정 도메인 이름입니다. |
| `url`               | 문자열          | 프로토콜을 포함한 Pages 사이트의 전체 URL입니다. |
| `verified`          | 부울         | 도메인이 확인되었는지 여부를 나타냅니다. |
| `verification_code` | 문자열          | 도메인 소유권을 확인하는 데 사용되는 고유 레코드입니다. |
| `enabled_until`     | 날짜            | 도메인이 활성화될 때까지의 날짜입니다. 도메인을 다시 확인할 때마다 정기적으로 업데이트됩니다.  |
| `auto_ssl_enabled`  | 부울         | [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)이 Let's Encrypt를 사용하는 SSL 인증서에 대해 이 도메인에 대해 활성화되어 있는지 나타냅니다. |
| `certificate` | 객체 | SSL 인증서에 대한 정보입니다. |
| `certificate.subject` | 문자열 | SSL 인증서의 주체로, 일반적으로 도메인에 대한 정보를 포함합니다. |
| `certificate.expired` | 날짜 | SSL 인증서가 만료되었는지(true) 또는 여전히 유효한지(false)를 나타냅니다. |
| `certificate.certificate` | 문자열 | PEM 형식의 전체 SSL 인증서입니다. |
| `certificate.certificate_text` | 날짜 | 발급자, 유효 기간, 주체 및 기타 인증서 정보와 같은 세부 정보를 포함하는 SSL 인증서의 사람이 읽을 수 있는 텍스트 표현입니다.  |

### 인증서 추가 {#adding-certificate}

`.pem` 파일에서 Pages 도메인의 인증서를 추가합니다:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=@/path/to/cert.pem" \
  --form "key=@/path/to/key.pem"
```

인증서를 포함하는 변수를 사용하여 Pages 도메인의 인증서를 추가합니다:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=$CERT_PEM" \
  --form "key=$KEY_PEM"
```

응답 예시:

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

### Pages 사용자 지정 도메인에 대해 Let's Encrypt 통합 활성화 {#enabling-lets-encrypt-integration-for-pages-custom-domains}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "auto_ssl_enabled=true"
```

응답 예시:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": true
}
```

### 인증서 제거 {#removing-certificate}

Pages 도메인에 첨부된 SSL 인증서를 제거하려면 다음을 실행합니다:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=" \
  --form "key="
```

응답 예시:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false
}
```

## Pages 도메인 확인 {#verify-pages-domain}

{{< history >}}

- GitLab 17.7에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/21261)

{{< /history >}}

프로젝트에서 지정된 Pages 도메인을 확인합니다. 사용자는 Pages 도메인을 업데이트할 수 있는 권한이 있어야 합니다.

```plaintext
PUT /projects/:id/pages/domains/:domain/verify
```

지원되는 속성:

| 속성          | 유형           | 필수 | 설명                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 URL 인코딩 경로 |
| `domain` | 문자열 | 예 | 확인할 사용자 지정 도메인 |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형            | 설명                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | 문자열          | GitLab Pages 사이트의 사용자 지정 도메인 이름입니다. |
| `url`               | 문자열          | 프로토콜을 포함한 Pages 사이트의 전체 URL입니다. |
| `verified`          | 부울         | 도메인이 확인되었는지 여부를 나타냅니다. |
| `verification_code` | 문자열          | 도메인 소유권을 확인하는 데 사용되는 고유 레코드입니다. |
| `enabled_until`     | 날짜            | 도메인이 활성화될 때까지의 날짜입니다. 도메인을 다시 확인할 때마다 정기적으로 업데이트됩니다.  |
| `auto_ssl_enabled`  | 부울         | [자동 생성](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)이 Let's Encrypt를 사용하는 SSL 인증서에 대해 이 도메인에 대해 활성화되어 있는지 나타냅니다. |
| `certificate` | 객체 | SSL 인증서에 대한 정보입니다. |
| `certificate.subject` | 문자열 | SSL 인증서의 주체로, 일반적으로 도메인에 대한 정보를 포함합니다. |
| `certificate.expired` | 날짜 | SSL 인증서가 만료되었는지(true) 또는 여전히 유효한지(false)를 나타냅니다. |
| `certificate.certificate` | 문자열 | PEM 형식의 전체 SSL 인증서입니다. |
| `certificate.certificate_text` | 날짜 | 발급자, 유효 기간, 주체 및 기타 인증서 정보와 같은 세부 정보를 포함하는 SSL 인증서의 사람이 읽을 수 있는 텍스트 표현입니다.  |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example/verify"
```

응답 예시:

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

## Pages 도메인 삭제 {#delete-pages-domain}

프로젝트에서 지정된 Pages 도메인을 삭제합니다.

```plaintext
DELETE /projects/:id/pages/domains/:domain
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `domain`  | 문자열         | 예      | 사용자가 표시한 사용자 지정 도메인입니다  |

성공한 경우, `204 No Content` HTTP 응답과 빈 본문이 예상됩니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```
