---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 Git 태그에 대한REST API 문서입니다.
title: 태그 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Git 태그](../user/project/repository/tags/_index.md)를 관리하려면 이 API를 사용합니다. 이 API는 서명된 태그의 X.509 서명 정보도 반환합니다.

## 모든 프로젝트 리포지토리 태그 나열 {#list-all-project-repository-tags}

{{< history >}}

- `created_at` 응답 속성은 GitLab 16.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/451011).

{{< /history >}}

프로젝트의 모든 리포지토리 태그를 나열하며, 업데이트 날짜와 시간을 내림차순으로 정렬합니다.

> [!note]
> 리포지토리가 공개적으로 접근 가능한 경우 인증(`--header "PRIVATE-TOKEN: <your_access_token>"`)이 필요하지 않습니다.

```plaintext
GET /projects/:id/repository/tags
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `order_by`   | 문자열            | 아니요       | 태그를 `name`, `updated`, 또는 `version`로 정렬하여 반환합니다. `version`는 의미론적 버전 번호로 정렬합니다. 기본값은 `updated`입니다. |
| `page`       | 정수           | 아니요       | 페이지 매김의 현재 페이지 번호입니다. 기본값은 `1`입니다. |
| `page_token` | 문자열            | 아니요       | 페이지 매김을 시작할 태그의 이름입니다. 키 집합 페이지 매김에 사용됩니다. |
| `search`     | 문자열            | 아니요       | 검색 기준과 일치하는 태그 목록을 반환합니다. `^term` 및 `term$`를 사용하여 `term`로 시작하고 끝나는 태그를 찾을 수 있습니다. 다른 정규식은 지원되지 않습니다. |
| `sort`       | 문자열            | 아니요       | 태그를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 표시합니다:

| 속성                | 유형    | 설명 |
|--------------------------|---------|-------------|
| `commit`                 | 객체  | 태그와 연결된 커밋 정보입니다. |
| `commit.author_email`    | 문자열  | 커밋 작성자의 이메일 주소입니다. |
| `commit.author_name`     | 문자열  | 커밋 작성자의 이름입니다. |
| `commit.authored_date`   | 문자열  | 커밋이 작성된 ISO 8601 형식의 날짜입니다. |
| `commit.committed_date`  | 문자열  | 커밋이 커밋된 ISO 8601 형식의 날짜입니다. |
| `commit.committer_email` | 문자열  | 커밋자의 이메일 주소입니다. |
| `commit.committer_name`  | 문자열  | 커밋자의 이름입니다. |
| `commit.created_at`      | 문자열  | 커밋이 생성된 ISO 8601 형식의 날짜입니다. |
| `commit.id`              | 문자열  | 커밋의 전체 SHA입니다. |
| `commit.message`         | 문자열  | 커밋 메시지. |
| `commit.parent_ids`      | 배열   | 부모 커밋 SHA의 배열입니다. |
| `commit.short_id`        | 문자열  | 커밋의 짧은 SHA입니다. |
| `commit.title`           | 문자열  | 커밋의 제목입니다. |
| `created_at`             | 문자열  | 태그가 생성된 ISO 8601 형식의 날짜입니다. |
| `message`                | 문자열  | 태그 메시지입니다. |
| `name`                   | 문자열  | 태그의 이름입니다. |
| `protected`              | 부울 | `true`이면 태그가 보호됩니다. |
| `release`                | 객체  | 태그와 연결된 릴리스 정보입니다. |
| `release.description`    | 문자열  | 릴리스의 설명입니다. |
| `release.tag_name`       | 문자열  | 릴리스의 태그 이름입니다. |
| `target`                 | 문자열  | 태그가 가리키는 SHA입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/repository/tags"
```

응답 예시:

```json
[
  {
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "short_id": "2695effb",
      "title": "Initial commit",
      "created_at": "2017-07-26T11:08:53.000+02:00",
      "parent_ids": [
        "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
      ],
      "message": "Initial commit",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committer_name": "Jack Smith",
      "committer_email": "jack@example.com",
      "committed_date": "2012-05-28T04:42:42-07:00"
    },
    "release": {
      "tag_name": "1.0.0",
      "description": "Amazing release. Wow"
    },
    "name": "v1.0.0",
    "target": "2695effb5807a22ff3d138d593fd856244e155e7",
    "message": null,
    "protected": true,
    "created_at": "2017-07-26T11:08:53.000+02:00"
  }
]
```

## 단일 리포지토리 태그 검색 {#retrieve-a-single-repository-tag}

{{< history >}}

- `created_at` 응답 속성은 GitLab 16.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/451011).

