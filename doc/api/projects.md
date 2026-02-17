---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: REST API to create, retrieve, update, delete, and manage projects and project features.
title: Projects API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage GitLab projects and their associated settings. A project is a central hub for
collaboration where you store code, track issues, and organize team activities.
For more information, see [create a project](../user/project/_index.md).

The Projects API contains endpoints that:

- Retrieve project information and metadata
- Create, edit, and remove projects
- Control project visibility, access permissions, and security settings
- Manage project features like issue tracking, merge requests, and CI/CD
- Archive and unarchive projects
- Transfer projects between namespaces
- Manage deployment and container registry settings

## Prerequisites

- Any [default role](../user/permissions.md#roles) on a project to read the project's properties.
- The Owner or Maintainer role on a project to edit the project's properties.

## Project visibility level

A project in GitLab can have a visibility level of either:

- Private
- Internal
- Public

The visibility level is determined by the `visibility` field in the project.

For more information, see [Project visibility](../user/public_access.md).

The fields returned in responses vary based on the [permissions](../user/permissions.md) of the authenticated user.

## Project feature visibility level

You can control the availability of project settings when you create or edit a project.
For example, to disable `forking_access_level` for an existing project:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"forking_access_level": "disabled"}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

Each setting can be defined independently and accepts the following values:

- `disabled`: Disable the feature.
- `private`: Enable and set the feature to **Only project members**.
- `enabled`: Enable and set the feature to **Everyone with access**.
- `public`: Enable and set the feature to **Everyone**. Available only for `pages_access_level`.

For more information, see [Change the visibility of individual features in a project](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project).

