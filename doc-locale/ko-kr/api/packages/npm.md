---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: npm API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [npm 패키지 관리자 클라이언트](../../user/packages/npm_registry/_index.md)와 상호작용합니다.

> [!warning]
> 이 API는 [npm 패키지 관리자 클라이언트](https://docs.npmjs.com/)에서 사용되며 수동으로 사용하기 위한 것이 아닙니다.

이러한 끝점은 표준 API 인증 방법을 준수하지 않습니다. 지원되는 헤더 및 토큰 유형에 대한 자세한 내용은 [npm 패키지 레지스트리 문서](../../user/packages/npm_registry/_index.md)를 참조하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## 패키지 다운로드 {#download-a-package}

프로젝트에 지정된 npm 패키지를 다운로드합니다. 이 URL은 [메타데이터 엔드포인트](#retrieve-package-metadata)에서 제공됩니다.

```plaintext
GET projects/:id/packages/npm/:package_name/-/:file_name
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name`    | 문자열 | 예      | 패키지의 이름입니다. |
| `file_name`       | 문자열 | 예      | 패키지 파일의 이름입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@my-scope/my-pkg-0.0.1.tgz"
```

파일에 출력을 작성합니다:

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@my-scope/my-pkg-0.0.1.tgz" >> @myscope/my-pkg-0.0.1.tgz
```

다운로드된 파일을 `@myscope/my-pkg-0.0.1.tgz`에 현재 디렉터리로 작성합니다.

## 패키지 파일 업로드 {#upload-a-package-file}

지정된 프로젝트에 대한 패키지를 업로드합니다.

```plaintext
PUT projects/:id/packages/npm/:package_name
```

| 속성      | 유형   | 필수 | 설명                         |
|----------------|--------|----------|-------------------------------------|
| `id`           | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다.            |
| `versions`     | 문자열 | 예      | 패키지 버전 정보입니다.        |

```shell
curl --request PUT
     --header "Content-Type: application/json"
     --data @./path/to/metadata/file.json
     --header "Authorization: Bearer <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope%2fmy-pkg"
```

메타데이터 파일 내용은 npm에서 생성되며 다음과 같이 보입니다:

```json
{
    "_attachments": {
        "@myscope/my-pkg-1.3.7.tgz": {
            "content_type": "application/octet-stream",
            "data": "H4sIAAAAAAAAE+1TQUvDMBjdeb/iI4edZEldV2dPwhARPIjiyXlI26zN1iYhSeeK7L+bNJtednMg4l4OKe+9PF7DF0XzNS0ZVmEfr4wUgxODEJLEMRzjPRJyCYPJNCFRlCTE+dzH1PvJqYscQ2ss1a7KT3PCv8DX/kfwMQRAgjYMpYBuIoIzKtwy6MILG6YNl8Jr0XgyvgpswUyuubJ75TGMDuSaUcsKyDooa1C6De6G8t7GRcG2br4CGxKME3wDR1hmrLexvJKwQLdaS52CkOAFMIrlfMlZsUAwGgHbcgsRcid3fdqade9SFz7u9a1naGsrqX3gHbcPNINDyydWcmN1By+W19x2oU7NcyZMfwn3z/PAqTaruanmUix5+V3UXVKq9yEoRZW1yqQYl9zWNBvnssFUcbyJsdJyxXJrcHQdz8gsTg6PzGChGty3H+6Gvz0BZ5xxxn/FJ1EDRNIACAAA",
            "length": 354
        }
    },
    "_id": "@myscope/my-pkg",
    "description": "Package created by me",
    "dist-tags": {
        "latest": "1.3.7"
    },
    "name": "@myscope/my-pkg",
    "readme": "ERROR: No README data found!",
    "versions": {
        "1.3.7": {
            "_id": "@myscope/my-pkg@1.3.7",
            "_nodeVersion": "12.18.4",
            "_npmVersion": "6.14.6",
            "author": {
                "name": "GitLab package registry Utility"
            },
            "description": "Package created by me",
            "dist": {
                "integrity": "sha512-loy16p+Dtw2S43lBmD3Nye+t+Vwv7Tbhv143UN2mwcjaHJyBfGZdNCTXnma3gJCUSE/AR4FPGWEyCOOTJ+ev9g==",
                "shasum": "4a9dbd94ca6093feda03d909f3d7e6bd89d9d4bf",
                "tarball": "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@myscope/my-pkg-1.3.7.tgz"
            },
            "keywords": [],
            "license": "ISC",
            "main": "index.js",
            "name": "@myscope/my-pkg",
            "publishConfig": {
                "@myscope:registry": "https://gitlab.example.com/api/v4/projects/1/packages/npm"
            },
            "readme": "ERROR: No README data found!",
            "scripts": {
                "test": "echo \"Error: no test specified\" && exit 1"
            },
            "version": "1.3.7"
        }
    }
}
```

## 경로 접두사 {#route-prefix}

나머지 경로의 경우 서로 다른 범위에서 요청을 만드는 두 세트의 동일한 경로가 있습니다:

- 인스턴스 수준 접두사를 사용하여 전체 인스턴스의 범위에서 요청을 만듭니다.
- 프로젝트 수준 접두사를 사용하여 단일 프로젝트의 범위에서 요청을 만듭니다.
- 그룹 수준 접두사를 사용하여 그룹의 범위에서 요청을 만듭니다.

이 문서의 예제는 모두 프로젝트 수준 접두사를 사용합니다.

### 인스턴스 수준 {#instance-level}

```plaintext
/packages/npm
```

### 프로젝트 수준 {#project-level}

```plaintext
/projects/:id/packages/npm
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다. |

### 그룹 수준 {#group-level}

{{< history >}}

- GitLab 16.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/299834) [플래그](../../administration/feature_flags/_index.md) `npm_group_level_endpoints` 이름 지정. 기본적으로 비활성화됨.
- GitLab 16.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121837)합니다. 기능 플래그 `npm_group_level_endpoints` 제거됨.

{{< /history >}}

```plaintext
/groups/:id/-/packages/npm
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 그룹 ID 또는 전체 그룹 경로입니다. |

## 패키지 메타데이터 검색 {#retrieve-package-metadata}

지정된 패키지에 대한 메타데이터를 검색합니다.

```plaintext
GET <route-prefix>/:package_name
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg"
```

응답 예:

```json
{
  "name": "@myscope/my-pkg",
  "versions": {
    "0.0.2": {
      "name": "@myscope/my-pkg",
      "version": "0.0.1",
      "dist": {
        "shasum": "93abb605b1110c0e3cca0a5b805e5cb01ac4ca9b",
        "tarball": "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@myscope/my-pkg-0.0.1.tgz"
      }
    }
  },
  "dist-tags": {
    "latest": "0.0.1"
  }
}
```

응답의 URL은 요청에 사용된 경로 접두사와 동일합니다. 인스턴스 수준 경로로 요청하면 반환된 URL에는 `/api/v4/packages/npm`가 포함됩니다.

## 배포 태그 {#dist-tags}

### 모든 배포 태그 나열 {#list-all-dist-tags}

지정된 패키지에 대한 모든 배포 태그를 나열합니다.

```plaintext
GET <route-prefix>/-/package/:package_name/dist-tags
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags"
```

응답 예:

```json
{
  "latest": "2.1.1",
  "stable": "1.0.0"
}
```

응답의 URL은 요청에 사용된 경로 접두사와 동일합니다. 인스턴스 수준 경로로 요청하면 반환된 URL에는 `/api/v4/packages/npm`가 포함됩니다.

### 배포 태그 생성 또는 업데이트 {#create-or-update-a-dist-tag}

패키지에 대한 지정된 배포 태그를 생성하거나 업데이트합니다.

```plaintext
PUT <route-prefix>/-/package/:package_name/dist-tags/:tag
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |
| `tag`          | 문자열 | 예      | 생성하거나 업데이트할 태그입니다. |
| `version`      | 문자열 | 예      | 태그로 지정할 버전입니다. |

```shell
curl --request PUT --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags/stable"
```

이 엔드포인트는 `204 No Content`로 성공적으로 응답합니다.

### 배포 태그 삭제 {#delete-a-dist-tag}

패키지에 대한 지정된 배포 태그를 삭제합니다.

```plaintext
DELETE <route-prefix>/-/package/:package_name/dist-tags/:tag
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |
| `tag`          | 문자열 | 예      | 생성하거나 업데이트할 태그입니다. |

```shell
curl --request DELETE --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags/stable"
```

이 엔드포인트는 `204 No Content`로 성공적으로 응답합니다.
