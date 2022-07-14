---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Permissions and roles **(FREE)**

Users have different abilities depending on the role they have in a
particular group or project. If a user is both in a project's group and the
project itself, the highest role is used.

On [public and internal projects](../api/projects.md#project-visibility-level), the Guest role
(not to be confused with [Guest user](#free-guest-users)) is not enforced.

When a member leaves a team's project, all the assigned [issues](project/issues/index.md) and
[merge requests](project/merge_requests/index.md) are automatically unassigned.

GitLab [administrators](../administration/index.md) receive all permissions.

To add or import a user, you can follow the
[project members documentation](project/members/index.md).

## Principles behind permissions

See our [product handbook on permissions](https://about.gitlab.com/handbook/product/gitlab-the-product/#permissions-in-gitlab).

## Instance-wide user permissions

By default, users can create top-level groups and change their
usernames. A GitLab administrator can configure the GitLab instance to
[modify this behavior](../administration/user_settings.md).

## Project members permissions

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/219299) in GitLab 14.8, personal namespace owners appear with Owner role in new projects in their namespace. Introduced [with a flag](../administration/feature_flags.md) named `personal_project_owner_with_owner_access`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/351919) in GitLab 14.9. Feature flag `personal_project_owner_with_owner_access` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/219299).

A user's role determines what permissions they have on a project. The Owner role provides all permissions but is
available only:

- For group owners. The role is inherited for a group's projects.
- For Administrators.

Personal [namespace](group/index.md#namespaces) owners:

- Are displayed as having the Maintainer role on projects in the namespace, but have the same permissions as a user with the Owner role.
- In GitLab 14.9 and later, for new projects in the namespace, are displayed as having the Owner role.

For more information about how to manage project members, see
[members of a project](project/members/index.md).

The following table lists project permissions available for each role:

<!-- Keep this table sorted: By topic first, then by minimum role, then alphabetically. -->

| Action                                                                                                                                                                               | Guest    | Reporter | Developer | Maintainer | Owner    |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------|-----------|------------|----------|
| [Analytics](analytics/index.md):<br>View [issue analytics](analytics/issue_analytics.md)                                                                                             | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [merge request analytics](analytics/merge_request_analytics.md)                                                                             | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [value stream analytics](analytics/value_stream_analytics.md)                                                                               | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [DORA metrics](analytics/ci_cd_analytics.md)                                                                                                |          | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [CI/CD analytics](analytics/ci_cd_analytics.md)                                                                                             |          | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [code review analytics](analytics/code_review_analytics.md)                                                                                 |          | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [repository analytics](analytics/repository_analytics.md)                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>View licenses in [dependency list](application_security/dependency_list/index.md)                                          |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Create and run [on-demand DAST scans](application_security/dast/index.md#on-demand-scans)                                  |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Manage [security policy](application_security/policies/index.md)                                                           |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>View [dependency list](application_security/dependency_list/index.md)                                                      |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Create a [CVE ID Request](application_security/cve_id_request.md)                                                          |          |          |           | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Create or assign [security policy project](application_security/policies/index.md)                                         |          |          |           |            | ✓        |
| [Clusters](infrastructure/clusters/index.md):<br>View clusters                                                                                                                       |          |          | ✓         | ✓          | ✓        |
| [Clusters](infrastructure/clusters/index.md):<br>Manage clusters                                                                                                                     |          |          |           | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Create, edit, delete [cleanup policies](packages/container_registry/index.md#delete-images-by-using-a-cleanup-policy) |          |          |          | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Push an image to the Container Registry                                                                               |          |          | ✓         | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Pull an image from the Container Registry                                                                             | ✓ (*20*) | ✓ (*20*) | ✓         | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Remove a Container Registry image                                                                                     |          |          | ✓         | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>View Pages protected by [access control](project/pages/introduction.md#gitlab-pages-access-control)                                       | ✓        | ✓        | ✓         | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>Manage                                                                                                                                    |          |          |           | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>Manage GitLab Pages domains and certificates                                                                                              |          |          |           | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>Remove GitLab Pages                                                                                                                       |          |          |           | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [alerts](../operations/incident_management/alerts.md)                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Assign an alert                                                                                                | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [incident](../operations/incident_management/incidents.md)                                                | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Create [incident](../operations/incident_management/incidents.md)                                              | (*16*)   | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [on-call schedules](../operations/incident_management/oncall_schedules.md)                                |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Participate in on-call rotation                                                                                | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [escalation policies](../operations/incident_management/escalation_policies.md)                           |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [on-call schedules](../operations/incident_management/oncall_schedules.md)                              |          |          |           | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [escalation policies](../operations/incident_management/escalation_policies.md)                         |          |          |           | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Add Labels                                                                                                                                     | ✓ (*15*) | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Assign                                                                                                                                         | ✓ (*15*) | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Create (*18*)                                                                                                                                  | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Create [confidential issues](project/issues/confidential_issues.md)                                                                            | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>View [Design Management](project/issues/design_management.md) pages                                                                            | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>View [related issues](project/issues/related_issues.md)                                                                                        | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Set [weight](project/issues/issue_weight.md)                                                                                                   | ✓ (*15*) | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>View [confidential issues](project/issues/confidential_issues.md)                                                                              | (*2*)    | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Close / reopen (*19*)                                                                                                                          |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Lock threads                                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Manage [related issues](project/issues/related_issues.md)                                                                                      |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Manage tracker                                                                                                                                 |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Move issues (*14*)                                                                                                                             |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Set issue [time tracking](project/time_tracking.md) estimate and time spent                                                                    |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Archive [Design Management](project/issues/design_management.md) files                                                                         |          |          | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Upload [Design Management](project/issues/design_management.md) files                                                                          |          |          | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Delete                                                                                                                                         |          |          |           |            | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>View allowed and denied licenses                                                                                    | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>View License Compliance reports                                                                                     | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>View License list                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>Manage license policy                                                                                               |          |          |           | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Assign reviewer                                                                                                                |          | ✓        | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>See list                                                                                                                       |          | ✓        | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Apply code change suggestions                                                                                                  |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Approve (*8*)                                                                                                                  |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Assign                                                                                                                         |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Create (*17*)                                                                                                                  |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Add labels                                                                                                                     |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Lock threads                                                                                                                   |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Manage or accept                                                                                                               |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>[Resolve a thread](discussions/#resolve-a-thread)                                                                              |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Manage [merge approval rules](project/merge_requests/approvals/settings.md) (project settings)                                 |          |          |           | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Delete                                                                                                                         |          |          |           |            | ✓        |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>Manage user-starred metrics dashboards (*6*)                                                                     | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>View metrics dashboard annotations                                                                               |          | ✓        | ✓         | ✓          | ✓        |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>Create/edit/delete metrics dashboard annotations                                                                 |          |          | ✓         | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Pull a package                                                                                                                             | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Publish a package                                                                                                                          |          |          | ✓         | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Delete a package                                                                                                                           |          |          |           | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Delete a file associated with a package                                                                                                    |          |          |           | ✓          | ✓        |
| [Project operations](../operations/index.md):<br>View [Error Tracking](../operations/error_tracking.md) list                                                                         |          | ✓        | ✓         | ✓          | ✓        |
| [Project operations](../operations/index.md):<br>Manage [Feature Flags](../operations/feature_flags.md)                                                                              |          |          | ✓         | ✓          | ✓        |
| [Project operations](../operations/index.md):<br>Manage [Error Tracking](../operations/error_tracking.md)                                                                            |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Download project                                                                                                                                    | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Leave comments                                                                                                                                      | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Reposition comments on images (posted by any user)                                                                                                  | ✓ (*9*)  | ✓ (*9*)  | ✓ (*9*)   | ✓          | ✓        |
| [Projects](project/index.md):<br>View [Insights](project/insights/index.md)                                                                                                          | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [releases](project/releases/index.md)                                                                                                          | ✓ (*5*)  | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [Requirements](project/requirements/index.md)                                                                                                  | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [time tracking](project/time_tracking.md) reports                                                                                              | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [wiki](project/wiki/index.md) pages                                                                                                            | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Create [snippets](snippets.md)                                                                                                                      |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Manage labels                                                                                                                                       |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [project traffic statistics](../api/project_statistics.md)                                                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Create, edit, delete [milestones](project/milestones/index.md).                                                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Create, edit, delete [releases](project/releases/index.md)                                                                                          |          |          | ✓ (*12*)  | ✓ (*12*)   | ✓ (*12*) |
| [Projects](project/index.md):<br>Create, edit [wiki](project/wiki/index.md) pages                                                                                                    |          |          | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Enable [Review Apps](../ci/review_apps/index.md)                                                                                                    |          |          | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View project [Audit Events](../administration/audit_events.md)                                                                                      |          |          | ✓ (*10*)  | ✓          | ✓        |
| [Projects](project/index.md):<br>Add [deploy keys](project/deploy_keys/index.md)                                                                                                     |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Add new [team members](project/members/index.md)                                                                                                    |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Manage [team members](project/members/index.md)                                                                                                     |          |          |           | ✓ (*21*)   | ✓        |
| [Projects](project/index.md):<br>Change [project features visibility](public_access.md) level                                                                                        |          |          |           | ✓ (*13*)   | ✓        |
| [Projects](project/index.md):<br>Configure [webhooks](project/integrations/webhooks.md)                                                                                              |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Delete [wiki](project/wiki/index.md) pages                                                                                                          |          |          | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Edit comments (posted by any user)                                                                                                                  |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Edit project badges                                                                                                                                 |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Edit project settings                                                                                                                               |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Export project                                                                                                                                      |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Manage [project access tokens](project/settings/project_access_tokens.md) (*11*)                                                                    |          |          |           | ✓ (*21*)   | ✓        |
| [Projects](project/index.md):<br>Manage [Project Operations](../operations/index.md)                                                                                                 |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Rename project                                                                                                                                      |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Share (invite) projects with groups                                                                                                                 |          |          |           | ✓ (*7*)    | ✓ (*7*)  |
| [Projects](project/index.md):<br>View 2FA status of members                                                                                                                          |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Assign project to a [compliance framework](project/settings/index.md#compliance-frameworks)                                                         |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Archive project                                                                                                                                     |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Change project visibility level                                                                                                                     |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Delete project                                                                                                                                      |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Disable notification emails                                                                                                                         |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Transfer project to another namespace                                                                                                               |          |          |           |            | ✓        |
| [Projects](project/index.md): View [Usage Quotas](usage_quotas.md) page                                                                                                              |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Pull project code                                                                                                                      | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>View project code                                                                                                                      | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>View a commit status                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Add tags                                                                                                                               |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Create new branches                                                                                                                    |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Create or update commit status                                                                                                         |          |          | ✓ (*4*)   | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Force push to non-protected branches                                                                                                   |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Push to non-protected branches                                                                                                         |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Remove non-protected branches                                                                                                          |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Rewrite or remove Git tags                                                                                                             |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Enable or disable branch protection                                                                                                    |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Enable or disable tag protection                                                                                                       |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Manage [push rules](project/repository/push_rules.md)                                                                                  |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Push to protected branches (*4*)                                                                                                       |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Turn on or off protected branch push for developers                                                                                    |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Remove fork relationship                                                                                                               |          |          |           |            | ✓        |
| [Repository](project/repository/index.md):<br>Force push to protected branches (*3*)                                                                                                 |          |          |           |            |          |
| [Repository](project/repository/index.md):<br>Remove protected branches (*3*)                                                                                                        |          |          |           |            |          |
| [Requirements Management](project/requirements/index.md):<br>Archive / reopen                                                                                                        |          | ✓        | ✓         | ✓          | ✓        |
| [Requirements Management](project/requirements/index.md):<br>Create / edit                                                                                                           |          | ✓        | ✓         | ✓          | ✓        |
| [Requirements Management](project/requirements/index.md):<br>Import / export                                                                                                         |          | ✓        | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Create issue from vulnerability finding                                                                   |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Create vulnerability from vulnerability finding                                                           |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Dismiss vulnerability                                                                                     |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Dismiss vulnerability finding                                                                             |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Resolve vulnerability                                                                                     |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Revert vulnerability to detected state                                                                    |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Use security dashboard                                                                                    |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>View vulnerability                                                                                        |          |          | ✓         | ✓          | ✓        |
| [Security dashboard](application_security/security_dashboard/index.md):<br>View vulnerability findings in [dependency list](application_security/dependency_list/index.md)           |          |          | ✓         | ✓          | ✓        |
| [Terraform](infrastructure/index.md):<br>Read Terraform state                                                                                                                        |          |          | ✓         | ✓          | ✓        |
| [Terraform](infrastructure/index.md):<br>Manage Terraform state                                                                                                                      |          |          |           | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Archive                                                                                                                                  |          | ✓        | ✓         | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Create                                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Move                                                                                                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Reopen                                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |

<!-- markdownlint-disable MD029 -->

1. On self-managed GitLab instances, guest users are able to perform this action only on
   public and internal projects (not on private projects). [External users](#external-users)
   must be given explicit access even if the project is internal. For GitLab.com, see the
   [GitLab.com visibility settings](gitlab_com/index.md#visibility-settings).
2. Guest users can only view the [confidential issues](project/issues/confidential_issues.md) they created themselves or are assigned to.
3. Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [protected branches](project/protected_branches.md).
4. If the [branch is protected](project/protected_branches.md), this depends on the access Developers and Maintainers are given.
5. Guest users can access GitLab [**Releases**](project/releases/index.md) for downloading assets but are not allowed to download the source code nor see [repository information like commits and release evidence](project/releases/index.md#view-a-release-and-download-assets).
6. Actions are limited only to records owned (referenced) by user.
7. When [Share Group Lock](group/index.md#prevent-a-project-from-being-shared-with-groups) is enabled the project can't be shared with other groups. It does not affect group with group sharing.
8. For information on eligible approvers for merge requests, see
   [Eligible approvers](project/merge_requests/approvals/rules.md#eligible-approvers).
9. Applies only to comments on [Design Management](project/issues/design_management.md) designs.
10. Users can only view events based on their individual actions.
11. Project access tokens are supported for self-managed instances on Free and above. They are also
    supported on GitLab SaaS Premium and above (excluding [trial licenses](https://about.gitlab.com/free-trial/)).
12. If the [tag is protected](#release-permissions-with-protected-tags), this depends on the access Developers and Maintainers are given.
13. A Maintainer can't change project features visibility level if
    [project visibility](public_access.md) is set to private.
14. Attached design files are moved together with the issue even if the user doesn't have the
    Developer role.
15. Guest users can only set metadata (for example, labels, assignees, or milestones)
    when creating an issue. They cannot change the metadata on existing issues.
16. In GitLab 14.5 or later, Guests are not allowed to [create incidents](../operations/incident_management/incidents.md#incident-creation).
    In GitLab 15.1 and later, a Guest who created an issue that was promoted to an incident cannot edit, close, or reopen their incident.
17. In projects that accept contributions from external members, users can create, edit, and close their own merge requests.
18. Authors and assignees of issues can modify the title and description even if they don't have the Reporter role.
19. Authors and assignees can close and reopen issues even if they don't have the Reporter role.
20. The ability to view the Container Registry and pull images is controlled by the [Container Registry's visibility permissions](packages/container_registry/index.md#container-registry-visibility-permissions).
21. Maintainers cannot create, demote, or remove Owners, and they cannot promote users to the Owner role. They also cannot approve Owner role access requests.

<!-- markdownlint-enable MD029 -->

## Project features permissions

More details about the permissions for some project-level features follow.

### GitLab CI/CD permissions

[GitLab CI/CD](../ci/index.md) permissions for some roles can be modified by these settings:

- [Public pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines):
  When set to public, gives access to certain CI/CD features to *Guest* project members.
- [Pipeline visibility](../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects):
  When set to **Everyone with Access**, gives access to certain CI/CD "view" features to *non-project* members.

| Action                                                                                                                    | Non-member | Guest   | Reporter | Developer | Maintainer | Owner |
|---------------------------------------------------------------------------------------------------------------------------|------------|---------|----------|-----------|------------|-------|
| See that artifacts exist                                                                                                  | ✓ (*3*)    | ✓ (*3*) | ✓        | ✓         | ✓          | ✓     |
| View a list of jobs                                                                                                       | ✓ (*1*)    | ✓ (*2*) | ✓        | ✓         | ✓          | ✓     |
| View and download artifacts                                                                                               | ✓ (*1*)    | ✓ (*2*) | ✓        | ✓         | ✓          | ✓     |
| View [environments](../ci/environments/index.md)                                                                          | ✓ (*3*)    | ✓ (*3*) | ✓        | ✓         | ✓          | ✓     |
| View job logs and job details page                                                                                        | ✓ (*1*)    | ✓ (*2*) | ✓        | ✓         | ✓          | ✓     |
| View pipeline details page                                                                                                | ✓ (*1*)    | ✓ (*2*) | ✓        | ✓         | ✓          | ✓     |
| View pipelines page                                                                                                       | ✓ (*1*)    | ✓ (*2*) | ✓        | ✓         | ✓          | ✓     |
| View pipelines tab in MR                                                                                                  | ✓ (*3*)    | ✓ (*3*) | ✓        | ✓         | ✓          | ✓     |
| [View vulnerabilities in a pipeline](application_security/security_dashboard/index.md#view-vulnerabilities-in-a-pipeline) |            | ✓ (*2*) | ✓        | ✓         | ✓          | ✓     |
| View and download project-level [Secure Files](../api/secure_files.md)                                                    |            |         |          | ✓         | ✓          | ✓     |
| Cancel and retry jobs                                                                                                     |            |         |          | ✓         | ✓          | ✓     |
| Create new [environments](../ci/environments/index.md)                                                                    |            |         |          | ✓         | ✓          | ✓     |
| Delete job logs or job artifacts                                                                                          |            |         |          | ✓ (*4*)   | ✓          | ✓     |
| Run CI/CD pipeline                                                                                                        |            |         |          | ✓         | ✓          | ✓     |
| Run CI/CD pipeline for a protected branch                                                                                 |            |         |          | ✓ (*5*)   | ✓ (*5*)    | ✓     |
| Stop [environments](../ci/environments/index.md)                                                                          |            |         |          | ✓         | ✓          | ✓     |
| View a job with [debug logging](../ci/variables/index.md#debug-logging)                                                   |            |         |          | ✓         | ✓          | ✓     |
| Use pipeline editor                                                                                                       |            |         |          | ✓         | ✓          | ✓     |
| Run [interactive web terminals](../ci/interactive_web_terminal/index.md)                                                  |            |         |          | ✓         | ✓          | ✓     |
| Add specific runners to project                                                                                           |            |         |          |           | ✓          | ✓     |
| Clear runner caches manually                                                                                              |            |         |          |           | ✓          | ✓     |
| Enable shared runners in project                                                                                          |            |         |          |           | ✓          | ✓     |
| Manage CI/CD settings                                                                                                     |            |         |          |           | ✓          | ✓     |
| Manage job triggers                                                                                                       |            |         |          |           | ✓          | ✓     |
| Manage project-level CI/CD variables                                                                                      |            |         |          |           | ✓          | ✓     |
| Manage project-level [Secure Files](../api/secure_files.md)                                                               |            |         |          |           | ✓          | ✓     |
| Use [environment terminals](../ci/environments/index.md#web-terminals-deprecated)                                         |            |         |          |           | ✓          | ✓     |
| Delete pipelines                                                                                                          |            |         |          |           |            | ✓     |

<!-- markdownlint-disable MD029 -->

1. If the project is public and **Public pipelines** is enabled in **Project Settings > CI/CD**.
2. If **Public pipelines** is enabled in **Project Settings > CI/CD**.
3. If the project is public.
4. Only if the job was both:
   - Triggered by the user.
   - [In GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/35069) and later,
     run for a non-protected branch.
5. If the user is [allowed to merge or push to the protected branch](../ci/pipelines/index.md#pipeline-security-on-protected-branches).

<!-- markdownlint-enable MD029 -->

#### Job permissions

This table shows granted privileges for jobs triggered by specific types of users:

| Action                                       | Guest, Reporter | Developer | Maintainer | Administrator |
|----------------------------------------------|-----------------|-----------|------------|---------------|
| Run CI job                                   |                 | ✓         | ✓          | ✓             |
| Clone source and LFS from current project    |                 | ✓         | ✓          | ✓             |
| Clone source and LFS from public projects    |                 | ✓         | ✓          | ✓             |
| Clone source and LFS from internal projects  |                 | ✓ (*1*)   | ✓  (*1*)   | ✓             |
| Clone source and LFS from private projects   |                 | ✓ (*2*)   | ✓  (*2*)   | ✓ (*2*)       |
| Pull container images from current project   |                 | ✓         | ✓          | ✓             |
| Pull container images from public projects   |                 | ✓         | ✓          | ✓             |
| Pull container images from internal projects |                 | ✓ (*1*)   | ✓  (*1*)   | ✓             |
| Pull container images from private projects  |                 | ✓ (*2*)   | ✓  (*2*)   | ✓ (*2*)       |
| Push container images to current project     |                 | ✓         | ✓          | ✓             |
| Push container images to other projects      |                 |           |            |               |
| Push source and LFS                          |                 |           |            |               |

1. Only if the triggering user is not an external one.
1. Only if the triggering user is a member of the project.

### Wiki and issues

Project features like [wikis](project/wiki/index.md) and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone
- Only team members: only team members can see even if your project is public or internal
- Everyone with access: everyone can see depending on your project's visibility level
- Everyone: enabled for everyone (only available for GitLab Pages)

### Protected branches

Additional restrictions can be applied on a per-branch basis with [protected branches](project/protected_branches.md).
Additionally, you can customize permissions to allow or prevent project
Maintainers and Developers from pushing to a protected branch. Read through the documentation on
[protected branches](project/protected_branches.md)
to learn more.

### Value stream analytics permissions

Find the current permissions on the value stream analytics dashboard, as described in
[related documentation](analytics/value_stream_analytics.md#access-permissions-for-value-stream-analytics).

### Issue board permissions

Find the current permissions for interacting with the issue board feature in the
[issue boards permissions page](project/issue_board.md#permissions).

### File Locking permissions **(PREMIUM)**

The user that locks a file or directory is the only one that can edit and push their changes back to the repository where the locked objects are located.

Read through the documentation on [permissions for File Locking](project/file_lock.md#permissions) to learn more.

### Confidential Issues permissions

[Confidential issues](project/issues/confidential_issues.md) can be accessed by users with reporter and higher permission levels,
as well as by guest users that create a confidential issue or are assigned to it. To learn more,
read through the documentation on [permissions and access to confidential issues](project/issues/confidential_issues.md#permissions-and-access-to-confidential-issues).

### Container Registry visibility permissions

The ability to view the Container Registry and pull images is controlled by the Container Registry's
visibility permissions. Find these permissions for the Container Registry as described in the
[related documentation](packages/container_registry/index.md#container-registry-visibility-permissions).

## Group members permissions

Any user can remove themselves from a group, unless they are the last Owner of
the group.

The following table lists group permissions available for each role:

<!-- Keep this table sorted: first, by minimum role, then alphabetically. -->

| Action                                                                                  | Guest | Reporter | Developer | Maintainer | Owner |
|-----------------------------------------------------------------------------------------|-------|----------|-----------|------------|-------|
| Browse group                                                                            | ✓     | ✓        | ✓         | ✓          | ✓     |
| Pull a container image using the dependency proxy                                       | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Contribution analytics                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group [epic](group/epics/index.md)                                                 | ✓     | ✓        | ✓         | ✓          | ✓     |
| View [group wiki](project/wiki/group.md) pages                                          | ✓ (6) | ✓        | ✓         | ✓          | ✓     |
| View [Insights](project/insights/index.md)                                              | ✓     | ✓        | ✓         | ✓          | ✓     |
| View [Insights](project/insights/index.md) charts                                       | ✓     | ✓        | ✓         | ✓          | ✓     |
| View [Issue analytics](analytics/issue_analytics.md)                                    | ✓     | ✓        | ✓         | ✓          | ✓     |
| View value stream analytics                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |
| Create/edit group [epic](group/epics/index.md)                                          |       | ✓        | ✓         | ✓          | ✓     |
| Create/edit/delete [epic boards](group/epics/epic_boards.md)                            |       | ✓        | ✓         | ✓          | ✓     |
| Manage group labels                                                                     |       | ✓        | ✓         | ✓          | ✓     |
| Publish [packages](packages/index.md)                                                   |       |          | ✓         | ✓          | ✓     |
| Pull [packages](packages/index.md)                                                      |       | ✓        | ✓         | ✓          | ✓     |
| Delete [packages](packages/index.md)                                                    |       |          |           | ✓          | ✓     |
| Create/edit/delete [Maven and generic package duplicate settings](packages/generic_packages/index.md#do-not-allow-duplicate-generic-packages)                                                    |       |          |           | ✓          | ✓     |
| Pull a Container Registry image                                                         | ✓ (7) | ✓        | ✓         | ✓          | ✓     |
| Remove a Container Registry image                                                       |       |          | ✓         | ✓          | ✓     |
| View [Group DevOps Adoption](group/devops_adoption/index.md)                            |       | ✓        | ✓         | ✓          | ✓     |
| View metrics dashboard annotations                                                      |       | ✓        | ✓         | ✓          | ✓     |
| View [Productivity analytics](analytics/productivity_analytics.md)                      |       | ✓        | ✓         | ✓          | ✓     |
| Create and edit [group wiki](project/wiki/group.md) pages                               |       |          | ✓         | ✓          | ✓     |
| Create project in group                                                                 |       |          | ✓ (3)(5)  | ✓ (3)      | ✓ (3) |
| Create/edit/delete group milestones                                                     |       | ✓        | ✓         | ✓          | ✓     |
| Create/edit/delete iterations                                                           |       | ✓        | ✓         | ✓          | ✓     |
| Create/edit/delete metrics dashboard annotations                                        |       |          | ✓         | ✓          | ✓     |
| Enable/disable a dependency proxy                                                       |       |          |           | ✓          | ✓     |
| Purge the dependency proxy for a group                                                  |       |          |           |            | ✓     |
| Create/edit/delete dependency proxy [cleanup policies](packages/dependency_proxy/reduce_dependency_proxy_storage.md#cleanup-policies)                                                  |       |          |           | ✓          | ✓     |
| Use [security dashboard](application_security/security_dashboard/index.md)              |       |          | ✓         | ✓          | ✓     |
| View group Audit Events                                                                 |       |          | ✓ (7)     | ✓ (7)      | ✓     |
| Create subgroup                                                                         |       |          |           | ✓ (1)      | ✓     |
| Delete [group wiki](project/wiki/group.md) pages                                        |       |          | ✓         | ✓          | ✓     |
| Edit [epic](group/epics/index.md) comments (posted by any user)                         |       |          |           | ✓ (2)      | ✓ (2) |
| List group deploy tokens                                                                |       |          |           | ✓          | ✓     |
| Manage [group push rules](group/index.md#group-push-rules)                              |       |          |           | ✓          | ✓     |
| View/manage group-level Kubernetes cluster                                              |       |          |           | ✓          | ✓     |
| Create and manage compliance frameworks                                                 |       |          |           |            | ✓     |
| Create/Delete group deploy tokens                                                       |       |          |           |            | ✓     |
| Change group visibility level                                                           |       |          |           |            | ✓     |
| Delete group                                                                            |       |          |           |            | ✓     |
| Delete group [epic](group/epics/index.md)                                               |       |          |           |            | ✓     |
| Disable notification emails                                                             |       |          |           |            | ✓     |
| Edit group settings                                                                     |       |          |           |            | ✓     |
| Edit [SAML SSO](group/saml_sso/index.md)                                                |       |          |           |            | ✓ (4) |
| Filter members by 2FA status                                                            |       |          |           |            | ✓     |
| Manage group level CI/CD variables                                                      |       |          |           |            | ✓     |
| Manage group members                                                                    |       |          |           |            | ✓     |
| Share (invite) groups with groups                                                       |       |          |           |            | ✓     |
| View 2FA status of members                                                              |       |          |           |            | ✓     |
| View [Billing](../subscriptions/gitlab_com/index.md#view-your-gitlab-saas-subscription) |       |          |           |            | ✓ (4) |
| View group [Usage Quotas](usage_quotas.md) page                                         |       |          |           |            | ✓ (4) |
| Manage group runners                                                                    |       |          |           |            | ✓     |
| [Migrate groups](group/import/index.md)                                                 |       |          |           |            | ✓     |
| Manage [subscriptions, and purchase CI/CD minutes and storage](../subscriptions/gitlab_com/index.md)         |       |          |           |            | ✓     |

<!-- markdownlint-disable MD029 -->

1. Groups can be set to allow either Owners, or Owners and users with the Maintainer role, to [create subgroups](group/subgroups/index.md#create-a-subgroup).
2. Introduced in GitLab 12.2.
3. Default project creation role can be changed at:
   - The [instance level](admin_area/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).
   - The [group level](group/index.md#specify-who-can-add-projects-to-a-group).
4. Does not apply to subgroups.
5. Developers can push commits to the default branch of a new project only if the [default branch protection](group/index.md#change-the-default-branch-protection-of-a-group) is set to "Partially protected" or "Not protected".
6. In addition, if your group is public or internal, all users who can see the group can also see group wiki pages.
7. Users can only view events based on their individual actions.

<!-- markdownlint-enable MD029 -->

### Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent groups. This model allows access to
nested groups if you have membership in one of its parents.

To learn more, read through the documentation on
[subgroups memberships](group/subgroups/index.md#subgroup-membership).

## External users **(FREE SELF)**

In cases where it is desired that a user has access only to some internal or
private projects, there is the option of creating **External Users**. This
feature may be useful when for example a contractor is working on a given
project and should only have access to that project.

External users:

- Can only create projects (including forks), subgroups, and snippets within the top-level group to which they belong.
- Can only access public projects and projects to which they are explicitly granted access,
  thus hiding all other internal or private ones from them (like being
  logged out).
- Can only access public groups and groups to which they are explicitly granted access,
  thus hiding all other internal or private ones from them (like being
  logged out).
- Can only access public snippets.

Access can be granted by adding the user as member to the project or group.
Like usual users, they receive a role in the project or group with all
the abilities that are mentioned in the [permissions table above](#project-members-permissions).
For example, if an external user is added as Guest, and your project is internal or
private, they do not have access to the code; you need to grant the external
user access at the Reporter level or above if you want them to have access to the code. You should
always take into account the
[project's visibility and permissions settings](project/settings/index.md#configure-project-visibility-features-and-permissions)
as well as the permission level of the user.

NOTE:
External users still count towards a license seat.

An administrator can flag a user as external by either of the following methods:

- [Through the API](../api/users.md#user-modification).
- Using the GitLab UI:
  1. On the top bar, select **Menu > Admin**.
  1. On the left sidebar, select **Overview > Users** to create a new user or edit an existing one.
     There, you can find the option to flag the user as external.

Additionally, users can be set as external users using:

- [SAML groups](../integration/saml.md#external-groups).
- [LDAP groups](../administration/auth/ldap/ldap_synchronization.md#external-groups).

### Setting new users to external

By default, new users are not set as external users. This behavior can be changed
by an administrator:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.

If you change the default behavior of creating new users as external, you
have the option to narrow it down by defining a set of internal users.
The **Internal users** field allows specifying an email address regex pattern to
identify default internal users. New users whose email address matches the regex
pattern are set to internal by default rather than an external collaborator.

The regex pattern format is in Ruby, but it needs to be convertible to JavaScript,
and the ignore case flag is set (`/regex pattern/i`). Here are some examples:

- Use `\.internal@domain\.com$` to mark email addresses ending with
  `.internal@domain.com` as internal.
- Use `^(?:(?!\.ext@domain\.com).)*$\r?` to mark users with email addresses
  not including `.ext@domain.com` as internal.

WARNING:
Be aware that this regex could lead to a
[regular expression denial of service (ReDoS) attack](https://en.wikipedia.org/wiki/ReDoS).

## Free Guest users **(ULTIMATE)**

When a user is given the Guest role on a project, group, or both, and holds no
higher permission level on any other project or group on the GitLab instance,
the user is considered a guest user by GitLab and does not consume a license seat.
There is no other specific "guest" designation for newly created users.

If the user is assigned a higher role on any projects or groups, the user
takes a license seat. If a user creates a project, the user becomes a Maintainer
on the project, resulting in the use of a license seat. Also, note that if your
project is internal or private, Guest users have all the abilities that are
mentioned in the [permissions table above](#project-members-permissions) (they
are unable to browse the project's repository, for example).

NOTE:
To prevent a guest user from creating projects, as an administrator, you can edit the
user's profile to mark the user as [external](#external-users).
Beware though that even if a user is external, if they already have Reporter or
higher permissions in any project or group, they are **not** counted as a
free guest user.

## Auditor users **(PREMIUM SELF)**

Auditor users are given read-only access to all projects, groups, and other
resources on the GitLab instance.

An Auditor user should be able to access all projects and groups of a GitLab instance
with the permissions described on the documentation on [auditor users permissions](../administration/auditor_users.md#auditor-user-permissions-and-restrictions).

[Read more about Auditor users.](../administration/auditor_users.md)

## Users with minimal access **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40942) in GitLab 13.4.

Owners can add members with a "minimal access" role to a parent group. Such users don't automatically have access to
projects and subgroups underneath. Owners must explicitly add these "minimal access" users to the specific subgroups and
projects.

Because of an [outstanding issue](https://gitlab.com/gitlab-org/gitlab/-/issues/267996), when minimal access users:

- Sign in with standard web authentication, they receive a `404` error when accessing the parent group.
- Sign in with Group SSO, they receive a `404` error immediately because they are redirected to the parent group page.

To work around the issue, give these users the Guest role or higher to any project or subgroup within the parent group.

### Minimal access users take license seats

Users with even a "minimal access" role are counted against your number of license seats. This
requirement does not apply for [GitLab Ultimate](https://about.gitlab.com/pricing/)
subscriptions.

## Project features

Project features like wiki and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone.
- Only team members: only team members can see, even if your project is public or internal.
- Everyone with access: everyone can see depending on your project visibility level.
- Everyone: enabled for everyone (only available for GitLab Pages).

## Release permissions with protected tags

[The permission to create tags](project/protected_tags.md) is used to define if a user can
create, edit, and delete [Releases](project/releases/index.md).

See [Release permissions](project/releases/index.md#release-permissions)
for more information.

## LDAP users permissions

LDAP user permissions can be manually overridden by an administrator.
Read through the documentation on [LDAP users permissions](group/index.md#manage-group-memberships-via-ldap) to learn more.

## Project aliases

Project aliases can only be read, created and deleted by a GitLab administrator.
Read through the documentation on [Project aliases](../user/project/import/index.md#project-aliases) to learn more.
