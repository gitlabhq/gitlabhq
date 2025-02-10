---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Repository storage
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab stores [repositories](../user/project/repository/_index.md) on repository storage. Repository
storage is either:

- Physical storage configured with a `gitaly_address` that points to a [Gitaly node](gitaly/_index.md).
- [Virtual storage](gitaly/_index.md#virtual-storage) that stores repositories on a Gitaly Cluster.

WARNING:
Repository storage could be configured as a `path` that points directly to the directory where the repositories are
stored. GitLab directly accessing a directory containing repositories is deprecated. You should configure GitLab to
access repositories through a physical or virtual storage.

For more information on:

- Configuring Gitaly, see [Configure Gitaly](gitaly/configure_gitaly.md).
- Configuring Gitaly Cluster, see [Configure Gitaly Cluster](gitaly/praefect.md).

## Hashed storage

> - Support for legacy storage, where repository paths were generated based on the project path, has been completely removed in GitLab 14.0.
> - **Storage name** field [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416) from **Gitaly storage name** and **Relative path** field [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416) from **Gitaly relative path** in GitLab 16.3.

Hashed storage stores projects on disk in a location based on a hash of the project's ID. This makes the folder
structure immutable and eliminates the need to synchronize state from URLs to disk structure. This means that renaming a
group, user, or project:

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

- The [**Admin** area](admin_area.md#administering-projects).
- A Rails console.

To look up a project's hash path in the **Admin** area:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Projects** and select the project.
1. Locate the **Relative path** field. The value is similar to:

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

Administrators can look up a project's name from its hashed relative path using:

- A Rails console.
- The `config` file in the `*.git` directory.

To look up a project's name using the Rails console:

1. Start a [Rails console](operations/rails_console.md#starting-a-rails-console-session).
1. Run a command similar to this example:

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project
   ```

The quoted string in that command is the directory tree you can find on your GitLab server. For
example, on a default Linux package installation this would be `/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`
with `.git` from the end of the directory name removed.

The output includes the project ID and the project name. For example:

```plaintext
=> #<Project id:16 it/supportteam/ticketsystem>
```

To look up a project's name using the `config` file in the `*.git` directory:

1. Locate the `*.git` directory. This directory is located in `/var/opt/gitlab/git-data/repositories/@hashed/`, where the first four
   characters of the hash are the first two directories in the path under `@hashed/`. For example, on a default Linux package installation the
   `*.git` directory of the hash `b17eb17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9` would be
   `/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`.
1. Open the `config` file and locate the `fullpath=` key under `[gitlab]`.

### Hashed object pools

Object pools are repositories used to deduplicate [forks of public and internal projects](../user/project/repository/forking_workflow.md) and
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

### Translate hashed object pool storage paths

To look up a project's object pool using a Rails console:

1. Start a [Rails console](operations/rails_console.md#starting-a-rails-console-session).
1. Run a command similar to the following example:

   ```ruby
   project_id = 1
   pool_repository = Project.find(project_id).pool_repository
   pool_repository = Project.find_by_full_path('group/project').pool_repository

   # Get more details about the pool repository
   pool_repository.source_project
   pool_repository.member_projects
   pool_repository.shard
   pool_repository.disk_path
   ```

### Group wiki storage

Unlike project wikis that are stored in the `@hashed` directory, group wikis are stored in a directory called `@groups`.
Like project wikis, group wikis follow the hashed storage folder convention, but use a hash of the group ID rather than the project ID.

For example:

```ruby
# group wiki paths
"@groups/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### Gitaly Cluster storage

If Gitaly Cluster is used, Praefect manages storage locations. The internal path used by Praefect for the repository
differs from the hashed path. For more information, see
[Praefect-generated replica paths](gitaly/_index.md#praefect-generated-replica-paths).

### Object storage support

This table shows which storable objects are storable in each storage type:

| Storable object  | Hashed storage | S3 compatible |
|:-----------------|:---------------|:--------------|
| Repository       | Yes            | -             |
| Attachments      | Yes            | -             |
| Avatars          | No             | -             |
| Pages            | No             | -             |
| Docker Registry  | No             | -             |
| CI/CD job logs   | No             | -             |
| CI/CD artifacts  | No             | Yes           |
| CI/CD cache      | No             | Yes           |
| LFS objects      | Similar        | Yes           |
| Repository pools | Yes            | -             |

Files stored in an S3-compatible endpoint can have the same advantages as
[hashed storage](#hashed-storage), as long as they are not prefixed with
`#{namespace}/#{project_name}`. This is true for CI/CD cache and LFS objects.

#### Avatars

Each file is stored in a directory that matches the `id` assigned to it in the database. The
filename is always `avatar.png` for user avatars. When an avatar is replaced, the `Upload` model is
destroyed and a new one takes place with a different `id`.

#### CI/CD artifacts

CI/CD artifacts are S3-compatible.

#### LFS objects

[LFS Objects in GitLab](../topics/git/lfs/_index.md) implement a similar
storage pattern using two characters and two-level folders, following the Git implementation:

```ruby
"shared/lfs-objects/#{oid[0..1}/#{oid[2..3]}/#{oid[4..-1]}"

# Based on object `oid`: `8909029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c`, path will be:
"shared/lfs-objects/89/09/029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c"
```

LFS objects are also [S3-compatible](lfs/_index.md#storing-lfs-objects-in-remote-object-storage).

## Configure where new repositories are stored

After you [configure multiple repository storages](https://docs.gitlab.com/omnibus/settings/configuration.html#store-git-data-in-an-alternative-directory), you can choose where new repositories are stored:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Repository**.
1. Expand **Repository storage**.
1. Enter values in the **Storage nodes for new repositories** fields.
1. Select **Save changes**.

Each repository storage path can be assigned a weight from 0-100. When a new project is created,
these weights are used to determine the storage location the repository is created on.

The higher the weight of a given repository storage path relative to other repository storages
paths, the more often it is chosen (`(storage weight) / (sum of all weights) * 100 = chance %`).

By default, if repository weights have not been configured earlier:

- `default` is weighted `100`.
- All other storages are weighted `0`.

NOTE:
If all storage weights are `0` (for example, when `default` does not exist), GitLab attempts to
create new repositories on `default`, regardless of the configuration or if `default` exists.
See [the tracking issue](https://gitlab.com/gitlab-org/gitlab/-/issues/36175) for more information.

## Move repositories

To move a repository to a different repository storage (for example, from `default` to `storage2`), use the
same process as [migrating to Gitaly Cluster](gitaly/_index.md#migrate-to-gitaly-cluster).
