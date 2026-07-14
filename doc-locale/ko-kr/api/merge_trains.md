---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 머지 트레인에 대한 REST API 설명서입니다.
title: 머지 트레인 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [머지 트레인](../ci/pipelines/merge_trains.md)과 상호 작용할 수 있습니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

모든 머지 트레인 엔드포인트는 `page`과 `per_page` 매개변수를 사용하는 [오프셋 기반 페이지 매김](rest/_index.md#offset-based-pagination)을 지원합니다.

## 프로젝트의 모든 머지 트레인 나열 {#list-all-merge-trains-for-a-project}

지정된 프로젝트의 모든 머지 트레인을 나열합니다.

```plaintext
GET /projects/:id/merge_trains
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `scope`   | 문자열            | 아니요       | 주어진 범위로 필터링된 머지 트레인을 반환합니다. 사용 가능한 범위는 `active`(병합될) 및 `complete`(병합됨)입니다. |
| `sort`    | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 정렬된 머지 트레인을 반환합니다. 기본값: `desc`. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                   | 유형     | 설명 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 날짜/시간 | 머지 트레인이 생성된 타임스탬프입니다. |
| `duration`                  | 정수  | 머지 트레인에서 소비한 시간(초)이거나, 완료되지 않은 경우 `null`입니다. |
| `id`                        | 정수  | 머지 트레인의 ID입니다. |
| `merged_at`                 | 날짜/시간 | 머지 리퀘스트가 병합된 타임스탬프이거나, 병합되지 않은 경우 `null`입니다. |
| `merge_request`             | 객체   | 머지 리퀘스트 세부 정보입니다. |
| `merge_request.created_at`  | 날짜/시간 | 머지 리퀘스트가 생성된 타임스탬프입니다. |
| `merge_request.description` | 문자열   | 머지 리퀘스트의 설명입니다. |
| `merge_request.id`          | 정수  | 머지 리퀘스트의 ID입니다. |
| `merge_request.iid`         | 정수  | 머지 리퀘스트의 내부 ID입니다. |
| `merge_request.project_id`  | 정수  | 머지 리퀘스트를 포함하는 프로젝트의 ID입니다. |
| `merge_request.state`       | 문자열   | 머지 리퀘스트의 상태입니다. |
| `merge_request.title`       | 문자열   | 머지 리퀘스트의 제목입니다. |
| `merge_request.updated_at`  | 날짜/시간 | 머지 리퀘스트가 마지막으로 업데이트된 타임스탬프입니다. |
| `merge_request.web_url`     | 문자열   | 머지 리퀘스트의 웹 URL입니다. |
| `pipeline`                  | 객체   | 파이프라인 세부 정보이거나, 연결된 파이프라인이 없는 경우 `null`입니다. |
| `pipeline.created_at`       | 날짜/시간 | 파이프라인이 생성된 타임스탬프입니다. |
| `pipeline.id`               | 정수  | 파이프라인의 ID입니다. |
| `pipeline.iid`              | 정수  | 파이프라인의 내부 ID입니다. |
| `pipeline.project_id`       | 정수  | 파이프라인을 포함하는 프로젝트의 ID입니다. |
| `pipeline.ref`              | 문자열   | 파이프라인의 Git 참조입니다. |
| `pipeline.sha`              | 문자열   | 파이프라인을 트리거한 커밋의 SHA입니다. |
| `pipeline.source`           | 문자열   | 파이프라인 트리거의 소스입니다. |
| `pipeline.status`           | 문자열   | 파이프라인의 상태입니다. |
| `pipeline.updated_at`       | 날짜/시간 | 파이프라인이 마지막으로 업데이트된 타임스탬프입니다. |
| `pipeline.web_url`          | 문자열   | 파이프라인의 웹 URL입니다. |
| `status`                    | 문자열   | 머지 트레인의 머지 리퀘스트의 상태입니다. 활성 머지 트레인의 가능한 값: `idle`, `fresh` 또는 `stale`입니다. 완료된 머지 트레인의 가능한 값: `merging`, `merged` 또는 `skip_merged`입니다. |
| `target_branch`             | 문자열   | 대상 브랜치의 이름입니다. |
| `updated_at`                | 날짜/시간 | 머지 트레인이 마지막으로 업데이트된 타임스탬프입니다. |
| `user`                      | 객체   | 머지 트레인에 머지 리퀘스트를 추가한 사용자입니다. |
| `user.avatar_url`           | 문자열   | 사용자의 아바타 URL입니다. |
| `user.id`                   | 정수  | 사용자의 ID입니다. |
| `user.name`                 | 문자열   | 사용자의 이름입니다. |
| `user.state`                | 문자열   | 사용자 계정의 상태입니다. |
| `user.username`             | 문자열   | 사용자의 사용자 이름입니다. |
| `user.web_url`              | 문자열   | 사용자 프로필의 웹 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_trains"
```

응답 예시:

```json
[
  {
    "id": 110,
    "merge_request": {
      "id": 126,
      "iid": 59,
      "project_id": 20,
      "title": "Test MR 1580978354",
      "description": "",
      "state": "merged",
      "created_at": "2020-02-06T08:39:14.883Z",
      "updated_at": "2020-02-06T08:40:57.038Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/-/merge_requests/59"
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://local.gitlab.test:8181/root"
    },
    "pipeline": {
      "id": 246,
      "sha": "bcc17a8ffd51be1afe45605e714085df28b80b13",
      "ref": "refs/merge-requests/59/train",
      "status": "success",
      "created_at": "2020-02-06T08:40:42.410Z",
      "updated_at": "2020-02-06T08:40:46.912Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/pipelines/246"
    },
    "created_at": "2020-02-06T08:39:47.217Z",
    "updated_at": "2020-02-06T08:40:57.720Z",
    "target_branch": "feature-1580973432",
    "status": "merged",
    "merged_at": "2020-02-06T08:40:57.719Z",
    "duration": 70
  }
]
```

## 머지 트레인의 모든 머지 리퀘스트 나열 {#list-all-merge-requests-in-a-merge-train}

대상 브랜치의 머지 트레인의 모든 머지 리퀘스트를 나열합니다.

```plaintext
GET /projects/:id/merge_trains/:target_branch
```

지원되는 속성:

| 속성       | 유형              | 필수 | 설명 |
| --------------- | ----------------- | -------- | ----------- |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `target_branch` | 문자열            | 예      | 머지 트레인의 대상 브랜치입니다. |
| `scope`         | 문자열            | 아니요       | 주어진 범위로 필터링된 머지 트레인을 반환합니다. 사용 가능한 범위는 `active`(병합될) 및 `complete`(병합됨)입니다. |
| `sort`          | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 정렬된 머지 트레인을 반환합니다. 기본값: `desc`. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                   | 유형     | 설명 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 날짜/시간 | 머지 트레인이 생성된 타임스탬프입니다. |
| `duration`                  | 정수  | 머지 트레인에서 소비한 시간(초)이거나, 완료되지 않은 경우 `null`입니다. |
| `id`                        | 정수  | 머지 트레인의 ID입니다. |
| `merged_at`                 | 날짜/시간 | 머지 리퀘스트가 병합된 타임스탬프이거나, 병합되지 않은 경우 `null`입니다. |
| `merge_request`             | 객체   | 머지 리퀘스트 세부 정보입니다. |
| `merge_request.created_at`  | 날짜/시간 | 머지 리퀘스트가 생성된 타임스탬프입니다. |
| `merge_request.description` | 문자열   | 머지 리퀘스트의 설명입니다. |
| `merge_request.id`          | 정수  | 머지 리퀘스트의 ID입니다. |
| `merge_request.iid`         | 정수  | 머지 리퀘스트의 내부 ID입니다. |
| `merge_request.project_id`  | 정수  | 머지 리퀘스트를 포함하는 프로젝트의 ID입니다. |
| `merge_request.state`       | 문자열   | 머지 리퀘스트의 상태입니다. |
| `merge_request.title`       | 문자열   | 머지 리퀘스트의 제목입니다. |
| `merge_request.updated_at`  | 날짜/시간 | 머지 리퀘스트가 마지막으로 업데이트된 타임스탬프입니다. |
| `merge_request.web_url`     | 문자열   | 머지 리퀘스트의 웹 URL입니다. |
| `pipeline`                  | 객체   | 파이프라인 세부 정보이거나, 연결된 파이프라인이 없는 경우 `null`입니다. |
| `pipeline.created_at`       | 날짜/시간 | 파이프라인이 생성된 타임스탬프입니다. |
| `pipeline.id`               | 정수  | 파이프라인의 ID입니다. |
| `pipeline.iid`              | 정수  | 파이프라인의 내부 ID입니다. |
| `pipeline.project_id`       | 정수  | 파이프라인을 포함하는 프로젝트의 ID입니다. |
| `pipeline.ref`              | 문자열   | 파이프라인의 Git 참조입니다. |
| `pipeline.sha`              | 문자열   | 파이프라인을 트리거한 커밋의 SHA입니다. |
| `pipeline.source`           | 문자열   | 파이프라인 트리거의 소스입니다. |
| `pipeline.status`           | 문자열   | 파이프라인의 상태입니다. |
| `pipeline.updated_at`       | 날짜/시간 | 파이프라인이 마지막으로 업데이트된 타임스탬프입니다. |
| `pipeline.web_url`          | 문자열   | 파이프라인의 웹 URL입니다. |
| `status`                    | 문자열   | 머지 트레인의 머지 리퀘스트의 상태입니다. 활성 머지 트레인의 가능한 값: `idle`, `fresh` 또는 `stale`입니다. 완료된 머지 트레인의 가능한 값: `merging`, `merged` 또는 `skip_merged`입니다. |
| `target_branch`             | 문자열   | 대상 브랜치의 이름입니다. |
| `updated_at`                | 날짜/시간 | 머지 트레인이 마지막으로 업데이트된 타임스탬프입니다. |
| `user`                      | 객체   | 머지 트레인에 머지 리퀘스트를 추가한 사용자입니다. |
| `user.avatar_url`           | 문자열   | 사용자의 아바타 URL입니다. |
| `user.id`                   | 정수  | 사용자의 ID입니다. |
| `user.name`                 | 문자열   | 사용자의 이름입니다. |
| `user.state`                | 문자열   | 사용자 계정의 상태입니다. |
| `user.username`             | 문자열   | 사용자의 사용자 이름입니다. |
| `user.web_url`              | 문자열   | 사용자 프로필의 웹 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/main"
```

응답 예시:

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```

## 머지 트레인 상태 조회 {#retrieve-merge-train-status}

지정된 머지 리퀘스트의 머지 트레인 상태를 조회합니다.

```plaintext
GET /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                   | 유형     | 설명 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 날짜/시간 | 머지 트레인이 생성된 타임스탬프입니다. |
| `duration`                  | 정수  | 머지 트레인에서 소비한 시간(초)이거나, 완료되지 않은 경우 `null`입니다. |
| `id`                        | 정수  | 머지 트레인의 ID입니다. |
| `merged_at`                 | 날짜/시간 | 머지 리퀘스트가 병합된 타임스탬프이거나, 병합되지 않은 경우 `null`입니다. |
| `merge_request`             | 객체   | 머지 리퀘스트 세부 정보입니다. |
| `merge_request.created_at`  | 날짜/시간 | 머지 리퀘스트가 생성된 타임스탬프입니다. |
| `merge_request.description` | 문자열   | 머지 리퀘스트의 설명입니다. |
| `merge_request.id`          | 정수  | 머지 리퀘스트의 ID입니다. |
| `merge_request.iid`         | 정수  | 머지 리퀘스트의 내부 ID입니다. |
| `merge_request.project_id`  | 정수  | 머지 리퀘스트를 포함하는 프로젝트의 ID입니다. |
| `merge_request.state`       | 문자열   | 머지 리퀘스트의 상태입니다. |
| `merge_request.title`       | 문자열   | 머지 리퀘스트의 제목입니다. |
| `merge_request.updated_at`  | 날짜/시간 | 머지 리퀘스트가 마지막으로 업데이트된 타임스탬프입니다. |
| `merge_request.web_url`     | 문자열   | 머지 리퀘스트의 웹 URL입니다. |
| `pipeline`                  | 객체   | 파이프라인 세부 정보이거나, 연결된 파이프라인이 없는 경우 `null`입니다. |
| `pipeline.created_at`       | 날짜/시간 | 파이프라인이 생성된 타임스탬프입니다. |
| `pipeline.id`               | 정수  | 파이프라인의 ID입니다. |
| `pipeline.iid`              | 정수  | 파이프라인의 내부 ID입니다. |
| `pipeline.project_id`       | 정수  | 파이프라인을 포함하는 프로젝트의 ID입니다. |
| `pipeline.ref`              | 문자열   | 파이프라인의 Git 참조입니다. |
| `pipeline.sha`              | 문자열   | 파이프라인을 트리거한 커밋의 SHA입니다. |
| `pipeline.source`           | 문자열   | 파이프라인 트리거의 소스입니다. |
| `pipeline.status`           | 문자열   | 파이프라인의 상태입니다. |
| `pipeline.updated_at`       | 날짜/시간 | 파이프라인이 마지막으로 업데이트된 타임스탬프입니다. |
| `pipeline.web_url`          | 문자열   | 파이프라인의 웹 URL입니다. |
| `status`                    | 문자열   | 머지 트레인의 머지 리퀘스트의 상태입니다. 활성 머지 트레인의 가능한 값: `idle`, `fresh` 또는 `stale`입니다. 완료된 머지 트레인의 가능한 값: `merging`, `merged` 또는 `skip_merged`입니다. |
| `target_branch`             | 문자열   | 대상 브랜치의 이름입니다. |
| `updated_at`                | 날짜/시간 | 머지 트레인이 마지막으로 업데이트된 타임스탬프입니다. |
| `user`                      | 객체   | 머지 트레인에 머지 리퀘스트를 추가한 사용자입니다. |
| `user.avatar_url`           | 문자열   | 사용자의 아바타 URL입니다. |
| `user.id`                   | 정수  | 사용자의 ID입니다. |
| `user.name`                 | 문자열   | 사용자의 이름입니다. |
| `user.state`                | 문자열   | 사용자 계정의 상태입니다. |
| `user.username`             | 문자열   | 사용자의 사용자 이름입니다. |
| `user.web_url`              | 문자열   | 사용자 프로필의 웹 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

응답 예시:

```json
{
  "id": 267,
  "merge_request": {
    "id": 273,
    "iid": 1,
    "project_id": 597,
    "title": "My title 9",
    "description": null,
    "state": "opened",
    "created_at": "2022-10-31T19:06:05.725Z",
    "updated_at": "2022-10-31T19:06:05.725Z",
    "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
  },
  "user": {
    "id": 933,
    "username": "user12",
    "name": "Sidney Jones31",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
    "web_url": "http://localhost/user12"
  },
  "pipeline": {
    "id": 273,
    "iid": 1,
    "project_id": 598,
    "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
    "ref": "main",
    "status": "pending",
    "source": "push",
    "created_at": "2022-10-31T19:06:06.231Z",
    "updated_at": "2022-10-31T19:06:06.231Z",
    "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
  },
  "created_at": "2022-10-31T19:06:06.237Z",
  "updated_at": "2022-10-31T19:06:06.237Z",
  "target_branch": "main",
  "status": "idle",
  "merged_at": null,
  "duration": null
}
```

## 머지 트레인에 머지 리퀘스트 추가 {#add-a-merge-request-to-a-merge-train}

지정된 머지 리퀘스트를 머지 트레인에 추가합니다.

```plaintext
POST /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

지원되는 속성:

| 속성                | 유형              | 필수 | 설명 |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid`      | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `auto_merge`             | 부울           | 아니요       | true인 경우, 검사가 통과하면 머지 리퀘스트가 머지 트레인에 추가됩니다. false이거나 지정되지 않은 경우, 머지 리퀘스트가 머지 트레인에 직접 추가됩니다. |
| `sha`                    | 문자열            | 아니요       | 존재하는 경우, SHA는 소스 브랜치의 `HEAD`과 일치해야 합니다. 그렇지 않으면 병합이 실패합니다. |
| `squash`                 | 부울           | 아니요       | true인 경우, 커밋이 병합 시 단일 커밋으로 스쿼시됩니다. |
| `when_pipeline_succeeds` | 부울           | 아니요       | GitLab 17.11에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/521290). `auto_merge` 대신 사용합니다. |

성공한 경우 반환값:

- 머지 리퀘스트가 머지 트레인에 즉시 추가되면 [`201 Created`](rest/troubleshooting.md#status-codes)입니다.
- 머지 리퀘스트가 머지 트레인에 추가되도록 예약되면 [`202 Accepted`](rest/troubleshooting.md#status-codes)입니다.

다음 응답 속성이 반환됩니다:

| 속성                   | 유형     | 설명 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 날짜/시간 | 머지 트레인이 생성된 타임스탬프입니다. |
| `duration`                  | 정수  | 머지 트레인에서 소비한 시간(초)이거나, 완료되지 않은 경우 `null`입니다. |
| `id`                        | 정수  | 머지 트레인의 ID입니다. |
| `merged_at`                 | 날짜/시간 | 머지 리퀘스트가 병합된 타임스탬프이거나, 병합되지 않은 경우 `null`입니다. |
| `merge_request`             | 객체   | 머지 리퀘스트 세부 정보입니다. |
| `merge_request.created_at`  | 날짜/시간 | 머지 리퀘스트가 생성된 타임스탬프입니다. |
| `merge_request.description` | 문자열   | 머지 리퀘스트의 설명입니다. |
| `merge_request.id`          | 정수  | 머지 리퀘스트의 ID입니다. |
| `merge_request.iid`         | 정수  | 머지 리퀘스트의 내부 ID입니다. |
| `merge_request.project_id`  | 정수  | 머지 리퀘스트를 포함하는 프로젝트의 ID입니다. |
| `merge_request.state`       | 문자열   | 머지 리퀘스트의 상태입니다. |
| `merge_request.title`       | 문자열   | 머지 리퀘스트의 제목입니다. |
| `merge_request.updated_at`  | 날짜/시간 | 머지 리퀘스트가 마지막으로 업데이트된 타임스탬프입니다. |
| `merge_request.web_url`     | 문자열   | 머지 리퀘스트의 웹 URL입니다. |
| `pipeline`                  | 객체   | 파이프라인 세부 정보이거나, 연결된 파이프라인이 없는 경우 `null`입니다. |
| `pipeline.created_at`       | 날짜/시간 | 파이프라인이 생성된 타임스탬프입니다. |
| `pipeline.id`               | 정수  | 파이프라인의 ID입니다. |
| `pipeline.iid`              | 정수  | 파이프라인의 내부 ID입니다. |
| `pipeline.project_id`       | 정수  | 파이프라인을 포함하는 프로젝트의 ID입니다. |
| `pipeline.ref`              | 문자열   | 파이프라인의 Git 참조입니다. |
| `pipeline.sha`              | 문자열   | 파이프라인을 트리거한 커밋의 SHA입니다. |
| `pipeline.source`           | 문자열   | 파이프라인 트리거의 소스입니다. |
| `pipeline.status`           | 문자열   | 파이프라인의 상태입니다. |
| `pipeline.updated_at`       | 날짜/시간 | 파이프라인이 마지막으로 업데이트된 타임스탬프입니다. |
| `pipeline.web_url`          | 문자열   | 파이프라인의 웹 URL입니다. |
| `status`                    | 문자열   | 머지 트레인의 머지 리퀘스트의 상태입니다. 활성 머지 트레인의 가능한 값: `idle`, `fresh` 또는 `stale`입니다. 완료된 머지 트레인의 가능한 값: `merging`, `merged` 또는 `skip_merged`입니다. |
| `target_branch`             | 문자열   | 대상 브랜치의 이름입니다. |
| `updated_at`                | 날짜/시간 | 머지 트레인이 마지막으로 업데이트된 타임스탬프입니다. |
| `user`                      | 객체   | 머지 트레인에 머지 리퀘스트를 추가한 사용자입니다. |
| `user.avatar_url`           | 문자열   | 사용자의 아바타 URL입니다. |
| `user.id`                   | 정수  | 사용자의 ID입니다. |
| `user.name`                 | 문자열   | 사용자의 이름입니다. |
| `user.state`                | 문자열   | 사용자 계정의 상태입니다. |
| `user.username`             | 문자열   | 사용자의 사용자 이름입니다. |
| `user.web_url`              | 문자열   | 사용자 프로필의 웹 URL입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

응답 예시:

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```
