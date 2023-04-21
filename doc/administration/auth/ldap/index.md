---
type: reference
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Integrate LDAP with GitLab **(FREE SELF)**

GitLab integrates with [LDAP - Lightweight Directory Access Protocol](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)
to support user authentication.

This integration works with most LDAP-compliant directory servers, including:

- Microsoft Active Directory.
- Apple Open Directory.
- Open LDAP.
- 389 Server.

NOTE:
GitLab does not support [Microsoft Active Directory Trusts](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771568(v=ws.10)).

Users added through LDAP:

- Usually use a [licensed seat](../../../subscriptions/self_managed/index.md#billable-users).
- Can authenticate with Git using either their GitLab username or their email and LDAP password,
  even if password authentication for Git
  [is disabled](../../../user/admin_area/settings/sign_in_restrictions.md#password-authentication-enabled).

The LDAP DN is associated with existing GitLab users when:

- The existing user signs in to GitLab with LDAP for the first time.
- The LDAP email address is the primary email address of an existing GitLab user. If the LDAP email
  attribute isn't found in the GitLab user database, a new user is created.

If an existing GitLab user wants to enable LDAP sign-in for themselves, they should:

1. Check that their GitLab email address matches their LDAP email address.
1. Sign in to GitLab by using their LDAP credentials.

## Security

GitLab has multiple mechanisms to verify a user is still active in LDAP. If the user is no longer active in
LDAP, they are placed in an `ldap_blocked` status and are signed out. They are unable to sign in using any authentication provider until they are
reactivated in LDAP.

Users are considered inactive in LDAP when they:

- Are removed from the directory completely.
- Reside outside the configured `base` DN or `user_filter` search.
- Are marked as disabled or deactivated in Active Directory through the user account control attribute. This means attribute
  `userAccountControl:1.2.840.113556.1.4.803` has bit 2 set.

Status is checked for all LDAP users:

- When signing in using any authentication provider. [In GitLab 14.4 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/343298), status was
  checked only when signing in using LDAP directly.
- Once per hour for active web sessions or Git requests using tokens or SSH keys.
- When performing Git over HTTP requests using LDAP username and password.
- Once per day during [User Sync](ldap_synchronization.md#user-sync).

### Security risks

You should only use LDAP integration if your LDAP users cannot:

- Change their `mail`, `email` or `userPrincipalName` attributes on the LDAP server. These
  users can potentially take over any account on your GitLab server.
- Share email addresses. LDAP users with the same email address can share the same GitLab
  account.

## Configure LDAP

LDAP users must have a set email address, regardless of whether or not it's used
to sign in.

Here's an example of setting up LDAP with only the required options.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'LDAP',
       'host' =>  'ldap.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'LDAP'
             host: 'ldap.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

For more information, see
[how to configure LDAP for a GitLab instance that was installed by using the Helm chart](https://docs.gitlab.com/charts/charts/globals.html#ldap).

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'LDAP',
               'host' =>  'ldap.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'LDAP'
           host: 'ldap.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           encryption: 'simple_tls'
           base: 'dc=example,dc=com'
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

For more information about the various LDAP options, see the `ldap` setting in
[`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example).

::EndTabs

After configuring LDAP, to test the configuration, use the
[LDAP check Rake task](../../raketasks/ldap.md#check).

### Basic configuration settings

> `hosts` configuration setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/139) in GitLab 14.7.

You can configure either:

- A single LDAP server using `host` and `port`.
- Many LDAP servers using `hosts`. This setting takes precedence over `host` and `port`. GitLab attempts to use the
  LDAP servers in the order specified, and the first reachable LDAP server is used.

These configuration settings are available:

| Setting            | Description | Required | Examples |
|--------------------|-------------|----------|----------|
| `label`            | A human-friendly name for your LDAP server. It is displayed on your sign-in page. | **{check-circle}** Yes | `'Paris'` or `'Acme, Ltd.'` |
| `host`             | IP address or domain name of your LDAP server. Ignored when `hosts` is defined. | **{check-circle}** Yes | `'ldap.mydomain.com'` |
| `port`             | The port to connect with on your LDAP server. Always an integer, not a string. Ignored when `hosts` is defined. | **{check-circle}** Yes | `389` or `636` (for SSL) |
| `hosts` (GitLab 14.7 and later) | An array of host and port pairs to open connections. | **{dotted-circle}** No | `[['ldap1.mydomain.com', 636], ['ldap2.mydomain.com', 636]]` |
| `uid`              | The LDAP attribute that maps to the username that users use to sign in. Should be the attribute, not the value that maps to the `uid`. Does not affect the GitLab username (see [attributes section](#attribute-configuration-settings)). | **{check-circle}** Yes | `'sAMAccountName'` or `'uid'` or `'userPrincipalName'` |
| `bind_dn`          | The full DN of the user you bind with. | **{dotted-circle}** No | `'america\momo'` or `'CN=Gitlab,OU=Users,DC=domain,DC=com'` |
| `password`         | The password of the bind user. | **{dotted-circle}** No | `'your_great_password'` |
| `encryption`       | Encryption method. The `method` key is deprecated in favor of `encryption`. | **{check-circle}** Yes | `'start_tls'`, `'simple_tls'`, or `'plain'`. `simple_tls` corresponds to 'Simple TLS' in the LDAP library. `start_tls` corresponds to StartTLS, not to be confused with regular TLS. If you specify `simple_tls`, usually it's on port 636, while `start_tls` (StartTLS) would be on port 389. `plain` also operates on port 389. |
| `verify_certificates` | Enables SSL certificate verification if encryption method is `start_tls` or `simple_tls`. If set to false, no validation of the LDAP server's SSL certificate is performed. Defaults to true. | **{dotted-circle}** No | boolean |
| `timeout`          | Set a timeout, in seconds, for LDAP queries. This helps avoid blocking a request if the LDAP server becomes unresponsive. A value of `0` means there is no timeout. (default: `10`) | **{dotted-circle}** No | `10` or `30` |
| `active_directory` | This setting specifies if LDAP server is Active Directory LDAP server. For non-AD servers it skips the AD specific queries. If your LDAP server is not AD, set this to false. | **{dotted-circle}** No | boolean |
| `allow_username_or_email_login` | If enabled, GitLab ignores everything after the first `@` in the LDAP username submitted by the user on sign-in. If you are using `uid: 'userPrincipalName'` on ActiveDirectory you must disable this setting, because the userPrincipalName contains an `@`. | **{dotted-circle}** No | boolean |
| `block_auto_created_users` | To maintain tight control over the number of billable users on your GitLab installation, enable this setting to keep new users blocked until they have been cleared by an administrator (default: false). | **{dotted-circle}** No | boolean |
| `base` | Base where we can search for users. | **{check-circle}** Yes | `'ou=people,dc=gitlab,dc=example'` or `'DC=mydomain,DC=com'` |
| `user_filter`      | Filter LDAP users. Format: [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html) Note: GitLab does not support `omniauth-ldap`'s custom filter syntax. | **{dotted-circle}** No | Some examples of the `user_filter` field syntax:<br/><br/>- `'(employeeType=developer)'`<br/>- `'(&(objectclass=user)(|(samaccountname=momo)(samaccountname=toto)))'` |
| `lowercase_usernames` | If enabled, GitLab converts the name to lower case. | **{dotted-circle}** No | boolean |
| `retry_empty_result_with_codes` | An array of LDAP query response code that attempt to retry the operation if the result/content is empty. For Google Secure LDAP, set this value to `[80]`. | **{dotted-circle}** No | `[80]` |

### SSL configuration settings

These SSL configuration settings are available:

| Setting       | Description | Required | Examples |
|---------------|-------------|----------|----------|
| `ca_file`     | Specifies the path to a file containing a PEM-format CA certificate, for example, if you need an internal CA. | **{dotted-circle}** No | `'/etc/ca.pem'` |
| `ssl_version` | Specifies the SSL version for OpenSSL to use, if the OpenSSL default is not appropriate. | **{dotted-circle}** No | `'TLSv1_1'` |
| `ciphers`     | Specific SSL ciphers to use in communication with LDAP servers. | **{dotted-circle}** No | `'ALL:!EXPORT:!LOW:!aNULL:!eNULL:!SSLv2'` |
| `cert`        | Client certificate. | **{dotted-circle}** No | `'-----BEGIN CERTIFICATE----- <REDACTED> -----END CERTIFICATE -----'` |
| `key`         | Client private key. | **{dotted-circle}** No | `'-----BEGIN PRIVATE KEY----- <REDACTED> -----END PRIVATE KEY -----'` |

### Attribute configuration settings

GitLab uses these LDAP attributes to create an account for the LDAP user. The specified
attribute can be either:

- The attribute name as a string. For example, `'mail'`.
- An array of attribute names to try in order. For example, `['mail', 'email']`.

The user's LDAP sign in is the LDAP attribute [specified as `uid`](#basic-configuration-settings).

| Setting      | Description | Required | Examples |
|--------------|-------------|----------|----------|
| `username`   | Used in paths for the user's own projects (for example, `gitlab.example.com/username/project`) and when mentioning them in issues, merge request and comments (for example, `@username`). If the attribute specified for `username` contains an email address, the GitLab username is part of the email address before the `@`. | **{dotted-circle}** No | `['uid', 'userid', 'sAMAccountName']` |
| `email`      | LDAP attribute for user email. | **{dotted-circle}** No | `['mail', 'email', 'userPrincipalName']` |
| `name`       | LDAP attribute for user display name. If `name` is blank, the full name is taken from the `first_name` and `last_name`. | **{dotted-circle}** No | Attributes `'cn'`, or `'displayName'` commonly carry full names. Alternatively, you can force the use of `first_name` and `last_name` by specifying an absent attribute such as `'somethingNonExistent'`. |
| `first_name` | LDAP attribute for user first name. Used when the attribute configured for `name` does not exist. | **{dotted-circle}** No | `'givenName'` |
| `last_name`  | LDAP attribute for user last name. Used when the attribute configured for `name` does not exist. | **{dotted-circle}** No | `'sn'` |

### LDAP sync configuration settings **(PREMIUM SELF)**

These LDAP sync configuration settings are available:

| Setting           | Description | Required | Examples |
|-------------------|-------------|----------|----------|
| `group_base`      | Base used to search for groups. | **{dotted-circle}** No (required when `external_groups` is configured) | `'ou=groups,dc=gitlab,dc=example'` |
| `admin_group`     | The CN of a group containing GitLab administrators. Not `cn=administrators` or the full DN. | **{dotted-circle}** No | `'administrators'` |
| `external_groups` | An array of CNs of groups containing users that should be considered external. Not `cn=interns` or the full DN. | **{dotted-circle}** No | `['interns', 'contractors']` |
| `sync_ssh_keys`   | The LDAP attribute containing a user's public SSH key. | **{dotted-circle}** No | `'sshPublicKey'` or false if not set |

### Use multiple LDAP servers **(PREMIUM SELF)**

If you have users on multiple LDAP servers, you can configure GitLab to use them. To add additional LDAP servers:

1. Duplicate the [`main` LDAP configuration](#configure-ldap).
1. Edit each duplicate configuration with the details of the additional servers.
   - For each additional server, choose a different provider ID, like `main`, `secondary`, or `tertiary`. Use lowercase
     alphanumeric characters. GitLab uses the provider ID to associate each user with a specific LDAP server.
   - For each entry, use a unique `label` value. These values are used for the tab names on the sign-in page.

The following example shows how to configure three LDAP servers with
minimal configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'GitLab AD',
       'host' =>  'ad.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'secondary' => {
       'label' => 'GitLab Secondary AD',
       'host' =>  'ad-secondary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'tertiary' => {
       'label' => 'GitLab Tertiary AD',
       'host' =>  'ad-tertiary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'GitLab AD'
             host: 'ad.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           secondary:
             label: 'GitLab Secondary AD'
             host: 'ad-secondary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           tertiary:
             label: 'GitLab Tertiary AD'
             host: 'ad-tertiary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'GitLab AD',
               'host' =>  'ad.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'secondary' => {
               'label' => 'GitLab Secondary AD',
               'host' =>  'ad-secondary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'tertiary' => {
               'label' => 'GitLab Tertiary AD',
               'host' =>  'ad-tertiary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'GitLab AD'
           host: 'ad.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         secondary:
           label: 'GitLab Secondary AD'
           host: 'ad-secondary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         tertiary:
           label: 'GitLab Tertiary AD'
           host: 'ad-tertiary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

For more information about the various LDAP options, see the `ldap` setting in
[`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example).

::EndTabs

This example results in a sign-in page with the following tabs:

- **GitLab AD**.
- **GitLab Secondary AD**.
- **GitLab Tertiary AD**.

### Set up LDAP user filter

To limit all GitLab access to a subset of the LDAP users on your LDAP server, first narrow the
configured `base`. However, to further filter users if
necessary, you can set up an LDAP user filter. The filter must comply with [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html).

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'user_filter' => '(employeeType=developer)'
     }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             user_filter: '(employeeType=developer)'
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'user_filter' => '(employeeType=developer)'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           user_filter: '(employeeType=developer)'
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

To limit access to the nested members of an Active Directory group, use the following syntax:

```plaintext
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

For more information about `LDAP_MATCHING_RULE_IN_CHAIN` filters, see
[Search Filter Syntax](https://learn.microsoft.com/en-us/windows/win32/adsi/search-filter-syntax).

Support for nested members in the user filter shouldn't be confused with
[group sync nested groups](ldap_synchronization.md#supported-ldap-group-typesattributes) support.

GitLab does not support the custom filter syntax used by OmniAuth LDAP.

#### Escape special characters in `user_filter`

The `user_filter` DN can contain special characters. For example:

- A comma:

  ```plaintext
  OU=GitLab, Inc,DC=gitlab,DC=com
  ```

- Open and close brackets:

  ```plaintext
  OU=GitLab (Inc),DC=gitlab,DC=com
  ```

These characters must be escaped as documented in
[RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html#section-4).

- Escape commas with `\2C`. For example:

  ```plaintext
  OU=GitLab\2C Inc,DC=gitlab,DC=com
  ```

- Escape open brackets with `\28` and close brackets with `\29`. For example:

  ```plaintext
  OU=GitLab \28Inc\29,DC=gitlab,DC=com
  ```

### Enable LDAP username lowercase

Some LDAP servers, depending on their configuration, can return uppercase usernames.
This can lead to several confusing issues such as creating links or namespaces with uppercase names.

GitLab can automatically lowercase usernames provided by the LDAP server by enabling
the configuration option `lowercase_usernames`. By default, this configuration option is `false`.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'lowercase_usernames' => true
     }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
            lowercase_usernames: true
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'lowercase_usernames' => true
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           lowercase_usernames: true
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Disable LDAP web sign in

It can be useful to prevent using LDAP credentials through the web UI when
an alternative such as SAML is preferred. This allows LDAP to be used for group
sync, while also allowing your SAML identity provider to handle additional
checks like custom 2FA.

When LDAP web sign in is disabled, users don't see an **LDAP** tab on the sign-in page.
This does not disable using LDAP credentials for Git access.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         preventSignin: true
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       prevent_ldap_sign_in: true
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Use encrypted credentials

Instead of having the LDAP integration credentials stored in plaintext in the configuration files, you can optionally
use an encrypted file for the LDAP credentials.

Prerequisites:

- To use encrypted credentials, you must first enable the
  [encrypted configuration](../../encrypted_configuration.md).

The encrypted configuration for LDAP exists in an encrypted YAML file. The
unencrypted contents of the file should be a subset of the secret settings from
your `servers` block in the LDAP configuration.

The supported configuration items for the encrypted file are:

- `bind_dn`
- `password`

::Tabs

:::TabTitle Linux package (Omnibus)

1. If initially your LDAP configuration in `/etc/gitlab/gitlab.rb` looked like:

   ```ruby
     gitlab_rails['ldap_servers'] = {
       'main' => {
         'bind_dn' => 'admin',
         'password' => '123'
       }
     }
   ```

1. Edit the encrypted secret:

   ```shell
   sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. Enter the unencrypted contents of the LDAP secret:

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. Edit `/etc/gitlab/gitlab.rb` and remove the settings for `bind_dn` and `password`.
1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

Use a Kubernetes secret to store the LDAP password. For more information,
read about [Helm LDAP secrets](https://docs.gitlab.com/charts/installation/secrets.html#ldap-password).

:::TabTitle Docker

1. If initially your LDAP configuration in `docker-compose.yml` looked like:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'bind_dn' => 'admin',
               'password' => '123'
             }
           }
   ```

1. Get inside the container, and edit the encrypted secret:

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. Enter the unencrypted contents of the LDAP secret:

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. Edit `docker-compose.yml` and remove the settings for `bind_dn` and `password`.
1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. If initially your LDAP configuration in `/home/git/gitlab/config/gitlab.yml` looked like:

   ```yaml
   production:
     ldap:
       servers:
         main:
           bind_dn: admin
           password: '123'
   ```

1. Edit the encrypted secret:

   ```shell
   bundle exec rake gitlab:ldap:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. Enter the unencrypted contents of the LDAP secret:

   ```yaml
   main:
    bind_dn: admin
    password: '123'
   ```

1. Edit `/home/git/gitlab/config/gitlab.yml` and remove the settings for `bind_dn` and `password`.
1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Updating LDAP DN and email

When an LDAP server creates a user in GitLab, the user's LDAP distinguished name (DN) is linked to their GitLab account
as an identifier.

When a user tries to sign in with LDAP, GitLab tries to find the user using the DN saved on that user's account.

- If GitLab finds the user by the DN and the user's email address:
  - Matches the GitLab account's email address, GitLab does not take any further action.
  - Has changed, GitLab updates its record of the user's email to match the one in LDAP.
- If GitLab cannot find a user by their DN, it tries to find the user by their email. If GitLab:
  - Finds the user by their email, GitLab updates the DN stored in the user's GitLab account. Both values now
    match the information stored in LDAP.
  - Cannot find the user by their email address (both the DN **and** the email address have changed), see
    [User DN and email have changed](ldap-troubleshooting.md#user-dn-and-email-have-changed).

## Disable anonymous LDAP authentication

GitLab doesn't support TLS client authentication. Complete these steps on your LDAP server.

1. Disable anonymous authentication.
1. Enable one of the following authentication types:
   - Simple authentication.
   - Simple Authentication and Security Layer (SASL) authentication.

The TLS client authentication setting in your LDAP server cannot be mandatory and clients cannot be
authenticated with the TLS protocol.

## Users deleted from LDAP

Users deleted from the LDAP server:

- Are immediately blocked from signing in to GitLab.
- [No longer consume a license](../../../user/admin_area/moderate_users.md).

However, these users can continue to use Git with SSH until the next time the
[LDAP check cache runs](ldap_synchronization.md#adjust-ldap-user-sync-schedule).

To delete the account immediately, you can manually
[block the user](../../../user/admin_area/moderate_users.md#block-a-user).

## Update user email addresses

Email addresses on the LDAP server are considered the source of truth for users when LDAP is used to sign in.

Updating user email addresses must be done on the LDAP server that manages the user. The email address for GitLab is updated either:

- When the user next signs in.
- When the next [user sync](ldap_synchronization.md#user-sync) is run.

The updated user's previous email address becomes the secondary email address to preserve that user's commit history.

You can find more details on the expected behavior of user updates in our [LDAP troubleshooting section](ldap-troubleshooting.md#user-dn-and-email-have-changed).

## Google Secure LDAP

> Introduced in GitLab 11.9.

[Google Cloud Identity](https://cloud.google.com/identity/) provides a Secure
LDAP service that can be configured with GitLab for authentication and group sync.
See [Google Secure LDAP](google_secure_ldap.md) for detailed configuration instructions.

## Synchronize users and groups

For more information on synchronizing users and groups between LDAP and GitLab, see
[LDAP synchronization](ldap_synchronization.md).

## Move from LDAP to SAML

1. [Configure SAML](../../../integration/saml.md). Add `auto_link_ldap_user` to:
   - [`gitlab.rb` for Omnibus](../../../integration/saml.html?tab=Linux+package+%28Omnibus%29).
   - [`values.yml` for Kubernetes](../../../integration/saml.html?tab=Helm+chart+%28Kubernetes%29).
   For more information, see the [initial settings for all providers](../../../integration/omniauth.md#configure-initial-settings).

1. Optional. [Disable the LDAP auth from the sign-in page](#disable-ldap-web-sign-in).

1. Optional. To fix issues with linking users, you can first [remove those users' LDAP identities](ldap-troubleshooting.md#remove-the-identity-records-that-relate-to-the-removed-ldap-server).

1. Confirm that users are able to sign in to their accounts. If a user cannot sign in, check if that user's LDAP is still there and remove it if necessary. If this issue persists, check the logs to identify the problem.

1. In the configuration file, change:
   - `omniauth_auto_link_user` to `saml` only.
   - `auto_link_ldap_user` to false.
   - `ldap_enabled` to `false`. 
   You can also comment out the LDAP provider settings.

## Troubleshooting

See our [administrator guide to troubleshooting LDAP](ldap-troubleshooting.md).
