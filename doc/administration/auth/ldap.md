# LDAP

GitLab integrates with LDAP to support user authentication.
This integration works with most LDAP-compliant directory
servers, including Microsoft Active Directory, Apple Open Directory, Open LDAP,
and 389 Server. GitLab EE includes enhanced integration, including group
membership syncing.

## Security

GitLab assumes that LDAP users are not able to change their LDAP 'mail', 'email'
or 'userPrincipalName' attribute. An LDAP user who is allowed to change their
email on the LDAP server can potentially
[take over any account](#enabling-ldap-sign-in-for-existing-gitlab-users)
on your GitLab server.

We recommend against using LDAP integration if your LDAP users are
allowed to change their 'mail', 'email' or 'userPrincipalName'  attribute on
the LDAP server.

### User deletion

If a user is deleted from the LDAP server, they will be blocked in GitLab, as
well. Users will be immediately blocked from logging in. However, there is an
LDAP check cache time (sync time) of one hour (see note). This means users that
are already logged in or are using Git over SSH will still be able to access
GitLab for up to one hour. Manually block the user in the GitLab Admin area to
immediately block all access.

>**Note**: GitLab EE supports a configurable sync time, with a default
of one hour.

## Git password authentication

LDAP-enabled users can always authenticate with Git using their GitLab username
or email and LDAP password, even if password authentication for Git is disabled
in the application settings.

## Configuration

For a complete guide on configuring LDAP with GitLab Community Edition, please check
the admin guide [How to configure LDAP with GitLab CE](how_to_configure_ldap_gitlab_ce/index.md).

To enable LDAP integration you need to add your LDAP server settings in
`/etc/gitlab/gitlab.rb` or `/home/git/gitlab/config/gitlab.yml`.

There is a Rake task to check LDAP configuration. After configuring LDAP
using the documentation below, see [LDAP check Rake task](../raketasks/check.md#ldap-check)
for information on the LDAP check Rake task.

>**Note**: In GitLab EE, you can configure multiple LDAP servers to connect to
one GitLab server.

Prior to version 7.4, GitLab used a different syntax for configuring
LDAP integration. The old LDAP integration syntax still works but may be
removed in a future version. If your `gitlab.rb` or `gitlab.yml` file contains
LDAP settings in both the old syntax and the new syntax, only the __old__
syntax will be used by GitLab.

The configuration inside `gitlab_rails['ldap_servers']` below is sensitive to
incorrect indentation. Be sure to retain the indentation given in the example.
Copy/paste can sometimes cause problems.

**Omnibus configuration**

```ruby
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = YAML.load <<-EOS # remember to close this block with 'EOS' below
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  ## label
  #
  # A human-friendly name for your LDAP server. It is OK to change the label later,
  # for instance if you find out it is too large to fit on the web page.
  #
  # Example: 'Paris' or 'Acme, Ltd.'
  label: 'LDAP'

  # Example: 'ldap.mydomain.com'
  host: '_your_ldap_server'
  # This port is an example, it is sometimes different but it is always an integer and not a string
  port: 389 # usually 636 for SSL
  uid: 'sAMAccountName' # This should be the attribute, not the value that maps to uid.

  # Examples: 'america\\momo' or 'CN=Gitlab Git,CN=Users,DC=mydomain,DC=com'
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'

  # Encryption method. The "method" key is deprecated in favor of
  # "encryption".
  #
  #   Examples: "start_tls" or "simple_tls" or "plain"
  #
  #   Deprecated values: "tls" was replaced with "start_tls" and "ssl" was
  #   replaced with "simple_tls".
  #
  encryption: 'plain'

  # Enables SSL certificate verification if encryption method is
  # "start_tls" or "simple_tls". Defaults to true since GitLab 10.0 for
  # security. This may break installations upon upgrade to 10.0, that did
  # not know their LDAP SSL certificates were not setup properly. For
  # example, when using self-signed certificates, the ca_file path may
  # need to be specified.
  verify_certificates: true

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

  # Set a timeout, in seconds, for LDAP queries. This helps avoid blocking
  # a request if the LDAP server becomes unresponsive.
  # A value of 0 means there is no timeout.
  timeout: 10

  # This setting specifies if LDAP server is Active Directory LDAP server.
  # For non AD servers it skips the AD specific queries.
  # If your LDAP server is not AD, set this to false.
  active_directory: true

  # If allow_username_or_email_login is enabled, GitLab will ignore everything
  # after the first '@' in the LDAP username submitted by the user on login.
  #
  # Example:
  # - the user enters 'jane.doe@example.com' and 'p@ssw0rd' as LDAP credentials;
  # - GitLab queries the LDAP server with 'jane.doe' and 'p@ssw0rd'.
  #
  # If you are using "uid: 'userPrincipalName'" on ActiveDirectory you need to
  # disable this setting, because the userPrincipalName contains an '@'.
  allow_username_or_email_login: false

  # To maintain tight control over the number of active users on your GitLab installation,
  # enable this setting to keep new users blocked until they have been cleared by the admin
  # (default: false).
  block_auto_created_users: false

  # Base where we can search for users
  #
  #   Ex. 'ou=People,dc=gitlab,dc=example' or 'DC=mydomain,DC=com'
  #
  base: ''

  # Filter LDAP users
  #
  #   Format: RFC 4515 https://tools.ietf.org/search/rfc4515
  #   Ex. (employeeType=developer)
  #
  #   Note: GitLab does not support omniauth-ldap's custom filter syntax.
  #
  #   Example for getting only specific users:
  #   '(&(objectclass=user)(|(samaccountname=momo)(samaccountname=toto)))'
  #
  user_filter: ''

  # LDAP attributes that GitLab will use to create an account for the LDAP user.
  # The specified attribute can either be the attribute name as a string (e.g. 'mail'),
  # or an array of attribute names to try in order (e.g. ['mail', 'email']).
  # Note that the user's LDAP login will always be the attribute specified as `uid` above.
  attributes:
    # The username will be used in paths for the user's own projects
    # (like `gitlab.example.com/username/project`) and when mentioning
    # them in issues, merge request and comments (like `@username`).
    # If the attribute specified for `username` contains an email address,
    # the GitLab username will be the part of the email address before the '@'.
    username: ['uid', 'userid', 'sAMAccountName']
    email:    ['mail', 'email', 'userPrincipalName']

    # If no full name could be found at the attribute specified for `name`,
    # the full name is determined using the attributes specified for
    # `first_name` and `last_name`.
    name:       'cn'
    first_name: 'givenName'
    last_name:  'sn'

  # If lowercase_usernames is enabled, GitLab will lower case the username.
  lowercase_usernames: false


  ## EE only

  # Base where we can search for groups
  #
  #   Ex. ou=groups,dc=gitlab,dc=example
  #
  group_base: ''

  # The CN of a group containing GitLab administrators
  #
  #   Ex. administrators
  #
  #   Note: Not `cn=administrators` or the full DN
  #
  admin_group: ''

  # The LDAP attribute containing a user's public SSH key
  #
  #   Ex. ssh_public_key
  #
  sync_ssh_keys: false

# GitLab EE only: add more LDAP servers
# Choose an ID made of a-z and 0-9 . This ID will be stored in the database
# so that GitLab can remember which LDAP server a user belongs to.
# uswest2:
#   label:
#   host:
#   ....
EOS
```

**Source configuration**

Use the same format as `gitlab_rails['ldap_servers']` for the contents under
`servers:` in the example below:

```
production:
  # snip...
  ldap:
    enabled: false
    servers:
      main: # 'main' is the GitLab 'provider ID' of this LDAP server
        ## label
        #
        # A human-friendly name for your LDAP server. It is OK to change the label later,
        # for instance if you find out it is too large to fit on the web page.
        #
        # Example: 'Paris' or 'Acme, Ltd.'
        label: 'LDAP'
        # snip...
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

```
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

Find more information about this "LDAP_MATCHING_RULE_IN_CHAIN" filter at
https://msdn.microsoft.com/en-us/library/aa746475(v=vs.85).aspx. Support for
nested members in the user filter should not be confused with
[group sync nested groups support (EE only)](https://docs.gitlab.com/ee/administration/auth/ldap-ee.html#supported-ldap-group-types-attributes).

Please note that GitLab does not support the custom filter syntax used by
omniauth-ldap.

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

2. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

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
2. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

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

### Debug LDAP user filter with ldapsearch

This example uses ldapsearch and assumes you are using ActiveDirectory. The
following query returns the login names of the users that will be allowed to
log in to GitLab if you configure your own user_filter.

```
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- Variables beginning with a `$` refer to a variable from the LDAP section of
  your configuration file.
- Replace ldaps:// with ldap:// if you are using the plain authentication method.
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

### Connection Refused

If you are getting 'Connection Refused' errors when trying to connect to the
LDAP server please double-check the LDAP `port` and `encryption` settings used by
GitLab. Common combinations are `encryption: 'plain'` and `port: 389`, OR
`encryption: 'simple_tls'` and `port: 636`.

### Troubleshooting

If a user account is blocked or unblocked due to the LDAP configuration, a
message will be logged to `application.log`.

If there is an unexpected error during an LDAP lookup (configuration error,
timeout), the login is rejected and a message will be logged to
`production.log`.
