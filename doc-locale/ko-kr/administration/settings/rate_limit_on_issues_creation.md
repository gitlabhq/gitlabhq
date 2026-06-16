---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 이슈 및 에픽 생성의 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

속도 제한은 새로운 에픽과 이슈를 생성할 수 있는 속도를 제어합니다. 예를 들어 제한을 `300`로 설정하면 [`Projects::IssuesController#create`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/controllers/projects/issues_controller.rb) 작업은 분당 300을 초과하는 요청을 차단합니다. 엔드포인트에 대한 액세스는 1분 후에 사용 가능합니다.

## 속도 제한 설정 {#set-the-rate-limit}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

이슈 및 에픽 생성 엔드포인트에 대한 요청 수를 제한하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Issues Rate Limits**을 확장합니다.
1. **Max requests per minute** 아래에 새 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

![사용자당 분당 최대 요청 수 속도 제한을 300으로 설정합니다.](img/rate_limit_on_issues_creation_v14_2.png)

[에픽](../../user/group/epics/_index.md) 생성의 제한은 이슈 생성에 적용된 것과 동일한 제한입니다. 속도 제한:

- 프로젝트 및 사용자별로 독립적으로 적용됩니다.
- IP 주소당 적용되지 않습니다.
- 속도 제한을 비활성화하려면 `0`로 설정할 수 있습니다.

속도 제한을 초과하는 요청은 `auth.log` 파일에 기록됩니다.
