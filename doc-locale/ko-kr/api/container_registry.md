---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 레지스트리 API
description: REST API를 사용하여 GitLab 컨테이너 레지스트리를 관리합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [컨테이너 레지스트리](../user/packages/container_registry/_index.md)를 관리합니다.

CI/CD 작업에서 이러한 엔드포인트에 인증하려면 [`$CI_JOB_TOKEN`](../ci/jobs/ci_job_token.md) 변수를 `JOB-TOKEN` 헤더로 전달하세요. 작업 토큰은 파이프라인을 생성한 프로젝트의 컨테이너 레지스트리에만 액세스할 수 있습니다.

## 컨테이너 레지스트리의 표시 여부 변경 {#change-the-visibility-of-the-container-registry}

지정된 프로젝트의 컨테이너 레지스트리 표시 여부를 변경합니다.

```plaintext
PUT /projects/:id/
```

| 속성                         | 유형              | 필수 | 설명 |
|-----------------------------------|-------------------|----------|-------------|
| `id`                              | 정수 또는 문자열 | 예      | 인증된 사용자가 액세스할 수 있는 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `container_registry_access_level` | 문자열            | 아니요       | 컨테이너 레지스트리의 원하는 표시 여부입니다. `enabled`(기본값), `private`, 또는 `disabled` 중 하나입니다. |

`container_registry_access_level`의 가능한 값에 대한 설명:

- `enabled`(기본값):  컨테이너 레지스트리는 프로젝트에 대한 액세스 권한이 있는 모든 사용자에게 표시됩니다. 프로젝트가 공개이면 컨테이너 레지스트리도 공개입니다. 프로젝트가 내부 또는 비공개이면 컨테이너 레지스트리도 내부 또는 비공개입니다.
- `private`:  컨테이너 레지스트리는 Reporter 역할 이상의 프로젝트 멤버에게만 표시됩니다. 이 동작은 컨테이너 레지스트리 표시 여부가 활성화된 비공개 프로젝트와 유사합니다.
- `disabled`:  컨테이너 레지스트리가 비활성화됩니다.

자세한 내용은 [컨테이너 레지스트리 표시 여부 권한](../user/packages/container_registry/_index.md#container-registry-visibility-permissions)을 참조하세요.

```shell
curl --request PUT "https://gitlab.example.com/api/v4/projects/5/" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "container_registry_access_level": "private"
  }'
```

응답 예시:

```json
{
  "id": 5,
  "name": "Project 5",
  "container_registry_access_level": "private",
  ...
}
```

## 모든 리포지토리 레지스트리 {#list-all-registry-repositories}

### 프로젝트 내 {#within-a-project}

지정된 프로젝트의 모든 리포지토리 레지스트리를 나열합니다.

응답은 [페이지로 나뉘며](rest/_index.md#pagination) 기본적으로 20개의 결과를 반환합니다.

```plaintext
GET /projects/:id/registry/repositories
```

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 인증된 사용자가 액세스할 수 있는 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `tags`       | 부울        | 아니요       | 매개변수가 true로 포함되면 각 리포지토리의 응답에 `"tags"`의 배열이 포함됩니다. |
| `tags_count` | 부울        | 아니요       | 매개변수가 true로 포함되면 각 리포지토리의 응답에 `"tags_count"`이(가) 포함됩니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
    "status": null
  },
  {
    "id": 2,
    "name": "releases",
    "path": "group/project/releases",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project/releases",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
    "status": "delete_ongoing"
  }
]
```

### 그룹 내 {#within-a-group}

{{< history >}}

- GitLab 15.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/336912) `tags` 및 `tag_count` 속성입니다.

{{< /history >}}

지정된 그룹의 모든 리포지토리 레지스트리를 나열합니다.

응답은 [페이지로 나뉘며](rest/_index.md#pagination) 기본적으로 20개의 결과를 반환합니다.

```plaintext
GET /groups/:id/registry/repositories
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 인증된 사용자가 액세스할 수 있는 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/registry/repositories"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
  },
  {
    "id": 2,
    "name": "",
    "path": "group/other_project",
    "project_id": 11,
    "location": "gitlab.example.com:5000/group/other_project",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
  }
]
```

## 단일 리포지토리의 세부 정보 검색 {#retrieve-details-of-a-single-repository}

지정된 리포지토리 레지스트리의 세부 정보를 검색합니다.

```plaintext
GET /registry/repositories/:id
```

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 인증된 사용자가 액세스할 수 있는 리포지토리 레지스트리의 ID입니다. |
| `tags`       | 부울        | 아니요       | 매개변수가 `true`로 포함되면 응답에 `"tags"`의 배열이 포함됩니다. |
| `tags_count` | 부울        | 아니요       | 매개변수가 `true`로 포함되면 응답에 `"tags_count"`이(가) 포함됩니다. |
| `size`       | 부울        | 아니요       | 매개변수가 `true`로 포함되면 응답에 `"size"`이(가) 포함됩니다. 이것은 리포지토리 내의 모든 이미지의 중복 제거된 크기입니다. 중복 제거는 동일한 데이터의 추가 복사본을 제거합니다. 예를 들어 동일한 이미지를 두 번 업로드하면 컨테이너 레지스트리에서는 한 개의 복사본만 저장합니다. 이 필드는 `2021-11-04` 이후에 생성된 리포지토리에 대해 GitLab.com에서만 사용할 수 있습니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/registry/repositories/2?tags=true&tags_count=true&size=true"
```

