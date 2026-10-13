---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 코드 소유자를 머지 리퀘스트 준비가 완료되었을 때 검토자로 자동으로 할당합니다.
title: 자동 검토자 할당
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `auto_assign_code_owner_reviewers`라는 이름의 [기능 플래그](../../../../administration/feature_flags/_index.md)로 GitLab 18.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 19.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239965)합니다. 기능 플래그 `auto_assign_code_owner_reviewers`가 제거되었습니다.

{{< /history >}}

자동 검토자 할당을 활성화하면 GitLab은 변경된 파일의 [코드 소유자](../../codeowners/_index.md)를 머지 리퀘스트의 검토자로 할당합니다. `CODEOWNERS` 파일에서 검토자를 직접 선택할 필요가 없습니다.

## 전제 조건 {#prerequisites}

- 프로젝트에는 [`CODEOWNERS` 파일](../../codeowners/_index.md)이 있어야 합니다.
- 프로젝트에 대한 Maintainer 또는 Owner 역할.

## 자동 검토자 할당 활성화 {#enable-automatic-reviewer-assignment}

프로젝트의 자동 검토자 할당을 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **머지 리퀘스트**를 선택합니다.
1. **자동 검토자 할당** 섹션으로 이동합니다.
1. **모든 코드 소유자를 검토자로 자동 할당**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## GitLab이 검토자를 할당하는 시기 {#when-gitlab-assigns-reviewers}

설정을 활성화한 후 GitLab은 다음의 경우에 코드 소유자를 검토자로 할당합니다.

- 준비가 완료된 상태로 머지 리퀘스트를 생성합니다.
- 초안 머지 리퀘스트를 준비 완료로 표시합니다.

GitLab은 머지 리퀘스트에서 변경된 파일과 일치하는 모든 코드 소유자를 할당합니다.

GitLab이 자동 할당을 건너뛰는 경우:

- 머지 리퀘스트가 초안 상태입니다.
- 머지 리퀘스트에 이미 검토자가 있습니다. [`@GitLabDuo`](../duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)는 이 확인에서 제외됩니다.
- 코드 소유자가 머지 리퀘스트에서 변경된 파일과 일치하지 않습니다.
- 머지 리퀘스트 작성자에게 머지 리퀘스트 메타데이터를 설정할 권한이 없습니다.

## 추천된 검토자 플로우로 검토자 할당 {#assign-reviewers-with-the-recommend-reviewers-flow}

{{< details >}}

- 상태:  베타

{{< /details >}}

{{< history >}}

- `dap_powered_recommend_reviewers`라는 이름의 [기능 플래그](../../../../administration/feature_flags/_index.md)와 함께 GitLab 19.0에 프로젝트 설정으로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236211)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 19.4에서 프로젝트 설정 대신 플로우 트리거를 사용하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/607677)되었습니다. 기능 플래그 `dap_powered_recommend_reviewers`가 제거되었습니다.

{{< /history >}}

추천된 검토자 플로우는 머지 리퀘스트를 검토하기에 가장 적합한 검토자를 추천하고 할당합니다.

모든 코드 소유자를 할당하는 대신, 가용성, 업무량 및 시간대를 기반으로 각 승인 규칙을 충족하는 데 필요한 최소 검토자 수를 할당합니다.

이 기능은 [GitLab Duo 에이전트 플랫폼](../../../duo_agent_platform/_index.md)에서 실행됩니다.

이 플로우는 GitLab 19.3 이전 버전에서 사용된 **검토자 할당 전략** 프로젝트 설정을 대체합니다.

전제 조건:

