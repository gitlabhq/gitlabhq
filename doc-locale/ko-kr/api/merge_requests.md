---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 머지 리퀘스트에 대한 REST API 문서입니다.
title: 머지 리퀘스트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

<!-- Do not remove these outdated lines until the changes are actually implemented in the API -->

{{< history >}}

- `reference` [GitLab 12.7에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354).
- `merged_by` [GitLab 14.7에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/350534).
- `merge_status` [GitLab 15.6에서 지원 중단되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) `detailed_merge_status` 대신 사용합니다.
- `with_merge_status_recheck` [GitLab 15.11에서 변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115948) [플래그](../administration/feature_flags/_index.md) `restrict_merge_status_recheck` 이름으로 권한이 부족한 사용자의 요청에서 무시되도록 합니다. 기본적으로 비활성화됨.
- `approvals_before_merge` [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119503).
- `prepared_at` [GitLab 16.1에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122001).
- `merge_user_id` [GitLab 17.0에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002).
- `merge_user_username` [GitLab 17.0에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002).
- `merged_at` 값 `order_by` [GitLab 17.2에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052).
- `merge_after` [GitLab 17.5에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165092).
- `security_policy_violations` [GitLab 18.4에서 일반적으로 이용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/473704). 기능 플래그 `policy_mergability_check` 제거됨.
- `draft` 필터 매개변수 [GitLab 19.0에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098).
- `wip` 필터 매개변수 [GitLab 19.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098).

{{< /history >}}

이 API를 사용하여 [머지 리퀘스트](../user/project/merge_requests/_index.md)를 관리합니다. 다음을 수행할 수 있습니다.

- 코드 검토 프로세스의 모든 부분을 자동화합니다.
- 코드 변경 사항을 외부 도구에 연결합니다.
- 머지 리퀘스트 정보를 원하는 형식으로 비GitLab 시스템에 보냅니다.
- 외부 시스템의 데이터를 기반으로 머지 리퀘스트를 업데이트, 승인, 병합 또는 차단합니다.

공개되지 않은 정보에 대한 모든 API 호출은 인증이 필요합니다.

## API v5에서 제거됨 {#removals-in-api-v5}

`approvals_before_merge` 속성은 지원 중단되었으며, [API v5에서 제거될 예정입니다](rest/deprecations.md) [머지 리퀘스트 승인 API](merge_request_approvals.md) 대신 사용합니다.

## 머지 리퀘스트 나열 {#list-merge-requests}

인증된 사용자가 액세스할 수 있는 모든 머지 리퀘스트를 나열합니다. 기본적으로 현재 사용자가 생성한 머지 리퀘스트만 반환합니다. `scope=all`을 사용하여 모든 머지 리퀘스트를 검색합니다.

`state` 매개변수를 사용하여 주어진 상태의 머지 리퀘스트만 가져옵니다(`opened`, `closed`, `locked` 또는 `merged`) 또는 모든 상태(`all`). `locked`로 검색하면 해당 상태가 단기이고 임시이므로 일반적으로 결과가 반환되지 않습니다. 페이지 매김 매개변수 `page`과 `per_page`를 사용하여 머지 리퀘스트 목록을 제한합니다.

```plaintext
GET /merge_requests
GET /merge_requests?state=opened
GET /merge_requests?state=all
GET /merge_requests?milestone=release
GET /merge_requests?labels=bug,reproduced
GET /merge_requests?author_id=5
GET /merge_requests?author_username=gitlab-bot
GET /merge_requests?my_reaction_emoji=star
GET /merge_requests?scope=assigned_to_me
GET /merge_requests?scope=reviews_for_me
GET /merge_requests?search=foo&in=title
```

지원되는 속성:

| 속성                   | 유형          | 필수 | 설명 |
|-----------------------------|---------------|----------|-------------|
| `approved_by_ids[]`         | 정수 배열 | 아니요       | 주어진 `id`을 가진 모든 사용자의 승인을 받은 머지 리퀘스트를 반환합니다(최대 5명). `None`는 승인되지 않은 머지 리퀘스트를 반환합니다. `Any`은 승인된 머지 리퀘스트를 반환합니다. |
| `approved_by_usernames[]`   | 문자열 배열  | 아니요       | 주어진 `username`을 가진 모든 사용자의 승인을 받은 머지 리퀘스트를 반환합니다(최대 5명). `None`는 승인되지 않은 머지 리퀘스트를 반환합니다. `Any`은 승인된 머지 리퀘스트를 반환합니다. |
| `approver_ids[]`            | 정수 배열 | 아니요       | 승인 규칙에 따라 지정된 `id`을 가진 모든 사용자가 적격 승인자인 머지 리퀴스트를 반환합니다. `None`는 적격 승인자가 없는 머지 리퀘스트를 반환합니다. `Any`은 최소 한 명 이상의 적격 승인자가 있는 머지 리퀘스트를 반환합니다. Premium 및 Ultimate만 해당합니다. |
| `assignee_id`               | 정수 또는 문자열 | 아니요   | 주어진 사용자 `id`에게 할당된 머지 리퀘스트를 반환합니다. `None`는 할당되지 않은 머지 리퀘스트를 반환합니다. `Any`은 담당자가 있는 머지 리퀘스트를 반환합니다. `assignee_username`과 상호 배타적입니다. |
| `assignee_username[]`       | 문자열 배열  | 아니요       | 주어진 사용자 이름에 할당된 머지 리퀘스트를 반환합니다. `assignee_id`과 상호 배타적입니다. |
| `author_id`                 | 정수       | 아니요       | 주어진 사용자 `id`이 생성한 머지 리퀘스트를 반환합니다. `author_username`과 상호 배타적입니다. `scope=all` 또는 `scope=assigned_to_me`과 결합합니다. |
| `author_username`           | 문자열        | 아니요       | 주어진 `username`이 생성한 머지 리퀘스트를 반환합니다. `author_id`과 상호 배타적입니다. |
| `created_after`             | 날짜/시간      | 아니요       | 주어진 날짜 및 시간 이후에 생성된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before`            | 날짜/시간      | 아니요       | 주어진 날짜 및 시간 이전에 생성된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `deployed_after`            | 날짜/시간      | 아니요       | 주어진 날짜/시간 이후에 배포된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `deployed_before`           | 날짜/시간      | 아니요       | 주어진 날짜/시간 이전에 배포된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `environment`               | 문자열        | 아니요       | 주어진 환경에 배포된 머지 리퀘스트를 반환합니다. |
| `in`                        | 문자열        | 아니요       | `search` 속성의 범위를 변경합니다. `title`, `description` 또는 쉼표로 결합한 문자열입니다. 기본값은 `title,description`입니다. |
| `labels`                    | 문자열        | 아니요       | 쉼표로 구분된 레이블 목록과 일치하는 머지 리퀘스트를 반환합니다. `None`은 레이블이 없는 모든 머지 리퀘스트를 나열합니다. `Any`는 최소 하나 이상의 레이블을 가진 모든 머지 리퀘스트를 나열합니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다. |
| `merge_user_id`             | 정수       | 아니요       | 주어진 사용자 `id`이 병합한 머지 리퀘스트를 반환합니다. `merge_user_username`과 상호 배타적입니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002). |
| `merge_user_username`       | 문자열        | 아니요       | 주어진 `username`이 병합한 머지 리퀘스트를 반환합니다. `merge_user_id`과 상호 배타적입니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002). |
| `milestone`                 | 문자열        | 아니요       | 특정 마일스톤의 머지 리퀘스트를 반환합니다. `None`는 마일스톤이 없는 머지 리퀘스트를 반환합니다. `Any`는 할당된 마일스톤이 있는 머지 리퀘스트를 반환합니다. |
| `my_reaction_emoji`         | 문자열        | 아니요       | 인증된 사용자가 주어진 `emoji`으로 반응한 머지 리퀘스트를 반환합니다. `None`는 반응이 지정되지 않은 이슈를 반환합니다. `Any`는 최소 하나 이상의 반응이 지정된 이슈를 반환합니다. |
| `non_archived`              | 부울       | 아니요       | `true`이면 보관되지 않은 프로젝트의 머지 리퀘스트만 반환합니다. 기본값은 `false`입니다. |
| `not`                       | 해시          | 아니요       | 제공된 매개변수와 일치하지 않는 머지 리퀘스트를 반환합니다. 수락: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                  | 문자열        | 아니요       | `created_at`, `updated_at`, `merged_at` ([GitLab 17.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)), `label_priority`, `priority`, `milestone_due`, `popularity` 또는 `title` 필드로 정렬된 머지 리퀘스트를 반환합니다. 기본값은 `created_at`입니다. |
| `reviewer_id`               | 정수 또는 문자열 | 아니요   | 주어진 사용자 `id`를 [검토자](../user/project/merge_requests/reviews/_index.md)로 하는 머지 리퀘스트를 반환합니다. `None`은 검토자가 없는 머지 리퀘스트를 반환합니다. `Any`은 모든 검토자가 있는 머지 리퀘스트를 반환합니다. `reviewer_username`과 상호 배타적입니다. |
| `reviewer_username`         | 문자열        | 아니요       | 주어진 `username`를 [검토자](../user/project/merge_requests/reviews/_index.md)로 하는 머지 리퀘스트를 반환합니다. `None`은 검토자가 없는 머지 리퀘스트를 반환합니다. `Any`은 모든 검토자가 있는 머지 리퀘스트를 반환합니다. `reviewer_id`과 상호 배타적입니다. |
| `scope`                     | 문자열        | 아니요       | 주어진 범위의 머지 리퀘스트를 반환합니다: `created_by_me`, `assigned_to_me`, `reviews_for_me` 또는 `all`. `reviews_for_me`는 현재 사용자가 검토자로 할당된 머지 리퀘스트를 반환합니다. `created_by_me`로 기본값이 설정됩니다. |
| `search`                    | 문자열        | 아니요       | `title` 및 `description`에 대해 머지 리퀘스트를 검색합니다. `in` 속성과 결합합니다. |
| `sort`                      | 문자열        | 아니요       | `asc` 또는 `desc` 순서로 정렬된 머지 리퀘스트를 반환합니다. 기본값은 `desc`입니다. |
| `source_branch`             | 문자열        | 아니요       | 주어진 소스 브랜치의 머지 리퀘스트를 반환합니다. |
| `state`                     | 문자열        | 아니요       | 모든 머지 리퀘스트(`all`) 또는 `opened`, `closed`, `locked` 또는 `merged`인 머지 리퀘스트만 반환합니다. `all`로 기본값이 설정됩니다. |
| `target_branch`             | 문자열        | 아니요       | 주어진 대상 브랜치의 머지 리퀘스트를 반환합니다. |
| `updated_after`             | 날짜/시간      | 아니요       | 주어진 날짜 및 시간 이후에 업데이트된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `updated_before`            | 날짜/시간      | 아니요       | 주어진 날짜 및 시간 이전에 업데이트된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `view`                      | 문자열        | 아니요       | `simple`이면 `iid`, URL, 제목, 설명 및 머지 리퀘스트의 기본 상태를 반환합니다. |
| `draft`                         | 부울        | 아니요       | 머지 리퀘스트의 `draft` 상태로 필터링합니다. `true`는 초안 머지 리퀘스트만 반환하고, `false`은 초안이 아닌 머지 리퀘스트를 반환합니다. `wip`과 상호 배타적입니다. |
| `wip`                           | 문자열         | 아니요       | [GitLab 19.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098). `draft` 대신 사용합니다. 머지 리퀘스트의 `wip` 상태로 필터링합니다. `yes`는 초안 머지 리퀘스트만 반환하고, `no`은 초안이 아닌 머지 리퀘스트를 반환합니다. |
| `with_labels_details`       | 부울       | 아니요       | `true`이면 응답은 labels 필드의 각 레이블에 대한 더 많은 세부 정보를 반환합니다: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. 기본값은 `false`입니다. |
| `with_merge_status_recheck` | 부울       | 아니요       | `true`이면 이 프로젝션은 `merge_status` 필드의 비동기 재계산을 요청(보장하지는 않음)합니다. `restrict_merge_status_recheck` [기능 플래그](../administration/feature_flags/_index.md)를 활성화하여 Developer, Maintainer 또는 Owner 역할이 없는 사용자가 요청할 때 이 속성을 무시합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환합니다. `view`이 `simple`로 설정되면 필드의 하위 집합을 반환합니다. 그렇지 않으면 응답 속성에는 다음이 포함됩니다:

| 속성                                | 유형     | 설명 |
|------------------------------------------|----------|-------------|
| `allow_collaboration`                    | 부울  | `true`이면 이 포크는 대상 브랜치로 병합할 수 있는 멤버 간의 협업을 허용합니다. 포크의 머지 리퀘스트에만 사용됩니다. |
| `allow_maintainer_to_push`               | 부울  | 지원 중단됨. `allow_collaboration` 대신 사용합니다. |
| `approvals_before_merge`                 | 정수  | [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). 승인 규칙을 구성하려면 대신 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. GitLab Premium 및 Ultimate만 해당합니다. |
| `assignee[]`                             | 객체   | 지원 중단됨. `assignees` 대신 사용합니다. |
| `assignees[]`                            | 배열    | 머지 리퀘스트에 할당된 사용자입니다. |
| `assignees.avatar_url`                   | 문자열   | 담당자의 아바타 이미지에 대한 전체 URL입니다. |
| `assignees.id`                           | 정수  | 담당자의 고유 ID입니다. |
| `assignees.locked`                       | 부울  | `true`이면 담당자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `assignees.name`                         | 문자열   | 담당자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `assignees.public_email`                 | 문자열   | 담당자의 공개 이메일 주소입니다. |
| `assignees.state`                        | 문자열   | 담당자 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `assignees.username`                     | 문자열   | 머지 리퀘스트 담당자의 사용자 이름입니다. |
| `assignees.web_url`                      | 문자열   | 담당자 프로필 페이지에 대한 전체 URL입니다. |
| `author[]`                               | 객체   | 머지 리퀘스트를 생성한 사용자에 대한 정보가 포함된 객체입니다. |
| `author.avatar_url`                      | 문자열   | 작성자의 아바타 이미지에 대한 전체 URL입니다. |
| `author.id`                              | 정수  | 머지 리퀘스트를 생성한 사용자의 고유 ID입니다. |
| `author.locked`                          | 부울  | `true`이면 작성자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `author.name`                            | 문자열   | 작성자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `author.public_email`                    | 문자열   | 작성자의 공개 이메일 주소입니다. |
| `author.state`                           | 문자열   | 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `author.username`                        | 문자열   | 머지 리퀘스트 작성자의 사용자 이름입니다. |
| `author.web_url`                         | 문자열   | 작성자 프로필 페이지에 대한 전체 URL입니다. |
| `blocking_discussions_resolved`          | 부울  | `true`이면 머지 리퀘스트가 병합되기 전에 모든 스레드를 해결해야 합니다. |
| `closed_at`                              | 날짜시간 | 머지 리퀘스트를 닫을 때의 타임스탬프입니다. |
| `closed_by[]`                            | 객체   | 머지 리퀘스트를 닫은 사용자에 대한 정보가 포함된 객체입니다. `null`이면 머지 리퀘스트가 열려 있습니다. |
| `closed_by.avatar_url`                   | 문자열   | 닫은 사용자의 아바타 이미지에 대한 전체 URL입니다. |
| `closed_by.id`                           | 정수  | 머지 리퀘스트를 닫은 사용자의 고유 ID입니다. |
| `closed_by.locked`                       | 부울  | `true`이면 닫은 사용자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `closed_by.name`                         | 문자열   | 닫은 사용자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `closed_by.public_email`                 | 문자열   | 닫은 사용자의 공개 이메일 주소입니다. |
| `closed_by.state`                        | 문자열   | 닫은 사용자의 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `closed_by.username`                     | 문자열   | 머지 리퀘스트를 닫은 사용자의 사용자 이름입니다. |
| `closed_by.web_url`                      | 문자열   | 닫은 사용자의 프로필 페이지에 대한 전체 URL입니다. |
| `created_at`                             | 날짜시간 | 머지 리퀘스트를 생성할 때의 타임스탬프입니다. |
| `description`                            | 문자열   | 머지 리퀘스트의 설명입니다. 캐싱을 위해 HTML로 렌더링된 Markdown이 포함되어 있습니다. |
| `description_html`                       | 문자열   | `render_html`이 설정되면 설명의 렌더링된 HTML 버전입니다. |
| `detailed_merge_status`                  | 문자열   | 세부 병합 상태 정보입니다. 가능한 값의 목록은 [병합 상태](#merge-status)를 참조하세요. |
| `discussion_locked`                      | 부울  | `true`이면 스레드가 잠겨 있습니다. 프로젝트 멤버만 잠긴 스레드에서 댓글을 추가, 편집 또는 해결할 수 있습니다. |
| `downvotes`                              | 정수  | 머지 리퀘스트의 다운보트 수입니다. |
| `draft`                                  | 부울  | `true`이면 머지 리퀘스트가 `draft` 상태로 표시됩니다. |
| `force_remove_source_branch`             | 부울  | `true`이면 프로젝트 설정이 병합 후 소스 브랜치 삭제를 강제합니다. |
| `has_conflicts`                          | 부울  | `true`이면 머지 리퀘스트에 충돌이 있어 병합할 수 없습니다. `merge_status` 속성에 따라 달라집니다. `merge_status`이 `cannot_be_merged`가 아닌 경우 `false`을 반환합니다. |
| `id`                                     | 정수  | 머지 리퀘스트의 고유 ID입니다. |
| `iid`                                    | 정수  | 프로젝트 내에서 머지 리퀘스트의 내부 ID입니다. |
| `imported`                               | 부울  | `true`이면 머지 리퀘스트를 가져왔습니다. |
| `imported_from`                          | 문자열   | `Bitbucket`과 같은 가져오기 소스입니다. |
| `labels[]`                               | 배열    | 머지 리퀘스트에 할당된 레이블의 배열입니다. `with_labels_details`이 `true`이면 각 레이블에 대한 배열을 반환합니다. |
| `labels.archived`                        | 부울  | `with_labels_details`이 `true`이면 레이블이 보관됩니다. |
| `labels.color`                           | 문자열   | `with_labels_details`이 `true`이면 레이블의 배경색입니다. |
| `labels.description`                     | 문자열   | `with_labels_details`이 `true`이면 레이블의 설명 텍스트입니다. `null`이면 레이블에 설명이 없습니다. |
| `labels.description_html`.               | 문자열   | `with_labels_details`이 `true`이면 레이블의 HTML로 렌더링된 설명입니다. `null`이면 레이블에 설명이 없습니다. |
| `labels.id`                              | 정수  | `with_labels_details`이 `true`이면 레이블의 고유 ID입니다. |
| `labels.name`                            | 문자열   | `with_labels_details`이 `true`이면 레이블의 이름입니다. |
| `labels.text_color`                      | 문자열   | `with_labels_details`이 `true`이면 레이블의 텍스트 색상입니다. |
| `merge_after`                            | 날짜시간 | 설정되면 머지 리퀘스트를 병합할 수 있는 이후의 타임스탬프입니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)되었습니다. |
| `merge_commit_sha`                       | 문자열   | 설정되면 머지 리퀘스트 커밋의 SHA입니다. 병합될 때까지 `null`을 반환합니다. |
| `merge_status`                           | 문자열   | 머지 리퀘스트의 상태입니다. 모든 가능한 상태를 고려하는 `detailed_merge_status` 대신 사용합니다. `has_conflicts` 속성에 영향을 미칩니다. 응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요. [GitLab 15.6에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204).  |
| `merge_user`                             | 객체   | 머지 리퀘스트를 병합했거나 자동 병합으로 설정했거나 `null`인 사용자에 대한 정보가 포함된 객체입니다. |
| `merge_when_pipeline_succeeds`           | 부울  | `true`이면 머지 리퀘스트가 자동 병합으로 설정됩니다. |
| `merged_at`                              | 날짜시간 | 머지 리퀘스트를 병합할 때의 타임스탬프입니다. |
| `merged_by[]`                            | 객체   | 지원 중단됨. `merge_user` 대신 사용합니다. |
| `milestone[]`                            | 객체   | 머지 리퀘스트에 할당된 마일스톤에 대한 정보가 포함된 객체입니다. |
| `milestone.created_at`                   | 날짜시간 | 마일스톤을 생성할 때의 타임스탬프입니다. |
| `milestone.description`                  | 문자열   | 마일스톤의 설명 텍스트입니다. `null`이면 마일스톤에 설명이 없습니다. |
| `milestone.due_date`                     | 날짜     | 마일스톤의 기한입니다. `null`이면 마일스톤에 기한이 없습니다. |
| `milestone.expired`                      | 부울  | `true`이면 마일스톤이 만료되었습니다. |
| `milestone.group_id`                     | 정수  | 마일스톤이 속한 그룹의 ID입니다. 마일스톤이 그룹 마일스톤인 경우에만 포함됩니다. |
| `milestone.id`                           | 정수  | 마일스톤의 고유 ID입니다. |
| `milestone.iid`                          | 정수  | 프로젝트 또는 그룹 내에서 마일스톤의 내부 ID입니다. |
| `milestone.project_id`                   | 정수  | 마일스톤이 속한 프로젝트의 ID입니다. 마일스톤이 프로젝트 마일스톤인 경우에만 포함됩니다. |
| `milestone.start_date`                   | 날짜     | 마일스톤의 시작 날짜입니다. `null`이면 마일스톤에 시작 날짜가 없습니다 |
| `milestone.state`                        | 문자열   | 마일스톤의 현재 상태입니다(예: `active` 또는 `closed`). |
| `milestone.title`                        | 문자열   | 마일스톤의 이름입니다. |
| `milestone.updated_at`                   | 날짜시간 | 마일스톤을 마지막으로 업데이트할 때의 타임스탬프입니다. |
| `milestone.web_url`                      | 문자열   | 마일스톤을 보기 위한 전체 웹 URL입니다. |
| `prepared_at`                            | 날짜시간 | 머지 리퀘스트를 준비할 때의 타임스탬프입니다. 이 필드는 모든 [준비 단계](#preparation-steps)가 완료된 후 한 번 채워지며, 더 많은 변경 사항이 추가되면 업데이트되지 않습니다. |
| `project_id`                             | 정수  | 머지 리퀘스트를 포함하는 프로젝트의 ID입니다. |
| `reference`                              | 문자열   | 지원 중단됨. `references` 대신 사용합니다. |
| `references[]`                           | 객체   | 머지 리퀘스트의 모든 내부 참조가 포함된 객체입니다. |
| `references.full`                        | 문자열   | `gitlab-org/gitlab!123`과 같은 전체 프로젝트 경로를 포함한 머지 리퀘스트에 대한 완전한 참조입니다. 그룹 또는 프로젝트 간에 요청할 때 `references.relative`와 동일합니다. |
| `references.relative`                    | 문자열   | 특정 프로젝트 또는 그룹에 상대적인 참조: 현재 프로젝트의 머지 리퀘스트의 경우 `!123`, 같은 그룹의 다른 프로젝트의 경우 `other-project!123`. |
| `references.short`                       | 문자열   | `!123`과 같은 머지 리퀘스트에 대한 가장 짧은 가능한 참조입니다. 머지 리퀘스트의 프로젝트에서 가져올 때 `references.relative`와 동일합니다. |
| `reviewers[]`                            | 배열    | 머지 리퀘스트의 검토자입니다. |
| `reviewers.avatar_url`                   | 문자열   | 검토자의 아바타 이미지에 대한 전체 URL입니다. |
| `reviewers.id`                           | 정수  | 검토자의 고유 ID입니다. |
| `reviewers.locked`                       | 부울  | `true`이면 검토자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `reviewers.name`                         | 문자열   | 검토자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `reviewers.public_email`                 | 문자열   | 검토자의 공개 이메일 주소입니다. |
| `reviewers.state`                        | 문자열   | 검토자의 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `reviewers.username`                     | 문자열   | 머지 리퀘스트 검토자의 사용자 이름입니다. |
| `reviewers.web_url`                      | 문자열   | 검토자 프로필 페이지에 대한 전체 URL입니다. |
| `sha`                                    | 문자열   | 소스 브랜치의 헤드 커밋의 SHA입니다. |
| `should_remove_source_branch`            | 부울  | `true`이면 병합 후 소스 브랜치를 제거합니다. |
| `source_branch`                          | 문자열   | 소스 브랜치의 이름입니다. |
| `source_project_id`                      | 정수  | 소스 브랜치의 프로젝트의 ID입니다. |
| `squash`                                 | 부울  | `true`이면 병합할 때 커밋을 스쿼시합니다. |
| `squash_commit_sha`                      | 문자열   | 설정되면 스쿼시 커밋의 SHA입니다. 병합될 때까지 비어 있습니다. |
| `squash_on_merge`                        | 부울  | `true`이면 병합할 때 커밋을 스쿼시합니다. |
| `state`                                  | 문자열   | 머지 리퀘스트의 현재 상태입니다. 가능한 값: `opened`, `closed`, `merged` 또는 `locked`. |
| `target_branch`                          | 문자열   | 대상 브랜치의 이름입니다. |
| `target_project_id`                      | 정수  | 대상 브랜치의 프로젝트의 ID입니다. |
| `task_completion_status[]`               | 객체   | 작업 목록 완료 상태에 대한 정보가 포함된 객체입니다. |
| `task_completion_status.completed_count` | 정수  | 머지 리퀘스트 설명의 완료된 작업 목록 항목 수입니다. 머지 리퀘스트에 설명이 없거나 작업 목록 항목이 없으면 `0`을 반환합니다. |
| `task_completion_status.count`           | 정수  | 머지 리퀘스트 설명에서 발견된 총 작업 목록 항목 수입니다. 머지 리퀘스트에 설명이 없거나 작업 목록 항목이 없으면 `0`을 반환합니다. |
| `time_stats[]`                           | 객체   | 이 머지 리퀘스트에 대한 시간 추적 정보가 포함된 객체입니다. |
| `time_stats.human_time_estimate`         | 문자열   | `time_stats.time_estimate`의 사람이 읽을 수 있는 형식입니다(예: `3h 30m`). |
| `time_stats.human_total_time_spent`      | 문자열   | `time_stats.total_time_spent`의 사람이 읽을 수 있는 형식입니다(예: `3h 30m`). |
| `time_stats.time_estimate`               | 정수  | 머지 리퀘스트를 완료하는 데 필요한 예상 시간(초)입니다. |
| `time_stats.total_time_spent`            | 정수  | 머지 리퀘스트에 소비한 총 시간(초)입니다. |
| `title`                                  | 문자열   | 머지 리퀘스트 제목입니다. |
| `title_html`                             | 문자열   | `render_html`이 `true`이면 제목의 렌더링된 HTML 버전입니다. |
| `updated_at`                             | 날짜시간 | 머지 리퀘스트를 마지막으로 업데이트할 때의 타임스탬프입니다. |
| `upvotes`                                | 정수  | 머지 리퀘스트의 업보트 수입니다. |
| `user_notes_count`                       | 정수  | 사용자 댓글 수입니다. |
| `web_url`                                | 문자열   | 머지 리퀘스트를 보기 위한 웹 URL입니다. |
| `work_in_progress`                       | 부울  | 지원 중단됨. `draft` 대신 사용합니다. |

기타 가능한 응답:

- 액세스 토큰이 유효하지 않으면 `401 Unauthorized`.
- 데이터베이스 쿼리가 시간 초과되면 `408 Request Timeout`.
- 검증이 실패하면 `422 Unprocessable Entity`.
- `search` 매개변수를 사용하고 요청이 속도 제한된 경우 `429 Too Many Requests`.

응답 예시:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "allow_collaboration": false,
    "allow_maintainer_to_push": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-group/my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    }
  }
]
```

