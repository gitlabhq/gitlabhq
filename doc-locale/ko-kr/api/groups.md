---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Groups API를 사용하여 그룹, 하위 그룹 및 프로젝트 액세스를 관리합니다."
title: Groups API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab 그룹을 보고 관리합니다. 자세한 내용은 [그룹](../user/group/_index.md)을 참조하세요.

엔드포인트 응답은 그룹에서 인증된 사용자의 [권한](../user/permissions.md)에 따라 달라질 수 있습니다.

## 그룹 검색 {#retrieve-a-group}

그룹의 세부 정보를 검색합니다. 그룹이 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다. 요청 사용자가 관리자인 경우 추가 정보가 반환됩니다. 인증을 통해 사용자가 관리자이거나 Owner 역할을 가진 경우 그룹의 `runners_token` 및 `enabled_git_access_protocol`를 반환합니다.

```plaintext
GET /groups/:id
```

매개변수:

| 속성                | 유형           | 필수 | 설명 |
|--------------------------|----------------|----------|-------------|
| `id`                     | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `with_custom_attributes` | 부울        | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |
| `with_projects`          | 부울        | 아니요       | 지정된 그룹에 속하는 프로젝트의 세부 정보 포함 (기본값: `true`). (더 이상 사용되지 않음, [API v5에서 제거 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/213797). 그룹의 모든 프로젝트의 세부 정보를 가져오려면 [그룹의 프로젝트 나열 엔드포인트](#list-projects)를 사용하세요.) |

> [!note]
> 응답의 `projects` 및 `shared_projects` 속성은 더 이상 사용되지 않으며 [API v5에서 제거 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/213797)입니다. 그룹 내의 모든 프로젝트의 세부 정보를 얻으려면 [그룹의 프로젝트 나열](#list-projects) 또는 [그룹의 공유된 프로젝트 나열](#list-shared-projects) 엔드포인트 중 하나를 사용하세요.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4"
```

이 엔드포인트는 최대 100개의 프로젝트 및 공유된 프로젝트를 반환합니다. 그룹 내의 모든 프로젝트의 세부 정보를 얻으려면 [그룹의 프로젝트 나열 엔드포인트](#list-projects)를 대신 사용하세요.

응답 예시:

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "runners_token": "ba324ca7b1c77fc20bb9",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "shared_with_groups": [
    {
      "group_id": 28,
      "group_name": "H5bp",
      "group_full_path": "h5bp",
      "group_access_level": 20,
      "expires_at": null
    }
  ],
  "prevent_sharing_groups_outside_hierarchy": false,
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 7,
      "description": "Voluptas veniam qui et beatae voluptas doloremque explicabo facilis.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "public",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/typeahead-js.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/typeahead-js.git",
      "web_url": "https://gitlab.example.com/twitter/typeahead-js",
      "name": "Typeahead.Js",
      "name_with_namespace": "Twitter / Typeahead.Js",
      "path": "typeahead-js",
      "path_with_namespace": "twitter/typeahead-js",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:25.578Z",
      "last_activity_at": "2016-06-17T07:47:25.881Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    },
    {
      "id": 6,
      "description": "Aspernatur omnis repudiandae qui voluptatibus eaque.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/flight.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/flight.git",
      "web_url": "https://gitlab.example.com/twitter/flight",
      "name": "Flight",
      "name_with_namespace": "Twitter / Flight",
      "path": "flight",
      "path_with_namespace": "twitter/flight",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:24.661Z",
      "last_activity_at": "2016-06-17T07:47:24.838Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 8,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "shared_projects": [ // Deprecated and will be removed in API v5
    {
      "id": 8,
      "description": "Velit eveniet provident fugiat saepe eligendi autem.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "private",
      "ssh_url_to_repo": "git@gitlab.example.com:h5bp/html5-boilerplate.git",
      "http_url_to_repo": "https://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "https://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "H5bp / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:27.089Z",
      "last_activity_at": "2016-06-17T07:47:27.310Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "H5bp",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 4,
      "public_jobs": true,
      "shared_with_groups": [
        {
          "group_id": 4,
          "group_name": "Twitter",
          "group_full_path": "twitter",
          "group_access_level": 30,
          "expires_at": null
        },
        {
          "group_id": 3,
          "group_name": "Gitlab Org",
          "group_full_path": "gitlab-org",
          "group_access_level": 10,
          "expires_at": "2018-08-14"
        }
      ]
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

`prevent_sharing_groups_outside_hierarchy` 속성은 최상위 그룹에만 표시됩니다.

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자도 다음 속성을 볼 수 있습니다:

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `marked_for_deletion_on`
- `membership_lock`
- `wiki_access_level`
- `duo_features_enabled`
- `lock_duo_features_enabled`
- `duo_availability`
- `experiment_features_enabled`

추가 응답 속성:

```json
{
  "id": 4,
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "marked_for_deletion_on": "2020-04-03",
  "membership_lock": false,
  "wiki_access_level": "disabled",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "duo_availability": "default_on",
  "experiment_features_enabled": false,
  ...
}
```

`with_projects=false` 매개변수를 추가하면 프로젝트가 반환되지 않습니다.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4?with_projects=false"
```

응답 예시:

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "file_template_project_id": 1,
  "parent_id": null
}
```

## 그룹 나열 {#list-groups}

### 모든 그룹 나열 {#list-all-groups}

인증된 사용자를 위한 표시된 그룹을 나열합니다. 인증 없이 액세스하는 경우 공개 그룹만 반환됩니다.

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

인증 없이 액세스하면 이 엔드포인트는 [키셋 페이지 매김](rest/_index.md#keyset-based-pagination)도 지원합니다:

- 연속된 결과 페이지를 요청할 때는 키셋 페이지 매김을 사용해야 합니다.
- 특정 오프셋 제한을 초과하면 ([오프셋 기반 페이지 매김에 대한 REST API 최대 오프셋](../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination)으로 지정됨) 오프셋 페이지 매김을 사용할 수 없습니다.

매개변수:

| 속성                | 유형              | 필수 | 설명 |
|--------------------------|-------------------|----------|-------------|
| `skip_groups`            | 정수 배열 | 아니요       | 전달된 그룹 ID를 건너뜁니다. |
| `all_available`          | 부울           | 아니요       | `true`일 때 액세스 가능한 모든 그룹을 반환합니다. `false`일 때 사용자가 멤버인 그룹만 반환합니다. 사용자의 경우 `false`, 관리자의 경우 `true`로 기본 설정됩니다. 인증되지 않은 요청은 항상 모든 공개 그룹을 반환합니다. `owned` 및 `min_access_level` 속성이 우선합니다. |
| `search`                 | 문자열            | 아니요       | 검색 기준과 일치하는 권한 있는 그룹의 목록을 반환합니다. |
| `order_by`               | 문자열            | 아니요       | `name`, `path`, `id` 또는 `similarity`로 그룹을 정렬합니다. 기본값은 `name`입니다. |
| `sort`                   | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 그룹을 정렬합니다. 기본값은 `asc`입니다. |
| `statistics`             | 부울           | 아니요       | 그룹 통계 포함 (관리자만 해당).<br> 최상위 그룹의 경우 응답은 UI에 표시된 전체 `root_storage_statistics` 데이터를 반환합니다. GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/469254)되었습니다. |
| `visibility`             | 문자열            | 아니요       | `public`, `internal` 또는 `private` 표시 유형을 가진 그룹으로 제한합니다. |
| `with_custom_attributes` | 부울           | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |
| `owned`                  | 부울           | 아니요       | 현재 사용자가 명시적으로 소유한 그룹으로 제한합니다. |
| `min_access_level`       | 정수           | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 가진 그룹으로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `top_level_only`         | 부울           | 아니요       | 최상위 그룹으로 제한하고 모든 하위 그룹을 제외합니다. |
| `repository_storage`     | 문자열            | 아니요       | 그룹에서 사용하는 리포지토리 저장소로 필터링 (관리자만 해당). [GitLab 16.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/419643)됨. Premium 및 Ultimate만 해당합니다. |
| `marked_for_deletion_on` | 날짜              | 아니요       | 그룹이 삭제로 표시된 날짜로 필터링합니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/429315)됨. Premium 및 Ultimate만 해당합니다. |
| `active`                 | 부울           | 아니요       | 보관되지 않고 삭제로 표시되지 않은 그룹으로 제한합니다. |
| `archived`               | 부울           | 아니요       | 보관된 그룹으로 제한합니다. [GitLab 18.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/519587)됨. |

```plaintext
GET /groups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "ip_restriction_ranges": null
  }
]
```

`statistics=true` 매개변수를 추가하고 인증된 사용자가 관리자인 경우 추가 그룹 통계가 반환됩니다. 최상위 그룹의 경우 `root_storage_statistics`도 추가됩니다.

```plaintext
GET /groups?statistics=true
```

`statistics=true` 매개변수를 사용하고 인증된 사용자가 관리자인 경우 응답은 컨테이너 레지스트리 저장소 크기에 대한 정보를 포함합니다:

- `container_registry_size`:  그룹 및 해당 하위 그룹의 모든 컨테이너 리포지토리에서 사용하는 총 저장소 크기(바이트). 그룹의 프로젝트 및 하위 그룹 내 모든 리포지토리 크기의 합으로 계산됩니다. 컨테이너 레지스트리 메타데이터 데이터베이스가 활성화된 경우에만 사용 가능합니다.
- `container_registry_size_is_estimated`:  크기가 모든 리포지토리의 실제 데이터를 기반으로 한 정확한 계산인지 (`false`) 또는 성능 제약으로 인해 추정된 것인지 (`true`) 나타냅니다.

GitLab Self-Managed 인스턴스의 경우 [컨테이너 레지스트리 메타데이터 데이터베이스](../administration/packages/container_registry_metadata_database.md)를 활성화하여 컨테이너 레지스트리 크기 속성을 포함해야 합니다.

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "statistics": {
      "storage_size": 363,
      "repository_size": 33,
      "wiki_size": 100,
      "lfs_objects_size": 123,
      "job_artifacts_size": 57,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 50,
      "uploads_size": 0
    },
    "root_storage_statistics": {
      "build_artifacts_size": 0,
      "container_registry_size": 0,
      "container_registry_size_is_estimated": false,
      "dependency_proxy_size": 0,
      "lfs_objects_size": 0,
      "packages_size": 0,
      "pipeline_artifacts_size": 0,
      "repository_size": 0,
      "snippets_size": 0,
      "storage_size": 0,
      "uploads_size": 0,
      "wiki_size": 0
  },
    "wiki_access_level": "private",
    "duo_features_enabled": true,
    "lock_duo_features_enabled": false,
    "duo_availability": "default_on",
    "experiment_features_enabled": false,
  }
]
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자도 `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` 및 `experiment_features_enabled` 속성을 볼 수 있습니다.

아래 참조하여 이름 또는 경로별로 그룹을 검색할 수 있습니다.

[사용자 정의 속성](custom_attributes.md)으로 필터링할 수 있습니다:

```plaintext
GET /groups?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

