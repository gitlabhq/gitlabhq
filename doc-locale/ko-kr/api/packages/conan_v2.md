---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Conan v2 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 17.11에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/519741) [플래그](../../administration/feature_flags/_index.md)가 있는 `conan_package_revisions_support`입니다. 기본적으로 비활성화됨.
- [GitLab.com에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/14896) (GitLab 18.3). 기능 플래그 `conan_package_revisions_support` 제거됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

이 API를 [Conan v2 패키지 레지스트리](../../user/packages/conan_2_repository/_index.md)와 상호작용하는 데 사용합니다. Conan v1 작업의 경우 [Conan v1 API](conan_v1.md)를 참조하세요.

> [!note]
> 이러한 엔드포인트는 표준 API 인증 방법을 준수하지 않습니다. 자격 증명을 전달하는 방법에 대한 자세한 내용은 각 경로를 참조하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

일반적으로 이 끝점들은 [Conan 2 패키지 관리자 클라이언트](https://docs.conan.io/2/index.html)에서 사용되며 수동으로 사용하기 위한 것이 아닙니다.

> [!warning]
> Conan 레지스트리는 FIPS 호환이 아니며 FIPS 모드가 활성화되면 비활성화됩니다. 이 엔드포인트는 모두 `404 Not Found`을 반환합니다.

## 인증 토큰 생성 {#create-an-authentication-token}

다른 요청에서 Bearer 헤더로 사용하기 위한 JSON 웹 토큰(JWT)을 생성합니다.

```shell
"Authorization: Bearer <authenticate_token>
```

Conan 2 패키지 관리자 클라이언트가 이 토큰을 자동으로 사용합니다.

```plaintext
GET /projects/:id/packages/conan/v2/users/authenticate
```

| 속성 | 유형   | 필수      | 설명                                                                  |
| --------- | ------ | ------------- | ---------------------------------------------------------------------------- |
| `id`      | 문자열 | 조건부 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. 프로젝트 엔드포인트에만 필수입니다. |

base64로 인코딩된 기본 인증 토큰을 생성합니다:

```shell
echo -n "<username>:<your_access_token>"|base64
```

base64로 인코딩된 기본 인증 토큰을 사용하여 JWT 토큰을 가져옵니다:

```shell
curl --request GET \
     --header 'Authorization: Basic <base64_encoded_token>' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v2/users/authenticate"
```

응답 예:

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## 인증 자격 증명 확인 {#verify-authentication-credentials}

기본 인증 자격 증명 또는 Conan v1 [`/authenticate`](conan_v1.md#create-an-authentication-token) 끝점에서 생성된 지정된 Conan JWT의 유효성을 확인합니다.

```plaintext
GET /projects/:id/packages/conan/v2/users/check_credentials
```

| 속성 | 유형   | 필수 | 설명                          |
| --------- | ------ | -------- | ------------------------------------ |
| `id`      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다. |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan/v2/users/check_credentials"
```

응답 예:

```plaintext
ok
```

## Conan 패키지 검색 {#search-for-a-conan-package}

프로젝트에서 지정된 Conan 패키지를 검색합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/search?q=:query
```

| 속성 | 유형   | 필수 | 설명                                  |
| --------- | ------ | -------- | -------------------------------------------- |
| `id`      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.         |
| `query`   | 문자열 | 예      | 검색 쿼리입니다. `*`을 와일드카드로 사용할 수 있습니다. |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/search?q=Hello*"
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

## 최신 레시피 수정본 검색 {#retrieve-latest-recipe-revision}

최신 패키지 레시피의 수정본 해시 및 생성 날짜를 검색합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/latest
```

| 속성          | 유형   | 필수 | 설명                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`     | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`  | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username` | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`  | 문자열 | 예      | 패키지의 채널입니다.                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/latest"
```

응답 예:

```json
{
  "revision" : "75151329520e7685dcf5da49ded2fec0",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## 모든 레시피 수정본 나열 {#list-all-recipe-revisions}

패키지 레시피의 모든 수정본을 나열합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions
```

| 속성          | 유형   | 필수 | 설명                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`     | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`  | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username` | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`  | 문자열 | 예      | 패키지의 채널입니다.                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions"
```

응답 예:

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable",
  "revisions": [
    {
      "revision": "75151329520e7685dcf5da49ded2fec0",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "df28fd816be3a119de5ce4d374436b25",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## 레시피 수정본 삭제 {#delete-a-recipe-revision}

레지스트리에서 지정된 레시피 수정본을 삭제합니다. 패키지에 레시피 수정본이 하나뿐인 경우 패키지도 함께 삭제됩니다.

```plaintext
DELETE /projects/:id/packages/conan/conans/:package_name/package_version/:package_username/:package_channel/revisions/:recipe_revision
```

| 속성          | 유형   | 필수 | 설명                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`     | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`  | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username` | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`  | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`  | 문자열 | 예      | 삭제할 레시피 수정본의 수정본 해시입니다.                                                |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/2be19f5a69b2cb02ab576755252319b9"
```

## 모든 레시피 파일 나열 {#list-all-recipe-files}

패키지 레지스트리의 모든 레시피 파일을 나열합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files
```

| 속성          | 유형   | 필수 | 설명                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`     | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`  | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username` | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`  | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`  | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                     |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files"
```

응답 예:

```json
{
  "files": {
    "conan_sources.tgz": {},
    "conanfile.py": {},
    "conanmanifest.txt": {}
  }
}
```

## 레시피 파일 검색 {#retrieve-a-recipe-file}

패키지 레지스트리에서 지정된 레시피 파일을 검색합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| 속성          | 유형   | 필수 | 설명                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`     | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`  | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username` | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`  | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`  | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                     |
| `file_name`        | 문자열 | 예      | 요청된 파일의 이름과 파일 확장자입니다.                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py"
```

다음을 사용하여 출력을 파일로 쓸 수도 있습니다:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py" \
     >> conanfile.py
```

이 예시는 현재 디렉토리에 `conanfile.py`로 씁니다.

## 레시피 파일 업로드 {#upload-a-recipe-file}

패키지 레지스트리에 지정된 레시피 파일을 업로드합니다.

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| 속성          | 유형   | 필수 | 설명                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`     | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`  | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username` | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`  | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`  | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                     |
| `file_name`        | 문자열 | 예      | 요청된 파일의 이름과 파일 확장자입니다.                                          |

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conanfile.py \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/upload-v2-package/1.0.0/user/stable/revisions/123456789012345678901234567890ab/files/conanfile.py"
```

응답 예:

```json
{
  "id": 38,
  "package_id": 28,
  "created_at": "2025-04-07T12:35:40.841Z",
  "updated_at": "2025-04-07T12:35:40.841Z",
  "size": 24,
  "file_store": 1,
  "file_md5": "131f806af123b497209a516f46d12ffd",
  "file_sha1": "01b992b2b1976a3f4c1e5294d0cab549cd438502",
  "file_name": "conanfile.py",
  "file": {
    "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/28/files/38/conanfile.py"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## 모든 패키지 수정본 나열 {#list-all-package-revisions}

특정 레시피 수정본 및 패키지 참조에 대한 모든 패키지 수정본을 나열합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions
```

| 속성                 | 유형   | 필수 | 설명                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`            | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`         | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username`        | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`         | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`         | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                     |
| `conan_package_reference` | 문자열 | 예      | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다.                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions"
```

응답 예:

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable#75151329520e7685dcf5da49ded2fec0:103f6067a947f366ef91fc1b7da351c588d1827f",
  "revisions": [
    {
      "revision": "2bfb52659449d84ed11356c353bfbe86",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "3bdd2d8c8e76c876ebd1ac0469a4e72c",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## 최신 패키지 수정본 검색 {#retrieve-latest-package-revision}

지정된 레시피 수정본 및 패키지 참조에 대한 최신 패키지 수정본의 수정본 해시 및 생성 날짜를 검색합니다.

```plaintext
GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/latest
```

| 속성                 | 유형   | 필수 | 설명                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`            | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`         | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username`        | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`         | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`         | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                     |
| `conan_package_reference` | 문자열 | 예      | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다.                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/latest"
```

응답 예:

```json
{
  "revision" : "3bdd2d8c8e76c876ebd1ac0469a4e72c",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## 패키지 수정본 삭제 {#delete-a-package-revision}

레지스트리에서 지정된 패키지 수정본을 삭제합니다. 패키지 참조에 패키지 수정본이 하나뿐인 경우 패키지 참조도 함께 삭제됩니다.

```plaintext
DELETE /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision
```

| 속성                 | 유형   | 필수 | 설명                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`            | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`         | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username`        | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`         | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`         | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                             |
| `conan_package_reference` | 문자열 | 예      | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다.                              |
| `package_revision`        | 문자열 | 예      | 패키지의 리비전입니다. `0`의 값을 허용하지 않습니다.                                    |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c"
```

## 패키지 파일 검색 {#retrieve-a-package-file}

패키지 레지스트리에서 지정된 패키지 파일을 검색합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| 속성                 | 유형   | 필수 | 설명                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`            | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`         | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username`        | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`         | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`         | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                     |
| `conan_package_reference` | 문자열 | 예      | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다.                              |
| `package_revision`        | 문자열 | 예      | 패키지의 리비전입니다. `0`의 값을 허용하지 않습니다.                                    |
| `file_name`               | 문자열 | 예      | 요청된 파일의 이름과 파일 확장자입니다.                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

다음을 사용하여 출력을 파일로 쓸 수도 있습니다:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt" \
     >> conaninfo.txt
```

이 예시는 현재 디렉토리에 `conaninfo.txt`로 씁니다.

## 패키지 파일 업로드 {#upload-a-package-file}

패키지 레지스트리에 지정된 패키지 파일을 업로드합니다.

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| 속성                 | 유형   | 필수 | 설명                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다.                                                        |
| `package_name`            | 문자열 | 예      | 패키지의 이름입니다.                                                                          |
| `package_version`         | 문자열 | 예      | 패키지의 버전입니다.                                                                       |
| `package_username`        | 문자열 | 예      | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`         | 문자열 | 예      | 패키지의 채널입니다.                                                                       |
| `recipe_revision`         | 문자열 | 예      | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다.                                     |
| `conan_package_reference` | 문자열 | 예      | Conan 패키지의 참조 해시입니다. Conan이 이 값을 생성합니다.                              |
| `package_revision`        | 문자열 | 예      | 패키지의 리비전입니다. `0`의 값을 허용하지 않습니다.                                    |
| `file_name`               | 문자열 | 예      | 요청된 파일의 이름과 파일 확장자입니다.                                          |

요청 본문에 파일 컨텍스트를 제공합니다:

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conaninfo.txt \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

응답 예:

```json
{
  "id": 202,
  "package_id": 48,
  "created_at": "2025-03-19T10:06:53.626Z",
  "updated_at": "2025-03-19T10:06:53.626Z",
  "size": 208,
  "file_store": 1,
  "file_md5": "bf996313bbdd75944b58f8c673661d99",
  "file_sha1": "02c8adf14c94135fb95d472f96525063efe09ee8",
  "file_name": "conaninfo.txt",
  "file": {
      "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/48/files/202/conaninfo.txt"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## 패키지 참조 메타데이터 검색 {#retrieve-package-references-metadata}

지정된 패키지의 모든 패키지 참조에 대한 메타데이터를 검색합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/search
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 예 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/search"
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
- `requires`:  패키지의 필수 종속성입니다.
- `recipe_hash`:  레시피의 해시입니다.

## 레시피 수정본별 패키지 참조 메타데이터 검색 {#retrieve-package-references-metadata-by-recipe-revision}

지정된 레시피 수정본과 관련된 모든 패키지 참조에 대한 메타데이터를 검색합니다.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/search
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                | 문자열 | 예 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. |
| `package_name`      | 문자열 | 예 | 패키지의 이름입니다. |
| `package_version`   | 문자열 | 예 | 패키지의 버전입니다. |
| `package_username`  | 문자열 | 예 | 패키지의 Conan 사용자 이름입니다. 이 속성은 `+`으로 구분된 프로젝트의 전체 경로입니다. |
| `package_channel`   | 문자열 | 예 | 패키지의 채널입니다. |
| `recipe_revision`   | 문자열 | 예 | 레시피의 리비전입니다. `0`의 값을 허용하지 않습니다. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/search"
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
- `requires`:  패키지의 필수 종속성입니다.
- `recipe_hash`:  레시피의 해시입니다.
