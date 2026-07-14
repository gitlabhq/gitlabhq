---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 시스템 노트
description: 작업 항목에 대한 시스템 생성 활동 노트를 추적하고 확인합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

시스템 노트는 다음과 같은 GitLab 객체의 수명 주기 동안 발생하는 이벤트의 이력을 이해하는 데 도움이 되는 짧은 설명입니다.

- [알림](../../operations/incident_management/alerts.md).
- [디자인](issues/design_management.md).
- [이슈](issues/_index.md).
- [머지 리퀘스트](merge_requests/_index.md).
- [OKR](../okrs.md) (목표와 핵심 결과).
- [작업](../tasks.md).

GitLab은 Git 또는 GitLab 애플리케이션에 의해 트리거된 이벤트에 대한 정보를 시스템 노트에 기록합니다. 시스템 노트는 `<Author> <action> <time ago>` 형식을 사용합니다.

## 시스템 노트 표시 또는 필터링 {#show-or-filter-system-notes}

기본적으로 시스템 노트는 표시되지 않습니다. 표시될 때는 가장 오래된 것부터 순서대로 표시됩니다. 필터 또는 정렬 옵션을 변경하면 선택 사항이 섹션 전체에 걸쳐 기억됩니다. 머지 리퀘스트를 제외한 모든 항목 유형에 대한 필터링 옵션은 다음과 같습니다.

- **모든 활동 보기**는 댓글과 이력을 모두 표시합니다.
- **댓글만 보기**는 시스템 노트를 숨깁니다.
- **이력만 표시**는 사용자 댓글을 숨깁니다.

머지 리퀘스트는 더 세밀한 필터링 옵션을 제공합니다.

### 에픽 {#on-an-epic}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택합니다.
1. 필터 바에서 필터 **유형**, 연산자 **다음과 같음**, 값 **에픽**을 선택합니다.
1. 원하는 에픽을 찾고 제목을 선택합니다.
1. **활동** 섹션으로 이동합니다.
1. **정렬 또는 필터링**을 클릭하고 **모든 활동 보기**를 선택합니다.

### 이슈 {#on-an-issue}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택한 후 **유형** = **이슈**로 필터링하고 이슈를 선택합니다.
1. **활동**으로 이동합니다.
1. **정렬 또는 필터링**을 클릭하고 **모든 활동 보기**를 선택합니다.

### 머지 리퀘스트 {#on-a-merge-request}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. **활동**으로 이동합니다.
1. **정렬 또는 필터링**을 클릭하고 **모든 활동 보기**를 선택하여 모든 시스템 노트를 확인합니다. 반환된 시스템 노트의 유형을 좁히려면 다음 중 하나 이상을 선택합니다.

   - **승인**
   - **담당자 및 검토자**
   - **댓글**
   - **커밋 및 브랜치**
   - **편집**
   - **레이블**
   - **잠금 상태**
   - **언급**
   - **머지 리퀘스트 상태**
   - **추적**

## 개인정보 보호 고려사항 {#privacy-considerations}

액세스할 수 있는 객체에 연결된 시스템 노트만 확인할 수 있습니다.

예를 들어 누군가 자신의 비공개 프로젝트의 이슈에서 이슈 111을 언급한 경우:

- 프로젝트 멤버는 이슈 111에서 다음 노트를 볼 수 있습니다. `Alex Garcia mentioned in agarcia/private-project#222`.
- 프로젝트의 비멤버는 노트를 볼 수 없습니다.

## 관련 항목 {#related-topics}

- [메모 API](../../api/notes.md)
