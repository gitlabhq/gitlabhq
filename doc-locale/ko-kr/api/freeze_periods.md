---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 동결 기간 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 배포 [동결 기간](../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze)과 상호작용합니다.

## 동결 기간 나열 {#list-freeze-periods}

`created_at`로 정렬된 동결 기간의 페이지 분할 목록(오름차순)입니다.

전제 조건:

- 프로젝트에 대해 리포터, 개발자, 유지 관리자 또는 소유자 역할이 필요합니다.

```plaintext
GET /projects/:id/freeze_periods
```

| 속성     | 유형           | 필수 | 설명                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

응답 예시:

```json
[
   {
      "id":1,
      "freeze_start":"0 23 * * 5",
      "freeze_end":"0 8 * * 1",
      "cron_timezone":"UTC",
      "created_at":"2020-05-15T17:03:35.702Z",
      "updated_at":"2020-05-15T17:06:41.566Z"
   }
]
```

## 동결 기간 검색 {#retrieve-a-freeze-period}

지정된 `freeze_period_id`에 대한 동결 기간을 검색합니다.

전제 조건:

- 프로젝트에 대해 리포터, 개발자, 유지 관리자 또는 소유자 역할이 필요합니다.

```plaintext
GET /projects/:id/freeze_periods/:freeze_period_id
```

| 속성     | 유형           | 필수 | 설명                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `freeze_period_id`    | 정수         | 예      | 동결 기간의 ID입니다.                                     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

응답 예시:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## 동결 기간 생성 {#create-a-freeze-period}

지정된 프로젝트에 대한 동결 기간을 생성합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
POST /projects/:id/freeze_periods
```

| 속성          | 유형            | 필수                    | 설명                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | 정수 또는 문자열  | 예                         | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                                              |
| `freeze_start`     | 문자열          | 예                         | 동결 기간의 시작 시간(단위: [cron](https://crontab.guru/) 형식)입니다.                                                              |
| `freeze_end`       | 문자열          | 예                         | 동결 기간의 종료 시간(단위: [cron](https://crontab.guru/) 형식)입니다.                                                                |
| `cron_timezone`    | 문자열          | 아니요                          | cron 필드의 시간대입니다. 제공되지 않으면 UTC가 기본값입니다.                                                               |

요청 예시:

```shell
curl --request POST \
  --header 'Content-Type: application/json' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{ "freeze_start": "0 23 * * 5", "freeze_end": "0 7 * * 1", "cron_timezone": "UTC" }' \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

응답 예시:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 7 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:03:35.702Z"
}
```

## 동결 기간 업데이트 {#update-a-freeze-period}

지정된 `freeze_period_id`에 대한 동결 기간을 업데이트합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
PUT /projects/:id/freeze_periods/:freeze_period_id
```

| 속성     | 유형            | 필수 | 설명                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열  | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                         |
| `freeze_period_id`    | 정수          | 예      | 동결 기간의 ID입니다.                                                              |
| `freeze_start`     | 문자열          | 아니요                         | 동결 기간의 시작 시간(단위: [cron](https://crontab.guru/) 형식)입니다.                                                              |
| `freeze_end`       | 문자열          | 아니요                         | 동결 기간의 종료 시간(단위: [cron](https://crontab.guru/) 형식)입니다.                                                                |
| `cron_timezone`    | 문자열          | 아니요                          | cron 필드의 시간대입니다.                                                               |

요청 예시:

```shell
curl --request PUT \
  --header 'Content-Type: application/json' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{ "freeze_end": "0 8 * * 1" }' \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

응답 예시:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## 동결 기간 삭제 {#delete-a-freeze-period}

지정된 `freeze_period_id`에 대한 동결 기간을 삭제합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
DELETE /projects/:id/freeze_periods/:freeze_period_id
```

| 속성     | 유형           | 필수 | 설명                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `freeze_period_id`    | 정수         | 예      | 동결 기간의 ID입니다.                                     |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```
