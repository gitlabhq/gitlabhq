---
type: reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SAML OmniAuth Provider **(CORE ONLY)**

This page describes instance-wide SAML for self-managed GitLab instances. For SAML on GitLab.com, see [SAML SSO for GitLab.com groups](../user/group/saml_sso/index.md).

You should also reference the [OmniAuth documentation](omniauth.md) for general settings that apply to all OmniAuth providers.

## Common SAML Terms

| Term | Description |
|------|-------------|
| Identity Provider (IdP) | The service which manages your user identities such as ADFS, Okta, Onelogin, or Ping Identity. |
| Service Provider (SP) | SAML considers GitLab to be a service provider. |
| Assertion | A piece of information about a user's identity, such as their name or role. Also know as claims or attributes. |
| SSO | Single Sign-On. |
| Assertion consumer service URL | The callback on GitLab where users will be redirected after successfully authenticating with the identity provider. |
| Issuer | How GitLab identifies itself to the identity provider. Also known as a "Relying party trust identifier". |
| Certificate fingerprint | Used to confirm that communications over SAML are secure by checking that the server is signing communications with the correct certificate. Also known as a certificate thumbprint. |

## General Setup

GitLab can be configured to act as a SAML 2.0 Service Provider (SP). This allows
GitLab to consume assertions from a SAML 2.0 Identity Provider (IdP) such as
Microsoft ADFS to authenticate users.

First configure SAML 2.0 support in GitLab, then register the GitLab application
in your SAML IdP:

1. Make sure GitLab is configured with HTTPS.
   See [Using HTTPS](../install/installation.md#using-https) for instructions.

1. On your GitLab server, open the configuration file.

   For Omnibus package:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H editor config/gitlab.yml
   ```

1. To allow your users to use SAML to sign up without having to manually create
   an account first, don't forget to add the following values to your configuration:

   For Omnibus package:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
   gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

   For installations from source:

   ```yaml
   omniauth:
     enabled: true
     allow_single_sign_on: ["saml"]
     block_auto_created_users: false
   ```

1. You can also automatically link SAML users with existing GitLab users if their
   email addresses match by adding the following setting:

   For Omnibus package:

   ```ruby
   gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   For installations from source:

   ```yaml
   auto_link_saml_user: true
   ```

1. Ensure that the SAML [`NameID`](../user/group/saml_sso/index.md#nameid) and email address are fixed for each user, as described in the section on [Security](#security). Otherwise, your users will be able to sign in as other authorized users.

1. Add the provider configuration:

   For Omnibus package:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: 'saml',
       args: {
                assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                idp_sso_target_url: 'https://login.example.com/idp',
                issuer: 'https://gitlab.example.com',
                name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
              },
       label: 'Company Login' # optional label for SAML login button, defaults to "Saml"
     }
   ]
   ```

   For installations from source:

   ```yaml
   omniauth:
     providers:
       - {
         name: 'saml',
         args: {
           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
           idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
           idp_sso_target_url: 'https://login.example.com/idp',
           issuer: 'https://gitlab.example.com',
           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
         },
         label: 'Company Login'  # optional label for SAML login button, defaults to "Saml"
       }
   ```

1. Change the value for `assertion_consumer_service_url` to match the HTTPS endpoint
   of GitLab (append `users/auth/saml/callback` to the HTTPS URL of your GitLab
   installation to generate the correct value).

1. Change the values of `idp_cert_fingerprint`, `idp_sso_target_url`,
   `name_identifier_format` to match your IdP. If a fingerprint is used it must
   be a SHA1 fingerprint; check
   [the OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml)
   for more details on these options.

1. Change the value of `issuer` to a unique name, which will identify the application
   to the IdP.

1. For the changes to take effect, you must [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab if you installed via Omnibus or [restart GitLab](../administration/restart_gitlab.md#installations-from-source) if you installed from source.

1. Register the GitLab SP in your SAML 2.0 IdP, using the application name specified
   in `issuer`.

To ease configuration, most IdP accept a metadata URL for the application to provide
configuration information to the IdP. To build the metadata URL for GitLab, append
`users/auth/saml/metadata` to the HTTPS URL of your GitLab installation, for instance:

```plaintext
https://gitlab.example.com/users/auth/saml/metadata
```

At a minimum the IdP *must* provide a claim containing the user's email address, using
claim name `email` or `mail`. The email will be used to automatically generate the GitLab
username. GitLab will also use claims with name `name`, `first_name`, `last_name`
(see [the OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)
for supported claims).

On the sign in page there should now be a SAML button below the regular sign in form.
Click the icon to begin the authentication process. If everything goes well the user
will be returned to GitLab and will be signed in.

## SAML Groups

You can require users to be members of a certain group, or assign users `external`, `admin` or `auditor` roles based on group membership. This feature **does not** allow you to
automatically add users to GitLab [Groups](../user/group/index.md).

### Requirements

First you need to tell GitLab where to look for group information. For this you
need to make sure that your IdP server sends a specific `AttributeStatement` along
with the regular SAML response. Here is an example:

```xml
<saml:AttributeStatement>
  <saml:Attribute Name="Groups">
    <saml:AttributeValue xsi:type="xs:string">Developers</saml:AttributeValue>
    <saml:AttributeValue xsi:type="xs:string">Freelancers</saml:AttributeValue>
    <saml:AttributeValue xsi:type="xs:string">Admins</saml:AttributeValue>
    <saml:AttributeValue xsi:type="xs:string">Auditors</saml:AttributeValue>
  </saml:Attribute>
