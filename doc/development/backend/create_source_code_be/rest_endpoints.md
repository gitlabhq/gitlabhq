---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Source Code REST endpoints

The Create :: Source Code team maintains these endpoints:

| Endpoint                                                                           | Threshold                             | Source                                                                               |
| -----------------------------------------------------------------------------------|---------------------------------------|--------------------------------------------------------------------------------------|
| `DELETE /api/:version/projects/:id/protected_branches/:name`                       | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/protected_branches.rb) |
| `GET /api/:version/internal/authorized_keys`                                       | `:high`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/base.rb) |            |         |
| `GET /api/:version/internal/lfs`                                                   | `:high`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/lfs.rb)|
| `GET /api/:version/projects/:id/approval_rules`                                    | `:low`                                |   |
| `GET /api/:version/projects/:id/approval_settings`                                 | default                               |   |
| `GET /api/:version/projects/:id/approvals`                                         | default                               |   |
| `GET /api/:version/projects/:id/forks`                                             | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/projects.rb) |
| `GET /api/:version/projects/:id/groups`                                            | default                               | [source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/projects.rb)  |
| `GET /api/:version/projects/:id/languages`                                         | `:medium`                             |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/projects.rb) |
| `GET /api/:version/projects/:id/merge_request_approval_setting`                    | `:medium`                             |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/merge_request_approval_settings.rb) |
| `GET /api/:version/projects/:id/merge_requests/:merge_request_iid/approval_rules`  | `:low`                                 |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/merge_request_approval_rules.rb) |
| `GET /api/:version/projects/:id/merge_requests/:merge_request_iid/approval_settings` | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/project_approval_settings.rb) |
| `GET /api/:version/projects/:id/merge_requests/:merge_request_iid/approval_state`  | `:low`                                | [source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/merge_request_approvals.rb) |
| `GET /api/:version/projects/:id/merge_requests/:merge_request_iid/approvals`       | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/merge_request_approvals.rb) |
| `GET /api/:version/projects/:id/protected_branches`                                | default                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/protected_branches.rb) |
| `GET /api/:version/projects/:id/protected_branches/:name`                          | default                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/protected_branches.rb) |
| `GET /api/:version/projects/:id/protected_tags`                                    | default                               |  |
| `GET /api/:version/projects/:id/protected_tags/:name`                              | default                               |  |
| `GET /api/:version/projects/:id/push_rule`                                         | default                               |   |
| `GET /api/:version/projects/:id/remote_mirrors`                                    | default                               |   |
| `GET /api/:version/projects/:id/repository/archive`                                | default                               |   |
| `GET /api/:version/projects/:id/repository/blobs/:sha`                             | default                               |   |
| `GET /api/:version/projects/:id/repository/blobs/:sha/raw`                         | default                               |    |
| `GET /api/:version/projects/:id/repository/branches`                               | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/branches.rb) |
| `GET /api/:version/projects/:id/repository/branches/:branch`                       | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/branches.rb) |
| `GET /api/:version/projects/:id/repository/commits`                                | `:low`                                 |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/commits.rb)|
| `GET /api/:version/projects/:id/repository/commits/:sha`                           | default                               | [source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/commits.rb) |
| `GET /api/:version/projects/:id/repository/commits/:sha/comments`                  | default                               | [source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/commits.rb) |
| `GET /api/:version/projects/:id/repository/commits/:sha/diff`                      | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/commits.rb) |
| `GET /api/:version/projects/:id/repository/commits/:sha/merge_requests`            | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/commits.rb)|
| `GET /api/:version/projects/:id/repository/commits/:sha/refs`                      | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/commits.rb) |
| `GET /api/:version/projects/:id/repository/compare`                                | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/repositories.rb) |
| `GET /api/:version/projects/:id/repository/contributors`                           | default                               |   |
| `GET /api/:version/projects/:id/repository/files/:file_path`                       | default                               |   |
| `GET /api/:version/projects/:id/repository/files/:file_path/raw`                   | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/files.rb) |
| `GET /api/:version/projects/:id/repository/tags`                                   | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/tags.rb) |
| `GET /api/:version/projects/:id/repository/tree`                                   | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/repositories.rb) |
| `GET /api/:version/projects/:id/statistics`                                        | default                               |    |
| `GraphqlController#execute`                                                        | default                               |    |
| `HEAD /api/:version/projects/:id/repository/files/:file_path`                      | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/files.rb) |
| `HEAD /api/:version/projects/:id/repository/files/:file_path/raw`                  | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/files.rb) |
| `POST /api/:version/internal/allowed`                                              | default                               | [source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/base.rb)  |
| `POST /api/:version/internal/lfs_authenticate`                                     | `:high`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/base.rb) |
| `POST /api/:version/internal/post_receive`                                         | default                               | [source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/base.rb)  |
| `POST /api/:version/internal/pre_receive`                                          | `:high`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/base.rb) |
| `POST /api/:version/projects/:id/approvals`                                        | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/project_approvals.rb) |
| `POST /api/:version/projects/:id/merge_requests/:merge_request_iid/approvals`      | `:low`                                | [source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/merge_request_approvals.rb) |
| `POST /api/:version/projects/:id/merge_requests/:merge_request_iid/approve`        | `:low`                                 |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/merge_request_approvals.rb) |
| `POST /api/:version/projects/:id/merge_requests/:merge_request_iid/unapprove`      | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/merge_request_approvals.rb)|
| `POST /api/:version/projects/:id/protected_branches`                               | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/protected_branches.rb)|
| `POST /api/:version/projects/:id/repository/commits`                               | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/commits.rb)|
| `POST /api/:version/projects/:id/repository/files/:file_path`                      | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/files.rb) |
| `PUT /api/:version/projects/:id/push_rule`                                         | default                               |   |
| `PUT /api/:version/projects/:id/repository/files/:file_path`                       | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/files.rb) |
| `Projects::BlameController#show`                                                   | `:low`                                 |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/blame_controller.rb) |
| `Projects::BlobController#create`                                                  | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/blob_controller.rb)  |
| `Projects::BlobController#diff`                                                    | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/blob_controller.rb) |
| `Projects::BlobController#edit`                                                    | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/blob_controller.rb)  |
| `Projects::BlobController#show`                                                    | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/blob_controller.rb)  |
| `Projects::BlobController#update`                                                  | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/blob_controller.rb)  |
| `Projects::BranchesController#create`                                              | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/branches_controller.rb) |
| `Projects::BranchesController#destroy`                                             | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/branches_controller.rb) |
| `Projects::BranchesController#diverging_commit_counts`                             | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/branches_controller.rb) |
| `Projects::BranchesController#index`                                               | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/branches_controller.rb) |
| `Projects::BranchesController#new`                                                 | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/branches_controller.rb) |
| `Projects::CommitController#branches`                                              | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/commit_controller.rb) |
| `Projects::CommitController#merge_requests`                                        | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/commit_controller.rb) |
| `Projects::CommitController#pipelines`                                             | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/commit_controller.rb) |
| `Projects::CommitController#show`                                                  | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/commit_controller.rb) |
| `Projects::CommitsController#show`                                                 | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/commits_controller.rb)|
| `Projects::CommitsController#signatures`                                           | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/commits_controller.rb) |
| `Projects::CompareController#create`                                               | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/commits_controller.rb) |
| `Projects::CompareController#index`                                                | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/compare_controller.rb) |
| `Projects::CompareController#show`                                                 | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/compare_controller.rb) |
| `Projects::CompareController#signatures`                                           | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/compare_controller.rb) |
| `Projects::FindFileController#list`                                                | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/find_file_controller.rb) |
| `Projects::FindFileController#show`                                                | `:low`                                 |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/find_file_controller.rb) |
| `Projects::ForksController#index`                                                  | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/forks_controller.rb) |
| `Projects::GraphsController#show`                                                  | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/graphs_controller.rb) |
| `Projects::NetworkController#show`                                                 | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/network_controller.rb) |
| `Projects::PathLocksController#index`                                              | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/controllers/projects/path_locks_controller.rb) |
| `Projects::RawController#show`                                                     | default                               |   |
| `Projects::RefsController#logs_tree`                                               | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/refs_controller.rb) |
| `Projects::RefsController#switch`                                                  | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/refs_controller.rb) |
| `Projects::RepositoriesController#archive`                                         | default                               |   |
| `Projects::Settings::RepositoryController#show`                                    | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/settings/repository_controller.rb) |
| `Projects::TagsController#index`                                                   | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/tags_controller.rb) |
| `Projects::TagsController#new`                                                     | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/tags_controller.rb) |
| `Projects::TagsController#show`                                                    | `:low`                               |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/tags_controller.rb) |
| `Projects::TemplatesController#names`                                              | `:low`                                 |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/templates_controller.rb) |
| `Projects::TreeController#show`                                                    | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/tree_controller.rb) |
| `ProjectsController#refs`                                                          | `:low`                                 |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects_controller.rb) |
| `Repositories::GitHttpController#git_receive_pack`                                 | default                               |   |
| `Repositories::GitHttpController#git_upload_pack`                                  | default                               |   |
| `Repositories::GitHttpController#info_refs`                                        | default                               |   |
| `Repositories::LfsApiController#batch`                                             | `:medium`                             |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/repositories/lfs_api_controller.rb) |
| `Repositories::LfsLocksApiController#verify`                                       | default                               |   |
| `Repositories::LfsStorageController#download`                                      | `:medium`                             |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/repositories/lfs_storage_controller.rb) |
| `Repositories::LfsStorageController#upload_authorize`                              | `:medium`                             |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/repositories/lfs_storage_controller.rb) |
| `Repositories::LfsStorageController#upload_finalize`                               | `:low`                                |[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/repositories/lfs_storage_controller.rb) |
