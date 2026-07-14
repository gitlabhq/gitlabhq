---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리소스 그룹 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [리소스 그룹](../ci/resource_groups/_index.md)과 상호 작용합니다.

## 모든 리소스 그룹 나열 {#list-all-resource-groups}

지정된 프로젝트의 모든 리소스 그룹을 나열합니다.

```plaintext
GET /projects/:id/resource_groups
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id`      | 정수 또는 문자열     | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/resource_groups"
```

응답 예시

```json
[
  {
    "id": 3,
    "key": "production",
    "process_mode": "unordered",
    "created_at": "2021-09-01T08:04:59.650Z",
    "updated_at": "2021-09-01T08:04:59.650Z"
  }
]
```

## 리소스 그룹 검색 {#retrieve-a-resource-group}

프로젝트에서 지정된 리소스 그룹을 검색합니다.

```plaintext
GET /projects/:id/resource_groups/:key
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id`      | 정수 또는 문자열     | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key`     | 문자열  | 예      | 리소스 그룹의 URL 인코딩 키입니다. 예를 들어 `resource%5Fa` 대신 `resource_a`를 사용합니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

응답 예시

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "unordered",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:04:59.650Z"
}
```

## 리소스 그룹의 현재 작업 검색 {#retrieve-current-job-for-a-resource-group}

{{< history >}}

- GitLab 18.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/572135)

{{< /history >}}

프로젝트에서 지정된 리소스 그룹의 현재 작업을 검색합니다.

```plaintext
GET /projects/:id/resource_groups/:key/current_job
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id`      | 정수 또는 문자열     | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key`     | 문자열  | 예      | 리소스 그룹의 URL 인코딩 키입니다. 예를 들어 `resource%5Fa` 대신 `resource_a`를 사용합니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/50/resource_groups/production/current_job"
```

응답 예시

```json
{
  "id": 1154,
  "status": "waiting_for_resource",
  "stage": "deploy",
  "name": "deploy_to_production",
  "ref": "main",
  "tag": false,
  "coverage": null,
  "allow_failure": false,
  "created_at": "2022-09-28T09:57:04.590Z",
  "started_at": null,
  "finished_at": null,
  "duration": null,
  "queued_duration": null,
  "user": {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/2d691a4d0427ca8db6efc3924a6408ba?s=80\u0026d=identicon",
    "web_url": "http://gitlab.example.com/john_smith",
    "created_at": "2022-05-27T19:19:17.526Z",
    "bio": "",
    "location": null,
    "public_email": null,
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null
  },
  "commit": {
    "id": "3177f39064891bbbf5124b27850c339da331f02f",
    "short_id": "3177f390",
    "created_at": "2022-09-27T17:55:31.000+02:00",
    "parent_ids": [
      "18059e45a16eaaeaddf6fc0daf061481549a89df"
    ],
    "title": "List upcoming jobs",
    "message": "List upcoming jobs",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2022-09-27T17:55:31.000+02:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2022-09-27T17:55:31.000+02:00",
    "trailers": {},
    "web_url": "https://gitlab.example.com/test/gitlab/-/commit/3177f39064891bbbf5124b27850c339da331f02f"
  },
  "pipeline": {
    "id": 274,
    "iid": 9,
    "project_id": 50,
    "sha": "3177f39064891bbbf5124b27850c339da331f02f",
    "ref": "main",
    "status": "waiting_for_resource",
    "source": "web",
    "created_at": "2022-09-28T09:57:04.538Z",
    "updated_at": "2022-09-28T09:57:13.537Z",
    "web_url": "https://gitlab.example.com/test/gitlab/-/pipelines/274"
  },
  "web_url": "https://gitlab.example.com/test/gitlab/-/jobs/1154",
  "project": {
    "ci_job_token_scope_enabled": false
  }
}
```

## 특정 리소스 그룹의 예정된 작업 나열 {#list-upcoming-jobs-for-a-specific-resource-group}

```plaintext
GET /projects/:id/resource_groups/:key/upcoming_jobs
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id`      | 정수 또는 문자열     | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key`     | 문자열  | 예      | 리소스 그룹의 URL 인코딩 키입니다. 예를 들어 `resource%5Fa` 대신 `resource_a`를 사용합니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/50/resource_groups/production/upcoming_jobs"
```

응답 예시

```json
[
  {
    "id": 1154,
    "status": "waiting_for_resource",
    "stage": "deploy",
    "name": "deploy_to_production",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "allow_failure": false,
    "created_at": "2022-09-28T09:57:04.590Z",
    "started_at": null,
    "finished_at": null,
    "duration": null,
    "queued_duration": null,
    "user": {
      "id": 1,
      "username": "john_smith",
      "name": "John Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/2d691a4d0427ca8db6efc3924a6408ba?s=80\u0026d=identicon",
      "web_url": "http://gitlab.example.com/john_smith",
      "created_at": "2022-05-27T19:19:17.526Z",
      "bio": "",
      "location": null,
      "public_email": null,
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": null,
      "job_title": "",
      "pronouns": null,
      "bot": false,
      "work_information": null,
      "followers": 0,
      "following": 0,
      "local_time": null
    },
    "commit": {
      "id": "3177f39064891bbbf5124b27850c339da331f02f",
      "short_id": "3177f390",
      "created_at": "2022-09-27T17:55:31.000+02:00",
      "parent_ids": [
        "18059e45a16eaaeaddf6fc0daf061481549a89df"
      ],
      "title": "List upcoming jobs",
      "message": "List upcoming jobs",
      "author_name": "Example User",
      "author_email": "user@example.com",
      "authored_date": "2022-09-27T17:55:31.000+02:00",
      "committer_name": "Example User",
      "committer_email": "user@example.com",
      "committed_date": "2022-09-27T17:55:31.000+02:00",
      "trailers": {},
      "web_url": "https://gitlab.example.com/test/gitlab/-/commit/3177f39064891bbbf5124b27850c339da331f02f"
    },
    "pipeline": {
      "id": 274,
      "iid": 9,
      "project_id": 50,
      "sha": "3177f39064891bbbf5124b27850c339da331f02f",
      "ref": "main",
      "status": "waiting_for_resource",
      "source": "web",
      "created_at": "2022-09-28T09:57:04.538Z",
      "updated_at": "2022-09-28T09:57:13.537Z",
      "web_url": "https://gitlab.example.com/test/gitlab/-/pipelines/274"
    },
    "web_url": "https://gitlab.example.com/test/gitlab/-/jobs/1154",
    "project": {
      "ci_job_token_scope_enabled": false
    }
  }
]
```

## 리소스 그룹 업데이트 {#update-a-resource-group}

기존 리소스 그룹의 속성을 업데이트합니다.

리소스 그룹이 성공적으로 업데이트되면 `200`을 반환합니다. 오류가 발생하면 상태 코드 `400`이 반환됩니다.

```plaintext
PUT /projects/:id/resource_groups/:key
```

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key`          | 문자열            | 예      | 리소스 그룹의 URL 인코딩 키입니다. 예를 들어 `resource%5Fa` 대신 `resource_a`를 사용합니다. |
| `process_mode` | 문자열            | 아니요       | 리소스 그룹의 프로세스 모드입니다. `unordered`, `oldest_first`, `newest_first` 또는 `newest_ready_first` 중 하나입니다. [프로세스 모드](../ci/resource_groups/_index.md#process-modes)에 대한 자세한 정보를 읽으세요. |

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "process_mode=oldest_first" \
     --url "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

응답 예시:

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "oldest_first",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:13:38.679Z"
}
```
