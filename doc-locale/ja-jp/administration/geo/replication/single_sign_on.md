---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoとシングルサインオン（SSO）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントでは、Geoに固有のSSOの考慮事項と設定についてのみ説明します。一般的な認証の詳細については、[GitLabの認証と認可](../../auth/_index.md)を参照してください。

## インスタンス全体のSAMLの設定 {#configuring-instance-wide-saml}

### 前提要件 {#prerequisites}

[インスタンス全体のSAML](../../../integration/saml.md)がプライマリGeoサイトで動作している必要があります。

プライマリサイトでのみSAMLを設定します。セカンダリサイトの`gitlab.rb`にある`gitlab_rails['omniauth_providers']`を設定しても効果はありません。セカンダリサイトは、プライマリサイトで設定されたSAMLプロバイダーに対して認証を行います。セカンダリサイトの[URLタイプ](#determine-the-type-of-url-your-secondary-site-uses)によっては、プライマリサイトで[追加の設定](#saml-with-separate-url-with-proxying-enabled)が必要になる場合があります。

### セカンダリサイトで使用するURLのタイプの決定 {#determine-the-type-of-url-your-secondary-site-uses}

インスタンス全体のSAMLの設定方法は、セカンダリサイトの設定によって異なります。セカンダリサイトが以下を使用しているかどうかを判断します:

- [統合URL](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites)。これは、`external_url`がプライマリサイトの`external_url`と完全に一致することを意味します。
- プロキシが有効になっている[個別のURL](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site)。GitLab 15.1以降、Geoプロキシはデフォルトで有効になっています。
- プロキシが無効になっている[個別のURL](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site)。

### 統合URLでのSAML {#saml-with-unified-url}

プライマリサイトでSAMLを正しく設定している場合は、追加の設定なしでセカンダリサイトで動作するはずです。

### プロキシが有効になっている個別のURLでのSAML {#saml-with-separate-url-with-proxying-enabled}

{{< alert type="note" >}}

プロキシが有効になっている場合、SAML IDプロバイダー（IdP）が、アプリケーションに複数のコールバックURLを設定できるようにする場合にのみ、SAMLを使用してセカンダリサイトにサインインできます。これに該当するかどうかを確認するには、IdPプロバイダーのサポートチームにお問い合わせください。

{{< /alert >}}

セカンダリサイトがプライマリサイトとは異なる`external_url`を使用している場合は、セカンダリサイトのSAMLコールバックURLを許可するようにSAML IDプロバイダー（IdP）を設定します。たとえば、Oktaを設定するには:

1. [Oktaにサインイン](https://login.okta.com/)。
1. **Okta Admin Dashboard** > **アプリケーション** > **Your App Name**（アプリ名） > **一般**に移動します。
1. **SAML Settings**（SAML設定）で、**編集**を選択します。
1. **一般設定**で、**次へ**を選択して、**SAML Settings**（SAML設定）に移動します。
1. **SAML Settings**（SAML設定） > **一般**で、**Single sign-on URL**（シングルサインオンURL）がプライマリサイトのSAMLコールバックURLであることを確認します。たとえば`https://gitlab-primary.example.com/users/auth/saml/callback`などです。そうでない場合は、このフィールドにプライマリサイトのSAMLコールバックURLを入力します。
1. **Show Advanced Settings**（高度な設定を表示）を選択します。
1. **Other Requestable SSO URLs**（リクエスト可能なその他のSSO URL）に、セカンダリサイトのSAMLコールバックURLを入力します。たとえば`https://gitlab-secondary.example.com/users/auth/saml/callback`などです。**インデックス**には任意の値設定できます。
1. **次へ**、**Finish**（完了）の順に選択します。

プライマリサイトの`gitlab.rb`の`gitlab_rails['omniauth_providers']`にあるSAMLプロバイダーの設定で、`assertion_consumer_service_url`を指定しないでください。例: 

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

この設定により、次のようになります:

- 両方のサイトで、アサーションコンシューマーサービス（ACS）URLとして`/users/auth/saml/callback`を使用します。
- URLのホストが、対応するサイトのホストに設定されます。

各サイトの`/users/auth/saml/metadata`パスにアクセスして、これを確認できます。たとえば、`https://gitlab-primary.example.com/users/auth/saml/metadata`にアクセスすると、次のように応答する場合があります:

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

`https://gitlab-secondary.example.com/users/auth/saml/metadata`にアクセスすると、次のように応答する場合があります:

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

`md:AssertionConsumerService`フィールドの`Location`属性は、`gitlab-secondary.example.com`を指します。

セカンダリサイトのSAMLコールバックURLを許可するようにSAML IdPを設定すると、プライマリサイトとセカンダリサイトでSAMLを使用してサインインできるようになります。

### プロキシが無効になっている個別のURLでのSAML {#saml-with-separate-url-with-proxying-disabled}

プライマリサイトでSAMLを正しく設定している場合は、追加の設定なしでセカンダリサイトで動作するはずです。

## OpenID Connect {#openid-connect}

[OpenID Connect](../../auth/oidc.md) OmniAuthプロバイダーを使用している場合、ほとんどの場合、問題なく動作します:

- **OIDC with Unified URL**（統合URLを使用したOIDC）: プライマリサイトでOIDCを正しく設定している場合は、追加の設定なしでセカンダリサイトで動作するはずです。
- **OIDC with separate URL with proxying disabled**（プロキシが無効になっている個別のURLを使用したOIDC）: プライマリサイトでOIDCを正しく設定している場合は、追加の設定なしでセカンダリサイトで動作するはずです。
- **OIDC with separate URL with proxying enabled**（プロキシが有効になっている個別のURLを使用したOIDC）: プロキシが有効になっている個別のURLを使用したGeoは、[OpenID Connect](../../auth/oidc.md)をサポートしていません。詳細については、[issue 396745](https://gitlab.com/gitlab-org/gitlab/-/issues/396745)を参照してください。

## LDAP {#ldap}

**プライマリ**サイトでLDAPを使用している場合、**セカンダリ**が認証に関連するリクエストを**プライマリ**にプロキシするため、同じLDAP設定が**セカンダリ**サイトにも適用されます。

ディザスターリカバリーのシナリオに備えて、各**セカンダリ**サイトにセカンダリLDAPサーバーをセットアップする必要があります。この場合、**セカンダリ**をプロモートすると、ユーザーはレプリカLDAPサービスを使用して認証できるようになります。そうでない場合、**プライマリ**サイトに接続されているLDAPサービスが、プロモートされた**セカンダリ**サイトで使用できない場合、ユーザーはHTTP Basic認証を使用して、**セカンダリ**サイトでHTTP(s)経由でGit操作を実行できなくなります。ただし、LDAPサービスが利用できない場合に、アカウントが複数のログイン試行の失敗によってロックされない限り、ユーザーはSSHとパーソナルアクセストークンでGitを使用できます。

{{< alert type="note" >}}

すべての**セカンダリ**サイトがLDAPサーバーを共有することも可能ですが、追加のレイテンシーが問題になる可能性があります。また、**セカンダリ**サイトがプロモートされて**プライマリ**サイトになる場合に、[ディザスターリカバリー](../disaster_recovery/_index.md)のシナリオでどのLDAPサーバーが利用可能になるかを検討してください。

{{< /alert >}}

LDAPサービスでのレプリケーションの設定方法については、LDAPサービスのドキュメントを確認してください。このプロセスは、使用するソフトウェアまたはサービスによって異なります。たとえば、OpenLDAPは、この[レプリケーションドキュメント](https://www.openldap.org/doc/admin24/replication.html)を提供しています。
