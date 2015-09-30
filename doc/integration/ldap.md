# GitLab LDAP integration

GitLab can be configured to allow your users to sign with their LDAP credentials to integrate with e.g. Active Directory.

The first time a user signs in with LDAP credentials, GitLab will create a new GitLab user associated with the LDAP Distinguished Name (DN) of the LDAP user.

GitLab user attributes such as nickname and email will be copied from the LDAP user entry.

## Security

GitLab assumes that LDAP users are not able to change their LDAP 'mail', 'email' or 'userPrincipalName' attribute.
An LDAP user who is allowed to change their email on the LDAP server can [take over any account](#enabling-ldap-sign-in-for-existing-gitlab-users) on your GitLab server.

We recommend against using GitLab LDAP integration if your LDAP users are allowed to change their 'mail', 'email' or 'userPrincipalName'  attribute on the LDAP server.

## Configuring GitLab for LDAP integration

To enable GitLab LDAP integration you need to add your LDAP server settings in `/etc/gitlab/gitlab.rb` or `/home/git/gitlab/config/gitlab.yml`.
In GitLab Enterprise Edition you can have multiple LDAP servers connected to one GitLab server.

Please note that before version 7.4, GitLab used a different syntax for configuring LDAP integration.
The old LDAP integration syntax still works in GitLab 7.4.
If your `gitlab.rb` or `gitlab.yml` file contains LDAP settings in both the old syntax and the new syntax, only the __old__ syntax will be used by GitLab.

```ruby
# For omnibus packages
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

  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  method: 'plain' # "tls" or "ssl" or "plain"
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'

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
  #   Ex. ou=People,dc=gitlab,dc=example
  #
  base: ''

  # Filter LDAP users
  #
  #   Format: RFC 4515 http://tools.ietf.org/search/rfc4515
  #   Ex. (employeeType=developer)
  #
  #   Note: GitLab does not support omniauth-ldap's custom filter syntax.
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

# GitLab EE only: add more LDAP servers
# Choose an ID made of a-z and 0-9 . This ID will be stored in the database
# so that GitLab can remember which LDAP server a user belongs to.
# uswest2:
#   label:
#   host:
#   ....
EOS
```

If you are getting 'Connection Refused' errors when trying to connect to the LDAP server please double-check the LDAP `port` and `method` settings used by GitLab.
Common combinations are `method: 'plain'` and `port: 389`, OR `method: 'ssl'` and `port: 636`.

If you are using a GitLab installation from source you can find the LDAP settings in `/home/git/gitlab/config/gitlab.yml`:

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

## Enabling LDAP sign-in for existing GitLab users

When a user signs in to GitLab with LDAP for the first time, and their LDAP email address is the primary email address of an existing GitLab user, then the LDAP DN will be associated with the existing user.

If the LDAP email attribute is not found in GitLab's database, a new user is created.

In other words, if an existing GitLab user wants to enable LDAP sign-in for themselves, they should check that their GitLab email address matches their LDAP email address, and then sign into GitLab via their LDAP credentials.

GitLab recognizes the following LDAP attributes as email addresses: `mail`, `email` and `userPrincipalName`.

If multiple LDAP email attributes are present, e.g. `mail: foo@bar.com` and `email: foo@example.com`, then the first attribute found wins -- in this case `foo@bar.com`.

## Using an LDAP filter to limit access to your GitLab server

If you want to limit all GitLab access to a subset of the LDAP users on your LDAP server you can set up an LDAP user filter.
The filter must comply with [RFC 4515](http://tools.ietf.org/search/rfc4515).

```ruby
# For omnibus packages; new LDAP server syntax
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  # snip...
  user_filter: '(employeeType=developer)'
EOS
```

```yaml
# For installations from source; new LDAP server syntax
production:
  ldap:
    servers:
      main:
        # snip...
        user_filter: '(employeeType=developer)'
```

Tip: if you want to limit access to the nested members of an Active Directory group you can use the following syntax:

```
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

Please note that GitLab does not support the custom filter syntax used by omniauth-ldap.

## Limitations

GitLab's LDAP client is based on [omniauth-ldap](https://gitlab.com/gitlab-org/omniauth-ldap)
which encapsulates Ruby's `Net::LDAP` class. It provides a pure-Ruby implementation
of the LDAP client protocol. As a result, GitLab is limited by `omniauth-ldap` and may impact your LDAP 
server settings.

### TLS Client Authentication  
Not implemented by `Net::LDAP`.  
So you should disable anonymous LDAP authentication and enable simple or SASL 
authentication. TLS client authentication setting in your LDAP server cannot be
mandatory and clients cannot be authenticated with the TLS protocol. 

### TLS Server Authentication  
Not supported by GitLab's configuration options.  
When setting `method: ssl`, the underlying authentication method used by 
`omniauth-ldap` is `simple_tls`.  This method establishes TLS encryption with 
the LDAP server before any LDAP-protocol data is exchanged but no validation of
the LDAP server's SSL certificate is performed.