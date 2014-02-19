### Add user as a developer to all projects

```bash
bundle exec rake gitlab:import:user_to_projects[username@domain.tld]
```


### Add all users to all projects

Notes:

* admin users are added as masters

```bash
bundle exec rake gitlab:import:all_users_to_all_projects
```

### Add user as a developer to all projects

```
bundle exec rake gitlab:import:user_to_groups[username@domain.tld]
```

### Add all users to all groups

Notes:

* admin users are added as owners so they can add additional users to the group

```
bundle exec rake gitlab:import:all_users_to_all_groups
```
