---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: JetBrains IDE에서 GitLab Duo를 연결하고 사용합니다.
title: JetBrains 문제 해결
---

이 페이지의 단계로 문제가 해결되지 않으면 JetBrains 플러그인 프로젝트에서 [열린 이슈 목록](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)을 확인하세요. 이슈가 문제와 일치하면 해당 이슈를 업데이트하세요. 일치하는 이슈가 없으면 [새로운 이슈를 생성](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/new)하고 [지원 담당자를 위한 필수 정보](#required-information-for-support)를 제공하세요.

## GitLab Duo 기능 사용 불가 {#gitlab-duo-features-are-unavailable}

IDE에서 GitLab Duo 오류를 해결하려면:

1. [전제 조건](setup.md#configure-gitlab-duo)을 충족하고 필요한 설정이 활성화되었는지 확인하세요.
1. [Admin 모드가 비활성화됨](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)을 확인하세요.
1. 진단 출력을 검토하세요:
   - JetBrains IDE에서 **도구** > **GitLab** > **Diagnostics**으로 이동하여 실패한 검사가 있는지 확인하세요.
1. 진단에서 기능이 활성화되지 않았다고 표시되면:
   1. JetBrains IDE에서 **Settings** > **Tools** > **GitLab Duo**로 이동합니다.
   1. 확인란을 찾아서 선택하여 누락된 기능을 활성화하세요.
   1. **확인** 또는 **저장**을 선택하세요.
   1. 메시지가 표시되면 IDE를 다시 시작하세요.
1. 진단에서 Agentic Chat이 현재 프로젝트에서 지원되지 않음을 나타내면 [기본 GitLab Duo 네임스페이스를 설정](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)하세요.
1. JetBrains Remote Development를 사용하고 진단에서 누락된 기능이 활성화되어 있다고 표시되면 GitLab Duo 플러그인이 호스트와 클라이언트 머신 모두에 설치되어 있는지 확인하세요. 설치되어 있으면 클라이언트 머신에서 플러그인을 제거하고 호스트 머신에만 유지하세요. 자세한 내용은 [원격 개발과 함께 사용](_index.md#use-with-remote-development)을 참조하세요.

Code Suggestions에 대한 지원은 [Code Suggestions 문제 해결](../../user/project/repository/code_suggestions/troubleshooting.md#jetbrains-ides-troubleshooting)을 참조하세요.

## 네트워크 문제 {#network-issues}

GitLab Duo에서 `HTTP/1.1` 응답이 로그의 `/-/cable` WebSocket 끝점 대신 표시되면 WebSocket 연결이 차단될 수 있습니다.

GitLab 인스턴스는 IDE 클라이언트로부터의 인바운드 WebSocket 연결을 허용해야 합니다. 문제가 의심되면 네트워크 관리자에게 [GitLab 인스턴스로의 WebSocket 트래픽 허용](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)을 요청하세요.

## IDE 명령어가 실패하거나 무한정 실행됨 {#ide-commands-fail-or-run-indefinitely}

IDE에서 GitLab Duo Agentic Chat 또는 Software Development 플로우를 사용할 때 GitLab Duo가 루프에 갇히거나 명령어 실행에 어려움이 있을 수 있습니다.

이 문제는 `Oh My ZSH!` 또는 `powerlevel10k`과 같은 셸 테마나 통합을 사용할 때 발생할 수 있습니다. GitLab Duo 에이전트가 터미널을 시작할 때 테마나 통합이 명령어가 제대로 실행되지 않도록 할 수 있습니다.

해결 방법으로서 에이전트가 보낸 명령어에 더 간단한 테마를 사용하세요. VS Code 확장 프로젝트의 [이슈 2070](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/2070)은 이 동작의 개선 사항을 추적하므로 이 해결 방법이 더 이상 필요하지 않습니다.

### `.zshrc` 파일 편집 {#edit-your-zshrc-file}

VS Code 및 JetBrains IDE에서 `Oh My ZSH!` 또는 `powerlevel10k`을 구성하여 에이전트가 보낸 명령어를 실행할 때 더 간단한 테마를 사용하도록 합니다. IDE가 노출하는 환경 변수를 사용하여 이러한 값을 설정할 수 있습니다.

`~/.zshrc` 파일을 편집하여 다음 코드를 포함시키세요:

```shell
# ~/.zshrc

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ...

# Decide whether to load a full terminal environment,
# or keep it minimal for agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" || "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
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

## 디버그 모드 활성화 {#enable-debug-mode}

JetBrains에서 디버그 로그를 활성화하려면:

1. 상단 메뉴 표시줄에서 **도움말** > **Diagnostic Tools** > **Debug Log Settings**으로 이동하거나, **도움말** > **Find Action** > **Debug log settings**으로 이동하여 작업을 검색하세요.
1. 다음 줄을 추가하세요: `com.gitlab.plugin`
1. **확인** 또는 **저장**을 선택하세요.

[인증서 오류](#certificate-errors)가 발생하거나 다른 연결 오류가 발생하고 HTTP 프록시를 사용하여 GitLab 인스턴스에 연결하는 경우 GitLab Language Server를 위해 [Language Server가 프록시를 사용하도록 구성](../language_server/_index.md#configure-the-language-server-to-use-a-proxy)해야 합니다.

[프록시 인증 활성화](../language_server/_index.md#enable-proxy-authentication)할 수도 있습니다.

## GitLab Language Server 디버그 로그 활성화 {#enable-gitlab-language-server-debug-logs}

GitLab Language Server 디버그 로그를 활성화하려면:

1. IDE의 상단 메뉴 표시줄에서 IDE 이름을 선택한 후 **설정**을 선택하세요.
1. 왼쪽 사이드바에서 **도구** > **GitLab Duo**를 선택하세요.
1. **GitLab Language Server**를 선택하여 섹션을 확장하세요.
1. **Logging** > **로그 수준**에서 `debug`을 입력하세요.
1. **적용**을 선택하세요.
1. **Enable GitLab Language Server** 아래에서 **Restart Language Server**을 선택하세요.

## 디버그 로그 가져오기 {#get-debug-logs}

디버그 로그는 `idea.log` 로그 파일에서 사용할 수 있습니다. 이 파일을 보려면 다음 중 하나를 수행하세요:

<!-- vale gitlab_base.SubstitutionWarning = NO -->

- IDE에서 **도움말** > **Show Log in Finder**로 이동하세요.
- `/Users/<user>/Library/Logs/JetBrains/IntelliJIdea<build_version>` 디렉토리로 이동하여 `<user>`와 `<build_version>`을 적절한 값으로 바꾸세요.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

## 인증서 오류 {#certificate-errors}

머신이 프록시를 통해 GitLab 인스턴스에 연결되면 JetBrains에서 SSL 인증서 오류가 발생할 수 있습니다. GitLab Duo는 시스템 저장소에서 인증서를 감지하려고 시도하지만 Language Server는 할 수 없습니다. Language Server에서 인증서에 대한 오류가 표시되면 인증 기관(CA) 인증서를 전달하는 옵션을 활성화해 보세요:

이를 수행하려면:

1. IDE의 오른쪽 아래 모서리에서 GitLab 아이콘을 선택하세요.
1. 대화 상자에서 **Show Settings**를 선택하세요. 이것은 **설정** 대화 상자를 **도구** > **GitLab Duo**로 엽니다.
1. **GitLab Language Server**를 선택하여 섹션을 확장하세요.
1. **HTTP Agent Options**을 선택하여 확장하세요.
1. 다음 중 하나를 수행합니다.
   - **Pass CA certificate from Duo to the Language Server** 옵션을 선택하세요.
   - **Certificate authority (CA)**에서 CA 인증서가 포함된 `.pem` 파일의 경로를 지정하세요.
1. IDE를 다시 시작하세요.

### 인증서 오류 무시 {#ignore-certificate-errors}

GitLab Duo가 계속 연결에 실패하면 인증서 오류를 무시해야 할 수도 있습니다. [디버그 모드](jetbrains_troubleshooting.md#enable-debug-mode)를 활성화한 후 GitLab Language Server 로그에서 오류가 표시될 수 있습니다:

```plaintext
2024-10-31T10:32:54:165 [error]: fetch: request to https://gitlab.com/api/v4/personal_access_tokens/self failed with:
request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
FetchError: request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
```

설계상 이 설정은 보안 위험을 나타냅니다. 이 오류는 잠재적 보안 위반을 알려줍니다. 프록시가 문제의 원인임을 절대적으로 확신하는 경우에만 이 설정을 활성화해야 합니다.

전제 조건:

- 시스템 브라우저에서 인증서 체인을 확인했거나 머신 관리자가 이 오류를 무시해도 안전함을 확인했습니다.

이를 수행하려면:

1. [SSL 인증서](https://www.jetbrains.com/help/idea/ssl-certificates.html)에 대한 JetBrains 설명서를 참조하세요.
1. IDE의 상단 메뉴 표시줄로 이동하여 **설정**을 선택하세요.
1. 왼쪽 사이드바에서 **도구** > **GitLab Duo**를 선택하세요.
1. 기본 브라우저가 사용 중인 **URL to GitLab instance**을 신뢰하는지 확인하세요.
1. **Ignore certificate errors** 옵션을 활성화하세요.
1. **Verify setup**을 선택하세요.
1. **확인** 또는 **저장**을 선택하세요.

### PyCharm에서 인증 실패 {#authentication-fails-in-pycharm}

GitLab 인증의 **Verify setup** 단계 중에 문제가 발생하면 지원되는 PyCharm 버전을 실행 중인지 확인하세요:

1. [플러그인 호환성](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions) 페이지로 이동하세요.
1. **Compatibility**의 경우 `PyCharm Community` 또는 `PyCharm Professional`을 선택하세요.
1. **Channels**의 경우 GitLab 플러그인에 원하는 안정성 수준을 선택하세요.
1. PyCharm 버전의 경우 **다운로드**를 선택하여 올바른 GitLab 플러그인 버전을 다운로드하고 설치하세요.

## JCEF 오류 {#jcef-errors}

GitLab Duo Chat과 관련된 JCEF(Java Chromium Embedded Framework) 문제가 발생하면 다음 단계를 시도할 수 있습니다:

1. 상단 메뉴 표시줄에서 **도움말** > **Find Action**로 이동하여 `Registry`를 검색하세요.
1. `ide.browser.jcef.sandbox.enable`을 찾거나 검색하세요.
1. 확인란을 선택하여 이 설정을 비활성화하세요.
1. 레지스트리 대화 상자를 닫으세요.
1. IDE를 다시 시작하세요.
1. 상단 메뉴 표시줄에서 **도움말** > **Find Action**로 이동하여 `Choose Boot Java Runtime for the IDE`를 검색하세요.
1. 현재 IDE 버전과 동일하지만 JCEF가 번들된 부트 Java 런타임 버전을 선택하세요: ![JCEF 지원 런타임 예시](img/jcef_supporting_runtime_example_v17_3.png)
1. IDE를 다시 시작하세요.

## 지원에 필요한 정보 {#required-information-for-support}

지원 담당자에게 문의하기 전에 최신 GitLab Duo 플러그인이 설치되어 있는지 확인하세요. 모든 릴리스는 [JetBrains 마켓플레이스](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions)의 **버전** 탭에서 사용할 수 있습니다.

영향을 받은 사용자로부터 이 정보를 수집하여 버그 보고서에 제공하세요:

1. 사용자에게 표시되는 오류 메시지입니다.
1. 진단 및 로그입니다. 다음 방법 중 하나를 선택하세요:
   - 자동(권장):
     - `GitLab: Export Diagnostics Bundle` 빠른 작업을 실행하세요. GitLab Duo 플러그인 3.27.0 이상에서 사용 가능합니다.
     - 이것은 지정한 위치에 IDE 로그 및 진단이 포함된 zip 파일을 다운로드합니다.
   - 수동:
     - [디버그 로그](#enable-debug-mode)를 활성화하고 수집하세요
     - [Language Server 디버그 로그](#enable-gitlab-language-server-debug-logs)를 활성화하고 수집하세요
     - [로그 출력](#get-debug-logs)을 캡처하세요
     - 빠른 작업 메뉴에서 `GitLab: Diagnostics`을 실행하고 Markdown 출력을 복사하세요
1. 영향 범위를 설명하세요. 영향을 받는 사용자가 몇 명입니까?
1. 오류를 재현하는 방법을 설명하세요. 가능하면 화면 녹화를 포함하세요.
1. 다른 GitLab Duo 기능이 어떻게 영향을 받는지 설명하세요:
   - GitLab Quick Chat이 작동합니까?
   - Code Suggestions이 작동합니까?
   - Web IDE의 GitLab Duo Chat이 응답을 반환합니까?
1. 확장 프로그램 격리 테스트를 수행하세요. 다른 확장 프로그램이 문제를 야기하는지 확인하기 위해 다른 모든 확장 프로그램을 비활성화(또는 제거)해 보세요. 이것은 문제가 당사 확장 프로그램과 관련이 있는지 아니면 외부 소스에서 비롯되었는지 확인하는 데 도움이 됩니다.
