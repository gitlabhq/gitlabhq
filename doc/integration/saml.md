---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# SAML OmniAuth Provider **(FREE SELF)**

This page describes instance-wide SAML for self-managed GitLab instances. For SAML on GitLab.com, see [SAML SSO for GitLab.com groups](../user/group/saml_sso/index.md).

You should also reference the [OmniAuth documentation](omniauth.md) for general settings that apply to all OmniAuth providers.

## Glossary of common terms

| Term                           | Description |
|--------------------------------|-------------|
| Identity provider (IdP)        | The service which manages your user identities, such as Okta or OneLogin. |
| Service provider (SP)          | GitLab can be configured as a SAML 2.0 SP. |
| Assertion                      | A piece of information about a user's identity, such as their name or role. Also known as claims or attributes. |
| Single Sign-On (SSO)           | Name of authentication scheme. |
| Assertion consumer service URL | The callback on GitLab where users will be redirected after successfully authenticating with the identity provider. |
| Issuer                         | How GitLab identifies itself to the identity provider. Also known as a "Relying party trust identifier". |
| Certificate fingerprint        | Used to confirm that communications over SAML are secure by checking that the server is signing communications with the correct certificate. Also known as a certificate thumbprint. |

## General Setup

GitLab can be configured to act as a SAML 2.0 Service Provider (SP). This allows
GitLab to consume assertions from a SAML 2.0 Identity Provider (IdP), such as
Okta to authenticate users.

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
   an account first, add the following values to your configuration:

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