| Attribute                              | Type   | Required | Description |
|:---------------------------------------|:-------|:---------|:------------|
| `analytics_access_level`               | string | No       | Set visibility of [analytics](../user/analytics/_index.md). |
| `builds_access_level`                  | string | No       | Set visibility of [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | No       | Set visibility of [container registry](../user/packages/container_registry/_index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | No       | Set visibility of [environments](../ci/environments/_index.md). |
| `feature_flags_access_level`           | string | No       | Set visibility of [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | No       | Set visibility of [forks](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | No       | Set visibility of [infrastructure management](../user/infrastructure/_index.md). |
| `issues_access_level`                  | string | No       | Set visibility of [issues](../user/project/issues/_index.md). |
| `merge_requests_access_level`          | string | No       | Set visibility of [merge requests](../user/project/merge_requests/_index.md). |
| `model_experiments_access_level`       | string | No       | Set visibility of [machine learning model experiments](../user/project/ml/experiment_tracking/_index.md). |
| `model_registry_access_level`          | string | No       | Set visibility of [machine learning model registry](../user/project/ml/model_registry/_index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | No       | Set visibility of [application performance monitoring](../operations/_index.md). |
| `pages_access_level`                   | string | No       | Set visibility of [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | No       | Set visibility of [releases](../user/project/releases/_index.md). |
| `repository_access_level`              | string | No       | Set visibility of [repository](../user/project/repository/_index.md). |
| `requirements_access_level`            | string | No       | Set visibility of [requirements management](../user/project/requirements/_index.md). |
| `security_and_compliance_access_level` | string | No       | Set visibility of [security and compliance](../user/application_security/_index.md). |
| `snippets_access_level`                | string | No       | Set visibility of [snippets](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | No       | Set visibility of [wiki](../user/project/wiki/_index.md#enable-or-disable-a-project-wiki). |

## Deprecated attributes

These attributes are deprecated and could be removed in a future version of the REST API.
Use the alternative attributes instead.

| Deprecated attribute     | Alternative |
|:-------------------------|:------------|
| `tag_list`               | Use `topics` instead. |
| `marked_for_deletion_at` | Use `marked_for_deletion_on` instead. Premium and Ultimate only. |
| `approvals_before_merge` | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/work_items/353097) in GitLab 16.0. Use the [Merge request approvals API](merge_request_approvals.md) instead. Premium and Ultimate only. |
| `packages_enabled` | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/work_items/454759) in GitLab 17.10. Use `package_registry_access_level` instead. |
| `container_registry_enabled` | Use `container_registry_access_level` instead. |
| `public_builds` | Use `public_jobs` instead. |
| `emails_disabled` | Use `emails_enabled` instead. |
| `issues_enabled` | Use `issues_access_level` instead. |
| `jobs_enabled` | Use `builds_access_level` instead. |
| `merge_requests_enabled` | Use `merge_request_access_level` instead. |
| `snippets_enabled` | Use `snippets_access_level` instead. |
| `wiki_enabled` | Use `wiki_access_level` instead. |
| `restrict_user_defined_variables` | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510) in GitLab 17.7. Use `ci_pipeline_variables_minimum_override_role` instead. |

## Retrieve a project

Retrieves the specified project. This endpoint can be accessed without authentication if
the project is publicly accessible.

```plaintext
GET /projects/:id
```

Supported attributes:

| Attribute                | Type              | Required | Description |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `license`                | boolean           | No       | Include project license data. |
| `statistics`             | boolean           | No       | Include project statistics. Available only to users with the Reporter, Developer, Maintainer, or Owner role. |
| `with_custom_attributes` | boolean           | No       | Include [custom attributes](custom_attributes.md) in response. Administrator access. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

<!-- markdownlint-disable MD055 -->
<!-- markdownlint-disable MD056 -->

| Attribute                | Type              | Description |
|:-------------------------|:------------------|:------------|
| `id` | integer | ID of the project. |
| `description` | string | Description of the project. |
| `description_html` | string | Description of the project in HTML format. |
| `name` | string | Name of the project. |
| `name_with_namespace` | string | Name of the project with its namespace. |
| `path` | string | Path of the project. |
| `path_with_namespace` | string | Path of the project with its namespace. |
| `created_at` | datetime | Timestamp when the project was created. |
| `default_branch` | string | Default branch of the project. |
| `tag_list` | array of strings | Deprecated. Use `topics` instead. List of tags for the project. |
| `topics` | array of strings | List of topics for the project. |
| `ssh_url_to_repo` | string | SSH URL to clone the repository. |
| `http_url_to_repo` | string | HTTP URL to clone the repository. |
| `web_url` | string | URL to access the project in a browser. |
| `readme_url` | string | URL to the project's README file. |
| `forks_count` | integer | Number of forks of the project. |
| `avatar_url` | string | URL to the project's avatar image. |
| `star_count` | integer | Number of stars the project has received. |
| `last_activity_at` | datetime | Timestamp of the last activity in the project. |
| `visibility` | string | Visibility level of the project. Possible values: `private`, `internal`, or `public`. |
| `namespace` | object | Namespace information for the project. |
| `namespace.id` | integer | ID of the namespace. |
| `namespace.name` | string | Name of the namespace. |
| `namespace.path` | string | Path of the namespace. |
| `namespace.kind` | string | Type of namespace. Possible values: `user` or `group`. |
| `namespace.full_path` | string | Full path of the namespace. |
| `namespace.parent_id` | integer | ID of the parent namespace, if applicable. |
| `namespace.avatar_url` | string | URL to the namespace's avatar image. |
| `namespace.web_url` | string | URL to access the namespace in a browser. |
| `container_registry_image_prefix` | string | Prefix for container registry images. |
| `_links` | object | Collection of API endpoint links related to the project. |
| `_links.self` | string | URL to the project resource. |
| `_links.issues` | string | URL to the project's issues. |
| `_links.merge_requests` | string | URL to the project's merge requests. |
| `_links.repo_branches` | string | URL to the project's repository branches. |
| `_links.labels` | string | URL to the project's labels. |
| `_links.events` | string | URL to the project's events. |
| `_links.members` | string | URL to the project's members. |
| `_links.cluster_agents` | string | URL to the project's cluster agents. |
| `marked_for_deletion_at` | date | Deprecated. Use `marked_for_deletion_on` instead. Date when the project is scheduled for deletion. |
| `marked_for_deletion_on` | date | Date when the project is scheduled for deletion. |
| `packages_enabled` | boolean | Whether the package registry is enabled for the project. |
| `empty_repo` | boolean | Whether the repository is empty. |
| `archived` | boolean | Whether the project is archived. |
| `owner` | object | Information about the project owner. |
| `owner.id` | integer | ID of the project Owner. |
| `owner.username` | string | Username of the owner. |
| `owner.public_email` | string | Public email address of the owner. |
| `owner.name` | string | Name of the project Owner. |
| `owner.state` | string | Current state of the owner account. |
| `owner.locked` | boolean | Indicates if the owner account is locked. |
| `owner.avatar_url` | string | URL to the owner's avatar image. |
| `owner.web_url` | string | Web URL for the owner's profile. |
| `owner.created_at` | datetime | Timestamp when the Owner was created. |
| `resolve_outdated_diff_discussions` | boolean | Whether outdated diff discussions are automatically resolved. |
| `container_expiration_policy` | object | Settings for container image expiration policy. |
| `container_expiration_policy.cadence` | string | How often the container expiration policy runs. |
| `container_expiration_policy.enabled` | boolean | Whether the container expiration policy is enabled. |
| `container_expiration_policy.keep_n` | integer | Number of container images to keep. |
| `container_expiration_policy.older_than` | string | Remove container images older than this value. |
| `container_expiration_policy.name_regex` | string | Deprecated. Use `name_regex_delete` instead. Regular expression to match container image names. |
| `container_expiration_policy.name_regex_delete` | string | Regular expression to match container image names to delete. |
| `container_expiration_policy.name_regex_keep` | string | Regular expression to match container image names to keep. |
| `container_expiration_policy.next_run_at` | datetime | Timestamp for the next scheduled policy run. |
| `repository_object_format` | string | Object format used by the repository. Possible values: `sha1` or `sha256`. |
| `issues_enabled` | boolean | Whether issues are enabled for the project. |
| `merge_requests_enabled` | boolean | Whether merge requests are enabled for the project. |
| `wiki_enabled` | boolean | Whether the wiki is enabled for the project. |
| `jobs_enabled` | boolean | Whether jobs are enabled for the project. |
| `snippets_enabled` | boolean | Whether snippets are enabled for the project. |
| `container_registry_enabled` | boolean | Deprecated. Use `container_registry_access_level` instead. Whether the container registry is enabled. |
| `service_desk_enabled` | boolean | Whether Service Desk is enabled for the project. |
| `service_desk_address` | string | Email address for the Service Desk. |
| `can_create_merge_request_in` | boolean | Whether the current user can create merge requests in the project. |
| `issues_access_level` | string | Access level for the issues feature. Possible values: `disabled`, `private`, or `enabled`. |
| `repository_access_level` | string | Access level for the repository feature. Possible values: `disabled`, `private`, or `enabled`. |
| `merge_requests_access_level` | string | Access level for the merge requests feature. Possible values: `disabled`, `private`, or `enabled`. |
| `forking_access_level` | string | Access level for forking the project. Possible values: `disabled`, `private`, or `enabled`. |
| `wiki_access_level` | string | Access level for the wiki feature. Possible values: `disabled`, `private`, or `enabled`. |
| `builds_access_level` | string | Access level for the CI/CD builds feature. Possible values: `disabled`, `private`, or `enabled`. |
| `snippets_access_level` | string | Access level for the snippets feature. Possible values: `disabled`, `private`, or `enabled`. |
| `pages_access_level` | string | Access level for GitLab Pages. Possible values: `disabled`, `private`, `enabled`, or `public`. |
| `analytics_access_level` | string | Access level for analytics features. Possible values: `disabled`, `private`, or `enabled`. |
| `container_registry_access_level` | string | Access level for the container registry. Possible values: `disabled`, `private`, or `enabled`. |
| `security_and_compliance_access_level` | string | Access level for security and compliance features. Possible values: `disabled`, `private`, or `enabled`. |
| `releases_access_level` | string | Access level for the releases feature. Possible values: `disabled`, `private`, or `enabled`. |
| `environments_access_level` | string | Access level for the environments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `feature_flags_access_level` | string | Access level for the feature flags feature. Possible values: `disabled`, `private`, or `enabled`. |
| `infrastructure_access_level` | string | Access level for the infrastructure feature. Possible values: `disabled`, `private`, or `enabled`. |
| `monitor_access_level` | string | Access level for the monitor feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_experiments_access_level` | string | Access level for the model experiments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_registry_access_level` | string | Access level for the model registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `package_registry_access_level` | string | Access level for the package registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `emails_disabled` | boolean | Indicates if emails are disabled for the project. |
| `emails_enabled` | boolean | Indicates if emails are enabled for the project. |
| `show_diff_preview_in_email` | boolean | Indicates if diff previews are shown in email notifications. |
| `shared_runners_enabled` | boolean | Whether shared runners are enabled for the project. |
| `lfs_enabled` | boolean | Indicates if Git LFS is enabled for the project. |
| `creator_id` | integer | ID of the user who created the project. |
| `import_url` | string | URL the project was imported from. |
| `import_type` | string | Type of import used for the project. |
| `import_status` | string | Status of the project import. |
| `import_error` | string | Error message if the import failed. |
| `open_issues_count` | integer | Number of open issues. |
| `updated_at` | datetime | Timestamp when the project was last updated. |
| `ci_default_git_depth` | integer | Default Git depth for CI/CD pipelines. Only visible if you have administrator access or the Owner role for the project. |
| `ci_delete_pipelines_in_seconds` | integer | Time in seconds before old pipelines are deleted. |
| `ci_forward_deployment_enabled` | boolean | Whether forward deployment is enabled. Only visible if you have administrator access or the Owner role for the project. |
| `ci_forward_deployment_rollback_allowed` | boolean | Whether rollback is allowed for forward deployments. |
| `ci_job_token_scope_enabled` | boolean | Indicates if CI/CD job token scope is enabled. Only visible if you have administrator access or the Owner role for the project. |
| `ci_separated_caches` | boolean | Whether CI/CD caches are separated by branch. Only visible if you have administrator access or the Owner role for the project. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean | Whether fork pipelines can run in the parent project. Only visible if you have administrator access or the Owner role for the project. |
| `ci_id_token_sub_claim_components` | array of strings | Components included in the CI/CD ID token subject claim. |
| `build_git_strategy` | string | Git strategy used for CI/CD builds (fetch or clone). Only visible if you have administrator access or the Owner role for the project. |
| `keep_latest_artifact` | boolean | Indicates if the latest artifact is kept when a new one is created. Only visible if you have administrator access or the Owner role for the project. |
| `restrict_user_defined_variables` | boolean | Whether user-defined variables are restricted. Only visible if you have administrator access or the Owner role for the project. |
| `ci_pipeline_variables_minimum_override_role` | string | Minimum role required to override pipeline variables. |
| `runner_token_expiration_interval` | integer | Expiration interval in seconds for runner tokens. Only visible if you have administrator access or the Owner role for the project. |
| `group_runners_enabled` | boolean | Whether group runners are enabled for the project. Only visible if you have administrator access or the Owner role for the project. |
| `resource_group_default_process_mode` | string | Default process mode for resource groups. |
| `auto_cancel_pending_pipelines` | string | Setting for automatically canceling pending pipelines. Only visible if you have administrator access or the Owner role for the project. |
| `build_timeout` | integer | Timeout in seconds for CI/CD jobs. Only visible if you have administrator access or the Owner role for the project. |
| `auto_devops_enabled` | boolean | Whether Auto DevOps is enabled for the project. Only visible if you have administrator access or the Owner role for the project. |
| `auto_devops_deploy_strategy` | string | Deployment strategy for Auto DevOps. Only visible if you have administrator access or the Owner role for the project. |
| `ci_push_repository_for_job_token_allowed` | boolean | Whether pushing to the repository is allowed using a job token. |
| `runners_token` | string | Token for registering runners with the project. Only visible if you have administrator access or the Owner role for the project. |
| `ci_config_path` | string | Path to the CI/CD configuration file. |
| `public_jobs` | boolean | Whether job logs are publicly accessible. |
| `shared_with_groups` | array of objects | List of groups the project is shared with. |
| `shared_with_groups[].group_id` | integer | ID of the group the project is shared with. |
| `shared_with_groups[].group_name` | string | Name of the group the project is shared with. |
| `shared_with_groups[].group_full_path` | string | Full path of the group the project is shared with. |
| `shared_with_groups[].group_access_level` | integer | Access level granted to the group. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Whether merges are allowed only if the pipeline succeeds. |
| `allow_merge_on_skipped_pipeline` | boolean | Whether merges are allowed when the pipeline is skipped. |
| `request_access_enabled` | boolean | Whether users can request access to the project. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Whether merges are allowed only if all discussions are resolved. |
| `remove_source_branch_after_merge` | boolean | Whether the source branch is automatically removed after merge. |
| `printing_merge_request_link_enabled` | boolean | Indicates if merge request links are printed after pushing. |
| `printing_merge_requests_link_enabled` | boolean | Whether the merge request link is printed after a push. |
| `merge_method` | string | Merge method used for the project. Possible values: `merge`, `rebase_merge`, or `ff`. |
| `merge_request_title_regex` | string | Regex pattern for validating merge request titles. |
| `merge_request_title_regex_description` | string | Description of the merge request title regex validation. |
| `squash_option` | string | Squash option for merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Whether authentication checks are enforced on uploads. |
| `suggestion_commit_message` | string | Custom commit message for suggestions. |
| `merge_commit_template` | string | Template for merge commit messages. |
| `squash_commit_template` | string | Template for squash commit messages. |
| `issue_branch_template` | string | Template for branch names created from issues. |
| `warn_about_potentially_unwanted_characters` | boolean | Whether to warn about potentially unwanted characters. |
| `autoclose_referenced_issues` | boolean | Whether referenced issues are automatically closed. |
| `max_artifacts_size` | integer | Maximum size in MB for CI/CD artifacts. |
| `approvals_before_merge` | integer | Deprecated. Use merge request approvals API instead. Number of approvals required before merge. |
| `mirror` | boolean | Whether the project is a mirror. |
| `external_authorization_classification_label` | string | External authorization classification label. |
| `requirements_enabled` | boolean | Indicates if requirements management is enabled. |
| `requirements_access_level` | string | Access level for the requirements feature. |
| `security_and_compliance_enabled` | boolean | Indicates if security and compliance features are enabled. |
| `secret_push_protection_enabled` | boolean | Whether secret push protection is enabled. |
| `pre_receive_secret_detection_enabled` | boolean | Indicates if pre-receive secret detection is enabled. |
| `compliance_frameworks` | array of strings | Compliance frameworks applied to the project. |
| `issues_template` | string | Default description for issues. Description is parsed with GitLab Flavored Markdown. Premium and Ultimate only. |
| `merge_requests_template` | string | Template for merge request descriptions. Premium and Ultimate only. |
| `ci_restrict_pipeline_cancellation_role` | string | Minimum role required to cancel pipelines. |
| `merge_pipelines_enabled` | boolean | Indicates if merge pipelines are enabled. |
| `merge_trains_enabled` | boolean | Indicates if merge trains are enabled. |
| `merge_trains_skip_train_allowed` | boolean | Indicates if skipping the merge train is allowed. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Whether merges are allowed only if all status checks have passed. Ultimate only. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Whether pipeline triggers can approve deployments. |
| `prevent_merge_without_jira_issue` | boolean | Indicates if merges require an associated Jira issue. |
| `duo_remote_flows_enabled` | boolean | Indicates if GitLab Duo remote flows are enabled. |
| `duo_foundational_flows_enabled` | boolean | Indicates if GitLab Duo foundational flows are enabled. |
| `duo_sast_fp_detection_enabled` | boolean | Indicates if GitLab Duo SAST false positive detection is enabled. |
| `web_based_commit_signing_enabled` | boolean | Indicates if web-based commit signing is enabled. |
| `spp_repository_pipeline_access` | boolean | Repository pipeline access for security policies. Only visible if the security orchestration policies feature is available. |
| `permissions` | object | User permissions for the project. |
| `permissions.project_access` | object | Project-level access permissions for the user. |
| `permissions.project_access.access_level` | integer | Access level for the project. |
| `permissions.project_access.notification_level` | integer | Notification level for the project. |
| `permissions.group_access` | object | Group-level access permissions for the user. |
| `permissions.group_access.access_level` | integer | Access level for the group. |
| `permissions.group_access.notification_level` | integer | Notification level for the group. |
| `license_url` | string | URL to the project's license file. |
| `license.key` | string | Key identifier for the license. |
| `license.name` | string | Full name of the license. |
| `license.nickname` | string | Nickname of the license. |
| `license.html_url` | string | URL to view the license details. |
| `license.source_url` | string | URL to the license source text. |
| `repository_storage` | string | Storage location for the project's repository. |
| `mirror_user_id` | integer | ID of the user who set up the mirror. |
| `mirror_trigger_builds` | boolean | Whether mirror updates trigger builds. |
| `only_mirror_protected_branches` | boolean | Whether only protected branches are mirrored. |
| `mirror_overwrites_diverged_branches` | boolean | Whether the mirror overwrites diverged branches. |
| `statistics.commit_count` | integer | Number of commits in the project. |
| `statistics.storage_size` | integer | Total storage size in bytes. |
| `statistics.repository_size` | integer | Repository storage size in bytes. |
| `statistics.wiki_size` | integer | Wiki storage size in bytes. |
| `statistics.lfs_objects_size` | integer | LFS objects storage size in bytes. |
| `statistics.job_artifacts_size` | integer | Job artifacts storage size in bytes. |
| `statistics.pipeline_artifacts_size` | integer | Pipeline artifacts storage size in bytes. |
| `statistics.packages_size` | integer | Packages storage size in bytes. |
| `statistics.snippets_size` | integer | Snippets storage size in bytes. |
| `statistics.uploads_size` | integer | Uploads storage size in bytes. |
| `statistics.container_registry_size` | integer | Container registry storage size in bytes. <sup>1</sup> |
| `forked_from_project` | object | The upstream project this project was forked from. If the upstream project is private, an authentication token is required to view this field. |
| `mr_default_target_self` | boolean | Whether merge requests target this project by default. If `false`, merge requests target the upstream project. Appears only if the project is a fork. |
{.condensed}
<!-- markdownlint-enable MD055 -->
<!-- markdownlint-enable MD056 -->

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null, // to be deprecated in GitLab 13.0 in favor of `name_regex_delete`
    "name_regex_delete": null,
    "name_regex_keep": null,
    "next_run_at": "2020-01-07T21:42:58.658Z"
  },
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/3/foo.jpg",
    "web_url": "http://localhost:3000/groups/diaspora"
  },
  "import_url": null,
  "import_type": null,
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "public_jobs": true,
  "shared_with_groups": [
    {
      "group_id": 4,
      "group_name": "Twitter",
      "group_full_path": "twitter",
      "group_access_level": 30
    },
    {
      "group_id": 3,
      "group_name": "Gitlab Org",
      "group_full_path": "gitlab-org",
      "group_access_level": 10
    }
  ],
  "repository_storage": "default",
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "printing_merge_requests_link_enabled": true,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "mirror_user_id": 45,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": false,
  "mirror_overwrites_diverged_branches": false,
  "external_authorization_classification_label": null,
  "packages_enabled": true,
  "empty_repo": false,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "autoclose_referenced_issues": true,
  "suggestion_commit_message": null,
  "enforce_auth_checks_on_uploads": true,
  "merge_commit_template": null,
  "squash_commit_template": null,
  "issue_branch_template": "gitlab/%{id}-%{title}",
  "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false,
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0,
    "container_registry_size": 0
  },
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  },
  "spp_repository_pipeline_access": false // Only visible if the security_orchestration_policies feature is available
}
```

## List projects

List projects and project attributes.

### List all projects

{{< history >}}

- `web_based_commit_signing_enabled` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194650) in GitLab 18.2 [with a flag](../administration/feature_flags/_index.md) named `use_web_based_commit_signing_enabled`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of the `web_based_commit_signing_enabled` attribute is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Lists all projects on the instance accessible to the authenticated user. Unauthenticated requests return only public projects with a limited subset of attributes.

You can filter responses by [custom attributes](custom_attributes.md).

This endpoint supports pagination:

- Use offset-based pagination to access up to 50,000 projects.
- Use keyset-based pagination to list more than 50,000 projects.

For more information, see [Pagination](rest/_index.md#pagination).

```plaintext
GET /projects
```

Supported attributes:
<!-- markdownlint-disable MD055 -->
<!-- markdownlint-disable MD056 -->

| Attribute                     | Type     | Required | Description |
|:------------------------------|:---------|:---------|:------------|
| `archived`                    | boolean  | No       | Limit by archived status. |
| `id_after`                    | integer  | No       | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                   | integer  | No       | Limit results to projects with IDs less than the specified ID. |
| `imported`                    | boolean  | No       | Limit results to projects which were imported from external systems by current user. |
| `include_hidden`              | boolean  | No       | Include hidden projects. _(administrators only)_ Premium and Ultimate only. |
| `include_pending_delete`      | boolean  | No       | Include projects pending deletion. _(administrators only)_ |
| `last_activity_after`         | datetime | No       | Limit results to projects with last activity after specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `last_activity_before`        | datetime | No       | Limit results to projects with last activity before specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `membership`                  | boolean  | No       | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer  | No       | Limit to projects where the current user has at least the specified access level. Possible values: `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner). |
| `order_by`                    | string   | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, `last_activity_at`, or `similarity` fields. `repository_size`, `storage_size`, `packages_size` or `wiki_size` fields are only allowed for administrators. `similarity` is only available when searching and is limited to projects that the current user is a member of. Default is `created_at`. |
| `owned`                       | boolean  | No       | Limit by projects explicitly owned by the current user. |
| `repository_checksum_failed`  | boolean  | No       | Limit projects where the repository checksum calculation has failed. Premium and Ultimate only. |
| `repository_storage`          | string   | No       | Limit results to projects stored on `repository_storage`. _(administrators only)_ |
| `search_namespaces`           | boolean  | No       | Include ancestor namespaces when matching search criteria. Default is `false`. |
| `search`                      | string   | No       | Return list of projects with a `path`, `name`, or `description` matching the search criteria (case-insensitive, substring match). Multiple terms can be provided, separated by an escaped space, either `+` or `%20`, and will be ANDed together. Example: `one+two` will match substrings `one` and `two` (in any order). |
| `simple`                      | boolean  | No       | If `true`, return only limited fields for each project. Unauthenticated requests return only public projects with limited fields, even if `simple` is not set. |
| `sort`                        | string   | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean  | No       | Limit by projects starred by the current user. |
| `statistics`                  | boolean  | No       | Include project statistics. Available only to users with the Reporter, Developer, Maintainer, or Owner role. |
| `topic_id`                    | integer  | No       | Limit results to projects with the assigned topic given by the topic ID. |
| `topic`                       | string   | No       | Comma-separated topic names. Limit results to projects that match all of given topics. See `topics` attribute. |
| `updated_after`               | datetime | No       | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |
| `updated_before`              | datetime | No       | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |
| `visibility`                  | string   | No       | Limit by visibility `public`, `internal`, or `private`. |
| `wiki_checksum_failed`        | boolean  | No       | Limit projects where the wiki checksum calculation has failed. Premium and Ultimate only. |
| `with_custom_attributes`      | boolean  | No       | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`         | boolean  | No       | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean  | No       | Limit by enabled merge requests feature. |
| `with_programming_language`   | string   | No       | Limit by projects which use the given programming language. |
| `marked_for_deletion_on`      | date     | No       | Filter by date when project was marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463939) in GitLab 17.1. Premium and Ultimate only. |
| `active`                      | boolean  | No       | Limit by projects that are not archived and not marked for deletion. |
{.condensed}
<!-- markdownlint-enable MD055 -->
<!-- markdownlint-enable MD056 -->

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

<!-- markdownlint-disable MD055 -->
<!-- markdownlint-disable MD056 -->

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | integer | ID of the project. |
| `description` | string | Description of the project. |
| `name` | string | Name of the project. |
| `name_with_namespace` | string | Name of the project with its namespace. |
| `path` | string | Path of the project. |
| `path_with_namespace` | string | Path of the project with its namespace. |
| `created_at` | datetime | Timestamp when the project was created. |
| `default_branch` | string | Default branch of the project. |
| `tag_list` | array of strings | Deprecated. Use `topics` instead. List of tags for the project. |
| `topics` | array of strings | List of topics for the project. |
| `ssh_url_to_repo` | string | SSH URL to clone the repository. |
| `http_url_to_repo` | string | HTTP URL to clone the repository. |
| `web_url` | string | URL to access the project in a browser. |
| `readme_url` | string | URL to the project's README file. |
| `forks_count` | integer | Number of forks of the project. |
| `avatar_url` | string | URL to the project's avatar image. |
| `star_count` | integer | Number of stars the project has received. |
| `last_activity_at` | datetime | Timestamp of the last activity in the project. |
| `visibility` | string | Visibility level of the project. Possible values: `private`, `internal`, or `public`. |
| `namespace` | object | Namespace information for the project. |
| `namespace.id` | integer | ID of the namespace. |
| `namespace.name` | string | Name of the namespace. |
| `namespace.path` | string | Path of the namespace. |
| `namespace.kind` | string | Type of namespace. Possible values: `user` or `group`. |
| `namespace.full_path` | string | Full path of the namespace. |
| `namespace.parent_id` | integer | ID of the parent namespace, if applicable. |
| `namespace.avatar_url` | string | URL to the namespace's avatar image. |
| `namespace.web_url` | string | URL to access the namespace in a browser. |
| `container_registry_image_prefix` | string | Prefix for container registry images. |
| `_links` | object | Collection of API endpoint links related to the project. |
| `_links.self` | string | URL to the project resource. |
| `_links.issues` | string | URL to the project's issues. |
| `_links.merge_requests` | string | URL to the project's merge requests. |
| `_links.repo_branches` | string | URL to the project's repository branches. |
| `_links.labels` | string | URL to the project's labels. |
| `_links.events` | string | URL to the project's events. |
| `_links.members` | string | URL to the project's members. |
| `_links.cluster_agents` | string | URL to the project's cluster agents. |
| `marked_for_deletion_at` | date | Deprecated. Use `marked_for_deletion_on` instead. Date when the project is scheduled for deletion. |
| `marked_for_deletion_on` | date | Date when the project is scheduled for deletion. |
| `packages_enabled` | boolean | Whether the package registry is enabled for the project. |
| `empty_repo` | boolean | Whether the repository is empty. |
| `archived` | boolean | Whether the project is archived. |
| `resolve_outdated_diff_discussions` | boolean | Whether outdated diff discussions are automatically resolved. |
| `container_expiration_policy` | object | Settings for container image expiration policy. |
| `container_expiration_policy.cadence` | string | How often the container expiration policy runs. |
| `container_expiration_policy.enabled` | boolean | Whether the container expiration policy is enabled. |
| `container_expiration_policy.keep_n` | integer | Number of container images to keep. |
| `container_expiration_policy.older_than` | string | Remove container images older than this value. |
| `container_expiration_policy.name_regex` | string | Deprecated. Use `name_regex_delete` instead. Regular expression to match container image names. |
| `container_expiration_policy.name_regex_keep` | string | Regular expression to match container image names to keep. |
| `container_expiration_policy.next_run_at` | datetime | Timestamp for the next scheduled policy run. |
| `repository_object_format` | string | Object format used by the repository (sha1 or sha256). |
| `issues_enabled` | boolean | Whether issues are enabled for the project. |
| `merge_requests_enabled` | boolean | Whether merge requests are enabled for the project. |
| `wiki_enabled` | boolean | Whether the wiki is enabled for the project. |
| `jobs_enabled` | boolean | Whether jobs are enabled for the project. |
| `snippets_enabled` | boolean | Whether snippets are enabled for the project. |
| `container_registry_enabled` | boolean | Deprecated. Use `container_registry_access_level` instead. Whether the container registry is enabled. |
| `service_desk_enabled` | boolean | Whether Service Desk is enabled for the project. |
| `can_create_merge_request_in` | boolean | Whether the current user can create merge requests in the project. |
| `issues_access_level` | string | Access level for the issues feature. Possible values: `disabled`, `private`, or `enabled`. |
| `repository_access_level` | string | Access level for the repository feature. Possible values: `disabled`, `private`, or `enabled`. |
| `merge_requests_access_level` | string | Access level for the merge requests feature. Possible values: `disabled`, `private`, or `enabled`. |
| `forking_access_level` | string | Access level for forking the project. Possible values: `disabled`, `private`, or `enabled`. |
| `wiki_access_level` | string | Access level for the wiki feature. Possible values: `disabled`, `private`, or `enabled`. |
| `builds_access_level` | string | Access level for the CI/CD builds feature. Possible values: `disabled`, `private`, or `enabled`. |
| `snippets_access_level` | string | Access level for the snippets feature. Possible values: `disabled`, `private`, or `enabled`. |
| `pages_access_level` | string | Access level for GitLab Pages. Possible values: `disabled`, `private`, `enabled`, or `public`. |
| `analytics_access_level` | string | Access level for analytics features. Possible values: `disabled`, `private`, or `enabled`. |
| `container_registry_access_level` | string | Access level for the container registry. Possible values: `disabled`, `private`, or `enabled`. |
| `security_and_compliance_access_level` | string | Access level for security and compliance features. Possible values: `disabled`, `private`, or `enabled`. |
| `releases_access_level` | string | Access level for the releases feature. Possible values: `disabled`, `private`, or `enabled`. |
| `environments_access_level` | string | Access level for the environments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `feature_flags_access_level` | string | Access level for the feature flags feature. Possible values: `disabled`, `private`, or `enabled`. |
| `infrastructure_access_level` | string | Access level for the infrastructure feature. Possible values: `disabled`, `private`, or `enabled`. |
| `monitor_access_level` | string | Access level for the monitor feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_experiments_access_level` | string | Access level for the model experiments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_registry_access_level` | string | Access level for the model registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `package_registry_access_level` | string | Access level for the package registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `emails_disabled` | boolean | Indicates if emails are disabled for the project. |
| `emails_enabled` | boolean | Indicates if emails are enabled for the project. |
| `show_diff_preview_in_email` | boolean | Indicates if diff previews are shown in email notifications. |
| `shared_runners_enabled` | boolean | Whether shared runners are enabled for the project. |
| `lfs_enabled` | boolean | Indicates if Git LFS is enabled for the project. |
| `creator_id` | integer | ID of the user who created the project. |
| `import_status` | string | Status of the project import. |
| `open_issues_count` | integer | Number of open issues. |
| `description_html` | string | Description of the project in HTML format. |
| `updated_at` | datetime | Timestamp when the project was last updated. |
| `ci_config_path` | string | Path to the CI/CD configuration file. |
| `public_jobs` | boolean | Whether job logs are publicly accessible. |
| `shared_with_groups` | array of objects | List of groups the project is shared with. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Whether merges are allowed only if the pipeline succeeds. |
| `allow_merge_on_skipped_pipeline` | boolean | Whether merges are allowed when the pipeline is skipped. |
| `request_access_enabled` | boolean | Whether users can request access to the project. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Whether merges are allowed only if all discussions are resolved. |
| `remove_source_branch_after_merge` | boolean | Whether the source branch is automatically removed after merge. |
| `printing_merge_request_link_enabled` | boolean | Indicates if merge request links are printed after pushing. |
| `merge_method` | string | Merge method used for the project. Possible values: `merge`, `rebase_merge`, or `ff`. |
| `merge_request_title_regex` | string | Regex pattern for validating merge request titles. |
| `merge_request_title_regex_description` | string | Description of the merge request title regex validation. |
| `squash_option` | string | Squash option for merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Whether authentication checks are enforced on uploads. |
| `suggestion_commit_message` | string | Custom commit message for suggestions. |
| `merge_commit_template` | string | Template for merge commit messages. |
| `squash_commit_template` | string | Template for squash commit messages. |
| `issue_branch_template` | string | Template for branch names created from issues. |
| `warn_about_potentially_unwanted_characters` | boolean | Whether to warn about potentially unwanted characters. |
| `autoclose_referenced_issues` | boolean | Whether referenced issues are automatically closed. |
| `max_artifacts_size` | integer | Maximum size in MB for CI/CD artifacts. |
| `approvals_before_merge` | integer | Deprecated. Use merge request approvals API instead. Number of approvals required before merge. |
| `mirror` | boolean | Whether the project is a mirror. |
| `external_authorization_classification_label` | string | External authorization classification label. |
| `requirements_enabled` | boolean | Indicates if requirements management is enabled. |
| `requirements_access_level` | string | Access level for the requirements feature. |
| `security_and_compliance_enabled` | boolean | Indicates if security and compliance features are enabled. |
| `compliance_frameworks` | array of strings | Compliance frameworks applied to the project. |
| `issues_template` | string | Default description for issues. Description is parsed with GitLab Flavored Markdown. Premium and Ultimate only. |
| `merge_requests_template` | string | Template for merge request descriptions. Premium and Ultimate only. |
| `merge_pipelines_enabled` | boolean | Indicates if merge pipelines are enabled. |
| `merge_trains_enabled` | boolean | Indicates if merge trains are enabled. |
| `merge_trains_skip_train_allowed` | boolean | Indicates if skipping the merge train is allowed. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Whether merges are allowed only if all status checks have passed. Ultimate only. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Whether pipeline triggers can approve deployments. |
| `prevent_merge_without_jira_issue` | boolean | Indicates if merges require an associated Jira issue. |
| `duo_remote_flows_enabled` | boolean | Indicates if GitLab Duo remote flows are enabled. |
| `duo_foundational_flows_enabled` | boolean | Indicates if GitLab Duo foundational flows are enabled. |
| `duo_sast_fp_detection_enabled` | boolean | Indicates if GitLab Duo SAST false positive detection is enabled. |
| `spp_repository_pipeline_access` | boolean | Repository pipeline access for security policies. Only visible if the security orchestration policies feature is available. |
| `permissions` | object | User permissions for the project. |
| `permissions.project_access` | object | Project access permissions for the user. |
| `permissions.group_access` | object | Group access permissions for the user. |
{.condensed}
<!-- markdownlint-enable MD055 -->
<!-- markdownlint-enable MD056 -->

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects
```

