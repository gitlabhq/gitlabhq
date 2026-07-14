---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "인스턴스, 그룹 및 프로젝트의 GitLab 감사 이벤트를 검색하기 위한 REST API입니다."
title: 감사 이벤트 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [응답 본문에 작성자 이메일 추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/386322) (GitLab 15.9)

{{< /history >}}

## 인스턴스 감사 이벤트 {#instance-audit-events}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab 셀프 관리, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [인스턴스 감사 이벤트](../administration/compliance/audit_event_reports.md)를 검색합니다.

API를 사용하여 감사 이벤트를 검색하려면 관리자로 [인증](rest/authentication.md)해야 합니다.

### 모든 인스턴스 감사 이벤트 나열 {#list-all-instance-audit-events}

{{< history >}}

- 키셋 페이지 매김 지원 [GitLab 15.11에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/367528)
- 엔터티 유형 `Gitlab::Audit::InstanceScope` (인스턴스 감사 이벤트의 경우 [GitLab 16.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/418185))

{{< /history >}}

사용 가능한 모든 인스턴스 감사 이벤트를 나열하며, 각 쿼리마다 최대 30일로 제한됩니다.

```plaintext
GET /audit_events
```

| 속성 | 유형 | 필수 | 설명                                                                                                     |
| --------- | ---- | -------- |-----------------------------------------------------------------------------------------------------------------|
| `created_after` | 문자열 | 아니요 | 지정된 시간 이후에 생성된 감사 이벤트를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)               |
| `created_before` | 문자열 | 아니요 | 지정된 시간 이전에 생성된 감사 이벤트를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)              |
| `entity_type` | 문자열 | 아니요 | 주어진 엔터티 유형에 대한 감사 이벤트를 반환합니다. 유효한 값은 `User`, `Group`, `Project` 또는 `Gitlab::Audit::InstanceScope`입니다. |
| `entity_id` | 정수 | 아니요 | 주어진 엔터티 ID에 대한 감사 이벤트를 반환합니다. `entity_type` 속성이 있어야 합니다.                    |

