---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 일정 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [파이프라인 일정](../ci/pipelines/schedules.md)과 상호작용합니다.

## 모든 파이프라인 일정 목록 {#list-all-pipeline-schedules}

프로젝트의 모든 파이프라인 일정을 나열합니다.

```plaintext
GET /projects/:id/pipeline_schedules
```

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `scope`   | 문자열            | 아니요       | 파이프라인 일정의 범위이며, 다음 중 하나여야 합니다: `active`, `inactive`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules"
```

```json
[
    {
        "id": 13,
        "description": "Test schedule pipeline",
        "ref": "refs/heads/main",
        "cron": "* * * * *",
        "cron_timezone": "Asia/Tokyo",
        "next_run_at": "2017-05-19T13:41:00.000Z",
        "active": true,
        "created_at": "2017-05-19T13:31:08.849Z",
        "updated_at": "2017-05-19T13:40:17.727Z",
        "owner": {
            "name": "Administrator",
            "username": "root",
            "id": 1,
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
            "web_url": "https://gitlab.example.com/root"
        },
        "inputs": [
            {
                "name": "deploy_strategy",
                "value": "blue-green"
            },
            {
                "name": "feature_flags",
                "value": ["flag1", "flag2"]
            }
        ]
    }
]
```

> [!note]
> `inputs` 필드는 Maintainer 또는 Owner 역할을 가진 사용자 또는 일정 소유자의 응답에만 포함됩니다.

## 파이프라인 일정 검색 {#retrieve-a-pipeline-schedule}

프로젝트의 파이프라인 일정을 검색합니다.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "* * * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T13:41:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:40:17.727Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    },
    "variables": [
        {
            "key": "TEST_VARIABLE_1",
            "variable_type": "env_var",
            "value": "TEST_1",
            "raw": false
        }
    ],
    "inputs": [
        {
            "name": "deploy_strategy",
            "value": "blue-green"
        },
        {
            "name": "feature_flags",
            "value": ["flag1", "flag2"]
        }
    ]
}
```

> [!note]
> `inputs` 및 `variables` 필드는 Maintainer 또는 Owner 역할을 가진 사용자 또는 일정 소유자의 응답에만 포함됩니다.

## 파이프라인 일정으로 트리거된 모든 파이프라인 나열 {#list-all-pipelines-triggered-by-a-pipeline-schedule}

프로젝트에서 파이프라인 일정으로 트리거된 모든 파이프라인을 나열합니다.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/pipelines
```

지원되는 속성:

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |
| `scope`                | 문자열            | 아니요       | 파이프라인의 범위입니다. 다음 중 하나입니다: `running`, `pending`, `finished`, `branches`, `tags`. |
| `sort`                 | 문자열            | 아니요       | 파이프라인을 `asc` 또는 `desc` 순서로 정렬합니다. 기본값은 `asc`입니다. |
| `status`               | 문자열            | 아니요       | 파이프라인의 상태입니다. 다음 중 하나입니다: `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled`. |
| `updated_after`        | 날짜/시간          | 아니요       | 지정된 날짜 이후에 업데이트된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `updated_before`       | 날짜/시간          | 아니요       | 지정된 날짜 이전에 업데이트된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_after`        | 날짜/시간          | 아니요       | 지정된 날짜 이후에 생성된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before`       | 날짜/시간          | 아니요       | 지정된 날짜 이전에 생성된 파이프라인을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/pipelines"
```

응답 예시:

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## 새 파이프라인 일정 생성 {#create-a-new-pipeline-schedule}

{{< history >}}

- `inputs` 속성은 GitLab 17.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/525504) [플래그](../administration/feature_flags/_index.md) `ci_inputs_for_pipelines`와 함께입니다. 기본적으로 활성화됨.
- `inputs` 속성은 GitLab 18.1에서 [일반 공급되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/536548). 기능 플래그 `ci_inputs_for_pipelines` 제거됨.

{{< /history >}}

