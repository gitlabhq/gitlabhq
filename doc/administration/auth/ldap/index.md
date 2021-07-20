---
type: reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# General LDAP setup **(FREE SELF)**

GitLab integrates with [LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)
to support user authentication.

This integration works with most LDAP-compliant directory servers, including:

- Microsoft Active Directory
  - [Microsoft Active Directory Trusts](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771568(v=ws.10)) are not supported.
- Apple Open Directory
- Open LDAP
- 389 Server

Users added through LDAP take a [licensed seat](../../../subscriptions/self_managed/index.md#billable-users).

GitLab Enterprise Editions (EE) include enhanced integration,
including group membership syncing and multiple LDAP server support.

## Security

GitLab assumes that LDAP users:

- Are not able to change their LDAP `mail`, `email`, or `userPrincipalName` attributes.
  An LDAP user allowed to change their email on the LDAP server can potentially
  [take over any account](#enabling-ldap-sign-in-for-existing-gitlab-users)
  on your GitLab server.
- Have unique email addresses. If not, it's possible for LDAP users with the same
  email address to share the same GitLab account.

We recommend against using LDAP integration if your LDAP users are
allowed to change their `mail`, `email` or `userPrincipalName` attributes on
the LDAP server, or share email addresses.

### User deletion

Users deleted from the LDAP server are immediately blocked from signing in
to GitLab. However, there's an LDAP check cache time of one hour (which is
[configurable](#adjusting-ldap-user-sync-schedule) for GitLab Premium users).
This means users already signed-in or who are using Git over SSH can access
GitLab for up to one hour. Manually block the user in the GitLab Admin Area
to immediately block all access.

## Git password authentication

LDAP-enabled users can authenticate with Git using their GitLab username or
email and LDAP password, even if password authentication for Git is disabled
in the application settings.

## Enabling LDAP sign-in for existing GitLab users

When a user signs in to GitLab with LDAP for the first time and their LDAP
email address is the primary email address of an existing GitLab user, the
LDAP DN is associated with the existing user. If the LDAP email attribute
isn't found in the GitLab user database, a new user is created.

In other words, if an existing GitLab user wants to enable LDAP sign-in for
themselves, they should check that their GitLab email address matches their
LDAP email address, and then sign into GitLab by using their LDAP credentials.

## Google Secure LDAP

> Introduced in GitLab 11.9.

[Google Cloud Identity](https://cloud.google.com/identity/) provides a Secure
LDAP service that can be configured with GitLab for authentication and group sync.
See [Google Secure LDAP](google_secure_ldap.md) for detailed configuration instructions.

## Configuration

To enable LDAP integration you need to add your LDAP server settings in
`/etc/gitlab/gitlab.rb` or `/home/git/gitlab/config/gitlab.yml` for Omnibus
GitLab and installations from source respectively.

There is a Rake task to check LDAP configuration. After configuring LDAP
using the documentation below, see [LDAP check Rake task](../../raketasks/check.md#ldap-check)
for information on the LDAP check Rake task.

NOTE:
The `encryption` value `simple_tls` corresponds to 'Simple TLS' in the LDAP
library. `start_tls` corresponds to StartTLS, not to be confused with regular TLS.
Normally, if you specify `simple_tls` it is on port 636, while `start_tls` (StartTLS)
would be on port 389. `plain` also operates on port 389. Removed values: `tls` was replaced
with `start_tls` and `ssl` was replaced with `simple_tls`.

LDAP users must have a set email address, regardless of whether or not it's used
to sign in.

### Example Configurations

**Omnibus Configuration**

```ruby
gitlab_rails['ldap_enabled'] = true
gitlab_rails['prevent_ldap_sign_in'] = false
gitlab_rails['ldap_servers'] = {
'main' => {
  'label' => 'LDAP',
  'host' =>  'ldap.mydomain.com',
  'port' => 389,
  'uid' => 'sAMAccountName',
  'encryption' => 'simple_tls',
  'verify_certificates' => true,
  'bind_dn' => '_the_full_dn_of_the_user_you_will_bind_with',
  'password' => '_the_password_of_the_bind_user',
  'verify_certificates' => true,
  'tls_options' => {
    'ca_file' => '',
    'ssl_version' => '',
    'ciphers' => '',
    'cert' => '',
    'key' => ''
  },
  'timeout' => 10,
  'active_directory' => true,
  'allow_username_or_email_login' => false,
  'block_auto_created_users' => false,
  'base' => 'dc=example,dc=com',
  'user_filter' => '',
  'attributes' => {
    'username' => ['uid', 'userid', 'sAMAccountName'],
    'email' => ['mail', 'email', 'userPrincipalName'],
    'name' => 'cn',
    'first_name' => 'givenName',
    'last_name' => 'sn'
  },
  'lowercase_usernames' => false,

  # EE Only
  'group_base' => '',
  'admin_group' => '',
  'external_groups' => [],
  'sync_ssh_keys' => false
  }
}
```

**Source Configuration**

```yaml
production:
  # snip...
  ldap:
    enabled: false
    prevent_ldap_sign_in: false
    servers:
      main:
        label: 'LDAP'
        ...
```

### Basic Configuration Settings

| Setting            | Description | Required | Examples |
|--------------------|-------------|----------|----------|
| `label`            | A human-friendly name for your LDAP server. It is displayed on your sign-in page. | **{check-circle}** Yes | `'Paris'` or `'Acme, Ltd.'` |
| `host`             | IP address or domain name of your LDAP server. | **{check-circle}** Yes | `'ldap.mydomain.com'` |
| `port`             | The port to connect with on your LDAP server. Always an integer, not a string. | **{check-circle}** Yes | `389` or `636` (for SSL) |
| `uid`              | LDAP attribute for username. Should be the attribute, not the value that maps to the `uid`. | **{check-circle}** Yes | `'sAMAccountName'` or `'uid'` or `'userPrincipalName'` |
| `bind_dn`          | The full DN of the user you bind with. | **{dotted-circle}** No | `'america\momo'` or `'CN=Gitlab,OU=Users,DC=domain,DC=com'` |
| `password`         | The password of the bind user. | **{dotted-circle}** No | `'your_great_password'` |
| `encryption`       | Encryption method. The `method` key is deprecated in favor of `encryption`. | **{check-circle}** Yes | `'start_tls'` or `'simple_tls'` or `'plain'` |
| `verify_certificates` | Enables SSL certificate verification if encryption method is `start_tls` or `simple_tls`. Defaults to true. | **{dotted-circle}** No | boolean |
| `timeout`          | Set a timeout, in seconds, for LDAP queries. This helps avoid blocking a request if the LDAP server becomes unresponsive. A value of `0` means there is no timeout. (default: `10`) | **{dotted-circle}** No | `10` or `30` |
| `active_directory` | This setting specifies if LDAP server is Active Directory LDAP server. For non-AD servers it skips the AD specific queries. If your LDAP server is not AD, set this to false. | **{dotted-circle}** No | boolean |
| `allow_username_or_email_login` | If enabled, GitLab ignores everything after the first `@` in the LDAP username submitted by the user on sign-in. If you are using `uid: 'userPrincipalName'` on ActiveDirectory you need to disable this setting, because the userPrincipalName contains an `@`. | **{dotted-circle}** No | boolean |
| `block_auto_created_users` | To maintain tight control over the number of billable users on your GitLab installation, enable this setting to keep new users blocked until they have been cleared by an administrator (default: false). | **{dotted-circle}** No | boolean |
| `base` | Base where we can search for users. | **{check-circle}** Yes | `'ou=people,dc=gitlab,dc=example'` or `'DC=mydomain,DC=com'` |
| `user_filter`      | Filter LDAP users. Format: [RFC 4515](https://tools.ietf.org/search/rfc4515) Note: GitLab does not support `omniauth-ldap`'s custom filter syntax. | **{dotted-circle}** No | For examples, read [Examples of user filters](#examples-of-user-filters). |
| `lowercase_usernames` | If enabled, GitLab converts the name to lower case. | **{dotted-circle}** No | boolean |
| `retry_empty_result_with_codes` | An array of LDAP query response code that will attempt to retrying the operation if the result/content is empty. | **{dotted-circle}** No | `[80]` |

#### Examples of user filters

Some examples of the `user_filter` field syntax:

- `'(employeeType=developer)'`
- `'(&(objectclass=user)(|(samaccountname=momo)(samaccountname=toto)))'`

### SSL Configuration Settings

| Setting       | Description | Required | Examples |
|---------------|-------------|----------|----------|
| `ca_file`     | Specifies the path to a file containing a PEM-format CA certificate, for example, if you need to use an internal CA. | **{dotted-circle}** No | `'/etc/ca.pem'` |
| `ssl_version` | Specifies the SSL version for OpenSSL to use, if the OpenSSL default is not appropriate. | **{dotted-circle}** No | `'TLSv1_1'` |
| `ciphers`     | Specific SSL ciphers to use in communication with LDAP servers. | **{dotted-circle}** No | `'ALL:!EXPORT:!LOW:!aNULL:!eNULL:!SSLv2'` |
| `cert`        | Client certificate. | **{dotted-circle}** No | `'-----BEGIN CERTIFICATE----- <REDACTED> -----END CERTIFICATE -----'` |
| `key`         | Client private key. | **{dotted-circle}** No | `'-----BEGIN PRIVATE KEY----- <REDACTED> -----END PRIVATE KEY -----'` |

### Attribute Configuration Settings

LDAP attributes that GitLab uses to create an account for the LDAP user. The specified
attribute can either be the attribute name as a string (for example, `'mail'`), or an
array of attribute names to try in order (for example, `['mail', 'email']`). Note that
the user's LDAP sign-in is the attribute specified as `uid` above.

| Setting      | Description | Required | Examples |
|--------------|-------------|----------|----------|
| `username`   | The username is used in paths for the user's own projects (like `gitlab.example.com/username/project`) and when mentioning them in issues, merge request and comments (like `@username`). If the attribute specified for `username` contains an email address, the GitLab username is part of the email address before the `@`. | **{dotted-circle}** No | `['uid', 'userid', 'sAMAccountName']` |
| `email`      | LDAP attribute for user email. | **{dotted-circle}** No | `['mail', 'email', 'userPrincipalName']` |
| `name`       | LDAP attribute for user display name. If `name` is blank, the full name is taken from the `first_name` and `last_name`. | **{dotted-circle}** No | Attributes `'cn'`, or `'displayName'` commonly carry full names. Alternatively, you can force the use of `first_name` and `last_name` by specifying an absent attribute such as `'somethingNonExistent'`. |
| `first_name` | LDAP attribute for user first name. Used when the attribute configured for `name` does not exist. | **{dotted-circle}** No | `'givenName'` |
| `last_name`  | LDAP attribute for user last name. Used when the attribute configured for `name` does not exist. | **{dotted-circle}** No | `'sn'` |

### LDAP Sync Configuration Settings **(PREMIUM SELF)**

| Setting           | Description | Required | Examples |
|-------------------|-------------|----------|----------|
| `group_base`      | Base used to search for groups. | **{dotted-circle}** No | `'ou=groups,dc=gitlab,dc=example'` |
| `admin_group`     | The CN of a group containing GitLab administrators. Note: Not `cn=administrators` or the full DN. | **{dotted-circle}** No | `'administrators'` |
| `external_groups` | An array of CNs of groups containing users that should be considered external. Note: Not `cn=interns` or the full DN. | **{dotted-circle}** No | `['interns', 'contractors']` |
| `sync_ssh_keys`   | The LDAP attribute containing a user's public SSH key. | **{dotted-circle}** No | `'sshPublicKey'` or false if not set |

### Set up LDAP user filter

If you want to limit all GitLab access to a subset of the LDAP users on your
LDAP server, the first step should be to narrow the configured `base`. However,
it's sometimes necessary to further filter users. In this case, you can set
up an LDAP user filter. The filter must comply with
[RFC 4515](https://tools.ietf.org/search/rfc4515).

**Omnibus configuration**

```ruby
gitlab_rails['ldap_servers'] = {
'main' => {
  # snip...
  'user_filter' => '(employeeType=developer)'
  }
}
```

**Source configuration**

```yaml
production:
  ldap:
    servers:
      main:
        # snip...
        user_filter: '(employeeType=developer)'
```

If you want to limit access to the nested members of an Active Directory
group, use the following syntax:

```plaintext
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

For more information about this "LDAP_MATCHING_RULE_IN_CHAIN" filter, see the following
[Microsoft Search Filter Syntax](https://docs.microsoft.com/en-us/windows/win32/adsi/search-filter-syntax) document.
Support for nested members in the user filter shouldn't be confused with
[group sync nested groups support](#supported-ldap-group-typesattributes). **(PREMIUM SELF)**

GitLab does not support the custom filter syntax used by OmniAuth LDAP.

#### Escaping special characters

The `user_filter` DN can contain special characters. For example:

- A comma:

  ```plaintext
  OU=GitLab, Inc,DC=gitlab,DC=com
  ```

- Open and close brackets:

  ```plaintext
  OU=Gitlab (Inc),DC=gitlab,DC=com
  ```

  These characters must be escaped as documented in
  [RFC 4515](https://tools.ietf.org/search/rfc4515).

- Escape commas with `\2C`. For example:

  ```plaintext
  OU=GitLab\2C Inc,DC=gitlab,DC=com
  ```

- Escape open and close brackets with `\28` and `\29`, respectively. For example:

  ```plaintext
  OU=Gitlab \28Inc\29,DC=gitlab,DC=com
  ```

### Enabling LDAP username lowercase

Some LDAP servers, depending on their configurations, can return uppercase usernames.
This can lead to several confusing issues such as creating links or namespaces with uppercase names.

GitLab can automatically lowercase usernames provided by the LDAP server by enabling
the configuration option `lowercase_usernames`. By default, this configuration option is `false`.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
   'main' => {
     # snip...
     'lowercase_usernames' => true
     }
   }
   ```

1. [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source configuration**

1. Edit `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           lowercase_usernames: true
   ```

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Disable LDAP web sign in

It can be useful to prevent using LDAP credentials through the web UI when
an alternative such as SAML is preferred. This allows LDAP to be used for group
sync, while also allowing your SAML identity provider to handle additional
checks like custom 2FA.

When LDAP web sign in is disabled, users don't see an **LDAP** tab on the sign-in page.
This does not disable [using LDAP credentials for Git access](#git-password-authentication).

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source configuration**

1. Edit `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       prevent_ldap_sign_in: true
   ```

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Using encrypted credentials

Instead of having the LDAP integration credentials stored in plaintext in the configuration files, you can optionally
use an encrypted file for the LDAP credentials. To use this feature, you first need to enable
[GitLab encrypted configuration](../../encrypted_configuration.md).

The encrypted configuration for LDAP exists in an encrypted YAML file. By default the file is created at
`shared/encrypted_configuration/ldap.yaml.enc`. This location is configurable in the GitLab configuration.

The unencrypted contents of the file should be a subset of the secret settings from your `servers` block in the LDAP
configuration.

The supported configuration items for the encrypted file are:

- `bind_dn`
- `password`

The encrypted contents can be configured with the [LDAP secret edit Rake command](../../raketasks/ldap.md#edit-secret).

**Omnibus configuration**

If initially your LDAP configuration looked like:

1. In `/etc/gitlab/gitlab.rb`:

  ```ruby
    gitlab_rails['ldap_servers'] = {
    'main' => {
      # snip...
      'bind_dn' => 'admin',
      'password' => '123'
      }
    }
  ```

1. Edit the encrypted secret:

   ```shell
   sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. The unencrypted contents of the LDAP secret should be entered like:

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. Edit `/etc/gitlab/gitlab.rb` and remove the settings for `user_bn` and `password`.

1. [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source configuration**

If initially your LDAP configuration looked like:

1. In `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           bind_dn: admin
           password: '123'
   ```

1. Edit the encrypted secret:

   ```shell
   bundle exec rake gitlab:ldap:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. The unencrypted contents of the LDAP secret should be entered like:

   ```yaml
   main:
    bind_dn: admin
    password: '123'
   ```

1. Edit `config/gitlab.yaml` and remove the settings for `user_bn` and `password`.

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Encryption

### TLS Server Authentication

There are two encryption methods, `simple_tls` and `start_tls`.

For either encryption method, if setting `verify_certificates: false`, TLS
encryption is established with the LDAP server before any LDAP-protocol data is
exchanged but no validation of the LDAP server's SSL certificate is performed.

### Limitations

#### TLS Client Authentication

Not implemented by `Net::LDAP`.

You should disable anonymous LDAP authentication and enable simple or SASL
authentication. The TLS client authentication setting in your LDAP server cannot
be mandatory and clients cannot be authenticated with the TLS protocol.

## Multiple LDAP servers **(PREMIUM SELF)**

With GitLab, you can configure multiple LDAP servers that your GitLab instance
connects to.

To add another LDAP server:

1. Duplicate the settings under [the main configuration](#configuration).
1. Edit them to match the additional LDAP server.

Be sure to choose a different provider ID made of letters a-z and numbers 0-9.
This ID is stored in the database so that GitLab can remember which LDAP
server a user belongs to.

![Multiple LDAP Servers Sign in](img/multi_login.gif)

Based on the example illustrated on the image above,
our `gitlab.rb` configuration would look like:

```ruby
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = {
'main' => {
  'label' => 'GitLab AD',
  'host' =>  'ad.example.org',
  'port' => 636,
  ...
  },

'secondary' => {
  'label' => 'GitLab Secondary AD',
  'host' =>  'ad-secondary.example.net',
  'port' => 636,
  ...
  },

'tertiary' => {
  'label' => 'GitLab Tertiary AD',
  'host' =>  'ad-tertiary.example.net',
  'port' => 636,
  ...
  }

}
```

If you configure multiple LDAP servers, use a unique naming convention for the
`label` section of each entry. That label is used as the display name of the tab
shown on the sign-in page.

## User sync **(PREMIUM SELF)**

Once per day, GitLab runs a worker to check and update GitLab
users against LDAP.

The process executes the following access checks:

- Ensure the user is still present in LDAP.
- If the LDAP server is Active Directory, ensure the user is active (not
  blocked/disabled state). This is checked only if
  `active_directory: true` is set in the LDAP configuration.

In Active Directory, a user is marked as disabled/blocked if the user
account control attribute (`userAccountControl:1.2.840.113556.1.4.803`)
has bit 2 set.

<!-- vale gitlab.Spelling = NO -->

For more information, see [Bitmask Searches in LDAP](https://ctovswild.com/2009/09/03/bitmask-searches-in-ldap/).

<!-- vale gitlab.Spelling = YES -->

The user is set to an `ldap_blocked` state in GitLab if the previous conditions
fail. This means the user cannot sign in or push or pull code.

The process also updates the following user information:

- Email address
- SSH public keys (if `sync_ssh_keys` is set)
- Kerberos identity (if Kerberos is enabled)

The LDAP sync process:

- Updates existing users.
- Creates new users on first sign in.

### Adjusting LDAP user sync schedule **(PREMIUM SELF)**

By default, GitLab runs a worker once per day at 01:30 a.m. server time to
check and update GitLab users against LDAP.

You can manually configure LDAP user sync times by setting the
following configuration values, in cron format. If needed, you can
use a [crontab generator](http://www.crontabgenerator.com).
The example below shows how to set LDAP user
sync to run once every 12 hours at the top of the hour.

**Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source installations**

1. Edit `config/gitlab.yaml`:

   ```yaml
   cron_jobs:
     ldap_sync_worker_cron:
       "0 */12 * * *"
   ```

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Group Sync **(PREMIUM SELF)**

If your LDAP supports the `memberof` property, when the user signs in for the
first time GitLab triggers a sync for groups the user should be a member of.
That way they don't need to wait for the hourly sync to be granted
access to their groups and projects.

A group sync process runs every hour on the hour, and `group_base` must be set
in LDAP configuration for LDAP synchronizations based on group CN to work. This allows
GitLab group membership to be automatically updated based on LDAP group members.

The `group_base` configuration should be a base LDAP 'container', such as an
'organization' or 'organizational unit', that contains LDAP groups that should
be available to GitLab. For example, `group_base` could be
`ou=groups,dc=example,dc=com`. In the configuration file it looks like the
following.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
   'main' => {
     # snip...
     'group_base' => 'ou=groups,dc=example,dc=com',
     }
   }
   ```

1. [Apply your changes to GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure).

**Source configuration**

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           group_base: ou=groups,dc=example,dc=com
   ```

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

To take advantage of group sync, group owners or maintainers need to [create one
or more LDAP group links](#adding-group-links).

### Adding group links **(PREMIUM SELF)**

For information on adding group links by using CNs and filters, refer to the
[GitLab groups documentation](../../../user/group/index.md#manage-group-memberships-via-ldap).

### Administrator sync **(PREMIUM SELF)**

As an extension of group sync, you can automatically manage your global GitLab
administrators. Specify a group CN for `admin_group` and all members of the
LDAP group are given administrator privileges. The configuration looks
like the following.

NOTE:
Administrators are not synced unless `group_base` is also
specified alongside `admin_group`. Also, only specify the CN of the `admin_group`,
as opposed to the full DN.
Additionally, note that if an LDAP user has an `admin` role, but is not a member of the `admin_group`
group, GitLab revokes their `admin` role when syncing.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
   'main' => {
     # snip...
     'group_base' => 'ou=groups,dc=example,dc=com',
     'admin_group' => 'my_admin_group',
     }
   }
   ```

1. [Apply your changes to GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure).

**Source configuration**

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           group_base: ou=groups,dc=example,dc=com
           admin_group: my_admin_group
   ```

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Global group memberships lock **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1793) in GitLab 12.0.

"Lock memberships to LDAP synchronization" setting allows instance administrators
to lock down user abilities to invite new members to a group.

When enabled, the following applies:

- Only administrator can manage memberships of any group including access levels.
- Users are not allowed to share project with other groups or invite members to
  a project created in a group.

To enable it you need to:

1. [Enable LDAP](#configuration)
1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Visibility and access controls** section.
1. Ensure the **Lock memberships to LDAP synchronization** checkbox is selected.

### Adjusting LDAP group sync schedule **(PREMIUM SELF)**

By default, GitLab runs a group sync process every hour, on the hour.
The values shown are in cron format. If needed, you can use a
[Crontab Generator](http://www.crontabgenerator.com).

WARNING:
Do not start the sync process too frequently as this
could lead to multiple syncs running concurrently. This is primarily a concern
for installations with a large number of LDAP users. Review the
[LDAP group sync benchmark metrics](#benchmarks) to see how
your installation compares before proceeding.

You can manually configure LDAP group sync times by setting the
following configuration values. The example below shows how to set group
sync to run once every two hours at the top of the hour.

**Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * * *"
   ```

1. [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source installations**

1. Edit `config/gitlab.yaml`:

   ```yaml
   cron_jobs:
     ldap_group_sync_worker_cron:
         "*/30 * * * *"
   ```

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

### External groups **(PREMIUM SELF)**

Using the `external_groups` setting allows you to mark all users belonging
to these groups as [external users](../../../user/permissions.md#external-users).
Group membership is checked periodically through the `LdapGroupSync` background
task.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
   'main' => {
     # snip...
     'external_groups' => ['interns', 'contractors'],
     }
   }
   ```

1. [Apply your changes to GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure).

**Source configuration**

1. Edit `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           external_groups: ['interns', 'contractors']
   ```

1. [Restart GitLab](../../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Group sync technical details

This section outlines what LDAP queries are executed and what behavior you
can expect from group sync.

Group member access are downgraded from a higher level if their LDAP group
membership changes. For example, if a user the Owner role in a group and the
next group sync reveals they should only have the Developer role, their
access is adjusted accordingly. The only exception is if the user is the
last owner in a group. Groups need at least one owner to fulfill
administrative duties.

#### Supported LDAP group types/attributes

GitLab supports LDAP groups that use member attributes:

- `member`
- `submember`
- `uniquemember`
- `memberof`
- `memberuid`

This means group sync supports (at least) LDAP groups with the following object
classes:

- `groupOfNames`
- `posixGroup`
- `groupOfUniqueNames`

Other object classes should work if members are defined as one of the
mentioned attributes.

Active Directory supports nested groups. Group sync recursively resolves
membership if `active_directory: true` is set in the configuration file.

##### Nested group memberships

Nested group memberships are resolved only if the nested group
is found in the configured `group_base`. For example, if GitLab sees a
nested group with DN `cn=nested_group,ou=special_groups,dc=example,dc=com` but
the configured `group_base` is `ou=groups,dc=example,dc=com`, `cn=nested_group`
is ignored.

#### Queries

- Each LDAP group is queried a maximum of one time with base `group_base` and
  filter `(cn=<cn_from_group_link>)`.
- If the LDAP group has the `memberuid` attribute, GitLab executes another
  LDAP query per member to obtain each user's full DN. These queries are
  executed with base `base`, scope 'base object', and a filter depending on
  whether `user_filter` is set. Filter may be `(uid=<uid_from_group>)` or a
  joining of `user_filter`.

#### Benchmarks

Group sync was written to be as performant as possible. Data is cached, database
queries are optimized, and LDAP queries are minimized. The last benchmark run
revealed the following metrics:

For 20,000 LDAP users, 11,000 LDAP groups, and 1,000 GitLab groups with 10
LDAP group links each:

- Initial sync (no existing members assigned in GitLab) took 1.8 hours
- Subsequent syncs (checking membership, no writes) took 15 minutes

These metrics are meant to provide a baseline and performance may vary based on
any number of factors. This was an extreme benchmark and most instances don't
have near this many users or groups. Disk speed, database performance,
network and LDAP server response time affects these metrics.

## Troubleshooting

See our [administrator guide to troubleshooting LDAP](ldap-troubleshooting.md).
