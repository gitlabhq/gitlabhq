---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Uploads guide: Adding new uploads

In this section, we describe how to add a new upload route [accelerated](implementation.md#uploading-technologies) by Workhorse for [body and multipart](implementation.md#upload-encodings) encoded uploads.

Upload routes belong to one of these categories:

1. Rails controllers: uploads handled by Rails controllers.
1. Grape API: uploads handled by a Grape API endpoint.
1. GraphQL API: uploads handled by a GraphQL resolve function.

WARNING:
GraphQL uploads do not support [direct upload](implementation.md#direct-upload) yet. Depending on the use case, the feature may not work on installations without NFS (like GitLab.com or Kubernetes installations). Uploading to object storage inside the GraphQL resolve function may result in timeout errors. For more details please follow [issue #280819](https://gitlab.com/gitlab-org/gitlab/-/issues/280819).

## Update Workhorse for the new route

For both the Rails controller and Grape API uploads, Workhorse has to be updated in order to get the
support for the new upload route.

1. Open a new issue in the [Workhorse tracker](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/new) describing precisely the new upload route:
   - The route's URL.
   - The [upload encoding](implementation.md#upload-encodings).
   - If possible, provide a dump of the upload request.
1. Implement and get the MR merged for this issue above.
1. Ask the Maintainers of [Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) to create a new release. You can do that in the MR
   directly during the maintainer review or ask for it in the `#workhorse` Slack channel.
1. Bump the [Workhorse version file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/GITLAB_WORKHORSE_VERSION)
   to the version you have from the previous points, or bump it in the same merge request that contains
   the Rails changes (see [Implementing the new route with a Rails controller](#implementing-the-new-route-with-a-rails-controller) or [Implementing the new route with a Grape API endpoint](#implementing-the-new-route-with-a-grape-api-endpoint) below).

## Implementing the new route with a Rails controller

For a Rails controller upload, we usually have a [multipart](implementation.md#upload-encodings) upload and there are a
few things to do:

1. The upload is available under the parameter name you're using. For example, it could be an `artifact`
   or a nested parameter such as `user[avatar]`. Let's say that we have the upload under the
   `file` parameter, reading `params[:file]` should get you an [`UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/uploaded_file.rb) instance.
1. Generally speaking, it's a good idea to check if the instance is from the [`UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/uploaded_file.rb) class. For example, see how we checked
[that the parameter is indeed an `UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/commit/ea30fe8a71bf16ba07f1050ab4820607b5658719#51c0cc7a17b7f12c32bc41cfab3649ff2739b0eb_79_77).

WARNING:
**Do not** call `UploadedFile#from_params` directly! Do not build an [`UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/uploaded_file.rb)
instance using `UploadedFile#from_params`! This method can be unsafe to use depending on the `params`
passed. Instead, use the [`UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/uploaded_file.rb)
instance that [`multipart.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/middleware/multipart.rb)
builds automatically for you.

## Implementing the new route with a Grape API endpoint

For a Grape API upload, we can have [body or a multipart](implementation.md#upload-encodings) upload. Things are slightly more complicated: two endpoints are needed. One for the
Workhorse pre-upload authorization and one for accepting the upload metadata from Workhorse:

1. Implement an endpoint with the URL + `/authorize` suffix that will:
   - Check that the request is coming from Workhorse with the `require_gitlab_workhorse!` from the [API helpers](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/helpers.rb).
   - Check user permissions.
   - Set the status to `200` with `status 200`.
   - Set the content type with `content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE`.
   - Use your dedicated `Uploader` class (let's say that it's `FileUploader`) to build the response with `FileUploader.workhorse_authorize(params)`.
1. Implement the endpoint for the upload request that will:
   - Require all the `UploadedFile` objects as parameters.
      - For example, if we expect a single parameter `file` to be an [`UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/uploaded_file.rb) instance,
use `requires :file, type: ::API::Validations::Types::WorkhorseFile`.
      - Body upload requests have their upload available under the parameter `file`.
   - Check that the request is coming from Workhorse with the `require_gitlab_workhorse!` from the
[API helpers](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/helpers.rb).
   - Check the user permissions.
   - The remaining code of the processing. This is where the code must be reading the parameter (for
our example, it would be `params[:file]`).

WARNING:
**Do not** call `UploadedFile#from_params` directly! Do not build an [`UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/uploaded_file.rb)
object using `UploadedFile#from_params`! This method can be unsafe to use depending on the `params`
passed. Instead, use the [`UploadedFile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/uploaded_file.rb)
object that [`multipart.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/middleware/multipart.rb)
builds automatically for you.

## Document Object Storage buckets and CarrierWave integration

When using Object Storage, GitLab expects each kind of upload to maintain its own bucket in the respective
Object Storage destination. Moreover, the integration with CarrierWave is not used all the time.
The [Object Storage Working Group](https://about.gitlab.com/company/team/structure/working-groups/object-storage/)
is investigating an approach that unifies Object Storage buckets into a single one and removes CarrierWave
so as to simplify implementation and administration of uploads.

Therefore, document new uploads here by slotting them into the following tables:

- [Feature bucket details](#feature-bucket-details)
- [CarrierWave integration](#carrierwave-integration)

### Feature bucket details

| Feature                                  | Upload technology | Uploader              | Bucket structure                                                                                          |
|------------------------------------------|-------------------|-----------------------|-----------------------------------------------------------------------------------------------------------|
| Job artifacts                            | `direct upload`     | `workhorse`             | `/artifacts/<proj_id_hash>/<date>/<job_id>/<artifact_id>`                                                 |
| Pipeline artifacts                       | `carrierwave`       | `sidekiq`               | `/artifacts/<proj_id_hash>/pipelines/<pipeline_id>/artifacts/<artifact_id>`                               |
| Live job traces                          | `fog`               | `sidekiq`               | `/artifacts/tmp/builds/<job_id>/chunks/<chunk_index>.log`                                                 |
| Job traces archive                       | `carrierwave`       | `sidekiq`               | `/artifacts/<proj_id_hash>/<date>/<job_id>/<artifact_id>/job.log`                                         |
| Autoscale runner caching                 | N/A               | `gitlab-runner`         | `/gitlab-com-[platform-]runners-cache/???`                                                                |
| Backups                                  | N/A               | `s3cmd`, `awscli`, or `gcs` | `/gitlab-backups/???`                                                                                     |
| Git LFS                                  | `direct upload`     | `workhorse`             | `/lsf-objects/<lfs_obj_oid[0:2]>/<lfs_obj_oid[2:2]>`                                                      |
| Design management files                  | `disk buffering`    | `rails controller`      | `/lsf-objects/<lfs_obj_oid[0:2]>/<lfs_obj_oid[2:2]>`                                                      |
| Design management thumbnails             | `carrierwave`       | `sidekiq`               | `/uploads/design_management/action/image_v432x230/<model_id>`                                             |
| Generic file uploads                     | `direct upload`     | `workhorse`             | `/uploads/@hashed/[0:2]/[2:4]/<hash1>/<hash2>/file`                                                       |
| Generic file uploads - personal snippets | `direct upload`     | `workhorse`             | `/uploads/personal_snippet/<snippet_id>/<filename>`                                                       |
| Global appearance settings               | `disk buffering`    | `rails controller`      | `/uploads/appearance/...`                                                                                 |
| Topics                                   | `disk buffering`    | `rails controller`      | `/uploads/projects/topic/...`                                                                             |
| Avatar images                            | `direct upload`     | `workhorse`             | `/uploads/[user,group,project]/avatar/<model_id>`                                                         |
| Import/export                            | `direct upload`     | `workhorse`             | `/uploads/import_export_upload/???`                                                                       |
| GitLab Migration                         | `carrierwave`       | `sidekiq`               | `/uploads/bulk_imports/???`                                                                               |
| MR diffs                                 | `carrierwave`       | `sidekiq`               | `/external-diffs/merge_request_diffs/mr-<mr_id>/diff-<diff_id>`                                           |
| Package manager archives                 | `direct upload`     | `sidekiq`               | `/packages/<proj_id_hash>/packages/<pkg_segment>/files/<pkg_file_id>`                                     |
| Package manager archives                 | `direct upload`     | `sidekiq`               | `/packages/<container_id_hash>/debian_*_component_file/<component_file_id>`                               |
| Package manager archives                 | `direct upload`     | `sidekiq`               | `/packages/<container_id_hash>/debian_*_distribution/<distribution_file_id>`                              |
| Container image cache (?)                | `direct upload`     | `workhorse`             | `/dependency-proxy/<group_id_hash>/dependency_proxy/<group_id>/files/<proxy_id>/<blob_id or manifest_id>` |
| Terraform state files                    | `carrierwave`       | `rails controller`      | `/terraform/<proj_id_hash>/<terraform_state_id>`                                                          |
| Pages content archives                   | `carrierwave`       | `sidekiq`               | `/gitlab-gprd-pages/<proj_id_hash>/pages_deployments/<deployment_id>/`                                    |
| Secure Files                             | `carrierwave`       | `sidekiq`               | `/ci-secure-files/<proj_id_hash>/secure_files/<secure_file_id>/`                                    |

### CarrierWave integration

| File                                                    | Carrierwave usage                                                                | Categorized         |
|---------------------------------------------------------|----------------------------------------------------------------------------------|---------------------|
| `app/models/project.rb`                                 | `include Avatarable`                                                             | :white_check_mark:  |
| `app/models/projects/topic.rb`                          | `include Avatarable`                                                             | :white_check_mark:  |
| `app/models/group.rb`                                   | `include Avatarable`                                                             | :white_check_mark:  |
| `app/models/user.rb`                                    | `include Avatarable`                                                             | :white_check_mark:  |
| `app/models/terraform/state_version.rb`                 | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/ci/job_artifact.rb`                         | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/ci/pipeline_artifact.rb`                    | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/pages_deployment.rb`                        | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/lfs_object.rb`                              | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/dependency_proxy/blob.rb`                   | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/dependency_proxy/manifest.rb`               | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/packages/composer/cache_file.rb`            | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/packages/package_file.rb`                   | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `app/models/concerns/packages/debian/component_file.rb` | `include FileStoreMounter`                                                       | :white_check_mark:  |
| `ee/app/models/issuable_metric_image.rb`                | `include FileStoreMounter`                                                       |                     |
| `ee/app/models/vulnerabilities/remediation.rb`          | `include FileStoreMounter`                                                       |                     |
| `ee/app/models/vulnerabilities/export.rb`               | `include FileStoreMounter`                                                       |                     |
| `app/models/packages/debian/project_distribution.rb`    | `include Packages::Debian::Distribution`                                         | :white_check_mark:  |
| `app/models/packages/debian/group_distribution.rb`      | `include Packages::Debian::Distribution`                                         | :white_check_mark:  |
| `app/models/packages/debian/project_component_file.rb`  | `include Packages::Debian::ComponentFile`                                        | :white_check_mark:  |
| `app/models/packages/debian/group_component_file.rb`    | `include Packages::Debian::ComponentFile`                                        | :white_check_mark:  |
| `app/models/merge_request_diff.rb`                      | `mount_uploader :external_diff, ExternalDiffUploader`                            | :white_check_mark:  |
| `app/models/note.rb`                                    | `mount_uploader :attachment, AttachmentUploader`                                 | :white_check_mark:  |
| `app/models/appearance.rb`                              | `mount_uploader :logo,         AttachmentUploader`                               | :white_check_mark:  |
| `app/models/appearance.rb`                              | `mount_uploader :header_logo,  AttachmentUploader`                               | :white_check_mark:  |
| `app/models/appearance.rb`                              | `mount_uploader :favicon,      FaviconUploader`                                  | :white_check_mark:  |
| `app/models/project.rb`                                 | `mount_uploader :bfg_object_map, AttachmentUploader`                             |                     |
| `app/models/import_export_upload.rb`                    | `mount_uploader :import_file, ImportExportUploader`                              | :white_check_mark:  |
| `app/models/import_export_upload.rb`                    | `mount_uploader :export_file, ImportExportUploader`                              | :white_check_mark:  |
| `app/models/ci/deleted_object.rb`                       | `mount_uploader :file, DeletedObjectUploader`                                    |                     |
| `app/models/design_management/action.rb`                | `mount_uploader :image_v432x230, DesignManagement::DesignV432x230Uploader`       | :white_check_mark:  |
| `app/models/concerns/packages/debian/distribution.rb`   | `mount_uploader :signed_file, Packages::Debian::DistributionReleaseFileUploader` | :white_check_mark:  |
| `app/models/bulk_imports/export_upload.rb`              | `mount_uploader :export_file, ExportUploader`                                    | :white_check_mark:  |
| `ee/app/models/user_permission_export_upload.rb`        | `mount_uploader :file, AttachmentUploader`                                       |                     |
| `app/models/ci/secure_file.rb`                          | `include FileStoreMounter`                                                       |                     |
