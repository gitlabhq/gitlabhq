# Cleanup

## Remove garbage from filesystem

You will be given a chance after running each command to view the changes that will be made and decide if you would like to proceed with the cleanup.

Remove namespaces(dirs) from `/home/git/repositories` if they don't exist in GitLab database.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:dirs

# installation from source or cookbook
sudo -u git -H bundle exec rake gitlab:cleanup:dirs RAILS_ENV=production
```

Remove repositories (global only for now) from `/home/git/repositories` if they don't exist in GitLab database.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:repos

# installation from source or cookbook
sudo -u git -H bundle exec rake gitlab:cleanup:repos RAILS_ENV=production
```

Block removed LDAP users.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:black_removed_ldap_users

# installation from source or cookbook
sudo -u git -H bundle exec rake gitlab:cleanup:black_removed_ldap_users RAILS_ENV=production
```
