---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Maven 가상 레지스트리 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- [GitLab 17.4에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615) [기능 플래그](../administration/feature_flags/_index.md)가 `virtual_registry_maven`로 명명되었습니다. 기본적으로 비활성화됨.
- 기능 플래그가 GitLab 18.1에서 `maven_virtual_registry`으로 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/540276). 기본적으로 비활성화됨. 기능 플래그 `virtual_registry_maven` 제거됨.
- GitLab 18.1에서 실험 버전에서 베타 버전으로 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/540276).
- GitLab 18.2에서 [GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432).

{{< /history >}}

> [!flag]
> 이 엔드포인트의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 이력을 참조하세요.

이 API를 다음과 같이 사용합니다:

- Maven 가상 레지스트리를 생성하고 관리합니다.
- 업스트림 레지스트리를 구성합니다.
- 캐시 항목을 관리합니다.
- 패키지 다운로드 및 업로드를 처리합니다.

## Maven 가상 레지스트리 관리 {#manage-maven-virtual-registries}

다음 엔드포인트를 사용하여 Maven 가상 레지스트리를 생성하고 관리합니다.

### 모든 가상 레지스트리 나열 {#list-all-virtual-registries}

{{< history >}}

- `downloads_count` 및 `downloaded_at`는 GitLab 18.4에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201790).

{{< /history >}}

지정된 그룹에 대한 모든 Maven 가상 레지스트리를 나열합니다.

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/registries
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 문자열/정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

응답 예시:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-virtual-registry",
    "description": "My virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### 가상 레지스트리 생성 {#create-a-virtual-registry}

