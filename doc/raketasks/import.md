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
- For installations from source, it is usually located at: `/home/git/repositories` or you can see where
your repositories are located by looking at `config/gitlab.yml` under the `repositories => storages` entries
(you'll usually use the `default` storage path to start).

New folder needs to have git user ownership and read/write/execute access for git user and its group:

```
sudo -u git mkdir /var/opt/gitlab/git-data/repositories/new_group
```

If you are using an installation from source, replace `/var/opt/gitlab/git-data`
with `/home/git`.

### Copy your bare repositories inside this newly created folder:

```
sudo cp -r /old/git/foo.git /var/opt/gitlab/git-data/repositories/new_group/

# Do this once when you are done copying git repositories
sudo chown -R git:git /var/opt/gitlab/git-data/repositories/new_group/
```

`foo.git` needs to be owned by the git user and git users group.

If you are using an installation from source, replace `/var/opt/gitlab/git-data`
with `/home/git`.

### Run the command below depending on your type of installation:

#### Omnibus Installation

```
$ sudo gitlab-rake gitlab:import:repos
```

#### Installation from source

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
