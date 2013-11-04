### Add user as a developer to all projects

```
bundle exec rake gitlab:import:user_to_projects[username@domain.tld]
```


### Add all users to all projects

Notes:

* admin users are added as masters

```
sudo -u git -H bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```