Example response:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "readme_url": "https://gitlab.example.com/diaspora/diaspora-client/blob/main/README.md",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "forks_count": 0,
    "star_count": 0,
    "last_activity_at": "2022-06-24T17:11:26.841Z",
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": "https://gitlab.example.com/uploads/project/avatar/6/uploads/avatar.png",
      "web_url": "https://gitlab.example.com/diaspora"
    },
    "container_registry_image_prefix": "registry.gitlab.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "https://gitlab.example.com/api/v4/projects/4",
      "issues": "https://gitlab.example.com/api/v4/projects/4/issues",
      "merge_requests": "https://gitlab.example.com/api/v4/projects/4/merge_requests",
      "repo_branches": "https://gitlab.example.com/api/v4/projects/4/repository/branches",
      "labels": "https://gitlab.example.com/api/v4/projects/4/labels",
      "events": "https://gitlab.example.com/api/v4/projects/4/events",
      "members": "https://gitlab.example.com/api/v4/projects/4/members",
      "cluster_agents": "https://gitlab.example.com/api/v4/projects/4/cluster_agents"
    },
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "package_registry_access_level": "enabled",
    "empty_repo": false,
    "archived": false,
    "visibility": "public",
    "resolve_outdated_diff_discussions": false,
    "container_expiration_policy": {
      "cadence": "1month",
      "enabled": true,
      "keep_n": 1,
      "older_than": "14d",
      "name_regex": "",
      "name_regex_keep": ".*-main",
      "next_run_at": "2022-06-25T17:11:26.865Z"
    },
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "container_registry_enabled": true,
    "service_desk_enabled": true,
    "can_create_merge_request_in": true,
    "issues_access_level": "enabled",
    "repository_access_level": "enabled",
    "merge_requests_access_level": "enabled",
    "forking_access_level": "enabled",
    "wiki_access_level": "enabled",
    "builds_access_level": "enabled",
    "snippets_access_level": "enabled",
    "pages_access_level": "enabled",
    "analytics_access_level": "enabled",
    "container_registry_access_level": "enabled",
    "security_and_compliance_access_level": "private",
    "emails_disabled": null,
    "emails_enabled": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "lfs_enabled": true,
    "creator_id": 1,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "open_issues_count": 0,
    "ci_default_git_depth": 20,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_job_token_scope_enabled": false,
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "public_jobs": true,
    "build_timeout": 3600,
    "auto_cancel_pending_pipelines": "enabled",
    "ci_config_path": "",
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": null,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "request_access_enabled": true,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": true,
    "printing_merge_request_link_enabled": true,
    "merge_method": "merge",
    "squash_option": "default_off",
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "auto_devops_enabled": false,
    "auto_devops_deploy_strategy": "continuous",
    "autoclose_referenced_issues": true,
    "keep_latest_artifact": true,
    "runner_token_expiration_interval": null,
    "external_authorization_classification_label": "",
    "requirements_enabled": false,
    "requirements_access_level": "enabled",
    "security_and_compliance_enabled": false,
    "secret_push_protection_enabled": false,
    "compliance_frameworks": [],
    "warn_about_potentially_unwanted_characters": true,
    "permissions": {
      "project_access": null,
      "group_access": null
    }
  },
  {
    ...
  }
]
```

> [!note]
> `last_activity_at` is updated based on [project activity](../user/project/working_with_projects.md#view-project-activity)
> and [project events](events.md). To optimize database performance, this field updates at most once per hour.
> Events occurring within one hour of the last update do not modify the timestamp.
> As a result, `last_activity_at` can be out of date by up to one hour.
> `updated_at` is updated whenever the project record is changed in the database.

### List all personal projects for a user

Lists all personal projects for a specified user. The following restrictions apply:

- Returns only projects in the user's personal namespace, not group or subgroup projects.
- If the user profile is private, returns an empty list.
- Requests without authentication return only public projects.

This endpoint supports pagination:

- Use offset-based pagination to access up to 50,000 projects.
- Use keyset-based pagination to list more than 50,000 projects.

For more information, see [Pagination](rest/_index.md#pagination).

```plaintext
GET /users/:user_id/projects
```

Supported attributes:

| Attribute                     | Type     | Required | Description |
|:------------------------------|:---------|:---------|:------------|
| `user_id`                     | string   | Yes      | The ID or username of the user. |
| `archived`                    | boolean  | No       | Limit by archived status. |
| `id_after`                    | integer  | No       | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                   | integer  | No       | Limit results to projects with IDs less than the specified ID. |
| `membership`                  | boolean  | No       | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer  | No       | Limit to projects where the current user has at least the specified access level. Possible values: `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner). |
| `order_by`                    | string   | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean  | No       | Limit by projects explicitly owned by the current user. |
| `search`                      | string   | No       | Return list of projects matching the search criteria. |
| `simple`                      | boolean  | No       | If `true`, return only limited fields for each project. Unauthenticated requests return only public projects with limited fields, even if `simple` is not set. |
| `sort`                        | string   | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean  | No       | Limit by projects starred by the current user. |
| `statistics`                  | boolean  | No       | Include project statistics. Available only to users with the Reporter, Developer, Maintainer, or Owner role. |
| `updated_after`               | datetime | No       | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `updated_before`              | datetime | No       | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `visibility`                  | string   | No       | Limit by visibility. Possible values: `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean  | No       | Include [custom attributes](custom_attributes.md) in response. Administrator access. |
| `with_issues_enabled`         | boolean  | No       | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean  | No       | Limit by enabled merge requests feature. |
| `with_programming_language`   | string   | No       | Limit by projects which use the given programming language. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

<!-- markdownlint-disable MD055 -->
<!-- markdownlint-disable MD056 -->

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | integer | ID of the project. |
| `description` | string | Description of the project. |
| `name` | string | Name of the project. |
| `name_with_namespace` | string | Name of the project with its namespace. |
| `path` | string | Path of the project. |
| `path_with_namespace` | string | Path of the project with its namespace. |
| `created_at` | datetime | Timestamp when the project was created. |
| `default_branch` | string | Default branch of the project. |
| `tag_list` | array of strings | Deprecated. Use `topics` instead. List of tags for the project. |
| `topics` | array of strings | List of topics for the project. |
| `ssh_url_to_repo` | string | SSH URL to clone the repository. |
| `http_url_to_repo` | string | HTTP URL to clone the repository. |
| `web_url` | string | URL to access the project in a browser. |
| `readme_url` | string | URL to the project's README file. |
| `forks_count` | integer | Number of forks of the project. |
| `avatar_url` | string | URL to the project's avatar image. |
| `star_count` | integer | Number of stars the project has received. |
| `last_activity_at` | datetime | Timestamp of the last activity in the project. |
| `visibility` | string | Visibility level of the project. Possible values: `private`, `internal`, or `public`. |
| `namespace` | object | Namespace information for the project. |
| `namespace.id` | integer | ID of the namespace. |
| `namespace.name` | string | Name of the namespace. |
| `namespace.path` | string | Path of the namespace. |
| `namespace.kind` | string | Type of namespace. Possible values: `user` or `group`. |
| `namespace.full_path` | string | Full path of the namespace. |
| `namespace.parent_id` | integer | ID of the parent namespace, if applicable. |
| `namespace.avatar_url` | string | URL to the namespace's avatar image. |
| `namespace.web_url` | string | URL to access the namespace in a browser. |
| `container_registry_image_prefix` | string | Prefix for container registry images. |
| `_links` | object | Collection of API endpoint links related to the project. |
| `_links.self` | string | URL to the project resource. |
| `_links.issues` | string | URL to the project's issues. |
| `_links.merge_requests` | string | URL to the project's merge requests. |
| `_links.repo_branches` | string | URL to the project's repository branches. |
| `_links.labels` | string | URL to the project's labels. |
| `_links.events` | string | URL to the project's events. |
| `_links.members` | string | URL to the project's members. |
| `_links.cluster_agents` | string | URL to the project's cluster agents. |
| `marked_for_deletion_at` | date | Deprecated. Use `marked_for_deletion_on` instead. Date when the project is scheduled for deletion. |
| `marked_for_deletion_on` | date | Date when the project is scheduled for deletion. |
| `packages_enabled` | boolean | Whether the package registry is enabled for the project. |
| `empty_repo` | boolean | Whether the repository is empty. |
| `archived` | boolean | Whether the project is archived. |
| `resolve_outdated_diff_discussions` | boolean | Whether outdated diff discussions are automatically resolved. |
| `container_expiration_policy` | object | Settings for container image expiration policy. |
| `container_expiration_policy.cadence` | string | How often the container expiration policy runs. |
| `container_expiration_policy.enabled` | boolean | Whether the container expiration policy is enabled. |
| `container_expiration_policy.keep_n` | integer | Number of container images to keep. |
| `container_expiration_policy.older_than` | string | Remove container images older than this value. |
| `container_expiration_policy.name_regex` | string | Deprecated. Use `name_regex_delete` instead. Regular expression to match container image names. |
| `container_expiration_policy.name_regex_keep` | string | Regular expression to match container image names to keep. |
| `container_expiration_policy.next_run_at` | datetime | Timestamp for the next scheduled policy run. |
| `repository_object_format` | string | Object format used by the repository (sha1 or sha256). |
| `issues_enabled` | boolean | Whether issues are enabled for the project. |
| `merge_requests_enabled` | boolean | Whether merge requests are enabled for the project. |
| `wiki_enabled` | boolean | Whether the wiki is enabled for the project. |
| `jobs_enabled` | boolean | Whether jobs are enabled for the project. |
| `snippets_enabled` | boolean | Whether snippets are enabled for the project. |
| `container_registry_enabled` | boolean | Deprecated. Use `container_registry_access_level` instead. Whether the container registry is enabled. |
| `service_desk_enabled` | boolean | Whether Service Desk is enabled for the project. |
| `can_create_merge_request_in` | boolean | Whether the current user can create merge requests in the project. |
| `issues_access_level` | string | Access level for the issues feature. Possible values: `disabled`, `private`, or `enabled`. |
| `repository_access_level` | string | Access level for the repository feature. Possible values: `disabled`, `private`, or `enabled`. |
| `merge_requests_access_level` | string | Access level for the merge requests feature. Possible values: `disabled`, `private`, or `enabled`. |
| `forking_access_level` | string | Access level for forking the project. Possible values: `disabled`, `private`, or `enabled`. |
| `wiki_access_level` | string | Access level for the wiki feature. Possible values: `disabled`, `private`, or `enabled`. |
| `builds_access_level` | string | Access level for the CI/CD builds feature. Possible values: `disabled`, `private`, or `enabled`. |
| `snippets_access_level` | string | Access level for the snippets feature. Possible values: `disabled`, `private`, or `enabled`. |
| `pages_access_level` | string | Access level for GitLab Pages. Possible values: `disabled`, `private`, `enabled`, or `public`. |
| `analytics_access_level` | string | Access level for analytics features. Possible values: `disabled`, `private`, or `enabled`. |
| `container_registry_access_level` | string | Access level for the container registry. Possible values: `disabled`, `private`, or `enabled`. |
| `security_and_compliance_access_level` | string | Access level for security and compliance features. Possible values: `disabled`, `private`, or `enabled`. |
| `releases_access_level` | string | Access level for the releases feature. Possible values: `disabled`, `private`, or `enabled`. |
| `environments_access_level` | string | Access level for the environments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `feature_flags_access_level` | string | Access level for the feature flags feature. Possible values: `disabled`, `private`, or `enabled`. |
| `infrastructure_access_level` | string | Access level for the infrastructure feature. Possible values: `disabled`, `private`, or `enabled`. |
| `monitor_access_level` | string | Access level for the monitor feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_experiments_access_level` | string | Access level for the model experiments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_registry_access_level` | string | Access level for the model registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `package_registry_access_level` | string | Access level for the package registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `emails_disabled` | boolean | Indicates if emails are disabled for the project. |
| `emails_enabled` | boolean | Indicates if emails are enabled for the project. |
| `show_diff_preview_in_email` | boolean | Indicates if diff previews are shown in email notifications. |
| `shared_runners_enabled` | boolean | Whether shared runners are enabled for the project. |
| `lfs_enabled` | boolean | Indicates if Git LFS is enabled for the project. |
| `creator_id` | integer | ID of the user who created the project. |
| `import_status` | string | Status of the project import. |
| `open_issues_count` | integer | Number of open issues. |
| `description_html` | string | Description of the project in HTML format. |
| `updated_at` | datetime | Timestamp when the project was last updated. |
| `ci_default_git_depth` | integer | Default Git depth for CI/CD pipelines. Only visible if you have administrator access or the Owner role for the project. |
| `ci_forward_deployment_enabled` | boolean | Whether forward deployment is enabled. Only visible if you have administrator access or the Owner role for the project. |
| `ci_job_token_scope_enabled` | boolean | Indicates if CI/CD job token scope is enabled. Only visible if you have administrator access or the Owner role for the project. |
| `ci_separated_caches` | boolean | Whether CI/CD caches are separated by branch. Only visible if you have administrator access or the Owner role for the project. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean | Whether fork pipelines can run in the parent project. Only visible if you have administrator access or the Owner role for the project. |
| `build_git_strategy` | string | Git strategy used for CI/CD builds (fetch or clone). Only visible if you have administrator access or the Owner role for the project. |
| `keep_latest_artifact` | boolean | Indicates if the latest artifact is kept when a new one is created. Only visible if you have administrator access or the Owner role for the project. |
| `restrict_user_defined_variables` | boolean | Whether user-defined variables are restricted. Only visible if you have administrator access or the Owner role for the project. |
| `runners_token` | string | Token for registering runners with the project. Only visible if you have administrator access or the Owner role for the project. |
| `runner_token_expiration_interval` | integer | Expiration interval in seconds for runner tokens. Only visible if you have administrator access or the Owner role for the project. |
| `group_runners_enabled` | boolean | Whether group runners are enabled for the project. Only visible if you have administrator access or the Owner role for the project. |
| `auto_cancel_pending_pipelines` | string | Setting for automatically canceling pending pipelines. Only visible if you have administrator access or the Owner role for the project. |
| `build_timeout` | integer | Timeout in seconds for CI/CD jobs. Only visible if you have administrator access or the Owner role for the project. |
| `auto_devops_enabled` | boolean | Whether Auto DevOps is enabled for the project. Only visible if you have administrator access or the Owner role for the project. |
| `auto_devops_deploy_strategy` | string | Deployment strategy for Auto DevOps. Only visible if you have administrator access or the Owner role for the project. |
| `ci_config_path` | string | Path to the CI/CD configuration file. |
| `public_jobs` | boolean | Whether job logs are publicly accessible. |
| `shared_with_groups` | array of objects | List of groups the project is shared with. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Whether merges are allowed only if the pipeline succeeds. |
| `allow_merge_on_skipped_pipeline` | boolean | Whether merges are allowed when the pipeline is skipped. |
| `request_access_enabled` | boolean | Whether users can request access to the project. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Whether merges are allowed only if all discussions are resolved. |
| `remove_source_branch_after_merge` | boolean | Whether the source branch is automatically removed after merge. |
| `printing_merge_request_link_enabled` | boolean | Indicates if merge request links are printed after pushing. |
| `merge_method` | string | Merge method used for the project. Possible values: `merge`, `rebase_merge`, or `ff`. |
| `merge_request_title_regex` | string | Regex pattern for validating merge request titles. |
| `merge_request_title_regex_description` | string | Description of the merge request title regex validation. |
| `squash_option` | string | Squash option for merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Whether authentication checks are enforced on uploads. |
| `suggestion_commit_message` | string | Custom commit message for suggestions. |
| `merge_commit_template` | string | Template for merge commit messages. |
| `squash_commit_template` | string | Template for squash commit messages. |
| `issue_branch_template` | string | Template for branch names created from issues. |
| `warn_about_potentially_unwanted_characters` | boolean | Whether to warn about potentially unwanted characters. |
| `autoclose_referenced_issues` | boolean | Whether referenced issues are automatically closed. |
| `max_artifacts_size` | integer | Maximum size in MB for CI/CD artifacts. |
| `approvals_before_merge` | integer | Deprecated. Use merge request approvals API instead. Number of approvals required before merge. |
| `mirror` | boolean | Whether the project is a mirror. |
| `external_authorization_classification_label` | string | External authorization classification label. |
| `requirements_enabled` | boolean | Indicates if requirements management is enabled. |
| `requirements_access_level` | string | Access level for the requirements feature. |
| `security_and_compliance_enabled` | boolean | Indicates if security and compliance features are enabled. |
| `compliance_frameworks` | array of strings | Compliance frameworks applied to the project. |
| `issues_template` | string | Default description for issues. Description is parsed with GitLab Flavored Markdown. Premium and Ultimate only. |
| `merge_requests_template` | string | Template for merge request descriptions. Premium and Ultimate only. |
| `merge_pipelines_enabled` | boolean | Indicates if merge pipelines are enabled. |
| `merge_trains_enabled` | boolean | Indicates if merge trains are enabled. |
| `merge_trains_skip_train_allowed` | boolean | Indicates if skipping the merge train is allowed. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Whether merges are allowed only if all status checks have passed. Ultimate only. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Whether pipeline triggers can approve deployments. |
| `prevent_merge_without_jira_issue` | boolean | Indicates if merges require an associated Jira issue. |
| `duo_remote_flows_enabled` | boolean | Indicates if GitLab Duo remote flows are enabled. |
| `duo_foundational_flows_enabled` | boolean | Indicates if GitLab Duo foundational flows are enabled. |
| `duo_sast_fp_detection_enabled` | boolean | Indicates if GitLab Duo SAST false positive detection is enabled. |
| `spp_repository_pipeline_access` | boolean | Repository pipeline access for security policies. Only visible if the security orchestration policies feature is available. |
| `permissions` | object | User permissions for the project. |
| `permissions.project_access` | object | Project access permissions for the user. |
| `permissions.group_access` | object | Group access permissions for the user. |
{.condensed}
<!-- markdownlint-enable MD055 -->
<!-- markdownlint-enable MD056 -->

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/users/:user_id/projects
```

