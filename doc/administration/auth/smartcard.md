---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Smart card authentication
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab supports authentication using smart cards.

## Existing password authentication

By default, existing users can continue to sign in with a username and password when smart card
authentication is enabled.

To force existing users to use only smart card authentication,
[disable username and password authentication](../settings/sign_in_restrictions.md#password-authentication-enabled).

## Authentication methods

GitLab supports two authentication methods:

- X.509 certificates with local databases.
- LDAP servers.

### Authentication against a local database with X.509 certificates

DETAILS:
**Status:** Experiment

Smart cards with X.509 certificates can be used to authenticate with GitLab.

To use a smart card with an X.509 certificate to authenticate against a local
database with GitLab, `CN` and `emailAddress` must be defined in the
certificate. For example:

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        Subject: CN=Gitlab User, emailAddress=gitlab-user@example.com
```

### Authentication against a local database with X.509 certificates and SAN extension

DETAILS:
**Status:** Experiment

Smart cards with X.509 certificates using SAN extensions can be used to authenticate
with GitLab.

To use a smart card with an X.509 certificate to authenticate against a local
database with GitLab:

- At least one of the `subjectAltName` (SAN) extensions
  must define the user identity (`email`) within the GitLab instance (`URI`).
- The `URI` must match `Gitlab.config.host.gitlab`.
- If your certificate contains only **one** SAN email entry, you don't need to
  add or modify it to match the `email` with the `URI`.

For example:

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        ...
        X509v3 extensions:
            X509v3 Key Usage:
                Key Encipherment, Data Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                email:gitlab-user@example.com, URI:http://gitlab.example.com/
```

### Authentication against an LDAP server

DETAILS:
**Status:** Experiment

GitLab implements a standard way of certificate matching following
[RFC4523](https://www.rfc-editor.org/rfc/rfc4523). It uses the
`certificateExactMatch` certificate matching rule against the `userCertificate`
attribute. As a prerequisite, you must use an LDAP server that:

- Supports the `certificateExactMatch` matching rule.
- Has the certificate stored in the `userCertificate` attribute.

### Authentication against an Active Directory LDAP server

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328074) in GitLab 16.9.

Active Directory does not support the `certificateExactMatch` rule or the `userCertificate` attribute. Most tools for certificate-based authentication such as smart cards use the `altSecurityIdentities` attribute, which can contain multiple certificates for each user. The data in the field must match [one of the formats Microsoft recommends](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#supported-patterns-for-certificate-user-ids).

Use the following attributes to customize the field GitLab checks and the format for certificate data:

- `smartcard_ad_cert_field` - specify the name of the field to search. This can be any attribute on a user object.
- `smartcard_ad_cert_format` - specify the format of the information gathered from the certificate. This format must be one of the following values. The most common is
  `issuer_and_serial_number` to match the behavior of non-Active Directory LDAP servers.

| `smartcard_ad_cert_format` | Example data                                                 |
| -------------------------- | ------------------------------------------------------------ |
| `principal_name`           | `X509:<PN>alice@example.com`                                 |
| `rfc822_name`              | `X509:<RFC822>bob@example.com`                               |
| `issuer_and_subject`       | `X509:<I>DC=com,DC=example,CN=EXAMPLE-DC-CA<S>DC=com,DC=example,OU=UserAccounts,CN=cynthia` |
| `subject`                  | `X509:<S>DC=com,DC=example,OU=UserAccounts,CN=dennis`        |
| `issuer_and_serial_number` | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<SR>1181914561`   |

For `issuer_and_serial_number`, the `<SR>` portion is in reverse-byte-order, with the least-significant byte first. For more information, see [how to map a user to a certificate using the altSecurityIdentities attribute](https://learn.microsoft.com/en-us/archive/blogs/spatdsg/howto-map-a-user-to-a-certificate-via-all-the-methods-available-in-the-altsecurityidentities-attribute).

NOTE:
If no `smartcard_ad_cert_format` is specified, but an LDAP server is configured with `active_directory: true` and smart cards enabled, GitLab defaults to the behavior of 16.8 and earlier, and uses `certificateExactMatch` on the `userCertificate` attribute.

### Authentication against Entra ID Domain Services

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328074) in GitLab 16.9.

[Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/whatis), formerly known as Azure Active Directory, provides a cloud-based directory for companies and organizations. [Entra Domain Services](https://learn.microsoft.com/en-us/entra/identity/domain-services/overview) provides a secure read-only LDAP interface to the directory, but only exposes a limited subset of the fields Entra ID has.

Entra ID uses the `CertificateUserIds` field to manage client certificates for users, but this field is not exposed in LDAP / Entra ID Domain Services. With a cloud-only setup, it is not possible for GitLab to authenticate users' smart cards using LDAP.

In a hybrid on-premise and cloud environment, entities are synced between the on-premise Active Directory controller and the cloud Entra ID using [Entra Connect](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-azure-ad-connect-v2). If you are [syncing your `altSecurityIdentities` attribute to `certificateUserIds` in Entra ID using Entra ID Connect](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#update-certificateuserids-using-microsoft-entra-connect), you can expose this data in LDAP / Entra ID Domain Services so it can be authenticated by GitLab:

1. Add a rule to Entra ID Connect to sync the `altSecurityIdentities` to an additional attribute in Entra ID.
1. Enable that extra attribute as an [extension attribute in Entra ID Domain Services](https://learn.microsoft.com/en-us/entra/identity/domain-services/concepts-custom-attributes).
1. Configure the `smartcard_ad_cert_field` field in GitLab to use this extension attribute.

## Configure GitLab for smart card authentication

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Allow smart card authentication
   gitlab_rails['smartcard_enabled'] = true

   # Path to a file containing a CA certificate
   gitlab_rails['smartcard_ca_file'] = "/etc/ssl/certs/CA.pem"

   # Host and port where the client side certificate is requested by the
   # webserver (NGINX/Apache)
   gitlab_rails['smartcard_client_certificate_required_host'] = "smartcard.example.com"
   gitlab_rails['smartcard_client_certificate_required_port'] = 3444
   ```

   NOTE:
   Assign a value to at least one of the following variables:
   `gitlab_rails['smartcard_client_certificate_required_host']` or
   `gitlab_rails['smartcard_client_certificate_required_port']`.

1. Save the file and [reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   GitLab for the changes to take effect.

For self-compiled installations:

1. Configure NGINX to request a client side certificate

   In NGINX configuration, an **additional** server context must be defined with
   the same configuration except:

   - The additional NGINX server context must be configured to run on a different
     port:

     ```plaintext
     listen *:3444 ssl;
     ```

   - It can also be configured to run on a different hostname:

     ```plaintext
     listen smartcard.example.com:443 ssl;
     ```

   - The additional NGINX server context must be configured to require the client
     side certificate:

     ```plaintext
     ssl_verify_depth 2;
     ssl_client_certificate /etc/ssl/certs/CA.pem;
     ssl_verify_client on;
     ```

   - The additional NGINX server context must be configured to forward the client
     side certificate:

     ```plaintext
     proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;
     ```

   For example, the following is an example server context in an NGINX
   configuration file (such as in `/etc/nginx/sites-available/gitlab-ssl`):

   ```plaintext
   server {
       listen smartcard.example.com:3443 ssl;

       # certificate for configuring SSL
       ssl_certificate /path/to/example.com.crt;
       ssl_certificate_key /path/to/example.com.key;

       ssl_verify_depth 2;
       # CA certificate for client side certificate verification
       ssl_client_certificate /etc/ssl/certs/CA.pem;
       ssl_verify_client on;

       location / {
           proxy_set_header    Host                        $http_host;
           proxy_set_header    X-Real-IP                   $remote_addr;
           proxy_set_header    X-Forwarded-For             $proxy_add_x_forwarded_for;
           proxy_set_header    X-Forwarded-Proto           $scheme;
           proxy_set_header    Upgrade                     $http_upgrade;
           proxy_set_header    Connection                  $connection_upgrade;

           proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;

           proxy_read_timeout 300;

           proxy_pass http://gitlab-workhorse;
       }
   }
   ```

1. Edit `config/gitlab.yml`:

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # Allow smart card authentication
     enabled: true

     # Path to a file containing a CA certificate
     ca_file: '/etc/ssl/certs/CA.pem'

     # Host and port where the client side certificate is requested by the
     # webserver (NGINX/Apache)
     client_certificate_required_host: smartcard.example.com
     client_certificate_required_port: 3443
   ```

   NOTE:
   Assign a value to at least one of the following variables:
   `client_certificate_required_host` or `client_certificate_required_port`.

1. Save the file and [restart](../restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

### Additional steps when using SAN extensions

For Linux package installations:

1. Add to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['smartcard_san_extensions'] = true
   ```

1. Save the file and [reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   GitLab for the changes to take effect.

For self-compiled installations:

1. Add the `san_extensions` line to `config/gitlab.yml` within the smart card section:

   ```yaml
   smartcard:
      enabled: true
      ca_file: '/etc/ssl/certs/CA.pem'
      client_certificate_required_port: 3444

      # Enable the use of SAN extensions to match users with certificates
      san_extensions: true
   ```

1. Save the file and [restart](../restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

### Additional steps when authenticating against an LDAP server

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     # snip...
     # Enable smart card authentication against the LDAP server. Valid values
     # are "false", "optional", and "required".
     smartcard_auth: optional

     # If your LDAP server is Active Directory, you can configure these two fields.
     # Specify which field contains certificate information, 'altSecurityIdentities' by default
     smartcard_ad_cert_field: altSecurityIdentities

     # Specify format of certificate information. Valid values are:
     # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
     smartcard_ad_cert_format: issuer_and_serial_number
   EOS
   ```

1. Save the file and [reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   GitLab for the changes to take effect.

For self-compiled installations:

1. Edit `config/gitlab.yml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           # Enable smart card authentication against the LDAP server. Valid values
           # are "false", "optional", and "required".
           smartcard_auth: optional

           # If your LDAP server is Active Directory, you can configure these two fields.
           # Specify which field contains certificate information, 'altSecurityIdentities' by default
           smartcard_ad_cert_field: altSecurityIdentities

           # Specify format of certificate information. Valid values are:
           # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
           smartcard_ad_cert_format: issuer_and_serial_number
   ```

1. Save the file and [restart](../restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

### Require browser session with smart card sign-in for Git access

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['smartcard_required_for_git_access'] = true
   ```

1. Save the file and [reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   GitLab for the changes to take effect.

For self-compiled installations:

1. Edit `config/gitlab.yml`:

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # snip...
     # Browser session with smart card sign-in is required for Git access
     required_for_git_access: true
   ```

1. Save the file and [restart](../restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

## Passwords for users created via smart card authentication

The [Generated passwords for users created through integrated authentication](../../security/passwords_for_integrated_authentication_methods.md) guide provides an overview of how GitLab generates and sets passwords for users created via smart card authentication.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
