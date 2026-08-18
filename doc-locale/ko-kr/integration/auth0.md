---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Auth0를 OAuth 2.0 인증 공급자로 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Auth0 OmniAuth 공급자를 활성화하려면 Auth0 계정과 애플리케이션을 생성해야 합니다.

1. [Auth0 Console](https://auth0.com/auth/login)에 로그인합니다. 동일한 링크를 사용하여 계정을 생성할 수도 있습니다.
1. **New App/API**를 선택합니다.
1. **Application Name**을 입력합니다. 예를 들어 'GitLab'입니다.
1. 애플리케이션을 생성한 후 **Quick Start** 옵션을 볼 수 있습니다. 이 옵션들을 무시하고 대신 **설정**을 선택합니다.
1. 설정 화면의 상단에서 Auth0 Console의 **도메인**, **클라이언트 ID**, 그리고 **Client Secret**을 볼 수 있습니다. 이 설정을 기록하여 나중에 구성 파일을 완성합니다. 예를 들어:
   - 도메인: `test1234.auth0.com`
   - 클라이언트 ID: `t6X8L2465bNePWLOvt9yi41i`
   - 클라이언트 보안 암호: `KbveM3nqfjwCbrhaUy_gDu2dss8TIlHIdzlyf33pB7dEK5u_NyQdp65O_o02hXs2`
1. **Allowed Callback URLs**을 입력합니다:
   - `http://<your_gitlab_url>/users/auth/auth0/callback` (또는)
   - `https://<your_gitlab_url>/users/auth/auth0/callback`
1. **Allowed Origins (CORS)**를 입력합니다:
   - `http://<your_gitlab_url>` (또는)
   - `https://<your_gitlab_url>`
1. GitLab 서버에서 구성 파일을 엽니다.

   Linux 패키지 설치의 경우:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `auth0`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 공급자 구성을 추가합니다:

   Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "auth0",
       # label: "Provider name", # optional label for login button, defaults to "Auth0"
       args: {
         client_id: "<your_auth0_client_id>",
         client_secret: "<your_auth0_client_secret>",
         domain: "<your_auth0_domain>",
         scope: "openid profile email"
       }
     }
   ]
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
   - { name: 'auth0',
       # label: 'Provider name', # optional label for login button, defaults to "Auth0"
       args: {
         client_id: '<your_auth0_client_id>',
         client_secret: '<your_auth0_client_secret>',
         domain: '<your_auth0_domain>',
         scope: 'openid profile email' }
     }
   ```

1. `<your_auth0_client_id>`을 Auth0 Console 페이지의 클라이언트 ID로 바꿉니다.
1. `<your_auth0_client_secret>`을 Auth0 Console 페이지의 클라이언트 보안 암호로 바꿉니다.
1. `<your_auth0_domain>`을 Auth0 Console 페이지의 도메인으로 바꿉니다.
1. 설치 방법에 따라 GitLab을 다시 구성하거나 재시작합니다:
   - Linux 패키지를 사용하여 설치한 경우 [GitLab을 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
   - 자체 컴파일된 설치의 경우 [GitLab을 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)합니다.

로그인 페이지에서 일반 로그인 양식 아래에 Auth0 아이콘이 표시되어야 합니다. 아이콘을 선택하여 인증 프로세스를 시작합니다. Auth0는 사용자에게 로그인하고 GitLab 애플리케이션을 승인하도록 요청합니다. 사용자가 성공적으로 인증되면 사용자는 GitLab으로 돌아가고 로그인됩니다.
