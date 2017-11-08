# Import bare repositories into your GitLab instance

## Notes

- The owner of the project will be the first admin
- The groups will be created as needed, including subgroups
- The owner of the group will be the first admin
- Existing projects will be skipped
- The existing Git repos will be moved from disk (removed from the original path)

## How to use

### Create a new folder to import your Git repositories from.

The new folder needs to have git user ownership and read/write/execute access for git user and its group:

```
sudo -u git mkdir /var/opt/gitlab/git-data/repository-import-<date>/new_group
```

### Copy your bare repositories inside this newly created folder:

- Any .git repositories found on any of the subfolders will be imported as projects
- Groups will be created as needed, these could be nested folders. Example:

If we copy the repos to `/var/opt/gitlab/git-data/repository-import-<date>`, and repo A needs to be under the groups G1 and G2, it will
have to be created under those folders: `/var/opt/gitlab/git-data/repository-import-<date>/G1/G2/A.git`.


```
sudo cp -r /old/git/foo.git /var/opt/gitlab/git-data/repository-import-<date>/new_group/

# Do this once when you are done copying git repositories
sudo chown -R git:git /var/opt/gitlab/git-data/repository-import-<date>
```

`foo.git` needs to be owned by the git user and git users group.

If you are using an installation from source, replace `/var/opt/gitlab/` with `/home/git`.

### Run the command below depending on your type of installation:

#### Omnibus Installation

```
$ sudo gitlab-rake gitlab:import:repos['/var/opt/gitlab/git-data/repository-import-<date>']
```

#### Installation from source

Before running this command you need to change the directory to where your GitLab installation is located:

```
$ cd /home/git/gitlab
$ sudo -u git -H bundle exec rake gitlab:import:repos['/var/opt/gitlab/git-data/repository-import-<date>'] RAILS_ENV=production
```

#### Example output

```
Processing /var/opt/gitlab/git-data/repository-import-1/a/b/c/blah.git
 * Using namespace: a/b/c
 * Created blah (a/b/c/blah)
 * Skipping repo  /var/opt/gitlab/git-data/repository-import-1/a/b/c/blah.wiki.git
Processing /var/opt/gitlab/git-data/repository-import-1/abcd.git
 * Created abcd (abcd.git)
Processing /var/opt/gitlab/git-data/repository-import-1/group/xyz.git
 * Using namespace: group (2)
 * Created xyz (group/xyz.git)
 * Skipping repo /var/opt/gitlab/git-data/repository-import-1/@shared/a/b/abcd.git
[...]
```
