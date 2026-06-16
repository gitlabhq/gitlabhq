---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Single Sign On(SSO)을 사용하는 Geo
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 설명서는 Geo 관련 SSO 고려 사항 및 구성만 다룹니다. 일반 인증에 대한 자세한 내용은 [GitLab 인증 및 권한 부여](../../auth/_index.md)를 참조하세요.

## 인스턴스 전체 SAML 구성 {#configuring-instance-wide-saml}

### 필수 요구 사항 {#prerequisites}

[인스턴스 전체 SAML](../../../integration/saml.md)이(가) 프라이머리 Geo 사이트에서 작동해야 합니다.

SAML은 프라이머리 사이트에서만 구성합니다. `gitlab_rails['omniauth_providers']`을(를) 세컨더리 사이트의 `gitlab.rb`에서 구성하면 효과가 없습니다. 세컨더리 사이트는 프라이머리 사이트에 구성된 SAML 공급자에 대해 인증합니다. 세컨더리 사이트의 [URL 유형](#determine-the-type-of-url-your-secondary-site-uses) 에 따라 프라이머리 사이트에서 [추가 구성](#saml-with-separate-url-with-proxying-enabled)이 필요할 수 있습니다.

### 세컨더리 사이트가 사용하는 URL 유형 결정 {#determine-the-type-of-url-your-secondary-site-uses}

인스턴스 전체 SAML을 구성하는 방식은 세컨더리 사이트 구성에 따라 다릅니다. 세컨더리 사이트가 다음 중 어느 것을 사용하는지 결정합니다:

- [통합 URL](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites) - `external_url`이(가) 프라이머리 사이트의 `external_url`과(와) 정확히 일치하는 경우입니다.
- 프록시가 활성화된 [별도 URL](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) GitLab 15.1 이상에서는 프록시가 기본적으로 활성화됩니다.
- 프록시가 비활성화된 [별도 URL](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site)

### 통합 URL을 사용하는 SAML {#saml-with-unified-url}

프라이머리 사이트에서 SAML을 올바르게 구성한 경우 세컨더리 사이트에서 추가 구성 없이 작동해야 합니다.

### 프록시가 활성화된 별도 URL을 사용하는 SAML {#saml-with-separate-url-with-proxying-enabled}

> [!note]
> 프록시가 활성화된 경우, SAML Identity Provider(IdP)에서 애플리케이션이 여러 콜백 URL을 구성할 수 있는 경우에만 SAML을 사용하여 세컨더리 사이트에 로그인할 수 있습니다. 이것이 해당되는지 확인하려면 IdP 공급자 지원팀에 문의하세요.

세컨더리 사이트에서 다른 `external_url`을(를) 프라이머리 사이트로 사용하는 경우, SAML Identity Provider(IdP)를 구성하여 세컨더리 사이트의 SAML 콜백 URL을 허용합니다. 예를 들어, Okta를 구성하려면:

1. [Okta에 로그인](https://login.okta.com/)합니다.
1. **Okta Admin Dashboard** > **응용 프로그램** > **Your App Name** > **일반**로 이동합니다.
1. **SAML Settings**에서 **편집**을(를) 선택합니다.
1. **일반 설정**에서 **다음**을(를) 선택하여 **SAML Settings**로 이동합니다.
1. **SAML Settings** > **일반**에서 **Single sign-on URL**이(가) 프라이머리 사이트의 SAML 콜백 URL인지 확인합니다. 예를 들어, `https://gitlab-primary.example.com/users/auth/saml/callback`. 그렇지 않으면 프라이머리 사이트의 SAML 콜백 URL을 이 필드에 입력합니다.
1. **Show Advanced Settings**를 선택합니다.
1. **Other Requestable SSO URLs**에서 세컨더리 사이트의 SAML 콜백 URL을 입력합니다. 예를 들어, `https://gitlab-secondary.example.com/users/auth/saml/callback`. **인덱스**를 임의의 값으로 설정할 수 있습니다.
1. **다음**을(를) 선택한 다음 **Finish**를 선택합니다.

프라이머리 사이트의 `gitlab_rails['omniauth_providers']`에서 SAML 공급자 구성에 `assertion_consumer_service_url`을(를) 지정하면 안 됩니다. 예를 들어, `gitlab.rb`에서:  예를 들어:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "saml",
    label: "Okta", # optional label for login button, defaults to "Saml"
    args: {
      idp_cert_fingerprint: "B5:AD:AA:9E:3C:05:68:AD:3B:78:ED:31:99:96:96:43:9E:6D:79:96",
      idp_sso_target_url: "https://<dev-account>.okta.com/app/dev-account_gitlabprimary_1/exk7k2gft2VFpVFXa5d1/sso/saml",
      issuer: "https://<gitlab-primary>",
      name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
    }
  }
]
```

이 구성으로 인해:

- 두 사이트 모두 `/users/auth/saml/callback`을(를) 어설션 소비자 서비스(ACS) URL로 사용합니다.
- URL 호스트가 해당 사이트의 호스트로 설정됩니다.

각 사이트의 `/users/auth/saml/metadata` 경로를 방문하여 이를 확인할 수 있습니다. 예를 들어, `https://gitlab-primary.example.com/users/auth/saml/metadata`을(를) 방문하면 다음과 같이 응답할 수 있습니다:

