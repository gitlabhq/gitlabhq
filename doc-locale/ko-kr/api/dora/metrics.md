---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API를 사용하여 프로젝트 및 그룹 DORA 메트릭을 검색합니다.
title: DevOps Research and Assessment (DORA) 메트릭 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 그룹 및 프로젝트에 대한 [DORA 메트릭](../../user/analytics/dora_metrics.md)의 세부 정보를 검색합니다.

[GraphQL API](../graphql/reference/_index.md)를 사용하여 추가 엔드포인트를 사용할 수 있습니다.

전제 조건:

- Reporter, Developer, Maintainer 또는 Owner 역할이 필요합니다.

## 프로젝트 수준 DORA 메트릭 검색 {#retrieve-project-level-dora-metrics}

지정된 프로젝트에 대한 DORA 메트릭을 검색합니다.

```plaintext
GET /projects/:id/dora/metrics
```

| 속성            | 유형             | 필수 | 설명 |
|:---------------------|:-----------------|:---------|:------------|
| `id`                 | 정수 또는 문자열   | 예      | ID 또는 [프로젝트의 URL 인코딩된 경로](../rest/_index.md#namespaced-paths)는 인증된 사용자가 접근할 수 있습니다. |
| `metric`             | 문자열           | 예      | `deployment_frequency`, `lead_time_for_changes`, `time_to_restore_service` 또는 `change_failure_rate` 중 하나입니다. |
| `end_date`           | 문자열           | 아니요       | 종료할 날짜 범위입니다. ISO 8601 날짜 형식(예: `2021-03-01`)입니다. 기본값은 현재 날짜입니다. |
| `environment_tiers`  | 문자열 배열 | 아니요       | [환경의 계층](../../ci/environments/_index.md#deployment-tier-of-environments)입니다. 기본값은 `production`입니다. |
| `interval`           | 문자열           | 아니요       | 버킷팅 간격입니다. `all`, `monthly` 또는 `daily` 중 하나입니다. 기본값은 `daily`입니다. |
| `start_date`         | 문자열           | 아니요       | 시작할 날짜 범위입니다. ISO 8601 날짜 형식(예: `2021-03-01`)입니다. 기본값은 3개월 전입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/dora/metrics?metric=deployment_frequency"
```

응답 예시:

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## 그룹 수준 DORA 메트릭 검색 {#retrieve-group-level-dora-metrics}

지정된 그룹에 대한 DORA 메트릭을 검색합니다.

```plaintext
GET /groups/:id/dora/metrics
```

| 속성           | 유형             | 필수 | 설명 |
|:--------------------|:-----------------|:---------|:------------|
| `id`                | 정수 또는 문자열   | 예      | ID 또는 [프로젝트의 URL 인코딩된 경로](../rest/_index.md#namespaced-paths)는 인증된 사용자가 접근할 수 있습니다. |
| `metric`            | 문자열           | 예      | `deployment_frequency`, `lead_time_for_changes`, `time_to_restore_service` 또는 `change_failure_rate` 중 하나입니다. |
| `end_date`          | 문자열           | 아니요       | 종료할 날짜 범위입니다. ISO 8601 날짜 형식(예: `2021-03-01`)입니다. 기본값은 현재 날짜입니다. |
| `environment_tiers` | 문자열 배열 | 아니요       | [환경의 계층](../../ci/environments/_index.md#deployment-tier-of-environments)입니다. 기본값은 `production`입니다. |
| `interval`          | 문자열           | 아니요       | 버킷팅 간격입니다. `all`, `monthly` 또는 `daily` 중 하나입니다. 기본값은 `daily`입니다. |
| `start_date`        | 문자열           | 아니요       | 시작할 날짜 범위입니다. ISO 8601 날짜 형식(예: `2021-03-01`)입니다. 기본값은 3개월 전입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/dora/metrics?metric=deployment_frequency"
```

응답 예시:

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## `value` 필드 {#the-value-field}

이전에 설명한 프로젝트 및 그룹 수준 엔드포인트 모두에서 API 응답의 `value` 필드는 제공된 `metric` 쿼리 매개변수에 따라 다른 의미를 갖습니다:

| `metric` 쿼리 매개변수   | 응답에서 `value`의 설명 |
|:---------------------------|:-----------------------------------|
| `deployment_frequency`     | API는 시간 기간 동안 성공적인 배포의 총 개수를 반환합니다. [이슈 371271](https://gitlab.com/gitlab-org/gitlab/-/issues/371271)은 API가 총 개수 대신 일일 평균을 반환하도록 업데이트할 것을 제안합니다. |
| `change_failure_rate`      | 시간 기간 동안 배포 수로 나눈 사건 수입니다. 프로덕션 환경에서만 사용 가능합니다. |
| `lead_time_for_changes`    | 시간 기간 동안 배포된 모든 머지 리퀘스트의 머지 리퀘스트(MR) 병합과 MR 커밋 배포 사이의 중앙값(초 단위)입니다. |
| `time_to_restore_service`  | 시간 기간 동안 사건이 열려 있던 중앙값(초 단위)입니다. 프로덕션 환경에서만 사용 가능합니다. |

> [!note]
> API는 일일 중앙값의 중앙값을 계산하여 `monthly` 및 `all` 간격을 반환합니다. 이는 반환된 데이터에 약간의 부정확성을 초래할 수 있습니다.
