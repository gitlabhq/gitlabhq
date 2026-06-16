---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 프로젝트에서 플로우가 실행되는 시점을 제어하는 트리거를 생성하고 관리합니다.
title: 트리거
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 [기능 플래그](../../../administration/feature_flags/_index.md)와 함께 도입되었으며 `ai_flow_triggers`입니다. 기본적으로 활성화됨.
- GitLab 18.8에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634) 되었으며 [기능 플래그](../../../administration/feature_flags/_index.md) `ai_catalog_create_third_party_flows`를 추가로 요구하도록 변경되었습니다. 기본적으로 비활성화됨.
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)합니다.

{{< /history >}}

> [!flag]
> 플로우 구성 파일의 위치를 변경하려면 기능 플래그를 활성화해야 합니다. 자세한 내용은 기록을 참조하세요.

트리거는 플로우 또는 외부 에이전트가 실행되는 시점을 결정합니다. 트리거는 사용자 지정 에이전트 또는 기본 에이전트에 대해 생성될 수 없습니다.

예를 들어 토론에서 언급할 때 또는 검토자로 할당할 때 플로우가 트리거되도록 지정할 수 있습니다.

## 트리거 생성 {#create-a-trigger}

{{< history >}}

- **할당** 및 **검토자 지정** 이벤트 유형이 GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)되었습니다.
- 파이프라인 이벤트 트리거 이벤트 유형이 GitLab 18.9에서 [실험](../../../policy/development_stages_support.md) 으로 [기능 플래그](../../../administration/feature_flags/_index.md) `ai_flow_trigger_pipeline_hooks` 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797)되었습니다. 기본적으로 비활성화됨.
- **머지 리퀘스트 준비 완료** 트리거 이벤트 유형이 GitLab 19.0에서 [기능 플래그](../../../administration/feature_flags/_index.md) `merge_request_ready_flow_trigger` 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454)되었습니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 기록을 참조하세요.

전제 조건:

- 프로젝트에 대한 유지보수자 또는 소유자 역할 이상이 필요합니다.

트리거를 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **AI** > **트리거**를 선택합니다.
1. **새 플로우 트리거**를 선택합니다.
1. **설명**에서 트리거에 대한 설명을 입력합니다.
1. **이벤트 유형** 드롭다운 목록에서 하나 이상의 이벤트 유형을 선택합니다:
   - **언급**:  서비스 계정 사용자가 이슈 또는 머지 리퀘스트의 댓글에서 언급될 때입니다.
   - **할당**:  서비스 계정 사용자가 이슈 또는 머지 리퀘스트에 할당될 때입니다.
   - **검토자 지정**:  서비스 계정 사용자가 머지 리퀘스트의 검토자로 할당될 때입니다.
   - **파이프라인 이벤트**:  파이프라인이 상태를 변경할 때입니다. 가능한 상태는 `created`, `started`, `succeeded`, 그리고 `failed`입니다.
   - **머지 리퀘스트 준비 완료**:  초안 머지 리퀘스트가 검토 준비 완료로 표시될 때입니다.
1. **서비스 계정** 드롭다운 목록에서 [복합 ID](../composite_identity.md)가 될 사용자를 선택합니다.
1. **구성 소스**에서 다음 중 하나를 선택합니다:
   - **AI 카탈로그**:  이 프로젝트에 대해 구성된 플로우 중에서 트리거가 실행할 플로우를 선택합니다.
   - **구성 경로**:  플로우 구성 파일의 경로를 입력합니다(예: `.gitlab/duo/flows/claude.yaml`). 이 옵션을 보려면 `ai_catalog_create_third_party_flows` 기능 플래그를 활성화해야 합니다.
1. **플로우 트리거 생성**을 선택합니다.

트리거가 이제 **AI** > **트리거**에 나타납니다.

### 트리거 편집 {#edit-a-trigger}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **AI** > **트리거**를 선택합니다.
1. 변경할 트리거에서 **플로우 트리거 편집** ({{< icon name="pencil" >}})을 선택합니다.
1. 변경 사항을 적용한 후 **변경사항 저장**을 선택합니다.

### 트리거 삭제 {#delete-a-trigger}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **AI** > **트리거**를 선택합니다.
1. 삭제할 트리거에서 **플로우 트리거 삭제** ({{< icon name="remove" >}})를 선택합니다.
1. 확인 대화상자에서 **확인**을 선택합니다.
