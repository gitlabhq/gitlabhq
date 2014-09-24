# GitLab LDAP integration

GitLab can be configured to allow your users to sign with their LDAP credentials to integrate with e.g. Active Directory.

The first time a user signs in with LDAP credentials, GitLab will create a new GitLab user associated with the LDAP Distinguished Name (DN) of the LDAP user.

GitLab user attributes such as nickname and email will be copied from the LDAP user entry.

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
# For omnibus-gitlab
gitlab_rails['ldap_user_filter'] = '(employeeType=developer)'
```

```yaml
# For installations from source
production:
  ldap:
     user_filter: '(employeeType=developer)'
```

Tip: if you want to limit access to the nested members of an Active Directory group you can use the following syntax:

```
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

Please note that GitLab does not support the custom filter syntax used by omniauth-ldap.
