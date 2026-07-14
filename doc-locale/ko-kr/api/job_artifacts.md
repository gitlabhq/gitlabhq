---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 아티팩트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [작업 아티팩트](../ci/jobs/job_artifacts.md)를 다운로드, 유지 및 삭제합니다.

## 작업 ID로 작업 아티팩트 다운로드 {#download-job-artifacts-by-job-id}

작업 ID를 사용하여 작업의 아티팩트 아카이브를 다운로드합니다.

GitLab.com에서 cURL을 사용하여 아티팩트를 다운로드하는 경우 `--location` 매개변수를 사용하세요. 요청이 CDN을 통해 리디렉션될 수 있습니다.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`    | 정수           | 예      | 작업의 ID입니다. |
| `job_token` | 문자열            | 아니요       | 다중 프로젝트 파이프라인용 CI/CD 작업 토큰입니다. Premium 및 Ultimate만 해당합니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)을 반환하고 아티팩트 파일을 제공합니다.

요청 예시:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts" \
  --output artifacts.zip
```

CI/CD 작업 토큰을 사용한 요청 예:

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --request GET \
         --location \
         --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN" \
         --output artifacts.zip'
```

## 참조 이름으로 작업 아티팩트 다운로드 {#download-job-artifacts-by-reference-name}

{{< history >}}

- `search_recent_successful_pipelines` 속성이 GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/515864) 되었으며 [플래그](../administration/feature_flags/_index.md) `ci_search_recent_successful_pipelines`를 사용합니다. 기본적으로 비활성화됨.
- 기능 플래그 `ci_search_recent_successful_pipelines`이 GitLab 18.10에서 제거되었습니다.

{{< /history >}}

참조 이름을 사용하여 최신 성공한 파이프라인에서 작업의 아티팩트 아카이브를 다운로드합니다. `search_recent_successful_pipelines=true`일 때 검색에는 지정된 참조의 최대 100개의 최근 성공한 파이프라인이 포함됩니다.

최신 성공한 파이프라인은 생성 시간을 기준으로 결정됩니다. 개별 작업의 시작 또는 종료 시간은 어떤 파이프라인이 최신인지에 영향을 주지 않습니다.

[상위 및 하위 파이프라인](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)의 경우 아티팩트는 상위에서 하위로의 계층 순서로 검색됩니다. 상위 및 하위 파이프라인 모두 같은 이름의 작업을 가진 경우 상위 파이프라인의 아티팩트가 반환됩니다.

전제 조건:

- 완료된 파이프라인이 `success` 상태여야 합니다.
- 파이프라인에 수동 작업이 포함된 경우 다음 중 하나여야 합니다:
  - 성공적으로 완료합니다.
  - `allow_failure: true`이 설정되어 있습니다.

GitLab.com에서 cURL을 사용하여 아티팩트를 다운로드하는 경우 `--location` 매개변수를 사용하세요. 요청이 CDN을 통해 리디렉션될 수 있습니다.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job`       | 문자열            | 예      | 작업의 이름입니다. |
| `ref_name`  | 문자열            | 예      | 리포지토리의 브랜치 또는 태그 이름입니다. HEAD 또는 SHA 참조는 지원되지 않습니다. 머지 리퀘스트 파이프라인의 경우 브랜치 이름 대신 `refs/merge-requests/:iid/head`을 사용하세요. |
| `job_token` | 문자열            | 아니요       | 다중 프로젝트 파이프라인용 CI/CD 작업 토큰입니다. Premium 및 Ultimate만 해당합니다. |
| `search_recent_successful_pipelines` | 부울 | 아니요 | 최신 파이프라인만이 아닌 최근 성공한 파이프라인을 검색합니다. `false`로 기본값이 설정됩니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)을 반환하고 아티팩트 파일을 제공합니다.

