# File Storage in GitLab

We use the [CarrierWave] gem to handle file upload, store and retrieval.

There are many places where file uploading is used, according to contexts:

* System
  - Instance Logo (logo visible in sign in/sign up pages)
  - Header Logo (one displayed in the navigation bar)
* Group
  - Group avatars
* User
  - User avatars
  - User snippet attachments
* Project
  - Project avatars
  - Issues/MR Markdown attachments
  - Issues/MR Legacy Markdown attachments
  - CI Build Artifacts
  - LFS Objects


## Disk storage

GitLab started saving everything on local disk. While directory location changed from previous versions,
they are still not 100% standardized. You can see them below:

| Description                           | In DB? | Relative path                                               | Uploader class         | model_type |
| ------------------------------------- | ------ | ----------------------------------------------------------- | ---------------------- | ---------- |
| Instance logo                         | yes    | uploads/-/system/appearance/logo/:id/:filename              | `AttachmentUploader`   | Appearance |
| Header logo                           | yes    | uploads/-/system/appearance/header_logo/:id/:filename       | `AttachmentUploader`   | Appearance |
| Group avatars                         | yes    | uploads/-/system/group/avatar/:id/:filename                 | `AvatarUploader`       | Group      |
| User avatars                          | yes    | uploads/-/system/user/avatar/:id/:filename                  | `AvatarUploader`       | User       |
| User snippet attachments              | yes    | uploads/-/system/personal_snippet/:id/:random_hex/:filename | `PersonalFileUploader` | Snippet    |
| Project avatars                       | yes    | uploads/-/system/project/avatar/:id/:filename               | `AvatarUploader`       | Project    |
| Issues/MR Markdown attachments        | yes    | uploads/:project_path_with_namespace/:random_hex/:filename  | `FileUploader`         | Project    |
| Issues/MR Legacy Markdown attachments | no     | uploads/-/system/note/attachment/:id/:filename              | `AttachmentUploader`   | Note       |
| CI Artifacts (CE)                     | yes    | shared/artifacts/:year_:month/:project_id/:id               | `ArtifactUploader`     | Ci::Build  |
| LFS Objects  (CE)                     | yes    | shared/lfs-objects/:hex/:hex/:object_hash                   | `LfsObjectUploader`    | LfsObject  |

CI Artifacts and LFS Objects behave differently in CE and EE. In CE they inherit the `GitlabUploader`
while in EE they inherit the `ObjectStoreUploader` and store files in and S3 API compatible object store.

In the case of Issues/MR Markdown attachments, there is a different approach using the [Hashed Storage] layout,
instead of basing the path into a mutable variable `:project_path_with_namespace`, it's possible to use the
hash of the project ID instead, if project migrates to the new approach (introduced in 10.2).

[CarrierWave]: https://github.com/carrierwaveuploader/carrierwave
[Hashed Storage]: ../administration/repository_storage_types.md
