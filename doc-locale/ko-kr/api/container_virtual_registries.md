---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 레지스트리 가상 API
description: 컨테이너 레지스트리용 가상 레지스트리를 생성 및 관리하고 업스트림 컨테이너 레지스트리를 구성합니다.
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- `container_virtual_registries`라는 이름의 [기능 플래그](../administration/feature_flags/_index.md)와 함께 GitLab 18.5에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/548794). 기본적으로 비활성화됨.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) \- GitLab 18.9에서 실험에서 베타로 변경됨.
- GitLab 18.10 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250).

{{< /history >}}

> [!flag]
> 이 엔드포인트의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 이력을 참조하세요.

이 API를 사용하여:

- 컨테이너 레지스트리용 가상 레지스트리를 생성 및 관리합니다.
- 업스트림 컨테이너 레지스트리를 구성합니다.
- 캐시된 컨테이너 이미지 및 매니페스트를 관리합니다.

가상 레지스트리를 통해 컨테이너 이미지를 가져오는 방법에 대한 자세한 내용은 [컨테이너 가상 레지스트리](../user/packages/virtual_registry/container/_index.md)를 참조하세요.

> [!note]
> 클라우드 공급자 레지스트리는 지원되지 않지만 [이슈 20919](https://gitlab.com/groups/gitlab-org/-/work_items/20919)에서 이 동작을 변경할 것을 제안합니다.

## 가상 레지스트리 관리 {#manage-virtual-registries}

다음 엔드포인트를 사용하여 컨테이너 레지스트리용 가상 레지스트리를 생성 및 관리합니다.

### 모든 가상 레지스트리 나열 {#list-all-virtual-registries}

그룹의 모든 컨테이너 가상 레지스트리를 나열합니다.

```plaintext
GET /groups/:id/-/virtual_registries/container/registries
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

응답 예시:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-container-virtual-registry",
    "description": "My container virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### 가상 레지스트리 생성 {#create-a-virtual-registry}

그룹용 컨테이너 가상 레지스트리를 생성합니다.

```plaintext
POST /groups/:id/-/virtual_registries/container/registries
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `name` | 문자열 | 예 | 가상 레지스트리의 이름입니다. |
| `description` | 문자열 | 아니요 | 가상 레지스트리의 설명입니다. |

> [!note]
> 그룹당 최대 5개의 가상 레지스트리를 생성할 수 있습니다.

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 가상 레지스트리 검색 {#retrieve-a-virtual-registry}

지정된 컨테이너 가상 레지스트리를 검색합니다.

```plaintext
GET /virtual_registries/container/registries/:id
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 컨테이너 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 2,
      "position": 1,
      "upstream_id": 2
    }
  ]
}
```

### 가상 레지스트리 업데이트 {#update-a-virtual-registry}

지정된 컨테이너 가상 레지스트리를 업데이트합니다.

```plaintext
PATCH /virtual_registries/container/registries/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 컨테이너 가상 레지스트리의 ID입니다. |
| `description` | 문자열 | 아니요 | 가상 레지스트리의 설명입니다. |
| `name` | 문자열 | 아니요 | 가상 레지스트리의 이름입니다. |

> [!note]
> 요청에서 선택적 매개변수(`name` 또는 `description`) 중 하나 이상을 제공해야 합니다.

요청 예시:

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 가상 레지스트리 삭제 {#delete-a-virtual-registry}

> [!warning]
> 가상 레지스트리를 삭제하면 다른 가상 레지스트리와 공유되지 않는 모든 관련 업스트림 레지스트리와 해당 캐시된 컨테이너 이미지 및 매니페스트도 삭제됩니다.

지정된 컨테이너 가상 레지스트리를 삭제합니다.

```plaintext
DELETE /virtual_registries/container/registries/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 컨테이너 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 가상 레지스트리의 캐시 항목 삭제 {#delete-cache-entries-for-a-virtual-registry}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) \- GitLab 18.7 [기능 플래그](../administration/feature_flags/_index.md) 포함 (`container_virtual_registries`) 명명됨. 기본적으로 비활성화됨.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) \- GitLab 18.9에서 실험에서 베타로 변경됨.
- GitLab 18.10 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250).

{{< /history >}}

컨테이너 가상 레지스트리에 대해 모든 독점 업스트림 레지스트리의 모든 캐시 항목을 삭제하도록 예약합니다. 다른 가상 레지스트리와 관련된 업스트림 레지스트리의 경우 캐시 항목이 삭제되도록 예약되지 않습니다.

```plaintext
DELETE /virtual_registries/container/registries/:id/cache
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 컨테이너 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/cache"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

## 업스트림 레지스트리 관리 {#manage-upstream-registries}

다음 엔드포인트를 사용하여 업스트림 컨테이너 레지스트리를 구성 및 관리합니다.

### 최상위 그룹의 모든 업스트림 레지스트리 나열 {#list-all-upstream-registries-for-a-top-level-group}

최상위 그룹의 모든 업스트림 컨테이너 레지스트리를 나열합니다.

```plaintext
GET /groups/:id/-/virtual_registries/container/upstreams
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `page` | 정수 | 아니요 | 페이지 번호입니다. 기본값은 1입니다. |
| `per_page` | 정수 | 아니요 | 페이지당 항목 수입니다. 기본값은 20입니다. |
| `upstream_name` | 문자열 | 아니요 | 이름으로 퍼지 검색 필터링을 위한 업스트림 레지스트리의 이름입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/upstreams"
```

응답 예시:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### 업스트림 레지스트리 생성 전에 연결 테스트 {#test-connection-before-creating-an-upstream-registry}

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/578679) 되었으며 [플래그](../administration/feature_flags/_index.md) `container_virtual_registries`로 명명됩니다. 기본적으로 비활성화됨.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) \- GitLab 18.9에서 실험에서 베타로 변경됨.
- GitLab 18.10 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250).

{{< /history >}}

아직 가상 레지스트리에 추가되지 않은 컨테이너 업스트림 레지스트리에 대한 연결을 테스트합니다. 이 엔드포인트는 업스트림 레지스트리를 생성하기 전에 연결 및 자격증명을 확인합니다.

```plaintext
POST /groups/:id/-/virtual_registries/container/upstreams/test
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `url` | 문자열 | 예 | 업스트림 레지스트리의 URL입니다. |
| `password` | 문자열 | 아니요 | 업스트림 레지스트리의 암호입니다. |
| `username` | 문자열 | 아니요 | 업스트림 레지스트리의 사용자 이름입니다. |

> [!note]
> 요청에서 `username`과(와) `password`을(를) 모두 포함하거나 둘 다 포함하지 않아야 합니다. 설정하지 않으면 공개(익명) 요청이 업스트림에 액세스하는 데 사용됩니다.

#### 테스트 워크플로우 {#test-workflow}

`test` 엔드포인트는 제공된 업스트림 URL로 테스트 경로를 사용하여 HEAD 요청을 보내 연결성 및 인증을 확인합니다. HEAD 요청에서 받은 응답은 다음과 같이 해석됩니다:

| 업스트림 응답 | 설명 | 결과 |
|:------------------|:--------|:-------|
| 2XX | 성공합니다. 업스트림 액세스 가능 | `{ "success": true }` |
| 404 | 성공합니다. 업스트림 액세스 가능하지만 테스트 아티팩트를 찾을 수 없음 | `{ "success": true }` |
| 401 | 인증 실패 | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | 액세스 금지됨 | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | 업스트림 서버 오류 | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| 네트워크 오류 | 연결/시간 초과 이슈 | `{ "success": false, "result": "Error: Connection timeout" }` |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/upstreams/test"
     --data '{"url": "https://registry-1.docker.io", "username": "<your_username>", "password": "<your_password>"}' \
```

응답 예시:

```json
{
  "success": true
}
```

> [!note]
> `2XX`(발견) 및 `404 Not Found` HTTP 상태 코드는 업스트림이 도달 가능하고 올바르게 구성되었음을 나타내므로 성공적인 응답으로 간주됩니다.

### 가상 레지스트리의 모든 업스트림 레지스트리 나열 {#list-all-upstream-registries-for-a-virtual-registry}

컨테이너 가상 레지스트리의 모든 업스트림 레지스트리를 나열합니다.

```plaintext
GET /virtual_registries/container/registries/:id/upstreams
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 정수 | 예 | 컨테이너 가상 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

응답 예시:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
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

지정된 컨테이너 가상 레지스트리에 대한 업스트림 컨테이너 레지스트리를 생성합니다.

```plaintext
POST /virtual_registries/container/registries/:id/upstreams
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 컨테이너 가상 레지스트리의 ID입니다. |
| `url` | 문자열 | 예 | 업스트림 컨테이너 레지스트리의 URL입니다. |
| `name` | 문자열 | 예 | 업스트림 레지스트리의 이름입니다. |
| `cache_validity_hours` | 정수 | 아니요 | 컨테이너 이미지의 캐시 유효성 기간입니다. 기본값은 24시간입니다. |
| `description` | 문자열 | 아니요 | 업스트림 레지스트리의 설명입니다. |
| `password` | 문자열 | 아니요 | 업스트림 레지스트리의 암호입니다. |
| `username` | 문자열 | 아니요 | 업스트림 레지스트리의 사용자 이름입니다. |

> [!note]
> 요청에서 `username`과(와) `password`을(를) 모두 포함하거나 전혀 포함하지 않아야 합니다. 설정하지 않으면 공개(익명) 요청이 업스트림에 액세스하는 데 사용됩니다.

동일한 최상위 그룹에 동일한 URL 및 자격증명(`username` 및 `password`)을 가진 두 개의 업스트림을 추가할 수 없습니다. 대신 다음 중 하나를 수행할 수 있습니다:

- 동일한 URL의 각 업스트림에 대해 다른 자격증명을 설정합니다.
- 업스트림을 여러 가상 레지스트리와 연결합니다.

> [!note]
> 각 가상 레지스트리에 최대 5개의 업스트림 레지스트리를 추가할 수 있습니다.

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io", "name": "Docker Hub", "description": "Docker Hub registry", "username": "<your_username>", "password": "<your_password>", "cache_validity_hours": 48}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 48,
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

지정된 업스트림 컨테이너 레지스트리를 검색합니다.

```plaintext
GET /virtual_registries/container/upstreams/:id
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

응답 예시:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 24,
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

지정된 업스트림 컨테이너 레지스트리를 업데이트합니다.

```plaintext
PATCH /virtual_registries/container/upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |
| `cache_validity_hours` | 정수 | 아니요 | 컨테이너 이미지의 캐시 유효성 기간입니다. 기본값은 24시간입니다. |
| `description` | 문자열 | 아니요 | 업스트림 레지스트리의 설명입니다. |
| `name` | 문자열 | 아니요 | 업스트림 레지스트리의 이름입니다. |
| `password` | 문자열 | 아니요 | 업스트림 레지스트리의 암호입니다. |
| `url` | 문자열 | 아니요 | 업스트림 레지스트리의 URL입니다. |
| `username` | 문자열 | 아니요 | 업스트림 레지스트리의 사용자 이름입니다. |

> [!note]
> 요청에서 선택적 매개변수 중 하나 이상을 제공해야 합니다.
>
> `username`과(와) `password`은(는) 함께 제공되거나 전혀 제공되지 않아야 합니다. 설정하지 않으면 공개(익명) 요청이 업스트림에 액세스하는 데 사용됩니다.

요청 예시:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리 위치 업데이트 {#update-an-upstream-registry-position}

컨테이너 가상 레지스트리에 대한 정렬된 목록에서 업스트림 컨테이너 레지스트리의 위치를 업데이트합니다.

```plaintext
PATCH /virtual_registries/container/registry_upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리 연결의 ID입니다. |
| `position` | 정수 | 예 | 업스트림 레지스트리의 위치입니다. 1에서 20 사이입니다. |

요청 예시:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리 삭제 {#delete-an-upstream-registry}

지정된 업스트림 컨테이너 레지스트리를 삭제합니다.

```plaintext
DELETE /virtual_registries/container/upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림을 레지스트리와 연결 {#associate-an-upstream-with-a-registry}

지정된 업스트림 컨테이너 레지스트리를 지정된 컨테이너 가상 레지스트리와 연결합니다.

```plaintext
POST /virtual_registries/container/registry_upstreams
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `registry_id` | 정수 | 예 | 컨테이너 가상 레지스트리의 ID입니다. |
| `upstream_id` | 정수 | 예 | 컨테이너 업스트림 레지스트리의 ID입니다. |

> [!note]
> 각 가상 레지스트리와 최대 5개의 업스트림 레지스트리를 연결할 수 있습니다.

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams"
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

### 업스트림을 레지스트리에서 분리 {#disassociate-an-upstream-from-a-registry}

지정된 업스트림 컨테이너 레지스트리와 지정된 컨테이너 가상 레지스트리 간의 연결을 제거합니다.

```plaintext
DELETE /virtual_registries/container/registry_upstreams/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리 연결의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 업스트림 레지스트리의 캐시 항목 삭제 {#delete-cache-entries-for-an-upstream-registry}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) \- GitLab 18.7 [기능 플래그](../administration/feature_flags/_index.md) 포함 (`container_virtual_registries`) 명명됨. 기본적으로 비활성화됨.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) \- GitLab 18.9에서 실험에서 베타로 변경됨.
- GitLab 18.10 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250).

{{< /history >}}

지정된 업스트림 레지스트리에 대해 모든 캐시 항목을 삭제하도록 예약합니다.

```plaintext
DELETE /virtual_registries/container/upstreams/:id/cache
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/cache"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

### 매개변수 재정의를 사용하여 업스트림 레지스트리에 대한 연결 테스트 {#test-connection-to-an-upstream-registry-with-override-parameters}

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/578679) 되었으며 [플래그](../administration/feature_flags/_index.md) `container_virtual_registries`로 명명됩니다. 기본적으로 비활성화됨.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) \- GitLab 18.9에서 실험에서 베타로 변경됨.
- GitLab 18.10 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250).

