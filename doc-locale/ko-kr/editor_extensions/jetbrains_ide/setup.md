---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: JetBrains IDE에서 GitLab Duo를 연결하고 사용합니다.
title: JetBrains IDE용 GitLab Duo 플러그인 설치 및 설정
---

[JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)에서 플러그인을 다운로드하여 설치합니다.

전제 조건:

- JetBrains IDE: 2025.1 이상
- GitLab 버전 16.8 이상

이전 버전의 JetBrains IDE를 사용하는 경우 IDE와 호환되는 플러그인 버전을 다운로드합니다:

1. GitLab Duo [플러그인 페이지](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)에서 **버전**을 선택합니다.
1. **Compatibility**을 선택한 다음 JetBrains IDE를 선택합니다.
1. **Channel**을 선택하여 안정 릴리스 또는 알파 릴리스로 필터링합니다.
1. 호환성 표에서 IDE 버전을 찾고 **다운로드**를 선택합니다.

## 플러그인 활성화 {#enable-the-plugin}

플러그인을 활성화하려면:

1. IDE에서 상단 표시줄의 IDE 이름을 선택한 다음 **설정**을 선택합니다.
1. 왼쪽 사이드바에서 **Plugins**을 선택합니다.
1. **GitLab Duo** 플러그인을 선택한 다음 **설치**를 선택합니다.
1. **확인** 또는 **저장**을 선택하세요.

## GitLab에 연결 {#connect-to-gitlab}

확장을 설치한 후 GitLab 계정에 연결합니다.

### GitLab으로 인증 {#authenticate-with-gitlab}

전제 조건:

- GitLab Self-Managed 및 GitLab Dedicated에서 OAuth를 사용한 인증:
  - JetBrains용 GitLab Duo 플러그인 3.30.30 이상
  - 인스턴스 범위의 [JetBrains IDE용 OAuth 애플리케이션](../../administration/settings/editor_extensions.md#jetbrains-ides)에 대한 애플리케이션 ID
- 개인 액세스 토큰을(를) 사용한 인증의 경우 `api` 범위가 있는 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)이 필요합니다.
- 1Password를 사용한 인증의 경우 [1Password와 통합하는 단계](_index.md#integrate-with-1password-cli) 완료 및 시크릿 참조

IDE에서 플러그인을 구성한 후 GitLab 계정에 연결합니다:

1. IDE에서 상단 표시줄의 IDE 이름을 선택한 다음 **설정**을 선택합니다.
1. 왼쪽 사이드바에서 **도구**를 확장한 다음 **GitLab Duo**를 선택합니다. 플러그인이 표시되지 않으면 IDE를 다시 시작합니다.
1. **URL to GitLab instance**을(를) 입력합니다. GitLab.com의 경우 `https://gitlab.com`을 사용합니다.
1. 인증 방법으로 **OAuth**, **PAT** 또는 **1Password CLI**를 선택합니다.
   - OAuth의 경우 프롬프트를 따라 로그인하고 인증합니다.
   - PAT의 경우 개인 액세스 토큰을 입력합니다. 토큰 값은 표시되거나 다른 사용자가 접근할 수 없습니다.
   - 1Password의 경우 **Integrate with 1Password CLI**을 선택한 다음 계정을 선택하고 필요에 따라 시크릿 참조를 입력합니다.
1. **Verify setup**을 선택하세요.
1. **확인** 또는 **저장**을 선택하세요.

## GitLab Duo 구성 {#configure-gitlab-duo}

전제 조건:

- 에이전트 기능의 경우 [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites)의 전제 조건을 충족합니다.
- GitLab Duo가 [켜져](../../user/gitlab_duo/turn_on_off.md) 있습니다.
- 플로우의 경우 [기본 플로우가 켜져](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off) 있습니다.
- 에이전트의 경우 [기본 에이전트가 켜져](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) 있고 [사용자 지정 에이전트가 활성화](../../user/duo_agent_platform/agents/custom.md#enable-an-agent)되어 있습니다(필요에 따라).
- 프로젝트가 [네임스페이스 그룹](../../user/namespace/_index.md)에 있습니다.
- [기본 GitLab Duo 네임스페이스](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)가 설정되어 있거나 GitLab Duo 액세스 권한이 있는 프로젝트가 열려 있습니다.

GitLab Duo 기능을 활성화하려면:

1. JetBrains IDE에서 **Settings** > **Tools** > **GitLab Duo**로 이동합니다.
1. 활성화할 기능을 찾아 확인란을 선택합니다.
1. 메시지가 표시되면 IDE를 다시 시작하세요.

GitLab Duo Code Suggestions의 경우 [추가 전제 조건 및 설정 단계를 검토](../../user/project/repository/code_suggestions/set_up.md#prerequisites)합니다.

Agentic Chat 도구를 개별적으로가 아니라 세션당 한 번 승인하려면 [도구 승인](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals)을 참조하세요.

## 플러그인의 알파 버전 설치 {#install-alpha-versions-of-the-plugin}

GitLab은 플러그인의 사전 릴리스(알파) 빌드를 JetBrains Marketplace의 [`Alpha` 릴리스 채널](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/edit/versions/alpha)에 게시합니다.

사전 릴리스 빌드를 설치하려면 다음 중 하나를 수행합니다:

- JetBrains Marketplace에서 빌드를 다운로드하고 [디스크에서 설치](https://www.jetbrains.com/help/idea/managing-plugins.html#install_plugin_from_disk)합니다.
- IDE에 [`alpha` 플러그인 리포지토리를 추가](https://www.jetbrains.com/help/idea/managing-plugins.html#add_plugin_repos)합니다. 리포지토리 URL의 경우 `https://plugins.jetbrains.com/plugins/alpha/list`을(를) 사용합니다.

  > [!note]
  > `alpha` 플러그인 리포지토리를 추가한 후 알파 릴리스를 보려면 GitLab Duo 플러그인을 제거한 후 다시 설치해야 할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 이 프로세스의 비디오 자습서를 보려면 [JetBrains용 GitLab Duo 플러그인 알파 릴리스 설치](https://www.youtube.com/watch?v=Z9AuKybmeRU)를 참조하세요.
<!-- Video published on 2024-04-04 -->
