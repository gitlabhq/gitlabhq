---
stage: SaaS Platforms
group: Scalability
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 'Uploads guide: Adding new uploads'
---

## Recommendations

- When creating an uploader, [make it a subclass](#where-should-you-store-your-files) of `AttachmentUploader`
- Add your uploader to the [tables](#tables) in this document
- Do not add [new object storage buckets](#where-should-you-store-your-files)
- Implement [direct upload](#implementing-direct-upload-support)
- If you need to process your uploads, decide [where to do that](#processing-uploads)

## Background information

- [CarrierWave Uploaders](#carrierwave-uploaders)
- [GitLab modifications to CarrierWave](#gitlab-modifications-to-carrierwave)

## Where should you store your files?

CarrierWave Uploaders determine where files get
stored. When you create a new Uploader class you are deciding where to store the files of your new
feature.

First of all, ask yourself if you need a new Uploader class. It is OK
to use the same Uploader class for different mount points or different
models.

If you do want or need your own Uploader class then you should make it
a **subclass of `AttachmentUploader`**. You then inherit the storage
location and directory scheme from that class. The directory scheme
is:

```ruby
File.join(model.class.underscore, mounted_as.to_s, model.id.to_s)
```

If you look around in the GitLab code base you find quite a few
Uploaders that have their own storage location. For object storage,
this means Uploaders have their own buckets. We now **discourage**
adding new buckets for the following reasons:

- Using a new bucket adds to development time because you need to make downstream changes in [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit), [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab) and [CNG](https://gitlab.com/gitlab-org/build/CNG).
- Using a new bucket requires GitLab.com Infrastructure changes, which slows down the roll-out of your new feature
- Using a new bucket slows down adoption of your new feature for GitLab Self-Managed: people cannot start using your new feature until their local GitLab administrator has configured the new bucket.

By using an existing bucket you avoid all this extra work
and friction. The `Gitlab.config.uploads` storage location, which is what
`AttachmentUploader` uses, is guaranteed to already be configured.

## Implementing Direct Upload support

Below we outline how to implement [direct upload](#direct-upload-via-workhorse) support.

Using direct upload is not always necessary but it is usually a good
idea. Unless the uploads handled by your feature are both infrequent
and small, you probably want to implement direct upload. An example of
a feature with small and infrequent uploads is project avatars: these
rarely change and the application imposes strict size limits on them.

If your feature handles uploads that are not both infrequent and small,
then not implementing direct upload support means that you are taking on
technical debt. At the very least, you should make sure that you _can_
add direct upload support later.

To support Direct Upload you need two things:

1. A pre-authorization endpoint in Rails
1. A Workhorse routing rule

Workhorse does not know where to store your upload. To find out it
makes a pre-authorization request. It also does not know whether or
where to make a pre-authorization request. For that you need the
routing rule.

A note to those of us who remember,
[Workhorse used to be a separate project](https://gitlab.com/groups/gitlab-org/-/epics/4826):
it is not necessary anymore to break these two steps into separate merge
requests. In fact it is probably easier to do both in one merge
request.

### Adding a Workhorse routing rule

Routing rules are defined in
[workhorse/internal/upstream/routes.go](https://gitlab.com/gitlab-org/gitlab/-/blob/adf99b5327700cf34a845626481d7d6fcc454e57/workhorse/internal/upstream/routes.go).
They consist of:

- An HTTP verb (usually "POST" or "PUT")
- A path regular expression
- An upload type: MIME multipart or "full request body"
- Optionally, you can also match on HTTP headers like `Content-Type`

Example:

```go
u.route("PUT", apiProjectPattern+`packages/nuget/`, mimeMultipartUploader),
```

You should add a test for your routing rule to `TestAcceleratedUpload`
in
[workhorse/upload_test.go](https://gitlab.com/gitlab-org/gitlab/-/blob/adf99b5327700cf34a845626481d7d6fcc454e57/workhorse/upload_test.go).

You should also manually verify that when you perform an upload
request for your new feature, Workhorse makes a pre-authorization
request. You can check this by looking at the Rails access logs. This
is necessary because if you make a mistake in your routing rule you
don't get a hard failure: you just end up using the less efficient
default path.

### Adding a pre-authorization endpoint

We distinguish three cases: Rails controllers, Grape API endpoints and
GraphQL resources.

To start with the bad news: direct upload for GraphQL is currently not
supported. The reason for this is that Workhorse does not parse
GraphQL queries. Also see [issue #280819](https://gitlab.com/gitlab-org/gitlab/-/issues/280819).
Consider accepting your file upload via Grape instead.

For Grape pre-authorization endpoints, look for existing examples that
implement `/authorize` routes. One example is the
[POST `:id/uploads/authorize` endpoint](https://gitlab.com/gitlab-org/gitlab/-/blob/9ad53d623eecebb799ce89eada951e4f4a59c116/lib/api/projects.rb#L642-651).
This particular example is using FileUploader, which means
that the upload is stored in the storage location (bucket) of
that Uploader class.

For Rails endpoints you can use the
[WorkhorseAuthorization concern](https://gitlab.com/gitlab-org/gitlab/-/blob/adf99b5327700cf34a845626481d7d6fcc454e57/app/controllers/concerns/workhorse_authorization.rb).

## Processing uploads

Some features require us to process uploads, for example to extract
metadata from the uploaded file. There are a couple of different ways
you can implement this. The main choice is _where_ to implement the
processing, or "who is the processor".

|Processor|Direct Upload possible?|Can reject HTTP request?|Implementation|
|---|---|---|---|
|Sidekiq|yes|no|Straightforward|
|Workhorse|yes|yes|Complex|
|Rails|no|yes|Easy|

Processing in Rails looks appealing but it tends to lead to scaling
problems down the road because you cannot use direct upload. You are
then forced to rebuild your feature with processing in Workhorse. So
if the requirements of your feature allows it, doing the processing in
Sidekiq strikes a good balance between complexity and the ability to
scale.

## CarrierWave Uploaders

GitLab uses a modified version of
[CarrierWave](https://github.com/carrierwaveuploader/carrierwave) to
manage uploads. Below we describe how we use CarrierWave and how
we modified it.

The central concept of CarrierWave is the **Uploader** class. The
Uploader defines where files get stored, and optionally contains
validation and processing logic. To use an Uploader you must associate
it with a text column on an ActiveRecord model. This is called "mounting"
and the column is called `mountpoint`. For example:

```ruby
class Project < ApplicationRecord
  mount_uploader :avatar, AttachmentUploader
end
```

Now if you upload an avatar called `tanuki.png` the idea is that in the
`projects.avatar` column for your project, CarrierWave stores the string
`tanuki.png`, and that the AttachmentUploader class contains the
configuration data and directory schema. For example if the project ID
is 123, the actual file may be in
`/var/opt/gitlab/gitlab-rails/uploads/-/system/project/avatar/123/tanuki.png`.
The directory
`/var/opt/gitlab/gitlab-rails/uploads/-/system/project/avatar/123/`
was chosen by the Uploader using among others configuration
(`/var/opt/gitlab/gitlab-rails/uploads`), the model name (`project`),
the model ID (`123`) and the mount point (`avatar`).

> The Uploader determines the individual storage directory of your
> upload. The `mountpoint` column in your model contains the filename.

You never access the `mountpoint` column directly because CarrierWave
defines a getter and setter on your model that operates on file handle
objects.

### Optional Uploader behaviors

Besides determining the storage directory for your upload, a
CarrierWave Uploader can implement several other behaviors via
callbacks. Not all of these behaviors are usable in GitLab. In
particular, you currently cannot use the `version` mechanism of
CarrierWave. Things you can do include:

- Filename validation
- **Incompatible with direct upload:** One time pre-processing of file contents, for example, image resizing
- **Incompatible with direct upload:** Encryption at rest

CarrierWave pre-processing behaviors such as image resizing
or encryption require local access to the uploaded file. This forces
you to upload the processed file from Ruby. This flies against direct
upload, which is all about _not_ doing the upload in Ruby. If you use
direct upload with an Uploader with pre-processing behaviors then the
pre-processing behaviors are skipped silently.

### CarrierWave Storage engines

CarrierWave has 2 storage engines:

|CarrierWave class|GitLab name|Description|
|---|---|---|
|`CarrierWave::Storage::File`|`ObjectStorage::Store::LOCAL` |Local files, accessed through the Ruby `stdlib` |
| `CarrierWave::Storage::Fog`|`ObjectStorage::Store::REMOTE`|Cloud files, accessed through the [Fog gem](https://github.com/fog/fog)|

GitLab uses both of these engines, depending on configuration.

The typical way to choose a storage engine in CarrierWave is to use the
`Uploader.storage` class method. In GitLab we do not do this; we have
overridden `Uploader#storage` instead. This allows us to vary the
storage engine file by file.

### CarrierWave file lifecycle

An Uploader is associated with two storage areas: regular storage and
cache storage. Each has its own storage engine. If you assign a file
to a mount point setter (`project.avatar = File.open('/tmp/tanuki.png')`)
you have to copy/move the file to cache
storage as a side effect via the `cache!` method. To persist the file
you must somehow call the `store!` method. This either happens via
[ActiveRecord callbacks](https://github.com/carrierwaveuploader/carrierwave/blob/v1.3.2/lib/carrierwave/orm/activerecord.rb#L55)
or by calling `store!` on an Uploader instance.

Typically you do not need to interact with `cache!` and `store!` but if
you need to debug GitLab CarrierWave modifications it is useful to
know that they are there and that they always get called.
Specifically, it is good to know that CarrierWave pre-processing
behaviors (`process` etc.) are implemented as `before :cache` hooks,
and in the case of direct upload, these hooks are ignored and do not
run.

> Direct upload skips all CarrierWave `before :cache` hooks.

## GitLab modifications to CarrierWave

GitLab uses a modified version of CarrierWave to make a number of things possible.

### Migrating data between storage engines

In
[app/uploaders/object_storage.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/adf99b5327700cf34a845626481d7d6fcc454e57/app/uploaders/object_storage.rb)
there is code for migrating user data between local storage and object
storage. This code exists because for a long time, GitLab.com stored
uploads on local storage via NFS. This changed when as part of an infrastructure
migration we had to move the uploads to object storage.

This is why the CarrierWave `storage` varies from upload to upload in
GitLab, and why we have database columns like `uploads.store` or
`ci_job_artifacts.file_store`.

### Direct Upload via Workhorse

Workhorse direct upload is a mechanism that lets us accept large
uploads without spending a lot of Ruby CPU time. Workhorse is written
in Go and goroutines have a much lower resource footprint than Ruby
threads.

Direct upload works as follows.

1. Workhorse accepts a user upload request
1. Workhorse pre-authenticates the request with Rails, and receives a temporary upload location
1. Workhorse stores the file upload in the user's request to the temporary upload location
1. Workhorse propagates the request to Rails
1. Rails issues a remote copy operation to copy the uploaded file from its temporary location to the final location
1. Rails deletes the temporary upload
1. Workhorse deletes the temporary upload a second time in case Rails timed out

Typically, `cache!` returns an instance of
`CarrierWave::SanitizedFile`, and `store!` then
[uploads that file using Fog](https://github.com/carrierwaveuploader/carrierwave/blob/v1.3.2/lib/carrierwave/storage/fog.rb#L327-L335).

In the case of object storage, with the modifications specific to GitLab, the
copying from the temporary location to the final location is
implemented by Rails fooling CarrierWave. When CarrierWave tries to
`cache!` the upload, we
[return](https://gitlab.com/gitlab-org/gitlab/-/blob/59b441d578e41cb177406a9799639e7a5aa9c7e1/app/uploaders/object_storage.rb#L367)
a `CarrierWave::Storage::Fog::File` file handle which points to the
temporary file. During the `store!` phase, CarrierWave then
[copies](https://github.com/carrierwaveuploader/carrierwave/blob/v1.3.2/lib/carrierwave/storage/fog.rb#L325)
this file to its intended location.

## Tables

The Scalability::Frameworks team is making object storage and uploads more easy to use and more robust. If you add or change uploaders, it helps us if you update this table too. This helps us keep an overview of where and how uploaders are used.

### Feature bucket details

| Feature                                  | Upload technology | Uploader              | Bucket structure                                                                                          |
|------------------------------------------|-------------------|-----------------------|-----------------------------------------------------------------------------------------------------------|
| Job artifacts                            | `direct upload`     | `workhorse`             | `/artifacts/<proj_id_hash>/<date>/<job_id>/<artifact_id>`                                                 |
| Pipeline artifacts                       | `carrierwave`       | `sidekiq`               | `/artifacts/<proj_id_hash>/pipelines/<pipeline_id>/artifacts/<artifact_id>`                               |
| Live job traces                          | `fog`               | `sidekiq`               | `/artifacts/tmp/builds/<job_id>/chunks/<chunk_index>.log`                                                 |
| Job traces archive                       | `carrierwave`       | `sidekiq`               | `/artifacts/<proj_id_hash>/<date>/<job_id>/<artifact_id>/job.log`                                         |
| Autoscale runner caching                 | Not applicable      | `gitlab-runner`         | `/gitlab-com-[platform-]runners-cache/???`                                                                |
| Backups                                  | Not applicable      | `s3cmd`, `awscli`, or `gcs` | `/gitlab-backups/???`                                                                                     |
| Git LFS                                  | `direct upload`     | `workhorse`             | `/lfs-objects/<lfs_obj_oid[0:2]>/<lfs_obj_oid[2:2]>`                                                      |
| Design management thumbnails             | `carrierwave`       | `sidekiq`               | `/uploads/design_management/action/image_v432x230/<model_id>/<original_lfs_obj_oid[2:2]`                                             |
| Generic file uploads                     | `direct upload`     | `workhorse`             | `/uploads/@hashed/[0:2]/[2:4]/<hash1>/<hash2>/file`                                                       |
| Generic file uploads - personal snippets | `direct upload`     | `workhorse`             | `/uploads/personal_snippet/<snippet_id>/<filename>`                                                       |
| Global appearance settings               | `disk buffering`    | `rails controller`      | `/uploads/appearance/...`                                                                                 |
| Topics                                   | `disk buffering`    | `rails controller`      | `/uploads/projects/topic/...`                                                                             |
| Avatar images                            | `direct upload`     | `workhorse`             | `/uploads/[user,group,project]/avatar/<model_id>`                                                         |
| Import                           | `direct upload`     | `workhorse`             | `/uploads/import_export_upload/import_file/<model_id>/<file_name>`                                                                       |
| Export                            | `carrierwave`     | `sidekiq`             | `/uploads/import_export_upload/export_file/<model_id>/<timestamp>_<namespace>-<project_name>_export.tag.gz`                                                                       |
| GitLab Migration                         | `carrierwave`       | `sidekiq`               | `/uploads/bulk_imports/???`                                                                               |
| MR diffs                                 | `carrierwave`       | `sidekiq`               | `/external-diffs/merge_request_diffs/mr-<mr_id>/diff-<diff_id>`                                           |
| [Package manager assets (except for NPM)](../../user/packages/package_registry/_index.md) | `direct upload`     | `workhorse`             | `/packages/<proj_id_hash>/packages/<package_id>/files/<package_file_id>`                                  |
| [NPM Package manager assets](../../user/packages/npm_registry/_index.md)                  | `carrierwave`       | `grape API`             | `/packages/<proj_id_hash>/packages/<package_id>/files/<package_file_id>`                                  |
| [Debian Package manager assets](../../user/packages/debian_repository/_index.md)          | `direct upload`     | `workhorse`             | `/packages/<group_id or project_id_hash>/debian_*/<group_id or project_id or distribution_file_id>`        |
| [Dependency Proxy cache](../../user/packages/dependency_proxy/_index.md)                  | [`send_dependency`](https://gitlab.com/gitlab-org/gitlab/-/blob/6ed73615ff1261e6ed85c8f57181a65f5b4ffada/workhorse/internal/dependencyproxy/dependencyproxy.go)   | `workhorse`             | `/dependency-proxy/<group_id_hash>/dependency_proxy/<group_id>/files/<blob_id or manifest_id>`            |
| Terraform state files                    | `carrierwave`       | `rails controller`      | `/terraform/<proj_id_hash>/<terraform_state_id>`                                                          |
| Pages content archives                   | `carrierwave`       | `sidekiq`               | `/gitlab-gprd-pages/<proj_id_hash>/pages_deployments/<deployment_id>/`                                    |
| Secure Files                             | `carrierwave`       | `sidekiq`               | `/ci-secure-files/<proj_id_hash>/secure_files/<secure_file_id>/`                                    |

### CarrierWave integration

| File                                                    | CarrierWave usage                                                                | Categorized         |
|---------------------------------------------------------|----------------------------------------------------------------------------------|---------------------|
| `app/models/project.rb`                                 | `include Avatarable`                                                             | **{check-circle}** Yes  |
| `app/models/projects/topic.rb`                          | `include Avatarable`                                                             | **{check-circle}** Yes  |
| `app/models/group.rb`                                   | `include Avatarable`                                                             | **{check-circle}** Yes  |
| `app/models/user.rb`                                    | `include Avatarable`                                                             | **{check-circle}** Yes  |
| `app/models/terraform/state_version.rb`                 | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/ci/job_artifact.rb`                         | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/ci/pipeline_artifact.rb`                    | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/pages_deployment.rb`                        | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/lfs_object.rb`                              | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/dependency_proxy/blob.rb`                   | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/dependency_proxy/manifest.rb`               | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/packages/composer/cache_file.rb`            | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/packages/package_file.rb`                   | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `app/models/concerns/packages/debian/component_file.rb` | `include FileStoreMounter`                                                       | **{check-circle}** Yes  |
| `ee/app/models/issuable_metric_image.rb`                | `include FileStoreMounter`                                                       |                     |
| `ee/app/models/vulnerabilities/remediation.rb`          | `include FileStoreMounter`                                                       |                     |
| `ee/app/models/vulnerabilities/export.rb`               | `include FileStoreMounter`                                                       |                     |
| `app/models/packages/debian/project_distribution.rb`    | `include Packages::Debian::Distribution`                                         | **{check-circle}** Yes  |
| `app/models/packages/debian/group_distribution.rb`      | `include Packages::Debian::Distribution`                                         | **{check-circle}** Yes  |
| `app/models/packages/debian/project_component_file.rb`  | `include Packages::Debian::ComponentFile`                                        | **{check-circle}** Yes  |
| `app/models/packages/debian/group_component_file.rb`    | `include Packages::Debian::ComponentFile`                                        | **{check-circle}** Yes  |
| `app/models/merge_request_diff.rb`                      | `mount_uploader :external_diff, ExternalDiffUploader`                            | **{check-circle}** Yes  |
| `app/models/note.rb`                                    | `mount_uploader :attachment, AttachmentUploader`                                 | **{check-circle}** Yes  |
| `app/models/appearance.rb`                              | `mount_uploader :logo,         AttachmentUploader`                               | **{check-circle}** Yes  |
| `app/models/appearance.rb`                              | `mount_uploader :header_logo,  AttachmentUploader`                               | **{check-circle}** Yes  |
| `app/models/appearance.rb`                              | `mount_uploader :favicon,      FaviconUploader`                                  | **{check-circle}** Yes  |
| `app/models/project.rb`                                 | `mount_uploader :bfg_object_map, AttachmentUploader`                             |                     |
| `app/models/import_export_upload.rb`                    | `mount_uploader :import_file, ImportExportUploader`                              | **{check-circle}** Yes  |
| `app/models/import_export_upload.rb`                    | `mount_uploader :export_file, ImportExportUploader`                              | **{check-circle}** Yes  |
| `app/models/ci/deleted_object.rb`                       | `mount_uploader :file, DeletedObjectUploader`                                    |                     |
| `app/models/design_management/action.rb`                | `mount_uploader :image_v432x230, DesignManagement::DesignV432x230Uploader`       | **{check-circle}** Yes  |
| `app/models/concerns/packages/debian/distribution.rb`   | `mount_uploader :signed_file, Packages::Debian::DistributionReleaseFileUploader` | **{check-circle}** Yes  |
| `app/models/bulk_imports/export_upload.rb`              | `mount_uploader :export_file, ExportUploader`                                    | **{check-circle}** Yes  |
| `ee/app/models/user_permission_export_upload.rb`        | `mount_uploader :file, AttachmentUploader`                                       |                     |
| `app/models/ci/secure_file.rb`                          | `include FileStoreMounter`                                                       |                     |
