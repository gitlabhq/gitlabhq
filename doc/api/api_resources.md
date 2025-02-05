---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: REST API resources
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Available resources for the [GitLab REST API](_index.md) can be grouped in the following contexts:

- [Projects](#project-resources)
- [Groups](#group-resources)
- [Standalone](#standalone-resources)

See also:

- Adding [deploy keys for multiple projects](deploy_keys.md#add-deploy-keys-to-multiple-projects)
- [API Resources for various templates](#templates-api-resources)

## Project resources

The following API resources are available in the project context:

| Resource                                                                       | Available endpoints |
|--------------------------------------------------------------------------------|---------------------|
| [Access requests](access_requests.md)                                          | `/projects/:id/access_requests` (also available for groups) |
| [Access tokens](project_access_tokens.md)                                      | `/projects/:id/access_tokens` (also available for groups) |
| [Agents](cluster_agents.md)                                                    | `/projects/:id/cluster_agents` |
| [Branches](branches.md)                                                        | `/projects/:id/repository/branches/`, `/projects/:id/repository/merged_branches` |
| [Commits](commits.md)                                                          | `/projects/:id/repository/commits`, `/projects/:id/statuses` |
| [Container registry](container_registry.md)                                    | `/projects/:id/registry/repositories` |
| [Container repository protection rules](container_repository_protection_rules.md)  | `/projects/:id/registry/protection/repository/rules` |
| [Custom attributes](custom_attributes.md)                                      | `/projects/:id/custom_attributes` (also available for groups and users) |
| [Composer distributions](packages/composer.md)                                 | `/projects/:id/packages/composer` (also available for groups) |
| [Conan distributions](packages/conan.md)                                       | `/projects/:id/packages/conan` (also available standalone) |
| [Debian distributions](packages/debian_project_distributions.md)               | `/projects/:id/debian_distributions` (also available for groups) |
| [Debian packages](packages/debian.md)                                          | `/projects/:id/packages/debian` (also available for groups) |
| [Dependencies](dependencies.md)                                                | `/projects/:id/dependencies` |
| [Deploy keys](deploy_keys.md)                                                  | `/projects/:id/deploy_keys` (also available standalone) |
| [Deploy tokens](deploy_tokens.md)                                              | `/projects/:id/deploy_tokens` (also available for groups and standalone) |
| [Deployments](deployments.md)                                                  | `/projects/:id/deployments` |
| [Discussions](discussions.md) (threaded comments)                              | `/projects/:id/issues/.../discussions`, `/projects/:id/snippets/.../discussions`, `/projects/:id/merge_requests/.../discussions`, `/projects/:id/commits/.../discussions` (also available for groups) |
| [Draft Notes](draft_notes.md) (comments)                                       | `/projects/:id/merge_requests/.../draft_notes` |
| [Emoji reactions](emoji_reactions.md)                                          | `/projects/:id/issues/.../award_emoji`, `/projects/:id/merge_requests/.../award_emoji`, `/projects/:id/snippets/.../award_emoji` |
| [Environments](environments.md)                                                | `/projects/:id/environments` |
| [Error Tracking](error_tracking.md)                                            | `/projects/:id/error_tracking/settings` |
| [Events](events.md)                                                            | `/projects/:id/events` (also available for users and standalone) |
| [External status checks](status_checks.md)                                     | `/projects/:id/external_status_checks` |
| [Feature flag User Lists](feature_flag_user_lists.md)                          | `/projects/:id/feature_flags_user_lists` |
| [Feature flags](feature_flags.md)                                              | `/projects/:id/feature_flags` |
| [Freeze Periods](freeze_periods.md)                                            | `/projects/:id/freeze_periods` |
| [Go Proxy](packages/go_proxy.md)                                               | `/projects/:id/packages/go` |
| [Helm repository](packages/helm.md)                                            | `/projects/:id/packages/helm_repository` |
| [Integrations](integrations.md) (Formerly "services")                          | `/projects/:id/integrations` |
| [Invitations](invitations.md)                                                  | `/projects/:id/invitations` (also available for groups) |
| [Issue boards](boards.md)                                                      | `/projects/:id/boards` |
| [Issue links](issue_links.md)                                                  | `/projects/:id/issues/.../links` |
| [Issues Statistics](issues_statistics.md)                                      | `/projects/:id/issues_statistics` (also available for groups and standalone) |
| [Issues](issues.md)                                                            | `/projects/:id/issues` (also available for groups and standalone) |
| [Iterations](iterations.md)                                                    | `/projects/:id/iterations` (also available for groups) |
| [Project CI/CD job token scope](project_job_token_scopes.md)                   | `/projects/:id/job_token_scope` |
| [Jobs](jobs.md)                                                                | `/projects/:id/jobs`, `/projects/:id/pipelines/.../jobs` |
| [Jobs Artifacts](job_artifacts.md)                                             | `/projects/:id/jobs/:job_id/artifacts` |
| [Labels](labels.md)                                                            | `/projects/:id/labels` |
| [Maven repository](packages/maven.md)                                          | `/projects/:id/packages/maven` (also available for groups and standalone) |
| [Members](members.md)                                                          | `/projects/:id/members` (also available for groups) |
| [Merge request approvals](merge_request_approvals.md)                          | `/projects/:id/approvals`, `/projects/:id/merge_requests/.../approvals` |
| [Merge requests](merge_requests.md)                                            | `/projects/:id/merge_requests` (also available for groups and standalone) |
| [Merge trains](merge_trains.md)                                                | `/projects/:id/merge_trains` |
| [Metadata](metadata.md)                                                        | `/metadata` |
| [Model registry](model_registry.md)                                            | `/projects/:id/packages/ml_models/` |
| [Notes](notes.md) (comments)                                                   | `/projects/:id/issues/.../notes`, `/projects/:id/snippets/.../notes`, `/projects/:id/merge_requests/.../notes` (also available for groups) |
| [Notification settings](notification_settings.md)                              | `/projects/:id/notification_settings` (also available for groups and standalone) |
| [NPM repository](packages/npm.md)                                              | `/projects/:id/packages/npm` |
| [NuGet packages](packages/nuget.md)                                            | `/projects/:id/packages/nuget` (also available for groups) |
| [Packages](packages.md)                                                        | `/projects/:id/packages` |
| [Pages domains](pages_domains.md)                                              | `/projects/:id/pages/domains` (also available standalone) |
| [Pages settings](pages.md)                                                     | `/projects/:id/pages` |
| [Pipeline schedules](pipeline_schedules.md)                                    | `/projects/:id/pipeline_schedules` |
| [Pipeline triggers](pipeline_triggers.md)                                      | `/projects/:id/triggers` |
| [Pipelines](pipelines.md)                                                      | `/projects/:id/pipelines` |
| [Project badges](project_badges.md)                                            | `/projects/:id/badges` |
| [Project clusters](project_clusters.md)                                        | `/projects/:id/clusters` |
| [Project import/export](project_import_export.md)                              | `/projects/:id/export`, `/projects/import`, `/projects/:id/import` |
| [Project milestones](milestones.md)                                            | `/projects/:id/milestones` |
| [Project snippets](project_snippets.md)                                        | `/projects/:id/snippets` |
| [Project templates](project_templates.md)                                      | `/projects/:id/templates` |
| [Project vulnerabilities](project_vulnerabilities.md).                         | `/projects/:id/vulnerabilities` |
| [Project wikis](wikis.md)                                                      | `/projects/:id/wikis` |
| [Project-level variables](project_level_variables.md)                          | `/projects/:id/variables` |
| [Projects](projects.md) including setting Webhooks                             | `/projects`, `/projects/:id/hooks` (also available for users) |
| [Protected branches](protected_branches.md)                                    | `/projects/:id/protected_branches` |
| [Protected container registry](project_container_registry_protection_rules.md) | `/projects/:id/registry/protection/rules` |
| [Protected environments](protected_environments.md)                            | `/projects/:id/protected_environments` |
| [Protected packages](project_packages_protection_rules.md)                     | `/projects/:id/packages/protection/rules` |
| [Protected tags](protected_tags.md)                                            | `/projects/:id/protected_tags` |
| [PyPI packages](packages/pypi.md)                                              | `/projects/:id/packages/pypi` (also available for groups) |
| [Release links](releases/links.md)                                             | `/projects/:id/releases/.../assets/links` |
| [Releases](releases/_index.md)                                                 | `/projects/:id/releases` |
| [Remote mirrors](remote_mirrors.md)                                            | `/projects/:id/remote_mirrors` |
| [Repositories](repositories.md)                                                | `/projects/:id/repository` |
| [Repository files](repository_files.md)                                        | `/projects/:id/repository/files` |
| [Repository submodules](repository_submodules.md)                              | `/projects/:id/repository/submodules` |
| [Resource label events](resource_label_events.md)                              | `/projects/:id/issues/.../resource_label_events`, `/projects/:id/merge_requests/.../resource_label_events` (also available for groups) |
| [Ruby gems](packages/rubygems.md)                                              | `/projects/:id/packages/rubygems` |
| [Runners](runners.md)                                                          | `/projects/:id/runners` (also available standalone) |
| [Search](search.md)                                                            | `/projects/:id/search` (also available for groups and standalone) |
| [Tags](tags.md)                                                                | `/projects/:id/repository/tags` |
| [Terraform modules](packages/terraform-modules.md)                             | `/projects/:id/packages/terraform/modules` (also available standalone) |
| [Validate `.gitlab-ci.yml` file](lint.md)                                      | `/projects/:id/ci/lint` |
| [Vulnerabilities](vulnerabilities.md)                                          | `/vulnerabilities/:id` |
| [Vulnerability exports](vulnerability_exports.md)                              | `/projects/:id/vulnerability_exports` |
| [Vulnerability findings](vulnerability_findings.md)                            | `/projects/:id/vulnerability_findings` |

## Group resources

The following API resources are available in the group context:

| Resource                                                       | Available endpoints |
|----------------------------------------------------------------|---------------------|
| [Access requests](access_requests.md)                          | `/groups/:id/access_requests/` (also available for projects) |
| [Access tokens](group_access_tokens.md)                        | `/groups/:id/access_tokens` (also available for projects) |
| [Custom attributes](custom_attributes.md)                      | `/groups/:id/custom_attributes` (also available for projects and users) |
| [Debian distributions](packages/debian_group_distributions.md) | `/groups/:id/-/packages/debian` (also available for projects) |
| [Deploy tokens](deploy_tokens.md)                              | `/groups/:id/deploy_tokens` (also available for projects and standalone) |
| [Discussions](discussions.md) (comments and threads)           | `/groups/:id/epics/.../discussions` (also available for projects) |
| [Epic issues](epic_issues.md)                                  | `/groups/:id/epics/.../issues` |
| [Epic links](epic_links.md)                                    | `/groups/:id/epics/.../epics` |
| [Epics](epics.md)                                              | `/groups/:id/epics` |
| [Groups](groups.md)                                            | `/groups`, `/groups/.../subgroups` |
| [Group badges](group_badges.md)                                | `/groups/:id/badges` |
| [Group issue boards](group_boards.md)                          | `/groups/:id/boards` |
| [Group iterations](group_iterations.md)                        | `/groups/:id/iterations` (also available for projects) |
| [Group labels](group_labels.md)                                | `/groups/:id/labels` |
| [Group-level variables](group_level_variables.md)              | `/groups/:id/variables` |
| [Group milestones](group_milestones.md)                        | `/groups/:id/milestones` |
| [Group releases](group_releases.md)                            | `/groups/:id/releases` |
| [Group SSH certificates](group_ssh_certificates.md)            | `/groups/:id/ssh_certificates` |
| [Group wikis](group_wikis.md)                                  | `/groups/:id/wikis` |
| [Invitations](invitations.md)                                  | `/groups/:id/invitations` (also available for projects) |
| [Issues](issues.md)                                            | `/groups/:id/issues` (also available for projects and standalone) |
| [Issues Statistics](issues_statistics.md)                      | `/groups/:id/issues_statistics` (also available for projects and standalone) |
| [Linked epics](linked_epics.md)                                | `/groups/:id/epics/.../related_epics` |
| [Member Roles](member_roles.md)                                | `/groups/:id/member_roles` |
| [Members](members.md)                                          | `/groups/:id/members` (also available for projects) |
| [Merge requests](merge_requests.md)                            | `/groups/:id/merge_requests` (also available for projects and standalone) |
| [Notes](notes.md) (comments)                                   | `/groups/:id/epics/.../notes` (also available for projects) |
| [Notification settings](notification_settings.md)              | `/groups/:id/notification_settings` (also available for projects and standalone) |
| [Resource label events](resource_label_events.md)              | `/groups/:id/epics/.../resource_label_events` (also available for projects) |
| [Search](search.md)                                            | `/groups/:id/search` (also available for projects and standalone) |

## Standalone resources

The following API resources are available outside of project and group contexts (including `/users`):

| Resource                                                                                     | Available endpoints |
|----------------------------------------------------------------------------------------------|---------------------|
| [Appearance](appearance.md)                                                                  | `/application/appearance` |
| [Applications](applications.md)                                                              | `/applications` |
| [Audit events](audit_events.md)                                                              | `/audit_events` |
| [Avatar](avatar.md)                                                                          | `/avatar` |
| [Broadcast messages](broadcast_messages.md)                                                  | `/broadcast_messages` |
| [Code snippets](snippets.md)                                                                 | `/snippets` |
| [Code Suggestions](code_suggestions.md)                                                      | `/code_suggestions` |
| [Custom attributes](custom_attributes.md)                                                    | `/users/:id/custom_attributes` (also available for groups and projects) |
| [Dependency list exports](dependency_list_export.md)                                         | `/pipelines/:id/dependency_list_exports`, `/projects/:id/dependency_list_exports`, `/groups/:id/dependency_list_exports`, `/security/dependency_list_exports/:id`, `/security/dependency_list_exports/:id/download` |
| [Deploy keys](deploy_keys.md)                                                                | `/deploy_keys` (also available for projects) |
| [Deploy tokens](deploy_tokens.md)                                                            | `/deploy_tokens` (also available for projects and groups) |
| [Events](events.md)                                                                          | `/events`, `/users/:id/events` (also available for projects) |
| [Feature flags](features.md)                                                                 | `/features` |
| [Geo Nodes](geo_nodes.md)                                                                    | `/geo_nodes` |
| [Group Activity Analytics](group_activity_analytics.md)                                      | `/analytics/group_activity/{issues_count}` |
| [Group repository storage moves](group_repository_storage_moves.md)                          | `/group_repository_storage_moves` |
| [Import repository from GitHub](import.md#import-repository-from-github)                     | `/import/github` |
| [Import repository from Bitbucket Server](import.md#import-repository-from-bitbucket-server) | `/import/bitbucket_server` |
| [Instance clusters](instance_clusters.md)                                                    | `/admin/clusters` |
| [Instance-level CI/CD variables](instance_level_ci_variables.md)                             | `/admin/ci/variables` |
| [Issues Statistics](issues_statistics.md)                                                    | `/issues_statistics` (also available for groups and projects) |
| [Issues](issues.md)                                                                          | `/issues` (also available for groups and projects) |
| [Jobs](jobs.md)                                                                              | `/job` |
| [Keys](keys.md)                                                                              | `/keys` |
| [License](license.md)                                                                        | `/license` |
| [Markdown](markdown.md)                                                                      | `/markdown` |
| [Merge requests](merge_requests.md)                                                          | `/merge_requests` (also available for groups and projects) |
| [Namespaces](namespaces.md)                                                                  | `/namespaces` |
| [Notification settings](notification_settings.md)                                            | `/notification_settings` (also available for groups and projects) |
| [Pages domains](pages_domains.md)                                                            | `/pages/domains` (also available for projects) |
| [Personal access tokens](personal_access_tokens.md)                                          | `/personal_access_tokens` |
| [Plan limits](plan_limits.md)                                                                | `/application/plan_limits` |
| [Project repository storage moves](project_repository_storage_moves.md)                      | `/project_repository_storage_moves` |
| [Projects](projects.md)                                                                      | `/users/:id/projects` (also available for projects) |
| [Runners](runners.md)                                                                        | `/runners` (also available for projects) |
| [Search](search.md)                                                                          | `/search` (also available for groups and projects) |
| [Service Data](usage_data.md)                                                                | `/usage_data` (For GitLab instance [Administrator](../user/permissions.md) users only) |
| [Settings](settings.md)                                                                      | `/application/settings` |
| [Sidekiq metrics](sidekiq_metrics.md)                                                        | `/sidekiq` |
| [Sidekiq queues administration](admin_sidekiq_queues.md)                                     | `/admin/sidekiq/queues/:queue_name` |
| [Snippet repository storage moves](snippet_repository_storage_moves.md)                      | `/snippet_repository_storage_moves` |
| [Statistics](statistics.md)                                                                  | `/application/statistics` |
| [Suggestions](suggestions.md)                                                                | `/suggestions` |
| [System hooks](system_hooks.md)                                                              | `/hooks` |
| [To-dos](todos.md)                                                                           | `/todos` |
| [Token information](admin/token.md)                                                          | `/admin/token` |
| [Topics](topics.md)                                                                          | `/topics` |
| [Users](users.md)                                                                            | `/users` |
| [Web commits](web_commits.md)                                                                | `/web_commits/public_key` |
| [Version](version.md)                                                                        | `/version` |

## Templates API resources

Endpoints are available for:

- [Dockerfile templates](templates/dockerfiles.md)
- [`.gitignore` templates](templates/gitignores.md)
- [GitLab CI/CD YAML templates](templates/gitlab_ci_ymls.md)
- [Open source license templates](templates/licenses.md)