작업 또는 아티팩트를 찾을 수 없으면 [`404`](rest/troubleshooting.md#status-codes)을 반환합니다.

요청 예시:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test"
```

CI/CD 작업 토큰을 사용한 요청 예:

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --request GET \
         --location \
         --url "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN" \
         --output artifacts.zip'
```

최근 파이프라인 검색을 사용한 요청 예:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&search_recent_successful_pipelines=true"
```

## 작업 ID로 단일 아티팩트 파일 다운로드 {#download-a-single-artifact-file-by-job-id}

작업 ID를 사용하여 작업의 아티팩트에서 단일 파일을 다운로드합니다. 파일이 아카이브에서 추출되어 클라이언트로 스트리밍됩니다.

GitLab.com에서 cURL을 사용하여 아티팩트를 다운로드하는 경우 `--location` 매개변수를 사용하세요. 요청이 CDN을 통해 리디렉션될 수 있습니다.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

지원되는 속성:

| 속성       | 유형              | 필수 | 설명 |
| --------------- | ----------------- | -------- | ----------- |
| `artifact_path` | 문자열            | 예      | 아티팩트 아카이브 내의 파일 경로입니다. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`        | 정수           | 예      | 고유한 작업 식별자입니다. |
| `job_token`     | 문자열            | 아니요       | 다중 프로젝트 파이프라인용 CI/CD 작업 토큰입니다. Premium 및 Ultimate만 해당합니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)을 반환하고 단일 아티팩트 파일을 전송합니다.

요청 예시:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

## 아티팩트 아카이브의 모든 파일 나열 {#list-all-files-in-the-artifacts-archive}

{{< history >}}

- GitLab 18.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/31448)되었습니다.

{{< /history >}}

지정된 작업의 아티팩트 아카이브에서 모든 파일과 디렉터리를 나열합니다. 이 작업은 전체 아카이브를 추출하지 않고 아티팩트 메타데이터를 읽으므로 큰 아카이브를 탐색할 때 효율적입니다.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/tree
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`    | 정수           | 예      | 작업의 ID입니다. |
| `path`      | 문자열            | 아니요       | 아티팩트 아카이브에서 찾아볼 경로입니다. 루트 디렉터리를 기본값으로 설정합니다. |
| `recursive` | 부울           | 아니요       | `true`일 때 모든 항목을 재귀적으로 반환합니다. 기본값: `false`. |
| `job_token` | 문자열            | 아니요       | 다중 프로젝트 파이프라인을 트리거하는 데 사용되는 CI/CD 작업 토큰입니다. Premium 및 Ultimate만 해당합니다. |

이 엔드포인트는 [페이지 매김](rest/_index.md#pagination)을 지원합니다.

성공하면 [`200`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 반환합니다:

| 속성 | 유형    | 설명 |
|-----------|---------|-------------|
| `name`    | 문자열  | 파일 또는 디렉터리 이름입니다. |
| `path`    | 문자열  | 아티팩트 아카이브의 전체 경로입니다. 디렉터리에는 후행 슬래시가 포함됩니다. |
| `type`    | 문자열  | 항목의 유형입니다. 가능한 값: `file`, `directory`. |
| `size`    | 정수 | 바이트 단위의 파일 크기입니다. 파일에만 표시됩니다. |
| `mode`    | 문자열  | 8진수 형식의 Unix 파일 모드입니다. 예를 들어 파일의 경우 `100644`, 디렉터리의 경우 `040755`입니다. |

작업, 아티팩트, 아티팩트 메타데이터 또는 지정된 경로를 찾을 수 없으면 [`404`](rest/troubleshooting.md#status-codes)을 반환합니다.

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree"
```

응답 예시:

```json
[
  {
    "name": "ci_build_artifacts.zip",
    "path": "ci_build_artifacts.zip",
    "type": "file",
    "size": 1024,
    "mode": "100644"
  },
  {
    "name": "other_artifacts_0.1.2",
    "path": "other_artifacts_0.1.2/",
    "type": "directory",
    "mode": "040755"
  }
]
```

