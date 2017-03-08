# Cleanup

## Remove garbage from filesystem. Important! Data loss!

Remove namespaces(dirs) from all repository storage paths if they don't exist in GitLab database.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:dirs

# installation from source
bundle exec rake gitlab:cleanup:dirs RAILS_ENV=production
```

Rename repositories from all repository storage paths if they don't exist in GitLab database.
The repositories get a `+orphaned+TIMESTAMP` suffix so that they cannot block new repositories from being created.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:repos

# installation from source
bundle exec rake gitlab:cleanup:repos RAILS_ENV=production
```

Remove old repository copies from repositories moved to another storage.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:moved

# installation from source
bundle exec rake gitlab:cleanup:moved RAILS_ENV=production
```
