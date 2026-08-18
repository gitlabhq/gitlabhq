---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Eclipse에서 GitLab Duo를 연결하고 사용합니다.
title: Eclipse용 GitLab 설치 및 설정
---

{{< details >}}

- 티어:  [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- [GitLab 17.11에서 실험에서 베타로 변경되었습니다](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163).
- GitLab 19.0의 일부로 2026년 5월 21일부터 GitLab Duo Core 고객을 대상으로 GitLab Duo Non-Agentic Chat 액세스가 제거됨(`no_duo_classic_for_duo_core_users` 기능 플래그 사용). 기본적으로 활성화됨.

{{< /history >}}

> [!disclaimer]

## Eclipse용 GitLab 플러그인 설치 {#install-the-gitlab-for-eclipse-plugin}

전제 조건:

- Eclipse 4.33 이상
- GitLab 버전 16.8 이상

Eclipse용 GitLab을 설치하려면:

1. Eclipse IDE와 선호하는 웹 브라우저를 엽니다.
1. 웹 브라우저에서 Eclipse Marketplace의 [Eclipse용 GitLab 플러그인](https://marketplace.eclipse.org/content/gitlab-eclipse) 페이지로 이동합니다.
1. 플러그인 페이지에서 **설치**를 선택하고 마우스를 Eclipse IDE로 드래그합니다.
1. **Eclipse Marketplace** 창에서 **GitLab For Eclipse** 카테고리를 선택합니다.
1. **Confirm >**을 선택한 후 **Finish**를 선택합니다.
1. **Trust Authorities** 창이 나타나면 **`https://gitlab.com`** 업데이트 사이트를 선택하고 **Trust Selected**를 선택합니다.
1. **Restart Now**을 선택합니다.

Eclipse Marketplace를 사용할 수 없는 경우 [Eclipse 설치 지침](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.platform.doc.user%2Ftasks%2Ftasks-124.htm)에 따라 새 소프트웨어 사이트를 추가합니다. **Work with**에 `https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases/permalink/latest/downloads/`을 사용합니다.

## GitLab으로 인증 {#authenticate-with-gitlab}

플러그인을 설치한 후 인증하고 GitLab 계정에 연결합니다.

전제 조건:

- `api` 범위가 있는 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)

GitLab으로 인증하려면:

1. IDE에서 환경설정을 엽니다:
   - macOS의 경우 **Eclipse** > **설정**을 선택합니다.
   - Windows 또는 Linux의 경우 **Window** > **환경설정**을 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **연결** 아래에서 GitLab 인스턴스의 URL을 입력합니다. GitLab.com의 경우 `https://gitlab.com`을 사용합니다.
1. **인증** 아래에서 개인 액세스 토큰을 입력합니다. 토큰은 Eclipse 보안 저장소를 사용하여 숨겨지고 저장됩니다.
1. **Verify Setup**을 선택합니다.
1. **Apply and Close**를 선택합니다.
