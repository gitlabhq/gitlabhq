---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Visual Studio Code, JetBrains IDE, Visual Studio, Eclipse 및 Neovim용 GitLab 편집기 확장프로그램을 구성합니다."
title: 편집기 확장프로그램 구성
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 인스턴스의 편집기 확장프로그램 설정을 구성합니다.

## OAuth 애플리케이션 만들기 {#create-an-oauth-application}

{{< history >}}

- [GitLab for VS Code 6.47.0](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2738)에서 소개되었습니다.

{{< /history >}}

OAuth 애플리케이션 ID를 사용하여 편집기 확장프로그램을 구성하여 GitLab에 연결하고 인증할 수 있습니다. 구성 단계는 사용 중인 IDE에 따라 다릅니다.

### VS Code {#vs-code}

VS Code용 OAuth 애플리케이션을 만들려면:

1. [인스턴스 전체 애플리케이션](../../integration/oauth_provider.md#create-an-instance-wide-application)을 만듭니다.
1. **Redirect URI**에서 `vscode://gitlab.gitlab-workflow/authentication`을 입력합니다.
   - Code Insiders 또는 Cursor와 같은 추가 IDE를 지정하려면 줄 바꿈으로 구분된 여러 리다이렉트 URI를 추가하세요.
1. `api` 범위를 선택합니다.
1. **제출**을 선택합니다.
1. **애플리케이션 ID**를 복사합니다. VS Code 구성에서 `gitlab.authentication.oauthClientIds` 설정에 이를 사용합니다.

### JetBrains IDE {#jetbrains-ides}

JetBrains IDE용 OAuth 애플리케이션을 만들려면:

1. [인스턴스 전체 애플리케이션](../../integration/oauth_provider.md#create-an-instance-wide-application)을 만듭니다.
1. **Redirect URI**에서 `http://127.0.0.1/api/oauth/gitlab/authorization`을 입력합니다.
1. `api` 범위를 선택합니다.
1. **제출**을 선택합니다.
1. **애플리케이션 ID**를 복사합니다. JetBrains IDE에서 GitLab Duo 플러그인을 구성할 때 이를 사용합니다.

## 최소 언어 서버 버전 요구 {#require-a-minimum-language-server-version}

{{< history >}}

- GitLab 18.1에서 [기능 플래그](../feature_flags/_index.md) 와 함께 [소개](https://gitlab.com/gitlab-org/gitlab/-/issues/541744)되었으며 이름은 `enforce_language_server_version`입니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서는 기본적으로 이 기능을 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 [기능 플래그](../feature_flags/_index.md)를 `enforce_language_server_version`에서 활성화할 수 있습니다. GitLab.com에서는 이 기능을 사용할 수 있지만 GitLab.com 관리자만 구성할 수 있습니다. GitLab Dedicated에서는 이 기능을 사용할 수 있습니다.

기본적으로 개인 액세스 토큰이 활성화된 경우 모든 GitLab Language Server 버전이 GitLab 인스턴스에 연결할 수 있습니다. 이전 버전의 클라이언트의 요청을 차단하려면 최소 언어 서버 버전을 구성합니다. 최소 허용 Language Server 버전보다 이전 버전의 클라이언트는 API 오류를 받습니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

  ```ruby
  # For a specific user
  Feature.enable(:enforce_language_server_version, User.find(1))

  # For this GitLab instance
  Feature.enable(:enforce_language_server_version)
  ```

최소 GitLab Language Server 버전을 적용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **편집기 확장프로그램**을 펼칩니다.
1. **Language Server 제한이 활성화됨**을 선택합니다.
1. **GitLab Language Server 클라이언트의 최소 버전**에서 유효한 GitLab Language Server 버전을 입력합니다.

모든 GitLab Language Server 클라이언트를 허용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **편집기 확장프로그램**을 펼칩니다.
1. **Language Server 제한이 활성화됨**을 선택 해제합니다.
1. **GitLab Language Server 클라이언트의 최소 버전**에서 유효한 GitLab Language Server 버전을 입력합니다.

> [!note]
> 모든 요청을 허용하지 않는 것이 좋습니다. GitLab 버전이 확장프로그램 버전보다 최신인 경우 호환성 문제가 발생할 수 있습니다. 최신 기능 개선, 버그 수정 및 보안 수정을 받으려면 확장프로그램을 업데이트해야 합니다.
