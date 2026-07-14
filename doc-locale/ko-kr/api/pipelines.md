---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "REST API를 사용하여 CI/CD 파이프라인을 생성, 관리 및 모니터링합니다."
title: 파이프라인 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [CI/CD 파이프라인](../ci/pipelines/_index.md)과 상호작용합니다.

## 프로젝트 파이프라인 목록 {#list-project-pipelines}

{{< history >}}

- `name` 응답에서 GitLab 15.11에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) 되었으며 [플래그](../administration/feature_flags/_index.md)인 `pipeline_name_in_api`와 함께 제공됩니다. 기본적으로 비활성화됨.
- `name` 요청에서 15.11에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) 되었으며 [플래그](../administration/feature_flags/_index.md)인 `pipeline_name_search`와 함께 제공됩니다. 기본적으로 비활성화됨.
- `name` 응답이 GitLab 16.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)되었습니다. 기능 플래그 `pipeline_name_in_api` 제거됨.
- `name` 요청이 GitLab 16.9에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/385864)되었습니다. 기능 플래그 `pipeline_name_search` 제거됨.
- `source`을 `parent_pipeline`로 설정하는 자식 파이프라인 반환 지원이 GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)되었습니다.

{{< /history >}}

프로젝트의 파이프라인을 나열합니다.

기본적으로 [자식 파이프라인](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)은 결과에 포함되지 않습니다. 자식 파이프라인을 반환하려면 `source`를 `parent_pipeline`로 설정합니다.

```plaintext
GET /projects/:id/pipelines
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`           | 문자열            | 아니요       | 지정된 이름을 가진 파이프라인을 반환합니다. |
| `order_by`       | 문자열            | 아니요       | 파이프라인을 정렬할 필드: `id`, `status`, `ref`, `updated_at` 또는 `user_id` (기본값: `id`). |
| `ref`            | 문자열            | 아니요       | 지정된 브랜치 또는 태그에 대한 파이프라인을 반환합니다. |
| `scope`          | 문자열            | 아니요       | 지정된 범위의 파이프라인을 반환합니다: `running`, `pending`, `finished`, `branches` 또는 `tags`. |
| `sha`            | 문자열            | 아니요       | 지정된 커밋 SHA에 대한 파이프라인을 반환합니다. |
| `sort`           | 문자열            | 아니요       | 정렬 순서: `asc` 또는 `desc` (기본값: `desc`). |
| `source`         | 문자열            | 아니요       | 지정된 [소스](../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable)를 가진 파이프라인을 반환합니다. |
| `status`         | 문자열            | 아니요       | 지정된 상태를 가진 파이프라인을 반환합니다: `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual` 또는 `scheduled`. |
| `updated_after`  | 날짜/시간          | 아니요       | 지정된 날짜 이후에 업데이트된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `updated_before` | 날짜/시간          | 아니요       | 지정된 날짜 이전에 업데이트된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_after`  | 날짜/시간          | 아니요       | 지정된 날짜 이후에 생성된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before` | 날짜/시간          | 아니요       | 지정된 날짜 이전에 생성된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `username`       | 문자열            | 아니요       | 지정된 사용자명으로 트리거된 파이프라인을 반환합니다. |
| `yaml_errors`    | 부울           | 아니요       | 잘못된 구성을 가진 파이프라인을 반환합니다. |

