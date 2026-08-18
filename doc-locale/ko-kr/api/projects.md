---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab 프로젝트를 생성, 검색, 업데이트, 삭제 및 관리하고 프로젝트 기능을 관리하는 REST API입니다."
title: Projects API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab 프로젝트와 관련 설정을 관리합니다. 프로젝트는 코드를 저장하고, 이슈를 추적하며, 팀 활동을 조직하는 협업의 중심 허브입니다. 자세한 내용은 [프로젝트 생성](../user/project/_index.md)을 참조하세요.

Projects API에는 다음을 수행하는 엔드포인트가 포함되어 있습니다:

- 프로젝트 정보 및 메타데이터 검색
- 프로젝트 생성, 편집, 제거
- 프로젝트 가시성, 액세스 권한, 보안 설정 제어
- 이슈 추적, 머지 리퀘스트, CI/CD 같은 프로젝트 기능 관리
- 프로젝트 보관 및 보관 해제
- 네임스페이스 간 프로젝트 이전
- 배포 및 컨테이너 레지스트리 설정 관리

## 전제 조건 {#prerequisites}

- 프로젝트의 속성을 읽으려면 프로젝트에서 모든 [기본 역할](../user/permissions.md#roles)이 필요합니다.
- 프로젝트 속성을 편집하려면 프로젝트의 관리자 또는 소유자 역할이 필요합니다.

## 프로젝트 가시성 수준 {#project-visibility-level}

GitLab의 프로젝트는 다음 중 하나의 가시성 수준을 가질 수 있습니다:

- 비공개
- 내부
- 공개

가시성 수준은 프로젝트의 `visibility` 필드로 결정됩니다.

자세한 내용은 [프로젝트 가시성](../user/public_access.md)을 참조하세요.

응답에서 반환되는 필드는 인증된 사용자의 [권한](../user/permissions.md)에 따라 다릅니다.

## 프로젝트 기능 가시성 수준 {#project-feature-visibility-level}

프로젝트를 생성하거나 편집할 때 프로젝트 설정의 가용성을 제어할 수 있습니다. 예를 들어, 기존 프로젝트에 대해 `forking_access_level`을(를) 비활성화하려면:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"forking_access_level": "disabled"}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

각 설정은 독립적으로 정의할 수 있으며 다음 값을 허용합니다:

- `disabled`:  기능을 비활성화합니다.
- `private`:  기능을 활성화하고 **Only project members** 가능하도록 설정합니다.
- `enabled`:  기능을 활성화하고 **Everyone with access** 가능하도록 설정합니다.
- `public`:  기능을 활성화하고 **모두** 가능하도록 설정합니다. `pages_access_level`에만 사용 가능합니다.

자세한 내용은 [프로젝트에서 개별 기능의 가시성 변경](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project)을 참조하세요.

