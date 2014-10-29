# Import

## Import bare repositories into GitLab project instance

Notes:

- project owner will be a first admin
- groups will be created as needed
- group owner will be the first admin
- existing projects will be skipped

How to use:

1. Create a new folder inside the git repositories path.

- For omnibus-gitlab it is located at: `/var/opt/gitlab/git-data/repositories`
- For manual installations it is usually located at: `/home/git/repositories` or you can see where
your repositories are located by looking at `config/gitlab.yml`:

```
# 3. Advanced settings
# ==========================

# GitLab Satellites
# satellites:
# Relative paths are relative to Rails.root (default: tmp/repo_satellites/)
# path: /home/git/gitlab-satellites/
# timeout: 30

satellites:
  path: /home/git/gitlab-satellites/
gitlab_shell:
  path: /home/git/gitlab-shell/
  repos_path: /home/git/repositories/
  hooks_path: /home/git/gitlab-shell/hooks/
  upload_pack: true
  receive_pack: true

```

2. Copy your bare repositories inside this newly created folder, e.g.:

```
$ cp /old/git/foo.git /home/git/repositories/new_group/foo.git
```

3. Run the command below depending on you type of installation:

#### Omnibus Installation

```
$ sudo gitlab-rake gitlab:import:repos
```

#### Manual Installation

```
$ cd /home/git/gitlab
$ sudo -u git -H bundle exec rake gitlab:import:repos RAILS_ENV=production
```

#### Example output:

```
Processing abcd.git
 * Created abcd (abcd.git)
Processing group/xyz.git
 * Created Group group (2)
 * Created xyz (group/xyz.git)
[...]
```
