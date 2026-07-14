---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "CI/CD 작업 세부 정보를 검색하고, 작업을 재시도 및 취소하며, 수동 작업을 실행하고, 작업 로그에 액세스할 수 있는 REST API입니다."
title: 작업 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [CI/CD 작업](../ci/jobs/_index.md)과 상호작용합니다.

## 프로젝트의 모든 작업 나열 {#list-all-jobs-for-a-project}

지정된 프로젝트의 모든 작업을 나열합니다.

기본적으로 이 요청은 API 결과가 [페이지별로 표시되기](rest/_index.md#pagination) 때문에 한 번에 20개의 결과를 반환합니다.

> [!note]
> 이 엔드포인트는 오프셋 기반 및 [키셋 기반](rest/_index.md#keyset-based-pagination) 페이지 매김을 모두 지원하지만, 연속된 결과 페이지를 요청할 때는 키셋 기반 페이지 매김을 강력히 권장합니다.

```plaintext
GET /projects/:id/jobs
```

| 속성  | 유형                           | 필수 | 설명 |
| ---------- | ------------------------------ | -------- | ----------- |
| `id`       | 정수 또는 문자열                 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `scope`    | 문자열 또는 문자열 배열 | 아니요       | 표시할 작업의 범위입니다. 작업 상태 값 중 하나 또는 배열로 [작업 상태 값](#job-status-values)을 지정합니다. `scope`가 제공되지 않으면 모든 작업이 반환됩니다. |
| `order_by` | 문자열                         | 아니요       | `id`로 순서가 지정된 작업을 반환합니다. |
| `sort`     | 문자열                         | 아니요       | `asc` 또는 `desc` 순서로 정렬된 작업을 반환합니다. 기본값은 `desc`입니다. |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs?scope[]=pending&scope[]=running"
```

응답 예시:

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "erased_at": null,
    "duration": 0.173,
    "queued_duration": 0.010,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "runner": {
      "id": 32,
      "description": "",
      "ip_address": null,
      "active": true,
      "paused": false,
      "is_shared": true,
      "runner_type": "instance_type",
      "name": null,
      "online": false,
      "status": "offline"
    },
    "runner_manager": {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-05-01T10:12:02.507Z",
      "contacted_at": "2024-05-07T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline"
    },
    "stage": "test",
    "status": "failed",
    "failure_reason": "script_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  },
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "erased_at": null,
    "duration": 0.192,
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "win10-2004"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "artifacts": [],
    "runner": null,
    "runner_manager": null,
    "stage": "test",
    "status": "failed",
    "failure_reason": "stuck_or_timeout_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  }
]
```

### 작업 상태 값 {#job-status-values}

작업 응답의 `status` 필드와 작업 필터링을 위한 `scope` 매개변수는 다음 값을 사용합니다:

- `canceled`:  작업이 수동으로 취소되었거나 자동으로 중단되었습니다.
- `canceling`:  작업이 취소 중이지만 `after_script`가 실행 중입니다.
- `created`:  작업이 생성되었지만 아직 처리되지 않았습니다.
- `failed`:  작업 실행이 실패했습니다.
- `manual`:  작업은 시작하기 위해 수동 조치가 필요합니다.
- `pending`:  작업이 러너를 기다리는 큐에 있습니다.
- `preparing`:  러너가 실행 환경을 준비 중입니다.
- `running`:  작업이 러너에서 실행 중입니다.
- `scheduled`:  작업이 예약되었지만 실행이 아직 시작되지 않았습니다.
- `skipped`:  작업이 조건 또는 종속성으로 인해 건너뛰어졌습니다.
- `success`:  작업이 성공적으로 완료되었습니다.
- `waiting_for_callback`:  작업이 외부 서비스의 콜백을 기다리고 있습니다.
- `waiting_for_resource`:  작업이 리소스가 사용 가능해질 때까지 기다리고 있습니다.

## 파이프라인별 모든 작업 나열 {#list-all-jobs-by-pipeline}

지정된 파이프라인의 모든 작업을 나열합니다.

기본적으로 이 요청은 API 결과가 [페이지별로 표시되기](rest/_index.md#pagination) 때문에 한 번에 20개의 결과를 반환합니다.

이 엔드포인트:

- [모든 파이프라인에 대한 데이터를 반환](pipelines.md#retrieve-a-single-pipeline) 하며 [하위 파이프라인](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)을 포함합니다.
- 기본적으로 응답에서 재시도된 작업을 반환하지 않습니다.
- 작업을 ID별로 내림차순(최신순)으로 정렬합니다.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/jobs
```

| 속성         | 유형                           | 필수 | 설명 |
| ----------------- | ------------------------------ | -------- | ----------- |
| `id`              | 정수 또는 문자열                 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_id`     | 정수                        | 예      | 파이프라인의 ID입니다. CI/CD 작업에서 [사전 정의된 CI 변수](../ci/variables/predefined_variables.md) `CI_PIPELINE_ID`를 사용하여 얻을 수도 있습니다. |
| `include_retried` | 부울                        | 아니요       | 응답에 재시도된 작업을 포함합니다. `false`로 기본값이 설정됩니다. |
| `scope`           | 문자열 **또는** 문자열 배열 | 아니요       | 표시할 작업의 범위입니다. 작업 상태 값 중 하나 또는 배열로 [작업 상태 값](#job-status-values)을 지정합니다. `scope`가 제공되지 않으면 모든 작업이 반환됩니다. |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/6/jobs?scope[]=pending&scope[]=running"
```

응답 예시:

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "erased_at": null,
    "duration": 0.192,
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "artifacts": [],
    "runner": {
      "id": 32,
      "description": "",
      "ip_address": null,
      "active": true,
      "paused": false,
      "is_shared": true,
      "runner_type": "instance_type",
      "name": null,
      "online": false,
      "status": "offline"
    },
    "runner_manager": {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-05-01T10:12:02.507Z",
      "contacted_at": "2024-05-07T06:30:09.355Z",
      "ip_address": "127.0.0.1",
    },
    "stage": "test",
    "status": "failed",
    "failure_reason": "stuck_or_timeout_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  },
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "erased_at": null,
    "duration": 0.173,
    "queued_duration": 0.023,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "runner": null,
    "runner_manager": null,
    "stage": "test",
    "status": "failed",
    "failure_reason": "script_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  }
]
```

## 파이프라인별 모든 트리거 작업 나열 {#list-all-trigger-jobs-by-pipeline}

지정된 파이프라인의 모든 트리거 작업을 나열합니다.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/bridges
```

| 속성     | 유형                           | 필수 | 설명 |
| ------------- | ------------------------------ | -------- | ----------- |
| `id`          | 정수 또는 문자열                 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_id` | 정수                        | 예      | 파이프라인의 ID입니다. |
| `scope`       | 문자열 **또는** 문자열 배열 | 아니요       | 표시할 작업의 범위입니다. 작업 상태 값 중 하나 또는 배열로 [작업 상태 값](#job-status-values)을 지정합니다. `scope`가 제공되지 않으면 모든 작업이 반환됩니다. |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/6/bridges?scope[]=pending&scope[]=running"
```

응답 예시:

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:58:27.895Z",
    "erased_at": null,
    "duration": 240,
    "queued_duration": 0.123,
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending",
      "created_at": "2015-12-24T15:50:16.123Z",
      "updated_at": "2015-12-24T18:00:44.432Z",
      "web_url": "https://example.com/foo/bar/pipelines/6"
    },
    "ref": "main",
    "stage": "test",
    "status": "pending",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    },
    "downstream_pipeline": {
      "id": 5,
      "sha": "f62a4b2fb89754372a346f24659212eb8da13601",
      "ref": "main",
      "status": "pending",
      "created_at": "2015-12-24T17:54:27.722Z",
      "updated_at": "2015-12-24T17:58:27.896Z",
      "web_url": "https://example.com/diaspora/diaspora-client/pipelines/5"
    }
  }
]
```

## 작업 토큰으로 작업 검색 {#retrieve-a-job-by-job-token}

지정된 작업 토큰으로 생성된 작업을 검색합니다.

```plaintext
GET /job
```

예시([`script`](../ci/yaml/_index.md#script) 섹션의 [CI/CD 작업](../ci/jobs/_index.md)의 일부로 실행되어야 함):

```shell
# Option 1
curl --header "Authorization: Bearer $CI_JOB_TOKEN" \
  --url "${CI_API_V4_URL}/job"

# Option 2
curl --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "${CI_API_V4_URL}/job"

# Option 3
curl --url "${CI_API_V4_URL}/job?job_token=$CI_JOB_TOKEN"
```

응답 예시:

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2015-12-24T15:51:21.880Z",
  "started_at": "2015-12-24T17:54:30.733Z",
  "finished_at": "2015-12-24T17:54:31.198Z",
  "erased_at": null,
  "duration": 0.465,
  "queued_duration": 0.123,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "failed",
  "failure_reason": "script_failure",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/8",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.dev/root",
    "created_at": "2015-12-21T13:14:24.077Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": ""
  }
}
```

## `CI_JOB_TOKEN`Kubernetes용 GitLab 에이전트 검색 {#retrieve-gitlab-agent-for-kubernetes-by-ci_job_token}

`CI_JOB_TOKEN`을 생성한 작업을 검색하고, 허용된 [에이전트](../user/clusters/agent/_index.md) 목록을 표시합니다.

```plaintext
GET /job/allowed_agents
```

지원되는 속성:

| 속성      | 유형   | 필수 | 설명 |
|----------------|--------|----------|-------------|
| `CI_JOB_TOKEN` | 문자열 | 예      | GitLab에서 제공한 `CI_JOB_TOKEN` 변수와 연결된 토큰 값입니다. |

요청 예시:

```shell
# Option 1
curl --header "JOB-TOKEN: <CI_JOB_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/job/allowed_agents"

# Option 2
curl --url "https://gitlab.example.com/api/v4/job/allowed_agents?job_token=<CI_JOB_TOKEN>"
```

응답 예시:

```json
{
  "allowed_agents": [
    {
      "id": 1,
      "config_project": {
        "id": 1,
        "description": null,
        "name": "project1",
        "name_with_namespace": "John Doe2 / project1",
        "path": "project1",
        "path_with_namespace": "namespace1/project1",
        "created_at": "2022-11-16T14:51:50.579Z"
      }
    }
  ],
  "job": {
    "id": 1
  },
  "pipeline": {
    "id": 2
  },
  "project": {
    "id": 1,
    "groups": [
      {
        "id": 1
      },
      {
        "id": 2
      },
      {
        "id": 3
      }
    ]
  },
  "user": {
    "id": 2,
    "name": "John Doe3",
    "username": "user2",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/10fc7f102b",
    "web_url": "http://localhost/user2"
  }
}
```

## 작업 ID로 작업 검색 {#retrieve-a-job-by-job-id}

지정된 작업 ID를 사용하여 작업을 검색합니다.

```plaintext
GET /projects/:id/jobs/:job_id
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`  | 정수        | 예      | 작업의 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/8"
```

응답 예시:

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2015-12-24T15:51:21.880Z",
  "started_at": "2015-12-24T17:54:30.733Z",
  "finished_at": "2015-12-24T17:54:31.198Z",
  "erased_at": null,
  "duration": 0.465,
  "queued_duration": 0.010,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "tag_list": [
      "docker runner", "macos-10.15"
    ],
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/8",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.dev/root",
    "created_at": "2015-12-21T13:14:24.077Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": ""
  }
}
```

## 작업에 대한 로그 파일 검색 {#retrieve-a-log-file-for-a-job}

지정된 작업 ID에 대한 작업 로그(추적)를 검색합니다.

```plaintext
GET /projects/:id/jobs/:job_id/trace
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`  | 정수        | 예      | 작업의 ID입니다. |

```shell
curl --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/8/trace"
```

가능한 응답 상태 코드:

| 상태 | 설명 |
|--------|-------------|
| 200    | 로그 파일을 제공합니다. |
| 404    | 작업을 찾을 수 없거나 로그 파일이 없습니다. |

## 작업 취소 {#cancel-a-job}

프로젝트의 단일 작업을 취소합니다.

```plaintext
POST /projects/:id/jobs/:job_id/cancel
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`  | 정수        | 예      | 작업의 ID입니다. |
| `force`   | 부울        | 아니요       | [작업 취소 강제 실행](../ci/jobs/_index.md#force-cancel-a-job)(`canceling` 상태의 작업에 대해 `true`로 설정할 때). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/cancel"
```

응답 예시:

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:14:09.526Z",
  "finished_at": null,
  "erased_at": null,
  "duration": 8,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "canceled",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

## 작업 재시도 {#retry-a-job}

{{< history >}}

- `job_inputs` 특성은 GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17833)되었습니다.

{{< /history >}}

프로젝트의 단일 작업을 재시도합니다.

```plaintext
POST /projects/:id/jobs/:job_id/retry
```

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`     | 정수           | 예      | 작업의 ID입니다. |
| `job_inputs` | 해시              | 아니요       | 작업을 재시도할 때 사용할 [작업 입력](../ci/jobs/job_inputs.md) 값의 해시입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/retry"
```

응답 예시:

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "erased_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

> [!note]
> GitLab 17.0 이전에는 이 엔드포인트가 트리거 작업을 지원하지 않습니다.

## 작업 삭제 {#erase-a-job}

프로젝트의 단일 작업을 삭제합니다(작업 아티팩트와 작업 로그를 제거).

```plaintext
POST /projects/:id/jobs/:job_id/erase
```

매개변수

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`  | 정수        | 예      | 작업의 ID입니다. |

요청 예시

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/erase"
```

응답 예시:

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "download_url": null,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "erased_at": "2016-01-11T11:30:19.914Z",
  "duration": 97.0,
  "queued_duration": 0.010,
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

> [!note]
> API를 사용하여 보관된 작업을 삭제할 수는 없지만, [특정 날짜 이전에 완료된 작업의 작업 아티팩트와 로그를 삭제](../administration/cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts)할 수 있습니다.

## 작업 실행 {#run-a-job}

{{< history >}}

- `job_inputs` 특성은 GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17833)되었습니다.

{{< /history >}}

수동 상태의 작업에 대해 작업을 시작할 작업을 트리거합니다.

```plaintext
POST /projects/:id/jobs/:job_id/play
```

| 속성                  | 유형              | 필수 | 설명 |
|----------------------------|-------------------|----------|-------------|
| `id`                       | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`                   | 정수           | 예      | 작업의 ID입니다. |
| `job_inputs`               | 해시              | 아니요       | 작업을 실행할 때 사용할 [작업 입력](../ci/jobs/job_inputs.md) 값의 해시입니다. |
| `job_variables_attributes` | 해시 배열   | 아니요       | 작업에서 사용 가능한 사용자 지정 변수를 포함하는 배열입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data @variables.json \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/play"
```

`@variables.json`의 구조는 다음과 같습니다:

```json
{
  "job_variables_attributes": [
    {
      "key": "TEST_VAR_1",
      "value": "test1"
    },
    {
      "key": "TEST_VAR_2",
      "value": "test2"
    }
  ]
}
```

응답 예시:

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "erased_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```
