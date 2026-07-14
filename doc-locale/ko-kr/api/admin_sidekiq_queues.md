---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiq 큐 관리 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Sidekiq 큐에서 작업 삭제하기 {#delete-jobs-from-a-sidekiq-queue}

주어진 메타데이터와 일치하는 Sidekiq 큐에서 작업을 삭제합니다.

응답에는 세 가지 필드가 있습니다:

1. `deleted_jobs` - 요청으로 삭제된 작업의 수입니다.
1. `queue_size` - 요청을 처리한 후 큐의 나머지 크기입니다.
1. `completed` - 요청이 지정된 시간 내에 전체 큐를 처리할 수 있었는지 여부입니다. 그렇지 않은 경우, 동일한 매개변수를 사용하여 재시도하면 추가 작업을 삭제할 수 있습니다(첫 번째 요청이 발행된 후 추가된 작업 포함).

이 API 엔드포인트는 관리자만 사용할 수 있습니다.

```plaintext
DELETE /admin/sidekiq/queues/:queue_name
```

| 속성           | 유형   | 필수 | 설명 |
|---------------------|--------|----------|-------------|
| `queue_name`        | 문자열 | 예      | 작업을 삭제할 큐의 이름 |
| `user`              | 문자열 | 아니요       | 작업을 예약한 사용자의 사용자 이름 |
| `project`           | 문자열 | 아니요       | 작업이 예약된 프로젝트의 전체 경로 |
| `root_namespace`    | 문자열 | 아니요       | 프로젝트의 루트 네임스페이스 |
| `subscription_plan` | 문자열 | 아니요       | 루트 네임스페이스의 구독 계획(GitLab.com만 해당) |
| `caller_id`         | 문자열 | 아니요       | 작업을 예약한 엔드포인트 또는 백그라운드 작업(예: `ProjectsController#create`, `/api/:version/projects/:id`, `PostReceive`) |
| `feature_category`  | 문자열 | 아니요       | 백그라운드 작업의 기능 카테고리(예: `team_planning` 또는 `code_review`) |
| `worker_class`      | 문자열 | 아니요       | 백그라운드 작업 워커의 클래스(예: `PostReceive` 또는 `MergeWorker`) |

`queue_name`을 제외한 최소 하나의 속성이 필요합니다.

요청 예시:

```shell
curl --request DELETE \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/admin/sidekiq/queues/:queue_name"
```

응답 예시:

```json
{
  "completed": true,
  "deleted_jobs": 7,
  "queue_size": 14
}
```
