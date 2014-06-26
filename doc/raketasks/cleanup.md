# Cleanup

## Remove garbage from filesystem. Important! Data loss!

Remove namespaces(dirs) from `/home/git/repositories` if they don't exist in GitLab database.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:dirs

# installation from source or cookbook
bundle exec rake gitlab:cleanup:dirs RAILS_ENV=production
```

Remove repositories (global only for now) from `/home/git/repositories` if they don't exist in GitLab database.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:repos

# installation from source or cookbook
bundle exec rake gitlab:cleanup:repos RAILS_ENV=production
```
