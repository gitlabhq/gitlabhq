---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 플로우 크리에이터
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/22644)되었습니다.

{{< /history >}}

Flow Creator는 [사용자 지정 플로우](../../flows/custom.md)를 AI 카탈로그에 대해 만들도록 도와주는 전문화된 AI 에이전트입니다. 원하는 플로우를 일반 언어로 설명하면 AI 카탈로그에서 사용할 수 있는 완전한 플로우 YAML을 에이전트가 생성합니다.

에이전트는 컴포넌트, 트리거, 입력 및 라우팅을 포함한 플로우 레지스트리 프레임워크를 이해합니다. 응답하기 전에 라이브 프레임워크 설명서를 조사하므로 응답이 고정된 스냅숏이 아닌 프레임워크의 현재 기능을 반영합니다.

플로우 크리에이터가 필요한 경우:

- 플로우 만들기: 플로우가 수행해야 하는 작업과 트리거되는 방식에 대한 설명에서 완전한 플로우 YAML을 생성합니다.
- 플로우 디버깅: 기존 플로우 구성이 유효성 검사에 실패하거나 예상대로 작동하지 않는 이유를 파악합니다.
- 프레임워크 이해: 사용 가능한 컴포넌트, 매개변수 및 트리거를 파악하고 이를 함께 연결하는 방법을 배웁니다.

## 플로우 크리에이터 사용 {#use-the-flow-creator}

사전 요구 사항:

- 기본 에이전트를 [활성화](_index.md#turn-foundational-agents-on-or-off)합니다.

GitLab UI에서 플로우 크리에이터를 사용하려면 다음을 수행합니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. GitLab Duo 사이드바에서 **새 채팅 추가**({{< icon name="pencil-square" >}})를 선택합니다.
1. 드롭다운 목록에서 **Flow Creator**를 선택합니다.

   화면 오른쪽의 GitLab Duo 사이드바에서 Chat 대화창이 열립니다.
1. 만들려는 플로우를 설명합니다. 최적의 결과를 얻으려면 다음을 수행합니다.

   - 플로우를 트리거해야 하는 조건을 설명합니다. 예를 들어 이슈에 할당 또는 새로운 병합 요청 만들기입니다.
   - 필요하다고 생각하는 컴포넌트가 아닌 원하는 결과를 설명합니다. 에이전트가 적절한 컴포넌트를 선택합니다.
   - 디버깅할 때는 전체 플로우 YAML을 붙여넣어 에이전트가 프레임워크 규칙에 따라 유효성을 검사하도록 합니다.
1. 에이전트의 응답에서 플로우 YAML을 복사한 다음 플로우를 만들 수 있는 권한이 있는 프로젝트의 [새 플로우](../../flows/custom.md) 화면에 붙여넣습니다.

## 프롬프트 예시 {#example-prompts}

- 플로우 만들기:
  - 이슈에 할당될 때 이슈를 요약하는 플로우를 만듭니다.
  - 이슈 설명을 기반으로 새 이슈에 레이블을 추가하는 플로우를 만듭니다.
  - 병합 요청에 댓글을 달기 전에 승인을 요청하는 플로우를 만듭니다.
- 플로우 디버깅:
  - 이 플로우 구성이 유효성 검사에 실패하는 이유는 무엇입니까? `<flow YAML>`
  - 이 플로우는 실행을 멈추지 않습니다. 문제가 무엇입니까? `<flow YAML>`"
- 플로우 작동 방식 이해:
  - 브랜치 이름을 내 플로우에 전달하려면 어떻게 해야 합니까?
  - 플로우의 중간에 사용자에게 입력을 요청하는 데 사용할 컴포넌트는 어느 것입니까?

## 알려진 이슈 {#known-issues}

- 에이전트는 플로우 레지스트리 v1 스키마에만 YAML을 생성합니다.
- 에이전트는 응답하기 전에 프레임워크 설명서를 읽습니다. 결과적으로 응답이 다른 에이전트의 응답보다 오래 걸릴 수 있습니다.
