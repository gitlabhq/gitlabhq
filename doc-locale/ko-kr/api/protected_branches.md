---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보호된 브랜치 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [보호된 브랜치](../user/project/repository/branches/protected.md)를 관리합니다.

GitLab Premium 및 GitLab Ultimate은 브랜치로의 푸시에 대한 보다 세분화된 보호를 지원합니다. 관리자는 특정 사용자 대신 배포 키에만 보호된 브랜치를 수정하고 푸시할 권한을 부여할 수 있습니다.

## 유효한 액세스 수준 {#valid-access-levels}

`ProtectedRefAccess.allowed_access_levels` 메서드는 푸시, 병합 및 보호 해제 구성에서 사용되는 다음 액세스 수준을 정의합니다.

- `0`:  액세스 없음 - 푸시 및 병합 액세스 수준에만 유효합니다. 보호 해제 액세스 수준에는 유효하지 않습니다.
- `30`:  개발자
- `40`:  유지관리자
- `60`:  관리자 - GitLab Self-Managed에만 유효합니다.

역할 기반 액세스 수준 외에도 다음 방법으로 액세스를 할당할 수 있습니다:

- 사용자 (`user_id`):  푸시, 병합 및 보호 해제 액세스 수준에 유효합니다.
- 그룹 (`group_id`):  푸시, 병합 및 보호 해제 액세스 수준에 유효합니다. 그룹은 프로젝트에 대해 개발자, 유지 관리자 또는 소유자 역할이 있어야 합니다.
- 배포 키 (`deploy_key_id`):  푸시 액세스 수준에만 유효합니다.

