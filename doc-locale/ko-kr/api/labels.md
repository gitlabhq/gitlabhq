---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 레이블 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `archived` 속성이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/4233) 되었으며 [플래그](../administration/feature_flags/_index.md)는 `labels_archive`입니다.
- GitLab 18.10에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/556700)합니다. 기능 플래그 `labels_archive` 제거됨.

{{< /history >}}

이 API를 사용하여 [프로젝트 레이블](../user/project/labels.md)을 관리합니다.

그룹 레이블의 경우 [그룹 레이블 API](group_labels.md)를 사용합니다.

## 모든 프로젝트 레이블 나열 {#list-all-project-labels}

지정된 프로젝트의 모든 레이블을 나열합니다.

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

```plaintext
GET /projects/:id/labels
```

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                                                              |
| `with_counts` | 부울        | 아니요       | 이슈 및 머지 리퀘스트 수를 포함할지 여부 `false`로 기본값이 설정됩니다. |
| `include_ancestor_groups` | 부울 | 아니요 | 상위 그룹을 포함합니다. `true`로 기본값이 설정됩니다. |
| `search` | 문자열 | 아니요 | 레이블을 필터링할 키워드입니다. |
| `archived` | 부울 | 아니요 | `true`이면 보관된 레이블만 반환합니다. 설정되지 않으면 모든 레이블을 반환합니다. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels?with_counts=true"
```

응답 예시:

```json
[
  {
    "id" : 1,
    "name" : "bug",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Bug reported by user",
    "description_html": "Bug reported by user",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": 10,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 4,
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "name" : "confirmed",
    "description": "Confirmed issue",
    "description_html": "Confirmed issue",
    "open_issues_count": 2,
    "closed_issues_count": 5,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 7,
    "name" : "critical",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Critical issue. Need fix ASAP",
    "description_html": "Critical issue. Need fix ASAP",
    "open_issues_count": 1,
    "closed_issues_count": 3,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 8,
    "name" : "documentation",
    "color" : "#f0ad4e",
    "text_color" : "#FFFFFF",
    "description": "Issue about documentation",
    "description_html": "Issue about documentation",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 2,
    "subscribed": false,
    "priority": null,
    "is_project_label": false,
    "archived": false
  },
  {
    "id" : 9,
    "color" : "#5cb85c",
    "text_color" : "#FFFFFF",
    "name" : "enhancement",
    "description": "Enhancement proposal",
    "description_html": "Enhancement proposal",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": true,
    "priority": null,
    "is_project_label": true,
    "archived": false
  }
]
```

## 프로젝트 레이블 검색 {#retrieve-a-project-label}

프로젝트의 지정된 레이블을 검색합니다.

```plaintext
GET /projects/:id/labels/:label_id
```

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                                                              |
| `label_id` | 정수 또는 문자열 | 예 | 프로젝트 레이블의 ID 또는 제목입니다. |
| `include_ancestor_groups` | 부울 | 아니요 | 상위 그룹을 포함합니다. `true`로 기본값이 설정됩니다. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

응답 예시:

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": false,
  "priority": 10,
  "is_project_label": true,
  "archived": false
}
```

## 프로젝트 레이블 생성 {#create-a-project-label}

지정된 이름과 색상으로 지정된 프로젝트에 대한 레이블을 생성합니다.

```plaintext
POST /projects/:id/labels
```