#### 그룹 페이지 매김 {#group-pagination}

기본적으로 API 결과가 페이지로 나뉘므로 한 번에 20개의 그룹만 표시됩니다.

더 많은 항목을 얻으려면 (최대 100개) API 호출에 다음을 인수로 전달하세요:

```plaintext
/groups?per_page=100
```

페이지를 전환하려면 다음을 추가하세요:

```plaintext
/groups?per_page=100&page=2
```

### 그룹 검색 {#search-for-a-group}

이름 또는 경로에서 문자열과 일치하는 그룹을 검색합니다.

```plaintext
GET /groups?search=foobar
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group"
  }
]
```

## 그룹 세부 정보 나열 {#list-group-details}

### 프로젝트 나열 {#list-projects}

그룹의 프로젝트를 나열합니다. 인증 없이 액세스하는 경우 공개 프로젝트만 반환됩니다.

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

```plaintext
GET /groups/:id/projects
```

매개변수:

| 속성                     | 유형           | 필수 | 설명 |
|-------------------------------|----------------|----------|-------------|
| `id`                          | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `active`                      | 부울        | 아니요       | 프로젝트 상태로 제한합니다. `true`일 때 활성 프로젝트를 반환합니다. `false`일 때 보관되거나 삭제로 표시된 프로젝트를 반환합니다. [GitLab 18.8에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218053)됨. |
| `archived`                    | 부울        | 아니요       | 보관 상태로 제한합니다. |
| `visibility`                  | 문자열         | 아니요       | `public`, `internal` 또는 `private` 표시 유형으로 제한합니다. |
| `order_by`                    | 문자열         | 아니요       | `id`, `name`, `path`, `created_at`, `updated_at`, `similarity` <sup>1</sup>, `star_count` 또는 `last_activity_at` 필드로 프로젝트를 정렬하여 반환합니다. 기본값은 `created_at`입니다. |
| `sort`                        | 문자열         | 아니요       | `asc` 또는 `desc` 순서로 프로젝트를 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `search`                      | 문자열         | 아니요       | 검색 기준과 일치하는 권한 있는 프로젝트의 목록을 반환합니다. |
| `simple`                      | 부울        | 아니요       | 각 프로젝트의 제한된 필드만 반환합니다. 인증 없이는 작동하지 않으며 단순 필드만 반환됩니다. |
| `owned`                       | 부울        | 아니요       | 현재 사용자가 소유한 프로젝트로 제한합니다. |
| `starred`                     | 부울        | 아니요       | 현재 사용자가 별표로 표시한 프로젝트로 제한합니다. |
| `topic`                       | 문자열         | 아니요       | 주제와 일치하는 프로젝트를 반환합니다. |
| `with_issues_enabled`         | 부울        | 아니요       | 이슈 기능이 활성화된 프로젝트로 제한합니다. 기본값은 `false`입니다. |
| `with_merge_requests_enabled` | 부울        | 아니요       | 머지 리퀘스트 기능이 활성화된 프로젝트로 제한합니다. 기본값은 `false`입니다. |
| `with_shared`                 | 부울        | 아니요       | 이 그룹에 공유된 프로젝트를 포함합니다. 기본값은 `true`입니다. |
| `include_subgroups`           | 부울        | 아니요       | 이 그룹의 하위 그룹에 있는 프로젝트를 포함합니다. 기본값은 `false`입니다. |
| `min_access_level`            | 정수        | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 가진 프로젝트로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `with_custom_attributes`      | 부울        | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |
| `with_security_reports`       | 부울        | 아니요       | 빌드에 보안 보고서 아티팩트가 있는 프로젝트만 반환합니다. 즉, "보안 보고서가 활성화된 프로젝트"를 의미합니다. 기본값은 `false`입니다. Ultimate만 해당. |

**각주**:

1. `search` URL 매개변수에서 계산한 유사성 점수로 결과를 정렬합니다. `order_by=similarity`을 사용하면 `sort` 매개변수가 무시됩니다. `search` 매개변수를 제공하지 않으면 API는 `name`로 정렬된 프로젝트를 반환합니다.

응답 예시:

```json
[
  {
    "id": 9,
    "description": "foo",
    "default_branch": "main",
    "tag_list": [], //deprecated, use `topics` instead
    "topics": [],
    "archived": false,
    "visibility": "internal",
    "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
    "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
    "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
    "name": "Html5 Boilerplate",
    "name_with_namespace": "Experimental / Html5 Boilerplate",
    "path": "html5-boilerplate",
    "path_with_namespace": "h5bp/html5-boilerplate",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "created_at": "2016-04-05T21:40:50.169Z",
    "last_activity_at": "2016-04-06T16:52:08.432Z",
    "shared_runners_enabled": true,
    "creator_id": 1,
    "namespace": {
      "id": 5,
      "name": "Experimental",
      "path": "h5bp",
      "kind": "group"
    },
    "avatar_url": null,
    "star_count": 1,
    "forks_count": 0,
    "open_issues_count": 3,
    "public_jobs": true,
    "shared_with_groups": [],
    "request_access_enabled": false
  }
]
```

> [!note]
> 그룹의 프로젝트와 그룹에 공유된 프로젝트를 구분하기 위해 `namespace` 속성을 사용할 수 있습니다. 프로젝트가 그룹에 공유된 경우 해당 `namespace`는 요청이 이루어지는 그룹과 다릅니다.

### 공유된 프로젝트 나열 {#list-shared-projects}

그룹에 공유된 프로젝트를 나열합니다. 인증 없이 액세스하는 경우 공개 공유 프로젝트만 반환됩니다.

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

```plaintext
GET /groups/:id/projects/shared
```

매개변수:

| 속성                     | 유형           | 필수 | 설명 |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `archived`                    | 부울        | 아니요       | 보관 상태로 제한합니다. |
| `visibility`                  | 문자열         | 아니요       | `public`, `internal` 또는 `private` 표시 유형으로 제한합니다. |
| `order_by`                    | 문자열         | 아니요       | `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` 또는 `last_activity_at` 필드로 프로젝트를 정렬하여 반환합니다. 기본값은 `created_at`입니다. |
| `sort`                        | 문자열         | 아니요       | `asc` 또는 `desc` 순서로 프로젝트를 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `search`                      | 문자열         | 아니요       | 검색 기준과 일치하는 권한 있는 프로젝트의 목록을 반환합니다. |
| `simple`                      | 부울        | 아니요       | 각 프로젝트의 제한된 필드만 반환합니다. 인증 없이는 작동하지 않으며 단순 필드만 반환됩니다. |
| `starred`                     | 부울        | 아니요       | 현재 사용자가 별표로 표시한 프로젝트로 제한합니다. |
| `with_issues_enabled`         | 부울        | 아니요       | 이슈 기능이 활성화된 프로젝트로 제한합니다. 기본값은 `false`입니다. |
| `with_merge_requests_enabled` | 부울        | 아니요       | 머지 리퀘스트 기능이 활성화된 프로젝트로 제한합니다. 기본값은 `false`입니다. |
| `min_access_level`            | 정수        | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 가진 프로젝트로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `with_custom_attributes`      | 부울        | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |

응답 예시:

