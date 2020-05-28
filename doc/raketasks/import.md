# Import bare repositories **(CORE ONLY)**

Rake tasks are available to import bare repositories into a GitLab instance.

Note that:

- The owner of the project will be the first administrator.
- The groups will be created as needed, including subgroups.
- The owner of the group will be the first administrator.
- Existing projects will be skipped.
- Projects in hashed storage may be skipped. For more information, see
  [Importing bare repositories from hashed storage](#importing-bare-repositories-from-hashed-storage).
- The existing Git repositories will be moved from disk (removed from the original path).

To import bare repositories into a GitLab instance:

1. Create a new folder to import your Git repositories from. The new folder needs to have Git user
   ownership and read/write/execute access for Git user and its group:

   ```shell
   sudo -u git mkdir -p /var/opt/gitlab/git-data/repository-import-<date>/new_group
   ```

1. Copy your bare repositories inside this newly created folder. Note:

   - Any `.git` repositories found on any of the subfolders will be imported as projects.
   - Groups will be created as needed, these could be nested folders.

   For example, if we copy the repositories to `/var/opt/gitlab/git-data/repository-import-<date>`,
   and repository `A` needs to be under the groups `G1` and `G2`, it must be created under those folders:
   `/var/opt/gitlab/git-data/repository-import-<date>/G1/G2/A.git`.

   ```shell
   sudo cp -r /old/git/foo.git /var/opt/gitlab/git-data/repository-import-<date>/new_group/

   # Do this once when you are done copying git repositories
   sudo chown -R git:git /var/opt/gitlab/git-data/repository-import-<date>
   ```

   `foo.git` needs to be owned by the `git` user and `git` users group.

   If you are using an installation from source, replace `/var/opt/gitlab/` with `/home/git`.

1. Run the following command depending on your type of installation:

   - Omnibus Installation

   ```shell
   sudo gitlab-rake gitlab:import:repos['/var/opt/gitlab/git-data/repository-import-<date>']
   ```

   - Installation from source. Before running this command you need to change to the directory where
     your GitLab installation is located:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:import:repos['/var/opt/gitlab/git-data/repository-import-<date>'] RAILS_ENV=production
   ```

## Example output

```plaintext
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

## Importing bare repositories from hashed storage

Projects in legacy storage have a directory structure that mirrors their full
project path in GitLab, including their namespace structure. This information is
leveraged by the bare repository importer to import projects into their proper
locations. Each project and its parent namespaces are meaningfully named.

However, the directory structure of projects in hashed storage do not contain
this information. This is beneficial for a variety of reasons, especially
improved performance and data integrity. See
[Repository Storage Types](../administration/repository_storage_types.md) for
more details.

The repositories that are importable depends on the version of GitLab.

### GitLab 10.3 or earlier

Importing bare repositories from hashed storage is unsupported.

### GitLab 10.4 and later

To support importing bare repositories from hashed storage, GitLab 10.4 and
later stores the full project path with each repository, in a special section of
the Git repository's configuration file. This section is formatted as follows:

```ini
[gitlab]
  fullpath = gitlab-org/gitlab
```

However, existing repositories were not migrated to include this path.

Bare repositories are importable if the following events occurred to the
repository in GitLab 10.4 and later:

- Created
- Migrated to hashed storage
- Renamed
- Transferred to another namespace
- Ancestor renamed
- Ancestor transferred to another namespace

Bare repositories are **not** importable by GitLab 10.4 to GitLab 11.6, if all the following are true about the repository:

- It was created in GitLab 10.3 or earlier.
- It was not renamed, transferred, or migrated to [hashed storage](../administration/repository_storage_types.md#hashed-storage) in GitLab 10.4 to GitLab 11.6.
- Its ancestor namespaces were not renamed or transferred in GitLab 10.4 to GitLab 11.6.

[Since GitLab 11.6](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41776), all
bare repositories are importable.

To manually migrate repositories yourself (for GitLab 10.4 to GitLab 11.6), you can use the
[Rails console](../administration/troubleshooting/debug.md#starting-a-rails-console-session)
to do so. In a Rails console session, run the following to migrate a project:

```ruby
project = Project.find_by_full_path('gitlab-org/gitlab')
project.write_repository_config
```

In a Rails console session, run the following to migrate all of a namespace's
projects (this may take a while if there are 1000s of projects in a namespace):

```ruby
namespace = Namespace.find_by_full_path('gitlab-org')
namespace.send(:write_projects_repository_config)
```
