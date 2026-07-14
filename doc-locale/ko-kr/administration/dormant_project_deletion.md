---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 휴면 프로젝트 삭제
description: 휴면 프로젝트 삭제를 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) 되었으며, [플래그](feature_flags/_index.md)는 `inactive_projects_deletion`로 이름 지정됩니다. 기본적으로 비활성화됨.
- [기능 플래그 `inactive_projects_deletion`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803)는 GitLab 15.4에서 제거되었습니다.
- GitLab UI를 통한 구성은 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85575)되었습니다.
- GitLab 18.1에서 비활성 프로젝트 삭제로부터 [이름이 변경](https://gitlab.com/gitlab-org/gitlab/-/work_items/533275)되었습니다.

{{< /history >}}

시간이 지남에 따라 대규모 GitLab 인스턴스의 프로젝트는 휴면 상태가 되어 불필요한 디스크 공간을 사용할 수 있습니다.

GitLab을 구성하여 특정 기간의 비활성 후 휴면 프로젝트를 자동으로 삭제할 수 있습니다. 정의된 기간 내에 프로젝트에 활동이 없는 경우:

- 유지보수자는 예약된 삭제를 경고하는 알림을 받습니다.
- 프로젝트에서 활동이 발생하지 않으면 기간이 만료되면 GitLab이 삭제합니다.
- 삭제가 발생하면 GitLab은 @GitLab-Admin-Bot이 삭제를 수행했음을 보여주는 감사 이벤트를 생성합니다.

GitLab.com의 기본 설정은 [GitLab.com 설정](../user/gitlab_com/_index.md#dormant-project-deletion)을 참조하세요.

## 휴면 프로젝트 삭제 구성 {#configure-dormant-project-deletion}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

휴면 프로젝트 삭제를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포지토리**를 선택합니다.
1. **리포지토리 유지 보수**를 확장합니다.
1. **휴면 프로젝트 삭제** 섹션에서 **휴면 프로젝트 삭제**를 선택합니다.
1. 설정을 구성합니다.
   - 경고 이메일은 휴면 프로젝트의 소유자 및 유지보수자 역할을 가진 사용자에게 전송됩니다.
   - 이메일 기간은 **다음 프로젝트 삭제** 기간보다 작아야 합니다.
1. **변경 사항 저장**을 선택합니다.

조건을 충족하는 휴면 프로젝트는 삭제가 예약되고 경고 이메일이 전송됩니다. 프로젝트가 계속 휴면 상태인 경우 지정된 기간 후에 삭제됩니다. [프로젝트가 보관](../user/project/working_with_projects.md#archive-a-project)된 경우에도 이러한 프로젝트는 삭제됩니다.

### 구성 예시 {#configuration-example}

#### 예 1 {#example-1}

이러한 설정을 사용하는 경우:

- **휴면 프로젝트 삭제**가 활성화되었습니다.
- **초과하는 휴면 프로젝트 삭제**는 `50`로 설정됩니다.
- **다음 프로젝트 삭제**는 `12`로 설정됩니다.
- **경고 이메일 보내기**는 `6`로 설정됩니다.

프로젝트가 50MB 미만인 경우 프로젝트는 휴면으로 간주되지 않습니다.

프로젝트가 50MB 이상이고 휴면 상태인 경우:

- 6개월 이상:  삭제 경고 이메일이 전송됩니다. 이 이메일에는 프로젝트가 삭제 예약되는 날짜가 포함됩니다.
- 12개월 이상:  프로젝트는 삭제가 예약됩니다.

#### 예 2 {#example-2}

이러한 설정을 사용하는 경우:

- **휴면 프로젝트 삭제**가 활성화되었습니다.
- **초과하는 휴면 프로젝트 삭제**는 `0`로 설정됩니다.
- **다음 프로젝트 삭제**는 `12`로 설정됩니다.
- **경고 이메일 보내기**는 `11`로 설정됩니다.

크기 제한이 0MB로 설정되었으므로 인스턴스의 모든 프로젝트가 포함됩니다. 프로젝트가 휴면 상태인 경우:

- 11개월 이상:  삭제 경고 이메일이 전송됩니다. 이 이메일에는 프로젝트가 삭제 예약되는 날짜가 포함됩니다.
- 12개월 이상:  프로젝트는 삭제가 예약됩니다.

이러한 설정을 구성할 때 이미 12개월 이상 휴면 상태인 프로젝트가 있는 경우:

- 삭제 경고 이메일이 즉시 전송됩니다. 이 이메일에는 프로젝트가 삭제 예약되는 날짜가 포함됩니다.
- 프로젝트는 경고 이메일이 전송된 후 1개월(12개월 - 11개월) 후에 삭제가 예약됩니다.

## 프로젝트가 마지막으로 활성화된 시간 결정 {#determine-when-a-project-was-last-active}

프로젝트 활동을 보고 프로젝트가 마지막으로 활성화된 시간을 다음 방법으로 결정할 수 있습니다:

- 프로젝트에 대한 [활동 페이지](../user/project/working_with_projects.md#view-project-activity)로 이동하고 최근 이벤트의 날짜를 봅니다.
- [Projects API](../api/projects.md)를 사용하여 프로젝트의 `last_activity_at` 속성을 봅니다.
- [Events API](../api/events.md#list-all-visible-events-for-a-project)를 사용하여 프로젝트의 표시되는 이벤트를 나열합니다. 최근 이벤트의 `created_at` 속성을 봅니다.
