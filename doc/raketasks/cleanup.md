### Remove grabage from filesystem. Important! Data loss!

Remove namespaces(dirs) from /home/git/repositories if they dont exist in GitLab database

```
bundle exec rake gitlab:cleanup:dirs RAILS_ENV=production
```

Remove repositories (global only for now) from /home/git/repositories if they dont exist in GitLab database

```
bundle exec rake gitlab:cleanup:repos RAILS_ENV=production
```

