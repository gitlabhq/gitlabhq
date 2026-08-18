---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 러너 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 인스턴스에 등록된 [러너](../ci/runners/_index.md)를 관리합니다.

새 인스턴스, 그룹 또는 프로젝트 러너를 만들려면 [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user) 엔드포인트를 사용합니다. 이 API를 사용하여 기존 러너를 관리합니다.

[페이지 매김](rest/_index.md#pagination)은 다음 API 엔드포인트에서 사용할 수 있습니다(기본적으로 20개 항목을 반환합니다):

```plaintext
GET /runners
GET /runners/all
GET /runners/:id/jobs
GET /projects/:id/runners
GET /groups/:id/runners
```

## 등록 및 인증 토큰 {#registration-and-authentication-tokens}

러너를 GitLab에 연결하려면 두 개의 토큰이 필요합니다.

| 토큰 | 설명 |
| ----- | ----------- |
| 등록 토큰(레거시) | [러너를 등록](https://docs.gitlab.com/runner/register/)하는 데 사용되는 토큰입니다. [GitLab을 통해 획득](../ci/runners/_index.md)할 수 있습니다. |
| 인증 토큰 | 러너를 GitLab 인스턴스로 인증하는 데 사용되는 토큰입니다. 토큰은 [러너를 등록](https://docs.gitlab.com/runner/register/) 할 때 자동으로 획득되거나 러너 API에 의해 수동으로 [러너를 등록](#create-a-runner) 하거나 [인증 토큰을 재설정](#reset-runners-authentication-token-by-using-the-runner-id)할 때 획득됩니다. [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user) 엔드포인트를 사용하여 토큰을 획득할 수도 있습니다. |

다음은 러너 등록을 위해 토큰을 사용하는 방법의 예입니다:

1. 등록 토큰으로 GitLab API를 사용하여 러너를 등록하여 인증 토큰을 받습니다.
1. [러너의 구성 파일](https://docs.gitlab.com/runner/commands/#configuration-file)에 인증 토큰을 추가합니다:

   ```toml
   [[runners]]
     token = "<authentication_token>"
   ```

GitLab과 러너가 연결됩니다.

## 사용 가능한 모든 러너 나열 {#list-all-available-runners}

사용자가 사용할 수 있는 모든 러너를 나열합니다.

전제 조건:

- 그룹 러너의 경우 소유자 네임스페이스에서 소유자 역할을 가져야 합니다.
- 프로젝트 러너의 경우 러너에 할당된 프로젝트에서 보안 관리자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

```plaintext
GET /runners
GET /runners?scope=active
GET /runners?type=project_type
GET /runners?status=online
GET /runners?paused=true
GET /runners?tag_list=tag1,tag2
```

| 속성        | 유형         | 필수 | 설명 |
|------------------|--------------|----------|-------------|
| `scope`          | 문자열       | 아니요       | 지원 중단됨:  대신 `type` 또는 `status`을(를) 사용하세요. 반환할 러너의 범위는 다음 중 하나입니다. `active`, `paused`, `online` 및 `offline`; 제공된 것이 없으면 모든 러너를 표시합니다. |
| `type`           | 문자열       | 아니요       | 반환할 러너의 유형은 다음 중 하나입니다. `instance_type`, `group_type`, `project_type` |
| `status`         | 문자열       | 아니요       | 반환할 러너의 상태는 다음 중 하나입니다. `online`, `offline`, `stale` 또는 `never_contacted`.<br/>기타 가능한 값은 더 이상 사용되지 않는 `active` 및 `paused`입니다.<br/>`offline` 러너를 요청하면 `stale`이 `offline`에 포함되어 있기 때문에 `stale` 러너도 반환될 수 있습니다. |
| `paused`         | 부울      | 아니요       | 새 작업을 수락하거나 무시하는 러너만 포함할지 여부 |
| `tag_list`       | 문자열 배열 | 아니요       | 러너 태그 목록 |
| `version_prefix` | 문자열       | 아니요       | 반환할 러너의 버전 접두사입니다. 예를 들어 `15.0`, `14`, `16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners"
```

> [!warning]
> 더 이상 사용되지 않음:
>
> - `status` 쿼리 매개 변수의 `active` 및 `paused` 값은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 쿼리 매개 변수를 대신 사용하세요.
> - 응답의 `active` 속성은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 속성을 대신 사용하세요.
> - 응답의 `ip_address` 속성은 [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. GitLab 17.0에서는 이 속성이 빈 문자열을 반환합니다. `ipAddress` 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.

응답 예시:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "online",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    }
]
```

## 모든 러너 나열 {#list-all-runners}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 인스턴스의 모든 러너(프로젝트 및 공유)를 나열합니다.

전제 조건:

- 관리자 액세스 또는 감사자 액세스가 있어야 합니다.

```plaintext
GET /runners/all
GET /runners/all?scope=online
GET /runners/all?type=project_type
GET /runners/all?status=online
GET /runners/all?paused=true
GET /runners/all?tag_list=tag1,tag2
```

| 속성        | 유형         | 필수 | 설명 |
|------------------|--------------|----------|-------------|
| `scope`          | 문자열       | 아니요       | 지원 중단됨:  대신 `type` 또는 `status`을(를) 사용하세요. 반환할 러너의 범위는 다음 중 하나입니다. `specific`, `shared`, `active`, `paused`, `online` 및 `offline`; 제공된 것이 없으면 모든 러너를 표시합니다. |
| `type`           | 문자열       | 아니요       | 반환할 러너의 유형은 다음 중 하나입니다. `instance_type`, `group_type`, `project_type` |
| `status`         | 문자열       | 아니요       | 반환할 러너의 상태는 다음 중 하나입니다. `online`, `offline`, `stale` 또는 `never_contacted`.<br/>기타 가능한 값은 더 이상 사용되지 않는 `active` 및 `paused`입니다.<br/>`offline` 러너를 요청하면 `stale`이 `offline`에 포함되어 있기 때문에 `stale` 러너도 반환될 수 있습니다. |
| `paused`         | 부울      | 아니요       | 새 작업을 수락하거나 무시하는 러너만 포함할지 여부 |
| `tag_list`       | 문자열 배열 | 아니요       | 러너 태그 목록 |
| `version_prefix` | 문자열       | 아니요       | 반환할 러너의 버전 접두사입니다. 예를 들어 `15.0`, `16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/all"
```

> [!warning]
> 더 이상 사용되지 않음:
>
> - `status` 쿼리 매개 변수의 `active` 및 `paused` 값은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 쿼리 매개 변수를 대신 사용하세요.
> - 응답의 `active` 속성은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 속성을 대신 사용하세요.
> - 응답의 `ip_address` 속성은 [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. GitLab 17.0에서는 이 속성이 빈 문자열을 반환합니다. `ipAddress` 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.

응답 예시:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-1",
        "id": 1,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-2",
        "id": 3,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "paused",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    }
]
```

처음 20개 러너보다 많이 보려면 [페이지 매김](rest/_index.md#pagination)을 사용합니다.

## 러너의 세부 정보 검색 {#retrieve-runners-details}

러너의 세부 정보를 검색합니다.

인스턴스 러너 세부 정보는 이 엔드포인트를 통해 모든 인증된 사용자가 사용할 수 있습니다.

전제 조건:

- 사용자 액세스:  다음 중 하나를 가져야 합니다:
  - 그룹 러너의 경우:  소유자 네임스페이스에서 유지 관리자 또는 소유자 역할입니다.
  - 프로젝트 러너의 경우:  러너를 소유하는 프로젝트에서 보안 관리자, 유지 관리자 또는 소유자 역할입니다.
  - 관련 그룹 또는 프로젝트에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.
- `manage_runner` 범위가 있는 액세스 토큰과 적절한 역할입니다.

```plaintext
GET /runners/:id
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 정수 | 예      | 러너의 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/6"
```

> [!warning]
> 더 이상 사용되지 않음:
>
> - 응답의 `active` 속성은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 속성을 대신 사용하세요.
> - 응답의 `ip_address` 속성은 [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. GitLab 17.0에서는 이 속성이 빈 문자열을 반환합니다. `ipAddress` 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.
> - 응답의 `version`, `revision`, `platform` 및 `architecture` 속성은 [GitLab 17.0](https://gitlab.com/gitlab-org/gitlab/-/issues/457128) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. 동일한 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.

응답 예시:

```json
{
    "active": true,
    "paused": false,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "job_execution_status": "idle",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": 3600
}
```

## 러너의 세부 정보 업데이트 {#update-runners-details}

러너의 세부 정보를 업데이트합니다.

```plaintext
PUT /runners/:id
```

전제 조건:

- 사용자 액세스:  다음 중 하나를 가져야 합니다:
  - 인스턴스 러너의 경우:  GitLab 인스턴스에 대한 관리자 액세스입니다.
  - 그룹 러너의 경우:  소유자 네임스페이스에서 소유자 역할입니다.
  - 프로젝트 러너의 경우:  러너에 할당된 프로젝트에서 유지 관리자 또는 소유자 역할입니다.
  - 관련 그룹 또는 프로젝트에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.
- `manage_runner` 범위가 있는 액세스 토큰과 적절한 역할입니다.

| 속성          | 유형    | 필수 | 설명 |
|--------------------|---------|----------|-------------|
| `id`               | 정수 | 예      | 러너의 ID |
| `description`      | 문자열  | 아니요       | 러너의 설명 |
| `active`           | 부울 | 아니요       | 지원 중단됨:  `paused` 대신 사용합니다. 러너가 작업을 수신할 수 있는지 여부를 나타내는 플래그입니다. |
| `paused`           | 부울 | 아니요       | 러너가 새 작업을 무시해야 하는지 여부를 지정합니다. |
| `tag_list`         | 배열   | 아니요       | 러너에 대한 태그 목록 |
| `run_untagged`     | 부울 | 아니요       | 러너가 태그 없는 작업을 실행할 수 있는지 여부를 지정합니다. |
| `locked`           | 부울 | 아니요       | 러너가 잠겨 있는지 여부를 지정합니다. |
| `access_level`     | 문자열  | 아니요       | 러너의 액세스 수준입니다. `not_protected` 또는 `ref_protected` |
| `maximum_timeout`  | 정수 | 아니요       | 러너가 작업을 실행할 수 있는 시간(초)의 양을 제한하는 최대 시간 초과입니다. |
| `maintenance_note` | 문자열  | 아니요       | 러너에 대한 자유 형식의 유지 보수 메모(1024자) |

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/6" \
     --form "description=test-1-20150125-test" \
     --form "tag_list=ruby,mysql,tag1,tag2"
```

> [!warning]
> 더 이상 사용되지 않음:
>
> - `active` 쿼리 매개 변수는 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 속성을 대신 사용하세요.
> - 응답의 `ip_address` 속성은 [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. GitLab 17.0에서는 이 속성이 빈 문자열을 반환합니다. `ipAddress` 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.

응답 예시:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "group_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "job_execution_status": "idle",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql",
        "tag1",
        "tag2"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": null
}
```

### 러너 일시 중지 {#pause-a-runner}

러너를 일시 중지합니다.

전제 조건:

- 사용자 액세스:  다음 중 하나를 가져야 합니다:
  - 인스턴스 러너의 경우:  GitLab 인스턴스에 대한 관리자 액세스입니다.
  - 그룹 러너의 경우:  소유자 네임스페이스에서 소유자 역할입니다.
  - 프로젝트 러너의 경우:  러너에 할당된 프로젝트에서 유지 관리자 또는 소유자 역할입니다.
  - 관련 그룹 또는 프로젝트에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.
- `manage_runner` 범위가 있는 액세스 토큰과 적절한 역할입니다.

```plaintext
PUT --form "paused=true" /runners/:runner_id

# --or--

# Deprecated: removal planned in 16.0
PUT --form "active=false" /runners/:runner_id
```

| 속성   | 유형    | 필수 | 설명 |
|-------------|---------|----------|-------------|
| `runner_id` | 정수 | 예      | 러너의 ID |

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "paused=true"  \
     --url "https://gitlab.example.com/api/v4/runners/6"

# --or--

# Deprecated: removal planned in 16.0
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "active=false"  \
     --url "https://gitlab.example.com/api/v4/runners/6"
```

> [!warning]
> `active` 양식 속성은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 속성을 대신 사용하세요.

## 러너가 처리한 모든 작업 나열 {#list-all-jobs-processed-by-a-runner}

지정된 러너가 처리하고 있거나 처리한 모든 작업을 나열합니다. 작업 목록은 사용자가 기자, 개발자, 유지 관리자 또는 소유자 역할을 가진 프로젝트로 제한됩니다.

```plaintext
GET /runners/:id/jobs
```

| 속성   | 유형    | 필수 | 설명 |
|-------------|---------|----------|-------------|
| `id`        | 정수 | 예      | 러너의 ID |
| `system_id` | 문자열  | 아니요       | 러너 관리자가 실행 중인 머신의 시스템 ID |
| `status`    | 문자열  | 아니요       | 작업의 상태입니다. `running`, `success`, `failed`, `canceled` 중 하나입니다. |
| `order_by`  | 문자열  | 아니요       | `id`로 작업을 정렬합니다. |
| `sort`      | 문자열  | 아니요       | `asc` 또는 `desc` 순서로 작업을 정렬합니다(기본값: `desc`). `sort`가 지정된 경우 `order_by`도 지정해야 합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/1/jobs?status=running"
```

응답 예시:

```json
[
    {
        "id": 2,
        "status": "running",
        "stage": "test",
        "name": "test",
        "ref": "main",
        "tag": false,
        "coverage": null,
        "created_at": "2017-11-16T08:50:29.000Z",
        "started_at": "2017-11-16T08:51:29.000Z",
        "finished_at": "2017-11-16T08:53:29.000Z",
        "duration": 120,
        "queued_duration": 2,
        "user": {
            "id": 1,
            "name": "John Doe2",
            "username": "user2",
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
            "web_url": "http://localhost/user2",
            "created_at": "2017-11-16T18:38:46.000Z",
            "bio": null,
            "location": null,
            "public_email": "",
            "linkedin": "",
            "twitter": "",
            "website_url": "",
            "organization": null
        },
        "commit": {
            "id": "97de212e80737a608d939f648d959671fb0a0142",
            "short_id": "97de212e",
            "title": "Update configuration\r",
            "created_at": "2017-11-16T08:50:28.000Z",
            "parent_ids": [
                "1b12f15a11fc6e62177bef08f47bc7b5ce50b141",
                "498214de67004b1da3d820901307bed2a68a8ef6"
            ],
            "message": "See merge request !123",
            "author_name": "John Doe2",
            "author_email": "user2@example.org",
            "authored_date": "2017-11-16T08:50:27.000Z",
            "committer_name": "John Doe2",
            "committer_email": "user2@example.org",
            "committed_date": "2017-11-16T08:50:27.000Z"
        },
        "pipeline": {
            "id": 2,
            "sha": "97de212e80737a608d939f648d959671fb0a0142",
            "ref": "main",
            "status": "running"
        },
        "project": {
            "id": 1,
            "description": null,
            "name": "project1",
            "name_with_namespace": "John Doe2 / project1",
            "path": "project1",
            "path_with_namespace": "namespace1/project1",
            "created_at": "2017-11-16T18:38:46.620Z"
        }
    }
]
```

## 러너의 모든 관리자 나열 {#list-all-runners-managers}

러너의 모든 관리자를 나열합니다.

```plaintext
GET /runners/:id/managers
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 정수 | 예      | 러너의 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/1/managers"
```

응답 예시:

```json
[
    {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-06-09T11:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline",
      "job_execution_status": "idle"
    },
    {
      "id": 2,
      "system_id": "runner-2",
      "version": "16.11.0",
      "revision": "91a27b2a",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-06-09T09:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline",
      "job_execution_status": "idle"
    }
]
```

## 프로젝트의 모든 러너 나열 {#list-all-of-a-projects-runners}

상위 그룹 및 [허용된 모든 인스턴스 러너](../ci/runners/runners_scope.md#enable-instance-runners-for-a-project)를 포함한 프로젝트에서 사용 가능한 모든 러너를 나열합니다.

전제 조건:

- GitLab 인스턴스의 관리자이거나 대상 프로젝트에 대해 최소한 유지 관리자 또는 감사자 역할을 가져야 합니다.

```plaintext
GET /projects/:id/runners
GET /projects/:id/runners?scope=active
GET /projects/:id/runners?type=project_type
GET /projects/:id/runners?status=online
GET /projects/:id/runners?paused=true
GET /projects/:id/runners?tag_list=tag1,tag2
```

| 속성        | 유형           | 필수 | 설명 |
|------------------|----------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `scope`          | 문자열         | 아니요       | 지원 중단됨:  대신 `type` 또는 `status`을(를) 사용하세요. 반환할 러너의 범위는 다음 중 하나입니다. `active`, `paused`, `online` 및 `offline`; 제공된 것이 없으면 모든 러너를 표시합니다. |
| `type`           | 문자열         | 아니요       | 반환할 러너의 유형은 다음 중 하나입니다. `instance_type`, `group_type`, `project_type` |
| `status`         | 문자열         | 아니요       | 반환할 러너의 상태는 다음 중 하나입니다. `online`, `offline`, `stale` 또는 `never_contacted`.<br/>기타 가능한 값은 더 이상 사용되지 않는 `active` 및 `paused`입니다.<br/>`offline` 러너를 요청하면 `stale`이 `offline`에 포함되어 있기 때문에 `stale` 러너도 반환될 수 있습니다. |
| `paused`         | 부울        | 아니요       | 새 작업을 수락하거나 무시하는 러너만 포함할지 여부 |
| `tag_list`       | 문자열 배열   | 아니요       | 러너 태그 목록 |
| `version_prefix` | 문자열         | 아니요       | 반환할 러너의 버전 접두사입니다. 예를 들어 `15.0`, `14`, `16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners"
```

> [!warning]
> 더 이상 사용되지 않음:
>
> - `status` 쿼리 매개 변수의 `active` 및 `paused` 값은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 쿼리 매개 변수를 대신 사용하세요.
> - 응답의 `active` 속성은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 속성을 대신 사용하세요.
> - 응답의 `ip_address` 속성은 [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. GitLab 17.0에서는 이 속성이 GitLab 17.0에서 빈 문자열을 반환합니다. `ipAddress` 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.

응답 예시:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "development_runner",
        "id": 5,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online",
        "job_execution_status": "idle"
    }
]
```

## 러너를 프로젝트에 할당 {#assign-a-runner-to-project}

사용 가능한 프로젝트 러너를 프로젝트에 할당합니다.

전제 조건:

- 사용자 액세스:  다음 중 하나를 가져야 합니다:

  - 러너를 소유하는 프로젝트와 대상 프로젝트에 대해 유지 관리자 또는 소유자 역할입니다.
  - 관련 그룹 또는 프로젝트에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.

```plaintext
POST /projects/:id/runners
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `runner_id` | 정수        | 예      | 러너의 ID |

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners" \
     --form "runner_id=9"
```

> [!warning]
> `ip_address` 속성은 [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. GitLab 17.0에서는 이 속성이 빈 문자열을 반환합니다. `ipAddress` 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.

응답 예시:

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "name": null,
    "online": true,
    "status": "online",
    "job_execution_status": "idle"
}
```

## 프로젝트에서 러너 할당 해제 {#unassign-a-runner-from-project}

프로젝트에서 프로젝트 러너의 할당을 해제합니다. 소유자 프로젝트에서 러너의 할당을 해제할 수 없습니다. 이 작업을 시도하면 오류가 발생합니다. [러너 삭제](#delete-a-runner)에 대한 호출을 대신 사용합니다.

전제 조건:

- 관리자가 아닌 경우 러너를 잠글 수 없습니다.
- 사용자 액세스:  다음 중 하나를 가져야 합니다:
  - 할당 해제하려는 프로젝트에서 유지 관리자 또는 소유자 역할입니다.
  - 관련 그룹 또는 프로젝트에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.
- `manage_runner` 범위가 있는 액세스 토큰과 적절한 역할입니다.

```plaintext
DELETE /projects/:id/runners/:runner_id
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `runner_id` | 정수        | 예      | 러너의 ID |

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners/9"
```

## 그룹의 모든 러너 나열 {#list-all-of-a-groups-runners}

그룹 및 상위 그룹에서 사용 가능한 모든 러너를 나열하고, [허용된 모든 인스턴스 러너](../ci/runners/runners_scope.md#enable-instance-runners-for-a-group)를 포함합니다.

전제 조건:

- 사용자 액세스:  다음 중 하나를 가져야 합니다:
  - GitLab 인스턴스에 대한 관리자 액세스입니다.
  - 그룹에서 소유자 또는 감사자 역할입니다.
  - 그룹에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.
- `manage_runner` 범위가 있는 액세스 토큰과 적절한 역할입니다.

```plaintext
GET /groups/:id/runners
GET /groups/:id/runners?type=group_type
GET /groups/:id/runners/all?status=online
GET /groups/:id/runners/all?paused=true
GET /groups/:id/runners?tag_list=tag1,tag2
```

| 속성        | 유형         | 필수 | 설명 |
|------------------|--------------|----------|-------------|
| `id`             | 정수      | 예      | 그룹의 ID |
| `type`           | 문자열       | 아니요       | 반환할 러너의 유형은 다음 중 하나입니다. `instance_type`, `group_type`, `project_type`. `project_type` 값은 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/351466) GitLab 15.0에서 제거될 예정입니다. |
| `status`         | 문자열       | 아니요       | 반환할 러너의 상태는 다음 중 하나입니다. `online`, `offline`, `stale` 또는 `never_contacted`.<br/>기타 가능한 값은 더 이상 사용되지 않는 `active` 및 `paused`입니다.<br/>`offline` 러너를 요청하면 `stale`이 `offline`에 포함되어 있기 때문에 `stale` 러너도 반환될 수 있습니다. |
| `paused`         | 부울      | 아니요       | 새 작업을 수락하거나 무시하는 러너만 포함할지 여부 |
| `tag_list`       | 문자열 배열 | 아니요       | 러너 태그 목록 |
| `version_prefix` | 문자열       | 아니요       | 반환할 러너의 버전 접두사입니다. 예를 들어 `15.0`, `14`, `16.1.241` |

> [!warning]
> 더 이상 사용되지 않음:
>
> - `status` 쿼리 매개 변수의 `active` 및 `paused` 값은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 쿼리 매개 변수를 대신 사용하세요.
> - 응답의 `active` 속성은 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. `paused` 속성을 대신 사용하세요.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/9/runners"
```

> [!warning]
> `ip_address` 속성은 [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) 에서 더 이상 사용되지 않으며 [REST API의 향후 버전](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)에서 제거될 예정입니다. GitLab에서는 이 속성이 빈 문자열을 반환합니다. `ipAddress` 속성을 각 러너 관리자 내부에서 찾을 수 있습니다. GraphQL [`CiRunnerManager` 유형](graphql/reference/_index.md#cirunnermanager)을 통해서만 사용할 수 있습니다.

응답 예시:

```json
[
  {
    "id": 3,
    "description": "Shared",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted",
    "job_execution_status": "idle"
  },
  {
    "id": 6,
    "description": "Test",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": false,
    "status": "offline",
    "job_execution_status": "idle"
  },
  {
    "id": 8,
    "description": "Test 2",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": false,
    "runner_type": "group_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted",
    "job_execution_status": "idle"
  }
]
```

## 러너 만들기 {#create-a-runner}

> [!warning]
> 엔드포인트는 등록 토큰([더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/380872))을 사용하며, 이는 GitLab 17.0 이상에서 기본적으로 비활성화됩니다. 권장 워크플로로 러너를 만들려면 [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user)를 대신 사용합니다.

러너 등록 토큰으로 러너를 만듭니다.

러너 등록 토큰으로 등록이 프로젝트 또는 그룹 설정에서 비활성화된 경우 이 엔드포인트는 `HTTP 410 Gone` 상태 코드를 반환합니다. 러너 등록 토큰으로 등록이 비활성화된 경우 [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user) 엔드포인트를 사용하여 러너를 만들고 등록합니다.

```plaintext
POST /runners
```

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `token`            | 문자열       | 예      | [등록 토큰](#registration-and-authentication-tokens) |
| `description`      | 문자열       | 아니요       | 러너의 설명 |
| `info`             | 해시         | 아니요       | 러너의 메타데이터입니다. `name`, `version`, `revision`, `platform` 및 `architecture`를 포함할 수 있지만, `version`, `platform` 및 `architecture`만 **운영자** 영역의 UI에 표시됩니다. |
| `active`           | 부울      | 아니요       | 지원 중단됨:  `paused` 대신 사용합니다. 러너가 새 작업을 수신할 수 있는지 여부를 지정합니다. |
| `paused`           | 부울      | 아니요       | 러너가 새 작업을 무시해야 하는지 여부를 지정합니다. |
| `locked`           | 부울      | 아니요       | 러너가 현재 프로젝트에 대해 잠겨야 하는지 여부를 지정합니다. |
| `run_untagged`     | 부울      | 아니요       | 러너가 태그 없는 작업을 처리해야 하는지 여부를 지정합니다. |
| `tag_list`         | 문자열 배열 | 아니요       | 러너 태그 목록 |
| `access_level`     | 문자열       | 아니요       | 러너의 액세스 수준입니다. `not_protected` 또는 `ref_protected` |
| `maximum_timeout`  | 정수      | 아니요       | 러너가 작업을 실행할 수 있는 시간(초)의 양을 제한하는 최대 시간 초과입니다. |
| `maintainer_note`  | 문자열       | 아니요       | [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/350730), `maintenance_note` 참조 |
| `maintenance_note` | 문자열       | 아니요       | 러너에 대한 자유 형식의 유지 보수 메모(1024자) |

```shell
curl --request POST \
     --url "https://gitlab.example.com/api/v4/runners" \
     --form "token=<registration_token>" --form "description=test-1-20150125-test" \
     --form "tag_list=ruby,mysql,tag1,tag2"
```

응답:

| 상태 | 설명 |
|--------|-------------|
| 201    | 러너가 생성됨 |
| 403    | 잘못된 러너 등록 토큰 |
| 410    | 러너 등록이 비활성화됨 |

응답 예시:

```json
{
    "id": 12345,
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## 러너 삭제 {#delete-a-runner}

다음을 지정하여 러너를 삭제할 수 있습니다:

- 러너 ID
- 러너의 인증 토큰

### ID로 러너 삭제 {#delete-a-runner-by-id}

ID로 러너를 삭제하려면 러너의 ID로 액세스 토큰을 사용합니다:

전제 조건:

- 사용자 액세스:  다음 중 하나를 가져야 합니다:
  - 인스턴스 러너의 경우:  GitLab 인스턴스에 대한 관리자 액세스입니다.
  - 그룹 러너의 경우:  소유자 네임스페이스에서 소유자 역할입니다.
  - 프로젝트 러너의 경우:  러너를 소유하는 프로젝트에서 유지 관리자 또는 소유자 역할입니다.
  - 관련 그룹 또는 프로젝트에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.
- `manage_runner` 범위가 있는 액세스 토큰과 적절한 역할입니다.

```plaintext
DELETE /runners/:id
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 정수 | 예      | 러너의 ID입니다. ID는 **설정** > **CI/CD** 아래의 UI에서 볼 수 있습니다. **러너**를 확장하면 **Remove Runner** 아래에 파운드 기호가 앞에 오는 ID가 있습니다(예: `#6`). |

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/6"
```

### 인증 토큰으로 러너 삭제 {#delete-a-runner-by-authentication-token}

인증 토큰을 사용하여 러너를 삭제합니다.

```plaintext
DELETE /runners
```

| 속성 | 유형   | 필수 | 설명 |
|-----------|--------|----------|-------------|
| `token`   | 문자열 | 예      | 러너의 [인증 토큰](#registration-and-authentication-tokens)입니다. |

```shell
curl --request DELETE \
     --url "https://gitlab.example.com/api/v4/runners" \
     --form "token=<authentication_token>"
```

응답:

| 상태 | 설명 |
|--------|-------------|
| 204    | 러너가 삭제됨 |

## 등록된 러너의 인증 확인 {#verify-authentication-for-a-registered-runner}

등록된 러너의 인증 자격 증명을 검증합니다.

```plaintext
POST /runners/verify
```

| 속성   | 유형   | 필수 | 설명 |
|-------------|--------|----------|-------------|
| `token`     | 문자열 | 예      | 러너의 [인증 토큰](#registration-and-authentication-tokens)입니다. |
| `system_id` | 문자열 | 아니요       | 러너의 시스템 식별자입니다. `token`이 `glrt-`로 시작하면 이 속성은 필수입니다. |

```shell
curl --request POST \
     --url "https://gitlab.example.com/api/v4/runners/verify" \
     --form "token=<authentication_token>"
```

응답:

| 상태 | 설명 |
|--------|-------------|
| 200    | 자격 증명이 유효함 |
| 403    | 자격 증명이 유효하지 않음 |

응답 예시:

```json
{
    "id": 12345,
    "token": "glrt-6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## 인스턴스의 러너 등록 토큰 재설정 {#reset-instances-runner-registration-token}

> [!warning]
> 러너 등록 토큰을 전달하고 특정 구성 인수를 지원하는 옵션은 레거시로 간주되며 권장하지 않습니다. [러너 생성 워크플로](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다.
>
> 자세한 내용은 [새 러너 등록 워크플로로 마이그레이션](../ci/runners/new_creation_workflow.md)을 참조합니다.

GitLab 인스턴스의 러너 등록 토큰을 재설정합니다.

```plaintext
POST /runners/reset_registration_token
```

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/reset_registration_token"
```

## 프로젝트의 러너 등록 토큰 재설정 {#reset-projects-runner-registration-token}

> [!warning]
> 러너 등록 토큰을 전달하고 특정 구성 인수를 지원하는 옵션은 레거시로 간주되며 권장하지 않습니다. [러너 생성 워크플로](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새 러너 등록 워크플로로 마이그레이션](../ci/runners/new_creation_workflow.md)을 참조합니다.

프로젝트의 러너 등록 토큰을 재설정합니다.

```plaintext
POST /projects/:id/runners/reset_registration_token
```

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners/reset_registration_token"
```

## 그룹의 러너 등록 토큰 재설정 {#reset-groups-runner-registration-token}

> [!warning]
> 러너 등록 토큰을 전달하고 특정 구성 인수를 지원하는 옵션은 레거시로 간주되며 권장하지 않습니다. [러너 생성 워크플로](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새 러너 등록 워크플로로 마이그레이션](../ci/runners/new_creation_workflow.md)을 참조합니다.

그룹의 러너 등록 토큰을 재설정합니다.

```plaintext
POST /groups/:id/runners/reset_registration_token
```

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/9/runners/reset_registration_token"
```

## 러너 ID를 사용하여 러너의 인증 토큰 재설정 {#reset-runners-authentication-token-by-using-the-runner-id}

러너 ID를 사용하여 러너의 인증 토큰을 재설정합니다.

전제 조건:

- 사용자 액세스:  다음 중 하나를 가져야 합니다:
  - 인스턴스 러너의 경우:  GitLab 인스턴스에 대한 관리자 액세스입니다.
  - 그룹 러너의 경우:  소유자 네임스페이스에서 소유자 역할입니다.
  - 프로젝트 러너의 경우:  러너에 할당된 프로젝트에서 유지 관리자 또는 소유자 역할입니다.
  - 관련 그룹 또는 프로젝트에서 `admin_runners` 권한이 있는 사용자 지정 역할입니다.
- `manage_runner` 범위가 있는 액세스 토큰과 적절한 역할입니다.

```plaintext
POST /runners/:id/reset_authentication_token
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 정수 | 예      | 러너의 ID |

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/1/reset_authentication_token"
```

응답 예시:

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## 현재 토큰을 사용하여 러너의 인증 토큰 재설정 {#reset-runners-authentication-token-by-using-the-current-token}

현재 토큰의 값을 입력으로 사용하여 러너의 인증 토큰을 재설정합니다.

```plaintext
POST /runners/reset_authentication_token
```

| 속성 | 유형   | 필수 | 설명 |
|-----------|--------|----------|-------------|
| `token`   | 문자열 | 예      | 러너의 인증 토큰 |

```shell
curl --request POST \
     --form "token=<current token>" \
     --url "https://gitlab.example.com/api/v4/runners/reset_authentication_token"
```

응답 예시:

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Job Router 정보 검색 {#discover-job-router-information}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/19607) 되었으며 [기능 플래그](../administration/feature_flags/_index.md) `job_router` 및 `job_router_instance_runners` 명명됩니다. 기본적으로 비활성화됨.

{{< /history >}}

러너에 대한 Job Router 검색 정보를 가져옵니다.

전제 조건:

- 유효한 러너 인증 토큰을 제공해야 합니다.

```plaintext
GET /runners/router/discovery
```

```shell
curl --header "Runner-Token: <runner_authentication_token>" \
     --url "https://gitlab.example.com/api/v4/runners/router/discovery"
```

응답:

응답에는 다음 필드가 포함됩니다:

| 속성    | 유형     | 설명           |
|--------------|----------|-----------------------|
| `server_url` | 문자열   | Job Router로 가는 URL |

응답은 다음 상태 코드 중 하나로 반환됩니다:

| 상태 | 설명                                   |
|--------|-----------------------------------------------|
| `200`  | Job Router 정보가 성공적으로 검색됨 |
| `403`  | 금지됨                                     |
| `501`  | Job Router를 사용할 수 없음                   |

응답 예시:

```json
{
    "server_url": "wss://kas.example.com"
}
```