Example response:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

### List all projects contributions for a user

Lists all contributions to visible projects for a specified user. Returns only contributions in
the past year. For more information about what counts as a contribution, see
[View projects you work with](../user/project/working_with_projects.md#view-projects-you-work-with).

```plaintext
GET /users/:user_id/contributed_projects
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `user_id`  | string  | Yes      | The ID or username of the user. |
| `order_by` | string  | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, or `last_activity_at` fields. Default is `created_at`. |
| `simple`   | boolean | No       | If `true`, return only limited fields for each project. Unauthenticated requests return only public projects with limited fields, even if `simple` is not set. |
| `sort`     | string  | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

<!-- markdownlint-disable MD055 -->
<!-- markdownlint-disable MD056 -->

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | integer | ID of the project. |
| `description` | string | Description of the project. |
| `name` | string | Name of the project. |
| `name_with_namespace` | string | Name of the project with its namespace. |
| `path` | string | Path of the project. |
| `path_with_namespace` | string | Path of the project with its namespace. |
| `created_at` | datetime | Timestamp when the project was created. |
| `default_branch` | string | Default branch of the project. |
| `tag_list` | array of strings | Deprecated. Use `topics` instead. List of tags for the project. |
| `topics` | array of strings | List of topics for the project. |
| `ssh_url_to_repo` | string | SSH URL to clone the repository. |
| `http_url_to_repo` | string | HTTP URL to clone the repository. |
| `web_url` | string | URL to access the project in a browser. |
| `readme_url` | string | URL to the project's README file. |
| `forks_count` | integer | Number of forks of the project. |
| `avatar_url` | string | URL to the project's avatar image. |
| `star_count` | integer | Number of stars the project has received. |
| `last_activity_at` | datetime | Timestamp of the last activity in the project. |
| `visibility` | string | Visibility level of the project. Possible values: `private`, `internal`, or `public`. |
| `namespace` | object | Namespace information for the project. |
| `namespace.id` | integer | ID of the namespace. |
| `namespace.name` | string | Name of the namespace. |
| `namespace.path` | string | Path of the namespace. |
| `namespace.kind` | string | Type of namespace. Possible values: `user` or `group`. |
| `namespace.full_path` | string | Full path of the namespace. |
| `namespace.parent_id` | integer | ID of the parent namespace, if applicable. |
| `namespace.avatar_url` | string | URL to the namespace's avatar image. |
| `namespace.web_url` | string | URL to access the namespace in a browser. |
| `container_registry_image_prefix` | string | Prefix for container registry images. |
| `_links` | object | Collection of API endpoint links related to the project. |
| `_links.self` | string | URL to the project resource. |
| `_links.issues` | string | URL to the project's issues. |
| `_links.merge_requests` | string | URL to the project's merge requests. |
| `_links.repo_branches` | string | URL to the project's repository branches. |
| `_links.labels` | string | URL to the project's labels. |
| `_links.events` | string | URL to the project's events. |
| `_links.members` | string | URL to the project's members. |
| `_links.cluster_agents` | string | URL to the project's cluster agents. |
| `marked_for_deletion_at` | date | Deprecated. Use `marked_for_deletion_on` instead. Date when the project is scheduled for deletion. |
| `marked_for_deletion_on` | date | Date when the project is scheduled for deletion. |
| `packages_enabled` | boolean | Whether the package registry is enabled for the project. |
| `empty_repo` | boolean | Whether the repository is empty. |
| `archived` | boolean | Whether the project is archived. |
| `resolve_outdated_diff_discussions` | boolean | Whether outdated diff discussions are automatically resolved. |
| `container_expiration_policy` | object | Settings for container image expiration policy. |
| `container_expiration_policy.cadence` | string | How often the container expiration policy runs. |
| `container_expiration_policy.enabled` | boolean | Whether the container expiration policy is enabled. |
| `container_expiration_policy.keep_n` | integer | Number of container images to keep. |
| `container_expiration_policy.older_than` | string | Remove container images older than this value. |
| `container_expiration_policy.name_regex` | string | Deprecated. Use `name_regex_delete` instead. Regular expression to match container image names. |
| `container_expiration_policy.name_regex_keep` | string | Regular expression to match container image names to keep. |
| `container_expiration_policy.next_run_at` | datetime | Timestamp for the next scheduled policy run. |
| `repository_object_format` | string | Object format used by the repository (sha1 or sha256). |
| `issues_enabled` | boolean | Whether issues are enabled for the project. |
| `merge_requests_enabled` | boolean | Whether merge requests are enabled for the project. |
| `wiki_enabled` | boolean | Whether the wiki is enabled for the project. |
| `jobs_enabled` | boolean | Whether jobs are enabled for the project. |
| `snippets_enabled` | boolean | Whether snippets are enabled for the project. |
| `container_registry_enabled` | boolean | Deprecated. Use `container_registry_access_level` instead. Whether the container registry is enabled. |
| `service_desk_enabled` | boolean | Whether Service Desk is enabled for the project. |
| `can_create_merge_request_in` | boolean | Whether the current user can create merge requests in the project. |
| `issues_access_level` | string | Access level for the issues feature. Possible values: `disabled`, `private`, or `enabled`. |
| `repository_access_level` | string | Access level for the repository feature. Possible values: `disabled`, `private`, or `enabled`. |
| `merge_requests_access_level` | string | Access level for the merge requests feature. Possible values: `disabled`, `private`, or `enabled`. |
| `forking_access_level` | string | Access level for forking the project. Possible values: `disabled`, `private`, or `enabled`. |
| `wiki_access_level` | string | Access level for the wiki feature. Possible values: `disabled`, `private`, or `enabled`. |
| `builds_access_level` | string | Access level for the CI/CD builds feature. Possible values: `disabled`, `private`, or `enabled`. |
| `snippets_access_level` | string | Access level for the snippets feature. Possible values: `disabled`, `private`, or `enabled`. |
| `pages_access_level` | string | Access level for GitLab Pages. Possible values: `disabled`, `private`, `enabled`, or `public`. |
| `analytics_access_level` | string | Access level for analytics features. Possible values: `disabled`, `private`, or `enabled`. |
| `container_registry_access_level` | string | Access level for the container registry. Possible values: `disabled`, `private`, or `enabled`. |
| `security_and_compliance_access_level` | string | Access level for security and compliance features. Possible values: `disabled`, `private`, or `enabled`. |
| `releases_access_level` | string | Access level for the releases feature. Possible values: `disabled`, `private`, or `enabled`. |
| `environments_access_level` | string | Access level for the environments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `feature_flags_access_level` | string | Access level for the feature flags feature. Possible values: `disabled`, `private`, or `enabled`. |
| `infrastructure_access_level` | string | Access level for the infrastructure feature. Possible values: `disabled`, `private`, or `enabled`. |
| `monitor_access_level` | string | Access level for the monitor feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_experiments_access_level` | string | Access level for the model experiments feature. Possible values: `disabled`, `private`, or `enabled`. |
| `model_registry_access_level` | string | Access level for the model registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `package_registry_access_level` | string | Access level for the package registry feature. Possible values: `disabled`, `private`, or `enabled`. |
| `emails_disabled` | boolean | Indicates if emails are disabled for the project. |
| `emails_enabled` | boolean | Indicates if emails are enabled for the project. |
| `show_diff_preview_in_email` | boolean | Indicates if diff previews are shown in email notifications. |
| `shared_runners_enabled` | boolean | Whether shared runners are enabled for the project. |
| `lfs_enabled` | boolean | Indicates if Git LFS is enabled for the project. |
| `creator_id` | integer | ID of the user who created the project. |
| `import_status` | string | Status of the project import. |
| `open_issues_count` | integer | Number of open issues. |
| `description_html` | string | Description of the project in HTML format. |
| `updated_at` | datetime | Timestamp when the project was last updated. |
| `ci_default_git_depth` | integer | Default Git depth for CI/CD pipelines. Only visible if you have administrator access or the Owner role for the project. |
| `ci_forward_deployment_enabled` | boolean | Whether forward deployment is enabled. Only visible if you have administrator access or the Owner role for the project. |
| `ci_job_token_scope_enabled` | boolean | Indicates if CI/CD job token scope is enabled. Only visible if you have administrator access or the Owner role for the project. |
| `ci_separated_caches` | boolean | Whether CI/CD caches are separated by branch. Only visible if you have administrator access or the Owner role for the project. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean | Whether fork pipelines can run in the parent project. Only visible if you have administrator access or the Owner role for the project. |
| `build_git_strategy` | string | Git strategy used for CI/CD builds (fetch or clone). Only visible if you have administrator access or the Owner role for the project. |
| `keep_latest_artifact` | boolean | Indicates if the latest artifact is kept when a new one is created. Only visible if you have administrator access or the Owner role for the project. |
| `restrict_user_defined_variables` | boolean | Whether user-defined variables are restricted. Only visible if you have administrator access or the Owner role for the project. |
| `runners_token` | string | Token for registering runners with the project. Only visible if you have administrator access or the Owner role for the project. |
| `runner_token_expiration_interval` | integer | Expiration interval in seconds for runner tokens. Only visible if you have administrator access or the Owner role for the project. |
| `group_runners_enabled` | boolean | Whether group runners are enabled for the project. Only visible if you have administrator access or the Owner role for the project. |
| `auto_cancel_pending_pipelines` | string | Setting for automatically canceling pending pipelines. Only visible if you have administrator access or the Owner role for the project. |
| `build_timeout` | integer | Timeout in seconds for CI/CD jobs. Only visible if you have administrator access or the Owner role for the project. |
| `auto_devops_enabled` | boolean | Whether Auto DevOps is enabled for the project. Only visible if you have administrator access or the Owner role for the project. |
| `auto_devops_deploy_strategy` | string | Deployment strategy for Auto DevOps. Only visible if you have administrator access or the Owner role for the project. |
| `ci_config_path` | string | Path to the CI/CD configuration file. |
| `public_jobs` | boolean | Whether job logs are publicly accessible. |
| `shared_with_groups` | array of objects | List of groups the project is shared with. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Whether merges are allowed only if the pipeline succeeds. |
| `allow_merge_on_skipped_pipeline` | boolean | Whether merges are allowed when the pipeline is skipped. |
| `request_access_enabled` | boolean | Whether users can request access to the project. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Whether merges are allowed only if all discussions are resolved. |
| `remove_source_branch_after_merge` | boolean | Whether the source branch is automatically removed after merge. |
| `printing_merge_request_link_enabled` | boolean | Indicates if merge request links are printed after pushing. |
| `merge_method` | string | Merge method used for the project. Possible values: `merge`, `rebase_merge`, or `ff`. |
| `merge_request_title_regex` | string | Regex pattern for validating merge request titles. |
| `merge_request_title_regex_description` | string | Description of the merge request title regex validation. |
| `squash_option` | string | Squash option for merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Whether authentication checks are enforced on uploads. |
| `suggestion_commit_message` | string | Custom commit message for suggestions. |
| `merge_commit_template` | string | Template for merge commit messages. |
| `squash_commit_template` | string | Template for squash commit messages. |
| `issue_branch_template` | string | Template for branch names created from issues. |
| `warn_about_potentially_unwanted_characters` | boolean | Whether to warn about potentially unwanted characters. |
| `autoclose_referenced_issues` | boolean | Whether referenced issues are automatically closed. |
| `max_artifacts_size` | integer | Maximum size in MB for CI/CD artifacts. |
| `approvals_before_merge` | integer | Deprecated. Use merge request approvals API instead. Number of approvals required before merge. |
| `mirror` | boolean | Whether the project is a mirror. |
| `external_authorization_classification_label` | string | External authorization classification label. |
| `requirements_enabled` | boolean | Indicates if requirements management is enabled. |
| `requirements_access_level` | string | Access level for the requirements feature. |
| `security_and_compliance_enabled` | boolean | Indicates if security and compliance features are enabled. |
| `compliance_frameworks` | array of strings | Compliance frameworks applied to the project. |
| `issues_template` | string | Default description for issues. Description is parsed with GitLab Flavored Markdown. Premium and Ultimate only. |
| `merge_requests_template` | string | Template for merge request descriptions. Premium and Ultimate only. |
| `merge_pipelines_enabled` | boolean | Indicates if merge pipelines are enabled. |
| `merge_trains_enabled` | boolean | Indicates if merge trains are enabled. |
| `merge_trains_skip_train_allowed` | boolean | Indicates if skipping the merge train is allowed. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Whether merges are allowed only if all status checks have passed. Ultimate only. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Whether pipeline triggers can approve deployments. |
| `prevent_merge_without_jira_issue` | boolean | Indicates if merges require an associated Jira issue. |
| `duo_remote_flows_enabled` | boolean | Indicates if GitLab Duo remote flows are enabled. |
| `duo_foundational_flows_enabled` | boolean | Indicates if GitLab Duo foundational flows are enabled. |
| `duo_sast_fp_detection_enabled` | boolean | Indicates if GitLab Duo SAST false positive detection is enabled. |
| `spp_repository_pipeline_access` | boolean | Repository pipeline access for security policies. Only visible if the security orchestration policies feature is available. |
| `permissions` | object | User permissions for the project. |
| `permissions.project_access` | object | Project access permissions for the user. |
| `permissions.group_access` | object | Group access permissions for the user. |
{.condensed}
<!-- markdownlint-enable MD055 -->
<!-- markdownlint-enable MD056 -->

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/5/contributed_projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## List attributes

List attributes of a project.

### List all members of a project

Lists all members with access to a specified project.

```plaintext
GET /projects/:id/users
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|:-------------|:------------------|:---------|:------------|
| `id`         | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`     | string            | No       | Search for a specific member by their `username` or `name`. |
| `skip_users` | integer array     | No       | Filter out members with the specified IDs. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID of the user. |
| `username` | string | Username of the user. |
| `name` | string | Full name of the user. |
| `state` | string | State of the user account. Possible values: `active` or `blocked`. |
| `avatar_url` | string | URL of the user's avatar image. |
| `web_url` | string | URL to access the user's profile in a browser. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<project_id>/users" \
```

Example response:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

### List all ancestor groups

Lists all ancestor groups for a specified project.

```plaintext
GET /projects/:id/groups
```

Supported attributes:

| Attribute                 | Type              | Required | Description |
|:--------------------------|:------------------|:---------|:------------|
| `id`                      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`                  | string            | No       | Search for specific groups by group ID. |
| `shared_min_access_level` | integer           | No       | Limit to shared groups with at least the specified access level. Possible values: `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner). |
| `shared_visible_only`     | boolean           | No       | If `true`, returns only shared groups the authenticated user can access. |
| `skip_groups`             | array of integers | No       | Skip the group IDs passed. |
| `with_shared`             | boolean           | No       | Include projects shared with this group. Default is `false`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID of the group. |
| `name` | string | Name of the group. |
| `avatar_url` | string | URL of the group's avatar image. |
| `web_url` | string | URL to access the group in a browser. |
| `full_name` | string | Full name of the group. |
| `full_path` | string | Full path of the group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/groups"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "full_name": "Foobar Group",
    "full_path": "foo-bar"
  },
  {
    "id": 2,
    "name": "Shared Group",
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "full_name": "Shared Group",
    "full_path": "foo/shared"
  }
]
```

### List all groups available to invite to a project

Lists all groups that can be invited to a project.

```plaintext
GET /projects/:id/share_locations
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`  | string            | No       | Search for specific groups by group ID. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID of the group. |
| `web_url` | string | URL to access the group in a browser. |
| `name` | string | Name of the group. |
| `avatar_url` | string | URL of the group's avatar image. |
| `full_name` | string | Full name of the group. |
| `full_path` | string | Full path of the group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/share_locations"
```

