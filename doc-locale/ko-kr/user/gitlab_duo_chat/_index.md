---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Duo Chat을 사용하여 코드에 대해 질문하고, GitLab에서 도움을 받으며, GitLab UI 또는 IDE에서 작업을 완료합니다."
title: GitLab Duo Non-Agentic Chat
---

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Pro 또는 Enterprise, GitLab Duo with Amazon Q
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../gitlab_duo/model_selection.md#default-models)
- Amazon Q용 LLM: Amazon Q Developer
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6 이상에서 GitLab Duo 애드온을 요구하도록 변경되었습니다.
- GitLab 18.3에서 GitLab Duo Core에 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)되었습니다.
- GitLab 18.6에서 Claude Sonnet 4.5로 [기본 LLM이 업데이트](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541)되었습니다.
- GitLab 19.0의 일부로 2026년 5월 21일부터 GitLab Duo Core 고객을 대상으로 GitLab Duo Non-Agentic Chat 액세스가 제거됨(`no_duo_classic_for_duo_core_users` 기능 플래그 사용). 기본적으로 활성화됨.

{{< /history >}}

> [!flag]
> GitLab Duo Core 고객의 액세스 제거는 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

GitLab Duo Chat은 상황별 대화형 AI로 개발을 가속화하는 AI 어시스턴트입니다. 이 비에이전트 Chat은:

- 개발 환경에서 직접 코드를 설명하고 개선 사항을 제안합니다.
- 코드, 머지 리퀘스트, 이슈 및 기타 GitLab 아티팩트를 분석합니다.
- 요구 사항 및 코드베이스에 따라 코드, 테스트 및 문서를 생성합니다.
- GitLab UI, 웹 IDE, VS Code, JetBrains IDE 및 Visual Studio에 직접 통합됩니다.
- 리포지토리 및 프로젝트의 정보를 포함하여 대상 개선 사항을 제공합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 보기](https://www.youtube.com/watch?v=ZQBAuf-CTAY)
<!-- Video published on 2024-04-18 -->

[GitLab Duo 에이전트 Chat](agentic_chat.md)에 대해 알아봅니다.

## GitLab Duo Core 사용자를 위한 액세스 {#access-for-gitlab-duo-core-users}

2026년 5월 21일부터 모든 GitLab 버전의 GitLab Duo Core 사용자는 GitLab Duo Non-Agentic Chat을 사용할 수 없습니다.

대신 다음 중 하나를 수행할 수 있습니다:

- [GitLab Duo 에이전트 Chat](agentic_chat.md)을 GitLab Duo 에이전트 플랫폼의 일부로 사용합니다.

  웹 IDE 또는 Eclipse에서 비에이전트 Chat을 사용한 경우, 다른 IDE를 사용해야 합니다.
- GitLab Duo Pro 또는 Enterprise를 구매합니다.

## 지원되는 에디터 확장 {#supported-editor-extensions}

다음에서 GitLab Duo Chat을 사용할 수 있습니다.

- GitLab UI
- [GitLab 웹 IDE(클라우드의 VS Code)](../project/web_ide/_index.md)

에디터 확장을 설치하여 이 IDE에서도 GitLab Duo Chat을 사용할 수 있습니다:

- [VS Code](../../editor_extensions/visual_studio_code/setup.md)
- [JetBrains](../../editor_extensions/jetbrains_ide/setup.md)
- [Eclipse](../../editor_extensions/eclipse/setup.md)
- [Visual Studio](../../editor_extensions/visual_studio/setup.md)

> [!note]
> GitLab Self-Managed가 있는 경우: 최상의 사용자 환경과 결과를 위해 GitLab 17.2 이상을 사용합니다. 이전 버전은 계속 작동할 수 있지만 환경이 저하될 수 있습니다.

## GitLab UI에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- GitLab 18.5에서 GitLab.com의 GitLab UI의 모든 페이지에서 사용 가능하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/562168)되었습니다.
- GitLab.com에서 새로운 탐색 및 GitLab Duo 사이드바가 GitLab 18.6에 `paneled_view` [플래그](../../administration/feature_flags/_index.md)로 도입되었습니다. 기본적으로 활성화됨.
- GitLab 18.7에서 이전 탐색 지침이 제거되었습니다.
- GitLab 18.8에서 새로운 탐색 및 GitLab Duo 사이드바가 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/574049)하게 되었습니다. `paneled_view` 기능 플래그가 제거되었습니다.

{{< /history >}}

사전 요구 사항:

- GitLab Duo Chat에 액세스할 수 있어야 하고 GitLab Duo가 켜져 있어야 합니다.
- GitLab Self-Managed에서는 Chat을 사용할 수 있는 곳에 있어야 합니다. 다음에서는 사용할 수 없습니다:
  - **귀하의 작업** 페이지(할 일 목록 등).
  - **사용자 설정** 페이지.
  - **도움말** 메뉴.

GitLab UI에서 Chat을 사용하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. GitLab Duo 사이드바에서 **새 GitLab Duo 채팅**({{< icon name="pencil-square" >}}) 또는 **현재 GitLab Duo 채팅**({{< icon name="duo-chat" >}})을 선택합니다. 화면 오른쪽의 GitLab Duo 사이드바에서 Chat 대화창이 열립니다.
1. Chat 텍스트 상자 아래에서 **에이전트 모드** 토글을 끕니다.
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd>를 누르거나 **전송**을 선택합니다.
   - 채팅을 위해 추가 [컨텍스트](../gitlab_duo/context.md)를 제공할 수 있습니다.
   - 대화형 AI 채팅이 답변을 생성하는 데 몇 초가 걸릴 수 있습니다.
1. 선택 사항. 다음을 수행할 수 있습니다.
   - 후속 질문을 합니다.
   - [다른 대화](#have-multiple-conversations)를 시작합니다.

새로운 관련 없는 질문을 하려면 `/reset`을 입력하고 **전송**을 선택하여 컨텍스트를 지웁니다.

### Chat 이력 보기 {#view-the-chat-history}

가장 최근의 25개 메시지가 채팅 이력에 보관됩니다.

GitLab Duo 사이드바에서 **GitLab Duo 채팅 이력**({{< icon name="history" >}})을 선택합니다.

### 여러 대화 진행 {#have-multiple-conversations}

{{< history >}}

- GitLab 17.10에서 `duo_chat_multi_thread` [기능 플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/16108)되었습니다. 기본적으로 사용 중지됩니다.
- GitLab 17.11에서 [GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187443)되었습니다.
- GitLab 18.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190042)하게 되었습니다. `duo_chat_multi_thread` 기능 플래그가 제거되었습니다.
- GitLab 18.9에서 GitLab UI의 채팅 이력 검색 기능이 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/582513)되었습니다.

{{< /history >}}

GitLab 17.10 이상에서는 Chat과의 무제한 동시 대화를 할 수 있습니다.

1. 다음 중 하나를 수행하여 새 Chat 대화를 만듭니다:

   - GitLab Duo 사이드바에서 **새 GitLab Duo 채팅**({{< icon name="pencil-square" >}})을 선택합니다.
   - 메시지 상자에 `/new`을 입력하고 <kbd>Enter</kbd>를 누르거나 **전송**을 선택합니다.

   새 Chat 대화가 이전 대화를 대체합니다.