`scope`을 `branches` 또는 `tags`로 설정하면 API는 각 브랜치 또는 태그 참조에 대한 최신 파이프라인만 반환합니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines"
```

응답 예시

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 1,
    "status": "pending",
    "source": "push",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 1,
    "status": "pending",
    "source": "web",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## 단일 파이프라인 검색 {#retrieve-a-single-pipeline}

{{< history >}}

- `name` 응답에서 GitLab 15.11에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) 되었으며 [플래그](../administration/feature_flags/_index.md)인 `pipeline_name_in_api`와 함께 제공됩니다. 기본적으로 비활성화됨.
- `name` 응답이 GitLab 16.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)되었습니다. 기능 플래그 `pipeline_name_in_api` 제거됨.

{{< /history >}}

프로젝트에서 단일 파이프라인을 검색합니다.

단일 [자식 파이프라인](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)도 검색할 수 있습니다.

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

응답 예시

```json
{
  "id": 287,
  "iid": 144,
  "project_id": 21,
  "name": "Build pipeline",
  "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
  "ref": "main",
  "status": "success",
  "source": "push",
  "created_at": "2022-09-21T01:05:07.200Z",
  "updated_at": "2022-09-21T01:05:50.185Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
  "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "username": "root",
    "name": "Administrator",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/root"
  },
  "started_at": "2022-09-21T01:05:14.197Z",
  "finished_at": "2022-09-21T01:05:50.175Z",
  "committed_at": null,
  "duration": 34,
  "queued_duration": 6,
  "coverage": null,
  "detailed_status": {
    "icon": "status_success",
    "text": "passed",
    "label": "passed",
    "group": "success",
    "tooltip": "passed",
    "has_details": false,
    "details_path": "/test-group/test-project/-/pipelines/287",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
  },
  "archived": false
}
```

## 최신 파이프라인 검색 {#retrieve-the-latest-pipeline}

{{< history >}}

- `name` 응답에서 GitLab 15.11에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) 되었으며 [플래그](../administration/feature_flags/_index.md)인 `pipeline_name_in_api`와 함께 제공됩니다. 기본적으로 비활성화됨.
- `name` 응답이 GitLab 16.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)되었습니다. 기능 플래그 `pipeline_name_in_api` 제거됨.

{{< /history >}}

프로젝트의 특정 참조에서 가장 최근 커밋의 최신 파이프라인을 검색합니다. 커밋에 대한 파이프라인이 없으면 `403` 상태 코드가 반환됩니다.

```plaintext
GET /projects/:id/pipelines/latest
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성 | 유형   | 필수 | 설명 |
|-----------|--------|----------|-------------|
| `ref`     | 문자열 | 아니요       | 최신 파이프라인을 확인할 브랜치 또는 태그입니다. 지정하지 않으면 기본 브랜치로 기본값이 설정됩니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/latest"
```

응답 예시

```json
{
    "id": 287,
    "iid": 144,
    "project_id": 21,
    "name": "Build pipeline",
    "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
    "ref": "main",
    "status": "success",
    "source": "push",
    "created_at": "2022-09-21T01:05:07.200Z",
    "updated_at": "2022-09-21T01:05:50.185Z",
    "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
    "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
    "tag": false,
    "yaml_errors": null,
    "user": {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/root"
    },
    "started_at": "2022-09-21T01:05:14.197Z",
    "finished_at": "2022-09-21T01:05:50.175Z",
    "committed_at": null,
    "duration": 34,
    "queued_duration": 6,
    "coverage": null,
    "detailed_status": {
        "icon": "status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "tooltip": "passed",
        "has_details": false,
        "details_path": "/test-group/test-project/-/pipelines/287",
        "illustration": null,
        "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
    },
    "archived": false
}
```

## 파이프라인 변수 검색 {#retrieve-pipeline-variables}

파이프라인의 [파이프라인 변수](../ci/variables/_index.md#use-pipeline-variables)를 검색합니다.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/variables"
```

응답 예시

```json
[
  {
    "key": "RUN_NIGHTLY_BUILD",
    "variable_type": "env_var",
    "value": "true"
  },
  {
    "key": "foo",
    "value": "bar"
  }
]
```

## 파이프라인에 대한 테스트 보고서 검색 {#retrieve-a-test-report-for-a-pipeline}

> [!note]
> 이 API 경로는 [단위 테스트 보고서](../ci/testing/unit_test_reports.md) 기능의 일부입니다.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

샘플 요청:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report"
```

응답 예시:

```json
{
  "total_time": 5,
  "total_count": 1,
  "success_count": 1,
  "failed_count": 0,
  "skipped_count": 0,
  "error_count": 0,
  "test_suites": [
    {
      "name": "Secure",
      "total_time": 5,
      "total_count": 1,
      "success_count": 1,
      "failed_count": 0,
      "skipped_count": 0,
      "error_count": 0,
      "test_cases": [
        {
          "status": "success",
          "name": "Security Reports can create an auto-remediation MR",
          "classname": "vulnerability_management_spec",
          "execution_time": 5,
          "system_output": null,
          "stack_trace": null
        }
      ]
    }
  ]
}
```

## 파이프라인에 대한 테스트 보고서 요약 검색 {#retrieve-a-test-report-summary-for-a-pipeline}

> [!note]
> 이 API 경로는 [단위 테스트 보고서](../ci/testing/unit_test_reports.md) 기능의 일부입니다.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report_summary
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

샘플 요청:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report_summary"
```

응답 예시:

