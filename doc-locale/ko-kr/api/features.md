---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 기능 플래그 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 API는 GitLab 개발에 사용되는 Flipper 기반 기능 플래그를 관리하기 위한 것입니다.

모든 메서드는 관리자 인증이 필요합니다.

API는 부울(boolean) 및 시간 백분율(percentage-of-time) 게이트 값만 지원합니다.

## 모든 기능 플래그 나열 {#list-all-feature-flags}

게이트 값과 함께 지속되는 모든 기능 플래그를 나열합니다.

```plaintext
GET /features
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features"
```

응답 예시:

```json
[
  {
    "name": "experimental_feature",
    "state": "off",
    "gates": [
      {
        "key": "boolean",
        "value": false
      }
    ],
    "definition": null
  },
  {
    "name": "my_user_feature",
    "state": "on",
    "gates": [
      {
        "key": "percentage_of_actors",
        "value": 34
      }
    ],
    "definition": {
      "name": "my_user_feature",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
      "group": "group::ci",
      "type": "development",
      "default_enabled": false
    }
  },
  {
    "name": "new_library",
    "state": "on",
    "gates": [
      {
        "key": "boolean",
        "value": true
      }
    ],
    "definition": null
  }
]
```

## 모든 기능 플래그 정의 나열 {#list-all-feature-flag-definitions}

모든 기능 플래그 정의를 나열합니다.

```plaintext
GET /features/definitions
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features/definitions"
```

응답 예시:

```json
[
  {
    "name": "geo_pages_deployment_replication",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68662",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/337676",
    "milestone": "14.3",
    "log_state_changes": null,
    "type": "development",
    "group": "group::geo",
    "default_enabled": true
  }
]
```

## 기능 플래그 생성 또는 업데이트 {#create-or-update-a-feature-flag}

기능 플래그의 게이트 값을 생성하거나 업데이트합니다. 주어진 이름의 기능 플래그가 아직 없으면 생성됩니다. 값은 부울(boolean)이거나 시간 백분율을 나타내는 정수일 수 있습니다.

> [!warning]
> 개발 중인 기능을 활성화하기 전에 [보안 및 안정성 위험](../administration/feature_flags/_index.md#risks-when-enabling-features-still-in-development)을 이해해야 합니다.

```plaintext
POST /features/:name
```

| 속성       | 유형           | 필수 | 설명                                                                                                                                                                                      |
|-----------------|----------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`          | 문자열         | 예      | 생성하거나 업데이트할 기능의 이름                                                                                                                                                          |
| `value`         | 정수 또는 문자열 | 예      | `true` 또는 `false`를 사용하여 활성화/비활성화하거나, 시간 백분율을 나타내는 정수                                                                                                                        |
| `key`           | 문자열         | 아니요       | `percentage_of_actors` 또는 `percentage_of_time` (기본값)                                                                                                                                         |
| `feature_group` | 문자열         | 아니요       | 기능 그룹 이름                                                                                                                                                                             |
| `user`          | 문자열         | 아니요       | GitLab 사용자명 또는 쉼표로 구분된 여러 사용자명                                                                                                                                          |
| `group`         | 문자열         | 아니요       | 예를 들어 `gitlab-org`인 GitLab 그룹의 경로, 또는 쉼표로 구분된 여러 그룹 경로                                                                                                         |
| `namespace`     | 문자열         | 아니요       | 예를 들어 `john-doe`인 GitLab 그룹 또는 사용자 네임스페이스의 경로, 또는 쉼표로 구분된 여러 네임스페이스 경로. [GitLab 15.0에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353117). |
| `project`       | 문자열         | 아니요       | 예를 들어 `gitlab-org/gitlab-foss`인 프로젝트 경로, 또는 쉼표로 구분된 여러 프로젝트 경로                                                                                                 |
| `repository`    | 문자열         | 아니요       | 예를 들어 `gitlab-org/gitlab-test.git`, `gitlab-org/gitlab-test.wiki.git`, , `snippets/21.git`인 리포지토리 경로 등. 쉼표를 사용하여 여러 리포지토리 경로를 구분합니다.              |
| `runner`        | 문자열         | 아니요       | 러너 ID 또는 쉼표로 구분된 러너 ID 목록                                                                                                                                               |
| `force`         | 부울        | 아니요       | YAML 정의 등의 기능 플래그 유효성 검사를 건너뜁니다.                                                                                                                                   |

단일 API 호출로 `feature_group`, `user`, `group`, `namespace`, `project`, `repository`, `runner`에 대해 기능을 활성화하거나 비활성화할 수 있습니다.

```shell
curl --request POST \
  --data "value=30" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features/new_library"
```

응답 예시:

```json
{
  "name": "new_library",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_time",
      "value": 30
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

### 액터 롤아웃 백분율 설정 {#set-percentage-of-actors-rollout}

액터의 백분율로 롤아웃합니다.

```plaintext
POST https://gitlab.example.com/api/v4/features/my_user_feature?private_token=<your_access_token>
Content-Type: application/x-www-form-urlencoded
value=42&key=percentage_of_actors&
```

응답 예시:

```json
{
  "name": "my_user_feature",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_actors",
      "value": 42
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

`my_user_feature`을 액터의 `42%`로 롤아웃합니다.

## 기능 삭제 {#delete-a-feature}

기능 플래그 게이트를 삭제합니다. 기능 플래그의 존재 여부와 관계없이 동일한 응답을 반환합니다.

```plaintext
DELETE /features/:name
```
