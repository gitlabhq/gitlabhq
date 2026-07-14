---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab 환경을 관리하기 위한 API 엔드포인트로, 나열, 생성, 업데이트, 중지 및 삭제를 포함합니다."
title: 환경 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `auto_stop_setting` 매개변수를 GitLab 17.8에 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/428625)했습니다.
- [GitLab CI/CD 작업 토큰](../ci/jobs/ci_job_token.md) 인증을 GitLab 16.2에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/414549)했습니다.

{{< /history >}}

이 API를 사용하여 [GitLab 환경](../ci/environments/_index.md)과 상호작용합니다.

## 모든 환경 나열 {#list-all-environments}

지정된 프로젝트의 모든 환경을 나열합니다.

```plaintext
GET /projects/:id/environments
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된](rest/_index.md#namespaced-paths) 경로입니다. |
| `name`    | 문자열         | 아니요       | 이 이름의 환경을 반환합니다. `search`과(와) 함께 사용할 수 없습니다. |
| `search`  | 문자열         | 아니요       | 검색 조건과 일치하는 환경 목록을 반환합니다. `name`과(와) 함께 사용할 수 없습니다. 최소 3자 이상이어야 합니다. |
| `states`  | 문자열         | 아니요       | 특정 상태와 일치하는 모든 환경을 나열합니다. 허용되는 값: `available`, `stopping` 또는 `stopped`입니다. 상태 값이 지정되지 않으면 모든 환경을 반환합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments?name=review%2Ffix-foo"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "review/fix-foo",
    "slug": "review-fix-foo-dfjre3",
    "description": "This is review environment",
    "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
    "state": "available",
    "tier": "development",
    "created_at": "2019-05-25T18:55:13.252Z",
    "updated_at": "2019-05-27T18:55:13.252Z",
    "enable_advanced_logs_querying": false,
    "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
    "auto_stop_at": "2019-06-03T18:55:13.252Z",
    "kubernetes_namespace": "flux-system",
    "flux_resource_path": "HelmRelease/flux-system",
    "auto_stop_setting": "always"
  }
]
```

## 환경 검색 {#retrieve-an-environment}

프로젝트의 지정된 환경을 검색합니다.

```plaintext
GET /projects/:id/environments/:environment_id
```

| 속성        | 유형           | 필수 | 설명 |
|------------------|----------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `environment_id` | 정수        | 예      | 환경의 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

응답 예시

