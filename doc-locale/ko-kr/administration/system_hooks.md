---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 시스템 hook
description: "GitLab 이벤트에서 HTTP POST 요청을 트리거하려면 시스템 hook을 사용합니다. JSON 페이로드 예제를 포함합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

시스템 hook은 특정 이벤트가 발생할 때 HTTP POST 요청을 외부 URL로 보내거나 서버에서 로컬 스크립트를 실행합니다.

프로젝트 웹후크와 달리 시스템 hook은 개별 프로젝트뿐만 아니라 전체 GitLab 인스턴스의 이벤트를 모니터링합니다. 이러한 hook은 사용자 생성, 프로젝트 및 그룹 변경, 모든 프로젝트에서의 리포지토리 푸시와 같은 이벤트를 캡처합니다.

## 트리거된 이벤트 {#triggered-events}

| 이벤트 유형                                | 트리거 |
|-------------------------------------------|---------|
| `group_create`                            | 그룹이 생성됩니다. |
| `group_destroy`                           | 그룹이 삭제됩니다. |
| `group_rename`                            | 그룹 경로 또는 이름이 변경됩니다. |
| `key_create`                              | SSH 키가 생성됩니다. |
| `key_destroy`                             | SSH 키가 삭제됩니다. |
| `project_create`                          | 프로젝트가 생성됩니다. |
| `project_destroy`                         | 프로젝트가 삭제됩니다. |
| `project_rename`                          | 프로젝트 경로 또는 이름이 변경됩니다. |
| `project_transfer`                        | 프로젝트가 새로운 네임스페이스로 전송됩니다. |
| `project_update`                          | 프로젝트 속성이 변경됩니다(프로젝트 경로 제외). |
| `repository_update`                       | 푸시에 태그 또는 여러 브랜치가 포함됩니다. |
| `user_access_request_revoked_for_group`   | 그룹에 대한 사용자의 액세스 요청이 취소됩니다. |
| `user_access_request_revoked_for_project` | 프로젝트에 대한 사용자의 액세스 요청이 취소됩니다. |
| `user_access_request_to_group`            | 사용자가 그룹에 대한 액세스를 요청합니다. |
| `user_access_request_to_project`          | 사용자가 프로젝트에 대한 액세스를 요청합니다. |
| `user_add_to_group`                       | 사용자가 그룹 구성원으로 추가됩니다. |
| `user_add_to_team`                        | 사용자가 프로젝트 구성원으로 추가됩니다. |
| `user_create`                             | 사용자 계정이 생성됩니다. |
| `user_destroy`                            | 사용자 계정이 삭제됩니다. |
| `user_failed_login`                       | 차단된 사용자가 로그인을 시도합니다. |
| `user_remove_from_group`                  | 사용자가 그룹에서 삭제됩니다. |
| `user_remove_from_team`                   | 사용자가 프로젝트에서 삭제됩니다. |
| `user_rename`                             | 사용자의 사용자 이름이 변경됩니다. |
| `user_update_for_group`                   | 그룹 구성원의 역할이 변경됩니다. |
| `user_update_for_team`                    | 프로젝트 구성원의 역할이 변경됩니다. |
| `gitlab_subscription_member_approval`     | 역할 승격이 요청됩니다(`"action": "enqueue"`). |
| `gitlab_subscription_member_approvals`    | 역할 승격이 승인됩니다(`"action": "approve"`) 또는 거부됩니다(`"action": "deny"`). |
| `push`                                    | 푸시가 리포지토리에 수행됩니다(태그 제외). |
| `tag_push`                                | 태그가 추가되거나 삭제됩니다. |
| `merge_request`                           | 머지 리퀘스트가 생성, 업데이트, 병합 또는 닫힙니다. |

> [!note]
> 푸시 및 태그 이벤트의 경우 [프로젝트 및 그룹 웹후크](../user/project/integrations/webhooks.md)와 동일한 구조 및 지원 중단이 따릅니다. 다만 커밋은 표시되지 않습니다.

## 시스템 hook 생성 {#create-a-system-hook}

{{< history >}}

- **이름** 및 **설명** 텍스트 상자가 GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141977)되었습니다.
- **URL masking**, **커스텀 헤더**, **Custom webhook template** 텍스트 상자가 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/503457)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

