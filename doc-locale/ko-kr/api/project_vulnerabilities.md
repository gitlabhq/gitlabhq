---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 취약성 API
description: 프로젝트 취약성 API는 프로젝트 취약성을 나열하고 생성합니다. 인증 및 적절한 권한이 필요합니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `last_edited_at` [사용 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) GitLab 16.7
- `start_date` [사용 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) GitLab 16.7
- `updated_by_id` [사용 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) GitLab 16.7
- `last_edited_by_id` [사용 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) GitLab 16.7
- `due_date` [사용 중단됨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) GitLab 16.7

{{< /history >}}

> [!warning]
> 이 API는 사용 중단 중이며 불안정한 상태로 간주됩니다. 응답 페이로드는 GitLab 릴리스 간에 변경되거나 손상될 수 있습니다. 대신 [GraphQL API](graphql/reference/_index.md#queryvulnerabilities)를 사용합니다.

이 API를 사용하여 [프로젝트 취약성](../user/application_security/vulnerabilities/_index.md)을 관리합니다. 이 API에 대한 모든 호출에는 인증이 필요합니다.

사용자가 비공개 프로젝트의 멤버가 아닌 경우 비공개 프로젝트에 대한 요청은 `404 Not Found` 상태 코드를 반환합니다.

## 프로젝트 취약성 나열 {#list-project-vulnerabilities}

프로젝트의 모든 취약성을 나열합니다.

인증된 사용자가 [프로젝트 보안 대시보드 사용](../user/permissions.md#project-permissions) 권한이 없으면 이 프로젝트의 취약성에 대한 `GET` 요청으로 인해 `403` 상태 코드가 발생합니다.

응답은 [페이지로 나뉘며](rest/_index.md#pagination) 기본적으로 20개의 결과를 반환합니다.

```plaintext
GET /projects/:id/vulnerabilities
```

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                                                            |

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/4/vulnerabilities"
```

응답 예시:

```json
[
    {
        "author_id": 1,
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.655Z",
        "description": null,
        "dismissed_at": null,
        "dismissed_by_id": null,
        "finding": {
            "confidence": "medium",
            "created_at": "2020-04-07T14:01:04.630Z",
            "id": 103,
            "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
            "metadata_version": "2.0",
            "name": "Regular Expression Denial of Service in debug",
            "primary_identifier_id": 135,
            "project_id": 24,
            "raw_metadata": "{\"category\":\"dependency_scanning\",\"name\":\"Regular Expression Denial of Service\",\"message\":\"Regular Expression Denial of Service in debug\",\"description\":\"The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.\",\"cve\":\"yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a\",\"severity\":\"Unknown\",\"solution\":\"Upgrade to latest versions.\",\"scanner\":{\"id\":\"gemnasium\",\"name\":\"Gemnasium\"},\"location\":{\"file\":\"yarn.lock\",\"dependency\":{\"package\":{\"name\":\"debug\"},\"version\":\"1.0.5\"}},\"identifiers\":[{\"type\":\"gemnasium\",\"name\":\"Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a\",\"value\":\"37283ed4-0380-40d7-ada7-2d994afcc62a\",\"url\":\"https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories\"}],\"links\":[{\"url\":\"https://nodesecurity.io/advisories/534\"},{\"url\":\"https://github.com/visionmedia/debug/issues/501\"},{\"url\":\"https://github.com/visionmedia/debug/pull/504\"}],\"remediations\":[null]}",
            "report_type": "dependency_scanning",
            "scanner_id": 63,
            "severity": "low",
            "updated_at": "2020-04-07T14:01:04.664Z",
            "uuid": "f1d528ae-d0cc-47f6-a72f-936cec846ae7",
            "vulnerability_id": 103
        },
        "id": 103,
        "project": {
            "created_at": "2020-04-07T13:54:25.634Z",
            "description": "",
            "id": 24,
            "name": "security-reports",
            "name_with_namespace": "gitlab-org / security-reports",
            "path": "security-reports",
            "path_with_namespace": "gitlab-org/security-reports"
        },
        "project_default_branch": "main",
        "report_type": "dependency_scanning",
        "resolved_at": null,
        "resolved_by_id": null,
        "resolved_on_default_branch": false,
        "severity": "low",
        "state": "detected",
        "title": "Regular Expression Denial of Service in debug",
        "updated_at": "2020-04-07T14:01:04.655Z"
    }
]
```

## 취약성 생성 {#create-a-vulnerability}

새 취약성을 생성합니다.

인증된 사용자가 [새 취약성 생성](../user/permissions.md#project-permissions) 권한이 없으면 이 요청으로 인해 `403` 상태 코드가 발생합니다.

```plaintext
POST /projects/:id/vulnerabilities?finding_id=<your_finding_id>
```

| 속성           | 유형              | 필수   | 설명                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열 | 예        | 인증된 사용자가 멤버인 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)  |
| `finding_id`        | 정수 또는 문자열 | 예        | 새 취약성을 생성할 취약성 찾기의 ID |

새로 생성된 취약성의 다른 속성은 해당 원본 취약성 찾기에서 채워지거나 다음 기본값으로 채워집니다:

| 속성    | 값                                                 |
|--------------|-------------------------------------------------------|
| `author`     | 인증된 사용자                                |
| `title`      | 취약성 찾기의 `name` 속성       |
| `state`      | `opened`                                              |
| `severity`   | 취약성 찾기의 `severity` 속성   |
| `confidence` | 취약성 찾기의 `confidence` 속성 |

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/1/vulnerabilities?finding_id=1"
```

응답 예시:

```json
{
    "author_id": 1,
    "confidence": "medium",
    "created_at": "2020-04-07T14:01:04.655Z",
    "description": null,
    "dismissed_at": null,
    "dismissed_by_id": null,
    "finding": {
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.630Z",
        "id": 103,
        "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
        "metadata_version": "2.0",
        "name": "Regular Expression Denial of Service in debug",
        "primary_identifier_id": 135,
        "project_id": 24,
        "raw_metadata": "{\"category\":\"dependency_scanning\",\"name\":\"Regular Expression Denial of Service\",\"message\":\"Regular Expression Denial of Service in debug\",\"description\":\"The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.\",\"cve\":\"yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a\",\"severity\":\"Unknown\",\"solution\":\"Upgrade to latest versions.\",\"scanner\":{\"id\":\"gemnasium\",\"name\":\"Gemnasium\"},\"location\":{\"file\":\"yarn.lock\",\"dependency\":{\"package\":{\"name\":\"debug\"},\"version\":\"1.0.5\"}},\"identifiers\":[{\"type\":\"gemnasium\",\"name\":\"Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a\",\"value\":\"37283ed4-0380-40d7-ada7-2d994afcc62a\",\"url\":\"https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories\"}],\"links\":[{\"url\":\"https://nodesecurity.io/advisories/534\"},{\"url\":\"https://github.com/visionmedia/debug/issues/501\"},{\"url\":\"https://github.com/visionmedia/debug/pull/504\"}],\"remediations\":[null]}",
        "report_type": "dependency_scanning",
        "scanner_id": 63,
        "severity": "low",
        "updated_at": "2020-04-07T14:01:04.664Z",
        "uuid": "f1d528ae-d0cc-47f6-a72f-936cec846ae7",
        "vulnerability_id": 103
    },
    "id": 103,
    "project": {
        "created_at": "2020-04-07T13:54:25.634Z",
        "description": "",
        "id": 24,
        "name": "security-reports",
        "name_with_namespace": "gitlab-org / security-reports",
        "path": "security-reports",
        "path_with_namespace": "gitlab-org/security-reports"
    },
    "project_default_branch": "main",
    "report_type": "dependency_scanning",
    "resolved_at": null,
    "resolved_by_id": null,
    "resolved_on_default_branch": false,
    "severity": "low",
    "state": "detected",
    "title": "Regular Expression Denial of Service in debug",
    "updated_at": "2020-04-07T14:01:04.655Z"
}
```

### 오류 {#errors}

이 오류는 취약성을 생성하도록 선택한 찾기가 없거나 이미 다른 취약성과 연결된 경우 발생합니다:

```plaintext
A Vulnerability Finding is not found or already attached to a different Vulnerability
```

상태 코드: `400`

응답 예시:

```json
{
  "message": {
    "base": [
      "finding is not found or is already attached to a vulnerability"
    ]
  }
}
```
