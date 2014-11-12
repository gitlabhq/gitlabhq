# Import bare repositories into your GitLab instance

## Notes

- The owner of the project will be the first admin
- The groups will be created as needed
- The owner of the group will be the first admin
- Existing projects will be skipped

## How to use

### Create a new folder inside the git repositories path. This will be the name of the new group.

- For omnibus-gitlab, it is located at: `/var/opt/gitlab/git-data/repositories` by default, unless you changed
it in the `/etc/gitlab/gitlab.rb` file.
- For manual installations, it is usually located at: `/home/git/repositories` or you can see where
your repositories are located by looking at `config/gitlab.yml` under the `gitlab_shell => repos_path` entry.

### Copy your bare repositories inside this newly created folder:

```
$ cp -r /old/git/foo.git/ /home/git/repositories/new_group/
```

### Run the command below depending on your type of installation:

#### Omnibus Installation

```
$ sudo gitlab-rake gitlab:import:repos
```

#### Manual Installation

Before running this command you need to change the directory to where your GitLab installation is located:

```
$ cd /home/git/gitlab
$ sudo -u git -H bundle exec rake gitlab:import:repos RAILS_ENV=production
```

#### Example output

```
Processing abcd.git
 * Created abcd (abcd.git)
Processing group/xyz.git
 * Created Group group (2)
 * Created xyz (group/xyz.git)
[...]
```
