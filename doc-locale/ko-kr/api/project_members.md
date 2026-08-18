---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 멤버 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 엔드포인트를 사용하여 프로젝트 멤버와 상호 작용합니다.

그룹 멤버에 대한 정보는 [그룹 멤버 API](group_members.md)를 참조하세요.

## 알려진 이슈 {#known-issues}

- `group_saml_identity` 및 `group_scim_identity` 속성은 [SSO 지원 그룹](../user/group/saml_sso/_index.md)의 그룹 소유자에게만 표시됩니다.
- `email` 속성은 API 요청이 그룹 자체 또는 해당 그룹의 하위 그룹 또는 프로젝트로 전송될 때 그룹의 [엔터프라이즈 사용자](../user/enterprise_user/_index.md)에 대해서만 그룹 소유자에게 표시됩니다.

## 프로젝트의 모든 직접 멤버 나열 {#list-all-direct-members-of-a-project}

인증된 사용자가 볼 수 있는 지정된 프로젝트의 모든 직접 멤버를 나열합니다. [프로젝트의 모든 멤버 나열](#list-all-members-of-a-project)을 사용하여 상속된 멤버를 나열합니다.

이 함수는 범위를 제한하기 위해 `page` 및 `per_page` 페이지 분할 매개변수를 사용합니다.

```plaintext
GET /projects/:id/members
```

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `query`          | 문자열            | 아니요       | 지정된 이름, 이메일 또는 사용자 이름을 기준으로 결과를 필터링합니다. 부분 값을 사용하여 쿼리의 범위를 확대하세요. |
| `user_ids`       | 정수 배열 | 아니요       | 지정된 사용자 ID의 결과를 필터링합니다. |
| `skip_users`     | 정수 배열 | 아니요       | 결과에서 건너뛴 사용자를 필터링합니다. |
| `show_seat_info` | 부울           | 아니요       | 사용자의 사용자 정보를 표시합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

응답 예시:

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null,
    "is_using_seat": true
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  }
]
```

## 프로젝트의 모든 멤버 나열 {#list-all-members-of-a-project}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) \- 현재 사용자가 GitLab 16.10의 공유 그룹 또는 프로젝트의 멤버인 경우 초대된 비공개 그룹의 멤버를 반환하도록 [플래그](../administration/feature_flags/_index.md) `webui_members_inherited_users` 포함 기본적으로 비활성화됨.
- 기능 플래그 `webui_members_inherited_users`는 GitLab 17.0에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)되었습니다.
- 기능 플래그 `webui_members_inherited_users`는 GitLab 17.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)되었습니다. 초대된 그룹의 멤버는 기본적으로 표시됩니다.

{{< /history >}}

인증된 사용자가 볼 수 있는 모든 프로젝트 멤버(상속된 멤버, 초대된 사용자 및 상위 그룹을 통한 권한 포함)를 나열합니다.

사용자가 이 프로젝트의 멤버이면서 동시에 하나 이상의 상위 그룹의 멤버인 경우, 가장 높은 `access_level`을 가진 멤버십만 반환됩니다. 이것은 사용자의 유효한 권한을 나타냅니다.

초대된 그룹의 멤버는 다음 중 하나인 경우 반환됩니다:

- 초대된 그룹은 공개입니다.
- 요청자가 초대된 그룹의 멤버이기도 합니다.
- 요청자가 공유된 그룹 또는 프로젝트의 멤버입니다.

> [!note]
> 초대된 그룹의 멤버는 공유 그룹 또는 프로젝트에서 공유된 멤버십을 가집니다. 즉, 요청자가 공유 그룹 또는 프로젝트의 멤버이지만 초대된 비공개 그룹의 멤버가 아닌 경우, 이 엔드포인트를 사용하면 요청자는 초대된 비공개 그룹의 멤버를 포함하여 공유 그룹 또는 프로젝트의 모든 멤버를 가져올 수 있습니다.

이 함수는 범위를 제한하기 위해 `page` 및 `per_page` 페이지 분할 매개변수를 사용합니다.

```plaintext
GET /projects/:id/members/all
```

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `query`          | 문자열            | 아니요       | 지정된 이름, 이메일 또는 사용자 이름을 기준으로 결과를 필터링합니다. 부분 값을 사용하여 쿼리의 범위를 확대하세요. |
| `user_ids`       | 정수 배열 | 아니요       | 지정된 사용자 ID의 결과를 필터링합니다. |
| `show_seat_info` | 부울           | 아니요       | 사용자의 사용자 정보를 표시합니다. |
| `state`          | 문자열            | 아니요       | `awaiting` 또는 `active` 중 하나인 멤버 상태로 결과를 필터링합니다. Premium 및 Ultimate만 해당합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all"
```

