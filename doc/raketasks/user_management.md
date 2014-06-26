# User management

## Add user as a developer to all projects

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source or cookbook
bundle exec rake gitlab:import:user_to_projects[username@domain.tld]
```

## Add all users to all projects

Notes:

- admin users are added as masters

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source or cookbook
bundle exec rake gitlab:import:all_users_to_all_projects
```

## Add user as a developer to all groups

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source or cookbook
bundle exec rake gitlab:import:user_to_groups[username@domain.tld]
```

## Add all users to all groups

Notes:

- admin users are added as owners so they can add additional users to the group

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source or cookbook
bundle exec rake gitlab:import:all_users_to_all_groups
```