> [!warning]
> 오프셋 기반 페이지 매김은 GitLab 17.8에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194) 19.0에서 제거할 예정입니다. 대신 [키셋 기반](rest/_index.md#keyset-based-pagination) 페이지 매김을 사용합니다. 이 변경은 주요 변경입니다.

이 엔드포인트는 오프셋 기반 및 [키셋 기반](rest/_index.md#keyset-based-pagination) 페이지 매김을 모두 지원합니다. 연속된 페이지의 결과를 요청할 때는 키셋 기반 페이지 매김을 사용해야 합니다.

[페이지 매김](rest/_index.md#pagination)에 대해 자세히 알아봅니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/audit_events"
```

응답 예시:

```json
[
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 6,
    "entity_type": "Project",
    "details": {
      "custom_message": "Project archived",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs/flight",
      "target_type": "Project",
      "target_details": "flightjs/flight",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs/flight"
    },
    "created_at": "2019-08-30T07:00:41.885Z"
  },
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  },
  {
    "id": 3,
    "author_id": 51,
    "entity_id": 51,
    "entity_type": "User",
    "details": {
      "change": "email address",
      "from": "hello@flightjs.com",
      "to": "maintainer@flightjs.com",
      "author_name": "Andreas",
      "author_email": "admin@example.com",
      "target_id": 51,
      "target_type": "User",
      "target_details": "Andreas",
      "ip_address": null,
      "entity_path": "Andreas"
    },
    "created_at": "2019-08-22T16:34:25.639Z"
  },
  {
    "id": 4,
    "author_id": 43,
    "entity_id": 1,
    "entity_type": "Gitlab::Audit::InstanceScope",
    "details": {
      "author_name": "Administrator",
      "author_class": "User",
      "target_id": 32,
      "target_type": "AuditEvents::Streaming::InstanceHeader",
      "target_details": "unknown",
      "custom_message": "Created custom HTTP header with key X-arg.",
      "ip_address": "127.0.0.1",
      "entity_path": "gitlab_instance"
    },
    "ip_address": "127.0.0.1",
    "author_name": "Administrator",
    "entity_path": "gitlab_instance",
    "target_details": "unknown",
    "created_at": "2023-08-01T11:29:44.764Z",
    "target_type": "AuditEvents::Streaming::InstanceHeader",
    "target_id": 32,
    "event_type": "audit_events_streaming_instance_headers_create"
  }
]
```

### 인스턴스 감사 이벤트 검색 {#retrieve-an-instance-audit-event}

지정된 인스턴스 감사 이벤트를 검색합니다.

```plaintext
GET /audit_events/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 감사 이벤트의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/audit_events/1"
```

응답 예시:

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 6,
  "entity_type": "Project",
  "details": {
    "custom_message": "Project archived",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "target_id": "flightjs/flight",
    "target_type": "Project",
    "target_details": "flightjs/flight",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs/flight"
  },
  "created_at": "2019-08-30T07:00:41.885Z"
}
```

## 그룹 감사 이벤트 {#group-audit-events}

{{< history >}}

- 키셋 페이지 매김 지원 [GitLab 15.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/333968)

{{< /history >}}

이 API를 사용하여 [그룹 감사 이벤트](../user/compliance/audit_events.md#group-audit-events)를 검색합니다.

다음 권한이 있는 사용자:

- 소유자 역할은 모든 사용자의 그룹 감사 이벤트를 검색할 수 있습니다.
- 개발자 또는 유지보수자 역할은 개인 작업을 기반으로 그룹 감사 이벤트로 제한됩니다.

> [!warning]
> 오프셋 기반 페이지 매김은 GitLab 17.8에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194) 19.0에서 제거할 예정입니다. 대신 [키셋 기반](rest/_index.md#keyset-based-pagination) 페이지 매김을 사용합니다. 이 변경은 주요 변경입니다.

이 엔드포인트는 오프셋 기반 및 [키셋 기반](rest/_index.md#keyset-based-pagination) 페이지 매김을 모두 지원합니다. 연속된 페이지의 결과를 요청할 때는 키셋 기반 페이지 매김을 권장합니다.

### 모든 그룹 감사 이벤트 나열 {#list-all-group-audit-events}

{{< history >}}

- 키셋 페이지 매김 지원 [GitLab 15.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/333968)

{{< /history >}}

지정된 그룹의 모든 감사 이벤트를 나열합니다.

```plaintext
GET /groups/:id/audit_events
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `created_after` | 문자열 | 아니요 | 지정된 시간 이후에 생성된 그룹 감사 이벤트를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ)`  |
| `created_before` | 문자열 | 아니요 | 지정된 시간 이전에 생성된 그룹 감사 이벤트를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

기본적으로 `GET` 요청은 API 결과가 페이지로 나뉘어지기 때문에 한 번에 20개의 결과를 반환합니다.

[페이지 매김](rest/_index.md#pagination)에 대해 자세히 알아봅니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/60/audit_events"
```

응답 예시:

```json
[
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "custom_message": "Group marked for deletion",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-28T19:36:44.162Z"
  },
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  }
]
```

### 그룹 감사 이벤트 검색 {#retrieve-a-group-audit-event}

지정된 그룹의 감사 이벤트를 검색합니다. 그룹 소유자 및 관리자만 사용 가능합니다.

```plaintext
GET /groups/:id/audit_events/:audit_event_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `audit_event_id` | 정수 | 예 | 감사 이벤트의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/60/audit_events/2"
```

응답 예시:

```json
{
  "id": 2,
  "author_id": 1,
  "entity_id": 60,
  "entity_type": "Group",
  "details": {
    "custom_message": "Group marked for deletion",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "target_id": "flightjs",
    "target_type": "Group",
    "target_details": "flightjs",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs"
  },
  "created_at": "2019-08-28T19:36:44.162Z"
}
```

## 프로젝트 감사 이벤트 {#project-audit-events}

이 API를 사용하여 [프로젝트 감사 이벤트](../user/compliance/audit_events.md#project-audit-events)를 검색합니다.

유지보수자 역할(이상)이 있는 사용자는 모든 사용자의 프로젝트 감사 이벤트를 검색할 수 있습니다. 개발자 역할이 있는 사용자는 개인 작업을 기반으로 프로젝트 감사 이벤트로 제한됩니다.

### 모든 프로젝트 감사 이벤트 나열 {#list-all-project-audit-events}

{{< history >}}

- 키셋 페이지 매김 지원 [GitLab 15.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/367528)

{{< /history >}}

지정된 프로젝트의 모든 감사 이벤트를 나열합니다.

```plaintext
GET /projects/:id/audit_events
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `created_after` | 문자열 | 아니요 | 지정된 시간 이후에 생성된 프로젝트 감사 이벤트를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)  |
| `created_before` | 문자열 | 아니요 | 지정된 시간 이전에 생성된 프로젝트 감사 이벤트를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

> [!warning]
> 오프셋 기반 페이지 매김은 GitLab 17.8에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194) 19.0에서 제거할 예정입니다. 대신 [키셋 기반](rest/_index.md#keyset-based-pagination) 페이지 매김을 사용합니다. 이 변경은 주요 변경입니다.

기본적으로 `GET` 요청은 API 결과가 페이지로 나뉘어지기 때문에 한 번에 20개의 결과를 반환합니다. 연속된 페이지의 결과를 요청할 때는 [키셋 페이지 매김](rest/_index.md#keyset-based-pagination)을 사용해야 합니다.

[페이지 매김](rest/_index.md#pagination)에 대해 자세히 알아봅니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/projects/7/audit_events"
```

응답 예시:

```json
[
  {
    "id": 5,
    "author_id": 1,
    "entity_id": 7,
    "entity_type": "Project",
    "details": {
        "change": "prevent merge request approval from committers",
        "from": "",
        "to": "true",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "target_id": 7,
        "target_type": "Project",
        "target_details": "twitter/typeahead-js",
        "ip_address": "127.0.0.1",
        "entity_path": "twitter/typeahead-js"
    },
    "created_at": "2020-05-26T22:55:04.230Z"
  },
  {
      "id": 4,
      "author_id": 1,
      "entity_id": 7,
      "entity_type": "Project",
      "details": {
          "change": "prevent merge request approval from authors",
          "from": "false",
          "to": "true",
          "author_name": "Administrator",
          "author_email": "admin@example.com",
          "target_id": 7,
          "target_type": "Project",
          "target_details": "twitter/typeahead-js",
          "ip_address": "127.0.0.1",
          "entity_path": "twitter/typeahead-js"
      },
      "created_at": "2020-05-26T22:55:04.218Z"
  }
]
```

### 프로젝트 감사 이벤트 검색 {#retrieve-a-project-audit-event}

지정된 프로젝트의 감사 이벤트를 검색합니다. 프로젝트의 유지보수자 또는 소유자 역할이 있는 사용자만 사용 가능합니다.

```plaintext
GET /projects/:id/audit_events/:audit_event_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `audit_event_id` | 정수 | 예 | 감사 이벤트의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/projects/7/audit_events/5"
```

응답 예시:

```json
{
  "id": 5,
  "author_id": 1,
  "entity_id": 7,
  "entity_type": "Project",
  "details": {
      "change": "prevent merge request approval from committers",
      "from": "",
      "to": "true",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": 7,
      "target_type": "Project",
      "target_details": "twitter/typeahead-js",
      "ip_address": "127.0.0.1",
      "entity_path": "twitter/typeahead-js"
  },
  "created_at": "2020-05-26T22:55:04.230Z"
}
```