{{< /history >}}

선택적 매개변수 재정의를 사용하여 기존 컨테이너 업스트림 레지스트리에 대한 연결을 테스트합니다.

이렇게 하면 업스트림 레지스트리 구성을 업데이트하기 전에 URL, 사용자 이름 또는 암호의 변경사항을 테스트할 수 있습니다.

```plaintext
POST /virtual_registries/container/upstreams/:id/test
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |
| `password` | 문자열 | 아니요 | 테스트용 재정의 암호입니다. |
| `url` | 문자열 | 아니요 | 테스트용 재정의 URL입니다. 제공되면 업스트림의 구성된 URL 대신 이 URL로의 연결을 테스트합니다. |
| `username` | 문자열 | 아니요 | 테스트용 재정의 사용자 이름입니다. |

#### 테스트 작동 방식 {#how-the-test-works}

엔드포인트는 테스트 경로를 사용하여 업스트림 URL로 HEAD 요청을 수행하여 연결성 및 인증을 확인합니다. 업스트림에 캐시된 아티팩트가 있으면 테스트에 업스트림의 상대 경로가 사용됩니다. 그렇지 않으면 자리 표시자 경로가 사용됩니다.

테스트 동작은 제공된 매개변수에 따라 달라집니다:

- 매개변수 없음:  현재 구성(기존 URL, 사용자 이름 및 암호)으로 업스트림을 테스트합니다.
- URL 재정의:  새 URL로의 연결을 테스트합니다(사용자 이름과 암호를 함께 제공하거나 전혀 제공하지 않아야 함).
- 자격증명 재정의:  새 자격증명으로 기존 URL을 테스트합니다.

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
> `2XX`(발견) 및 `404 Not Found` 응답은 업스트림 레지스트리에 대한 성공적인 연결 및 인증을 나타냅니다. 테스트는 특정 아티팩트의 존재 여부를 확인하지 않습니다.

요청 예(기존 구성 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

요청 예(URL 재정의 및 자격증명 없음으로 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

요청 예(URL 및 자격증명 재정의로 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io", "username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

요청 예(자격증명 재정의로 테스트):

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

응답 예시:

```json
{
  "success": true
}
```

## 캐시 항목 관리 {#manage-cache-entries}

다음 엔드포인트를 사용하여 컨테이너 가상 레지스트리의 캐시된 컨테이너 이미지 및 매니페스트를 관리합니다.

### 업스트림 레지스트리 캐시 항목 나열 {#list-upstream-registry-cache-entries}

컨테이너 업스트림 레지스트리의 캐시된 컨테이너 이미지 및 매니페스트를 나열합니다.

```plaintext
GET /virtual_registries/container/upstreams/:id/cache_entries
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 정수 | 예 | 업스트림 레지스트리의 ID입니다. |
| `page` | 정수 | 아니요 | 페이지 번호입니다. 기본값은 1입니다. |
| `per_page` | 정수 | 아니요 | 페이지당 항목 수입니다. 기본값은 20입니다. |
| `search` | 문자열 | 아니요 | 컨테이너 이미지의 상대 경로에 대한 검색 쿼리입니다(예: `library/nginx`). |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/cache_entries?search=library/nginx"
```

응답 예시:

```json
[
  {
    "id": "MTUgbGlicmFyeS9uZ2lueC9tYW5pZmVzdC9zaGEyNTY6YWJjZGVmZ2hpams=",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "library/nginx/manifests/latest",
    "content_type": "application/vnd.docker.distribution.manifest.v2+json",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "downloads_count": 5,
    "downloaded_at": "2024-06-05T14:58:32.855Z"
  }
]
```

### 업스트림 레지스트리 캐시 항목 삭제 {#delete-an-upstream-registry-cache-entry}

업스트림 레지스트리의 지정된 캐시된 컨테이너 이미지 또는 매니페스트를 삭제합니다.

```plaintext
DELETE /virtual_registries/container/cache_entries/*id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 | 예 | base64로 인코딩된 업스트림 ID 및 캐시 항목의 상대 경로인 캐시 항목 ID입니다(예: 'bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0'). |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/cache_entries/bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.