</saml:AttributeStatement>
```

The name of the attribute can be anything you like, but it must contain the groups
to which a user belongs. In order to tell GitLab where to find these groups, you need
to add a `groups_attribute:` element to your SAML settings.

### Required groups **(STARTER ONLY)**

Your IdP passes Group Information to the SP (GitLab) in the SAML Response. You need to configure GitLab to identify:

- Where to look for the groups in the SAML response via the `groups_attribute` setting
- Which group membership is requisite to sign in via the `required_groups` setting

When `required_groups` is not set or it is empty, anyone with proper authentication
will be able to use the service.

Example:

```yaml
{ name: 'saml',
  label: 'Our SAML Provider',
  groups_attribute: 'Groups',
  required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
  args: {
          assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
          idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
          idp_sso_target_url: 'https://login.example.com/idp',
          issuer: 'https://gitlab.example.com',
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
  } }
```

### External Groups **(STARTER ONLY)**

SAML login supports automatic identification on whether a user should be considered an [external](../user/permissions.md) user. This is based on the user's group membership in the SAML identity provider.

```yaml
{ name: 'saml',
  label: 'Our SAML Provider',
  groups_attribute: 'Groups',
  external_groups: ['Freelancers'],
  args: {
          assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
          idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
          idp_sso_target_url: 'https://login.example.com/idp',
          issuer: 'https://gitlab.example.com',
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
  } }
```

### Admin Groups **(STARTER ONLY)**

The requirements are the same as the previous settings, your IdP needs to pass Group information to GitLab, you need to tell
GitLab where to look for the groups in the SAML response, and which group(s) should be
considered admin users.

```yaml
{ name: 'saml',
  label: 'Our SAML Provider',
  groups_attribute: 'Groups',
  admin_groups: ['Admins'],
  args: {
          assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
          idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
          idp_sso_target_url: 'https://login.example.com/idp',
          issuer: 'https://gitlab.example.com',
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
  } }
```

### Auditor Groups **(STARTER ONLY)**

> Introduced in [GitLab Starter](https://about.gitlab.com/pricing/) 11.4.

The requirements are the same as the previous settings, your IdP needs to pass Group information to GitLab, you need to tell
GitLab where to look for the groups in the SAML response, and which group(s) should be
considered auditor users.

```yaml
{ name: 'saml',
  label: 'Our SAML Provider',
  groups_attribute: 'Groups',
  auditor_groups: ['Auditors'],
  args: {
          assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
          idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
          idp_sso_target_url: 'https://login.example.com/idp',
          issuer: 'https://gitlab.example.com',
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
  } }
```

## Bypass two factor authentication

If you want some SAML authentication methods to count as 2FA on a per session basis, you can register them in the
`upstream_two_factor_authn_contexts` list.

In addition to the changes in GitLab, make sure that your IdP is returning the
`AuthnContext`. For example:

```xml
<saml:AuthnStatement>
    <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:MediumStrongCertificateProtectedTransport</saml:AuthnContextClassRef>
    </saml:AuthnContext>
</saml:AuthnStatement>
```

**For Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: 'saml',
       args: {
                assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                idp_sso_target_url: 'https://login.example.com/idp',
                issuer: 'https://gitlab.example.com',
                name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                upstream_two_factor_authn_contexts:
                  %w(
                    urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                    urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                    urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
                  )

              },
       label: 'Company Login' # optional label for SAML login button, defaults to "Saml"
     }
   ]
   ```

