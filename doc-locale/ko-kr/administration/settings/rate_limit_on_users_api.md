---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Users API의 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Users API의 속도 제한이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/452349) 되었으며, [플래그](../feature_flags/_index.md) `rate_limiting_user_endpoints`가 포함되었습니다. 기본적으로 비활성화됨.
- GitLab 17.10에서 사용자 지정 가능한 속도 제한이 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)되었습니다.
- GitLab 18.1에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/524831)됩니다. 기능 플래그 `rate_limiting_user_endpoints` 제거됨.

{{< /history >}}

> [!note]
> GitLab 18.0 이상으로 업그레이드할 때, 이 API의 구성 가능한 속도 제한이 `0`로 설정됩니다. 관리자는 필요에 따라 속도 제한을 조정할 수 있습니다. 영향을 받는 속도 제한에 대한 자세한 내용은 [Projects, Groups 및 Users API의 공지된 속도 제한](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)을 참조하세요.

다음 [Users API](../../api/users.md)에 대한 요청의 IP 주소당 및 사용자당 분당 속도 제한을 구성할 수 있습니다.

| 제한                                                           | 기본값 |
|-----------------------------------------------------------------|---------|
| [`GET /users/:id/followers`](../../api/user_follow_unfollow.md#list-all-accounts-that-follow-a-user) | 분당 100 |
| [`GET /users/:id/following`](../../api/user_follow_unfollow.md#list-all-accounts-followed-by-a-user) | 분당 100 |
| [`GET /users/:id/status`](../../api/users.md#retrieve-the-status-of-a-user)                               | 분당 240 |
| [`GET /users/:id/keys`](../../api/user_keys.md#list-all-ssh-keys-for-a-user)                         | 분당 120 |
| [`GET /users/:id/keys/:key_id`](../../api/user_keys.md#retrieve-an-ssh-key-for-a-user)                               | 분당 120 |
| [`GET /users/:id/gpg_keys`](../../api/user_keys.md#list-all-gpg-keys-for-a-user)                     | 분당 120 |
| [`GET /users/:id/gpg_keys/:key_id`](../../api/user_keys.md#retrieve-a-gpg-key-for-a-user)                 | 분당 120 |

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

속도 제한을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Users API rate limit**을 확장합니다.
1. 사용 가능한 속도 제한에 대한 값을 설정합니다. 속도 제한은 인증된 요청의 경우 분당, 사용자당이며, 인증되지 않은 요청의 경우 IP 주소당입니다. 속도 제한을 비활성화하려면 `0`을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

각 속도 제한:

- 요청이 인증된 경우 사용자당 적용됩니다.
- 요청이 인증되지 않은 경우 IP 주소당 적용됩니다.
- 속도 제한을 비활성화하려면 `0`로 설정할 수 있습니다.

로그:

- 속도 제한을 초과하는 요청은 `auth.log` 파일에 기록됩니다.
- 속도 제한 수정 사항은 `audit_json.log` 파일에 기록됩니다.

예시:

`GET /users/:id/followers`에 대해 150의 속도 제한을 설정하고 1분에 155개의 요청을 보내면, 마지막 5개의 요청이 차단됩니다. 1분 후에 속도 제한을 다시 초과할 때까지 계속 요청을 보낼 수 있습니다.
