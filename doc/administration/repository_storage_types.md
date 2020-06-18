# Repository storage types **(CORE ONLY)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28283) in GitLab 10.0.
> - Hashed storage became the default for new installations in GitLab 12.0
> - Hashed storage is enabled by default for new and renamed projects in GitLab 13.0.

GitLab can be configured to use one or multiple repository storage paths/shard
locations that can be:

- Mounted to the local disk
- Exposed as an NFS shared volume
- Accessed via [Gitaly](gitaly/index.md) on its own machine.

In GitLab, this is configured in `/etc/gitlab/gitlab.rb` by the `git_data_dirs({})`
configuration hash. The storage layouts discussed here will apply to any shard
defined in it.

The `default` repository shard that is available in any installations
that haven't customized it, points to the local folder: `/var/opt/gitlab/git-data`.
Anything discussed below is expected to be part of that folder.

## Hashed storage

NOTE: **Note:**
In GitLab 13.0, hashed storage is enabled by default and the legacy storage is
deprecated. Support for legacy storage will be removed in GitLab 14.0.
If you haven't migrated yet, check the
[migration instructions](raketasks/storage.md#migrate-to-hashed-storage).
The option to choose between hashed and legacy storage in the admin area has
been disabled.

Hashed storage is the storage behavior we rolled out with 10.0. Instead
of coupling project URL and the folder structure where the repository will be
stored on disk, we are coupling a hash, based on the project's ID. This makes
the folder structure immutable, and therefore eliminates any requirement to
synchronize state from URLs to disk structure. This means that renaming a group,
user, or project will cost only the database transaction, and will take effect
immediately.

The hash also helps to spread the repositories more evenly on the disk, so the
top-level directory will contain less folders than the total amount of top-level
namespaces.

The hash format is based on the hexadecimal representation of SHA256:
`SHA256(project.id)`. The top-level folder uses the first 2 characters, followed
by another folder with the next 2 characters. They are both stored in a special
`@hashed` folder, to be able to co-exist with existing Legacy Storage projects:

```ruby
# Project's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"

# Wiki's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### Translating hashed storage paths

Troubleshooting problems with the Git repositories, adding hooks, and other
tasks will require you translate between the human readable project name
and the hashed storage path.

#### From project name to hashed path

The hashed path is shown on the project's page in the [admin area](../user/admin_area/index.md#administering-projects).

To access the Projects page, go to **Admin Area > Overview > Projects** and then
open up the page for the project.

The "Gitaly relative path" is shown there, for example:

```plaintext
"@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
```

This is the path under `/var/opt/gitlab/git-data/repositories/` on a
default Omnibus installation.

In a [Rails console](troubleshooting/debug.md#starting-a-rails-console-session),
get this information using either the numeric project ID or the full path:

```ruby
Project.find(16).disk_path
Project.find_by_full_path('group/project').disk_path
```

#### From hashed path to project name

To translate from a hashed storage path to a project name:

1. Start a [Rails console](troubleshooting/debug.md#starting-a-rails-console-session).
1. Run the following:

```ruby
ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project
```

The quoted string in that command is the directory tree you'll find on your
GitLab server. For example, on a default Omnibus installation this would be
`/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`
with `.git` from the end of the directory name removed.

The output includes the project ID and the project name:

```plaintext
=> #<Project id:16 it/supportteam/ticketsystem>
```

### Hashed object pools

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/1606) in GitLab 12.1.

DANGER: **Danger:**
Do not run `git prune` or `git gc` in pool repositories! This can
cause data loss in "real" repositories that depend on the pool in
question.

Forks of public projects are deduplicated by creating a third repository, the
object pool, containing the objects from the source project. Using
`objects/info/alternates`, the source project and forks use the object pool for
shared objects. Objects are moved from the source project to the object pool
when housekeeping is run on the source project.

```ruby
# object pool paths
"@pools/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"
```

### Hashed storage coverage migration

Files stored in an S3 compatible endpoint will not have the downsides
mentioned earlier, if they are not prefixed with `#{namespace}/#{project_name}`,
which is true for CI Cache and LFS Objects.

In the table below, you can find the coverage of the migration to the hashed storage.

| Storable Object | Legacy storage | Hashed storage | S3 Compatible | GitLab Version |
| --------------- | -------------- | -------------- | ------------- | -------------- |
| Repository      | Yes            | Yes            | -             | 10.0           |
| Attachments     | Yes            | Yes            | -             | 10.2           |
| Avatars         | Yes            | No             | -             | -              |
| Pages           | Yes            | No             | -             | -              |
| Docker Registry | Yes            | No             | -             | -              |
| CI Build Logs   | No             | No             | -             | -              |
| CI Artifacts    | No             | No             | Yes           | 9.4 / 10.6     |
| CI Cache        | No             | No             | Yes           | -              |
| LFS Objects     | Yes            | Similar        | Yes           | 10.0 / 10.7    |
| Repository pools| No             | Yes            | -             | 11.6           |

#### Avatars

Each file is stored in a folder with its `id` from the database. The filename is always `avatar.png` for user avatars.
When avatar is replaced, `Upload` model is destroyed and a new one takes place with different `id`.

#### CI artifacts

CI Artifacts are S3 compatible since **9.4** (GitLab Premium), and available in GitLab Core since **10.6**.

#### LFS objects

[LFS Objects in GitLab](../topics/git/lfs/index.md) implement a similar
storage pattern using 2 chars, 2 level folders, following Git's own implementation:

```ruby
"shared/lfs-objects/#{oid[0..1}/#{oid[2..3]}/#{oid[4..-1]}"

# Based on object `oid`: `8909029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c`, path will be:
"shared/lfs-objects/89/09/029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c"
```

LFS objects are also [S3 compatible](lfs/index.md#storing-lfs-objects-in-remote-object-storage).

## Legacy storage

NOTE: **Deprecated:**
In GitLab 13.0, hashed storage is enabled by default and the legacy storage is
deprecated. If you haven't migrated yet, check the
[migration instructions](raketasks/storage.md#migrate-to-hashed-storage).
Support for legacy storage will be removed in GitLab 14.0. If you're on GitLab
13.0 and later, switching new projects to legacy storage is not possible.
The option to choose between hashed and legacy storage in the admin area has
been disabled.

Legacy storage is the storage behavior prior to version 10.0. For historical
reasons, GitLab replicated the same mapping structure from the projects URLs:

- Project's repository: `#{namespace}/#{project_name}.git`
- Project's wiki: `#{namespace}/#{project_name}.wiki.git`

This structure made it simple to migrate from existing solutions to GitLab and
easy for Administrators to find where the repository is stored.

On the other hand this has some drawbacks:

Storage location will concentrate huge amount of top-level namespaces. The
impact can be reduced by the introduction of
[multiple storage paths](repository_storage_paths.md).

Because backups are a snapshot of the same URL mapping, if you try to recover a
very old backup, you need to verify whether any project has taken the place of
an old removed or renamed project sharing the same URL. This means that
`mygroup/myproject` from your backup may not be the same original project that
is at that same URL today.

Any change in the URL will need to be reflected on disk (when groups / users or
projects are renamed). This can add a lot of load in big installations,
especially if using any type of network based filesystem.
