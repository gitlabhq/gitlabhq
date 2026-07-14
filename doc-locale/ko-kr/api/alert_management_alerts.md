---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 알림 관리 알림 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [알림](../operations/incident_management/alerts.md)의 메트릭 이미지와 상호 작용합니다.

[GraphQL API](graphql/reference/_index.md#alertmanagementalert)를 사용하여 추가 엔드포인트를 사용할 수 있습니다.

## 메트릭 이미지 업로드 {#upload-metric-image}

지정된 알림에 대해 메트릭 이미지를 업로드합니다.

```plaintext
POST /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `alert_iid` | 정수        | 예      | 프로젝트 알림의 내부 ID입니다. |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --form 'file=@/path/to/file.png' \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

응답 예시:

```json
{
  "id":17,
  "created_at":"2020-11-12T20:07:58.156Z",
  "filename":"sample_2054",
  "file_path":"/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
  "url":"https://example.com/metric",
  "url_text":"An example metric"
}
```

## 모든 메트릭 이미지 나열 {#list-all-metric-images}

지정된 알림의 모든 메트릭 이미지를 나열합니다.

```plaintext
GET /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `alert_iid` | 정수        | 예      | 프로젝트 알림의 내부 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

응답 예시:

```json
[
  {
    "id":17,
    "created_at":"2020-11-12T20:07:58.156Z",
    "filename":"sample_2054",
    "file_path":"/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
    "url":"https://example.com/metric",
    "url_text":"An example metric"
  },
  {
    "id":18,
    "created_at":"2020-11-12T20:14:26.441Z",
    "filename":"sample_2054",
    "file_path":"/uploads/-/system/alert_metric_image/file/18/sample_2054.png",
    "url":"https://example.com/metric",
    "url_text":"An example metric"
  }
]
```

## 메트릭 이미지 업데이트 {#update-a-metric-image}

알림에 대해 지정된 메트릭 이미지를 업데이트합니다.

```plaintext
PUT /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `alert_iid` | 정수        | 예      | 프로젝트 알림의 내부 ID입니다. |
| `image_id`  | 정수        | 예      | 이미지의 ID입니다. |
| `url`       | 문자열         | 아니요       | 메트릭 정보를 확인할 URL입니다. |
| `url_text`  | 문자열         | 아니요       | 이미지 또는 URL의 설명입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request PUT  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

응답 예시:

```json
{
  "id":23,
  "created_at":"2020-11-13T00:06:18.084Z",
  "filename":"file.png",
  "file_path":"/uploads/-/system/alert_metric_image/file/23/file.png",
  "url":"https://example.com/metric",
  "url_text":"An example metric"
}
```

## 메트릭 이미지 삭제 {#delete-a-metric-image}

알림에 대해 지정된 메트릭 이미지를 삭제합니다.

```plaintext
DELETE /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `alert_iid` | 정수        | 예      | 프로젝트 알림의 내부 ID입니다. |
| `image_id`  | 정수        | 예      | 이미지의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url  "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

다음 상태 코드를 반환할 수 있습니다:

- `204 No Content`: 이미지가 성공적으로 삭제된 경우입니다.
- `422 Unprocessable`: 이미지를 삭제할 수 없는 경우입니다.