| 속성                              | 유형   | 필수 | 설명 |
|:---------------------------------------|:-------|:---------|:------------|
| `analytics_access_level`               | 문자열 | 아니요       | [분석](../user/analytics/_index.md) 가시성을 설정합니다. |
| `builds_access_level`                  | 문자열 | 아니요       | [파이프라인](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines)의 가시성을 설정합니다. |
| `container_registry_access_level`      | 문자열 | 아니요       | [컨테이너 레지스트리](../user/packages/container_registry/_index.md#change-visibility-of-the-container-registry)의 가시성을 설정합니다. |
| `environments_access_level`            | 문자열 | 아니요       | [환경](../ci/environments/_index.md)의 가시성을 설정합니다. |
| `feature_flags_access_level`           | 문자열 | 아니요       | [기능 플래그](../operations/feature_flags.md)의 가시성을 설정합니다. |
| `forking_access_level`                 | 문자열 | 아니요       | [포크](../user/project/repository/forking_workflow.md)의 가시성을 설정합니다. |
| `infrastructure_access_level`          | 문자열 | 아니요       | [인프라 관리](../user/infrastructure/_index.md)의 가시성을 설정합니다. |
| `issues_access_level`                  | 문자열 | 아니요       | [이슈](../user/project/issues/_index.md)의 가시성을 설정합니다. |
| `merge_requests_access_level`          | 문자열 | 아니요       | [머지 리퀘스트](../user/project/merge_requests/_index.md)의 가시성을 설정합니다. |
| `model_experiments_access_level`       | 문자열 | 아니요       | [머신 러닝 모델 실험](../user/project/ml/experiment_tracking/_index.md)의 가시성을 설정합니다. |
| `model_registry_access_level`          | 문자열 | 아니요       | [머신 러닝 모델 레지스트리](../user/project/ml/model_registry/_index.md#access-the-model-registry)의 가시성을 설정합니다. |
| `monitor_access_level`                 | 문자열 | 아니요       | [애플리케이션 성능 모니터링](../operations/_index.md)의 가시성을 설정합니다. |
| `pages_access_level`                   | 문자열 | 아니요       | [GitLab Pages](../user/project/pages/pages_access_control.md)의 가시성을 설정합니다. |
| `releases_access_level`                | 문자열 | 아니요       | [릴리스](../user/project/releases/_index.md)의 가시성을 설정합니다. |
| `repository_access_level`              | 문자열 | 아니요       | [리포지토리](../user/project/repository/_index.md)의 가시성을 설정합니다. |
| `requirements_access_level`            | 문자열 | 아니요       | [요구 사항 관리](../user/project/requirements/_index.md)의 가시성을 설정합니다. |
| `security_and_compliance_access_level` | 문자열 | 아니요       | [보안 및 규정 준수](../user/application_security/_index.md)의 가시성을 설정합니다. |
| `snippets_access_level`                | 문자열 | 아니요       | [스니펫](../user/snippets.md#change-default-visibility-of-snippets)의 가시성을 설정합니다. |
| `wiki_access_level`                    | 문자열 | 아니요       | [위키](../user/project/wiki/_index.md#enable-or-disable-a-project-wiki)의 가시성을 설정합니다. |

## 더 이상 사용되지 않는 속성 {#deprecated-attributes}

이 속성들은 더 이상 사용되지 않으며 향후 REST API 버전에서 제거될 수 있습니다. 대신 대체 속성을 사용합니다.

| 더 이상 사용되지 않는 속성     | 대체 속성 |
|:-------------------------|:------------|
| `tag_list`               | `topics` 대신 사용합니다. |
| `marked_for_deletion_at` | `marked_for_deletion_on` 대신 사용합니다. Premium 및 Ultimate만 해당합니다. |
| `approvals_before_merge` | [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/work_items/353097). 대신 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 사용합니다. Premium 및 Ultimate만 해당합니다. |
| `packages_enabled` | GitLab 17.10에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/work_items/454759). `package_registry_access_level` 대신 사용합니다. |
| `container_registry_enabled` | `container_registry_access_level` 대신 사용합니다. |
| `public_builds` | `public_jobs` 대신 사용합니다. |
| `emails_disabled` | `emails_enabled` 대신 사용합니다. |
| `issues_enabled` | `issues_access_level` 대신 사용합니다. |
| `jobs_enabled` | `builds_access_level` 대신 사용합니다. |
| `merge_requests_enabled` | `merge_request_access_level` 대신 사용합니다. |
| `snippets_enabled` | `snippets_access_level` 대신 사용합니다. |
| `wiki_enabled` | `wiki_access_level` 대신 사용합니다. |
| `restrict_user_defined_variables` | GitLab 17.7에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510). `ci_pipeline_variables_minimum_override_role` 대신 사용합니다. |

## 프로젝트 검색 {#retrieve-a-project}

{{< history >}}

- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

지정된 프로젝트를 검색합니다. 프로젝트가 공개적으로 접근 가능한 경우 이 엔드포인트는 인증 없이 접근할 수 있습니다.

```plaintext
GET /projects/:id
```

지원되는 속성:

| 속성                | 유형              | 필수 | 설명 |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `license`                | 부울           | 아니요       | 프로젝트 라이선스 데이터를 포함합니다. |
| `statistics`             | 부울           | 아니요       | 프로젝트 통계를 포함합니다. 리포터, 개발자, 유지 보수자 또는 소유자 역할을 가진 사용자만 사용 가능합니다. |
| `with_custom_attributes` | 부울           | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md)을 포함합니다. 관리자 액세스 권한이 있어야 합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                | 유형              | 설명 |
|:-------------------------|:------------------|:------------|
| `id` | 정수 | 프로젝트의 ID입니다. |
| `description` | 문자열 | 프로젝트의 설명. |
| `description_html` | 문자열 | HTML 형식의 프로젝트 설명. |
| `name` | 문자열 | 프로젝트의 이름. |
| `name_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 이름. |
| `path` | 문자열 | 프로젝트의 경로. |
| `path_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 경로. |
| `created_at` | 날짜/시간 | 프로젝트가 생성된 타임스탬프. |
| `default_branch` | 문자열 | 프로젝트의 기본 브랜치. |
| `tag_list` | 문자열 배열 | 지원 중단됨. `topics` 대신 사용합니다. 프로젝트의 태그 목록. |
| `topics` | 문자열 배열 | 프로젝트의 주제 목록. |
| `ssh_url_to_repo` | 문자열 | 리포지토리를 복제할 SSH URL. |
| `http_url_to_repo` | 문자열 | 리포지토리를 복제할 HTTP URL. |
| `web_url` | 문자열 | 브라우저에서 프로젝트에 액세스할 URL. |
| `readme_url` | 문자열 | 프로젝트의 README 파일 URL. |
| `forks_count` | 정수 | 프로젝트의 포크 수. |
| `avatar_url` | 문자열 | 프로젝트의 아바타 이미지 URL. |
| `star_count` | 정수 | 프로젝트가 받은 스타 수. |
| `last_activity_at` | 날짜/시간 | 프로젝트의 마지막 활동 타임스탬프. |
| `visibility` | 문자열 | 프로젝트의 가시성 수준. 가능한 값: `private`, `internal` 또는 `public`. |
| `namespace` | 객체 | 프로젝트의 네임스페이스 정보. |
| `namespace.id` | 정수 | 네임스페이스의 ID. |
| `namespace.name` | 문자열 | 네임스페이스의 이름. |
| `namespace.path` | 문자열 | 네임스페이스의 경로. |
| `namespace.kind` | 문자열 | 네임스페이스의 유형. 가능한 값: `user` 또는 `group`. |
| `namespace.full_path` | 문자열 | 네임스페이스의 전체 경로. |
| `namespace.parent_id` | 정수 | 해당하는 경우 부모 네임스페이스의 ID. |
| `namespace.avatar_url` | 문자열 | 네임스페이스의 아바타 이미지 URL. |
| `namespace.web_url` | 문자열 | 브라우저에서 네임스페이스에 액세스할 URL. |
| `container_registry_image_prefix` | 문자열 | 컨테이너 레지스트리 이미지의 접두사. |
| `_links` | 객체 | 프로젝트와 관련된 API 엔드포인트 링크 모음. |
| `_links.self` | 문자열 | 프로젝트 리소스로의 URL. |
| `_links.issues` | 문자열 | 프로젝트의 이슈로의 URL. |
| `_links.merge_requests` | 문자열 | 프로젝트의 머지 리퀘스트로의 URL. |
| `_links.repo_branches` | 문자열 | 프로젝트의 리포지토리 브랜치로의 URL. |
| `_links.labels` | 문자열 | 프로젝트의 레이블로의 URL. |
| `_links.events` | 문자열 | 프로젝트의 이벤트로의 URL. |
| `_links.members` | 문자열 | 프로젝트의 멤버로의 URL. |
| `_links.cluster_agents` | 문자열 | 프로젝트의 클러스터 에이전트로의 URL. |
| `marked_for_deletion_at` | 날짜 | 지원 중단됨. `marked_for_deletion_on` 대신 사용합니다. 프로젝트가 삭제 예약된 날짜. |
| `marked_for_deletion_on` | 날짜 | 프로젝트가 삭제 예약된 날짜. |
| `packages_enabled` | 부울 | 패키지 레지스트리가 프로젝트에 대해 활성화되어 있는지 여부. |
| `empty_repo` | 부울 | 리포지토리가 비어 있는지 여부. |
| `archived` | 부울 | 프로젝트가 보관되어 있는지 여부. |
| `owner` | 객체 | 프로젝트 소유자에 대한 정보. |
| `owner.id` | 정수 | 프로젝트 소유자의 ID. |
| `owner.username` | 문자열 | 소유자의 사용자명. |
| `owner.public_email` | 문자열 | 소유자의 공개 이메일 주소. |
| `owner.name` | 문자열 | 프로젝트 소유자의 이름. |
| `owner.state` | 문자열 | 소유자 계정의 현재 상태. |
| `owner.locked` | 부울 | 소유자 계정이 잠금 상태인지 여부. |
| `owner.avatar_url` | 문자열 | 소유자의 아바타 이미지 URL. |
| `owner.web_url` | 문자열 | 소유자 프로필의 웹 URL. |
| `owner.created_at` | 날짜/시간 | 소유자가 생성된 타임스탬프. |
| `resolve_outdated_diff_discussions` | 부울 | 오래된 diff 토론이 자동으로 해결되는지 여부. |
| `container_expiration_policy` | 객체 | 컨테이너 이미지 만료 정책의 설정. |
| `container_expiration_policy.cadence` | 문자열 | 컨테이너 만료 정책이 실행되는 빈도. |
| `container_expiration_policy.enabled` | 부울 | 컨테이너 만료 정책이 활성화되어 있는지 여부. |
| `container_expiration_policy.keep_n` | 정수 | 유지할 컨테이너 이미지 수. |
| `container_expiration_policy.older_than` | 문자열 | 이 값보다 오래된 컨테이너 이미지를 제거합니다. |
| `container_expiration_policy.name_regex` | 문자열 | 지원 중단됨. `name_regex_delete` 대신 사용합니다. 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.name_regex_delete` | 문자열 | 삭제할 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.name_regex_keep` | 문자열 | 유지할 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.next_run_at` | 날짜/시간 | 다음 정책 실행 예약 타임스탬프. |
| `repository_object_format` | 문자열 | 리포지토리에서 사용하는 객체 형식. 가능한 값: `sha1` 또는 `sha256`. |
| `issues_enabled` | 부울 | 이슈가 프로젝트에 대해 활성화되어 있는지 여부. |
| `merge_requests_enabled` | 부울 | 머지 리퀘스트가 프로젝트에 대해 활성화되어 있는지 여부. |
| `wiki_enabled` | 부울 | 위키가 프로젝트에 대해 활성화되어 있는지 여부. |
| `jobs_enabled` | 부울 | 작업이 프로젝트에 대해 활성화되어 있는지 여부. |
| `snippets_enabled` | 부울 | 스니펫이 프로젝트에 대해 활성화되어 있는지 여부. |
| `container_registry_enabled` | 부울 | 지원 중단됨. `container_registry_access_level` 대신 사용합니다. 컨테이너 레지스트리가 활성화되어 있는지 여부. |
| `service_desk_enabled` | 부울 | Service Desk가 프로젝트에 대해 활성화되어 있는지 여부. |
| `service_desk_address` | 문자열 | Service Desk의 이메일 주소. |
| `can_create_merge_request_in` | 부울 | 현재 사용자가 프로젝트에서 머지 리퀘스트를 생성할 수 있는지 여부. |
| `issues_access_level` | 문자열 | 이슈 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `repository_access_level` | 문자열 | 리포지토리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `merge_requests_access_level` | 문자열 | 머지 리퀘스트 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `forking_access_level` | 문자열 | 프로젝트를 포크하기 위한 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `wiki_access_level` | 문자열 | 위키 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `builds_access_level` | 문자열 | CI/CD 작업 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `snippets_access_level` | 문자열 | 스니펫 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `pages_access_level` | 문자열 | GitLab Pages의 액세스 수준. 가능한 값: `disabled`, `private`, `enabled` 또는 `public`. |
| `analytics_access_level` | 문자열 | 분석 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `container_registry_access_level` | 문자열 | 컨테이너 레지스트리의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `security_and_compliance_access_level` | 문자열 | 보안 및 규정 준수 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `releases_access_level` | 문자열 | 릴리스 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `environments_access_level` | 문자열 | 환경 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `feature_flags_access_level` | 문자열 | 기능 플래그 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `infrastructure_access_level` | 문자열 | 인프라 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `monitor_access_level` | 문자열 | 모니터 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_experiments_access_level` | 문자열 | 모델 실험 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_registry_access_level` | 문자열 | 모델 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `package_registry_access_level` | 문자열 | 패키지 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `emails_disabled` | 부울 | 프로젝트에 대해 이메일이 비활성화되었는지 여부. |
| `emails_enabled` | 부울 | 프로젝트에 대해 이메일이 활성화되었는지 여부. |
| `show_diff_preview_in_email` | 부울 | 이메일 알림에 diff 미리보기가 표시되는지 여부. |
| `shared_runners_enabled` | 부울 | 공유 러너가 프로젝트에 대해 활성화되어 있는지 여부. |
| `lfs_enabled` | 부울 | Git LFS가 프로젝트에 대해 활성화되어 있는지 여부. |
| `creator_id` | 정수 | 프로젝트를 생성한 사용자의 ID. |
| `import_url` | 문자열 | 프로젝트를 가져온 URL. |
| `import_type` | 문자열 | 프로젝트에 사용된 가져오기 유형. |
| `import_status` | 문자열 | 프로젝트 가져오기 상태. |
| `import_error` | 문자열 | 가져오기 실패 시 오류 메시지. |
| `open_issues_count` | 정수 | 미해결 이슈 수. |
| `updated_at` | 날짜/시간 | 프로젝트가 마지막으로 업데이트된 타임스탬프. |
| `ci_default_git_depth` | 정수 | CI/CD 파이프라인의 기본 Git 깊이. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_delete_pipelines_in_seconds` | 정수 | 오래된 파이프라인이 삭제되기 전의 시간(초). |
| `ci_forward_deployment_enabled` | 부울 | 전달 배포가 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_forward_deployment_rollback_allowed` | 부울 | 전달 배포에 대해 롤백이 허용되는지 여부. |
| `ci_job_token_scope_enabled` | 부울 | CI/CD 작업 토큰 범위가 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_separated_caches` | 부울 | CI/CD 캐시가 브랜치별로 분리되는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | 부울 | 포크 파이프라인이 부모 프로젝트에서 실행될 수 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_id_token_sub_claim_components` | 문자열 배열 | CI/CD ID 토큰 주체 청구에 포함된 구성 요소. |
| `build_git_strategy` | 문자열 | CI/CD 작업에 사용되는 Git 전략(가져오기 또는 클론). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `keep_latest_artifact` | 부울 | 새 아티팩트가 생성될 때 최신 작업 아티팩트를 유지하는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `restrict_user_defined_variables` | 부울 | 사용자 정의 변수가 제한되는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_pipeline_variables_minimum_override_role` | 문자열 | 파이프라인 변수를 재정의하는 데 필요한 최소 역할. |
| `runner_token_expiration_interval` | 정수 | 러너 토큰의 만료 간격(초). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `group_runners_enabled` | 부울 | 그룹 러너가 프로젝트에 대해 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `resource_group_default_process_mode` | 문자열 | 리소스 그룹의 기본 프로세스 모드. |
| `auto_cancel_pending_pipelines` | 문자열 | 자동으로 보류 중인 파이프라인을 취소하기 위한 설정. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `build_timeout` | 정수 | CI/CD 작업의 시간 초과(초). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_devops_enabled` | 부울 | Auto DevOps가 프로젝트에 대해 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_devops_deploy_strategy` | 문자열 | Auto DevOps의 배포 전략. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_push_repository_for_job_token_allowed` | 부울 | 작업 토큰을 사용하여 리포지토리에 푸시가 허용되는지 여부. |
| `runners_token` | 문자열 | 프로젝트에 러너를 등록하기 위한 토큰. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_config_path` | 문자열 | CI/CD 구성 파일로의 경로. |
| `public_jobs` | 부울 | 작업 로그가 공개적으로 접근 가능한지 여부. |
| `shared_with_groups` | 객체 배열 | 프로젝트가 공유된 그룹 목록. |
| `shared_with_groups[].group_id` | 정수 | 프로젝트가 공유된 그룹의 ID. |
| `shared_with_groups[].group_name` | 문자열 | 프로젝트가 공유된 그룹의 이름. |
| `shared_with_groups[].group_full_path` | 문자열 | 프로젝트가 공유된 그룹의 전체 경로. |
| `shared_with_groups[].group_access_level` | 정수 | 그룹에 부여된 액세스 수준. |
| `only_allow_merge_if_pipeline_succeeds` | 부울 | 파이프라인이 성공한 경우에만 머지가 허용되는지 여부. |
| `allow_merge_on_skipped_pipeline` | 부울 | 파이프라인이 건너뛰어진 경우 머지가 허용되는지 여부. |
| `request_access_enabled` | 부울 | 사용자가 프로젝트에 대한 액세스를 요청할 수 있는지 여부. |
| `only_allow_merge_if_all_discussions_are_resolved` | 부울 | 모든 토론이 해결된 경우에만 머지가 허용되는지 여부. |
| `remove_source_branch_after_merge` | 부울 | 머지 후 소스 브랜치가 자동으로 제거되는지 여부. |
| `printing_merge_request_link_enabled` | 부울 | 푸시 후 머지 리퀘스트 링크가 출력되는지 여부. |
| `printing_merge_requests_link_enabled` | 부울 | 푸시 후 머지 리퀘스트 링크가 출력되는지 여부. |
| `merge_method` | 문자열 | 프로젝트에 사용되는 머지 방법. 가능한 값: `merge`, `rebase_merge` 또는 `ff`. |
| `merge_request_title_regex` | 문자열 | 머지 리퀘스트 제목 검증을 위한 정규식 패턴. |
| `merge_request_title_regex_description` | 문자열 | 머지 리퀘스트 제목 정규식 검증의 설명. |
| `squash_option` | 문자열 | 머지 리퀘스트의 스쿼시 옵션. |
| `enforce_auth_checks_on_uploads` | 부울 | 업로드에 인증 검사가 적용되는지 여부. |
| `suggestion_commit_message` | 문자열 | 제안에 대한 사용자 정의 커밋 메시지. |
| `merge_commit_template` | 문자열 | 머지 커밋 메시지 템플릿. |
| `mr_default_title_template` | 문자열 | 머지 리퀘스트 제목 템플릿. |
| `squash_commit_template` | 문자열 | 스쿼시 커밋 메시지 템플릿. |
| `issue_branch_template` | 문자열 | 이슈에서 생성된 브랜치 이름 템플릿. |
| `warn_about_potentially_unwanted_characters` | 부울 | 잠재적으로 원치 않는 문자에 대해 경고할지 여부. |
| `autoclose_referenced_issues` | 부울 | 참조된 이슈가 자동으로 종료되는지 여부. |
| `max_artifacts_size` | 정수 | CI/CD 작업 아티팩트의 최대 크기(MB). |
| `approvals_before_merge` | 정수 | 지원 중단됨. 대신 머지 리퀘스트 승인 API를 사용합니다. 머지 전에 필요한 승인 수. |
| `mirror` | 부울 | 프로젝트가 미러인지 여부. |
| `external_authorization_classification_label` | 문자열 | 외부 인증 분류 레이블. |
| `requirements_enabled` | 부울 | 요구 사항 관리가 활성화되어 있는지 여부. |
| `requirements_access_level` | 문자열 | 요구 사항 기능의 액세스 수준. |
| `security_and_compliance_enabled` | 부울 | 보안 및 규정 준수 기능이 활성화되어 있는지 여부. |
| `secret_push_protection_enabled` | 부울 | 시크릿 푸시 보호가 활성화되어 있는지 여부. |
| `pre_receive_secret_detection_enabled` | 부울 | 사전 수신 시크릿 검색이 활성화되어 있는지 여부. |
| `compliance_frameworks` | 문자열 배열 | 프로젝트에 적용된 규정 준수 프레임워크. |
| `issues_template` | 문자열 | 이슈의 기본 설명. 설명은 GitLab Flavored Markdown으로 구문 분석됩니다. Premium 및 Ultimate만 해당합니다. |
| `merge_requests_template` | 문자열 | 머지 리퀘스트 설명 템플릿. Premium 및 Ultimate만 해당합니다. |
| `ci_restrict_pipeline_cancellation_role` | 문자열 | 파이프라인을 취소하는 데 필요한 최소 역할. |
| `merge_pipelines_enabled` | 부울 | 머지 파이프라인이 활성화되어 있는지 여부. |
| `merge_trains_enabled` | 부울 | 머지 트레인이 활성화되어 있는지 여부. |
| `merge_trains_skip_train_allowed` | 부울 | 머지 트레인을 건너뛰는 것이 허용되는지 여부. |
| `max_pipelines_per_merge_train` | 정수 | 머지 트레인당 최대 병렬 파이프라인 수. |
| `only_allow_merge_if_all_status_checks_passed` | 부울 | 모든 상태 검사가 통과한 경우에만 머지가 허용되는지 여부. Ultimate만 해당. |
| `allow_pipeline_trigger_approve_deployment` | 부울 | 파이프라인 트리거가 배포를 승인할 수 있는지 여부. |
| `prevent_merge_without_jira_issue` | 부울 | 머지에 관련 Jira 이슈가 필요한지 여부. |
| `duo_remote_flows_enabled` | 부울 | GitLab Duo 원격 플로우가 활성화되어 있는지 여부. |
| `duo_foundational_flows_enabled` | 부울 | GitLab Duo 기본 플로우가 활성화되어 있는지 여부. |
| `duo_sast_fp_detection_enabled` | 부울 | GitLab Duo SAST 거짓 양성 탐지가 활성화되어 있는지 여부. |
| `duo_sast_vr_workflow_enabled` | 부울 | GitLab Duo SAST 취약성 해결 워크플로우가 활성화되어 있는지 여부. |
| `web_based_commit_signing_enabled` | 부울 | 웹 기반 커밋 서명이 활성화되어 있는지 여부. |
| `spp_repository_pipeline_access` | 부울 | 보안 정책의 리포지토리 파이프라인 액세스. 보안 조직 정책 기능을 사용 가능한 경우에만 표시됩니다. |
| `permissions` | 객체 | 프로젝트의 사용자 권한. |
| `permissions.project_access` | 객체 | 사용자의 프로젝트 수준 액세스 권한. |
| `permissions.project_access.access_level` | 정수 | 프로젝트의 액세스 수준. |
| `permissions.project_access.notification_level` | 정수 | 프로젝트의 알림 수준. |
| `permissions.group_access` | 객체 | 사용자의 그룹 수준 액세스 권한. |
| `permissions.group_access.access_level` | 정수 | 그룹의 액세스 수준. |
| `permissions.group_access.notification_level` | 정수 | 그룹의 알림 수준. |
| `license_url` | 문자열 | 프로젝트의 라이선스 파일 URL. |
| `license.key` | 문자열 | 라이선스의 핵심 식별자. |
| `license.name` | 문자열 | 라이선스의 전체 이름. |
| `license.nickname` | 문자열 | 라이선스의 별명. |
| `license.html_url` | 문자열 | 라이선스 세부 정보 보기 URL. |
| `license.source_url` | 문자열 | 라이선스 소스 텍스트 URL. |
| `repository_storage` | 문자열 | 프로젝트 리포지토리의 저장소 위치. |
| `mirror_user_id` | 정수 | 미러를 설정한 사용자의 ID. |
| `mirror_trigger_builds` | 부울 | 미러 업데이트가 빌드를 트리거하는지 여부. |
| `only_mirror_protected_branches` | 부울 | 보호된 브랜치만 미러되는지 여부. |
| `mirror_overwrites_diverged_branches` | 부울 | 미러가 분기된 브랜치를 덮어쓰는지 여부. |
| `statistics.commit_count` | 정수 | 프로젝트의 커밋 수. |
| `statistics.storage_size` | 정수 | 총 저장소 크기(바이트). |
| `statistics.repository_size` | 정수 | 리포지토리 저장소 크기(바이트). |
| `statistics.wiki_size` | 정수 | 위키 저장소 크기(바이트). |
| `statistics.lfs_objects_size` | 정수 | LFS 객체 저장소 크기(바이트). |
| `statistics.job_artifacts_size` | 정수 | 작업 아티팩트 저장소 크기(바이트). |
| `statistics.pipeline_artifacts_size` | 정수 | 파이프라인 작업 아티팩트 저장소 크기(바이트). |
| `statistics.packages_size` | 정수 | 패키지 저장소 크기(바이트). |
| `statistics.snippets_size` | 정수 | 스니펫 저장소 크기(바이트). |
| `statistics.uploads_size` | 정수 | 업로드 저장소 크기(바이트). |
| `statistics.container_registry_size` | 정수 | 컨테이너 레지스트리 저장소 크기(바이트). <sup>1</sup> |
| `forked_from_project` | 객체 | 이 프로젝트가 포크된 업스트림 프로젝트. 업스트림 프로젝트가 비공개이면 이 필드를 보려면 인증 토큰이 필요합니다. |
| `mr_default_target_self` | 부울 | 머지 리퀘스트가 기본적으로 이 프로젝트를 대상으로 하는지 여부. `false`인 경우 머지 리퀘스트는 업스트림 프로젝트를 대상으로 합니다. 프로젝트가 포크인 경우에만 나타납니다. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

응답 예시:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
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
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
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
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null, // to be deprecated in GitLab 13.0 in favor of `name_regex_delete`
    "name_regex_delete": null,
    "name_regex_keep": null,
    "next_run_at": "2020-01-07T21:42:58.658Z"
  },
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/3/foo.jpg",
    "web_url": "http://localhost:3000/groups/diaspora"
  },
  "import_url": null,
  "import_type": null,
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [
    {
      "group_id": 4,
      "group_name": "Twitter",
      "group_full_path": "twitter",
      "group_access_level": 30
    },
    {
      "group_id": 3,
      "group_name": "Gitlab Org",
      "group_full_path": "gitlab-org",
      "group_access_level": 10
    }
  ],
  "repository_storage": "default",
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "printing_merge_requests_link_enabled": true,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "mirror_user_id": 45,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": false,
  "mirror_overwrites_diverged_branches": false,
  "external_authorization_classification_label": null,
  "packages_enabled": true,
  "empty_repo": false,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "autoclose_referenced_issues": true,
  "suggestion_commit_message": null,
  "enforce_auth_checks_on_uploads": true,
  "merge_commit_template": null,
  "mr_default_title_template": null,
  "squash_commit_template": null,
  "issue_branch_template": "gitlab/%{id}-%{title}",
  "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false,
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0,
    "container_registry_size": 0
  },
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  },
  "spp_repository_pipeline_access": false // Only visible if the security_orchestration_policies feature is available
}
```

## 프로젝트 나열 {#list-projects}

프로젝트와 프로젝트 속성을 나열합니다.

### 모든 프로젝트 나열 {#list-all-projects}

{{< history >}}

- `web_based_commit_signing_enabled` [GitLab 18.2에 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194650) 됨 [플래그](../administration/feature_flags/_index.md) `use_web_based_commit_signing_enabled` 이름. 기본적으로 비활성화됨.
- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

> [!flag]
> `web_based_commit_signing_enabled` 속성의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트용으로 사용할 수 있지만, 프로덕션 환경에서 사용할 준비가 되지 않았습니다.

인스턴스의 모든 프로젝트를 나열합니다(인증된 사용자가 접근 가능). 인증되지 않은 요청은 속성 부분 집합이 있는 공개 프로젝트만 반환합니다.

[사용자 정의 속성](custom_attributes.md)으로 응답을 필터링할 수 있습니다.

이 엔드포인트는 페이지 매김을 지원합니다:

- 오프셋 기반 페이지 매김을 사용하여 최대 50,000개 프로젝트에 액세스합니다.
- 키셋 기반 페이지 매김을 사용하여 50,000개 이상의 프로젝트를 나열합니다.

자세한 내용은 [페이지 매김](rest/_index.md#pagination)을 참조하세요.

```plaintext
GET /projects
```

지원되는 속성:

| 속성                     | 유형     | 필수 | 설명 |
|:------------------------------|:---------|:---------|:------------|
| `archived`                    | 부울  | 아니요       | 보관 상태로 제한합니다. |
| `id_after`                    | 정수  | 아니요       | 지정된 ID보다 큰 ID를 가진 프로젝트로 결과를 제한합니다. |
| `id_before`                   | 정수  | 아니요       | 지정된 ID보다 작은 ID를 가진 프로젝트로 결과를 제한합니다. |
| `imported`                    | 부울  | 아니요       | 현재 사용자가 외부 시스템에서 가져온 프로젝트로 결과를 제한합니다. |
| `include_hidden`              | 부울  | 아니요       | 숨겨진 프로젝트를 포함합니다. _(관리자만)_ Premium 및 Ultimate만 해당합니다. |
| `include_pending_delete`      | 부울  | 아니요       | 삭제 대기 중인 프로젝트를 포함합니다. _(관리자만)_ |
| `last_activity_after`         | 날짜/시간 | 아니요       | 지정된 시간 후에 마지막 활동이 있은 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `last_activity_before`        | 날짜/시간 | 아니요       | 지정된 시간 전에 마지막 활동이 있은 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `membership`                  | 부울  | 아니요       | 현재 사용자가 멤버인 프로젝트로 제한합니다. |
| `min_access_level`            | 정수  | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 보유한 프로젝트로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `order_by`                    | 문자열   | 아니요       | `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, `last_activity_at`, 또는 `similarity` 필드로 정렬된 프로젝트를 반환합니다. `repository_size`, `storage_size`, `packages_size` 또는 `wiki_size` 필드는 관리자만 허용됩니다. `similarity`은 검색할 때만 사용 가능하며 현재 사용자가 멤버인 프로젝트로 제한됩니다. 기본값은 `created_at`입니다. |
| `owned`                       | 부울  | 아니요       | 현재 사용자가 명시적으로 소유한 프로젝트로 제한합니다. |
| `repository_checksum_failed`  | 부울  | 아니요       | 리포지토리 체크섬 계산이 실패한 프로젝트로 제한합니다. Premium 및 Ultimate만 해당합니다. |
| `repository_storage`          | 문자열   | 아니요       | `repository_storage`에 저장된 프로젝트로 결과를 제한합니다. _(관리자만)_ |
| `search_namespaces`           | 부울  | 아니요       | 검색 기준을 일치시킬 때 상위 네임스페이스를 포함합니다. 기본값은 `false`입니다. |
| `search`                      | 문자열   | 아니요       | `path`, `name`, 또는 `description` 중 하나가 검색 기준과 일치하는 프로젝트 목록을 반환합니다(대소문자 구분 안 함, 부분 문자열 일치). 여러 항목을 제공할 수 있으며, 공백, `+` 또는 `%20`로 구분되어 함께 AND됩니다. 예: `one+two`는 부분 문자열 `one` 및 `two`(순서 무관)과 일치합니다. |
| `simple`                      | 부울  | 아니요       | `true`이면 각 프로젝트의 제한된 필드만 반환합니다. 인증되지 않은 요청은 `simple`을 설정하지 않았더라도 제한된 필드가 있는 공개 프로젝트만 반환합니다. |
| `sort`                        | 문자열   | 아니요       | `asc` 또는 `desc` 순서로 프로젝트를 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `starred`                     | 부울  | 아니요       | 현재 사용자가 별표로 표시한 프로젝트로 제한합니다. |
| `statistics`                  | 부울  | 아니요       | 프로젝트 통계를 포함합니다. 리포터, 개발자, 유지 보수자 또는 소유자 역할을 가진 사용자만 사용 가능합니다. |
| `topic_id`                    | 정수  | 아니요       | 주제 ID로 지정된 프로젝트로 결과를 제한합니다. |
| `topic`                       | 문자열   | 아니요       | 쉼표로 구분된 주제 이름. 지정된 모든 주제와 일치하는 프로젝트로 결과를 제한합니다. `topics` 속성을 참조하세요. |
| `updated_after`               | 날짜/시간 | 아니요       | 지정된 시간 이후에 마지막으로 업데이트된 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [GitLab 15.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393979). 이 필터가 작동하려면 `updated_at`를 `order_by` 속성으로 제공해야 합니다. |
| `updated_before`              | 날짜/시간 | 아니요       | 지정된 시간 이전에 마지막으로 업데이트된 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [GitLab 15.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393979). 이 필터가 작동하려면 `updated_at`를 `order_by` 속성으로 제공해야 합니다. |
| `visibility`                  | 문자열   | 아니요       | `public`, `internal` 또는 `private` 표시 유형으로 제한합니다. |
| `wiki_checksum_failed`        | 부울  | 아니요       | 위키 체크섬 계산이 실패한 프로젝트로 제한합니다. Premium 및 Ultimate만 해당합니다. |
| `with_custom_attributes`      | 부울  | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md)을 포함합니다. _(관리자만)_ |
| `with_issues_enabled`         | 부울  | 아니요       | 활성화된 이슈 기능으로 제한합니다. |
| `with_merge_requests_enabled` | 부울  | 아니요       | 활성화된 머지 리퀘스트 기능으로 제한합니다. |
| `with_programming_language`   | 문자열   | 아니요       | 지정된 프로그래밍 언어를 사용하는 프로젝트로 제한합니다. |
| `marked_for_deletion_on`      | 날짜     | 아니요       | 프로젝트가 삭제 표시된 날짜로 필터링합니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/463939)됨. Premium 및 Ultimate만 해당합니다. |
| `active`                      | 부울  | 아니요       | 보관되지 않고 삭제 대상으로 표시되지 않은 프로젝트로 제한합니다. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `id` | 정수 | 프로젝트의 ID입니다. |
| `description` | 문자열 | 프로젝트의 설명. |
| `name` | 문자열 | 프로젝트의 이름. |
| `name_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 이름. |
| `path` | 문자열 | 프로젝트의 경로. |
| `path_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 경로. |
| `created_at` | 날짜/시간 | 프로젝트가 생성된 타임스탬프. |
| `default_branch` | 문자열 | 프로젝트의 기본 브랜치. |
| `tag_list` | 문자열 배열 | 지원 중단됨. `topics` 대신 사용합니다. 프로젝트의 태그 목록. |
| `topics` | 문자열 배열 | 프로젝트의 주제 목록. |
| `ssh_url_to_repo` | 문자열 | 리포지토리를 복제할 SSH URL. |
| `http_url_to_repo` | 문자열 | 리포지토리를 복제할 HTTP URL. |
| `web_url` | 문자열 | 브라우저에서 프로젝트에 액세스할 URL. |
| `readme_url` | 문자열 | 프로젝트의 README 파일 URL. |
| `forks_count` | 정수 | 프로젝트의 포크 수. |
| `avatar_url` | 문자열 | 프로젝트의 아바타 이미지 URL. |
| `star_count` | 정수 | 프로젝트가 받은 스타 수. |
| `last_activity_at` | 날짜/시간 | 프로젝트의 마지막 활동 타임스탬프. |
| `visibility` | 문자열 | 프로젝트의 가시성 수준. 가능한 값: `private`, `internal` 또는 `public`. |
| `namespace` | 객체 | 프로젝트의 네임스페이스 정보. |
| `namespace.id` | 정수 | 네임스페이스의 ID. |
| `namespace.name` | 문자열 | 네임스페이스의 이름. |
| `namespace.path` | 문자열 | 네임스페이스의 경로. |
| `namespace.kind` | 문자열 | 네임스페이스의 유형. 가능한 값: `user` 또는 `group`. |
| `namespace.full_path` | 문자열 | 네임스페이스의 전체 경로. |
| `namespace.parent_id` | 정수 | 해당하는 경우 부모 네임스페이스의 ID. |
| `namespace.avatar_url` | 문자열 | 네임스페이스의 아바타 이미지 URL. |
| `namespace.web_url` | 문자열 | 브라우저에서 네임스페이스에 액세스할 URL. |
| `container_registry_image_prefix` | 문자열 | 컨테이너 레지스트리 이미지의 접두사. |
| `_links` | 객체 | 프로젝트와 관련된 API 엔드포인트 링크 모음. |
| `_links.self` | 문자열 | 프로젝트 리소스로의 URL. |
| `_links.issues` | 문자열 | 프로젝트의 이슈로의 URL. |
| `_links.merge_requests` | 문자열 | 프로젝트의 머지 리퀘스트로의 URL. |
| `_links.repo_branches` | 문자열 | 프로젝트의 리포지토리 브랜치로의 URL. |
| `_links.labels` | 문자열 | 프로젝트의 레이블로의 URL. |
| `_links.events` | 문자열 | 프로젝트의 이벤트로의 URL. |
| `_links.members` | 문자열 | 프로젝트의 멤버로의 URL. |
| `_links.cluster_agents` | 문자열 | 프로젝트의 클러스터 에이전트로의 URL. |
| `marked_for_deletion_at` | 날짜 | 지원 중단됨. `marked_for_deletion_on` 대신 사용합니다. 프로젝트가 삭제 예약된 날짜. |
| `marked_for_deletion_on` | 날짜 | 프로젝트가 삭제 예약된 날짜. |
| `packages_enabled` | 부울 | 패키지 레지스트리가 프로젝트에 대해 활성화되어 있는지 여부. |
| `empty_repo` | 부울 | 리포지토리가 비어 있는지 여부. |
| `archived` | 부울 | 프로젝트가 보관되어 있는지 여부. |
| `resolve_outdated_diff_discussions` | 부울 | 오래된 diff 토론이 자동으로 해결되는지 여부. |
| `container_expiration_policy` | 객체 | 컨테이너 이미지 만료 정책의 설정. |
| `container_expiration_policy.cadence` | 문자열 | 컨테이너 만료 정책이 실행되는 빈도. |
| `container_expiration_policy.enabled` | 부울 | 컨테이너 만료 정책이 활성화되어 있는지 여부. |
| `container_expiration_policy.keep_n` | 정수 | 유지할 컨테이너 이미지 수. |
| `container_expiration_policy.older_than` | 문자열 | 이 값보다 오래된 컨테이너 이미지를 제거합니다. |
| `container_expiration_policy.name_regex` | 문자열 | 지원 중단됨. `name_regex_delete` 대신 사용합니다. 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.name_regex_keep` | 문자열 | 유지할 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.next_run_at` | 날짜/시간 | 다음 정책 실행 예약 타임스탬프. |
| `repository_object_format` | 문자열 | 리포지토리에서 사용하는 객체 형식(sha1 또는 sha256)입니다. |
| `issues_enabled` | 부울 | 이슈가 프로젝트에 대해 활성화되어 있는지 여부. |
| `merge_requests_enabled` | 부울 | 머지 리퀘스트가 프로젝트에 대해 활성화되어 있는지 여부. |
| `wiki_enabled` | 부울 | 위키가 프로젝트에 대해 활성화되어 있는지 여부. |
| `jobs_enabled` | 부울 | 작업이 프로젝트에 대해 활성화되어 있는지 여부. |
| `snippets_enabled` | 부울 | 스니펫이 프로젝트에 대해 활성화되어 있는지 여부. |
| `container_registry_enabled` | 부울 | 지원 중단됨. `container_registry_access_level` 대신 사용합니다. 컨테이너 레지스트리가 활성화되어 있는지 여부. |
| `service_desk_enabled` | 부울 | Service Desk가 프로젝트에 대해 활성화되어 있는지 여부. |
| `can_create_merge_request_in` | 부울 | 현재 사용자가 프로젝트에서 머지 리퀘스트를 생성할 수 있는지 여부. |
| `issues_access_level` | 문자열 | 이슈 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `repository_access_level` | 문자열 | 리포지토리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `merge_requests_access_level` | 문자열 | 머지 리퀘스트 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `forking_access_level` | 문자열 | 프로젝트를 포크하기 위한 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `wiki_access_level` | 문자열 | 위키 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `builds_access_level` | 문자열 | CI/CD 작업 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `snippets_access_level` | 문자열 | 스니펫 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `pages_access_level` | 문자열 | GitLab Pages의 액세스 수준. 가능한 값: `disabled`, `private`, `enabled` 또는 `public`. |
| `analytics_access_level` | 문자열 | 분석 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `container_registry_access_level` | 문자열 | 컨테이너 레지스트리의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `security_and_compliance_access_level` | 문자열 | 보안 및 규정 준수 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `releases_access_level` | 문자열 | 릴리스 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `environments_access_level` | 문자열 | 환경 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `feature_flags_access_level` | 문자열 | 기능 플래그 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `infrastructure_access_level` | 문자열 | 인프라 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `monitor_access_level` | 문자열 | 모니터 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_experiments_access_level` | 문자열 | 모델 실험 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_registry_access_level` | 문자열 | 모델 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `package_registry_access_level` | 문자열 | 패키지 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `emails_disabled` | 부울 | 프로젝트에 대해 이메일이 비활성화되었는지 여부. |
| `emails_enabled` | 부울 | 프로젝트에 대해 이메일이 활성화되었는지 여부. |
| `show_diff_preview_in_email` | 부울 | 이메일 알림에 diff 미리보기가 표시되는지 여부. |
| `shared_runners_enabled` | 부울 | 공유 러너가 프로젝트에 대해 활성화되어 있는지 여부. |
| `lfs_enabled` | 부울 | Git LFS가 프로젝트에 대해 활성화되어 있는지 여부. |
| `creator_id` | 정수 | 프로젝트를 생성한 사용자의 ID. |
| `import_status` | 문자열 | 프로젝트 가져오기 상태. |
| `open_issues_count` | 정수 | 미해결 이슈 수. |
| `description_html` | 문자열 | HTML 형식의 프로젝트 설명. |
| `updated_at` | 날짜/시간 | 프로젝트가 마지막으로 업데이트된 타임스탬프. |
| `ci_config_path` | 문자열 | CI/CD 구성 파일로의 경로. |
| `public_jobs` | 부울 | 작업 로그가 공개적으로 접근 가능한지 여부. |
| `shared_with_groups` | 객체 배열 | 프로젝트가 공유된 그룹 목록. |
| `only_allow_merge_if_pipeline_succeeds` | 부울 | 파이프라인이 성공한 경우에만 머지가 허용되는지 여부. |
| `allow_merge_on_skipped_pipeline` | 부울 | 파이프라인이 건너뛰어진 경우 머지가 허용되는지 여부. |
| `request_access_enabled` | 부울 | 사용자가 프로젝트에 대한 액세스를 요청할 수 있는지 여부. |
| `only_allow_merge_if_all_discussions_are_resolved` | 부울 | 모든 토론이 해결된 경우에만 머지가 허용되는지 여부. |
| `remove_source_branch_after_merge` | 부울 | 머지 후 소스 브랜치가 자동으로 제거되는지 여부. |
| `printing_merge_request_link_enabled` | 부울 | 푸시 후 머지 리퀘스트 링크가 출력되는지 여부. |
| `merge_method` | 문자열 | 프로젝트에 사용되는 머지 방법. 가능한 값: `merge`, `rebase_merge` 또는 `ff`. |
| `merge_request_title_regex` | 문자열 | 머지 리퀘스트 제목 검증을 위한 정규식 패턴. |
| `merge_request_title_regex_description` | 문자열 | 머지 리퀘스트 제목 정규식 검증의 설명. |
| `squash_option` | 문자열 | 머지 리퀘스트의 스쿼시 옵션. |
| `enforce_auth_checks_on_uploads` | 부울 | 업로드에 인증 검사가 적용되는지 여부. |
| `suggestion_commit_message` | 문자열 | 제안에 대한 사용자 정의 커밋 메시지. |
| `merge_commit_template` | 문자열 | 머지 커밋 메시지 템플릿. |
| `mr_default_title_template` | 문자열 | 머지 리퀘스트 제목 템플릿. |
| `squash_commit_template` | 문자열 | 스쿼시 커밋 메시지 템플릿. |
| `issue_branch_template` | 문자열 | 이슈에서 생성된 브랜치 이름 템플릿. |
| `warn_about_potentially_unwanted_characters` | 부울 | 잠재적으로 원치 않는 문자에 대해 경고할지 여부. |
| `autoclose_referenced_issues` | 부울 | 참조된 이슈가 자동으로 종료되는지 여부. |
| `max_artifacts_size` | 정수 | CI/CD 작업 아티팩트의 최대 크기(MB). |
| `approvals_before_merge` | 정수 | 지원 중단됨. 대신 머지 리퀘스트 승인 API를 사용합니다. 머지 전에 필요한 승인 수. |
| `mirror` | 부울 | 프로젝트가 미러인지 여부. |
| `external_authorization_classification_label` | 문자열 | 외부 인증 분류 레이블. |
| `requirements_enabled` | 부울 | 요구 사항 관리가 활성화되어 있는지 여부. |
| `requirements_access_level` | 문자열 | 요구 사항 기능의 액세스 수준. |
| `security_and_compliance_enabled` | 부울 | 보안 및 규정 준수 기능이 활성화되어 있는지 여부. |
| `compliance_frameworks` | 문자열 배열 | 프로젝트에 적용된 규정 준수 프레임워크. |
| `issues_template` | 문자열 | 이슈의 기본 설명. 설명은 GitLab Flavored Markdown으로 구문 분석됩니다. Premium 및 Ultimate만 해당합니다. |
| `merge_requests_template` | 문자열 | 머지 리퀘스트 설명 템플릿. Premium 및 Ultimate만 해당합니다. |
| `merge_pipelines_enabled` | 부울 | 머지 파이프라인이 활성화되어 있는지 여부. |
| `merge_trains_enabled` | 부울 | 머지 트레인이 활성화되어 있는지 여부. |
| `merge_trains_skip_train_allowed` | 부울 | 머지 트레인을 건너뛰는 것이 허용되는지 여부. |
| `max_pipelines_per_merge_train` | 정수 | 머지 트레인당 최대 병렬 파이프라인 수. |
| `only_allow_merge_if_all_status_checks_passed` | 부울 | 모든 상태 검사가 통과한 경우에만 머지가 허용되는지 여부. Ultimate만 해당. |
| `allow_pipeline_trigger_approve_deployment` | 부울 | 파이프라인 트리거가 배포를 승인할 수 있는지 여부. |
| `prevent_merge_without_jira_issue` | 부울 | 머지에 관련 Jira 이슈가 필요한지 여부. |
| `duo_remote_flows_enabled` | 부울 | GitLab Duo 원격 플로우가 활성화되어 있는지 여부. |
| `duo_foundational_flows_enabled` | 부울 | GitLab Duo 기본 플로우가 활성화되어 있는지 여부. |
| `duo_sast_fp_detection_enabled` | 부울 | GitLab Duo SAST 거짓 양성 탐지가 활성화되어 있는지 여부. |
| `duo_sast_vr_workflow_enabled` | 부울 | GitLab Duo SAST 취약성 해결 워크플로우가 활성화되어 있는지 여부. |
| `spp_repository_pipeline_access` | 부울 | 보안 정책의 리포지토리 파이프라인 액세스. 보안 조직 정책 기능을 사용 가능한 경우에만 표시됩니다. |
| `permissions` | 객체 | 프로젝트의 사용자 권한. |
| `permissions.project_access` | 객체 | 사용자의 프로젝트 액세스 권한입니다. |
| `permissions.group_access` | 객체 | 사용자의 그룹 액세스 권한입니다. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects"
```

응답 예시:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "readme_url": "https://gitlab.example.com/diaspora/diaspora-client/blob/main/README.md",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "forks_count": 0,
    "star_count": 0,
    "last_activity_at": "2022-06-24T17:11:26.841Z",
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": "https://gitlab.example.com/uploads/project/avatar/6/uploads/avatar.png",
      "web_url": "https://gitlab.example.com/diaspora"
    },
    "container_registry_image_prefix": "registry.gitlab.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "https://gitlab.example.com/api/v4/projects/4",
      "issues": "https://gitlab.example.com/api/v4/projects/4/issues",
      "merge_requests": "https://gitlab.example.com/api/v4/projects/4/merge_requests",
      "repo_branches": "https://gitlab.example.com/api/v4/projects/4/repository/branches",
      "labels": "https://gitlab.example.com/api/v4/projects/4/labels",
      "events": "https://gitlab.example.com/api/v4/projects/4/events",
      "members": "https://gitlab.example.com/api/v4/projects/4/members",
      "cluster_agents": "https://gitlab.example.com/api/v4/projects/4/cluster_agents"
    },
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "package_registry_access_level": "enabled",
    "empty_repo": false,
    "archived": false,
    "visibility": "public",
    "resolve_outdated_diff_discussions": false,
    "container_expiration_policy": {
      "cadence": "1month",
      "enabled": true,
      "keep_n": 1,
      "older_than": "14d",
      "name_regex": "",
      "name_regex_keep": ".*-main",
      "next_run_at": "2022-06-25T17:11:26.865Z"
    },
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "container_registry_enabled": true,
    "service_desk_enabled": true,
    "can_create_merge_request_in": true,
    "issues_access_level": "enabled",
    "repository_access_level": "enabled",
    "merge_requests_access_level": "enabled",
    "forking_access_level": "enabled",
    "wiki_access_level": "enabled",
    "builds_access_level": "enabled",
    "snippets_access_level": "enabled",
    "pages_access_level": "enabled",
    "analytics_access_level": "enabled",
    "container_registry_access_level": "enabled",
    "security_and_compliance_access_level": "private",
    "emails_disabled": null,
    "emails_enabled": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "lfs_enabled": true,
    "creator_id": 1,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "open_issues_count": 0,
    "ci_default_git_depth": 20,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_job_token_scope_enabled": false,
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "build_timeout": 3600,
    "auto_cancel_pending_pipelines": "enabled",
    "ci_config_path": "",
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": null,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "request_access_enabled": true,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": true,
    "printing_merge_request_link_enabled": true,
    "merge_method": "merge",
    "squash_option": "default_off",
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "auto_devops_enabled": false,
    "auto_devops_deploy_strategy": "continuous",
    "autoclose_referenced_issues": true,
    "keep_latest_artifact": true,
    "runner_token_expiration_interval": null,
    "external_authorization_classification_label": "",
    "requirements_enabled": false,
    "requirements_access_level": "enabled",
    "security_and_compliance_enabled": false,
    "secret_push_protection_enabled": false,
    "compliance_frameworks": [],
    "warn_about_potentially_unwanted_characters": true,
    "permissions": {
      "project_access": null,
      "group_access": null
    }
  },
  {
    ...
  }
]
```

