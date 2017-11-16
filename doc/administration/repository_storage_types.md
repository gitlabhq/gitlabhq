# Repository Storage Types

> [Introduced][ce-28283] in GitLab 10.0.

## Legacy Storage

Legacy Storage is the storage behavior prior to version 10.0. For historical reasons, GitLab replicated the same
mapping structure from the projects URLs:

 * Project's repository: `#{namespace}/#{project_name}.git`
 * Project's wiki: `#{namespace}/#{project_name}.wiki.git`

This structure made simple to migrate from existing solutions to GitLab and easy for Administrators to find where the
repository is stored.

On the other hand this has some drawbacks:

Storage location will concentrate huge amount of top-level namespaces. The impact can be reduced by the introduction of [multiple storage paths][storage-paths].

Because Backups are a snapshot of the same URL mapping, if you try to recover a very old backup, you need to verify
if any project has taken the place of an old removed project sharing the same URL. This means that `mygroup/myproject`
from your backup may not be the same original project that is today in the same URL.

Any change in the URL will need to be reflected on disk (when groups / users or projects are renamed). This can add a lot
of load in big installations, and can be even worst if they are using any type of network based filesystem.

Last, for GitLab Geo, this storage type means we have to synchronize the disk state, replicate renames in the correct
order or we may end-up with wrong repository or missing data temporarily.

This pattern also exists in other objects stored in GitLab, like issue Attachments, GitLab Pages artifacts,
Docker Containers for the integrated Registry, etc.

## Hashed Storage

Hashed Storage is the new storage behavior we are rolling out with 10.0. It's not enabled by default yet, but we
encourage everyone to try-it and take the time to fix any script you may have that depends on the old behavior.

Instead of coupling project URL and the folder structure where the repository will be stored on disk, we are coupling
a hash, based on the project's ID.

This makes the folder structure immutable, and therefore eliminates any requirement to synchronize state from URLs to
disk structure. This means that renaming a group, user or project will cost only the database transaction, and will take
effect immediately.

The hash also helps to spread the repositories more evenly on the disk, so the top-level directory will contain less
folders than the total amount of top-level namespaces.

Hash format is based on hexadecimal representation of SHA256: `SHA256(project.id)`.
Top-level folder uses first 2 characters, followed by another folder with the next 2 characters. They are both stored in
a special folder `@hashed`, to co-exist with existing Legacy projects:

```ruby
# Project's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"

# Wiki's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

This new format also makes possible to restore backups with confidence, as when restoring a repository from the backup,
you will never mistakenly restore a repository in the wrong project (considering the backup is made after the migration).

### How to migrate to Hashed Storage

In GitLab, go to **Admin > Settings**, find the **Repository Storage** section and select
"_Create new projects using hashed storage paths_".

To migrate your existing projects to the new storage type, check the specific [rake tasks].

[ce-28283]: https://gitlab.com/gitlab-org/gitlab-ce/issues/28283
[rake tasks]: raketasks/storage.md#migrate-existing-projects-to-hashed-storage
[storage-paths]: repository_storage_types.md

### Hashed Storage coverage

We are incrementally moving every storable object in GitLab to the Hashed Storage pattern. You can check the current
coverage status below.

Note that things stored in an S3 compatible endpoint will not have the downsides mentioned earlier, if they are not
prefixed with `#{namespace}/#{project_name}`, which is true for CI Cache and LFS Objects.

| Storable Object | Legacy Storage | Hashed Storage | S3 Compatible | GitLab Version |
| --------------- | -------------- | -------------- | ------------- | -------------- |
| Repository      | Yes            | Yes            | -             | 10.0           |
| Attachments     | Yes            | Yes            | -             | 10.2           |
| Avatars         | Yes            | No             | -             | -              |
| Pages           | Yes            | No             | -             | -              |
| Docker Registry | Yes            | No             | -             | -              |
| CI Build Logs   | No             | No             | -             | -              |
| CI Artifacts    | No             | No             | Yes (EEP)     | -              |
| CI Cache        | No             | No             | Yes           | -              |
| LFS Objects     | Yes            | No             | Yes (EEP)     | -              |
