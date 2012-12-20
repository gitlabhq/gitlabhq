### Add user to as a developer to all projects

```
bundle exec rake gitlab:import:user_to_projects[username@domain.tld]
```


### Add all users to all projects

Notes:

* admin users are added as masters

```
bundle exec rake gitlab:import:all_users_to_all_projects
```
