---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 에이전트 모드 채팅을 사용하여 복잡한 질문에 답변하고 파일을 자동으로 만들거나 편집합니다.
title: GitLab Duo 에이전트 모드 채팅
---

{{< details >}}

- 계층:  [무료](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../duo_agent_platform/model_selection.md#default-models)
- [자가 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- VS Code [GitLab.com에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917) 은 GitLab 18.1에서 [실험](../../policy/development_stages_support.md) 기능으로 [플래그](../../administration/feature_flags/_index.md) `duo_agentic_chat`를 사용하여 진행되었습니다. 기본적으로 비활성화됨.
- VS Code [GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688)은 GitLab 18.2입니다.
- GitLab UI [GitLab.com 및 GitLab Self-Managed에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/546140) 은 GitLab 18.2에서 [플래그](../../administration/feature_flags/_index.md) `duo_workflow_workhorse` 및 `duo_workflow_web_chat_mutation_tools`로 진행됩니다. 두 플래그 모두 기본적으로 활성화됩니다.
- 기능 플래그 `duo_agentic_chat`은 GitLab 18.2에서 기본적으로 활성화되었습니다.
- JetBrains IDE [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077)은 GitLab 18.2입니다.
- GitLab 18.2에서 베타로 변경되었습니다.
- Visual Studio for Windows [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/245)은 GitLab 18.3입니다.
- [추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)은 GitLab 18.3에서 GitLab Duo Core에 추가되었습니다.
- 기능 플래그 `duo_workflow_workhorse` 및 `duo_workflow_web_chat_mutation_tools` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198487)은 GitLab 18.4입니다.
- [도입된](https://gitlab.com/groups/gitlab-org/-/epics/19213) GitLab Duo Agent Platform을 GitLab Self-Managed에 도입했습니다([자체 호스팅 모델](../../administration/gitlab_duo_self_hosted/_index.md) 및 클라우드 연결 GitLab 모델 포함). GitLab 18.4에서 [실험](../../policy/development_stages_support.md#experiment) 기능으로 [기능 플래그](../../administration/feature_flags/_index.md) `self_hosted_agent_platform`로 진행됩니다. 기본적으로 비활성화됨.
- GitLab Self-Managed의 GitLab Duo Agent Platform이 GitLab 18.5에서 실험에서 [베타](https://gitlab.com/groups/gitlab-org/-/epics/19402)로 변경되었습니다.
- [기본 LLM 업데이트됨](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541)을 Claude Sonnet 4.5로 GitLab 18.6에서 업데이트되었습니다.
- 기능 플래그 `self_hosted_agent_platform`이 GitLab 18.7에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)되었습니다.
- [기본 LLM 업데이트됨](https://gitlab.com/groups/gitlab-org/-/epics/19998)을 Claude Haiku 4.5로 GitLab 18.7에서 업데이트되었습니다.
- [일반적으로 이용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/581872) 은 GitLab 18.8에서 [플래그](../../administration/feature_flags/_index.md) `agentic_chat_ga` 및 `ai_duo_agent_platform_ga_rollout_self_managed`로 진행됩니다. 두 플래그 모두 기본적으로 활성화됩니다. 기능 플래그 `duo_agentic_chat` 제거됨.
- 기능 플래그 [`self_hosted_agent_platform`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589) , [`agentic_chat_ga`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219679) , 및 [`ai_duo_agent_platform_ga_rollout_self_managed`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219679)는 GitLab 18.10에서 제거되었습니다.
- GitLab 18.10에서 GitLab.com의 무료 티어에서 GitLab Credits를 사용하여 사용 가능합니다.

{{< /history >}}

GitLab Duo 에이전트 모드 채팅은 GitLab Duo 비에이전트 모드 채팅의 향상된 버전입니다. 이 새로운 채팅은 당신을 대신하여 자동으로 작업을 수행하여 복잡한 질문에 더 포괄적으로 답변할 수 있습니다.

비에이전트 모드 채팅이 단일 컨텍스트를 기반으로 질문에 답변하는 동안, 에이전트 모드 채팅은 GitLab 프로젝트 전체에서 여러 소스의 정보를 검색, 검색 및 결합하여 더 철저하고 관련성 있는 답변을 제공합니다.

에이전트 모드 채팅을 할 수 있습니다:

- 프로젝트를 검색하여 키워드 기반 검색(의미론적 검색 아님)을 사용하여 관련 이슈, 머지 리퀘스트 및 기타 아티팩트를 찾습니다.
- 파일 경로를 수동으로 지정하지 않고 로컬 프로젝트의 파일에 접근합니다.
- 여러 위치에서 파일을 만들고 편집합니다.
- 이슈, 머지 리퀘스트 및 CI/CD 파이프라인과 같은 리소스를 검색합니다.
- 완전한 답변을 제공하기 위해 여러 소스를 분석합니다. [Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md)을 사용하여 외부 데이터 소스 및 도구에 연결합니다.
- 사용자 지정 규칙을 사용하여 맞춤형 응답을 제공합니다.
- GitLab UI에서 채팅을 사용할 때 커밋을 만듭니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [GitLab Duo Chat (에이전트 모드)](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)를 참조하세요.
<!-- Video published on 2025-06-02 -->

## GitLab Duo Chat 사용 {#use-gitlab-duo-chat}

다음에서 GitLab Duo Chat을 사용할 수 있습니다:

- GitLab UI.
- VS Code.
- JetBrains IDE.
- Visual Studio for Windows.

### GitLab UI에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- Chat이 최근 대화를 기억하는 기능 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203653)은 GitLab 18.4입니다.
- 새로운 네비게이션 및 GitLab Duo 사이드바가 GitLab 18.6에서 GitLab.com에 도입되었으며 [플래그](../../administration/feature_flags/_index.md) `paneled_view`로 진행됩니다. 기본적으로 활성화됨.
- 이전 네비게이션 지침이 GitLab 18.7에서 제거되었습니다.
- 새로운 네비게이션 및 GitLab Duo 사이드바 [일반적으로 이용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/574049)은 GitLab 18.8입니다. 기능 플래그 `paneled_view` 제거됨.

{{< /history >}}

전제 조건:

- [GitLab Duo Agent Platform 필수 조건](../duo_agent_platform/_index.md#prerequisites)을 충족하세요.
- [기본 GitLab Duo 네임스페이스](../profile/preferences.md#set-a-default-gitlab-duo-namespace)를 설정하세요.

GitLab UI에서 Chat을 사용하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. GitLab Duo 사이드바에서 **새 채팅 추가**({{< icon name="pencil-square" >}}) 또는 **현재 GitLab Duo 채팅**({{< icon name="duo-chat" >}})을 선택합니다.

   새 채팅을 선택한 경우 드롭다운 목록에서 에이전트를 선택합니다.

   Chat 대화가 화면 오른쪽의 GitLab Duo 사이드바에서 열립니다.
1. 채팅 텍스트 상자 아래에서 **에이전트 모드** 토글이 켜져 있는지 확인하세요.
1. 채팅 텍스트 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **전송**을 선택합니다.
   - 채팅을 위해 추가 [컨텍스트](../duo_agent_platform/context.md#gitlab-duo-agentic-chat)를 제공할 수 있습니다.
   - 대화형 AI 채팅이 답변을 생성하는 데 몇 초가 걸릴 수 있습니다.
1. 선택사항. 다음을 할 수 있습니다:
   - 후속 질문을 합니다.
   - [다른 대화](#have-multiple-conversations)를 시작합니다.

액세스하는 웹페이지를 다시 로드하거나 다른 웹페이지로 이동하면 Chat이 최근 대화를 기억하고 해당 대화는 Chat 드로어에서 여전히 활성 상태입니다.

### VS Code에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-vs-code}

전제 조건:

- [GitLab for VS Code 확장 설치 및 구성](../../editor_extensions/visual_studio_code/setup.md) 버전 6.15.1 이상.
- [GitLab Duo Agent Platform 필수 조건](../duo_agent_platform/_index.md#prerequisites)을 충족하세요.
- [기본 GitLab Duo 네임스페이스](../profile/preferences.md#set-a-default-gitlab-duo-namespace)를 설정하세요.

GitLab Duo Chat 켜기:

1. VS Code에서 설정 편집기를 엽니다:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. **Extensions** > **GitLab** > **GitLab Duo**를 선택합니다.
1. **GitLab › Duo Agent Platform: 아래: 활성화**, **Enable GitLab Duo Agent Platform** 체크박스를 선택합니다.

GitLab Duo Chat을 사용하려면:

1. 왼쪽 사이드바에서 **GitLab Duo 에이전트 플랫폼**({{< icon name="duo-agentic-chat" >}})을 선택합니다.
1. **채팅** 탭을 선택합니다.
1. 메시지가 표시되면 **Refresh page**을 선택합니다.
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **전송**을 선택합니다.

### JetBrains IDE에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-jetbrains-ides}

전제 조건:

- [JetBrains IDE용 GitLab Duo 플러그인 설치 및 구성](../../editor_extensions/jetbrains_ide/setup.md) 버전 3.11.1 이상.
- [GitLab Duo Agent Platform 필수 조건](../duo_agent_platform/_index.md#prerequisites)을 충족하세요.
- [기본 GitLab Duo 네임스페이스](../profile/preferences.md#set-a-default-gitlab-duo-namespace)를 설정하세요.

GitLab Duo Chat 켜기:

1. JetBrains IDE에서 **설정** > **도구** > **GitLab Duo**로 이동합니다.
1. **GitLab Duo 에이전트 플랫폼** 아래에서 **Enable GitLab Duo Agent Platform** 체크박스를 선택합니다.
1. 메시지가 표시되면 IDE를 다시 시작합니다.

GitLab Duo Chat을 사용하려면:

1. 오른쪽 도구 창 막대에서 **GitLab Duo 에이전트 플랫폼**({{< icon name="duo-agentic-chat" >}})을 선택합니다.
1. **채팅** 탭을 선택합니다.
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **전송**을 선택합니다.

### Visual Studio에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-visual-studio}

전제 조건:

- [GitLab for Visual Studio 확장 설치 및 구성](../../editor_extensions/visual_studio/setup.md) 버전 0.60.0 이상.
- [GitLab Duo Agent Platform 필수 조건](../duo_agent_platform/_index.md#prerequisites)을 충족하세요.
- [기본 GitLab Duo 네임스페이스](../profile/preferences.md#set-a-default-gitlab-duo-namespace)를 설정하세요.

GitLab Duo Chat 켜기:

1. Visual Studio에서 **도구** > **옵션** > **GitLab**으로 이동합니다.
1. **GitLab** 아래에서 **일반**을 선택합니다.
1. **Enable Agentic Duo Chat**의 경우 **True**를 선택한 다음 **확인**을 선택합니다.

GitLab Duo Chat을 사용하려면:

1. **Extensions** > **GitLab** > **Open Agentic Chat**를 선택합니다.
1. 메시지 상자에 질문을 입력하고 **Enter**를 누릅니다.

## 채팅 이력 보기 {#view-the-chat-history}

{{< history >}}

- Chat 이력 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/17922)은 GitLab 18.2의 IDE에서 도입되었습니다.
- [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)은 GitLab 18.3에서 GitLab UI에 추가되었습니다.

{{< /history >}}

채팅 이력을 보려면:

- GitLab UI의 GitLab Duo 사이드바에서 **GitLab Duo 채팅 이력**({{< icon name="history" >}})을 선택합니다.

- IDE에서 메시지 상자의 오른쪽 위 모서리에서 **채팅 이력**({{< icon name="history" >}})을 선택합니다.

GitLab UI에서 채팅 이력의 모든 대화가 표시됩니다.

IDE에서 마지막 20개 대화가 표시됩니다. [이슈 1308](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1308)은 이것을 변경하기를 제안합니다.

## 여러 대화 진행 {#have-multiple-conversations}

{{< history >}}

- 여러 대화 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)은 GitLab 18.3입니다.
- GitLab UI에서 채팅 이력에 대한 검색 기능 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/582513)은 GitLab 18.9입니다.

{{< /history >}}

GitLab Duo Chat과 무제한의 동시 대화를 진행할 수 있습니다.

GitLab UI 및 IDE의 GitLab Duo Chat에서 대화를 동기화합니다.

1. GitLab UI 또는 IDE에서 GitLab Duo Chat을 엽니다.
1. 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **전송**을 선택합니다.
1. 새 Chat 대화 만들기:

   - GitLab UI에서 다음 중 하나를 수행할 수 있습니다:

     - 특정 에이전트와 새 대화를 만들려면:
       1. GitLab Duo 사이드바에서 **새 채팅 추가**({{< icon name="pencil-square" >}})을 선택합니다.
       1. 드롭다운 목록에서 에이전트를 선택합니다.
     - 기존 대화와 동일한 에이전트로 새 대화를 만들려면 메시지 상자에 `/new`을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **전송**을 선택합니다.

     새 Chat 대화가 기존 대화를 대체합니다.
   - Chat 텍스트 상자 아래에서 **에이전트 모드** 토글이 켜져 있는지 확인하세요.
   - IDE에서 메시지 상자의 오른쪽 위 모서리에서 **새 채팅**({{< icon name="plus" >}})을 선택합니다.
1. 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **전송**을 선택합니다.
1. 모든 대화를 보려면 [채팅 이력](#view-the-chat-history)을 봅니다.
1. 대화 간에 전환하려면 채팅 이력에서 해당 대화를 선택합니다.
1. 채팅 이력에서 특정 대화를 검색하려면:
   - GitLab UI:  **스레드 검색** 텍스트 상자에 검색어를 입력합니다.
   - IDE:  **채팅 검색** 텍스트 상자에 검색어를 입력합니다.

LLM 컨텍스트 창 제한으로 인해 대화가 각 200,000개 토큰(대략 800,000자)으로 잘립니다.

## 대화 삭제 {#delete-a-conversation}

{{< history >}}

- 대화를 삭제하는 기능 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/545289)은 GitLab 18.2입니다.

{{< /history >}}

1. GitLab UI 또는 IDE에서 [채팅 이력](#view-the-chat-history)을 선택합니다.
1. 이력에서 **이 채팅 삭제**({{< icon name="remove" >}})을 선택합니다.

개별 대화는 30일의 비활성 후에 자동으로 만료되고 삭제됩니다.

## 로컬 환경에서 GitLab Duo Chat 사용자 지정 {#customize-gitlab-duo-chat-in-your-local-environment}

코딩 스타일, 팀 관행 및 프로젝트 요구 사항을 반영하는 지침을 제공하여 로컬 환경에서 GitLab Duo Chat이 동작하는 방식을 사용자 지정합니다.

GitLab Duo Chat은 두 가지 접근 방식을 지원합니다:

- [사용자 지정 규칙](../duo_agent_platform/customize/custom_rules.md) `chat-rules.md`에서:  GitLab만 해당. 개인 설정 및 팀 표준에 가장 적합합니다.
- [`AGENTS.md`의 공유 규칙](../duo_agent_platform/customize/agents_md.md):  `AGENTS.md` 사양을 지원하는 GitLab 및 기타 AI 도구용입니다. 프로젝트 컨텍스트, monorepo 조직 및 디렉터리별 규칙에 가장 적합합니다.

두 파일을 동시에 사용할 수 있습니다. GitLab Duo Chat은 사용 가능한 모든 규칙 파일의 지침을 적용합니다.

[GitLab Duo 사용자 지정](../duo_agent_platform/customize/_index.md) 방법에 대해 자세히 알아봅니다.

## 모델 선택 {#select-a-model}

{{< details >}}

- 제공:  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/19251) 은 GitLab 18.4에서 [베타](../../policy/development_stages_support.md#beta) 기능으로 [플래그](../../administration/feature_flags/_index.md) `ai_user_model_switching`로 진행됩니다. 기본적으로 비활성화됨.
- [활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/560319)은 GitLab 18.4입니다.
- [GitLab Self-Managed에서 사용 가능](https://gitlab.com/groups/gitlab-org/-/epics/19344)은 GitLab 18.6입니다.
- [추가됨](https://gitlab.com/groups/gitlab-org/-/epics/19345)은 GitLab 18.6에서 VS Code 및 JetBrains IDE에 추가되었습니다.
- 기능 플래그 `ai_user_model_switching` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214042) GitLab 18.7에서.
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/569140)합니다.

{{< /history >}}

GitLab UI, VS Code 또는 JetBrains IDE에서 Chat을 사용할 때 대화에 사용할 모델을 선택할 수 있습니다.

채팅 이력에서 이전 채팅을 열고 해당 대화를 계속하면 Chat이 이전에 선택한 모델을 사용합니다.

기존 대화에서 새 모델을 선택하면 Chat이 새 대화를 만듭니다.

전제 조건:

{{< tabs >}}

{{< tab title=GitLab.com >}}

- 최상위 그룹의 소유자가 GitLab Duo Agent Platform의 모델을 선택하지 않았습니다. [그룹에 모델이 선택되었으면](../gitlab_duo/model_selection.md) Chat의 모델을 변경할 수 없습니다.
- 최상위 그룹에서 Chat을 사용해야 합니다. 조직에서 Chat에 액세스하는 경우 모델을 변경할 수 없습니다.

{{< /tab >}}

{{< tab title="Self-managed" >}}

- 관리자가 인스턴스의 모델을 선택하지 않았습니다. 인스턴스에 대해 모델이 선택된 경우 Chat의 모델을 변경할 수 없습니다.
- 인스턴스가 GitLab AI Gateway에 연결되어야 합니다.

{{< /tab >}}

{{< /tabs >}}

모델을 선택하려면:

- GitLab UI에서:
  1. 채팅 텍스트 상자 아래에서 **에이전트 모드** 토글이 켜져 있는지 확인하세요.
  1. 드롭다운 목록에서 모델을 선택합니다.
- IDE에서:
  1. 사이드바에서 **GitLab Duo 에이전트 플랫폼**({{< icon name="duo-agentic-chat" >}})을 선택합니다.
  1. **채팅** 탭을 선택합니다.
  1. 드롭다운 목록에서 모델을 선택합니다.

## 에이전트 선택 {#select-an-agent}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/562708)은 GitLab 18.4입니다.
- [추가됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2196)은 GitLab 18.5에서 VS Code 및 JetBrains IDE에 추가되었습니다.

{{< /history >}}

GitLab UI, VS Code 또는 JetBrains IDE의 프로젝트에서 Chat을 사용할 때 Chat에서 사용할 특정 에이전트를 선택할 수 있습니다.

전제 조건:

- 프로젝트에서 [AI 카탈로그의 에이전트를 활성화해야 합니다](../duo_agent_platform/agents/custom.md#enable-an-agent).
- 에이전트가 활성화되어 있는 프로젝트의 구성원이어야 합니다.
- VS Code의 경우 [GitLab for VS Code 확장 설치 및 구성](../../editor_extensions/visual_studio_code/setup.md) 버전 6.49.12 이상.
- JetBrains IDE의 경우 [JetBrains IDE용 GitLab Duo 플러그인 설치 및 구성](../../editor_extensions/jetbrains_ide/setup.md) 버전 3.22.0 이상.

에이전트를 선택하려면:

1. GitLab UI 또는 IDE에서 GitLab Duo Chat의 새 대화를 엽니다.
1. GitLab UI에서 Chat 텍스트 상자 아래에서 **에이전트 모드** 토글이 켜져 있는지 확인하세요.
1. 드롭다운 목록에서 에이전트를 선택합니다. 에이전트를 설정하지 않은 경우 드롭다운 목록이 없으며 Chat은 기본 GitLab Duo 에이전트를 사용합니다.
1. 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **전송**을 선택합니다.

에이전트와의 대화를 만든 후:

- 대화가 선택한 에이전트를 기억합니다. 해당 대화에 대해 다른 에이전트를 선택할 수 없습니다.
- 채팅 이력을 사용하여 동일한 대화로 돌아가면 동일한 에이전트를 사용합니다.
- 대화로 돌아가서 관련 에이전트를 더 이상 사용할 수 없는 경우 해당 대화를 계속할 수 없습니다.

## 프롬프트 캐싱 {#prompt-caching}

{{< history >}}

- GitLab 18.7에서 도입되었습니다.

{{< /history >}}

프롬프트 캐싱은 기본적으로 활성화되어 있으며 선택된 에이전트 모드 Chat 모델이 Anthropic에서 가져온 경우 또는 Vertex를 통해 제공되는 Anthropic 모델인 경우에만 작동합니다.

프롬프트 캐싱이 활성화되면 Chat 프롬프트 데이터는 모델 공급업체에 의해 메모리에 일시적으로 저장됩니다.

프롬프트 캐싱은 캐시된 프롬프트 및 입력 데이터의 재처리를 피함으로써 지연 시간을 크게 개선합니다.

[프롬프트 캐싱을 끄면](../gitlab_duo/data_usage.md#turn-off-prompt-caching):

- GitLab.com에서:  최상위 그룹의 경우.
- GitLab Self-Managed에서:  인스턴스의 경우.

이 설정은 모든 GitLab Duo Agent Platform 기능에 적용됩니다.

## 도구 승인 {#tool-approvals}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/20519)은 GitLab 19.0입니다
  - [GitLab for VS Code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.72.0) 6.72.0에서 도입됨
  - [JetBrains IDE용 GitLab Duo 플러그인](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases/v3.33.0) 3.33.0에서 도입됨
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0에서 도입됨.

{{< /history >}}

에이전트 모드 Chat이 당신을 대신하여 도구를 사용하기 전에 당신의 승인이 필요합니다. 기본적으로 각 도구 호출에는 승인이 필요합니다.

도구를 신뢰하고 워크플로우를 간소화하려면 전체 세션 동안 한 번만 승인할 수 있습니다.

세션 승인은 Chat에만 적용되며 플로우에는 적용되지 않습니다.

### 도구 승인 관리 {#manage-tool-approvals}

소유자 및 관리자는 사용자가 세션 동안 도구를 승인할 수 있는지 여부를 제어할 수 있습니다. 설정은 인스턴스에서 그룹으로 프로젝트로 계단식으로 적용됩니다.

그룹 또는 인스턴스에 대해 다음 옵션 중 하나를 구성합니다:

- **기본적으로 켜짐**:  사용자는 세션 동안 도구를 한 번 승인할 수 있습니다. 그룹 및 하위 그룹은 이를 끌 수 있습니다.
- **기본적으로 꺼짐**: (기본값) 사용자는 각 도구 호출을 승인해야 합니다. 그룹 및 하위 그룹은 이를 켤 수 있습니다.
- **항상 꺼짐**:  사용자는 세션 동안 도구를 승인할 수 없습니다. 그룹 및 하위 그룹은 이 설정을 재정의할 수 없습니다.

#### 기본 설정 관리 {#manage-default-settings}

인스턴스 또는 최상위 그룹에 대한 기본 도구 승인 설정을 구성합니다.

{{< tabs >}}

{{< tab title="GitLab.com" >}}

전제 조건:

- 최상위 그룹의 소유자 역할.

기본 도구 승인 설정을 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **세션에 대한 도구 사용 승인** 드롭다운 목록에서 선호하는 옵션을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

전제 조건:

- 관리자 액세스.

기본 도구 승인 설정을 구성하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. **GitLab Duo**를 선택합니다.
1. **세션에 대한 도구 사용 승인** 드롭다운 목록에서 선호하는 옵션을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab Dedicated" >}}

전제 조건:

- 관리자 액세스.

기본 도구 승인 설정을 구성하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. **GitLab Duo**를 선택합니다.
1. **세션에 대한 도구 사용 승인** 드롭다운 목록에서 선호하는 옵션을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

#### 그룹 또는 프로젝트 설정 관리 {#manage-group-or-project-settings}

특정 그룹 또는 프로젝트에 대한 도구 승인 설정을 구성합니다.

전제 조건:

- 그룹의 소유자 역할 또는 프로젝트의 유지 관리자 역할.

도구 승인 설정을 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹 또는 프로젝트를 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. 그룹의 경우 **세션에 대한 도구 사용 승인** 드롭다운 목록에서 선호하는 옵션을 선택합니다.
1. 프로젝트의 경우 **세션에 대한 도구 사용 승인** 체크박스를 선택하거나 선택을 취소합니다.

### 로컬 환경에서 도구 승인 {#approve-tools-in-your-local-environment}

전제 조건:

- 도구 승인이 그룹 또는 인스턴스에 대해 켜져 있습니다.
- 로컬 환경의 GitLab Duo Chat의 경우 다음 중 하나를 설치하고 구성합니다:
  - [GitLab for VS Code](../../editor_extensions/visual_studio_code/setup.md) 6.72.0 이상.
  - [JetBrains IDE용 GitLab Duo 플러그인](../../editor_extensions/jetbrains_ide/setup.md) 3.33.0 이상.
  - [GitLab Duo CLI](../gitlab_duo_cli/_index.md) 8.80.0 이상.

현재 세션에 대한 도구를 승인하려면:

1. 도구 승인 메시지가 나타나면 승인 버튼 옆의 드롭다운을 선택합니다.
1. **Approve for Session**을 선택합니다.

승인은 Chat 세션의 나머지 동안 유지되며 새 대화를 시작할 때 재설정됩니다.

## Chat 기능 비교 {#chat-feature-comparison}

| 기능                                              | GitLab Duo 비에이전트 모드 Chat |                                                         GitLab Duo 에이전트 모드 채팅                                                                                                           |
| ------------                                            |------|                                                         -------------                                                                                                          |
| 일반 프로그래밍 질문 물어보기 |                       예  |                                                          예                                                                                                                   |
| 편집기에서 열린 파일에 대한 답변 얻기 |     예  |                                                          예. 질문에서 파일의 경로를 제공합니다.                                                                   |
| 지정된 파일에 대한 컨텍스트 제공 |                   예. `/include`을 사용하여 대화에 파일을 추가합니다. <sup>1</sup> |        예. 질문에서 파일의 경로를 제공합니다.                                                                   |
| 자동으로 프로젝트 컨텐츠 검색 |                    아니요 |                                                            예                                                                                                                   |
| 자동으로 파일 만들기 및 파일 변경 |              아니요 |                                                            예. 파일을 변경하도록 요청합니다. 참고: 수동으로 변경했지만 아직 커밋하지 않은 변경 사항을 덮어쓸 수 있습니다.  |
| ID를 지정하지 않고 이슈 및 머지 리퀘스트 검색 |          아니요 |                                                            예. 다른 기준으로 검색합니다. 예를 들어 머지 리퀘스트 또는 이슈의 제목 또는 담당자.                                       |
| 여러 소스의 정보 결합 |               아니요 |                                                            예                                                                                                                   |
| 파이프라인 로그 분석 |                                   예. GitLab Duo Enterprise 추가 기능이 필요합니다. |                          예                                                                                                                   |
| 대화 다시 시작 |                                  예. `/new` 또는 `/reset`를 사용합니다. |                             예. `/new` 또는 UI에 있는 경우 `/reset`를 사용합니다.                                                                                       |
| 대화 삭제 |                                   예, 채팅 이력에서.|                                             예, 채팅 이력에서                                                                                                            |
| 이슈 및 머지 리퀘스트 만들기 |                                   아니요 |                                                            예                                                                                                                   |
| Git 읽기 전용 명령 사용 |                                                 아니요 |                                                            예                                                  |
| Git 쓰기 명령 사용 |                                                 아니요 |                                                            예, UI만                                                  |
| Shell 명령 실행 |                                      아니요 |                                                            예, IDE만                                                                                                        |
| MCP 도구 실행 |                                      아니요 |                                                            예, IDE만                                                                                                          |
| 세션 동안 도구 승인 |                        아니요 |                                                            예, IDE만                                                                                                          |

**각주**:

1. Web IDE에서 GitLab Duo 비에이전트 모드 Chat을 사용할 때는 사용할 수 없습니다.

## 문제 해결 {#troubleshooting}

GitLab Duo Chat을 사용할 때 이슈가 발생할 수 있습니다.

이러한 이슈를 해결하는 방법에 대한 정보는 [이슈 해결](troubleshooting.md)을 참조하세요.

## 피드백 {#feedback}

이 기능을 개선하는 데 도움이 되는 피드백은 소중합니다. [이슈 542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198)에서 경험을 공유합니다.

## 관련 항목 {#related-topics}

- [블로그: GitLab Duo Chat이 에이전트 모드 AI로 탈바꿈됨](https://about.gitlab.com/blog/gitlab-duo-chat-gets-agentic-ai-makeover/)