하위 디렉터리를 찾아보기 위한 요청 예:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?path=coverage/reports"
```

재귀 나열을 위한 요청 예:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?recursive=true"
```

CI/CD 작업 토큰을 사용한 요청 예:

```yaml
# Uses the job_token parameter
list_artifacts:
  stage: test
  script:
    - 'curl --request GET \
         --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?job_token=$CI_JOB_TOKEN"'
```

## 참조 이름으로 단일 아티팩트 파일 다운로드 {#download-a-single-artifact-file-by-reference-name}

{{< history >}}

- `search_recent_successful_pipelines` 속성이 GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/515864) 되었으며 [플래그](../administration/feature_flags/_index.md) `ci_search_recent_successful_pipelines`를 사용합니다. 기본적으로 비활성화됨.
- 기능 플래그 `ci_search_recent_successful_pipelines`이 GitLab 18.10에서 제거되었습니다.

{{< /history >}}

참조 이름을 사용하여 최신 성공한 파이프라인에서 작업의 아티팩트의 단일 파일을 다운로드합니다. 파일이 아카이브에서 추출되어 `plain/text` 콘텐츠 유형으로 클라이언트에 스트리밍됩니다. `search_recent_successful_pipelines=true`일 때 검색에는 지정된 참조의 최대 100개의 최근 성공한 파이프라인이 포함됩니다.

[상위 및 하위 파이프라인](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)의 경우 아티팩트는 상위에서 하위로의 계층 순서로 검색됩니다. 상위 및 하위 파이프라인 모두 같은 이름의 작업을 가진 경우 상위 파이프라인의 아티팩트가 반환됩니다.