지정된 그룹에 대한 Maven 가상 레지스트리를 생성합니다.

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/registries
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열/정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `name` | 문자열 | 예 | 가상 레지스트리의 이름입니다. |
| `description` | 문자열 | 아니요 | 가상 레지스트리의 설명입니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 가상 레지스트리 검색 {#retrieve-a-virtual-registry}

지정된 Maven 가상 레지스트리를 검색합니다.

```plaintext
GET /virtual_registries/packages/maven/registries/:id
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 가상 레지스트리 업데이트 {#update-a-virtual-registry}

지정된 Maven 가상 레지스트리를 업데이트합니다.

```plaintext
PATCH /virtual_registries/packages/maven/registries/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |
| `name` | 문자열 | 예 | 가상 레지스트리의 이름입니다. |
| `description` | 문자열 | 아니요 | 가상 레지스트리의 설명입니다. |

요청 예시:

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 가상 레지스트리 삭제 {#delete-a-virtual-registry}

> [!warning]
> 가상 레지스트리를 삭제하면 다른 가상 레지스트리와 공유되지 않은 모든 관련 업스트림 레지스트리와 해당 캐시 항목도 함께 삭제됩니다.

지정된 Maven 가상 레지스트리를 삭제합니다.

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 가상 레지스트리의 캐시 항목 삭제 {#delete-cache-entries-for-a-virtual-registry}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) 되었으며 [플래그](../administration/feature_flags/_index.md) `maven_virtual_registry`를 사용합니다. 기본적으로 활성화됨.

{{< /history >}}

Maven 가상 레지스트리의 모든 독점적 업스트림 레지스트리에서 모든 캐시 항목을 삭제하도록 예약합니다. 다른 가상 레지스트리와 관련된 업스트림 레지스트리의 경우 캐시 항목이 삭제하도록 예약되지 않습니다.

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id/cache
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/cache"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

## 업스트림 레지스트리 관리 {#manage-upstream-registries}

다음 엔드포인트를 사용하여 업스트림 Maven 레지스트리를 구성하고 관리합니다.

### 모든 업스트림 레지스트리 나열 {#list-all-upstream-registries}

{{< history >}}

- [GitLab 18.3에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/550728) [기능 플래그](../administration/feature_flags/_index.md)가 `maven_virtual_registry`로 명명되었습니다. 기본적으로 활성화됨.
- `upstream_name`은 GitLab 18.4에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/561675).

{{< /history >}}

지정된 최상위 그룹에 대한 모든 업스트림 Maven 레지스트리를 나열합니다.

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/upstreams
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 문자열/정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `page` | 정수 | 아니요 | 페이지 번호입니다. 기본값은 1입니다. |
| `per_page` | 정수 | 아니요 | 페이지당 항목의 수입니다. 기본값은 20입니다. |
| `upstream_name` | 문자열 | 아니요 | 이름으로 검색 필터링하기 위한 업스트림 레지스트리의 이름입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/upstreams"
```

응답 예시:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
    "cache_validity_hours": 24,
    "metadata_cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### 생성 전에 업스트림 레지스트리 연결 테스트 {#test-upstream-registry-connection-before-creation}

{{< history >}}

- [GitLab 18.3에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/535637) [기능 플래그](../administration/feature_flags/_index.md)가 `maven_virtual_registry`로 명명되었습니다. 기본적으로 활성화됨.

{{< /history >}}

가상 레지스트리에 아직 추가되지 않은 Maven 업스트림 레지스트리로의 연결을 테스트합니다. 이 엔드포인트는 업스트림 레지스트리를 생성하기 전에 연결성 및 자격 증명을 검증합니다.

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/upstreams/test
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 문자열/정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `url` | 문자열 | 예 | 업스트림 레지스트리의 URL입니다. |
| `password` | 문자열 | 아니요 | 업스트림 레지스트리의 암호입니다. |
| `username` | 문자열 | 아니요 | 업스트림 레지스트리의 사용자 이름입니다. |

> [!note]
> `username` 및 `password`을 모두 요청에 포함하거나 둘 다 포함하지 않아야 합니다. 설정되지 않으면 공용(익명) 요청을 사용하여 연결을 테스트합니다.

#### 테스트 워크플로 {#test-workflow}

`test` 엔드포인트는 제공된 업스트림 URL에 테스트 경로를 사용하여 HEAD 요청을 전송하여 연결성 및 인증을 검증합니다. HEAD 요청에서 받은 응답은 다음과 같이 해석됩니다:

| 업스트림 응답 | 설명 | 결과 |
|:------------------|:--------|:-------|
| 2XX | 성공 - 업스트림 액세스 가능 | `{ "success": true }` |
| 404 | 성공 - 업스트림 액세스 가능하지만 테스트 아티팩트를 찾을 수 없음 | `{ "success": true }` |
| 401 | 인증 실패 | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | 액세스 금지됨 | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | 업스트림 서버 오류 | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| 네트워크 오류 | 연결 또는 시간 초과 이슈 | `{ "success": false, "result": "Error: Connection timeout" }` |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/upstreams/test" \
     --data '{"url": "https://repo.maven.apache.org/maven2"}'
```

응답 예시:

```json
{
  "success": true
}
```

### 가상 레지스트리에 대한 모든 업스트림 레지스트리 나열 {#list-all-upstream-registries-for-a-virtual-registry}

지정된 가상 레지스트리에 대한 모든 업스트림 Maven 레지스트리를 나열합니다.

```plaintext
GET /virtual_registries/packages/maven/registries/:id/upstreams
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

응답 예시:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
    "cache_validity_hours": 24,
    "metadata_cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "registry_upstream": {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  }
]
```

### 업스트림 레지스트리 생성 {#create-an-upstream-registry}

{{< history >}}

- `metadata_cache_validity_hours`은 GitLab 18.3에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/556138).

{{< /history >}}

지정된 Maven 가상 레지스트리에 대한 업스트림 레지스트리를 생성합니다.

```plaintext
POST /virtual_registries/packages/maven/registries/:id/upstreams
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |
| `url` | 문자열 | 예 | 업스트림 레지스트리의 URL입니다. |
| `cache_validity_hours` | 정수 | 아니요 | 캐시 유효 기간입니다. 기본값은 24시간입니다. |
| `description` | 문자열 | 아니요 | 업스트림 레지스트리의 설명입니다. |
| `metadata_cache_validity_hours` | 정수 | 아니요 | 메타데이터 캐시 유효 기간입니다. 기본값은 24시간입니다. |
| `name` | 문자열 | 아니요 | 업스트림 레지스트리의 이름입니다. |
| `password` | 문자열 | 아니요 | 업스트림 레지스트리의 암호입니다. |
| `username` | 문자열 | 아니요 | 업스트림 레지스트리의 사용자 이름입니다. |

> [!note]
> `username` 및 `password`을 모두 요청에 포함하거나 전혀 포함하지 않아야 합니다. 설정되지 않으면 공용(익명) 요청을 사용하여 업스트림에 액세스합니다.
>
> 동일한 URL 및 자격 증명(`username` 및 `password`)을 가진 두 개의 업스트림을 동일한 최상위 그룹에 추가할 수 없습니다. 대신 다음 중 하나를 수행할 수 있습니다:
>
> - 동일한 URL을 가진 각 업스트림에 대해 다른 자격 증명을 설정합니다.
> - [업스트림을 여러 가상 레지스트리와 연결합니다](#associate-an-upstream-registry-with-a-virtual-registry).

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://repo.maven.apache.org/maven2", "name": "Maven Central", "description": "Maven Central repository", "username": <your_username>, "password": <your_password>, "cache_validity_hours": 48, "metadata_cache_validity_hours": 1}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
  "cache_validity_hours": 48,
  "metadata_cache_validity_hours": 1,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstream": {
    "id": 1,
    "registry_id": 1,
    "position": 1
  }
}
```

### 업스트림 레지스트리 검색 {#retrieve-an-upstream-registry}

지정된 업스트림 레지스트리를 검색합니다.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
  "cache_validity_hours": 24,
  "metadata_cache_validity_hours": 24,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  ]
}
```

### 업스트림 레지스트리 업데이트 {#update-an-upstream-registry}

{{< history >}}

- `metadata_cache_validity_hours`은 GitLab 18.3에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/556138).

{{< /history >}}

지정된 업스트림 레지스트리를 업데이트합니다.

```plaintext
PATCH /virtual_registries/packages/maven/upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |
| `cache_validity_hours` | 정수 | 아니요 | 캐시 유효 기간입니다. 기본값은 24시간입니다. |
| `description` | 문자열 | 아니요 | 업스트림 레지스트리의 설명입니다. |
| `metadata_cache_validity_hours` | 정수 | 아니요 | 메타데이터 캐시 유효 기간입니다. 기본값은 24시간입니다. |
| `name` | 문자열 | 아니요 | 업스트림 레지스트리의 이름입니다. |
| `password` | 문자열 | 아니요 | 업스트림 레지스트리의 암호입니다. |
| `url` | 문자열 | 아니요 | 업스트림 레지스트리의 URL입니다. |
| `username` | 문자열 | 아니요 | 업스트림 레지스트리의 사용자 이름입니다. |

