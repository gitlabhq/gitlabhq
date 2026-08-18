---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Shibboleth을 인증 공급자로 사용하기
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> [GitLab SAML 통합](saml.md)을 사용하여 특정 Shibboleth 신원 공급자(IdP)를 통합합니다. Shibboleth 페더레이션 지원(Discovery Service)의 경우 이 문서를 사용하세요.

GitLab에서 Shibboleth 지원을 활성화하려면 NGINX 대신 Apache를 사용합니다. Apache는 Shibboleth 인증을 위해 `mod_shib2` 모듈을 사용하며 OmniAuth Shibboleth 공급자에 헤더로 속성을 전달할 수 있습니다.

Linux 패키지에 제공되는 번들 NGINX를 사용하여 리버스 프록시 설정을 통해 다른 인스턴스에서 Shibboleth 서비스 공급자를 실행할 수 있습니다. 하지만 이렇게 하지 않으면 번들 NGINX는 구성하기 어렵습니다.

Shibboleth OmniAuth 공급자를 활성화하려면 다음을 수행해야 합니다:

- [Apache 모듈 설치](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335062/Apache)합니다.
- [Apache 모듈 구성](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache)합니다.

Shibboleth를 활성화하려면:

1. OmniAuth Shibboleth 콜백 URL을 보호합니다:

   ```apache
   <Location /users/auth/shibboleth/callback>
     AuthType shibboleth
     ShibRequestSetting requireSession 1
     ShibUseHeaders On
     require valid-user
   </Location>

   Alias /shibboleth-sp /usr/share/shibboleth
   <Location /shibboleth-sp>
     Satisfy any
   </Location>

   <Location /Shibboleth.sso>
     SetHandler shib
   </Location>
   ```

1. Shibboleth URL을 재쓰기에서 제외합니다. `RewriteCond %{REQUEST_URI} !/Shibboleth.sso` 및 `RewriteCond %{REQUEST_URI} !/shibboleth-sp`을 추가합니다. 예제 구성:

   ```apache
   # Apache equivalent of Nginx try files
   RewriteEngine on
   RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_URI} !/Shibboleth.sso
   RewriteCond %{REQUEST_URI} !/shibboleth-sp
   RewriteRule .* http://127.0.0.1:8080%{REQUEST_URI} [P,QSA]
   RequestHeader set X_FORWARDED_PROTO 'https'
   ```

1. Shibboleth를 `/etc/gitlab/gitlab.rb`에 OmniAuth 공급자로 추가합니다. 사용자 속성은 Apache 리버스 프록시에서 Shibboleth 속성 매핑의 이름을 가진 헤더로 GitLab으로 전송됩니다. 따라서 `args` 해시의 값은 `"HTTP_ATTRIBUTE"` 형식이어야 합니다. 해시의 키는 [OmniAuth::Strategies::Shibboleth 클래스](https://github.com/omniauth/omniauth-shibboleth-redux/blob/master/lib/omniauth/strategies/shibboleth.rb)에 대한 인수이며 [`omniauth-shibboleth-redux`](https://github.com/omniauth/omniauth-shibboleth-redux) 젬으로 문서화됩니다(GitLab과 함께 패키징된 젬의 버전을 주의하세요).

   파일은 다음과 같이 표시되어야 합니다:

   ```ruby
   external_url 'https://gitlab.example.com'
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   # disable Nginx
   nginx['enable'] = false

   gitlab_rails['omniauth_allow_single_sign_on'] = true
   gitlab_rails['omniauth_block_auto_created_users'] = false
   gitlab_rails['omniauth_providers'] = [
     {
       "name"  => "shibboleth",
       "label" => "Text for Login Button",
       "args"  => {
           "shib_session_id_field"     => "HTTP_SHIB_SESSION_ID",
           "shib_application_id_field" => "HTTP_SHIB_APPLICATION_ID",
           "uid_field"                 => 'HTTP_EPPN',
           "name_field"                => 'HTTP_CN',
           "info_fields"               => { "email" => 'HTTP_MAIL'}
       }
     }
   ]
   ```

   일부 사용자가 Shibboleth 및 Apache로 인증된 것으로 표시되지만 GitLab이 "e-mail is invalid"를 포함하는 URI와 함께 해당 계정을 거부하면 Shibboleth 신원 공급자 또는 속성 권한이 여러 이메일 주소를 주장할 수 있습니다. 이 경우 `multi_values` 인수를 `first`로 설정하는 것을 고려하세요.
1. 변경 사항을 적용하려면:
   - Linux 패키지 설치의 경우 GitLab을 [재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
   - 자체 컴파일 설치의 경우 GitLab을 [다시 시작](../administration/restart_gitlab.md#self-compiled-installations)합니다.

로그인 페이지에는 이제 **로그인 대상: Shibboleth** 아이콘이 일반 로그인 양식 아래에 표시되어야 합니다. 아이콘을 선택하여 인증 프로세스를 시작하세요. Shibboleth 모듈 구성에 적합한 IdP 서버로 리디렉션됩니다. 모든 것이 잘 진행되면 GitLab으로 돌아가서 로그인됩니다.