```json
[
   {
      "id":8,
      "description":"Shared project for Html5 Boilerplate",
      "name":"Html5 Boilerplate",
      "name_with_namespace":"H5bp / Html5 Boilerplate",
      "path":"html5-boilerplate",
      "path_with_namespace":"h5bp/html5-boilerplate",
      "created_at":"2020-04-27T06:13:22.642Z",
      "default_branch":"main",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"ssh://git@gitlab.com/h5bp/html5-boilerplate.git",
      "http_url_to_repo":"https://gitlab.com/h5bp/html5-boilerplate.git",
      "web_url":"https://gitlab.com/h5bp/html5-boilerplate",
      "readme_url":"https://gitlab.com/h5bp/html5-boilerplate/-/blob/main/README.md",
      "avatar_url":null,
      "star_count":0,
      "forks_count":4,
      "last_activity_at":"2020-04-27T06:13:22.642Z",
      "namespace":{
         "id":28,
         "name":"H5bp",
         "path":"h5bp",
         "kind":"group",
         "full_path":"h5bp",
         "parent_id":null,
         "avatar_url":null,
         "web_url":"https://gitlab.com/groups/h5bp"
      },
      "_links":{
         "self":"https://gitlab.com/api/v4/projects/8",
         "issues":"https://gitlab.com/api/v4/projects/8/issues",
         "merge_requests":"https://gitlab.com/api/v4/projects/8/merge_requests",
         "repo_branches":"https://gitlab.com/api/v4/projects/8/repository/branches",
         "labels":"https://gitlab.com/api/v4/projects/8/labels",
         "events":"https://gitlab.com/api/v4/projects/8/events",
         "members":"https://gitlab.com/api/v4/projects/8/members"
      },
      "empty_repo":false,
      "archived":false,
      "visibility":"public",
      "resolve_outdated_diff_discussions":false,
      "container_registry_enabled":true,
      "container_expiration_policy":{
         "cadence":"7d",
         "enabled":true,
         "keep_n":null,
         "older_than":null,
         "name_regex":null,
         "name_regex_keep":null,
         "next_run_at":"2020-05-04T06:13:22.654Z"
      },
      "issues_enabled":true,
      "merge_requests_enabled":true,
      "wiki_enabled":true,
      "jobs_enabled":true,
      "snippets_enabled":true,
      "can_create_merge_request_in":true,
      "issues_access_level":"enabled",
      "repository_access_level":"enabled",
      "merge_requests_access_level":"enabled",
      "forking_access_level":"enabled",
      "wiki_access_level":"enabled",
      "builds_access_level":"enabled",
      "snippets_access_level":"enabled",
      "pages_access_level":"enabled",
      "security_and_compliance_access_level":"enabled",
      "emails_disabled":null,
      "emails_enabled": null,
      "shared_runners_enabled":true,
      "lfs_enabled":true,
      "creator_id":1,
      "import_status":"failed",
      "open_issues_count":10,
      "ci_default_git_depth":50,
      "ci_forward_deployment_enabled":true,
      "ci_forward_deployment_rollback_allowed": true,
      "ci_allow_fork_pipelines_to_run_in_parent_project":true,
      "public_jobs":true,
      "build_timeout":3600,
      "auto_cancel_pending_pipelines":"enabled",
      "ci_config_path":null,
      "shared_with_groups":[
         {
            "group_id":24,
            "group_name":"Commit451",
            "group_full_path":"Commit451",
            "group_access_level":30,
            "expires_at":null
         }
      ],
      "only_allow_merge_if_pipeline_succeeds":false,
      "request_access_enabled":true,
      "only_allow_merge_if_all_discussions_are_resolved":false,
      "remove_source_branch_after_merge":true,
      "printing_merge_request_link_enabled":true,
      "merge_method":"merge",
      "suggestion_commit_message":null,
      "auto_devops_enabled":true,
      "auto_devops_deploy_strategy":"continuous",
      "autoclose_referenced_issues":true,
      "repository_storage":"default"
   }
]
```

### 모든 SAML 사용자 나열 {#list-all-saml-users}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 18.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193748)됨.

{{< /history >}}

주어진 최상위 그룹의 모든 SAML 사용자를 나열합니다.

`page` 및 `per_page` [페이지 매김 매개변수](rest/_index.md#offset-based-pagination)를 사용하여 결과를 필터링합니다.

```plaintext
GET /groups/:id/saml_users
```

지원되는 속성:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `username`       | 문자열         | 아니요       | 주어진 사용자명을 가진 사용자를 반환합니다. |
| `search`         | 문자열         | 아니요       | 일치하는 이름, 이메일 또는 사용자명을 가진 사용자를 반환합니다. 부분 값을 사용하여 결과를 증가시킵니다. |
| `active`         | 부울        | 아니요       | 활성 사용자만 반환합니다. |
| `blocked`        | 부울        | 아니요       | 차단된 사용자만 반환합니다. |
| `created_after`  | 날짜/시간       | 아니요       | 지정된 시간 이후에 생성된 사용자를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `created_before` | 날짜/시간       | 아니요       | 지정된 시간 이전에 생성된 사용자를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/saml_users"
```

응답 예시:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```

### 프로비저닝된 사용자 나열 {#list-provisioned-users}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

그룹에서 프로비저닝된 사용자를 나열합니다. 하위 그룹은 포함하지 않습니다.

그룹에 대한 유지보수자 또는 소유자 역할이 필요합니다.

```plaintext
GET /groups/:id/provisioned_users
```

매개변수:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `username`       | 문자열         | 아니요       | 특정 사용자명을 가진 단일 사용자를 반환합니다. |
| `search`         | 문자열         | 아니요       | 이름, 이메일, 사용자명으로 사용자를 검색합니다. |
| `active`         | 부울        | 아니요       | 활성 사용자만 반환합니다. |
| `blocked`        | 부울        | 아니요       | 차단된 사용자만 반환합니다. |
| `created_after`  | 날짜/시간       | 아니요       | 지정된 시간 이후에 생성된 사용자를 반환합니다. |
| `created_before` | 날짜/시간       | 아니요       | 지정된 시간 이전에 생성된 사용자를 반환합니다. |

응답 예시:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "John Doe22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [ ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  ...
]
```

### 하위 그룹 나열 {#list-subgroups}

그룹에서 표시되는 직접 하위 그룹을 나열합니다.

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

이 목록을 요청하면 다음과 같이 됩니다:

- 인증되지 않은 사용자는 공개 그룹만 반환합니다.
- 인증된 사용자는 귀하가 멤버인 그룹만 반환하며 공개 그룹은 포함하지 않습니다.

매개변수:

| 속성                | 유형              | 필수 | 설명 |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | 정수 또는 문자열    | 예      | 직접 부모 그룹의 그룹 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `skip_groups`            | 정수 배열 | 아니요       | 전달된 그룹 ID를 건너뜁니다. |
| `all_available`          | 부울           | 아니요       | 액세스 가능한 모든 그룹을 표시합니다 (인증된 사용자의 경우 `false`, 관리자의 경우 `true`로 기본 설정). `owned` 및 `min_access_level` 속성이 우선합니다. |
| `search`                 | 문자열            | 아니요       | 검색 기준과 일치하는 권한 있는 그룹의 목록을 반환합니다. 하위 그룹 짧은 경로만 검색됩니다 (전체 경로 아님). |
| `order_by`               | 문자열            | 아니요       | `name`, `path` 또는 `id`로 그룹을 정렬합니다. 기본값은 `name`입니다. |
| `sort`                   | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 그룹을 정렬합니다. 기본값은 `asc`입니다. |
| `statistics`             | 부울           | 아니요       | 그룹 통계 포함 (관리자만 해당). |
| `with_custom_attributes` | 부울           | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |
| `owned`                  | 부울           | 아니요       | 현재 사용자가 명시적으로 소유한 그룹으로 제한합니다. |
| `min_access_level`       | 정수           | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 가진 그룹으로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `all_available`          | 부울           | 아니요       | `true`일 때 액세스 가능한 모든 그룹을 반환합니다. `false`일 때 사용자가 멤버인 그룹만 반환합니다. 사용자의 경우 `false`, 관리자의 경우 `true`로 기본 설정됩니다. 인증되지 않은 요청은 항상 모든 공개 그룹을 반환합니다. `owned` 및 `min_access_level` 속성이 우선합니다. |
| `active`                 | 부울           | 아니요       | 보관되지 않고 삭제로 표시되지 않은 그룹으로 제한합니다. |

```plaintext
GET /groups/:id/subgroups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://gitlab.example.com/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자도 `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` 및 `experiment_features_enabled` 속성을 볼 수 있습니다.

### 하위 항목 그룹 나열 {#list-descendant-groups}

그룹의 표시되는 하위 항목 그룹을 나열합니다. 인증 없이 액세스하는 경우 공개 그룹만 반환됩니다.

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

매개변수:

| 속성                | 유형              | 필수 | 설명 |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | 정수 또는 문자열    | 예      | 직접 부모 그룹의 그룹 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `skip_groups`            | 정수 배열 | 아니요       | 전달된 그룹 ID를 건너뜁니다. |
| `all_available`          | 부울           | 아니요       | `true`일 때 액세스 가능한 모든 그룹을 반환합니다. `false`일 때 사용자가 멤버인 그룹만 반환합니다. 사용자의 경우 `false`, 관리자의 경우 `true`로 기본 설정됩니다. 인증되지 않은 요청은 항상 모든 공개 그룹을 반환합니다. `owned` 및 `min_access_level` 속성이 우선합니다. |
| `search`                 | 문자열            | 아니요       | 검색 기준과 일치하는 권한 있는 그룹의 목록을 반환합니다. 하위 항목 그룹 짧은 경로만 검색됩니다 (전체 경로 아님). |
| `order_by`               | 문자열            | 아니요       | `name`, `path` 또는 `id`로 그룹을 정렬합니다. 기본값은 `name`입니다. |
| `sort`                   | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 그룹을 정렬합니다. 기본값은 `asc`입니다. |
| `statistics`             | 부울           | 아니요       | 그룹 통계 포함 (관리자만 해당). |
| `with_custom_attributes` | 부울           | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |
| `owned`                  | 부울           | 아니요       | 현재 사용자가 명시적으로 소유한 그룹으로 제한합니다. |
| `min_access_level`       | 정수           | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 가진 그룹으로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `active`                 | 부울           | 아니요       | 보관되지 않고 삭제로 표시되지 않은 그룹으로 제한합니다. |

```plaintext
GET /groups/:id/descendant_groups
```

