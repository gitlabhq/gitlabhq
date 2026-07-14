---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated용 OpenID Connect 단일 로그온(SSO) 인증을 구성합니다.
title: GitLab Dedicated용 OpenID Connect SSO
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated 인스턴스용 OpenID Connect(OIDC) 단일 로그온(SSO)을 구성하여 ID 공급자로 사용자를 인증합니다.

다음과 같은 경우에 OIDC SSO를 사용합니다:

- 기존 ID 공급자를 통해 사용자 인증을 중앙화합니다.
- 사용자의 비밀번호 관리 부담을 줄입니다.
- 조직의 애플리케이션 전반에 걸쳐 일관된 액세스 제어를 구현합니다.
- 광범위한 업계 지원이 있는 최신 인증 프로토콜을 사용합니다.

> [!note]
> 이는 GitLab Dedicated 인스턴스의 최종 사용자를 위해 OIDC를 구성합니다. Switchboard 관리자용 SSO를 구성하려면 [Switchboard SSO 구성](_index.md#configure-switchboard-sso)을 참고하세요.

## OpenID Connect 구성 {#configure-openid-connect}

전제 조건:

- ID 공급자를 설정합니다. GitLab에서 구성 후 콜백 URL을 제공하므로 임시 콜백 URL을 사용할 수 있습니다.
- ID 공급자가 OpenID Connect 사양을 지원하는지 확인합니다.

GitLab Dedicated 인스턴스용 OIDC를 구성하려면:

1. [지원 티켓 생성](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)합니다.
1. 지원 티켓에서 다음 구성을 제공합니다:

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true
   }
   ```

1. 지원 팀이 액세스할 수 있는 비밀 관리자에 대한 임시 링크를 사용하여 Client ID와 Client Secret을 안전하게 제공합니다.
1. ID 공급자가 자동 검색을 지원하지 않으면 클라이언트 엔드포인트 옵션을 포함합니다. 예를 들어:

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://example.com/accounts",
     "discovery": false,
     "client_options": {
       "end_session_endpoint": "https://example.com/logout",
       "authorization_endpoint": "https://example.com/authorize",
       "token_endpoint": "https://example.com/token",
       "userinfo_endpoint": "https://example.com/userinfo",
       "jwks_uri": "https://example.com/jwks"
     }
   }
   ```

GitLab에서 인스턴스용 OIDC를 구성한 후:

1. 지원 티켓에서 콜백 URL을 받습니다.
1. 이 콜백 URL로 ID 공급자를 업데이트합니다.
1. 인스턴스의 로그인 페이지에서 SSO 로그인 버튼을 확인하여 구성을 검증합니다.

## OIDC 그룹 멤버십에 따라 사용자 구성 {#configure-users-based-on-oidc-group-membership}

OIDC 그룹 멤버십에 기반하여 사용자 역할 및 액세스를 할당하도록 GitLab을 구성할 수 있습니다.

전제 조건:

- ID 공급자는 `ID token` 또는 `userinfo` 엔드포인트에 그룹 정보를 포함해야 합니다.
- 기본 OIDC 인증을 이미 구성했어야 합니다.

OIDC 그룹 멤버십에 기반하여 사용자를 구성하려면:

1. `groups_attribute` 매개변수를 추가하여 GitLab에서 그룹 정보를 찾아야 할 위치를 지정합니다.
1. 필요에 따라 적절한 그룹 배열을 구성합니다.
1. 지원 티켓에서 OIDC 블록에 그룹 구성을 포함합니다. 예를 들어:

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true,
     "groups_attribute": "groups",
     "required_groups": [
       "gitlab-users"
     ],
     "external_groups": [
       "external-contractors"
     ],
     "auditor_groups": [
       "auditors"
     ],
     "admin_groups": [
       "gitlab-admins"
     ]
   }
   ```

## 구성 매개변수 {#configuration-parameters}

다음 매개변수는 GitLab Dedicated 인스턴스용 OIDC를 구성하는 데 사용할 수 있습니다. 자세한 내용은 [OpenID Connect를 인증 공급자로 사용](../../../auth/oidc.md)을 참조하세요.

### 필수 매개변수 {#required-parameters}

| 매개변수 | 설명 |
|-----------|-------------|
| `issuer` | ID 공급자의 OpenID Connect 발급자 URL입니다. |
| `label` | 로그인 버튼의 표시 이름입니다. |
| `discovery` | OpenID Connect 검색 사용 여부입니다(권장: `true`). |

### 선택적 매개변수 {#optional-parameters}

| 매개변수 | 설명 | 기본값 |
|-----------|-------------|---------|
| `admin_groups` | 관리자 액세스 권한이 있는 그룹입니다. | `[]` |
| `auditor_groups` | 감사자 액세스 권한이 있는 그룹입니다. | `[]` |
| `client_auth_method` | 클라이언트 인증 방법입니다. | `"basic"` |
| `external_groups` | 외부 사용자로 표시된 그룹입니다. | `[]` |
| `groups_attribute` | OIDC 응답에서 그룹을 찾을 위치입니다. | 없음 |
| `pkce` | PKCE(Code Exchange용 Proof Key)를 활성화합니다. | `false` |
| `required_groups` | 액세스에 필요한 그룹입니다. | `[]` |
| `response_mode` | 인증 응답이 전달되는 방식입니다. | 없음 |
| `response_type` | OAuth 2.0 응답 유형입니다. | `"code"` |
| `scope` | 요청할 OpenID Connect 범위입니다. | `["openid"]` |
| `send_scope_to_token_endpoint` | 토큰 엔드포인트 요청에 범위 매개변수를 포함합니다. | `true` |
| `uid_field` | 고유 식별자로 사용할 필드입니다. | `"sub"` |

### 공급자별 예제 {#provider-specific-examples}

#### Google {#google}

```json
{
  "label": "Google",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://accounts.google.com",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Microsoft Azure AD {#microsoft-azure-ad}

```json
{
  "label": "Azure AD",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://login.microsoftonline.com/your-tenant-id/v2.0",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Okta {#okta}

```json
{
  "label": "Okta",
  "scope": ["openid", "profile", "email", "groups"],
  "response_type": "code",
  "issuer": "https://your-domain.okta.com/oauth2/default",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

## 문제 해결 {#troubleshooting}

OpenID Connect 구성에 이슈가 발생하면:

- ID 공급자가 올바르게 구성되고 액세스 가능한지 확인합니다.
- 지원 팀에 제공한 클라이언트 ID와 비밀이 올바른지 확인합니다.
- ID 공급자의 리다이렉트 URI가 지원 티켓에 제공된 URI와 일치하는지 확인합니다.
- 발급자 URL이 올바르고 액세스 가능한지 확인합니다.
