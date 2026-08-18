---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code 확장을 사용하여 VS Code에서 일반적인 GitLab 작업을 직접 처리합니다.
title: GitLab for VS Code 확장 프로그램 설치 및 설정
---

GitLab for VS Code 확장 프로그램을 사용하려면 확장 프로그램을 설치하고 GitLab에 연결한 후 필요에 따라 구성합니다.

## 확장 프로그램 설치 {#install-the-extension}

필요에 맞는 설치 방법을 선택합니다:

- 표준 VS Code의 경우 [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)에서 설치합니다.
- 비공식 VS Code 버전의 경우 [Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow)에서 설치합니다.
- 보안이 필요한 로컬 개발의 경우 Visual Studio Code Dev Container에 설치합니다.

### Visual Studio Code Dev Container에 설치 {#install-in-a-visual-studio-code-dev-container}

보안을 강화하려면 [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)를 사용하여 컨테이너화된 개발 환경에서 확장 프로그램을 설정하고 GitLab Duo를 사용합니다.

전제 조건:

- [Docker](https://www.docker.com/products/docker-desktop/)가 설치되어 실행 중입니다.
- Visual Studio Code [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 확장 프로그램이 VS Code에 설치되어 있습니다.

VS Code Dev Container에 확장 프로그램을 설치하려면:

1. **Dev Containers: Add Dev Container Configuration Files** 명령을 Command Palette에서 실행합니다.
1. 구성 파일에 GitLab 확장 프로그램을 추가합니다:

   ```json
   // .devcontainer/devcontainer.json
   {
   "name": "My Project",
   "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
   "customizations": {
      "vscode": {
         "extensions": [
         "GitLab.gitlab-workflow"
         ]
      }
   }
   }
   ```

1. **Dev Containers: Open Folder in Container** 명령을 실행하여 VS Code Dev Container에서 프로젝트를 엽니다. VS Code가 컨테이너 내에 확장 프로그램을 자동으로 설치합니다.

## GitLab에 연결 {#connect-to-gitlab}

확장 프로그램을 설치한 후 인증을 한 다음 프로젝트를 GitLab의 리포지토리에 연결합니다.

### GitLab으로 인증 {#authenticate-with-gitlab}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#release--6470-2025-09-26) GitLab 18.3 릴리스 중 GitLab for VS Code 6.47.0에서 GitLab Self-Managed 및 GitLab Dedicated에 대한 OAuth 인증을 도입했습니다.

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab.com" >}}

전제 조건:

- 개인 액세스 토큰을(를) 사용한 인증의 경우 `api` 범위가 있는 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)이 필요합니다.

GitLab으로 인증하려면:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. `GitLab: Authenticate`을 입력하고 <kbd>Enter</kbd>를 누르세요.
1. 옵션에서 GitLab 인스턴스 URL을 선택하거나 수동으로 입력합니다.
   - 수동으로 입력하는 경우 **URL to GitLab instance**에 `http://` 또는 `https://`을(를) 포함하여 전체 URL을 붙여넣습니다. <kbd>Enter</kbd>를 눌러 확인합니다.
1. 인증 방법 **OAuth** 또는 **PAT**를 선택합니다.
   - OAuth의 경우 프롬프트를 따라 로그인하고 인증합니다.
   - PAT의 경우 프롬프트를 따라 토큰을 생성하거나 기존 토큰을 입력하여 인증합니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed 및 GitLab Dedicated" >}}

전제 조건:

- OAuth를 사용하여 인증하는 경우 [VS Code용 OAuth 응용 프로그램](../../administration/settings/editor_extensions.md#vs-code)의 응용 프로그램 ID입니다.
- 개인 액세스 토큰을(를) 사용한 인증의 경우 `api` 범위가 있는 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)이 필요합니다.

OAuth를 사용하려면 먼저 OAuth 응용 프로그램 로그인을 구성합니다:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. `Preferences: Open User Settings`을 입력하고 <kbd>Enter</kbd>를 누르세요.
1. **설정** > **Extensions** > **GitLab** > **인증**을 선택합니다.
1. **OAuth Client IDs** 아래에서 **Add Item**을 선택합니다.
1. **키**를 선택하고 GitLab 인스턴스 URL을 입력합니다.
1. **값**을 선택하고 OAuth 응용 프로그램의 ID를 입력합니다.

GitLab으로 인증하려면:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. `GitLab: Authenticate`을 입력하고 <kbd>Enter</kbd>를 누르세요.
1. 옵션에서 GitLab 인스턴스 URL을 선택하거나 수동으로 입력합니다.
   - 수동으로 입력하는 경우 **URL to GitLab instance**에 `http://` 또는 `https://`을(를) 포함하여 전체 URL을 붙여넣습니다. <kbd>Enter</kbd>를 눌러 확인합니다.
1. 인증 방법 **OAuth** 또는 **PAT**를 선택합니다.
   - OAuth의 경우 프롬프트를 따라 로그인하고 인증합니다.
   - PAT의 경우 프롬프트를 따라 토큰을 생성하거나 기존 토큰을 입력하여 인증합니다.

{{< /tab >}}

{{< /tabs >}}

확장 프로그램은 Git 리모트 URL과 토큰에 대해 지정한 GitLab 인스턴스 URL을 일치시킵니다. 여러 계정 또는 프로젝트가 있는 경우 사용할 계정 또는 프로젝트를 선택할 수 있습니다.

> [!note]
> GitLab 인스턴스 또는 네트워크가 사용자 지정 SSL 설정을 사용하는 경우 확장 프로그램을 자체 서명된 인증서를 지원하도록 구성할 수 있습니다. 자세한 내용은 [자체 서명된 인증서로 확장 프로그램 사용](ssl.md)을 참조하세요.

### 리포지토리에 연결 {#connect-to-your-repository}

VS Code에서 GitLab 리포지토리에 연결하려면:

1. VS Code의 상단 메뉴에서 **터미널** > **New Terminal**을 선택합니다.
1. 리포지토리 복제: `git clone <repository>`.
1. 리포지토리가 복제된 디렉터리로 변경하고 브랜치를 확인합니다: `git checkout <branch_name>`.
1. 프로젝트가 선택되었는지 확인합니다:
   1. 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택합니다.
   1. 프로젝트 이름을 선택합니다. 여러 프로젝트가 있는 경우 작업할 프로젝트를 선택합니다.
1. 터미널에서 리포지토리가 리모트로 구성되었는지 확인합니다: `git remote -v`. 결과는 다음과 같아야 합니다:

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   리모트가 정의되지 않았거나 여러 리모트가 있는 경우:

   1. 왼쪽 사이드바에서 **Source Control** ({{< icon name="branch" >}})을 선택합니다.
   1. **Source Control** 레이블에서 마우스 오른쪽 단추를 클릭하고 **리포지토리**를 선택합니다.
   1. 리포지토리 옆에서 줄임표 ({{< icon name=ellipsis_h >}})를 선택한 다음 **리모트** > **Add Remote**를 선택합니다.
   1. **Add remote from GitLab**을 선택합니다.
   1. 리모트를 선택합니다.

확장 프로그램은 다음 두 조건이 모두 충족될 때 VS Code 상태 표시줄에 정보를 표시합니다:

- 프로젝트에 마지막 커밋에 대한 파이프라인이 있습니다.
- 현재 브랜치가 머지 리퀘스트와 연결되어 있습니다.

## 확장 구성 {#configure-the-extension}

설정을 구성하려면 **설정** > **Extensions** > **GitLab**으로 이동합니다.

### 계정 및 프로젝트 구성 {#configure-accounts-and-projects}

인증을 하고 리포지토리에 연결한 후 확장 프로그램은 Git 리포지토리 구성을 기반으로 GitLab 계정 및 프로젝트를 자동으로 연결합니다.

일부 환경에서는 자격 증명을 유지하기 위해 추가 구성이 필요할 수 있습니다.

#### 환경 변수에 토큰 저장 {#store-tokens-in-environment-variables}

Gitpod 컨테이너와 같이 VS Code 저장소를 자주 삭제하는 경우 인증 토큰을 [VS Code 환경 변수](https://code.visualstudio.com/docs/editor/variables-reference#_environment-variables)에 저장합니다. VS Code 저장소를 삭제할 때 환경 변수가 유지됩니다.

VS Code를 시작하기 전에 다음 변수를 설정합니다:

- `GITLAB_WORKFLOW_INSTANCE_URL`: GitLab 인스턴스 URL입니다. 예를 들어, `https://gitlab.com`입니다.
- `GITLAB_WORKFLOW_TOKEN`: 개인 액세스 토큰입니다.

확장 프로그램에서 동일한 GitLab 인스턴스에 대한 토큰을 구성하는 경우 확장 프로그램 토큰이 환경 변수를 재정의합니다.

#### 계정 전환 {#switch-accounts}

확장 프로그램은 각 [VS Code 워크스페이스](https://code.visualstudio.com/docs/editor/workspaces)(창)에 대해 하나의 계정을 사용합니다. 다음의 경우 계정을 자동으로 선택합니다:

- 확장 프로그램에서 하나의 GitLab 계정으로만 인증합니다.
- VS Code 창의 모든 워크스페이스가 `git remote` 구성을 기반으로 동일한 GitLab 계정을 사용합니다.

여러 GitLab 계정이 있고 확장 프로그램이 사용할 계정을 결정할 수 없으면 **Multiple GitLab Accounts** ({{< icon name="question-o" >}})을 상태 표시줄에 추가합니다. GitLab 계정을 선택하려면 상태 표시줄 항목을 선택하고 프롬프트를 따릅니다.

또는 명령 팔레트를 사용할 수 있습니다:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. `GitLab: Select Account for this Workspace` 명령을 실행합니다.
1. 목록에서 계정을 선택합니다.

#### 프로젝트 선택 {#select-a-project}

확장 프로그램은 Git 리포지토리 리모트를 사용하여 VS Code 워크스페이스와 연결할 GitLab 프로젝트를 결정합니다.

Git 리포지토리에 여러 리모트가 있고 여러 GitLab 프로젝트를 가리키는 경우 확장 프로그램은 사용할 리모트를 결정할 수 없습니다. 예를 들어:

- `origin`: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- `personal-fork`: `git@gitlab.com:myusername/gitlab-vscode-extension.git`

이 경우 확장 프로그램은 **(multiple projects)** 레이블을 상태 표시줄에 추가합니다.

프로젝트를 선택하려면:

1. 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택합니다.
1. **이슈와 머지 리퀘스트**를 확장합니다.
1. **(multiple projects, click to select)**를 포함하는 줄을 선택합니다.
1. 목록에서 프로젝트를 선택합니다.

**이슈와 머지 리퀘스트** 목록이 선택한 프로젝트의 정보로 업데이트됩니다.

#### 프로젝트 변경 {#change-the-project}

프로젝트 선택을 변경하려면:

1. 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택합니다.
1. **이슈와 머지 리퀘스트**를 확장합니다.
1. 프로젝트를 선택합니다.
1. 프로젝트 이름 옆에서 **Clear Selected Project** ({{< icon name="close-xs" >}})을 선택합니다.

### GitLab Duo 구성 {#configure-gitlab-duo}

GitLab Duo 기능은 전제 조건을 충족할 때 VS Code에서 기본적으로 활성화됩니다:

- 에이전트 기능의 경우 [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites)의 전제 조건을 충족합니다.
- GitLab Duo가 [켜져](../../user/gitlab_duo/turn_on_off.md) 있습니다.
- 플로우의 경우 [기본 플로우가 켜져](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off) 있습니다.
- 에이전트의 경우 [기본 에이전트가 켜져](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) 있고 [사용자 지정 에이전트가 활성화](../../user/duo_agent_platform/agents/custom.md#enable-an-agent)되어 있습니다(필요에 따라).
- 프로젝트가 [네임스페이스 그룹](../../user/namespace/_index.md)에 있습니다.
- [기본 GitLab Duo 네임스페이스](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)가 설정되어 있거나 GitLab Duo 액세스 권한이 있는 프로젝트가 열려 있습니다.
- GitLab Duo Code Suggestions의 경우 [추가 전제 조건을 충족](../../user/project/repository/code_suggestions/set_up.md#prerequisites)입니다.

Agentic Chat 도구를 개별적으로가 아니라 세션당 한 번 승인하려면 [도구 승인](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals)을 참조하세요.

#### GitLab Duo 끄기 {#turn-off-gitlab-duo}

VS Code에서 GitLab Duo 기능을 끄려면:

1. VS Code에서 설정 편집기를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. **Extensions** > **GitLab** > **GitLab Duo**를 선택합니다.
1. 끄려는 기능을 찾아 확인란을 선택 해제합니다.

### 원격 측정 구성 {#configure-telemetry}

GitLab for VS Code는 Visual Studio Code의 원격 측정 설정을 사용하여 사용량 및 오류 정보를 GitLab으로 전송합니다. Visual Studio Code에서 원격 측정을 켜거나 사용자 지정하려면:

1. VS Code에서 설정 편집기를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. **Application** > **Telemetry**를 선택합니다.
1. **Telemetry Level**에서 공유하려는 데이터를 선택합니다:
   - `all`: 사용 데이터, 일반 오류 원격 측정 및 충돌 보고서를 전송합니다.
   - `error`: 일반 오류 원격 측정 및 충돌 보고서를 전송합니다.
   - `crash`: OS 수준 충돌 보고서를 전송합니다.
   - `off`: Visual Studio Code에서 모든 원격 측정 데이터를 비활성화합니다.
1. 변경 사항을 저장합니다.
