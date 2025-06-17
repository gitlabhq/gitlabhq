---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: File Storage in GitLab
---

We use the [CarrierWave](https://github.com/carrierwaveuploader/carrierwave) gem to handle file upload, store and retrieval.

File uploads should be accelerated by workhorse, for details refer to [uploads development documentation](uploads/_index.md).

There are many places where file uploading is used, according to contexts:

- System
  - Instance Logo (logo visible in sign in/sign up pages)
  - Header Logo (one displayed in the navigation bar)
- Group
  - Group avatars
- User
  - User avatars
  - User snippet attachments
- Project
  - Project avatars
  - Issues/MR/Notes Markdown attachments
  - Issues/MR/Notes Legacy Markdown attachments
  - CI Artifacts (archive, metadata, trace)
  - LFS Objects
  - Merge request diffs
  - Design Management design thumbnails
- Topic
  - Topic avatars

## Disk storage

GitLab started saving everything on local disk. While directory location changed from previous versions,
they are still not 100% standardized. You can see them below:

| Description                           | In DB? | Relative path (from CarrierWave.root)                       | Uploader class         | Model type |
| ------------------------------------- | ------ | ----------------------------------------------------------- | ---------------------- | ---------- |
| Instance logo                         | yes    | `uploads/-/system/appearance/logo/:id/:filename`              | `AttachmentUploader`   | Appearance |
| Header logo                           | yes    | `uploads/-/system/appearance/header_logo/:id/:filename`       | `AttachmentUploader`   | Appearance |
| Group avatars                         | yes    | `uploads/-/system/group/avatar/:id/:filename`                 | `AvatarUploader`       | Group      |
| User avatars                          | yes    | `uploads/-/system/user/avatar/:id/:filename`                  | `AvatarUploader`       | User       |
| User snippet attachments              | yes    | `uploads/-/system/personal_snippet/:id/:random_hex/:filename` | `PersonalFileUploader` | Snippet    |
| Project avatars                       | yes    | `uploads/-/system/project/avatar/:id/:filename`               | `AvatarUploader`       | Project    |
| Topic avatars                         | yes    | `uploads/-/system/projects/topic/avatar/:id/:filename`        | `AvatarUploader`       | Topic      |
| Issues/MR/Notes Markdown attachments  | yes    | `uploads/:hash_project_id/:random_hex/:filename`  | `FileUploader`         | Project    |
| Design Management design thumbnails   | yes | `uploads/-/system/design_management/action/image_v432x230/:id/:filename` | `DesignManagement::DesignV432x230Uploader` | DesignManagement::Action |
| CI Artifacts (CE)                     | yes    | `shared/artifacts/:disk_hash[0..1]/:disk_hash[2..3]/:disk_hash/:year_:month_:date/:job_id/:job_artifact_id` (`:disk_hash` is SHA256 digest of `project_id`) | `JobArtifactUploader`  | Ci::JobArtifact  |
| LFS Objects (CE)                      | yes    | `shared/lfs-objects/:hex/:hex/:object_hash`                   | `LfsObjectUploader`    | LfsObject  |
| External merge request diffs          | yes    | `shared/external-diffs/merge_request_diffs/mr-:parent_id/diff-:id` | `ExternalDiffUploader` | MergeRequestDiff |
| Issuable metric images                | yes    | `uploads/-/system/issuable_metric_image/file/:id/:filename` | `IssuableMetricImageUploader` | IssuableMetricImage |

CI Artifacts and LFS Objects behave differently in CE and EE. In CE they inherit the `GitlabUploader`
while in EE they inherit the `ObjectStorage` and store files in and S3 API compatible object store.

Attachments for issues, merge requests (MR), and notes in Markdown use
[hashed storage](../administration/repository_storage_paths.md) with the hash of the project ID.

We provide an [all-in-one Rake task](../administration/raketasks/uploads/migrate.md)
to migrate all uploads to object storage in one go. If a new Uploader class or model
type is introduced, make sure you add a Rake task invocation corresponding to it to the
[category list](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/uploads/migrate.rake).

### Path segments

Files are stored at multiple locations and use different path schemes.
All the `GitlabUploader` derived classes should comply with this path segment schema:

```plaintext
|   GitlabUploader
| ----------------------- + ------------------------- + --------------------------------- + -------------------------------- |
| `<gitlab_root>/public/` | `uploads/-/system/`       | `user/avatar/:id/`                | `:filename`                      |
| ----------------------- + ------------------------- + --------------------------------- + -------------------------------- |
| `CarrierWave.root`      | `GitlabUploader.base_dir` | `GitlabUploader#dynamic_segment`  | `CarrierWave::Uploader#filename` |
|                         | `CarrierWave::Uploader#store_dir`                             |                                  |

|   FileUploader
| ----------------------- + ------------------------- + --------------------------------- + -------------------------------- |
| `<gitlab_root>/shared/` | `artifacts/`              | `:year_:month/:id`                | `:filename`                      |
| `<gitlab_root>/shared/` | `snippets/`               | `:secret/`                        | `:filename`                      |
| ----------------------- + ------------------------- + --------------------------------- + -------------------------------- |
| `CarrierWave.root`      | `GitlabUploader.base_dir` | `GitlabUploader#dynamic_segment`  | `CarrierWave::Uploader#filename` |
|                         | `CarrierWave::Uploader#store_dir`                             |                                  |
|                         |                           | `FileUploader#upload_path`                                           |

|   ObjectStore::Concern (store = remote)
| ----------------------- + ------------------------- + ----------------------------------- + -------------------------------- |
| `<bucket_name>`         | <ignored>                 | `user/avatar/:id/`                  | `:filename`                      |
| ----------------------- + ------------------------- + ----------------------------------- + -------------------------------- |
| `#fog_dir`              | `GitlabUploader.base_dir` | `GitlabUploader#dynamic_segment`    | `CarrierWave::Uploader#filename` |
|                         |                           | `ObjectStorage::Concern#store_dir`  |                                  |
|                         |                           | `ObjectStorage::Concern#upload_path`                                   |
```

The `RecordsUploads::Concern` concern creates an `Upload` entry for every file stored by a `GitlabUploader` persisting the dynamic parts of the path using
`GitlabUploader#dynamic_path`. You may then use the `Upload#build_uploader` method to manipulate the file.

## Object Storage

By including the `ObjectStorage::Concern` in the `GitlabUploader` derived class, you may enable the object storage for this uploader. To enable the object storage
in your uploader, you need to either 1) include `RecordsUpload::Concern` and prepend `ObjectStorage::Extension::RecordsUploads` or 2) mount the uploader and create a new field named `<mount>_store`.