### 머지 리퀘스트 목록 응답 참고 사항 {#merge-requests-list-response-notes}

- 머지 리퀘스트를 나열하면 `merge_status`(이는 `has_conflicts`에도 영향을 미칩니다)을 사전에 업데이트하지 않을 수 있습니다. 이는 비용이 큰 작업이 될 수 있습니다. 이 엔드포인트에서 이러한 필드의 값이 필요하면 쿼리에서 `with_merge_status_recheck` 매개변수를 `true`로 설정합니다.
- 머지 리퀘스트 객체 필드에 대한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요.

## 프로젝트 머지 리퀘스트 나열 {#list-project-merge-requests}

프로젝트에 대한 모든 머지 리퀘스트를 나열합니다.

```plaintext
GET /projects/:id/merge_requests
GET /projects/:id/merge_requests?state=opened
GET /projects/:id/merge_requests?state=all
GET /projects/:id/merge_requests?iids[]=42&iids[]=43
GET /projects/:id/merge_requests?milestone=release
GET /projects/:id/merge_requests?labels=bug,reproduced
GET /projects/:id/merge_requests?my_reaction_emoji=star
```

지원되는 속성:

| 속성                       | 유형           | 필수 | 설명 |
| ------------------------------- | -------------- | -------- | ----------- |
| `id`                            | 정수 또는 문자열 | 예   | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `iids[]`                        | 정수 배열  | 아니요       | 제공된 IID와 일치하는 머지 리퀘스트를 반환합니다. |
| `approved_by_ids[]`             | 정수 배열  | 아니요       | 주어진 `id`을 가진 모든 사용자의 승인을 받은 머지 리퀘스트를 반환합니다(최대 5명). `None`는 승인되지 않은 머지 리퀘스트를 반환합니다. `Any`은 승인된 머지 리퀘스트를 반환합니다. |
| `approved_by_usernames[]`       | 문자열 배열   | 아니요       | 주어진 `username`을 가진 모든 사용자의 승인을 받은 머지 리퀘스트를 반환합니다(최대 5명). `None`는 승인되지 않은 머지 리퀘스트를 반환합니다. `Any`은 승인된 머지 리퀘스트를 반환합니다. |
| `approver_ids[]`                | 정수 배열  | 아니요       | 승인 규칙에 따라 지정된 `id`을 가진 모든 사용자가 적격 승인자인 머지 리퀴스트를 반환합니다. `None`는 적격 승인자가 없는 머지 리퀘스트를 반환합니다. `Any`은 최소 한 명 이상의 적격 승인자가 있는 머지 리퀘스트를 반환합니다. Premium 및 Ultimate만 해당합니다. |
| `assignee_id`                   | 정수 또는 문자열 | 아니요    | 주어진 사용자 `id`에게 할당된 머지 리퀘스트를 반환합니다. `None`는 할당되지 않은 머지 리퀘스트를 반환합니다. `Any`은 담당자가 있는 머지 리퀘스트를 반환합니다. `assignee_username`과 상호 배타적입니다. |
| `assignee_username[]`           | 문자열 배열   | 아니요       | 주어진 사용자 이름에 할당된 머지 리퀘스트를 반환합니다. `assignee_id`과 상호 배타적입니다. |
| `author_id`                     | 정수        | 아니요       | 주어진 사용자 `id`이 생성한 머지 리퀘스트를 반환합니다. `author_username`과 상호 배타적입니다. |
| `author_username`               | 문자열         | 아니요       | 주어진 `username`이 생성한 머지 리퀘스트를 반환합니다. `author_id`과 상호 배타적입니다. |
| `created_after`                 | 날짜/시간       | 아니요       | 주어진 날짜 및 시간 이후에 생성된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before`                | 날짜/시간       | 아니요       | 주어진 날짜 및 시간 이전에 생성된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `deployed_after`                | 날짜/시간       | 아니요       | 주어진 날짜 및 시간 이후에 배포된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `deployed_before`               | 날짜/시간       | 아니요       | 주어진 날짜 및 시간 이전에 배포된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `environment`                   | 문자열         | 아니요       | 주어진 환경에 배포된 머지 리퀘스트를 반환합니다. |
| `in`                            | 문자열         | 아니요       | `search` 속성의 범위를 변경합니다. `title`, `description` 또는 쉼표로 결합한 문자열입니다. 기본값은 `title,description`입니다. |
| `labels`                        | 문자열         | 아니요       | 쉼표로 구분된 레이블 목록과 일치하는 머지 리퀘스트를 반환합니다. `None`은 레이블이 없는 모든 머지 리퀘스트를 나열합니다. `Any`는 최소 하나 이상의 레이블을 가진 모든 머지 리퀘스트를 나열합니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다. |
| `merge_user_id`                 | 정수        | 아니요       | 주어진 사용자 `id`이 병합한 머지 리퀘스트를 반환합니다. `merge_user_username`과 상호 배타적입니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002). |
| `merge_user_username`           | 문자열         | 아니요       | 주어진 `username`이 병합한 머지 리퀘스트를 반환합니다. `merge_user_id`과 상호 배타적입니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002). |
| `milestone`                     | 문자열         | 아니요       | 특정 마일스톤의 머지 리퀘스트를 반환합니다. `None`는 마일스톤이 없는 머지 리퀘스트를 반환합니다. `Any`는 할당된 마일스톤이 있는 머지 리퀘스트를 반환합니다. |
| `my_reaction_emoji`             | 문자열         | 아니요       | 인증된 사용자가 주어진 `emoji`으로 반응한 머지 리퀘스트를 반환합니다. `None`는 반응이 지정되지 않은 이슈를 반환합니다. `Any`는 최소 하나 이상의 반응이 지정된 이슈를 반환합니다. |
| `not`                           | 해시           | 아니요       | 제공된 매개변수와 일치하지 않는 머지 리퀘스트를 반환합니다. 수락: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                      | 문자열         | 아니요       | `created_at`, `updated_at`, `merged_at` ([GitLab 17.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)), `label_priority`, `priority`, `milestone_due`, `popularity` 또는 `title` 필드로 정렬된 머지 리퀘스트를 반환합니다. 기본값은 `created_at`입니다. |
| `reviewer_id`                   | 정수 또는 문자열 | 아니요    | 주어진 사용자 `id`를 [검토자](../user/project/merge_requests/reviews/_index.md)로 하는 머지 리퀘스트를 반환합니다. `None`은 검토자가 없는 머지 리퀘스트를 반환합니다. `Any`은 모든 검토자가 있는 머지 리퀘스트를 반환합니다. `reviewer_username`과 상호 배타적입니다.  |
| `reviewer_username`             | 문자열         | 아니요       | 주어진 `username`를 [검토자](../user/project/merge_requests/reviews/_index.md)로 하는 머지 리퀘스트를 반환합니다. `None`은 검토자가 없는 머지 리퀘스트를 반환합니다. `Any`은 모든 검토자가 있는 머지 리퀘스트를 반환합니다. `reviewer_id`과 상호 배타적입니다. |
| `scope`                         | 문자열         | 아니요       | 주어진 범위의 머지 리퀘스트를 반환합니다: `created_by_me`, `assigned_to_me`, `reviews_for_me` 또는 `all`. `reviews_for_me`는 현재 사용자가 검토자로 할당된 머지 리퀘스트를 반환합니다. `all`로 기본값이 설정됩니다. |
| `search`                        | 문자열         | 아니요       | `title` 및 `description`에 대해 머지 리퀘스트를 검색합니다. `in` 속성과 결합합니다. |
| `sort`                          | 문자열         | 아니요       | `asc` 또는 `desc` 순서로 정렬된 머지 리퀘스트를 반환합니다. 기본값은 `desc`입니다. |
| `source_branch`                 | 문자열         | 아니요       | 주어진 소스 브랜치의 머지 리퀘스트를 반환합니다. |
| `state`                         | 문자열         | 아니요       | 모든 머지 리퀘스트(`all`) 또는 `opened`, `closed`, `locked` 또는 `merged`인 머지 리퀘스트만 반환합니다. `all`로 기본값이 설정됩니다. |
| `target_branch`                 | 문자열         | 아니요       | 주어진 대상 브랜치의 머지 리퀘스트를 반환합니다. |
| `updated_after`                 | 날짜/시간       | 아니요       | 주어진 날짜 및 시간 이후에 업데이트된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `updated_before`                | 날짜/시간       | 아니요       | 주어진 날짜 및 시간 이전에 업데이트된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `view`                          | 문자열         | 아니요       | `simple`이면 `iid`, URL, 제목, 설명 및 머지 리퀘스트의 기본 상태를 반환합니다. |
| `draft`                     | 부울           | 아니요       | 머지 리퀘스트의 `draft` 상태로 필터링합니다. `true`는 초안 머지 리퀘스트만 반환하고, `false`은 초안이 아닌 머지 리퀘스트를 반환합니다. `wip`과 상호 배타적입니다. |
| `wip`                       | 문자열            | 아니요       | [GitLab 19.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098). `draft` 대신 사용합니다. 머지 리퀘스트의 `wip` 상태로 필터링합니다. `yes`는 초안 머지 리퀘스트만 반환하고, `no`은 초안이 아닌 머지 리퀘스트를 반환합니다. |
| `with_labels_details`           | 부울        | 아니요       | `true`이면 응답은 labels 필드의 각 레이블에 대한 더 많은 세부 정보를 반환합니다: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. 기본값은 `false`입니다. |
| `with_merge_status_recheck`     | 부울        | 아니요       | `true`이면 이 프로젝션은 `merge_status` 필드의 비동기 재계산을 요청(보장하지는 않음)합니다. `restrict_merge_status_recheck` [기능 플래그](../administration/feature_flags/_index.md)를 활성화하여 Developer, Maintainer 또는 Owner 역할이 없는 사용자가 요청할 때 이 속성을 무시합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                          | 유형     | 설명 |
| ---------------------------------- | -------- | ----------- |
| `[].id`                            | 정수  | 머지 리퀘스트의 ID입니다. |
| `[].iid`                           | 정수  | 머지 리퀘스트의 내부 ID입니다. |
| `[].approvals_before_merge`        | 정수  | 이 머지 리퀘스트가 병합되기 전에 필요한 승인 수입니다. 승인 규칙을 구성하려면 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). Premium 및 Ultimate만 해당합니다. |
| `[].assignee`                      | 객체   | 머지 리퀘스트의 첫 번째 담당자입니다. |
| `[].assignees`                     | 배열    | 머지 리퀘스트의 담당자입니다. |
| `[].author`                        | 객체   | 이 머지 리퀘스트를 생성한 사용자입니다. |
| `[].blocking_discussions_resolved` | 부울  | 머지 리퀘스트를 병합하기 전에 모든 것이 필요한 경우에만 모든 스레드가 해결되었는지 나타냅니다. |
| `[].closed_at`                     | 날짜/시간 | 머지 리퀘스트를 닫을 때의 타임스탬프입니다. |
| `[].closed_by`                     | 객체   | 이 머지 리퀘스트를 닫은 사용자입니다. |
| `[].created_at`                    | 날짜/시간 | 머지 리퀘스트를 생성할 때의 타임스탬프입니다. |
| `[].description`                   | 문자열   | 머지 리퀘스트의 설명입니다. |
| `[].detailed_merge_status`         | 문자열   | 머지 리퀘스트의 세부 병합 상태입니다. 가능한 값의 목록은 [병합 상태](#merge-status)를 참조하세요. |
| `[].discussion_locked`             | 부울  | 머지 리퀘스트의 댓글이 멤버 전용으로 잠겨 있는지 나타냅니다. |
| `[].downvotes`                     | 정수  | 머지 리퀘스트의 다운보트 수입니다. |
| `[].draft`                         | 부울  | 머지 리퀘스트가 초안인지 나타냅니다. |
| `[].force_remove_source_branch`    | 부울  | 프로젝트 설정으로 인해 병합 후 소스 브랜치를 삭제하는지 나타냅니다. |
| `[].has_conflicts`                 | 부울  | 머지 리퀘스트에 충돌이 있어 병합할 수 없는지 나타냅니다. `merge_status` 속성에 따라 달라집니다. `merge_status`이 `cannot_be_merged`가 아닌 경우 `false`을 반환합니다. |
| `[].labels`                        | 배열    | 머지 리퀘스트의 레이블입니다. |
| `[].merge_commit_sha`              | 문자열   | 머지 리퀘스트 커밋의 SHA입니다. 병합될 때까지 `null`을 반환합니다. |
| `[].merge_status`                  | 문자열   | 머지 리퀘스트의 상태입니다. `unchecked`, `checking`, `can_be_merged`, `cannot_be_merged` 또는 `cannot_be_merged_recheck`일 수 있습니다. `has_conflicts` 속성에 영향을 미칩니다. 응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요. [GitLab 15.6에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204). `detailed_merge_status` 대신 사용합니다.  |
| `[].merge_user`                    | 객체   | 이 머지 리퀘스트를 병합했거나 자동 병합으로 설정했거나 `null`인 사용자입니다. |
| `[].merge_when_pipeline_succeeds`  | 부울  | 머지 리퀘스트가 자동 병합으로 설정되었는지 나타냅니다. |
| `[].merged_at`                     | 날짜/시간 | 머지 리퀘스트를 병합할 때의 타임스탬프입니다. |
| `[].merged_by`                     | 객체   | 이 머지 리퀘스트를 병합했거나 자동 병합으로 설정한 사용자입니다. GitLab 14.7에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)되었으며, [API 버전 5](https://gitlab.com/groups/gitlab-org/-/epics/8115)에서 제거될 예정입니다. `merge_user` 대신 사용합니다.  |
| `[].milestone`                     | 객체   | 머지 리퀘스트의 마일스톤입니다. |
| `[].prepared_at`                   | 날짜/시간 | 머지 리퀘스트를 준비할 때의 타임스탬프입니다. 이 필드는 모든 [준비 단계](#preparation-steps)가 완료된 후 한 번 채워지며, 더 많은 변경 사항이 추가되면 업데이트되지 않습니다. |
| `[].project_id`                    | 정수  | 머지 리퀘스트가 있는 프로젝트의 ID입니다. 항상 `target_project_id`과 같습니다. |
| `[].reference`                     | 문자열   | 머지 리퀘스트의 내부 참조입니다. 기본적으로 단축된 형식으로 반환됩니다. GitLab 12.7에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354)되었으며, [API 버전 5](https://gitlab.com/groups/gitlab-org/-/epics/8115)에서 제거될 예정입니다. `references` 대신 사용합니다.  |
| `[].references`                    | 객체   | 머지 리퀘스트의 내부 참조입니다. `short`, `relative` 및 `full` 참조를 포함합니다. `references.relative`는 머지 리퀘스트의 그룹 또는 프로젝트에 상대적입니다. 머지 리퀘스트의 프로젝트에서 가져올 때 `relative`와 `short` 형식이 동일합니다. 그룹 또는 프로젝트 간에 요청할 때 `relative`과 `full` 형식이 동일합니다.|
| `[].reviewers`                     | 배열    | 머지 리퀘스트의 검토자입니다. |
| `[].sha`                           | 문자열   | 머지 리퀘스트의 Diff 헤드 SHA입니다. |
| `[].should_remove_source_branch`   | 부울  | 병합 후 머지 리퀘스트의 소스 브랜치를 삭제해야 하는지 나타냅니다. |
| `[].source_branch`                 | 문자열   | 머지 리퀘스트의 소스 브랜치입니다. |
| `[].source_project_id`             | 정수  | 머지 리퀘스트 소스 브랜치 프로젝트의 ID입니다. 머지 리퀘스트가 포크에서 시작된 경우를 제외하고 `target_project_id`과 같습니다. |
| `[].squash`                        | 부울  | `true`이면 머지 시 모든 커밋을 단일 커밋으로 스쿼시합니다. [프로젝트 설정](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)이 이 값을 재정의할 수 있습니다. 프로젝트 스쿼시 옵션을 고려하려면 `squash_on_merge`을 대신 사용합니다. |
| `[].squash_commit_sha`             | 문자열   | 스쿼시 커밋의 SHA입니다. 병합될 때까지 비어 있습니다. |
| `[].squash_on_merge`               | 부울  | 머지 시 머지 리퀘스트를 스쿼시할지 여부를 나타냅니다. |
| `[].state`                         | 문자열   | 머지 리퀘스트의 상태입니다. `opened`, `closed`, `merged`, `locked`일 수 있습니다. |
| `[].target_branch`                 | 문자열   | 머지 리퀘스트의 대상 브랜치입니다. |
| `[].target_project_id`             | 정수  | 머지 리퀘스트 대상 프로젝트의 ID입니다. |
| `[].task_completion_status`        | 객체   | 작업 완료 상태입니다. `count`과 `completed_count`를 포함합니다. |
| `[].time_stats`                    | 객체   | 머지 리퀘스트의 시간 추적 통계입니다. `time_estimate`, `total_time_spent`, `human_time_estimate`, `human_total_time_spent`를 포함합니다. |
| `[].title`                         | 문자열   | 머지 리퀘스트의 제목입니다. |
| `[].updated_at`                    | 날짜/시간 | 머지 리퀘스트가 업데이트된 타임스탬프입니다. |
| `[].upvotes`                       | 정수  | 머지 리퀘스트의 업보트 수입니다. |
| `[].user_notes_count`              | 정수  | 머지 리퀘스트의 사용자 노트 수입니다. |
| `[].web_url`                       | 문자열   | 머지 리퀘스트의 웹 URL입니다. |
| `[].work_in_progress`              | 부울  | 지원 중단됨:  `draft` 대신 사용합니다. 머지 리퀘스트가 초안인지 나타냅니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests"
```