응답 예시:

```json
{
  "id": 2,
  "name": "",
  "path": "group/project",
  "project_id": 9,
  "location": "gitlab.example.com:5000/group/project",
  "created_at": "2019-01-10T13:38:57.391Z",
  "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
  "tags_count": 1,
  "tags": [
    {
      "name": "0.0.1",
      "path": "group/project:0.0.1",
      "location": "gitlab.example.com:5000/group/project:0.0.1"
    }
  ],
  "size": 2818413,
  "status": "delete_scheduled"
}
```

## 리포지토리 레지스트리 삭제 {#delete-registry-repository}

레지스트리에서 지정된 리포지토리를 삭제합니다.

이 작업은 비동기적으로 실행되며 실행하는 데 시간이 걸릴 수 있습니다.

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id
```

| 속성       | 유형           | 필수 | 설명 |
|-----------------|----------------|----------|-------------|
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `repository_id` | 정수        | 예      | 리포지토리 레지스트리의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## 모든 리포지토리 레지스트리 태그 나열 {#list-all-registry-repository-tags}

### 프로젝트 내 {#within-a-project-1}

{{< history >}}

- Keyset 페이지 매김은 GitLab 16.10에서 GitLab.com 전용으로 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/432470).

{{< /history >}}

지정된 리포지토리 레지스트리의 모든 태그를 나열합니다.

응답은 [페이지로 나뉘며](rest/_index.md#pagination) 기본적으로 20개의 결과를 반환합니다.

> [!note]
> 오프셋 페이지 매김은 더 이상 사용되지 않으며 keyset 페이지 매김이 이제 선호하는 페이지 매김 방법입니다.

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags
```

| 속성       | 유형           | 필수 | 설명 |
|-----------------|----------------|----------|-------------|
| `id`            | 정수 또는 문자열 | 예      | 인증된 사용자가 액세스할 수 있는 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `repository_id` | 정수        | 예      | 리포지토리 레지스트리의 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

응답 예시:

```json
[
  {
    "name": "A",
    "path": "group/project:A",
    "location": "gitlab.example.com:5000/group/project:A"
  },
  {
    "name": "latest",
    "path": "group/project:latest",
    "location": "gitlab.example.com:5000/group/project:latest"
  }
]
```

## 리포지토리 레지스트리 태그의 세부 정보 검색 {#retrieve-details-of-a-registry-repository-tag}

지정된 리포지토리 레지스트리 태그의 세부 정보를 검색합니다.

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| 속성       | 유형           | 필수 | 설명 |
|-----------------|----------------|----------|-------------|
| `id`            | 정수 또는 문자열 | 예      | 인증된 사용자가 액세스할 수 있는 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `repository_id` | 정수        | 예      | 리포지토리 레지스트리의 ID입니다. |
| `tag_name`      | 문자열         | 예      | 태그의 이름입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

응답 예시:

```json
{
  "name": "v10.0.0",
  "path": "group/project:latest",
  "location": "gitlab.example.com:5000/group/project:latest",
  "revision": "e9ed9d87c881d8c2fd3a31b41904d01ba0b836e7fd15240d774d811a1c248181",
  "short_revision": "e9ed9d87c",
  "digest": "sha256:c3490dcf10ffb6530c1303522a1405dfaf7daecd8f38d3e6a1ba19ea1f8a1751",
  "created_at": "2019-01-06T16:49:51.272+00:00",
  "total_size": 350224384
}
```

