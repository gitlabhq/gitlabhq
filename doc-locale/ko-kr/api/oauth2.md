---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에 대한 제3자 인증입니다.
title: OAuth 2.0 ID 제공자 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 제3자 서비스가 [OAuth 2.0](https://oauth.net/2/) 프로토콜을 사용하여 사용자의 GitLab 리소스에 접근할 수 있도록 허용합니다. 자세한 내용은 [GitLab을 OAuth 2.0 인증 ID 제공자로 구성](../integration/oauth_provider.md)을 참조하세요.

이 기능은 [doorkeeper Ruby gem](https://github.com/doorkeeper-gem/doorkeeper)을 기반으로 합니다.

## 교차 출처 리소스 공유 {#cross-origin-resource-sharing}

{{< history >}}

- CORS preflight 요청 지원이 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/364680)되었습니다.

{{< /history >}}

많은 `/oauth` 엔드포인트가 교차 출처 리소스 공유(CORS)를 지원합니다. GitLab 15.1부터 다음 엔드포인트도 [CORS preflight 요청](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)을 지원합니다:

- `/oauth/revoke`
- `/oauth/token`
- `/oauth/userinfo`

preflight 요청에는 특정 헤더만 사용할 수 있습니다:

- [단순 요청](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests)에 나열된 헤더입니다.
- `Authorization` 헤더입니다.

예를 들어 `X-Requested-With` 헤더는 preflight 요청에 사용할 수 없습니다.

## 지원되는 OAuth 2.0 플로우 {#supported-oauth-20-flows}

GitLab은 다음 인증 플로우를 지원합니다:

- **[Proof Key for Code Exchange(PKCE)](https://www.rfc-editor.org/rfc/rfc7636)를 사용한 인증 코드**:  가장 안전합니다. PKCE 없으면 모바일 클라이언트에 클라이언트 비밀을 포함해야 하며, 클라이언트 및 서버 앱 모두에 권장됩니다.
- **Authorization code**:  안전하고 일반적인 플로우입니다. 안전한 서버 측 앱에 권장되는 옵션입니다.
- **Device Authorization Grant**(GitLab 17.1 이상) 브라우저 접근이 없는 디바이스를 대상으로 하는 안전한 플로우입니다. 인증 플로우를 완료하려면 보조 디바이스가 필요합니다.

[OAuth 2.1](https://oauth.net/2.1/)의 초안 명세서는 암시적 부여 및 리소스 소유자 비밀번호 자격 증명 플로우를 모두 명시적으로 제외합니다.

[OAuth RFC](https://www.rfc-editor.org/rfc/rfc6749)를 참조하여 모든 플로우의 작동 방식을 이해하고 사용 사례에 맞는 플로우를 선택하세요.

인증 코드(PKCE 포함 또는 미포함) 플로우는 먼저 사용자 계정의 `/user_settings/applications` 페이지를 통해 `application`를 등록해야 합니다. 등록 중에 적절한 범위를 활성화하면 `application`이 접근할 수 있는 리소스의 범위를 제한할 수 있습니다. 생성 후 `application` 자격 증명을 얻습니다:  _Application ID_와 _Client Secret_입니다. _Client Secret_은 **must be kept secure**. 애플리케이션 아키텍처가 허용하는 경우 _Application ID_를 비밀로 유지하는 것도 유리합니다.

GitLab의 범위 목록은 [공급자 문서](../integration/oauth_provider.md#view-all-authorized-applications)를 참조하세요.

### CSRF 공격 방지 {#prevent-csrf-attacks}

[리디렉션 기반 플로우를 보호](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics-13#section-3.1)하기 위해 OAuth 명세서는 `/oauth/authorize` 엔드포인트에 대한 각 요청에서 "상태 매개 변수에 수행된 일회용 CSRF 토큰으로, 사용자 에이전트에 안전하게 바인딩됨"의 사용을 권장합니다. 이는 [CSRF 공격](https://wiki.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF))을 방지할 수 있습니다.

### 프로덕션에서 HTTPS 사용 {#use-https-in-production}

프로덕션의 경우 `redirect_uri`에 HTTPS를 사용합니다. 개발 환경에서는 GitLab이 안전하지 않은 HTTP 리디렉션 URI를 허용합니다.

OAuth 2.0은 전적으로 전송 계층의 보안에 기반하므로 보호되지 않은 URI를 사용하면 안 됩니다. 자세한 내용은 [OAuth 2.0 RFC](https://www.rfc-editor.org/rfc/rfc6749#section-3.1.2.1) 및 [OAuth 2.0 Threat Model RFC](https://www.rfc-editor.org/rfc/rfc6819#section-4.4.2.1)를 참조하세요.

다음 섹션에서는 각 플로우로 인증을 받는 방법에 대한 자세한 지침을 확인할 수 있습니다.

### Proof Key for Code Exchange(PKCE)를 사용한 인증 코드 {#authorization-code-with-proof-key-for-code-exchange-pkce}

{{< history >}}

- OAuth 애플리케이션에 대한 Group SAML SSO 지원이 GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/461212) 되었으며 [플래그](../administration/feature_flags/_index.md) `ff_oauth_redirect_to_sso_login`로 명명되었습니다. 기본적으로 비활성화됨.
- OAuth 애플리케이션에 대한 Group SAML SSO 지원이 GitLab 18.3에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)되었습니다.
- GitLab 18.5에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/issues/561778). 기능 플래그 `ff_oauth_redirect_to_sso_login` 제거됨.

{{< /history >}}

[PKCE RFC](https://www.rfc-editor.org/rfc/rfc7636#section-1.1)는 인증 요청에서 액세스 토큰까지의 자세한 플로우 설명을 포함합니다. 다음 단계는 플로우의 구현을 설명합니다.

PKCE라고 불리는 PKCE를 사용한 인증 코드 플로우는 _Client Secret_에 전혀 접근할 필요 없이 공개 클라이언트에서 클라이언트 자격 증명을 액세스 토큰으로 안전하게 교환할 수 있게 합니다. 이것은 PKCE 플로우를 단일 페이지 JavaScript 애플리케이션 또는 사용자로부터 비밀을 유지하는 것이 기술적으로 불가능한 다른 클라이언트 측 앱에 유리하게 만듭니다.

플로우를 시작하기 전에 `STATE`, `CODE_VERIFIER`, `CODE_CHALLENGE`을 생성합니다.

- `STATE`은 클라이언트가 요청과 콜백 간의 상태를 유지하는 데 사용되는 예측할 수 없는 값입니다. CSRF 토큰으로도 사용되어야 합니다.
- `CODE_VERIFIER`은 길이가 43자에서 128자 사이의 무작위 문자열이며 `A-Z`, `a-z`, `0-9`, `-`, `.`, `_`, `~` 문자를 사용합니다.
- `CODE_CHALLENGE`은 `CODE_VERIFIER`의 SHA256 해시의 URL-안전 base64 인코딩 문자열입니다:
  - SHA256 해시는 인코딩 전에 이진 형식이어야 합니다.
  - Ruby에서는 `Base64.urlsafe_encode64(Digest::SHA256.digest(CODE_VERIFIER), padding: false)`으로 설정할 수 있습니다.
  - 참고로, `CODE_VERIFIER` 문자열 `ks02i3jdikdo2k0dkfodf3m39rjfjsdk0wk349rj3jrhf`을 이전 Ruby 스니펫을 사용하여 해시하고 인코딩하면 `CODE_CHALLENGE` 문자열 `2i0WFA-0AerkjQm4X4oDEhqA17QIAKNjXpagHBXmO_U`이 생성됩니다.

1. 인증 코드를 요청합니다. 이를 위해 사용자를 다음 쿼리 매개 변수와 함께 `/oauth/authorize` 페이지로 리디렉션해야 합니다:

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&code_challenge=CODE_CHALLENGE&code_challenge_method=S256&root_namespace_id=ROOT_NAMESPACE_ID
   ```

   이 페이지는 사용자에게 `REQUESTED_SCOPES`에 지정된 범위에 따라 자신의 계정에 접근하도록 앱의 요청을 승인하도록 요청합니다. 그러면 사용자가 지정된 `REDIRECT_URI`으로 리디렉션됩니다. [범위 매개 변수](../integration/oauth_provider.md#view-all-authorized-applications)는 사용자와 연결된 범위의 공백으로 구분된 목록입니다. 예를 들어 `scope=read_user+profile`은 `read_user` 및 `profile` 범위를 요청합니다. `root_namespace_id`은 프로젝트와 연결된 루트 네임스페이스 ID입니다. 이 선택적 매개 변수는 [SAML SSO](../user/group/saml_sso/_index.md)가 관련 그룹에 대해 구성된 경우 사용해야 합니다. 리디렉션에는 인증 `code`이 포함됩니다. 예를 들어:

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. 이전 요청에서 반환된 인증 `code`(다음 예에서 `RETURNED_CODE`로 표시됨)을 사용하면 모든 HTTP 클라이언트로 `access_token`을 요청할 수 있습니다. 다음 예는 Ruby의 `rest-client`을 사용합니다:

   ```ruby
   parameters = 'client_id=APP_ID&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI&code_verifier=CODE_VERIFIER'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   예시 응답:

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. 새 `access_token`을 검색하려면 `refresh_token` 매개 변수를 사용합니다. Refresh 토큰은 `access_token` 자체가 만료된 후에도 사용할 수 있습니다. 이 요청:
   - 기존 `access_token` 및 `refresh_token`을 무효화합니다.
   - 응답에서 새 토큰을 보냅니다.

   ```ruby
     parameters = 'client_id=APP_ID&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   예시 응답:

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

> [!note]
> `redirect_uri`은 원본 인증 요청에서 사용된 `redirect_uri`과 일치해야 합니다.

이제 액세스 토큰을 사용하여 API에 요청을 할 수 있습니다.

### 인증 코드 플로우 {#authorization-code-flow}

{{< history >}}

- OAuth 애플리케이션에 대한 Group SAML SSO 지원이 GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/461212) 되었으며 [플래그](../administration/feature_flags/_index.md) `ff_oauth_redirect_to_sso_login`로 명명되었습니다. 기본적으로 비활성화됨.
- OAuth 애플리케이션에 대한 Group SAML SSO 지원이 GitLab 18.3에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)되었습니다.
- GitLab 18.5에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/issues/561778). 기능 플래그 `ff_oauth_redirect_to_sso_login` 제거됨.

{{< /history >}}

> [!note]
> 자세한 플로우 설명은 [RFC 명세서](https://www.rfc-editor.org/rfc/rfc6749#section-4.1)를 확인하세요.

인증 코드 플로우는 기본적으로 [PKCE를 사용한 인증 코드 플로우](#authorization-code-with-proof-key-for-code-exchange-pkce)와 동일합니다.

플로우를 시작하기 전에 `STATE`을 생성합니다. 클라이언트가 요청과 콜백 간의 상태를 유지하는 데 사용되는 예측할 수 없는 값입니다. CSRF 토큰으로도 사용되어야 합니다.

1. 인증 코드를 요청합니다. 이를 위해 사용자를 다음 쿼리 매개 변수와 함께 `/oauth/authorize` 페이지로 리디렉션해야 합니다:

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&root_namespace_id=ROOT_NAMESPACE_ID
   ```

   이 페이지는 사용자에게 `REQUESTED_SCOPES`에 지정된 범위에 따라 자신의 계정에 접근하도록 앱의 요청을 승인하도록 요청합니다. 그러면 사용자가 지정된 `REDIRECT_URI`으로 리디렉션됩니다. [범위 매개 변수](../integration/oauth_provider.md#view-all-authorized-applications)는 사용자와 연결된 범위의 공백으로 구분된 목록입니다. 예를 들어 `scope=read_user+profile`은 `read_user` 및 `profile` 범위를 요청합니다. `root_namespace_id`은 프로젝트와 연결된 루트 네임스페이스 ID입니다. 이 선택적 매개 변수는 [SAML SSO](../user/group/saml_sso/_index.md)가 관련 그룹에 대해 구성된 경우 사용해야 합니다. 리디렉션에는 인증 `code`이 포함됩니다. 예를 들어:

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. 이전 요청에서 반환된 인증 `code`(다음 예에서 `RETURNED_CODE`로 표시됨)을 사용하면 모든 HTTP 클라이언트로 `access_token`을 요청할 수 있습니다. 다음 예는 Ruby의 `rest-client`을 사용합니다:

   ```ruby
   parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   예시 응답:

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. 새 `access_token`을 검색하려면 `refresh_token` 매개 변수를 사용합니다. Refresh 토큰은 `access_token` 자체가 만료된 후에도 사용할 수 있습니다. 이 요청:
   - 기존 `access_token` 및 `refresh_token`을 무효화합니다.
   - 응답에서 새 토큰을 보냅니다.

   ```ruby
     parameters = 'client_id=APP_ID&client_secret=APP_SECRET&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   예시 응답:

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

> [!note]
> `redirect_uri`은 원본 인증 요청에서 사용된 `redirect_uri`과 일치해야 합니다.

이제 반환된 액세스 토큰을 사용하여 API에 요청을 할 수 있습니다.

### 디바이스 권한 부여 플로우 {#device-authorization-grant-flow}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/332682) 되었으며 [플래그](../administration/feature_flags/_index.md) `oauth2_device_grant_flow`로 명명되었습니다.
- 17.3에서 기본값으로 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/468479)되었습니다.
- GitLab 17.9에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/505557)됩니다. 기능 플래그 `oauth2_device_grant_flow` 제거됨.

{{< /history >}}

> [!note]
> 디바이스 권한 부여 플로우에 대한 자세한 설명은 [RFC 명세서](https://datatracker.ietf.org/doc/html/rfc8628#section-3.1)를 확인하세요. 디바이스 권한 부여 요청에서 브라우저 로그인의 토큰 응답까지입니다.

디바이스 권한 부여 플로우는 브라우저 상호 작용이 옵션이 아닌 입력 제약이 있는 디바이스에서 GitLab ID를 안전하게 인증할 수 있게 합니다.

이것은 헤드리스 서버 또는 UI가 없거나 제한된 다른 디바이스에서 GitLab 서비스를 사용하려는 사용자에게 디바이스 권한 부여 플로우를 이상적으로 만듭니다.

1. 디바이스 권한 부여를 요청하려면 입력 제한 디바이스 클라이언트에서 `https://gitlab.example.com/oauth/authorize_device`으로 요청을 보냅니다. 예를 들어:

   ```ruby
     parameters = 'client_id=UID&scope=read'
     RestClient.post 'https://gitlab.example.com/oauth/authorize_device', parameters
   ```

   성공한 요청 후 `verification_uri`을 포함하는 응답이 사용자에게 반환됩니다. 예를 들어:

   ```json
   {
       "device_code": "GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS",
       "user_code": "0A44L90H",
       "verification_uri": "https://gitlab.example.com/oauth/device",
       "verification_uri_complete": "https://gitlab.example.com/oauth/device?user_code=0A44L90H",
       "expires_in": 300,
       "interval": 5
   }
   ```

1. 디바이스 클라이언트는 응답에서 `user_code` 및 `verification_uri`을 요청하는 사용자에게 표시합니다. 그 사용자가 그 후 브라우저 접근이 있는 보조 디바이스에서:
   1. 제공된 URI로 이동합니다.
   1. 사용자 코드를 입력합니다.
   1. 메시지가 표시되면 인증을 완료합니다.

1. `verification_uri` 및 `user_code`을 표시한 직후 디바이스 클라이언트는 초기 응답에서 반환된 연결된 `device_code`으로 토큰 엔드포인트를 폴링하기 시작합니다:

   ```ruby
   parameters = 'grant_type=urn:ietf:params:oauth:grant-type:device_code
   &device_code=GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS
   &client_id=1406020730'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

1. 디바이스 클라이언트는 토큰 엔드포인트에서 응답을 받습니다. 인증이 성공하면 성공 응답이 반환되고, 그렇지 않으면 오류 응답이 반환됩니다. 잠재적 오류 응답은 다음 중 하나로 분류됩니다:

   - OAuth 권한 부여 프레임워크 액세스 토큰 오류 응답에서 정의된 것들입니다.
   - 여기에 설명된 디바이스 권한 부여 플로우에 특정된 것들입니다.

   디바이스 플로우에 특정된 이러한 오류 응답은 다음 콘텐츠에 설명됩니다. 각 잠재적 응답에 대한 자세한 내용은 관련 [디바이스 권한 부여 RFC 명세서](https://datatracker.ietf.org/doc/html/rfc8628#section-3.5) 및 [권한 부여 토큰 RFC 명세서](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2)를 참조하세요.

   예시 응답:

   ```json
   {
     "error": "authorization_pending",
     "error_description": "..."
   }
   ```

   이 응답을 수신하면 디바이스 클라이언트는 폴링을 계속합니다.

   폴링 간격이 너무 짧으면 느린 다운 오류 응답이 반환됩니다. 예를 들어:

    ```json
    {
      "error": "slow_down",
      "error_description": "..."
    }
    ```

   이 응답을 수신하면 디바이스 클라이언트는 폴링 속도를 줄이고 새 속도로 폴링을 계속합니다.

   인증이 완료되기 전에 디바이스 코드가 만료되면 만료된 토큰 오류 응답이 반환됩니다. 예를 들어:

   ```json
   {
     "error": "expired_token",
     "error_description": "..."
   }
   ```

   이 시점에서 디바이스 클라이언트는 중지하고 새 디바이스 권한 부여 요청을 시작해야 합니다.

   인증 요청이 거부되면 접근 거부 오류 응답이 반환됩니다. 예를 들어:

   ```json
   {
     "error": "access_denied",
     "error_description": "..."
   }
   ```

   인증 요청이 거부되었습니다. 사용자는 자신의 자격 증명을 확인하거나 시스템 관리자에게 문의해야 합니다

1. 사용자가 성공적으로 인증한 후 성공 응답이 반환됩니다:

   ```json
   {
       "access_token": "TOKEN",
       "token_type": "Bearer",
       "expires_in": 7200,
       "scope": "read",
       "created_at": 1593096829
   }
   ```

이 시점에서 디바이스 인증 플로우가 완료됩니다. 반환된 `access_token`을 HTTPS를 통해 복제하거나 API에 접근할 때와 같이 GitLab 리소스에 접근할 때 GitLab에 제공하여 사용자 ID를 인증할 수 있습니다.

클라이언트 측 디바이스 플로우를 구현하는 샘플 애플리케이션은 <https://gitlab.com/johnwparent/git-auth-over-https>에서 찾을 수 있습니다.

## `access token` 사용하여 GitLab API 접근 {#access-gitlab-api-with-access-token}

`access token`은 사용자를 대신하여 API에 요청을 할 수 있게 해줍니다. GET 매개 변수로 토큰을 전달할 수 있습니다:

```plaintext
GET https://gitlab.example.com/api/v4/user?access_token=<OAUTH-TOKEN>
```

또는 토큰을 Authorization 헤더에 넣을 수 있습니다:

```shell
curl --header "Authorization: Bearer <OAUTH-TOKEN>" \
  --url "https://gitlab.example.com/api/v4/user"
```

## `access token` 사용하여 HTTPS를 통해 Git 접근 {#access-git-over-https-with-access-token}

[범위](../integration/oauth_provider.md#view-all-authorized-applications) `read_repository` 또는 `write_repository`을 가진 토큰은 HTTPS를 통해 Git에 접근할 수 있습니다. 토큰을 비밀번호로 사용합니다. 사용자 이름을 임의의 문자열 값으로 설정할 수 있습니다. `oauth2`을 사용해야 합니다:

```plaintext
https://oauth2:<your_access_token>@gitlab.example.com/project_path/project_name.git
```

또는 [Git 자격 증명 도우미](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)를 사용하여 OAuth를 통해 GitLab에 인증할 수 있습니다. 이는 OAuth 토큰 새로 고침을 자동으로 처리합니다.

## 토큰 정보 검색 {#retrieve-the-token-information}

토큰의 세부 정보를 확인하려면 Doorkeeper gem에서 제공하는 `token/info` 엔드포인트를 사용합니다. 자세한 내용은 [`/oauth/token/info`](https://github.com/doorkeeper-gem/doorkeeper/wiki/API-endpoint-descriptions-and-examples#get----oauthtokeninfo)를 참조하세요.

액세스 토큰을 제공해야 합니다:

- 매개 변수로:

  ```plaintext
  GET https://gitlab.example.com/oauth/token/info?access_token=<OAUTH-TOKEN>
  ```

- Authorization 헤더에서:

  ```shell
  curl --header "Authorization: Bearer <OAUTH-TOKEN>" \
    --url "https://gitlab.example.com/oauth/token/info"
  ```

다음은 응답 예입니다:

```json
{
    "resource_owner_id": 1,
    "scope": ["api"],
    "expires_in": null,
    "application": {"uid": "1cb242f495280beb4291e64bee2a17f330902e499882fe8e1e2aa875519cab33"},
    "created_at": 1575890427
}
```

### 더 이상 사용되지 않는 필드 {#deprecated-fields}

`scopes` 및 `expires_in_seconds` 필드는 응답에 포함되지만 이제 더 이상 사용되지 않습니다. `scopes` 필드는 `scope`의 별칭이고 `expires_in_seconds` 필드는 `expires_in`의 별칭입니다. 자세한 내용은 [Doorkeeper API 변경](https://github.com/doorkeeper-gem/doorkeeper/wiki/Migration-from-old-versions#api-changes-5)를 참조하세요.

## 토큰 취소 {#revoke-a-token}

토큰을 취소하려면 `revoke` 엔드포인트를 사용합니다. API는 200 응답 코드와 빈 JSON 해시를 반환하여 성공을 나타냅니다.

```ruby
parameters = 'client_id=APP_ID&client_secret=APP_SECRET&token=TOKEN'
RestClient.post 'https://gitlab.example.com/oauth/revoke', parameters
```

## OAuth 2.0 토큰 및 GitLab 레지스트리 {#oauth-20-tokens-and-gitlab-registries}

표준 OAuth 2.0 토큰은 GitLab 레지스트리에 대한 다양한 수준의 접근을 지원합니다:

- 사용자가 다음에 인증할 수 없습니다:
  - GitLab [컨테이너 레지스트리](../user/packages/container_registry/authenticate_with_container_registry.md)입니다.
  - GitLab [패키지 레지스트리](../user/packages/package_registry/_index.md)에 나열된 패키지입니다.
  - [가상 레지스트리](../user/packages/virtual_registry/_index.md)입니다.
- 사용자가 [컨테이너 레지스트리 API](container_registry.md)를 통해 레지스트리를 얻고 나열하고 삭제할 수 있습니다.
- 사용자가 [Maven 가상 레지스트리 API](maven_virtual_registries.md)를 통해 레지스트리 객체를 얻고 나열하고 삭제할 수 있습니다.
