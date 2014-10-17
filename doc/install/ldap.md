# Link LDAP Groups
You can link LDAP groups with GitLab groups.
It gives you ability to automatically add/remove users from GitLab groups based on LDAP groups membership.

How it works: 
1. We retrieve user ldap groups
2. We find corresponding GitLab groups
3. We add user to GitLab groups
4. We remove user from GitLab groups if user has no membership in LDAP groups

In order to use LDAP groups feature:

1. Edit gitlab.yml config LDAP sections.
2. Visti group settings -> LDAP tab
3. Edit LDAP cn and access level for gitlab group
4. Setup LDAP group members


Example of LDAP section from gitlab.yml

```
  #
  # 2. Auth settings
  # ==========================

  ## LDAP settings
  ldap:
    enabled: true
    host: 'localhost'
    base: 'ou=People,dc=gitlab,dc=local'
    group_base: 'ou=Groups,dc=gitlab,dc=local'
    port: 389
    uid: 'uid'
```


# Test whether LDAP group functionality is configured correctly

You need a non-LDAP admin user (such as the default admin@local.host), an LDAP user (e.g. Mary) and an LDAP group to which Mary belongs (e.g. Developers).

1. As the admin, create a new group 'Developers' in GitLab and associate it with the Developers LDAP group at gitlab.example.com/admin/groups/developers/edit .
2. Log in as Mary.
3. Verify that Mary is now a member of the Developers group in GitLab.

If you get an error message when logging in as Mary, double-check your `group_base` setting in `config/gitlab.yml`. 


# Debug LDAP user filter with ldapsearch

This example uses [ldapsearch](http://www.openldap.org/software/man.cgi?query=ldapsearch&apropos=0&sektion=0&manpath=OpenLDAP+2.0-Release&format=html) and assumes you are using ActiveDirectory.

The following query returns the login names of the users that will be allowed to log in to GitLab if you configure your own `user_filter`.

```bash
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "(&(ObjectClass=User)($user_filter))" sAMAccountName
```

- `$var` refers to a variable from the `ldap` section of your `config/gitlab.yml` https://gitlab.com/subscribers/gitlab-ee/blob/master/config/gitlab.yml.example#L100;
- Replace `ldaps://` with `ldap://` if you are using the `plain` authentication method;
- We are assuming the password for the `bind_dn` user is in `bind_dn_password.txt`.