1. Chat 텍스트 상자 아래에서 **에이전트 모드** 토글을 끕니다.
1. 모든 대화를 보려면 [Chat 이력](#view-the-chat-history)을 봅니다.
1. 대화 간에 전환하려면 Chat 이력에서 적절한 대화를 선택합니다.
1. GitLab UI에서 채팅 이력에서 특정 대화를 검색하려면 **스레드 검색** 텍스트 상자에 검색어를 입력합니다.

모든 대화는 무제한 메시지를 유지합니다. 그러나 마지막 25개 메시지만 LLM의 컨텍스트 윈도우에 맞게 LLM에 전송됩니다.

이 기능을 활성화하기 전에 생성된 대화는 Chat 이력에 표시되지 않습니다.

### 대화 삭제 {#delete-a-conversation}

대화를 삭제하려면:

1. [Chat 이력](#view-the-chat-history)을 선택합니다.
1. 이력에서 **이 채팅 삭제**({{< icon name="remove" >}})를 선택합니다.

기본적으로 개별 대화는 30일 동안 활동이 없으면 만료되고 자동으로 삭제됩니다.

그러나 관리자는 [이 만료 기간을 변경](#configure-chat-conversation-expiration)할 수 있습니다.

## 웹 IDE에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-the-web-ide}

GitLab의 웹 IDE에서 GitLab Duo Chat을 사용하려면:

1. 웹 IDE를 엽니다:
   1. GitLab UI의 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. 파일을 선택합니다. 그런 다음 오른쪽 위에서 **편집** > **웹 IDE에서 열기**를 선택합니다.
1. 다음 방법 중 하나를 사용하여 Chat을 엽니다:
   - 왼쪽 사이드바에서 **GitLab Duo Chat**을 선택합니다.
   - 편집기에서 열려 있는 파일에서 일부 코드를 선택합니다.
     1. 마우스 오른쪽 단추로 클릭하고 **GitLab Duo Chat**을 선택합니다.
     1. **선택된 코드 조각 설명**, **수정**, **테스트 생성**, **빠른 Chat 열기** 또는 **리팩토링**을 선택합니다.
   - 키보드 단축키를 사용합니다:
     - Windows 또는 Linux: <kbd>ALT</kbd>+<kbd>d</kbd>
     - macOS: <kbd>Option</kbd>+<kbd>d</kbd>
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **보내기**를 선택합니다.

편집기에서 코드를 선택했으면 이 선택이 GitLab Duo Chat에 대한 질문에 포함됩니다. 예를 들어 코드를 선택하고 Chat에 `Can you simplify this?`을 물어볼 수 있습니다.

### 구성 진단 확인 {#check-configuration-diagnostics}

시스템 버전 관리, 기능 상태 관리 및 기능 플래그를 포함하여 GitLab Duo 구성 진단 및 시스템 설정을 확인하려면:

- Chat 창의 오른쪽 위 모서리에서 **상태**를 선택합니다.

## VS Code에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-vs-code}

{{< history >}}

- GitLab for VS Code 확장 5.29.0에서 상태가 [추가](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1712)되었습니다.

{{< /history >}}

사전 요구 사항:

- [VS Code 확장을 설치하고 구성](../../editor_extensions/visual_studio_code/setup.md)했습니다.

GitLab for VS Code 확장에서 GitLab Duo Chat을 사용하려면:

1. VS Code에서 파일을 엽니다. 파일은 Git 리포지토리의 파일일 필요가 없습니다.
1. 왼쪽 사이드바에서 **GitLab Duo Chat**({{< icon name="duo-chat" >}})을 선택합니다.
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **보내기**를 선택합니다.

편집기에서 코드를 선택했으면 이 선택이 GitLab Duo Chat에 대한 질문에 포함됩니다. 예를 들어 코드를 선택하고 Chat에 `Can you simplify this?`을 물어볼 수 있습니다.

### 편집기 창에서 작업하는 동안 Chat 사용 {#use-chat-while-working-in-the-editor-window}

{{< history >}}

- GitLab for VS Code 확장 5.15.0에서 [일반적으로 사용 가능](https://gitlab.com/groups/gitlab-org/-/work_items/15218)하도록 도입되었습니다.
- GitLab for VS Code 확장 5.25.0에서 코드 조각 삽입이 [추가](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2150)되었습니다.

{{< /history >}}

편집기 창에서 GitLab Duo Chat을 열려면 다음 방법 중 하나를 사용합니다:

- 키보드 단축키에서:
  - Windows 및 Linux: <kbd>ALT</kbd>+<kbd>c</kbd>
  - macOS: <kbd>Option</kbd>+<kbd>c</kbd>
- IDE에서 현재 열려 있는 파일에서 마우스 오른쪽 단추로 클릭하고 **GitLab Duo Chat** > **빠른 Chat 열기**를 선택합니다. 추가 컨텍스트를 제공할 코드를 선택합니다.
- 명령 팔레트를 열고 **GitLab Duo Chat: 빠른 Chat 열기**를 선택합니다.

빠른 Chat이 열린 후:

1. 메시지 상자에 질문을 입력합니다. 다음을 수행할 수도 있습니다:
   - `/`을 입력하여 사용 가능한 모든 명령을 표시합니다.
   - `/re`을 입력하여 `/refactor` 및 `/reset`을 표시합니다.
1. 질문을 보내려면 **전송**을 선택하거나 <kbd>Command</kbd>+<kbd>Enter</kbd>를 누릅니다.
1. 응답과 상호 작용하려면 코드 블록 위에 있는 **코드 조각 복사** 및 **코드 조각 삽입** 링크를 사용합니다.
1. Chat을 종료하려면 거터의 Chat 아이콘을 선택하거나 Chat에 포커스가 있을 때 **에스케이프**를 누릅니다.

### Chat의 상태 확인 {#check-the-status-of-chat}

GitLab Duo 구성의 상태를 확인하려면:

- Chat 창의 오른쪽 위 모서리에서 **상태**를 선택합니다.

### Chat 닫기 {#close-chat}

GitLab Duo Chat을 닫으려면:

- 왼쪽 사이드바의 GitLab Duo Chat의 경우 **GitLab Duo Chat**({{< icon name="duo-chat" >}})을 선택합니다.
- 파일에 포함된 빠른 Chat 창의 경우 오른쪽 위 모서리에서 **접기**({{< icon name="chevron-lg-up" >}})를 선택합니다.

## Windows용 Visual Studio에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-visual-studio-for-windows}

사전 요구 사항:

- [GitLab for Visual Studio 확장](../../editor_extensions/visual_studio/setup.md)을 설치하고 구성했습니다.

GitLab for Visual Studio 확장에서 GitLab Duo Chat을 사용하려면:

1. Visual Studio에서 파일을 엽니다. 파일은 Git 리포지토리의 파일일 필요가 없습니다.
1. 다음 방법 중 하나를 사용하여 Chat을 엽니다:
   - 상단 메뉴 바에서 **확장**을 선택한 다음 **Duo Chat 열기**를 선택합니다.
   - 편집기에서 열려 있는 파일에서 일부 코드를 선택합니다.
     1. 마우스 오른쪽 단추로 클릭하고 **GitLab Duo Chat**을 선택합니다.
     1. **선택된 코드 설명** 또는 **테스트 생성**을 선택합니다.
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **보내기**를 선택합니다.

편집기에서 코드를 선택한 경우 이 선택이 AI에 대한 질문과 함께 전송됩니다. 이렇게 하면 이 코드 선택에 대해 질문할 수 있습니다. 예를 들어 `Could you refactor this?`입니다.

## JetBrains IDE에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-jetbrains-ides}

사전 요구 사항:

- [JetBrains IDE용 GitLab Duo 플러그인을 설치하고 구성](../../editor_extensions/jetbrains_ide/setup.md)했습니다.

JetBrains IDE용 GitLab Duo 플러그인에서 GitLab Duo Chat을 사용하려면:

1. JetBrains IDE에서 프로젝트를 엽니다.
1. Chat 창 또는 편집기 창에서 GitLab Duo Chat을 엽니다.

### Chat 창에서 {#in-a-chat-window}

Chat 창에서 GitLab Duo Chat을 열려면 다음 방법 중 하나를 사용합니다:

- 오른쪽 도구 창 바에서 **GitLab Duo Non-Agentic Chat**을 선택합니다.
- 키보드 단축키에서:
  - Windows 및 Linux: <kbd>ALT</kbd>+<kbd>d</kbd>
  - macOS: <kbd>Option</kbd>+<kbd>d</kbd>
- 열려 있는 편집기 파일에서:
  1. 마우스 오른쪽 단추로 클릭하고 **GitLab Duo Chat**을 선택합니다.
  1. **Chat 창 열기**를 선택합니다.
- 선택된 코드 포함:
  1. 편집기에서 명령에 포함할 코드를 선택합니다.
  1. 마우스 오른쪽 단추로 클릭하고 **GitLab Duo Chat**을 선택합니다.
  1. **코드 설명**, **코드 수정**, **테스트 생성** 또는 **코드 리팩토링**을 선택합니다.
- 강조된 코드 문제에서:
  1. 마우스 오른쪽 단추로 클릭하고 **컨텍스트 작업 표시**를 선택합니다.
  1. **Duo를 사용한 수정**을 선택합니다.
- **설정** > **키맵**에서 설정할 수 있는 GitLab Duo 작업의 키보드 또는 마우스 단축키 포함.

GitLab Duo Chat이 열린 후:

1. 메시지 상자에 질문을 입력합니다. 다음을 수행할 수도 있습니다:
   - `/`을 입력하여 사용 가능한 모든 명령을 표시합니다.
   - `/re`을 입력하여 `/refactor` 및 `/reset`을 표시합니다.
1. 질문을 보내려면 <kbd>Enter</kbd>를 누르거나 **전송**을 선택합니다.
1. 코드 블록 내의 단추를 사용하여 응답과 상호 작용합니다.

### 편집기 창에서 {#in-an-editor-window}

{{< history >}}

- [JetBrains용 GitLab Duo 플러그인 3.0.0](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/80) 및 [GitLab for VS Code 확장 5.14.0](https://gitlab.com/groups/gitlab-org/-/work_items/15218)에서 일반적으로 사용 가능하도록 도입되었습니다.

{{< /history >}}

편집기 창에서 GitLab Duo Chat을 열려면 다음 방법 중 하나를 사용합니다:

- 키보드 단축키에서:
  - Windows 및 Linux: <kbd>ALT</kbd>+<kbd>c</kbd>
  - macOS: <kbd>Option</kbd>+<kbd>c</kbd>
- IDE에서 열려 있는 파일에서 일부 코드를 선택한 다음 부동 도구 모음에서 **GitLab Duo 빠른 Chat**({{< icon name="tanuki-ai" >}})을 선택합니다.
- 마우스 오른쪽 단추로 클릭하고 **GitLab Duo Chat** > **빠른 Chat 열기**를 선택합니다.

빠른 Chat이 열린 후:

1. 메시지 상자에 질문을 입력합니다. 다음을 수행할 수도 있습니다:
   - `/`을 입력하여 사용 가능한 모든 명령을 표시합니다.
   - `/re`을 입력하여 `/refactor` 및 `/reset`을 표시합니다.
1. 질문을 보내려면 <kbd>Enter</kbd>를 누릅니다.
1. 코드 블록 주변의 단추를 사용하여 응답과 상호 작용합니다.
1. Chat을 종료하려면 **에스케이프하여 닫기**를 선택하거나 Chat에 포커스가 있을 때 <kbd>에스케이프</kbd>를 누릅니다.

<div class="video-fallback">
  <a href="https://youtu.be/5JbAM5g2VbQ">GitLab Duo 빠른 Chat을 사용하는 방법 보기</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/5JbAM5g2VbQ?si=pm7bTRDCR5we_1IX" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-10-15 -->

## Eclipse에서 GitLab Duo Chat 사용 {#use-gitlab-duo-chat-in-eclipse}

{{< history >}}

- GitLab 17.11에서 실험에서 베타로 [변경](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163)되었습니다.

{{< /history >}}

사전 요구 사항:

- [GitLab for Eclipse 플러그인을 설치하고 구성](../../editor_extensions/eclipse/setup.md)했습니다.

GitLab for Eclipse 플러그인에서 GitLab Duo Chat을 사용하려면:

1. Eclipse에서 프로젝트를 엽니다.
1. 오른쪽 위 모서리에서 **GitLab Duo Chat**({{< icon name="duo-chat" >}})을 선택하거나 키보드 단축키를 사용합니다:
   - Windows 및 Linux: <kbd>Alt</kbd>+<kbd>D</kbd>
   - macOS: <kbd>Option</kbd>+<kbd>D</kbd>
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **보내기**를 선택합니다.

## Chat 대화 만료 구성 {#configure-chat-conversation-expiration}

{{< history >}}

- GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997)되었습니다.

{{< /history >}}

대화가 만료되고 자동으로 삭제되기 전에 얼마나 오래 유지되는지 구성할 수 있습니다.

사전 요구 사항:

- 관리자 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo Chat 대화** 아래에서 다음 옵션 중 하나를 선택합니다:
   - **대화가 최종 업데이트된 이후**.
   - **대화가 생성된 이후**.
1. **변경 사항 저장**을 선택합니다.

## IDE 단축키 {#ide-shortcuts}

지원되는 IDE에서 Chat을 사용할 때 [키보드 단축키](../shortcuts.md#gitlab-duo-chat)를 사용할 수 있습니다.

## 사용 가능한 언어 모델 {#available-language-models}

다양한 언어 모델이 GitLab Duo Chat의 소스가 될 수 있습니다.

- GitLab.com 또는 GitLab Self-Managed에서 기본 GitLab 관리 모델 및 GitLab에서 호스팅하는 클라우드 기반 AI 게이트웨이.
- GitLab Self-Managed에서 GitLab 17.9 이상에서 [지원되는 자체 호스팅 모델이 있는 GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md). 자체 호스팅 모델은 아무것도 외부 모델로 전송되지 않도록 하여 보안 및 개인 정보를 최대화합니다. GitLab 관리 모델, 지원되는 다른 언어 모델 또는 자신의 호환 가능한 모델을 사용할 수 있습니다.

## 입력 및 출력 길이 {#input-and-output-length}

각 Chat 대화의 입력 및 출력 길이는 제한됩니다:

- 입력은 200,000개 토큰(약 680,000자)으로 제한됩니다. 입력 토큰에는 다음이 포함됩니다:
  - Chat이 인식하는 모든 [컨텍스트](../gitlab_duo/context.md).
  - 해당 대화의 모든 이전 질문 및 답변.
- 출력은 8,192개 토큰(약 28,600자)으로 제한됩니다.

## 피드백 제공 {#give-feedback}

GitLab이 계속 GitLab Duo Chat 환경을 개선하므로 피드백이 중요합니다. 피드백은 Chat을 사용자의 필요에 맞게 맞춤화하고 모든 사용자를 위해 성능을 향상시키는 데 도움이 됩니다.

특정 응답에 대해 피드백을 제공하려면 응답 메시지의 피드백 단추를 사용합니다. 또는 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)에 주석을 추가할 수 있습니다.
