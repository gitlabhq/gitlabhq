---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 패키지 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/349418) 된 [GitLab CI/CD 작업 토큰](../ci/jobs/ci_job_token.md) 인증 지원(GitLab 15.3의 프로젝트 수준 API).

{{< /history >}}

이 API를 사용하여 [GitLab 패키지](../administration/packages/_index.md)와 상호 작용합니다.

## 패키지 나열 {#list-packages}

{{< history >}}

- `pipelines` [폐기됨](https://gitlab.com/gitlab-org/gitlab/-/issues/341950)(GitLab 16.1).

{{< /history >}}

### 프로젝트의 경우 {#for-a-project}

지정된 프로젝트의 모든 패키지를 나열합니다. 모든 패키지 유형이 결과에 포함됩니다. 인증 없이 액세스할 때는 공개 프로젝트의 패키지만 반환됩니다. 기본적으로 `default`, `deprecated`, `error` 상태의 패키지가 반환됩니다. `status` 매개변수를 사용하여 다른 패키지를 봅니다.

```plaintext
GET /projects/:id/packages
```

| 속성             | 유형           | 필수 | 설명 |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `order_by`            | 문자열         | 아니요       | 정렬에 사용할 필드입니다. `created_at` (기본값), `name`, `version` 또는 `type` 중 하나입니다. |
| `sort`                | 문자열         | 아니요       | 정렬 방향입니다. `asc` (기본값)은 오름차순, `desc`는 내림차순입니다. |
| `package_type`        | 문자열         | 아니요       | 유형별로 반환된 패키지를 필터링합니다. `composer`, `conan`, `generic`, `golang`, `helm`, `maven`, `npm`, `nuget`, `pypi` 또는 `terraform_module` 중 하나입니다. |
| `package_name`        | 문자열         | 아니요       | 이름으로 퍼지 검색을 사용하여 프로젝트 패키지를 필터링합니다. |
| `package_version`     | 문자열         | 아니요       | 버전별로 프로젝트 패키지를 필터링합니다. `include_versionless`과 함께 사용하면 버전 없는 패키지가 반환되지 않습니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/349065)(GitLab 16.6). |
| `include_versionless` | 부울        | 아니요       | true로 설정하면 버전 없는 패키지가 응답에 포함됩니다. |
| `status`              | 문자열         | 아니요       | 상태별로 반환된 패키지를 필터링합니다. `default`, `hidden`, `processing`, `error`, `pending_destruction` 또는 `deprecated` 중 하나입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "created_at": "2019-11-27T03:37:38.711Z",
    "creator_id": 1,
    "pipeline": {
      "id": 123,
      "status": "pending",
      "ref": "new-pipeline",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "web_url": "https://example.com/foo/bar/pipelines/47",
      "created_at": "2016-08-11T11:28:34.085Z",
      "updated_at": "2016-08-11T11:32:35.169Z",
      "user": {
        "name": "Administrator",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
      }
    },
    "pipelines": [],
    "tags": []
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "created_at": "2019-11-27T03:37:38.711Z",
    "tags": []
  }
]
```

기본적으로 `GET` 요청은 API가 [페이지가 나뉘어](rest/_index.md#pagination) 있기 때문에 20개 결과를 반환합니다.

`processing` 상태의 패키지로 작업하면 데이터가 손상되거나 패키지가 손상될 수 있습니다.

### 그룹의 경우 {#for-a-group}

전제 조건:

- 그룹 계층 구조의 최소 1개 프로젝트에 대한 기자, 보안 관리자, 개발자, 유지보수자 또는 소유자 역할.

지정된 그룹의 모든 패키지를 나열합니다. 인증 없이 액세스할 때는 공개 프로젝트의 패키지만 반환됩니다. 기본적으로 `default`, `deprecated`, `error` 상태의 패키지가 반환됩니다. `status` 매개변수를 사용하여 다른 패키지를 봅니다.

이 권한 모델은 GraphQL `Group.packages` 필드와 일치하므로 REST 및 GraphQL 끝점이 동일한 호출자에 대해 동일한 패키지를 반환합니다.

```plaintext
GET /groups/:id/packages
```

| 속성             | 유형           | 필수 | 설명 |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `exclude_subgroups`   | 부울        | 아니요       | 매개변수가 true로 포함되면 하위 그룹의 프로젝트에서 패키지가 나열되지 않습니다. 기본값은 `false`입니다. |
| `order_by`            | 문자열         | 아니요       | 정렬에 사용할 필드입니다. `created_at` (기본값), `name`, `version`, `type` 또는 `project_path` 중 하나입니다. |
| `sort`                | 문자열         | 아니요       | 정렬 방향입니다. `asc` (기본값)은 오름차순, `desc`는 내림차순입니다. |
| `package_type`        | 문자열         | 아니요       | 유형별로 반환된 패키지를 필터링합니다. `composer`, `conan`, `generic`, `golang`, `helm`, `maven`, `npm`, `nuget`, `pypi` 또는 `terraform_module` 중 하나입니다. |
| `package_name`        | 문자열         | 아니요       | 이름으로 퍼지 검색을 사용하여 프로젝트 패키지를 필터링합니다. |
| `package_version`     | 문자열         | 아니요       | 버전별로 반환된 패키지를 필터링합니다. `include_versionless`과 함께 사용하면 버전 없는 패키지가 반환되지 않습니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/349065)(GitLab 16.6). |
| `include_versionless` | 부울        | 아니요       | true로 설정하면 버전 없는 패키지가 응답에 포함됩니다. |
| `status`              | 문자열         | 아니요       | 상태별로 반환된 패키지를 필터링합니다. `default`, `hidden`, `processing`, `error`, `pending_destruction` 또는 `deprecated` 중 하나입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/packages?exclude_subgroups=false"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "creator_id": 1,
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  }
]
```