- 최상위 그룹의 소유자 역할과 프로젝트의 유지 관리자 또는 소유자 역할입니다.
- [GitLab Duo Agent Platform의 필수 조건](../../../duo_agent_platform/_index.md#prerequisites)입니다.
- **플로우 실행 허용**, **기본 플로우 허용** 및 **추천된 검토자**를 [최상위 그룹에 대해](../../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off) 활성화합니다.

### 플로우 사용 {#use-the-flow}

추천된 검토자 플로우를 사용하려면 트리거를 생성합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **AI** > **트리거**를 선택합니다.
1. **새 플로우 트리거**를 선택합니다.
1. **설명**에 트리거에 대한 설명을 입력합니다.
1. **구성 소스**가 표시되면 **플로우 또는 외부 에이전트**를 선택한 다음 플로우 목록에서 **추천된 검토자**를 선택합니다.
1. **조건** 섹션에서:
   1. **조건 추가**를 선택한 다음 **이벤트에서**를 선택합니다.
   1. **이벤트** 드롭다운 목록에서 **머지 리퀘스트**를 선택합니다.
   1. **실행 시점** 드롭다운 목록에서 **준비됨으로 마킹**을 선택합니다.
   1. **이벤트 추가**를 선택합니다.
1. **플로우 트리거 만들기**를 선택합니다.

플로우는 개발자 역할 이상의 권한을 가진 사용자가 초안 머지 리퀘스트를 준비됨으로 마킹할 때 실행됩니다.

트리거 생성 및 편집에 대한 자세한 내용은 [트리거](../../../duo_agent_platform/triggers/_index.md)를 참조하세요.

### 예외 {#exceptions}

- 검토자는 초안 머지 리퀘스트가 준비됨으로 마킹될 때만 할당됩니다. 플로우는 머지 리퀘스트가 준비된 상태로 직접 열릴 때 검토자를 할당하지 않습니다. 자세한 내용은 [이슈 592452](https://gitlab.com/gitlab-org/gitlab/-/issues/592452)를 참조하세요.
- 머지 리퀘스트를 준비됨으로 마킹하는 사용자는 프로젝트에 대해 최소한 개발자 역할 이상이어야 합니다. 사용자가 더 낮은 역할을 가지고 있으면 플로우는 검토자를 할당하지 않습니다.

### 검토자 선택 {#reviewer-selection}

추천된 검토자 플로우는 머지 리퀘스트에서 필수 승인 규칙을 읽습니다. 각 규칙에 대해, 규칙을 충족하는 데 필요한 최소 검토자 수를 추천하고 할당합니다. 그런 다음 권장 사항을 설명하는 메모를 추가합니다. 플로우는 선택 사항인 승인 규칙을 무시합니다.

규칙에 대한 적격 승인자 중에서 선택하려면, 플로우는 각 승인자에 대해 다음을 고려합니다.

- 가용성(해당 [상태](../../../profile/_index.md#set-your-status)에 기반).
- 검토 워크로드(검토 대기 중인 열린 머지 리퀘스트의 수에 기반).
- 현지 시간(프로필의 시간대에 기반).
- 가장 최근 활동.

승인자가 없는 기본 **모든 구성원** 규칙의 경우, 플로우는 머지 리퀘스트를 승인할 수 있고 대상 브랜치로 병합할 수 있는 프로젝트의 직접 구성원 중에서 선택합니다. 어떤 역할도 대상 브랜치로 병합할 수 없는 경우, 후보는 승인할 수 있는 모든 직접 구성원입니다. 상위 그룹이나 초대된 그룹에서 액세스를 받는 구성원은 후보가 아니므로, 직접 구성원이 없는 프로젝트는 이 규칙에 대한 권장 사항을 받지 않습니다.

권장 사항이 백그라운드에서 실행되므로 검토자가 표시되는 데 약간의 시간이 걸릴 수 있습니다. 플로우는 검토자 할당 및 메모의 소유를 최상위 그룹에 대해 플로우를 활성화할 때 설정되는 [서비스 계정](../../../duo_agent_platform/flows/foundational_flows/_index.md#service-accounts)으로 지정합니다. 머지 리퀘스트를 준비됨으로 마킹한 사용자에게 귀속되지 않습니다.

## 관련 항목 {#related-topics}

- [코드 소유자](../../codeowners/_index.md)
- [머지 리퀘스트 검토](_index.md)
- [머지 리퀘스트 승인 규칙](../approvals/rules.md)
