---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 메모 생성에 대한 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

메모 생성 엔드포인트에 대한 요청에 대해 사용자별 속도 제한을 구성할 수 있습니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

메모 생성 속도 제한을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Notes rate limit**을 확장합니다.
1. **분당 최대 요청** 상자에 새 값을 입력합니다.
1. 선택사항. **속도 제한에서 제외할 사용자** 상자에 제한을 초과할 수 있는 사용자를 나열합니다.
1. **변경 사항 저장**을 선택합니다.

이 제한은 다음과 같습니다:

- 사용자별로 독립적으로 적용됩니다.
- IP 주소별로 적용되지 않습니다.

기본값은 `300`입니다.

속도 제한을 초과하는 요청은 `auth.log` 파일에 기록됩니다.

예를 들어 제한을 300으로 설정한 경우 [`Projects::NotesController#create`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/notes_controller.rb) 작업을 사용하여 분당 300을 초과하는 요청은 차단됩니다. 1분 후 엔드포인트에 대한 액세스가 허용됩니다.