기본적으로 `GET` 요청은 API가 [페이지가 나뉘어](rest/_index.md#pagination) 있기 때문에 20개 결과를 반환합니다.

`creator_id` 필드는 패키지를 생성한 사용자의 ID를 포함합니다. 이 필드는 패키지가 배포 토큰 또는 작업 토큰으로 생성된 경우 `null`입니다.

`_links` 개체에는 다음 속성이 포함됩니다:

- `web_path`:  GitLab에서 방문하여 패키지의 세부 정보를 볼 수 있는 경로입니다.
- `delete_api_path`:  패키지를 삭제하는 API 경로입니다. 요청 사용자가 권한이 있는 경우에만 사용 가능합니다.

`processing` 상태의 패키지로 작업하면 데이터가 손상되거나 패키지가 손상될 수 있습니다.

## 프로젝트 패키지 검색 {#retrieve-a-project-package}

{{< history >}}

- `pipelines` [폐기됨](https://gitlab.com/gitlab-org/gitlab/-/issues/341950)(GitLab 16.1).

{{< /history >}}

지정된 프로젝트 패키지를 검색합니다. `default` 또는 `deprecated` 상태의 패키지만 반환됩니다.

```plaintext
GET /projects/:id/packages/:package_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `package_id`      | 정수 | 예 | 패키지의 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

응답 예시:

```json
{
  "id": 1,
  "name": "com/mycompany/my-app",
  "version": "1.0-SNAPSHOT",
  "package_type": "maven",
  "_links": {
    "web_path": "/namespace1/project1/-/packages/1",
    "delete_api_path": "/namespace1/project1/-/packages/1"
  },
  "created_at": "2019-11-27T03:37:38.711Z",
  "last_downloaded_at": "2022-09-07T07:51:50.504Z",
  "creator_id": 1,
  "pipelines": [
    {
      "id": 123,
      "status": "pending",
      "ref": "new-pipeline",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "web_url": "https://example.com/foo/bar/pipelines/47",
      "created_at": "2016-08-11T11:28:34.085Z",
      "updated_at": "2016-08-11T11:32:35.169Z",
      "user": {
        "name": "Administrator",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
      }
    }
  ],
  "versions": [
    {
      "id":2,
      "version":"2.0-SNAPSHOT",
      "created_at":"2020-04-28T04:42:11.573Z",
      "pipelines": [
        {
          "id": 234,
          "status": "pending",
          "ref": "new-pipeline",
          "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
          "web_url": "https://example.com/foo/bar/pipelines/58",
          "created_at": "2016-08-11T11:28:34.085Z",
          "updated_at": "2016-08-11T11:32:35.169Z",
          "user": {
            "name": "Administrator",
            "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
          }
        }
      ]
    }
  ]
}
```

`creator_id` 필드는 패키지를 생성한 사용자의 ID를 포함합니다. 이 필드는 패키지가 배포 토큰 또는 작업 토큰으로 생성된 경우 `null`입니다.

`_links` 개체에는 다음 속성이 포함됩니다:

- `web_path`:  GitLab에서 방문하여 패키지의 세부 정보를 볼 수 있는 경로입니다. `default` 또는 `deprecated` 상태의 패키지가 있는 경우에만 사용 가능합니다.
- `delete_api_path`:  패키지를 삭제하는 API 경로입니다. 요청 사용자가 권한이 있는 경우에만 사용 가능합니다.

## 패키지 파일 나열 {#list-package-files}

지정된 패키지의 모든 패키지 파일을 나열합니다.

```plaintext
GET /projects/:id/packages/:package_id/package_files
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `package_id`      | 정수 | 예 | 패키지의 ID입니다. |
| `order_by`            | 문자열         | 아니요       | 정렬에 사용할 필드입니다. `id` (기본값), `file_name`, `created_at` 중 하나입니다. |
| `sort`                | 문자열         | 아니요       | 정렬 방향입니다. `asc` (기본값)은 오름차순, `desc`는 내림차순입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files"
```

응답 예시:

```json
[
  {
    "id": 25,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:52.199Z",
    "file_name": "my-app-1.5-20181107.152550-1.jar",
    "size": 2421,
    "file_md5": "58e6a45a629910c6ff99145a688971ac",
    "file_sha1": "ebd193463d3915d7e22219f52740056dfd26cbfe",
    "file_sha256": "a903393463d3915d7e22219f52740056dfd26cbfeff321b",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 26,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:56.776Z",
    "file_name": "my-app-1.5-20181107.152550-1.pom",
    "size": 1122,
    "file_md5": "d90f11d851e17c5513586b4a7e98f1b2",
    "file_sha1": "9608d068fe88aff85781811a42f32d97feb440b5",
    "file_sha256": "2987d068fe88aff85781811a42f32d97feb4f092a399"
  },
  {
    "id": 27,
    "package_id": 4,
    "created_at": "2018-11-07T15:26:00.556Z",
    "file_name": "maven-metadata.xml",
    "size": 767,
    "file_md5": "6dfd0cce1203145a927fef5e3a1c650c",
    "file_sha1": "d25932de56052d320a8ac156f745ece73f6a8cd2",
    "file_sha256": "ac849d002e56052d320a8ac156f745ece73f6a8cd2f3e82"
  }
]
```

기본적으로 `GET` 요청은 API가 [페이지가 나뉘어](rest/_index.md#pagination) 있기 때문에 20개 결과를 반환합니다.

## 패키지 파이프라인 나열 {#list-package-pipelines}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/341950)(GitLab 16.1).

{{< /history >}}

지정된 패키지의 모든 파이프라인을 나열합니다. 결과는 `id`을 기준으로 내림차순으로 정렬됩니다.

결과는 [페이지가 나뉘어](rest/_index.md#keyset-based-pagination) 있으며 페이지당 최대 20개의 레코드를 반환합니다.

```plaintext
GET /projects/:id/packages/:package_id/pipelines
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `package_id`      | 정수 | 예 | 패키지의 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/pipelines"
```

응답 예시:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 9,
    "sha": "2b6127f6bb6f475c4e81afcc2251e3f941e554f9",
    "ref": "mytag",
    "status": "failed",
    "source": "push",
    "created_at": "2023-02-01T12:19:21.895Z",
    "updated_at": "2023-02-01T14:00:05.922Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/1",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  },
  {
    "id": 2,
    "iid": 2,
    "project_id": 9,
    "sha": "e564015ac6cb3d8617647802c875b27d392f72a6",
    "ref": "main",
    "status": "canceled",
    "source": "push",
    "created_at": "2023-02-01T12:23:23.694Z",
    "updated_at": "2023-02-01T12:26:28.635Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/2",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  }
]
```

## 프로젝트 패키지 삭제 {#delete-a-project-package}

지정된 프로젝트 패키지를 삭제합니다.

```plaintext
DELETE /projects/:id/packages/:package_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `package_id`      | 정수 | 예 | 패키지의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

다음 상태 코드를 반환할 수 있습니다:

- `204 No Content`:  패키지가 성공적으로 삭제되었습니다.
- `403 Forbidden`:  패키지가 삭제로부터 보호됩니다.
- `404 Not Found`:  패키지를 찾을 수 없습니다.

[요청 전달](../user/packages/package_registry/supported_functionality.md#forwarding-requests) 이 활성화된 경우, 패키지를 삭제하면 [종속성 혼동 위험](../user/packages/package_registry/supported_functionality.md#deleting-packages)을 야기할 수 있습니다.

패키지가 [보호 규칙](../user/packages/package_registry/package_protection_rules.md#protect-a-package)으로 보호되면 패키지 삭제가 금지됩니다.

## 패키지 파일 삭제 {#delete-a-package-file}

> [!warning]
> 패키지 파일을 삭제하면 패키지가 손상되어 패키지 관리자 클라이언트에서 사용할 수 없거나 끌어올 수 없게 될 수 있습니다. 패키지 파일을 삭제할 때는 자신이 하는 일을 이해하고 있는지 확인하세요.

지정된 패키지 파일을 삭제합니다.

```plaintext
DELETE /projects/:id/packages/:package_id/package_files/:package_file_id
```

| 속성         | 유형           | 필수 | 설명 |
| ----------------- | -------------- | -------- | ----------- |
| `id`              | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `package_id`      | 정수        | 예 | 패키지의 ID입니다. |
| `package_file_id` | 정수        | 예 | 패키지 파일의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files/:package_file_id"
```

다음 상태 코드를 반환할 수 있습니다:

- `204 No Content`:  패키지가 성공적으로 삭제되었습니다.
- `403 Forbidden`:  사용자는 파일을 삭제할 권한이 없거나 패키지가 삭제로부터 보호됩니다.
- `404 Not Found`:  패키지 또는 패키지 파일을 찾을 수 없습니다.

패키지 파일이 속한 패키지가 [보호 규칙](../user/packages/package_registry/package_protection_rules.md#protect-a-package)으로 보호되면 패키지 파일 삭제가 금지됩니다.