응답 예시:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "locked": false,
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "reference": "!1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "squash_on_merge": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true,
    "approvals_before_merge": 2
  }
]
```

응답 데이터에 대한 중요 참고 사항은 [머지 리퀘스트 목록 응답 참고](#merge-requests-list-response-notes)를 참조하세요.

## 그룹 머지 리퀘스트 목록 {#list-group-merge-requests}

그룹 및 해당 하위 그룹의 모든 머지 리퀘스트를 나열합니다.

```plaintext
GET /groups/:id/merge_requests
GET /groups/:id/merge_requests?state=opened
GET /groups/:id/merge_requests?state=all
GET /groups/:id/merge_requests?milestone=release
GET /groups/:id/merge_requests?labels=bug,reproduced
GET /groups/:id/merge_requests?my_reaction_emoji=star
```

지원되는 속성:

| 속성                   | 유형              | 필수 | 설명 |
|-----------------------------|-------------------|----------|-------------|
| `id`                        | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approved_by_ids[]`         | 정수 배열     | 아니요       | 주어진 `id`을 가진 모든 사용자의 승인을 받은 머지 리퀘스트를 반환합니다(최대 5명). `None`는 승인되지 않은 머지 리퀘스트를 반환합니다. `Any`은 승인된 머지 리퀘스트를 반환합니다. |
| `approved_by_usernames[]`   | 문자열 배열      | 아니요       | 주어진 `username`을 가진 모든 사용자의 승인을 받은 머지 리퀘스트를 반환합니다(최대 5명). `None`는 승인되지 않은 머지 리퀘스트를 반환합니다. `Any`은 승인된 머지 리퀘스트를 반환합니다. |
| `approver_ids[]`            | 정수 배열     | 아니요       | 승인 규칙에 따라 지정된 `id`을 가진 모든 사용자가 적격 승인자인 머지 리퀴스트를 반환합니다. `None`는 적격 승인자가 없는 머지 리퀘스트를 반환합니다. `Any`은 최소 한 명 이상의 적격 승인자가 있는 머지 리퀘스트를 반환합니다. Premium 및 Ultimate만 해당합니다. |
| `assignee_id`               | 정수 또는 문자열 | 아니요       | 주어진 사용자 `id`에게 할당된 머지 리퀘스트를 반환합니다. `None`는 할당되지 않은 머지 리퀘스트를 반환합니다. `Any`은 담당자가 있는 머지 리퀘스트를 반환합니다. `assignee_username`과 상호 배타적입니다. |
| `assignee_username[]`       | 문자열 배열      | 아니요       | 주어진 사용자 이름에 할당된 머지 리퀘스트를 반환합니다. `assignee_id`과 상호 배타적입니다. |
| `author_id`                 | 정수           | 아니요       | 주어진 사용자 `id`이 생성한 머지 리퀘스트를 반환합니다. `author_username`과 상호 배타적입니다. |
| `author_username`           | 문자열            | 아니요       | 주어진 `username`이 생성한 머지 리퀘스트를 반환합니다. `author_id`과 상호 배타적입니다. |
| `created_after`             | 날짜/시간          | 아니요       | 주어진 날짜 및 시간 이후에 생성된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before`            | 날짜/시간          | 아니요       | 주어진 날짜 및 시간 이전에 생성된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `deployed_after`            | 날짜/시간          | 아니요       | 주어진 날짜 및 시간 이후에 배포된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `deployed_before`           | 날짜/시간          | 아니요       | 주어진 날짜 및 시간 이전에 배포된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `environment`               | 문자열            | 아니요       | 주어진 환경에 배포된 머지 리퀘스트를 반환합니다. |
| `in`                        | 문자열            | 아니요       | `search` 속성의 범위를 변경합니다. `title`, `description` 또는 쉼표로 결합한 문자열입니다. 기본값은 `title,description`입니다. |
| `labels`                  | 문자열             | 아니요       | 쉼표로 구분된 레이블 목록과 일치하는 머지 리퀘스트를 반환합니다. `None`은 레이블이 없는 모든 머지 리퀘스트를 나열합니다. `Any`는 최소 하나 이상의 레이블을 가진 모든 머지 리퀘스트를 나열합니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다. |
| `merge_user_id`             | 정수           | 아니요       | 주어진 사용자 `id`이 병합한 머지 리퀘스트를 반환합니다. `merge_user_username`과 상호 배타적입니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002). |
| `merge_user_username`       | 문자열            | 아니요       | 주어진 `username`이 병합한 머지 리퀘스트를 반환합니다. `merge_user_id`과 상호 배타적입니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002). |
| `milestone`                 | 문자열            | 아니요       | 특정 마일스톤의 머지 리퀘스트를 반환합니다. `None`는 마일스톤이 없는 머지 리퀘스트를 반환합니다. `Any`는 할당된 마일스톤이 있는 머지 리퀘스트를 반환합니다. |
| `my_reaction_emoji`         | 문자열            | 아니요       | 인증된 사용자가 주어진 `emoji`으로 반응한 머지 리퀘스트를 반환합니다. `None`는 반응이 지정되지 않은 이슈를 반환합니다. `Any`는 최소 하나 이상의 반응이 지정된 이슈를 반환합니다. |
| `non_archived`              | 부울           | 아니요       | `true`이면 보관되지 않은 프로젝트의 머지 리퀘스트만 반환합니다. 기본값은 `true`입니다. |
| `not`                       | 해시              | 아니요       | 제공된 매개변수와 일치하지 않는 머지 리퀘스트를 반환합니다. 수락: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                  | 문자열            | 아니요       | `created_at`, `updated_at`, `merged_at` ([GitLab 17.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)), `label_priority`, `priority`, `milestone_due`, `popularity` 또는 `title` 필드로 정렬된 머지 리퀘스트를 반환합니다. 기본값은 `created_at`입니다. |
| `reviewer_id`               | 정수 또는 문자열 | 아니요       | 주어진 사용자 `id`를 [검토자](../user/project/merge_requests/reviews/_index.md)로 하는 머지 리퀘스트를 반환합니다. `None`은 검토자가 없는 머지 리퀘스트를 반환합니다. `Any`은 모든 검토자가 있는 머지 리퀘스트를 반환합니다. `reviewer_username`과 상호 배타적입니다. |
| `reviewer_username`         | 문자열            | 아니요       | 주어진 `username`를 [검토자](../user/project/merge_requests/reviews/_index.md)로 하는 머지 리퀘스트를 반환합니다. `None`은 검토자가 없는 머지 리퀘스트를 반환합니다. `Any`은 모든 검토자가 있는 머지 리퀘스트를 반환합니다. `reviewer_id`과 상호 배타적입니다. |
| `scope`                     | 문자열            | 아니요       | 주어진 범위의 머지 리퀘스트를 반환합니다: `created_by_me`, `assigned_to_me`, `reviews_for_me` 또는 `all`. `reviews_for_me`는 현재 사용자가 검토자로 할당된 머지 리퀘스트를 반환합니다. `all`로 기본값이 설정됩니다. |
| `search`                    | 문자열            | 아니요       | `title` 및 `description`에 대해 머지 리퀘스트를 검색합니다. `in` 속성과 결합합니다. |
| `sort`                      | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 정렬된 머지 리퀘스트를 반환합니다. 기본값은 `desc`입니다. |
| `source_branch`             | 문자열            | 아니요       | 주어진 소스 브랜치의 머지 리퀘스트를 반환합니다. |
| `source_project_id`         | 정수           | 아니요       | 주어진 소스 프로젝트 ID를 가진 머지 리퀘스트를 반환합니다. |
| `state`                     | 문자열            | 아니요       | 모든 머지 리퀘스트(`all`) 또는 `opened`, `closed`, `locked` 또는 `merged`인 머지 리퀘스트만 반환합니다. `all`로 기본값이 설정됩니다. |
| `target_branch`             | 문자열            | 아니요       | 주어진 대상 브랜치의 머지 리퀘스트를 반환합니다. |
| `updated_after`             | 날짜/시간          | 아니요       | 주어진 날짜 및 시간 이후에 업데이트된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `updated_before`            | 날짜/시간          | 아니요       | 주어진 날짜 및 시간 이전에 업데이트된 머지 리퀘스트를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `view`                      | 문자열            | 아니요       | `simple`이면 `iid`, URL, 제목, 설명 및 머지 리퀘스트의 기본 상태를 반환합니다. |
| `draft`                     | 부울           | 아니요       | 머지 리퀘스트의 `draft` 상태로 필터링합니다. `true`는 초안 머지 리퀘스트만 반환하고, `false`은 초안이 아닌 머지 리퀘스트를 반환합니다. `wip`과 상호 배타적입니다. |
| `wip`                       | 문자열            | 아니요       | [GitLab 19.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098). `draft` 대신 사용합니다. 머지 리퀘스트의 `wip` 상태로 필터링합니다. `yes`는 초안 머지 리퀘스트만 반환하고, `no`은 초안이 아닌 머지 리퀘스트를 반환합니다. |
| `with_labels_details`       | 부울           | 아니요       | `true`이면 응답은 labels 필드의 각 레이블에 대한 더 많은 세부 정보를 반환합니다: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. 기본값은 `false`입니다. |
| `with_merge_status_recheck` | 부울           | 아니요       | `true`이면 이 프로젝션은 `merge_status` 필드의 비동기 재계산을 요청(보장하지는 않음)합니다. `restrict_merge_status_recheck` [기능 플래그](../administration/feature_flags/_index.md)를 활성화하여 Developer, Maintainer 또는 Owner 역할이 없는 사용자가 요청할 때 이 속성을 무시합니다. |

응답에서 `group_id`은(는) 머지 리퀘스트가 있는 프로젝트를 포함하는 그룹의 ID를 나타냅니다.

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환합니다. `view`이 `simple`로 설정되면 필드의 하위 집합을 반환합니다. 그렇지 않으면 응답 속성에는 다음이 포함됩니다:

| 속성                                | 유형     | 설명 |
|------------------------------------------|----------|-------------|
| `allow_collaboration`                    | 부울  | `true`이면 이 포크는 대상 브랜치로 병합할 수 있는 멤버 간의 협업을 허용합니다. 포크의 머지 리퀘스트에만 사용됩니다. |
| `allow_maintainer_to_push`               | 부울  | 지원 중단됨. `allow_collaboration` 대신 사용합니다. |
| `approvals_before_merge`                 | 정수  | [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). 승인 규칙을 구성하려면 대신 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. GitLab Premium 및 Ultimate만 해당합니다. |
| `assignee[]`                             | 객체   | 지원 중단됨. `assignees` 대신 사용합니다. |
| `assignees[]`                            | 배열    | 머지 리퀘스트에 할당된 사용자입니다. |
| `assignees.avatar_url`                   | 문자열   | 담당자의 아바타 이미지에 대한 전체 URL입니다. |
| `assignees.id`                           | 정수  | 담당자의 고유 ID입니다. |
| `assignees.locked`                       | 부울  | `true`이면 담당자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `assignees.name`                         | 문자열   | 담당자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `assignees.public_email`                 | 문자열   | 담당자의 공개 이메일 주소입니다. |
| `assignees.state`                        | 문자열   | 담당자 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `assignees.username`                     | 문자열   | 머지 리퀘스트 담당자의 사용자 이름입니다. |
| `assignees.web_url`                      | 문자열   | 담당자 프로필 페이지에 대한 전체 URL입니다. |
| `author[]`                               | 객체   | 머지 리퀘스트를 생성한 사용자에 대한 정보가 포함된 객체입니다. |
| `author.avatar_url`                      | 문자열   | 작성자의 아바타 이미지에 대한 전체 URL입니다. |
| `author.id`                              | 정수  | 머지 리퀘스트를 생성한 사용자의 고유 ID입니다. |
| `author.locked`                          | 부울  | `true`이면 작성자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `author.name`                            | 문자열   | 작성자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `author.public_email`                    | 문자열   | 작성자의 공개 이메일 주소입니다. |
| `author.state`                           | 문자열   | 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `author.username`                        | 문자열   | 머지 리퀘스트 작성자의 사용자 이름입니다. |
| `author.web_url`                         | 문자열   | 작성자 프로필 페이지에 대한 전체 URL입니다. |
| `blocking_discussions_resolved`          | 부울  | `true`이면 머지 리퀘스트가 병합되기 전에 모든 스레드를 해결해야 합니다. |
| `closed_at`                              | 날짜시간 | 머지 리퀘스트를 닫을 때의 타임스탬프입니다. |
| `closed_by[]`                            | 객체   | 머지 리퀘스트를 닫은 사용자에 대한 정보가 포함된 객체입니다. `null`이면 머지 리퀘스트가 열려 있습니다. |
| `closed_by.avatar_url`                   | 문자열   | 닫은 사용자의 아바타 이미지에 대한 전체 URL입니다. |
| `closed_by.id`                           | 정수  | 머지 리퀘스트를 닫은 사용자의 고유 ID입니다. |
| `closed_by.locked`                       | 부울  | `true`이면 닫은 사용자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `closed_by.name`                         | 문자열   | 닫은 사용자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `closed_by.public_email`                 | 문자열   | 닫은 사용자의 공개 이메일 주소입니다. |
| `closed_by.state`                        | 문자열   | 닫은 사용자의 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `closed_by.username`                     | 문자열   | 머지 리퀘스트를 닫은 사용자의 사용자 이름입니다. |
| `closed_by.web_url`                      | 문자열   | 닫은 사용자의 프로필 페이지에 대한 전체 URL입니다. |
| `created_at`                             | 날짜시간 | 머지 리퀘스트를 생성할 때의 타임스탬프입니다. |
| `description`                            | 문자열   | 머지 리퀘스트의 설명입니다. 캐싱을 위해 HTML로 렌더링된 Markdown이 포함되어 있습니다. |
| `detailed_merge_status`                  | 문자열   | 세부 병합 상태 정보입니다. 가능한 값의 목록은 [병합 상태](#merge-status)를 참조하세요. |
| `discussion_locked`                      | 부울  | `true`이면 스레드가 잠겨 있습니다. 프로젝트 멤버만 잠긴 스레드에서 댓글을 추가, 편집 또는 해결할 수 있습니다. |
| `downvotes`                              | 정수  | 머지 리퀘스트의 다운보트 수입니다. |
| `draft`                                  | 부울  | `true`이면 머지 리퀘스트가 `draft` 상태로 표시됩니다. |
| `force_remove_source_branch`             | 부울  | `true`이면 프로젝트 설정이 병합 후 소스 브랜치 삭제를 강제합니다. |
| `has_conflicts`                          | 부울  | `true`이면 머지 리퀘스트에 충돌이 있어 병합할 수 없습니다. `merge_status` 속성에 따라 달라집니다. `merge_status`이 `cannot_be_merged`가 아닌 경우 `false`을 반환합니다. |
| `id`                                     | 정수  | 머지 리퀘스트의 고유 ID입니다. |
| `iid`                                    | 정수  | 프로젝트 내에서 머지 리퀘스트의 내부 ID입니다. |
| `imported`                               | 부울  | `true`이면 머지 리퀘스트를 가져왔습니다. |
| `imported_from`                          | 문자열   | `Bitbucket`과 같은 가져오기 소스입니다. |
| `labels[]`                               | 배열    | 머지 리퀘스트에 할당된 레이블의 배열입니다. `with_labels_details`이 `true`이면 각 레이블에 대한 배열을 반환합니다. |
| `labels.archived`                        | 부울  | `with_labels_details`이 `true`이면 레이블이 보관됩니다. |
| `labels.color`                           | 문자열   | `with_labels_details`이 `true`이면 레이블의 배경색입니다. |
| `labels.description`                     | 문자열   | `with_labels_details`이 `true`이면 레이블의 설명 텍스트입니다. `null`이면 레이블에 설명이 없습니다. |
| `labels.description_html`                | 문자열   | `with_labels_details`이 `true`이면 레이블의 HTML로 렌더링된 설명입니다. `null`이면 레이블에 설명이 없습니다. |
| `labels.id`                              | 정수  | `with_labels_details`이 `true`이면 레이블의 고유 ID입니다. |
| `labels.name`                            | 문자열   | `with_labels_details`이 `true`이면 레이블의 이름입니다. |
| `labels.text_color`                      | 문자열   | `with_labels_details`이 `true`이면 레이블의 텍스트 색상입니다. |
| `merge_after`                            | 날짜시간 | 설정되면 머지 리퀘스트를 병합할 수 있는 이후의 타임스탬프입니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)되었습니다. |
| `merge_commit_sha`                       | 문자열   | 설정되면 머지 리퀘스트 커밋의 SHA입니다. 병합될 때까지 `null`을 반환합니다. |
| `merge_status`                           | 문자열   | 머지 리퀘스트의 상태입니다. 모든 가능한 상태를 고려하는 `detailed_merge_status` 대신 사용합니다. `has_conflicts` 속성에 영향을 미칩니다. 응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요. [GitLab 15.6에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204).  |
| `merge_user`                             | 객체   | 머지 리퀘스트를 병합했거나 자동 병합으로 설정했거나 `null`인 사용자에 대한 정보가 포함된 객체입니다. |
| `merge_when_pipeline_succeeds`           | 부울  | `true`이면 머지 리퀘스트가 자동 병합으로 설정됩니다. |
| `merged_at`                              | 날짜시간 | 머지 리퀘스트를 병합할 때의 타임스탬프입니다. |
| `merged_by[]`                            | 객체   | 지원 중단됨. `merge_user` 대신 사용합니다. |
| `milestone[]`                            | 객체   | 머지 리퀘스트에 할당된 마일스톤에 대한 정보가 포함된 객체입니다. |
| `milestone.created_at`                   | 날짜시간 | 마일스톤을 생성할 때의 타임스탬프입니다. |
| `milestone.description`                  | 문자열   | 마일스톤의 설명 텍스트입니다. `null`이면 마일스톤에 설명이 없습니다. |
| `milestone.due_date`                     | 날짜     | 마일스톤의 기한입니다. `null`이면 마일스톤에 기한이 없습니다. |
| `milestone.expired`                      | 부울  | `true`이면 마일스톤이 만료되었습니다. |
| `milestone.group_id`                     | 정수  | 마일스톤이 속한 그룹의 ID입니다. 마일스톤이 그룹 마일스톤인 경우에만 포함됩니다. |
| `milestone.id`                           | 정수  | 마일스톤의 고유 ID입니다. |
| `milestone.iid`                          | 정수  | 프로젝트 또는 그룹 내에서 마일스톤의 내부 ID입니다. |
| `milestone.project_id`                   | 정수  | 마일스톤이 속한 프로젝트의 ID입니다. 마일스톤이 프로젝트 마일스톤인 경우에만 포함됩니다. |
| `milestone.start_date`                   | 날짜     | 마일스톤의 시작 날짜입니다. `null`이면 마일스톤에 시작 날짜가 없습니다 |
| `milestone.state`                        | 문자열   | 마일스톤의 현재 상태입니다(예: `active` 또는 `closed`). |
| `milestone.title`                        | 문자열   | 마일스톤의 이름입니다. |
| `milestone.updated_at`                   | 날짜시간 | 마일스톤을 마지막으로 업데이트할 때의 타임스탬프입니다. |
| `milestone.web_url`                      | 문자열   | 마일스톤을 보기 위한 전체 웹 URL입니다. |
| `prepared_at`                            | 날짜시간 | 머지 리퀘스트를 준비할 때의 타임스탬프입니다. 이 필드는 모든 [준비 단계](#preparation-steps)가 완료된 후 한 번 채워지며, 더 많은 변경 사항이 추가되면 업데이트되지 않습니다. |
| `project_id`                             | 정수  | 머지 리퀘스트를 포함하는 프로젝트의 ID입니다. |
| `reference`                              | 문자열   | 지원 중단됨. `references` 대신 사용합니다. |
| `references[]`                           | 객체   | 머지 리퀘스트의 모든 내부 참조가 포함된 객체입니다. |
| `references.full`                        | 문자열   | `gitlab-org/gitlab!123`과 같은 전체 프로젝트 경로를 포함한 머지 리퀘스트에 대한 완전한 참조입니다. 그룹 또는 프로젝트 간에 요청할 때 `references.relative`와 동일합니다. |
| `references.relative`                    | 문자열   | 특정 프로젝트 또는 그룹에 상대적인 참조: 현재 프로젝트의 머지 리퀘스트의 경우 `!123`, 같은 그룹의 다른 프로젝트의 경우 `other-project!123`. |
| `references.short`                       | 문자열   | `!123`과 같은 머지 리퀘스트에 대한 가장 짧은 가능한 참조입니다. 머지 리퀘스트의 프로젝트에서 가져올 때 `references.relative`와 동일합니다. |
| `reviewers[]`                            | 배열    | 머지 리퀘스트의 검토자입니다. |
| `reviewers.avatar_url`                   | 문자열   | 검토자의 아바타 이미지에 대한 전체 URL입니다. |
| `reviewers.id`                           | 정수  | 검토자의 고유 ID입니다. |
| `reviewers.locked`                       | 부울  | `true`이면 검토자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `reviewers.name`                         | 문자열   | 검토자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `reviewers.public_email`                 | 문자열   | 검토자의 공개 이메일 주소입니다. |
| `reviewers.state`                        | 문자열   | 검토자의 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `reviewers.username`                     | 문자열   | 머지 리퀘스트 검토자의 사용자 이름입니다. |
| `reviewers.web_url`                      | 문자열   | 검토자 프로필 페이지에 대한 전체 URL입니다. |
| `sha`                                    | 문자열   | 소스 브랜치의 헤드 커밋의 SHA입니다. |
| `should_remove_source_branch`            | 부울  | `true`이면 병합 후 소스 브랜치를 제거합니다. |
| `source_branch`                          | 문자열   | 소스 브랜치의 이름입니다. |
| `source_project_id`                      | 정수  | 소스 브랜치의 프로젝트의 ID입니다. |
| `squash`                                 | 부울  | `true`이면 병합할 때 커밋을 스쿼시합니다. |
| `squash_commit_sha`                      | 문자열   | 설정되면 스쿼시 커밋의 SHA입니다. 병합될 때까지 비어 있습니다. |
| `squash_on_merge`                        | 부울  | `true`이면 병합할 때 커밋을 스쿼시합니다. |
| `state`                                  | 문자열   | 머지 리퀘스트의 현재 상태입니다. 가능한 값: `opened`, `closed`, `merged` 또는 `locked`. |
| `target_branch`                          | 문자열   | 대상 브랜치의 이름입니다. |
| `target_project_id`                      | 정수  | 대상 브랜치의 프로젝트의 ID입니다. |
| `task_completion_status[]`               | 객체   | 작업 목록 완료 상태에 대한 정보가 포함된 객체입니다. |
| `task_completion_status.completed_count` | 정수  | 머지 리퀘스트 설명의 완료된 작업 목록 항목 수입니다. 머지 리퀘스트에 설명이 없거나 작업 목록 항목이 없으면 `0`을 반환합니다. |
| `task_completion_status.count`           | 정수  | 머지 리퀘스트 설명에서 발견된 총 작업 목록 항목 수입니다. 머지 리퀘스트에 설명이 없거나 작업 목록 항목이 없으면 `0`을 반환합니다. |
| `time_stats[]`                           | 객체   | 이 머지 리퀘스트에 대한 시간 추적 정보가 포함된 객체입니다. |
| `time_stats.human_time_estimate`         | 문자열   | `time_stats.time_estimate`의 사람이 읽을 수 있는 형식입니다(예: `3h 30m`). |
| `time_stats.human_total_time_spent`      | 문자열   | `time_stats.total_time_spent`의 사람이 읽을 수 있는 형식입니다(예: `3h 30m`). |
| `time_stats.time_estimate`               | 정수  | 머지 리퀘스트를 완료하는 데 필요한 예상 시간(초)입니다. |
| `time_stats.total_time_spent`            | 정수  | 머지 리퀘스트에 소비한 총 시간(초)입니다. |
| `title`                                  | 문자열   | 머지 리퀘스트 제목입니다. |
| `updated_at`                             | 날짜시간 | 머지 리퀘스트를 마지막으로 업데이트할 때의 타임스탬프입니다. |
| `upvotes`                                | 정수  | 머지 리퀘스트의 업보트 수입니다. |
| `user_notes_count`                       | 정수  | 사용자 댓글 수입니다. |
| `web_url`                                | 문자열   | 머지 리퀘스트를 보기 위한 웹 URL입니다. |
| `work_in_progress`                       | 부울  | 지원 중단됨. `draft` 대신 사용합니다. |

기타 가능한 응답:

- 액세스 토큰이 유효하지 않으면 `401 Unauthorized`.
- 프로젝트 또는 머지 리퀘스트를 찾을 수 없으면 `404 Not Found`.
- 검증이 실패하면 `422 Unprocessable Entity`.
- `search` 매개변수를 사용하고 요청이 속도 제한된 경우 `429 Too Many Requests`.

응답 예시:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-10-22",
      "start_date": "2018-09-08",
      "web_url": "gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true
  }
]
```