시스템 hook을 생성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **시스템 hook**을 선택합니다.
1. **새 webhook 추가**를 선택합니다.
1. **URL**에 웹후크 엔드포인트의 URL을 입력합니다. 특수 문자는 퍼센트 인코딩을 사용합니다.
1. 선택사항. **이름** 텍스트 상자에 웹후크의 이름을 입력합니다.
1. 선택사항. **설명** 텍스트 상자에 웹후크에 대한 설명을 입력합니다.
1. 선택사항. **비밀 토큰** 텍스트 상자에 요청을 검증하기 위한 비밀 토큰을 입력합니다.

   토큰은 `X-Gitlab-Token` HTTP 헤더로 웹후크 요청과 함께 전송됩니다. 웹후크 엔드포인트는 이 토큰을 사용하여 요청의 적법성을 확인할 수 있습니다.

1. 선택사항. URL의 민감한 부분을 마스킹하려면 **Add URL masking**를 선택합니다. 자세한 내용은 [시스템 hook URL의 민감한 부분 마스킹](#mask-sensitive-portions-of-system-hook-urls)을 참조하세요.
1. 선택사항. 외부 서비스에 대한 인증 헤더를 추가하려면 **커스텀 헤더 추가**를 선택합니다. 자세한 내용은 [커스텀 헤더](#custom-headers)를 참조하세요.
1. **트리거** 섹션에서 hook을 트리거하려는 각 GitLab [이벤트](#optional-triggers)의 확인란을 선택합니다.
1. 선택사항. **Custom webhook template**을 설정하여 요청 본문을 제어합니다. 자세한 내용은 [커스텀 웹후크 템플릿](#custom-webhook-template)을 참조하세요.
1. 선택사항. **SSL 검증 활성화** 확인란을 해제하여 [SSL 검증](../user/project/integrations/_index.md#ssl-verification)을 비활성화합니다.
1. **Add system hook**를 선택합니다.

### 시스템 hook URL의 민감한 부분 마스킹 {#mask-sensitive-portions-of-system-hook-urls}

시스템 hook의 URL의 민감한 부분을 마스킹하는 것은 프로젝트 및 그룹 웹후크와 동일하게 작동합니다. 마스킹된 URL의 부분:

- hook이 실행될 때 구성된 값으로 바뀝니다.
- 로깅되지 않습니다.
- 데이터베이스에서 저장된 상태로 암호화됩니다.

구성에 대한 자세한 내용은 [웹후크 URL의 민감한 부분 마스킹](../user/project/integrations/webhooks.md#mask-sensitive-portions-of-webhook-urls)에 대한 프로젝트 및 그룹 문서를 참조하세요.

### 커스텀 헤더 {#custom-headers}

시스템 hook의 커스텀 헤더는 프로젝트 및 그룹 웹후크와 동일하게 작동합니다. hook당 최대 20개의 커스텀 헤더를 구성할 수 있습니다. 커스텀 헤더는 **최근 이벤트**에 마스킹된 값으로 표시됩니다.

헤더 요구 사항은 [커스텀 헤더](../user/project/integrations/webhooks.md#custom-headers)에 대한 프로젝트 및 그룹 문서를 참조하세요.

### 선택적 트리거 {#optional-triggers}

시스템 hook은 사용자 및 그룹 수명 주기 변경과 같은 [지원되는 이벤트](#triggered-events)에서 자동으로 실행됩니다. 다음의 선택적 트리거를 활성화할 수도 있습니다:

| 트리거                      | 설명 |
|:-----------------------------|:------------|
| **리포지토리 업데이트 이벤트** | 태그 또는 여러 브랜치를 포함하는 푸시입니다. |
| **푸시 이벤트**              | 모든 브랜치에 대한 푸시입니다. |
| **태그 푸시 이벤트**          | 태그가 추가되거나 삭제됩니다. |
| **머지 리퀘스트 이벤트**     | 머지 리퀘스트가 생성, 업데이트, 병합 또는 닫힙니다. |

#### 브랜치별 푸시 이벤트 필터링 {#filter-push-events-by-branch}

브랜치별 푸시 이벤트 필터링은 프로젝트 및 그룹 웹후크와 동일하게 작동합니다. 자세한 내용은 [브랜치별 푸시 이벤트 필터링](../user/project/integrations/webhooks.md#filter-push-events-by-branch)에 대한 프로젝트 및 그룹 문서를 참조하세요.

### 커스텀 웹후크 템플릿 {#custom-webhook-template}

커스텀 웹후크 템플릿은 프로젝트 및 그룹 웹후크와 동일하게 작동합니다. 사용법 및 예제는 [커스텀 웹후크 템플릿](../user/project/integrations/webhooks.md#custom-webhook-template)에 대한 프로젝트 및 그룹 문서를 참조하세요.

## 시스템 hook 제한 {#system-hook-limits}

시스템 hook은 프로젝트 웹후크와 동일한 푸시 이벤트 제한을 적용합니다. 기본적으로 단일 푸시에 3개를 초과하는 브랜치 또는 태그가 포함된 경우 시스템 hook이 트리거되지 않습니다.

이 제한은 `push_event_hooks_limit` 설정(기본값: `3`)으로 제어됩니다. GitLab Self-Managed 인스턴스의 경우 관리자는 [애플리케이션 설정 API](../api/settings.md#available-settings)를 사용하여 이 제한을 수정할 수 있습니다.

## Hook 요청 예제 {#hooks-request-example}

요청 헤더:

```plaintext
X-Gitlab-Event: System Hook
```

프로젝트 생성됨:

```json
{
            "created_at": "2012-07-21T07:30:54Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_create",
                  "name": "StoreCloud",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "storecloud",
   "path_with_namespace": "jsmith/storecloud",
            "project_id": 74,
 "project_namespace_id" : 23,
    "project_visibility": "private"
}
```

프로젝트 삭제됨:

```json
{
            "created_at": "2012-07-21T07:30:58Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_destroy",
                  "name": "Underscore",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "underscore",
   "path_with_namespace": "jsmith/underscore",
            "project_id": 73,
 "project_namespace_id" : 23,
    "project_visibility": "internal"
}
```

프로젝트 이름 변경됨:

```json
{
               "created_at": "2012-07-21T07:30:58Z",
               "updated_at": "2012-07-21T07:38:22Z",
               "event_name": "project_rename",
                     "name": "Underscore",
                     "path": "underscore",
      "path_with_namespace": "jsmith/underscore",
               "project_id": 73,
               "owner_name": "John Smith",
              "owner_email": "johnsmith@example.com",
                   "owners": [{
                              "name": "John",
                              "email": "user1@example.com"
                             }],
    "project_namespace_id" : 23,
       "project_visibility": "internal",
  "old_path_with_namespace": "jsmith/overscore"
}
```

`project_rename`은 네임스페이스가 변경되면 트리거되지 않습니다. 해당 경우에는 `group_rename`와 `user_rename`를 참조하세요.

프로젝트 전송됨:

```json
{
               "created_at": "2012-07-21T07:30:58Z",
               "updated_at": "2012-07-21T07:38:22Z",
               "event_name": "project_transfer",
                     "name": "Underscore",
                     "path": "underscore",
      "path_with_namespace": "scores/underscore",
               "project_id": 73,
               "owner_name": "John Smith",
              "owner_email": "johnsmith@example.com",
                   "owners": [{
                              "name": "John",
                              "email": "user1@example.com"
                             }],
    "project_namespace_id" : 23,
       "project_visibility": "internal",
  "old_path_with_namespace": "jsmith/overscore"
}
```

프로젝트 업데이트됨:

```json
{
            "created_at": "2012-07-21T07:30:54Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_update",
                  "name": "StoreCloud",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "storecloud",
   "path_with_namespace": "jsmith/storecloud",
            "project_id": 74,
 "project_namespace_id" : 23,
    "project_visibility": "private"
}
```

그룹에 대한 액세스 요청 제거됨:

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_access_request_revoked_for_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

프로젝트에 대한 액세스 요청 제거됨:

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_access_request_revoked_for_project",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

그룹에 대한 액세스 요청 생성됨:

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_access_request_to_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

프로젝트에 대한 액세스 요청 생성됨:

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_access_request_to_project",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

새 팀 구성원:

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_add_to_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

팀 구성원 제거됨:

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_remove_from_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

팀 구성원 업데이트됨:

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_update_for_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

사용자 생성됨:

```json
{
   "created_at": "2012-07-21T07:44:07Z",
   "updated_at": "2012-07-21T07:38:22Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_create",
         "name": "John Smith",
     "username": "js",
      "user_id": 41
}
```

사용자 제거됨:

```json
{
   "created_at": "2012-07-21T07:44:07Z",
   "updated_at": "2012-07-21T07:38:22Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_destroy",
         "name": "John Smith",
     "username": "js",
      "user_id": 41
}
```

사용자 로그인 실패:

```json
{
  "event_name": "user_failed_login",
  "created_at": "2017-10-03T06:08:48Z",
  "updated_at": "2018-01-15T04:52:06Z",
        "name": "John Smith",
       "email": "user4@example.com",
     "user_id": 26,
    "username": "user4",
       "state": "blocked"
}
```

사용자가 LDAP을 통해 차단되면 `state`은 `ldap_blocked`입니다.

사용자 이름 변경됨:

```json
{
    "event_name": "user_rename",
    "created_at": "2017-11-01T11:21:04Z",
    "updated_at": "2017-11-01T14:04:47Z",
          "name": "new-name",
         "email": "best-email@example.tld",
       "user_id": 58,
      "username": "new-exciting-name",
  "old_username": "old-boring-name"
}
```

키 추가됨:

```json
{
    "event_name": "key_create",
    "created_at": "2014-08-18 18:45:16 UTC",
    "updated_at": "2012-07-21T07:38:22Z",
      "username": "root",
           "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost",
           "id": 4
}
```

키 제거됨:

```json
{
    "event_name": "key_destroy",
    "created_at": "2014-08-18 18:45:16 UTC",
    "updated_at": "2012-07-21T07:38:22Z",
      "username": "root",
           "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost",
            "id": 4
}
```

그룹 생성됨:

```json
{
   "created_at": "2012-07-21T07:30:54Z",
   "updated_at": "2012-07-21T07:38:22Z",
   "event_name": "group_create",
         "name": "StoreCloud",
         "path": "storecloud",
     "group_id": 78
}
```

그룹 제거됨:

```json
{
   "created_at": "2012-07-21T07:30:54Z",
   "updated_at": "2012-07-21T07:38:22Z",
   "event_name": "group_destroy",
         "name": "StoreCloud",
         "path": "storecloud",
     "group_id": 78
}
```

그룹 이름 변경됨:

```json
{
     "event_name": "group_rename",
     "created_at": "2017-10-30T15:09:00Z",
     "updated_at": "2017-11-01T10:23:52Z",
           "name": "Better Name",
           "path": "better-name",
      "full_path": "parent-group/better-name",
       "group_id": 64,
       "old_path": "old-name",
  "old_full_path": "parent-group/old-name"
}
```

새 그룹 구성원:

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_add_to_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

그룹 구성원 제거됨:

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_remove_from_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

그룹 구성원 업데이트됨:

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_update_for_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

## 푸시 이벤트 {#push-events}

리포지토리에 푸시할 때 트리거됩니다(태그 푸시 제외). 수정된 각 브랜치마다 하나의 이벤트를 생성합니다.

요청 헤더:

```plaintext
X-Gitlab-Event: System Hook
```

요청 본문:

```json
{
  "event_name": "push",
  "before": "95790bf891e76fee5e1747ab589903a6a1f80f22",
  "after": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "ref": "refs/heads/master",
  "checkout_sha": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "user_id": 4,
  "user_name": "John Smith",
  "user_email": "john@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 15,
  "project":{
    "name":"Diaspora",
    "description":"",
    "web_url":"http://example.com/mike/diaspora",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:mike/diaspora.git",
    "git_http_url":"http://example.com/mike/diaspora.git",
    "namespace":"Mike",
    "visibility_level":0,
    "path_with_namespace":"mike/diaspora",
    "default_branch":"master",
    "homepage":"http://example.com/mike/diaspora",
    "url":"git@example.com:mike/diaspora.git",
    "ssh_url":"git@example.com:mike/diaspora.git",
    "http_url":"http://example.com/mike/diaspora.git"
  },
  "repository":{
    "name": "Diaspora",
    "url": "git@example.com:mike/diaspora.git",
    "description": "",
    "homepage": "http://example.com/mike/diaspora",
    "git_http_url":"http://example.com/mike/diaspora.git",
    "git_ssh_url":"git@example.com:mike/diaspora.git",
    "visibility_level":0
  },
  "commits": [
    {
      "id": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "message": "Add simple search to projects in public area",
      "timestamp": "2013-05-13T18:18:08+00:00",
      "url": "https://dev.gitlab.org/gitlab/gitlabhq/commit/c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "author": {
        "name": "Example User",
        "email": "user@example.com"
      }
    }
  ],
  "total_commits_count": 1
}
```

## 태그 이벤트 {#tag-events}

리포지토리에 태그를 생성(또는 삭제)할 때 트리거됩니다. 수정된 각 태그마다 하나의 이벤트를 생성합니다.

요청 헤더:

```plaintext
X-Gitlab-Event: System Hook
```

요청 본문:

```json
{
  "event_name": "tag_push",
  "before": "0000000000000000000000000000000000000000",
  "after": "82b3d5ae55f7080f1e6022629cdb57bfae7cccc7",
  "ref": "refs/tags/v1.0.0",
  "checkout_sha": "5937ac0a7beb003549fc5fd26fc247adbce4a52e",
  "user_id": 1,
  "user_name": "John Smith",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 1,
  "project":{
    "name":"Example",
    "description":"",
    "web_url":"http://example.com/jsmith/example",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "git_http_url":"http://example.com/jsmith/example.git",
    "namespace":"Jsmith",
    "visibility_level":0,
    "path_with_namespace":"jsmith/example",
    "default_branch":"master",
    "homepage":"http://example.com/jsmith/example",
    "url":"git@example.com:jsmith/example.git",
    "ssh_url":"git@example.com:jsmith/example.git",
    "http_url":"http://example.com/jsmith/example.git"
  },
  "repository":{
    "name": "Example",
    "url": "ssh://git@example.com/jsmith/example.git",
    "description": "",
    "homepage": "http://example.com/jsmith/example",
    "git_http_url":"http://example.com/jsmith/example.git",
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "visibility_level":0
  },
  "commits": [],
  "total_commits_count": 0
}
```

## 머지 리퀘스트 이벤트 {#merge-request-events}

새 머지 리퀘스트가 생성되거나, 기존 머지 리퀘스트가 업데이트/병합/닫혔거나, 소스 브랜치에 커밋이 추가될 때 트리거됩니다.

요청 헤더:

```plaintext
X-Gitlab-Event: System Hook
```

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project": {
    "id": 1,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlabhq/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "git_http_url":"http://example.com/gitlabhq/gitlab-test.git",
    "namespace":"GitlabHQ",
    "visibility_level":20,
    "path_with_namespace":"gitlabhq/gitlab-test",
    "default_branch":"master",
    "homepage":"http://example.com/gitlabhq/gitlab-test",
    "url":"http://example.com/gitlabhq/gitlab-test.git",
    "ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "http_url":"http://example.com/gitlabhq/gitlab-test.git"
  },
  "repository": {
    "name": "Gitlab Test",
    "url": "http://example.com/gitlabhq/gitlab-test.git",
    "description": "Aut reprehenderit ut est.",
    "homepage": "http://example.com/gitlabhq/gitlab-test"
  },
  "object_attributes": {
    "id": 99,
    "target_branch": "master",
    "source_branch": "ms-viewport",
    "source_project_id": 14,
    "author_id": 51,
    "assignee_id": 6,
    "title": "MS-Viewport",
    "created_at": "2013-12-03T17:23:34Z",
    "updated_at": "2013-12-03T17:23:34Z",
    "milestone_id": null,
    "state": "opened",
    "merge_status": "unchecked",
    "target_project_id": 14,
    "iid": 1,
    "description": "",
    "source": {
      "name":"Awesome Project",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/awesome_space/awesome_project",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "git_http_url":"http://example.com/awesome_space/awesome_project.git",
      "namespace":"Awesome Space",
      "visibility_level":20,
      "path_with_namespace":"awesome_space/awesome_project",
      "default_branch":"master",
      "homepage":"http://example.com/awesome_space/awesome_project",
      "url":"http://example.com/awesome_space/awesome_project.git",
      "ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "http_url":"http://example.com/awesome_space/awesome_project.git"
    },
    "target": {
      "name":"Awesome Project",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/awesome_space/awesome_project",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "git_http_url":"http://example.com/awesome_space/awesome_project.git",
      "namespace":"Awesome Space",
      "visibility_level":20,
      "path_with_namespace":"awesome_space/awesome_project",
      "default_branch":"master",
      "homepage":"http://example.com/awesome_space/awesome_project",
      "url":"http://example.com/awesome_space/awesome_project.git",
      "ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "http_url":"http://example.com/awesome_space/awesome_project.git"
    },
    "last_commit": {
      "id": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "message": "fixed readme",
      "timestamp": "2012-01-03T23:36:29+02:00",
      "url": "http://example.com/awesome_space/awesome_project/commits/da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "author": {
        "name": "GitLab dev user",
        "email": "gitlabdev@dv6700.(none)"
      }
    },
    "work_in_progress": false,
    "url": "http://example.com/diaspora/merge_requests/1",
    "action": "open",
    "assignee": {
      "name": "User1",
      "username": "user1",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
    }
  },
  "labels": [{
    "id": 206,
    "title": "API",
    "color": "#ffffff",
    "project_id": 14,
    "created_at": "2013-12-03T17:15:43Z",
    "updated_at": "2013-12-03T17:15:43Z",
    "template": false,
    "description": "API related issues",
    "type": "ProjectLabel",
    "group_id": 41
  }],
  "changes": {
    "updated_by_id": {
      "previous": null,
      "current": 1
    },
    "updated_at": {
      "previous": "2017-09-15 16:50:55 UTC",
      "current":"2017-09-15 16:52:00 UTC"
    },
    "labels": {
      "previous": [{
        "id": 206,
        "title": "API",
        "color": "#ffffff",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "API related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }],
      "current": [{
        "id": 205,
        "title": "Platform",
        "color": "#123123",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "Platform related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }]
    }
  }
}
```

## 리포지토리 업데이트 이벤트 {#repository-update-events}

리포지토리에 푸시할 때만 한 번 트리거됩니다(태그 포함).

요청 헤더:

```plaintext
X-Gitlab-Event: System Hook
```

요청 본문:

```json
{
  "event_name": "repository_update",
  "user_id": 1,
  "user_name": "John Smith",
  "user_email": "admin@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 1,
  "project": {
    "name":"Example",
    "description":"",
    "web_url":"http://example.com/jsmith/example",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "git_http_url":"http://example.com/jsmith/example.git",
    "namespace":"Jsmith",
    "visibility_level":0,
    "path_with_namespace":"jsmith/example",
    "default_branch":"master",
    "homepage":"http://example.com/jsmith/example",
    "url":"git@example.com:jsmith/example.git",
    "ssh_url":"git@example.com:jsmith/example.git",
    "http_url":"http://example.com/jsmith/example.git"
  },
  "changes": [
    {
      "before":"8205ea8d81ce0c6b90fbe8280d118cc9fdad6130",
      "after":"4045ea7a3df38697b3730a20fb73c8bed8a3e69e",
      "ref":"refs/heads/master"
    }
  ],
  "refs":["refs/heads/master"]
}
```

## 구독 상태에서 구성원 승인을 위한 이벤트 {#events-for-member-approval-in-subscription}

이러한 이벤트는 [역할 승격을 위한 관리자 승인](settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)이 활성화된 경우 트리거됩니다.

요청 헤더:

```plaintext
X-Gitlab-Event: System Hook
```

승격 관리를 위해 대기 중인 구성원:

```json
{
  "object_kind": "gitlab_subscription_member_approval",
  "action": "enqueue",
  "object_attributes": {
    "new_access_level": 30,
    "old_access_level": 10,
    "existing_member_id": 123
  },
  "user_id": 42,
  "requested_by_user_id": 99,
  "promotion_namespace_id": 789,
  "created_at": "2025-04-10T14:00:00Z",
  "updated_at": "2025-04-10T14:05:00Z"
}
```

인스턴스 관리자에 의해 청구 가능한 역할에서 승인된 사용자:

```json
{
  "object_kind": "gitlab_subscription_member_approvals",
  "action": "approve",
  "object_attributes": {
    "promotion_request_ids_that_failed_to_apply": [],
    "status": "success"
  },
  "reviewed_by_user_id": 101,
  "user_id": 42,
  "updated_at": "2025-04-10T14:10:00Z"
}
```

인스턴스 관리자에 의해 청구 가능한 역할에서 거부된 사용자:

```json
{
"object_kind": "gitlab_subscription_member_approvals",
"action": "deny",
"object_attributes": {
"status": "success"
},
"reviewed_by_user_id": 101,
"user_id": 42,
"updated_at": "2025-04-10T14:12:00Z"
}
```

## 시스템 hook의 로컬 요청 {#local-requests-in-system-hooks}

[시스템 hook에 의한 로컬 네트워크 요청](../security/webhooks.md)은 관리자에 의해 허용되거나 차단될 수 있습니다.

## 관련 항목 {#related-topics}

- [서버 hook](server_hooks.md)
- [파일 hook](file_hooks.md)