Example response:

```json
[
  {
    "id": 22,
    "web_url": "http://127.0.0.1:3000/groups/gitlab-org",
    "name": "Gitlab Org",
    "avatar_url": null,
    "full_name": "Gitlab Org",
    "full_path": "gitlab-org"
  },
  {
    "id": 25,
    "web_url": "http://127.0.0.1:3000/groups/gnuwget",
    "name": "Gnuwget",
    "avatar_url": null,
    "full_name": "Gnuwget",
    "full_path": "gnuwget"
  }
]
```

### List all invited groups in a project

Lists all invited groups in a project. When accessed without authentication, returns only public invited groups.
This endpoint is rate-limited to 60 requests per minute per:

- User for authenticated users
- IP address for unauthenticated users

This endpoint supports pagination:

- Use offset-based pagination to access up to 50,000 projects.
- Use keyset-based pagination to list more than 50,000 projects.

For more information, see [Pagination](rest/_index.md#pagination).

```plaintext
GET /projects/:id/invited_groups
```

Supported attributes:

| Attribute                | Type             | Required | Description |
|:-------------------------|:-----------------|:---------|:------------|
| `id`                     | integer or string   | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `search`                 | string           | no       | Return the list of authorized groups matching the search criteria. |
| `min_access_level`       | integer          | no       | Limit to groups where the current user has at least the specified access level. Possible values: `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner). |
| `relation`               | array of strings | no       | Filter the groups by relation. Possible values: `direct` or `inherited`. |
| `with_custom_attributes` | boolean          | no       | If `true`, returns [custom attributes](custom_attributes.md) in response. Requires administrator access. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID of the group. |
| `web_url` | string | URL to access the group in a browser. |
| `name` | string | Name of the group. |
| `avatar_url` | string | URL of the group's avatar image. |
| `full_name` | string | Full name of the group. |
| `full_path` | string | Full path of the group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/invited_groups"
```

Example response:

```json
[
  {
    "id": 35,
    "web_url": "https://gitlab.example.com/groups/twitter",
    "name": "Twitter",
    "avatar_url": null,
    "full_name": "Twitter",
    "full_path": "twitter"
  }
]
```

### Retrieve programming language usage information

Retrieves information about all programming languages used in a specified project.

```plaintext
GET /projects/:id/languages
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and
a list of programming languages and usage percentages.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/languages"
```

Example response:

```json
{
  "Ruby": 66.69,
  "JavaScript": 22.98,
  "HTML": 7.91,
  "CoffeeScript": 2.42
}
```

## Manage projects

Manage a project, including creation, deletion, and archival.

### Create a project

{{< history >}}

- `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
- `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.
- `packages_enabled` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 17.10.
- `package_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 18.5.

{{< /history >}}

Creates a new project owned by the authenticated user.

If your HTTP repository isn't publicly accessible, add authentication information to the URL
`https://username:password@gitlab.company.com/group/project.git`, where `password` is a public access key with the `api`
scope enabled.

```plaintext
POST /projects
```

Supported general project attributes:

| Attribute                                          | Type    | Required                       | Description |
|:---------------------------------------------------|:--------|:-------------------------------|:------------|
| `name`                                             | string  | Yes (if `path` isn't provided) | The name of the new project. Equals path if not provided. |
| `path`                                             | string  | Yes (if `name` isn't provided) | Repository name for new project. Generated based on name if not provided (generated as lowercase with dashes). The path must not start or end with a special character and must not contain consecutive special characters. |
| `allow_merge_on_skipped_pipeline`                  | boolean | No                             | Set whether or not merge requests can be merged with skipped jobs. |
| `approvals_before_merge`                           | integer | No                             | How many approvers should approve merge requests by default. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. Premium and Ultimate only. |
| `auto_cancel_pending_pipelines`                    | string  | No                             | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                      | string  | No                             | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                              | boolean | No                             | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                      | boolean | No                             | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                           | mixed   | No                             | Image file for avatar of the project. |
| `build_git_strategy`                               | string  | No                             | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                    | integer | No                             | The maximum amount of time, in seconds, that a job can run. |
| `ci_config_path`                                   | string  | No                             | The path to CI configuration file. |
| `container_expiration_policy_attributes`           | hash    | No                             | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). See the [container registry](../user/packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api) documentation for more information on `cadence`, `keep_n` and `older_than` values. |
| `container_registry_enabled`                       | boolean | No                             | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                   | string  | No                             | The [default branch](../user/project/repository/branches/default.md) name. Accepts a branch name (for example, `main`) or a fully qualified reference (for example, `refs/heads/main`). If a fully qualified reference is provided, the API strips the `refs/heads/` prefix. Requires `initialize_with_readme` to be `true`. |
| `description`                                      | string  | No                             | Short project description. |
| `emails_disabled`                                  | boolean | No                             | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead |
| `emails_enabled`                                   | boolean | No                             | Enable email notifications. |
| `external_authorization_classification_label`      | string  | No                             | The classification label for the project. Premium and Ultimate only. |
| `group_runners_enabled`                            | boolean | No                             | Enable group runners for this project. |
| `group_with_project_templates_id`                  | integer | No                             | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. Premium and Ultimate only. |
| `import_url`                                       | string  | No                             | URL to import repository from. When the URL value isn't empty, you must not set `initialize_with_readme` to `true`. Doing so might result in the [following error](https://gitlab.com/gitlab-org/gitlab/-/issues/360266): `not a git repository`. |
| `initialize_with_readme`                           | boolean | No                             | Whether to create a Git repository with just a `README.md` file. Default is `false`. When this boolean is true, you must not pass `import_url` or other attributes of this endpoint which specify alternative contents for the repository. Doing so might result in the [following error](https://gitlab.com/gitlab-org/gitlab/-/issues/360266): `not a git repository`. |
| `issues_enabled`                                   | boolean | No                             | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                     | boolean | No                             | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                      | boolean | No                             | Enable LFS. |
| `merge_method`                                     | string  | No                             | Set the project's [merge method](../user/project/merge_requests/methods/_index.md). Can be `merge` (merge commit), `rebase_merge` (merge commit with semi-linear history), or `ff` (fast-forward merge). |
| `merge_pipelines_enabled`                          | boolean | No                             | Enable or disable merged results pipelines. |
| `merge_requests_enabled`                           | boolean | No                             | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_trains_enabled`                             | boolean | No                             | Enable or disable merge trains. |
| `merge_trains_skip_train_allowed`                  | boolean | No                             | Allows merge train merge requests to be merged without waiting for pipelines to finish. |
| `mirror_trigger_builds`                            | boolean | No                             | Pull mirroring triggers builds. Premium and Ultimate only. |
| `mirror`                                           | boolean | No                             | Enables pull mirroring in a project. Premium and Ultimate only. |
| `namespace_id`                                     | integer | No                             | Namespace for the new project. Specify a group ID or subgroup ID. If not provided, defaults to the current user's personal namespace. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | No                             | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean | No                             | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. Ultimate only. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean | No                             | Set whether merge requests can only be merged with successful pipelines. This setting is named [**Pipelines must succeed**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) in the project settings. |
| `packages_enabled`                                 | boolean | No                             | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 17.10. Enable or disable packages repository feature. Use `package_registry_access_level` instead. |
| `package_registry_access_level`                    | string  | No                             | Enable or disable packages repository feature. |
| `printing_merge_request_link_enabled`              | boolean | No                             | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                    | boolean | No                             | _(Deprecated)_ If `true`, jobs can be viewed by non-project members. Use `public_jobs` instead. |
| `public_jobs`                                      | boolean | No                             | If `true`, jobs can be viewed by non-project members. |
| `repository_object_format`                         | string  | No                             | Repository object format. Defaults to `sha1`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419887) in GitLab 16.9. |
| `remove_source_branch_after_merge`                 | boolean | No                             | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_storage`                               | string  | No                             | Which storage shard the repository is on. _(administrator only)_ |
| `request_access_enabled`                           | boolean | No                             | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                | boolean | No                             | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `shared_runners_enabled`                           | boolean | No                             | Enable instance runners for this project. |
| `show_default_award_emojis`                        | boolean | No                             | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean | No                             | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `squash_option`                                    | string  | No                             | One of `never`, `always`, `default_on`, or `default_off`. |
| `tag_list`                                         | array   | No                             | The list of tags for a project; put array of tags, that should be finally assigned to a project. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0. Use `topics` instead. |
| `template_name`                                    | string  | No                             | When used without `use_custom_template`, name of a [built-in project template](../user/project/_index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
| `template_project_id`                              | integer | No                             | When used with `use_custom_template`, project ID of a custom project template. Using a project ID is preferable to using `template_name` because `template_name` can be ambiguous. Premium and Ultimate only. |
| `topics`                                           | array   | No                             | The list of topics for a project; put array of topics, that should be finally assigned to a project. |
| `use_custom_template`                              | boolean | No                             | Use either custom [instance](../administration/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. Premium and Ultimate only. |
| `visibility`                                       | string  | No                             | See [project visibility level](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean | No                             | Enable warnings about usage of potentially unwanted characters in this project. |
| `wiki_enabled`                                     | boolean | No                             | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
     --header "Content-Type: application/json" --data '{
        "name": "new_project", "description": "New Project", "path": "new_project",
        "namespace_id": "42", "initialize_with_readme": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/"
```

To set the visibility level of individual project features,
see [Project feature visibility level](#project-feature-visibility-level).

### Create a project for a user

{{< history >}}

- `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
- `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.
- `packages_enabled` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 17.10.
- `package_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 18.5.

{{< /history >}}

Create a project for a user.

Prerequisites:

- You must be an administrator.

If your HTTP repository isn't publicly accessible, add authentication information to the URL. For example,
`https://username:password@gitlab.company.com/group/project.git` where `password` is a public access key with the `api`
scope enabled.

```plaintext
POST /projects/user/:user_id
```

Supported general project attributes:

| Attribute                                          | Type    | Required | Description |
|:---------------------------------------------------|:--------|:---------|:------------|
| `name`                                             | string  | Yes      | The name of the new project. |
| `user_id`                                          | integer | Yes      | The user ID of the project owner. |
| `allow_merge_on_skipped_pipeline`                  | boolean | No       | Set whether or not merge requests can be merged with skipped jobs. |
| `approvals_before_merge`                           | integer | No       | How many approvers should approve merge requests by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). Premium and Ultimate only. |
| `auto_cancel_pending_pipelines`                    | string  | No       | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                      | string  | No       | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                              | boolean | No       | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                      | boolean | No       | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                           | mixed   | No       | Image file for avatar of the project. |
| `build_git_strategy`                               | string  | No       | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                    | integer | No       | The maximum amount of time, in seconds, that a job can run. |
| `ci_config_path`                                   | string  | No       | The path to CI configuration file. |
| `container_registry_enabled`                       | boolean | No       | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                   | string  | No       | The [default branch](../user/project/repository/branches/default.md) name. Requires `initialize_with_readme` to be `true`. |
| `description`                                      | string  | No       | Short project description. |
| `emails_disabled`                                  | boolean | No       | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead |
| `emails_enabled`                                   | boolean | No       | Enable email notifications. |
| `enforce_auth_checks_on_uploads`                   | boolean | No       | Enforce [auth checks](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) on uploads. |
| `external_authorization_classification_label`      | string  | No       | The classification label for the project. Premium and Ultimate only. |
| `group_runners_enabled`                            | boolean | No       | Enable group runners for this project. |
| `group_with_project_templates_id`                  | integer | No       | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. Premium and Ultimate only. |
| `import_url`                                       | string  | No       | URL to import repository from. |
| `initialize_with_readme`                           | boolean | No       | `false` by default. |
| `issue_branch_template`                            | string  | No       | Template used to suggest names for [branches created from issues](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) in GitLab 15.6.)_ |
| `issues_enabled`                                   | boolean | No       | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                     | boolean | No       | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                      | boolean | No       | Enable LFS. |
| `merge_commit_template`                            | string  | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create merge commit message in merge requests. |
| `merge_method`                                     | string  | No       | Set the project's [merge method](../user/project/merge_requests/methods/_index.md). Can be `merge` (merge commit), `rebase_merge` (merge commit with semi-linear history), or `ff` (fast-forward merge). |
| `merge_requests_enabled`                           | boolean | No       | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `mirror_trigger_builds`                            | boolean | No       | Pull mirroring triggers builds. Premium and Ultimate only. |
| `mirror`                                           | boolean | No       | Enables pull mirroring in a project. Premium and Ultimate only. |
| `namespace_id`                                     | integer | No       | Namespace for the new project (defaults to the current user's namespace). |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | No       | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean | No       | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. Ultimate only. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean | No       | Set whether merge requests can only be merged with successful jobs. |
| `packages_enabled`                                 | boolean | No       | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 17.10. Enable or disable packages repository feature. Use `package_registry_access_level` instead. |
| `package_registry_access_level`                    | string  | No       | Enable or disable packages repository feature. |
| `path`                                             | string  | No       | Custom repository name for new project. By default generated based on name. |
| `printing_merge_request_link_enabled`              | boolean | No       | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                    | boolean | No       | _(Deprecated)_ If `true`, jobs can be viewed by non-project members. Use `public_jobs` instead. |
| `public_jobs`                                      | boolean | No       | If `true`, jobs can be viewed by non-project members. |
| `repository_object_format`                         | string  | No       | Repository object format. Defaults to `sha1`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419887) in GitLab 16.9. |
| `remove_source_branch_after_merge`                 | boolean | No       | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_storage`                               | string  | No       | Which storage shard the repository is on. _(administrators only)_ |
| `request_access_enabled`                           | boolean | No       | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                | boolean | No       | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `shared_runners_enabled`                           | boolean | No       | Enable instance runners for this project. |
| `show_default_award_emojis`                        | boolean | No       | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean | No       | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `squash_commit_template`                           | string  | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create squash commit message in merge requests. |
| `squash_option`                                    | string  | No       | One of `never`, `always`, `default_on`, or `default_off`. |
| `suggestion_commit_message`                        | string  | No       | The commit message used to apply merge request [suggestions](../user/project/merge_requests/reviews/suggestions.md). |
| `tag_list`                                         | array   | No       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                    | string  | No       | When used without `use_custom_template`, name of a [built-in project template](../user/project/_index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
| `topics`                                           | array   | No       | The list of topics for the project. |
| `use_custom_template`                              | boolean | No       | Use either custom [instance](../administration/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. Premium and Ultimate only. |
| `visibility`                                       | string  | No       | See [project visibility level](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean | No       | Enable warnings about usage of potentially unwanted characters in this project. |
| `wiki_enabled`                                     | boolean | No       | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

To set the visibility level of individual project features,
see [Project feature visibility level](#project-feature-visibility-level).

### Edit a project

{{< history >}}

- `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
- `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.
- `packages_enabled` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 17.10.
- `package_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 18.5.

{{< /history >}}

Update an existing project.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
PUT /projects/:id
```

Supported general project attributes:

| Attribute                                          | Type              | Required | Description |
|:---------------------------------------------------|:------------------|:---------|:------------|
| `id`                                               | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `allow_merge_on_skipped_pipeline`                  | boolean           | No       | Set whether or not merge requests can be merged with skipped jobs. |
| `allow_pipeline_trigger_approve_deployment`        | boolean           | No       | Set whether or not a pipeline triggerer is allowed to approve deployments. Premium and Ultimate only. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean           | No       | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false.<br/><br/>[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. The feature flag was enabled by default in GitLab 15.9. Ultimate only. |
| `approvals_before_merge`                           | integer           | No       | How many approvers should approve merge requests by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). Premium and Ultimate only. |
| `auto_cancel_pending_pipelines`                    | string            | No       | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                      | string            | No       | Auto Deploy strategy (`continuous`, `manual`, or `timed_incremental`). |
| `auto_devops_enabled`                              | boolean           | No       | Enable Auto DevOps for this project. |
| `auto_duo_code_review_enabled`                     | boolean           | No       | Enable automatic reviews by GitLab Duo on merge requests. See [GitLab Duo in merge requests](../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code). Ultimate only. |
| `autoclose_referenced_issues`                      | boolean           | No       | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                           | mixed             | No       | Image file for avatar of the project. |
| `build_git_strategy`                               | string            | No       | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                    | integer           | No       | The maximum amount of time, in seconds, that a job can run. |
| `ci_config_path`                                   | string            | No       | The path to CI configuration file. |
| `ci_default_git_depth`                             | integer           | No       | Default number of revisions for [shallow cloning](../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone). |
| `ci_delete_pipelines_in_seconds`                   | integer           | No       | Pipelines older than the configured time are deleted. |
| `ci_forward_deployment_enabled`                    | boolean           | No       | Enable or disable [prevent outdated deployment jobs](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_forward_deployment_rollback_allowed`           | boolean           | No       | Enable or disable [allow job retries for rollback deployments](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean           | No       | Enable or disable [running pipelines in the parent project for merge requests from forks](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325189) in GitLab 15.3.)_ |
| `ci_id_token_sub_claim_components`                 | array             | No       | Fields included in the `sub` claim of the [ID Token](../ci/secrets/id_token_authentication.md). Accepts an array starting with `project_path`. The array might also include `ref_type`, `ref`, `environment_protected`, and `deployment_tier`. Defaults to `["project_path", "ref_type", "ref"]`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/477260) in GitLab 17.10. Support for `environment_protected` and `deployment_tier` introduced in GitLab 18.7. |
| `ci_separated_caches`                              | boolean           | No       | Set whether or not caches should be [separated](../ci/caching/_index.md#cache-key-names) by branch protection status. |
| `ci_restrict_pipeline_cancellation_role`           | string            | No       | Set the [role required to cancel a pipeline or job](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs). One of `developer`, `maintainer`, or `no_one`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429921) in GitLab 16.8. Premium and Ultimate only. |
| `ci_pipeline_variables_minimum_override_role`      | string            | No       | You can specify which role can override variables. One of `owner`, `maintainer`, `developer` or `no_one_allowed`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440338) in GitLab 17.1. In GitLab 17.1 to 17.7, `restrict_user_defined_variables` must be enabled. |
| `ci_push_repository_for_job_token_allowed`         | boolean           | No       | Enable or disable the ability to push to the project repository using job token. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) in GitLab 17.2. |
| `container_expiration_policy_attributes`           | hash              | No       | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). |
| `container_registry_enabled`                       | boolean           | No       | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                   | string            | No       | The [default branch](../user/project/repository/branches/default.md) name. |
| `description`                                      | string            | No       | Short project description. |
| `duo_remote_flows_enabled`                         | boolean           | No       | Determine whether or not [flows](../user/duo_agent_platform/flows/_index.md) can run in your project. |
| `emails_disabled`                                  | boolean           | No       | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead |
| `emails_enabled`                                   | boolean           | No       | Enable email notifications. |
| `enforce_auth_checks_on_uploads`                   | boolean           | No       | Enforce [auth checks](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) on uploads. |
| `external_authorization_classification_label`      | string            | No       | The classification label for the project. Premium and Ultimate only. |
| `group_runners_enabled`                            | boolean           | No       | Enable group runners for this project. |
| `import_url`                                       | string            | No       | URL the repository was imported from. |
| `issues_enabled`                                   | boolean           | No       | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `issues_template` | string | No | Default description for new issues. Formatted as GitLab Flavored Markdown. Premium and Ultimate only. |
| `merge_requests_template` | string | No | Default description for new merge requests. Formatted as GitLab Flavored Markdown. Premium and Ultimate only. |
| `jobs_enabled`                                     | boolean           | No       | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `keep_latest_artifact`                             | boolean           | No       | Disable or enable the ability to keep the latest artifact for this project. |
| `lfs_enabled`                                      | boolean           | No       | Enable LFS. |
| `max_artifacts_size`                               | integer           | No       | The maximum file size in megabytes for individual job artifacts. |
| `merge_commit_template`                            | string            | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create merge commit message in merge requests. |
| `merge_method`                                     | string            | No       | Set the project's [merge method](../user/project/merge_requests/methods/_index.md). Can be `merge` (merge commit), `rebase_merge` (merge commit with semi-linear history), or `ff` (fast-forward merge). |
| `merge_pipelines_enabled`                          | boolean           | No       | Enable or disable merged results pipelines. |
| `merge_requests_enabled`                           | boolean           | No       | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_trains_enabled`                             | boolean           | No       | Enable or disable merge trains. |
| `merge_trains_skip_train_allowed`                  | boolean           | No       | Allows merge train merge requests to be merged without waiting for pipelines to finish. |
| `mirror_overwrites_diverged_branches`              | boolean           | No       | Pull mirror overwrites diverged branches. Premium and Ultimate only. |
| `mirror_trigger_builds`                            | boolean           | No       | Pull mirroring triggers builds. Premium and Ultimate only. |
| `mirror_user_id`                                   | integer           | No       | User responsible for all the activity surrounding a pull mirror event. _(administrators only)_ Premium and Ultimate only. |
| `mirror`                                           | boolean           | No       | Enables pull mirroring in a project. Premium and Ultimate only. |
| `mr_default_target_self`                           | boolean           | No       | For forked projects, target merge requests to this project. If `false`, the target is the upstream project. |
| `name`                                             | string            | No       | The name of the project. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean           | No       | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean           | No       | Set whether merge requests can only be merged with successful jobs. |
| `only_mirror_protected_branches`                   | boolean           | No       | Only mirror protected branches. Premium and Ultimate only. |
| `packages_enabled`                                 | boolean           | No       | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) in GitLab 17.10. Enable or disable packages repository feature. Use `package_registry_access_level` instead. |
| `package_registry_access_level`                    | string  | No                 | Enable or disable packages repository feature. |
| `path`                                             | string            | No       | Custom repository name for the project. By default generated based on name. |
| `prevent_merge_without_jira_issue`                 | boolean           | No       | Set whether merge requests require an associated issue from Jira. Ultimate only. |
| `printing_merge_request_link_enabled`              | boolean           | No       | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                    | boolean           | No       | _(Deprecated)_ If `true`, jobs can be viewed by non-project members. Use `public_jobs` instead. |
| `public_jobs`                                      | boolean           | No       | If `true`, jobs can be viewed by non-project members. |
| `remove_source_branch_after_merge`                 | boolean           | No       | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_storage`                               | string            | No       | Which storage shard the repository is on. _(administrators only)_ |
| `request_access_enabled`                           | boolean           | No       | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                | boolean           | No       | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `restrict_user_defined_variables`                  | boolean           | No       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510) in GitLab 17.7 in favour of `ci_pipeline_variables_minimum_override_role`)_ Allow only users with the Maintainer role to pass user-defined variables when triggering a pipeline. For example when the pipeline is triggered in the UI, with the API, or by a trigger token. |
| `service_desk_enabled`                             | boolean           | No       | Enable or disable Service Desk feature. |
| `shared_runners_enabled`                           | boolean           | No       | Enable instance runners for this project. |
| `show_default_award_emojis`                        | boolean           | No       | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean           | No       | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `issue_branch_template`                            | string            | No       | Template used to suggest names for [branches created from issues](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) in GitLab 15.6.)_ |
| `spp_repository_pipeline_access`                   | boolean           | No       | Allow users and tokens read-only access to fetch security policy configurations from this project. Required for enforcing security policies in projects that use this project as their security policy source. Ultimate only. |
| `squash_commit_template`                           | string            | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create squash commit message in merge requests. |
| `squash_option`                                    | string            | No       | One of `never`, `always`, `default_on`, or `default_off`. |
| `suggestion_commit_message`                        | string            | No       | The commit message used to apply merge request suggestions. |
| `tag_list`                                         | array             | No       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `topics`                                           | array             | No       | The list of topics for the project. This replaces any existing topics that are already added to the project. |
| `visibility`                                       | string            | No       | See [project visibility level](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean           | No       | Enable warnings about usage of potentially unwanted characters in this project. |
| `wiki_enabled`                                     | boolean           | No       | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |
| `web_based_commit_signing_enabled`                 | boolean           | No       | Enables web-based commit signing for commits created from the GitLab UI. Available only on GitLab SaaS. |

For example, to toggle the setting for [instance runners on a GitLab.com project](../ci/runners/_index.md):

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your-token>" \
     --url "https://gitlab.com/api/v4/projects/<your-project-ID>" \
     --data "shared_runners_enabled=true" # to turn off: "shared_runners_enabled=false"
```

To set the visibility level of individual project features,
see [Project feature visibility level](#project-feature-visibility-level).

### Import members

Import members from another project.

If the importing member's role for the target project is:

- Maintainer, then members with the Owner role for the source project are imported with the Maintainer role.
- Owner, then members with the Owner role for the source project are imported with the Owner role.

```plaintext
POST /projects/:id/import_project_members/:project_id
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|:-------------|:------------------|:---------|:------------|
| `id`         | integer or string | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the target project to receive the members. |
| `project_id` | integer or string | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the source project to import the members from. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/import_project_members/32"
```

Returns:

- `200 OK` on success.
- `404 Project Not Found` if the target or source project does not exist or cannot be accessed by the requester.
- `422 Unprocessable Entity` if the import of project members does not complete successfully.

Example responses:

- When all emails were successfully sent (`200` HTTP status code):

  ```json
  {  "status":  "success"  }
  ```

- When there was any error importing 1 or more members (`200` HTTP status code):

  ```json
  {
    "status": "error",
    "message": {
                 "john_smith": "Some individual error message",
                 "jane_smith": "Some individual error message"
               },
    "total_members_count": 3
  }
  ```

- When there is a system error (`404` and `422` HTTP status codes):

```json
{  "message":  "Import failed"  }
```

### Archive a project

Archive a project.

Prerequisites:

- You must be an administrator or be assigned the Owner role on the project.

This endpoint is idempotent. Archiving an already-archived project does not change the project.

```plaintext
POST /projects/:id/archive
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/archive"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "secret_push_protection_enabled": false,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

### Unarchive a project

Unarchive a project.

Prerequisites:

- You must be an administrator or be assigned the Owner role on the project.

This endpoint is idempotent. Unarchiving a project that isn't archived doesn't change the project.

```plaintext
POST /projects/:id/unarchive
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/unarchive"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "secret_push_protection_enabled": false,
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

### Delete a project

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 16.0. Premium and Ultimate only.
- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must be an administrator or have the Owner role for the project.

Marks a project for deletion. Projects are deleted at the end of the retention period:

- On GitLab.com, projects are retained for 30 days.
- On GitLab Self-Managed, the retention period is controlled by the
  [instance settings](../administration/settings/visibility_and_access_controls.md#deletion-protection).

This endpoint can also immediately delete a project that was previously marked for deletion.

> [!warning]
> On GitLab.com, after a project is deleted, its data is retained for 30 days, and permanent deletion is not available.
> If you really need to delete a project immediately on GitLab.com, you can open a [support ticket](https://about.gitlab.com/support/).

```plaintext
DELETE /projects/:id
```

Supported attributes:

| Attribute            | Type              | Required | Description |
|:---------------------|:------------------|:---------|:------------|
| `id`                 | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `full_path`          | string            | no       | Full path of project to use with `permanently_remove`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11 for Premium and Ultimate only and moved to GitLab Free in 18.0. To find the project path, use `path_with_namespace` from [get single project](projects.md#retrieve-a-project). |
| `permanently_remove` | boolean/string    | no       | Immediately deletes a project if it is marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11 for Premium and Ultimate only and moved to GitLab Free in 18.0. Disabled on GitLab.com and Dedicated. |

### Restore a project marked for deletion

Restore a project that is marked for deletion.

```plaintext
POST /projects/:id/restore
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

### Transfer a project to a new namespace

Transfer a project to a new namespace.

For information on prerequisites for transferring a project, see
[Transfer a project to another namespace](../user/project/working_with_projects.md#transfer-a-project).

```plaintext
PUT /projects/:id/transfer
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|:------------|:------------------|:---------|:------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `namespace` | integer or string | Yes      | The ID or path of the namespace to transfer to project to. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/transfer?namespace=14"
```

Example response:

```json
  {
  "id": 7,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "name": "hello-world",
  "name_with_namespace": "cute-cats / hello-world",
  "path": "hello-world",
  "path_with_namespace": "cute-cats/hello-world",
  "created_at": "2020-10-15T16:25:22.415Z",
  "updated_at": "2020-10-15T16:25:22.415Z",
  "default_branch": "main",
  "tag_list": [], //deprecated, use `topics` instead
  "topics": [],
  "ssh_url_to_repo": "git@gitlab.example.com:cute-cats/hello-world.git",
  "http_url_to_repo": "https://gitlab.example.com/cute-cats/hello-world.git",
  "web_url": "https://gitlab.example.com/cute-cats/hello-world",
  "readme_url": "https://gitlab.example.com/cute-cats/hello-world/-/blob/main/README.md",
  "avatar_url": null,
  "forks_count": 0,
  "star_count": 0,
  "last_activity_at": "2020-10-15T16:25:22.415Z",
  "namespace": {
    "id": 18,
    "name": "cute-cats",
    "path": "cute-cats",
    "kind": "group",
    "full_path": "cute-cats",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/cute-cats"
  },
  "container_registry_image_prefix": "registry.example.com/cute-cats/hello-world",
  "_links": {
    "self": "https://gitlab.example.com/api/v4/projects/7",
    "issues": "https://gitlab.example.com/api/v4/projects/7/issues",
    "merge_requests": "https://gitlab.example.com/api/v4/projects/7/merge_requests",
    "repo_branches": "https://gitlab.example.com/api/v4/projects/7/repository/branches",
    "labels": "https://gitlab.example.com/api/v4/projects/7/labels",
    "events": "https://gitlab.example.com/api/v4/projects/7/events",
    "members": "https://gitlab.example.com/api/v4/projects/7/members"
  },
  "packages_enabled": true, // deprecated, use package_registry_access_level instead
  "package_registry_access_level": "enabled",
  "empty_repo": false,
  "archived": false,
  "visibility": "private",
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": true, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "enabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null,
    "name_regex_keep": null,
    "next_run_at": "2020-10-22T16:25:22.746Z"
  },
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wiki_enabled": true,
  "jobs_enabled": true,
  "snippets_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "can_create_merge_request_in": true,
  "issues_access_level": "enabled",
  "repository_access_level": "enabled",
  "merge_requests_access_level": "enabled",
  "forking_access_level": "enabled",
  "analytics_access_level": "enabled",
  "wiki_access_level": "enabled",
  "builds_access_level": "enabled",
  "snippets_access_level": "enabled",
  "pages_access_level": "enabled",
  "security_and_compliance_access_level": "enabled",
  "emails_disabled": null,
  "emails_enabled": null,
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "lfs_enabled": true,
  "creator_id": 2,
  "import_status": "none",
  "open_issues_count": 0,
  "ci_default_git_depth": 50,
  "public_jobs": true,
  "build_timeout": 3600,
  "auto_cancel_pending_pipelines": "enabled",
  "ci_config_path": null,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": null,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "request_access_enabled": true,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": true,
  "printing_merge_request_link_enabled": true,
  "merge_method": "merge",
  "squash_option": "default_on",
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "autoclose_referenced_issues": true,
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "compliance_frameworks": [],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false
}
```

#### List groups available for project transfer

Retrieve a list of groups to which the user can transfer a project.

```plaintext
GET /projects/:id/transfer_locations
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`  | string            | No       | The group names to search for. |

Example request:

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/transfer_locations"
```

Example response:

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

### Upload a project avatar

Upload an avatar to the specified project.

```plaintext
PUT /projects/:id
```

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- Your file must be 200 KB or smaller. The ideal image size is 192 x 192 pixels.
- The image must be one of the following file types:
  - `.bmp`
  - `.gif`
  - `.ico`
  - `.jpeg`
  - `.png`
  - `.tiff`

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `avatar`  | string            | Yes      | The file to be uploaded. |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

To upload an avatar from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`avatar=` parameter must point to an image file on your file system and be
preceded by `@`.

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5" \
  --form "avatar=@dk.png"
```

Example response:

```json
{
  "avatar_url": "https://gitlab.example.com/uploads/-/system/project/avatar/2/dk.png"
}
```

### Download a project avatar

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144039) in GitLab 16.9.

{{< /history >}}

Download a project avatar. You can access this endpoint without authentication if the project is publicly accessible.

```plaintext
GET /projects/:id/avatar
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/avatar"
```

### Remove a project avatar

To remove a project avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "avatar=" "https://gitlab.example.com/api/v4/projects/5"
```

## Share projects

Share a project with a group.

For more information, see [Invite a group to a project](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project).

### Share a project with a group

Share a project with a group.

```plaintext
POST /projects/:id/share
```

Supported attributes:

| Attribute      | Type              | Required | Description |
|:---------------|:------------------|:---------|:------------|
| `group_access` | integer           | Yes      | The access level to grant to the group. Possible values: `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner). |
| `group_id`     | integer           | Yes      | The ID of the group to share with. |
| `id`           | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `expires_at`   | string            | No       | Share expiration date in ISO 8601 format. For example, `2016-09-26`. |

