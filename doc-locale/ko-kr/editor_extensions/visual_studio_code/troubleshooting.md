---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab for VS Code 확장 프로그램 문제 해결
---

GitLab for VS Code를 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

문제가 아래에 나열되지 않으면 [지원에 필요한 정보](#required-information-for-support)를 수집하고 [`gitlab-vscode-extension` 이슈 트래커](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues)에서 버그를 보고하세요.

## 로그 {#logs}

GitLab for VS Code 확장 프로그램과 확장 프로그램을 지원하는 GitLab Language Server는 문제 해결에 도움이 되는 로그를 제공합니다.

### 디버그 로그 활성화 {#enable-debug-logs}

디버그 로깅을 활성화하려면:

1. VS Code에서 설정 편집기를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. **Extensions** > **GitLab** > **기타**를 선택하세요.
1. **GitLab 아래에서: 디버그**에서 체크박스를 선택하여 디버그 모드를 활성화하세요.
1. 창을 다시 로드하여 확장 프로그램을 다시 시작하세요.
   1. 명령 팔레트를 여세요:
      - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
      - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   1. `Developer: Reload Window`을 입력하고 <kbd>Enter</kbd>를 누르세요.

### 디버그 로그 보기 {#view-debug-logs}

디버그 로그를 보려면:

1. VS Code에서 **보기** > **Output**을 선택하세요.
1. 출력 패널의 오른쪽 위 모서리에서 드롭다운 목록을 선택하여 **GitLab** 또는 **GitLab Language Server** 로그를 필터링하세요.
1. 오류, 경고, 연결 문제 또는 인증 문제를 검토하세요.

## 인증 {#authentication}

다음과 같은 인증 오류가 발생할 수 있습니다.

### 오류: `...can't access the OS Keychain` {#error-cant-access-the-os-keychain}

macOS 및 Ubuntu에서 확장 프로그램이 인증을 위해 OS 키체인에 액세스할 수 없을 때 오류가 발생할 수 있습니다.

예를 들어:

```plaintext
The GitLab extension can't access the OS Keychain.
If you use Ubuntu, see this existing issue.
```

```plaintext
Error: Cannot get password
at I.$getPassword (vscode-file://vscode-app/snap/code/97/usr/share/code/resources/app/out/vs/workbench/workbench.desktop.main.js:1712:49592)
```

운영 체제에 맞는 다음 해결 방법을 따르세요.

이 오류에 대한 자세한 내용은 다음을 참조하세요:

- [확장 프로그램 이슈 580](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/580)
- [업스트림 `microsoft/vscode` 이슈 147515](https://github.com/microsoft/vscode/issues/147515)

#### macOS 해결 방법 {#macos-workaround}

macOS에서 이 오류를 해결하려면:

1. 컴퓨터에서 **Keychain Access**를 열고 `vscodegitlab.gitlab-workflow`를 검색하세요.
1. `vscodegitlab.gitlab-workflow`을 키체인에서 삭제하세요.
1. <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 눌러 명령 팔레트를 여세요.
1. `GitLab: Remove Account from VS Code`을 입력하고 <kbd>Enter</kbd>를 눌러 VS Code에서 손상된 계정을 제거하세요.
1. 명령 팔레트를 다시 열고 `GitLab: Authenticate`을 실행하여 계정을 다시 추가하세요.

#### Ubuntu 해결 방법 {#ubuntu-workaround}

Ubuntu 20.04 및 22.04에서 `snap`로 VS Code를 설치하면 VS Code가 OS 키체인에서 비밀번호를 읽을 수 없습니다. 확장 프로그램 버전 3.44.0 이상은 보안 토큰 저장을 위해 OS 키체인을 사용합니다.

VS Code 버전 1.68.0 이전을 사용 중이면 다음 해결 방법 중 하나를 시도하세요:

- GitLab for VS Code 확장 프로그램을 버전 3.43.1로 다운그레이드하세요.
- VS Code를 `.deb` 패키지에서 설치하세요. `snap`이 아닌:
  1. `snap` VS Code를 제거하세요.
  1. VS Code를 [`.deb` 패키지](https://code.visualstudio.com/Download)에서 설치하세요.
  1. Ubuntu의 **Password & Keys**로 이동하여 `vscodegitlab.workflow/gitlab-tokens` 항목을 찾아 제거하세요.
  1. VS Code에서 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 눌러 명령 팔레트를 여세요.
  1. `Gitlab: Remove Your Account`을 입력하고 <kbd>Enter</kbd>를 눌러 자격 증명이 없는 계정을 제거하세요.
  1. 명령 팔레트를 다시 열고 `GitLab: Authenticate`을 실행하여 계정을 다시 추가하세요.

VS Code 버전 1.68.0 이상을 사용 중이면 다시 인증을 시도하세요:

1. Ubuntu의 **Password & Keys**로 이동하여 `vscodegitlab.workflow/gitlab-tokens` 항목을 찾아 제거하세요.
1. VS Code에서 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 눌러 명령 팔레트를 여세요.
1. `Gitlab: Remove Your Account`을 입력하고 <kbd>Enter</kbd>를 눌러 자격 증명이 없는 계정을 제거하세요.
1. 명령 팔레트를 다시 열고 `GitLab: Authenticate`을 실행하여 계정을 다시 추가하세요.

### GDK 사용 시 연결 및 권한 부여 오류 {#connection-and-authorization-error-when-using-gdk}

GDK와 함께 VS Code를 사용할 때 시스템이 localhost에서 실행 중인 GitLab 인스턴스에 대한 보안 TLS 연결을 설정할 수 없다는 오류가 발생할 수 있습니다.

예를 들어 `127.0.0.1:3000`을 GitLab 서버로 사용 중인 경우:

```plaintext
Request to https://127.0.0.1:3000/api/v4/version failed, reason: Client network
socket disconnected before secure TLS connection was established
```

GDK를 `http`에서 실행 중이고 GitLab 인스턴스가 `https`에서 호스팅되는 경우 이 문제가 발생합니다.

이 문제를 해결하려면:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. `GitLab: Authenticate`을 입력하고 <kbd>Enter</kbd>를 누르세요.
1. 인스턴스에 대해 `http` URL을 수동으로 입력하는 옵션을 선택하고 <kbd>Enter</kbd>를 누르세요.
1. 나머지 프롬프트를 따라 인증하세요.

## 프로젝트 구성 {#project-configuration}

다음과 같은 프로젝트 구성 오류가 발생할 수 있습니다.

### 계정 및 프로젝트 구성 오류 {#account-and-project-configuration-errors}

VS Code에서 프로젝트를 열면 **GitLab** ({{< icon name="tanuki" >}}) 탭의 프로젝트 이름 옆에 오류 메시지가 나타날 수 있습니다. 또는 상태 표시줄에 여러 계정이나 프로젝트에 대한 경고 메시지가 나타날 수 있습니다.

이러한 메시지는 확장 프로그램이 사용할 리포지토리, 계정 또는 프로젝트를 식별할 수 없을 때 나타납니다.

이러한 오류를 해결하려면:

- 원격이 정의되지 않았거나 여러 원격이 구성된 경우 [리포지토리에 연결](setup.md#connect-to-your-repository)을 참조하세요.
- **Multiple GitLab Accounts**이 상태 표시줄에 나타나면 [계정 전환](setup.md#switch-accounts)을 수행하세요.
- **(multiple projects)**이 상태 표시줄에 나타나면 [프로젝트 선택](setup.md#select-a-project)을 수행하세요.

VS Code에서 Git을 처음 사용하는 경우 [VS Code의 소스 제어](https://code.visualstudio.com/docs/sourcecontrol/overview)를 참조하여 GitLab 확장 프로그램 외부에서 수행되는 리포지토리 및 VS Code 워크스페이스 초기화에 대한 정보를 확인하세요.

#### SSH 사용자 지정 별칭이 있는 Git 원격 {#git-remote-with-ssh-custom-alias}

리포지토리 원격이 SSH 사용자 지정 별칭을 사용하는 경우 확장 프로그램이 리포지토리를 GitLab 프로젝트와 올바르게 일치시키지 못할 수 있습니다. 예를 들어 원격이 `git@gitlab.com:group/project.git` 대신 `git@my-work-gitlab:group/project.git`을 사용하는 경우.

이 문제를 해결하려면 다음을 수행할 수 있습니다:

- 원격을 HTTP를 사용하도록 변경하거나 사용자 지정 별칭 없이 SSH를 사용하세요.
- 확장 프로그램에서 기본 GitLab Duo 네임스페이스를 구성하세요.

기본 네임스페이스를 구성하려면:

1. [프로젝트가 있는 네임스페이스 확인](../../user/namespace/_index.md#determine-which-type-of-namespace-youre-in)하세요.
1. VS Code에서 설정 편집기를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. **Extensions** > **GitLab** > **GitLab Duo**를 선택합니다.
1. **GitLab › Duo Agent Platform: 기본 네임스페이스**에서 네임스페이스를 입력하세요.

### HTTPS 프로젝트 복제는 작동하지만 SSH 복제는 실패 {#https-project-cloning-works-but-ssh-cloning-fails}

HTTPS 복제가 작동하는 동안 SSH 복제 오류가 발생할 수 있습니다. SSH URL 호스트 또는 경로가 HTTPS 경로와 다를 때 발생합니다.

GitLab for VS Code 확장 프로그램은 다음을 사용합니다:

- 설정한 계정과 일치하는 호스트입니다.
- 네임스페이스 및 프로젝트 이름을 가져오는 경로입니다.

예를 들어 VS Code 확장 프로그램 프로젝트의 URL은 다음과 같습니다:

- SSH: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- HTTPS: `https://gitlab.com/gitlab-org/gitlab-vscode-extension.git`

둘 다 `gitlab.com` 호스트와 `gitlab-org/gitlab-vscode-extension` 경로를 가집니다.

이 오류를 해결하려면:

1. SSH URL이 다른 호스트에 있는지 또는 경로에 추가 세그먼트가 있는지 확인하세요.
1. 둘 중 하나가 참이면 Git 리포지토리를 GitLab 프로젝트에 수동으로 할당하세요:
   1. VS Code의 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택하세요.
   1. `(no GitLab project)`로 표시된 프로젝트를 선택한 다음 **Manually assign GitLab project**을 선택하세요: ![GitLab 프로젝트 수동 할당](img/manually_assign_v15_3.png)
   1. 목록에서 올바른 프로젝트를 선택하세요.

이 프로세스를 단순화하는 방법에 대한 자세한 내용은 `gitlab-vscode-extension` 프로젝트의 [이슈 577](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/577)을 참조하세요.

## 네트워크 및 연결성 {#network-and-connectivity}

다음과 같은 네트워크 및 연결성 오류가 발생할 수 있습니다.

### 오류: `407 Access Denied` 프록시 실패 {#error-407-access-denied-failure-with-a-proxy}

인증된 프록시를 사용하는 경우 `407 Access Denied (authentication_failed)` 오류가 발생할 수 있습니다.

예를 들어:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

이 오류를 해결하려면 GitLab Language Server에 대해 [프록시 인증을 활성화](../language_server/_index.md#enable-proxy-authentication)하세요.

### 사용자 지정 인증서 오류 {#errors-with-custom-certificates}

자체 서명된 인증서와 같은 사용자 지정 인증서를 사용하여 GitLab 인스턴스에 연결하는 경우 오류가 발생할 수 있습니다.

이러한 오류는 인증서가 다음 설정을 사용하는 경우에 발생할 수 있습니다:

| 설정 이름                     | 정보 |
|----------------------------------|-------------|
| `gitlab.ca`                      | 사용되지 않습니다. 자체 서명된 CA를 설정하는 방법에 대한 자세한 내용은 [SSL 설정 가이드](ssl.md)를 참조하세요.|
| `gitlab.cert`                    | 지원되지 않습니다. [에픽 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)를 참조하세요. |
| `gitlab.certKey`                 | 지원되지 않습니다. [에픽 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)를 참조하세요. |
| `gitlab.ignoreCertificateErrors` | 지원되지 않습니다. [에픽 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)를 참조하세요. |

해결하려면 [사용자 지정 인증서 기관에 대한 확장 프로그램 구성](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/docs/user/custom-certificates.md)을 참조하세요.

### 만료된 SSL 인증서 {#expired-ssl-certificate}

거짓 만료된 SSL 인증서 오류가 발생할 수 있습니다. 예를 들어:

`API request failed - Error: certificate has expired`.

이 오류를 해결하려면 시스템 인증서를 비활성화하세요:

1. VS Code에서 설정 편집기를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. **사용자** 설정 탭에서 **Application** > **Proxy**를 선택하세요.
1. **Proxy Strict SSL** 및 **System Certificates**의 설정을 비활성화하세요.

## GitLab Duo {#gitlab-duo}

VS Code에서 GitLab Duo를 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

### GitLab Duo 기능 사용 불가 {#gitlab-duo-features-are-unavailable}

VS Code에서 GitLab Duo 오류를 해결하려면:

1. [전제 조건](setup.md#configure-gitlab-duo)을 충족하고 필요한 설정이 활성화되었는지 확인하세요.
1. [Admin 모드가 비활성화됨](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)을 확인하세요.
1. 진단 출력을 검토하세요:
   1. VS Code에서 명령 팔레트를 여세요:
      - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
      - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   1. `GitLab: Diagnostics` 명령을 실행하고 실패한 검사에 대한 출력을 검토하세요.
1. 진단에서 기능이 활성화되지 않았음을 나타내는 경우:
   1. VS Code에서 설정 편집기를 엽니다.
      - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
      - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
   1. **Extensions** > **GitLab** > **GitLab Duo**를 선택합니다.
   1. 누락된 기능에 대해 **GitLab ›** 섹션을 찾고 체크박스를 선택하여 활성화하세요.
1. 진단에서 Agentic Chat이 현재 프로젝트에 대해 지원되지 않음을 나타내는 경우 [기본 GitLab Duo 네임스페이스](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)를 설정하세요.
1. 진단에서 모든 Agentic Chat 검사가 통과했는데도 패널이 표시되지 않으면 [사용자 정의 VS Code 레이아웃](https://code.visualstudio.com/docs/configure/custom-layout)에 숨겨져 있을 수 있습니다.
   1. VS Code에서 명령 팔레트를 여세요:
      - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
      - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   1. `View: Show GitLab Duo Agent Platform` 또는 `View: Toggle GitLab Duo Agent Platform` 명령을 실행하세요.

Code Suggestions에 대한 지원은 [Code Suggestions 문제 해결](../../user/project/repository/code_suggestions/troubleshooting.md#vs-code-troubleshooting)을 참조하세요.

### GitLab Duo는 WebSocket 엔드포인트 대신 `HTTP/1.1` 응답을 반환 {#gitlab-duo-returns-http11-responses-instead-of-websocket-endpoints}

GitLab Duo의 로그에서 `/-/cable` WebSocket 엔드포인트 대신 `HTTP/1.1` 응답이 표시될 수 있습니다.

GitLab 인스턴스가 WebSocket 연결을 차단할 때 발생합니다.

이 오류를 해결하려면 네트워크 관리자에게 GitLab 인스턴스를 수정하여 [IDE 클라이언트의 인바운드 WebSocket 연결을 허용](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)하도록 요청하세요.

### GitLab Duo Chat이 원격 환경에서 초기화 실패 {#gitlab-duo-chat-fails-to-initialize-in-remote-environments}

브라우저 기반 VS Code 또는 원격 SSH 연결과 같은 원격 개발 환경에서 GitLab Duo Chat을 사용할 때 다음과 같은 초기화 실패가 발생할 수 있습니다:

- 빈 또는 로드되지 않은 Chat 패널입니다.
- `The webview didn't initialize in 10000ms`과 같은 로그 오류입니다.
- 확장 프로그램이 액세스할 수 없는 로컬 URL에 연결을 시도합니다.

이러한 오류를 해결하려면:

1. VS Code에서 설정 편집기를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. 오른쪽 위 모서리에서 **Open Settings (JSON)**를 선택하여 `settings.json` 파일을 편집하세요.
1. 다음 설정을 추가하거나 수정하세요:

   ```json
   "gitlab.featureFlags.languageServerWebviews": false
   ```

1. 변경 사항을 저장하고 창을 다시 로드하세요:
   1. 명령 팔레트를 여세요:
      - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
      - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   1. `Developer: Reload Window`을 입력하고 <kbd>Enter</kbd>를 누르세요.

영구적인 솔루션의 업데이트는 [이슈 #1944](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1944) 및 [이슈 #1943](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1943)을 참조하세요.

### GitLab Duo 명령이 실패하거나 무한정 실행 {#gitlab-duo-commands-fail-or-run-indefinitely}

IDE에서 GitLab Duo Agentic Chat 또는 Software Development 플로우를 사용할 때 GitLab Duo가 루프에 멈추거나 명령 실행에 어려움을 겪을 수 있습니다.

`Oh My ZSH!` 또는 `powerlevel10k`과 같은 셸 테마 또는 통합을 사용할 때 이 문제가 발생할 수 있습니다. GitLab Duo 에이전트가 터미널을 생성할 때 셸 테마 또는 통합이 명령이 제대로 실행되지 않도록 할 수 있습니다.

해결 방법으로 아래 지침을 따라 에이전트가 보낸 명령에 대해 더 간단한 테마를 사용하세요.

수정에 대한 자세한 내용은 [이슈 2116](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2116)을 참조하세요.

#### `.zshrc` 파일 편집 {#edit-your-zshrc-file}

VS Code에서 `Oh My ZSH!` 또는 `powerlevel10k`을 구성하여 에이전트가 보낸 명령을 실행할 때 더 간단한 테마를 사용하도록 하세요. IDE가 노출하는 환경 변수를 사용하여 이러한 값을 설정할 수 있습니다.

`~/.zshrc` 파일을 편집하여 다음 코드를 포함시키세요:

```shell
# ~/.zshrc

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ...

# Decide whether to load a full terminal environment,
# or keep it minimal for agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"
else
  # Oh My ZSH
  source $ZSH/oh-my-zsh.sh
  # Theme: Powerlevel10k
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  # Other integrations like syntax highlighting
fi

# Other setup, like PATH variables
```

#### Bash 셸 편집 {#edit-your-bash-shell}

VS Code에서 Bash에서 고급 프롬프트를 비활성화할 수 있습니다.

`~/.bashrc` 또는 `~/.bash_profile` 파일을 편집하여 다음 코드를 포함시키세요:

```shell
# ~/.bashrc or ~/.bash_profile

# Decide whether to load a full terminal environment,
# or keep it minimal for Agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"

  # Keep only essential settings for agents
  export PS1='\$ '  # Minimal prompt

else
  # Load full Bash environment

  # Custom prompt (e.g., Starship, custom PS1)
  if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
  else
    # ... Add your own PS1 variable
  fi

  # Load additional integrations
fi

# Always load essential environment variables and aliases
```

## 지원에 필요한 정보 {#required-information-for-support}

지원에 문의하기 전에 최신 GitLab for VS Code 확장 프로그램이 설치되었는지 확인하세요.

[VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)에서 최신 릴리스를 찾으세요. **Version History** 탭에서.

영향을 받은 사용자로부터 다음 정보를 수집하고 버그 보고서에 제공하세요:

1. 사용자에게 표시되는 오류 메시지입니다.
1. **GitLab** 및 **GitLab Language Server** [로그](#logs).
1. 진단 출력.
   1. 명령 팔레트를 여세요:
      - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
      - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   1. `GitLab: Diagnostics`을 입력하고 <kbd>Enter</kbd>를 누르세요.
   1. 확장 프로그램 버전을 기록하세요.
1. 시스템 세부 정보:
   - VS Code에서 **OS** 세부 정보:
     - macOS의 경우 **코드** > **About Visual Studio Code**로 이동하여 **OS**를 찾으세요.
     - Windows 또는 Linux의 경우 **도움말** > **정보**로 이동하여 **OS**를 찾으세요.
   - 머신 사양(CPU, RAM): 머신에서 이를 제공하세요. IDE에서 액세스할 수 없습니다.
1. 영향 범위를 설명하세요. 영향을 받는 사용자가 몇 명입니까?
1. 오류를 재현하는 방법을 설명하세요. 가능하면 화면 녹화를 포함하세요.
1. 다른 GitLab Duo 기능이 어떻게 영향을 받는지 설명하세요:
   - GitLab Quick Chat이 작동합니까?
   - Code Suggestions이 작동합니까?
   - Web IDE의 GitLab Duo Chat이 응답을 반환합니까?
1. [GitLab for VS Code 확장 프로그램 격리 가이드](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/814#step-2-extension-isolation-testing)에 설명된 대로 확장 프로그램 격리 테스트를 수행하세요. 다른 확장 프로그램이 문제를 일으키는지 확인하기 위해 다른 모든 확장 프로그램을 비활성화(또는 제거)해 보세요.