> [!note]
> `last_activity_at`는 [프로젝트 활동](../user/project/working_with_projects.md#view-project-activity) 과 [프로젝트 이벤트](events.md)를 기반으로 업데이트됩니다. 데이터베이스 성능을 최적화하기 위해 이 필드는 최대 1시간에 한 번 업데이트됩니다. 마지막 업데이트로부터 1시간 이내에 발생하는 이벤트는 타임스탬프를 수정하지 않습니다. 결과적으로 `last_activity_at`는 최대 1시간까지 오래될 수 있습니다. `updated_at`는 프로젝트 레코드이 데이터베이스에서 변경될 때마다 업데이트됩니다.

### 사용자의 모든 개인 프로젝트 나열 {#list-all-personal-projects-for-a-user}

{{< history >}}

- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

지정된 사용자의 모든 개인 프로젝트를 나열합니다. 다음 제한 사항이 적용됩니다:

- 사용자의 개인 네임스페이스의 프로젝트만 반환하며, 그룹 또는 서브그룹 프로젝트는 반환하지 않습니다.
- 사용자 프로필이 비공개인 경우 빈 목록을 반환합니다.
- 인증 없는 요청은 공개 프로젝트만 반환합니다.

이 엔드포인트는 페이지 매김을 지원합니다:

- 오프셋 기반 페이지 매김을 사용하여 최대 50,000개 프로젝트에 액세스합니다.
- 키셋 기반 페이지 매김을 사용하여 50,000개 이상의 프로젝트를 나열합니다.

자세한 내용은 [페이지 매김](rest/_index.md#pagination)을 참조하세요.

```plaintext
GET /users/:user_id/projects
```

지원되는 속성:

| 속성                     | 유형     | 필수 | 설명 |
|:------------------------------|:---------|:---------|:------------|
| `user_id`                     | 문자열   | 예      | 사용자의 ID 또는 사용자 이름입니다. |
| `archived`                    | 부울  | 아니요       | 보관 상태로 제한합니다. |
| `id_after`                    | 정수  | 아니요       | 지정된 ID보다 큰 ID를 가진 프로젝트로 결과를 제한합니다. |
| `id_before`                   | 정수  | 아니요       | 지정된 ID보다 작은 ID를 가진 프로젝트로 결과를 제한합니다. |
| `membership`                  | 부울  | 아니요       | 현재 사용자가 멤버인 프로젝트로 제한합니다. |
| `min_access_level`            | 정수  | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 보유한 프로젝트로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `order_by`                    | 문자열   | 아니요       | `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` 또는 `last_activity_at` 필드로 정렬하여 프로젝트를 반환합니다. 기본값은 `created_at`입니다. |
| `owned`                       | 부울  | 아니요       | 현재 사용자가 명시적으로 소유한 프로젝트로 제한합니다. |
| `search`                      | 문자열   | 아니요       | 검색 기준과 일치하는 프로젝트 목록을 반환합니다. |
| `simple`                      | 부울  | 아니요       | `true`이면 각 프로젝트의 제한된 필드만 반환합니다. 인증되지 않은 요청은 `simple`을 설정하지 않았더라도 제한된 필드가 있는 공개 프로젝트만 반환합니다. |
| `sort`                        | 문자열   | 아니요       | `asc` 또는 `desc` 순서로 프로젝트를 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `starred`                     | 부울  | 아니요       | 현재 사용자가 별표로 표시한 프로젝트로 제한합니다. |
| `statistics`                  | 부울  | 아니요       | 프로젝트 통계를 포함합니다. 리포터, 개발자, 유지 보수자 또는 소유자 역할을 가진 사용자만 사용 가능합니다. |
| `updated_after`               | 날짜/시간 | 아니요       | 지정된 시간 이후에 마지막으로 업데이트된 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `updated_before`              | 날짜/시간 | 아니요       | 지정된 시간 이전에 마지막으로 업데이트된 프로젝트로 결과를 제한합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `visibility`                  | 문자열   | 아니요       | 가시성으로 제한합니다. 가능한 값: `public`, `internal` 또는 `private`. |
| `with_custom_attributes`      | 부울  | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md)을 포함합니다. 관리자 액세스 권한이 있어야 합니다. |
| `with_issues_enabled`         | 부울  | 아니요       | 활성화된 이슈 기능으로 제한합니다. |
| `with_merge_requests_enabled` | 부울  | 아니요       | 활성화된 머지 리퀘스트 기능으로 제한합니다. |
| `with_programming_language`   | 문자열   | 아니요       | 지정된 프로그래밍 언어를 사용하는 프로젝트로 제한합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `id` | 정수 | 프로젝트의 ID입니다. |
| `description` | 문자열 | 프로젝트의 설명. |
| `name` | 문자열 | 프로젝트의 이름. |
| `name_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 이름. |
| `path` | 문자열 | 프로젝트의 경로. |
| `path_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 경로. |
| `created_at` | 날짜/시간 | 프로젝트가 생성된 타임스탬프. |
| `default_branch` | 문자열 | 프로젝트의 기본 브랜치. |
| `tag_list` | 문자열 배열 | 지원 중단됨. `topics` 대신 사용합니다. 프로젝트의 태그 목록. |
| `topics` | 문자열 배열 | 프로젝트의 주제 목록. |
| `ssh_url_to_repo` | 문자열 | 리포지토리를 복제할 SSH URL. |
| `http_url_to_repo` | 문자열 | 리포지토리를 복제할 HTTP URL. |
| `web_url` | 문자열 | 브라우저에서 프로젝트에 액세스할 URL. |
| `readme_url` | 문자열 | 프로젝트의 README 파일 URL. |
| `forks_count` | 정수 | 프로젝트의 포크 수. |
| `avatar_url` | 문자열 | 프로젝트의 아바타 이미지 URL. |
| `star_count` | 정수 | 프로젝트가 받은 스타 수. |
| `last_activity_at` | 날짜/시간 | 프로젝트의 마지막 활동 타임스탬프. |
| `visibility` | 문자열 | 프로젝트의 가시성 수준. 가능한 값: `private`, `internal` 또는 `public`. |
| `namespace` | 객체 | 프로젝트의 네임스페이스 정보. |
| `namespace.id` | 정수 | 네임스페이스의 ID. |
| `namespace.name` | 문자열 | 네임스페이스의 이름. |
| `namespace.path` | 문자열 | 네임스페이스의 경로. |
| `namespace.kind` | 문자열 | 네임스페이스의 유형. 가능한 값: `user` 또는 `group`. |
| `namespace.full_path` | 문자열 | 네임스페이스의 전체 경로. |
| `namespace.parent_id` | 정수 | 해당하는 경우 부모 네임스페이스의 ID. |
| `namespace.avatar_url` | 문자열 | 네임스페이스의 아바타 이미지 URL. |
| `namespace.web_url` | 문자열 | 브라우저에서 네임스페이스에 액세스할 URL. |
| `container_registry_image_prefix` | 문자열 | 컨테이너 레지스트리 이미지의 접두사. |
| `_links` | 객체 | 프로젝트와 관련된 API 엔드포인트 링크 모음. |
| `_links.self` | 문자열 | 프로젝트 리소스로의 URL. |
| `_links.issues` | 문자열 | 프로젝트의 이슈로의 URL. |
| `_links.merge_requests` | 문자열 | 프로젝트의 머지 리퀘스트로의 URL. |
| `_links.repo_branches` | 문자열 | 프로젝트의 리포지토리 브랜치로의 URL. |
| `_links.labels` | 문자열 | 프로젝트의 레이블로의 URL. |
| `_links.events` | 문자열 | 프로젝트의 이벤트로의 URL. |
| `_links.members` | 문자열 | 프로젝트의 멤버로의 URL. |
| `_links.cluster_agents` | 문자열 | 프로젝트의 클러스터 에이전트로의 URL. |
| `marked_for_deletion_at` | 날짜 | 지원 중단됨. `marked_for_deletion_on` 대신 사용합니다. 프로젝트가 삭제 예약된 날짜. |
| `marked_for_deletion_on` | 날짜 | 프로젝트가 삭제 예약된 날짜. |
| `packages_enabled` | 부울 | 패키지 레지스트리가 프로젝트에 대해 활성화되어 있는지 여부. |
| `empty_repo` | 부울 | 리포지토리가 비어 있는지 여부. |
| `archived` | 부울 | 프로젝트가 보관되어 있는지 여부. |
| `resolve_outdated_diff_discussions` | 부울 | 오래된 diff 토론이 자동으로 해결되는지 여부. |
| `container_expiration_policy` | 객체 | 컨테이너 이미지 만료 정책의 설정. |
| `container_expiration_policy.cadence` | 문자열 | 컨테이너 만료 정책이 실행되는 빈도. |
| `container_expiration_policy.enabled` | 부울 | 컨테이너 만료 정책이 활성화되어 있는지 여부. |
| `container_expiration_policy.keep_n` | 정수 | 유지할 컨테이너 이미지 수. |
| `container_expiration_policy.older_than` | 문자열 | 이 값보다 오래된 컨테이너 이미지를 제거합니다. |
| `container_expiration_policy.name_regex` | 문자열 | 지원 중단됨. `name_regex_delete` 대신 사용합니다. 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.name_regex_keep` | 문자열 | 유지할 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.next_run_at` | 날짜/시간 | 다음 정책 실행 예약 타임스탬프. |
| `repository_object_format` | 문자열 | 리포지토리에서 사용하는 객체 형식(sha1 또는 sha256)입니다. |
| `issues_enabled` | 부울 | 이슈가 프로젝트에 대해 활성화되어 있는지 여부. |
| `merge_requests_enabled` | 부울 | 머지 리퀘스트가 프로젝트에 대해 활성화되어 있는지 여부. |
| `wiki_enabled` | 부울 | 위키가 프로젝트에 대해 활성화되어 있는지 여부. |
| `jobs_enabled` | 부울 | 작업이 프로젝트에 대해 활성화되어 있는지 여부. |
| `snippets_enabled` | 부울 | 스니펫이 프로젝트에 대해 활성화되어 있는지 여부. |
| `container_registry_enabled` | 부울 | 지원 중단됨. `container_registry_access_level` 대신 사용합니다. 컨테이너 레지스트리가 활성화되어 있는지 여부. |
| `service_desk_enabled` | 부울 | Service Desk가 프로젝트에 대해 활성화되어 있는지 여부. |
| `can_create_merge_request_in` | 부울 | 현재 사용자가 프로젝트에서 머지 리퀘스트를 생성할 수 있는지 여부. |
| `issues_access_level` | 문자열 | 이슈 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `repository_access_level` | 문자열 | 리포지토리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `merge_requests_access_level` | 문자열 | 머지 리퀘스트 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `forking_access_level` | 문자열 | 프로젝트를 포크하기 위한 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `wiki_access_level` | 문자열 | 위키 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `builds_access_level` | 문자열 | CI/CD 작업 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `snippets_access_level` | 문자열 | 스니펫 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `pages_access_level` | 문자열 | GitLab Pages의 액세스 수준. 가능한 값: `disabled`, `private`, `enabled` 또는 `public`. |
| `analytics_access_level` | 문자열 | 분석 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `container_registry_access_level` | 문자열 | 컨테이너 레지스트리의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `security_and_compliance_access_level` | 문자열 | 보안 및 규정 준수 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `releases_access_level` | 문자열 | 릴리스 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `environments_access_level` | 문자열 | 환경 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `feature_flags_access_level` | 문자열 | 기능 플래그 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `infrastructure_access_level` | 문자열 | 인프라 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `monitor_access_level` | 문자열 | 모니터 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_experiments_access_level` | 문자열 | 모델 실험 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_registry_access_level` | 문자열 | 모델 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `package_registry_access_level` | 문자열 | 패키지 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `emails_disabled` | 부울 | 프로젝트에 대해 이메일이 비활성화되었는지 여부. |
| `emails_enabled` | 부울 | 프로젝트에 대해 이메일이 활성화되었는지 여부. |
| `show_diff_preview_in_email` | 부울 | 이메일 알림에 diff 미리보기가 표시되는지 여부. |
| `shared_runners_enabled` | 부울 | 공유 러너가 프로젝트에 대해 활성화되어 있는지 여부. |
| `lfs_enabled` | 부울 | Git LFS가 프로젝트에 대해 활성화되어 있는지 여부. |
| `creator_id` | 정수 | 프로젝트를 생성한 사용자의 ID. |
| `import_status` | 문자열 | 프로젝트 가져오기 상태. |
| `open_issues_count` | 정수 | 미해결 이슈 수. |
| `description_html` | 문자열 | HTML 형식의 프로젝트 설명. |
| `updated_at` | 날짜/시간 | 프로젝트가 마지막으로 업데이트된 타임스탬프. |
| `ci_default_git_depth` | 정수 | CI/CD 파이프라인의 기본 Git 깊이. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_forward_deployment_enabled` | 부울 | 전달 배포가 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_job_token_scope_enabled` | 부울 | CI/CD 작업 토큰 범위가 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_separated_caches` | 부울 | CI/CD 캐시가 브랜치별로 분리되는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | 부울 | 포크 파이프라인이 부모 프로젝트에서 실행될 수 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `build_git_strategy` | 문자열 | CI/CD 작업에 사용되는 Git 전략(가져오기 또는 클론). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `keep_latest_artifact` | 부울 | 새 아티팩트가 생성될 때 최신 작업 아티팩트를 유지하는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `restrict_user_defined_variables` | 부울 | 사용자 정의 변수가 제한되는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `runners_token` | 문자열 | 프로젝트에 러너를 등록하기 위한 토큰. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `runner_token_expiration_interval` | 정수 | 러너 토큰의 만료 간격(초). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `group_runners_enabled` | 부울 | 그룹 러너가 프로젝트에 대해 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_cancel_pending_pipelines` | 문자열 | 자동으로 보류 중인 파이프라인을 취소하기 위한 설정. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `build_timeout` | 정수 | CI/CD 작업의 시간 초과(초). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_devops_enabled` | 부울 | Auto DevOps가 프로젝트에 대해 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_devops_deploy_strategy` | 문자열 | Auto DevOps의 배포 전략. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_config_path` | 문자열 | CI/CD 구성 파일로의 경로. |
| `public_jobs` | 부울 | 작업 로그가 공개적으로 접근 가능한지 여부. |
| `shared_with_groups` | 객체 배열 | 프로젝트가 공유된 그룹 목록. |
| `only_allow_merge_if_pipeline_succeeds` | 부울 | 파이프라인이 성공한 경우에만 머지가 허용되는지 여부. |
| `allow_merge_on_skipped_pipeline` | 부울 | 파이프라인이 건너뛰어진 경우 머지가 허용되는지 여부. |
| `request_access_enabled` | 부울 | 사용자가 프로젝트에 대한 액세스를 요청할 수 있는지 여부. |
| `only_allow_merge_if_all_discussions_are_resolved` | 부울 | 모든 토론이 해결된 경우에만 머지가 허용되는지 여부. |
| `remove_source_branch_after_merge` | 부울 | 머지 후 소스 브랜치가 자동으로 제거되는지 여부. |
| `printing_merge_request_link_enabled` | 부울 | 푸시 후 머지 리퀘스트 링크가 출력되는지 여부. |
| `merge_method` | 문자열 | 프로젝트에 사용되는 머지 방법. 가능한 값: `merge`, `rebase_merge` 또는 `ff`. |
| `merge_request_title_regex` | 문자열 | 머지 리퀘스트 제목 검증을 위한 정규식 패턴. |
| `merge_request_title_regex_description` | 문자열 | 머지 리퀘스트 제목 정규식 검증의 설명. |
| `squash_option` | 문자열 | 머지 리퀘스트의 스쿼시 옵션. |
| `enforce_auth_checks_on_uploads` | 부울 | 업로드에 인증 검사가 적용되는지 여부. |
| `suggestion_commit_message` | 문자열 | 제안에 대한 사용자 정의 커밋 메시지. |
| `merge_commit_template` | 문자열 | 머지 커밋 메시지 템플릿. |
| `mr_default_title_template` | 문자열 | 머지 리퀘스트 제목 템플릿. |
| `squash_commit_template` | 문자열 | 스쿼시 커밋 메시지 템플릿. |
| `issue_branch_template` | 문자열 | 이슈에서 생성된 브랜치 이름 템플릿. |
| `warn_about_potentially_unwanted_characters` | 부울 | 잠재적으로 원치 않는 문자에 대해 경고할지 여부. |
| `autoclose_referenced_issues` | 부울 | 참조된 이슈가 자동으로 종료되는지 여부. |
| `max_artifacts_size` | 정수 | CI/CD 작업 아티팩트의 최대 크기(MB). |
| `approvals_before_merge` | 정수 | 지원 중단됨. 대신 머지 리퀘스트 승인 API를 사용합니다. 머지 전에 필요한 승인 수. |
| `mirror` | 부울 | 프로젝트가 미러인지 여부. |
| `external_authorization_classification_label` | 문자열 | 외부 인증 분류 레이블. |
| `requirements_enabled` | 부울 | 요구 사항 관리가 활성화되어 있는지 여부. |
| `requirements_access_level` | 문자열 | 요구 사항 기능의 액세스 수준. |
| `security_and_compliance_enabled` | 부울 | 보안 및 규정 준수 기능이 활성화되어 있는지 여부. |
| `compliance_frameworks` | 문자열 배열 | 프로젝트에 적용된 규정 준수 프레임워크. |
| `issues_template` | 문자열 | 이슈의 기본 설명. 설명은 GitLab Flavored Markdown으로 구문 분석됩니다. Premium 및 Ultimate만 해당합니다. |
| `merge_requests_template` | 문자열 | 머지 리퀘스트 설명 템플릿. Premium 및 Ultimate만 해당합니다. |
| `merge_pipelines_enabled` | 부울 | 머지 파이프라인이 활성화되어 있는지 여부. |
| `merge_trains_enabled` | 부울 | 머지 트레인이 활성화되어 있는지 여부. |
| `merge_trains_skip_train_allowed` | 부울 | 머지 트레인을 건너뛰는 것이 허용되는지 여부. |
| `max_pipelines_per_merge_train` | 정수 | 머지 트레인당 최대 병렬 파이프라인 수. |
| `only_allow_merge_if_all_status_checks_passed` | 부울 | 모든 상태 검사가 통과한 경우에만 머지가 허용되는지 여부. Ultimate만 해당. |
| `allow_pipeline_trigger_approve_deployment` | 부울 | 파이프라인 트리거가 배포를 승인할 수 있는지 여부. |
| `prevent_merge_without_jira_issue` | 부울 | 머지에 관련 Jira 이슈가 필요한지 여부. |
| `duo_remote_flows_enabled` | 부울 | GitLab Duo 원격 플로우가 활성화되어 있는지 여부. |
| `duo_foundational_flows_enabled` | 부울 | GitLab Duo 기본 플로우가 활성화되어 있는지 여부. |
| `duo_sast_fp_detection_enabled` | 부울 | GitLab Duo SAST 거짓 양성 탐지가 활성화되어 있는지 여부. |
| `duo_sast_vr_workflow_enabled` | 부울 | GitLab Duo SAST 취약성 해결 워크플로우가 활성화되어 있는지 여부. |
| `spp_repository_pipeline_access` | 부울 | 보안 정책의 리포지토리 파이프라인 액세스. 보안 조직 정책 기능을 사용 가능한 경우에만 표시됩니다. |
| `permissions` | 객체 | 프로젝트의 사용자 권한. |
| `permissions.project_access` | 객체 | 사용자의 프로젝트 액세스 권한입니다. |
| `permissions.group_access` | 객체 | 사용자의 그룹 액세스 권한입니다. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/users/:user_id/projects
```

응답 예시:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
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
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
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
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
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
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
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
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
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

### 사용자의 모든 프로젝트 기여도 나열 {#list-all-projects-contributions-for-a-user}

{{< history >}}

- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

지정된 사용자의 표시 가능한 프로젝트에 대한 모든 기여를 나열합니다. 지난 1년의 기여만 반환합니다. 기여로 간주되는 항목에 대한 자세한 내용은 [작업하는 프로젝트 보기](../user/project/working_with_projects.md#view-projects-you-work-with)를 참조하세요.

```plaintext
GET /users/:user_id/contributed_projects
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명 |
|:-----------|:--------|:---------|:------------|
| `user_id`  | 문자열  | 예      | 사용자의 ID 또는 사용자 이름입니다. |
| `order_by` | 문자열  | 아니요       | `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` 또는 `last_activity_at` 필드로 정렬하여 프로젝트를 반환합니다. 기본값은 `created_at`입니다. |
| `simple`   | 부울 | 아니요       | `true`이면 각 프로젝트의 제한된 필드만 반환합니다. 인증되지 않은 요청은 `simple`을 설정하지 않았더라도 제한된 필드가 있는 공개 프로젝트만 반환합니다. |
| `sort`     | 문자열  | 아니요       | `asc` 또는 `desc` 순서로 프로젝트를 정렬하여 반환합니다. 기본값은 `desc`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `id` | 정수 | 프로젝트의 ID입니다. |
| `description` | 문자열 | 프로젝트의 설명. |
| `name` | 문자열 | 프로젝트의 이름. |
| `name_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 이름. |
| `path` | 문자열 | 프로젝트의 경로. |
| `path_with_namespace` | 문자열 | 네임스페이스와 함께 프로젝트의 경로. |
| `created_at` | 날짜/시간 | 프로젝트가 생성된 타임스탬프. |
| `default_branch` | 문자열 | 프로젝트의 기본 브랜치. |
| `tag_list` | 문자열 배열 | 지원 중단됨. `topics` 대신 사용합니다. 프로젝트의 태그 목록. |
| `topics` | 문자열 배열 | 프로젝트의 주제 목록. |
| `ssh_url_to_repo` | 문자열 | 리포지토리를 복제할 SSH URL. |
| `http_url_to_repo` | 문자열 | 리포지토리를 복제할 HTTP URL. |
| `web_url` | 문자열 | 브라우저에서 프로젝트에 액세스할 URL. |
| `readme_url` | 문자열 | 프로젝트의 README 파일 URL. |
| `forks_count` | 정수 | 프로젝트의 포크 수. |
| `avatar_url` | 문자열 | 프로젝트의 아바타 이미지 URL. |
| `star_count` | 정수 | 프로젝트가 받은 스타 수. |
| `last_activity_at` | 날짜/시간 | 프로젝트의 마지막 활동 타임스탬프. |
| `visibility` | 문자열 | 프로젝트의 가시성 수준. 가능한 값: `private`, `internal` 또는 `public`. |
| `namespace` | 객체 | 프로젝트의 네임스페이스 정보. |
| `namespace.id` | 정수 | 네임스페이스의 ID. |
| `namespace.name` | 문자열 | 네임스페이스의 이름. |
| `namespace.path` | 문자열 | 네임스페이스의 경로. |
| `namespace.kind` | 문자열 | 네임스페이스의 유형. 가능한 값: `user` 또는 `group`. |
| `namespace.full_path` | 문자열 | 네임스페이스의 전체 경로. |
| `namespace.parent_id` | 정수 | 해당하는 경우 부모 네임스페이스의 ID. |
| `namespace.avatar_url` | 문자열 | 네임스페이스의 아바타 이미지 URL. |
| `namespace.web_url` | 문자열 | 브라우저에서 네임스페이스에 액세스할 URL. |
| `container_registry_image_prefix` | 문자열 | 컨테이너 레지스트리 이미지의 접두사. |
| `_links` | 객체 | 프로젝트와 관련된 API 엔드포인트 링크 모음. |
| `_links.self` | 문자열 | 프로젝트 리소스로의 URL. |
| `_links.issues` | 문자열 | 프로젝트의 이슈로의 URL. |
| `_links.merge_requests` | 문자열 | 프로젝트의 머지 리퀘스트로의 URL. |
| `_links.repo_branches` | 문자열 | 프로젝트의 리포지토리 브랜치로의 URL. |
| `_links.labels` | 문자열 | 프로젝트의 레이블로의 URL. |
| `_links.events` | 문자열 | 프로젝트의 이벤트로의 URL. |
| `_links.members` | 문자열 | 프로젝트의 멤버로의 URL. |
| `_links.cluster_agents` | 문자열 | 프로젝트의 클러스터 에이전트로의 URL. |
| `marked_for_deletion_at` | 날짜 | 지원 중단됨. `marked_for_deletion_on` 대신 사용합니다. 프로젝트가 삭제 예약된 날짜. |
| `marked_for_deletion_on` | 날짜 | 프로젝트가 삭제 예약된 날짜. |
| `packages_enabled` | 부울 | 패키지 레지스트리가 프로젝트에 대해 활성화되어 있는지 여부. |
| `empty_repo` | 부울 | 리포지토리가 비어 있는지 여부. |
| `archived` | 부울 | 프로젝트가 보관되어 있는지 여부. |
| `resolve_outdated_diff_discussions` | 부울 | 오래된 diff 토론이 자동으로 해결되는지 여부. |
| `container_expiration_policy` | 객체 | 컨테이너 이미지 만료 정책의 설정. |
| `container_expiration_policy.cadence` | 문자열 | 컨테이너 만료 정책이 실행되는 빈도. |
| `container_expiration_policy.enabled` | 부울 | 컨테이너 만료 정책이 활성화되어 있는지 여부. |
| `container_expiration_policy.keep_n` | 정수 | 유지할 컨테이너 이미지 수. |
| `container_expiration_policy.older_than` | 문자열 | 이 값보다 오래된 컨테이너 이미지를 제거합니다. |
| `container_expiration_policy.name_regex` | 문자열 | 지원 중단됨. `name_regex_delete` 대신 사용합니다. 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.name_regex_keep` | 문자열 | 유지할 컨테이너 이미지 이름과 일치하는 정규식. |
| `container_expiration_policy.next_run_at` | 날짜/시간 | 다음 정책 실행 예약 타임스탬프. |
| `repository_object_format` | 문자열 | 리포지토리에서 사용하는 객체 형식(sha1 또는 sha256)입니다. |
| `issues_enabled` | 부울 | 이슈가 프로젝트에 대해 활성화되어 있는지 여부. |
| `merge_requests_enabled` | 부울 | 머지 리퀘스트가 프로젝트에 대해 활성화되어 있는지 여부. |
| `wiki_enabled` | 부울 | 위키가 프로젝트에 대해 활성화되어 있는지 여부. |
| `jobs_enabled` | 부울 | 작업이 프로젝트에 대해 활성화되어 있는지 여부. |
| `snippets_enabled` | 부울 | 스니펫이 프로젝트에 대해 활성화되어 있는지 여부. |
| `container_registry_enabled` | 부울 | 지원 중단됨. `container_registry_access_level` 대신 사용합니다. 컨테이너 레지스트리가 활성화되어 있는지 여부. |
| `service_desk_enabled` | 부울 | Service Desk가 프로젝트에 대해 활성화되어 있는지 여부. |
| `can_create_merge_request_in` | 부울 | 현재 사용자가 프로젝트에서 머지 리퀘스트를 생성할 수 있는지 여부. |
| `issues_access_level` | 문자열 | 이슈 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `repository_access_level` | 문자열 | 리포지토리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `merge_requests_access_level` | 문자열 | 머지 리퀘스트 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `forking_access_level` | 문자열 | 프로젝트를 포크하기 위한 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `wiki_access_level` | 문자열 | 위키 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `builds_access_level` | 문자열 | CI/CD 작업 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `snippets_access_level` | 문자열 | 스니펫 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `pages_access_level` | 문자열 | GitLab Pages의 액세스 수준. 가능한 값: `disabled`, `private`, `enabled` 또는 `public`. |
| `analytics_access_level` | 문자열 | 분석 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `container_registry_access_level` | 문자열 | 컨테이너 레지스트리의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `security_and_compliance_access_level` | 문자열 | 보안 및 규정 준수 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `releases_access_level` | 문자열 | 릴리스 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `environments_access_level` | 문자열 | 환경 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `feature_flags_access_level` | 문자열 | 기능 플래그 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `infrastructure_access_level` | 문자열 | 인프라 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `monitor_access_level` | 문자열 | 모니터 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_experiments_access_level` | 문자열 | 모델 실험 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `model_registry_access_level` | 문자열 | 모델 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `package_registry_access_level` | 문자열 | 패키지 레지스트리 기능의 액세스 수준. 가능한 값: `disabled`, `private` 또는 `enabled`. |
| `emails_disabled` | 부울 | 프로젝트에 대해 이메일이 비활성화되었는지 여부. |
| `emails_enabled` | 부울 | 프로젝트에 대해 이메일이 활성화되었는지 여부. |
| `show_diff_preview_in_email` | 부울 | 이메일 알림에 diff 미리보기가 표시되는지 여부. |
| `shared_runners_enabled` | 부울 | 공유 러너가 프로젝트에 대해 활성화되어 있는지 여부. |
| `lfs_enabled` | 부울 | Git LFS가 프로젝트에 대해 활성화되어 있는지 여부. |
| `creator_id` | 정수 | 프로젝트를 생성한 사용자의 ID. |
| `import_status` | 문자열 | 프로젝트 가져오기 상태. |
| `open_issues_count` | 정수 | 미해결 이슈 수. |
| `description_html` | 문자열 | HTML 형식의 프로젝트 설명. |
| `updated_at` | 날짜/시간 | 프로젝트가 마지막으로 업데이트된 타임스탬프. |
| `ci_default_git_depth` | 정수 | CI/CD 파이프라인의 기본 Git 깊이. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_forward_deployment_enabled` | 부울 | 전달 배포가 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_job_token_scope_enabled` | 부울 | CI/CD 작업 토큰 범위가 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_separated_caches` | 부울 | CI/CD 캐시가 브랜치별로 분리되는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | 부울 | 포크 파이프라인이 부모 프로젝트에서 실행될 수 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `build_git_strategy` | 문자열 | CI/CD 작업에 사용되는 Git 전략(가져오기 또는 클론). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `keep_latest_artifact` | 부울 | 새 아티팩트가 생성될 때 최신 작업 아티팩트를 유지하는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `restrict_user_defined_variables` | 부울 | 사용자 정의 변수가 제한되는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `runners_token` | 문자열 | 프로젝트에 러너를 등록하기 위한 토큰. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `runner_token_expiration_interval` | 정수 | 러너 토큰의 만료 간격(초). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `group_runners_enabled` | 부울 | 그룹 러너가 프로젝트에 대해 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_cancel_pending_pipelines` | 문자열 | 자동으로 보류 중인 파이프라인을 취소하기 위한 설정. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `build_timeout` | 정수 | CI/CD 작업의 시간 초과(초). 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_devops_enabled` | 부울 | Auto DevOps가 프로젝트에 대해 활성화되어 있는지 여부. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `auto_devops_deploy_strategy` | 문자열 | Auto DevOps의 배포 전략. 관리자 액세스 권한이 있거나 프로젝트의 소유자 역할이 있을 때만 표시됩니다. |
| `ci_config_path` | 문자열 | CI/CD 구성 파일로의 경로. |
| `public_jobs` | 부울 | 작업 로그가 공개적으로 접근 가능한지 여부. |
| `shared_with_groups` | 객체 배열 | 프로젝트가 공유된 그룹 목록. |
| `only_allow_merge_if_pipeline_succeeds` | 부울 | 파이프라인이 성공한 경우에만 머지가 허용되는지 여부. |
| `allow_merge_on_skipped_pipeline` | 부울 | 파이프라인이 건너뛰어진 경우 머지가 허용되는지 여부. |
| `request_access_enabled` | 부울 | 사용자가 프로젝트에 대한 액세스를 요청할 수 있는지 여부. |
| `only_allow_merge_if_all_discussions_are_resolved` | 부울 | 모든 토론이 해결된 경우에만 머지가 허용되는지 여부. |
| `remove_source_branch_after_merge` | 부울 | 머지 후 소스 브랜치가 자동으로 제거되는지 여부. |
| `printing_merge_request_link_enabled` | 부울 | 푸시 후 머지 리퀘스트 링크가 출력되는지 여부. |
| `merge_method` | 문자열 | 프로젝트에 사용되는 머지 방법. 가능한 값: `merge`, `rebase_merge` 또는 `ff`. |
| `merge_request_title_regex` | 문자열 | 머지 리퀘스트 제목 검증을 위한 정규식 패턴. |
| `merge_request_title_regex_description` | 문자열 | 머지 리퀘스트 제목 정규식 검증의 설명. |
| `squash_option` | 문자열 | 머지 리퀘스트의 스쿼시 옵션. |
| `enforce_auth_checks_on_uploads` | 부울 | 업로드에 인증 검사가 적용되는지 여부. |
| `suggestion_commit_message` | 문자열 | 제안에 대한 사용자 정의 커밋 메시지. |
| `merge_commit_template` | 문자열 | 머지 커밋 메시지 템플릿. |
| `mr_default_title_template` | 문자열 | 머지 리퀘스트 제목 템플릿. |
| `squash_commit_template` | 문자열 | 스쿼시 커밋 메시지 템플릿. |
| `issue_branch_template` | 문자열 | 이슈에서 생성된 브랜치 이름 템플릿. |
| `warn_about_potentially_unwanted_characters` | 부울 | 잠재적으로 원치 않는 문자에 대해 경고할지 여부. |
| `autoclose_referenced_issues` | 부울 | 참조된 이슈가 자동으로 종료되는지 여부. |
| `max_artifacts_size` | 정수 | CI/CD 작업 아티팩트의 최대 크기(MB). |
| `approvals_before_merge` | 정수 | 지원 중단됨. 대신 머지 리퀘스트 승인 API를 사용합니다. 머지 전에 필요한 승인 수. |
| `mirror` | 부울 | 프로젝트가 미러인지 여부. |
| `external_authorization_classification_label` | 문자열 | 외부 인증 분류 레이블. |
| `requirements_enabled` | 부울 | 요구 사항 관리가 활성화되어 있는지 여부. |
| `requirements_access_level` | 문자열 | 요구 사항 기능의 액세스 수준. |
| `security_and_compliance_enabled` | 부울 | 보안 및 규정 준수 기능이 활성화되어 있는지 여부. |
| `compliance_frameworks` | 문자열 배열 | 프로젝트에 적용된 규정 준수 프레임워크. |
| `issues_template` | 문자열 | 이슈의 기본 설명. 설명은 GitLab Flavored Markdown으로 구문 분석됩니다. Premium 및 Ultimate만 해당합니다. |
| `merge_requests_template` | 문자열 | 머지 리퀘스트 설명 템플릿. Premium 및 Ultimate만 해당합니다. |
| `merge_pipelines_enabled` | 부울 | 머지 파이프라인이 활성화되어 있는지 여부. |
| `merge_trains_enabled` | 부울 | 머지 트레인이 활성화되어 있는지 여부. |
| `merge_trains_skip_train_allowed` | 부울 | 머지 트레인을 건너뛰는 것이 허용되는지 여부. |
| `max_pipelines_per_merge_train` | 정수 | 머지 트레인당 최대 병렬 파이프라인 수. |
| `only_allow_merge_if_all_status_checks_passed` | 부울 | 모든 상태 검사가 통과한 경우에만 머지가 허용되는지 여부. Ultimate만 해당. |
| `allow_pipeline_trigger_approve_deployment` | 부울 | 파이프라인 트리거가 배포를 승인할 수 있는지 여부. |
| `prevent_merge_without_jira_issue` | 부울 | 머지에 관련 Jira 이슈가 필요한지 여부. |
| `duo_remote_flows_enabled` | 부울 | GitLab Duo 원격 플로우가 활성화되어 있는지 여부. |
| `duo_foundational_flows_enabled` | 부울 | GitLab Duo 기본 플로우가 활성화되어 있는지 여부. |
| `duo_sast_fp_detection_enabled` | 부울 | GitLab Duo SAST 거짓 양성 탐지가 활성화되어 있는지 여부. |
| `duo_sast_vr_workflow_enabled` | 부울 | GitLab Duo SAST 취약성 해결 워크플로우가 활성화되어 있는지 여부. |
| `spp_repository_pipeline_access` | 부울 | 보안 정책의 리포지토리 파이프라인 액세스. 보안 조직 정책 기능을 사용 가능한 경우에만 표시됩니다. |
| `permissions` | 객체 | 프로젝트의 사용자 권한. |
| `permissions.project_access` | 객체 | 사용자의 프로젝트 액세스 권한입니다. |
| `permissions.group_access` | 객체 | 사용자의 그룹 액세스 권한입니다. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/5/contributed_projects"
```

응답 예시:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
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
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
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
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
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
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
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
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
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

## 속성 나열 {#list-attributes}

프로젝트의 속성을 나열합니다.

### 프로젝트의 모든 멤버 나열 {#list-all-members-of-a-project}

지정된 프로젝트에 액세스할 수 있는 모든 멤버를 나열합니다.

```plaintext
GET /projects/:id/users
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|:-------------|:------------------|:---------|:------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`     | 문자열            | 아니요       | `username` 또는 `name`로 특정 멤버를 검색합니다. |
| `skip_users` | 정수 배열     | 아니요       | 지정된 ID를 가진 멤버를 필터링합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|:----------|:-----|:------------|
| `id` | 정수 | 사용자의 ID입니다. |
| `username` | 문자열 | 사용자의 사용자 이름입니다. |
| `name` | 문자열 | 사용자의 전체 이름입니다. |
| `state` | 문자열 | 사용자 계정의 상태입니다. 가능한 값: `active` 또는 `blocked`. |
| `avatar_url` | 문자열 | 사용자의 아바타 이미지에 대한 URL입니다. |
| `web_url` | 문자열 | 브라우저에서 사용자 프로필에 액세스하기 위한 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<project_id>/users" \
```

응답 예시:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

### 모든 상위 그룹 나열 {#list-all-ancestor-groups}

지정된 프로젝트의 모든 상위 그룹을 나열합니다.

```plaintext
GET /projects/:id/groups
```

지원되는 속성:

| 속성                 | 유형              | 필수 | 설명 |
|:--------------------------|:------------------|:---------|:------------|
| `id`                      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`                  | 문자열            | 아니요       | 그룹 ID별로 특정 그룹을 검색합니다. |
| `shared_min_access_level` | 정수           | 아니요       | 지정된 액세스 수준 이상의 공유 그룹으로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `shared_visible_only`     | 부울           | 아니요       | `true`이면 인증된 사용자가 액세스할 수 있는 공유 그룹만 반환합니다. |
| `skip_groups`             | 정수 배열 | 아니요       | 전달된 그룹 ID를 건너뜁니다. |
| `with_shared`             | 부울           | 아니요       | 이 그룹과 공유된 프로젝트를 포함합니다. 기본값은 `false`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|:----------|:-----|:------------|
| `id` | 정수 | 그룹의 ID입니다. |
| `name` | 문자열 | 그룹의 이름입니다. |
| `avatar_url` | 문자열 | 그룹의 아바타 이미지에 대한 URL입니다. |
| `web_url` | 문자열 | 브라우저에서 그룹에 액세스하기 위한 URL입니다. |
| `full_name` | 문자열 | 그룹의 전체 이름입니다. |
| `full_path` | 문자열 | 그룹의 전체 경로입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/groups"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "full_name": "Foobar Group",
    "full_path": "foo-bar"
  },
  {
    "id": 2,
    "name": "Shared Group",
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "full_name": "Shared Group",
    "full_path": "foo/shared"
  }
]
```

### 프로젝트에 초대할 수 있는 모든 그룹 나열 {#list-all-groups-available-to-invite-to-a-project}

프로젝트에 초대할 수 있는 모든 그룹을 나열합니다.

```plaintext
GET /projects/:id/share_locations
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`  | 문자열            | 아니요       | 그룹 ID별로 특정 그룹을 검색합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|:----------|:-----|:------------|
| `id` | 정수 | 그룹의 ID입니다. |
| `web_url` | 문자열 | 브라우저에서 그룹에 액세스하기 위한 URL입니다. |
| `name` | 문자열 | 그룹의 이름입니다. |
| `avatar_url` | 문자열 | 그룹의 아바타 이미지에 대한 URL입니다. |
| `full_name` | 문자열 | 그룹의 전체 이름입니다. |
| `full_path` | 문자열 | 그룹의 전체 경로입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/share_locations"
```

응답 예시:

```json
[
  {
    "id": 22,
    "web_url": "http://127.0.0.1:3000/groups/gitlab-org",
    "name": "Gitlab Org",
    "avatar_url": null,
    "full_name": "Gitlab Org",
    "full_path": "gitlab-org"
  },
  {
    "id": 25,
    "web_url": "http://127.0.0.1:3000/groups/gnuwget",
    "name": "Gnuwget",
    "avatar_url": null,
    "full_name": "Gnuwget",
    "full_path": "gnuwget"
  }
]
```

### 프로젝트의 모든 초대된 그룹 나열 {#list-all-invited-groups-in-a-project}

프로젝트의 모든 초대된 그룹을 나열합니다. 인증 없이 액세스할 때는 공개 초대된 그룹만 반환합니다. 이 엔드포인트는 분당 60 요청 수가 제한됩니다:

- 인증된 사용자를 위한 사용자
- 인증되지 않은 사용자의 IP 주소

이 엔드포인트는 페이지 매김을 지원합니다:

- 오프셋 기반 페이지 매김을 사용하여 최대 50,000개 프로젝트에 액세스합니다.
- 키셋 기반 페이지 매김을 사용하여 50,000개 이상의 프로젝트를 나열합니다.

자세한 내용은 [페이지 매김](rest/_index.md#pagination)을 참조하세요.

```plaintext
GET /projects/:id/invited_groups
```

지원되는 속성:

| 속성                | 유형             | 필수 | 설명 |
|:-------------------------|:-----------------|:---------|:------------|
| `id`                     | 정수 또는 문자열   | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`                 | 문자열           | 아니요       | 검색 기준과 일치하는 권한 있는 그룹의 목록을 반환합니다. |
| `min_access_level`       | 정수          | 아니요       | 현재 사용자가 지정된 액세스 수준 이상을 가진 그룹으로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `relation`               | 문자열 배열 | 아니요       | 관계별로 그룹을 필터링합니다. 가능한 값: `direct` 또는 `inherited`. |
| `with_custom_attributes` | 부울          | 아니요       | `true`이면 응답에서 [사용자 지정 속성](custom_attributes.md)을 반환합니다. 관리자 액세스가 필요합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|:----------|:-----|:------------|
| `id` | 정수 | 그룹의 ID입니다. |
| `web_url` | 문자열 | 브라우저에서 그룹에 액세스하기 위한 URL입니다. |
| `name` | 문자열 | 그룹의 이름입니다. |
| `avatar_url` | 문자열 | 그룹의 아바타 이미지에 대한 URL입니다. |
| `full_name` | 문자열 | 그룹의 전체 이름입니다. |
| `full_path` | 문자열 | 그룹의 전체 경로입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/invited_groups"
```

응답 예시:

```json
[
  {
    "id": 35,
    "web_url": "https://gitlab.example.com/groups/twitter",
    "name": "Twitter",
    "avatar_url": null,
    "full_name": "Twitter",
    "full_path": "twitter"
  }
]
```

### 프로그래밍 언어 사용 정보 검색 {#retrieve-programming-language-usage-information}

지정된 프로젝트에서 사용되는 모든 프로그래밍 언어에 대한 정보를 검색합니다.

```plaintext
GET /projects/:id/languages
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 프로그래밍 언어 및 사용 비율 목록이 표시됩니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/languages"
```

응답 예시:

```json
{
  "Ruby": 66.69,
  "JavaScript": 22.98,
  "HTML": 7.91,
  "CoffeeScript": 2.42
}
```

## 프로젝트 관리 {#manage-projects}

생성, 삭제 및 보관 포함한 프로젝트를 관리합니다.

### 프로젝트 생성 {#create-a-project}

{{< history >}}

- `operations_access_level` GitLab 16.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/385798)되었습니다.
- `model_registry_access_level` GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/412734)되었습니다.
- `packages_enabled` GitLab 17.10에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/454759).
- `package_registry_access_level` GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)되었습니다.

{{< /history >}}

인증된 사용자가 소유한 프로젝트를 생성합니다.

HTTP 리포지토리가 공개적으로 액세스 불가능한 경우 `https://username:password@gitlab.company.com/group/project.git`에 인증 정보를 추가하세요. 여기서 `password`는 `api` 범위가 활성화된 공개 액세스 키입니다.

```plaintext
POST /projects
```

지원되는 일반 프로젝트 속성:

| 속성                                          | 유형    | 필수                       | 설명 |
|:---------------------------------------------------|:--------|:-------------------------------|:------------|
| `name`                                             | 문자열  | 예 (`path`이 제공되지 않는 경우) | 새 프로젝트의 이름입니다. 제공되지 않으면 경로와 같습니다. |
| `path`                                             | 문자열  | 예 (`name`이 제공되지 않는 경우) | 새 프로젝트의 리포지토리 이름입니다. 제공되지 않으면 이름을 기반으로 생성합니다(소문자 및 하이픈으로 생성). 경로는 특수 문자로 시작하거나 끝나면 안 되며 연속된 특수 문자를 포함할 수 없습니다. |
| `allow_merge_on_skipped_pipeline`                  | 부울 | 아니요                             | 건너뛴 작업으로 머지 리퀘스트를 병합할 수 있는지 설정합니다. |
| `approvals_before_merge`                           | 정수 | 아니요                             | 기본적으로 머지 리퀘스트를 승인해야 하는 승인자 수입니다. 승인 규칙을 구성하려면 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). Premium 및 Ultimate만 해당합니다. |
| `auto_cancel_pending_pipelines`                    | 문자열  | 아니요                             | 대기 중인 파이프라인을 자동 취소합니다. 이 작업은 활성화 상태와 비활성화 상태 간에 전환합니다. 부울이 아닙니다. |
| `auto_devops_deploy_strategy`                      | 문자열  | 아니요                             | 자동 배포 전략 (`continuous`, `manual` 또는 `timed_incremental`). |
| `auto_devops_enabled`                              | 부울 | 아니요                             | 이 프로젝트에 대해 Auto DevOps를 활성화합니다. |
| `autoclose_referenced_issues`                      | 부울 | 아니요                             | 기본 브랜치에서 참조된 이슈 자동 닫기 설정 여부를 설정합니다. |
| `avatar`                                           | 혼합   | 아니요                             | 프로젝트 아바타의 이미지 파일입니다. |
| `build_git_strategy`                               | 문자열  | 아니요                             | Git 전략입니다. `fetch`로 기본값이 설정됩니다. |
| `build_timeout`                                    | 정수 | 아니요                             | 작업이 실행될 수 있는 최대 시간(초 단위)입니다. |
| `ci_config_path`                                   | 문자열  | 아니요                             | CI 구성 파일의 경로입니다. |
| `container_expiration_policy_attributes`           | 해시    | 아니요                             | 이 프로젝트의 이미지 정리 정책을 업데이트합니다. 허용: `cadence`(문자열), `keep_n`(정수), `older_than`(문자열), `name_regex`(문자열), `name_regex_delete`(문자열), `name_regex_keep`(문자열), `enabled`(부울). `cadence`, `keep_n` 및 `older_than` 값에 대한 자세한 내용은 [컨테이너 레지스트리](../user/packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api) 설명서를 참조하세요. |
| `container_registry_enabled`                       | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 컨테이너 레지스트리를 활성화합니다. `container_registry_access_level` 대신 사용합니다. |
| `default_branch`                                   | 문자열  | 아니요                             | [기본 브랜치](../user/project/repository/branches/default.md) 이름입니다. 브랜치 이름(예: `main`) 또는 정규화된 참조(예: `refs/heads/main`)를 허용합니다. 정규화된 참조가 제공되면 API는 `refs/heads/` 접두사를 제거합니다. `initialize_with_readme`이 `true`이어야 합니다. |
| `description`                                      | 문자열  | 아니요                             | 짧은 프로젝트 설명입니다. |
| `emails_disabled`                                  | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ 이메일 알림을 비활성화합니다. 대신 `emails_enabled`을 사용합니다 |
| `emails_enabled`                                   | 부울 | 아니요                             | 이메일 알림을 활성화합니다. |
| `external_authorization_classification_label`      | 문자열  | 아니요                             | 프로젝트의 분류 레이블입니다. Premium 및 Ultimate만 해당합니다. |
| `group_runners_enabled`                            | 부울 | 아니요                             | 이 프로젝트에 대해 그룹 러너를 활성화합니다. |
| `group_with_project_templates_id`                  | 정수 | 아니요                             | 그룹 수준 사용자 지정 템플릿의 경우 모든 사용자 지정 프로젝트 템플릿이 소싱되는 그룹의 ID를 지정합니다. 인스턴스 수준 템플릿의 경우 비워 둡니다. `use_custom_template`이 true여야 합니다. Premium 및 Ultimate만 해당합니다. |
| `import_url`                                       | 문자열  | 아니요                             | 가져올 리포지토리의 URL입니다. URL 값이 비어있지 않으면 `initialize_with_readme`을 `true`로 설정하면 안 됩니다. 이렇게 하면 [다음 오류](https://gitlab.com/gitlab-org/gitlab/-/issues/360266)가 발생할 수 있습니다: `not a git repository`. |
| `initialize_with_readme`                           | 부울 | 아니요                             | 단 `README.md` 파일만 포함된 Git 리포지토리를 생성할지 여부입니다. 기본값은 `false`입니다. 이 부울이 true일 때 `import_url` 또는 리포지토리 콘텐츠를 지정하는 이 엔드포인트의 다른 속성을 전달하면 안 됩니다. 이렇게 하면 [다음 오류](https://gitlab.com/gitlab-org/gitlab/-/issues/360266)가 발생할 수 있습니다: `not a git repository`. |
| `issues_enabled`                                   | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 이슈를 활성화합니다. `issues_access_level` 대신 사용합니다. |
| `jobs_enabled`                                     | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 작업을 활성화합니다. `builds_access_level` 대신 사용합니다. |
| `lfs_enabled`                                      | 부울 | 아니요                             | LFS를 활성화합니다. |
| `merge_method`                                     | 문자열  | 아니요                             | 프로젝트의 [병합 방법](../user/project/merge_requests/methods/_index.md)을 설정합니다. `merge`(병합 커밋), `rebase_merge`(반선형 이력을 포함한 병합 커밋) 또는 `ff`(빠른 포워드 병합)일 수 있습니다. |
| `merge_pipelines_enabled`                          | 부울 | 아니요                             | 병합 파이프라인을 활성화하거나 비활성화합니다. |
| `merge_requests_enabled`                           | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 머지 리퀘스트를 활성화합니다. `merge_requests_access_level` 대신 사용합니다. |
| `merge_trains_enabled`                             | 부울 | 아니요                             | 머지 트레인을 활성화하거나 비활성화합니다. |
| `merge_trains_skip_train_allowed`                  | 부울 | 아니요                             | 머지 트레인 머지 리퀘스트가 파이프라인이 완료될 때까지 기다리지 않고 병합되도록 허용합니다. |
| `max_pipelines_per_merge_train`                    | 정수 | 아니요                             | 머지 트레인당 최대 병렬 파이프라인 수. |
| `mirror_trigger_builds`                            | 부울 | 아니요                             | 풀 미러링 빌드를 트리거합니다. Premium 및 Ultimate만 해당합니다. |
| `mirror`                                           | 부울 | 아니요                             | 프로젝트에서 풀 미러링을 활성화합니다. Premium 및 Ultimate만 해당합니다. |
| `namespace_id`                                     | 정수 | 아니요                             | 새 프로젝트의 네임스페이스입니다. 그룹 ID 또는 서브그룹 ID를 지정합니다. 제공되지 않으면 현재 사용자의 개인 네임스페이스로 기본 설정됩니다. |
| `only_allow_merge_if_all_discussions_are_resolved` | 부울 | 아니요                             | 머지 리퀘스트가 모든 토론이 해결되는 경우에만 병합될 수 있는지 설정합니다. |
| `only_allow_merge_if_all_status_checks_passed`     | 부울 | 아니요                             | 모든 상태 확인이 통과하지 않으면 머지 리퀘스트 병합이 차단됨을 나타냅니다. 기본값은 false입니다. GitLab 15.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369859)되었으며, 기능 플래그 `only_allow_merge_if_all_status_checks_passed`가 기본적으로 비활성화되어 있습니다. Ultimate만 해당. |
| `only_allow_merge_if_pipeline_succeeds`            | 부울 | 아니요                             | 머지 리퀘스트가 성공적인 파이프라인으로만 병합될 수 있는지 설정합니다. 이 설정은 프로젝트 설정에서 [**파이프라인이 성공해야 함**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)이라고 이름 지어졌습니다. |
| `packages_enabled`                                 | 부울 | 아니요                             | GitLab 17.10에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/454759). 패키지 리포지토리 기능을 활성화하거나 비활성화합니다. `package_registry_access_level` 대신 사용합니다. |
| `package_registry_access_level`                    | 문자열  | 아니요                             | 패키지 리포지토리 기능을 활성화하거나 비활성화합니다. |
| `printing_merge_request_link_enabled`              | 부울 | 아니요                             | 명령줄에서 푸시할 때 머지 리퀘스트를 생성/보기 위한 링크를 표시합니다. |
| `public_builds`                                    | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ `true`이면 작업을 프로젝트 멤버가 아닌 사용자가 볼 수 있습니다. `public_jobs` 대신 사용합니다. |
| `public_jobs`                                      | 부울 | 아니요                             | `true`이면 작업을 프로젝트 멤버가 아닌 사용자가 볼 수 있습니다. |
| `repository_object_format`                         | 문자열  | 아니요                             | 리포지토리 개체 형식입니다. `sha1`로 기본값이 설정됩니다. [GitLab 16.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/419887). |
| `remove_source_branch_after_merge`                 | 부울 | 아니요                             | 모든 새로운 머지 리퀘스트에 대해 기본적으로 `Delete source branch` 옵션을 활성화합니다. |
| `repository_storage`                               | 문자열  | 아니요                             | 리포지토리가 있는 스토리지 샤드입니다. _(관리자만)_ |
| `request_access_enabled`                           | 부울 | 아니요                             | 사용자가 멤버 액세스를 요청할 수 있도록 허용합니다. |
| `resolve_outdated_diff_discussions`                | 부울 | 아니요                             | 푸시를 통해 변경된 라인에 대한 머지 리퀘스트 diff 토론을 자동으로 해결합니다. |
| `shared_runners_enabled`                           | 부울 | 아니요                             | 이 프로젝트에 대해 인스턴스 러너를 활성화합니다. |
| `show_default_award_emojis`                        | 부울 | 아니요                             | 기본 이모지 반응을 표시합니다. |
| `snippets_enabled`                                 | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 코드 조각을 활성화합니다. `snippets_access_level` 대신 사용합니다. |
| `squash_option`                                    | 문자열  | 아니요                             | `never`, `always`, `default_on` 또는 `default_off` 중 하나입니다. |
| `tag_list`                                         | 배열   | 아니요                             | 프로젝트의 태그 목록입니다. 최종적으로 프로젝트에 할당되어야 하는 태그 배열을 입력합니다. GitLab 14.0에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/328226). `topics` 대신 사용합니다. |
| `template_name`                                    | 문자열  | 아니요                             | `use_custom_template`과 함께 사용하지 않는 경우 [기본 제공 프로젝트 템플릿](../user/project/_index.md#create-a-project-from-a-built-in-template)의 이름입니다. `use_custom_template`과 함께 사용되는 경우 사용자 지정 프로젝트 템플릿의 이름입니다. |
| `template_project_id`                              | 정수 | 아니요                             | `use_custom_template`과 함께 사용되는 경우 사용자 지정 프로젝트 템플릿의 프로젝트 ID입니다. 프로젝트 ID를 사용하는 것이 `template_name`을 사용하는 것보다 좋습니다. `template_name`은 모호할 수 있기 때문입니다. Premium 및 Ultimate만 해당합니다. |
| `topics`                                           | 배열   | 아니요                             | 프로젝트의 주제 목록입니다. 최종적으로 프로젝트에 할당되어야 하는 주제 배열을 입력합니다. |
| `use_custom_template`                              | 부울 | 아니요                             | 사용자 지정 [인스턴스](../administration/custom_project_templates.md) 또는 [그룹](../user/group/custom_project_templates.md)(`group_with_project_templates_id` 포함) 프로젝트 템플릿을 사용합니다. Premium 및 Ultimate만 해당합니다. |
| `visibility`                                       | 문자열  | 아니요                             | [프로젝트 표시 수준](#project-visibility-level)을 참조하세요. |
| `warn_about_potentially_unwanted_characters`       | 부울 | 아니요                             | 이 프로젝트에서 잠재적으로 원하지 않는 문자 사용에 대한 경고를 활성화합니다. |
| `wiki_enabled`                                     | 부울 | 아니요                             | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 wiki를 활성화합니다. `wiki_access_level` 대신 사용합니다. |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
     --header "Content-Type: application/json" --data '{
        "name": "new_project", "description": "New Project", "path": "new_project",
        "namespace_id": "42", "initialize_with_readme": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/"
```

개별 프로젝트 기능의 표시 수준을 설정하려면 [프로젝트 기능 표시 수준](#project-feature-visibility-level)을 참조하세요.

### 사용자를 위한 프로젝트 생성 {#create-a-project-for-a-user}

{{< history >}}

- `operations_access_level` GitLab 16.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/385798)되었습니다.
- `model_registry_access_level` GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/412734)되었습니다.
- `packages_enabled` GitLab 17.10에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/454759).
- `package_registry_access_level` GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)되었습니다.
- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

사용자를 위한 프로젝트를 생성합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

HTTP 리포지토리에 공개적으로 액세스할 수 없으면 URL에 인증 정보를 추가하세요. 예를 들어, `https://username:password@gitlab.company.com/group/project.git` 여기서 `password`는 `api` 범위가 활성화된 공개 액세스 키입니다.

```plaintext
POST /projects/user/:user_id
```

지원되는 일반 프로젝트 속성:

| 속성                                          | 유형    | 필수 | 설명 |
|:---------------------------------------------------|:--------|:---------|:------------|
| `name`                                             | 문자열  | 예      | 새 프로젝트의 이름입니다. |
| `user_id`                                          | 정수 | 예      | 프로젝트 소유자의 사용자 ID입니다. |
| `allow_merge_on_skipped_pipeline`                  | 부울 | 아니요       | 건너뛴 작업으로 머지 리퀘스트를 병합할 수 있는지 설정합니다. |
| `approvals_before_merge`                           | 정수 | 아니요       | 기본적으로 머지 리퀘스트를 승인해야 하는 승인자 수입니다. [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). 승인 규칙을 구성하려면 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. Premium 및 Ultimate만 해당합니다. |
| `auto_cancel_pending_pipelines`                    | 문자열  | 아니요       | 대기 중인 파이프라인을 자동 취소합니다. 이 작업은 활성화 상태와 비활성화 상태 간에 전환합니다. 부울이 아닙니다. |
| `auto_devops_deploy_strategy`                      | 문자열  | 아니요       | 자동 배포 전략 (`continuous`, `manual` 또는 `timed_incremental`). |
| `auto_devops_enabled`                              | 부울 | 아니요       | 이 프로젝트에 대해 Auto DevOps를 활성화합니다. |
| `autoclose_referenced_issues`                      | 부울 | 아니요       | 기본 브랜치에서 참조된 이슈 자동 닫기 설정 여부를 설정합니다. |
| `avatar`                                           | 혼합   | 아니요       | 프로젝트 아바타의 이미지 파일입니다. |
| `build_git_strategy`                               | 문자열  | 아니요       | Git 전략입니다. `fetch`로 기본값이 설정됩니다. |
| `build_timeout`                                    | 정수 | 아니요       | 작업이 실행될 수 있는 최대 시간(초 단위)입니다. |
| `ci_config_path`                                   | 문자열  | 아니요       | CI 구성 파일의 경로입니다. |
| `container_registry_enabled`                       | 부울 | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 컨테이너 레지스트리를 활성화합니다. `container_registry_access_level` 대신 사용합니다. |
| `default_branch`                                   | 문자열  | 아니요       | [기본 브랜치](../user/project/repository/branches/default.md) 이름입니다. `initialize_with_readme`이 `true`이어야 합니다. |
| `description`                                      | 문자열  | 아니요       | 짧은 프로젝트 설명입니다. |
| `emails_disabled`                                  | 부울 | 아니요       | _(더 이상 사용되지 않음)_ 이메일 알림을 비활성화합니다. 대신 `emails_enabled`을 사용합니다 |
| `emails_enabled`                                   | 부울 | 아니요       | 이메일 알림을 활성화합니다. |
| `enforce_auth_checks_on_uploads`                   | 부울 | 아니요       | 업로드에 [인증 확인](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files)을 강제합니다. |
| `external_authorization_classification_label`      | 문자열  | 아니요       | 프로젝트의 분류 레이블입니다. Premium 및 Ultimate만 해당합니다. |
| `group_runners_enabled`                            | 부울 | 아니요       | 이 프로젝트에 대해 그룹 러너를 활성화합니다. |
| `group_with_project_templates_id`                  | 정수 | 아니요       | 그룹 수준 사용자 지정 템플릿의 경우 모든 사용자 지정 프로젝트 템플릿이 소싱되는 그룹의 ID를 지정합니다. 인스턴스 수준 템플릿의 경우 비워 둡니다. `use_custom_template`이 true여야 합니다. Premium 및 Ultimate만 해당합니다. |
| `import_url`                                       | 문자열  | 아니요       | 가져올 리포지토리의 URL입니다. |
| `initialize_with_readme`                           | 부울 | 아니요       | 기본값은 `false`입니다. |
| `issue_branch_template`                            | 문자열  | 아니요       | [이슈에서 생성된 브랜치](../user/project/merge_requests/creating_merge_requests.md#from-an-issue)의 이름을 제안하는 데 사용되는 템플릿입니다. _([GitLab 15.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/21243).)_ |
| `issues_enabled`                                   | 부울 | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 이슈를 활성화합니다. `issues_access_level` 대신 사용합니다. |
| `jobs_enabled`                                     | 부울 | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 작업을 활성화합니다. `builds_access_level` 대신 사용합니다. |
| `lfs_enabled`                                      | 부울 | 아니요       | LFS를 활성화합니다. |
| `merge_commit_template`                            | 문자열  | 아니요       | [템플릿](../user/project/merge_requests/commit_templates.md)은 머지 리퀘스트에서 머지 커밋 메시지를 만드는 데 사용됩니다. |
| `merge_method`                                     | 문자열  | 아니요       | 프로젝트의 [병합 방법](../user/project/merge_requests/methods/_index.md)을 설정합니다. `merge`(병합 커밋), `rebase_merge`(반선형 이력을 포함한 병합 커밋) 또는 `ff`(빠른 포워드 병합)일 수 있습니다. |
| `merge_requests_enabled`                           | 부울 | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 머지 리퀘스트를 활성화합니다. `merge_requests_access_level` 대신 사용합니다. |
| `mr_default_title_template`                        | 문자열  | 아니요       | [템플릿](../user/project/merge_requests/title_templates.md)은 기본 머지 리퀘스트 제목을 설정하는 데 사용됩니다. |
| `mirror_trigger_builds`                            | 부울 | 아니요       | 풀 미러링 빌드를 트리거합니다. Premium 및 Ultimate만 해당합니다. |
| `mirror`                                           | 부울 | 아니요       | 프로젝트에서 풀 미러링을 활성화합니다. Premium 및 Ultimate만 해당합니다. |
| `namespace_id`                                     | 정수 | 아니요       | 새 프로젝트의 네임스페이스입니다(기본값은 현재 사용자의 네임스페이스). |
| `only_allow_merge_if_all_discussions_are_resolved` | 부울 | 아니요       | 머지 리퀘스트가 모든 토론이 해결되는 경우에만 병합될 수 있는지 설정합니다. |
| `only_allow_merge_if_all_status_checks_passed`     | 부울 | 아니요       | 모든 상태 확인이 통과하지 않으면 머지 리퀘스트 병합이 차단됨을 나타냅니다. 기본값은 false입니다. GitLab 15.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369859)되었으며, 기능 플래그 `only_allow_merge_if_all_status_checks_passed`가 기본적으로 비활성화되어 있습니다. Ultimate만 해당. |
| `only_allow_merge_if_pipeline_succeeds`            | 부울 | 아니요       | 성공한 작업으로만 머지 리퀘스트를 병합할 수 있는지 여부를 설정하세요. |
| `packages_enabled`                                 | 부울 | 아니요       | GitLab 17.10에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/454759). 패키지 리포지토리 기능을 활성화하거나 비활성화합니다. `package_registry_access_level` 대신 사용합니다. |
| `package_registry_access_level`                    | 문자열  | 아니요       | 패키지 리포지토리 기능을 활성화하거나 비활성화합니다. |
| `path`                                             | 문자열  | 아니요       | 새 프로젝트의 사용자 정의 리포지토리 이름입니다. 기본적으로 이름을 기반으로 생성됩니다. |
| `printing_merge_request_link_enabled`              | 부울 | 아니요       | 명령줄에서 푸시할 때 머지 리퀘스트를 생성/보기 위한 링크를 표시합니다. |
| `public_builds`                                    | 부울 | 아니요       | _(더 이상 사용되지 않음)_ `true`이면 작업을 프로젝트 멤버가 아닌 사용자가 볼 수 있습니다. `public_jobs` 대신 사용합니다. |
| `public_jobs`                                      | 부울 | 아니요       | `true`이면 작업을 프로젝트 멤버가 아닌 사용자가 볼 수 있습니다. |
| `repository_object_format`                         | 문자열  | 아니요       | 리포지토리 개체 형식입니다. `sha1`로 기본값이 설정됩니다. [GitLab 16.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/419887). |
| `remove_source_branch_after_merge`                 | 부울 | 아니요       | 모든 새로운 머지 리퀘스트에 대해 기본적으로 `Delete source branch` 옵션을 활성화합니다. |
| `repository_storage`                               | 문자열  | 아니요       | 리포지토리가 있는 저장소 샤드입니다. _(관리자만)_ |
| `request_access_enabled`                           | 부울 | 아니요       | 사용자가 멤버 액세스를 요청할 수 있도록 허용합니다. |
| `resolve_outdated_diff_discussions`                | 부울 | 아니요       | 푸시를 통해 변경된 라인에 대한 머지 리퀘스트 diff 토론을 자동으로 해결합니다. |
| `shared_runners_enabled`                           | 부울 | 아니요       | 이 프로젝트에 대해 인스턴스 러너를 활성화합니다. |
| `show_default_award_emojis`                        | 부울 | 아니요       | 기본 이모지 반응을 표시합니다. |
| `snippets_enabled`                                 | 부울 | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 코드 조각을 활성화합니다. `snippets_access_level` 대신 사용합니다. |
| `squash_commit_template`                           | 문자열  | 아니요       | [템플릿](../user/project/merge_requests/commit_templates.md)은 머지 리퀘스트에서 스쿼시 커밋 메시지를 만드는 데 사용됩니다. |
| `squash_option`                                    | 문자열  | 아니요       | `never`, `always`, `default_on` 또는 `default_off` 중 하나입니다. |
| `suggestion_commit_message`                        | 문자열  | 아니요       | 머지 리퀘스트 [제안](../user/project/merge_requests/reviews/suggestions.md)을 적용하는 데 사용되는 커밋 메시지입니다. |
| `tag_list`                                         | 배열   | 아니요       | _([GitLab 14.0에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/328226))_ 프로젝트의 태그 목록입니다. 최종적으로 프로젝트에 할당해야 하는 태그 배열을 입력하세요. `topics` 대신 사용합니다. |
| `template_name`                                    | 문자열  | 아니요       | `use_custom_template`과 함께 사용하지 않는 경우 [기본 제공 프로젝트 템플릿](../user/project/_index.md#create-a-project-from-a-built-in-template)의 이름입니다. `use_custom_template`과 함께 사용되는 경우 사용자 지정 프로젝트 템플릿의 이름입니다. |
| `topics`                                           | 배열   | 아니요       | 프로젝트의 주제 목록입니다. |
| `use_custom_template`                              | 부울 | 아니요       | 사용자 지정 [인스턴스](../administration/custom_project_templates.md) 또는 [그룹](../user/group/custom_project_templates.md)(`group_with_project_templates_id` 포함) 프로젝트 템플릿을 사용합니다. Premium 및 Ultimate만 해당합니다. |
| `visibility`                                       | 문자열  | 아니요       | [프로젝트 표시 수준](#project-visibility-level)을 참조하세요. |
| `warn_about_potentially_unwanted_characters`       | 부울 | 아니요       | 이 프로젝트에서 잠재적으로 원하지 않는 문자 사용에 대한 경고를 활성화합니다. |
| `wiki_enabled`                                     | 부울 | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 wiki를 활성화합니다. `wiki_access_level` 대신 사용합니다. |

개별 프로젝트 기능의 표시 수준을 설정하려면 [프로젝트 기능 표시 수준](#project-feature-visibility-level)을 참조하세요.

### 프로젝트 업데이트 {#update-a-project}

{{< history >}}

- `operations_access_level` GitLab 16.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/385798)되었습니다.
- `model_registry_access_level` GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/412734)되었습니다.
- `packages_enabled` GitLab 17.10에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/454759).
- `package_registry_access_level` GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)되었습니다.
- `protect_merge_request_pipelines` 및 `ci_display_pipeline_variables` [GitLab 18.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/584488).
- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

