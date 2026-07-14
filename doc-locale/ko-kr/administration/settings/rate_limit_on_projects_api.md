---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 API의 속도 제한
description: 프로젝트 API 엔드포인트에서 속도 제한을 설정합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab 18.0 이상으로 업그레이드할 때, 이 API에 대해 구성 가능한 속도 제한은 `0`으로 설정됩니다. 관리자는 필요에 따라 속도 제한을 조정할 수 있습니다. 영향을 받는 속도 제한에 대한 정보는 [프로젝트, 그룹 및 사용자 API에 대해 공표된 속도 제한](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)을 참조하세요.

## 프로젝트 API 속도 제한 구성 {#configure-projects-api-rate-limits}

{{< history >}}

- GitLab 16.0에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120445) 기능 플래그 `rate_limit_for_unauthenticated_projects_api_access` 제거됨.
- GitLab 17.1에서 그룹 및 프로젝트 API에 대한 속도 제한이 [플래그](../feature_flags/_index.md) `rate_limit_groups_and_projects_api`와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/421909)되었습니다. 기본적으로 비활성화됨.
- GitLab 18.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)합니다. 기능 플래그 `rate_limit_groups_and_projects_api` 제거됨.

{{< /history >}}

다음 프로젝트 API 엔드포인트에 대한 요청을 위해 각 IP 주소 및 사용자별 속도 제한을 구성합니다:

| 제한                                                                                                       | 기본값 | 간격 |
|-------------------------------------------------------------------------------------------------------------|---------|----------|
| [`GET /projects`](../../api/projects.md#list-all-projects) (인증되지 않은 요청)                       | 400     | 10분 |
| [`GET /projects`](../../api/projects.md#list-all-projects) (인증된 요청)                         | 2000    | 10분 |
| [`GET /projects/:id`](../../api/projects.md#retrieve-a-project)                                             | 400     | 1분 |
| [`GET /users/:user_id/projects`](../../api/projects.md#list-all-personal-projects-for-a-user)               | 300     | 1분 |
| [`GET /users/:user_id/contributed_projects`](../../api/projects.md#list-all-projects-contributions-for-a-user) | 100     | 1분 |
| [`GET /users/:user_id/starred_projects`](../../api/project_starring.md#list-projects-starred-by-a-user)     | 100     | 1분 |

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

속도 제한을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **프로젝트 API 속도 제한**을 확장합니다.
1. 속도 제한의 값을 변경하거나 속도 제한을 `0`로 설정하여 비활성화합니다.
1. **변경 사항 저장**을 선택합니다.

속도 제한:

- 각 인증된 사용자에게 적용됩니다. 요청이 인증되지 않은 경우, 속도 제한이 IP 주소에 적용됩니다.

속도 제한을 초과한 요청은 `auth.log` 파일에 기록됩니다.

예를 들어, `GET /projects/:id`에 대해 400의 제한을 설정하면, 분당 400개 요청을 초과하는 API 엔드포인트 요청이 차단됩니다. 1분 후 엔드포인트에 대한 액세스가 복구됩니다.

프로젝트 API 엔드포인트에 대한 자세한 정보는 [프로젝트 API](../../api/projects.md#list-all-projects)를 참조하세요.

## 프로젝트 멤버 삭제에 대한 속도 제한 구성 {#configure-rate-limits-on-deleting-project-members}

{{< history >}}

- GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/420321)되었습니다.

{{< /history >}}

각 프로젝트 및 사용자에 대해 [멤버 삭제 엔드포인트](../../api/project_members.md#remove-a-direct-member-of-a-project)에 대한 요청을 위한 속도 제한을 구성합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

속도 제한을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Members API rate limit**을 확장합니다.
1. **그룹/프로젝트별 분당 최대 요청 수** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

속도 제한:

- 기본값은 분당 60개 요청입니다.
- 각 프로젝트 및 사용자에게 적용됩니다.
- `0`로 설정하여 속도 제한을 비활성화할 수 있습니다.

속도 제한을 초과한 요청은 `auth.log` 파일에 기록됩니다.

예를 들어, 60의 제한을 설정하면, 분당 60개 요청을 초과하는 API 엔드포인트 요청이 차단됩니다. 엔드포인트에 대한 액세스는 1분 후에 재개됩니다.

## 프로젝트 멤버 목록 조회에 대한 속도 제한 구성 {#configure-rate-limits-on-listing-project-members}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/578527)되었습니다.

{{< /history >}}

[프로젝트 멤버 목록 엔드포인트](../../api/project_members.md#list-all-members-of-a-project)에 대한 요청을 위한 속도 제한을 구성합니다.

`GET /projects/:id/members/all`과 `GET /groups/:id/members/all` API 엔드포인트 모두 동일한 속도 제한 구성을 공유합니다. 프로젝트 엔드포인트에 속도 제한을 설정하면, 속도 제한이 그룹 엔드포인트에도 적용됩니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

속도 제한을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **프로젝트 API 속도 제한**을 확장합니다.
1. **`GET /projects/:id/members/all` API에 대한 분당 최대 요청 수 (사용자 또는 IP 주소별)** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

속도 제한:

- 기본값은 분당 200개 요청입니다.
- 각 프로젝트 및 사용자에게 적용됩니다.
- `0`로 설정하여 속도 제한을 비활성화할 수 있습니다.

속도 제한을 초과한 요청은 `auth.log` 파일에 기록됩니다.

예를 들어, 200의 제한을 설정하면, 분당 200개 요청을 초과하는 API 엔드포인트 요청이 차단됩니다. 엔드포인트에 대한 액세스는 1분 후에 재개됩니다.
