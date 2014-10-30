# Import bare repositories into your GitLab instance

### Notes:

- The owner of the project will be the first admin
- The groups will be created as needed
- The owner of the group will be the first admin
- Existing projects will be skipped

## How to use:

### Create a new folder inside the git repositories path. This will be the name of the new group.

- For omnibus-gitlab, it is located at: `/var/opt/gitlab/git-data/repositories`
- For manual installations, it is usually located at: `/home/git/repositories` or you can see where
your repositories are located by looking at `config/gitlab.yml`:

```yaml
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

### Copy your bare repositories inside this newly created folder:

```
$ cp -r /old/git/foo.git/ /home/git/repositories/new_group/
```

### Run the commands below depending on your type of installation:

#### Omnibus Installation

```
$ sudo gitlab-rake gitlab:import:repos
```
```
$ sudo gitlab-rake gitlab:satellites:create
```

#### Manual Installation

Before running these commands you need to change the directory to where your GitLab installation is located:

```
$ cd /home/git/gitlab
$ sudo -u git -H bundle exec rake gitlab:import:repos RAILS_ENV=production
```
```
$ sudo -u git -H bundle exec rake gitlab:satellites:create
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