> [!note]
> 요청에서 선택적 매개변수 중 최소 하나를 제공해야 합니다.
>
> `username` 및 `password`은 함께 제공되어야 하거나 전혀 제공되지 않아야 합니다. 설정되지 않으면 공용(익명) 요청을 사용하여 업스트림에 액세스합니다.

요청 예시:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리 위치 업데이트 {#update-an-upstream-registry-position}

Maven 가상 레지스트리의 정렬된 목록에서 업스트림 레지스트리의 위치를 업데이트합니다.

```plaintext
PATCH /virtual_registries/packages/maven/registry_upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |
| `position` | 정수 | 예 | 업스트림 레지스트리의 위치입니다. 1에서 20 사이입니다. |

요청 예시:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리 삭제 {#delete-an-upstream-registry}

지정된 업스트림 레지스트리를 삭제합니다.

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리를 가상 레지스트리와 연결 {#associate-an-upstream-registry-with-a-virtual-registry}

{{< history >}}

- [GitLab 18.1에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) [기능 플래그](../administration/feature_flags/_index.md)가 `maven_virtual_registry`로 명명되었습니다. 기본적으로 비활성화됨.
- GitLab 18.2에서 [GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432).

{{< /history >}}

기존 업스트림 레지스트리를 지정된 Maven 가상 레지스트리와 연결합니다.

```plaintext
POST /virtual_registries/packages/maven/registry_upstreams
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `registry_id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |
| `upstream_id` | 정수 | 예 | Maven 업스트림 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams"
```

응답 예시:

```json
{
  "id": 5,
  "registry_id": 1,
  "upstream_id": 2,
  "position": 2
}
```

### 업스트림 레지스트리를 가상 레지스트리에서 분리 {#disassociate-an-upstream-registry-from-a-virtual-registry}

{{< history >}}

- [GitLab 18.1에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) [기능 플래그](../administration/feature_flags/_index.md)가 `maven_virtual_registry`로 명명되었습니다. 기본적으로 비활성화됨.
- GitLab 18.2에서 [GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432).

{{< /history >}}

지정된 Maven 가상 레지스트리에서 업스트림 레지스트리를 분리합니다.

```plaintext
DELETE /virtual_registries/packages/maven/registry_upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 레지스트리 업스트림 연결의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리의 캐시 항목 삭제 {#delete-cache-entries-for-an-upstream-registry}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) 되었으며 [플래그](../administration/feature_flags/_index.md) `maven_virtual_registry`를 사용합니다. 기본적으로 활성화됨.

{{< /history >}}

지정된 업스트림 레지스트리의 모든 캐시 항목을 삭제하도록 예약합니다.

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id/cache
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리 연결 테스트 {#test-upstream-registry-connection}

{{< history >}}

- [GitLab 18.3에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/535637) [기능 플래그](../administration/feature_flags/_index.md)가 `maven_virtual_registry`로 명명되었습니다. 기본적으로 활성화됨.

{{< /history >}}

지정된 Maven 업스트림 레지스트리로의 연결을 테스트합니다.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/test
```

#### 테스트 작동 방식 {#how-the-test-works}

엔드포인트는 업스트림 URL에 테스트 경로를 사용하여 HEAD 요청을 수행하여 연결성 및 인증을 검증합니다. 업스트림에 캐시된 아티팩트가 있으면 상대 경로를 테스트에 사용합니다. 그렇지 않으면 더미 경로를 사용합니다. HEAD 요청에서 받은 응답은 다음과 같이 해석됩니다:

| 업스트림 응답 | 의미 | 결과 |
|:------------------|:--------|:-------|
| 2XX | 성공 - 업스트림 액세스 가능 | `{ "success": true }` |
| 404 | 성공 - 업스트림 액세스 가능하지만 테스트 아티팩트를 찾을 수 없음 | `{ "success": true }` |
| 401 | 인증 실패 | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | 액세스 금지됨 | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | 업스트림 서버 오류 | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| 네트워크 오류 | 연결/시간 초과 이슈 | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note]
> `2XX`(발견) 및 `404`(발견 안 함) 응답은 업스트림 레지스트리로의 성공적인 연결 및 인증을 나타냅니다. 테스트는 GitLab이 업스트림에 도달하고 인증할 수 있는지 확인하며, 특정 아티팩트의 존재 여부를 확인하지 않습니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