## 리포지토리 레지스트리 태그 삭제 {#delete-a-registry-repository-tag}

지정된 컨테이너 레지스트리 리포지토리 태그를 삭제합니다.

태그가 프로젝트의 보호 규칙과 일치하면 엔드포인트는 [`403 Forbidden`](rest/troubleshooting.md#status-codes) 오류를 반환합니다. 태그 보호 규칙에 대한 자세한 내용은 [보호된 컨테이너 태그](../user/packages/container_registry/protected_container_tags.md)를 참조하세요.

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| 속성       | 유형           | 필수 | 설명 |
|-----------------|----------------|----------|-------------|
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `repository_id` | 정수        | 예      | 리포지토리 레지스트리의 ID입니다. |
| `tag_name`      | 문자열         | 예      | 태그의 이름입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

이 작업은 blob을 삭제하지 않습니다. 디스크 공간을 확보하려면 [가비지 수집을 실행](../administration/packages/container_registry.md#container-registry-garbage-collection)하세요.

## 리포지토리 레지스트리 태그를 일괄로 삭제 {#delete-registry-repository-tags-in-bulk}

지정된 조건에 따라 리포지토리 레지스트리 태그를 일괄로 삭제합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [컨테이너 레지스트리 API를 사용하여 \*를 제외한 모든 태그 삭제](https://youtu.be/Hi19bKe_xsg)를 참조하세요.

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| 속성           | 유형           | 필수 | 설명 |
|---------------------|----------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `repository_id`     | 정수        | 예      | 리포지토리 레지스트리의 ID입니다. |
| `keep_n`            | 정수        | 아니요       | 유지할 지정된 이름의 최신 태그 개수입니다. |
| `name_regex`        | 문자열         | 아니요       | 삭제할 이름의 [re2](https://github.com/google/re2/wiki/Syntax) 정규식입니다. 모든 태그를 삭제하려면 `.*`를 지정하세요. 참고: `name_regex`은(는) `name_regex_delete`를 선호하므로 더 이상 사용되지 않습니다. 이 필드는 검증됩니다. |
| `name_regex_delete` | 문자열         | 예      | 삭제할 이름의 [re2](https://github.com/google/re2/wiki/Syntax) 정규식입니다. 모든 태그를 삭제하려면 `.*`를 지정하세요. 이 필드는 검증됩니다. |
| `name_regex_keep`   | 문자열         | 아니요       | 유지할 이름의 [re2](https://github.com/google/re2/wiki/Syntax) 정규식입니다. 이 값은 `name_regex_delete`의 모든 일치를 재정의합니다. 이 필드는 검증됩니다. 참고: `.*`로 설정하면 작동하지 않습니다. |
| `older_than`        | 문자열         | 아니요       | 주어진 시간보다 오래된 태그를 삭제하려면 `1h`, `1d`, `1month` 형식의 읽기 쉬운 형식으로 작성합니다. |

이 API는 성공하면 [HTTP 응답 상태 코드 202](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202)를 반환하고 다음 작업을 수행합니다:

- 모든 태그를 생성 날짜 순서로 정렬합니다. 생성 날짜는 태그 푸시 시간이 아닌 manifest 생성 시간입니다.
- 주어진 `name_regex_delete`(또는 더 이상 사용되지 않는 `name_regex`)과 일치하는 태그만 제거하고 `name_regex_keep`과 일치하는 모든 태그는 유지합니다.
- `latest`이라는 태그는 절대 제거하지 않습니다.
- (`keep_n`이 지정된 경우) 최신 일치 태그 N개를 유지합니다.
- (`older_than`이 지정된 경우) X 시간보다 오래된 태그만 제거합니다.
- [보호된 태그](../user/packages/container_registry/protected_container_tags.md)를 제외합니다.
- 백그라운드에서 실행할 비동기 작업을 예약합니다.

이러한 작업은 비동기적으로 실행되며 실행하는 데 시간이 걸릴 수 있습니다. 지정된 컨테이너 리포지토리에 대해 최대 1시간에 한 번 실행할 수 있습니다.

이 작업은 blob을 삭제하지 않습니다. 디스크 공간을 확보하려면 [가비지 수집을 실행](../administration/packages/container_registry.md#container-registry-garbage-collection)하세요.

> [!warning]
> 컨테이너 레지스트리의 규모 때문에 GitLab.com에서 이 API로 삭제된 태그 개수는 제한됩니다. 컨테이너 레지스트리에 삭제할 태그가 많으면 일부만 삭제되며 여러 번 이 API를 호출해야 할 수 있습니다. 태그를 자동으로 삭제하도록 예약하려면 대신 [정리 정책](../user/packages/container_registry/reduce_container_registry_storage.md#cleanup-policy)을 사용하세요.

예:

- 정규식(Git SHA)과 일치하는 태그 이름을 제거하고, 최소 5개는 항상 유지하며, 2일보다 오래된 태그를 제거합니다:

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=[0-9a-z]{40}' \
    --data 'keep_n=5' \
    --data 'older_than=2d' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- 모든 태그를 제거하되 항상 최신 5개는 유지합니다:

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'keep_n=5' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- 모든 태그를 제거하되 항상 `stable`로 시작하는 태그는 유지합니다:

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'name_regex_keep=stable.*' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- 1개월보다 오래된 모든 태그를 제거합니다:

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'older_than=1month' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

### `+`을(를) 포함하는 정규식에 cURL 사용 {#use-curl-with-a-regular-expression-that-contains-}

cURL을 사용할 때 정규식에서 `+` 문자는 GitLab Rails 백엔드에서 올바르게 처리되도록 [URL 인코딩](https://curl.se/docs/manpage.html#--data-urlencode)되어야 합니다. 예를 들어:

```shell
curl --request DELETE \
  --data-urlencode 'name_regex_delete=dev-.+' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

## 인스턴스 전체 엔드포인트 {#instance-wide-endpoints}

이전에 설명한 그룹 및 프로젝트별 GitLab API 외에도 컨테이너 레지스트리에는 자체 엔드포인트가 있습니다. 이를 쿼리하려면 [인증 토큰](https://distribution.github.io/distribution/spec/auth/token/)을(를) 얻고 사용하기 위해 레지스트리의 기본 제공 메커니즘을 따르세요.

> [!note]
> 이러한 항목은 GitLab 애플리케이션의 개인 액세스 토큰과는 다릅니다.

### GitLab에서 토큰 얻기 {#obtain-token-from-gitlab}

```plaintext
GET ${CI_SERVER_URL}/jwt/auth?service=container_registry&scope=*
```

유효한 토큰을 검색하려면 올바른 [범위 및 작업](https://distribution.github.io/distribution/spec/auth/scope/)을(를) 지정해야 합니다:

```shell
SCOPE="repository:${CI_PROJECT_PATH}:delete" # or push, pull

curl --request GET \
  --user "${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}" \
  --url "${CI_SERVER_URL}/jwt/auth?service=container_registry&scope=${SCOPE}"
```

### 참조로 이미지 태그 삭제 {#delete-image-tags-by-reference}

{{< history >}}

- 엔드포인트 `v2/<name>/manifests/<tag>`는 GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/container-registry/-/issues/1091)되었으며 엔드포인트 `v2/<name>/tags/reference/<tag>`는 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/container-registry/-/issues/1094).

{{< /history >}}

```plaintext
DELETE http(s)://${CI_REGISTRY}/v2/${CI_REGISTRY_IMAGE}/tags/reference/${CI_COMMIT_SHORT_SHA}
```

사전 정의된 `CI_REGISTRY_USER` 및 `CI_REGISTRY_PASSWORD` 변수로 검색한 토큰을 사용하여 GitLab 인스턴스에서 참조로 컨테이너 이미지 태그를 삭제할 수 있습니다. `tag_delete` [컨테이너 레지스트리 기능](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/docker/v2/api.md#delete-tag)을(를) 활성화해야 합니다.

```shell
$ curl --request DELETE \
    --header "Authorization: Bearer <token_from_above>" \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    --url "https://gitlab.example.com:5050/v2/${CI_REGISTRY_IMAGE}/manifests/${CI_COMMIT_SHORT_SHA}"
```

### 모든 컨테이너 리포지토리 나열 {#listing-all-container-repositories}

```plaintext
GET http(s)://${CI_REGISTRY}/v2/_catalog
```

GitLab 인스턴스의 모든 컨테이너 리포지토리를 나열하려면 관리자 자격증명이 필요합니다:

```shell
$ SCOPE="registry:catalog:*"

$ curl --request GET \
    --user "<admin-username>:<admin-password>" \
    --url "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}

$ curl --header "Authorization: Bearer <token_from_above>" \
    --url "https://gitlab.example.com:5050/v2/_catalog"
```
