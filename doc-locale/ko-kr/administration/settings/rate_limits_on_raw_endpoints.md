---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 원시 끝점의 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- 인증되지 않은 원시 Blob 요청 분당 속도 제한 [GitLab 18.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/226344)

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

두 가지 속도 제한 설정이 원시 끝점에 대한 액세스를 제어합니다:

- **분당 원시 Blob 요청 속도 제한**:  각 프로젝트 및 파일 경로에 대한 요청을 제한합니다. 기본값은 `300`분당 요청입니다.
- **Raw blob request rate limit per minute (unauthenticated)**:  각 프로젝트의 모든 파일 경로에서 인증되지 않은 요청을 제한합니다. 기본값은 `800`분당 요청입니다.

이러한 설정을 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **성능 최적화**를 확장합니다.

![분당 원시 Blob 요청 속도 제한이 300과 800으로 설정되어 있습니다.](img/rate_limits_on_raw_endpoints_v18_10.png)

예를 들어 경로 기반 제한이 `300`인 경우 분당 `300` 이상의 요청이 `https://gitlab.com/gitlab-org/gitlab-foss/raw/master/app/controllers/application_controller.rb`로 차단됩니다. 원시 파일에 대한 액세스는 1분 후에 릴리스됩니다.

경로 기반 제한은:

- 각 프로젝트 및 파일 경로에 대해 독립적으로 적용됩니다.
- IP 주소 또는 사용자별로 적용되지 않습니다.
- 기본적으로 활성화됩니다. 비활성화하려면 옵션을 `0`로 설정합니다.

인증되지 않은 프로젝트 전체 제한은:

- 각 프로젝트에서 모든 파일 경로에 적용되며 인증되지 않은 요청에만 적용됩니다.
- 인증된 사용자에게는 적용되지 않습니다.
- IP 주소당 적용되지 않습니다.
- 기본적으로 활성화됩니다. 비활성화하려면 옵션을 `0`로 설정합니다.

속도 제한을 초과하는 요청은 `auth.log`에 기록됩니다.