### Delete a shared project link in a group

Unshare the project from the group. Returns `204` and no content on success.

```plaintext
DELETE /projects/:id/share/:group_id
```

Supported attributes:

| Attribute  | Type              | Required | Description |
|:-----------|:------------------|:---------|:------------|
| `group_id` | integer           | Yes      | The ID of the group. |
| `id`       | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## Start the housekeeping task for a project

Start the [housekeeping task](../administration/housekeeping.md) for a project.

```plaintext
POST /projects/:id/housekeeping
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `task`    | string            | No       | `prune` to trigger manual prune of unreachable objects or `eager` to trigger eager housekeeping. |

## Real-time security scan

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/479210) in GitLab 17.6. This feature is an [experiment](../policy/development_stages_support.md).

{{< /history >}}

Returns SAST scan results for a single file in real-time.

```plaintext
POST /projects/:id/security_scans/sast/scan
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "file_path":"src/main.c",
  "content":"#include<string.h>\nint main(int argc, char **argv) {\n  char buff[128];\n  strcpy(buff, argv[1]);\n  return 0;\n}\n"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/:id/security_scans/sast/scan"
```

Example response:

```json
{
  "vulnerabilities": [
    {
      "name": "Insecure string processing function (strcpy)",
      "description": "The `strcpy` family of functions do not provide the ability to limit or check buffer\nsizes before copying to a destination buffer. This can lead to buffer overflows. Consider\nusing more secure alternatives such as `strncpy` and provide the correct limit to the\ndestination buffer and ensure the string is null terminated.\n\nFor more information please see: https://linux.die.net/man/3/strncpy\n\nIf developing for C Runtime Library (CRT), more secure versions of these functions should be\nused, see:\nhttps://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/strncpy-s-strncpy-s-l-wcsncpy-s-wcsncpy-s-l-mbsncpy-s-mbsncpy-s-l?view=msvc-170\n",
      "severity": "High",
      "location": {
        "file": "src/main.c",
        "start_line": 5,
        "end_line": 5,
        "start_column": 3,
        "end_column": 23
      }
    }
  ]
}
```

## Download snapshot of a Git repository

This endpoint may only be accessed by an administrative user.

Download a snapshot of the project (or wiki, if requested) Git repository. This
snapshot is always in uncompressed [tar](https://en.wikipedia.org/wiki/Tar_(computing))
format.

If a repository is corrupted to the point where `git clone` doesn't work, the
snapshot may allow some of the data to be retrieved.

```plaintext
GET /projects/:id/snapshot
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `wiki`    | boolean           | No       | Whether to download the wiki, rather than project, repository. |