| 속성     | 유형    | 필수 | 설명                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | 정수 또는 문자열    | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `name`        | 문자열  | 예      | 레이블의 이름        |
| `color`       | 문자열  | 예      | 6자리 16진수 표기법으로 주어진 레이블의 색상(예: #FFAABB) 또는 [CSS 색상 이름](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) 중 하나 |
| `description` | 문자열  | 아니요       | 레이블의 설명 |
| `priority`    | 정수 | 아니요       | 레이블의 우선순위입니다. 0 이상이거나 우선순위를 제거하려면 `null`이어야 합니다. |
| `archived`    | 부울 | 아니요       | `true`이면 레이블을 보관됨으로 표시합니다. 기본값: `false`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels" \
  --data "name=feature&color=#5843AD"
```

응답 예시:

```json
{
  "id" : 10,
  "name" : "feature",
  "color" : "#5843AD",
  "text_color" : "#FFFFFF",
  "description":null,
  "description_html":null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## 프로젝트 레이블 삭제 {#delete-a-project-label}

프로젝트에서 지정된 레이블을 삭제합니다.

```plaintext
DELETE /projects/:id/labels/:label_id
```

| 속성 | 유형    | 필수 | 설명           |
| --------- | ------- | -------- | --------------------- |
| `id`            | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예 | 프로젝트 레이블의 ID 또는 제목입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

> [!note]
> 더 이상 사용되지 않는 엔드포인트 `DELETE /projects/:id/labels`이 매개변수에서 `name`과 함께 계속 사용할 수 있습니다.

## 프로젝트 레이블 업데이트 {#update-a-project-label}

프로젝트의 지정된 레이블을 새 이름 또는 색상으로 업데이트합니다. 레이블을 업데이트하려면 최소 하나의 매개변수가 필요합니다.

```plaintext
PUT /projects/:id/labels/:label_id
```

| 속성       | 유형    | 필수                          | 설명                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | 정수 또는 문자열    | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예 | 프로젝트 레이블의 ID 또는 제목입니다. |
| `new_name`      | 문자열  | `color`이 제공되지 않으면 예    | 레이블의 새 이름        |
| `color`         | 문자열  | `new_name`이 제공되지 않으면 예 | 6자리 16진수 표기법으로 주어진 레이블의 색상(예: #FFAABB) 또는 [CSS 색상 이름](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) 중 하나 |
| `description`   | 문자열  | 아니요                                | 레이블의 새 설명 |
| `priority`    | 정수 | 아니요       | 레이블의 새 우선순위입니다. 0 이상이거나 우선순위를 제거하려면 `null`이어야 합니다. |
| `archived`    | 부울 | 아니요       | `true`이면 레이블을 보관됨으로 표시합니다. 기본값: `false`. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation" \
  --data "new_name=docs&color=#8E44AD&description=Documentation"
```

응답 예시:

```json
{
  "id" : 8,
  "name" : "docs",
  "color" : "#8E44AD",
  "text_color" : "#FFFFFF",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

> [!note]
> 더 이상 사용되지 않는 엔드포인트 `PUT /projects/:id/labels`이 매개변수에서 `name` 또는 `label_id`과 함께 계속 사용할 수 있습니다.

## 프로젝트 레이블을 그룹 레이블로 승격 {#promote-a-project-label-to-a-group-label}

지정된 프로젝트 레이블을 그룹 레이블로 승격합니다. 레이블은 ID를 유지합니다.

```plaintext
PUT /projects/:id/labels/:label_id/promote
```

| 속성       | 유형    | 필수                          | 설명                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | 정수 또는 문자열    | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예 | 프로젝트 레이블의 ID 또는 제목입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation/promote"
```

응답 예시:

```json
{
  "id" : 8,
  "name" : "documentation",
  "color" : "#8E44AD",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "archived": false
}
```

> [!note]
> 더 이상 사용되지 않는 엔드포인트 `PUT /projects/:id/labels/promote`이 매개변수에서 `name`과 함께 계속 사용할 수 있습니다.

## 프로젝트 레이블 구독 {#subscribe-to-a-project-label}

인증된 사용자가 지정된 프로젝트 레이블을 구독하여 알림을 받습니다. 사용자가 이미 레이블을 구독하고 있으면 상태 코드 `304`이 반환됩니다.

```plaintext
POST /projects/:id/labels/:label_id/subscribe
```

| 속성  | 유형              | 필수 | 설명                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 정수 또는 문자열    | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예      | 프로젝트 레이블의 ID 또는 제목 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/subscribe"
```

응답 예시:

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": true,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## 프로젝트 레이블 구독 취소 {#unsubscribe-from-a-project-label}

인증된 사용자가 지정된 프로젝트 레이블의 구독을 취소하여 알림을 더 이상 받지 않습니다. 사용자가 레이블을 구독하지 않고 있으면 상태 코드 `304`이 반환됩니다.

```plaintext
POST /projects/:id/labels/:label_id/unsubscribe
```

| 속성  | 유형              | 필수 | 설명                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 정수 또는 문자열    | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예      | 프로젝트 레이블의 ID 또는 제목 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/unsubscribe"
```
