---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 마일스톤 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [마일스톤](../user/project/milestones/_index.md)을 관리합니다.

그룹 마일스톤의 경우 [그룹 마일스톤 API](group_milestones.md)를 사용합니다.

## 모든 프로젝트 마일스톤 나열 {#list-all-project-milestones}

프로젝트의 모든 마일스톤을 나열합니다.

```plaintext
GET /projects/:id/milestones
GET /projects/:id/milestones?iids[]=42
GET /projects/:id/milestones?iids[]=42&iids[]=43
GET /projects/:id/milestones?state=active
GET /projects/:id/milestones?state=closed
GET /projects/:id/milestones?title=1.0
GET /projects/:id/milestones?search=version
GET /projects/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /projects/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
```

매개 변수:

| 속성                         | 유형   | 필수 | 설명 |
| ----------------------------      | ------ | -------- | ----------- |
| `id`                              | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `iids[]`                          | 정수 배열 | 아니요 | 주어진 `iid`을 가진 마일스톤만 반환합니다. `include_ancestors`이 `true`인 경우 무시됩니다.  |
| `state`                           | 문자열 | 아니요 | `active` 또는 `closed` 마일스톤만 반환합니다 |
| `title`                           | 문자열 | 아니요 | 주어진 `title`을 가진 마일스톤만 반환합니다 |
| `search`                          | 문자열 | 아니요 | 제공된 문자열과 일치하는 제목 또는 설명이 있는 마일스톤만 반환합니다 |
| `include_parent_milestones`       | 부울 | 아니요 | GitLab 16.7에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/433298). 대신 `include_ancestors`을 사용합니다. |
| `include_ancestors`               | 부울 | 아니요 | 모든 상위 그룹의 마일스톤을 포함합니다. |
| `updated_before`                  | 날짜 시간 | 아니요 | 주어진 날짜/시간 이전에 업데이트된 마일스톤만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. GitLab 15.10에서 도입됨 |
| `updated_after`                   | 날짜 시간 | 아니요 | 주어진 날짜/시간 이후에 업데이트된 마일스톤만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. GitLab 15.10에서 도입됨 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/milestones"
```

응답 예시:

```json
[
  {
    "id": 12,
    "iid": 3,
    "project_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z",
    "expired": false
  }
]
```

## 마일스톤 검색 {#retrieve-a-milestone}

지정된 프로젝트 마일스톤을 검색합니다.

```plaintext
GET /projects/:id/milestones/:milestone_id
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수        | 예      | 프로젝트 마일스톤의 ID                                                                               |

## 마일스톤 생성 {#create-a-milestone}

프로젝트 마일스톤을 생성합니다.

```plaintext
POST /projects/:id/milestones
```

매개 변수:

| 속성     | 유형           | 필수 | 설명                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `title`       | 문자열         | 예      | 마일스톤의 제목                                                                                        |
| `description` | 문자열         | 아니요       | 마일스톤의 설명                                                                                |
| `due_date`    | 문자열         | 아니요       | 마일스톤의 마감일(`YYYY-MM-DD`)                                                                    |
| `start_date`  | 문자열         | 아니요       | 마일스톤의 시작일(`YYYY-MM-DD`)                                                                  |

## 마일스톤 업데이트 {#update-a-milestone}

지정된 프로젝트 마일스톤을 업데이트합니다.

```plaintext
PUT /projects/:id/milestones/:milestone_id
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수        | 예      | 프로젝트 마일스톤의 ID                                                                               |
| `title`        | 문자열         | 아니요       | 마일스톤의 제목                                                                                        |
| `description`  | 문자열         | 아니요       | 마일스톤의 설명                                                                                |
| `due_date`     | 문자열         | 아니요       | 마일스톤의 마감일(`YYYY-MM-DD`)                                                                    |
| `start_date`   | 문자열         | 아니요       | 마일스톤의 시작일(`YYYY-MM-DD`)                                                                  |
| `state_event`  | 문자열         | 아니요       | 마일스톤의 상태 이벤트(종료 또는 활성화)                                                            |

## 마일스톤 삭제 {#delete-a-milestone}

{{< history >}}

- GitLab 15.0에서 최소 사용자 역할이 Developer에서 Reporter로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/343889)되었습니다.
- GitLab 17.7에서 최소 사용자 역할이 Reporter에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

지정된 프로젝트 마일스톤을 삭제합니다.

프로젝트에 대해 플래너, Reporter, Developer, Maintainer 또는 Owner 역할을 가진 사용자만 사용할 수 있습니다.

```plaintext
DELETE /projects/:id/milestones/:milestone_id
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수        | 예      | 프로젝트 마일스톤의 ID                                                                               |

## 이슈에 대한 모든 마일스톤 나열 {#list-all-issues-for-a-milestone}

지정된 프로젝트 마일스톤에 할당된 모든 이슈를 나열합니다.

```plaintext
GET /projects/:id/milestones/:milestone_id/issues
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수        | 예      | 프로젝트 마일스톤의 ID                                                                               |

## 마일스톤에 대한 모든 머지 리퀘스트 나열 {#list-all-merge-requests-for-a-milestone}

지정된 프로젝트 마일스톤에 할당된 모든 머지 리퀘스트를 나열합니다.

```plaintext
GET /projects/:id/milestones/:milestone_id/merge_requests
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수        | 예      | 프로젝트 마일스톤의 ID                                                                               |

## 마일스톤을 그룹 마일스톤으로 승격 {#promote-a-milestone-to-group-milestone}

{{< history >}}

- GitLab 15.0에서 최소 사용자 역할이 Developer에서 Reporter로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/343889)되었습니다.
- GitLab 17.7에서 최소 사용자 역할이 Reporter에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

프로젝트 마일스톤을 그룹 마일스톤으로 승격합니다.

그룹에 대해 플래너, Reporter, Developer, Maintainer 또는 Owner 역할을 가진 사용자만 사용할 수 있습니다.

```plaintext
POST /projects/:id/milestones/:milestone_id/promote
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수        | 예      | 프로젝트 마일스톤의 ID                                                                               |

## 마일스톤에 대한 모든 번다운 차트 이벤트 나열 {#list-all-burndown-chart-events-for-a-milestone}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 마일스톤에 대한 모든 번다운 차트 이벤트를 나열합니다.

```plaintext
GET /projects/:id/milestones/:milestone_id/burndown_events
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수        | 예      | 프로젝트 마일스톤의 ID                                                                               |
