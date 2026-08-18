---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: GitLab 인스턴스에 대한 머지 리퀘스트 승인을 구성합니다.
title: 머지 리퀘스트 승인
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

머지 리퀘스트 승인 규칙은 사용자가 특정 프로젝트 설정을 재정의하는 것을 방지합니다. 활성화되면 이러한 설정이 인스턴스의 [모든 프로젝트 및 그룹에 적용](../user/project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)됩니다.

이러한 머지 리퀘스트 승인 설정을 전체 인스턴스에 대해 설정할 수 있습니다:

- **머지 리퀘스트 작성자의 승인 방지** 프로젝트 유지 관리자가 머지 리퀘스트 작성자가 자신의 머지 리퀘스트를 승인하도록 허용하는 것을 방지합니다.
- **커밋한 사용자의 승인 방지** 프로젝트 유지 관리자가 소스 브랜치에 커밋을 제출한 경우 사용자가 머지 리퀘스트를 승인하도록 허용하는 것을 방지합니다.
- **프로젝트 및 머지 리퀘스트에서 승인 규칙 편집 방지** 사용자가 프로젝트 설정 또는 개별 머지 리퀘스트의 승인자 목록을 수정하는 것을 방지합니다. 개별 머지 리퀘스트에서만 재정의를 방지하는 동등한 그룹 및 프로젝트 설정과는 달리, 이 인스턴스 설정은 프로젝트 설정의 승인 규칙 목록을 잠급니다.

다음도 전체 인스턴스 규칙의 영향을 받습니다:

- [프로젝트 머지 리퀘스트 승인 규칙](../user/project/merge_requests/approvals/_index.md)
- [그룹 머지 리퀘스트 승인 설정](../user/group/manage.md#group-merge-request-approval-settings)

## 인스턴스에 대한 머지 리퀘스트 승인 설정 활성화 {#enable-merge-request-approval-settings-for-an-instance}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

머지 리퀘스트 승인 설정을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **푸시 규칙**을 선택합니다.
1. **머지 리퀘스트 승인**을 펼칩니다.
1. 승인 규칙 중 하나의 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.
