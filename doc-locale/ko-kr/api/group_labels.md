---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 레이블 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `archived` 속성이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/4233) 되었으며 [플래그](../administration/feature_flags/_index.md)는 `labels_archive`입니다.
- GitLab 18.10에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/556700)합니다. 기능 플래그 `labels_archive` 제거됨.

{{< /history >}}

이 API를 사용하여 [그룹 레이블](../user/project/labels.md#types-of-labels)을 관리합니다.

프로젝트 레이블의 경우 [프로젝트 레이블 API](labels.md)를 사용합니다.

## 그룹 레이블 나열 {#list-group-labels}

주어진 그룹의 모든 레이블을 가져옵니다.

```plaintext
GET /groups/:id/labels
```

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.                                                               |
| `with_counts` | 부울        | 아니요       | 이슈 및 머지 리퀘스트 수를 포함할지 여부입니다. 기본값은 `false`. |
| `include_ancestor_groups` | 부울 | 아니요 | 상위 그룹을 포함합니다. 기본값은 `true`. |
| `include_descendant_groups` | 부울 | 아니요 | 하위 그룹을 포함합니다. 기본값은 `false`. |
| `only_group_labels` | 부울 | 아니요 | 그룹 레이블만 포함할지 또는 프로젝트 레이블도 포함할지 전환합니다. 기본값은 `true`. |
| `search` | 문자열 | 아니요 | 레이블을 필터링할 키워드입니다. |
| `archived` | 부울 | 아니요 | `true`인 경우 보관된 레이블만 반환합니다. 설정하지 않으면 모든 레이블을 반환합니다. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels?with_counts=true"
```

예시 응답:

```json
[
  {
    "id": 7,
    "name": "bug",
    "color": "#FF0000",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "archived": false
  },
  {
    "id": 4,
    "name": "feature",
    "color": "#228B22",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "archived": false
  }
]
```

## 단일 그룹 레이블 가져오기 {#get-a-single-group-label}

주어진 그룹의 단일 레이블을 가져옵니다.

```plaintext
GET /groups/:id/labels/:label_id
```

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.                                                               |
| `label_id` | 정수 또는 문자열 | 예 | 그룹의 레이블 ID 또는 제목입니다. |
| `include_ancestor_groups` | 부울 | 아니요 | 상위 그룹을 포함합니다. 기본값은 `true`. |
| `include_descendant_groups` | 부울 | 아니요 | 하위 그룹을 포함합니다. 기본값은 `false`. |
| `only_group_labels` | 부울 | 아니요 | 그룹 레이블만 포함할지 또는 프로젝트 레이블도 포함할지 전환합니다. 기본값은 `true`. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

예시 응답:

```json
{
  "id": 7,
  "name": "bug",
  "color": "#FF0000",
  "text_color" : "#FFFFFF",
  "description": null,
  "description_html": null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

## 새로운 그룹 레이블 생성 {#create-a-new-group-label}

주어진 그룹의 새로운 그룹 레이블을 생성합니다.

```plaintext
POST /groups/:id/labels
```

| 속성     | 유형    | 필수 | 설명                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `name`        | 문자열  | 예      | 레이블의 이름        |
| `color`       | 문자열  | 예      | 6자리 16진법 표기법(예: #FFAABB)으로 제공되는 레이블의 색상 또는 [CSS 색상 이름](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) 중 하나 |
| `description` | 문자열  | 아니요       | 레이블의 설명, |
| `archived`    | 부울 | 아니요       | `true`인 경우 레이블을 보관됨으로 표시합니다. 기본값: `false`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "Feature Proposal",
    "color": "#FFA500",
    "description": "Describes new ideas"
  }' \
  --url "https://gitlab.example.com/api/v4/groups/5/labels"
```

예시 응답:

```json
{
  "id": 9,
  "name": "Feature Proposal",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

## 그룹 레이블 업데이트 {#update-a-group-label}

기존 그룹 레이블을 업데이트합니다. 그룹 레이블을 업데이트하려면 최소한 하나의 매개변수가 필요합니다.

```plaintext
PUT /groups/:id/labels/:label_id
```

| 속성     | 유형    | 필수 | 설명                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예 | 그룹의 레이블 ID 또는 제목입니다. |
| `new_name`    | 문자열  | 아니요      | 레이블의 새로운 이름        |
| `color`       | 문자열  | 아니요      | 6자리 16진법 표기법(예: #FFAABB)으로 제공되는 레이블의 색상 또는 [CSS 색상 이름](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) 중 하나 |
| `description` | 문자열  | 아니요       | 레이블의 설명입니다. |
| `archived`    | 부울 | 아니요       | `true`인 경우 레이블을 보관됨으로 표시합니다. 기본값: `false`. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"new_name": "Feature Idea"}' \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/Feature%20Proposal"
```

예시 응답:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

> [!note]
> 이전 엔드포인트 `PUT /groups/:id/labels`는 `name`이 매개변수에 포함되어 있지만 여전히 사용 가능하며 더 이상 사용되지 않습니다.

## 그룹 레이블 삭제 {#delete-a-group-label}

주어진 이름의 그룹 레이블을 삭제합니다.

```plaintext
DELETE /groups/:id/labels/:label_id
```

| 속성 | 유형    | 필수 | 설명           |
| --------- | ------- | -------- | --------------------- |
| `id`      | 정수 또는 문자열    | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예 | 그룹의 레이블 ID 또는 제목입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

> [!note]
> 이전 엔드포인트 `DELETE /groups/:id/labels`는 `name`이 매개변수에 포함되어 있지만 여전히 사용 가능하며 더 이상 사용되지 않습니다.

## 그룹 레이블 구독 {#subscribe-to-a-group-label}

인증된 사용자를 그룹 레이블에 구독하여 알림을 받습니다. 사용자가 이미 레이블을 구독한 경우 상태 코드 `304`이 반환됩니다.

```plaintext
POST /groups/:id/labels/:label_id/subscribe
```

| 속성  | 유형              | 필수 | 설명                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 정수 또는 문자열    | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예      | 그룹의 레이블 ID 또는 제목입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/9/subscribe"
```

예시 응답:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": true,
  "archived": false
}
```

## 그룹 레이블 구독 해제 {#unsubscribe-from-a-group-label}

인증된 사용자를 그룹 레이블에서 구독 해제하여 알림을 받지 않습니다. 사용자가 레이블을 구독하지 않은 경우 상태 코드 `304`이 반환됩니다.

```plaintext
POST /groups/:id/labels/:label_id/unsubscribe
```

| 속성  | 유형              | 필수 | 설명                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 정수 또는 문자열    | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `label_id` | 정수 또는 문자열 | 예      | 그룹의 레이블 ID 또는 제목입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/9/unsubscribe"
```

예시 응답:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```