```xml
<md:EntityDescriptor ID="_b9e00d84-d34e-4e3d-95de-122e3c361617" entityID="https://gitlab-primary.example.com"
  xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
  xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
  <md:SPSSODescriptor AuthnRequestsSigned="false" WantAssertionsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://gitlab-primary.example.com/users/auth/saml/callback"    index="0" isDefault="true"/>
    <md:AttributeConsumingService index="1" isDefault="true">
      <md:ServiceName xml:lang="en">Required attributes</md:ServiceName>
      <md:RequestedAttribute FriendlyName="Email address" Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Full name" Name="name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Given name" Name="first_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Family name" Name="last_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
    </md:AttributeConsumingService>
  </md:SPSSODescriptor>
</md:EntityDescriptor>
```

`https://gitlab-secondary.example.com/users/auth/saml/metadata`을(를) 방문하면 다음과 같이 응답할 수 있습니다:

```xml
<md:EntityDescriptor ID="_bf71eb57-7490-4024-bfe2-54cec716d4bf" entityID="https://gitlab-primary.example.com"
  xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
  xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
  <md:SPSSODescriptor AuthnRequestsSigned="false" WantAssertionsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://gitlab-secondary.example.com/users/auth/saml/callback"    index="0" isDefault="true"/>
    <md:AttributeConsumingService index="1" isDefault="true">
      <md:ServiceName xml:lang="en">Required attributes</md:ServiceName>
      <md:RequestedAttribute FriendlyName="Email address" Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Full name" Name="name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Given name" Name="first_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Family name" Name="last_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
    </md:AttributeConsumingService>
  </md:SPSSODescriptor>
</md:EntityDescriptor>
```

`Location` 속성의 `md:AssertionConsumerService` 필드가 `gitlab-secondary.example.com`을(를) 가리킵니다.

세컨더리 사이트의 SAML 콜백 URL을 허용하도록 SAML IdP를 구성한 후 프라이머리 사이트 및 세컨더리 사이트 모두에서 SAML로 로그인할 수 있어야 합니다.

### 프록시가 비활성화된 별도 URL을 사용하는 SAML {#saml-with-separate-url-with-proxying-disabled}

프라이머리 사이트에서 SAML을 올바르게 구성한 경우 세컨더리 사이트에서 추가 구성 없이 작동해야 합니다.

## OpenID Connect {#openid-connect}

[OpenID Connect(OIDC)](../../auth/oidc.md) OmniAuth 공급자를 사용하는 경우, 대부분의 경우 문제 없이 작동해야 합니다:

- **OIDC with Unified URL**:  프라이머리 사이트에서 OIDC를 올바르게 구성한 경우 세컨더리 사이트에서 추가 구성 없이 작동해야 합니다.
- **OIDC with separate URL with proxying disabled**:  프라이머리 사이트에서 OIDC를 올바르게 구성한 경우 세컨더리 사이트에서 추가 구성 없이 작동해야 합니다.
- **OIDC with separate URL with proxying enabled**:  프록시가 활성화된 별도 URL을 사용하는 Geo는 [OpenID Connect](../../auth/oidc.md)를 지원하지 않습니다. 자세한 내용은 [이슈 396745](https://gitlab.com/gitlab-org/gitlab/-/issues/396745)를 참조하세요.

## LDAP {#ldap}

**프라이머리** 사이트에서 LDAP을 사용하는 경우, **세컨더리** 사이트도 동일한 LDAP 구성이 적용됩니다. **세컨더리**가 인증 관련 요청을 **프라이머리**로 프록시하기 때문입니다.

재해 복구 시나리오를 대비하여 각 **세컨더리** 사이트에서 보조 LDAP 서버를 설정해야 합니다. 이 경우 **세컨더리**를 승격할 때 사용자는 복제 LDAP 서비스를 사용하여 인증할 수 있습니다. 그 외에 **프라이머리** 사이트에 연결된 LDAP 서비스를 승격된 **세컨더리** 사이트에서 사용할 수 없으면 사용자는 HTTP 기본 인증을 사용하여 **세컨더리** 사이트에서 HTTP(S)를 통해 Git 작업을 수행할 수 없습니다. 그러나 사용자는 LDAP 서비스를 사용할 수 없을 때 여러 번의 실패한 로그인 시도로 인해 계정이 잠기지 않은 한 SSH 및 개인 액세스 토큰을(를) 사용하여 Git을 계속 사용할 수 있습니다.

> [!note]
> 모든 **세컨더리** 사이트가 LDAP 서버를 공유할 수 있지만 추가 지연이 문제가 될 수 있습니다. 또한 **세컨더리** 사이트가 **프라이머리** 사이트로 승격되는 경우 [재해 복구](../disaster_recovery/_index.md) 시나리오에서 어떤 LDAP 서버를 사용할 수 있는지 고려하세요.

LDAP 서비스 설명서에서 LDAP 서비스의 복제를 설정하는 방법에 대한 지침을 확인합니다. 프로세스는 사용되는 소프트웨어 또는 서비스에 따라 다릅니다. 예를 들어, OpenLDAP는 이 [복제 설명서](https://www.openldap.org/doc/admin24/replication.html)를 제공합니다.