1. Save the file and [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

---

**For installations from source:**

1. Edit `config/gitlab.yml`:

   ```yaml
   omniauth:
     providers:
       - {
         name: 'saml',
         args: {
           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
           idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
           idp_sso_target_url: 'https://login.example.com/idp',
           issuer: 'https://gitlab.example.com',
           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
           upstream_two_factor_authn_contexts:
             [
               'urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport',
               'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS',
               'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN'
             ]
         },
         label: 'Company Login'  # optional label for SAML login button, defaults to "Saml"
       }
   ```

1. Save the file and [restart GitLab](../administration/restart_gitlab.md#installations-from-source) for the changes to take effect

## Customization

### `auto_sign_in_with_provider`

You can add this setting to your GitLab configuration to automatically redirect you
to your SAML server for authentication, thus removing the need to click a button
before actually signing in.

For Omnibus package:

```ruby
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
```

For installations from source:

```yaml
omniauth:
  auto_sign_in_with_provider: saml
```

Keep in mind that every sign in attempt will be redirected to the SAML server;
you won't be able to sign in using local credentials. Ensure at least one of the
SAML users has admin permissions.

You may also bypass the auto sign-in feature by browsing to
`https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

### `attribute_statements`

NOTE: **Note:**
This setting should be used only to map attributes that are part of the OmniAuth
`info` hash schema.

`attribute_statements` is used to map Attribute Names in a SAMLResponse to entries
in the OmniAuth [`info` hash](https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later).

For example, if your SAMLResponse contains an Attribute called 'EmailAddress',
specify `{ email: ['EmailAddress'] }` to map the Attribute to the
corresponding key in the `info` hash. URI-named Attributes are also supported, e.g.
`{ email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] }`.

This setting allows you tell GitLab where to look for certain attributes required
to create an account. Like mentioned above, if your IdP sends the user's email
address as `EmailAddress` instead of `email`, let GitLab know by setting it on
your configuration:

```yaml
args: {
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
        idp_sso_target_url: 'https://login.example.com/idp',
        issuer: 'https://gitlab.example.com',
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        attribute_statements: { email: ['EmailAddress'] }
}
```

#### Setting a username

By default, the email in the SAML response will be used to automatically generate the user's GitLab username. If you'd like to set another attribute as the username, assign it to the `nickname` OmniAuth `info` hash attribute. For example, if you wanted to set the `username` attribute in your SAML Response to the username in GitLab, use the following setting:

```yaml
args: {
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
        idp_sso_target_url: 'https://login.example.com/idp',
        issuer: 'https://gitlab.example.com',
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        attribute_statements: { nickname: ['username'] }
}
```

### `allowed_clock_drift`

The clock of the Identity Provider may drift slightly ahead of your system clocks.
To allow for a small amount of clock drift you can use `allowed_clock_drift` within
your settings. Its value must be given in a number (and/or fraction) of seconds.
The value given is added to the current time at which the response is validated.

```yaml
args: {
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
        idp_sso_target_url: 'https://login.example.com/idp',
        issuer: 'https://gitlab.example.com',
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        attribute_statements: { email: ['EmailAddress'] },
        allowed_clock_drift: 1  # for one second clock drift
}
```

### `uid_attribute`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17734) in GitLab 10.7.

By default, the `uid` is set as the `name_id` in the SAML response. If you'd like to designate a unique attribute for the `uid`, you can set the `uid_attribute`. In the example below, the value of `uid` attribute in the SAML response is set as the `uid_attribute`.

```yaml
args: {
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
        idp_sso_target_url: 'https://login.example.com/idp',
        issuer: 'https://gitlab.example.com',
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        uid_attribute: 'uid'
}
```

Make sure you read the [Security](#security) section before changing this value.

## Response signature validation (required)

We require Identity Providers to sign SAML responses to ensure that the assertions are
not tampered with.

This prevents user impersonation and prevents privilege escalation when specific group
membership is required. Typically this:

- Is configured using `idp_cert_fingerprint`.
- Includes the full certificate in the response, although if your Identity Provider
  doesn't support this, you can directly configure GitLab using the `idp_cert` option.

Example configuration with `idp_cert_fingerprint`:

```yaml
args: {
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
  idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
  idp_sso_target_url: 'https://login.example.com/idp',
  issuer: 'https://gitlab.example.com',
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
}
```

Example configuration with `idp_cert`:

```yaml
args: {
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
  idp_cert: '-----BEGIN CERTIFICATE-----
    <redacted>
    -----END CERTIFICATE-----',
  idp_sso_target_url: 'https://login.example.com/idp',
  issuer: 'https://gitlab.example.com',
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
}
```

If the response signature validation is configured incorrectly, you can see error messages
such as:

- A key validation error.
- Digest mismatch.
- Fingerprint mismatch.

Refer to the [troubleshooting section](#troubleshooting) for more information on
debugging these errors.

## Assertion Encryption (optional)

GitLab requires the use of TLS encryption with SAML, but in some cases there can be a
need for additional encryption of the assertions.

This may be the case, for example, if you terminate TLS encryption early at a load
balancer and include sensitive details in assertions that you do not want appearing
in logs. Most organizations should not need additional encryption at this layer.

The SAML integration supports EncryptedAssertion. You need to define the private key and the public certificate of your GitLab instance in the SAML settings:

```yaml
args: {
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
  idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
  idp_sso_target_url: 'https://login.example.com/idp',
  issuer: 'https://gitlab.example.com',
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
  certificate: '-----BEGIN CERTIFICATE-----
    <redacted>
    -----END CERTIFICATE-----',
  private_key: '-----BEGIN PRIVATE KEY-----
    <redacted>
    -----END PRIVATE KEY-----'
}
```

Your Identity Provider will encrypt the assertion with the public certificate of GitLab. GitLab will decrypt the EncryptedAssertion with its private key.

NOTE: **Note:**
This integration uses the `certificate` and `private_key` settings for both assertion encryption and request signing.

## Request signing (optional)

Another optional configuration is to sign SAML authentication requests. GitLab
SAML Requests use the SAML redirect binding, so this isn't necessary (unlike the
SAML POST binding, where signing is required to prevent intermediaries from
tampering with the requests).

To sign, you need to create a private key and public certificate pair for your
GitLab instance to use for SAML. The settings for signing can be set in the
`security` section of the configuration.

For example:

```yaml
args: {
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
  idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
  idp_sso_target_url: 'https://login.example.com/idp',
  issuer: 'https://gitlab.example.com',
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
  certificate: '-----BEGIN CERTIFICATE-----
    <redacted>
    -----END CERTIFICATE-----',
  private_key: '-----BEGIN PRIVATE KEY-----
    <redacted>
    -----END PRIVATE KEY-----',
  security: {
    authn_requests_signed: true,  # enable signature on AuthNRequest
    want_assertions_signed: true,  # enable the requirement of signed assertion
    embed_sign: true,  # embedded signature or HTTP GET parameter signature
    metadata_signed: false,  # enable signature on Metadata
    signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
    digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
  }
}
```

GitLab will sign the request with the provided private key. GitLab will include the configured public x500 certificate in the metadata for your Identity Provider to validate the signature of the received request with. For more information on this option, see the [Ruby SAML gem documentation](https://github.com/onelogin/ruby-saml/tree/v1.7.0). The Ruby SAML gem is used by the [OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml) to implement the client side of the SAML authentication.

## Security

Avoid user control of the following attributes:

- [`*NameID*`](../user/group/saml_sso/index.md#nameid)
- *Email* when used with `omniauth_auto_link_saml_user`

These attributes define the SAML user. If users can change these attributes, they can impersonate others.

Refer to the documentation for your SAML Identity Provider for information on how to fix these attributes.

## Passwords for users created via SAML

The [Generated passwords for users created through integrated authentication](../security/passwords_for_integrated_authentication_methods.md) guide provides an overview of how GitLab generates and sets passwords for users created via SAML.

## Configuring Group SAML on a self-managed GitLab instance **(PREMIUM ONLY)**

For information on the GitLab.com implementation, please see the [SAML SSO for GitLab.com groups page](../user/group/saml_sso).

Group SAML SSO helps if you need to allow access via multiple SAML identity providers, but as a multi-tenant solution is less suited to cases where you administer your own GitLab instance.

To proceed with configuring Group SAML SSO instead, you'll need to enable the `group_saml` OmniAuth provider. This can be done from:

- `gitlab.rb` for [Omnibus GitLab installations](#omnibus-installations).
- `gitlab/config/gitlab.yml` for [source installations](#source-installations).

### Limitations

Group SAML on a self-managed instance is limited when compared to the recommended
[instance-wide SAML](../user/group/saml_sso/index.md). The recommended solution allows you to take advantage of:

- [LDAP compatibility](../administration/auth/ldap/index.md).
- [LDAP Group Sync](../user/group/index.md#manage-group-memberships-via-ldap).
- [Required groups](#required-groups).
- [Admin groups](#admin-groups).
- [Auditor groups](#auditor-groups).

### Omnibus installations

1. Make sure GitLab is
   [configured with HTTPS](../install/installation.md#using-https).
1. Enable OmniAuth and the `group_saml` provider in `gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

### Source installations

1. Make sure GitLab is
   [configured with HTTPS](../install/installation.md#using-https).
1. Enable OmniAuth and the `group_saml` provider in `gitlab/config/gitlab.yml`:

    ```yaml
    omniauth:
      enabled: true
      providers:
        - { name: 'group_saml' }
    ```

## Troubleshooting

### SAML Response

You can find the base64-encoded SAML Response in the [`production_json.log`](../administration/logs.md#production_jsonlog). This response is sent from the IdP, and contains user information that is consumed by GitLab. Many errors in the SAML integration can be solved by decoding this response and comparing it to the SAML settings in the GitLab configuration file.

### GitLab+SAML Testing Environments

If you need to troubleshoot, [a complete GitLab+SAML testing environment using Docker compose](https://gitlab.com/gitlab-com/support/toolbox/replication/tree/master/compose_files) is available.

If you only need a SAML provider for testing, a [quick start guide to start a Docker container](../administration/troubleshooting/test_environments.md#saml) with a plug and play SAML 2.0 Identity Provider (IdP) is available.

### 500 error after login

If you see a "500 error" in GitLab when you are redirected back from the SAML
sign-in page, this likely indicates that GitLab couldn't get the email address
for the SAML user.

Ensure the IdP provides a claim containing the user's email address, using the
claim name `email` or `mail`.

### Redirect back to the login screen with no evident error

If after signing in into your SAML server you are redirected back to the sign in page and
no error is displayed, check your `production.log` file. It will most likely contain the
message `Can't verify CSRF token authenticity`. This means that there is an error during
the SAML request, but in GitLab 11.7 and earlier this error never reaches GitLab due to
the CSRF check.

To bypass this you can add `skip_before_action :verify_authenticity_token` to the
`omniauth_callbacks_controller.rb` file immediately after the `class` line and
comment out the `protect_from_forgery` line using a `#`. Restart Unicorn for this
change to take effect. This will allow the error to hit GitLab, where it can then
be seen in the usual logs, or as a flash message on the login screen.

That file is located in `/opt/gitlab/embedded/service/gitlab-rails/app/controllers`
for Omnibus installations and by default in `/home/git/gitlab/app/controllers` for
installations from source. Restart Unicorn using the `sudo gitlab-ctl restart unicorn`
command on Omnibus installations and `sudo service gitlab restart` on installations
from source.

You may also find the [SAML Tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/)
(Firefox) and [SAML Chrome Panel](https://chrome.google.com/webstore/detail/saml-chrome-panel/paijfdbeoenhembfhkhllainmocckace)
(Chrome) browser extensions useful in your debugging.

### Invalid audience

This error means that the IdP doesn't recognize GitLab as a valid sender and
receiver of SAML requests. Make sure to add the GitLab callback URL to the approved
audiences of the IdP server.

### Missing claims, or `Email can't be blank` errors

The IdP server needs to pass certain information in order for GitLab to either
create an account, or match the login information to an existing account. `email`
is the minimum amount of information that needs to be passed. If the IdP server
is not providing this information, all SAML requests will fail.

Make sure this information is provided.

Another issue that can result in this error is when the correct information is being sent by the IdP, but the attributes don't match the names in the OmniAuth `info` hash. In this case, you'll need to set `attribute_statements` in the SAML configuration to [map the attribute names in your SAML Response to the corresponding OmniAuth `info` hash names](#attribute_statements).

### Key validation error, Digest mismatch or Fingerprint mismatch

These errors all come from a similar place, the SAML certificate. SAML requests
need to be validated using a fingerprint, a certificate or a validator.

For this you need take the following into account:

- If a fingerprint is used, it must be the SHA1 fingerprint
- If no certificate is provided in the settings, a fingerprint or fingerprint
  validator needs to be provided and the response from the server must contain
  a certificate (`<ds:KeyInfo><ds:X509Data><ds:X509Certificate>`)
- If a certificate is provided in the settings, it is no longer necessary for
  the request to contain one. In this case the fingerprint or fingerprint
  validators are optional

Make sure that one of the above described scenarios is valid, or the requests will
fail with one of the mentioned errors.

### User is blocked when signing in through SAML

The following are the most likely reasons that a user is blocked when signing in through SAML:

- In the configuration, `gitlab_rails['omniauth_block_auto_created_users'] = true` is set and this is the user's first time signing in.
- There are [`required_groups`](#required-groups) configured, but the user is not a member of one.
