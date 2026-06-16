---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 개발 수명 주기 전반에 걸쳐 AI 네이티브 기능을 사용합니다.
title: GitLab Duo 시작하기
---

GitLab Duo는 계획, 개발, 보안 워크플로 전반에 걸쳐 도움을 주는 AI 네이티브 어시스턴트입니다. GitLab Duo에는 코드 작성, 검토, 편집을 도와주는 Code Suggestions, Code Explanation 같은 기능이 포함되어 있습니다.

## 1단계:  GitLab Duo에 대한 액세스 권한이 있는지 확인 {#step-1-ensure-you-have-access-to-gitlab-duo}

GitLab Duo는 관리자, 그룹 또는 프로젝트 소유자가 설정해야 합니다.

GitLab Duo 기능에 액세스하는 데 이슈가 있으면 관리자가 설치 상태를 확인할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [GitLab Duo 켜기](../gitlab_duo/turn_on_off.md).
- [상태 확인 세부 정보](../../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo).

## 2단계:  UI에서 GitLab Duo Chat 사용해 보기 {#step-2-try-gitlab-duo-chat-in-the-ui}

시작하려면 GitLab UI에서 Chat을 사용해 보세요.

프로젝트로 이동한 후 오른쪽 상단 모서리에서 **GitLab Duo Chat** 버튼을 선택합니다. 이 버튼을 사용할 수 있으면 모든 것이 제대로 설정된 것입니다. 특정 이슈 또는 머지 리퀘스트에 대해 Chat에 질문을 하거나, GitLab 일반 사항에 대해 물어보세요.

자세한 정보는 다음을 참조하세요:

- [GitLab Duo Non-Agentic Chat](../gitlab_duo_chat/_index.md).

## 3단계:  다른 GitLab Duo 기능 사용해 보기 {#step-3-try-other-gitlab-duo-features}

GitLab Duo는 워크플로 전체에서 사용할 수 있습니다. 스프린트 계획부터 CI/CD 파이프라인 문제 해결, 테스트 케이스 작성부터 보안 위협 해결까지 GitLab Duo는 다양한 방식으로 도움을 줄 수 있습니다.

사용자가 액세스할 수 있는 기능은 구독에 따라 다를 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [워크플로와 일치하는 GitLab Duo 기능을 결정하는 데 도움이 되는 의사 결정 트리](../gitlab_duo/_index.md).
- [GitLab Duo 기능의 전체 목록](../gitlab_duo/feature_summary.md).
- [아직 개발 중인 GitLab Duo 기능을 켜는 방법](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).

## 4단계:  IDE에서 GitLab Duo를 사용할 준비 {#step-4-prepare-to-use-gitlab-duo-in-your-ide}

이제 IDE에서 GitLab Duo 기능을 사용해 보세요. VS Code 및 기타 편집기에서 GitLab Duo Chat, 소프트웨어 개발 플로우, Code Suggestions 같은 기능을 사용할 수 있습니다.

시작하려면 확장 프로그램을 설치하고 GitLab으로 인증합니다.

자세한 정보는 다음을 참조하세요:

- [VS Code용 확장 프로그램 설정](../../editor_extensions/visual_studio_code/setup.md).
- [JetBrains용 확장 프로그램 설정](../../editor_extensions/jetbrains_ide/setup.md).
- [Visual Studio용 확장 프로그램 설정](../../editor_extensions/visual_studio/setup.md).
- [Neovim용 확장 프로그램 설정](../../editor_extensions/neovim/setup.md).
- [Web IDE 사용](../project/web_ide/_index.md).

## 5단계:  IDE 기능 사용 시작 {#step-5-start-using-ide-features}

마지막으로 IDE에서 GitLab Duo를 테스트합니다.

- Code Suggestions는 입력하는 동안 코드를 추천합니다.
- Chat을 사용하여 코드 또는 필요한 다른 항목에 대한 질문을 할 수 있습니다.
- 소프트웨어 개발 플로우는 사용자 대신 작업을 수행합니다.

제안을 받고 싶은 개발 언어를 선택할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [지원되는 확장 프로그램 및 언어](../project/repository/code_suggestions/supported_extensions.md).
- [Code Suggestions 켜기](../project/repository/code_suggestions/set_up.md#turn-on-code-suggestions).
- [VS Code용 GitLab 문제 해결](../../editor_extensions/visual_studio_code/troubleshooting.md).
- [JetBrains IDE용 GitLab Duo 플러그인 문제 해결](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md).
- [Visual Studio용 GitLab 문제 해결](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md).
- [Neovim용 GitLab 플러그인 문제 해결](../../editor_extensions/neovim/neovim_troubleshooting.md).