아티팩트 파일은 [CSV 내보내기](../user/application_security/vulnerability_report/_index.md#exporting)에서 사용 가능한 것보다 더 자세한 정보를 제공합니다.

전제 조건:

- 완료된 파이프라인이 `success` 상태여야 합니다.
- 파이프라인에 수동 작업이 포함된 경우 다음 중 하나여야 합니다:
  - 성공적으로 완료합니다.
  - `allow_failure: true`이 설정되어 있습니다.
- 최근 성공한 파이프라인을 검색하려면 `ci_search_recent_successful_pipelines` 기능 플래그가 프로젝트에서 활성화되어야 합니다.

GitLab.com에서 cURL을 사용하여 아티팩트를 다운로드하는 경우 `--location` 매개변수를 사용하세요. 요청이 CDN을 통해 리디렉션될 수 있습니다.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

지원되는 속성:

| 속성       | 유형              | 필수 | 설명 |
| --------------- | ----------------- | -------- | ----------- |
| `artifact_path` | 문자열            | 예      | 아티팩트 아카이브 내의 파일 경로입니다. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job`           | 문자열            | 예      | 작업의 이름입니다. |
| `ref_name`      | 문자열            | 예      | 리포지토리의 브랜치 또는 태그 이름입니다. `HEAD` 또는 `SHA` 참조는 지원되지 않습니다. 머지 리퀘스트 파이프라인의 경우 브랜치 이름 대신 `refs/merge-requests/:iid/head`을 사용하세요. |
| `job_token`     | 문자열            | 아니요       | 다중 프로젝트 파이프라인용 CI/CD 작업 토큰입니다. Premium 및 Ultimate만 해당합니다. |
| `search_recent_successful_pipelines` | 부울 | 아니요 | 최신 파이프라인만이 아닌 최근 성공한 파이프라인을 검색합니다. `false`로 기본값이 설정됩니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)을 반환하고 단일 아티팩트 파일을 전송합니다.

작업 또는 아티팩트 파일을 찾을 수 없으면 [`404`](rest/troubleshooting.md#status-codes)을 반환합니다.

요청 예시:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf"
```

최근 파이프라인 검색을 사용한 요청 예:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf&search_recent_successful_pipelines=true"
```

## 작업 아티팩트 유지 {#keep-job-artifacts}

작업의 아티팩트가 만료 날짜에 도달할 때 자동으로 삭제되는 것을 방지합니다.

```plaintext
POST /projects/:id/jobs/:job_id/artifacts/keep
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`  | 정수           | 예      | 작업의 ID입니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)을 반환하고 작업 세부 정보를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts/keep"
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
  "allow_failure": false,
  "download_url": null,
  "id": 42,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "duration": 97.0,
  "status": "failed",
  "failure_reason": "script_failure",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## 작업 아티팩트 삭제 {#delete-job-artifacts}

특정 작업과 관련된 모든 아티팩트를 삭제합니다. 아티팩트는 삭제된 후 복구할 수 없습니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
DELETE /projects/:id/jobs/:job_id/artifacts
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `job_id`  | 정수           | 예      | 작업의 ID입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)을 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts"
```

## 프로젝트의 모든 작업 아티팩트 삭제 {#delete-all-job-artifacts-in-a-project}

프로젝트에서 삭제할 수 있는 모든 작업 아티팩트를 삭제합니다. 아티팩트는 삭제된 후 복구할 수 없습니다.

기본적으로 [각 참조의 가장 최근 성공한 파이프라인](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)의 아티팩트는 삭제되지 않습니다.

이 엔드포인트에 대한 요청은 삭제할 수 있는 모든 작업 아티팩트의 만료를 현재 시간으로 설정합니다. 그러면 파일이 만료된 작업 아티팩트의 정기 정리의 일부로 시스템에서 삭제됩니다. 작업 로그는 절대 삭제되지 않습니다.

정기 정리는 일정에 따라 비동기적으로 발생하므로 아티팩트가 삭제되기 전에 약간의 지연이 있을 수 있습니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
DELETE /projects/:id/artifacts
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`202 Accepted`](rest/troubleshooting.md#status-codes)을 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/artifacts"
```

## 문제 해결 {#troubleshooting}

### 머지 리퀘스트 파이프라인에서 브랜치 이름 사용 {#using-branch-names-with-merge-request-pipelines}

`ref_name`로 작업 아티팩트를 다운로드하려고 할 때 `404 Not Found` 오류가 발생할 수 있습니다.

이 문제는 머지 리퀘스트 파이프라인이 브랜치 파이프라인보다 다른 참조 형식을 사용하기 때문에 발생합니다. 머지 리퀘스트 파이프라인은 `refs/merge-requests/:iid/head`에서 실행되며 소스 브랜치에서 직접 실행되지 않습니다.

머지 리퀘스트 파이프라인에 대한 작업 아티팩트를 다운로드하려면 브랜치 이름 대신 `ref_name`로 `refs/merge-requests/:iid/head`을 사용하세요. 여기서 `:iid`은 머지 리퀘스트 ID입니다. 머지 리퀘스트 파이프라인에서 ID는 변수 `$CI_MERGE_REQUEST_IID`에서 사용 가능하고 전체 `ref_name`는 변수 `$CI_MERGE_REQUEST_REF_PATH`에서 사용 가능합니다.

예를 들어 머지 리퀘스트 `!123`의 경우:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/refs/merge-requests/123/head/raw/file.txt?job=test"
```

### `artifacts:reports` 파일 다운로드 {#downloading-artifactsreports-files}

작업 아티팩트 API를 사용하여 보고서를 다운로드하려고 할 때 `404 Not Found` 오류가 발생할 수 있습니다.

이 문제는 [보고서](../ci/yaml/_index.md#artifactsreports)가 기본적으로 다운로드 가능하지 않기 때문에 발생합니다.

보고서를 다운로드 가능하게 하려면 파일 이름 또는 `gl-*-report.json`을 [`artifacts:paths`](../ci/yaml/_index.md#artifactspaths)에 추가하세요.