```json
[
  {
    "id": 2,
    "name": "Bar Group",
    "path": "bar",
    "description": "A subgroup of Foo Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "request_access_enabled": false,
    "full_name": "Bar Group",
    "full_path": "foo/bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  },
  {
    "id": 3,
    "name": "Baz Group",
    "path": "baz",
    "description": "A subgroup of Bar Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/baz.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar/baz",
    "request_access_enabled": false,
    "full_name": "Baz Group",
    "full_path": "foo/bar/baz",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자도 `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` 및 `experiment_features_enabled` 속성을 볼 수 있습니다.

### 공유된 그룹 나열 {#list-shared-groups}

주어진 그룹이 초대받은 그룹을 나열합니다. 인증 없이 액세스하는 경우 공개 공유 그룹만 반환됩니다.

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

매개변수:

| 속성                             | 유형              | 필수 | 설명 |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | 정수 또는 문자열    | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `skip_groups`                         | 정수 배열 | 아니요       | 지정된 그룹 ID를 건너뜁니다. |
| `search`                              | 문자열            | 아니요       | 검색 기준과 일치하는 권한 있는 그룹의 목록을 반환합니다. |
| `order_by`                            | 문자열            | 아니요       | `name`, `path`, `id` 또는 `similarity`로 그룹을 정렬합니다. 기본값은 `name`입니다. |
| `sort`                                | 문자열            | 아니요       | `asc` 또는 `desc` 순서로 그룹을 정렬합니다. 기본값은 `asc`입니다. |
| `visibility`                          | 문자열            | 아니요       | `public`, `internal` 또는 `private` 표시 유형을 가진 그룹으로 제한합니다. |
| `min_access_level`                    | 정수           | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 가진 그룹으로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `with_custom_attributes`              | 부울           | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |

```plaintext
GET /groups/:id/groups/shared
```

응답 예시:

```json
[
  {
    "id": 101,
    "web_url": "http://gitlab.example.com/groups/some_path",
    "name": "group1",
    "path": "some_path",
    "description": "",
    "visibility": "public",
    "share_with_group_lock": "false",
    "require_two_factor_authentication": "false",
    "two_factor_grace_period": 48,
    "project_creation_level": "maintainer",
    "auto_devops_enabled": "nil",
    "subgroup_creation_level": "maintainer",
    "emails_disabled": "false",
    "emails_enabled": "true",
    "mentions_disabled": "nil",
    "lfs_enabled": "true",
    "math_rendering_limits_enabled": "true",
    "lock_math_rendering_limits_enabled": "false",
    "default_branch": "nil",
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
        "allowed_to_push": [
          {
              "access_level": 30
          }
        ],
        "allow_force_push": "true",
        "allowed_to_merge": [
          {
              "access_level": 30
          }
        ],
        "developer_can_initial_push": "false",
        "code_owner_approval_required": "false"
    },
    "avatar_url": "http://gitlab.example.com/uploads/-/system/group/avatar/101/banana_sample.gif",
    "request_access_enabled": "true",
    "full_name": "group1",
    "full_path": "some_path",
    "created_at": "2024-06-06T09:39:30.056Z",
    "parent_id": "nil",
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": "nil",
    "ldap_access": "nil",
    "wiki_access_level": "enabled"
  }
]
```

### 초대된 그룹 나열 {#list-invited-groups}

그룹의 초대된 그룹을 나열합니다. 인증 없이 액세스하는 경우 공개 초대 그룹만 반환됩니다. 이 엔드포인트는 분당 60개의 요청으로 속도 제한됩니다 (인증된 사용자의 경우 사용자당, 인증되지 않은 사용자의 경우 IP당).

기본적으로 API 결과가 [페이지로 나뉘므로](rest/_index.md#pagination) 이 요청은 한 번에 20개의 결과를 반환합니다.

매개변수:

| 속성                             | 유형              | 필수 | 설명 |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | 정수 또는 문자열    | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`                              | 문자열            | 아니요       | 검색 기준과 일치하는 권한 있는 그룹의 목록을 반환합니다. |
| `min_access_level`                    | 정수           | 아니요       | 현재 사용자가 최소한 지정된 액세스 수준을 가진 그룹으로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `relation`                            | 문자열 배열  | 아니요       | 관계 (직접 또는 상속)로 그룹을 필터링합니다. |
| `with_custom_attributes`              | 부울           | 아니요       | 응답에 [사용자 정의 속성](custom_attributes.md) 포함 (관리자만 해당). |

```plaintext
GET /groups/:id/invited_groups
```

응답 예시:

```json
[
  {
    "id": 33,
    "web_url": "http://gitlab.example.com/groups/flightjs",
    "name": "Flightjs",
    "path": "flightjs",
    "description": "Illo dolorum tempore eligendi minima ducimus provident.",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "maintainer",
    "emails_disabled": false,
    "emails_enabled": true,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "math_rendering_limits_enabled": true,
    "lock_math_rendering_limits_enabled": false,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
        {
          "access_level": 40
        }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
        {
          "access_level": 40
        }
      ],
      "developer_can_initial_push": false
    },
    "avatar_url": null,
    "request_access_enabled": true,
    "full_name": "Flightjs",
    "full_path": "flightjs",
    "created_at": "2024-07-09T10:31:08.307Z",
    "parent_id": null,
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": null,
    "ldap_access": null,
    "wiki_access_level": "enabled"
  }
]
```

### 감사 이벤트 나열 {#list-audit-events}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