```json
{
    "total": {
        "time": 1904,
        "count": 3363,
        "success": 3351,
        "failed": 0,
        "skipped": 12,
        "error": 0,
        "suite_error": null
    },
    "test_suites": [
        {
            "name": "test",
            "total_time": 1904,
            "total_count": 3363,
            "success_count": 3351,
            "failed_count": 0,
            "skipped_count": 12,
            "error_count": 0,
            "build_ids": [
                66004
            ],
            "suite_error": null
        }
    ]
}
```

## 새 파이프라인 생성 {#create-a-new-pipeline}

{{< history >}}

- `iid` 응답에 GitLab 14.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)되었습니다.
- `inputs` 속성이 GitLab 17.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/519958) 되었으며 [플래그](../administration/feature_flags/_index.md)인 `ci_inputs_for_pipelines`와 함께 제공됩니다. 기본적으로 활성화됨.
- `inputs` 특성이 GitLab 18.1에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/536548)되었습니다. 기능 플래그 `ci_inputs_for_pipelines` 제거됨.

{{< /history >}}

```plaintext
POST /projects/:id/pipeline
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `ref`       | 문자열         | 예      | 파이프라인을 실행할 브랜치 또는 태그입니다. 머지 리퀘스트 파이프라인의 경우 [머지 리퀘스트 엔드포인트](merge_requests.md#create-merge-request-pipeline)를 사용합니다. |
| `variables` | 배열          | 아니요       | [해시 배열](rest/_index.md#array-of-hashes)로 파이프라인에서 사용 가능한 변수를 포함하며 `[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }, {'key': 'TEST', 'value': 'test variable'}]` 구조와 일치합니다. `variable_type`가 제외되면 `env_var`로 기본값이 설정됩니다. |
| `inputs`    | 해시           | 아니요       | 파이프라인을 생성할 때 사용할 키-값 쌍으로 입력을 포함하는 [해시](rest/_index.md#hash)입니다. |

기본 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

[입력](../ci/inputs/_index.md)이 포함된 예시 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main" \
  --data '{"inputs": {"environment": "environment", "scan_security": false, "level": 3}}'
```

응답 예시

```json
{
  "id": 61,
  "iid": 21,
  "project_id": 1,
  "sha": "384c444e840a515b23f21915ee5766b87068a70d",
  "ref": "main",
  "status": "pending",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-11-04T09:36:13.747Z",
  "updated_at": "2016-11-04T09:36:13.977Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/61",
  "archived": false
}
```

## 파이프라인의 작업 재시도 {#retry-jobs-in-a-pipeline}

{{< history >}}

- `iid` 응답에 GitLab 14.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)되었습니다.

{{< /history >}}

파이프라인에서 실패하거나 취소된 작업을 재시도합니다. 파이프라인에 실패하거나 취소된 작업이 없으면 이 엔드포인트를 호출해도 효과가 없습니다.

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
```

응답:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "pending",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "archived": false
}
```

## 파이프라인의 모든 작업 취소 {#cancel-all-jobs-for-a-pipeline}

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

> [!note]
> 이 엔드포인트는 파이프라인의 상태와 관계없이 성공 응답 `200`을 반환합니다. 자세한 내용은 [이슈 414963](https://gitlab.com/gitlab-org/gitlab/-/issues/414963)을 참조하세요.

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
```

응답:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "canceled",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "archived": false
}
```

## 파이프라인 삭제 {#delete-a-pipeline}

파이프라인을 삭제하면 모든 파이프라인 캐시가 만료되고 빌드, 로그, 아티팩트 및 트리거와 같은 모든 직접 관련 객체가 삭제됩니다. **This action cannot be undone**.

파이프라인을 삭제해도 [자식 파이프라인](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)이 자동으로 삭제되지 않습니다. 자세한 내용은 [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)를 참조하세요.

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

## 파이프라인 메타데이터 업데이트 {#update-pipeline-metadata}

파이프라인 메타데이터를 업데이트합니다. 메타데이터에는 파이프라인의 이름이 포함됩니다.

```plaintext
PUT /projects/:id/pipelines/:pipeline_id/metadata
```

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `name`        | 문자열         | 예      | 파이프라인의 새로운 이름 |
| `pipeline_id` | 정수        | 예      | 파이프라인의 ID |

샘플 요청:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/metadata" \
  --data '{"name": "Some new pipeline name"}'
```

응답 예시:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "running",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "name": "Some new pipeline name",
  "archived": false
}
```
