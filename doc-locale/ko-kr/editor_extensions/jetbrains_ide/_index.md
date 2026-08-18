---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: JetBrains IDE에서 GitLab Duo를 연결하고 사용합니다.
title: JetBrains IDE용 GitLab Duo 플러그인
---

[GitLab Duo 플러그인](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)은 IntelliJ, PyCharm, GoLand, Webstorm, Rubymine 등의 JetBrains IDE와 GitLab Duo를 통합합니다.

플러그인에는 다음과 같은 기능이 포함됩니다:

- 오른쪽 도구 창 표시줄에서 **GitLab Duo 에이전트 플랫폼**({{< icon name="duo-agentic-chat" >}}):
  - 채팅 탭: GitLab Duo 에이전트 채팅과 상호 작용하거나 **새 채팅** ({{< icon name="duo-chat-new" >}}) 드롭다운 목록을 사용하여 작업할 기초 또는 사용자 지정 에이전트를 선택합니다.
  - 플로우 탭: Software Development 플로우를 사용합니다. [채팅과 플로우의 차이](../../user/duo_agent_platform/flows/foundational_flows/software_development.md#flow-and-chat-comparison)에 대해 자세히 알아보세요.
- 상태 표시줄에서 **Duo** ({{< icon name="tanuki-ai" >}}): GitLab Duo 코드 제안 기능 상태를 확인하고 코드를 작성할 때 파일의 제안을 검토합니다.
- 오른쪽 도구 창 표시줄에서 **GitLab Duo Non-Agentic Chat**({{< icon name="duo-chat" >}}): GitLab Duo 비 에이전트 채팅과 상호 작용합니다. 또는 일부 코드를 선택한 다음 부동 도구 모음에서 **GitLab Duo Quick Chat**({{< icon name="tanuki-ai" >}})을 선택하여 인라인 대화를 나눕니다.

시작하려면 플러그인을 [설치 및 구성](setup.md)합니다.

## 원격 개발 환경과 함께 사용 {#use-with-remote-development}

GitLab Duo 플러그인은 호스트 머신(원격 서버)에 설치되면 JetBrains Remote Development와 함께 작동합니다.

> [!warning]
> 원격 개발 환경을 사용하는 경우 호스트 머신에만 플러그인을 설치합니다. 클라이언트(로컬) 머신에도 플러그인을 설치하면 GitLab Duo 기능이 IDE에서 작동하지 않습니다. 원격 개발 환경에서 플러그인 설치에 대한 정보는 JetBrains 설명서를 참조하세요:

- [원격 프로젝트에서 플러그인 설치](https://www.jetbrains.com/help/idea/work-inside-remote-project.html#plugins).
- [Dev Containers에 플러그인 추가](https://www.jetbrains.com/help/idea/customizing-devcontainer-json-file.html#add_plugins).

## 실험적 또는 베타 기능 활성화 {#enable-experimental-or-beta-features}

플러그인의 일부 기능은 실험 또는 베타 상태입니다. 이를 사용하려면 선택해야 합니다:

1. IDE의 상단 메뉴 표시줄로 이동하여 **설정**을 선택하거나:
   - macOS: <kbd>Command</kbd>+<kbd>,</kbd> 키를 누르세요
   - Windows 또는 Linux: <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd> 키를 누르세요
1. 왼쪽 사이드바에서 **도구**를 확장한 다음 **GitLab Duo**를 선택합니다.
1. **Enable Experiment or BETA features**를 선택합니다.
1. 변경 사항을 적용하려면 IDE를 다시 시작합니다.

## 확장 업데이트 {#update-the-extension}

확장을 최신 버전으로 업데이트하려면:

1. JetBrains IDE에서 **설정** > **Plugins**으로 이동합니다.
1. **Marketplace**에서 **GitLab Duo**(게시자: **GitLab, Inc.**)를 선택합니다.
1. **업데이트**를 선택하여 최신 플러그인 버전으로 업데이트합니다.

## 원격 분석 활성화 {#enable-telemetry}

GitLab Duo 플러그인은 JetBrains IDE의 원격 분석 설정을 사용하여 사용 정보 및 오류 정보를 GitLab에 보냅니다. JetBrains IDE에서 원격 분석을 활성화하려면:

1. IDE의 상단 메뉴 표시줄로 이동하여 **설정**을 선택하세요. 예를 들어 PyCharm에서는 **PyCharm** > **설정**을 선택합니다.
1. 왼쪽 사이드바에서 **도구**를 확장한 다음 **GitLab Duo**를 선택합니다.
1. **고급** 아래에서 **Enable telemetry** 확인란을 선택합니다.
1. **확인** 또는 **적용**을 선택하여 변경 사항을 저장합니다.

## 1Password CLI와 통합 {#integrate-with-1password-cli}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11 이상에서 GitLab Duo 2.1에 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291).

{{< /history >}}

개인 액세스 토큰을 하드코딩하는 대신 1Password 비밀 참조를 사용하도록 플러그인을 구성할 수 있습니다.

전제 조건:

- [1Password](https://1password.com) 데스크톱 앱이 설치되어 있습니다.
- [1Password CLI](https://developer.1password.com/docs/cli/get-started/) 도구가 설치되어 있습니다.

GitLab Duo plugin for JetBrains IDE를 1Password CLI와 통합하려면:

1. GitLab으로 인증합니다. 다음 중 하나를 수행합니다.
   - [`glab` CLI 설치](https://docs.gitlab.com/cli/#install-the-cli)하고 [1Password 셸 플러그인](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)을 구성합니다.
   - GitLab Duo plugin for JetBrains IDE [설정 단계](setup.md)를 따릅니다.
1. 1Password 항목을 엽니다.
1. [비밀 참조 복사](https://developer.1password.com/docs/cli/secret-references/#step-1-copy-secret-references).

   `gitlab` 1Password 셸 플러그인을 사용하는 경우 토큰은 `"op://Private/GitLab Personal Access Token/token"` 아래에 암호로 저장됩니다.

IDE에서:

1. IDE의 상단 메뉴 표시줄로 이동하여 **설정**을 선택하세요.
1. 왼쪽 사이드바에서 **도구**를 확장한 다음 **GitLab Duo**를 선택합니다.
1. **인증** 아래에서 **1Password CLI** 탭을 선택합니다.
1. **Integrate with 1Password CLI**을 선택합니다.
1. 선택 사항. **Secret reference**에 대해 1Password에서 복사한 비밀 참조를 붙여넣습니다.
1. 선택 사항. 자격 증명을 확인하려면 **Verify setup**을 선택합니다.
1. **확인** 또는 **저장**을 선택하세요.

## 플러그인 문제 보고 {#report-issues-with-the-plugin}

[`gitlab-jetbrains-plugin` 이슈 추적기](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues)에서 모든 이슈, 버그 또는 기능 요청을 보고할 수 있습니다. `Bug` 또는 `Feature Proposal` 템플릿을 사용합니다.

GitLab Duo를 사용하는 동안 오류가 발생하면 IDE의 기본 제공 오류 보고 도구로도 보고할 수 있습니다:

1. 도구에 액세스하려면:
   - 오류가 발생하면 오류 메시지에서 **See details and submit report**을 선택합니다.
   - 상태 표시줄의 오른쪽 하단에서 느낌표를 선택합니다.
1. **IDE Internal Errors** 대화 상자에서 오류를 설명합니다.
1. **Report and clear all**를 선택합니다.
1. 브라우저에서 GitLab 이슈 양식이 열리며 디버그 정보가 미리 입력됩니다.
1. 이슈 템플릿의 프롬프트를 따라 설명을 작성하고 가능한 한 많은 컨텍스트를 제공합니다.
1. **이슈 생성**을 선택하여 버그 보고서를 제출합니다.

## 관련 항목 {#related-topics}

- [JetBrains IDE용 GitLab Duo 플러그인 릴리스](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases)
- [에디터 확장에 대한 보안 고려 사항](../security_considerations.md)
- [JetBrains 문제 해결](jetbrains_troubleshooting.md)
- [GitLab 언어 서버 설명서](../language_server/_index.md)
- [이 플러그인에 대한 이슈 열기](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/)
- [플러그인 설명서](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/README.md)
- [소스 코드 보기](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin)