응답 예시:

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-10-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-11-22",
    "access_level": 30,
    "group_saml_identity": null
  }
]
```

## 프로젝트의 직접 멤버 검색 {#retrieve-a-direct-member-of-a-project}

프로젝트의 지정된 직접 멤버를 검색합니다. [프로젝트의 멤버 검색](#retrieve-a-member-of-a-project)을 사용하여 상속된 멤버를 검색합니다.

```plaintext
GET /projects/:id/members/:user_id
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 멤버의 사용자 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

사용자 지정 역할을 그룹 멤버에서 제거하려면 빈 `member_role_id` 값을 전달합니다:

```shell
# Updates a project membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "email": "john@example.com",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": null,
  "group_saml_identity": null
}
```

## 프로젝트의 멤버 검색 {#retrieve-a-member-of-a-project}

{{< history >}}

- GitLab 12.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744).
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) \- 현재 사용자가 GitLab 16.10의 공유 그룹 또는 프로젝트의 멤버인 경우 초대된 비공개 그룹의 멤버를 반환하도록 [플래그](../administration/feature_flags/_index.md) `webui_members_inherited_users` 포함 기본적으로 비활성화됨.
- GitLab 17.0에서 [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/219230).
- 기능 플래그 `webui_members_inherited_users`는 GitLab 17.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)되었습니다. 초대된 그룹의 멤버는 기본적으로 표시됩니다.

{{< /history >}}

