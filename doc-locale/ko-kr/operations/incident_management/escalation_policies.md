---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab에서 에스컬레이션 정책을 만들고, 편집하고, 삭제하여 중요한 경고를 올바르게 처리하고 온콜 담당자에게 라우팅하는 방법을 알아봅니다."
title: 에스컬레이션 정책
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

에스컬레이션 정책은 회사를 놓친 중요한 경고로부터 보호합니다. 에스컬레이션 정책은 이전 단계의 담당자가 응답하지 않은 경우 에스컬레이션 단계에서 다음 담당자에게 자동으로 페이지를 전송하는 시간 제한이 있는 단계를 포함합니다. [온콜 일정](oncall_schedules.md)을 관리하는 GitLab 프로젝트에서 에스컬레이션 정책을 만들 수 있습니다.

## 에스컬레이션 정책 추가 {#add-an-escalation-policy}

전제 조건:

- Maintainer 또는 Owner 역할이 있어야 합니다.
- [온콜 일정](oncall_schedules.md)이 있어야 합니다.

에스컬레이션 정책을 만들려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **에스컬레이션 정책**을 선택합니다.
1. **에스컬레이션 정책 추가**를 선택합니다.
1. 정책의 이름과 설명을 입력하고 기본 담당자가 경고를 놓칠 때 따를 에스컬레이션 규칙을 입력합니다.
1. **에스컬레이션 정책 추가**를 선택합니다.

![에스컬레이션 정책](img/escalation_policy_v14_1.png)

### 에스컬레이션 규칙의 담당자 선택 {#select-the-responder-of-an-escalation-rule}

에스컬레이션 규칙을 구성할 때 페이지할 사람을 지정할 수 있습니다:

- **일정에 따라 온콜 사용자에게 이메일 보내기**: 규칙이 트리거될 때 온콜 상태인 사용자에게 알림을 보내고 지정된 [온콜 일정](oncall_schedules.md)에서 모든 로테이션을 커버합니다.
- **이메일 사용자**: 지정된 사용자에게 직접 알림을 보냅니다.

온콜 일정 또는 직접을 통해 사용자에게 알림을 보낼 때 페이지된 사용자를 나열하는 시스템 노트가 경고에 생성됩니다.

에스컬레이션 규칙에 지정된 시간은 0분과 1440분 사이여야 합니다.

## 에스컬레이션 정책 편집 {#edit-an-escalation-policy}

에스컬레이션 정책을 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **에스컬레이션 정책**을 선택합니다.
1. **에스컬레이션 정책 편집** ({{< icon name="pencil" >}})을 선택합니다.
1. 정보를 편집합니다.
1. **변경사항 저장**을 선택합니다.

## 에스컬레이션 정책 삭제 {#delete-an-escalation-policy}

에스컬레이션 정책을 삭제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **에스컬레이션 정책**을 선택합니다.
1. **에스컬레이션 정책 삭제** ({{< icon name="remove" >}})을 선택합니다.
1. 확인 대화 상자에서 **에스컬레이션 정책 삭제**를 선택합니다.
