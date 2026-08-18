---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 프로젝트에서 플로우가 실행되는 시점을 제어하는 트리거를 생성하고 관리합니다.
title: 트리거
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `ai_flow_triggers`라는 이름의 [플래그와 함께](../../../administration/feature_flags/_index.md) GitLab 18.3에 도입됨. 기본적으로 활성화됨.
- `ai_catalog_create_third_party_flows`라는 이름의 추가 [플래그](../../../administration/feature_flags/_index.md)를 요구하도록 GitLab 18.8에서 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634). 기본적으로 비활성화됨.
- GitLab 18.8에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273).

{{< /history >}}

> [!flag]
> 플로우 구성 파일의 위치를 변경하려면 기능 플래그를 활성화해야 합니다. 자세한 내용은 이력을 참조하세요.

트리거는 플로우 또는 외부 에이전트가 실행되는 시점을 결정합니다. 트리거는 사용자 지정 에이전트 또는 기본 에이전트에 대해 생성될 수 없습니다.

예를 들어, 토론에서 언급하거나 검토자(reviewer)로 할당할 때 플로우가 트리거되도록 지정할 수 있습니다.

## 트리거 생성 {#create-a-trigger}

{{< history >}}

- **Assign** 및 **Assign reviewer** 이벤트 유형이 GitLab 18.5에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/567787).
- 파이프라인 이벤트 트리거 이벤트 유형이 `ai_flow_trigger_pipeline_hooks`라는 이름의 [플래그](../../../administration/feature_flags/_index.md)를 사용하는 [실험적 기능](../../../policy/development_stages_support.md)으로 GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797). 기본적으로 비활성화됨.
- `merge_request_ready_flow_trigger`라는 이름의 [플래그](../../../administration/feature_flags/_index.md)와 함께 GitLab 19.0에 **Merge request ready** 트리거 이벤트 유형이 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454). 기본적으로 비활성화됨.
- **Merge request code conflict** 트리거 이벤트 유형은 [GitLab 19.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234044)되었습니다.
- **머지 리퀘스트** 트리거 이벤트 유형과 **승인됨** 작업이 [GitLab 19.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237081)되었습니다.
- 기능 플래그 `ai_flow_trigger_pipeline_hooks`이(가) GitLab 19.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/work_items/587272)되었습니다.
- **Work item created** 트리거 이벤트 유형이 [GitLab 19.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/599985)되었습니다.
- **Merge request ready** 트리거 이벤트 유형이 GitLab 19.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/598421)합니다. 기능 플래그 `merge_request_ready_flow_trigger`이 제거되었습니다.
- **Work item status changed** 트리거 이벤트 유형이 [GitLab 19.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/599983)되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

트리거를 생성하려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **AI** > **Triggers**를 선택합니다.
1. **New flow trigger**를 선택합니다.
1. **Description**에 트리거에 대한 설명을 입력합니다.
1. **Event types** 드롭다운 목록에서 하나 이상의 이벤트 유형을 선택합니다.
   - **Mention (언급)**: 서비스 계정 사용자가 이슈 또는 머지 리퀘스트의 댓글에서 언급될 때입니다.
   - **Assign (할당)**: 서비스 계정 사용자가 이슈 또는 머지 리퀘스트에 할당될 때입니다.
   - **Assign reviewer (검토자 지정)**: 서비스 계정 사용자가 머지 리퀘스트의 검토자로 할당될 때입니다.
   - **Pipeline events (파이프라인 이벤트)**: 파이프라인 상태가 변경될 때입니다.
   - **Merge request ready (머지 리퀘스트 준비 완료)**: 초안 머지 리퀘스트가 검토 준비 완료로 표시될 때입니다.
   - **머지 리퀘스트 코드 충돌**: 코드 충돌로 인해 머지 리퀘스트를 더 이상 병합할 수 없을 때입니다.
   - **머지 리퀘스트**: 선택한 머지 리퀨스트 작업이 발생할 때입니다.
   - **작업 항목**: 선택한 작업 항목 작업이 발생할 때입니다.
1. 선택 사항. **파이프라인 이벤트**를 선택한 경우, **Pipeline events configuration** 섹션의 **Trigger when** 드롭다운 목록에서 다음 상태 중 하나 이상을 선택합니다: **실행중**, **통과됨**, **실패함**, 또는 **취소됨**.
1. 선택 사항. **머지 리퀘스트**를 선택한 경우, **Merge request events configuration** 섹션의 **Trigger when** 드롭다운 목록에서 **승인됨**을 선택합니다.
1. 선택 사항. **작업 항목**을 선택한 경우, **Work item events configuration** 섹션의 **Trigger when** 드롭다운 목록에서 다음 상태 중 하나 이상을 선택합니다: **생성됨**, **Status changed**.
1. **Service account** 드롭다운 목록에서 [복합 ID(composite identity)](../composite_identity.md)가 될 사용자를 선택합니다.
1. **Configuration source**에서 다음 중 하나를 선택합니다.
   - **AI Catalog (AI 카탈로그)**: 이 프로젝트에 대해 구성된 플로우 중에서 트리거가 실행할 플로우를 선택합니다.
   - **Configuration path (구성 경로)**: 플로우 구성 파일의 경로를 입력합니다(예: `.gitlab/duo/flows/claude.yaml`). 이 옵션을 확인하려면 `ai_catalog_create_third_party_flows` 기능 플래그를 활성화해야 합니다.
1. **Create flow trigger**를 선택합니다.

이제 트리거가 **AI** > **Triggers**에 표시됩니다.

### 트리거 편집 {#edit-a-trigger}

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **AI** > **Triggers**를 선택합니다.
1. 변경하려는 트리거에서 **Edit flow trigger** ({{< icon name="pencil" >}})를 선택합니다.
1. 변경 사항을 적용하고 **Save changes**를 선택합니다.

### 트리거 삭제 {#delete-a-trigger}

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **AI** > **Triggers**를 선택합니다.
1. 삭제하려는 트리거에서 **Delete flow trigger** ({{< icon name="remove" >}})를 선택합니다.
1. 확인 대화 상자에서 **OK**를 선택합니다.
