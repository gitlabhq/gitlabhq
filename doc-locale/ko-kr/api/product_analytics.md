---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Cube를 사용하여 GitLab 제품 분석 API를 쿼리합니다. 쿼리를 전송하고, 액세스 토큰을 생성하며, 분석 메타데이터를 검색합니다."
title: 제품 분석 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 15.4에서 [feature flag](../administration/feature_flags/_index.md)과 함께 도입되었으며 `cube_api_proxy`로 명명되었습니다. 기본적으로 비활성화됨.
- `cube_api_proxy`이(가) 제거되었으며 GitLab 15.10에서 `product_analytics_internal_preview`(으)로 대체되었습니다.
- `product_analytics_internal_preview`(이)가 GitLab 15.11에서 `product_analytics_dashboards`(으)로 대체되었습니다.
- `product_analytics_dashboards`(이)가 GitLab 16.11에서 기본적으로 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/398653)되었습니다.
- 기능 플래그 `product_analytics_dashboards`(이)가 GitLab 17.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/454059)되었습니다.
- GitLab 17.5에서 베타로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167296) 되었으며 [기능 플래그](../administration/feature_flags/_index.md)와 함께 `product_analytics_features`로 명명되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 프로덕션 사용을 위해 준비되지 않았습니다.

이 API를 사용하여 사용자 동작 및 애플리케이션 사용을 추적합니다.

> [!note]
> `cube_api_base_url` 및 `cube_api_key` 애플리케이션 설정을 먼저 [API](settings.md)를 사용하여 정의했는지 확인합니다.

## Cube 쿼리 요청 생성 {#create-a-cube-query-request}

Cube API에 쿼리 요청을 생성하고 액세스 토큰을 생성합니다.

```plaintext
POST /projects/:id/product_analytics/request/load
POST /projects/:id/product_analytics/request/dry-run
```

| 속성       | 유형             | 필수 | 설명                                                                                 |
|-----------------|------------------| -------- |---------------------------------------------------------------------------------------------|
| `id`            | 정수          | 예      | 현재 사용자가 읽기 액세스 권한이 있는 프로젝트의 ID입니다.                               |
| `include_token` | 부울          | 아니요       | 응답에 액세스 토큰을 포함할지 여부입니다. (깔때기 생성에만 필수입니다.) |

### 요청 본문 {#request-body}

로드 요청의 본문은 유효한 Cube 쿼리여야 합니다.

> [!note]
> `TrackedEvents`를 측정할 때는 `dimensions` 및 `timeDimensions`에 대해 `TrackedEvents.*`을(를) 사용해야 합니다. `Sessions`을(를) 측정할 때도 동일한 규칙이 적용됩니다.

#### 추적된 이벤트 예 {#tracked-events-example}

```json
{
  "query": {
    "measures": [
      "TrackedEvents.count"
    ],
    "timeDimensions": [
      {
        "dimension": "TrackedEvents.utcTime",
        "dateRange": "This week"
      }
    ],
    "order": [
      [
        "TrackedEvents.count",
        "desc"
      ],
      [
        "TrackedEvents.docPath",
        "desc"
      ],
      [
        "TrackedEvents.utcTime",
        "asc"
      ]
    ],
    "dimensions": [
      "TrackedEvents.docPath"
    ],
    "limit": 23
  },
  "queryType": "multi"
}
```

#### 세션 예 {#sessions-example}

```json
{
  "query": {
    "measures": [
      "Sessions.count"
    ],
    "timeDimensions": [
      {
        "dimension": "Sessions.startAt",
        "granularity": "day"
      }
    ],
    "order": {
      "Sessions.startAt": "asc"
    },
    "limit": 100
  },
  "queryType": "multi"
}
```

## Cube 메타데이터 검색 {#retrieve-cube-metadata}

분석 데이터에 대한 Cube 메타데이터를 검색합니다.

```plaintext
GET /projects/:id/product_analytics/request/meta
```

| 속성 | 유형             | 필수 | 설명                                                   |
| --------- |------------------| -------- |---------------------------------------------------------------|
| `id`      | 정수          | 예      | 현재 사용자가 읽기 액세스 권한이 있는 프로젝트의 ID입니다. |
