---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab 작업 항목 및 머지 리퀘스트와 상호작용한 사용자(작성자, 담당자, 댓글을 남기거나 반응을 추가했거나 언급된 사용자 포함)."
title: 참가자
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

참가자는 작업 항목 및 머지 리퀘스트와 상호작용한 사용자입니다. 참가자에는 작성자, 담당자, 검토자(머지 리퀘스트의 경우), 그리고 댓글을 남기거나 이모지 반응을 추가했거나 댓글이나 설명에서 언급된 사용자가 포함됩니다.

참가자는 작업 항목(이슈, 작업, 에픽 등) 및 머지 리퀘스트에서 사용할 수 있습니다.

## 참가자 보기 {#view-participants}

### 작업 항목의 경우 {#for-work-items}

작업 항목의 참가자를 보려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택한 다음 작업 항목을 선택합니다.
1. 오른쪽 사이드바의 **참가자** 섹션에서 작업 항목에 참가한 모든 사용자를 봅니다.

### 머지 리퀘스트의 경우 {#for-merge-requests}

머지 리퀘스트에서 참가자를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **병합 요청**를 선택하고 병합 요청을 찾습니다.
1. 오른쪽 사이드바의 **참가자** 섹션에서 머지 리퀘스트에 참가한 모든 사용자를 봅니다.

## 참가자 가시성 및 권한 {#participant-visibility-and-permissions}

참가자 목록은 작업 항목 또는 머지 리퀘스트에 액세스할 수 있는 필요한 권한이 있는 사용자만 표시합니다:

- **기본 요구 사항** \- 사용자가 작업 항목 또는 머지 리퀘스트의 참가자로 표시되려면 읽기 권한이 필요합니다.
- **내부 메모** \- 내부 메모에서 언급된 사용자는 내부 메모를 읽을 수 있는 권한이 있는 경우에만 참가자로 표시됩니다.
- **언급이 참가자를 추가합니다** - `@username` 또는 `@team-name`와 같은 그룹 언급으로 언급된 사용자는 작업 항목 또는 머지 리퀘스트 액세스 권한이 있으면 참가자로 추가됩니다.

> [!warning]
> 그룹 언급(`@team-name` 등)은 모든 직접 그룹 멤버를 참가자로 추가합니다. `@`을 일반적인 단어와 함께 사용할 때는 주의하세요. 이는 의도하지 않게 기존 그룹을 언급할 수 있습니다.

## 참가자 및 이메일 알림 {#participants-and-email-notifications}

작업 항목 또는 머지 리퀘스트의 참가자가 되면 이메일 알림 설정에 영향을 줍니다. 이 관계를 이해하면 알림 설정을 효과적으로 관리할 수 있습니다.

참가자 상태가 알림과 관련되는 방식:

- 자동 참가: 작업 항목 또는 머지 리퀘스트에 댓글을 남기거나 편집하거나 언급되면 자동으로 참가자가 됩니다. 이는 알림 수준 설정에 따라 이메일 알림을 트리거할 수 있습니다.
- 알림 수준: 사용자의 [알림 수준](profile/notifications.md#notification-levels)은 어떤 활동이 이메일 알림을 생성하는지 결정합니다.
- 구독한 참가자: 아직 참가하지 않았더라도 작업 항목 또는 머지 리퀘스트에 대해 수동으로 [알림 구독](profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)할 수 있습니다. 이렇게 하면 참가자 목록에 추가되고 기본 알림 수준에 따라 알림이 활성화됩니다.
- 언급 알림: 누군가 댓글이나 설명에서 `@username`으로 언급하면 알림을 받고 알림 수준 설정과 관계없이 참가자가 됩니다.
- 기밀 콘텐츠: 기밀 작업 항목의 경우 적절한 권한이 있는 사용자만 참가자로 표시되고 알림을 받습니다. 자세한 내용은 [참가자 가시성 및 권한](#participant-visibility-and-permissions)을 참조하세요.

알림 설정 관리에 대한 자세한 내용은 [알림 이메일](profile/notifications.md)을 참조하세요.
