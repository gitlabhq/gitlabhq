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