상위 그룹을 통해 상속되거나 초대된 멤버를 포함하는 프로젝트의 지정된 멤버를 검색합니다. 자세한 내용은 [프로젝트의 모든 멤버 나열](#list-all-members-of-a-project)을 참조하세요.

> [!note]
> 초대된 그룹의 멤버는 공유 그룹 또는 프로젝트에서 공유된 멤버십을 가집니다. 즉, 요청자가 공유 그룹 또는 프로젝트의 멤버이지만 초대된 비공개 그룹의 멤버가 아닌 경우, 이 엔드포인트를 사용하면 요청자는 초대된 비공개 그룹의 멤버를 포함하여 공유 그룹 또는 프로젝트의 모든 멤버를 가져올 수 있습니다.

```plaintext
GET /projects/:id/members/all/:user_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수 | 예   | 멤버의 사용자 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all/:user_id"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "email": "john@example.com",
  "expires_at": null,
  "group_saml_identity": null
}
```

## 프로젝트에 멤버 추가 {#add-a-member-to-a-project}

지정된 프로젝트에 직접 멤버를 추가합니다.

그룹에 프로젝트 액세스 권한을 부여하려면 [그룹과 프로젝트 공유](projects.md#share-a-project-with-a-group)를 참조하세요.

```plaintext
POST /projects/:id/members
```

| 속성        | 유형              | 필수                           | 설명 |
| ---------------- | ----------------- | ---------------------------------- | ----------- |
| `id`             | 정수 또는 문자열 | 예                                | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`        | 정수 또는 문자열 | `username`이 제공되지 않은 경우 예 | 새 멤버의 사용자 ID 또는 쉼표로 구분된 여러 ID입니다. |
| `username`       | 문자열            | `user_id`이 제공되지 않은 경우 예  | 새 멤버의 사용자 이름 또는 쉼표로 구분된 여러 사용자 이름입니다. |
| `access_level`   | 정수           | 예                                | 유효한 [액세스 수준](../user/permissions.md#default-roles) 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). 기본값: `30`. |
| `expires_at`     | 문자열            | 아니요                                 | `YEAR-MONTH-DAY` 형식의 날짜 문자열입니다. |
| `invite_source`  | 문자열            | 아니요                                 | 멤버 생성 프로세스를 시작하는 초대의 출처입니다. GitLab 팀 멤버는 이 기밀 이슈에서 자세한 정보를 볼 수 있습니다: `https://gitlab.com/gitlab-org/gitlab/-/issues/327120`. |
| `member_role_id` | 정수           | 아니요                                 | Ultimate만 해당. 사용자 지정 역할의 ID입니다. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 30,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> [역할 승격을 위한 관리자 승인](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)이 활성화된 경우 기존 사용자를 청구 가능 역할로 승격하는 멤버십 요청에는 관리자 승인이 필요합니다.

**Manage Non-Billable Promotions**를 활성화하려면 먼저 `enable_member_promotion_management` 애플리케이션 설정을 활성화해야 합니다.

단일 사용자를 대기 중으로 설정하는 예:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

여러 사용자를 대기 중으로 설정하는 예:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval.",
    "username_2": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## 프로젝트의 멤버 업데이트 {#update-a-member-of-a-project}

프로젝트의 지정된 멤버를 업데이트합니다.

```plaintext
PUT /projects/:id/members/:user_id
```

| 속성        | 유형              | 필수 | 설명 |
| ---------------- | ----------------- | -------- | ----------- |
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`        | 정수           | 예      | 멤버의 사용자 ID입니다. |
| `access_level`   | 정수           | 예       | 유효한 [액세스 수준](../user/permissions.md#default-roles) 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). 기본값: `30`. |
| `expires_at`     | 문자열            | 아니요       | `YEAR-MONTH-DAY` 형식의 날짜 문자열입니다. |
| `member_role_id` | 정수           | 아니요       | Ultimate만 해당. 사용자 지정 역할의 ID입니다. 값을 지정하지 않으면 모든 역할이 제거됩니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id?access_level=40"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> [역할 승격을 위한 관리자 승인](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)이 활성화된 경우 기존 사용자를 청구 가능 역할로 승격하는 멤버십 요청에는 관리자 승인이 필요합니다.

**Manage non-billable promotions**를 활성화하려면 먼저 `enable_member_promotion_management` 애플리케이션 설정을 활성화해야 합니다.

응답 예시:

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

## 프로젝트의 직접 멤버 제거 {#remove-a-direct-member-of-a-project}

프로젝트의 지정된 직접 멤버를 제거합니다.

예를 들어, 사용자가 이 그룹이 아닌 그룹의 프로젝트에 직접 추가된 경우 이 엔드포인트를 사용하여 해당 사용자를 제거할 수 없습니다. 자세한 내용은 [그룹에서 청구 가능한 멤버 제거](group_members.md#remove-a-billable-group-member)를 참조하세요.

```plaintext
DELETE /projects/:id/members/:user_id
```

| 속성            | 유형              | 필수 | 설명 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`            | 정수           | 예      | 멤버의 사용자 ID입니다. |
| `skip_subresources`  | 부울           | 거짓    | 하위 그룹 및 프로젝트에서 제거된 멤버의 직접 멤버십 삭제를 건너뛸지 여부입니다. 기본값은 `false`입니다. |
| `unassign_issuables` | 부울           | 거짓    | 제거된 멤버가 주어진 프로젝트 내의 이슈 또는 머지 리퀘스트에서 할당 해제되어야 하는지 여부입니다. 기본값은 `false`입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```
