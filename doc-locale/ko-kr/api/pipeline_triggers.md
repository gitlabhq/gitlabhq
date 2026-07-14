---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 트리거 토큰 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [파이프라인을 트리거](../ci/triggers/_index.md)합니다.

## 프로젝트 트리거 토큰 나열 {#list-project-trigger-tokens}

프로젝트의 파이프라인 트리거 토큰을 나열합니다.

```plaintext
GET /projects/:id/triggers
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
[
    {
        "id": 10,
        "description": "my trigger",
        "created_at": "2016-01-07T09:53:58.235Z",
        "last_used": null,
        "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
        "updated_at": "2016-01-07T09:53:58.235Z",
        "owner": null
    }
]
```

인증된 사용자가 생성한 트리거 토큰이면 전체 트리거 토큰이 표시됩니다. 다른 사용자가 생성한 트리거 토큰은 4자로 단축됩니다.

## 트리거 토큰 세부 정보 검색 {#retrieve-trigger-token-details}

프로젝트의 파이프라인 트리거 토큰 세부 정보를 검색합니다.

```plaintext
GET /projects/:id/triggers/:trigger_id
```

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `trigger_id` | 정수        | 예      | 트리거 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## 트리거 토큰 생성 {#create-a-trigger-token}

프로젝트의 파이프라인 트리거 토큰을 생성합니다.

```plaintext
POST /projects/:id/triggers
```

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `description` | 문자열         | 예      | 트리거 이름 |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form description="my description" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## 파이프라인 트리거 토큰 업데이트 {#update-a-pipeline-trigger-token}

프로젝트의 파이프라인 트리거 토큰을 업데이트합니다.

```plaintext
PUT /projects/:id/triggers/:trigger_id
```

| 속성     | 유형           | 필수 | 설명 |
|---------------|----------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `trigger_id`  | 정수        | 예      | 트리거 ID |
| `description` | 문자열         | 아니요       | 트리거 이름 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form description="my description" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/10"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## 파이프라인 트리거 토큰 삭제 {#delete-a-pipeline-trigger-token}

프로젝트의 파이프라인 트리거 토큰을 삭제합니다.

```plaintext
DELETE /projects/:id/triggers/:trigger_id
```

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `trigger_id` | 정수        | 예      | 트리거 ID |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

## 토큰으로 파이프라인 트리거 {#trigger-a-pipeline-with-a-token}

{{< history >}}

- `inputs` 속성 [GitLab 17.10에 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/519958) 됨 [플래그](../administration/feature_flags/_index.md)로 이름이 `ci_inputs_for_pipelines`. 기본적으로 비활성화됨.
- `inputs` 속성 [GitLab 17.11에서 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/525504).
- `inputs` 속성은 GitLab 18.1에서 [일반 공급되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/536548). 기능 플래그 `ci_inputs_for_pipelines` 제거됨.

{{< /history >}}

[파이프라인 트리거 토큰](../ci/triggers/_index.md#create-a-pipeline-trigger-token) 또는 [CI/CD 작업 토큰](../ci/jobs/ci_job_token.md)을 사용하여 파이프라인을 트리거합니다.

CI/CD 작업 토큰을 사용하면 [트리거된 파이프라인은 다중 프로젝트 파이프라인](../ci/pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)입니다. 요청을 인증하는 작업은 파이프라인 그래프에 표시되는 업스트림 파이프라인과 연결됩니다.

작업에서 트리거 토큰을 사용하면 작업은 업스트림 파이프라인과 연결되지 않습니다.

```plaintext
POST /projects/:id/trigger/pipeline
```

지원되는 속성:

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `ref`       | 문자열         | 예      | 파이프라인을 실행할 브랜치 또는 태그. |
| `token`     | 문자열         | 예      | 트리거 토큰 또는 CI/CD 작업 토큰. |
| `variables` | 해시           | 아니요       | 파이프라인 변수를 포함하는 키-값 문자열의 맵. 예: `{ VAR1: "value1", VAR2: "value2" }`. |
| `inputs`    | 해시           | 아니요       | 파이프라인 생성 시 사용할 키-값 쌍으로 입력하는 맵. |

[변수](../ci/variables/_index.md)를 포함한 요청 예시:

```shell
curl --request POST \
  --form "variables[VAR1]=value1" \
  --form "variables[VAR2]=value2" \
  --url "https://gitlab.example.com/api/v4/projects/123/trigger/pipeline?token=2cb1840fb9dfc9fb0b7b1609cd29cb&ref=main"
```

[입력](../ci/inputs/_index.md)을 포함한 요청 예시:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --data '{"inputs": {"environment": "environment", "scan_security": false, "level": 3}}' \
  --url "https://gitlab.example.com/api/v4/projects/123/trigger/pipeline?token=2cb1840fb9dfc9fb0b7b1609cd29cb&ref=main"
```

응답 예시:

```json
{
  "id": 257,
  "iid": 118,
  "project_id": 123,
  "sha": "91e2711a93e5d9e8dddfeb6d003b636b25bf6fc9",
  "ref": "main",
  "status": "created",
  "source": "trigger",
  "created_at": "2022-03-31T01:12:49.068Z",
  "updated_at": "2022-03-31T01:12:49.068Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/257",
  "before_sha": "0000000000000000000000000000000000000000",
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
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_created",
    "text": "created",
    "label": "created",
    "group": "created",
    "tooltip": "created",
    "has_details": true,
    "details_path": "/test-group/test-project/-/pipelines/257",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png"
  },
  "archived": false
}
```
