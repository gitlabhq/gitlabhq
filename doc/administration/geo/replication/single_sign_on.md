---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo with Single Sign On (SSO)
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This documentation only discusses Geo-specific SSO considerations and configuration. For more information on general authentication, see [GitLab authentication and authorization](../../auth/_index.md).

## Configuring instance-wide SAML

### Prerequisites

[Instance-wide SAML](../../../integration/saml.md) must be working on your primary Geo site.

You only configure SAML on the primary site. Configuring `gitlab_rails['omniauth_providers']` in `gitlab.rb` in a secondary site has no effect. The secondary site authenticates against the SAML provider configured on the primary site. Depending on the [URL type](#determine-the-type-of-url-your-secondary-site-uses) of the secondary site, [additional configuration](#saml-with-separate-url-with-proxying-enabled) might be needed on the primary site.

### Determine the type of URL your secondary site uses

How you configure instance-wide SAML differs depending on your secondary site configuration. Determine if your secondary site uses a:

- [Unified URL](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites), meaning the `external_url` exactly matches the `external_url` of the primary site.
- [Separate URL](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) with proxying enabled. Proxying is enabled by default in GitLab 15.1 and later.
- [Separate URL](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) with proxying disabled.

### SAML with Unified URL

If you have configured SAML on the primary site correctly, then it should work on the secondary site without additional configuration.

### SAML with separate URL with proxying enabled

NOTE:
When proxying is enabled, SAML can only be used to sign in the secondary site if your SAML Identity Provider (IdP) allows an
application to have multiple callback URLs configured. Check with your IdP provider support team to confirm if this is the case.

If a secondary site uses a different `external_url` to the primary site, then configure your SAML Identity Provider (IdP) to allow the secondary site's SAML callback URL. For example, to configure Okta:

1. [Sign in to Okta](https://login.okta.com/).
1. Go to **Okta Admin Dashboard** > **Applications** > **Your App Name** > **General**.
1. In **SAML Settings**, select **Edit**.
1. In **General Settings**, select **Next** to go to **SAML Settings**.
1. In **SAML Settings > General**, make sure the **Single sign-on URL** is your primary site's SAML callback URL. For example, `https://gitlab-primary.example.com/users/auth/saml/callback`. If it is not, enter your primary site's SAML callback URL into this field.
1. Select **Show Advanced Settings**.
1. In **Other Requestable SSO URLs**, enter your secondary site's SAML callback URL. For example, `https://gitlab-secondary.example.com/users/auth/saml/callback`. You can set **Index** to anything.
1. Select **Next** and then **Finish**.

You must not specify `assertion_consumer_service_url` in the SAML provider configuration in `gitlab_rails['omniauth_providers']` in `gitlab.rb` of the primary site. For example:

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

This configuration causes:

- Both your sites to use `/users/auth/saml/callback` as their assertion consumer service (ACS) URL.
- The URL's host to be set to the corresponding site's host.

You can check this by visiting each site's `/users/auth/saml/metadata` path. For example, visiting `https://gitlab-primary.example.com/users/auth/saml/metadata` may respond with:

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

Visiting `https://gitlab-secondary.example.com/users/auth/saml/metadata` may respond with:

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

The `Location` attribute of the `md:AssertionConsumerService` field points to `gitlab-secondary.example.com`.

After configuring your SAML IdP to allow the secondary site's SAML callback URL, you should be able to sign in with SAML on your primary site as well as your secondary site.

### SAML with separate URL with proxying disabled

If you have configured SAML on the primary site correctly, then it should work on the secondary site without additional configuration.

## OpenID Connect

If you use an [OpenID Connect (OIDC)](../../auth/oidc.md) OmniAuth provider,
in most cases, it should work without an issue:

- **OIDC with Unified URL**: If you have configured OIDC on the primary site correctly, then it should work on the secondary site without additional configuration.
- **OIDC with separate URL with proxying disabled**: If you have configured OIDC on the primary site correctly, then it should work on the secondary site without additional configuration.
- **OIDC with separate URL with proxying enabled**: Geo with separate URL with proxying enabled does not support [OpenID Connect](../../auth/oidc.md). For more information, see [issue 396745](https://gitlab.com/gitlab-org/gitlab/-/issues/396745).

## LDAP

If you use LDAP on your **primary** site, you should also set up secondary LDAP servers on each **secondary** site. Otherwise, users cannot perform Git operations over HTTP(s) on the **secondary** site using HTTP basic authentication. However, users can still use Git with SSH and personal access tokens.

NOTE:
It is possible for all **secondary** sites to share an LDAP server, but additional latency can be an issue. Also, consider what LDAP server is available in a [disaster recovery](../disaster_recovery/_index.md) scenario if a **secondary** site is promoted to be a **primary** site.

Check your LDAP service documentation for instructions on how to set up replication in your LDAP service. The process differs depending on the software or service used. For example, OpenLDAP provides this [replication documentation](https://www.openldap.org/doc/admin24/replication.html).
