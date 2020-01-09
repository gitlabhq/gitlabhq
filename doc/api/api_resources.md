# API resources

Available resources for the [GitLab API](README.md) can be grouped in the following contexts:

- [Projects](#project-resources).
- [Groups](#group-resources).
- [Standalone](#standalone-resources).

See also:

- [V3 to V4](v3_to_v4.md).
- Adding [deploy keys for multiple projects](deploy_key_multiple_projects.md).
- [API Resources for various templates](#templates-api-resources).

## Project resources

The following API resources are available in the project context:

| Resource                                                            | Available endpoints                                                                                                                                                                                   |
|:--------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Access requests](access_requests.md)                               | `/projects/:id/access_requests` (also available for groups)                                                                                                                                           |
| [Award emoji](award_emoji.md)                                       | `/projects/:id/issues/.../award_emoji`, `/projects/:id/merge_requests/.../award_emoji`, `/projects/:id/snippets/.../award_emoji`                                                                      |
| [Branches](branches.md)                                             | `/projects/:id/repository/branches/`, `/projects/:id/repository/merged_branches`                                                                                                                      |
| [Commits](commits.md)                                               | `/projects/:id/repository/commits`, `/projects/:id/statuses`                                                                                                                                          |
| [Container Registry](container_registry.md)                         | `/projects/:id/registry/repositories`                                                                                                                                                                 |
| [Custom attributes](custom_attributes.md)                           | `/projects/:id/custom_attributes` (also available for groups and users)                                                                                                                               |
| [Dependencies](dependencies.md) **(ULTIMATE)**                      | `/projects/:id/dependencies`                                                                                                                                                                          |
| [Deploy keys](deploy_keys.md)                                       | `/projects/:id/deploy_keys` (also available standalone)                                                                                                                                               |
| [Deployments](deployments.md)                                       | `/projects/:id/deployments`                                                                                                                                                                           |
| [Discussions](discussions.md) (threaded comments)                   | `/projects/:id/issues/.../discussions`, `/projects/:id/snippets/.../discussions`, `/projects/:id/merge_requests/.../discussions`, `/projects/:id/commits/.../discussions` (also available for groups) |
| [Environments](environments.md)                                     | `/projects/:id/environments`                                                                                                                                                                          |
| [Events](events.md)                                                 | `/projects/:id/events` (also available for users and standalone)                                                                                                                                      |
| [Issues](issues.md)                                                 | `/projects/:id/issues` (also available for groups and standalone)                                                                                                                                     |
| [Issues Statistics](issues_statistics.md)                           | `/projects/:id/issues_statistics` (also available for groups and standalone)                                                                                                                          |
| [Issue boards](boards.md)                                           | `/projects/:id/boards`                                                                                                                                                                                |
| [Issue links](issue_links.md) **(STARTER)**                         | `/projects/:id/issues/.../links`                                                                                                                                                                      |
| [Jobs](jobs.md)                                                     | `/projects/:id/jobs`, `/projects/:id/pipelines/.../jobs`                                                                                                                                              |
| [Labels](labels.md)                                                 | `/projects/:id/labels`                                                                                                                                                                                |
| [Managed licenses](managed_licenses.md) **(ULTIMATE)**              | `/projects/:id/managed_licenses`                                                                                                                                                                      |
| [Members](members.md)                                               | `/projects/:id/members` (also available for groups)                                                                                                                                                   |
| [Merge request approvals](merge_request_approvals.md) **(STARTER)** | `/projects/:id/approvals`, `/projects/:id/merge_requests/.../approvals`                                                                                                                               |
| [Merge requests](merge_requests.md)                                 | `/projects/:id/merge_requests` (also available for groups and standalone)                                                                                                                             |
| [Notes](notes.md) (comments)                                        | `/projects/:id/issues/.../notes`, `/projects/:id/snippets/.../notes`, `/projects/:id/merge_requests/.../notes` (also available for groups)                                                            |
| [Notification settings](notification_settings.md)                   | `/projects/:id/notification_settings` (also available for groups and standalone)                                                                                                                      |
| [Packages](packages.md) **(PREMIUM)**                               | `/projects/:id/packages`                                                                                                                                                                              |
| [Pages domains](pages_domains.md)                                   | `/projects/:id/pages` (also available standalone)                                                                                                                                                     |
| [Pipelines](pipelines.md)                                           | `/projects/:id/pipelines`                                                                                                                                                                             |
| [Pipeline schedules](pipeline_schedules.md)                         | `/projects/:id/pipeline_schedules`                                                                                                                                                                    |
| [Pipeline triggers](pipeline_triggers.md)                           | `/projects/:id/triggers`                                                                                                                                                                              |
| [Projects](projects.md) including setting Webhooks                  | `/projects`, `/projects/:id/hooks` (also available for users)                                                                                                                                         |
| [Project badges](project_badges.md)                                 | `/projects/:id/badges`                                                                                                                                                                                |
| [Project clusters](project_clusters.md)                             | `/projects/:id/clusters`                                                                                                                                                                              |
| [Project-level variables](project_level_variables.md)               | `/projects/:id/variables`                                                                                                                                                                             |
| [Project import/export](project_import_export.md)                   | `/projects/:id/export`, `/projects/import`, `/projects/:id/import`                                                                                                                                    |
| [Project milestones](milestones.md)                                 | `/projects/:id/milestones`                                                                                                                                                                            |
| [Project snippets](project_snippets.md)                             | `/projects/:id/snippets`                                                                                                                                                                              |
| [Project templates](project_templates.md)                           | `/projects/:id/templates`                                                                                                                                                                             |
| [Protected branches](protected_branches.md)                         | `/projects/:id/protected_branches`                                                                                                                                                                    |
| [Protected tags](protected_tags.md)                                 | `/projects/:id/protected_tags`                                                                                                                                                                        |
| [Releases](releases/index.md)                                       | `/projects/:id/releases`                                                                                                                                                                              |
| [Release links](releases/links.md)                                  | `/projects/:id/releases/.../assets/links`                                                                                                                                                             |
| [Repositories](repositories.md)                                     | `/projects/:id/repository`                                                                                                                                                                            |
| [Repository files](repository_files.md)                             | `/projects/:id/repository/files`                                                                                                                                                                      |
| [Repository submodules](repository_submodules.md)                   | `/projects/:id/repository/submodules`                                                                                                                                                                 |
| [Resource label events](resource_label_events.md)                   | `/projects/:id/issues/.../resource_label_events`, `/projects/:id/merge_requests/.../resource_label_events` (also available for groups)                                                                |
| [Runners](runners.md)                                               | `/projects/:id/runners` (also available standalone)                                                                                                                                                   |
| [Search](search.md)                                                 | `/projects/:id/search` (also available for groups and standalone)                                                                                                                                     |
| [Services](services.md)                                             | `/projects/:id/services`                                                                                                                                                                              |
| [Tags](tags.md)                                                     | `/projects/:id/repository/tags`                                                                                                                                                                       |
| [Visual Review discussions](visual_review_discussions.md) **(STARTER**) | `/projects/:id/merge_requests/:merge_request_id/visual_review_discussions`                                                                                                                        |
| [Vulnerabilities](vulnerabilities.md) **(ULTIMATE)**                | `/projects/:id/vulnerabilities`                                                                                                                                                                       |
| [Vulnerability Findings](vulnerability_findings.md) **(ULTIMATE)**  | `/projects/:id/vulnerability_findings`                                                                                                                                                                |
| [Wikis](wikis.md)                                                   | `/projects/:id/wikis`                                                                                                                                                                                 |

## Group resources

The following API resources are available in the group context:

| Resource                                                         | Available endpoints                                                              |
|:-----------------------------------------------------------------|:---------------------------------------------------------------------------------|
| [Access requests](access_requests.md)                            | `/groups/:id/access_requests/` (also available for projects)                     |
| [Custom attributes](custom_attributes.md)                        | `/groups/:id/custom_attributes` (also available for projects and users)          |
| [Discussions](discussions.md) (threaded comments) **(ULTIMATE)** | `/groups/:id/epics/.../discussions` (also available for projects)                |
| [Epic issues](epic_issues.md) **(ULTIMATE)**                     | `/groups/:id/epics/.../issues`                                                   |
| [Epic links](epic_links.md) **(ULTIMATE)**                       | `/groups/:id/epics/.../epics`                                                    |
| [Epics](epics.md) **(ULTIMATE)**                                 | `/groups/:id/epics`                                                              |
| [Groups](groups.md)                                              | `/groups`, `/groups/.../subgroups`                                               |
| [Group badges](group_badges.md)                                  | `/groups/:id/badges`                                                             |
| [Group issue boards](group_boards.md)                            | `/groups/:id/boards`                                                             |
| [Group labels](group_labels.md)                                  | `/groups/:id/labels`                                                             |
| [Group-level variables](group_level_variables.md)                | `/groups/:id/variables`                                                          |
| [Group milestones](group_milestones.md)                          | `/groups/:id/milestones`                                                         |
| [Issues](issues.md)                                              | `/groups/:id/issues` (also available for projects and standalone)                |
| [Issues Statistics](issues_statistics.md)                        | `/groups/:id/issues_statistics` (also available for projects and standalone)     |
| [Members](members.md)                                            | `/groups/:id/members` (also available for projects)                              |
| [Merge requests](merge_requests.md)                              | `/groups/:id/merge_requests` (also available for projects and standalone)        |
| [Notes](notes.md) (comments)                                     | `/groups/:id/epics/.../notes` (also available for projects)                      |
| [Notification settings](notification_settings.md)                | `/groups/:id/notification_settings` (also available for projects and standalone) |
| [Resource label events](resource_label_events.md)                | `/groups/:id/epics/.../resource_label_events` (also available for projects)      |
| [Search](search.md)                                              | `/groups/:id/search` (also available for projects and standalone)                |

## Standalone resources

The following API resources are available outside of project and group contexts (including `/users`):

| Resource                                          | Available endpoints                                                     |
|:--------------------------------------------------|:------------------------------------------------------------------------|
| [Appearance](appearance.md) **(CORE ONLY)**       | `/application/appearance`                                               |
| [Applications](applications.md)                   | `/applications`                                                         |
| [Audit Events](audit_events.md) **(PREMIUM ONLY)** | `/audit_events`                                                         |
| [Avatar](avatar.md)                               | `/avatar`                                                               |
| [Broadcast messages](broadcast_messages.md)       | `/broadcast_messages`                                                   |
| [Code snippets](snippets.md)                      | `/snippets`                                                             |
| [Custom attributes](custom_attributes.md)         | `/users/:id/custom_attributes` (also available for groups and projects) |
| [Deploy keys](deploy_keys.md)                     | `/deploy_keys` (also available for projects)                            |
| [Events](events.md)                               | `/events`, `/users/:id/events` (also available for projects)            |
| [Feature flags](features.md)                      | `/features`                                                             |
| [Geo Nodes](geo_nodes.md) **(PREMIUM ONLY)**      | `/geo_nodes`                                                            |
| [Import repository from GitHub](import.md)        | `/import/github`                                                        |
| [Issues](issues.md)                               | `/issues` (also available for groups and projects)                      |
| [Issues Statistics](issues_statistics.md)         | `/issues_statistics` (also available for groups and projects)           |
| [Keys](keys.md)                                   | `/keys`                                                                 |
| [License](license.md) **(CORE ONLY)**             | `/license`                                                              |
| [Markdown](markdown.md)                           | `/markdown`                                                             |
| [Merge requests](merge_requests.md)               | `/merge_requests` (also available for groups and projects)              |
| [Namespaces](namespaces.md)                       | `/namespaces`                                                           |
| [Notification settings](notification_settings.md) | `/notification_settings` (also available for groups and projects)       |
| [Pages domains](pages_domains.md)                 | `/pages/domains` (also available for projects)                          |
| [Projects](projects.md)                           | `/users/:id/projects` (also available for projects)                     |
| [Runners](runners.md)                             | `/runners` (also available for projects)                                |
| [Search](search.md)                               | `/search` (also available for groups and projects)                      |
| [Settings](settings.md)                           | `/application/settings`                                                 |
| [Statistics](statistics.md)                       | `/application/statistics`                                               |
| [Sidekiq metrics](sidekiq_metrics.md)             | `/sidekiq`                                                              |
| [Suggestions](suggestions.md)                     | `/suggestions`                                                          |
| [System hooks](system_hooks.md)                   | `/hooks`                                                                |
| [Todos](todos.md)                                 | `/todos`                                                                |
| [Users](users.md)                                 | `/users`                                                                |
| [Validate `.gitlab-ci.yml` file](lint.md)         | `/lint`                                                                 |
| [Version](version.md)                             | `/version`                                                              |

## Templates API resources

Endpoints are available for:

- [Dockerfile templates](templates/dockerfiles.md).
- [`.gitignore` templates](templates/gitignores.md).
- [GitLab CI YAML templates](templates/gitlab_ci_ymls.md).
- [Open source license templates](templates/licenses.md).