프로젝트의 새 파이프라인 일정을 생성합니다.

```plaintext
POST /projects/:id/pipeline_schedules
```

| 속성       | 유형              | 필수 | 설명 |
| --------------- | ----------------- | -------- | ----------- |
| `cron`          | 문자열            | 예      | Cron 일정입니다(예: `0 1 * * *`). |
| `description`   | 문자열            | 예      | 파이프라인 일정에 대한 설명입니다. |
| `id`            | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `ref`           | 문자열            | 예      | 파이프라인을 트리거하는 브랜치 또는 태그 이름입니다. 짧은 참조(`main`) 또는 전체 참조(`refs/heads/main` 또는 `refs/tags/main`)를 허용합니다. 짧은 참조는 값이 브랜치 또는 태그와 일치할 수 있는 경우를 제외하고 자동으로 전체 참조로 확장됩니다. |
| `active`        | 부울           | 아니요       | 파이프라인 일정을 활성화합니다. false로 설정하면 파이프라인 일정이 처음에는 비활성화됩니다(기본값: `true`). |
| `cron_timezone` | 문자열            | 아니요       | `ActiveSupport::TimeZone`에서 지원하는 시간대입니다(예: `Pacific Time (US & Canada)`)(기본값: `UTC`). |
| `inputs`        | 해시              | 아니요       | 파이프라인 일정으로 전달할 [입력](../ci/inputs/_index.md#for-a-pipeline)의 배열입니다. 각 입력은 `name`와 `value`을 포함합니다. 값은 문자열, 배열, 숫자 또는 부울일 수 있습니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules" \
  --form "description=Build packages" \
  --form "ref=main" \
  --form "cron=0 1 * * 5" \
  --form "cron_timezone=UTC" \
  --form "active=true"
```

응답 예시:

```json
{
    "id": 14,
    "description": "Build packages",
    "ref": "refs/heads/main",
    "cron": "0 1 * * 5",
    "cron_timezone": "UTC",
    "next_run_at": "2017-05-26T01:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:43:08.169Z",
    "updated_at": "2017-05-19T13:43:08.169Z",
    "last_pipeline": null,
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

`inputs`이 포함된 요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules" \
  --form "description=Build packages" \
  --form "ref=main" \
  --form "cron=0 1 * * 5" \
  --form "cron_timezone=UTC" \
  --form "active=true" \
  --form "inputs[][name]=deploy_strategy" \
  --form "inputs[][value]=blue-green"
```

## 파이프라인 일정 업데이트 {#update-a-pipeline-schedule}

프로젝트의 파이프라인 일정을 업데이트합니다. 업데이트가 완료되면 자동으로 다시 예약됩니다.

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |
| `active`               | 부울           | 아니요       | 파이프라인 일정을 활성화합니다. false로 설정하면 파이프라인 일정이 처음에는 비활성화됩니다. |
| `cron_timezone`        | 문자열            | 아니요       | `ActiveSupport::TimeZone`(예: `Pacific Time (US & Canada)`)에서 지원하는 시간대 또는 `TZInfo::Timezone`(예: `America/Los_Angeles`)입니다. |
| `cron`                 | 문자열            | 아니요       | Cron 일정입니다(예: `0 1 * * *`). |
| `description`          | 문자열            | 아니요       | 파이프라인 일정에 대한 설명입니다. |
| `ref`                  | 문자열            | 아니요       | 파이프라인을 트리거하는 브랜치 또는 태그 이름입니다. 짧은 참조(`main`) 또는 전체 참조(`refs/heads/main` 또는 `refs/tags/main`)를 허용합니다. 짧은 참조는 값이 브랜치 또는 태그와 일치할 수 있는 경우를 제외하고 자동으로 전체 참조로 확장됩니다. |
| `inputs`               | 해시              | 아니요       | 파이프라인 일정으로 전달할 [입력](../ci/inputs/_index.md)의 배열입니다. 각 입력은 `name`와 `value`을 포함합니다. 기존 입력을 삭제하려면 `name` 필드를 포함하고 `destroy`을 `true`으로 설정합니다. 값은 문자열, 배열, 숫자 또는 부울일 수 있습니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13" \
  --form "cron=0 2 * * *"
```

응답 예시:

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:44:16.135Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

`inputs`이 포함된 요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13" \
  --form "cron=0 2 * * *" \
  --form "inputs[][name]=deploy_strategy" \
  --form "inputs[][value]=rolling" \
  --form "inputs[][name]=existing_input" \
  --form "inputs[][destroy]=true"
```

## 파이프라인 일정의 소유권 업데이트 {#update-ownership-of-a-pipeline-schedule}

프로젝트의 파이프라인 일정 소유자를 업데이트합니다.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/take_ownership"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## 파이프라인 일정 삭제 {#delete-a-pipeline-schedule}

프로젝트의 파이프라인 일정을 삭제합니다.

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## 파이프라인 일정 즉시 실행 {#run-a-pipeline-schedule-immediately}

파이프라인 일정을 즉시 실행합니다. 이 파이프라인의 다음 예약된 실행은 영향을 받지 않습니다.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/play
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/pipeline_schedules/1/play"
```

응답 예시:

```json
{
  "message": "201 Created"
}
```

## 파이프라인 일정의 변수 생성 {#create-a-variable-for-a-pipeline-schedule}

파이프라인 일정의 새 변수를 생성합니다.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`                  | 문자열            | 예      | 변수의 키입니다. 255자 이하여야 하며 `A-Z`, `a-z`, `0-9`, `_`만 허용됩니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |
| `value`                | 문자열            | 예      | 변수의 값입니다. |
| `variable_type`        | 문자열            | 아니요       | 변수의 유형입니다. 사용 가능한 유형은 `env_var`(기본값) 및 `file`입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "variable_type": "env_var",
    "value": "new value"
}
```

## 파이프라인 일정의 변수 검색 {#retrieve-a-variable-for-a-pipeline-schedule}

{{< history >}}

- GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/386005).

{{< /history >}}

파이프라인 일정의 변수를 검색합니다.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`                  | 문자열            | 예      | 변수의 키입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성       | 유형   | 설명 |
| --------------- | ------ | ----------- |
| `key`           | 문자열 | 변수의 키입니다. |
| `value`         | 문자열 | 변수의 값입니다. |
| `variable_type` | 문자열 | 변수의 유형입니다. `env_var` 또는 `file`입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

응답 예시:

```json
{
    "key": "NEW_VARIABLE",
    "variable_type": "env_var",
    "value": "new value"
}
```

## 파이프라인 일정의 변수 업데이트 {#update-a-variable-for-a-pipeline-schedule}

파이프라인 일정의 변수를 업데이트합니다.

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`                  | 문자열            | 예      | 변수의 키입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |
| `value`                | 문자열            | 예      | 변수의 값입니다. |
| `variable_type`        | 문자열            | 아니요       | 변수의 유형입니다. 사용 가능한 유형은 `env_var`(기본값) 및 `file`입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var"
}
```

## 파이프라인 일정의 변수 삭제 {#delete-a-variable-for-a-pipeline-schedule}

파이프라인 일정의 변수를 삭제합니다.

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| 속성              | 유형              | 필수 | 설명 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`                  | 문자열            | 예      | 변수의 키입니다. |
| `pipeline_schedule_id` | 정수           | 예      | 파이프라인 일정의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

### 모호한 참조 {#ambiguous-refs}

API는 다음과 같은 경우 짧은 `ref`를 전체 `ref`으로 자동 확장할 수 없습니다:

- 브랜치와 태그가 모두 짧은 `ref`과 같은 이름으로 존재합니다.
- 해당 이름으로 존재하는 브랜치 또는 태그가 없습니다.

이 이슈를 해결하려면 전체 `ref`을 제공하여 올바른 리소스가 식별되도록 합니다.