응답 예시:

```json
{
  "success": true
}
```

### 재정의 매개변수를 사용한 업스트림 레지스트리 연결 테스트 {#test-upstream-registry-connection-with-override-parameters}

{{< history >}}

- [GitLab 18.7에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/565897) [기능 플래그](../administration/feature_flags/_index.md)가 `maven_virtual_registry`로 명명되었습니다. 기본적으로 활성화됨.

{{< /history >}}

선택적 매개변수 재정의를 사용하여 지정된 Maven 업스트림 레지스트리로의 연결을 테스트합니다.

이 방법으로 업스트림 레지스트리 구성을 업데이트하기 전에 URL, 사용자 이름 또는 암호 변경을 테스트할 수 있습니다.

```plaintext
POST /virtual_registries/packages/maven/upstreams/:id/test
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |
| `password` | 문자열 | 아니요 | 테스트를 위한 재정의 암호입니다. |
| `url` | 문자열 | 아니요 | 테스트를 위한 재정의 URL입니다. 제공되면 업스트림의 구성된 URL 대신 이 URL로의 연결을 테스트합니다. |
| `username` | 문자열 | 아니요 | 테스트를 위한 재정의 사용자 이름입니다. |

#### 테스트 작동 방식 {#how-the-test-works-1}

엔드포인트는 업스트림 URL에 테스트 경로를 사용하여 HEAD 요청을 수행하여 연결성 및 인증을 검증합니다. 업스트림에 캐시된 아티팩트가 있으면 업스트림의 상대 경로를 테스트에 사용합니다. 그렇지 않으면 자리표시자 경로를 사용합니다.

테스트 동작은 제공된 매개변수에 따라 달라집니다:

- 매개변수 없음:  현재 구성(기존 URL, 사용자 이름 및 암호)으로 업스트림을 테스트합니다
- URL 재정의:  새 URL로의 연결을 테스트합니다. 사용자 이름과 암호를 함께 제공하거나 전혀 제공하지 않아야 합니다
- 자격 증명 재정의:  새 자격 증명으로 기존 URL을 테스트합니다

HEAD 요청에서 받은 응답은 다음과 같이 해석됩니다:

| 업스트림 응답 | 의미 | 결과 |
|:------------------|:--------|:-------|
| 2XX | 성공합니다. 업스트림 액세스 가능 | `{ "success": true }` |
| 404 | 성공합니다. 업스트림 액세스 가능하지만 테스트 아티팩트를 찾을 수 없음 | `{ "success": true }` |
| 401 | 인증 실패 | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | 액세스 금지됨 | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | 업스트림 서버 오류 | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| 네트워크 오류 | 연결 또는 시간 초과 이슈 | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note]
> `2XX`(발견) 및 `404`(발견 안 함) 응답은 업스트림 레지스트리로의 성공적인 연결 및 인증을 나타냅니다. 테스트는 특정 아티팩트의 존재 여부를 검증하지 않습니다.

요청 예시(기존 구성 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

요청 예시(URL 재정의 및 자격 증명 없이 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "<https://new-repo.example.com/maven2>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

요청 예시(URL 및 자격 증명 재정의로 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "<https://new-repo.example.com/maven2>", "username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

요청 예시(자격 증명 재정의로 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

응답 예시:

```json
{
  "success": true
}
```

## 캐시 항목 관리 {#manage-cache-entries}

다음 엔드포인트를 사용하여 Maven 가상 레지스트리의 캐시 항목을 관리합니다.

### 모든 업스트림 레지스트리 캐시 항목 나열 {#list-all-upstream-registry-cache-entries}

지정된 Maven 업스트림 레지스트리의 모든 캐시 항목을 나열합니다.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/cache_entries
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |
| `page` | 정수 | 아니요 | 페이지 번호입니다. 기본값은 1입니다. |
| `per_page` | 정수 | 아니요 | 페이지당 항목의 수입니다. 기본값은 20입니다. |
| `search` | 문자열 | 아니요 | 패키지의 상대 경로에 대한 검색 쿼리입니다(예: `foo/bar/mypkg`). |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache_entries?search=foo/bar"
```

