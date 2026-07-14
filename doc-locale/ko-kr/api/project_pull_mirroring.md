---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 끌어오기 미러링 API
description: "프로젝트의 끌어오기 미러링을 관리합니다. 미러 세부 정보를 확인하고, 미러링 설정을 구성하며, 미러 업데이트를 시작합니다."
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 프로젝트 [끌어오기 미러링](../user/project/repository/mirror/pull.md)을 관리합니다.

## 프로젝트 끌어오기 미러 세부 정보 검색 {#retrieve-project-pull-mirror-details}

{{< history >}}

- [응답 확장](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168377) \- GitLab 17.5의 미러 구성 정보 포함. 포함되는 구성 설정: `enabled`, `mirror_trigger_builds`, `only_mirror_protected_branches`, `mirror_overwrites_diverged_branches`, 및 `mirror_branch_regex`.

{{< /history >}}

지정된 프로젝트의 끌어오기 미러 세부 정보를 검색합니다.

```plaintext
GET /projects/:id/mirror/pull
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                             | 유형            | 설명 |
|---------------------------------------|-----------------|-------------|
| `enabled`                             | 부울         | `true`이면 미러가 활성 상태입니다. |
| `id`                                  | 정수         | 미러 구성의 고유 식별자입니다. |
| `last_error`                          | 문자열 또는 null  | 가장 최근의 오류 메시지(있는 경우). 오류가 발생하지 않은 경우 `null`. |
| `last_successful_update_at`           | 문자열          | 마지막 성공한 미러 업데이트의 타임스탬프입니다. |
| `last_update_at`                      | 문자열          | 가장 최근의 미러 업데이트 시도의 타임스탬프입니다. |
| `last_update_started_at`              | 문자열          | 마지막 미러 업데이트 프로세스가 시작된 타임스탬프입니다. |
| `mirror_branch_regex`                 | 문자열 또는 null  | 미러링할 브랜치를 필터링하기 위한 정규식 패턴입니다. 설정되지 않은 경우 `null`. |
| `mirror_overwrites_diverged_branches` | 부울         | `true`이면 미러링 중 분산된 브랜치를 덮어씁니다. |
| `mirror_trigger_builds`               | 부울         | `true`이면 미러 업데이트에 대해 작업을 트리거합니다. |
| `only_mirror_protected_branches`      | 부울 또는 null | `true`이면 보호된 브랜치만 미러링됩니다. 설정되지 않은 경우 값은 `null`입니다. |
| `update_status`                       | 문자열          | 미러 업데이트 프로세스의 상태입니다. 가능한 값: `none`, `scheduled`, `started`, `finished`, `failed`, 또는 `canceled`. |
| `url`                                 | 문자열          | 미러링된 리포지토리의 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

응답 예시:

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "enabled": true,
  "mirror_trigger_builds": true,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## 프로젝트 끌어오기 미러링 설정 업데이트 {#update-project-pull-mirroring-settings}

{{< history >}}

- GitLab 17.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/494294).

{{< /history >}}

프로젝트의 끌어오기 미러링 설정을 업데이트합니다.

```plaintext
PUT /projects/:id/mirror/pull
```

지원되는 속성:

| 속성                             | 유형              | 필수 | 설명 |
|:--------------------------------------|:------------------|:---------|:------------|
| `id`                                  | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `auth_password`                       | 문자열            | 아니요       | 프로젝트 끌어오기 미러링 인증에 사용되는 비밀번호입니다. |
| `auth_user`                           | 문자열            | 아니요       | 프로젝트 끌어오기 미러링 인증에 사용되는 사용자 이름입니다. |
| `enabled`                             | 부울           | 아니요       | `true`이면 `true`로 설정되었을 때 프로젝트에서 끌어오기 미러링을 활성화합니다. |
| `mirror_branch_regex`                 | 문자열            | 아니요       | 정규식을 포함합니다. 정규식과 일치하는 이름의 브랜치만 미러링됩니다. `only_mirror_protected_branches`를 비활성화해야 합니다. |
| `mirror_overwrites_diverged_branches` | 부울           | 아니요       | `true`이면 분산된 브랜치를 덮어씁니다. |
| `mirror_trigger_builds`               | 부울           | 아니요       | `true`이면 미러 업데이트에 대해 파이프라인을 트리거합니다. |
| `only_mirror_protected_branches`      | 부울           | 아니요       | `true`이면 미러링을 보호된 브랜치만으로 제한합니다. |
| `url`                                 | 문자열            | 아니요       | 미러링되는 원격 리포지토리의 URL입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 업데이트된 끌어오기 미러 구성을 제공합니다.

끌어오기 미러링을 추가하기 위한 요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "enabled": true,
    "url": "https://gitlab.example.com/group/project.git",
    "auth_user": "user",
    "auth_password": "password"
  }' \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

끌어오기 미러링을 제거하기 위한 요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "enabled=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

응답 예시:

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://gitlab.example.com/group/project.git",
  "enabled": true,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## 프로젝트의 끌어오기 미러링 업데이트(더 이상 사용되지 않음) {#update-pull-mirroring-for-a-project-deprecated}

{{< history >}}

- 기능 플래그 `mirror_only_branches_match_regex` - GitLab 16.0에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/381667).
- GitLab 16.2에서 [일반 공급 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/410354). 기능 플래그 `mirror_only_branches_match_regex` 제거됨.
- GitLab 17.6에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/494294).

{{< /history >}}

> [!warning]
> 이 구성 옵션은 GitLab 17.6에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) API의 v5 버전에서 제거될 계획입니다. 대신 [새로운 구성 및 엔드포인트](project_pull_mirroring.md#update-project-pull-mirroring-settings)를 사용하세요. 이는 주요 변경 사항입니다.

원격 리포지토리가 공개적으로 액세스 가능하거나 `username:token` 인증을 사용하는 경우, API를 사용하여 프로젝트를 [생성](projects.md#create-a-project) 하거나 [업데이트](projects.md#update-a-project)할 때 끌어오기 미러링을 구성합니다.

HTTP 리포지토리가 공개적으로 액세스 가능하지 않은 경우, URL에 인증 정보를 추가할 수 있습니다. 예를 들어, `https://username:token@gitlab.company.com/group/project.git` - 여기서 `token`는 [PAT](../user/profile/personal_access_tokens.md) - `api` 범위가 활성화되어 있습니다.