```json
{
  "id": 1,
  "name": "review/fix-foo",
  "slug": "review-fix-foo-dfjre3",
  "description": "This is review environment",
  "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
  "state": "available",
  "tier": "development",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "enable_advanced_logs_querying": false,
  "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
  "auto_stop_at": "2019-06-03T18:55:13.252Z",
  "last_deployment": {
    "id": 100,
    "iid": 34,
    "ref": "fdroid",
    "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
    "created_at": "2019-03-25T18:55:13.252Z",
    "status": "success",
    "user": {
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "deployable": {
      "id": 710,
      "status": "success",
      "stage": "deploy",
      "name": "staging",
      "ref": "fdroid",
      "tag": false,
      "coverage": null,
      "created_at": "2019-03-25T18:55:13.215Z",
      "started_at": "2019-03-25T12:54:50.082Z",
      "finished_at": "2019-03-25T18:55:13.216Z",
      "duration": 21623.13423,
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
        "organization": null
      },
      "commit": {
        "id": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "short_id": "416d8ea1",
        "created_at": "2016-01-02T15:39:18.000Z",
        "parent_ids": [
          "e9a4449c95c64358840902508fc827f1a2eab7df"
        ],
        "title": "Removed fabric to fix #40",
        "message": "Removed fabric to fix #40\n",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "authored_date": "2016-01-02T15:39:18.000Z",
        "committer_name": "Administrator",
        "committer_email": "admin@example.com",
        "committed_date": "2016-01-02T15:39:18.000Z"
      },
      "pipeline": {
        "id": 34,
        "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "ref": "fdroid",
        "status": "success",
        "web_url": "http://localhost:3000/Commit451/lab-coat/pipelines/34"
      },
      "web_url": "http://localhost:3000/Commit451/lab-coat/-/jobs/710",
      "artifacts": [
        {
          "file_type": "trace",
          "size": 1305,
          "filename": "job.log",
          "file_format": null
        }
      ],
      "runner": null,
      "artifacts_expire_at": null
    }
  },
  "cluster_agent": {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 환경 생성 {#create-an-environment}

지정된 프로젝트에 대한 환경을 생성합니다.

```plaintext
POST /projects/:id/environments
```

| 속성              | 유형           | 필수 | 설명 |
|------------------------|----------------|----------|-------------|
| `id`                   | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                 | 문자열         | 예      | 환경의 이름입니다. |
| `description`          | 문자열         | 아니요       | 환경의 설명입니다. |
| `external_url`         | 문자열         | 아니요       | 이 환경으로 링크할 수 있는 위치입니다. |
| `tier`                 | 문자열         | 아니요       | 새 환경의 계층입니다. 허용되는 값: `production`, `staging`, `testing`, `development` 및 `other`입니다. |
| `cluster_agent_id`     | 정수        | 아니요       | 이 환경과 연결할 클러스터 에이전트입니다. |
| `kubernetes_namespace` | 문자열         | 아니요       | 이 환경과 연결할 Kubernetes 네임스페이스입니다. |
| `flux_resource_path`   | 문자열         | 아니요       | 이 환경과 연결할 Flux 리소스 경로입니다. 전체 리소스 경로여야 합니다. 예를 들어, `helm.toolkit.fluxcd.io/v2/namespaces/gitlab-agent/helmreleases/gitlab-agent`입니다. |
| `auto_stop_setting`    | 문자열         | 아니요       | 환경의 자동 중지 설정입니다. 허용되는 값: `always` 또는 `with_action`입니다. |

성공하면 `201`을 반환하고, 잘못된 매개변수의 경우 `400`을 반환합니다.

```shell
curl --data "name=deploy&external_url=https://deploy.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments"
```

응답 예시:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "description": null,
  "external_url": "https://deploy.gitlab.example.com",
  "state": "available",
  "tier": "production",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 기존 환경 업데이트 {#update-an-existing-environment}

{{< history >}}

- `name` 매개변수를 GitLab 16.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/338897)했습니다.

{{< /history >}}

프로젝트에 대한 기존 환경을 업데이트합니다.

```plaintext
PUT /projects/:id/environments/:environments_id
```

| 속성              | 유형            | 필수 | 설명 |
|------------------------|-----------------|----------|-------------|
| `id`                   | 정수 또는 문자열  | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `environment_id`       | 정수         | 예      | 환경의 ID입니다. |
| `description`          | 문자열          | 아니요       | 환경의 설명입니다. |
| `external_url`         | 문자열          | 아니요       | 새로운 `external_url`입니다. |
| `tier`                 | 문자열          | 아니요       | 새 환경의 계층입니다. 허용되는 값: `production`, `staging`, `testing`, `development` 및 `other`입니다. |
| `cluster_agent_id`     | 정수 또는 null | 아니요       | 이 환경과 연결할 클러스터 에이전트 또는 제거할 `null`입니다. |
| `kubernetes_namespace` | 문자열 또는 null  | 아니요       | 이 환경과 연결할 Kubernetes 네임스페이스 또는 제거할 `null`입니다. |
| `flux_resource_path`   | 문자열 또는 null  | 아니요       | 이 환경과 연결할 Flux 리소스 경로 또는 제거할 `null`입니다. |
| `auto_stop_setting`    | 문자열 또는 null  | 아니요       | 환경의 자동 중지 설정입니다. 허용되는 값: `always` 또는 `with_action`입니다. |

성공하면 `200`을 반환합니다. 오류 발생 시 `400`을 반환합니다.

```shell
curl --request PUT \
  --data "external_url=https://staging.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "staging",
  "slug": "staging",
  "description": null,
  "external_url": "https://staging.gitlab.example.com",
  "state": "available",
  "tier": "staging",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 환경 삭제 {#delete-an-environment}

프로젝트에서 환경을 삭제합니다. 환경을 먼저 중지해야 합니다.

```plaintext
DELETE /projects/:id/environments/:environment_id
```

| 속성        | 유형           | 필수 | 설명 |
|------------------|----------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `environment_id` | 정수        | 예      | 환경의 ID입니다. |

성공하면 `204`을 반환합니다. 환경이 존재하지 않으면 `404`을 반환합니다. 환경이 중지되지 않았으면 `403`을 반환합니다.

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

## 중지된 검토 앱 여러 개 삭제 {#delete-multiple-stopped-review-apps}

이미 [중지](../ci/environments/_index.md#stopping-an-environment) 된 여러 환경의 삭제를 예약하고, [검토 앱 폴더에](../ci/review_apps/_index.md) 있습니다. 실제 삭제는 실행 시점으로부터 1주일 후에 수행됩니다. 기본적으로 30일 이상 된 환경만 삭제합니다.

```plaintext
DELETE /projects/:id/environments/review_apps
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `before`  | 날짜/시간       | 아니요       | 환경을 삭제할 수 있는 이전 날짜입니다. 기본값은 30일 전입니다. ISO 8601 형식(`YYYY-MM-DDTHH:MM:SSZ`)으로 예상됩니다. |
| `limit`   | 정수        | 아니요       | 삭제할 최대 환경 개수입니다. 기본값은 100입니다. |
| `dry_run` | 부울        | 아니요       | 안전상의 이유로 `true`이 기본값입니다. 실제 삭제가 수행되지 않는 드라이 런을 수행합니다. 실제로 환경을 삭제하려면 `false`로 설정합니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/review_apps"
```

응답 예시:

```json
{
  "scheduled_entries": [
    {
      "id": 387,
      "name": "review/023f1bce01229c686a73",
      "slug": "review-023f1bce01-3uxznk",
      "external_url": null
    },
    {
      "id": 388,
      "name": "review/85d4c26a388348d3c4c0",
      "slug": "review-85d4c26a38-5giw1c",
      "external_url": null
    }
  ],
  "unprocessable_entries": []
}
```

## 환경 중지 {#stop-an-environment}

실행 중인 환경을 중지합니다.

```plaintext
POST /projects/:id/environments/:environment_id/stop
```

| 속성        | 유형           | 필수 | 설명 |
|------------------|----------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `environment_id` | 정수        | 예      | 환경의 ID입니다. |
| `force`          | 부울        | 아니요       | `on_stop` 작업을 실행하지 않고 강제로 환경을 중지합니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1/stop"
```

응답 예시:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.gitlab.example.com",
  "state": "stopped",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 오래된 환경 중지 {#stop-stale-environments}

지정된 날짜 이전에 마지막으로 수정되었거나 배포된 모든 환경을 중지합니다. 보호 환경을 제외합니다.

```plaintext
POST /projects/:id/environments/stop_stale
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `before`  | 날짜           | 예      | 지정된 날짜 이전에 수정되었거나 배포된 환경을 중지합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. 유효한 입력은 10년 전과 1주일 전 사이입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/stop_stale?before=10%2F10%2F2021"
```

응답 예시:

```json
{
  "message": "Successfully requested stop for all stale environments"
}
```
