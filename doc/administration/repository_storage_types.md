---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Repository storage types **(FREE SELF)**

GitLab can be configured to use one or multiple repository storages. These storages can be:

- Accessed via [Gitaly](gitaly/index.md), optionally on
  [its own server](gitaly/configure_gitaly.md#run-gitaly-on-its-own-server).
- Mounted to the local disk. This [method](repository_storage_paths.md#configure-repository-storage-paths)
  is deprecated and [scheduled to be removed](https://gitlab.com/groups/gitlab-org/-/epics/2320) in
  GitLab 14.0.
- Exposed as an NFS shared volume. This method is deprecated and
  [scheduled to be removed](https://gitlab.com/groups/gitlab-org/-/epics/3371) in GitLab 14.0.

In GitLab:

- Repository storages are configured in:
  - `/etc/gitlab/gitlab.rb` by the `git_data_dirs({})` configuration hash for Omnibus GitLab
    installations.
  - `gitlab.yml` by the `repositories.storages` key for installations from source.
- The `default` repository storage is available in any installations that haven't customized it. By
  default, it points to a Gitaly node.

The repository storage types documented here apply to any repository storage defined in
`git_data_dirs({})` or `repositories.storages`.

## Hashed storage

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28283) in GitLab 10.0.
> - Made the default for new installations in GitLab 12.0.
> - Enabled by default for new and renamed projects in GitLab 13.0.

Hashed storage stores projects on disk in a location based on a hash of the project's ID. Hashed
storage is different to [legacy storage](#legacy-storage) where a project is stored based on:

- The project's URL.
- The folder structure where the repository is stored on disk.

This makes the folder structure immutable and eliminates the need to synchronize state from URLs to
disk structure. This means that renaming a group, user, or project:

- Costs only the database transaction.
- Takes effect immediately.

The hash also helps spread the repositories more evenly on the disk. The top-level directory
contains fewer folders than the total number of top-level namespaces.

The hash format is based on the hexadecimal representation of a SHA256, calculated with
`SHA256(project.id)`. The top-level folder uses the first two characters, followed by another folder
with the next two characters. They are both stored in a special `@hashed` folder so they can
co-exist with existing legacy storage projects. For example:

```ruby
# Project's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"

# Wiki's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### Translate hashed storage paths

Troubleshooting problems with the Git repositories, adding hooks, and other tasks requires you
translate between the human-readable project name and the hashed storage path. You can translate:

- From a [project's name to its hashed path](#from-project-name-to-hashed-path).
- From a [hashed path to a project's name](#from-hashed-path-to-project-name).

#### From project name to hashed path

Administrators can look up a project's hashed path from its name or ID using:

- The [Admin area](../user/admin_area/index.md#administering-projects).
- A Rails console.

To look up a project's hash path in the Admin Area:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Projects** and select the project.

The **Gitaly relative path** is displayed there and looks similar to:

```plaintext
"@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
```

To look up a project's hash path using a Rails console:

1. Start a [Rails console](operations/rails_console.md#starting-a-rails-console-session).
1. Run a command similar to this example (use either the project's ID or its name):

   ```ruby
   Project.find(16).disk_path
   Project.find_by_full_path('group/project').disk_path
   ```

#### From hashed path to project name

Administrators can look up a project's name from its hashed storage path using a Rails console. To
look up a project's name from its hashed storage path:

1. Start a [Rails console](operations/rails_console.md#starting-a-rails-console-session).
1. Run a command similar to this example:

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project
   ```

The quoted string in that command is the directory tree you can find on your GitLab server. For
example, on a default Omnibus installation this would be `/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`
with `.git` from the end of the directory name removed.

The output includes the project ID and the project name. For example:

```plaintext
=> #<Project id:16 it/supportteam/ticketsystem>
```

### Hashed object pools

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/1606) in GitLab 12.1.

Object pools are repositories used to deduplicate forks of public and internal projects and
contain the objects from the source project. Using `objects/info/alternates`, the source project and
forks use the object pool for shared objects. For more information, see
[How Git object deduplication works in GitLab](../development/git_object_deduplication.md).

Objects are moved from the source project to the object pool when housekeeping is run on the source
project. Object pool repositories are stored similarly to regular repositories in a directory called `@pools` instead of `@hashed`

```ruby
# object pool paths
"@pools/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"
```

WARNING:
Do not run `git prune` or `git gc` in object pool repositories, which are stored in the `@pools` directory.
This can cause data loss in the regular repositories that depend on the object pool.

### Object storage support

This table shows which storable objects are storable in each storage type:

| Storable object  | Legacy storage | Hashed storage | S3 compatible | GitLab version |
|:-----------------|:---------------|:---------------|:--------------|:---------------|
| Repository       | Yes            | Yes            | -             | 10.0           |
| Attachments      | Yes            | Yes            | -             | 10.2           |
| Avatars          | Yes            | No             | -             | -              |
| Pages            | Yes            | No             | -             | -              |
| Docker Registry  | Yes            | No             | -             | -              |
| CI/CD job logs   | No             | No             | -             | -              |
| CI/CD artifacts  | No             | No             | Yes           | 9.4 / 10.6     |
| CI/CD cache      | No             | No             | Yes           | -              |
| LFS objects      | Yes            | Similar        | Yes           | 10.0 / 10.7    |
| Repository pools | No             | Yes            | -             | 11.6           |

Files stored in an S3-compatible endpoint can have the same advantages as
[hashed storage](#hashed-storage), as long as they are not prefixed with
`#{namespace}/#{project_name}`. This is true for CI/CD cache and LFS objects.

#### Avatars

Each file is stored in a directory that matches the `id` assigned to it in the database. The
filename is always `avatar.png` for user avatars. When an avatar is replaced, the `Upload` model is
destroyed and a new one takes place with a different `id`.

#### CI/CD artifacts

CI/CD artifacts are:

- S3-compatible since GitLab 9.4, initially available in [GitLab Premium](https://about.gitlab.com/pricing/).
- Available in [GitLab Free](https://about.gitlab.com/pricing/) since GitLab 10.6.

#### LFS objects

[LFS Objects in GitLab](../topics/git/lfs/index.md) implement a similar
storage pattern using two characters and two-level folders, following Git's own implementation:

```ruby
"shared/lfs-objects/#{oid[0..1}/#{oid[2..3]}/#{oid[4..-1]}"

# Based on object `oid`: `8909029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c`, path will be:
"shared/lfs-objects/89/09/029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c"
```

LFS objects are also [S3-compatible](lfs/index.md#storing-lfs-objects-in-remote-object-storage).

## Legacy storage

WARNING:
In GitLab 13.0, legacy storage is deprecated. If you haven't migrated to hashed storage yet, check
the [migration instructions](raketasks/storage.md#migrate-to-hashed-storage). Support for legacy
storage is [scheduled to be removed](https://gitlab.com/gitlab-org/gitaly/-/issues/1690) in GitLab
14.0. In GitLab 13.0 and later, switching new projects to legacy storage is not possible. The
option to choose between hashed and legacy storage in the Admin Area is disabled.

Legacy storage was the storage behavior prior to version GitLab 10.0. For historical reasons,
GitLab replicated the same mapping structure from the projects URLs:

- Project's repository: `#{namespace}/#{project_name}.git`.
- Project's wiki: `#{namespace}/#{project_name}.wiki.git`.

This structure enabled you to migrate from existing solutions to GitLab, and for Administrators to
find where the repository was stored. This approach also had some drawbacks:

- Storage location concentrated a large number of top-level namespaces. The impact could be
  reduced by [multiple repository storage paths](repository_storage_paths.md).
- Because backups were a snapshot of the same URL mapping, if you tried to recover a very old
  backup, you needed to verify whether any project had taken the place of an old removed or renamed
  project sharing the same URL. This meant that `mygroup/myproject` from your backup may not have
  been the same original project that was at that same URL today.
- Any change in the URL needed to be reflected on disk (when groups, users, or projects were
  renamed. This could add a lot of load in big installations, especially if using any type of
  network-based file system.
