---
type: reference
---

<!-- If the change is EE-specific, put it in `ldap-ee.md`, NOT here. -->

# LDAP

GitLab integrates with LDAP to support user authentication.

This integration works with most LDAP-compliant directory servers, including:

- Microsoft Active Directory
- Apple Open Directory
- Open LDAP
- 389 Server.

GitLab Enterprise Editions (EE) include enhanced integration,
including group membership syncing as well as multiple LDAP servers support.

For more details about EE-specific LDAP features, see the
[LDAP Enterprise Edition documentation](ldap-ee.md).

NOTE: **Note:**
The information on this page is relevant for both GitLab CE and EE.

## Overview

[LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)
stands for **Lightweight Directory Access Protocol**, which is a standard
application protocol for accessing and maintaining distributed directory
information services over an Internet Protocol (IP) network.

## Security

GitLab assumes that LDAP users:

- Are not able to change their LDAP `mail`, `email`, or `userPrincipalName` attribute.
  An LDAP user who is allowed to change their email on the LDAP server can potentially
  [take over any account](#enabling-ldap-sign-in-for-existing-gitlab-users)
  on your GitLab server.
- Have unique email addresses, otherwise it is possible for LDAP users with the same
  email address to share the same GitLab account.

We recommend against using LDAP integration if your LDAP users are
allowed to change their 'mail', 'email' or 'userPrincipalName' attribute on
the LDAP server or share email addresses.

### User deletion

If a user is deleted from the LDAP server, they will be blocked in GitLab as
well. Users will be immediately blocked from logging in. However, there is an
LDAP check cache time of one hour (see note) which means users that
are already logged in or are using Git over SSH will still be able to access
GitLab for up to one hour. Manually block the user in the GitLab Admin Area to
immediately block all access.

NOTE: **Note**:
GitLab Enterprise Edition Starter supports a
[configurable sync time](ldap-ee.md#adjusting-ldap-user-sync-schedule),
with a default of one hour.

## Git password authentication

LDAP-enabled users can always authenticate with Git using their GitLab username
or email and LDAP password, even if password authentication for Git is disabled
in the application settings.

## Google Secure LDAP **(CORE ONLY)**

> Introduced in GitLab 11.9.

[Google Cloud Identity](https://cloud.google.com/identity/) provides a Secure
LDAP service that can be configured with GitLab for authentication and group sync.
See [Google Secure LDAP](google_secure_ldap.md) for detailed configuration instructions.

## Configuration

NOTE: **Note**:
In GitLab Enterprise Edition Starter, you can configure multiple LDAP servers
to connect to one GitLab server.

For a complete guide on configuring LDAP with:

- GitLab Community Edition, see
  [How to configure LDAP with GitLab CE](how_to_configure_ldap_gitlab_ce/index.md).
- Enterprise Editions, see
  [How to configure LDAP with GitLab EE](how_to_configure_ldap_gitlab_ee/index.md). **(STARTER ONLY)**

To enable LDAP integration you need to add your LDAP server settings in
`/etc/gitlab/gitlab.rb` or `/home/git/gitlab/config/gitlab.yml` for Omnibus
GitLab and installations from source respectively.

There is a Rake task to check LDAP configuration. After configuring LDAP
using the documentation below, see [LDAP check Rake task](../raketasks/check.md#ldap-check)
for information on the LDAP check Rake task.

Prior to version 7.4, GitLab used a different syntax for configuring
LDAP integration. The old LDAP integration syntax still works but may be
removed in a future version. If your `gitlab.rb` or `gitlab.yml` file contains
LDAP settings in both the old syntax and the new syntax, only the __old__
syntax will be used by GitLab.

The configuration inside `gitlab_rails['ldap_servers']` below is sensitive to
incorrect indentation. Be sure to retain the indentation given in the example.
Copy/paste can sometimes cause problems.

NOTE: **Note:**
The `encryption` value `ssl` corresponds to 'Simple TLS' in the LDAP
library. `tls` corresponds to StartTLS, not to be confused with regular TLS.
Normally, if you specify `ssl` it will be on port 636, while `tls` (StartTLS)
would be on port 389. `plain` also operates on port 389.

NOTE: **Note:**
LDAP users must have an email address set, regardless of whether it is used to log in.

**Omnibus configuration**

```ruby
gitlab_rails['ldap_enabled'] = true
gitlab_rails['prevent_ldap_sign_in'] = false
gitlab_rails['ldap_servers'] = YAML.load <<-EOS # remember to close this block with 'EOS' below
##
## 'main' is the GitLab 'provider ID' of this LDAP server
##
main:
  ##
  ## A human-friendly name for your LDAP server. It is OK to change the label later,
  ## for instance if you find out it is too large to fit on the web page.
  ##
  ## Example: 'Paris' or 'Acme, Ltd.'
  ##
  label: 'LDAP'

  ##
  ## Example: 'ldap.mydomain.com'
  ##
  host: '_your_ldap_server'

  ##
  ## This port is an example, it is sometimes different but it is always an
  ## integer and not a string.
  ##
  port: 389 # usually 636 for SSL
  uid: 'sAMAccountName' # This should be the attribute, not the value that maps to uid.

  ##
  ## Examples: 'america\momo' or 'CN=Gitlab Git,CN=Users,DC=mydomain,DC=com'
  ##
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'

  ##
  ## Encryption method. The "method" key is deprecated in favor of
  ## "encryption".
  ##
  ##   Examples: "start_tls" or "simple_tls" or "plain"
  ##
  ##   Deprecated values: "tls" was replaced with "start_tls" and "ssl" was
  ##   replaced with "simple_tls".
  ##
  ##
  encryption: 'plain'

  ##
  ## Enables SSL certificate verification if encryption method is
  ## "start_tls" or "simple_tls". Defaults to true since GitLab 10.0 for
  ## security. This may break installations upon upgrade to 10.0, that did
  ## not know their LDAP SSL certificates were not set up properly.
  ##
  verify_certificates: true

  # OpenSSL::SSL::SSLContext options.
  tls_options:
    # Specifies the path to a file containing a PEM-format CA certificate,
    # e.g. if you need to use an internal CA.
    #
    #   Example: '/etc/ca.pem'
    #
    ca_file: ''

    # Specifies the SSL version for OpenSSL to use, if the OpenSSL default
    # is not appropriate.
    #
    #   Example: 'TLSv1_1'
    #
    ssl_version: ''

    # Specific SSL ciphers to use in communication with LDAP servers.
    #
    # Example: 'ALL:!EXPORT:!LOW:!aNULL:!eNULL:!SSLv2'
    ciphers: ''

    # Client certificate
    #
    # Example:
    #   cert: |
    #     -----BEGIN CERTIFICATE-----
    #     MIIDbDCCAlSgAwIBAgIGAWkJxLmKMA0GCSqGSIb3DQEBCwUAMHcxFDASBgNVBAoTC0dvb2dsZSBJ
    #     bmMuMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQDEwtMREFQIENsaWVudDEPMA0GA1UE
    #     CxMGR1N1aXRlMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTAeFw0xOTAyMjAwNzE4
    #     rntnF4d+0dd7zP3jrWkbdtoqjLDT/5D7NYRmVCD5vizV98FJ5//PIHbD1gL3a9b2MPAc6k7NV8tl
    #     ...
    #     4SbuJPAiJxC1LQ0t39dR6oMCAMab3hXQqhL56LrR6cRBp6Mtlphv7alu9xb/x51y2x+g2zWtsf80
    #     Jrv/vKMsIh/sAyuogb7hqMtp55ecnKxceg==
    #     -----END CERTIFICATE -----
    cert: ''

    # Client private key
    #   key: |
    #     -----BEGIN PRIVATE KEY-----
    #     MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC3DmJtLRmJGY4xU1QtI3yjvxO6
    #     bNuyE4z1NF6Xn7VSbcAaQtavWQ6GZi5uukMo+W5DHVtEkgDwh92ySZMuJdJogFbNvJvHAayheCdN
    #     7mCQ2UUT9jGXIbmksUn9QMeJVXTZjgJWJzPXToeUdinx9G7+lpVa62UATEd1gaI3oyL72WmpDy/C
    #     rntnF4d+0dd7zP3jrWkbdtoqjLDT/5D7NYRmVCD5vizV98FJ5//PIHbD1gL3a9b2MPAc6k7NV8tl
    #     ...
    #     +9IhSYX+XIg7BZOVDeYqlPfxRvQh8vy3qjt/KUihmEPioAjLaGiihs1Fk5ctLk9A2hIUyP+sEQv9
    #     l6RG+a/mW+0rCWn8JAd464Ps9hE=
    #     -----END PRIVATE KEY-----
    key: ''

  ##
  ## Set a timeout, in seconds, for LDAP queries. This helps avoid blocking
  ## a request if the LDAP server becomes unresponsive.
  ## A value of 0 means there is no timeout.
  ##
  timeout: 10

  ##
  ## This setting specifies if LDAP server is Active Directory LDAP server.
  ## For non AD servers it skips the AD specific queries.
  ## If your LDAP server is not AD, set this to false.
  ##
  active_directory: true

  ##
  ## If allow_username_or_email_login is enabled, GitLab will ignore everything
  ## after the first '@' in the LDAP username submitted by the user on login.
  ##
  ## Example:
  ## - the user enters 'jane.doe@example.com' and 'p@ssw0rd' as LDAP credentials;
  ## - GitLab queries the LDAP server with 'jane.doe' and 'p@ssw0rd'.
  ##
  ## If you are using "uid: 'userPrincipalName'" on ActiveDirectory you need to
  ## disable this setting, because the userPrincipalName contains an '@'.
  ##
  allow_username_or_email_login: false

  ##
  ## To maintain tight control over the number of active users on your GitLab installation,
  ## enable this setting to keep new users blocked until they have been cleared by the admin
  ## (default: false).
  ##
  block_auto_created_users: false

  ##
  ## Base where we can search for users
  ##
  ##   Ex. 'ou=People,dc=gitlab,dc=example' or 'DC=mydomain,DC=com'
  ##
  ##
  base: ''

  ##
  ## Filter LDAP users
  ##
  ##   Format: RFC 4515 https://tools.ietf.org/search/rfc4515
  ##   Ex. (employeeType=developer)
  ##
  ##   Note: GitLab does not support omniauth-ldap's custom filter syntax.
  ##
  ##   Example for getting only specific users:
  ##   '(&(objectclass=user)(|(samaccountname=momo)(samaccountname=toto)))'
  ##
  user_filter: ''

  ##
  ## LDAP attributes that GitLab will use to create an account for the LDAP user.
  ## The specified attribute can either be the attribute name as a string (e.g. 'mail'),
  ## or an array of attribute names to try in order (e.g. ['mail', 'email']).
  ## Note that the user's LDAP login will always be the attribute specified as `uid` above.
  ##
  attributes:
    ##
    ## The username will be used in paths for the user's own projects
    ## (like `gitlab.example.com/username/project`) and when mentioning
    ## them in issues, merge request and comments (like `@username`).
    ## If the attribute specified for `username` contains an email address,
    ## the GitLab username will be the part of the email address before the '@'.
    ##
    username: ['uid', 'userid', 'sAMAccountName']
    email:    ['mail', 'email', 'userPrincipalName']

    ##
    ## If no full name could be found at the attribute specified for `name`,
    ## the full name is determined using the attributes specified for
    ## `first_name` and `last_name`.
    ##
    name:       'cn'
    first_name: 'givenName'
    last_name:  'sn'

  ##
  ## If lowercase_usernames is enabled, GitLab will lower case the username.
  ##
  lowercase_usernames: false

  ##
  ## EE only
  ##

  ## Base where we can search for groups
  ##
  ##   Ex. ou=groups,dc=gitlab,dc=example
  ##
  group_base: ''

  ## The CN of a group containing GitLab administrators
  ##
  ##   Ex. administrators
  ##
  ##   Note: Not `cn=administrators` or the full DN
  ##
  admin_group: ''

  ## An array of CNs of groups containing users that should be considered external
  ##
  ##   Ex. ['interns', 'contractors']
  ##
  ##   Note: Not `cn=interns` or the full DN
  ##
  external_groups: []

  ##
  ## The LDAP attribute containing a user's public SSH key
  ##
  ##   Example: sshPublicKey
  ##
  sync_ssh_keys: false

## GitLab EE only: add more LDAP servers
## Choose an ID made of a-z and 0-9 . This ID will be stored in the database
## so that GitLab can remember which LDAP server a user belongs to.
#uswest2:
#  label:
#  host:
#  ....
EOS
```

**Source configuration**

Use the same format as `gitlab_rails['ldap_servers']` for the contents under
`servers:` in the example below:

```yaml
production:
  # snip...
  ldap:
    enabled: false
    prevent_ldap_sign_in: false
    servers:
      ##
      ## 'main' is the GitLab 'provider ID' of this LDAP server
      ##
      main:
        ##
        ## A human-friendly name for your LDAP server. It is OK to change the label later,
        ## for instance if you find out it is too large to fit on the web page.
        ##
        ## Example: 'Paris' or 'Acme, Ltd.'
        label: 'LDAP'
        ## snip...
```

## Using an LDAP filter to limit access to your GitLab server

If you want to limit all GitLab access to a subset of the LDAP users on your
LDAP server, the first step should be to narrow the configured `base`. However,
it is sometimes necessary to filter users further. In this case, you can set up
an LDAP user filter. The filter must comply with
[RFC 4515](https://tools.ietf.org/search/rfc4515).

**Omnibus configuration**

```ruby
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  # snip...
  user_filter: '(employeeType=developer)'
EOS
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

Tip: If you want to limit access to the nested members of an Active Directory
group, you can use the following syntax:

```text
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

Find more information about this "LDAP_MATCHING_RULE_IN_CHAIN" filter at
<https://docs.microsoft.com/en-us/windows/win32/adsi/search-filter-syntax>. Support for
nested members in the user filter should not be confused with
[group sync nested groups support](ldap-ee.md#supported-ldap-group-typesattributes). **(STARTER ONLY)**

Please note that GitLab does not support the custom filter syntax used by
OmniAuth LDAP.

### Escaping special characters

The `user_filter` DN can contain special characters. For example:

- A comma:

  ```text
  OU=GitLab, Inc,DC=gitlab,DC=com
  ```

- Open and close brackets:

  ```text
  OU=Gitlab (Inc),DC=gitlab,DC=com
  ```

  These characters must be escaped as documented in
  [RFC 4515](https://tools.ietf.org/search/rfc4515).

- Escape commas with `\2C`. For example:

  ```text
  OU=GitLab\2C Inc,DC=gitlab,DC=com
  ```

- Escape open and close brackets with `\28` and `\29`, respectively. For example:

  ```text
  OU=Gitlab \28Inc\29,DC=gitlab,DC=com
  ```

## Enabling LDAP sign-in for existing GitLab users

When a user signs in to GitLab with LDAP for the first time, and their LDAP
email address is the primary email address of an existing GitLab user, then
the LDAP DN will be associated with the existing user. If the LDAP email
attribute is not found in GitLab's database, a new user is created.

In other words, if an existing GitLab user wants to enable LDAP sign-in for
themselves, they should check that their GitLab email address matches their
LDAP email address, and then sign into GitLab via their LDAP credentials.

## Enabling LDAP username lowercase

Some LDAP servers, depending on their configurations, can return uppercase usernames. This can lead to several confusing issues like, for example, creating links or namespaces with uppercase names.

GitLab can automatically lowercase usernames provided by the LDAP server by enabling
the configuration option `lowercase_usernames`. By default, this configuration option is `false`.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     # snip...
     lowercase_usernames: true
   EOS
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

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

1. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Disable LDAP web sign in

It can be be useful to prevent using LDAP credentials through the web UI when
an alternative such as SAML is preferred. This allows LDAP to be used for group
sync, while also allowing your SAML identity provider to handle additional
checks like custom 2FA.

When LDAP web sign in is disabled, users will not see a **LDAP** tab on the sign in page.
This does not disable [using LDAP credentials for Git access](#git-password-authentication).

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source configuration**

1. Edit `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       prevent_ldap_sign_in: true
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Encryption

### TLS Server Authentication

There are two encryption methods, `simple_tls` and `start_tls`.

For either encryption method, if setting `verify_certificates: false`, TLS
encryption is established with the LDAP server before any LDAP-protocol data is
exchanged but no validation of the LDAP server's SSL certificate is performed.

>**Note**: Before GitLab 9.5, `verify_certificates: false` is the default if
unspecified.

## Limitations

### TLS Client Authentication

Not implemented by `Net::LDAP`.
You should disable anonymous LDAP authentication and enable simple or SASL
authentication. The TLS client authentication setting in your LDAP server cannot
be mandatory and clients cannot be authenticated with the TLS protocol.

## Troubleshooting

If a user account is blocked or unblocked due to the LDAP configuration, a
message will be logged to `application.log`.

If there is an unexpected error during an LDAP lookup (configuration error,
timeout), the login is rejected and a message will be logged to
`production.log`.

### Debug LDAP user filter with ldapsearch

This example uses `ldapsearch` and assumes you are using ActiveDirectory. The
following query returns the login names of the users that will be allowed to
log in to GitLab if you configure your own user_filter.

```sh
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- Variables beginning with a `$` refer to a variable from the LDAP section of
  your configuration file.
- Replace `ldaps://` with `ldap://` if you are using the plain authentication method.
  Port `389` is the default `ldap://` port and `636` is the default `ldaps://`
  port.
- We are assuming the password for the bind_dn user is in bind_dn_password.txt.

### Invalid credentials when logging in

- Make sure the user you are binding with has enough permissions to read the user's
  tree and traverse it.
- Check that the `user_filter` is not blocking otherwise valid users.
- Run the following check command to make sure that the LDAP settings are
  correct and GitLab can see your users:

  ```bash
  # For Omnibus installations
  sudo gitlab-rake gitlab:ldap:check

  # For installations from source
  sudo -u git -H bundle exec rake gitlab:ldap:check RAILS_ENV=production
  ```

### Connection refused

If you are getting 'Connection Refused' errors when trying to connect to the
LDAP server please double-check the LDAP `port` and `encryption` settings used by
GitLab. Common combinations are `encryption: 'plain'` and `port: 389`, OR
`encryption: 'simple_tls'` and `port: 636`.

### Connection times out

If GitLab cannot reach your LDAP endpoint, you will see a message like this:

```
Could not authenticate you from Ldapmain because "Connection timed out - user specified timeout".
```

If your configured LDAP provider and/or endpoint is offline or otherwise unreachable by GitLab, no LDAP user will be able to authenticate and log in. GitLab does not cache or store credentials for LDAP users to provide authentication during an LDAP outage.

Contact your LDAP provider or administrator if you are seeing this error.