그룹 감사 이벤트는 [그룹 감사 이벤트 API](audit_events.md#group-audit-events)를 통해 액세스할 수 있습니다

## 그룹 관리 {#manage-groups}

### 그룹 만들기 {#create-a-group}

> [!note]
> GitLab.com에서는 GitLab UI를 사용하여 부모 그룹이 없는 그룹을 만들어야 합니다. API를 사용하여 이를 수행할 수 없습니다.

새 프로젝트 그룹을 만듭니다. 그룹을 만들 수 있는 사용자만 사용할 수 있습니다.

```plaintext
POST /groups
```

매개변수:

| 속성                            | 유형    | 필수 | 설명 |
|--------------------------------------|---------|----------|-------------|
| `name`                               | 문자열  | 예      | 그룹의 이름. |
| `path`                               | 문자열  | 예      | 그룹의 경로. |
| `auto_devops_enabled`                | 부울 | 아니요       | 이 그룹 내의 모든 프로젝트에 대해 기본값을 Auto DevOps 파이프라인으로 설정합니다. |
| `avatar`                             | 혼합   | 아니요       | 그룹 아바타의 이미지 파일. |
| `default_branch`                     | 문자열  | 아니요       | 그룹의 프로젝트에 대한 [기본 브랜치](../user/project/repository/branches/default.md) 이름. [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442298)됨. |
| `default_branch_protection`          | 정수 | 아니요       | [GitLab 17.0에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/408314). `default_branch_protection_defaults` 대신 사용합니다. |
| `default_branch_protection_defaults` | 해시    | 아니요       | GitLab 17.0에서 도입됨. 사용 가능한 옵션은 [`default_branch_protection_defaults`에 대한 옵션](#options-for-default_branch_protection_defaults)을 참조하세요. |
| `description`                        | 문자열  | 아니요       | 그룹의 설명. |
| `enabled_git_access_protocol`        | 문자열  | 아니요       | Git 액세스에 대해 활성화된 프로토콜. 허용되는 값: `ssh`, `http`, 및 `all`(두 프로토콜 모두 허용). [GitLab 16.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/436618). |
| `emails_disabled`                    | 부울 | 아니요       | ([GitLab 16.5에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899)) 이메일 알림을 비활성화합니다. `emails_enabled` 대신 사용합니다. |
| `emails_enabled`                     | 부울 | 아니요       | 이메일 알림을 활성화합니다. |
| `lfs_enabled`                        | 부울 | 아니요       | 이 그룹의 프로젝트에 대한 LFS(Large File Storage)를 활성화/비활성화합니다. |
| `mentions_disabled`                  | 부울 | 아니요       | 그룹이 언급되는 기능을 비활성화합니다. |
| `organization_id`                    | 정수 | 아니요       | 그룹의 조직 ID. |
| `parent_id`                          | 정수 | 아니요       | 중첩된 그룹을 만들기 위한 부모 그룹 ID. |
| `project_creation_level`             | 문자열  | 아니요       | 개발자가 그룹에서 프로젝트를 만들 수 있는지 결정합니다. `administrator`(Admin Mode가 활성화된 사용자), `noone`(아무도 아님), `maintainer`(유지보수자 역할을 가진 사용자) 또는 `developer`(개발자 또는 유지보수자 역할을 가진 사용자)일 수 있습니다. |
| `request_access_enabled`             | 부울 | 아니요       | 사용자가 멤버 액세스를 요청할 수 있도록 허용합니다. |
| `require_two_factor_authentication`  | 부울 | 아니요       | 이 그룹의 모든 사용자가 2단계 인증을 설정해야 합니다. |
| `share_with_group_lock`              | 부울 | 아니요       | 이 그룹 내에서 프로젝트를 다른 그룹과 공유하는 것을 방지합니다. |
| `subgroup_creation_level`            | 문자열  | 아니요       | [하위 그룹을 만들도록](../user/group/subgroups/_index.md#create-a-subgroup) 허용됩니다. `owner`(소유자 역할을 가진 사용자) 또는 `maintainer`(유지보수자 역할을 가진 사용자)일 수 있습니다. |
| `two_factor_grace_period`            | 정수 | 아니요       | 2단계 인증이 적용되기 전의 시간(시간). |
| `visibility`                         | 문자열  | 아니요       | 그룹의 표시 유형. `private`, `internal` 또는 `public`일 수 있습니다. |
| `membership_lock`                    | 부울 | 아니요       | 사용자를 이 그룹의 프로젝트에 추가할 수 없습니다. Premium 및 Ultimate만 해당합니다. |
| `extra_shared_runners_minutes_limit` | 정수 | 아니요       | 관리자만 설정할 수 있습니다. 이 그룹에 대한 추가 계산 분. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `shared_runners_minutes_limit`       | 정수 | 아니요       | 관리자만 설정할 수 있습니다. 이 그룹의 월간 최대 계산 분. `nil`(기본값; 시스템 기본값 상속), `0`(무제한) 또는 `> 0`일 수 있습니다. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `wiki_access_level`                  | 문자열  | 아니요       | 위키 액세스 수준. `disabled`, `private` 또는 `enabled`일 수 있습니다. Premium 및 Ultimate만 해당합니다. |
| `duo_availability` | 문자열 | 아니요 | GitLab Duo 가용성 설정. 유효한 값: `default_on`, `default_off`, `never_on`. 참고: UI에서 `never_on`는 "항상 끔"으로 표시됩니다. |
| `experiment_features_enabled` | 부울 | 아니요 | 이 그룹에 대한 실험 기능을 활성화합니다. |

#### `default_branch_protection`에 대한 옵션 {#options-for-default_branch_protection}

`default_branch_protection` 속성은 Developer 또는 Maintainer 역할을 가진 사용자가 해당 [기본 브랜치](../user/project/repository/branches/default.md)로 푸시할 수 있는지 결정하며, 다음 표에서 설명합니다:

| 값 | 설명 |
|-------|-------------|
| `0`   | 보호 없음. Developer 또는 Maintainer 역할을 가진 사용자는 다음을 수행할 수 있습니다: <br>\- 새 커밋을 푸시합니다.<br>\- 변경 사항을 강제 푸시합니다.<br>\- 브랜치를 삭제합니다. |
| `1`   | 부분 보호. Developer 또는 Maintainer 역할을 가진 사용자는 다음을 수행할 수 있습니다: <br>\- 새 커밋을 푸시합니다. |
| `2`   | 전체 보호. Maintainer 역할을 가진 사용자만 다음을 수행할 수 있습니다: <br>\- 새 커밋을 푸시합니다. |
| `3`   | 푸시에 대한 보호. Maintainer 역할을 가진 사용자는 다음을 수행할 수 있습니다: <br>\- 새 커밋을 푸시합니다.<br>\- 변경 사항을 강제 푸시합니다.<br>\- 머지 리퀘스트를 승인합니다.<br>Developer 역할을 가진 사용자는 다음을 수행할 수 있습니다:<br>\- 머지 리퀘스트를 승인합니다. |
| `4`   | 초기 푸시 후 전체 보호. Developer 역할을 가진 사용자는 다음을 수행할 수 있습니다: <br>\- 빈 리포지토리에 커밋을 푸시합니다.<br> Maintainer 역할을 가진 사용자는 다음을 수행할 수 있습니다: <br>\- 새 커밋을 푸시합니다.<br>\- 머지 리퀘스트를 승인합니다. |

#### `default_branch_protection_defaults`에 대한 옵션 {#options-for-default_branch_protection_defaults}

{{< history >}}

- [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314).

{{< /history >}}

`default_branch_protection_defaults` 속성은 기본 브랜치 보호 기본값을 설명합니다. 모든 매개변수는 선택 사항입니다.

| 키                            | 유형    | 설명 |
|:-------------------------------|:--------|:------------|
| `allowed_to_push`              | 배열   | 푸시가 허용되는 액세스 수준의 배열입니다. Developer (30) 또는 Maintainer (40)를 지원합니다. |
| `allow_force_push`             | 부울 | 푸시 액세스가 있는 모든 사용자의 강제 푸시를 허용합니다. |
| `allowed_to_merge`             | 배열   | 병합이 허용되는 액세스 수준의 배열입니다. Developer (30) 또는 Maintainer (40)를 지원합니다. |
| `developer_can_initial_push`   | 부울 | 개발자가 초기 푸시를 수행할 수 있도록 허용합니다. |
| `code_owner_approval_required` | 부울 | 코드 소유자 승인이 필요합니다. |

### 서브그룹 만들기 {#create-a-subgroup}

이는 [새 그룹 만들기](#create-a-group)와 유사합니다. [그룹 나열](#list-groups) 호출에서 `parent_id`를 가져와야 합니다. 그런 다음 다음을 입력할 수 있습니다:

- `subgroup_path`
- `subgroup_name`

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"path": "<subgroup_path>", "name": "<subgroup_name>", "parent_id": <parent_group_id> }' \
  --url "https://gitlab.example.com/api/v4/groups/"
```

### 그룹 삭제 예약 {#schedule-a-group-for-deletion}

{{< history >}}

- [GitLab 16.0에 일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)됩니다. Premium 및 Ultimate만 해당합니다.
- GitLab 18.0에서 GitLab Premium에서 GitLab Free로 [이동](https://gitlab.com/groups/gitlab-org/-/epics/17208)되었습니다.

{{< /history >}}

그룹을 삭제하도록 예약합니다. 그룹은 보존 기간이 끝날 때 삭제됩니다:

- GitLab.com에서는 그룹이 30일 동안 보존됩니다.
- GitLab Self-Managed에서는 보존 기간이 [인스턴스 설정](../administration/settings/visibility_and_access_controls.md#deletion-protection)에 의해 제어됩니다.

이 엔드포인트는 이전에 삭제하도록 예약되었던 서브그룹을 즉시 삭제할 수도 있습니다.

전제 조건:

- 관리자이거나 그룹에 대한 Owner 역할을 가져야 합니다.

```plaintext
DELETE /groups/:id
```

| 속성            | 유형              | 필수 | 설명 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `full_path`          | 문자열            | 조건부       | 서브그룹의 전체 경로입니다. 서브그룹 삭제를 확인하는 데 사용됩니다. `permanently_remove`이 `true`인 경우 이 속성이 필요합니다. 서브그룹 경로를 찾으려면 [그룹 세부 정보](groups.md#retrieve-a-group)를 참조하세요. |
| `permanently_remove` | 부울/문자열    | 아니요       | `true`인 경우 이미 삭제하도록 예약된 서브그룹을 즉시 삭제합니다. 최상위 그룹은 삭제할 수 없습니다. |

성공하면 [`202 Accepted`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/:id"
```

> [!note]
> GitLab.com 그룹을 구독에 연결한 경우 삭제할 수 없습니다. 먼저 다른 그룹으로 [구독을 연결](../subscriptions/manage_subscription.md#link-subscription-to-a-group)해야 합니다.

#### 그룹을 영구적으로 삭제 {#delete-a-group-permanently}

구성된 보존 기간을 무시하고 그룹 및 해당 데이터를 영구적으로 삭제합니다.

전제 조건:

- 관리자이거나 그룹에 대한 Owner 역할을 가져야 합니다.

```plaintext
DELETE /groups/:id
```

| 속성            | 유형              | 필수 | 설명 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `full_path`          | 문자열            | 예       | 삭제하도록 예약한 후 서브그룹의 수정된 전체 경로입니다. `permanently_remove`이 `true`인 경우 이 속성이 필요합니다. 수정된 전체 경로를 확인하려면 [그룹을 검색](#retrieve-a-group)하세요. |
| `permanently_remove` | 부울/문자열    | 예       | `true`인 경우 이미 삭제하도록 예약된 서브그룹을 영구적으로 삭제합니다. 최상위 그룹은 삭제할 수 없습니다. |

성공하면 [`202 Accepted`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

삭제하도록 예약된 그룹을 영구적으로 삭제하려면 다음을 수행해야 합니다:

1. API 호출을 통해 그룹을 삭제하도록 예약합니다.
1. 두 번째 API 호출에서 그룹을 삭제합니다.

예를 들어:

```shell
# Schedule a group for deletion
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/:id"

# Permanently delete a group scheduled for deletion
# Use the modified full_path of the subgroup
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data '{"full_path": "<path-after-soft-delete>", "permanently_remove": "true"}' \
  --url "https://gitlab.example.com/api/v4/groups/:id"
```

#### 삭제를 위해 표시된 그룹 복원 {#restore-a-group-marked-for-deletion}

이전에 삭제하도록 표시된 그룹을 복원합니다.

```plaintext
POST /groups/:id/restore
```

매개변수:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

### 그룹 아카이브 {#archive-a-group}

{{< history >}}

- GitLab 18.0에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) 됨 [플래그](../administration/feature_flags/_index.md) `archive_group` 이름. 기본적으로 비활성화됨.
- GitLab 18.9에 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/526771)됩니다. 기능 플래그 `archive_group` 제거됨.

{{< /history >}}

그룹을 아카이브합니다.

전제 조건:

- 관리자이거나 그룹에 대한 Owner 역할을 가져야 합니다.

이 엔드포인트는 그룹이 이미 아카이브된 경우 `422` 처리 불가능한 엔티티 오류를 반환합니다.

```plaintext
POST /groups/:id/archive
```

매개변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 인증된 사용자가 소유한 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |

응답 예시:

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": true,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

#### 그룹 보관 해제 {#unarchive-a-group}

{{< history >}}

- GitLab 18.0에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) 됨 [플래그](../administration/feature_flags/_index.md) `archive_group` 이름. 기본적으로 비활성화됨.
- GitLab 18.9에 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/526771)됩니다. 기능 플래그 `archive_group` 제거됨.

{{< /history >}}

그룹의 보관을 해제합니다.

전제 조건:

- 관리자이거나 그룹에 대한 Owner 역할을 가져야 합니다.

이 엔드포인트는 그룹이 아카이브되지 않은 경우 `422` 처리 불가능한 엔티티 오류를 반환합니다.

```plaintext
POST /groups/:id/unarchive
```

매개변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 인증된 사용자가 소유한 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |

응답 예시:

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": false,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

### 그룹 이전 {#transfer-a-group}

그룹을 새 상위 그룹으로 이전하거나 서브그룹을 최상위 그룹으로 변환합니다.

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.
- 그룹을 이전하는 경우 새 상위 그룹에서 [서브그룹을 만들](../user/group/subgroups/_index.md#create-a-subgroup) 수 있는 권한이 있어야 합니다.
- 서브그룹을 변환하는 경우 [최상위 그룹을 만들 수 있는 권한](../administration/user_settings.md)이 있어야 합니다.

```plaintext
POST /groups/:id/transfer
```

매개변수:

| 속성  | 유형    | 필수 | 설명 |
|------------|---------|----------|-------------|
| `id`       | 정수 | 예      | 이전할 그룹의 ID입니다. |
| `id`       | 정수 | 예      | 이전할 그룹의 ID입니다. |
| `group_id` | 정수 | 아니요       | 새 상위 그룹의 ID입니다. 지정되지 않으면 그룹이 최상위 그룹으로 변환됩니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/transfer?group_id=7"
```

#### 그룹 이전에 사용 가능한 모든 위치 나열 {#list-all-locations-available-for-group-transfer}

지정된 그룹을 이전하기 위해 사용 가능한 모든 상위 그룹을 나열합니다.

```plaintext
GET /groups/:id/transfer_locations
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 이전할 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `search`  | 문자열            | 아니요       | 검색할 특정 그룹의 이름입니다. |

요청 예시:

```shell
curl --request GET \
    --url "https://gitlab.example.com/api/v4/groups/1/transfer_locations"
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

#### 프로젝트를 그룹으로 이전 {#transfer-a-project-to-a-group}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트를 다른 그룹 네임스페이스로 이전합니다. 대신 [프로젝트를 새 네임스페이스로 이전](projects.md#transfer-a-project-to-a-new-namespace) 엔드포인트를 사용할 수 있습니다.

> [!note]
> 프로젝트의 리포지토리에 태그된 패키지가 있으면 이전 프로세스가 실패할 수 있습니다.

전제 조건:

- 인스턴스의 관리자여야 합니다.

```plaintext
POST /groups/:id/projects/:project_id
```

매개변수:

| 속성    | 유형           | 필수 | 설명 |
| ------------ | -------------- | -------- | ----------- |
| `id`         | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `project_id` | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/projects/56"
```

### 그룹 초대 {#invite-groups}

이 엔드포인트는 그룹 초대에 사용됩니다. 자세한 내용은 [그룹을 그룹으로 초대](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group)를 참조하세요.

#### 그룹 초대 만들기 {#create-a-group-invitation}

지정된 그룹에 대상 그룹을 추가하는 그룹 초대를 만듭니다.

```plaintext
POST /groups/:id/share
```

매개변수:

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `group_id`       | 정수           | 예      | 초대할 그룹의 ID입니다. |
| `group_access`   | 정수           | 예      | 초대된 그룹에 할당할 기본 `access_level`. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `expires_at`     | 날짜 (ISO 8601)   | 아니요       | 그룹 초대가 만료되는 날짜입니다. |
| `member_role_id` | 정수           | 아니요       | 초대된 그룹에 할당할 [사용자 지정 역할](../user/custom_roles/_index.md#assign-a-custom-role-to-an-invited-group)의 ID입니다. 정의된 경우 `group_access`은(는) 사용자 지정 역할을 만드는 데 사용된 기본 역할과 일치해야 합니다. |

`200`을(를) 반환하고 성공 시 그룹 세부 정보를 반환합니다.

#### 그룹 초대 삭제 {#delete-a-group-invitation}

그룹 초대를 삭제하고 지정된 그룹에서 대상 그룹으로의 액세스를 제거합니다.

```plaintext
DELETE /groups/:id/share/:group_id
```

| 속성  | 유형           | 필수 | 설명 |
|------------|----------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `group_id` | 정수        | 예      | 초대 취소할 그룹의 ID입니다. |

`204`을(를) 반환하고 성공 시 콘텐츠 없음을 반환합니다.

## 그룹 속성 업데이트 {#update-group-attributes}

{{< history >}}

- GitLab 18.0에 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183101)됩니다. 기능 플래그 `limit_unique_project_downloads_per_namespace_user` 제거됨.
- `web_based_commit_signing_enabled` [GitLab 18.2에 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193928) 됨 [플래그](../administration/feature_flags/_index.md) `use_web_based_commit_signing_enabled` 이름. 기본적으로 비활성화됨.
- `allow_personal_snippets` [GitLab 18.5에 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200575) 됨 [플래그](../administration/feature_flags/_index.md) `allow_personal_snippets_setting` 이름. 기본적으로 비활성화됨.
- `allow_personal_snippets` [GitLab 18.9에 일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/work_items/583564)됩니다. 기능 플래그 `allow_personal_snippets_setting` 제거됨.

{{< /history >}}

> [!flag]
> `web_based_commit_signing_enabled` 속성의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트용으로 사용할 수 있지만, 프로덕션 환경에서 사용할 준비가 되지 않았습니다.

지정된 그룹의 속성을 업데이트합니다.

전제 조건:

- 관리자이거나 그룹에 대한 Owner 역할을 가져야 합니다.

```plaintext
PUT /groups/:id
```

| 속성                                            | 유형              | 필수 | 설명 |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | 정수           | 예      | 그룹의 ID입니다. |
| `name`                                               | 문자열            | 아니요       | 그룹의 이름. |
| `path`                                               | 문자열            | 아니요       | 그룹의 경로. |
| `auto_devops_enabled`                                | 부울           | 아니요       | 이 그룹 내의 모든 프로젝트에 대해 기본값을 Auto DevOps 파이프라인으로 설정합니다. |
| `avatar`                                             | 혼합             | 아니요       | 그룹 아바타의 이미지 파일. |
| `default_branch`                                     | 문자열            | 아니요       | 그룹의 프로젝트에 대한 [기본 브랜치](../user/project/repository/branches/default.md) 이름. [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442298)됨. |
| `default_branch_protection`                          | 정수           | 아니요       | [GitLab 17.0에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/408314). `default_branch_protection_defaults` 대신 사용합니다. |
| `default_branch_protection_defaults`                 | 해시              | 아니요       | [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314). 사용 가능한 옵션은 [`default_branch_protection_defaults`에 대한 옵션](#options-for-default_branch_protection_defaults)을 참조하세요. |
| `description`                                        | 문자열            | 아니요       | 그룹의 설명입니다. |
| `enabled_git_access_protocol`                        | 문자열            | 아니요       | Git 액세스에 대해 활성화된 프로토콜. 허용되는 값: `ssh`, `http`, 및 `all`(두 프로토콜 모두 허용). [GitLab 16.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/436618). |
| `emails_disabled`                                    | 부울           | 아니요       | ([GitLab 16.5에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899)) 이메일 알림을 비활성화합니다. `emails_enabled` 대신 사용합니다. |
| `emails_enabled`                                     | 부울           | 아니요       | 이메일 알림을 활성화합니다. |
| `lfs_enabled`                                        | 부울           | 아니요       | 이 그룹의 프로젝트에 대한 LFS(Large File Storage)를 활성화/비활성화합니다. |
| `mentions_disabled`                                  | 부울           | 아니요       | 그룹이 언급되는 기능을 비활성화합니다. |
| `prevent_sharing_groups_outside_hierarchy`           | 부울           | 아니요       | [그룹 계층 외부에서 그룹 공유 방지](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy)를 참조하세요. 이 속성은 최상위 그룹에서만 사용 가능합니다. |
| `project_creation_level`                             | 문자열            | 아니요       | 개발자가 그룹에서 프로젝트를 만들 수 있는지 결정합니다. `noone` (아무도 안 함), `maintainer` (Maintainer 역할을 가진 사용자), 또는 `developer` (Developer 또는 Maintainer 역할을 가진 사용자) 중 하나입니다. |
| `request_access_enabled`                             | 부울           | 아니요       | 사용자가 멤버 액세스를 요청할 수 있도록 허용합니다. |
| `require_two_factor_authentication`                  | 부울           | 아니요       | 이 그룹의 모든 사용자가 2단계 인증을 설정해야 합니다. |
| `shared_runners_setting`                             | 문자열            | 아니요       | [`shared_runners_setting`에 대한 옵션](#options-for-shared_runners_setting)을(를) 참조하세요. 그룹의 서브그룹 및 프로젝트에 대해 인스턴스 러너를 활성화하거나 비활성화합니다. |
| `share_with_group_lock`                              | 부울           | 아니요       | 이 그룹 내에서 프로젝트를 다른 그룹과 공유하는 것을 방지합니다. |
| `step_up_auth_required_oauth_provider`               | 문자열            | 아니요       | 단계 업 인증에 필요한 OAuth 공급자입니다. 비활성화하려면 빈 문자열을 전달합니다. GitLab 18.4에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/556943). `omniauth_step_up_auth_for_namespace` 기능 플래그가 활성화되어 있을 때 사용 가능합니다. |
| `subgroup_creation_level`                            | 문자열            | 아니요       | [하위 그룹을 만들도록](../user/group/subgroups/_index.md#create-a-subgroup) 허용됩니다. `owner`(소유자 역할을 가진 사용자) 또는 `maintainer`(유지보수자 역할을 가진 사용자)일 수 있습니다. |
| `two_factor_grace_period`                            | 정수           | 아니요       | 2단계 인증이 적용되기 전의 시간(시간). |
| `visibility`                                         | 문자열            | 아니요       | 그룹의 가시성 수준입니다. `private`, `internal` 또는 `public`일 수 있습니다. |
| `extra_shared_runners_minutes_limit`                 | 정수           | 아니요       | 관리자만 설정할 수 있습니다. 이 그룹에 대한 추가 계산 분. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `file_template_project_id`                           | 정수           | 아니요       | 사용자 지정 파일 템플릿을 로드할 프로젝트의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `membership_lock`                                    | 부울           | 아니요       | 사용자를 이 그룹의 프로젝트에 추가할 수 없습니다. Premium 및 Ultimate만 해당합니다. |
| `prevent_forking_outside_group`                      | 부울           | 아니요       | 활성화되면 사용자가 이 그룹에서 외부 네임스페이스로 프로젝트를 포크할 수 없습니다. Premium 및 Ultimate만 해당합니다. |
| `shared_runners_minutes_limit`                       | 정수           | 아니요       | 관리자만 설정할 수 있습니다. 이 그룹의 월간 최대 계산 분. `nil`(기본값; 시스템 기본값 상속), `0`(무제한) 또는 `> 0`일 수 있습니다. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `unique_project_download_limit`                      | 정수           | 아니요       | 사용자가 지정된 시간 동안 다운로드할 수 있는 최대 고유 프로젝트 수입니다. 최상위 그룹에서만 사용 가능합니다. 기본값:  0, 최대:  10,000. Ultimate만 해당. |
| `unique_project_download_limit_interval_in_seconds`  | 정수           | 아니요       | 사용자가 이를 초과하면 금지되기 전에 최대 프로젝트 수를 다운로드할 수 있는 시간 범위입니다. 최상위 그룹에서만 사용 가능합니다. 기본값:  0, 최대:  864,000초(10일). Ultimate만 해당. |
| `unique_project_download_limit_allowlist`            | 문자열 배열  | 아니요       | 고유 프로젝트 다운로드 제한에서 제외된 사용자 이름 목록입니다. 최상위 그룹에서만 사용 가능합니다. 기본값: `[]`, 최대:  100명의 사용자. Ultimate만 해당. |
| `unique_project_download_limit_alertlist`            | 정수 배열 | 아니요       | 고유 프로젝트 다운로드 제한을 초과했을 때 이메일을 받는 사용자 ID 목록입니다. 최상위 그룹에서만 사용 가능합니다. 기본값: `[]`, 최대:  100명의 사용자 ID. Ultimate만 해당. |
| `auto_ban_user_on_excessive_projects_download`       | 부울           | 아니요       | 활성화되면 사용자가 `unique_project_download_limit` 및 `unique_project_download_limit_interval_in_seconds`에 의해 지정된 고유 프로젝트의 최대 수 이상을 다운로드할 때 그룹에서 자동으로 금지됩니다. Ultimate만 해당. |
| `ip_restriction_ranges`                              | 문자열      | 아니요       | 그룹 액세스를 제한할 IP 주소 또는 서브넷 마스크의 쉼표로 구분된 목록입니다. Premium 및 Ultimate만 해당합니다. |
| `allowed_email_domains_list`                         | 문자열      | 아니요       | 그룹 액세스를 허용할 이메일 주소 도메인의 쉼표로 구분된 목록입니다. 17.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/351494)됨. GitLab Premium 및 Ultimate만 해당합니다. |
| `wiki_access_level`                                  | 문자열            | 아니요       | 위키 액세스 수준. `disabled`, `private` 또는 `enabled`일 수 있습니다. Premium 및 Ultimate만 해당합니다. |
| `duo_availability`                                   | 문자열 | 아니요 | GitLab Duo 가용성 설정. 유효한 값: `default_on`, `default_off`, `never_on`. 참고: UI에서 `never_on`는 "항상 끔"으로 표시됩니다. |
| `experiment_features_enabled`                        | 부울 | 아니요 | 이 그룹에 대한 실험 기능을 활성화합니다. |
| `math_rendering_limits_enabled`                      | 부울           | 아니요       | 이 그룹에 수학 렌더링 제한이 사용되는지 나타냅니다. |
| `lock_math_rendering_limits_enabled`                 | 부울           | 아니요       | 수학 렌더링 제한이 모든 하위 그룹에 대해 잠겨 있는지 나타냅니다. |
| `duo_features_enabled`                               | 부울           | 아니요       | GitLab Duo 기능이 이 그룹에 대해 활성화되어 있는지 나타냅니다. GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)됨. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `lock_duo_features_enabled`                          | 부울           | 아니요       | GitLab Duo 기능 활성화 설정이 모든 서브그룹에 대해 적용되는지 나타냅니다. GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)됨. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `max_artifacts_size`                                 | 정수           | 아니요       | 개별 작업 아티팩트에 대한 최대 파일 크기(MB)입니다. |
| `web_based_commit_signing_enabled`                  | 부울           | 아니요       | GitLab UI에서 만든 커밋에 대해 웹 기반 커밋 서명을 활성화합니다. GitLab.com의 최상위 그룹에서만 사용 가능합니다. 그룹에 대해 활성화되면 그룹의 모든 프로젝트에 적용됩니다. |
| `only_allow_merge_if_pipeline_succeeds`             | 부울           | 아니요       | 파이프라인이 성공한 경우에만 머지 리퀘스트 병합을 허용합니다. 그룹에 대해 활성화되면 그룹의 모든 프로젝트에 적용됩니다. Premium 및 Ultimate만 해당합니다. |
| `allow_merge_on_skipped_pipeline`                   | 부울           | 아니요       | 파이프라인을 건너뛸 때 머지 리퀘스트 병합을 허용합니다. `only_allow_merge_if_pipeline_succeeds`이 `true`인 경우에만 적용됩니다. Premium 및 Ultimate만 해당합니다. |
| `only_allow_merge_if_all_discussions_are_resolved`  | 부울           | 아니요       | 모든 토론이 해결되었을 때만 머지 리퀘스트 병합을 허용합니다. 그룹에 대해 활성화되면 그룹의 모든 프로젝트에 적용됩니다. Premium 및 Ultimate만 해당합니다. |
| `allow_personal_snippets`                           | 부울           | 아니요       | 이 그룹의 엔터프라이즈 사용자가 개인 코드 조각을 만들 수 있도록 허용합니다. 비활성화되면 엔터프라이즈 사용자는 개인 네임스페이스에서 코드 조각을 만들 수 없습니다. |

> [!note]
> 응답의 `projects` 및 `shared_projects` 속성은 더 이상 사용되지 않으며 [API v5에서 제거 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/213797)입니다. 그룹 내의 모든 프로젝트의 세부 정보를 얻으려면 [그룹의 프로젝트 나열](#list-projects) 또는 [그룹의 공유된 프로젝트 나열](#list-shared-projects) 엔드포인트 중 하나를 사용하세요.

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5?name=Experimental"
```

이 엔드포인트는 최대 100개의 프로젝트 및 공유된 프로젝트를 반환합니다. 그룹의 모든 프로젝트의 세부 정보를 가져오려면 [그룹의 프로젝트 나열 엔드포인트](#list-projects)를 대신 사용하세요.

응답 예시:

```json
{
  "id": 5,
  "name": "Experimental",
  "path": "h5bp",
  "description": "foo",
  "visibility": "internal",
  "avatar_url": null,
  "web_url": "http://gitlab.example.com/groups/h5bp",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Foobar Group",
  "full_path": "h5bp",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "prevent_sharing_groups_outside_hierarchy": false,
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "allow_personal_snippets": true,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 9,
      "description": "foo",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "public": false,
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
      "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "Experimental / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": true,
      "created_at": "2016-04-05T21:40:50.169Z",
      "last_activity_at": "2016-04-06T16:52:08.432Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "Experimental",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 1,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

`prevent_sharing_groups_outside_hierarchy` 속성은 최상위 그룹에 대한 응답에만 표시됩니다.

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자도 `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` 및 `experiment_features_enabled` 속성을 볼 수 있습니다.

### `shared_runners_setting`에 대한 옵션 {#options-for-shared_runners_setting}

`shared_runners_setting` 속성은 그룹의 서브그룹 및 프로젝트에 대해 인스턴스 러너가 활성화되어 있는지 여부를 결정합니다.

| 값                        | 설명 |
|------------------------------|-------------|
| `enabled`                    | 이 그룹의 모든 프로젝트 및 서브그룹에 대해 인스턴스 러너를 활성화합니다. |
| `disabled_and_overridable`   | 이 그룹의 모든 프로젝트 및 서브그룹에 대해 인스턴스 러너를 비활성화하지만 서브그룹이 이 설정을 재정의하도록 허용합니다. |
| `disabled_and_unoverridable` | 이 그룹의 모든 프로젝트 및 서브그룹에 대해 인스턴스 러너를 비활성화하고 서브그룹이 이 설정을 재정의하는 것을 방지합니다. |
| `disabled_with_override`     | (더 이상 사용되지 않음. `disabled_and_overridable`을(를) 사용) 이 그룹의 모든 프로젝트 및 서브그룹에 대해 인스턴스 러너를 비활성화하지만 서브그룹이 이 설정을 재정의하도록 허용합니다. |

## 그룹 아바타 업데이트 {#update-group-avatars}

그룹 아바타를 업데이트합니다.

### 그룹 아바타 다운로드 {#download-a-group-avatar}

그룹 아바타를 가져옵니다. 그룹이 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

```plaintext
GET /groups/:id/avatar
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID입니다. |

예: 

```shell
curl --header "PRIVATE-TOKEN: $GITLAB_LOCAL_TOKEN" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/groups/4/avatar"
```

### 그룹 아바타 업로드 {#upload-a-group-avatar}

파일 시스템에서 아바타 파일을 업로드하려면 `--form` 인수를 사용하세요. 이로 인해 curl이 헤더 `Content-Type: multipart/form-data`을(를) 사용하여 데이터를 게시합니다. `file=` 매개변수는 파일 시스템의 파일을 가리켜야 하며 `@`가 앞에 와야 합니다. 예를 들어:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "avatar=@/tmp/example.png" \
  --url "https://gitlab.example.com/api/v4/groups/22"
```

### 그룹 아바타 제거 {#remove-a-group-avatar}

그룹 아바타를 제거하려면 `avatar` 속성에 빈 값을 사용하세요.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "avatar=" \
  --url "https://gitlab.example.com/api/v4/groups/22"
```

## LDAP로 그룹 동기화 {#sync-a-group-with-ldap}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

지정된 그룹을 연결된 LDAP 그룹과 동기화합니다.

전제 조건:

- 관리자이거나 그룹에 대한 Owner 역할을 가져야 합니다.

```plaintext
POST /groups/:id/ldap_sync
```

| 속성 | 유형                | 필수 | 설명                            |
| --------- | ------------------- | -------- | -------------------------------------- |
| `id`      | 정수 또는 문자열   | 예      | 그룹의 ID 또는 URL 인코딩된 경로입니다. |

## 자격 증명 인벤토리 관리 {#credentials-inventory-management}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/groups/gitlab-org/-/epics/16343) 됨 [플래그](../administration/feature_flags/_index.md) `manage_pat_by_group_owners_ready` 이름. 기본적으로 비활성화됨.
- GitLab 18.7에 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/578133)됩니다. 기능 플래그 `manage_pat_by_group_owners_ready` 제거됨.

{{< /history >}}

GitLab.com에서 엔터프라이즈 사용자의 자격 증명을 보고, 취소하고, 회전합니다.

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

### 그룹에 대한 모든 개인 액세스 토큰 나열 {#list-all-personal-access-tokens-for-a-group}

최상위 그룹의 엔터프라이즈 사용자와 연결된 모든 개인 액세스 토큰을 나열합니다.

```plaintext
GET /groups/:id/manage/personal_access_tokens
```

| 속성          | 유형                | 필수 | 설명 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 정수 또는 문자열   | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `created_after`    | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 생성된 토큰을 반환합니다. |
| `created_before`   | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 생성된 토큰을 반환합니다. |
| `last_used_after`  | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 마지막으로 사용된 토큰을 반환합니다. |
| `last_used_before` | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 마지막으로 사용된 토큰을 반환합니다. |
| `revoked`          | 부울             | 아니요       | `true`인 경우 취소된 토큰만 반환합니다. |
| `search`           | 문자열              | 아니요       | 정의된 경우 이름에 지정된 값을 포함하는 토큰을 반환합니다. |
| `state`            | 문자열              | 아니요       | 정의된 경우 지정된 상태의 토큰을 반환합니다. 가능한 값: `active` 및 `inactive`. |
| `sort`             | 문자열              | 아니요       | 정의된 경우 지정된 값으로 결과를 정렬합니다. 가능한 값: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/personal_access_tokens"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "Test Token",
    "revoked": false,
    "created_at": "2020-07-23T14:31:47.729Z",
    "description": "Test Token description",
    "scopes": [
        "api"
    ],
    "user_id": 3,
    "last_used_at": "2021-10-06T17:58:37.550Z",
    "active": true,
    "expires_at": "2025-11-08"
  }
]
```

### 그룹에 대한 모든 그룹 및 프로젝트 액세스 토큰 나열 {#list-all-group-and-project-access-tokens-for-a-group}

최상위 그룹과 연결된 모든 그룹 및 프로젝트 액세스 토큰을 나열합니다.

```plaintext
GET /groups/:id/manage/resource_access_tokens
```

| 속성          | 유형                | 필수 | 설명 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 정수 또는 문자열   | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `created_after`    | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 생성된 토큰을 반환합니다. |
| `created_before`   | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 생성된 토큰을 반환합니다. |
| `last_used_after`  | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 마지막으로 사용된 토큰을 반환합니다. |
| `last_used_before` | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 마지막으로 사용된 토큰을 반환합니다. |
| `revoked`          | 부울             | 아니요       | `true`인 경우 취소된 토큰만 반환합니다. |
| `search`           | 문자열              | 아니요       | 정의된 경우 이름에 지정된 값을 포함하는 토큰을 반환합니다. |
| `state`            | 문자열              | 아니요       | 정의된 경우 지정된 상태의 토큰을 반환합니다. 가능한 값: `active` 및 `inactive`. |
| `sort`             | 문자열              | 아니요       | 정의된 경우 지정된 값으로 결과를 정렬합니다. 가능한 값: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/resource_access_tokens"
```

응답 예시:

```json
[
  {
    "id": 12767703,
    "name": "Test Group Token",
    "revoked": false,
    "created_at": "2025-01-07T00:25:02.128Z",
    "description": "",
    "scopes": [
        "read_registry"
    ],
    "user_id": 25365147,
    "last_used_at": null,
    "active": true,
    "expires_at": "2025-06-19",
    "access_level": 10,
    "resource_type": "group",
    "resource_id": 77449520
  }
]
```

### 그룹에 대한 모든 SSH 키 나열 {#list-all-ssh-keys-for-a-group}

최상위 그룹의 엔터프라이즈 사용자와 연결된 모든 SSH 공개 키를 나열합니다.

```plaintext
GET /groups/:id/manage/ssh_keys
```

| 속성        | 유형                | 필수 | 설명 |
| ---------------- | ------------------- | -------- | ----------- |
| `id`             | 정수 또는 문자열   | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `created_after`  | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 생성된 SSH 키를 반환합니다. |
| `created_before` | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 생성된 SSH 키를 반환합니다. |
| `expires_before` | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 만료되는 SSH 키를 반환합니다. |
| `expires_after`  | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 만료되는 SSH 키를 반환합니다. |

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/ssh_keys"
```

응답 예시:

```json
[
  {
    "id":3,
    "title":"Sample key 3",
    "created_at":"2024-12-23T05:40:11.891Z",
    "expires_at":null,
    "last_used_at":"2024-12-23T05:40:11.891Z",
    "usage_type":"auth_and_signing",
    "user_id":3
  }
]
```

### 엔터프라이즈 사용자를 위한 개인 액세스 토큰 취소 {#revoke-a-personal-access-token-for-an-enterprise-user}

엔터프라이즈 사용자를 위한 지정된 개인 액세스 토큰을 취소합니다.

```plaintext
DELETE groups/:id/manage/personal_access_tokens/:id
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id` | 정수 또는 문자열 | 예 | 개인 액세스 토큰 또는 키워드 `self`의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/personal_access_tokens/<personal_access_token_id>"
```

성공하면 `204: No Content`을(를) 반환합니다.

기타 가능한 응답:

- 취소되지 않으면 `400: Bad Request`.
- 액세스 토큰이 유효하지 않으면 `401: Unauthorized`.
- 액세스 토큰에 필요한 권한이 없으면 `403: Forbidden`.

### 엔터프라이즈 사용자를 위한 그룹 또는 프로젝트 액세스 토큰 취소 {#revoke-a-group-or-project-access-token-for-an-enterprise-user}

최상위 그룹과 연결된 엔터프라이즈 사용자를 위한 지정된 그룹 또는 프로젝트 액세스 토큰을 취소합니다.

```plaintext
DELETE groups/:id/manage/resource_access_tokens/:id
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id` | 정수 또는 문자열 | 예 | 리소스 액세스 토큰 또는 키워드 `self`의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/resource_access_tokens/<personal_access_token_id>"
```

성공하면 `204: No Content`을(를) 반환합니다.

기타 가능한 응답:

- 취소되지 않으면 `400: Bad Request`.
- 액세스 토큰이 유효하지 않으면 `401: Unauthorized`.
- 액세스 토큰에 필요한 권한이 없으면 `403: Forbidden`.

### 엔터프라이즈 사용자를 위한 SSH 키 삭제 {#delete-an-ssh-key-for-an-enterprise-user}

최상위 그룹과 연결된 엔터프라이즈 사용자를 위한 지정된 SSH 공개 키를 삭제합니다.

```plaintext
DELETE /groups/:id/manage/ssh_keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `key_id`  | 정수 | 예      | 기존 키의 ID입니다.  |

성공하면 `204: No Content`을(를) 반환합니다.

기타 가능한 응답:

- SSH 키가 성공적으로 삭제되지 않으면 `400: Bad Request`.
- SSH 키가 유효하지 않으면 `401: Unauthorized`.
- 사용자에게 필요한 권한이 없으면 `403: Forbidden`.

### 엔터프라이즈 사용자의 개인 액세스 토큰 회전 {#rotate-a-personal-access-token-for-an-enterprise-user}

최상위 그룹과 연결된 엔터프라이즈 사용자의 지정된 개인 액세스 토큰을 회전합니다. 이전 토큰을 취소하고 일주일 후에 만료되는 새 토큰을 생성합니다.

```plaintext
POST groups/:id/manage/personal_access_tokens/:id/rotate
```

| 속성 | 유형      | 필수 | 설명         |
|-----------|-----------|----------|---------------------|
| `id` | 정수 또는 문자열 | 예      | 개인 액세스 토큰 또는 키워드 `self`의 ID입니다. |
| `expires_at` | 날짜   | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 날짜는 회전 날짜로부터 1년 이하여야 합니다. 정의되지 않으면 토큰은 일주일 후에 만료됩니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/manage/personal_access_tokens/<personal_access_token_id>/rotate"
```

응답 예시:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

성공하면 `200: OK`을(를) 반환합니다.

기타 가능한 응답:

- 회전하지 못한 경우 `400: Bad Request`입니다.
- 다음 조건 중 하나라도 참이면 `401: Unauthorized`입니다:
  - 토큰이 존재하지 않습니다.
  - 토큰이 만료되었습니다.
  - 토큰이 취소되었습니다.
  - 지정된 토큰에 액세스할 수 없습니다.
- 토큰이 자신을 회전할 수 없는 경우 `403: Forbidden`입니다.
- 사용자가 소유자 역할을 가지고 있지만 토큰이 존재하지 않는 경우 `404: Not Found`입니다.
- 토큰이 개인 액세스 토큰이 아닌 경우 `405: Method Not Allowed`입니다.

### 엔터프라이즈 사용자의 그룹 또는 프로젝트 액세스 토큰 회전 {#rotate-a-group-or-project-access-token-for-an-enterprise-user}

최상위 그룹과 연결된 엔터프라이즈 사용자의 지정된 그룹 또는 프로젝트 액세스 토큰을 회전합니다. 이전 토큰을 취소하고 일주일 후에 만료되는 새 토큰을 생성합니다.

```plaintext
POST groups/:id/manage/resource_access_tokens/:id/rotate
```

| 속성 | 유형      | 필수 | 설명         |
|-----------|-----------|----------|---------------------|
| `id` | 정수 또는 문자열 | 예      | 개인 액세스 토큰 또는 키워드 `self`의 ID입니다. |
| `expires_at` | 날짜   | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 날짜는 회전 날짜로부터 1년 이하여야 합니다. 정의되지 않으면 토큰은 일주일 후에 만료됩니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/manage/resource_access_tokens/<resource_access_token_id>/rotate"
```

응답 예시:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

성공하면 `200: OK`을(를) 반환합니다.

기타 가능한 응답:

- 회전하지 못한 경우 `400: Bad Request`입니다.
- 다음 조건 중 하나라도 참이면 `401: Unauthorized`입니다:
  - 토큰이 존재하지 않습니다.
  - 토큰이 만료되었습니다.
  - 토큰이 취소되었습니다.
  - 지정된 토큰에 액세스할 수 없습니다.
- 토큰이 자신을 회전할 수 없거나 토큰이 봇 사용자 토큰이 아닌 경우 `403: Forbidden`입니다.
- 사용자가 소유자 역할을 가지고 있지만 토큰이 존재하지 않는 경우 `404: Not Found`입니다.