{{< /history >}}

지정된 이름의 리포지토리 태그를 검색합니다. 리포지토리가 공개적으로 접근 가능한 경우 인증 없이 이 끝점에 액세스할 수 있습니다.

```plaintext
GET /projects/:id/repository/tags/:tag_name
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `tag_name` | 문자열            | 예      | 태그의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 표시합니다:

| 속성                | 유형    | 설명 |
|--------------------------|---------|-------------|
| `commit`                 | 객체  | 태그와 연결된 커밋 정보입니다. |
| `commit.author_email`    | 문자열  | 커밋 작성자의 이메일 주소입니다. |
| `commit.author_name`     | 문자열  | 커밋 작성자의 이름입니다. |
| `commit.authored_date`   | 문자열  | 커밋이 작성된 ISO 8601 형식의 날짜입니다. |
| `commit.committed_date`  | 문자열  | 커밋이 커밋된 ISO 8601 형식의 날짜입니다. |
| `commit.committer_email` | 문자열  | 커밋자의 이메일 주소입니다. |
| `commit.committer_name`  | 문자열  | 커밋자의 이름입니다. |
| `commit.created_at`      | 문자열  | 커밋이 생성된 ISO 8601 형식의 날짜입니다. |
| `commit.id`              | 문자열  | 커밋의 전체 SHA입니다. |
| `commit.message`         | 문자열  | 커밋 메시지. |
| `commit.parent_ids`      | 배열   | 부모 커밋 SHA의 배열입니다. |
| `commit.short_id`        | 문자열  | 커밋의 짧은 SHA입니다. |
| `commit.title`           | 문자열  | 커밋의 제목입니다. |
| `created_at`             | 문자열  | 태그가 생성된 ISO 8601 형식의 날짜입니다. |
| `message`                | 문자열  | 태그 메시지입니다. |
| `name`                   | 문자열  | 태그의 이름입니다. |
| `protected`              | 부울 | `true`이면 태그가 보호됩니다. |
| `release`                | 객체  | 태그와 연결된 릴리스 정보입니다. |
| `target`                 | 문자열  | 태그가 가리키는 SHA입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags/v1.0.0"
```

응답 예시:

```json
{
  "name": "v5.0.0",
  "message": null,
  "target": "60a8ff033665e1207714d6670fcd7b65304ec02f",
  "commit": {
    "id": "60a8ff033665e1207714d6670fcd7b65304ec02f",
    "short_id": "60a8ff03",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "f61c062ff8bcbdb00e0a1b3317a91aed6ceee06b"
    ],
    "message": "v5.0.0\n",
    "author_name": "Arthur Verschaeve",
    "author_email": "contact@arthurverschaeve.be",
    "authored_date": "2015-02-01T21:56:31.000+01:00",
    "committer_name": "Arthur Verschaeve",
    "committer_email": "contact@arthurverschaeve.be",
    "committed_date": "2015-02-01T21:56:31.000+01:00"
  },
  "release": null,
  "protected": false,
  "created_at": "2017-07-26T11:08:53.000+02:00"
}
```

## 새 태그 생성 {#create-a-new-tag}

{{< history >}}

- `created_at` 응답 속성은 GitLab 16.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/451011).

{{< /history >}}

제공된 참조를 가리키는 리포지토리에 새 태그를 생성합니다.

```plaintext
POST /projects/:id/repository/tags
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `ref`      | 문자열            | 예      | 커밋 SHA, 다른 태그 이름 또는 브랜치 이름에서 태그를 생성합니다. |
| `tag_name` | 문자열            | 예      | 태그의 이름입니다. |
| `message`  | 문자열            | 아니요       | 주석 태그를 생성합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 표시합니다:

| 속성                | 유형    | 설명 |
|--------------------------|---------|-------------|
| `commit`                 | 객체  | 태그와 연결된 커밋 정보입니다. |
| `commit.author_email`    | 문자열  | 커밋 작성자의 이메일 주소입니다. |
| `commit.author_name`     | 문자열  | 커밋 작성자의 이름입니다. |
| `commit.authored_date`   | 문자열  | 커밋이 작성된 ISO 8601 형식의 날짜입니다. |
| `commit.committed_date`  | 문자열  | 커밋이 커밋된 ISO 8601 형식의 날짜입니다. |
| `commit.committer_email` | 문자열  | 커밋자의 이메일 주소입니다. |
| `commit.committer_name`  | 문자열  | 커밋자의 이름입니다. |
| `commit.created_at`      | 문자열  | 커밋이 생성된 ISO 8601 형식의 날짜입니다. |
| `commit.id`              | 문자열  | 커밋의 전체 SHA입니다. |
| `commit.message`         | 문자열  | 커밋 메시지. |
| `commit.parent_ids`      | 배열   | 부모 커밋 SHA의 배열입니다. |
| `commit.short_id`        | 문자열  | 커밋의 짧은 SHA입니다. |
| `commit.title`           | 문자열  | 커밋의 제목입니다. |
| `created_at`             | 문자열  | 태그가 생성된 ISO 8601 형식의 날짜입니다. |
| `message`                | 문자열  | 태그 메시지입니다. |
| `name`                   | 문자열  | 태그의 이름입니다. |
| `protected`              | 부울 | `true`이면 태그가 보호됩니다. |
| `release`                | 객체  | 태그와 연결된 릴리스 정보입니다. |
| `target`                 | 문자열  | 태그가 가리키는 SHA입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags?tag_name=test&ref=main"
```