지원되는 속성:

| 속성                        | 유형    | 필수 | 설명 |
|:---------------------------------|:--------|:---------|:------------|
| `import_url`                     | 문자열  | 예      | 미러링되는 원격 리포지토리의 URL(`user:token`(필요한 경우))입니다. |
| `mirror`                         | 부울 | 예      | `true`이면 끌어오기 미러링을 활성화합니다. |
| `mirror_branch_regex`            | 문자열  | 아니요       | 정규식을 포함합니다. 정규식과 일치하는 이름의 브랜치만 미러링됩니다. `only_mirror_protected_branches`를 비활성화해야 합니다. |
| `mirror_trigger_builds`          | 부울 | 아니요       | `true`이면 미러 업데이트에 대해 파이프라인을 트리거합니다. |
| `only_mirror_protected_branches` | 부울 | 아니요       | `true`이면 미러링을 보호된 브랜치만으로 제한합니다. |

끌어오기 미러링을 사용하여 프로젝트를 생성하는 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "new_project",
    "namespace_id": "1",
    "mirror": true,
    "import_url": "https://username:token@gitlab.example.com/group/project.git"
  }' \
  --url "https://gitlab.example.com/api/v4/projects/"
```

끌어오기 미러링을 추가하는 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "mirror=true&import_url=https://username:token@gitlab.example.com/group/project.git" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

끌어오기 미러링을 제거하는 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "mirror=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

## 프로젝트의 끌어오기 미러링 프로세스 시작 {#start-the-pull-mirroring-process-for-a-project}

프로젝트의 끌어오기 미러링 프로세스를 시작합니다.

```plaintext
POST /projects/:id/mirror/pull
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`202 Accepted`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```