응답 데이터에 대한 중요 참고 사항은 [머지 리퀘스트 목록 응답 참고](#merge-requests-list-response-notes)를 참조하세요.

## 머지 리퀘스트 검색 {#retrieve-a-merge-request}

머지 리퀘스트에 대한 정보를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid
```

지원되는 속성:

| 속성                        | 유형              | 필수 | 설명 |
|----------------------------------|-------------------|----------|-------------|
| `id`                             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid`              | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `include_diverged_commits_count` | 부울           | 아니요       | `true`이면 응답은 대상 브랜치보다 뒤에 있는 커밋을 포함합니다. |
| `include_rebase_in_progress`     | 부울           | 아니요       | `true`이면 응답은 리베이스 작업이 진행 중인지 여부를 포함합니다. |
| `render_html`                    | 부울           | 아니요       | `true`이면 응답은 제목 및 설명에 대해 렌더링된 HTML을 포함합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환합니다. 기타 가능한 응답:

- 액세스 토큰이 유효하지 않으면 `401 Unauthorized`.
- 액세스가 거부되면 `403 Forbidden`.
- 프로젝트 또는 머지 리퀘스트를 찾을 수 없으면 `404 Not Found`.
- 데이터베이스 쿼리가 시간 초과되면 `408 Request Timeout`.
- 리소스 잠금 충돌이 존재하면 `409 Conflict`.
- 검증이 실패하면 `422 Unprocessable Entity`.
- `search` 매개변수를 사용하고 요청이 속도 제한된 경우 `429 Too Many Requests`.

### 응답 {#response}

| 속성                                                   | 유형     | 설명 |
|-------------------------------------------------------------|----------|-------------|
| `allow_collaboration`                                       | 부울  | `true`이면 이 포크는 대상 브랜치로 병합할 수 있는 멤버 간의 협업을 허용합니다. 포크의 머지 리퀘스트에만 사용됩니다. |
| `allow_maintainer_to_push`                                  | 부울  | 지원 중단됨. `allow_collaboration` 대신 사용합니다. |
| `approvals_before_merge`                                    | 정수  | [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). 승인 규칙을 구성하려면 대신 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. GitLab Premium 및 Ultimate만 해당합니다. |
| `assignee[]`                                                | 객체   | 지원 중단됨. `assignees` 대신 사용합니다. |
| `assignees[]`                                               | 배열    | 머지 리퀘스트에 할당된 사용자입니다. |
| `assignees.avatar_url`                                      | 문자열   | 담당자의 아바타 이미지에 대한 전체 URL입니다. |
| `assignees.id`                                              | 정수  | 담당자의 고유 ID입니다. |
| `assignees.locked`                                          | 부울  | `true`이면 담당자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `assignees.name`                                            | 문자열   | 담당자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `assignees.public_email`                                    | 문자열   | 담당자의 공개 이메일 주소입니다. |
| `assignees.state`                                           | 문자열   | 담당자 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `assignees.username`                                        | 문자열   | 머지 리퀘스트 담당자의 사용자 이름입니다. |
| `assignees.web_url`                                         | 문자열   | 담당자 프로필 페이지에 대한 전체 URL입니다. |
| `author[]`                                                  | 객체   | 머지 리퀘스트를 생성한 사용자에 대한 정보가 포함된 객체입니다. |
| `author.avatar_url`                                         | 문자열   | 작성자의 아바타 이미지에 대한 전체 URL입니다. |
| `author.id`                                                 | 정수  | 머지 리퀘스트를 생성한 사용자의 고유 ID입니다. |
| `author.locked`                                             | 부울  | `true`이면 작성자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `author.name`                                               | 문자열   | 작성자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `author.public_email`                                       | 문자열   | 작성자의 공개 이메일 주소입니다. |
| `author.state`                                              | 문자열   | 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `author.username`                                           | 문자열   | 머지 리퀘스트 작성자의 사용자 이름입니다. |
| `author.web_url`                                            | 문자열   | 작성자 프로필 페이지에 대한 전체 URL입니다. |
| `blocking_discussions_resolved`                             | 부울  | `true`이면 머지 리퀘스트가 병합되기 전에 모든 스레드를 해결해야 합니다. |
| `changes_count`                                             | 문자열   | 설정되면 머지 리퀘스트에서 변경한 수입니다. 머지 리퀘스트가 생성되면 비어 있습니다. 비동기적으로 채워집니다. 정수가 아닌 문자열입니다. 머지 리퀘스트에 표시하고 저장하기에 너무 많은 변경 사항이 있으면 값은 1000으로 제한되고 문자열 `"1000+"`을(를) 반환합니다. [새 머지 리퀘스트에 대한 빈 API 필드](#empty-api-fields-for-new-merge-requests)를 참조하세요. |
| `closed_at`                                                 | 날짜시간 | 머지 리퀘스트를 닫을 때의 타임스탬프입니다. |
| `closed_by[]`                                               | 객체   | 머지 리퀘스트를 닫은 사용자에 대한 정보가 포함된 객체입니다. `null`이면 머지 리퀘스트가 열려 있습니다. |
| `closed_by.avatar_url`                                      | 문자열   | 닫은 사용자의 아바타 이미지에 대한 전체 URL입니다. |
| `closed_by.id`                                              | 정수  | 머지 리퀘스트를 닫은 사용자의 고유 ID입니다. |
| `closed_by.locked`                                          | 부울  | `true`이면 닫은 사용자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `closed_by.name`                                            | 문자열   | 닫은 사용자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `closed_by.public_email`                                    | 문자열   | 닫은 사용자의 공개 이메일 주소입니다. |
| `closed_by.state`                                           | 문자열   | 닫은 사용자의 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `closed_by.username`                                        | 문자열   | 머지 리퀘스트를 닫은 사용자의 사용자 이름입니다. |
| `closed_by.web_url`                                         | 문자열   | 닫은 사용자의 프로필 페이지에 대한 전체 URL입니다. |
| `created_at`                                                | 날짜/시간 | 머지 리퀘스트를 생성할 때의 타임스탬프입니다. |
| `description`                                               | 문자열   | 머지 리퀘스트의 설명입니다. 캐싱을 위해 HTML로 렌더링된 Markdown이 포함되어 있습니다. |
| `detailed_merge_status`                                     | 문자열   | 세부 병합 상태 정보입니다. 가능한 값의 목록은 [병합 상태](#merge-status)를 참조하세요. |
| `diff_refs[]`                                               | 객체   | 이 머지 리퀘스트의 기본, 헤드 및 시작 SHA의 참조가 있는 객체입니다. 머지 리퀘스트의 최신 diff 버전에 해당합니다. 머지 리퀘스트가 생성되면 비어 있으며 비동기적으로 채워집니다. [새 머지 리퀘스트에 대한 빈 API 필드](#empty-api-fields-for-new-merge-requests)를 참조하세요. |
| `diff_refs.base_sha`                                        | 문자열   | 소스 및 대상 브랜치가 분기된 머지 베이스 커밋의 SHA입니다. |
| `diff_refs.start_sha`                                       | 문자열   | 대상 브랜치 커밋의 SHA입니다. diff의 시작점입니다. 일반적으로 `base_sha`과(와) 동일합니다. |
| `diff_refs.head_sha`                                        | 문자열   | 소스 브랜치의 헤드 커밋의 SHA입니다. 머지 리퀘스트의 최신 커밋입니다. |
| `discussion_locked`                                         | 부울  | `true`이면 스레드가 잠겨 있습니다. 프로젝트 멤버만 잠긴 스레드에서 댓글을 추가, 편집 또는 해결할 수 있습니다. |
| `diverged_commits_count`                                    | 정수  | 설정되면 소스 브랜치가 대상 브랜치보다 뒤에 있는 커밋 수를 포함합니다. |
| `downvotes`                                                 | 정수  | 머지 리퀘스트의 다운보트 수입니다. |
| `draft`                                                     | 부울  | `true`이면 머지 리퀘스트가 `draft` 상태로 표시됩니다. |
| `first_contribution`                                        | 부울  | `true`이면 이 프로젝트에 대한 작성자의 첫 기여입니다. |
| `first_deployed_to_production_at`                           | 날짜/시간 | 첫 배포가 완료된 타임스탐프입니다. |
| `force_remove_source_branch`                                | 부울  | `true`이면 프로젝트 설정이 병합 후 소스 브랜치 삭제를 강제합니다. |
| `has_conflicts`                                             | 부울  | `true`이면 머지 리퀘스트에 충돌이 있어 병합할 수 없습니다. `merge_status` 속성에 따라 달라집니다. `merge_status`이 `cannot_be_merged`가 아닌 경우 `false`을 반환합니다. |
| `head_pipeline[]`                                           | 객체   | 머지 리퀘스트의 소스 브랜치의 HEAD 커밋에서 실행되는 파이프라인입니다. `pipeline` 대신 사용하세요. 더 완전한 정보를 포함하기 때문입니다. 현재 사용자가 이 프로젝트의 파이프라인을 볼 수 있는 경우에만 노출됩니다. |
| `head_pipeline.before_sha`                                  | 문자열   | 이 파이프라인 이전의 커밋의 SHA입니다. |
| `head_pipeline.committed_at`                                | 날짜시간 | 커밋이 생성된 타임스탐프입니다. |
| `head_pipeline.coverage`                                    | 숫자   | 테스트 커버리지 백분율(예: `98.29`)입니다. |
| `head_pipeline.created_at`                                  | 날짜시간 | 파이프라인이 생성된 타임스탐프입니다. |
| `head_pipeline.detailed_status[]`                           | 객체   | 이 파이프라인의 상세 상태를 포함하는 필드가 있는 객체입니다. |
| `head_pipeline.detailed_status.action[]`                    | 객체   | 설정되면 이 파이프라인에 대해 사용 가능한 작업을 포함하는 객체입니다. |
| `head_pipeline.detailed_status.action.button_title`         | 문자열   | 작업에 대한 버튼 제목입니다. |
| `head_pipeline.detailed_status.action.confirmation_message` | 문자열   | 작업의 확인 메시지입니다. |
| `head_pipeline.detailed_status.action.icon`                 | 문자열   | 작업의 아이콘입니다. |
| `head_pipeline.detailed_status.action.method`               | 문자열   | 작업의 HTTP 메서드(예: `POST`)입니다. |
| `head_pipeline.detailed_status.action.path`                 | 문자열   | 작업의 경로(예: `"/namespace1/project1/-/jobs/2/cancel"`)입니다. |
| `head_pipeline.detailed_status.action.title`                | 문자열   | 작업의 제목입니다. |
| `head_pipeline.detailed_status.details_path`                | 문자열   | 상세 보기의 경로(예: `"/test-group/test-project/-/pipelines/287"`)입니다. |
| `head_pipeline.detailed_status.favicon`                     | 문자열   | 상태 파비콘의 경로입니다. |
| `head_pipeline.detailed_status.group`                       | 문자열   | 상태 그룹(예: `success`)입니다. |
| `head_pipeline.detailed_status.has_details`                 | 부울  | 설정되면 상세 보기를 사용할 수 있습니다. |
| `head_pipeline.detailed_status.icon`                        | 문자열   | 상태 아이콘 이름(예: `"status_success"`)입니다. |
| `head_pipeline.detailed_status.illustration.content`        | 문자열   | 일러스트레이션의 콘텐츠 텍스트(예: `"This job depends on upstream jobs that need to succeed in order for this job to be triggered"`)입니다. |
| `head_pipeline.detailed_status.illustration.image`          | 문자열   | 일러스트레이션 이미지의 경로입니다. |
| `head_pipeline.detailed_status.illustration.size`           | 문자열   | 일러스트레이션의 크기입니다. |
| `head_pipeline.detailed_status.illustration.title`          | 문자열   | 일러스트레이션의 제목(예: `"This job has not been triggered yet"`)입니다. |
| `head_pipeline.detailed_status.label`                       | 문자열   | 파이프라인의 상태 레이블(예: `"passed"`)입니다. |
| `head_pipeline.detailed_status.text`                        | 문자열   | 파이프라인의 상태 텍스트(예: `"passed"`)입니다. |
| `head_pipeline.detailed_status.tooltip`                     | 문자열   | 파이프라인의 도구 설명 텍스트(예: `"passed"`)입니다. |
| `head_pipeline.duration`                                    | 정수  | 파이프라인 실행에 소요된 시간(초 단위)입니다. |
| `head_pipeline.finished_at`                                 | 날짜시간 | 파이프라인이 완료된 타임스탐프입니다. |
| `head_pipeline.id`                                          | 정수  | 파이프라인의 고유 숫자 식별자입니다. `ci_pipelines` 테이블의 외래 키입니다. |
| `head_pipeline.iid`                                         | 정수  | 파이프라인의 내부 숫자 ID입니다. |
| `head_pipeline.project_id`                                  | 정수  | 파이프라인을 포함하는 프로젝트의 숫자 ID입니다. |
| `head_pipeline.queued_duration`                             | 정수  | 대기열에 소요된 시간(초 단위)입니다. |
| `head_pipeline.ref`                                         | 문자열   | 파이프라인이 실행되는 Git 참조(브랜치 또는 태그)의 이름입니다. |
| `head_pipeline.sha`                                         | 문자열   | 파이프라인을 트리거한 커밋의 SHA입니다. |
| `head_pipeline.source`                                      | 문자열   | 파이프라인이 트리거된 방식입니다. 예를 들어 `push`, `merge_request_event` 또는 `api` |
| `head_pipeline.started_at`                                  | 날짜시간 | 파이프라인이 실행을 시작한 타임스탐프입니다. |
| `head_pipeline.status`                                      | 문자열   | 파이프라인의 현재 상태입니다. 가능한 값: `success`, `failed`, `running`, `pending` |
| `head_pipeline.tag`                                         | 부울  | `true`이 참일 경우, 파이프라인이 Git 태그에서 실행되고 있습니다. |
| `head_pipeline.updated_at`                                  | 날짜시간 | 파이프라인이 마지막으로 업데이트된 시간의 타임스탬프입니다. |
| `head_pipeline.user[]`                                      | 객체   | 파이프라인을 트리거한 사용자 정보를 포함하는 객체입니다. |
| `head_pipeline.user.avatar_url`                             | 문자열   | 사용자 프로필 사진의 전체 URL입니다. |
| `head_pipeline.user.id`                                     | 정수  | 파이프라인을 트리거한 사용자의 고유 ID입니다. |
| `head_pipeline.user.locked`                                 | 부울  | `true`이 참일 경우, 파이프라인을 트리거한 사용자 계정이 인증 시도 실패로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `head_pipeline.user.name`                                   | 문자열   | 파이프라인을 트리거한 사용자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `head_pipeline.user.public_email`                           | 문자열   | 파이프라인을 트리거한 사용자의 공개 이메일 주소입니다. |
| `head_pipeline.user.state`                                  | 문자열   | 파이프라인을 트리거한 사용자의 계정 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `head_pipeline.user.username`                               | 문자열   | 파이프라인을 트리거한 사용자의 사용자 이름입니다. |
| `head_pipeline.user.web_url`                                | 문자열   | 파이프라인을 트리거한 사용자의 프로필 페이지 전체 URL입니다. |
| `head_pipeline.web_url`                                     | 문자열   | 파이프라인 페이지의 전체 URL입니다. |
| `head_pipeline.yaml_errors`                                 | 문자열   | 모든 YAML 구성 오류입니다. 예를 들어, `widgets:build: needs 'widgets:test'`) |
| `id`                                                        | 정수  | 머지 리퀘스트의 ID입니다. |
| `iid`                                                       | 정수  | 머지 리퀘스트의 내부 ID입니다. |
| `imported`                                                  | 부울  | `true`이면 머지 리퀘스트를 가져왔습니다. |
| `imported_from`                                             | 문자열   | `Bitbucket`과 같은 가져오기 소스입니다. |
| `labels[]`                                                  | 배열    | 머지 리퀘스트에 할당된 레이블의 배열입니다. `with_labels_details`이 `true`이면 각 레이블에 대한 배열을 반환합니다. |
| `labels.archived`                                           | 부울  | `with_labels_details`이 `true`이면 레이블이 보관됩니다. |
| `labels.color`                                              | 문자열   | `with_labels_details`이 `true`이면 레이블의 배경색입니다. |
| `labels.description`                                        | 문자열   | `with_labels_details`이 `true`이면 레이블의 설명 텍스트입니다. `null`이면 레이블에 설명이 없습니다. |
| `labels.description_html`                                   | 문자열   | `with_labels_details`이 `true`이면 레이블의 HTML로 렌더링된 설명입니다. `null`이면 레이블에 설명이 없습니다. |
| `labels.id`                                                 | 정수  | `with_labels_details`이 `true`이면 레이블의 고유 ID입니다. |
| `labels.name`                                               | 문자열   | `with_labels_details`이 `true`이면 레이블의 이름입니다. |
| `labels.text_color`                                         | 문자열   | `with_labels_details`이 `true`이면 레이블의 텍스트 색상입니다. |
| `latest_build_finished_at`                                  | 날짜/시간 | 머지 리퀘스트의 최신 빌드가 완료된 시간의 타임스탬프입니다. |
| `latest_build_started_at`                                   | 날짜/시간 | 머지 리퀘스트의 최신 빌드가 시작된 시간의 타임스탬프입니다. |
| `merge_after`                                               | 날짜시간 | 설정되면 머지 리퀘스트를 병합할 수 있는 이후의 타임스탬프입니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)되었습니다. |
| `merge_commit_sha`                                          | 문자열   | 설정되면 머지 리퀘스트 커밋의 SHA입니다. 병합될 때까지 `null`을 반환합니다. |
| `merge_error`                                               | 문자열   | 설정된 경우, 병합이 실패할 때 표시되는 오류 메시지입니다. 병합 가능성을 확인하려면 `detailed_merge_status`을 대신 사용하세요. |
| `merge_status`                                              | 문자열   | 머지 리퀘스트의 상태입니다. 모든 가능한 상태를 고려하는 `detailed_merge_status` 대신 사용합니다. `has_conflicts` 속성에 영향을 미칩니다. 응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요. [GitLab 15.6에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204).  |
| `merge_user[]`                                              | 객체   | 이 머지 리퀘스트를 병합한 사용자, 자동 병합으로 설정한 사용자, 또는 `null`입니다. |
| `merge_when_pipeline_succeeds`                              | 부울  | `true`이면 머지 리퀘스트가 자동 병합으로 설정됩니다. |
| `merged_at`                                                 | 날짜시간 | 머지 리퀘스트를 병합할 때의 타임스탬프입니다. |
| `merged_by[]`                                               | 객체   | 이 머지 리퀘스트를 병합했거나 자동 병합으로 설정한 사용자입니다. GitLab 14.7에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)되었으며, [API 버전 5](https://gitlab.com/groups/gitlab-org/-/epics/8115)에서 제거될 예정입니다. `merge_user` 대신 사용합니다.  |
| `milestone[]`                                               | 객체   | 머지 리퀘스트에 할당된 마일스톤에 대한 정보가 포함된 객체입니다. |
| `milestone.created_at`                                      | 날짜시간 | 마일스톤을 생성할 때의 타임스탬프입니다. |
| `milestone.description`                                     | 문자열   | 마일스톤의 설명 텍스트입니다. `null`이면 마일스톤에 설명이 없습니다. |
| `milestone.due_date`                                        | 날짜     | 마일스톤의 기한입니다. `null`이면 마일스톤에 기한이 없습니다. |
| `milestone.expired`                                         | 부울  | `true`이면 마일스톤이 만료되었습니다. |
| `milestone.group_id`                                        | 정수  | 마일스톤이 속한 그룹의 ID입니다. 마일스톤이 그룹 마일스톤인 경우에만 포함됩니다. |
| `milestone.id`                                              | 정수  | 마일스톤의 고유 ID입니다. |
| `milestone.iid`                                             | 정수  | 프로젝트 또는 그룹 내에서 마일스톤의 내부 ID입니다. |
| `milestone.project_id`                                      | 정수  | 마일스톤이 속한 프로젝트의 ID입니다. 마일스톤이 프로젝트 마일스톤인 경우에만 포함됩니다. |
| `milestone.start_date`                                      | 날짜     | 마일스톤의 시작 날짜입니다. `null`이면 마일스톤에 시작 날짜가 없습니다 |
| `milestone.state`                                           | 문자열   | 마일스톤의 현재 상태입니다(예: `active` 또는 `closed`). |
| `milestone.title`                                           | 문자열   | 마일스톤의 이름입니다. |
| `milestone.updated_at`                                      | 날짜시간 | 마일스톤을 마지막으로 업데이트할 때의 타임스탬프입니다. |
| `milestone.web_url`                                         | 문자열   | 마일스톤을 보기 위한 전체 웹 URL입니다. |
| `pipeline[]`                                                | 객체   | 머지 리퀘스트의 브랜치 HEAD에서 실행되는 파이프라인입니다. `head_pipeline`을 대신 사용하는 것이 좋습니다. 더 많은 정보를 포함합니다. |
| `prepared_at`                                               | 날짜시간 | 머지 리퀘스트를 준비할 때의 타임스탬프입니다. 이 필드는 모든 [준비 단계](#preparation-steps)가 완료된 후 한 번 채워지며, 더 많은 변경 사항이 추가되면 업데이트되지 않습니다. |
| `project_id`                                                | 정수  | 머지 리퀘스트를 포함하는 프로젝트의 ID입니다. |
| `rebase_in_progress`                                        | 부울  | `true`이 참일 경우, Sidekiq이 이 브랜치에서 리베이스 작업을 실행 중입니다. |
| `reference`                                                 | 문자열   | 지원 중단됨. `references` 대신 사용합니다. GitLab 12.7에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354)되었으며, [API 버전 5](https://gitlab.com/groups/gitlab-org/-/epics/8115)에서 제거될 예정입니다. `references` 대신 사용합니다.  |
| `references[]`                                              | 객체   | 머지 리퀘스트의 모든 내부 참조가 포함된 객체입니다. |
| `references.full`                                           | 문자열   | `gitlab-org/gitlab!123`과 같은 전체 프로젝트 경로를 포함한 머지 리퀘스트에 대한 완전한 참조입니다. 그룹 또는 프로젝트 간에 요청할 때 `references.relative`와 동일합니다. |
| `references.relative`                                       | 문자열   | 특정 프로젝트 또는 그룹에 상대적인 참조: 현재 프로젝트의 머지 리퀘스트의 경우 `!123`, 같은 그룹의 다른 프로젝트의 경우 `other-project!123`. |
| `references.short`                                          | 문자열   | `!123`과 같은 머지 리퀘스트에 대한 가장 짧은 가능한 참조입니다. 머지 리퀘스트의 프로젝트에서 가져올 때 `references.relative`와 동일합니다. |
| `reviewers[]`                                               | 배열    | 머지 리퀘스트의 검토자입니다. |
| `reviewers.avatar_url`                                      | 문자열   | 검토자의 아바타 이미지에 대한 전체 URL입니다. |
| `reviewers.id`                                              | 정수  | 검토자의 고유 ID입니다. |
| `reviewers.locked`                                          | 부울  | `true`이면 검토자의 계정이 실패한 인증 시도로 인해 잠겨 있으며, 잠금이 만료되거나 관리자가 계정을 잠금 해제할 때까지 로그인할 수 없습니다. |
| `reviewers.name`                                            | 문자열   | 검토자의 표시 이름입니다. 현재 사용자의 권한을 기반으로 수정될 수 있습니다. |
| `reviewers.public_email`                                    | 문자열   | 검토자의 공개 이메일 주소입니다. |
| `reviewers.state`                                           | 문자열   | 검토자의 사용자 계정의 현재 상태입니다. 가능한 값: `active`, `blocked` 또는 `deactivated`. |
| `reviewers.username`                                        | 문자열   | 머지 리퀘스트 검토자의 사용자 이름입니다. |
| `reviewers.web_url`                                         | 문자열   | 검토자 프로필 페이지에 대한 전체 URL입니다. |
| `sha`                                                       | 문자열   | 소스 브랜치의 헤드 커밋의 SHA입니다. |
| `should_remove_source_branch`                               | 부울  | `true`이면 병합 후 소스 브랜치를 제거합니다. |
| `source_branch`                                             | 문자열   | 소스 브랜치의 이름입니다. |
| `source_project_id`                                         | 정수  | 소스 브랜치의 프로젝트의 ID입니다. |
| `squash`                                                    | 부울  | `true`이면 병합할 때 커밋을 스쿼시합니다. |
| `squash_commit_sha`                                         | 문자열   | 설정되면 스쿼시 커밋의 SHA입니다. 병합될 때까지 비어 있습니다. |
| `squash_on_merge`                                           | 부울  | `true`이면 병합할 때 커밋을 스쿼시합니다. |
| `state`                                                     | 문자열   | 머지 리퀘스트의 현재 상태입니다. 가능한 값: `opened`, `closed`, `merged` 또는 `locked`. |
| `subscribed`                                                | 부울  | `true`이 참일 경우, 현재 인증된 사용자가 이 머지 리퀘스트를 구독합니다. |
| `target_branch`                                             | 문자열   | 대상 브랜치의 이름입니다. |
| `target_project_id`                                         | 정수  | 대상 브랜치의 프로젝트의 ID입니다. |
| `task_completion_status[]`                                  | 객체   | 작업 목록 완료 상태에 대한 정보가 포함된 객체입니다. |
| `task_completion_status.completed_count`                    | 정수  | 머지 리퀘스트 설명의 완료된 작업 목록 항목 수입니다. 머지 리퀘스트에 설명이 없거나 작업 목록 항목이 없으면 `0`을 반환합니다. |
| `task_completion_status.count`                              | 정수  | 머지 리퀘스트 설명에서 발견된 총 작업 목록 항목 수입니다. 머지 리퀘스트에 설명이 없거나 작업 목록 항목이 없으면 `0`을 반환합니다. |
| `time_stats[]`                                              | 객체   | 이 머지 리퀘스트에 대한 시간 추적 정보가 포함된 객체입니다. |
| `time_stats.human_time_estimate`                            | 문자열   | `time_stats.time_estimate`의 사람이 읽을 수 있는 형식입니다(예: `3h 30m`). |
| `time_stats.human_total_time_spent`                         | 문자열   | `time_stats.total_time_spent`의 사람이 읽을 수 있는 형식입니다(예: `3h 30m`). |
| `time_stats.time_estimate`                                  | 정수  | 머지 리퀘스트를 완료하는 데 필요한 예상 시간(초)입니다. |
| `time_stats.total_time_spent`                               | 정수  | 머지 리퀘스트에 소비한 총 시간(초)입니다. |
| `title`                                                     | 문자열   | 머지 리퀘스트 제목입니다. |
| `updated_at`                                                | 날짜/시간 | 머지 리퀘스트를 마지막으로 업데이트할 때의 타임스탬프입니다. |
| `upvotes`                                                   | 정수  | 머지 리퀘스트의 업보트 수입니다. |
| `user[]`                                                    | 객체   | 머지 리퀘스트를 요청한 사용자의 권한입니다. |
| `user.can_merge`                                            | 부울  | `true`이 참일 경우, 현재 인증된 사용자가 이 머지 리퀘스트를 병합할 수 있습니다. |
| `user_notes_count`                                          | 정수  | 사용자 댓글 수입니다. |
| `web_url`                                                   | 문자열   | 머지 리퀘스트를 보기 위한 웹 URL입니다. |
| `work_in_progress`                                          | 부울  | 지원 중단됨. `draft` 대신 사용합니다. |

응답 예시:

```json
{
  "id": 155016530,
  "iid": 133,
  "project_id": 15513260,
  "title": "Manual job rules",
  "description": "",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "created_at": "2022-05-13T07:26:38.402Z",
  "updated_at": "2022-05-14T03:38:31.354Z",
  "merged_by": null, // Deprecated and will be removed in API v5. Use `merge_user` instead.
  "merge_user": null,
  "merged_at": null,
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "target_branch": "main",
  "source_branch": "manual-job-rules",
  "user_notes_count": 0,
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 4155490,
    "username": "marcel.amirault",
    "name": "Marcel Amirault",
    "state": "active",
    "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
    "web_url": "https://gitlab.com/marcel.amirault"
  },
  "assignees": [],
  "assignee": null,
  "reviewers": [],
  "source_project_id": 15513260,
  "target_project_id": 15513260,
  "labels": [],
  "draft": false,
  "work_in_progress": false,
  "milestone": null,
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "mergeable",
  "sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "discussion_locked": null,
  "should_remove_source_branch": null,
  "force_remove_source_branch": true,
  "reference": "!133", // Deprecated. Use `references` instead.
  "references": {
    "short": "!133",
    "relative": "!133",
    "full": "marcel.amirault/test-project!133"
  },
  "web_url": "https://gitlab.com/marcel.amirault/test-project/-/merge_requests/133",
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "task_completion_status": {
    "count": 0,
    "completed_count": 0
  },
  "has_conflicts": false,
  "blocking_discussions_resolved": true,
  "approvals_before_merge": null, // deprecated, use [Merge request approvals API](merge_request_approvals.md)
  "subscribed": true,
  "changes_count": "1",
  "latest_build_started_at": "2022-05-13T09:46:50.032Z",
  "latest_build_finished_at": null,
  "first_deployed_to_production_at": null,
  "pipeline": { // Use `head_pipeline` instead.
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940"
  },
  "head_pipeline": {
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940",
    "before_sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "tag": false,
    "yaml_errors": null,
    "user": {
      "id": 4155490,
      "username": "marcel.amirault",
      "name": "Marcel Amirault",
      "state": "active",
      "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
      "web_url": "https://gitlab.com/marcel.amirault"
    },
    "started_at": "2022-05-13T09:46:50.032Z",
    "finished_at": "2022-05-13T09:47:20.697Z",
    "committed_at": null,
    "duration": 30,
    "queued_duration": 10,
    "coverage": null,
    "detailed_status": {
      "icon": "status_failed",
      "text": "failed",
      "label": "failed",
      "group": "failed",
      "tooltip": "failed",
      "has_details": true,
      "details_path": "/marcel.amirault/test-project/-/pipelines/538317940",
      "illustration": null,
      "favicon": "/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png"
    },
    "archived": false
  },
  "diff_refs": {
    "base_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab",
    "head_sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
    "start_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab"
  },
  "merge_error": null,
  "first_contribution": false,
  "user": {
    "can_merge": true
  },
  "approvals_before_merge": { // Available for GitLab Premium and Ultimate tiers only
    "id": 1,
    "title": "test1",
    "approvals_before_merge": null
  },
}
```

### 단일 머지 리퀘스트 응답 참고 사항 {#single-merge-request-response-notes}

각 머지 리퀘스트의 병합 가능성(`merge_status`)은 이 끝점에 대한 요청이 만들어질 때 비동기식으로 확인됩니다. 업데이트된 상태를 얻으려면 이 API 끝점을 폴링하세요. 이는 `has_conflicts` 속성에 영향을 줍니다. `merge_status`에 따라 달라집니다. `merge_status`이 `cannot_be_merged`가 아닌 경우`false`을 반환합니다.

### 머지 상태 {#merge-status}

모든 가능한 상태를 고려하기 위해 `merge_status` 대신 `detailed_merge_status`을 사용하세요.

- `detailed_merge_status` 필드는 머지 리퀘스트와 관련된 다음 값 중 하나를 포함할 수 있습니다:
  - `approvals_syncing`:  머지 리퀘스트의 승인이 동기화 중입니다.
  - `checking`:  Git이 유효한 병합이 가능한지 테스트하고 있습니다.
  - `ci_must_pass`:  병합 전에 CI/CD 파이프라인이 성공해야 합니다.
  - `ci_still_running`:  CI/CD 파이프라인이 여전히 실행 중입니다.
  - `commits_status`:  소스 브랜치는 존재해야 하며 커밋을 포함해야 합니다.
  - `conflict`:  소스 및 대상 브랜치 간에 충돌이 존재합니다.
  - `discussions_not_resolved`:  병합 전에 모든 토론이 해결되어야 합니다.
  - `draft_status`:  머지 리퀘스트가 초안이기 때문에 병합할 수 없습니다.
  - `jira_association_missing`:  제목 또는 설명이 Jira 이슈를 참조해야 합니다. 구성하려면, [병합할 머지 리퀘스트에 대해 연결된 Jira 이슈 필요](../integration/jira/issues.md#require-associated-jira-issue-for-merge-requests-to-be-merged)을 참조하세요.
  - `mergeable`:  브랜치가 대상 브랜치로 깔끔하게 병합될 수 있습니다.
  - `merge_request_blocked`:  다른 머지 리퀘스트에 의해 차단되었습니다.
  - `merge_time`:  지정된 시간 이후에만 병합될 수 있습니다.
  - `need_rebase`:  머지 리퀘스트는 리베이스되어야 합니다.
  - `not_approved`:  병합 전에 승인이 필요합니다.
  - `not_open`:  머지 리퀘스트는 병합 전에 열려 있어야 합니다.
  - `preparing`:  머지 리퀘스트 diff가 생성 중입니다.
  - `requested_changes`:  머지 리퀘스트에는 변경을 요청한 검토자가 있습니다.
  - `security_policy_pipeline_check`:  보안 정책이 적용될 때 머지 리퀘스트가 병합되기 전에 최신 커밋의 모든 파이프라인이 성공해야 합니다.
  - `security_policy_violations`:  모든 보안 정책을 충족해야 합니다.
  - `status_checks_must_pass`:  병합 전에 모든 상태 확인이 통과해야 합니다.
  - `unchecked`:  Git이 아직 유효한 병합이 가능한지 테스트하지 않았습니다.
  - `locked_paths`:  다른 사용자가 잠금한 경로는 기본 브랜치로 병합하기 전에 잠금을 해제해야 합니다.
  - `locked_lfs_files`:  다른 사용자가 잠금한 LFS 파일은 병합 전에 잠금을 해제해야 합니다.
  - `title_regex`:  제목이 예상 정규식과 일치하는지 확인합니다(프로젝트 설정에서 구성된 경우).

### 준비 단계 {#preparation-steps}

`prepared_at` 필드는 다음 단계가 완료된 후에만 채워집니다:

- diff를 생성합니다.
- 파이프라인을 생성합니다.
- 병합 가능성을 확인합니다.
- 모든 Git LFS 객체를 연결합니다.
- 알림을 보냅니다.

`prepared_at` 필드는 머지 리퀘스트에 더 많은 변경사항이 추가되면 업데이트되지 않습니다.

## 머지 리퀘스트 참여자 검색 {#retrieve-merge-request-participants}

머지 리퀘스트의 참여자를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/participants
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

응답 예시:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  },
  {
    "id": 2,
    "name": "John Doe2",
    "username": "user2",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
    "web_url": "http://localhost/user2"
  }
]
```

## 머지 리퀘스트 검토자 검색 {#retrieve-merge-request-reviewers}

머지 리퀘스트의 검토자를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/reviewers
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

응답 예시:

```json
[
  {
    "user": {
      "id": 1,
      "name": "John Doe1",
      "username": "user1",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
      "web_url": "http://localhost/user1"
    },
    "state": "unreviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  },
  {
    "user": {
      "id": 2,
      "name": "John Doe2",
      "username": "user2",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
      "web_url": "http://localhost/user2"
    },
    "state": "reviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  }
]
```

## 머지 리퀘스트 커밋 검색 {#retrieve-merge-request-commits}

머지 리퀘스트의 커밋을 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/commits
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                     | 유형         | 설명 |
|-------------------------------|--------------|-------------|
| `commits`                     | 객체 배열 | 머지 리퀘스트의 커밋입니다. |
| `commits[].id`                | 문자열       | 커밋의 ID입니다. |
| `commits[].short_id`          | 문자열       | 커밋의 짧은 ID입니다. |
| `commits[].created_at`        | 날짜/시간     | `committed_date` 필드와 동일합니다. |
| `commits[].parent_ids`        | 배열        | 부모 커밋의 ID입니다. |
| `commits[].title`             | 문자열       | 커밋 제목입니다. |
| `commits[].message`           | 문자열       | 커밋 메시지. |
| `commits[].author_name`       | 문자열       | 커밋 작성자의 이름입니다. |
| `commits[].author_email`      | 문자열       | 커밋 작성자의 이메일 주소입니다. |
| `commits[].authored_date`     | 날짜/시간     | 커밋 작성 날짜 및 시간입니다. |
| `commits[].committer_name`    | 문자열       | 커밋 작업자의 이름입니다. |
| `commits[].committer_email`   | 문자열       | 커밋 작업자의 이메일 주소입니다. |
| `commits[].committed_date`    | 날짜/시간     | 커밋 날짜 및 시간입니다. |
| `commits[].trailers`          | 객체       | 커밋에 대해 구문 분석된 Git 트레일러입니다. 중복 키는 마지막 값만 포함합니다. |
| `commits[].extended_trailers` | 객체       | 커밋에 대해 구문 분석된 Git 트레일러입니다. |
| `commits[].web_url`           | 문자열       | 머지 리퀘스트의 웹 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/commits"
```

응답 예시:

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T11:50:22+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T11:50:22+03:00",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T09:06:12+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T09:06:12+03:00",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
  }
]
```

## 머지 리퀘스트 종속성 검색 {#retrieve-merge-request-dependencies}

머지 리퀘스트가 병합되기 전에 해결해야 하는 종속성을 검색합니다.

> [!note]
> 사용자가 차단 머지 리퀘스트에 액세스할 수 없으면, `blocking_merge_request` 속성이 반환되지 않습니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blocks
```

지원되는 속성:

| 속성           | 유형           | 필수 | 설명 |
|---------------------|----------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks"
```

응답 예시:

```json
[
  {
    "id": 1,
    "blocking_merge_request": {
      "id": 145,
      "iid": 12,
      "project_id": 7,
      "title": "Interesting MR",
      "description": "Does interesting things.",
      "state": "opened",
      "created_at": "2024-07-05T21:29:11.172Z",
      "updated_at": "2024-07-05T21:29:11.172Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "v2.x",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        },
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "unchecked",
      "detailed_merge_status": "unchecked",
      "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!12",
      "references": {
        "short": "!12",
        "relative": "!12",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 146,
      "iid": 13,
      "project_id": 7,
      "title": "Really cool MR",
      "description": "Adds some stuff",
      "state": "opened",
      "created_at": "2024-07-05T21:31:34.811Z",
      "updated_at": "2024-07-27T02:57:08.054Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "remove-from",
      "user_notes_count": 0,
      "upvotes": 1,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhose/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": {
        "id": 59,
        "iid": 6,
        "project_id": 7,
        "title": "Sprint 1718897375",
        "description": "Accusantium omnis iusto a animi.",
        "state": "active",
        "created_at": "2024-06-20T15:29:35.739Z",
        "updated_at": "2024-06-20T15:29:35.739Z",
        "due_date": null,
        "start_date": null,
        "expired": false,
        "web_url": "https://localhost/my-group/my-project/-/milestones/6"
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "not_approved",
      "sha": "daa75b9b17918f51f43866ff533987fda71375ea",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": "2024-07-11T18:50:46.215Z",
      "reference": "!13",
      "references": {
        "short": "!13",
        "relative": "!13",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/13",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## 머지 리퀘스트 종속성 삭제 {#delete-a-merge-request-dependency}

머지 리퀘스트 종속성을 삭제합니다.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/blocks/:block_id
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 인증된 사용자가 소유한 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `block_id`          | 정수           | 예      | 블록의 ID입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks/1"
```

반환:

- 종속성이 성공적으로 삭제되면 `204 No Content`을 반환합니다.
- 사용자가 머지 리퀘스트를 업데이트할 수 있는 권한이 없으면 `403 Forbidden`을 반환합니다.
- 사용자가 차단 머지 리퀘스트를 읽을 수 있는 권한이 없으면 `403 Forbidden`을 반환합니다.

## 머지 리퀘스트 종속성 생성 {#create-a-merge-request-dependency}

머지 리퀘스트 종속성을 생성합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/blocks
```

지원되는 속성:

| 속성                    | 유형              | 필수    | 설명 |
|------------------------------|-------------------|-------------|-------------|
| `id`                         | 정수 또는 문자열 | 예         | 인증된 사용자가 소유한 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid`          | 정수           | 예         | 차단될 머지 리퀘스트의 내부 ID입니다. |
| `blocking_merge_request_id`  | 정수           | 조건부 | 차단 머지 리퀘스트의 전역 ID입니다. `blocking_merge_request_iid`이 제공되지 않으면 필수입니다. |
| `blocking_merge_request_iid` | 정수           | 조건부 | 차단 머지 리퀘스트의 IID입니다. `blocking_merge_request_id`이 제공되지 않으면 필수입니다. |
| `blocking_project_id`        | 정수 또는 문자열 | 아니요          | 차단 머지 리퀘스트를 포함하는 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. `blocking_merge_request_iid`이 다른 프로젝트의 머지 리퀘스트를 참조할 때 필수입니다. 현재 프로젝트로 기본 설정됩니다. |

IID를 사용한 요청 예시(같은 프로젝트):

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_iid=2"
```

IID를 사용한 요청 예시(프로젝트 간):

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_iid=5&blocking_project_id=2"
```

전역 ID를 사용한 요청 예시(레거시 방법):

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_id=12345"
```

반환:

- 종속성이 성공적으로 생성되면 `201 Created`을 반환합니다.
- 차단 머지 리퀘스트를 저장하지 못하면 `400 Bad request`을 반환합니다.
- 사용자가 차단 머지 리퀘스트를 읽을 수 있는 권한이 없으면 `403 Forbidden`을 반환합니다.
- 차단 머지 리퀘스트를 찾을 수 없으면 `404 Not found`을 반환합니다.
- 블록이 이미 존재하면 `409 Conflict`을 반환합니다.

응답 예시:

```json
{
  "id": 1,
  "blocking_merge_request": {
    "id": 145,
    "iid": 12,
    "project_id": 7,
    "title": "Interesting MR",
    "description": "Does interesting things.",
    "state": "opened",
    "created_at": "2024-07-05T21:29:11.172Z",
    "updated_at": "2024-07-05T21:29:11.172Z",
    "merged_by": null,
    "merge_user": null,
    "merged_at": null,
    "merge_after": "2018-09-07T11:16:00.000Z",
    "closed_by": null,
    "closed_at": null,
    "target_branch": "master",
    "source_branch": "v2.x",
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 2,
      "username": "aiguy123",
      "name": "AI GUY",
      "state": "active",
      "locked": false,
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "https://localhost/aiguy123"
    },
    "assignees": [
      {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      }
    ],
    "assignee": {
      "id": 2,
      "username": "aiguy123",
      "name": "AI GUY",
      "state": "active",
      "locked": false,
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "https://localhost/aiguy123"
    },
    "reviewers": [
      {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/root"
      }
    ],
    "source_project_id": 7,
    "target_project_id": 7,
    "labels": [],
    "draft": false,
    "imported": false,
    "imported_from": "none",
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "detailed_merge_status": "unchecked",
    "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "prepared_at": null,
    "reference": "!12",
    "references": {
      "short": "!12",
      "relative": "!12",
      "full": "my-group/my-project!12"
    },
    "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "squash_on_merge": false,
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true,
    "approvals_before_merge": null
  },
  "project_id": 7
}
```

## 차단된 머지 리퀘스트 검색 {#retrieve-blocked-merge-requests}

머지 리퀘스트에 의해 차단된 머지 리퀘스트를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blockees
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blockees"
```

응답 예시:

```json
[
  {
    "id": 18,
    "blocking_merge_request": {
      "id": 71,
      "iid": 10,
      "project_id": 7,
      "title": "At quaerat occaecati voluptate ex explicabo nisi.",
      "description": "Aliquid distinctio officia corrupti ad nemo natus ipsum culpa.",
      "state": "merged",
      "created_at": "2024-07-05T19:44:14.023Z",
      "updated_at": "2024-07-05T19:44:14.023Z",
      "merged_by": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merge_user": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merged_at": "2024-06-26T19:44:14.123Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "Brickwood-Brunefunc-417",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "can_be_merged",
      "detailed_merge_status": "not_open",
      "merge_after": null,
      "sha": null,
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": null,
      "prepared_at": null,
      "reference": "!10",
      "references": {
        "short": "!10",
        "relative": "!10",
        "full": "flightjs/Flight!10"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/10",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 176,
      "iid": 14,
      "project_id": 7,
      "title": "second_mr",
      "description": "Signed-off-by: Lucas Zampieri <lzampier@redhat.com>",
      "state": "opened",
      "created_at": "2024-07-08T19:12:29.089Z",
      "updated_at": "2024-08-27T19:27:17.045Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "second_mr",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/fc3634394c590e212d964e8e0a34c4d9b8c17c992f4d6d145d75f9c21c1c3b6e?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/root"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "commits_status",
      "merge_after": null,
      "sha": "3a576801e528db79a75fbfea463673054ff224fb",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!14",
      "references": {
        "short": "!14",
        "relative": "!14",
        "full": "flightjs/Flight!14"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/14",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## 머지 리퀘스트 변경사항 검색 {#retrieve-merge-request-changes}

> [!warning]
> 이 끝점은 GitLab 15.7에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/322117) API v5에서 [제거 예정](rest/deprecations.md)입니다. 대신 [머지 리퀘스트 diffs 목록](#list-merge-request-diffs) 끝점을 사용하세요.
> <!-- Do not remove line until endpoint is actually removed -->

머지 리퀘스트에 대한 정보(파일 및 변경사항 포함)를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `access_raw_diffs`  | 부울           | 아니요       | Gitaly를 통해 변경사항 diffs를 검색합니다. |
| `unidiff`           | 부울           | 아니요       | 변경사항 diffs를 [통합 diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) 형식으로 표시합니다. 기본값은 거짓입니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610). |

변경사항과 연결된 diffs는 API 또는 UI를 통해 반환된 다른 diffs와 동일한 크기 제한이 적용됩니다. 이러한 제한이 결과에 영향을 미칠 때, `overflow` 필드는 `true` 값을 포함합니다. `access_raw_diffs` 매개변수를 추가하여 이러한 제한 없이 diff 데이터를 검색합니다. 이는 데이터베이스가 아닌 Gitaly에서 직접 diffs에 액세스합니다. 이 방법은 일반적으로 더 느리고 더 많은 리소스를 사용하지만, 데이터베이스 기반 diffs에 적용된 크기 제한의 영향을 받지 않습니다. Gitaly에 내재된 제한이 여전히 적용됩니다.

응답 예시:

```json
{
  "id": 21,
  "iid": 1,
  "project_id": 4,
  "title": "Blanditiis beatae suscipit hic assumenda et molestias nisi asperiores repellat et.",
  "state": "reopened",
  "created_at": "2015-02-02T19:49:39.159Z",
  "updated_at": "2015-02-02T20:08:49.959Z",
  "target_branch": "secret_token",
  "source_branch": "version-1-9",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "name": "Chad Hamill",
    "username": "jarrett",
    "id": 5,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/b95567800f828948baf5f4160ebb2473?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/jarrett"
  },
  "assignee": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/root"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 4,
  "target_project_id": 4,
  "labels": [ ],
  "description": "Qui voluptatibus placeat ipsa alias quasi. Deleniti rem ut sint. Optio velit qui distinctio.",
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "mergeable",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "changes": [
    {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@ -1 +1 @@\ -1.9.7\ +1.9.8",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
    }
  ],
  "overflow": false
}
```

## 머지 리퀘스트 diffs 목록 {#list-merge-request-diffs}

{{< history >}}

- `generated_file` [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141576) GitLab 16.9 [플래그 사용](../administration/feature_flags/_index.md) `collapse_generated_diff_files`. 기본적으로 비활성화됨.
- GitLab 16.10에서 [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/432670).
- `generated_file` GitLab 16.11에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148478). 기능 플래그 `collapse_generated_diff_files` 제거됨.
- `collapsed` 및 `too_large` 응답 속성 [GitLab 18.4에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633).

{{< /history >}}

머지 리퀘스트에서 변경된 파일의 diffs를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/diffs
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `page`              | 정수           | 아니요       | 반환할 결과의 페이지입니다. 기본값은 1입니다. |
| `per_page`          | 정수           | 아니요       | 페이지당 결과 수입니다. 기본값은 20입니다. |
| `unidiff`           | 부울           | 아니요       | diffs를 [통합 diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) 형식으로 표시합니다. 기본값은 거짓입니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610). |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성        | 유형    | 설명 |
|------------------|---------|-------------|
| `a_mode`         | 문자열  | 파일의 이전 파일 모드입니다. |
| `b_mode`         | 문자열  | 파일의 새 파일 모드입니다. |
| `collapsed`      | 부울 | 파일 diffs는 제외되지만 요청 시 가져올 수 있습니다. |
| `deleted_file`   | 부울 | 파일이 제거되었습니다. |
| `diff`           | 문자열  | 파일에 적용된 변경사항의 diff 표현입니다. |
| `generated_file` | 부울 | 파일이 [생성됨으로 표시됨](../user/project/merge_requests/changes.md#collapse-generated-files). |
| `new_file`       | 부울 | 파일이 추가되었습니다. |
| `new_path`       | 문자열  | 파일의 새 경로입니다. |
| `old_path`       | 문자열  | 파일의 이전 경로입니다. |
| `renamed_file`   | 부울 | 파일이 이름이 변경되었습니다. |
| `too_large`      | 부울 | 파일 diffs는 제외되며 검색할 수 없습니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/diffs?page=1&per_page=2"
```

응답 예시:

```json
[
  {
    "old_path": "README",
    "new_path": "README",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@ -1 +1 @@\ -Title\ +README",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  },
  {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@\ -1.9.7\ +1.9.8",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }
]
```

> [!note]
> 이 끝점은 [머지 리퀘스트 diff 제한](../administration/instance_limits.md#diff-limits)의 영향을 받습니다. diff 제한을 초과하는 머지 리퀘스트는 제한된 결과를 반환합니다.

## 머지 리퀘스트 원본 diffs 표시 {#show-merge-request-raw-diffs}

머지 리퀘스트에서 변경된 파일의 원본 diffs를 표시합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/raw_diffs
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 프로그래밍 방식으로 사용할 원본 diff 응답:

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/raw_diffs"
```

응답 예시:

```diff
        diff --git a/lib/api/helpers.rb b/lib/api/helpers.rb
index 31525ad523553c8d7eff163db3e539058efd6d3a..f30e36d6fdf4cd4fa25f62e08ecdbf4a7b169681 100644
--- a/lib/api/helpers.rb
+++ b/lib/api/helpers.rb
@@ -944,6 +944,10 @@ def send_git_blob(repository, blob)
       body ''
     end

+    def send_git_diff(repository, diff_refs)
+      header(*Gitlab::Workhorse.send_git_diff(repository, diff_refs))
+    end
+
     def send_git_archive(repository, **kwargs)
       header(*Gitlab::Workhorse.send_git_archive(repository, **kwargs))

diff --git a/lib/api/merge_requests.rb b/lib/api/merge_requests.rb
index e02d9eea1852f19fe5311acda6aa17465eeb422e..f32b38585398a18fea75c11d7b8ebb730eeb3fab 100644
--- a/lib/api/merge_requests.rb
+++ b/lib/api/merge_requests.rb
@@ -6,6 +6,8 @@ class MergeRequests < ::API::Base
     include PaginationParams
     include Helpers::Unidiff

+    helpers ::API::Helpers::HeadersHelpers
+
     CONTEXT_COMMITS_POST_LIMIT = 20

     before { authenticate_non_get! }
```

> [!note]
> 이 끝점은 [머지 리퀘스트 diff 제한](../administration/instance_limits.md#diff-limits)의 영향을 받습니다. diff 제한을 초과하는 머지 리퀘스트는 제한된 결과를 반환합니다.

## 머지 리퀘스트 파이프라인 목록 {#list-merge-request-pipelines}

머지 리퀘스트의 모든 파이프라인을 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/pipelines
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

머지 리퀘스트 파이프라인 목록을 제한하려면 `page` 및 `per_page` 페이지 매김 매개변수를 사용하세요.

응답 예시:

```json
[
  {
    "id": 77,
    "sha": "959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d",
    "ref": "main",
    "status": "success"
  }
]
```

## 머지 리퀘스트 파이프라인 생성 {#create-merge-request-pipeline}

새 [머지 리퀘스트용 파이프라인](../ci/pipelines/merge_request_pipelines.md)을 생성합니다. 이 끝점에서 생성된 파이프라인은 일반적인 브랜치/태그 파이프라인을 실행하지 않습니다. 작업을 생성하려면 `.gitlab-ci.yml`을 `only: [merge_requests]`으로 구성하세요.

새 파이프라인은 다음과 같을 수 있습니다:

- 분리된 머지 리퀘스트 파이프라인.
- [병합된 결과 파이프라인](../ci/pipelines/merged_results_pipelines.md) [프로젝트 설정이 활성화된 경우](../ci/pipelines/merged_results_pipelines.md#enable-merged-results-pipelines).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/pipelines
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

응답 예시:

```json
{
  "id": 2,
  "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
  "ref": "refs/merge-requests/1/head",
  "status": "pending",
  "web_url": "http://localhost/user1/project1/pipelines/2",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://example.com"
  },
  "created_at": "2019-09-04T19:20:18.267Z",
  "updated_at": "2019-09-04T19:20:18.459Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_pending",
    "text": "pending",
    "label": "pending",
    "group": "pending",
    "tooltip": "pending",
    "has_details": false,
    "details_path": "/user1/project1/pipelines/2",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png"
  },
  "archived": false
}
```

## 머지 리퀘스트 생성 {#create-a-merge-request}

새 머지 리퀘스트를 생성합니다.

```plaintext
POST /projects/:id/merge_requests
```

| 속성                  | 유형              | 필수 | 설명 |
|----------------------------|-------------------|----------|-------------|
| `id`                       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `source_branch`            | 문자열            | 예      | 소스 브랜치입니다. |
| `target_branch`            | 문자열            | 예      | 대상 브랜치입니다. |
| `title`                    | 문자열            | 예      | MR 제목입니다. |
| `allow_collaboration`      | 부울           | 아니요       | 대상 브랜치로 병합할 수 있는 멤버의 커밋을 허용합니다. |
| `approvals_before_merge`   | 정수           | 아니요       | 이 머지 리퀘스트가 병합되기 전에 필요한 승인 수입니다(아래 참조). 승인 규칙을 구성하려면 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). Premium 및 Ultimate만 해당합니다. |
| `allow_maintainer_to_push` | 부울           | 아니요       | `allow_collaboration`의 별칭입니다. |
| `assignee_id`              | 정수           | 아니요       | 담당자 사용자 ID입니다. |
| `assignee_ids`             | 정수 배열     | 아니요       | 머지 리퀘스트를 할당할 사용자의 ID입니다. `0`로 설정하거나 모든 담당자를 할당 해제하려면 빈 값을 제공하세요. |
| `description`              | 문자열            | 아니요       | 머지 리퀘스트의 설명입니다. 1,048,576자로 제한됩니다. |
| `labels`                   | 문자열            | 아니요       | 머지 리퀘스트의 레이블(쉼표로 구분된 목록)입니다. 레이블이 아직 없으면, 새 프로젝트 레이블을 생성하고 머지 리퀘스트에 할당합니다. |
| `merge_after`              | 문자열            | 아니요       | 머지 리퀘스트를 병합할 수 있는 날짜입니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)되었습니다. |
| `milestone_id`             | 정수           | 아니요       | 마일스톤의 전역 ID입니다. `milestone`과 상호 배타적입니다. |
| `milestone`                | 문자열            | 아니요       | 머지 리퀘스트에 할당할 프로젝트 또는 상위 그룹 마일스톤의 제목입니다. 정확히 일치합니다(대소문자 구분). `milestone_id`과 상호 배타적입니다. |
| `remove_source_branch`     | 부울           | 아니요       | 머지 리퀘스트가 소스 브랜치를 제거해야 하는지 여부를 나타내는 플래그입니다. |
| `reviewer_ids`             | 정수 배열     | 아니요       | 머지 리퀘스트에 검토자로 추가할 사용자의 ID입니다. `0`로 설정하거나 비어 있으면 검토자를 추가하지 않습니다. |
| `squash`                   | 부울           | 아니요       | `true`이면 머지 시 모든 커밋을 단일 커밋으로 스쿼시합니다. 제공되지 않으면, [프로젝트의 스쿼시 옵션 설정](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)으로 기본 설정됩니다. 프로젝트 설정이 병합 시 이 값을 재정의할 수 있습니다. |
| `target_project_id`        | 정수           | 아니요       | 대상 프로젝트의 숫자 ID입니다. |

응답 예시:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "imported": false,
  "imported_from": "none",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요.

## 머지 리퀘스트 업데이트 {#update-a-merge-request}

기존 머지 리퀘스트를 업데이트합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid
```

| 속성                  | 유형              | 필수 | 설명 |
|----------------------------|-------------------|----------|-------------|
| `id`                       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid`        | 정수           | 예      | 머지 리퀘스트의 ID입니다. |
| `add_labels`               | 문자열            | 아니요       | 머지 리퀘스트에 추가할 레이블 이름(쉼표로 구분)입니다. 레이블이 아직 없으면, 새 프로젝트 레이블을 생성하고 머지 리퀘스트에 할당합니다. |
| `allow_collaboration`      | 부울           | 아니요       | 대상 브랜치로 병합할 수 있는 멤버의 커밋을 허용합니다. |
| `allow_maintainer_to_push` | 부울           | 아니요       | `allow_collaboration`의 별칭입니다. |
| `assignee_id`              | 정수           | 아니요       | 머지 리퀘스트를 할당할 사용자의 ID입니다. `0`로 설정하거나 모든 담당자를 할당 해제하려면 빈 값을 제공하세요. |
| `assignee_ids`             | 정수 배열     | 아니요       | 머지 리퀘스트를 할당할 사용자의 ID입니다. `0`로 설정하거나 모든 담당자를 할당 해제하려면 빈 값을 제공하세요. |
| `description`              | 문자열            | 아니요       | 머지 리퀘스트의 설명입니다. 1,048,576자로 제한됩니다. |
| `discussion_locked`        | 부울           | 아니요       | 머지 리퀘스트의 토론이 잠겨 있는지 여부를 나타내는 플래그입니다. 잠긴 토론에는 프로젝트 멤버만 댓글을 추가, 편집 또는 해결할 수 있습니다. |
| `labels`                   | 문자열            | 아니요       | 머지 리퀘스트에 대한 쉼표로 구분된 레이블 이름입니다. 모든 레이블을 할당 해제하려면 빈 문자열로 설정합니다. 레이블이 아직 없으면, 새 프로젝트 레이블을 생성하고 머지 리퀘스트에 할당합니다. |
| `merge_after`              | 문자열            | 아니요       | 머지 리퀘스트를 병합할 수 있는 날짜입니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)되었습니다. |
| `milestone_id`             | 정수           | 아니요       | 머지 리퀘스트에 할당할 마일스톤의 전역 ID입니다. `0`로 설정하거나 빈 값을 제공하여 마일스톤을 할당 해제합니다. `milestone`과 상호 배타적입니다. |
| `milestone`                | 문자열            | 아니요       | 머지 리퀘스트에 할당할 프로젝트 또는 상위 그룹 마일스톤의 제목입니다. 정확히 일치합니다(대소문자 구분). `milestone_id`과 상호 배타적입니다. |
| `remove_labels`            | 문자열            | 아니요       | 머지 리퀘스트에서 제거할 쉼표로 구분된 레이블 이름입니다. |
| `remove_source_branch`     | 부울           | 아니요       | 머지 리퀘스트가 소스 브랜치를 제거해야 하는지 여부를 나타내는 플래그입니다. |
| `reviewer_ids`             | 정수 배열     | 아니요       | 머지 리퀘스트의 검토자로 설정된 사용자의 ID입니다. 값을 `0`로 설정하거나 빈 값을 제공하여 모든 검토자를 설정 해제합니다. |
| `squash`                   | 부울           | 아니요       | `true`이면 머지 시 모든 커밋을 단일 커밋으로 스쿼시합니다. 제공되지 않으면, [프로젝트의 스쿼시 옵션 설정](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)으로 기본 설정됩니다. 프로젝트가 **요구** 또는 **허용하지 않음**으로 스쿼싱을 설정하면 병합 시간에 해당 설정이 우선합니다. |
| `state_event`              | 문자열            | 아니요       | 새 상태(종료/다시 열기) |
| `target_branch`            | 문자열            | 아니요       | 대상 브랜치입니다. |
| `title`                    | 문자열            | 아니요       | 머지 리퀘스트 제목입니다. |

최소한 하나의 필수가 아닌 속성을 포함해야 합니다.

응답 예시:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요.

## 머지 리퀘스트 삭제 {#delete-a-merge-request}

머지 리퀘스트를 삭제합니다. 관리자와 프로젝트 소유자만 머지 리퀘스트를 삭제할 수 있습니다.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/merge_requests/85"
```

## 머지 리퀘스트 병합 {#merge-a-merge-request}

이 API를 사용하여 머지 리퀘스트로 제출된 변경 사항을 수락하고 병합합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

지원되는 속성:

| 속성                      | 유형              | 필수 | 설명 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid`            | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `auto_merge`                   | 부울           | 아니요       | `true`이면 파이프라인이 성공하면 머지 리퀘스트가 병합됩니다. |
| `merge_commit_message`         | 문자열            | 아니요       | 사용자 지정 병합 커밋 메시지입니다. |
| `merge_when_pipeline_succeeds` | 부울           | 아니요       | [GitLab 17.11에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/521291) `auto_merge` 대신 사용합니다. |
| `sha`                          | 문자열            | 아니요       | 표시된 경우 이 SHA는 소스 브랜치의 HEAD와 일치해야 합니다. 검토된 커밋만 병합되도록 보장하는 데 사용합니다. |
| `should_remove_source_branch`  | 부울           | 아니요       | `true`이면 소스 브랜치를 제거합니다. |
| `squash_commit_message`        | 문자열            | 아니요       | 사용자 지정 스쿼시 커밋 메시지입니다. |
| `squash`                       | 부울           | 아니요       | `true`이면 머지 시 모든 커밋을 단일 커밋으로 스쿼시합니다. |

이 API는 실패 시 특정 HTTP 상태 코드를 반환합니다:

| HTTP 상태 | 메시지                                    | 이유 |
|-------------|--------------------------------------------|--------|
| `401`       | `401 Unauthorized`                         | 이 사용자는 이 머지 리퀘스트를 수락할 권한이 없습니다. |
| `405`       | `405 Method Not Allowed`                   | 머지 리퀘스트는 병합할 수 없습니다. |
| `409`       | `SHA does not match HEAD of source branch` | 제공된 `sha` 매개변수가 소스의 HEAD와 일치하지 않습니다. |
| `422`       | `Branch cannot be merged`                  | 머지 리퀘스트가 병합에 실패했습니다. |

응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요.

응답 예시:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

## 기본 병합 참조 경로로 병합 {#merge-to-default-merge-ref-path}

가능하면 머지 리퀘스트 소스 및 대상 브랜치 사이의 변경 사항을 대상 프로젝트 리포지토리의 `refs/merge-requests/:iid/merge` 참조로 병합합니다. 이 참조는 일반 병합 작업이 수행된 경우 대상 브랜치가 가질 상태입니다.

이 작업은 머지 리퀘스트 대상 브랜치 상태를 어떤 방식으로든 변경하지 않기 때문에 일반 병합 작업이 아닙니다.

이 참조(`refs/merge-requests/:iid/merge`)는 이 API에 요청을 제출할 때 반드시 덮어쓰이지는 않지만 참조가 최신 상태를 유지하도록 보장합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/merge_ref
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

이 API는 특정 HTTP 상태 코드를 반환합니다:

| HTTP 상태 | 메시지                          | 이유 |
|-------------|----------------------------------|--------|
| `200`       | _(없음)_                         | 성공합니다. `refs/merge-requests/:iid/merge`의 HEAD 커밋을 반환합니다. |
| `400`       | `Merge request is not mergeable` | 머지 리퀘스트에 충돌이 있습니다. |
| `400`       | `Merge ref cannot be updated`    |        |
| `400`       | `Unsupported operation`          | GitLab 데이터베이스가 읽기 전용 모드입니다. |

응답 예시:

```json
{
  "commit_id": "854a3a7a17acbcc0bbbea170986df1eb60435f34"
}
```

## 파이프라인이 성공하면 병합 취소 {#cancel-merge-when-pipeline-succeeds}

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

이 API는 특정 HTTP 상태 코드를 반환합니다:

| HTTP 상태 | 메시지  | 이유 |
|-------------|----------|--------|
| `201`       | _(없음)_ | 성공하거나 머지 리퀘스트가 이미 병합됨. |
| `406`       | `Can't cancel the automatic merge` | 머지 리퀘스트가 종료되었습니다. |

응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요.

응답 예시:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

## 머지 리퀘스트 리베이스 {#rebase-a-merge-request}

머지 리퀘스트의 `source_branch`을 `target_branch`에 대해 자동으로 리베이스합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/rebase
```

| 속성           | 유형           | 필수 | 설명 |
|---------------------|----------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수        | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `skip_ci`           | 부울        | 아니요       | CI 파이프라인 생성을 건너뛰려면 `true`로 설정합니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/rebase"
```

이 API는 특정 HTTP 상태 코드를 반환합니다:

| HTTP 상태 | 메시지                                    | 이유 |
|-------------|--------------------------------------------|--------|
| `202`       | _(메시지 없음)_ | 성공적으로 대기열에 추가됨. |
| `403`       | `Cannot push to source branch` | 머지 리퀘스트의 소스 브랜치에 푸시할 권한이 없습니다. |
| `403`       | `Source branch does not exist` | 머지 리퀘스트의 소스 브랜치에 푸시할 권한이 없습니다. |
| `403`       | `Source branch is protected from force push` | 머지 리퀘스트의 소스 브랜치에 푸시할 권한이 없습니다. |
| `409`       | `Failed to enqueue the rebase operation` | 오래 지속되는 이 요청을 차단했을 수 있습니다. |

요청이 대기열에 성공적으로 추가되면 응답은 다음을 포함합니다:

```json
{
  "rebase_in_progress": true
}
```

[머지 리퀘스트 검색](#retrieve-a-merge-request) 엔드포인트를 `include_rebase_in_progress` 매개변수로 폴링하여 비동기 요청의 상태를 확인할 수 있습니다.

리베이스 작업이 진행 중이면 응답은 다음을 포함합니다:

```json
{
  "rebase_in_progress": true,
  "merge_error": null
}
```

리베이스 작업이 성공적으로 완료되면 응답은 다음을 포함합니다:

```json
{
  "rebase_in_progress": false,
  "merge_error": null
}
```

리베이스 작업이 실패하면 응답은 다음을 포함합니다:

```json
{
  "rebase_in_progress": false,
  "merge_error": "Rebase failed. Please rebase locally"
}
```

## 머지 리퀘스트의 댓글 {#comments-on-merge-requests}

[주석](notes.md) 리소스가 댓글을 만듭니다.

## 병합 시 종료할 이슈 나열 {#list-issues-that-close-on-merge}

머지 리퀘스트가 병합될 때 종료될 이슈를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/closes_issues
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)과 GitLab 이슈 추적기를 사용할 때 다음 응답 속성을 반환합니다:

| 속성                   | 유형     | 설명 |
|-----------------------------|----------|-------------|
| `[].assignee`               | 객체   | 이슈의 첫 번째 담당자입니다. |
| `[].assignees`              | 배열    | 이슈의 담당자입니다. |
| `[].author`                 | 객체   | 이 이슈를 만든 사용자입니다. |
| `[].blocking_issues_count`  | 정수  | 이 이슈가 차단하는 이슈의 개수입니다. |
| `[].closed_at`              | 날짜/시간 | 이슈가 종료된 시간의 타임스탬프입니다. |
| `[].closed_by`              | 객체   | 이 이슈를 종료한 사용자입니다. |
| `[].confidential`           | 부울  | 이슈가 기밀인지 여부를 나타냅니다. |
| `[].created_at`             | 날짜/시간 | 이슈가 생성된 시간의 타임스탬프입니다. |
| `[].description`            | 문자열   | 이슈에 대한 설명입니다. |
| `[].discussion_locked`      | 부울  | 이슈의 댓글이 멤버만으로 제한되어 있는지 여부를 나타냅니다. |
| `[].downvotes`              | 정수  | 이슈가 받은 부정 투표 수입니다. |
| `[].due_date`               | 날짜     | 이슈의 기한입니다. |
| `[].id`                     | 정수  | 이슈의 ID입니다. |
| `[].iid`                    | 정수  | 이슈의 내부 ID입니다. |
| `[].issue_type`             | 문자열   | 이슈의 유형입니다. `issue`, `incident`, `test_case`, `requirement`, `task`일 수 있습니다. |
| `[].labels`                 | 배열    | 이슈의 레이블입니다. |
| `[].merge_requests_count`   | 정수  | 병합 시 이슈를 종료하는 머지 리퀘스트의 개수입니다. |
| `[].milestone`              | 객체   | 이슈의 마일스톤입니다. |
| `[].project_id`             | 정수  | 이슈 프로젝트의 ID입니다. |
| `[].state`                  | 문자열   | 이슈의 상태입니다. `opened` 또는 `closed`일 수 있습니다. |
| `[].task_completion_status` | 객체   | `count`과 `completed_count`를 포함합니다. |
| `[].time_stats`             | 객체   | 이슈에 대한 시간 통계입니다. `time_estimate`, `total_time_spent`, `human_time_estimate`, `human_total_time_spent`를 포함합니다. |
| `[].title`                  | 문자열   | 이슈의 제목입니다. |
| `[].type`                   | 문자열   | 이슈의 유형입니다. `issue_type`과 동일하지만 대문자입니다. |
| `[].updated_at`             | 날짜/시간 | 이슈가 업데이트된 시간의 타임스탬프입니다. |
| `[].upvotes`                | 정수  | 이슈가 받은 긍정 투표 수입니다. |
| `[].user_notes_count`       | 정수  | 이슈의 사용자 주석 개수입니다. |
| `[].web_url`                | 문자열   | 이슈의 웹 URL입니다. |
| `[].weight`                 | 정수  | 이슈의 가중치입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)과 Jira와 같은 외부 이슈 추적기를 사용할 때 다음 응답 속성을 반환합니다:

| 속성  | 유형    | 설명 |
|------------|---------|-------------|
| `[].id`    | 정수 | 이슈의 ID입니다. |
| `[].title` | 문자열  | 이슈의 제목입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/closes_issues"
```

GitLab 이슈 추적기를 사용할 때 응답 예시:

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 1,
    "title": "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description": "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2024-09-06T10:58:49.002Z",
    "updated_at": "2024-09-06T11:01:40.710Z",
    "closed_at": null,
    "closed_by": null,
    "labels": [
      "label"
    ],
    "milestone": {
      "project_id": 1,
      "description": "Ducimus nam enim ex consequatur cumque ratione.",
      "state": "closed",
      "due_date": null,
      "iid": 2,
      "created_at": "2016-01-04T15:31:39.996Z",
      "title": "v4.0",
      "id": 17,
      "updated_at": "2016-01-04T15:31:39.996Z"
    },
    "assignees": [
      {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": null,
        "web_url": "https://gitlab.example.com/root"
      }
    ],
    "author": {
      "id": 18,
      "username": "eileen.lowe",
      "name": "Alexandra Bashirian",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/eileen.lowe"
    },
    "type": "ISSUE",
    "assignee": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/root"
    },
    "user_notes_count": 1,
    "merge_requests_count": 1,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "issue_type": "issue",
    "web_url": "https://gitlab.example.com/my-group/my-project/-/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "weight": null,
    "blocking_issues_count": 0
 }
]
```

Jira와 같은 외부 이슈 추적기를 사용할 때 응답 예시:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## 머지 리퀘스트와 관련된 이슈 나열 {#list-issues-related-to-the-merge-request}

머지 리퀘스트의 제목, 설명, 커밋메시지, 댓글 및 토론과 관련된 이슈를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/related_issues
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/related_issues"
```

GitLab 이슈 추적기를 사용할 때 응답 예시:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "author" : {
         "state" : "active",
         "id" : 18,
         "web_url" : "https://gitlab.example.com/eileen.lowe",
         "name" : "Alexandra Bashirian",
         "avatar_url" : null,
         "username" : "eileen.lowe"
      },
      "milestone" : {
         "project_id" : 1,
         "description" : "Ducimus nam enim ex consequatur cumque ratione.",
         "state" : "closed",
         "due_date" : null,
         "iid" : 2,
         "created_at" : "2016-01-04T15:31:39.996Z",
         "title" : "v4.0",
         "id" : 17,
         "updated_at" : "2016-01-04T15:31:39.996Z"
      },
      "project_id" : 1,
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "iid" : 6,
      "labels" : [],
      "user_notes_count": 1,
      "changes_count": "1"
   }
]
```

Jira와 같은 외부 이슈 추적기를 사용할 때 응답 예시:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## 머지 리퀘스트 구독 {#subscribe-to-a-merge-request}

인증된 사용자를 머지 리퀘스트에 구독하여 알림을 받도록 합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/subscribe
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

사용자가 이미 머지 리퀘스트를 구독하고 있으면 엔드포인트가 상태 코드 `HTTP 304 Not Modified`를 반환합니다.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/subscribe"
```

응답 예시:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요.

## 머지 리퀘스트 구독 해제 {#unsubscribe-from-a-merge-request}

인증된 사용자를 머지 리퀘스트에서 구독 해제하여 해당 머지 리퀘스트로부터 알림을 받지 않도록 합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unsubscribe
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/unsubscribe"
```

사용자가 머지 리퀘스트를 구독하지 않은 경우 엔드포인트가 상태 코드 `HTTP 304 Not Modified`를 반환합니다.

응답 예시:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

응답 데이터에 대한 중요한 참고 사항은 [단일 머지 리퀘스트 응답 참고 사항](#single-merge-request-response-notes)을 참조하세요.

## 할 일 항목 만들기 {#create-a-to-do-item}

머지 리퀘스트에서 현재 사용자에 대한 할 일 항목을 수동으로 만듭니다. 할 일 항목이 이미 해당 머지 리퀘스트에 대한 사용자에 대해 있으면 이 엔드포인트는 상태 코드 `HTTP 304 Not Modified`를 반환합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/todo
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/27/todo"
```

응답 예시:

```json
{
  "id": 113,
  "project": {
    "id": 3,
    "name": "GitLab CI/CD",
    "name_with_namespace": "GitLab Org / GitLab CI/CD",
    "path": "gitlab-ci",
    "path_with_namespace": "gitlab-org/gitlab-ci"
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "MergeRequest",
  "target": {
    "id": 27,
    "iid": 7,
    "project_id": 3,
    "title": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
    "description": "Veniam sunt nihil modi earum cumque illum delectus. Nihil ad quis distinctio quia. Autem eligendi at quibusdam repellendus.",
    "state": "merged",
    "created_at": "2016-06-17T07:48:04.330Z",
    "updated_at": "2016-07-01T11:14:15.537Z",
    "target_branch": "allow_regex_for_project_skip_ref",
    "source_branch": "backup",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca",
      "discussion_locked": false
    },
    "assignee": {
      "name": "Dr. Gabrielle Strosin",
      "username": "barrett.krajcik",
      "id": 4,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/733005fcd7e6df12d2d8580171ccb966?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/barrett.krajcik"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "source_project_id": 3,
    "target_project_id": 3,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 3,
      "title": "v1.0",
      "description": "Quis ea accusantium animi hic fuga assumenda.",
      "state": "active",
      "created_at": "2016-06-17T07:47:33.840Z",
      "updated_at": "2016-06-17T07:47:33.840Z",
      "due_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "detailed_merge_status": "not_open",
    "subscribed": true,
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 7,
    "changes_count": "1",
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "squash": false,
    "web_url": "http://example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/merge_requests/7",
  "body": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
  "state": "pending",
  "created_at": "2016-07-01T11:14:15.530Z"
}
```

## 머지 리퀘스트 diff 버전 검색 {#retrieve-merge-request-diff-versions}

머지 리퀘스트에 대한 diff 버전을 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions
```

| 속성           | 유형    | 필수 | 설명                           |
|---------------------|---------|----------|---------------------------------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID입니다.                |
| `merge_request_iid` | 정수 | 예      | 머지 리퀘스트의 내부 ID입니다. |

응답의 SHA에 대한 설명은 [API 응답의 SHA](#shas-in-the-api-response)를 참조하세요.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions"
```

응답 예시:

```json
[{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f"
}, {
  "id": 108,
  "head_commit_sha": "3eed087b29835c48015768f839d76e5ea8f07a24",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-25T14:21:33.028Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "72c30d1f0115fc1d2bb0b29b24dc2982cbcdfd32"
}]
```

### API 응답의 SHA {#shas-in-the-api-response}

| SHA 필드          | 목적                                                                             |
|--------------------|-------------------------------------------------------------------------------------|
| `base_commit_sha`  | 소스 브랜치와 대상 브랜치 사이의 병합 베이스 커밋 SHA입니다.        |
| `head_commit_sha`  | 소스 브랜치의 HEAD 커밋입니다.                                               |
| `start_commit_sha` | 이 버전의 diff가 생성되었을 때의 대상 브랜치의 HEAD 커밋 SHA입니다. |

## 머지 리퀘스트 diff 버전 검색 {#retrieve-a-merge-request-diff-version}

{{< history >}}

- `collapsed` 및 `too_large` 응답 속성 [GitLab 18.4에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633).

{{< /history >}}

머지 리퀘스트에 대한 특정 diff 버전을 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions/:version_id
```

지원되는 속성:

| 속성           | 유형    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID입니다. |
| `merge_request_iid` | 정수 | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `version_id`        | 정수 | 예      | 머지 리퀘스트 diff 버전의 ID입니다. |
| `unidiff`           | 부울 | 아니요       | diffs를 [통합 diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) 형식으로 표시합니다. 기본값은 거짓입니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610). |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                     | 유형         | 설명 |
|-------------------------------|--------------|-------------|
| `id`                          | 정수      | 머지 리퀘스트 diff 버전의 ID입니다. |
| `base_commit_sha`             | 문자열       | 소스 브랜치와 대상 브랜치 사이의 병합 베이스 커밋 SHA입니다. |
| `commits`                     | 객체 배열 | 머지 리퀘스트 diff의 커밋입니다. |
| `commits[].id`                | 문자열       | 커밋의 ID입니다. |
| `commits[].short_id`          | 문자열       | 커밋의 짧은 ID입니다. |
| `commits[].created_at`        | 날짜/시간     | `committed_date` 필드와 동일합니다. |
| `commits[].parent_ids`        | 배열        | 부모 커밋의 ID입니다. |
| `commits[].title`             | 문자열       | 커밋 제목입니다. |
| `commits[].message`           | 문자열       | 커밋 메시지. |
| `commits[].author_name`       | 문자열       | 커밋 작성자의 이름입니다. |
| `commits[].author_email`      | 문자열       | 커밋 작성자의 이메일 주소입니다. |
| `commits[].authored_date`     | 날짜/시간     | 커밋 작성 날짜 및 시간입니다. |
| `commits[].committer_name`    | 문자열       | 커밋 작업자의 이름입니다. |
| `commits[].committer_email`   | 문자열       | 커밋 작업자의 이메일 주소입니다. |
| `commits[].committed_date`    | 날짜/시간     | 커밋 날짜 및 시간입니다. |
| `commits[].trailers`          | 객체       | 커밋에 대해 구문 분석된 Git 트레일러입니다. 중복 키는 마지막 값만 포함합니다. |
| `commits[].extended_trailers` | 객체       | 커밋에 대해 구문 분석된 Git 트레일러입니다. |
| `commits[].web_url`           | 문자열       | 머지 리퀘스트의 웹 URL입니다. |
| `created_at`                  | 날짜/시간     | 머지 리퀘스트의 생성 날짜 및 시간입니다. |
| `diffs`                       | 객체 배열 | 머지 리퀘스트 diff 버전의 diff입니다. |
| `diffs[].a_mode`              | 문자열       | 파일의 이전 파일 모드입니다. |
| `diffs[].b_mode`              | 문자열       | 파일의 새 파일 모드입니다. |
| `diffs[].collapsed`           | 부울      | 파일 diffs는 제외되지만 요청 시 가져올 수 있습니다. |
| `diffs[].deleted_file`        | 부울      | 파일이 제거되었습니다. |
| `diffs[].diff`                | 문자열       | diff의 내용입니다. |
| `diffs[].generated_file`      | 부울      | 파일이 [생성됨으로 표시됨](../user/project/merge_requests/changes.md#collapse-generated-files). |
| `diffs[].new_file`            | 부울      | 파일이 추가되었습니다. |
| `diffs[].new_path`            | 문자열       | 파일의 새 경로입니다. |
| `diffs[].old_path`            | 문자열       | 파일의 이전 경로입니다. |
| `diffs[].renamed_file`        | 부울      | 파일이 이름이 변경되었습니다. |
| `diffs[].too_large`           | 부울      | 파일 diffs는 제외되며 검색할 수 없습니다. |
| `head_commit_sha`             | 문자열       | 소스 브랜치의 HEAD 커밋입니다. |
| `merge_request_id`            | 정수      | 머지 리퀘스트의 ID입니다. |
| `patch_id_sha`                | 문자열       | 머지 리퀘스트 diff에 대한 [Patch ID](https://git-scm.com/docs/git-patch-id)입니다. |
| `real_size`                   | 문자열       | 머지 리퀘스트 diff의 변경 개수입니다. |
| `start_commit_sha`            | 문자열       | 이 버전의 diff가 생성되었을 때의 대상 브랜치의 HEAD 커밋 SHA입니다. |
| `state`                       | 문자열       | 머지 리퀘스트 diff의 상태입니다. `collected`, `overflow`, `without_files`일 수 있습니다. 더 이상 사용되지 않는 값: `timeout`, `overflow_commits_safe_size`, `overflow_diff_files_limit`, `overflow_diff_lines_limit`. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions/1"
```

응답 예시:

```json
{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f",
  "commits": [{
    "id": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
    "short_id": "33e2ee85",
    "parent_ids": [],
    "title": "Change year to 2018",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-26T17:44:29.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-26T17:44:29.000+03:00",
    "created_at": "2016-07-26T17:44:29.000+03:00",
    "message": "Change year to 2018",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30"
  }, {
    "id": "aa24655de48b36335556ac8a3cd8bb521f977cbd",
    "short_id": "aa24655d",
    "parent_ids": [],
    "title": "Update LICENSE",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:53.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:53.000+03:00",
    "created_at": "2016-07-25T17:21:53.000+03:00",
    "message": "Update LICENSE",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/aa24655de48b36335556ac8a3cd8bb521f977cbd"
  }, {
    "id": "3eed087b29835c48015768f839d76e5ea8f07a24",
    "short_id": "3eed087b",
    "parent_ids": [],
    "title": "Add license",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:20.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:20.000+03:00",
    "created_at": "2016-07-25T17:21:20.000+03:00",
    "message": "Add license",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/3eed087b29835c48015768f839d76e5ea8f07a24"
  }],
  "diffs": [{
    "old_path": "LICENSE",
    "new_path": "LICENSE",
    "a_mode": "0",
    "b_mode": "100644",
    "diff": "@@ -0,0 +1,21 @@\n+The MIT License (MIT)\n+\n+Copyright (c) 2018 Administrator\n+\n+Permission is hereby granted, free of charge, to any person obtaining a copy\n+of this software and associated documentation files (the \"Software\"), to deal\n+in the Software without restriction, including without limitation the rights\n+to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n+copies of the Software, and to permit persons to whom the Software is\n+furnished to do so, subject to the following conditions:\n+\n+The above copyright notice and this permission notice shall be included in all\n+copies or substantial portions of the Software.\n+\n+THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n+IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n+FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n+AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n+LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n+OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n+SOFTWARE.\n",
    "collapsed": false,
    "too_large": false,
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }]
}
```

## 머지 리퀘스트에 대한 시간 예상치 설정 {#set-a-time-estimate-for-a-merge-request}

이 머지 리퀘스트에 대한 예상 작업 시간을 설정합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/time_estimate
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `duration`          | 문자열            | 예      | `3h30m`와 같은 인간 형식의 기간입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_estimate?duration=3h30m"
```

응답 예시:

```json
{
  "human_time_estimate": "3h 30m",
  "human_total_time_spent": null,
  "time_estimate": 12600,
  "total_time_spent": 0
}
```

## 머지 리퀘스트에 대한 시간 예상치 초기화 {#reset-the-time-estimate-for-a-merge-request}

이 머지 리퀘스트에 대한 예상 시간을 0초로 초기화합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_time_estimate
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 프로젝트의 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_time_estimate"
```

응답 예시:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## 머지 리퀘스트에 소요된 시간 추가 {#add-spent-time-for-a-merge-request}

이 머지 리퀘스트에 소요된 시간을 추가합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/add_spent_time
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `duration`          | 문자열            | 예      | `3h30m`과 같은 인간 형식의 기간 |
| `summary`           | 문자열            | 아니요       | 시간이 어떻게 소요되었는지에 대한 요약입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/add_spent_time?duration=1h"
```

응답 예시:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": "1h",
  "time_estimate": 0,
  "total_time_spent": 3600
}
```

## 머지 리퀘스트에 대한 소요 시간 초기화 {#reset-spent-time-for-a-merge-request}

이 머지 리퀘스트에 대한 총 소요 시간을 0초로 초기화합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_spent_time
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 프로젝트의 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_spent_time"
```

응답 예시:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## 시간 추적 통계 검색 {#retrieve-time-tracking-statistics}

머지 리퀘스트에 대한 시간 추적 통계를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/time_stats
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_stats"
```

응답 예시:

```json
{
  "human_time_estimate": "2h",
  "human_total_time_spent": "1h",
  "time_estimate": 7200,
  "total_time_spent": 3600
}
```

## 승인 {#approvals}

승인에 대해서는 [머지 리퀘스트 승인](merge_request_approvals.md)을 참조하세요.

## 머지 리퀘스트 상태 이벤트 나열 {#list-merge-request-state-events}

어느 상태가 설정되었는지, 누가 설정했는지, 언제 발생했는지 추적하려면 [리소스 상태 이벤트 API](resource_state_events.md#merge-requests)를 참조하세요.

## 문제 해결 {#troubleshooting}

### 새 머지 리퀘스트의 빈 API 필드 {#empty-api-fields-for-new-merge-requests}

머지 리퀘스트를 만들 때 `diff_refs` 및 `changes_count` 필드는 처음에 비어 있습니다. 이러한 필드는 머지 리퀘스트를 만든 후 비동기적으로 채워집니다. 자세한 내용은 [이슈 386562](https://gitlab.com/gitlab-org/gitlab/-/issues/386562) 및 GitLab 포럼의 [관련 토론](https://forum.gitlab.com/t/diff-refs-empty-after-mr-is-created/78975)을(를) 참조하세요.
