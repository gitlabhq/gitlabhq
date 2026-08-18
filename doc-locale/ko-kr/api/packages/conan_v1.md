---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Conan v1 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Conan v2 작업의 경우 [Conan v2 API](conan_v2.md)를 참조하세요.

이 API를 사용하여 [Conan v1 패키지 레지스트리](../../user/packages/conan_1_repository/_index.md)와 상호작용합니다. 이 엔드포인트는 프로젝트와 인스턴스 모두에서 작동합니다.

> [!note]
> 이러한 엔드포인트는 표준 API 인증 방법을 준수하지 않습니다. 자격 증명을 전달하는 방법에 대한 자세한 내용은 각 경로를 참조하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

일반적으로 이 엔드포인트는 [Conan 1 패키지 레지스트리](https://docs.conan.io/en/latest/)에서 사용되며 수동으로 사용하기 위한 것이 아닙니다.

> [!warning]
> Conan 레지스트리는 FIPS 호환이 아니며 FIPS 모드가 활성화되면 비활성화됩니다. 이 엔드포인트는 모두 `404 Not Found`을 반환합니다.

## 인증 토큰 생성 {#create-an-authentication-token}

Conan 패키지 레지스트리 클라이언트에 대한 다른 요청에서 Bearer 헤더로 사용할 JSON Web Token(JWT)을 생성합니다.

```shell
"Authorization: Bearer <authenticate_token>"
```

```plaintext
GET /packages/conan/v1/users/authenticate
GET /projects/:id/packages/conan/v1/users/authenticate
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |

```shell
curl --user <username>:<your_access_token> \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/users/authenticate"
```

응답 예:

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## Conan 패키지 레지스트리 가용성 확인 {#verify-availability-of-a-conan-repository}

GitLab Conan 패키지 레지스트리의 가용성을 확인합니다.

```plaintext
GET /packages/conan/v1/ping
GET /projects/:id/packages/conan/v1/ping
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |

```shell
curl --url "https://gitlab.example.com/api/v4/packages/conan/v1/ping"
```

응답 예:

```json
""
```

## Conan 패키지 검색 {#search-for-a-conan-package}

지정된 Conan 패키지를 인스턴스에서 검색합니다.

```plaintext
GET /packages/conan/v1/conans/search
GET /projects/:id/packages/conan/v1/conans/search
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `q`       | 문자열 | 예 | 검색 쿼리입니다. `*`을 와일드카드로 사용할 수 있습니다. |

```shell
curl --user <username>:<your_access_token> \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/search?q=Hello*"
```

응답 예:

```json
{
  "results": [
    "Hello/0.1@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan_test_prod/stable",
    "Hello/0.2@foo+conan_test_prod/beta",
    "Hello/0.3@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan-reference-test/stable",
    "HelloWorld/0.1@baz+conan-reference-test/beta"
    "hello-world/0.4@buz+conan-test/alpha"
  ]
}
```

## 인증 자격 증명 확인 {#verify-authentication-credentials}

기본 인증 자격 증명 또는 [`/authenticate`](#create-an-authentication-token) 엔드포인트에서 생성된 지정된 Conan JWT의 유효성을 확인합니다.

```plaintext
GET /packages/conan/v1/users/check_credentials
GET /projects/:id/packages/conan/v1/users/check_credentials
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/users/check_credentials"
```

응답 예:

```shell
ok
```

## 레시피 스냅샷 검색 {#retrieve-a-recipe-snapshot}

지정된 Conan 레시피의 파일 스냅샷을 검색합니다. 스냅샷은 파일 이름 목록과 연결된 MD5 해시입니다.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
GET /projects/:id/packages/conan/v1/conans/:package_version/:package_username/:package_channel
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

응답 예:

```json
{
  "conan_sources.tgz": "eadf19b33f4c3c7e113faabf26e76277",
  "conanfile.py": "25e55b96a28f81a14ba8e8a8c99eeace",
  "conanmanifest.txt": "5b6fd77a2ba14303ce4cdb08c87e82ab"
}
```

## 패키지 스냅샷 검색 {#retrieve-a-package-snapshot}

지정된 Conan 패키지 및 참조의 파일 스냅샷을 검색합니다. 스냅샷은 파일 이름 목록과 연결된 MD5 해시입니다.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `conan_package_reference` | 문자열 | 예 | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f"
```

응답 예:

```json
{
  "conan_package.tgz": "749b29bdf72587081ca03ec033ee59dc",
  "conaninfo.txt": "32859d737fe84e6a7ccfa4d64dc0d1f2",
  "conanmanifest.txt": "a86b398e813bd9aa111485a9054a2301"
}
```

## 레시피 매니페스트 검색 {#retrieve-a-recipe-manifest}

지정된 레시피의 파일 목록 및 관련 다운로드 URL을 포함하는 매니페스트를 검색합니다.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

응답 예:

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## 패키지 매니페스트 검색 {#retrieve-a-package-manifest}

지정된 패키지의 파일 목록 및 관련 다운로드 URL을 포함하는 매니페스트를 검색합니다.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `conan_package_reference` | 문자열 | 예 | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/digest"
```

응답 예:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

## 모든 레시피 다운로드 URL 나열 {#list-all-recipe-download-urls}

지정된 레시피의 모든 파일 및 관련 다운로드 URL을 나열합니다. [레시피 매니페스트](#retrieve-a-recipe-manifest) 엔드포인트와 동일한 페이로드를 반환합니다.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

응답 예:

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## 모든 패키지 다운로드 URL 나열 {#list-all-package-download-urls}

지정된 패키지의 모든 파일 및 관련 다운로드 URL을 나열합니다. [패키지 매니페스트](#retrieve-a-package-manifest) 엔드포인트와 동일한 페이로드를 반환합니다.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `conan_package_reference` | 문자열 | 예 | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/download_urls"
```

응답 예:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

## 모든 레시피 업로드 URL 나열 {#list-all-recipe-upload-urls}

지정된 레시피 파일 모음의 업로드 URL을 나열합니다. 요청에는 개별 파일의 이름과 크기가 포함된 JSON 개체가 포함되어야 합니다.

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |

요청 JSON 페이로드 예시:

페이로드에는 파일의 이름과 크기가 모두 포함되어야 합니다.

```json
{
  "conanfile.py": 410,
  "conanmanifest.txt": 130
}
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conanfile.py":410,"conanmanifest.txt":130}' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/upload_urls"
```

응답 예:

```json
{
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## 모든 패키지 업로드 URL 나열 {#list-all-package-upload-urls}

지정된 패키지 파일 모음의 업로드 URL을 나열합니다. 요청에는 개별 파일의 이름과 크기가 포함된 JSON 개체가 포함되어야 합니다.

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `conan_package_reference` | 문자열 | 예 | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다. |

요청 JSON 페이로드 예시:

페이로드에는 파일의 이름과 크기가 모두 포함되어야 합니다.

```json
{
  "conan_package.tgz": 5412,
  "conanmanifest.txt": 130,
  "conaninfo.txt": 210
}
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conan_package.tgz":5412,"conanmanifest.txt":130,"conaninfo.txt":210}' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/upload_urls"
```

응답 예:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
}
```

## 레시피 파일 검색 {#retrieve-a-recipe-file}

패키지 레지스트리에서 지정된 레시피 파일을 검색합니다. [레시피 다운로드 URL](#list-all-recipe-download-urls) 엔드포인트에서 반환한 다운로드 URL을 사용해야 합니다.

```plaintext
GET /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
GET /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `recipe_revision`   | 문자열 | 예 | 레시피의 리비전입니다. GitLab은 아직 Conan 리비전을 지원하지 않으므로 `0`의 기본값이 항상 사용됩니다. |
| `file_name`         | 문자열 | 예 | 요청된 파일의 이름과 파일 확장자입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

다음을 사용하여 출력을 파일로 쓸 수도 있습니다:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py" \
     >> conanfile.py
```

이 예시는 현재 디렉토리에 `conanfile.py`로 씁니다.

## 레시피 파일 업로드 {#upload-a-recipe-file}

패키지 레지스트리에 지정된 레시피 파일을 업로드합니다. [레시피 업로드 URL](#list-all-recipe-upload-urls) 엔드포인트에서 반환한 업로드 URL을 사용해야 합니다.

```plaintext
PUT /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
PUT /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `recipe_revision`   | 문자열 | 예 | 레시피의 리비전입니다. GitLab은 아직 Conan 리비전을 지원하지 않으므로 `0`의 기본값이 항상 사용됩니다. |
| `file_name`         | 문자열 | 예 | 요청된 파일의 이름과 파일 확장자입니다. |

요청 본문에 파일 컨텍스트를 제공합니다:

```shell
curl --request PUT \
     --user <username>:<personal_access_token> \
     --upload-file path/to/conanfile.py \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

## 패키지 파일 검색 {#retrieve-a-package-file}

패키지 레지스트리에서 지정된 패키지 파일을 검색합니다. [패키지 다운로드 URL](#list-all-package-download-urls) 엔드포인트에서 반환한 다운로드 URL을 사용해야 합니다.

```plaintext
GET /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
GET /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `recipe_revision`   | 문자열 | 예 | 레시피의 리비전입니다. GitLab은 아직 Conan 리비전을 지원하지 않으므로 `0`의 기본값이 항상 사용됩니다. |
| `conan_package_reference` | 문자열 | 예 | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다. |
| `package_revision`  | 문자열 | 예 | 패키지의 리비전입니다. GitLab은 아직 Conan 리비전을 지원하지 않으므로 `0`의 기본값이 항상 사용됩니다. |
| `file_name`         | 문자열 | 예 | 요청된 파일의 이름과 파일 확장자입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

다음을 사용하여 출력을 파일로 쓸 수도 있습니다:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt" \
     >> conaninfo.txt
```

이 예시는 현재 디렉토리에 `conaninfo.txt`로 씁니다.

## 패키지 파일 업로드 {#upload-a-package-file}

패키지 레지스트리에 지정된 패키지 파일을 업로드합니다. [패키지 업로드 URL](#list-all-package-upload-urls) 엔드포인트에서 반환한 업로드 URL을 사용해야 합니다.

```plaintext
PUT /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
PUT /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `recipe_revision`   | 문자열 | 예 | 레시피의 리비전입니다. GitLab은 아직 Conan 리비전을 지원하지 않으므로 `0`의 기본값이 항상 사용됩니다. |
| `conan_package_reference` | 문자열 | 예 | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다. |
| `package_revision`  | 문자열 | 예 | 패키지의 리비전입니다. GitLab은 아직 Conan 리비전을 지원하지 않으므로 `0`의 기본값이 항상 사용됩니다. |
| `file_name`         | 문자열 | 예 | 요청된 파일의 이름과 파일 확장자입니다. |

요청 본문에 파일 컨텍스트를 제공합니다:

```shell
curl --request PUT \
     --user <username>:<your_access_token> \
     --upload-file path/to/conaninfo.txt \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

## 레시피 및 패키지 삭제 {#delete-a-recipe-and-package}

패키지 레지스트리에서 지정된 Conan 레시피 및 연관된 패키지 파일을 삭제합니다.

```plaintext
DELETE /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
DELETE /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

응답 예:

```json
{
  "id": 1,
  "project_id": 123,
  "created_at": "2020-08-19T13:17:28.655Z",
  "updated_at": "2020-08-19T13:17:28.655Z",
  "name": "my-package",
  "version": "1.0",
  "package_type": "conan",
  "creator_id": null,
  "status": "default"
}
```

## 패키지 참조 메타데이터 검색 {#retrieve-package-references-metadata}

지정된 패키지의 모든 패키지 참조에 대한 메타데이터를 검색합니다.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/search
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/search
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/search"
```

응답 예:

```json
{
  "103f6067a947f366ef91fc1b7da351c588d1827f": {
    "settings": {
      "arch": "x86_64",
      "build_type": "Release",
      "compiler": "gcc",
      "compiler.libcxx": "libstdc++",
      "compiler.version": "9",
      "os": "Linux"
    },
    "options": {
      "shared": "False"
    },
    "requires": {
      "zlib/1.2.11": null
    },
    "recipe_hash": "75151329520e7685dcf5da49ded2fec0"
  }
}
```

응답에는 각 패키지 참조에 대한 다음 메타데이터가 포함됩니다:

- `settings`:  패키지에 사용되는 빌드 설정입니다.
- `options`:  패키지 옵션입니다.
- `requires`:  패키지에 필요한 종속성입니다.
- `recipe_hash`:  레시피의 해시입니다.
