# Repository Storage Types

> [Introduced][ce-28283] in GitLab 10.0.

## Legacy Storage

Legacy Storage is the storage behavior prior to version 10.0. For historical
reasons, GitLab replicated the same mapping structure from the projects URLs:

* Project's repository: `#{namespace}/#{project_name}.git`
* Project's wiki: `#{namespace}/#{project_name}.wiki.git`

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

For GitLab Geo in particular: Geo does work with legacy storage, but in some
edge cases due to race conditions it can lead to errors when a project is
renamed multiple times in short succession, or a project is deleted and
recreated under the same name very quickly. We expect these race events to be
rare, and we have not observed a race condition side-effect happening yet.

This pattern also exists in other objects stored in GitLab, like issue
Attachments, GitLab Pages artifacts, Docker Containers for the integrated
Registry, etc.

## Hashed Storage

> **Warning:** Hashed storage is in **Beta**. For the latest updates, check the
> associated [issue](https://gitlab.com/gitlab-com/infrastructure/issues/2821)
> and please report any problems you encounter.

Hashed Storage is the new storage behavior we are rolling out with 10.0. Instead
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

### How to migrate to Hashed Storage

In GitLab, go to **Admin > Settings**, find the **Repository Storage** section
and select "_Create new projects using hashed storage paths_".

To migrate your existing projects to the new storage type, check the specific
[rake tasks].

[ce-28283]: https://gitlab.com/gitlab-org/gitlab-ce/issues/28283
[rake tasks]: raketasks/storage.md#migrate-existing-projects-to-hashed-storage
[storage-paths]: repository_storage_types.md

### Hashed Storage coverage

We are incrementally moving every storable object in GitLab to the Hashed
Storage pattern. You can check the current coverage status below (and also see
the [issue](https://gitlab.com/gitlab-com/infrastructure/issues/2821)).

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
| CI Artifacts    | No             | No             | Yes (Premium) | -              |
| CI Cache        | No             | No             | Yes           | -              |
| LFS Objects     | Yes            | No             | Yes (Premium) | -              |
