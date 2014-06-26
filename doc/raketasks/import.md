# Import

### Import bare repositories into GitLab project instance

Notes:

* project owner will be a first admin
* groups will be created as needed
* group owner will be the first admin
* existing projects will be skipped

How to use:

1. copy your bare repos under git repos_path (see `config/gitlab.yml` gitlab_shell -> repos_path)
2. run the command below

```
# omnibus-gitlab
sudo gitlab-rake gitlab:import:repos

# installation from source or cookbook
bundle exec rake gitlab:import:repos RAILS_ENV=production
```

Example output:

```
Processing abcd.git
 * Created abcd (abcd.git)
Processing group/xyz.git
 * Created Group group (2)
 * Created xyz (group/xyz.git)
[...]
```
