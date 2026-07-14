---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: JWT를 인증 제공자로 사용
description: GitLab에서 Just-In-Time 사용자 프로비저닝을 통해 JWT 기반 SSO 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

JWT OmniAuth 제공자를 활성화하려면 JWT에 애플리케이션을 등록해야 합니다. JWT는 사용할 수 있도록 비밀 키를 제공합니다.

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

1. [공통 설정](../../integration/omniauth.md#configure-common-settings)을 구성하여 `jwt`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 공급자 구성을 추가합니다.

   Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: "jwt",
       label: "Provider name", # optional label for login button, defaults to "Jwt"
       args: {
         secret: "YOUR_APP_SECRET",
         algorithm: "HS256", # Supported algorithms: "RS256", "RS384", "RS512", "ES256", "ES384", "ES512", "HS256", "HS384", "HS512"
         uid_claim: "email",
         required_claims: ["name", "email"],
         info_map: { name: "name", email: "email" },
         auth_url: "https://example.com/",
         valid_within: 3600 # 1 hour
       }
     }
   ]
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
   - { name: 'jwt',
       label: 'Provider name', # optional label for login button, defaults to "Jwt"
       args: {
         secret: 'YOUR_APP_SECRET',
         algorithm: 'HS256', # Supported algorithms: 'RS256', 'RS384', 'RS512', 'ES256', 'ES384', 'ES512', 'HS256', 'HS384', 'HS512'
         uid_claim: 'email',
         required_claims: ['name', 'email'],
         info_map: { name: 'name', email: 'email' },
         auth_url: 'https://example.com/',
         valid_within: 3600 # 1 hour
       }
     }
   ```

   각 구성 옵션에 대한 자세한 내용은 [OmniAuth JWT 사용 설명서](https://github.com/mbleigh/omniauth-jwt#usage)를 참조합니다.

   > [!warning]
   > 이러한 설정을 잘못 구성하면 안전하지 않은 인스턴스가 될 수 있습니다.

1. `YOUR_APP_SECRET`을 클라이언트 비밀로 변경하고 `auth_url`을 리디렉션 URL로 설정합니다.
1. 구성 파일을 저장합니다.
1. 변경 사항을 적용하려면 다음을 수행하세요:
   - Linux 패키지를 사용하여 GitLab을 설치했으면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
   - GitLab을 자체 컴파일로 설치했으면 [GitLab 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

로그인 페이지에서 이제 일반 로그인 양식 아래에 JWT 아이콘이 표시됩니다. 아이콘을 선택하여 인증 프로세스를 시작합니다. JWT는 사용자에게 로그인하고 GitLab 애플리케이션을 승인하도록 요청합니다. 모든 것이 정상이면 사용자가 GitLab으로 리디렉션되어 로그인됩니다.
