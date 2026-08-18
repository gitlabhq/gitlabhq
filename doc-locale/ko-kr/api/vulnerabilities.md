---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 취약성 API
description: "GitLab 취약성을 REST API를 통해 관리합니다(지원 중단됨). 검색, 확인, 해결, 무시 및 되돌리기 작업을 지원합니다. 대신 GraphQL을 사용합니다."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `last_edited_at` [지원 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) (GitLab 16.7).
- `start_date` [지원 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) (GitLab 16.7).
- `updated_by_id` [지원 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) (GitLab 16.7).
- `last_edited_by_id` [지원 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) (GitLab 16.7).
- `due_date` [지원 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) (GitLab 16.7).

{{< /history >}}

> [!note]
> 이전 취약성 API는 취약성 Findings API로 이름이 변경되었으며 문서는 [다른 위치](vulnerability_findings.md)로 이동되었습니다. 이 문서에서는 [취약성](https://gitlab.com/groups/gitlab-org/-/epics/634)에 대한 액세스를 제공하는 새로운 취약성 API를 설명합니다.

취약성에 대한 모든 API 호출은 [인증](rest/authentication.md)되어야 합니다.

인증된 사용자에게 [취약성 보고서 보기](../user/permissions.md#project-application-security) 권한이 없는 경우 이 요청은 `403 Forbidden` 상태 코드를 반환합니다.

> [!warning]
> 이 API는 지원 중단 중이며 불안정한 것으로 간주됩니다. 응답 페이로드는 GitLab 릴리스 전반에 걸쳐 변경되거나 손상될 수 있습니다. 대신 [GraphQL API](graphql/reference/_index.md#queryvulnerabilities)를 사용합니다. 자세한 내용은 [GraphQL 예제](#replace-vulnerability-rest-api-with-graphql)를 참조하세요.

## 취약성 검색 {#retrieve-a-vulnerability}

지정된 취약성을 검색합니다.

```plaintext
GET /vulnerabilities/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 가져올 취약성의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/1"
```

응답 예시:

```json
{
  "id": 1,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "opened",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 취약성 확인 {#confirm-a-vulnerability}

지정된 취약성을 확인합니다. 취약성이 이미 확인된 경우 상태 코드 `304`을 반환합니다.

인증된 사용자에게 [취약성 상태 변경](../user/permissions.md#project-application-security) 권한이 없는 경우 이 요청은 `403` 상태 코드를 생성합니다.

```plaintext
POST /vulnerabilities/:id/confirm
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 확인할 취약성의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/confirm"
```

응답 예시:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "confirmed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 취약성 해결 {#resolve-a-vulnerability}

지정된 취약성을 해결합니다. 취약성이 이미 해결된 경우 상태 코드 `304`을 반환합니다.

인증된 사용자에게 [취약성 상태 변경](../user/permissions.md#project-application-security) 권한이 없는 경우 이 요청은 `403` 상태 코드를 생성합니다.

```plaintext
POST /vulnerabilities/:id/resolve
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 해결할 취약성의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/resolve"
```

응답 예시:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "resolved",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 취약성 무시 {#dismiss-a-vulnerability}

지정된 취약성을 무시합니다. 취약성이 이미 무시된 경우 상태 코드 `304`을 반환합니다.

인증된 사용자에게 [취약성 상태 변경](../user/permissions.md#project-application-security) 권한이 없는 경우 이 요청은 `403` 상태 코드를 생성합니다.

```plaintext
POST /vulnerabilities/:id/dismiss
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 무시할 취약성의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/dismiss"
```

응답 예시:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "closed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 취약성을 감지된 상태로 되돌리기 {#revert-a-vulnerability-to-the-detected-state}

지정된 취약성을 감지된 상태로 되돌립니다. 취약성이 이미 감지된 상태인 경우 상태 코드 `304`을 반환합니다.

인증된 사용자에게 [취약성 상태 변경](../user/permissions.md#project-application-security) 권한이 없는 경우 이 요청은 `403` 상태 코드를 생성합니다.

```plaintext
POST /vulnerabilities/:id/revert
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 취약성을 감지된 상태로 되돌릴 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/revert"
```

응답 예시:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "detected",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 취약성 REST API를 GraphQL로 바꾸기 {#replace-vulnerability-rest-api-with-graphql}

취약성 REST API 엔드포인트의 [예정된 지원 중단](https://gitlab.com/groups/gitlab-org/-/epics/5118)에 대비하기 위해 아래 예제를 사용하여 GraphQL API로 동등한 작업을 수행합니다.

### GraphQL - 단일 취약성 {#graphql---single-vulnerability}

[`Query.vulnerability`](graphql/reference/_index.md#queryvulnerability)를 사용합니다.

```graphql
{
  vulnerability(id: "gid://gitlab/Vulnerability/20345379") {
    title
    description
    state
    severity
    reportType
    project {
      id
      name
      fullPath
    }
    detectedAt
    confirmedAt
    resolvedAt
    resolvedBy {
      id
      username
    }
  }
}
```

응답 예시:

```json
{
  "data": {
    "vulnerability": {
      "title": "Improper Input Validation in railties",
      "description": "A remote code execution vulnerability in development mode Rails beta3 can allow an attacker to guess the automatically generated development mode secret token. This secret token can be used in combination with other Rails internals to escalate to a remote code execution exploit.",
      "state": "RESOLVED",
      "severity": "CRITICAL",
      "reportType": "DEPENDENCY_SCANNING",
      "project": {
        "id": "gid://gitlab/Project/6102100",
        "name": "security-reports",
        "fullPath": "gitlab-examples/security/security-reports"
      },
      "detectedAt": "2021-10-14T03:13:41Z",
      "confirmedAt": "2021-12-14T01:45:56Z",
      "resolvedAt": "2021-12-14T01:45:59Z",
      "resolvedBy": {
        "id": "gid://gitlab/User/480804",
        "username": "thiagocsf"
      }
    }
  }
}
```

### GraphQL - 취약성 확인 {#graphql---confirm-vulnerability}

[`Mutation.vulnerabilityConfirm`](graphql/reference/_index.md#mutationvulnerabilityconfirm)를 사용합니다.

```graphql
mutation {
  vulnerabilityConfirm(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

응답 예시:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "CONFIRMED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - 취약성 해결 {#graphql---resolve-vulnerability}

[`Mutation.vulnerabilityResolve`](graphql/reference/_index.md#mutationvulnerabilityresolve)를 사용합니다.

```graphql
mutation {
  vulnerabilityResolve(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

응답 예시:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "RESOLVED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - 취약성 무시 {#graphql---dismiss-vulnerability}

[`Mutation.vulnerabilityDismiss`](graphql/reference/_index.md#mutationvulnerabilitydismiss)를 사용합니다.

```graphql
mutation {
  vulnerabilityDismiss(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

응답 예시:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DISMISSED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - 취약성을 감지된 상태로 되돌리기 {#graphql---revert-vulnerability-to-the-detected-state}

[`Mutation.vulnerabilityRevertToDetected`](graphql/reference/_index.md#mutationvulnerabilityreverttodetected)를 사용합니다.

```graphql
mutation {
  vulnerabilityRevertToDetected(input: { id: "gid://gitlab/Vulnerability/20345379"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

응답 예시:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DETECTED"
      },
      "errors": []
    }
  }
}
```