## Get the path to repository storage

Get the path to repository storage for the specified project. If you're using Gitaly Cluster (Praefect), see [Praefect-generated replica paths](../administration/gitaly/praefect/_index.md#praefect-generated-replica-paths) instead.

Available for administrators only.

```plaintext
GET /projects/:id/storage
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```json
[
  {
    "project_id": 1,
    "disk_path": "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
    "created_at": "2012-10-12T17:04:47Z",
    "repository_storage": "default"
  }
]
```

## Secret push protection status

{{< details >}}

- Tier: Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160960) in GitLab 17.3.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186602) from `setPreReceiveSecretDetection` in GitLab 17.11.

{{< /history >}}

If you have the Developer, Maintainer, or Owner role, the following requests could also return the `secret_push_protection_enabled` value.
Some of these requests have stricter requirements about roles. Refer to the endpoints previously mentioned for clarification.
Use this information to determine whether secret push protection is enabled for a project.
To modify the `secret_push_protection_enabled` value, use the [Project Security Settings API](project_security_settings.md).

- `GET /projects`
- `GET /projects/:id`
- `GET /users/:user_id/projects`
- `GET /users/:user_id/contributed_projects`
- `PUT /projects/:project_id/transfer?namespace=:namespace_id`
- `PUT /projects/:id`
- `POST /projects`
- `POST /projects/user/:user_id`
- `POST /projects/:id/archive`
- `POST /projects/:id/unarchive`

Example response:

```json
{
  "id": 1,
  "project_id": 3,
  "secret_push_protection_enabled": true,
  ...
}
```

## Troubleshooting

### Unexpected `restrict_user_defined_variables` value in response

If you set conflicting values for `restrict_user_defined_variables` and `ci_pipeline_variables_minimum_override_role`,
the response values might differ from what you expect because the `pipeline_variables_minimum_override_role`
setting has higher priority.

For example, if you:

- Set `restrict_user_defined_variables` to `true` and `ci_pipeline_variables_minimum_override_role` to `developer`,
  the response returns `restrict_user_defined_variables: false`. Setting `ci_pipeline_variables_minimum_override_role`
  to `developer` takes precedence and variables are not restricted.
- Set `restrict_user_defined_variables` to `false` and `ci_pipeline_variables_minimum_override_role` to `maintainer`,
  The response returns `restrict_user_defined_variables: true` because setting `ci_pipeline_variables_minimum_override_role`
  to `maintainer` takes precedence and variables are restricted.
