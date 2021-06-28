---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Project Vulnerabilities API **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10242) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6.

WARNING:
This API is in an alpha stage and considered unstable.
The response payload may be subject to change or breakage
across GitLab releases.

Every API call to vulnerabilities must be [authenticated](index.md#authentication).

Vulnerability permissions inherit permissions from their project. If a project is
private, and a user isn't a member of the project to which the vulnerability
belongs, requests to that project returns a `404 Not Found` status code.

## Vulnerabilities pagination

API results are paginated, and `GET` requests return 20 results at a time by default.

Read more on [pagination](index.md#pagination).

## List project vulnerabilities

List all of a project's vulnerabilities.

If an authenticated user does not have permission to
[use the Project Security Dashboard](../user/permissions.md#project-members-permissions),
`GET` requests for vulnerabilities of this project result in a `403` status code.

```plaintext
GET /projects/:id/vulnerabilities
```

| Attribute     | Type           | Required | Description                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                                                            |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/vulnerabilities"
```

Example response:

```json
[
    {
        "author_id": 1,
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.655Z",
        "description": null,
        "dismissed_at": null,
        "dismissed_by_id": null,
        "due_date": null,
        "finding": {
            "confidence": "medium",
            "created_at": "2020-04-07T14:01:04.630Z",
            "id": 103,
            "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
            "metadata_version": "2.0",
            "name": "Regular Expression Denial of Service in debug",
            "primary_identifier_id": 135,
            "project_fingerprint": "05e7cc9978ca495cf739a9f707ed34811e41c615",
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
        "last_edited_at": null,
        "last_edited_by_id": null,
        "project": {
            "created_at": "2020-04-07T13:54:25.634Z",
            "description": "",
            "id": 24,
            "name": "security-reports",
            "name_with_namespace": "gitlab-org / security-reports",
            "path": "security-reports",
            "path_with_namespace": "gitlab-org/security-reports"
        },
        "project_default_branch": "master",
        "report_type": "dependency_scanning",
        "resolved_at": null,
        "resolved_by_id": null,
        "resolved_on_default_branch": false,
        "severity": "low",
        "start_date": null,
        "state": "detected",
        "title": "Regular Expression Denial of Service in debug",
        "updated_at": "2020-04-07T14:01:04.655Z",
        "updated_by_id": null
    }
]
```

## New vulnerability

Creates a new vulnerability.

If an authenticated user does not have a permission to
[create a new vulnerability](../user/permissions.md#project-members-permissions),
this request results in a `403` status code.

```plaintext
POST /projects/:id/vulnerabilities?finding_id=<your_finding_id>
```

| Attribute           | Type              | Required   | Description                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer or string | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) which the authenticated user is a member of  |
| `finding_id`        | integer or string | yes        | The ID of a Vulnerability Finding to create the new Vulnerability from |

The other attributes of a newly created Vulnerability are populated from
its source Vulnerability Finding, or with these default values:

| Attribute    | Value                                                 |
|--------------|-------------------------------------------------------|
| `author`     | The authenticated user                                |
| `title`      | The `name` attribute of a Vulnerability Finding       |
| `state`      | `opened`                                              |
| `severity`   | The `severity` attribute of a Vulnerability Finding   |
| `confidence` | The `confidence` attribute of a Vulnerability Finding |

```shell
curl --header POST "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/vulnerabilities?finding_id=1"
```

Example response:

```json
{
    "author_id": 1,
    "confidence": "medium",
    "created_at": "2020-04-07T14:01:04.655Z",
    "description": null,
    "dismissed_at": null,
    "dismissed_by_id": null,
    "due_date": null,
    "finding": {
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.630Z",
        "id": 103,
        "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
        "metadata_version": "2.0",
        "name": "Regular Expression Denial of Service in debug",
        "primary_identifier_id": 135,
        "project_fingerprint": "05e7cc9978ca495cf739a9f707ed34811e41c615",
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
    "last_edited_at": null,
    "last_edited_by_id": null,
    "project": {
        "created_at": "2020-04-07T13:54:25.634Z",
        "description": "",
        "id": 24,
        "name": "security-reports",
        "name_with_namespace": "gitlab-org / security-reports",
        "path": "security-reports",
        "path_with_namespace": "gitlab-org/security-reports"
    },
    "project_default_branch": "master",
    "report_type": "dependency_scanning",
    "resolved_at": null,
    "resolved_by_id": null,
    "resolved_on_default_branch": false,
    "severity": "low",
    "start_date": null,
    "state": "detected",
    "title": "Regular Expression Denial of Service in debug",
    "updated_at": "2020-04-07T14:01:04.655Z",
    "updated_by_id": null
}
```

### Errors

This error occurs when a Finding chosen to create a Vulnerability from is not found, or
is already associated with a different Vulnerability:

```plaintext
A Vulnerability Finding is not found or already attached to a different Vulnerability
```

Status code: `400`

Example response:

```json
{
  "message": {
    "base": [
      "finding is not found or is already attached to a vulnerability"
    ]
  }
}
```
