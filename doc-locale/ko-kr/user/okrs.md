---
stage: Plan
group: Portfolio Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "목표와 핵심 결과(OKR)를 생성, 편집 및 유지합니다."
title: 목표와 핵심 결과(OKR)
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.6에서 [소개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103355)됨 [기능 플래그](../administration/feature_flags/_index.md)와 함께 명명됨 `okrs_mvc`. 기본적으로 사용 중지됩니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용은 준비되지 않았습니다.

[목표와 핵심 결과](https://en.wikipedia.org/wiki/OKR)(OKR)는 조직의 전체 전략 및 비전에 맞춘 목표를 설정하고 추적하기 위한 프레임워크입니다.

GitLab의 목표와 핵심 결과는 많은 기능을 공유합니다. 문서에서 **OKR** 용어는 목표와 핵심 결과를 모두 나타냅니다.

OKR은 작업 항목의 유형이며 GitLab의 [기본 이슈 유형](https://gitlab.com/gitlab-org/gitlab/-/issues/323404)을 향한 한 단계입니다. [이슈](project/issues/_index.md) 및 [에픽](group/epics/_index.md)을 작업 항목으로 마이그레이션하고 사용자 지정 작업 항목 유형을 추가하기 위한 로드맵은 [에픽 6033](https://gitlab.com/groups/gitlab-org/-/work_items/6033) 또는 [계획 방향 페이지](https://about.gitlab.com/direction/plan/)를 참조하세요.

## 효과적인 OKR 설계 {#designing-effective-okrs}

목표와 핵심 결과를 사용하여 워크포스를 공통 목표에 맞추고 진행률을 추적합니다. 목표로 큰 목표를 설정하고 [하위 목표 및 핵심 결과](#child-objectives-and-key-results)를 사용하여 큰 목표의 완료를 측정합니다.

목표는 달성할 원대한 목표이며 무엇을 목표로 하는지 정의합니다. 이는 개인, 팀 또는 부서의 작업이 조직의 전체 방향에 미치는 영향을 보여주며, 작업을 회사 전체 전략과 연결합니다.

**핵심 결과**는 정렬된 목표에 대한 진행률의 척도입니다. 목표(목표)에 도달했는지 여부를 아는 방법을 나타냅니다. 특정 결과(핵심 결과)를 달성함으로써 연결된 목표에 대한 진행률을 만듭니다.

OKR이 타당한지 알기 위해 이 문장을 사용할 수 있습니다:

<!-- vale gitlab_base.FutureTense = NO -->
> 나/우리는 다음 메트릭(핵심 결과)을 달성함으로써 (목표)을(를) (날짜)까지 달성할 것입니다.
<!-- vale gitlab_base.FutureTense = YES -->

더 나은 OKR을 만드는 방법과 GitLab에서 이를 사용하는 방법을 알아보려면 [목표 및 핵심 결과 핸드북 페이지](https://handbook.gitlab.com/handbook/company/okrs/)를 참조하세요.

## 목표 생성 {#create-an-objective}

목표를 생성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택합니다.
1. 오른쪽 위 모서리에서 **새 항목**을 선택합니다.
1. **유형**에 대해 **목표**를 선택합니다.
1. 목표 제목을 입력합니다.
1. **목표 생성**을 선택합니다.

핵심 결과를 생성하려면 기존 목표에 [하위 항목으로 추가](#add-a-child-key-result)하세요.

## 목표 보기 {#view-an-objective}

목표를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택합니다.
1. [작업 항목 목록 필터링](project/issues/managing_issues.md#filter-the-list-of-issues) `Type = Objective`.
1. 목록에서 목표의 제목을 선택합니다.

## 핵심 결과 보기 {#view-a-key-result}

핵심 결과를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택합니다.
1. [작업 항목 목록 필터링](project/issues/managing_issues.md#filter-the-list-of-issues) `Type = Key Result`.
1. 목록에서 핵심 결과의 제목을 선택합니다.

또는 상위 목표의 **하위 항목** 섹션에서 핵심 결과에 액세스할 수 있습니다.

## 제목 및 설명 편집 {#edit-title-and-description}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

OKR을 편집하려면:

1. [편집할 목표](#view-an-objective) 또는 [핵심 결과](#view-a-key-result)를 엽니다.
1. 선택 사항입니다. 제목을 선택하고 변경하고 제목 텍스트 상자 외부의 아무 영역이나 선택합니다.
1. 선택 사항입니다. 설명을 편집하려면 편집 아이콘({{< icon name="pencil" >}})을 선택하고 변경을 수행한 후 **저장**을 선택합니다.

## **더 읽기**로 설명 축약 방지 {#prevent-truncating-descriptions-with-read-more}

{{< history >}}

- GitLab 17.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184)되었습니다.

{{< /history >}}

OKR 설명이 긴 경우 GitLab은 일부만 표시합니다. 전체 설명을 보려면 **더 읽기**를 선택해야 합니다. 이 축약을 사용하면 긴 텍스트를 스크롤하지 않고도 페이지의 다른 요소를 더 쉽게 찾을 수 있습니다.

설명이 축약되는지 변경하려면:

1. 목표 또는 핵심 결과에서 오른쪽 위 모서리에서 **추가 작업**({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **옵션 보기**를 선택합니다.
1. 선호도에 따라 **설명 축약**을 전환합니다.

이 설정은 기억되며 모든 이슈, 작업, 에픽, 목표 및 핵심 결과에 영향을 미칩니다.

## 오른쪽 사이드바 숨기기 {#hide-the-right-sidebar}

{{< history >}}

- GitLab 17.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184)되었습니다.

{{< /history >}}

속성은 공간이 허락하면 설명의 오른쪽에 있는 사이드바에 표시됩니다. 설명 공간을 늘리려면 사이드바를 숨깁니다:

1. 목표 또는 핵심 결과에서 오른쪽 위 모서리에서 **추가 작업**({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **옵션 보기**를 선택합니다.
1. **사이드바 숨기기**를 선택합니다.

이 설정은 기억되며 모든 이슈, 작업, 에픽, 목표 및 핵심 결과에 영향을 미칩니다.

사이드바를 다시 표시하려면:

- 이전 단계를 반복하고 **사이드바 표시**를 선택합니다.

## OKR 시스템 노트 보기 {#view-okr-system-notes}

{{< history >}}

- GitLab 15.7에서 [소개](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)됨 [기능 플래그](../administration/feature_flags/_index.md)와 함께 명명됨 `work_items_mvc_2`. 기본적으로 사용 중지됩니다.
- GitLab 15.8에서 `work_items_mvc` 명명된 기능 플래그로 [이동](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)됨. 기본적으로 사용 중지됩니다.
- 기능 플래그 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144141) `work_items_mvc`에서 `work_items_beta`로 GitLab 16.10에서.
- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.
- 기능 플래그 `work_items_beta`이 GitLab 18.6에서 [제거](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17549)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

OKR과 관련된 모든 [시스템 노트](project/system_notes.md)를 볼 수 있습니다. 기본적으로 **가장 오래된 것부터**로 정렬됩니다. 정렬 순서를 **최신순**로 항상 변경할 수 있으며 이는 세션 간에 기억됩니다.

## 댓글 및 스레드 {#comments-and-threads}

OKR에서 [댓글](discussions/_index.md)을 추가하고 스레드에 응답할 수 있습니다.

## 사용자 할당 {#assign-users}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

OKR에 대해 누가 책임이 있는지 표시하기 위해 사용자를 할당할 수 있습니다.

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

OKR에서 담당자를 변경하려면:

1. [편집할 목표](#view-an-objective) 또는 [핵심 결과](#view-a-key-result)를 엽니다.
1. **담당자** 옆에서 **담당자 추가**를 선택합니다.
1. 드롭다운 목록에서 담당자로 추가할 사용자를 선택합니다.
1. 드롭다운 목록 외부의 모든 영역을 선택합니다.

## 라벨 할당 {#assign-labels}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

[라벨](project/labels.md)을 사용하여 팀 간에 OKR을 정리합니다.

OKR에 라벨을 추가하려면:

1. [편집할 목표](#view-an-objective) 또는 [핵심 결과](#view-a-key-result)를 엽니다.
1. **라벨** 옆에서 **라벨 추가**를 선택합니다.
1. 드롭다운 목록에서 추가할 라벨을 선택합니다.
1. 드롭다운 목록 외부의 모든 영역을 선택합니다.

## 마일스톤에 목표 추가 {#add-an-objective-to-a-milestone}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

[마일스톤](project/milestones/_index.md)에 목표를 추가할 수 있습니다. 목표를 볼 때 마일스톤 제목을 볼 수 있습니다.

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

마일스톤에 목표를 추가하려면:

1. [편집할 목표](#view-an-objective)를 엽니다.
1. **마일스톤** 옆에서 **마일스톤에 추가**를 선택합니다. 목표가 이미 마일스톤에 속하면 드롭다운 목록은 현재 마일스톤을 표시합니다.
1. 드롭다운 목록에서 목표와 연결할 마일스톤을 선택합니다.

## 진행률 설정 {#set-progress}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

목표를 달성하기 위해 필요한 작업 중 얼마나 많은 부분이 완료되었는지 보여줍니다.

목표 및 핵심 결과에 대해 수동으로 진행률을 설정할 수 있습니다.

하위 항목에 대한 진행률을 입력하면 계층 구조의 모든 상위 항목의 진행률이 하위 항목의 진행률 평균으로 업데이트됩니다. 모든 레벨에서 진행률을 재정의하고 값을 수동으로 입력할 수 있지만, 하위 항목의 진행률 값이 업데이트되면 자동화가 평균을 표시하기 위해 모든 상위 항목을 다시 업데이트합니다.

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

목표 또는 핵심 결과의 진행률을 설정하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택합니다.
1. [작업 항목 목록 필터링](project/issues/managing_issues.md#filter-the-list-of-issues) `Type = Objective` 또는 `Type = Key Result` 및 항목을 선택합니다.
1. **진행률** 옆에서 텍스트 상자를 선택합니다.
1. 0에서 100 사이의 숫자를 입력합니다.

## 헬스 체크 상태 설정 {#set-health-status}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

목표 달성의 위험을 더 잘 추적하기 위해 각 목표 및 핵심 결과에 [헬스 체크 상태](project/issues/managing_issues.md#health-status)를 할당할 수 있습니다. 헬스 체크 상태를 사용하여 조직의 다른 사람들에게 OKR이 계획대로 진행 중인지 또는 일정에 맞게 유지하려면 주의가 필요한지 신호를 보낼 수 있습니다.

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

OKR의 헬스 체크 상태를 설정하려면:

1. [편집할 핵심 결과](#view-a-key-result)를 엽니다.
1. **헬스 체크 상태** 옆에서 드롭다운 목록을 선택하고 원하는 헬스 체크 상태를 선택합니다.

## 핵심 결과를 목표로 승격 {#promote-a-key-result-to-an-objective}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

핵심 결과를 승격하려면:

1. [핵심 결과를 엽니다](#view-a-key-result).
1. 오른쪽 위 모서리에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. **목표로 승격**을 선택합니다.

또는 [`/promote_to objective` 빠른 작업](project/quick_actions.md#promote_to)을 사용합니다.

## OKR을 다른 항목 유형으로 변환 {#convert-an-okr-to-another-item-type}

{{< history >}}

- GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/385131)되었으며 [기능 플래그](../administration/feature_flags/_index.md)라고 명명되어 `work_items_beta`입니다. 기본적으로 사용 중지됩니다.
- [이동](https://gitlab.com/gitlab-org/gitlab/-/issues/385131) [플래그](../administration/feature_flags/_index.md)로 명명되어 `okrs_mvc`입니다. 현재 플래그 상태는 이 페이지의 맨 위를 참조하세요.

{{< /history >}}

목표 또는 핵심 결과를 다음과 같은 다른 항목 유형으로 변환합니다:

- 이슈
- 작업
- 목표
- 핵심 결과

> [!warning]
> 유형을 변경하면 대상 유형이 원본 유형의 모든 필드를 지원하지 않는 경우 데이터 손실이 발생할 수 있습니다.

사전 요구 사항:

- 변환하려는 OKR에는 상위 항목이 할당되지 않아야 합니다.
- 변환하려는 OKR에 하위 항목이 없어야 합니다.

OKR을 다른 항목 유형으로 변환하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택한 후 이슈를 선택하여 봅니다.
1. 목록에서 목표 또는 핵심 결과를 찾아 선택합니다.
1. 오른쪽 위 모서리에서 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택한 다음 **유형 변경**을 선택합니다.
1. 원하는 항목 유형을 선택합니다.
1. 모든 조건이 충족되면 **유형 변경**을 선택합니다.

또는 [`/type` 빠른 작업](project/quick_actions.md#type)을 사용할 수 있으며, 그 다음에 주석에 `issue`, `task`, `objective` 또는 `key result`을 입력합니다.

## 목표 또는 핵심 결과 참조 복사 {#copy-objective-or-key-result-reference}

GitLab의 다른 곳에서 목표 또는 핵심 결과를 참조하려면 전체 URL 또는 `namespace/project-name#123`처럼 보이는 짧은 참조를 사용할 수 있습니다. 여기서 `namespace`는 그룹 또는 사용자 이름입니다.

목표 또는 핵심 결과 참조를 클립보드에 복사하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택한 후 목표 또는 핵심 결과를 선택하여 봅니다.
1. 오른쪽 위 모서리에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 후 **참조 복사**를 선택합니다.

이제 참조를 다른 설명이나 댓글로 붙여넣을 수 있습니다.

[GitLab 맛 Markdown](markdown.md#gitlab-specific-references)에서 목표 또는 핵심 결과 참조에 대해 자세히 알아보세요.

## 목표 또는 핵심 결과 이메일 주소 복사 {#copy-objective-or-key-result-email-address}

이메일을 전송하여 목표 또는 핵심 결과에 댓글을 만들 수 있습니다. 이 주소로 이메일을 보내면 이메일 본문을 포함하는 댓글이 생성됩니다.

이메일로 댓글을 생성하고 필요한 구성에 대한 자세한 내용은 [이메일을 보내 댓글에 답글 달기](discussions/_index.md#reply-to-a-comment-by-sending-email)를 참조하세요.

목표 또는 핵심 결과의 이메일 주소를 복사하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택한 후 목표를 선택하여 봅니다.
1. 오른쪽 위 모서리에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 후 **목표 이메일 주소 복사** 또는 **핵심 결과 이메일 주소 복사**를 선택합니다.

## OKR 닫기 {#close-an-okr}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

OKR이 달성되면 닫을 수 있습니다. OKR은 닫힘으로 표시되지만 삭제되지는 않습니다.

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

OKR을 닫으려면:

1. [편집할 목표](#view-an-objective)를 엽니다.
1. **상태** 옆에서 **닫힘**을 선택합니다.

같은 방식으로 닫힌 OKR을 다시 열 수 있습니다.

## 하위 목표 및 핵심 결과 {#child-objectives-and-key-results}

GitLab에서 목표는 핵심 결과와 유사합니다. 워크플로우에서 핵심 결과를 사용하여 목표에 설명된 목표를 측정합니다.

총 9개 레벨까지 하위 목표를 추가할 수 있습니다. 목표는 최대 100개의 하위 OKR을 가질 수 있습니다. 핵심 결과는 목표의 하위이며 자신의 하위 항목을 가질 수 없습니다.

하위 목표 및 핵심 결과는 목표 설명 아래의 **하위 항목** 섹션에서 사용할 수 있습니다.

### 하위 목표 추가 {#add-a-child-objective}

{{< history >}}

- 목표를 생성할 프로젝트를 선택하는 기능은 GitLab 17.1에서 [소개](https://gitlab.com/gitlab-org/gitlab/-/issues/436255)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 게스트, 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

목표에 새로운 목표를 추가하려면:

1. 목표에서 **하위 항목** 섹션에서 **추가**를 선택한 후 **새 목표**를 선택합니다.
1. 새 목표의 제목을 입력합니다.
1. 새 목표를 생성할 [프로젝트](project/organize_work_with_projects.md)를 선택합니다.
1. **목표 생성**을 선택합니다.

기존 목표를 목표에 추가하려면:

1. 목표에서 **하위 항목** 섹션에서 **추가**를 선택한 후 **기존 목표**를 선택합니다.
1. 제목의 일부를 입력하여 원하는 목표를 검색한 후 원하는 항목을 선택합니다.

   여러 목표를 추가하려면 이 단계를 반복합니다.
1. **목표 추가**를 선택합니다.

### 하위 핵심 결과 추가 {#add-a-child-key-result}

{{< history >}}

- 핵심 결과를 생성할 프로젝트를 선택하는 기능은 GitLab 17.1에서 [소개](https://gitlab.com/gitlab-org/gitlab/-/issues/436255)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 게스트, 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

목표에 새로운 핵심 결과를 추가하려면:

1. 목표에서 **하위 항목** 섹션에서 **추가**를 선택한 후 **새 핵심 결과**를 선택합니다.
1. 새 핵심 결과의 제목을 입력합니다.
1. 새 핵심 결과를 생성할 [프로젝트](project/organize_work_with_projects.md)를 선택합니다.
1. **핵심 결과 생성**을 선택합니다.

기존 핵심 결과를 목표에 추가하려면:

1. 목표에서 **하위 항목** 섹션에서 **추가**를 선택한 후 **기존 핵심 결과**를 선택합니다.
1. 제목의 일부를 입력하여 원하는 OKR을 검색한 후 원하는 항목을 선택합니다.

   여러 목표를 추가하려면 이 단계를 반복합니다.
1. **핵심 결과 추가**를 선택합니다.

### 목표 및 핵심 결과 하위 항목 재정렬 {#reorder-objective-and-key-result-children}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

기본적으로 하위 OKR은 생성 날짜로 정렬됩니다. 순서를 바꾸려면 끌어다놓으세요.

### OKR 체크인 알림 예약 {#schedule-okr-check-in-reminders}

{{< history >}}

- GitLab 16.4에서 `okr_checkin_reminders` [기능 플래그](../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/422761)되었습니다. 기본적으로 사용 중지됩니다.
- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용은 준비되지 않았습니다.

팀에게 중요한 핵심 결과에 대한 상태 업데이트를 제공하도록 상기시키기 위해 체크인 알림을 예약합니다. 알림은 후손 객체 및 핵심 결과의 모든 담당자에게 이메일 알림 및 할 일 항목으로 전송됩니다. 사용자는 이메일 알림 구독을 취소할 수 없지만 체크인 알림은 끌 수 있습니다. 알림은 화요일에 전송됩니다.

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.
- 프로젝트에 최소 하나의 핵심 결과가 있는 최소 하나의 목표가 있어야 합니다.
- 최상위 목표에 대해서만 알림을 예약할 수 있습니다. 하위 목표에 대한 체크인 알림 예약은 효과가 없습니다. 최상위 목표의 설정은 모든 하위 목표에 상속됩니다.

목표에 대한 반복 알림을 예약하려면 새 댓글에서 [`/checkin_reminder` 빠른 작업](project/quick_actions.md#checkin_reminder)을 사용합니다.

## 목표를 상위로 설정 {#set-an-objective-as-a-parent}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.
- 상위 목표와 하위 OKR은 동일한 프로젝트에 속해야 합니다.

목표를 OKR의 상위로 설정하려면:

1. [편집할 목표](#view-an-objective) 또는 [핵심 결과](#view-a-key-result)를 엽니다.
1. **상위** 옆에서 드롭다운 목록에서 추가할 상위를 선택합니다.
1. 드롭다운 목록 외부의 모든 영역을 선택합니다.

목표 또는 핵심 결과의 상위를 제거하려면 **상위** 옆에서 드롭다운 목록을 선택한 후 **할당취소**를 선택합니다.

## 비공개 OKR {#confidential-okrs}

비공개 OKR은 [충분한 권한](#who-can-see-confidential-okrs)이 있는 프로젝트의 구성원에게만 표시되는 OKR입니다. 비공개 OKR을 사용하여 보안 취약점을 비공개로 유지하거나 놀라운 일이 유출되는 것을 방지할 수 있습니다.

### OKR 비공개 활성화 {#make-an-okr-confidential}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

기본적으로 OKR은 공개입니다. OKR을 생성하거나 편집할 때 비공개로 만들 수 있습니다.

#### 새로운 OKR에서 {#in-a-new-okr}

새로운 목표를 생성할 때 OKR을 비공개로 표시할 수 있는 확인란이 텍스트 영역 바로 아래에 있습니다.

해당 확인란을 선택한 후 **목표 생성** 또는 **핵심 결과 생성**을 선택하여 OKR을 생성합니다.

#### 기존 OKR에서 {#in-an-existing-okr}

사전 요구 사항:

- 프로젝트의 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.
- **비공개 목표**는 [비공개 하위 목표 또는 핵심 결과](#child-objectives-and-key-results)만 가질 수 있습니다:
  - 목표를 비공개로 만들려면: 하위 목표 또는 핵심 결과가 있으면 먼저 모두 비공개로 만들거나 제거해야 합니다.
  - 목표를 공개로 만들려면: 하위 목표 또는 핵심 결과가 있으면 먼저 모두 공개로 만들거나 제거해야 합니다.
  - 비공개 목표에 하위 목표 또는 핵심 결과를 추가하려면 먼저 비공개로 만들어야 합니다.

기존 OKR의 비공개성을 변경하려면:

1. [편집할 목표](#view-an-objective) 또는 [핵심 결과](#view-a-key-result)를 엽니다.
1. 오른쪽 위 모서리에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. **비공개 활성화** 또는 **비공개 해제**를 선택합니다.

### 비공개 OKR을 볼 수 있는 사용자 {#who-can-see-confidential-okrs}

{{< history >}}

- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.

{{< /history >}}

OKR이 비공개로 설정되면 프로젝트의 플래너, Reporter, Developer, Maintainer 또는 Owner 역할이 있는 사용자만 OKR에 액세스할 수 있습니다. 게스트 또는 [최소](permissions.md#users-with-minimal-access) 역할의 사용자는 변경 전에 적극적으로 참여하고 있었더라도 OKR에 액세스할 수 없습니다.

그러나 게스트 역할을 가진 사용자는 비공개 OKR을 만들 수 있지만 자신이 만든 OKR만 볼 수 있습니다.

게스트 역할 또는 비회원인 사용자는 OKR에 할당된 경우 비공개 OKR을 읽을 수 있습니다. 게스트 사용자 또는 비회원이 비공개 OKR에서 할당이 해제되면 더 이상 볼 수 없습니다.

비공개 OKR은 필요한 권한이 없는 사용자의 검색 결과에서 숨겨집니다.

### 비공개 OKR 표시기 {#confidential-okr-indicators}

비공개 OKR은 일반 OKR과 시각적으로 여러 방면에서 다릅니다. OKR이 나열된 모든 곳에서 비공개로 표시된 OKR 옆에 비공개({{< icon name="eye-slash" >}}) 아이콘을 볼 수 있습니다.

[충분한 권한](#who-can-see-confidential-okrs)이 없으면 비공개 OKR을 전혀 볼 수 없습니다.

마찬가지로 OKR 내부에 있을 때 이동 경로 바로 옆에 비공개({{< icon name="eye-slash" >}}) 아이콘을 볼 수 있습니다.

공개에서 비공개로 또는 그 반대로의 모든 변경은 OKR의 댓글에 있는 시스템 노트로 표시됩니다. 예를 들어:

- {{< icon name="eye-slash" >}} Jo Garcia가 5분 전 이슈를 기밀로 설정했습니다.
- {{< icon name="eye" >}} Jo Garcia가 방금 이슈를 모두에게 공개했습니다.

## 토론 잠금 {#lock-discussion}

{{< history >}}

- GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/398649)되었으며 [기능 플래그](../administration/feature_flags/_index.md)라고 명명되어 `work_items_beta`입니다. 기본적으로 사용 중지됩니다.
- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다.
- 기능 플래그 `work_items_beta`이 GitLab 18.6에서 [제거](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17549)되었습니다.

{{< /history >}}

OKR의 공개 댓글을 방지할 수 있습니다. 그렇게 하면 프로젝트 구성원만 댓글을 추가하고 편집할 수 있습니다.

사전 요구 사항:

- 플래너, Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

OKR을 잠그려면:

1. 오른쪽 위 모서리에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. **토론 잠금**을 선택합니다.

시스템 노트가 페이지 세부 정보에 추가됩니다.

OKR이 잠금된 토론과 함께 닫혀있으면 토론을 잠금 해제할 때까지 다시 열 수 없습니다.

## OKR의 링크된 항목 {#linked-items-in-okrs}

{{< history >}}

- `linked_work_items`이라는 [기능 플래그](../administration/feature_flags/_index.md)로 GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/416558)되었습니다. 기본적으로 사용으로 설정됩니다.
- GitLab 16.7에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139394)됨.
- GitLab 17.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150148)합니다. 기능 플래그 `linked_work_items`이 제거되었습니다.
- GitLab 17.0에서 최소 필수 역할이 리포터(참인 경우)에서 게스트로 [변경](https://gitlab.com/groups/gitlab-org/-/work_items/10267)되었습니다.

{{< /history >}}

링크된 항목은 양방향 관계이며 하위 목표 및 핵심 결과 아래의 블록에 나타납니다. 같은 프로젝트의 목표, 핵심 결과 또는 작업을 서로 연결할 수 있습니다.

사용자가 두 항목을 볼 수 있는 경우에만 관계가 UI에 나타납니다.

### 연결된 항목 추가 {#add-a-linked-item}

사전 요구 사항:

- 프로젝트의 게스트, 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

목표 또는 핵심 결과에 항목을 링크하려면:

1. 목표 또는 핵심 결과의 **링크된 항목** 섹션에서 **추가**를 선택합니다.
1. 두 항목 사이의 관계를 선택합니다. 다음 중 하나를 선택합니다.
   - **다음과 관련**
   - **차단**
   - **차단됨**
1. 항목의 검색 텍스트, URL 또는 참조 ID를 입력합니다.
1. 연결할 모든 항목을 추가한 경우 검색 상자 아래에서 **추가**를 선택합니다.

모든 연결된 항목 추가를 완료한 경우 분류된 항목을 보아 관계를 시각적으로 더 잘 이해할 수 있습니다.

![작업 항목이 차단, 차단됨 또는 관련된 것으로 분류되고 진행률을 시각화하는 상태 표시기 및 종속성이 있습니다.](img/linked_items_list_v16_5.png)

### 연결된 항목 제거 {#remove-a-linked-item}

사전 요구 사항:

- 프로젝트의 게스트, 플래너, 리포터, 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다.

목표 또는 핵심 결과의 **링크된 항목** 섹션에서 각 항목 옆의 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 후 **삭제**를 선택합니다.

양방향 관계 때문에 관계가 더 이상 항목 중 하나에도 나타나지 않습니다.