자세한 내용은 [보호된 리포지토리 브랜치 예제](#protect-repository-branches)를 참고하세요.

> [!note]
> 브랜치에 대한 보호 설정이 영구적으로 잠기지 않도록 하려면 적어도 한 명의 사용자 또는 그룹이 항상 해당 브랜치에 대한 보호 해제 권한을 유지하는지 확인합니다. 자세한 내용은 [브랜치 보호를 해제할 수 있는 사용자 제어](../user/project/repository/branches/protected.md#control-who-can-unprotect-branches)를 참고하세요.

## 보호된 브랜치 나열 {#list-protected-branches}

{{< history >}}

- 배포 키 정보가 GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846)되었습니다.

{{< /history >}}

프로젝트에서 UI에 정의된 대로 [보호된 브랜치](../user/project/repository/branches/protected.md)의 목록을 가져옵니다. 와일드카드가 설정되면 해당 와일드카드와 일치하는 브랜치의 정확한 이름 대신 와일드카드가 반환됩니다.

```plaintext
GET /projects/:id/protected_branches
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`  | 문자열            | 아니요       | 보호된 브랜치의 이름 또는 이름의 일부를 검색합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                        | 유형    | 설명 |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | 부울 | `true`인 경우, 이 브랜치에서 강제 푸시가 허용됩니다. |
| `code_owner_approval_required`                   | 부울 | `true`인 경우, 이 브랜치로의 푸시에 대해 코드 소유자 승인이 필요합니다. |
| `id`                                             | 정수 | 보호된 브랜치의 ID입니다. |
| `inherited`                                      | 부울 | `true`인 경우, 보호 설정이 상위 그룹에서 상속됩니다. Premium 및 Ultimate만 해당합니다. |
| `merge_access_levels`                            | 배열   | 병합 액세스 수준 구성의 배열입니다. |
| `merge_access_levels[].access_level`             | 정수 | 병합을 위한 액세스 수준입니다. |
| `merge_access_levels[].access_level_description` | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `merge_access_levels[].group_id`                 | 정수 | 병합 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `merge_access_levels[].id`                       | 정수 | 병합 액세스 수준 구성의 ID입니다. |
| `merge_access_levels[].user_id`                  | 정수 | 병합 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `name`                                           | 문자열  | 보호된 브랜치의 이름입니다. |
| `push_access_levels`                             | 배열   | 푸시 액세스 수준 구성의 배열입니다. |
| `push_access_levels[].access_level`              | 정수 | 푸시를 위한 액세스 수준입니다. |
| `push_access_levels[].access_level_description`  | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `push_access_levels[].deploy_key_id`             | 정수 | 푸시 액세스 권한이 있는 배포 키의 ID입니다. |
| `push_access_levels[].group_id`                  | 정수 | 푸시 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `push_access_levels[].id`                        | 정수 | 푸시 액세스 수준 구성의 ID입니다. |
| `push_access_levels[].user_id`                   | 정수 | 푸시 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |

다음 예제 요청에서 프로젝트 ID는 `5`입니다.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

다음 예제 응답에 포함됩니다:

- ID `100` 및 `101`를 가진 두 개의 보호된 브랜치입니다.
- ID `1001`, `1002` 및 `1003`를 가진 `push_access_levels`입니다.
- ID `2001` 및 `2002`를 가진 `merge_access_levels`입니다.

```json
[
  {
    "id": 100,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 101,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1003,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  2002,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  }
]
```

GitLab Premium 또는 Ultimate의 사용자는 `user_id`, `group_id` 및 `inherited` 매개변수도 볼 수 있습니다. `inherited` 매개변수가 존재하면 설정은 프로젝트의 그룹에서 상속되었습니다.

다음 예제 응답에 포함됩니다:

- ID `100`를 가진 하나의 보호된 브랜치입니다.
- ID `1001` 및 `1002`를 가진 `push_access_levels`입니다.
- ID `2001`를 가진 `merge_access_levels`입니다.

```json
[
  {
    "id": 101,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1,
        "user_id": null,
        "group_id": null
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": null,
        "user_id": null,
        "group_id": 1234,
        "access_level_description": "Example Merge Group"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false,
    "inherited": true
  }
]
```

## 보호된 브랜치 또는 와일드카드 보호된 브랜치 검색 {#retrieve-a-protected-branch-or-wildcard-protected-branch}

지정된 보호된 브랜치 또는 와일드카드 보호된 브랜치를 검색합니다.

```plaintext
GET /projects/:id/protected_branches/:name
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열            | 예      | 브랜치 또는 와일드카드의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                        | 유형    | 설명 |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | 부울 | `true`인 경우, 이 브랜치에서 강제 푸시가 허용됩니다. |
| `code_owner_approval_required`                   | 부울 | `true`인 경우, 이 브랜치로의 푸시에 대해 코드 소유자 승인이 필요합니다. |
| `id`                                             | 정수 | 보호된 브랜치의 ID입니다. |
| `merge_access_levels`                            | 배열   | 병합 액세스 수준 구성의 배열입니다. |
| `merge_access_levels[].access_level`             | 정수 | 병합을 위한 액세스 수준입니다. |
| `merge_access_levels[].access_level_description` | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `merge_access_levels[].group_id`                 | 정수 | 병합 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `merge_access_levels[].id`                       | 정수 | 병합 액세스 수준 구성의 ID입니다. |
| `merge_access_levels[].user_id`                  | 정수 | 병합 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `name`                                           | 문자열  | 보호된 브랜치의 이름입니다. |
| `push_access_levels`                             | 배열   | 푸시 액세스 수준 구성의 배열입니다. |
| `push_access_levels[].access_level`              | 정수 | 푸시를 위한 액세스 수준입니다. |
| `push_access_levels[].access_level_description`  | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `push_access_levels[].group_id`                  | 정수 | 푸시 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `push_access_levels[].id`                        | 정수 | 푸시 액세스 수준 구성의 ID입니다. |
| `push_access_levels[].user_id`                   | 정수 | 푸시 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |

다음 예제 요청에서 프로젝트 ID는 `5` 및 브랜치 이름은 `main`입니다:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

응답 예시:

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

GitLab Premium 또는 Ultimate의 사용자는 `user_id` 및 `group_id` 매개변수도 볼 수 있습니다.

응답 예시:

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 1234,
      "access_level_description": "Example Merge Group"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

## 리포지토리 브랜치 보호 {#protect-repository-branches}

{{< history >}}

- `deploy_key_id` 구성이 GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)되었습니다.
- `deploy_key_id` 구성이 GitLab 18.10에서 GitLab Premium에서 GitLab Free로 [이동](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542)되었습니다.

{{< /history >}}

와일드카드 보호된 브랜치를 사용하여 단일 리포지토리 브랜치 또는 여러 프로젝트 리포지토리 브랜치를 보호합니다.

```plaintext
POST /projects/:id/protected_branches
```

지원되는 속성:

| 속성                      | 유형              | 필수 | 설명 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                         | 문자열            | 예      | 브랜치 또는 와일드카드의 이름입니다. |
| `allow_force_push`             | 부울           | 아니요       | `true`인 경우, 이 브랜치로 푸시할 수 있는 구성원은 강제 푸시도 할 수 있습니다. 기본값은 `false`입니다. |
| `allowed_to_merge`             | 배열             | 아니요       | `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식으로 설명되는 각 병합 액세스 수준의 배열입니다. Premium 및 Ultimate만 해당합니다. |
| `allowed_to_push`              | 배열             | 아니요       | `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` 또는 `{access_level: integer}` 형식으로 설명되는 각 푸시 액세스 수준의 배열입니다. `user_id`, `group_id` 및 `access_level`은(는) Premium 및 Ultimate만 해당합니다. |
| `allowed_to_unprotect`         | 배열             | 아니요       | `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식으로 설명되는 각 보호 해제 액세스 수준의 배열입니다. 액세스 수준 `No access`은(는) 이 필드에 사용할 수 없습니다. Premium 및 Ultimate만 해당합니다. |
| `code_owner_approval_required` | 부울           | 아니요       | `true`인 경우, [`CODEOWNERS` 파일](../user/project/codeowners/_index.md)의 항목과 일치하면 이 브랜치로의 푸시를 방지합니다. 기본값은 `false`입니다. Premium 및 Ultimate만 해당합니다. |
| `merge_access_level`           | 정수           | 아니요       | 병합이 허용되는 액세스 수준입니다. 기본값은 `40`(유지관리자 역할)입니다. |
| `push_access_level`            | 정수           | 아니요       | 푸시가 허용되는 액세스 수준입니다. 기본값은 `40`(유지관리자 역할)입니다. |
| `unprotect_access_level`       | 정수           | 아니요       | 보호 해제가 허용되는 액세스 수준입니다. 기본값은 `40`(유지관리자 역할)입니다. `0`(액세스 없음)은 유효하지 않습니다. |

액세스 수준을 구성할 때:

- `allowed_to_push` 및 `allowed_to_merge`에 대해 여러 액세스 수준을 동시에 설정할 수 있습니다.
- 가장 허용적인 액세스 수준은 누가 작업을 수행할 수 있는지 결정합니다.
- `allowed_to_push`, `allowed_to_merge` 또는 `allowed_to_unprotect` 배열에 `id`를 포함하지 마십시오. `id` 필드는 기존 액세스 수준 기록을 식별하며 [보호된 브랜치 업데이트](#update-a-protected-branch)할 때만 유효합니다. 기존 기록과 일치하지 않는 `id`를 포함하면 API는 `404 Not Found`를 반환합니다.

이 동작은 **아무도 없음** (`access_level: 0`)을 선택할 때 자동으로 다른 역할 선택을 지우는 UI와 다릅니다.

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                            | 유형    | 설명 |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | 부울 | `true`인 경우, 이 브랜치에서 강제 푸시가 허용됩니다. |
| `code_owner_approval_required`                       | 부울 | `true`인 경우, 이 브랜치로의 푸시에 대해 코드 소유자 승인이 필요합니다. |
| `id`                                                 | 정수 | 보호된 브랜치의 ID입니다. |
| `merge_access_levels`                                | 배열   | 병합 액세스 수준 구성의 배열입니다. |
| `merge_access_levels[].access_level`                 | 정수 | 병합을 위한 액세스 수준입니다. |
| `merge_access_levels[].access_level_description`     | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `merge_access_levels[].group_id`                     | 정수 | 병합 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `merge_access_levels[].id`                           | 정수 | 병합 액세스 수준 구성의 ID입니다. |
| `merge_access_levels[].user_id`                      | 정수 | 병합 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `name`                                               | 문자열  | 보호된 브랜치의 이름입니다. |
| `push_access_levels`                                 | 배열   | 푸시 액세스 수준 구성의 배열입니다. |
| `push_access_levels[].access_level`                  | 정수 | 푸시를 위한 액세스 수준입니다. |
| `push_access_levels[].access_level_description`      | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `push_access_levels[].deploy_key_id`                 | 정수 | 푸시 액세스 권한이 있는 배포 키의 ID입니다. |
| `push_access_levels[].group_id`                      | 정수 | 푸시 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `push_access_levels[].id`                            | 정수 | 푸시 액세스 수준 구성의 ID입니다. |
| `push_access_levels[].user_id`                       | 정수 | 푸시 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `unprotect_access_levels`                            | 배열   | 보호 해제 액세스 수준 구성의 배열입니다. |
| `unprotect_access_levels[].access_level`             | 정수 | 보호 해제를 위한 액세스 수준입니다. |
| `unprotect_access_levels[].access_level_description` | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `unprotect_access_levels[].group_id`                 | 정수 | 보호 해제 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `unprotect_access_levels[].id`                       | 정수 | 보호 해제 액세스 수준 구성의 ID입니다. |
| `unprotect_access_levels[].user_id`                  | 정수 | 보호 해제 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |

다음 예제 요청에서 프로젝트 ID는 `5` 및 브랜치 이름은 `*-stable`입니다.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

예제 응답에 포함됩니다:

- ID `101`를 가진 보호된 브랜치입니다.
- ID `1001`를 가진 `push_access_levels`입니다.
- ID `2001`를 가진 `merge_access_levels`입니다.
- ID `3001`를 가진 `unprotect_access_levels`입니다.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

GitLab Premium 또는 Ultimate의 사용자는 `user_id` 및 `group_id` 매개변수도 볼 수 있습니다:

다음 예제 응답에 포함됩니다:

- ID `101`를 가진 보호된 브랜치입니다.
- ID `1001`를 가진 `push_access_levels`입니다.
- ID `2001`를 가진 `merge_access_levels`입니다.
- ID `3001`를 가진 `unprotect_access_levels`입니다.

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### 사용자 푸시 액세스 및 그룹 병합 액세스가 있는 예제 {#example-with-user-push-access-and-group-merge-access}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`allowed_to_push` / `allowed_to_merge` / `allowed_to_unprotect` 배열의 요소는 `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식이어야 합니다. 각 사용자는 프로젝트에 대한 액세스 권한이 있어야 하고 각 그룹은 [이 프로젝트를 공유](../user/project/members/sharing_projects_groups.md)해야 합니다. 이러한 액세스 수준을 통해 보호된 브랜치 액세스를 보다 세밀하게 제어할 수 있습니다. 자세한 내용은 [그룹 권한 구성](../user/project/repository/branches/protected.md#with-group-permissions)을 참고하세요.

다음 예제 요청은 사용자 푸시 액세스 및 그룹 병합 액세스를 사용하여 보호된 브랜치를 만듭니다. `user_id`은 `2` 및 `group_id`은 `3`입니다.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push%5B%5D%5Buser_id%5D=2&allowed_to_merge%5B%5D%5Bgroup_id%5D=3"
```

다음 예제 응답에 포함됩니다:

- ID `101`를 가진 보호된 브랜치입니다.
- ID `1001`를 가진 `push_access_levels`입니다.
- ID `2001`를 가진 `merge_access_levels`입니다.
- ID `3001`를 가진 `unprotect_access_levels`입니다.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": 2,
      "group_id": null,
      "access_level_description": "Administrator"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 3,
      "access_level_description": "Example Merge Group"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### 배포 키 액세스가 있는 예제 {#example-with-deploy-key-access}

{{< history >}}

- GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)되었습니다.
- GitLab 18.10에서 GitLab Premium에서 GitLab Free로 [이동](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542)되었습니다.

{{< /history >}}

`allowed_to_push` 배열의 요소는 `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` 또는 `{access_level: integer}`의 형식을 따릅니다. 배포 키는 프로젝트에 대해 활성화되어야 하며 프로젝트 리포지토리에 대한 쓰기 액세스 권한이 있어야 합니다. 기타 요구 사항은 [보호된 브랜치로 푸시할 배포 키 허용](../user/project/repository/branches/protected.md#enable-deploy-key-access)을 참고하세요.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push[][deploy_key_id]=1"
```

다음 예제 응답에 포함됩니다:

- ID `101`를 가진 보호된 브랜치입니다.
- ID `1001`를 가진 `push_access_levels`입니다.
- ID `2001`를 가진 `merge_access_levels`입니다.
- ID `3001`를 가진 `unprotect_access_levels`입니다.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": null,
      "group_id": null,
      "deploy_key_id": 1,
      "access_level_description": "Deploy"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### 푸시 및 병합 액세스 허용이 있는 예제 {#example-with-allow-to-push-and-allow-to-merge-access}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 13.9에서 GitLab Premium으로 이동했습니다.

{{< /history >}}

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [
      {"access_level": 30}
    ],
    "allowed_to_merge": [
      {"access_level": 30},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

다음 예제 응답에 포함됩니다:

- ID `105`를 가진 보호된 브랜치입니다.
- ID `1001`를 가진 `push_access_levels`입니다.
- ID `2001` 및 `2002`를 가진 `merge_access_levels`입니다.
- ID `3001`를 가진 `unprotect_access_levels`입니다.

```json
{
    "id": 105,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 2001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2002,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 3001,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
}
```

### 보호 해제 액세스 수준이 있는 예제 {#examples-with-unprotect-access-levels}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

특정 그룹만 브랜치 보호를 해제할 수 있는 보호된 브랜치를 만들려면:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "production",
    "allowed_to_unprotect": [
      {"group_id": 789}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

여러 유형의 사용자가 브랜치의 보호를 해제하도록 허용하려면:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_unprotect": [
      {"user_id": 123},
      {"group_id": 456},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

이 구성은 다음 사용자가 브랜치 보호를 해제할 수 있도록 합니다:

- ID `123`인 사용자입니다.
- ID `456`인 그룹의 구성원입니다.
- 유지 관리자 또는 소유자 역할이 있는 사용자(액세스 수준 40)입니다.

## 리포지토리 브랜치 보호 해제 {#unprotect-repository-branches}

지정된 보호된 브랜치 또는 와일드카드 보호된 브랜치의 보호를 해제합니다.

```plaintext
DELETE /projects/:id/protected_branches/:name
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열            | 예      | 브랜치의 이름입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

다음 예제 요청에서 프로젝트 ID는 `5` 및 브랜치 이름은 `*-stable`입니다:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/*-stable"
```

## 보호된 브랜치 업데이트 {#update-a-protected-branch}

{{< history >}}

- `deploy_key_id` 구성이 GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)되었습니다.

{{< /history >}}

보호된 브랜치를 업데이트합니다.

```plaintext
PATCH /projects/:id/protected_branches/:name
```

지원되는 속성:

| 속성                      | 유형              | 필수 | 설명 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                         | 문자열            | 예      | 브랜치 또는 와일드카드의 이름입니다. |
| `allow_force_push`             | 부울           | 아니요       | `true`인 경우, 이 브랜치로 푸시할 수 있는 구성원은 강제 푸시도 할 수 있습니다. |
| `allowed_to_merge`             | 배열             | 아니요       | `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식으로 설명되는 각 병합 액세스 수준의 배열입니다. Premium 및 Ultimate만 해당합니다. |
| `allowed_to_push`              | 배열             | 아니요       | `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` 또는 `{access_level: integer}` 형식으로 설명되는 각 푸시 액세스 수준의 배열입니다. `user_id`, `group_id` 및 `access_level`은(는) Premium 및 Ultimate만 해당합니다. |
| `allowed_to_unprotect`         | 배열             | 아니요       | `{user_id: integer}`, `{group_id: integer}`, `{access_level: integer}` 또는 기존 액세스 수준을 제거할 `{id: integer, _destroy: true}` 형식으로 설명되는 각 보호 해제 액세스 수준의 배열입니다. 액세스 수준 `No access`은(는) 이 필드에 사용할 수 없습니다. Premium 및 Ultimate만 해당합니다. |
| `code_owner_approval_required` | 부울           | 아니요       | `true`인 경우, [`CODEOWNERS` 파일](../user/project/codeowners/_index.md)의 항목과 일치하면 이 브랜치로의 푸시를 방지합니다. Premium 및 Ultimate만 해당합니다. |

여러 값을 설정할 때 액세스 수준이 어떻게 상호 작용하는지 알아보려면 [리포지토리 브랜치 보호](#protect-repository-branches)를 참고하세요.

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                            | 유형    | 설명 |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | 부울 | `true`인 경우, 이 브랜치에서 강제 푸시가 허용됩니다. |
| `code_owner_approval_required`                       | 부울 | `true`인 경우, 이 브랜치로의 푸시에 대해 코드 소유자 승인이 필요합니다. |
| `id`                                                 | 정수 | 보호된 브랜치의 ID입니다. |
| `merge_access_levels`                                | 배열   | 병합 액세스 수준 구성의 배열입니다. |
| `merge_access_levels[].access_level`                 | 정수 | 병합을 위한 액세스 수준입니다. |
| `merge_access_levels[].access_level_description`     | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `merge_access_levels[].group_id`                     | 정수 | 병합 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `merge_access_levels[].id`                           | 정수 | 병합 액세스 수준 구성의 ID입니다. |
| `merge_access_levels[].user_id`                      | 정수 | 병합 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `name`                                               | 문자열  | 보호된 브랜치의 이름입니다. |
| `push_access_levels`                                 | 배열   | 푸시 액세스 수준 구성의 배열입니다. |
| `push_access_levels[].access_level`                  | 정수 | 푸시를 위한 액세스 수준입니다. |
| `push_access_levels[].access_level_description`      | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `push_access_levels[].deploy_key_id`                 | 정수 | 푸시 액세스 권한이 있는 배포 키의 ID입니다. |
| `push_access_levels[].group_id`                      | 정수 | 푸시 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `push_access_levels[].id`                            | 정수 | 푸시 액세스 수준 구성의 ID입니다. |
| `push_access_levels[].user_id`                       | 정수 | 푸시 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `unprotect_access_levels`                            | 배열   | 보호 해제 액세스 수준 구성의 배열입니다. |
| `unprotect_access_levels[].access_level`             | 정수 | 보호 해제를 위한 액세스 수준입니다. |
| `unprotect_access_levels[].access_level_description` | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `unprotect_access_levels[].group_id`                 | 정수 | 보호 해제 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `unprotect_access_levels[].id`                       | 정수 | 보호 해제 액세스 수준 구성의 ID입니다. |
| `unprotect_access_levels[].user_id`                  | 정수 | 보호 해제 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

`allowed_to_push`, `allowed_to_merge` 및 `allowed_to_unprotect` 배열의 요소는 `user_id`, `group_id` 또는 `access_level` 중 하나여야 하며 `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식이어야 합니다.

`allowed_to_push`에는 `deploy_key_id` 형식을 사용하는 추가 요소 `{deploy_key_id: integer}`이 포함됩니다.

업데이트하려면:

- `user_id`:  업데이트된 사용자가 프로젝트에 액세스할 수 있는지 확인합니다. 액세스 수준 기록의 `id`를 해시에 포함합니다.
- `group_id`:  업데이트된 그룹 [이 프로젝트가 공유](../user/project/members/sharing_projects_groups.md)되었는지 확인합니다. 액세스 수준 기록의 `id`를 해시에 포함합니다.
- `deploy_key_id`:  배포 키가 프로젝트에 대해 활성화되었으며 프로젝트 리포지토리에 대한 쓰기 액세스 권한이 있는지 확인합니다.

기존 액세스 수준 기록의 다른 필드를 업데이트하려면 기록의 `id`를 해시에 포함합니다.

삭제하려면 `_destroy`을 `true`로 설정해야 합니다. 다음 예제를 참조하세요.

### 예제: `push_access_level` 기록 만들기 {#example-create-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"access_level": 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

응답 예시:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 예제: `push_access_level` 기록 업데이트 {#example-update-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

응답 예시:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 0,
         "access_level_description": "No One",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 예제: `push_access_level` 기록 삭제 {#example-delete-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "_destroy": true}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

응답 예시:

```json
{
   "name": "main",
   "push_access_levels": []
}
```

### 예제: `unprotect_access_level` 기록 업데이트 {#example-update-an-unprotect_access_level-record}

전제 조건:

- 이 API를 호출하는 사용자는 `allowed_to_unprotect` 구성에 포함되어야 합니다.
- `user_id`로 지정된 사용자는 프로젝트 구성원이어야 합니다.
- `group_id`로 지정된 그룹은 프로젝트에 액세스할 수 있어야 합니다.

기존 보호된 브랜치의 보호 해제 권한을 가질 수 있는 사용자를 수정하려면 기존 액세스 수준 기록의 `id`를 포함합니다. 예를 들어:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "allowed_to_unprotect": [
      {"id": 17486, "user_id": 3791}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

특정 액세스 수준을 제거하려면 `_destroy: true`을 사용합니다.

## 관련 항목 {#related-topics}

- [보호된 브랜치](../user/project/repository/branches/protected.md)
- [브랜치](../user/project/repository/branches/_index.md)
- [브랜치 API](branches.md)