응답 예시:

```json
{
  "commit": {
    "id": "2695effb5807a22ff3d138d593fd856244e155e7",
    "short_id": "2695effb",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
    ],
    "message": "Initial commit",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-05-28T04:42:42-07:00",
    "committer_name": "Jack Smith",
    "committer_email": "jack@example.com",
    "committed_date": "2012-05-28T04:42:42-07:00"
  },
  "release": null,
  "name": "v1.0.0",
  "target": "2695effb5807a22ff3d138d593fd856244e155e7",
  "message": null,
  "protected": false,
  "created_at": null
}
```

생성된 태그의 유형은 `created_at`, `target` 및 `message`의 내용을 결정합니다:

- 주석 태그의 경우:
  - `created_at`은 태그 생성의 타임스탬프를 포함합니다.
  - `message`은 주석을 포함합니다.
  - `target`은 태그 객체의 ID를 포함합니다.
- 경량 태그의 경우:
  - `created_at`은 null입니다.
  - `message`은 null입니다.
  - `target`은 커밋 ID를 포함합니다.

오류는 상태 코드 `405`을 설명하는 오류 메시지와 함께 반환합니다.

## 태그 삭제 {#delete-a-tag}

지정된 이름의 리포지토리 태그를 삭제합니다.

```plaintext
DELETE /projects/:id/repository/tags/:tag_name
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `tag_name` | 문자열            | 예      | 태그의 이름입니다. |

## 태그의 X.509 서명 검색 {#retrieve-x509-signature-of-a-tag}

서명된 경우 [태그의 X.509 서명](../user/project/repository/signed_commits/x509.md)을 검색합니다. 서명되지 않은 태그는 `404 Not Found` 응답을 반환합니다.

```plaintext
GET /projects/:id/repository/tags/:tag_name/signature
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `tag_name` | 문자열            | 예      | 태그의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 표시합니다:

| 속성                                             | 유형    | 설명 |
|-------------------------------------------------------|---------|-------------|
| `signature_type`                                      | 문자열  | 서명 유형(`X509`)입니다. |
| `verification_status`                                 | 문자열  | 서명의 검증 상태입니다. |
| `x509_certificate`                                    | 객체  | X.509 인증서 정보입니다. |
| `x509_certificate.certificate_status`                 | 문자열  | 인증서의 상태입니다. |
| `x509_certificate.email`                              | 문자열  | 인증서의 이메일 주소입니다. |
| `x509_certificate.id`                                 | 정수 | 인증서의 ID입니다. |
| `x509_certificate.serial_number`                      | 정수 | 인증서의 일련 번호입니다. |
| `x509_certificate.subject`                            | 문자열  | 인증서의 제목입니다. |
| `x509_certificate.subject_key_identifier`             | 문자열  | 인증서의 주체 키 식별자입니다. |
| `x509_certificate.x509_issuer`                        | 객체  | 인증서의 발급자 정보입니다. |
| `x509_certificate.x509_issuer.crl_url`                | 문자열  | 인증서 해지 목록 URL입니다. |
| `x509_certificate.x509_issuer.id`                     | 정수 | 발급자의 ID입니다. |
| `x509_certificate.x509_issuer.subject`                | 문자열  | 발급자의 제목입니다. |
| `x509_certificate.x509_issuer.subject_key_identifier` | 문자열  | 발급자의 주체 키 식별자입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/tags/v1.1.1/signature"
```

태그가 X.509로 서명된 경우 응답 예시:

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  }
}
```

태그가 서명되지 않은 경우 응답 예시:

```json
{
  "message": "404 GPG Signature Not Found"
}
```
