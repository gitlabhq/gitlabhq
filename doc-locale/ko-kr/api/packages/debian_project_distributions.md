---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Debian 프로젝트 배포판 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [기능 플래그로 배포](../../administration/feature_flags/_index.md), 기본적으로 비활성화됨.

{{< /history >}}

이 API를 사용하여 [Debian 프로젝트 배포판](../../user/packages/debian_repository/_index.md)을 관리할 수 있습니다. 이 API는 기본적으로 비활성화된 기능 플래그 뒤에 있습니다. 이 API를 사용하려면 [Debian API 활성화](#enable-the-debian-api)해야 합니다.

> [!warning]
> 이 API는 개발 중이며 프로덕션 용도로는 사용되지 않습니다.

## Debian API 활성화 {#enable-the-debian-api}

Debian API는 기본적으로 비활성화된 기능 플래그 뒤에 있습니다. [GitLab Rails 콘솔에 액세스할 수 있는 GitLab 관리자](../../administration/feature_flags/_index.md)는 활성화를 선택할 수 있습니다. 활성화하려면 [Debian API 활성화](../../user/packages/debian_repository/_index.md#enable-the-debian-api)의 지침을 따릅니다.

## Debian 배포 API 인증 {#authenticate-to-the-debian-distributions-apis}

[Debian 배포 API 인증](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-distributions-apis)을 참조하세요.

## 프로젝트의 모든 Debian 배포판 나열 {#list-all-debian-distributions-in-a-project}

지정된 프로젝트의 모든 Debian 배포판을 나열합니다.

```plaintext
GET /projects/:id/debian_distributions
```

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `codename` | 문자열         | 아니오       | 특정 `codename`으로 필터링합니다. |
| `suite`    | 문자열         | 아니오       | 특정 `suite`으로 필터링합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/debian_distributions"
```

응답 예:

```json
[
  {
    "id": 1,
    "codename": "sid",
    "suite": null,
    "origin": null,
    "label": null,
    "version": null,
    "description": null,
    "valid_time_duration_seconds": null,
    "components": [
      "main"
    ],
    "architectures": [
      "all",
      "amd64"
    ]
  }
]
```

## Debian 프로젝트 배포판 검색 {#retrieve-a-debian-project-distribution}

프로젝트의 지정된 Debian 프로젝트 배포판을 검색합니다.

```plaintext
GET /projects/:id/debian_distributions/:codename
```

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `codename` | 문자열         | 예      | 배포의 `codename`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/debian_distributions/unstable"
```

응답 예:

```json
{
  "id": 1,
  "codename": "sid",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Debian 프로젝트 배포판 키 검색 {#retrieve-a-debian-project-distribution-key}

프로젝트의 지정된 Debian 프로젝트 배포판 키를 검색합니다.

```plaintext
GET /projects/:id/debian_distributions/:codename/key.asc
```

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `codename` | 문자열         | 예      | 배포의 `codename`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/debian_distributions/unstable/key.asc"
```

응답 예:

```plaintext
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: Alice's OpenPGP certificate
Comment: https://www.ietf.org/id/draft-bre-openpgp-samples-01.html

mDMEXEcE6RYJKwYBBAHaRw8BAQdArjWwk3FAqyiFbFBKT4TzXcVBqPTB3gmzlC/U
b7O1u120JkFsaWNlIExvdmVsYWNlIDxhbGljZUBvcGVucGdwLmV4YW1wbGU+iJAE
ExYIADgCGwMFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQTrhbtfozp14V6UTmPy
MVUMT0fjjgUCXaWfOgAKCRDyMVUMT0fjjukrAPoDnHBSogOmsHOsd9qGsiZpgRnO
dypvbm+QtXZqth9rvwD9HcDC0tC+PHAsO7OTh1S1TC9RiJsvawAfCPaQZoed8gK4
OARcRwTpEgorBgEEAZdVAQUBAQdAQv8GIa2rSTzgqbXCpDDYMiKRVitCsy203x3s
E9+eviIDAQgHiHgEGBYIACAWIQTrhbtfozp14V6UTmPyMVUMT0fjjgUCXEcE6QIb
DAAKCRDyMVUMT0fjjlnQAQDFHUs6TIcxrNTtEZFjUFm1M0PJ1Dng/cDW4xN80fsn
0QEA22Kr7VkCjeAEC08VSTeV+QFsmz55/lntWkwYWhmvOgE=
=iIGO
-----END PGP PUBLIC KEY BLOCK-----
```

## Debian 프로젝트 배포판 만들기 {#create-a-debian-project-distribution}

지정된 프로젝트의 Debian 프로젝트 배포판을 만듭니다.

```plaintext
POST /projects/:id/debian_distributions
```

| 속성                     | 유형           | 필수 | 설명 |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `codename`                    | 문자열         | 예      | Debian 배포판의 코드명.  |
| `suite`                       | 문자열         | 아니오       | 새 Debian 배포판의 suite. |
| `origin`                      | 문자열         | 아니오       | 새 Debian 배포판의 origin. |
| `label`                       | 문자열         | 아니오       | 새 Debian 배포판의 label. |
| `version`                     | 문자열         | 아니오       | 새 Debian 배포판의 버전. |
| `description`                 | 문자열         | 아니오       | 새 Debian 배포판의 설명. |
| `valid_time_duration_seconds` | 정수        | 아니오       | 새 Debian 배포판의 유효 시간 기간(초). |
| `components`                  | 문자열 배열   | 아니오       | 새 Debian 배포의 구성 요소 목록입니다. |
| `architectures`               | 문자열 배열   | 아니오       | 새 Debian 배포의 아키텍처 목록입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/debian_distributions?codename=sid"
```

응답 예:

```json
{
  "id": 1,
  "codename": "sid",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Debian 프로젝트 배포판 업데이트 {#update-a-debian-project-distribution}

프로젝트의 지정된 Debian 프로젝트 배포판을 업데이트합니다.

```plaintext
PUT /projects/:id/debian_distributions/:codename
```

| 속성                     | 유형           | 필수 | 설명 |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `codename`                    | 문자열         | 예      | Debian 배포판의 코드명. |
| `suite`                       | 문자열         | 아니오       | Debian 배포의 새 제품군입니다. |
| `origin`                      | 문자열         | 아니오       | Debian 배포의 새 원본입니다. |
| `label`                       | 문자열         | 아니오       | Debian 배포의 새 레이블입니다. |
| `version`                     | 문자열         | 아니오       | Debian 배포의 새 버전입니다. |
| `description`                 | 문자열         | 아니오       | Debian 배포의 새 설명입니다. |
| `valid_time_duration_seconds` | 정수        | 아니오       | Debian 배포의 새 유효한 시간 기간(초)입니다. |
| `components`                  | 문자열 배열   | 아니오       | Debian 배포의 새 구성 요소 목록입니다. |
| `architectures`               | 문자열 배열   | 아니오       | Debian 배포의 새 아키텍처 목록입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/debian_distributions/unstable?suite=new-suite&valid_time_duration_seconds=604800"
```

응답 예:

```json
{
  "id": 1,
  "codename": "sid",
  "suite": "new-suite",
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": 604800,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Debian 프로젝트 배포판 삭제 {#delete-a-debian-project-distribution}

프로젝트의 지정된 Debian 프로젝트 배포판을 삭제합니다.

```plaintext
DELETE /projects/:id/debian_distributions/:codename
```

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `codename` | 문자열         | 예      | Debian 배포판의 코드명. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/debian_distributions/unstable"
```
