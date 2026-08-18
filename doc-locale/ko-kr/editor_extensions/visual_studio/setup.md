---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Visual Studio에서 GitLab Duo를 연결하고 사용합니다.
title: Visual Studio용 GitLab 확장 설치 및 설정
---

확장을 가져오려면 다음 방법 중 하나를 사용합니다:

- Visual Studio 내에서 활동 표시줄에서 **Extensions**을 선택하고 `GitLab for Visual Studio`를 검색합니다.
- [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio)에서
- GitLab에서 [릴리스 목록](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases)에서 또는 [최신 버전을 다운로드](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases/permalink/latest/downloads/GitLab.Extension.vsix)하여 직접 다운로드합니다.

확장을 설치하려면 다음이 필요합니다:

- Visual Studio 2022 버전 17.6 이상(AMD64 또는 Arm64).
- Visual Studio용 [IntelliCode](https://visualstudio.microsoft.com/services/intellicode/) 구성 요소.
- GitLab 버전 16.1 이상.
  - GitLab Duo 코드 제안은 GitLab 버전 16.8 이상을 필요로 합니다.
- 지원되지 않으므로 Mac용 Visual Studio를 사용하지 않습니다.

이 기능을 사용하기 위해 새로운 추가 데이터는 수집되지 않습니다. 비공개 GitLab 고객 데이터는 학습 데이터로 사용되지 않습니다. [Gemini Enterprise Agent Platform의 데이터 거버넌스](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/zero-data-retention)에 대해 자세히 알아봅니다.

## GitLab에 연결 {#connect-to-gitlab}

확장을 설치한 후 개인 액세스 토큰을 생성하고 GitLab으로 인증하여 GitLab 계정에 연결합니다.

### 개인 액세스 토큰 생성 {#create-a-personal-access-token}

GitLab Self-Managed에 있는 경우 개인 액세스 토큰을 생성합니다.

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **개인 액세스 토큰**을 선택합니다.
1. **새 토큰 추가**를 선택합니다.
1. 이름, 설명 및 만료 날짜를 입력합니다.
1. `api` 및 `read_user` 범위를 선택합니다.
1. **Create personal access token**을 선택합니다.

### GitLab으로 인증 {#authenticate-with-gitlab}

GitLab으로 인증하려면:

1. Visual Studio의 상단 표시줄에서 **도구** > **옵션** > **GitLab**으로 이동합니다.
1. **액세스 토큰** 텍스트 상자에 토큰을 붙여넣습니다. 토큰이 표시되지 않으며 다른 사용자가 액세스할 수 없습니다.
1. **GitLab URL** 텍스트 상자에 GitLab 인스턴스의 URL을 입력합니다. GitLab.com의 경우 `https://gitlab.com`을 사용합니다.

## 원격 분석 활성화 {#enable-telemetry}

GitLab 확장은 Visual Studio의 원격 분석 설정을 사용하여 사용 및 오류 정보를 GitLab으로 보냅니다. Visual Studio용 GitLab에서 원격 분석을 활성화하려면:

1. Visual Studio의 상단 표시줄에서 **도구** > **옵션**으로 이동합니다.
1. 왼쪽 사이드바에서 **GitLab**을 확장하고 **일반**을 선택합니다.
1. **Enable telemetry** 드롭다운 목록에서 **True**를 선택합니다.
1. **확인**을 선택합니다.

## 확장 구성 {#configure-the-extension}

이 확장은 GitLab과 함께 사용할 수 있는 사용자 지정 명령을 제공합니다. 대부분의 명령은 기존 Visual Studio 구성과의 충돌을 방지하기 위해 기본 키보드 단축키를 갖지 않습니다.

| 명령 이름                          | 기본 키보드 단축키                   | 설명 |
|---------------------------------------|---------------------------------------------|-------------|
| `GitLab.ToggleCodeSuggestions`        | 없음                                        | 코드 제안을 켜거나 끕니다. |
| `GitLab.OpenDuoChat`                  | 없음                                        | GitLab Duo Chat을 엽니다. |
| `GitLab.GitLabDuoNextSuggestions`     | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>N</kbd> | 다음 코드 제안으로 전환합니다. |
| `GitLab.GitLabDuoPreviousSuggestions` | 없음                                        | 이전 코드 제안으로 전환합니다. |
| `GitLab.GitLabExplainTerminalWithDuo` | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd> | 터미널에서 선택한 텍스트를 설명합니다. |
| `GitLabDuoChat.ExplainCode`           | 없음                                        | 선택한 코드를 설명합니다. |
| `GitLabDuoChat.Fix`                   | 없음                                        | 선택한 코드의 문제를 수정합니다. |
| `GitLabDuoChat.GenerateTests`         | 없음                                        | 선택한 코드에 대한 테스트를 생성합니다. |
| `GitLabDuoChat.Refactor`              | 없음                                        | 선택한 코드를 리팩터링합니다. |

확장의 사용자 지정 명령에 키보드 단축키를 사용하여 액세스할 수 있으며, 이를 사용자 지정할 수 있습니다:

1. 상단 표시줄에서 **도구** > **옵션**으로 이동합니다.
1. **환경** > **Keyboard**로 이동합니다. `GitLab.`을 검색합니다.
1. 명령을 선택하고 키보드 단축키를 할당합니다.

### GitLab Duo 구성 {#configure-gitlab-duo}

GitLab Duo 기능은 사전 조건을 충족할 때 기본적으로 활성화됩니다:

- 에이전트 기능의 경우 [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites)의 전제 조건을 충족합니다.
- GitLab Duo가 [켜져](../../user/gitlab_duo/turn_on_off.md) 있습니다.
- 플로우의 경우 [기본 플로우가 켜져](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off) 있습니다.
- 프로젝트가 [네임스페이스 그룹](../../user/namespace/_index.md)에 있습니다.
- [기본 GitLab Duo 네임스페이스](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)가 설정되어 있거나 GitLab Duo 액세스 권한이 있는 프로젝트가 열려 있습니다.
- GitLab Duo Code Suggestions의 경우 [추가 전제 조건을 충족](../../user/project/repository/code_suggestions/set_up.md#prerequisites)합니다.
