---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 포크 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab 프로젝트의 포크를 관리합니다. 자세한 정보는 [포크](../user/project/repository/forking_workflow.md)를 참조하세요.

## 프로젝트 포크 생성 {#create-a-fork-of-a-project}

지정된 프로젝트의 포크를 생성합니다.

전제 조건:

- 인증을 받아야 합니다.

프로젝트의 포크 작업은 비동기이며 백그라운드 작업에서 완료됩니다. 요청이 즉시 반환됩니다. 프로젝트의 포크 완료 여부를 확인하려면 새 프로젝트에 대해 `import_status`을 쿼리합니다.

```plaintext
POST /projects/:id/fork
```

| 속성                | 유형              | 필수 | 설명 |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `branches`               | 문자열            | 아니요       | 포크할 브랜치(모든 브랜치의 경우 비어 있음)입니다. |
| `description`            | 문자열            | 아니요       | 포크 후 생성된 프로젝트에 할당된 설명입니다. |
| `mr_default_target_self` | 부울           | 아니요       | 포크된 프로젝트의 경우 이 프로젝트로 머지 리퀘스트를 대상으로 지정합니다. `false`인 경우 대상은 업스트림 프로젝트입니다. |
| `name`                   | 문자열            | 아니요       | 포크 후 생성된 프로젝트에 할당된 이름입니다. |
| `namespace_id`           | 정수           | 아니요       | 프로젝트가 포크되는 네임스페이스의 ID입니다. |
| `namespace_path`         | 문자열            | 아니요       | 프로젝트가 포크되는 네임스페이스의 경로입니다. |
| `namespace`              | 정수 또는 문자열 | 아니요       | _(더 이상 사용되지 않음)_ 프로젝트가 포크되는 네임스페이스의 ID 또는 경로입니다. |
| `path`                   | 문자열            | 아니요       | 포크 후 생성된 프로젝트에 할당된 경로입니다. |
| `visibility`             | 문자열            | 아니요       | 포크 후 생성된 프로젝트에 할당된 [표시 여부 수준](projects.md#project-visibility-level)입니다. |

> [!note]
> 서비스 계정을 사용하여 프로젝트를 포크할 때는 `namespace_id` 또는 `namespace_path`를 제공해야 합니다. 서비스 계정은 프로젝트를 개인 네임스페이스로 포크할 수 없습니다. 자세한 정보는 [그룹 또는 프로젝트에 서비스 계정 추가](../user/profile/service_accounts.md#add-a-service-account-to-a-group-or-project)를 참조하세요.

## 프로젝트의 모든 포크 나열 {#list-all-forks-of-a-project}

지정된 프로젝트의 모든 포크를 나열합니다. 액세스 가능한 포크만 반환합니다.

```plaintext
GET /projects/:id/forks
```

지원되는 속성:

| 속성                     | 유형              | 필수 | 설명 |
|:------------------------------|:------------------|:---------|:------------|
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `archived`                    | 부울           | 아니요       | 보관 상태로 제한합니다. |
| `membership`                  | 부울           | 아니요       | 현재 사용자가 멤버인 프로젝트로 제한합니다. |
| `min_access_level`            | 정수           | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 보유한 프로젝트로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `order_by`                    | 문자열            | 아니요       | `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` 또는 `last_activity_at` 필드로 정렬하여 프로젝트를 반환합니다. 기본값은 `created_at`입니다. |
| `owned`                       | 부울           | 아니요       | 현재 사용자가 명시적으로 소유한 프로젝트로 제한합니다. |
| `search`                      | 문자열            | 아니요       | 검색 기준과 일치하는 프로젝트 목록을 반환합니다. |
| `simple`                      | 부울           | 아니요       | 각 프로젝트의 제한된 필드만 반환합니다. 인증 없이 이 작업은 작동하지 않습니다. 단순 필드만 반환됩니다. |
| `sort`                        | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 프로젝트를 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `starred`                     | 부울           | 아니요       | 현재 사용자가 별표로 표시한 프로젝트로 제한합니다. |
| `statistics`                  | 부울           | 아니요       | 프로젝트 통계를 포함합니다. 리포터, 개발자, 유지 보수자 또는 소유자 역할을 가진 사용자만 사용 가능합니다. |
| `updated_after`               | 날짜/시간          | 아니요       | 지정된 시간 이후에 마지막으로 업데이트된 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [GitLab 15.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393979). |
| `updated_before`              | 날짜/시간          | 아니요       | 지정된 시간 이전에 마지막으로 업데이트된 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [GitLab 15.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393979). |
| `visibility`                  | 문자열            | 아니요       | `public`, `internal` 또는 `private` 표시 유형으로 제한합니다. |
| `with_custom_attributes`      | 부울           | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md)을 포함합니다. _(관리자만)_ |
| `with_issues_enabled`         | 부울           | 아니요       | 활성화된 이슈 기능으로 제한합니다. |
| `with_merge_requests_enabled` | 부울           | 아니요       | 활성화된 머지 리퀘스트 기능으로 제한합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/forks"
```

응답 예시:

```json
[
  {
    "id": 3,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "internal",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
    "web_url": "http://example.com/diaspora/diaspora-project-site",
    "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora project"
    ],
    "topics": [
      "example",
      "disapora project"
    ],
    "name": "Diaspora Project Site",
    "name_with_namespace": "Diaspora / Diaspora Project Site",
    "path": "diaspora-project-site",
    "path_with_namespace": "diaspora/diaspora-project-site",
    "repository_object_format": "sha1",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": true,
    "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 1,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## 포크 관계 생성 {#create-a-fork-relationship}

두 개의 지정된 프로젝트 간 포크 관계를 생성합니다.

전제 조건:

- 관리자이거나 프로젝트에서 소유자 역할을 할당받아야 합니다.

```plaintext
POST /projects/:id/fork/:forked_from_id
```

지원되는 속성:

| 속성        | 유형              | 필수 | 설명 |
|:-----------------|:------------------|:---------|:------------|
| `forked_from_id` | ID                | 예      | 포크된 원본 프로젝트의 ID입니다. |
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

## 포크 관계 삭제 {#delete-a-fork-relationship}

두 개의 지정된 프로젝트 간 포크 관계를 삭제합니다.

전제 조건:

- 관리자이거나 프로젝트에서 소유자 역할을 할당받아야 합니다.

```plaintext
DELETE /projects/:id/fork
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
