# Repository Storage Types

> [Introduced][ce-28283] in GitLab 10.0.

Two different storage layouts can be used
to store the repositories on disk and their characteristics.

GitLab can be configured to use one or multiple repository shard locations
that can be:

- Mounted to the local disk
- Exposed as an NFS shared volume
- Acessed via [gitaly] on its own machine.

In GitLab, this is configured in `/etc/gitlab/gitlab.rb` by the `git_data_dirs({})`
configuration hash. The storage layouts discussed here will apply to any shard
defined in it.

The `default` repository shard that is available in any installations
that haven't customized it, points to the local folder: `/var/opt/gitlab/git-data`.
Anything discussed below is expected to be part of that folder.

## Legacy Storage

Legacy Storage is the storage behavior prior to version 10.0. For historical
reasons, GitLab replicated the same mapping structure from the projects URLs:

- Project's repository: `#{namespace}/#{project_name}.git`
- Project's wiki: `#{namespace}/#{project_name}.wiki.git`

This structure made it simple to migrate from existing solutions to GitLab and
easy for Administrators to find where the repository is stored.

On the other hand this has some drawbacks:

Storage location will concentrate huge amount of top-level namespaces. The
impact can be reduced by the introduction of [multiple storage
paths][storage-paths].

Because backups are a snapshot of the same URL mapping, if you try to recover a
very old backup, you need to verify whether any project has taken the place of
an old removed or renamed project sharing the same URL. This means that
`mygroup/myproject` from your backup may not be the same original project that
is at that same URL today.

Any change in the URL will need to be reflected on disk (when groups / users or
projects are renamed). This can add a lot of load in big installations,
especially if using any type of network based filesystem.

## Hashed Storage

CAUTION: **Important:**
Geo requires Hashed Storage since 12.0. If you haven't migrated yet,
check the [migration instructions](#how-to-migrate-to-hashed-storage) ASAP.

Hashed Storage is the new storage behavior we rolled out with 10.0. Instead
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

### Hashed object pools

> [Introduced](https://gitlab.com/gitlab-org/gitaly/issues/1606) in GitLab 12.1.

Forks of public projects are deduplicated by creating a third repository, the object pool, containing the objects from the source project. Using `objects/info/alternates`, the source project and forks use the object pool for shared objects. Objects are moved from the source project to the object pool when housekeeping is run on the source project.

```ruby
# object pool paths
"@pools/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"
```

Object pools can be disabled using the `object_pools` feature flag, and can be
disabled for individual projects by executing
`Feature.disable(:object_pools, Project.find(<id>))`. Disabling object pools
will not change existing deduplicated forks, but will prevent new forks from
being deduplicated.

DANGER: **Danger:**
Do not run `git prune` or `git gc` in pool repositories! This can
cause data loss in "real" repositories that depend on the pool in
question.

### How to migrate to Hashed Storage

To start a migration, enable Hashed Storage for new projects:

1. Go to **Admin > Settings > Repository** and expand the **Repository Storage** section.
2. Select the **Use hashed storage paths for newly created and renamed projects** checkbox.

Check if the change breaks any existing integration you may have that
either runs on the same machine as your repositories are located, or may login to that machine
to access data (for example, a remote backup solution).

To schedule a complete rollout, see the
[rake task documentation for storage migration][rake/migrate-to-hashed] for instructions.

If you do have any existing integration, you may want to do a small rollout first,
to validate. You can do so by specifying a range with the operation.

This is an example of how to limit the rollout to Project IDs 50 to 100, running in
an Omnibus Gitlab installation:

```bash
sudo gitlab-rake gitlab:storage:migrate_to_hashed ID_FROM=50 ID_TO=100
```

Check the [documentation][rake/migrate-to-hashed] for additional information and instructions for
source-based installation.

#### Rollback

Similar to the migration, to disable Hashed Storage for new
projects:

1. Go to **Admin > Settings > Repository** and expand the **Repository Storage** section.
2. Uncheck the **Use hashed storage paths for newly created and renamed projects** checkbox.

To schedule a complete rollback, see the
[rake task documentation for storage rollback](raketasks/storage.md#rollback-from-hashed-storage-to-legacy-storage) for instructions.

The rollback task also supports specifying a range of Project IDs. Here is an example
of limiting the rollout to Project IDs 50 to 100, in an Omnibus Gitlab installation:

```bash
sudo gitlab-rake gitlab:storage:rollback_to_legacy ID_FROM=50 ID_TO=100
```

If you have a Geo setup, please note that the rollback will not be reflected automatically
on the **secondary** node. You may need to wait for a backfill operation to kick-in and remove
the remaining repositories from the special `@hashed/` folder manually.

### Hashed Storage coverage

We are incrementally moving every storable object in GitLab to the Hashed
Storage pattern. You can check the current coverage status below (and also see
the [issue][ce-2821]).

Note that things stored in an S3 compatible endpoint will not have the downsides
mentioned earlier, if they are not prefixed with `#{namespace}/#{project_name}`,
which is true for CI Cache and LFS Objects.

| Storable Object | Legacy Storage | Hashed Storage | S3 Compatible | GitLab Version |
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

#### Implementation Details

##### Avatars

Each file is stored in a folder with its `id` from the database. The filename is always `avatar.png` for user avatars.
When avatar is replaced, `Upload` model is destroyed and a new one takes place with different `id`.

##### CI Artifacts

CI Artifacts are S3 compatible since **9.4** (GitLab Premium), and available in GitLab Core since **10.6**.

##### LFS Objects

LFS Objects implements a similar storage pattern using 2 chars, 2 level folders, following git own implementation:

```ruby
"shared/lfs-objects/#{oid[0..1}/#{oid[2..3]}/#{oid[4..-1]}"

# Based on object `oid`: `8909029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c`, path will be:
"shared/lfs-objects/89/09/029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c"
```

They are also S3 compatible since **10.0** (GitLab Premium), and available in GitLab Core since **10.7**.

[ce-2821]: https://gitlab.com/gitlab-com/infrastructure/issues/2821
[ce-28283]: https://gitlab.com/gitlab-org/gitlab-ce/issues/28283
[rake/migrate-to-hashed]: raketasks/storage.md#migrate-existing-projects-to-hashed-storage
[storage-paths]: repository_storage_types.md
[gitaly]: gitaly/index.md
