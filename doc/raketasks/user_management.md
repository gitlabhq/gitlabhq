# User management

## Add user as a developer to all projects

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_projects[username@domain.tld] RAILS_ENV=production
```

## Add all users to all projects

Notes:

- admin users are added as masters

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source
bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```

## Add user as a developer to all groups

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_groups[username@domain.tld] RAILS_ENV=production
```

## Add all users to all groups

Notes:

- admin users are added as owners so they can add additional users to the group

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source
bundle exec rake gitlab:import:all_users_to_all_groups RAILS_ENV=production
```

## Maintain tight control over the number of active users on your GitLab installation

- Enable this setting to keep new users blocked until they have been cleared by the admin 

```bash
(default: false).
block_auto_created_users: false

Base where we can search for users

Ex. ou=People,dc=gitlab,dc=example

base: ''

Filter LDAP users

Format: RFC 4515 http://tools.ietf.org/search/rfc4515
Ex. (employeeType=developer)

Note: GitLab does not support omniauth-ldap's custom filter syntax.

user_filter: ''
```

- GitLab EE only: add more LDAP servers

```bash
Choose an ID made of a-z and 0-9 . This ID will be stored in the database
so that GitLab can remember which LDAP server a user belongs to.
uswest2:
label:
host:
....
```