1. Ensure that the SAML [`NameID`](../user/group/saml_sso/index.md#nameid) and email address are fixed for each user,
as described in the section on [Security](#security). Otherwise, your users are able to sign in as other authorized users.

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
       label: 'Provider name' # optional label for SAML login button, defaults to "Saml"
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
   See the [notes on configuring your identity provider](#notes-on-configuring-your-identity-provider) for more information.

1. Change the value of `issuer` to a unique name, which identifies the application
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

At a minimum the IdP *must* provide a claim containing the user's email address using `email` or `mail`.
See [the assertions list](#assertions) for other available claims.

On the sign in page there should now be a SAML button below the regular sign in form.
Click the icon to begin the authentication process. If everything goes well the user
is returned to GitLab and signed in.

### Notes on configuring your identity provider

When configuring a SAML app on the IdP, you need at least:

- Assertion consumer service URL
- Issuer
- [`NameID`](../user/group/saml_sso/index.md#nameid)
- [Email address claim](#assertions)

Your identity provider may require additional configuration, such as the following:

| Field | Value | Notes |
|-------|-------|-------|
| SAML profile | Web browser SSO profile | GitLab uses SAML to sign users in through their browser. No requests are made directly to the identity provider. |
| SAML request binding | HTTP Redirect | GitLab (the service provider) redirects users to your identity provider with a base64 encoded `SAMLRequest` HTTP parameter. |
| SAML response binding | HTTP POST | Specifies how the SAML token is sent by your identity provider. Includes the `SAMLResponse`, which a user's browser submits back to GitLab. |
| Sign SAML response | Required | Prevents tampering. |
| X.509 certificate in response | Required | Signs the response and checks against the provided fingerprint. |
| Fingerprint algorithm | SHA-1  |  GitLab uses a SHA-1 hash of the certificate to sign the SAML Response. |
| Signature algorithm | SHA-1/SHA-256/SHA-384/SHA-512 | Determines how a response is signed. Also known as the digest method, this can be specified in the SAML response. |
| Encrypt SAML assertion | Optional | Uses TLS between your identity provider, the user's browser, and GitLab. |
| Sign SAML assertion | Optional | Validates the integrity of a SAML assertion. When active, signs the whole response. |
| Check SAML request signature | Optional | Checks the signature on the SAML response. |
| Default RelayState | Optional | Specifies the URL users should end up on after successfully signing in through SAML at your identity provider. |
| NameID format | Persistent | See [NameID format details](../user/group/saml_sso/index.md#nameid-format). |
| Additional URLs | Optional | May include the issuer (or identifier) or the assertion consumer service URL in other fields on some providers. |

For example configurations, see the [notes on specific providers](#providers).

### Assertions

| Field           | Supported keys |
|-----------------|----------------|
| Email (required)| `email`, `mail` |
| Username        | `username`, `nickname` |
| Full Name       | `name` |
| First Name      | `first_name`, `firstname`, `firstName` |
| Last Name       | `last_name`, `lastname`, `lastName` |

If a username is not specified, the email address is used to generate the GitLab username.

Please refer to [the OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)
for a full list of supported assertions.

## SAML Groups

You can require users to be members of a certain group, or assign users [external](../user/permissions.md#external-users), admin or [auditor](../user/permissions.md#auditor-users) roles based on group membership.
These groups are checked on each SAML login and user attributes updated as necessary.
This feature **does not** allow you to
automatically add users to GitLab [Groups](../user/group/index.md).

Support for these groups depends on your [subscription](https://about.gitlab.com/pricing/)
and whether you've installed [GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/).

| Group                        | Tier               | GitLab Enterprise Edition (EE) Only? |
|------------------------------|--------------------|--------------------------------------|
| [Required](#required-groups) | **(FREE SELF)**    | Yes                                  |
| [External](#external-groups) | **(FREE SELF)**    | No                                   |
| [Admin](#admin-groups)       | **(FREE SELF)**    | Yes                                  |
| [Auditor](#auditor-groups)   | **(PREMIUM SELF)** | Yes                                  |

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

### Required groups **(FREE SELF)**

Your IdP passes Group Information to the SP (GitLab) in the SAML Response. You need to configure GitLab to identify:

- Where to look for the groups in the SAML response via the `groups_attribute` setting
- Which group membership is requisite to sign in via the `required_groups` setting

When `required_groups` is not set or it is empty, anyone with proper authentication
is able to use the service.

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

### External groups **(FREE SELF)**

SAML login supports automatic identification on whether a user should be considered an [external user](../user/permissions.md#external-users). This is based on the user's group membership in the SAML identity provider.

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

### Admin groups **(FREE SELF)**

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

### Auditor groups **(PREMIUM SELF)**

> Introduced in GitLab 11.4.

The requirements are the same as the previous settings, your IdP needs to pass Group information to GitLab, you need to tell
GitLab where to look for the groups in the SAML response, and which group(s) should be
considered [auditor users](../user/permissions.md#auditor-users).

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

Keep in mind that every sign in attempt redirects to the SAML server;
you cannot sign in using local credentials. Ensure at least one of the
SAML users has admin permissions.

You may also bypass the auto sign-in feature by browsing to
`https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

### `attribute_statements`

NOTE:
This setting should be used only to map attributes that are part of the OmniAuth
`info` hash schema.

`attribute_statements` is used to map Attribute Names in a SAMLResponse to entries
in the OmniAuth [`info` hash](https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later).

For example, if your SAMLResponse contains an Attribute called `EmailAddress`,
specify `{ email: ['EmailAddress'] }` to map the Attribute to the
corresponding key in the `info` hash. URI-named Attributes are also supported, for example,
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

By default, the email in the SAML response is used to automatically generate the user's GitLab username. If you'd like to set another attribute as the username, assign it to the `nickname` OmniAuth `info` hash attribute. For example, if you wanted to set the `username` attribute in your SAML Response to the username in GitLab, use the following setting:

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

Your Identity Provider encrypts the assertion with the public certificate of GitLab. GitLab decrypts the EncryptedAssertion with its private key.

NOTE:
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

GitLab signs the request with the provided private key. GitLab includes the configured public x500 certificate in the metadata for your Identity Provider to validate the signature of the received request with. For more information on this option, see the [Ruby SAML gem documentation](https://github.com/onelogin/ruby-saml/tree/v1.7.0). The Ruby SAML gem is used by the [OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml) to implement the client side of the SAML authentication.

## Security

Avoid user control of the following attributes:

- [`NameID`](../user/group/saml_sso/index.md#nameid)
- `Email` when used with `omniauth_auto_link_saml_user`

These attributes define the SAML user. If users can change these attributes, they can impersonate others.

Refer to the documentation for your SAML Identity Provider for information on how to fix these attributes.

## Passwords for users created via SAML

The [Generated passwords for users created through integrated authentication](../security/passwords_for_integrated_authentication_methods.md) guide provides an overview of how GitLab generates and sets passwords for users created via SAML.

## Configuring Group SAML on a self-managed GitLab instance **(PREMIUM SELF)**

For information on the GitLab.com implementation, please see the [SAML SSO for GitLab.com groups page](../user/group/saml_sso).

Group SAML SSO helps if you need to allow access via multiple SAML identity providers, but as a multi-tenant solution is less suited to cases where you administer your own GitLab instance.

To proceed with configuring Group SAML SSO instead, enable the `group_saml` OmniAuth provider. This can be done from:

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

## Providers

GitLab support of SAML means that you can sign in to GitLab with a wide range of identity providers.
Your identity provider may have additional documentation. Some identity providers include
documentation on how to use SAML to sign in to GitLab.

Examples:

- [ADFS (Active Directory Federation Services)](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-relying-party-trust)
- [Auth0](https://auth0.com/docs/protocols/saml-protocol/configure-auth0-as-saml-identity-provider)
- [PingOne by Ping Identity](https://docs.pingidentity.com/bundle/pingone/page/xsh1564020480660-1.html)

Please note that GitLab provides the following setup notes for guidance only.
If you have any questions on configuring the SAML app, please contact your provider's support.

### Okta setup notes

The following guidance is based on this Okta article, on adding a [SAML Application with an Okta Developer account](https://support.okta.com/help/s/article/Why-can-t-I-add-a-SAML-Application-with-an-Okta-Developer-account?language=en_US):

1. In the Okta admin section, make sure to select Classic UI view in the top left corner. From there, choose to **Add an App**.
1. When the app screen comes up you see another button to **Create an App** and
   choose SAML 2.0 on the next screen.
1. Optionally, you can add a logo
   (you can choose it from <https://about.gitlab.com/press/>). You must
   crop and resize it.
1. Next, fill in the SAML general configuration with
   the assertion consumer service URL as "Single sign-on URL" and
   the issuer as "Audience URI" along with the [NameID](../user/group/saml_sso/index.md#nameid) and [assertions](#assertions).
1. The last part of the configuration is the feedback section where you can
   just say you're a customer and creating an app for internal use.
1. When you have your app you can see a few tabs on the top of the app's
   profile. Click on the SAML 2.0 configuration instructions button.
1. On the screen that comes up take note of the
   **Identity Provider Single Sign-On URL** which you can use for the
   `idp_sso_target_url` on your GitLab configuration file.
1. **Before you leave Okta, make sure you add your user and groups if any.**

### Google workspace setup notes

The following guidance is based on this Google Workspace article, on how to [Set up your own custom SAML application](https://support.google.com/a/answer/6087519?hl=en):

Make sure you have access to a Google Workspace [Super Admin](https://support.google.com/a/answer/2405986#super_admin) account.
   Use the information below and follow the instructions in the linked Google Workspace article.

|                  | Typical value                                    | Description                                              |
|------------------|--------------------------------------------------|----------------------------------------------------------|
| Name of SAML App | GitLab                                           | Other names OK.                                          |
| ACS URL          | `https://<GITLAB_DOMAIN>/users/auth/saml/callback` | ACS is short for Assertion Consumer Service.             |
| GITLAB_DOMAIN    | `gitlab.example.com`                             | Set to the domain of your GitLab instance.               |
| Entity ID        | `https://gitlab.example.com`                     | A value unique to your SAML app, set it to the `issuer` in your GitLab configuration.                         |
| Name ID format   | EMAIL                                            | Required value. Also known as `name_identifier_format`                    |
| Name ID          | Primary email address                            | Make sure someone receives content sent to that address                |
| First name       | `first_name`                                     | Required value to communicate with GitLab.               |
| Last name        | `last_name`                                      | Required value to communicate with GitLab.               |

You also need to setup the following SAML attribute mappings:

| Google Directory attributes       | App attributes |
|-----------------------------------|----------------|
| Basic information > Email         | `email`        |
| Basic Information > First name    | `first_name`   |
| Basic Information > Last name     | `last_name`    |

You may also use some of this information when you [configure GitLab](#general-setup).

When configuring the Google Workspace SAML app, be sure to record the following information:

|             | Value        | Description                                                                       |
|-------------|--------------|-----------------------------------------------------------------------------------|
| SSO URL     | Depends      | Google Identity Provider details. Set to the GitLab `idp_sso_target_url` setting. |
| Certificate | Downloadable | Run `openssl x509 -in <your_certificate.crt> -noout -fingerprint` to generate the SHA1 fingerprint that can be used in the `idp_cert_fingerprint` setting.                         |

While the Google Workspace Admin provides IdP metadata, Entity ID and SHA-256 fingerprint,
GitLab does not need that information to connect to the Google Workspace SAML app.

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

### 422 error after login

If you see a "422 error" in GitLab when you are redirected from the SAML
sign-in page, you might have an incorrectly configured assertion consumer
service (ACS) URL on the identity provider.

Make sure the ACS URL points to `https://gitlab.example.com/users/auth/saml/callback`, where
`gitlab.example.com` is the URL of your GitLab instance.

If the ACS URL is correct, and you still have errors, review the other
[Troubleshooting](#troubleshooting) sections.

If you are sure that the ACS URL is correct, proceed to the [Redirect back to the login screen with no evident error](#redirect-back-to-the-login-screen-with-no-evident-error)
section for further troubleshooting steps.

### Redirect back to the login screen with no evident error

If after signing in into your SAML server you are redirected back to the sign in page and
no error is displayed, check your `production.log` file. It most likely contains the
message `Can't verify CSRF token authenticity`. This means that there is an error during
the SAML request, but in GitLab 11.7 and earlier this error never reaches GitLab due to
the CSRF check.

To bypass this you can add `skip_before_action :verify_authenticity_token` to the
`omniauth_callbacks_controller.rb` file immediately after the `class` line and
comment out the `protect_from_forgery` line using a `#`. Restart Puma for this
change to take effect. This allows the error to hit GitLab, where it can then
be seen in the usual logs, or as a flash message on the login screen.

That file is located in `/opt/gitlab/embedded/service/gitlab-rails/app/controllers`
for Omnibus installations and by default in `/home/git/gitlab/app/controllers` for
installations from source. Restart Puma using the `sudo gitlab-ctl restart puma`
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
is not providing this information, all SAML requests fail.

Make sure this information is provided.

Another issue that can result in this error is when the correct information is being sent by the IdP, but the attributes don't match the names in the OmniAuth `info` hash. In this case, you need to set `attribute_statements` in the SAML configuration to [map the attribute names in your SAML Response to the corresponding OmniAuth `info` hash names](#attribute_statements).

### Key validation error, Digest mismatch or Fingerprint mismatch

These errors all come from a similar place, the SAML certificate. SAML requests
need to be validated using a fingerprint, a certificate or a validator.

For this you need to take the following into account:

- If a fingerprint is used, it must be the SHA1 fingerprint
- If no certificate is provided in the settings, a fingerprint or fingerprint
  validator needs to be provided and the response from the server must contain
  a certificate (`<ds:KeyInfo><ds:X509Data><ds:X509Certificate>`)
- If a certificate is provided in the settings, it is no longer necessary for
  the request to contain one. In this case the fingerprint or fingerprint
  validators are optional

If none of the above described scenarios is valid, the request
fails with one of the mentioned errors.

### User is blocked when signing in through SAML

The following are the most likely reasons that a user is blocked when signing in through SAML:

- In the configuration, `gitlab_rails['omniauth_block_auto_created_users'] = true` is set and this is the user's first time signing in.
- There are [`required_groups`](#required-groups) configured, but the user is not a member of one.

### Google workspace troubleshooting tips

The Google Workspace documentation on [SAML app error messages](https://support.google.com/a/answer/6301076?hl=en) is helpful for debugging if you are seeing an error from Google while signing in.
Pay particular attention to the following 403 errors:

- `app_not_configured`
- `app_not_configured_for_user`