기존 프로젝트를 업데이트합니다.

HTTP 리포지토리가 공개적으로 액세스 불가능한 경우 `https://username:password@gitlab.company.com/group/project.git`에 인증 정보를 추가하세요. 여기서 `password`는 `api` 범위가 활성화된 공개 액세스 키입니다.

```plaintext
PUT /projects/:id
```

지원되는 일반 프로젝트 속성:

| 속성                                          | 유형              | 필수 | 설명 |
|:---------------------------------------------------|:------------------|:---------|:------------|
| `id`                                               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `allow_merge_on_skipped_pipeline`                  | 부울           | 아니요       | 건너뛴 작업으로 머지 리퀘스트를 병합할 수 있는지 설정합니다. |
| `allow_pipeline_trigger_approve_deployment`        | 부울           | 아니요       | 파이프라인 트리거가 배포를 승인할 수 있도록 허용할지 여부를 설정하세요. Premium 및 Ultimate만 해당합니다. |
| `only_allow_merge_if_all_status_checks_passed`     | 부울           | 아니요       | 모든 상태 확인이 통과하지 않으면 머지 리퀘스트 병합이 차단됨을 나타냅니다. 기본값은 false입니다.<br/><br/>GitLab 15.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369859)되었으며, 기능 플래그 `only_allow_merge_if_all_status_checks_passed`가 기본적으로 비활성화되어 있습니다. 기능 플래그는 GitLab 15.9에서 기본적으로 활성화되었습니다. Ultimate만 해당. |
| `approvals_before_merge`                           | 정수           | 아니요       | 기본적으로 머지 리퀘스트를 승인해야 하는 승인자 수입니다. [GitLab 16.0에서 지원 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353097). 승인 규칙을 구성하려면 [머지 리퀘스트 승인 API](merge_request_approvals.md)를 참조하세요. Premium 및 Ultimate만 해당합니다. |
| `auto_cancel_pending_pipelines`                    | 문자열            | 아니요       | 대기 중인 파이프라인을 자동 취소합니다. 이 작업은 활성화 상태와 비활성화 상태 간에 전환합니다. 부울이 아닙니다. |
| `auto_devops_deploy_strategy`                      | 문자열            | 아니요       | 자동 배포 전략 (`continuous`, `manual` 또는 `timed_incremental`). |
| `auto_devops_enabled`                              | 부울           | 아니요       | 이 프로젝트에 대해 Auto DevOps를 활성화합니다. |
| `auto_duo_code_review_enabled`                     | 부울           | 아니요       | 머지 리퀘스트에서 GitLab Duo로 자동 검토를 활성화합니다. [머지 리퀘스트에서 GitLab Duo](../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)를 참조하세요. Ultimate만 해당. |
| `autoclose_referenced_issues`                      | 부울           | 아니요       | 기본 브랜치에서 참조된 이슈 자동 닫기 설정 여부를 설정합니다. |
| `avatar`                                           | 혼합             | 아니요       | 프로젝트 아바타의 이미지 파일입니다. |
| `build_git_strategy`                               | 문자열            | 아니요       | Git 전략입니다. `fetch`로 기본값이 설정됩니다. |
| `build_timeout`                                    | 정수           | 아니요       | 작업이 실행될 수 있는 최대 시간(초 단위)입니다. |
| `ci_config_path`                                   | 문자열            | 아니요       | CI 구성 파일의 경로입니다. |
| `ci_default_git_depth`                             | 정수           | 아니요       | [얕은 복제](../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)의 기본 리비전 수입니다. |
| `ci_delete_pipelines_in_seconds`                   | 정수           | 아니요       | 구성된 시간보다 오래된 파이프라인은 삭제됩니다. |
| `ci_display_pipeline_variables`                    | 부울           | 아니요       | 파이프라인을 수동으로 실행한 후 파이프라인 세부 정보 페이지에 모든 수동으로 정의된 변수를 표시합니다. |
| `ci_forward_deployment_enabled`                    | 부울           | 아니요       | [배포 작업 방지](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs)를 활성화하거나 비활성화합니다. |
| `ci_forward_deployment_rollback_allowed`           | 부울           | 아니요       | [롤백 배포에 대한 작업 재시도 허용](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs)을 활성화하거나 비활성화합니다. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | 부울           | 아니요       | [포크의 머지 리퀘스트에 대해 부모 프로젝트에서 파이프라인 실행](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project)을 활성화하거나 비활성화합니다. _([GitLab 15.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/325189).)_ |
| `ci_id_token_sub_claim_components`                 | 배열             | 아니요       | [ID 토큰](../ci/secrets/id_token_authentication.md)의 `sub` 클레임에 포함된 필드입니다. `project_path`로 시작하는 배열을 허용합니다. 배열에는 `ref_type`, `ref`, `ref_protected`, `environment_protected` 및 `deployment_tier`도 포함될 수 있습니다. `["project_path", "ref_type", "ref"]`로 기본값이 설정됩니다. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/477260). `environment_protected` 및 `deployment_tier` 지원은 GitLab 18.7에서 도입되었습니다. |
| `ci_separated_caches`                              | 부울           | 아니요       | 캐시를 [분리](../ci/caching/_index.md#cache-key-names)해야 하는지 여부를 브랜치 보호 상태별로 설정합니다. |
| `ci_restrict_pipeline_cancellation_role`           | 문자열            | 아니요       | 파이프라인 또는 작업을 취소하기 위해 [필요한 역할](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs)을 설정합니다. `developer`, `maintainer` 또는 `no_one` 중 하나입니다. GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/429921)되었습니다. Premium 및 Ultimate만 해당합니다. |
| `ci_pipeline_variables_minimum_override_role`      | 문자열            | 아니요       | 변수를 재정의할 수 있는 역할을 지정할 수 있습니다. `owner`, `maintainer`, `developer` 또는 `no_one_allowed` 중 하나입니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)됨. GitLab 17.1~17.7에서 `restrict_user_defined_variables`을(를) 활성화해야 합니다. |
| `ci_push_repository_for_job_token_allowed`         | 부울           | 아니요       | 작업 토큰을 사용하여 프로젝트 리포지토리에 푸시하는 기능을 활성화하거나 비활성화합니다. GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)되었습니다. |
| `container_expiration_policy_attributes`           | 해시              | 아니요       | 이 프로젝트의 이미지 정리 정책을 업데이트합니다. 허용: `cadence`(문자열), `keep_n`(정수), `older_than`(문자열), `name_regex`(문자열), `name_regex_delete`(문자열), `name_regex_keep`(문자열), `enabled`(부울). |
| `container_registry_enabled`                       | 부울           | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 컨테이너 레지스트리를 활성화합니다. `container_registry_access_level` 대신 사용합니다. |
| `default_branch`                                   | 문자열            | 아니요       | [기본 브랜치](../user/project/repository/branches/default.md) 이름입니다. |
| `description`                                      | 문자열            | 아니요       | 짧은 프로젝트 설명입니다. |
| `duo_remote_flows_enabled`                         | 부울           | 아니요       | [플로우](../user/duo_agent_platform/flows/_index.md)가 프로젝트에서 실행될 수 있는지 여부를 결정합니다. |
| `duo_sast_fp_detection_enabled` | 부울 | 아니요 | SAST 위양성 탐지를 활성화하거나 비활성화합니다. [SAST 위양성 탐지 켜기](../user/application_security/vulnerabilities/false_positive_detection.md#turn-on-for-a-project)를 참조하세요. |
| `duo_sast_vr_workflow_enabled` | 부울 | 아니요 | SAST 취약성 해결 워크플로우를 활성화하거나 비활성화합니다. [SAST 취약성 해결 워크플로우 켜기](../user/application_security/vulnerabilities/agentic_vulnerability_resolution.md#turn-on-for-a-project)를 참조하세요. |
| `emails_disabled`                                  | 부울           | 아니요       | _(더 이상 사용되지 않음)_ 이메일 알림을 비활성화합니다. 대신 `emails_enabled`을 사용합니다 |
| `emails_enabled`                                   | 부울           | 아니요       | 이메일 알림을 활성화합니다. |
| `enforce_auth_checks_on_uploads`                   | 부울           | 아니요       | 업로드에 [인증 확인](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files)을 강제합니다. |
| `external_authorization_classification_label`      | 문자열            | 아니요       | 프로젝트의 분류 레이블입니다. Premium 및 Ultimate만 해당합니다. |
| `group_runners_enabled`                            | 부울           | 아니요       | 이 프로젝트에 대해 그룹 러너를 활성화합니다. |
| `import_url`                                       | 문자열            | 아니요       | 리포지토리를 가져온 URL입니다. |
| `issues_enabled`                                   | 부울           | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 이슈를 활성화합니다. `issues_access_level` 대신 사용합니다. |
| `issues_template` | 문자열 | 아니요 | 새 이슈의 기본 설명입니다. GitLab Flavored Markdown로 형식이 지정되었습니다. Premium 및 Ultimate만 해당합니다. |
| `merge_requests_template` | 문자열 | 아니요 | 새 머지 리퀘스트의 기본 설명입니다. GitLab Flavored Markdown로 형식이 지정되었습니다. Premium 및 Ultimate만 해당합니다. |
| `jobs_enabled`                                     | 부울           | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 작업을 활성화합니다. `builds_access_level` 대신 사용합니다. |
| `keep_latest_artifact`                             | 부울           | 아니요       | 이 프로젝트에 대해 최신 아티팩트를 유지하는 기능을 비활성화하거나 활성화합니다. |
| `lfs_enabled`                                      | 부울           | 아니요       | LFS를 활성화합니다. |
| `max_artifacts_size`                               | 정수           | 아니요       | 개별 작업 아티팩트에 대한 최대 파일 크기(MB)입니다. |
| `merge_commit_template`                            | 문자열            | 아니요       | [템플릿](../user/project/merge_requests/commit_templates.md)은 머지 리퀘스트에서 머지 커밋 메시지를 만드는 데 사용됩니다. |
| `merge_method`                                     | 문자열            | 아니요       | 프로젝트의 [병합 방법](../user/project/merge_requests/methods/_index.md)을 설정합니다. `merge`(병합 커밋), `rebase_merge`(반선형 이력을 포함한 병합 커밋) 또는 `ff`(빠른 포워드 병합)일 수 있습니다. |
| `merge_pipelines_enabled`                          | 부울           | 아니요       | 병합 파이프라인을 활성화하거나 비활성화합니다. |
| `merge_requests_enabled`                           | 부울           | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 머지 리퀘스트를 활성화합니다. `merge_requests_access_level` 대신 사용합니다. |
| `mr_default_title_template`                        | 문자열            | 아니요       | [템플릿](../user/project/merge_requests/title_templates.md)은 기본 머지 리퀘스트 제목을 설정하는 데 사용됩니다. |
| `merge_trains_enabled`                             | 부울           | 아니요       | 머지 트레인을 활성화하거나 비활성화합니다. |
| `merge_trains_skip_train_allowed`                  | 부울           | 아니요       | 머지 트레인 머지 리퀘스트가 파이프라인이 완료될 때까지 기다리지 않고 병합되도록 허용합니다. |
| `max_pipelines_per_merge_train`                    | 정수           | 아니요       | 머지 트레인당 최대 병렬 파이프라인 수. |
| `mirror_overwrites_diverged_branches`              | 부울           | 아니요       | 끌어오기 미러는 분산된 브랜치를 덮어씁니다. Premium 및 Ultimate만 해당합니다. |
| `mirror_trigger_builds`                            | 부울           | 아니요       | 풀 미러링 빌드를 트리거합니다. Premium 및 Ultimate만 해당합니다. |
| `mirror_user_id`                                   | 정수           | 아니요       | 끌어오기 미러 이벤트와 관련된 모든 활동을 담당하는 사용자입니다. _(관리자만)_ Premium 및 Ultimate만 해당합니다. |
| `mirror`                                           | 부울           | 아니요       | 프로젝트에서 풀 미러링을 활성화합니다. Premium 및 Ultimate만 해당합니다. |
| `mr_default_target_self`                           | 부울           | 아니요       | 포크된 프로젝트의 경우 이 프로젝트로 머지 리퀘스트를 대상으로 지정합니다. `false`인 경우 대상은 업스트림 프로젝트입니다. |
| `name`                                             | 문자열            | 아니요       | 프로젝트의 이름입니다. |
| `only_allow_merge_if_all_discussions_are_resolved` | 부울           | 아니요       | 머지 리퀘스트가 모든 토론이 해결되는 경우에만 병합될 수 있는지 설정합니다. |
| `only_allow_merge_if_pipeline_succeeds`            | 부울           | 아니요       | 성공한 작업으로만 머지 리퀘스트를 병합할 수 있는지 여부를 설정하세요. |
| `only_mirror_protected_branches`                   | 부울           | 아니요       | 보호된 브랜치만 미러합니다. Premium 및 Ultimate만 해당합니다. |
| `packages_enabled`                                 | 부울           | 아니요       | GitLab 17.10에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/454759). 패키지 리포지토리 기능을 활성화하거나 비활성화합니다. `package_registry_access_level` 대신 사용합니다. |
| `package_registry_access_level`                    | 문자열  | 아니요                 | 패키지 리포지토리 기능을 활성화하거나 비활성화합니다. |
| `path`                                             | 문자열            | 아니요       | 프로젝트의 사용자 정의 리포지토리 이름입니다. 기본적으로 이름을 기반으로 생성됩니다. |
| `prevent_merge_without_jira_issue`                 | 부울           | 아니요       | 머지 리퀘스트에 Jira의 관련 이슈가 필요한지 여부를 설정합니다. Ultimate만 해당. |
| `printing_merge_request_link_enabled`              | 부울           | 아니요       | 명령줄에서 푸시할 때 머지 리퀘스트를 생성/보기 위한 링크를 표시합니다. |
| `protect_merge_request_pipelines`                  | 부울           | 아니요       | [보호된 변수 및 러너에 대한 액세스 제어](../ci/pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners)를 활성화하거나 비활성화합니다. |
| `public_builds`                                    | 부울           | 아니요       | _(더 이상 사용되지 않음)_ `true`이면 작업을 프로젝트 멤버가 아닌 사용자가 볼 수 있습니다. `public_jobs` 대신 사용합니다. |
| `public_jobs`                                      | 부울           | 아니요       | `true`이면 작업을 프로젝트 멤버가 아닌 사용자가 볼 수 있습니다. |
| `remove_source_branch_after_merge`                 | 부울           | 아니요       | 모든 새로운 머지 리퀘스트에 대해 기본적으로 `Delete source branch` 옵션을 활성화합니다. |
| `repository_storage`                               | 문자열            | 아니요       | 리포지토리가 있는 저장소 샤드입니다. _(관리자만)_ |
| `request_access_enabled`                           | 부울           | 아니요       | 사용자가 멤버 액세스를 요청할 수 있도록 허용합니다. |
| `resolve_outdated_diff_discussions`                | 부울           | 아니요       | 푸시를 통해 변경된 라인에 대한 머지 리퀘스트 diff 토론을 자동으로 해결합니다. |
| `restrict_user_defined_variables`                  | 부울           | 아니요       | _(GitLab 17.7에서 `ci_pipeline_variables_minimum_override_role`을(를) 사용하지 않는 것으로 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510))_ 파이프라인을 트리거할 때 Maintainer 역할을 가진 사용자만 사용자 정의 변수를 전달할 수 있습니다. 예를 들어 UI, API 또는 트리거 토큰으로 파이프라인이 트리거될 때입니다. |
| `service_desk_enabled`                             | 부울           | 아니요       | Service Desk 기능을 활성화하거나 비활성화합니다. |
| `shared_runners_enabled`                           | 부울           | 아니요       | 이 프로젝트에 대해 인스턴스 러너를 활성화합니다. |
| `show_default_award_emojis`                        | 부울           | 아니요       | 기본 이모지 반응을 표시합니다. |
| `snippets_enabled`                                 | 부울           | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 코드 조각을 활성화합니다. `snippets_access_level` 대신 사용합니다. |
| `issue_branch_template`                            | 문자열            | 아니요       | [이슈에서 생성된 브랜치](../user/project/merge_requests/creating_merge_requests.md#from-an-issue)의 이름을 제안하는 데 사용되는 템플릿입니다. _([GitLab 15.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/21243).)_ |
| `spp_repository_pipeline_access`                   | 부울           | 아니요       | 사용자 및 토큰이 이 프로젝트에서 보안 정책 구성을 가져올 수 있는 읽기 전용 액세스를 허용합니다. 이 프로젝트를 보안 정책 소스로 사용하는 프로젝트에서 보안 정책을 시행하는 데 필요합니다. Ultimate만 해당. |
| `squash_commit_template`                           | 문자열            | 아니요       | [템플릿](../user/project/merge_requests/commit_templates.md)은 머지 리퀘스트에서 스쿼시 커밋 메시지를 만드는 데 사용됩니다. |
| `squash_option`                                    | 문자열            | 아니요       | `never`, `always`, `default_on` 또는 `default_off` 중 하나입니다. |
| `suggestion_commit_message`                        | 문자열            | 아니요       | 머지 리퀘스트 제안을 적용하는 데 사용되는 커밋 메시지입니다. |
| `tag_list`                                         | 배열             | 아니요       | _([GitLab 14.0에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/328226))_ 프로젝트의 태그 목록입니다. 최종적으로 프로젝트에 할당해야 하는 태그 배열을 입력하세요. `topics` 대신 사용합니다. |
| `topics`                                           | 배열             | 아니요       | 프로젝트의 주제 목록입니다. 이것은 프로젝트에 이미 추가된 기존 주제를 모두 바꿉니다. |
| `visibility`                                       | 문자열            | 아니요       | [프로젝트 표시 수준](#project-visibility-level)을 참조하세요. |
| `warn_about_potentially_unwanted_characters`       | 부울           | 아니요       | 이 프로젝트에서 잠재적으로 원하지 않는 문자 사용에 대한 경고를 활성화합니다. |
| `wiki_enabled`                                     | 부울           | 아니요       | _(더 이상 사용되지 않음)_ 이 프로젝트에 대해 wiki를 활성화합니다. `wiki_access_level` 대신 사용합니다. |
| `web_based_commit_signing_enabled`                 | 부울           | 아니요       | GitLab UI에서 만든 커밋에 대해 웹 기반 커밋 서명을 활성화합니다. GitLab.com에서만 사용 가능합니다. |

예를 들어, [GitLab.com 프로젝트에서 인스턴스 러너](../ci/runners/_index.md)에 대한 설정을 전환하려면:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your-token>" \
     --url "https://gitlab.com/api/v4/projects/<your-project-ID>" \
     --data "shared_runners_enabled=true" # to turn off: "shared_runners_enabled=false"
```

개별 프로젝트 기능의 표시 수준을 설정하려면 [프로젝트 기능 표시 수준](#project-feature-visibility-level)을 참조하세요.

### 멤버 가져오기 {#import-members}

다른 프로젝트에서 멤버를 가져옵니다.

가져오는 멤버의 대상 프로젝트에 대한 역할이 다음과 같은 경우:

- Maintainer이면 소스 프로젝트에 대한 Owner 역할을 가진 멤버를 Maintainer 역할로 가져옵니다.
- Owner이면 소스 프로젝트에 대한 Owner 역할을 가진 멤버를 Owner 역할로 가져옵니다.

```plaintext
POST /projects/:id/import_project_members/:project_id
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|:-------------|:------------------|:---------|:------------|
| `id`         | 정수 또는 문자열 | 예      | 멤버를 수신할 대상 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `project_id` | 정수 또는 문자열 | 예      | 멤버를 가져올 소스 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/import_project_members/32"
```

반환:

- `200 OK` 성공 시.
- 대상 또는 소스 프로젝트가 존재하지 않거나 요청자가 액세스할 수 없는 경우 `404 Project Not Found`.
- 프로젝트 멤버 가져오기가 성공적으로 완료되지 않은 경우 `422 Unprocessable Entity`.

응답 예시:

- 모든 이메일을 성공적으로 보낸 경우 (`200` HTTP 상태 코드):

  ```json
  {  "status":  "success"  }
  ```

- 1명 이상의 멤버를 가져오는 중에 오류가 발생한 경우 (`200` HTTP 상태 코드):

  ```json
  {
    "status": "error",
    "message": {
                 "john_smith": "Some individual error message",
                 "jane_smith": "Some individual error message"
               },
    "total_members_count": 3
  }
  ```

- 시스템 오류가 있는 경우 (`404` 및 `422` HTTP 상태 코드):

```json
{  "message":  "Import failed"  }
```

### 프로젝트 보관 {#archive-a-project}

{{< history >}}

- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

지정된 프로젝트를 보관합니다.

전제 조건:

- 관리자이거나 프로젝트에서 소유자 역할을 할당받아야 합니다.

이 엔드포인트는 멱등입니다. 이미 보관된 프로젝트를 보관해도 프로젝트가 변경되지 않습니다.

```plaintext
POST /projects/:id/archive
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/archive"
```

응답 예시:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
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
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
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
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
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
  "mr_default_title_template": null,
  "secret_push_protection_enabled": false,
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
```

### 프로젝트 보관 해제 {#unarchive-a-project}

{{< history >}}

- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

지정된 프로젝트의 보관을 해제합니다.

전제 조건:

- 관리자이거나 프로젝트에서 소유자 역할을 할당받아야 합니다.

이 엔드포인트는 멱등입니다. 보관되지 않은 프로젝트의 보관을 해제해도 프로젝트가 변경되지 않습니다.

```plaintext
POST /projects/:id/unarchive
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/unarchive"
```

응답 예시:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
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
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
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
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
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
  "mr_default_title_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "secret_push_protection_enabled": false,
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
```

### 프로젝트 삭제 {#delete-a-project}

{{< history >}}

- [GitLab 16.0에 일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)됩니다. Premium 및 Ultimate만 해당합니다.
- GitLab 18.0에서 GitLab Premium에서 GitLab Free로 [이동](https://gitlab.com/groups/gitlab-org/-/epics/17208)되었습니다.

{{< /history >}}

전제 조건:

- 관리자이거나 프로젝트에 대한 Owner 역할을 가져야 합니다.

삭제할 프로젝트를 표시합니다. 프로젝트는 보존 기간이 끝나면 삭제됩니다:

- GitLab.com에서 프로젝트는 30일 동안 보존됩니다.
- GitLab Self-Managed에서는 보존 기간이 [인스턴스 설정](../administration/settings/visibility_and_access_controls.md#deletion-protection)에 의해 제어됩니다.

이 엔드포인트는 삭제하기로 표시된 프로젝트를 즉시 삭제할 수도 있습니다.

> [!warning]
> GitLab.com에서 프로젝트가 삭제되면 데이터가 30일 동안 보존되며 영구 삭제는 불가능합니다. GitLab.com에서 프로젝트를 즉시 삭제해야 할 경우 [지원 티켓](https://about.gitlab.com/support/)을 열 수 있습니다.

```plaintext
DELETE /projects/:id
```

지원되는 속성:

| 속성            | 유형              | 필수 | 설명 |
|:---------------------|:------------------|:---------|:------------|
| `id`                 | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `full_path`          | 문자열            | 아니요       | `permanently_remove`과(와) 함께 사용할 프로젝트의 전체 경로입니다. [GitLab 15.11에서 Premium 및 Ultimate만 해당하는 경우에 도입되었고 18.0에서 GitLab Free로 이동됨](https://gitlab.com/gitlab-org/gitlab/-/issues/396500). 프로젝트 경로를 찾으려면 [단일 프로젝트 가져오기](projects.md#retrieve-a-project)에서 `path_with_namespace`를 사용하세요. |
| `permanently_remove` | 부울/문자열    | 아니요       | 삭제하기로 표시된 프로젝트가 있으면 즉시 삭제합니다. [GitLab 15.11에서 Premium 및 Ultimate만 해당하는 경우에 도입되었고 18.0에서 GitLab Free로 이동됨](https://gitlab.com/gitlab-org/gitlab/-/issues/396500). GitLab.com 및 Dedicated에서 비활성화됩니다. |

### 삭제하기로 표시된 프로젝트 복원 {#restore-a-project-marked-for-deletion}

삭제하기로 표시된 지정된 프로젝트를 복원합니다.

```plaintext
POST /projects/:id/restore
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

### 프로젝트를 새로운 네임스페이스로 전송 {#transfer-a-project-to-a-new-namespace}

{{< history >}}

- `mr_default_title_template` GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) [기능 플래그](../administration/feature_flags/_index.md) `mr_default_title_template`로 이름 지정됨. 기본적으로 비활성화됨.
- 기능 플래그 `mr_default_title_template` GitLab 19.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

프로젝트를 새로운 네임스페이스로 전송합니다.

프로젝트를 전송하기 위한 사전 조건에 대한 정보는 [프로젝트를 다른 네임스페이스로 전송](../user/project/working_with_projects.md#transfer-a-project)을 참조하세요.

```plaintext
PUT /projects/:id/transfer
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
|:------------|:------------------|:---------|:------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `namespace` | 정수 또는 문자열 | 예      | 프로젝트를 전송할 네임스페이스의 ID 또는 경로입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/transfer?namespace=14"
```

응답 예시:

```json
  {
  "id": 7,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "name": "hello-world",
  "name_with_namespace": "cute-cats / hello-world",
  "path": "hello-world",
  "path_with_namespace": "cute-cats/hello-world",
  "created_at": "2020-10-15T16:25:22.415Z",
  "updated_at": "2020-10-15T16:25:22.415Z",
  "default_branch": "main",
  "tag_list": [], //deprecated, use `topics` instead
  "topics": [],
  "ssh_url_to_repo": "git@gitlab.example.com:cute-cats/hello-world.git",
  "http_url_to_repo": "https://gitlab.example.com/cute-cats/hello-world.git",
  "web_url": "https://gitlab.example.com/cute-cats/hello-world",
  "readme_url": "https://gitlab.example.com/cute-cats/hello-world/-/blob/main/README.md",
  "avatar_url": null,
  "forks_count": 0,
  "star_count": 0,
  "last_activity_at": "2020-10-15T16:25:22.415Z",
  "namespace": {
    "id": 18,
    "name": "cute-cats",
    "path": "cute-cats",
    "kind": "group",
    "full_path": "cute-cats",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/cute-cats"
  },
  "container_registry_image_prefix": "registry.example.com/cute-cats/hello-world",
  "_links": {
    "self": "https://gitlab.example.com/api/v4/projects/7",
    "issues": "https://gitlab.example.com/api/v4/projects/7/issues",
    "merge_requests": "https://gitlab.example.com/api/v4/projects/7/merge_requests",
    "repo_branches": "https://gitlab.example.com/api/v4/projects/7/repository/branches",
    "labels": "https://gitlab.example.com/api/v4/projects/7/labels",
    "events": "https://gitlab.example.com/api/v4/projects/7/events",
    "members": "https://gitlab.example.com/api/v4/projects/7/members"
  },
  "packages_enabled": true, // deprecated, use package_registry_access_level instead
  "package_registry_access_level": "enabled",
  "empty_repo": false,
  "archived": false,
  "visibility": "private",
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": true, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "enabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null,
    "name_regex_keep": null,
    "next_run_at": "2020-10-22T16:25:22.746Z"
  },
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wiki_enabled": true,
  "jobs_enabled": true,
  "snippets_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "can_create_merge_request_in": true,
  "issues_access_level": "enabled",
  "repository_access_level": "enabled",
  "merge_requests_access_level": "enabled",
  "forking_access_level": "enabled",
  "analytics_access_level": "enabled",
  "wiki_access_level": "enabled",
  "builds_access_level": "enabled",
  "snippets_access_level": "enabled",
  "pages_access_level": "enabled",
  "security_and_compliance_access_level": "enabled",
  "emails_disabled": null,
  "emails_enabled": null,
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "lfs_enabled": true,
  "creator_id": 2,
  "import_status": "none",
  "open_issues_count": 0,
  "ci_default_git_depth": 50,
  "public_jobs": true,
  "build_timeout": 3600,
  "auto_cancel_pending_pipelines": "enabled",
  "ci_config_path": null,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": null,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "request_access_enabled": true,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": true,
  "printing_merge_request_link_enabled": true,
  "merge_method": "merge",
  "squash_option": "default_on",
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "mr_default_title_template": null,
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "autoclose_referenced_issues": true,
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "compliance_frameworks": [],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false
}
```

#### 프로젝트 전송에 사용 가능한 그룹 목록 {#list-groups-available-for-project-transfer}

사용자가 프로젝트를 전송할 수 있는 그룹 목록을 검색합니다.

```plaintext
GET /projects/:id/transfer_locations
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`  | 문자열            | 아니요       | 검색할 그룹 이름입니다. |

요청 예시:

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/transfer_locations"
```

응답 예시:

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

### 프로젝트 아바타 업로드 {#upload-a-project-avatar}

지정된 프로젝트에 아바타를 업로드합니다.

```plaintext
PUT /projects/:id
```

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.
- 파일은 200 KB 이하여야 합니다. 이상적인 이미지 크기는 192 x 192 픽셀입니다.
- 이미지는 다음 파일 유형 중 하나여야 합니다:
  - `.bmp`
  - `.gif`
  - `.ico`
  - `.jpeg`
  - `.png`
  - `.tiff`

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `avatar`  | 문자열            | 예      | 업로드할 파일입니다. |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

파일 시스템에서 아바타를 업로드하려면 `--form` 인수를 사용하세요. 이로 인해 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `avatar=` 매개변수는 파일 시스템의 이미지 파일을 가리키고 `@`가 앞에 있어야 합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5" \
  --form "avatar=@dk.png"
```

응답 예시:

```json
{
  "avatar_url": "https://gitlab.example.com/uploads/-/system/project/avatar/2/dk.png"
}
```

### 프로젝트 아바타 다운로드 {#download-a-project-avatar}

{{< history >}}

- [GitLab 16.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144039).

{{< /history >}}

프로젝트 아바타를 다운로드합니다. 프로젝트가 공개적으로 액세스할 수 있는 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

```plaintext
GET /projects/:id/avatar
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/avatar"
```

### 프로젝트 아바타 제거 {#remove-a-project-avatar}

프로젝트 아바타를 제거하려면 `avatar` 속성에 빈 값을 사용합니다.

요청 예시:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "avatar=" "https://gitlab.example.com/api/v4/projects/5"
```

## 프로젝트 공유 {#share-projects}

프로젝트를 그룹과 공유합니다.

자세한 내용은 [프로젝트에 그룹 초대](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)를 참조하세요.

### 프로젝트를 그룹과 공유 {#share-a-project-with-a-group}

지정된 프로젝트를 그룹과 공유합니다.

```plaintext
POST /projects/:id/share
```

지원되는 속성:

| 속성      | 유형              | 필수 | 설명 |
|:---------------|:------------------|:---------|:------------|
| `group_access` | 정수           | 예      | 그룹에 부여할 액세스 수준입니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `group_id`     | 정수           | 예      | 공유할 그룹의 ID입니다. |
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `expires_at`   | 문자열            | 아니요       | ISO 8601 형식의 공유 만료 날짜입니다. 예를 들어, `2016-09-26`입니다. |

### 그룹에서 공유 프로젝트 링크 삭제 {#delete-a-shared-project-link-in-a-group}

지정된 그룹에서 프로젝트의 공유를 해제합니다. `204`을(를) 반환하고 성공 시 콘텐츠 없음을 반환합니다.

```plaintext
DELETE /projects/:id/share/:group_id
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|:-----------|:------------------|:---------|:------------|
| `group_id` | 정수           | 예      | 그룹의 ID입니다. |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## 프로젝트의 하우스키핑 작업 시작 {#start-the-housekeeping-task-for-a-project}

프로젝트의 [하우스키핑 작업](../administration/housekeeping.md)을 시작합니다.

```plaintext
POST /projects/:id/housekeeping
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `task`    | 문자열            | 아니요       | `prune`을(를) 트리거하여 도달할 수 없는 객체의 수동 프루닝 또는 `eager`을(를) 트리거하여 즉시 하우스키핑을 수행합니다. |

## 실시간 보안 스캔 {#real-time-security-scan}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- [GitLab 17.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/479210). 이 기능은 [실험](../policy/development_stages_support.md)입니다.

{{< /history >}}

실시간으로 단일 파일에 대한 SAST 스캔 결과를 반환합니다.

```plaintext
POST /projects/:id/security_scans/sast/scan
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "file_path":"src/main.c",
  "content":"#include<string.h>\nint main(int argc, char **argv) {\n  char buff[128];\n  strcpy(buff, argv[1]);\n  return 0;\n}\n"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/:id/security_scans/sast/scan"
```

응답 예시:

```json
{
  "vulnerabilities": [
    {
      "name": "Insecure string processing function (strcpy)",
      "description": "The `strcpy` family of functions do not provide the ability to limit or check buffer\nsizes before copying to a destination buffer. This can lead to buffer overflows. Consider\nusing more secure alternatives such as `strncpy` and provide the correct limit to the\ndestination buffer and ensure the string is null terminated.\n\nFor more information please see: https://linux.die.net/man/3/strncpy\n\nIf developing for C Runtime Library (CRT), more secure versions of these functions should be\nused, see:\nhttps://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/strncpy-s-strncpy-s-l-wcsncpy-s-wcsncpy-s-l-mbsncpy-s-mbsncpy-s-l?view=msvc-170\n",
      "severity": "High",
      "location": {
        "file": "src/main.c",
        "start_line": 5,
        "end_line": 5,
        "start_column": 3,
        "end_column": 23
      }
    }
  ]
}
```

## Git 리포지토리의 스냅샷 다운로드 {#download-snapshot-of-a-git-repository}

이 엔드포인트는 관리 사용자만 액세스할 수 있습니다.

프로젝트(또는 요청한 경우 위키) Git 리포지토리의 스냅샷을 다운로드합니다. 이 스냅샷은 항상 압축되지 않은 [tar](https://en.wikipedia.org/wiki/Tar_(computing)) 형식입니다.

리포지토리가 `git clone`이 작동하지 않을 정도로 손상된 경우 스냅샷을 통해 일부 데이터를 복구할 수 있습니다.

```plaintext
GET /projects/:id/snapshot
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `wiki`    | 부울           | 아니요       | 프로젝트 리포지토리가 아닌 위키를 다운로드할지 여부입니다. |

## 리포지토리 스토리지 경로 검색 {#retrieve-the-path-to-repository-storage}

지정된 프로젝트의 리포지토리 스토리지 경로를 검색합니다. Gitaly Cluster(Praefect)를 사용하는 경우 [Praefect에서 생성한 복제 경로](../administration/gitaly/praefect/_index.md#praefect-generated-replica-paths)를 참조하세요.

관리자만 사용 가능합니다.

```plaintext
GET /projects/:id/storage
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

```json
[
  {
    "project_id": 1,
    "disk_path": "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
    "created_at": "2012-10-12T17:04:47Z",
    "repository_storage": "default"
  }
]
```

## 비밀 푸시 보호 상태 {#secret-push-protection-status}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

{{< history >}}

- [GitLab 17.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160960).
- GitLab 17.11에서 [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186602)되었습니다 `setPreReceiveSecretDetection`

{{< /history >}}

보안 관리자, Developer, Maintainer 또는 Owner 역할을 가지고 있으면 다음 요청도 `secret_push_protection_enabled` 값을 반환할 수 있습니다. 이러한 요청 중 일부는 역할에 대한 더 엄격한 요구 사항이 있습니다. 명확히 하기 위해 이전에 언급한 엔드포인트를 참조하세요. 이 정보를 사용하여 프로젝트에 대해 비밀 푸시 보호가 활성화되어 있는지 확인합니다. `secret_push_protection_enabled` 값을 수정하려면 [프로젝트 보안 설정 API](project_security_settings.md)를 사용하세요.

- `GET /projects`
- `GET /projects/:id`
- `GET /users/:user_id/projects`
- `GET /users/:user_id/contributed_projects`
- `PUT /projects/:project_id/transfer?namespace=:namespace_id`
- `PUT /projects/:id`
- `POST /projects`
- `POST /projects/user/:user_id`
- `POST /projects/:id/archive`
- `POST /projects/:id/unarchive`

응답 예시:

```json
{
  "id": 1,
  "project_id": 3,
  "secret_push_protection_enabled": true,
  ...
}
```

## 문제 해결 {#troubleshooting}

### 응답에서 예상치 못한 `restrict_user_defined_variables` 값 {#unexpected-restrict_user_defined_variables-value-in-response}

`restrict_user_defined_variables` 및 `ci_pipeline_variables_minimum_override_role`에 대해 충돌하는 값을 설정하면 `pipeline_variables_minimum_override_role` 설정이 더 높은 우선순위를 가지기 때문에 응답 값이 예상과 다를 수 있습니다.

예를 들어:

- `restrict_user_defined_variables`을(를) `true`로 설정하고 `ci_pipeline_variables_minimum_override_role`을(를) `developer`로 설정하면 응답이 `restrict_user_defined_variables: false`를 반환합니다. `ci_pipeline_variables_minimum_override_role`을(를) `developer`로 설정하면 우선순위를 가지며 변수가 제한되지 않습니다.
- `restrict_user_defined_variables`을(를) `false`로 설정하고 `ci_pipeline_variables_minimum_override_role`을(를) `maintainer`로 설정하면 `ci_pipeline_variables_minimum_override_role`을(를) `maintainer`로 설정하면 우선순위를 가지며 변수가 제한되기 때문에 응답이 `restrict_user_defined_variables: true`를 반환합니다.
