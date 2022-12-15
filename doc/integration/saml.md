---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# SAML SSO for self-managed GitLab instances **(FREE SELF)**

This page describes how to set up instance-wide SAML single sign on (SSO) for
self-managed GitLab instances.

You can configure GitLab to act as a SAML service provider (SP). This allows
GitLab to consume assertions from a SAML identity provider (IdP), such as
Okta, to authenticate users.

To set up SAML on GitLab.com, see [SAML SSO for GitLab.com groups](../user/group/saml_sso/index.md).

For more information on:

- OmniAuth provider settings, see the [OmniAuth documentation](omniauth.md).
- Commonly-used terms, see the [glossary of common terms](#glossary-of-common-terms).

## Configure SAML support in GitLab

1. Make sure GitLab is [configured with HTTPS](../install/installation.md#using-https).

1. On your GitLab server, open the configuration file.

   For Omnibus installations:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H editor config/gitlab.yml
   ```

1. Edit the initial [configuration settings](omniauth.md#configure-initial-settings).

1. To allow your users to use SAML to sign up without having to manually create
   an account first, add the following values to your configuration.

   For Omnibus installations:

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

1. Optional. You can automatically link SAML users with existing GitLab users if their
   email addresses match by adding the following setting.

   For Omnibus installations:

   ```ruby
   gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   For installations from source:

   ```yaml
   auto_link_saml_user: true
   ```

   Alternatively, a user can manually link their SAML identity to an existing GitLab
   account by [enabling OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user).

1. Configure the following attributes so your SAML users cannot change them:

   - [`NameID`](../user/group/saml_sso/index.md#nameid)
   - `Email` when used with `omniauth_auto_link_saml_user`

   If users can change these attributes, they can sign in as other authorized users.
   See your SAML IdP documentation for information on how to make these attributes
   unchangeable.

1. Add the provider configuration.

   For Omnibus installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "saml",
       label: "Provider name", # optional label for login button, defaults to "Saml"
       args: {
         assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
         idp_cert_fingerprint: "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
         idp_sso_target_url: "https://login.example.com/idp",
         issuer: "https://gitlab.example.com",
         name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
       }
     }
   ]
   ```

   For installations from source:

   ```yaml
   omniauth:
     providers:
       - {
         name: 'saml',
         label: 'Provider name', # optional label for login button, defaults to "Saml"
         args: {
           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
           idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
           idp_sso_target_url: 'https://login.example.com/idp',
           issuer: 'https://gitlab.example.com',
           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
         }
       }
   ```

1. Match the value for `assertion_consumer_service_url` to the HTTPS endpoint
   of GitLab. To generate the correct value, append `users/auth/saml/callback` to the
   HTTPS URL of your GitLab installation.

1. Change the following values to match your IdP:
   - `idp_cert_fingerprint`.
   - `idp_sso_target_url`.
   - `name_identifier_format`.
   If you use a `idp_cert_fingerprint`, it must be a SHA1 fingerprint. For more
   information on these values, see the
   [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml).
   For more information on other configuration settings, see
   [configuring SAML on your IdP](#configure-saml-on-your-idp).

1. Change the value of `issuer` to a unique name, which identifies the application
   to the IdP.

1. For the changes to take effect, if you installed:
   - Using Omnibus, [reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure).
   - From source, [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

### Register GitLab in your SAML IdP

1. Register the GitLab SP in your SAML IdP, using the application name specified in `issuer`.

1. To provide configuration information to the IdP, build a metadata URL for the
   application. To build the metadata URL for GitLab, append `users/auth/saml/metadata`
   to the HTTPS URL of your GitLab installation. For example:

   ```plaintext
   https://gitlab.example.com/users/auth/saml/metadata
   ```

   At a minimum the IdP **must** provide a claim containing the user's email address
   using `email` or `mail`. For more information on other available claims, see
   [configuring assertions](#configure-assertions).

1. On the sign in page there should now be a SAML icon below the regular sign in form.
   Select the icon to begin the authentication process. If authentication is successful,
   you are returned to GitLab and signed in.

### Configure SAML on your IdP

To configure a SAML application on your IdP, you need at least the following information:

- Assertion consumer service URL.
- Issuer.
- [`NameID`](../user/group/saml_sso/index.md#nameid).
- [Email address claim](#configure-assertions).

For an example configuration, see [set up identity providers](#set-up-identity-providers).

Your IdP may need additional configuration. For more information, see
[additional configuration for SAML apps on your IdP](#additional-configuration-for-saml-apps-on-your-idp).

### Configure GitLab to use multiple SAML IdPs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14361) in GitLab 14.6.

You can configure GitLab to use multiple SAML 2.0 identity providers if:

- Each provider has a unique name set that matches a name set in `args`. At least one provider **must** have the name `saml` to mitigate a
  [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/366450) in GitLab 14.6 and newer.
- The providers' names are:
  - Used in OmniAuth configuration for properties based on the provider name. For example, `allowBypassTwoFactor`, `allowSingleSignOn`, and
    `syncProfileFromProvider`.
  - Used for association to each existing user as an additional identity.
- The `assertion_consumer_service_url` matches the provider name.
- The `strategy_class` is explicitly set because it cannot be inferred from provider name.

Example multiple providers configuration for Omnibus GitLab:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: 'saml',
    args: {
            name: 'saml', # This is mandatory and must match the provider name
            strategy_class: 'OmniAuth::Strategies::SAML',
            assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_1/callback', # URL must match the name of the provider
            ... # Put here all the required arguments similar to a single provider
          },
    label: 'Provider 1' # Differentiate the two buttons and providers in the UI
  },
  {
    name: 'saml1',
    args: {
            name: 'saml1', # This is mandatory and must match the provider name
            strategy_class: 'OmniAuth::Strategies::SAML',
            assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
            ... # Put here all the required arguments similar to a single provider
          },
    label: 'Provider 2' # Differentiate the two buttons and providers in the UI
  }
]
```

Example providers configuration for installations from source:

```yaml
omniauth:
  providers:
    - {
      name: 'saml',
      args: {
        name: 'saml', # This is mandatory and must match the provider name
        strategy_class: 'OmniAuth::Strategies::SAML',
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_1/callback', # URL must match the name of the provider
        ... # Put here all the required arguments similar to a single provider
      },
      label: 'Provider 1' # Differentiate the two buttons and providers in the UI
    }
    - {
      name: 'saml1',
      args: {
        name: 'saml1', # This is mandatory and must match the provider name
        strategy_class: 'OmniAuth::Strategies::SAML',
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
        ... # Put here all the required arguments similar to a single provider
      },
      label: 'Provider 2' # Differentiate the two buttons and providers in the UI
    }
```

## Set up identity providers

GitLab support of SAML means you can sign in to GitLab through a wide range
of IdPs.

GitLab provides the following content on setting up the Okta and Google Workspace
IdPs for guidance only. If you have any questions on configuring either of these
IdPs, contact your provider's support.

### Set up Okta

1. In the Okta administrator section choose **Applications**.
1. On the app screen, select **Create App Integration** and then select
   **SAML 2.0** on the next screen.
1. Optional. Choose and add a logo from [GitLab Press](https://about.gitlab.com/press/).
   You must crop and resize the logo.
1. Complete the SAML general configuration. Enter:
   - `"Single sign-on URL"`: Use the assertion consumer service URL.
   - `"Audience URI"`: Use the issuer.
   - [`NameID`](../user/group/saml_sso/index.md#nameid).
   - [Assertions](#configure-assertions).
1. In the feedback section, enter that you're a customer and creating an
   app for internal use.
1. At the top of your new app's profile, select **SAML 2.0 configuration instructions**.
1. Note the **Identity Provider Single Sign-On URL**. Use this URL for the
   `idp_sso_target_url` on your GitLab configuration file.
1. Before you sign out of Okta, make sure you add your user and groups if any.

### Set up Google Workspace

Prerequisites:

- Make sure you have access to a
[Google Workspace Super Admin account](https://support.google.com/a/answer/2405986#super_admin).

1. Use the following information, and follow the instructions in
[Set up your own custom SAML application in Google Workspace](https://support.google.com/a/answer/6087519?hl=en).

   |                  | Typical value                                    | Description                                              |
   |------------------|--------------------------------------------------|----------------------------------------------------------|
   | Name of SAML App | GitLab                                           | Other names OK.                                          |
   | ACS URL          | `https://<GITLAB_DOMAIN>/users/auth/saml/callback` | Assertion Consumer Service URL.             |
   | GITLAB_DOMAIN    | `gitlab.example.com`                             | Your GitLab instance domain.               |
   | Entity ID        | `https://gitlab.example.com`                     | A value unique to your SAML application. Set it to the `issuer` in your GitLab configuration.                         |
   | Name ID format   | EMAIL                                            | Required value. Also known as `name_identifier_format`.                    |
   | Name ID          | Primary email address                            | Your email address. Make sure someone receives content sent to that address.                |
   | First name       | `first_name`                                     | First name. Required value to communicate with GitLab.               |
   | Last name        | `last_name`                                      | Last name. Required value to communicate with GitLab.               |

1. Set up the following SAML attribute mappings:

   | Google Directory attributes       | App attributes |
   |-----------------------------------|----------------|
   | Basic information > Email         | `email`        |
   | Basic Information > First name    | `first_name`   |
   | Basic Information > Last name     | `last_name`    |

   You might use some of this information when you
   [configure SAML support in GitLab](#configure-saml-support-in-gitlab).

When configuring the Google Workspace SAML application, record the following information:

|             | Value        | Description                                                                       |
|-------------|--------------|-----------------------------------------------------------------------------------|
| SSO URL     | Depends      | Google Identity Provider details. Set to the GitLab `idp_sso_target_url` setting. |
| Certificate | Downloadable | Run `openssl x509 -in <your_certificate.crt> -noout -fingerprint` to generate the SHA1 fingerprint that can be used in the `idp_cert_fingerprint` setting.                         |

Google Workspace Administrator also provides the IdP metadata, Entity ID, and SHA-256
fingerprint. However, GitLab does not need this information to connect to the
Google Workspace SAML application.

### Set up other IdPs

Some IdPs have documentation on how to use them as the IdP in SAML configurations.
For example:

- [Active Directory Federation Services (ADFS)](https://learn.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-relying-party-trust)
- [Auth0](https://auth0.com/docs/authenticate/protocols/saml/saml-sso-integrations/configure-auth0-saml-identity-provider)

If you have any questions on configuring your IdP in a SAML configuration, contact
your provider's support.

### Configure assertions

| Field           | Supported default keys |
|-----------------|------------------------|
| Email (required)| `email`, `mail`        |
| Full Name       | `name`                 |
| First Name      | `first_name`, `firstname`, `firstName` |
| Last Name       | `last_name`, `lastname`, `lastName`    |

See [`attribute_statements`](#map-saml-response-attribute-names) for:

- Custom assertion configuration examples.
- How to configure custom username attributes.

For a full list of supported assertions, see the [OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)

## Configure users based on SAML group membership

You can require users to be members of a certain group, or assign users [external](../user/admin_area/external_users.md), administrator or [auditor](../administration/auditor_users.md) access levels based on group membership.
These groups are checked on each SAML login and user attributes updated as necessary.
This feature **does not** allow you to
automatically add users to GitLab [Groups](../user/group/index.md).

Support for these groups depends on your [subscription](https://about.gitlab.com/pricing/)
and whether you've installed [GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/).

| Group                        | Tier               | GitLab Enterprise Edition (EE) Only? |
|------------------------------|--------------------|--------------------------------------|
| [Required](#required-groups) | **(FREE SELF)**    | Yes                                  |
| [External](#external-groups) | **(FREE SELF)**    | No                                   |
| [Admin](#administrator-groups)       | **(FREE SELF)**    | Yes                                  |
| [Auditor](#auditor-groups)   | **(PREMIUM SELF)** | Yes                                  |

### Prerequisites

First tell GitLab where to look for group information. For this, you
must make sure that your IdP server sends a specific `AttributeStatement` along
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
to which a user belongs. To tell GitLab where to find these groups, you need
to add a `groups_attribute:` element to your SAML settings.

### Required groups

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

Use the `required_groups` setting to configure GitLab to identify which group
membership is required to sign in.

If you do not set `required_groups` or leave the setting empty, anyone with proper
authentication can use the service.

Example configuration:

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
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
  } }
```

### External groups

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

SAML can automatically identify a user as an
[external user](../user/admin_area/external_users.md), based on the `external_groups`
setting.

Example configuration:

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

### Administrator groups

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

Use the `admin_groups` setting to configure GitLab to identify which groups grant
the user administrator access.

Example configuration:

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
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
  } }
```

### Auditor groups **(PREMIUM SELF)**

> Introduced in GitLab 11.4.

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

Use the `auditor_groups` setting to configure GitLab to identify which groups include
users with [auditor access](../administration/auditor_users.md).

Example configuration:

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
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
  } }
```

## Automatically manage SAML Group Sync

For information on automatically managing GitLab group membership, see [SAML Group Sync](../user/group/saml_sso/group_sync.md).

## Bypass two-factor authentication

To configure a SAML authentication method to count as two-factor authentication
(2FA) on a per session basis, register that method in the `upstream_two_factor_authn_contexts`
list.

1. Make sure that your IdP is returning the `AuthnContext`. For example:

```xml
<saml:AuthnStatement>
    <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:MediumStrongCertificateProtectedTransport</saml:AuthnContextClassRef>
    </saml:AuthnContext>
</saml:AuthnStatement>
```

1. Edit your installation configuration to register the SAML authentication method
   in the `upstream_two_factor_authn_contexts` list. How you edit your configuration
   will differ depending on your installation type.

### Omnibus GitLab installations

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "saml",
       args: {
         assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
         idp_cert_fingerprint: "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
         idp_sso_target_url: "https://login.example.com/idp",
         issuer: "https://gitlab.example.com",
         name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
         upstream_two_factor_authn_contexts:
           %w(
             urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
             urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
             urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
           )
       },
       label: "Company Login" # optional label for SAML login button, defaults to "Saml"
     }
   ]
   ```

1. Save the file and [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   GitLab for the changes to take effect.

### Installations from source

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

1. Save the file and [restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect.

## Validate response signatures

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
solving these errors.

## Customize SAML settings

### Redirect users to SAML server for authentication

You can add this setting to your GitLab configuration to automatically redirect you
to your SAML server for authentication. This removes the requirement to select a button
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
SAML users has administrator access.

You may also bypass the auto sign-in feature by browsing to
`https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

### Map SAML response attribute names **(FREE SELF)**

NOTE:
This setting should be used only to map attributes that are part of the OmniAuth
`info` hash schema.

`attribute_statements` is used to map Attribute Names in a `SAMLResponse` to entries
in the OmniAuth [`info` hash](https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later).

For example, if your `SAMLResponse` contains an Attribute called `EmailAddress`,
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

#### Set a username

By default, the local part of the email address in the SAML response is used to
generate the user's GitLab username.

Configure `nickname` in `attribute_statements` to specify one or more attributes that contain a user's desired username:

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

This also sets the `username` attribute in your SAML Response to the username in GitLab.

### Allow for clock drift

The clock of the Identity Provider may drift slightly ahead of your system clocks.
To allow for a small amount of clock drift, you can use `allowed_clock_drift` in
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

### Designate a unique attribute for the `uid`

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

Ensure that attributes define the SAML user, such as
[`NameID`](../user/group/saml_sso/index.md#nameid) and email address, are fixed
for each user before changing this value.

## Assertion encryption (optional)

GitLab requires the use of TLS encryption with SAML 2.0, but in some cases there can be a
need for additional encryption of the assertions.

This may be the case, for example, if you terminate TLS encryption early at a load
balancer and include sensitive details in assertions that you do not want appearing
in logs. Most organizations should not need additional encryption at this layer.

The SAML integration supports EncryptedAssertion. You should define the private
key and the public certificate of your GitLab instance in the SAML settings. When you define the key and certificate, replace all line feeds in the key file with `\n`. This makes the key file one long string with no line feeds.

```yaml
args: {
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
  idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
  idp_sso_target_url: 'https://login.example.com/idp',
  issuer: 'https://gitlab.example.com',
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
  certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
  private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
}
```

Your Identity Provider encrypts the assertion with the public certificate of GitLab. GitLab decrypts the EncryptedAssertion with its private key.

NOTE:
This integration uses the `certificate` and `private_key` settings for both assertion encryption and request signing.

## Sign SAML authentication requests (optional)

Another optional configuration is to sign SAML authentication requests. GitLab
SAML Requests use the SAML redirect binding, so this isn't necessary (unlike the
SAML POST binding, where signing is required to prevent intermediaries from
tampering with the requests).

To sign, create a private key and public certificate pair for your
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
  certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
  private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
  security: {
    authn_requests_signed: true,  # enable signature on AuthNRequest
    want_assertions_signed: true,  # enable the requirement of signed assertion
    metadata_signed: false,  # enable signature on Metadata
    signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
    digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
  }
}
```

GitLab signs the request with the provided private key. GitLab includes the configured public x500 certificate in the metadata for your Identity Provider to validate the signature of the received request with. For more information on this option, see the [Ruby SAML gem documentation](https://github.com/onelogin/ruby-saml/tree/v1.7.0). The Ruby SAML gem is used by the [OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml) to implement the client side of the SAML authentication.

## Password generation for users created through SAML

The [Generated passwords for users created through integrated authentication](../security/passwords_for_integrated_authentication_methods.md) guide provides an overview of how GitLab generates and sets passwords for users created via SAML.

Users authenticated with SSO or SAML must not use a password for Git operations over HTTPS. These users can do one of the following instead:

- Set up a [personal access token](../user/profile/personal_access_tokens.md).
- Use the [Git Credential Manager](../user/profile/account/two_factor_authentication.md#git-credential-manager) which securely authenticates using OAuth.

## Link SAML identity for an existing user

A user can manually link their SAML identity to an existing GitLab account by following the steps in
[Enable OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user).

## Group SAML on a self-managed GitLab instance **(PREMIUM SELF)**

For information on the GitLab.com implementation, please see the [SAML SSO for GitLab.com groups page](../user/group/saml_sso).

Group SAML SSO helps if you have to allow access via multiple SAML identity providers, but as a multi-tenant solution is less suited to cases where you administer your own GitLab instance.

To proceed with configuring Group SAML SSO instead, enable the `group_saml` OmniAuth provider. This can be done from:

- `gitlab.rb` for Omnibus GitLab installations.
- `gitlab/config/gitlab.yml` for source installations.

### Self-managed instance group SAML limitations

Group SAML on a self-managed instance is limited when compared to the recommended
[instance-wide SAML](../user/group/saml_sso/index.md). The recommended solution allows you to take advantage of:

- [LDAP compatibility](../administration/auth/ldap/index.md).
- [LDAP Group Sync](../user/group/access_and_permissions.md#manage-group-memberships-via-ldap).
- [Required groups](#required-groups).
- [Administrator groups](#administrator-groups).
- [Auditor groups](#auditor-groups).

For Omnibus installations:

1. Make sure GitLab is
   [configured with HTTPS](../install/installation.md#using-https).
1. Enable OmniAuth and the `group_saml` provider in `gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

For installations from source:

1. Make sure GitLab is
   [configured with HTTPS](../install/installation.md#using-https).
1. Enable OmniAuth and the `group_saml` provider in `gitlab/config/gitlab.yml`:

    ```yaml
    omniauth:
      enabled: true
      providers:
        - { name: 'group_saml' }
    ```

## Additional configuration for SAML apps on your IdP

When configuring a SAML app on the IdP, your identity provider may require additional configuration, such as the following:

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

For example configurations, see the [notes on specific providers](#set-up-identity-providers).

## Glossary of common terms

| Term                           | Description |
|--------------------------------|-------------|
| Identity provider (IdP)        | The service which manages your user identities, such as Okta or OneLogin. |
| Service provider (SP)          | GitLab can be configured as a SAML 2.0 SP. |
| Assertion                      | A piece of information about a user's identity, such as their name or role. Also known as claims or attributes. |
| Single Sign-On (SSO)           | Name of authentication scheme. |
| Assertion consumer service URL | The callback on GitLab where users are redirected after successfully authenticating with the identity provider. |
| Issuer                         | How GitLab identifies itself to the identity provider. Also known as a "Relying party trust identifier". |
| Certificate fingerprint        | Used to confirm that communications over SAML are secure by checking that the server is signing communications with the correct certificate. Also known as a certificate thumbprint. |

## Troubleshooting

See our [troubleshooting SAML guide](../user/group/saml_sso/troubleshooting.md).