응답 예시:

```json
[
  {
    "id": "MTUgZm9vL2Jhci9teXBrZy8xLjAtU05BUFNIT1QvbXlwa2ctMS4wLVNOQVBTSE9ULmphcg==",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "foo/bar/package-1.0.0.pom",
    "content_type": "application/xml",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "downloads_count": 6,
    "downloaded_at": "2024-06-05T14:58:32.855Z"
  }
]
```

### 업스트림 레지스트리 캐시 항목 삭제 {#delete-an-upstream-registry-cache-entry}

Maven 업스트림 레지스트리의 지정된 캐시 항목을 삭제합니다.

```plaintext
DELETE /virtual_registries/packages/maven/cache_entries/*id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 | 예 | 캐시 항목의 base64 인코딩된 업스트림 ID 및 상대 경로입니다(예: 'Zm9vL2Jhci9teXBrZy5wb20='). |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/cache_entries/Zm9vL2Jhci9teXBrZy5wb20="
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

## 패키지 작업 관리 {#manage-package-operations}

다음 엔드포인트를 사용하여 Maven 가상 레지스트리의 패키지 작업을 관리합니다.

> [!warning]
> 이 엔드포인트는 GitLab의 내부 사용을 위한 것이며 일반적으로 수동 사용을 위한 것이 아닙니다.

이 엔드포인트는 [REST API 인증 방법](rest/authentication.md)을 따르지 않습니다. 지원되는 헤더 및 토큰 유형에 대한 자세한 내용은 [Maven 가상 레지스트리](../user/packages/virtual_registry/maven/_index.md)를 참조하세요. 문서화되지 않은 인증 방법이 나중에 제거될 수 있습니다.

### 패키지 다운로드 {#download-a-package}

지정된 Maven 가상 레지스트리에서 패키지를 다운로드합니다. 이 리소스에 액세스하려면 [레지스트리로 인증해야 합니다](../user/packages/package_registry/supported_functionality.md#authenticate-with-the-registry).

```plaintext
GET /virtual_registries/packages/maven/:id/*path
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |
| `path` | 문자열 | 예 | 전체 패키지 경로입니다(예: `foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`). |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/1/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" \
     --output mypkg-1.0-SNAPSHOT.jar
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 헤더를 반환합니다:

- `x-checksum-sha1`:  파일의 SHA1 체크섬
- `x-checksum-md5`:  파일의 MD5 체크섬
- `Content-Type`:  파일의 MIME 타입
- `Content-Length`:  파일 크기(바이트)

### 패키지 업로드 {#upload-a-package}

지정된 Maven 가상 레지스트리로 패키지를 업로드합니다. 이 엔드포인트는 [GitLab Workhorse](../development/workhorse/_index.md)에서만 액세스할 수 있습니다.

```plaintext
POST /virtual_registries/packages/maven/:id/*path/upload
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | Maven 가상 레지스트리의 ID입니다. |
| `file` | 파일 | 예 | 업로드 중인 파일입니다. |
| `path` | 문자열 | 예 | 전체 패키지 경로입니다(예: `foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`). |

요청 헤더:

- `Etag`:  파일의 엔터티 태그
- `GitLab-Workhorse-Send-Dependency-Content-Type`:  파일의 콘텐츠 유형
- `Upstream-GID`:  대상 업스트림의 글로벌 ID

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.
