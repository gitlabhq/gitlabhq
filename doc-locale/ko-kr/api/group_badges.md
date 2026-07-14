---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 배지 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 그룹 배지와 상호작용합니다. 자세한 내용은 [그룹 배지](../user/project/badges.md#group-badges)를 참조하세요.

배지는 링크 및 이미지 URL 모두에서 실시간으로 대체되는 자리 표시자를 지원합니다. 다음 자리 표시자를 사용할 수 있습니다:

- `%{project_path}`: 프로젝트 경로로 대체됩니다.
- `%{project_title}`: 프로젝트 제목으로 대체됩니다.
- `%{project_name}`: 프로젝트 이름으로 대체됩니다.
- `%{project_id}`: 프로젝트 ID로 대체됩니다.
- `%{project_namespace}`: 프로젝트의 네임스페이스 전체 경로로 대체됩니다.
- `%{group_name}`: 프로젝트의 최상위 그룹 이름으로 대체됩니다.
- `%{gitlab_server}`: 프로젝트의 서버 이름으로 대체됩니다.
- `%{gitlab_pages_domain}`: GitLab Pages를 호스팅하는 도메인 이름으로 대체됩니다.
- `%{default_branch}`: 프로젝트 기본 브랜치로 대체됩니다.
- `%{commit_sha}`: 프로젝트의 마지막 커밋 SHA로 대체됩니다.
- `%{latest_tag}`: 프로젝트의 마지막 태그로 대체됩니다.

이러한 엔드포인트가 프로젝트의 컨텍스트 내에 있지 않으므로, 자리 표시자를 대체하는 데 사용되는 정보는 생성 날짜 기준으로 첫 번째 그룹의 프로젝트에서 가져옵니다. 그룹에 프로젝트가 없으면 자리 표시자가 있는 원본 URL이 반환됩니다.

## 모든 그룹 배지 나열 {#list-all-group-badges}

지정된 그룹의 배지를 나열합니다.

```plaintext
GET /groups/:id/badges
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `name`    | 문자열         | 아니요  | 반환할 배지의 이름(대소문자 구분)입니다. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges?name=Coverage"
```

응답 예시:

```json
[
  {
    "name": "Coverage",
    "id": 1,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  }
]
```

## 그룹 배지 검색 {#retrieve-a-group-badge}

지정된 그룹의 배지를 검색합니다.

```plaintext
GET /groups/:id/badges/:badge_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `badge_id` | 정수 | 예   | 배지 ID |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

응답 예시:

```json
{
  "name": "Coverage",
  "id": 1,
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## 그룹 배지 생성 {#create-a-group-badge}

지정된 그룹의 배지를 생성합니다.

```plaintext
POST /groups/:id/badges
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `link_url` | 문자열         | 예 | 배지 링크의 URL |
| `image_url` | 문자열 | 예 | 배지 이미지의 URL |
| `name` | 문자열 | 아니요 | 배지의 이름 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges" \
  --data "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/master&image_url=https://shields.io/my/badge1&name=mybadge&position=0"
```

응답 예시:

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge1",
  "kind": "group"
}
```

## 그룹 배지 업데이트 {#update-a-group-badge}

지정된 그룹의 배지를 업데이트합니다.

```plaintext
PUT /groups/:id/badges/:badge_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `badge_id` | 정수 | 예   | 배지 ID |
| `link_url` | 문자열         | 아니요 | 배지 링크의 URL |
| `image_url` | 문자열 | 아니요 | 배지 이미지의 URL |
| `name` | 문자열 | 아니요 | 배지의 이름 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

응답 예시:

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## 그룹 배지 삭제 {#delete-a-group-badge}

그룹에서 지정된 배지를 삭제합니다.

```plaintext
DELETE /groups/:id/badges/:badge_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `badge_id` | 정수 | 예   | 배지 ID |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

## 그룹 배지 미리 보기 검색 {#retrieve-a-group-badge-preview}

자리 표시자 보간을 확인한 후 지정된 그룹의 최종 `link_url` 및 `image_url` URL의 미리 보기를 검색합니다.

```plaintext
GET /groups/:id/badges/render
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `link_url` | 문자열         | 예 | 배지 링크의 URL|
| `image_url` | 문자열 | 예 | 배지 이미지의 URL |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge"
```

응답 예시:

```json
{
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
  "rendered_image_url": "https://shields.io/my/badge"
}
```
