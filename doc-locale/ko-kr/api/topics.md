---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 토픽 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

이 API를 사용하여 프로젝트 토픽과 상호작용합니다. 자세한 정보는 [프로젝트 토픽](../user/project/project_topics.md)을 참조하세요.

## 모든 토픽 나열 {#list-all-topics}

GitLab 인스턴스의 프로젝트 토픽 목록을 연결된 프로젝트 수로 정렬하여 반환합니다.

```plaintext
GET /topics
```

지원되는 속성:

| 속성          | 유형    | 필수               | 설명 |
| ------------------ | ------- | ---------------------- | ----------- |
| `page`             | 정수 | 아니요 | 검색할 페이지입니다. `1`로 기본값이 설정됩니다.                      |
| `per_page`         | 정수 | 아니요 | 페이지당 반환할 레코드 수입니다. `20`로 기본값이 설정됩니다. |
| `search`           | 문자열  | 아니요 | `name`에 대해 토픽을 검색합니다.                     |
| `without_projects` | 부울 | 아니요 | 할당된 프로젝트가 없는 토픽으로만 결과를 제한합니다.      |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/topics?search=git"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "gitlab",
    "title": "GitLab",
    "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
    "total_projects_count": 1000,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
  },
  {
    "id": 3,
    "name": "git",
    "title": "Git",
    "description": "Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.",
    "total_projects_count": 900,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
  },
  {
    "id": 2,
    "name": "git-lfs",
    "title": "Git LFS",
    "description": null,
    "total_projects_count": 300,
    "organization_id": 1,
    "avatar_url": null
  }
]
```

## 토픽 검색 {#retrieve-a-topic}

ID로 프로젝트 토픽을 검색합니다.

```plaintext
GET /topics/:id
```

지원되는 속성:

| 속성 | 유형    | 필수               | 설명         |
| --------- | ------- | ---------------------- | ------------------- |
| `id`      | 정수 | 예 | 프로젝트 토픽의 ID |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/topics/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "gitlab",
  "title": "GitLab",
  "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
  "total_projects_count": 1000,
  "organization_id": 1,
  "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
}
```

## 토픽에 할당된 모든 프로젝트 나열 {#list-all-projects-assigned-to-a-topic}

[프로젝트 API](projects.md#list-all-projects)를 사용하여 특정 토픽에 할당된 모든 프로젝트를 나열합니다.

```plaintext
GET /projects?topic=<topic_name>
```

## 프로젝트 토픽 생성 {#create-a-project-topic}

새 프로젝트 토픽을 생성합니다. 관리자만 사용할 수 있습니다.

```plaintext
POST /topics
```

지원되는 속성:

| 속성         | 유형    | 필수 | 설명                                                                                                                                                                                    |
|-------------------|---------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`            | 문자열  | 예      | 슬러그(이름)                                                                                                                                                                                    |
| `title`           | 문자열  | 예      | 제목                                                                                                                                                                                          |
| `avatar`          | 파일    | 아니요       | 아바타                                                                                                                                                                                         |
| `description`     | 문자열  | 아니요       | 설명                                                                                                                                                                                    |
| `organization_id` | 정수 | 아니요       | 토픽의 조직 ID입니다. 경고: 이 속성은 실험적이며 향후 변경될 수 있습니다. 조직에 대한 자세한 정보는 [조직 API](organizations.md)를 참조하세요. |

요청 예시:

```shell
curl --request POST \
    --data "name=topic1&title=Topic 1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics"
```

응답 예시:

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

## 프로젝트 토픽 업데이트 {#update-a-project-topic}

프로젝트 토픽을 업데이트합니다. 관리자만 사용할 수 있습니다.

```plaintext
PUT /topics/:id
```

지원되는 속성:

| 속성     | 유형    | 필수 | 설명         |
|---------------|---------|----------|---------------------|
| `id`          | 정수 | 예      | 프로젝트 토픽의 ID |
| `avatar`      | 파일    | 아니요       | 아바타              |
| `description` | 문자열  | 아니요       | 설명         |
| `name`        | 문자열  | 아니요       | 슬러그(이름)         |
| `title`       | 문자열  | 아니요       | 제목               |

요청 예시:

```shell
curl --request PUT \
    --data "name=topic1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

### 토픽 아바타 업로드 {#upload-a-topic-avatar}

파일 시스템에서 아바타 파일을 업로드하려면 `--form` 인수를 사용하세요. 이 인수는 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시하도록 합니다. `file=` 매개변수는 파일 시스템의 파일을 가리켜야 하며 `@`가 앞에 와야 합니다. 예를 들어:

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1" \
    --form "avatar=@/tmp/example.png"
```

### 토픽 아바타 제거 {#remove-a-topic-avatar}

토픽 아바타를 제거하려면 `avatar` 속성에 빈 값을 사용합니다.

요청 예시:

```shell
curl --request PUT \
    --data "avatar=" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## 프로젝트 토픽 삭제 {#delete-a-project-topic}

프로젝트 토픽을 삭제하려면 관리자여야 합니다. 프로젝트 토픽을 삭제하면 프로젝트의 토픽 할당도 삭제됩니다.

```plaintext
DELETE /topics/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id`      | 정수 | 예      | 프로젝트 토픽의 ID |

요청 예시:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## 토픽 병합 {#merge-topics}

소스 토픽을 대상 토픽으로 병합하려면 관리자여야 합니다. 토픽을 병합하면 소스 토픽을 삭제하고 할당된 모든 프로젝트를 대상 토픽으로 이동합니다.

```plaintext
POST /topics/merge
```

지원되는 속성:

| 속성         | 유형    | 필수 | 설명                |
|-------------------|---------|----------|----------------------------|
| `source_topic_id` | 정수 | 예      | 소스 프로젝트 토픽의 ID |
| `target_topic_id` | 정수 | 예      | 대상 프로젝트 토픽의 ID |

> [!note]
> `source_topic_id`와 `target_topic_id`는 동일한 조직에 속해야 합니다.

요청 예시:

```shell
curl --request POST \
    --data "source_topic_id=2&target_topic_id=1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/merge"
```

응답 예시:

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```
