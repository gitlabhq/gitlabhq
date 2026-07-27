---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code 확장을 사용하여 VS Code에서 일반적인 GitLab 작업을 직접 처리합니다.
title: GitLab for VS Code 확장
---

[GitLab for VS Code 확장](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)은 GitLab Duo 및 기타 GitLab 기능을 IDE에 직접 통합합니다.

시작하려면 [확장을 설치하고 구성](setup.md)하세요. 추가 보안을 위해 Visual Studio Code Dev Container에서 확장을 설정할 수 있습니다.

구성되면 이 확장은 매일 사용하는 GitLab 기능을 VS Code 환경에 직접 가져옵니다:

- [프로젝트 작업](projects.md): 이슈로 작업을 계획하고 추적하고, 머지 리퀘스트로 변경 사항을 검토하고 논의하고, 코드 스니펫을 공유합니다. AI 네이티브 계획 및 코딩을 위해 GitLab Duo를 사용합니다.
- [CI/CD 파이프라인 모니터링 및 테스트](cicd.md): 파이프라인 구성을 테스트합니다. 파이프라인 상태와 작업 출력을 봅니다.
- [애플리케이션 보안 설정](security_scanning.md): 보안 결과를 검토하고 프로젝트에 대해 SAST 스캔을 수행합니다.
- [리포지토리 찾아보기](remote_urls.md#browse-a-repository-in-read-only-mode): 복제하지 않고 GitLab 리포지토리에 읽기 전용 모드로 액세스합니다.

VS Code에서 GitLab 프로젝트를 보면 현재 브랜치에 대한 정보를 표시합니다:

- 브랜치의 가장 최근 CI/CD 파이프라인 상태입니다.
- 이 브랜치에 대한 머지 리퀘스트로의 링크입니다.
- 머지 리퀘스트가 [이슈 종료 패턴](../../user/project/issues/managing_issues.md#closing-issues-automatically)을 포함하면 이슈로의 링크입니다.

## GitLab 확장 패널 {#gitlab-extension-panels}

확장에는 다음 기능이 포함되어 있습니다:

- 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}}): 이슈 및 머지 리퀘스트를 관리하고, CI/CD 명령을 실행하고, 파이프라인 상태를 보고, 보안 스캔을 수행합니다. 사용자 지정 에이전트 [사용자 지정 쿼리](custom_queries.md)로 보기를 확장할 수도 있습니다.
- 왼쪽 사이드바에서 **GitLab Duo 에이전트 플랫폼** ({{< icon name="duo-agentic-chat" >}}):
  - 채팅 탭: GitLab Duo 에이전트 채팅과 상호 작용하거나 **새 채팅** ({{< icon name="duo-chat-new" >}}) 드롭다운 목록을 사용하여 작업할 기초 또는 사용자 지정 에이전트를 선택합니다.
  - 플로우 탭: Software Development 플로우를 사용합니다. [채팅과 플로우의 차이](../../user/duo_agent_platform/flows/foundational_flows/software_development.md#flow-and-chat-comparison)에 대해 자세히 알아보세요.
- 상태 표시줄에서 **Duo** ({{< icon name="tanuki-ai" >}}): GitLab Duo 코드 제안 기능 상태를 확인하고 코드를 작성할 때 파일의 제안을 검토합니다.
- 왼쪽 사이드바에서 **GitLab Duo Chat** ({{< icon name="duo-chat" >}}): GitLab Duo 비 에이전트 채팅과 상호 작용합니다.

이 기능이 표시되지 않으면 [문제 해결](troubleshooting.md#gitlab-duo-features-are-unavailable)을 참조하세요.

## 키보드 단축키 사용자 지정 {#customize-keyboard-shortcuts}

**Accept Inline Suggestion**, **Accept Next Word Of Inline Suggestion** 또는 **Accept Next Line Of Inline Suggestion**에 대해 다른 키보드 단축키를 할당할 수 있습니다:

1. VS Code에서 `Preferences: Open Keyboard Shortcuts` 명령을 실행합니다.
1. 편집할 단축키를 찾아 **Change keybinding** ({{< icon name="pencil" >}})을 선택합니다.
1. **Accept Inline Suggestion**, **Accept Next Word Of Inline Suggestion** 또는 **Accept Next Line Of Inline Suggestion**에 선호하는 단축키를 할당합니다.
1. <kbd>Enter</kbd> 키를 눌러 변경 사항을 저장합니다.

## 확장 업데이트 {#update-the-extension}

확장을 최신 버전으로 업데이트하려면:

1. Visual Studio Code에서 **설정** > **Extensions**로 이동합니다.
1. **GitLab**을 검색하고 **GitLab (`gitlab.com`)**에서 게시합니다.
1. **확장: GitLab**에서 **Update to {later version}**를 선택합니다.
1. 선택 사항. 앞으로 자동 업데이트를 활성화하려면 **Auto-Update**를 선택합니다.

## 사전 릴리스 버전 설치 {#install-the-pre-release-version}

GitLab은 확장의 사전 릴리스 빌드를 VS Code 확장 마켓플레이스에 게시합니다.

사전 릴리스 빌드를 설치하려면:

1. VS Code를 엽니다.
1. **Extensions** > **GitLab** 아래에서 **Switch to Pre-release Version**을 선택합니다.
1. **Restart Extensions**을 선택합니다.

## GitLab Duo 상태 확인 {#check-gitlab-duo-status}

1. Visual Studio Code의 하단 상태 표시줄에서 GitLab 아이콘 ({{< icon name="tanuki" >}})을 선택합니다.
1. VS Code 검색 상자 아래에 메뉴가 열리고 GitLab for VS Code 확장이 상태를 표시합니다. 모든 오류는 **상태:** 옆에 표시됩니다.

GitLab Duo 비 에이전트 채팅의 경우 [채팅 상태](../../user/gitlab_duo_chat/_index.md#check-the-status-of-chat)도 확인할 수 있습니다.

## 관련 항목 {#related-topics}

- [GitLab for VS Code 릴리스](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases)
- [에디터 확장에 대한 보안 고려 사항](../security_considerations.md)
- [명령 팔레트 명령](settings.md#command-palette-commands)
- [GitLab for VS Code 확장 프로그램 문제 해결](troubleshooting.md)
- [GitLab for VS Code 확장 다운로드](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- 확장 [소스 코드](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
- [GitLab 언어 서버 설명서](../language_server/_index.md)
