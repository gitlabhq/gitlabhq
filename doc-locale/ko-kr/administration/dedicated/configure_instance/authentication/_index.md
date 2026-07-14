---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated의 인증 방법을 구성합니다.
title: GitLab Dedicated의 인증
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated에는 두 가지 별도의 인증 콘텍스트가 있습니다:

- Switchboard 인증:  관리자가 GitLab Dedicated 인스턴스를 관리하기 위해 로그인하는 방식입니다.
- 인스턴스 인증:  최종 사용자가 GitLab Dedicated 인스턴스에 로그인하는 방식입니다.

Switchboard는 GitLab Dedicated 인스턴스의 관리 콘솔이며 인스턴스 자체와 별개입니다.

## Switchboard 인증 {#switchboard-authentication}

관리자는 Switchboard를 사용하여 인스턴스, 사용자 및 구성을 관리합니다.

Switchboard는 다음 인증 방법을 지원합니다:

- SAML 또는 OIDC를 사용한 Single Sign-On(SSO)
- 이메일 및 비밀번호

### Switchboard SSO 구성 {#configure-switchboard-sso}

Switchboard의 Single Sign-On(SSO)을 활성화하여 조직의 ID 공급자와 통합합니다. Switchboard는 SAML 및 OIDC 프로토콜을 모두 지원합니다.

> [!note]
> 이는 GitLab Dedicated 인스턴스를 관리하는 Switchboard 관리자를 위한 SSO를 구성합니다.

Switchboard의 SSO를 구성하려면:

1. 선택한 프로토콜에 필요한 정보를 수집합니다:
   - [SAML 매개변수](#saml-parameters-for-switchboard)
   - [OIDC 매개변수](#oidc-parameters-for-switchboard)
1. [지원 티켓 제출](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)하고 정보를 제공합니다.
1. GitLab이 제공하는 정보로 ID 공급자를 구성합니다.

#### Switchboard의 SAML 매개변수 {#saml-parameters-for-switchboard}

SAML 구성을 요청할 때 다음을 제공해야 합니다:

| 매개변수                 | 설명 |
| ------------------------- | ----------- |
| 메타데이터 URL              | ID 공급자의 SAML 메타데이터 문서를 가리키는 URL입니다. 일반적으로 `/saml/metadata.xml`로 끝나거나 ID 공급자의 SSO 구성 섹션에서 사용할 수 있습니다. |
| 이메일 속성 매핑   | ID 공급자가 이메일 주소를 나타내는 데 사용하는 형식입니다. 예를 들어 Auth0에서 이것은 `http://schemas.auth0.com/email`일 수 있습니다. |
| 속성 요청 방법 | ID 공급자에서 속성을 요청할 때 사용해야 하는 HTTP 메서드(GET 또는 POST)입니다. 권장 방법을 보려면 ID 공급자의 설명서를 확인합니다. |
| 사용자 이메일 도메인         | 사용자의 이메일 주소 도메인 부분입니다(예: `gitlab.com`). |

GitLab은 ID 공급자에서 구성할 수 있도록 다음 정보를 제공합니다:

| 매개변수           | 설명 |
| ------------------- | ----------- |
| 콜백/ACS URL    | ID 공급자가 인증 후 SAML 응답을 보내야 하는 URL입니다. |
| 필수 속성 | SAML 응답에 포함되어야 하는 속성입니다. 최소한 `email`에 매핑된 속성이 필요합니다. |

ID 공급자를 구성할 때 SAML 어설션을 암호화해야 합니다. GitLab은 필요할 때 암호화 및 서명 인증서를 제공할 수 있습니다.

인증서 가져오기 단계는 ID 공급자의 설명서를 참조합니다. Entra ID(Azure AD)의 경우 다음을 참조합니다:

- [Microsoft Entra SAML 토큰 암호화 구성](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/howto-saml-token-encryption?tabs=azure-portal)
- [서명된 SAML 인증 요청 적용](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/howto-enforce-signed-saml-authentication)

> [!note]
> GitLab Dedicated는 IdP-시작 SAML을 지원하지 않습니다.

#### Switchboard의 OIDC 매개변수 {#oidc-parameters-for-switchboard}

OIDC 구성을 요청할 때 다음을 제공해야 합니다:

| 매개변수       | 설명 |
| --------------- | ----------- |
| 발급자 URL      | OIDC 공급자를 고유하게 식별하는 기본 URL입니다. 이 URL은 일반적으로 `https://[your-idp-domain]/.well-known/openid-configuration`에 있는 공급자의 검색 문서를 가리킵니다. |
| 토큰 엔드포인트 | 인증 토큰을 얻고 검증하는 데 사용되는 ID 공급자의 특정 URL입니다. 이 엔드포인트는 일반적으로 공급자의 OpenID Connect 구성 설명서에 나열되어 있습니다. |
| 범위          | 인증 중에 요청되는 권한 수준으로, 공유되는 사용자 정보를 결정합니다. 표준 범위에는 `openid`, `email`, 및 `profile`이 포함됩니다. |
| 클라이언트 ID       | ID 공급자에 애플리케이션으로 등록할 때 Switchboard에 할당되는 고유 식별자입니다. 먼저 ID 공급자의 대시보드에서 이 등록을 작성해야 합니다. |
| 클라이언트 암호   | ID 공급자에서 Switchboard를 등록할 때 생성되는 기밀 보안 키입니다. 이 암호는 Switchboard를 ID 공급자에 인증하며 안전하게 보관되어야 합니다. |

GitLab은 ID 공급자에서 구성할 수 있도록 다음 정보를 제공합니다:

| 매개변수              | 설명 |
| ---------------------- | ----------- |
| 리디렉션/콜백 URL | 인증에 성공한 후 ID 공급자가 사용자를 리디렉션해야 하는 URL입니다. 이 항목은 ID 공급자의 허용 리디렉션 URL 목록에 추가되어야 합니다. |
| 필수 클레임        | 인증 토큰 페이로드에 포함되어야 하는 특정 사용자 정보입니다. 최소한 사용자의 이메일 주소에 매핑된 클레임이 필요합니다. |

OIDC 공급자에 따라 추가 구성 세부사항이 필요할 수 있습니다.

### 문제 해결 {#troubleshooting}

Switchboard의 SAML SSO를 구성할 때 다음 이슈가 발생할 수 있습니다.

#### 오류: `Invalid SAML response received...` {#error-invalid-saml-response-received}

이 오류는 Switchboard가 암호화된 SAML 어설션을 예상하지만 ID 공급자가 암호화하도록 구성되지 않았기 때문에 발생합니다:

```plaintext
Invalid SAML response received: Responses must contain exactly one Encrypted Assertion
```

이 이슈를 해결하려면 GitLab에서 제공하는 암호화 인증서가 ID 공급자 애플리케이션 설정에서 가져오고 활성화되도록 합니다.

## 인스턴스 인증 {#instance-authentication}

조직의 사용자가 GitLab Dedicated 인스턴스에 인증하는 방식을 구성합니다.

GitLab Dedicated 인스턴스는 다음 인증 방법을 지원합니다:

- [SAML SSO 구성](saml.md)
- [OIDC 구성](openid_connect.md)
