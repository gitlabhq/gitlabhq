---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 초대 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 초대를 관리하고 [그룹](../user/group/_index.md#add-users-to-a-group) 또는 [프로젝트](../user/project/members/_index.md)에 사용자를 추가합니다.

## 그룹 또는 프로젝트에 멤버 추가 {#add-a-member-to-a-group-or-project}

새 멤버를 추가합니다. 사용자 ID를 지정하거나 이메일로 사용자를 초대할 수 있습니다.

전제 조건:

- 그룹의 경우 그룹에 대한 소유자 역할이 필요합니다.
- 프로젝트의 경우:
  - 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.
  - [그룹 멤버십 잠금](../user/group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)을 사용하지 않아야 합니다.
- GitLab 자체 관리 인스턴스의 경우:
  - [새 사용자 계정을 허용하지 않으면](../administration/settings/sign_up_restrictions.md#disable-new-user-account-creation) 관리자가 사용자를 추가해야 합니다.
  - [사용자 초대를 허용하지 않으면](../administration/settings/visibility_and_access_controls.md#prevent-invitations-to-groups-and-projects) 관리자가 사용자를 추가해야 합니다.
  - [역할 승격에 대한 관리자 승인이 활성화되면](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) 관리자가 초대를 승인해야 합니다.

```plaintext
POST /groups/:id/invitations
POST /projects/:id/invitations
```

| 속성        | 유형              | 필수                          | 설명 |
| ---------------- | ----------------- | --------------------------------- | ----------- |
| `id`             | 정수 또는 문자열 | 예                               | [프로젝트 또는 그룹의 URL 인코딩된 경로](rest/_index.md#namespaced-paths)의 ID |
| `email`          | 문자열            | `user_id`이 제공되지 않은 경우 예 | 새 멤버의 이메일 또는 쉼표로 구분된 여러 이메일입니다. |
| `user_id`        | 정수 또는 문자열 | `email`이 제공되지 않은 경우 예   | 새 멤버의 ID 또는 쉼표로 구분된 여러 ID입니다. |
| `access_level`   | 정수           | 예                               | 유효한 [액세스 수준](../user/permissions.md#default-roles) 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). 기본값: `30`. |
| `expires_at`     | 문자열            | 아니요                                | `YEAR-MONTH-DAY` 형식의 날짜 문자열 |
| `invite_source`  | 문자열            | 아니요                                | 멤버 생성 프로세스를 시작하는 초대의 출처입니다. |
| `member_role_id` | 정수           | 아니요                                | 새 멤버를 제공된 사용자 지정 역할에 할당합니다. ([도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134100)) GitLab 16.6. Ultimate만 해당. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/invitations" \
  --data "email=test@example.com&user_id=1&access_level=30"
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/invitations" \
  --data "email=test@example.com&user_id=1&access_level=30"
```

응답 예시:

모든 이메일이 성공적으로 전송된 경우:

```json
{  "status":  "success"  }
```

이메일을 보낼 때 오류가 있는 경우:

```json
{
  "status": "error",
  "message": {
               "test@example.com": "Invite email has already been taken",
               "test2@example.com": "User already exists in source",
               "test_username": "Access level is not included in the list"
             }
}
```

**Manage non-billable promotions**를 활성화하려면 먼저 `enable_member_promotion_management` 애플리케이션 설정을 활성화해야 합니다.

응답 예시:

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## 그룹 또는 프로젝트의 모든 보류 중인 초대 나열 {#list-all-pending-invitations-for-a-group-or-project}

인증된 사용자가 볼 수 있는 모든 보류 중인 초대를 나열합니다. 직접 멤버로의 초대만 반환하고 상속된 상위 그룹을 통한 초대는 반환하지 않습니다.

이 함수는 `page`과 `per_page` 페이지 매김 매개변수를 사용하여 멤버 목록을 제한합니다.

```plaintext
GET /groups/:id/invitations
GET /projects/:id/invitations
```

| 속성  | 유형           | 필수 | 설명 |
|------------|----------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | [프로젝트 또는 그룹의 URL 인코딩된 경로](rest/_index.md#namespaced-paths)의 ID |
| `page`     | 정수        | 아니요       | 검색할 페이지 |
| `per_page` | 정수        | 아니요       | 페이지당 반환할 멤버 초대 수 |
| `query`    | 문자열         | 아니요       | 초대 이메일로 초대된 멤버를 검색하는 쿼리 문자열입니다. 쿼리 텍스트는 이메일 주소와 정확히 일치해야 합니다. 비어있으면 모든 초대를 반환합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/invitations?query=member@example.org"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/invitations?query=member@example.org"
```

응답 예시:

```json
 [
   {
     "id": 1,
     "invite_email": "member@example.org",
     "created_at": "2020-10-22T14:13:35Z",
     "access_level": 30,
     "expires_at": "2020-11-22T14:13:35Z",
     "user_name": "Raymond Smith",
     "created_by_name": "Administrator"
   },
]
```

## 그룹 또는 프로젝트의 초대 업데이트 {#update-an-invitation-to-a-group-or-project}

그룹 또는 프로젝트에 대한 보류 중인 초대를 업데이트합니다.

```plaintext
PUT /groups/:id/invitations/:email
PUT /projects/:id/invitations/:email
```

| 속성      | 유형              | 필수 | 설명 |
| -------------- | ----------------- | -------- | ----------- |
| `id`           | 정수 또는 문자열 | 예      | [프로젝트 또는 그룹의 URL 인코딩된 경로](rest/_index.md#namespaced-paths)의 ID |
| `email`        | 문자열            | 예      | 이전에 초대를 보낸 이메일 주소입니다. |
| `access_level` | 정수           | 아니요       | 유효한 [액세스 수준](../user/permissions.md#default-roles) 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). 기본값: `30`. |
| `expires_at`   | 문자열            | 아니요       | ISO 8601 형식의 날짜 문자열(`YYYY-MM-DDTHH:MM:SSZ`). |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org?access_level=40"
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org?access_level=40"
```

응답 예시:

```json
{
  "expires_at": "2012-10-22T14:13:35Z",
  "access_level": 40,
}
```

## 그룹 또는 프로젝트의 초대 삭제 {#delete-an-invitation-to-a-group-or-project}

지정된 이메일 주소로의 보류 중인 초대를 삭제합니다.

```plaintext
DELETE /groups/:id/invitations/:email
DELETE /projects/:id/invitations/:email
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | [프로젝트 또는 그룹의 URL 인코딩된 경로](rest/_index.md#namespaced-paths)의 ID |
| `email`   | 문자열         | 예      | 이전에 초대를 보낸 이메일 주소 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org"
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org"
```

- `204`을(를) 반환하고 성공 시 콘텐츠 없음을 반환합니다.
- `403` 초대를 삭제할 권한이 없으면 금지됨을 반환합니다.
- `404` 권한이 있고 해당 이메일 주소에 대한 초대를 찾을 수 없으면 찾을 수 없음을 반환합니다.
- `409` 요청이 유효했지만 초대를 삭제할 수 없으면 반환합니다.