The `CarrierWave::Uploader#store_dir` is overridden to

- `GitlabUploader.base_dir` + `GitlabUploader.dynamic_segment` when the store is LOCAL
- `GitlabUploader.dynamic_segment` when the store is REMOTE (the bucket name is used to namespace)

### Using `ObjectStorage::Extension::RecordsUploads`

This concern includes `RecordsUploads::Concern` if not already included.

The `ObjectStorage::Concern` uploader searches for the matching `Upload` to select the correct object store. The `Upload` is mapped using `#store_dirs + identifier` for each store (LOCAL/REMOTE).

```ruby
class SongUploader < GitlabUploader
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads

  ...
end

class Thing < ActiveRecord::Base
  mount :theme, SongUploader # we have a great theme song!

  ...
end
```

### Using a mounted uploader

The `ObjectStorage::Concern` queries the `model.<mount>_store` attribute to select the correct object store.
This column must be present in the model schema.

```ruby
class SongUploader < GitlabUploader
  include ObjectStorage::Concern

  ...
end

class Thing < ActiveRecord::Base
  attr_reader :theme_store # this is an ActiveRecord attribute
  mount :theme, SongUploader # we have a great theme song!

  def theme_store
    super || ObjectStorage::Store::LOCAL
  end

  ...
end
```
