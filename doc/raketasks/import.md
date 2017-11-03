# Import bare repositories into your GitLab instance

## Notes

- The owner of the project will be the first admin
- The groups will be created as needed, including subroups
- The owner of the group will be the first admin
- Existing projects will be skipped

## How to use

### Create a new folder to import your Git repositories from.

The new folder needs to have git user ownership and read/write/execute access for git user and its group:

```
sudo -u git mkdir /tmp/git_repos/new_group
```

### Copy your bare repositories inside this newly created folder:

- Any .git repositories found on any of the subfolders will be imported as projects
- Groups will be created as needed, these could be nested folders. Example:

If we copy the repos to `/tmp/git_repos`, and repo A needs to be under the groups G1 and G2, it will
have to be created under those folders: `/tmp/git_repos/G1/G2/A.git`.


```
sudo cp -r /old/git/foo.git /tmp/git_repos/new_group/

# Do this once when you are done copying git repositories
sudo chown -R git:git /tmp/git_repos
```

`foo.git` needs to be owned by the git user and git users group.

### Run the command below depending on your type of installation:

#### Omnibus Installation

```
$ sudo gitlab-rake gitlab:import:repos['/tmp/git_repos']
```

#### Installation from source

Before running this command you need to change the directory to where your GitLab installation is located:

```
$ cd /home/git/gitlab
$ sudo -u git -H bundle exec rake gitlab:import:repos['/tmp/git_repos'] RAILS_ENV=production
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
