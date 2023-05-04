---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Permissions and roles **(FREE)**

When you add a user to a project or group, you assign them a role.
The role determines which actions they can take in GitLab.

If you add a user to both a project's group and the
project itself, the higher role is used.

GitLab [administrators](../administration/index.md) have all permissions.

## Roles

The available roles are:

- Guest (This role applies to [private and internal projects](../user/public_access.md) only.)
- Reporter
- Developer
- Maintainer
- Owner
- Minimal Access (available for the top-level group only)

A user assigned the Guest role has the least permissions,
and the Owner has the most.

By default, all users can create top-level groups and change their
usernames. A GitLab administrator can [change this behavior](../administration/user_settings.md)
for the GitLab instance.

## Project members permissions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/219299) in GitLab 14.8, personal namespace owners appear with Owner role in new projects in their namespace. Introduced [with a flag](../administration/feature_flags.md) named `personal_project_owner_with_owner_access`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/351919) in GitLab 14.9. Feature flag `personal_project_owner_with_owner_access` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/219299).

A user's role determines what permissions they have on a project. The Owner role provides all permissions but is
available only:

- For group and project Owners. In GitLab 14.8 and earlier, the role is inherited for a group's projects.
- For Administrators.

Personal [namespace](namespace/index.md) owners:

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
| [Analytics](analytics/index.md):<br>View [value stream analytics](group/value_stream_analytics/index.md)                                                                               | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [DORA metrics](analytics/ci_cd_analytics.md)                                                                                                |          | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [CI/CD analytics](analytics/ci_cd_analytics.md)                                                                                             |          | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [code review analytics](analytics/code_review_analytics.md)                                                                                 |          | ✓        | ✓         | ✓          | ✓        |
| [Analytics](analytics/index.md):<br>View [repository analytics](analytics/repository_analytics.md)                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>View licenses in [dependency list](application_security/dependency_list/index.md)                                          |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Create and run [on-demand DAST scans](application_security/dast/proxy-based.md#on-demand-scans)                                  |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Manage [security policy](application_security/policies/index.md)                                                           |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>View [dependency list](application_security/dependency_list/index.md)                                                      |          |          | ✓         | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Create a [CVE ID Request](application_security/cve_id_request.md)                                                          |          |          |           | ✓          | ✓        |
| [Application security](application_security/index.md):<br>Create or assign [security policy project](application_security/policies/index.md)                                         |          |          |           |            | ✓        |
| [GitLab Agent for Kubernetes](clusters/agent/index.md):<br>View agents                                                                                                               |          |          | ✓         | ✓          | ✓        |
| [GitLab Agent for Kubernetes](clusters/agent/index.md):<br>Manage agents                                                                                                             |          |          |           | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Create, edit, delete [cleanup policies](packages/container_registry/delete_container_registry_images.md#use-a-cleanup-policy) |          |          |          | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Push an image to the Container Registry                                                                               |          |          | ✓         | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Pull an image from the Container Registry                                                                             | ✓ (19) | ✓ (19) | ✓         | ✓          | ✓        |
| [Container Registry](packages/container_registry/index.md):<br>Remove a Container Registry image                                                                                     |          |          | ✓         | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>View Pages protected by [access control](project/pages/pages_access_control.md)                                       | ✓        | ✓        | ✓         | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>Manage                                                                                                                                    |          |          |           | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>Manage GitLab Pages domains and certificates                                                                                              |          |          |           | ✓          | ✓        |
| [GitLab Pages](project/pages/index.md):<br>Remove GitLab Pages                                                                                                                       |          |          |           | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Assign an alert                                                                                                | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Participate in on-call rotation                                                                                | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [incident](../operations/incident_management/incidents.md)                                                | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Change [alert status](../operations/incident_management/alerts.md#change-an-alerts-status)                  |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Change [incident severity](../operations/incident_management/manage_incidents.md#change-severity)              |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Create [incident](../operations/incident_management/incidents.md)                                              |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [alerts](../operations/incident_management/alerts.md)                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [escalation policies](../operations/incident_management/escalation_policies.md)                           |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>View [on-call schedules](../operations/incident_management/oncall_schedules.md)                                |          | ✓        | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Change [incident escalation status](../operations/incident_management/manage_incidents.md#change-status)       |          |          | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Change [incident escalation policy](../operations/incident_management/manage_incidents.md#change-escalation-policy) |     |          | ✓         | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [on-call schedules](../operations/incident_management/oncall_schedules.md)                              |          |          |           | ✓          | ✓        |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [escalation policies](../operations/incident_management/escalation_policies.md)                         |          |          |           | ✓          | ✓        |
| [Issue boards](project/issue_board.md):<br>Create or delete lists                                                                                                                    |          | ✓        | ✓         | ✓          | ✓        |
| [Issue boards](project/issue_board.md):<br>Move issues between lists                                                                                                                 |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Add Labels                                                                                                                                     | ✓ (15) | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Add to epic                                                                                                                                    |           | ✓ (22) | ✓ (22)  | ✓ (22)   | ✓ (22) |
| [Issues](project/issues/index.md):<br>Assign                                                                                                                                         | ✓ (15) | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Create (17)                                                                                                                                  | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Create [confidential issues](project/issues/confidential_issues.md)                                                                            | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>View [Design Management](project/issues/design_management.md) pages                                                                            | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>View [related issues](project/issues/related_issues.md)                                                                                        | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Set [weight](project/issues/issue_weight.md)                                                                                                   | ✓ (15) | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Set metadata such as labels, milestones, or assignees when creating an issue                                                             | ✓ (15)  | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Edit metadata such labels, milestones, or assignees for an existing issue                                                                |   (15)  | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Set [parent epic](group/epics/manage_epics.md#add-an-existing-issue-to-an-epic) |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>View [confidential issues](project/issues/confidential_issues.md)                                                                              | (2)    | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Close / reopen (18)                                                                                                                          |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Lock threads                                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Manage [related issues](project/issues/related_issues.md)                                                                                      |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Manage tracker                                                                                                                                 |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Move issues (14)                                                                                                                             |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Set issue [time tracking](project/time_tracking.md) estimate and time spent                                                                    |          | ✓        | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Archive [Design Management](project/issues/design_management.md) files                                                                         |          |          | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Upload [Design Management](project/issues/design_management.md) files                                                                          |          |          | ✓         | ✓          | ✓        |
| [Issues](project/issues/index.md):<br>Delete                                                                                                                                         |          |          |           |            | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>View allowed and denied licenses                                                                                    | ✓ (1)  | ✓        | ✓         | ✓          | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>View License Compliance reports                                                                                     | ✓ (1)  | ✓        | ✓         | ✓          | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>View License list                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [License Compliance](compliance/license_compliance/index.md):<br>Manage license policy                                                                                               |          |          |           | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Assign reviewer                                                                                                                |          | ✓        | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>See list                                                                                                                       |          | ✓        | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Apply code change suggestions                                                                                                  |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Approve (8)                                                                                                                  |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Assign                                                                                                                         |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Create (16)                                                                                                                  |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Add labels                                                                                                                     |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Lock threads                                                                                                                   |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Manage or accept                                                                                                               |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>[Resolve a thread](discussions/index.md#resolve-a-thread)                                                                      |          |          | ✓         | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Manage [merge approval rules](project/merge_requests/approvals/settings.md) (project settings)                                 |          |          |           | ✓          | ✓        |
| [Merge requests](project/merge_requests/index.md):<br>Delete                                                                                                                         |          |          |           |            | ✓        |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>Manage user-starred metrics dashboards (6)                                                                     | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>View metrics dashboard annotations                                                                               |          | ✓        | ✓         | ✓          | ✓        |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>Create/edit/delete metrics dashboard annotations                                                                 |          |          | ✓         | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Pull a package                                                                                                                             | ✓ (1)  | ✓        | ✓         | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Publish a package                                                                                                                          |          |          | ✓         | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Delete a package                                                                                                                           |          |          |           | ✓          | ✓        |
| [Package registry](packages/index.md):<br>Delete a file associated with a package                                                                                                    |          |          |           | ✓          | ✓        |
| [Project operations](../operations/index.md):<br>View [Error Tracking](../operations/error_tracking.md) list                                                                         |          | ✓        | ✓         | ✓          | ✓        |
| [Project operations](../operations/index.md):<br>Manage [Feature flags](../operations/feature_flags.md)                                                                              |          |          | ✓         | ✓          | ✓        |
| [Project operations](../operations/index.md):<br>Manage [Error Tracking](../operations/error_tracking.md)                                                                            |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Download project                                                                                                                                    | ✓ (1)  | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Leave comments                                                                                                                                      | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Reposition comments on images (posted by any user)                                                                                                  | ✓ (9)  | ✓ (9)  | ✓ (9)   | ✓          | ✓        |
| [Projects](project/index.md):<br>View [Insights](project/insights/index.md)                                                                                                          | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [releases](project/releases/index.md)                                                                                                          | ✓ (5)  | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [Requirements](project/requirements/index.md)                                                                                                  | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [time tracking](project/time_tracking.md) reports                                                                                              | ✓ (1)  | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [wiki](project/wiki/index.md) pages                                                                                                            | ✓        | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Create [snippets](snippets.md)                                                                                                                      |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Manage labels                                                                                                                                       |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View [project traffic statistics](../api/project_statistics.md)                                                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Create, edit, delete [milestones](project/milestones/index.md).                                                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Create, edit, delete [releases](project/releases/index.md)                                                                                          |          |          | ✓ (12)  | ✓ (12)   | ✓ (12) |
| [Projects](project/index.md):<br>Create, edit [wiki](project/wiki/index.md) pages                                                                                                    |          |          | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Enable [Review Apps](../ci/review_apps/index.md)                                                                                                    |          |          | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>View project [Audit Events](../administration/audit_events.md)                                                                                      |          |          | ✓ (10)  | ✓          | ✓        |
| [Projects](project/index.md):<br>Add [deploy keys](project/deploy_keys/index.md)                                                                                                     |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Add new [team members](project/members/index.md)                                                                                                    |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Manage [team members](project/members/index.md)                                                                                                     |          |          |           | ✓ (20)   | ✓        |
| [Projects](project/index.md):<br>Change [project features visibility](public_access.md) level                                                                                        |          |          |           | ✓ (13)   | ✓        |
| [Projects](project/index.md):<br>Configure [webhooks](project/integrations/webhooks.md)                                                                                              |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Delete [wiki](project/wiki/index.md) pages                                                                                                          |          |          | ✓         | ✓          | ✓        |
| [Projects](project/index.md):<br>Edit comments (posted by any user)                                                                                                                  |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Edit project badges                                                                                                                                 |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Edit project settings                                                                                                                               |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>[Export project](project/settings/import_export.md)                                                                                                                                      |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Manage [project access tokens](project/settings/project_access_tokens.md) (11)                                                                    |          |          |           | ✓ (20)   | ✓        |
| [Projects](project/index.md):<br>Manage [Project Operations](../operations/index.md)                                                                                                 |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Rename project                                                                                                                                      |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Share (invite) projects with groups                                                                                                                 |          |          |           | ✓ (7)    | ✓ (7)  |
| [Projects](project/index.md):<br>View 2FA status of members                                                                                                                          |          |          |           | ✓          | ✓        |
| [Projects](project/index.md):<br>Assign project to a [compliance framework](project/settings/index.md#add-a-compliance-framework-to-a-project)                                       |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Archive project                                                                                                                                     |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Change project visibility level                                                                                                                     |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Delete project                                                                                                                                      |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Disable notification emails                                                                                                                         |          |          |           |            | ✓        |
| [Projects](project/index.md):<br>Transfer project to another namespace                                                                                                               |          |          |           |            | ✓        |
| [Projects](project/index.md): View [Usage Quotas](usage_quotas.md) page                                                                                                              |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Pull project code                                                                                                                      | ✓ (1)  | ✓        | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>View project code                                                                                                                      | ✓ (1) (23)  | ✓        | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>View a commit status                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Add tags                                                                                                                               |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Create new branches                                                                                                                    |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Create or update commit status                                                                                                         |          |          | ✓ (4)   | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Force push to non-protected branches                                                                                                   |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Push to non-protected branches                                                                                                         |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Remove non-protected branches                                                                                                          |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Rewrite or remove Git tags                                                                                                             |          |          | ✓         | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Enable or disable branch protection                                                                                                    |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Enable or disable tag protection                                                                                                       |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Manage [push rules](project/repository/push_rules.md)                                                                                  |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Push to protected branches (4)                                                                                                       |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Turn on or off protected branch push for developers                                                                                    |          |          |           | ✓          | ✓        |
| [Repository](project/repository/index.md):<br>Remove fork relationship                                                                                                               |          |          |           |            | ✓        |
| [Repository](project/repository/index.md):<br>Force push to protected branches (3)                                                                                                 |          |          |           |            |          |
| [Repository](project/repository/index.md):<br>Remove protected branches (3)                                                                                                        |          |          |           |            |          |
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
| [Tasks](tasks.md):<br>Create (17)     |          | ✓        | ✓         | ✓          | ✓        |
| [Tasks](tasks.md):<br>Edit              |          | ✓         | ✓         | ✓          | ✓        |
| [Tasks](tasks.md):<br>Remove from issue |          | ✓         | ✓         | ✓          | ✓        |
| [Tasks](tasks.md):<br>Delete (21)     |          |           |            |            | ✓        |
| [Terraform](infrastructure/index.md):<br>Read Terraform state                                                                                                                        |          |          | ✓         | ✓          | ✓        |
| [Terraform](infrastructure/index.md):<br>Manage Terraform state                                                                                                                      |          |          |           | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Archive                                                                                                                                  |          | ✓        | ✓         | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Create                                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Move                                                                                                                                     |          | ✓        | ✓         | ✓          | ✓        |
| [Test cases](../ci/test_cases/index.md):<br>Reopen                                                                                                                                   |          | ✓        | ✓         | ✓          | ✓        |

<!-- markdownlint-disable MD029 -->

1. On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](admin_area/external_users.md) must be given explicit access even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available.
2. Guest users can only view the [confidential issues](project/issues/confidential_issues.md) they created themselves or are assigned to.
3. Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [protected branches](project/protected_branches.md).
4. If the [branch is protected](project/protected_branches.md), this depends on the access given to Developers and Maintainers.
5. Guest users can access GitLab [**Releases**](project/releases/index.md) for downloading assets but are not allowed to download the source code nor see [repository information like commits and release evidence](project/releases/index.md#view-a-release-and-download-assets).
6. Actions are limited only to records owned (referenced) by user.
7. When [Share Group Lock](group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups) is enabled the project can't be shared with other groups. It does not affect group with group sharing.
8. For information on eligible approvers for merge requests, see
   [Eligible approvers](project/merge_requests/approvals/rules.md#eligible-approvers).
9. Applies only to comments on [Design Management](project/issues/design_management.md) designs.
10. Users can only view events based on their individual actions.
11. Project access tokens are supported for self-managed instances on Free and above. They are also
    supported on GitLab SaaS Premium and above (excluding [trial licenses](https://about.gitlab.com/free-trial/)).
12. If the [tag is protected](project/protected_tags.md), this depends on the access given to Developers and Maintainers.
13. A Maintainer or Owner can't change project features visibility level if
    [project visibility](public_access.md) is set to private.
14. Attached design files are moved together with the issue even if the user doesn't have the
    Developer role.
15. Guest users can only set metadata (for example, labels, assignees, or milestones)
    when creating an issue. They cannot change the metadata on existing issues.
16. In projects that accept contributions from external members, users can create, edit, and close their own merge requests.
17. Authors and assignees can modify the title and description even if they don't have the Reporter role.
18. Authors and assignees can close and reopen issues even if they don't have the Reporter role.
19. The ability to view the Container Registry and pull images is controlled by the [Container Registry's visibility permissions](packages/container_registry/index.md#container-registry-visibility-permissions).
20. Maintainers cannot create, demote, or remove Owners, and they cannot promote users to the Owner role. They also cannot approve Owner role access requests.
21. Authors of tasks can delete them even if they don't have the Owner role, but they have to have at least the Guest role for the project.
22. You must have permission to [view the epic](group/epics/manage_epics.md#who-can-view-an-epic).
23. In GitLab 15.9 and later, users with the Guest role and an Ultimate license can view private repository content if an administrator gives those users permission. The administrator can create a [custom role](#custom-roles) through the API and assign that role to the users.

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
| See that artifacts exist                                                                                                  | ✓ (3)    | ✓ (3) | ✓        | ✓         | ✓          | ✓     |
| View a list of jobs                                                                                                       | ✓ (1)    | ✓ (2) | ✓        | ✓         | ✓          | ✓     |
| View and download artifacts                                                                                               | ✓ (1)    | ✓ (2) | ✓        | ✓         | ✓          | ✓     |
| View [environments](../ci/environments/index.md)                                                                          | ✓ (3)    | ✓ (3) | ✓        | ✓         | ✓          | ✓     |
| View job logs and job details page                                                                                        | ✓ (1)    | ✓ (2) | ✓        | ✓         | ✓          | ✓     |
| View pipelines and pipeline details pages                                                                                 | ✓ (1)    | ✓ (2) | ✓        | ✓         | ✓          | ✓     |
| View pipelines tab in MR                                                                                                  | ✓ (3)    | ✓ (3) | ✓        | ✓         | ✓          | ✓     |
| [View vulnerabilities in a pipeline](application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline) |       | ✓ (2) | ✓        | ✓         | ✓          | ✓     |
| View and download project-level [Secure Files](../api/secure_files.md)                                                    |            |         |          | ✓         | ✓          | ✓     |
| Cancel and retry jobs                                                                                                     |            |         |          | ✓         | ✓          | ✓     |
| Create new [environments](../ci/environments/index.md)                                                                    |            |         |          | ✓         | ✓          | ✓     |
| Delete job logs or job artifacts                                                                                          |            |         |          | ✓ (4)   | ✓          | ✓     |
| Run CI/CD pipeline                                                                                                        |            |         |          | ✓         | ✓          | ✓     |
| Run CI/CD pipeline for a protected branch                                                                                 |            |         |          | ✓ (5)   | ✓ (5)    | ✓     |
| Stop [environments](../ci/environments/index.md)                                                                          |            |         |          | ✓         | ✓          | ✓     |
| View a job with [debug logging](../ci/variables/index.md#enable-debug-logging)                                            |            |         |          | ✓         | ✓          | ✓     |
| Use pipeline editor                                                                                                       |            |         |          | ✓         | ✓          | ✓     |
| Run [interactive web terminals](../ci/interactive_web_terminal/index.md)                                                  |            |         |          | ✓         | ✓          | ✓     |
| Add project runners to project                                                                                           |            |         |          |           | ✓          | ✓     |
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
| Clone source and LFS from internal projects  |                 | ✓ (1)     | ✓  (1)     | ✓             |
| Clone source and LFS from private projects   |                 | ✓ (2)     | ✓  (2)     | ✓ (2)         |
| Pull container images from current project   |                 | ✓         | ✓          | ✓             |
| Pull container images from public projects   |                 | ✓         | ✓          | ✓             |
| Pull container images from internal projects |                 | ✓ (1)     | ✓  (1)     | ✓             |
| Pull container images from private projects  |                 | ✓ (2)     | ✓  (2)     | ✓ (2)         |
| Push container images to current project     |                 | ✓         | ✓          | ✓             |
| Push container images to other projects      |                 |           |            |               |
| Push source and LFS                          |                 |           |            |               |

1. Only if the triggering user is not an external one.
1. Only if the triggering user is a member of the project. See also [Usage of private Docker images with `if-not-present` pull policy](https://docs.gitlab.com/runner/security/index.html#usage-of-private-docker-images-with-if-not-present-pull-policy).

## Group members permissions

Any user can remove themselves from a group, unless they are the last Owner of
the group.

The following table lists group permissions available for each role:

<!-- Keep this table sorted: first, by minimum role, then alphabetically. -->

| Action                                                                                  | Guest | Reporter | Developer | Maintainer | Owner |
|-----------------------------------------------------------------------------------------|-------|----------|-----------|------------|-------|
| Add/remove [child epics](group/epics/manage_epics.md#multi-level-child-epics)           | ✓ (8) | ✓        | ✓         | ✓          | ✓     |
| Add an issue to an [epic](group/epics/index.md)                                         | ✓ (7) | ✓ (7)    | ✓ (7)     | ✓ (7)      | ✓ (7) |
| Browse group                                                                            | ✓     | ✓        | ✓         | ✓          | ✓     |
| Pull a container image using the dependency proxy                                       | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Contribution analytics                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group [epic](group/epics/index.md)                                                 | ✓     | ✓        | ✓         | ✓          | ✓     |
| View [group wiki](project/wiki/group.md) pages                                          | ✓ (5) | ✓        | ✓         | ✓          | ✓     |
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
| Enable/disable package request forwarding                                               |       |          |           | ✓          | ✓     |
| Pull a Container Registry image                                                         | ✓ (6) | ✓        | ✓         | ✓          | ✓     |
| Remove a Container Registry image                                                       |       |          | ✓         | ✓          | ✓     |
| View [Group DevOps Adoption](group/devops_adoption/index.md)                            |       | ✓        | ✓         | ✓          | ✓     |
| View metrics dashboard annotations                                                      |       | ✓        | ✓         | ✓          | ✓     |
| View [Productivity analytics](analytics/productivity_analytics.md)                      |       | ✓        | ✓         | ✓          | ✓     |
| Create and edit [group wiki](project/wiki/group.md) pages                               |       |          | ✓         | ✓          | ✓     |
| Create project in group                                                                 |       |          | ✓ (2)(4)  | ✓ (2)      | ✓ (2) |
| Create/edit/delete group milestones                                                     |       | ✓        | ✓         | ✓          | ✓     |
| Create/edit/delete iterations                                                           |       | ✓        | ✓         | ✓          | ✓     |
| Create/edit/delete metrics dashboard annotations                                        |       |          | ✓         | ✓          | ✓     |
| Enable/disable a dependency proxy                                                       |       |          |           | ✓          | ✓     |
| Purge the dependency proxy for a group                                                  |       |          |           |            | ✓     |
| Create/edit/delete dependency proxy [cleanup policies](packages/dependency_proxy/reduce_dependency_proxy_storage.md#cleanup-policies)                                                  |       |          |           | ✓          | ✓     |
| Use [security dashboard](application_security/security_dashboard/index.md)              |       |          | ✓         | ✓          | ✓     |
| View group Audit Events                                                                 |       |          | ✓ (6)     | ✓ (6)      | ✓     |
| Create subgroup                                                                         |       |          |           | ✓ (1)      | ✓     |
| Delete [group wiki](project/wiki/group.md) pages                                        |       |          | ✓         | ✓          | ✓     |
| Edit [epic](group/epics/index.md) comments (posted by any user)                         |       |          |           | ✓          | ✓     |
| List group deploy tokens                                                                |       |          |           | ✓          | ✓     |
| Manage [group push rules](group/access_and_permissions.md#group-push-rules)                              |       |          |           | ✓          | ✓     |
| View/manage group-level Kubernetes cluster                                              |       |          |           | ✓          | ✓     |
| Create and manage compliance frameworks                                                 |       |          |           |            | ✓     |
| Create/Delete group deploy tokens                                                       |       |          |           |            | ✓     |
| Change group visibility level                                                           |       |          |           |            | ✓     |
| Delete group                                                                            |       |          |           |            | ✓     |
| Delete group [epic](group/epics/index.md)                                               |       |          |           |            | ✓     |
| Disable notification emails                                                             |       |          |           |            | ✓     |
| Edit group settings                                                                     |       |          |           |            | ✓     |
| Edit [SAML SSO](group/saml_sso/index.md)                                                |       |          |           |            | ✓ (3) |
| Filter members by 2FA status                                                            |       |          |           |            | ✓     |
| Manage group level CI/CD variables                                                      |       |          |           |            | ✓     |
| Manage group members                                                                    |       |          |           |            | ✓     |
| Share (invite) groups with groups                                                       |       |          |           |            | ✓     |
| View 2FA status of members                                                              |       |          |           |            | ✓     |
| View [Billing](../subscriptions/gitlab_com/index.md#view-your-gitlab-saas-subscription) |       |          |           |            | ✓ (3) |
| View group [Usage Quotas](usage_quotas.md) page                                         |       |          |           |            | ✓ (3) |
| Manage group runners                                                                    |       |          |           |            | ✓     |
| [Migrate groups](group/import/index.md)                                                 |       |          |           |            | ✓     |
| Manage [subscriptions, and purchase CI/CD minutes and storage](../subscriptions/gitlab_com/index.md)         |       |          |           |            | ✓     |

<!-- markdownlint-disable MD029 -->

1. Groups can be set to allow either Owners, or Owners and users with the Maintainer role, to [create subgroups](group/subgroups/index.md#create-a-subgroup).
2. Default project creation role can be changed at:
   - The [instance level](admin_area/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).
   - The [group level](group/manage.md#specify-who-can-add-projects-to-a-group).
3. Does not apply to subgroups.
4. Developers can push commits to the default branch of a new project only if the [default branch protection](group/manage.md#change-the-default-branch-protection-of-a-group) is set to "Partially protected" or "Not protected".
5. In addition, if your group is public or internal, all users who can see the group can also see group wiki pages.
6. Users can only view events based on their individual actions.
7. You must have permission to [view the epic](group/epics/manage_epics.md#who-can-view-an-epic) and edit the issue.
8. You must have permission to [view](group/epics/manage_epics.md#who-can-view-an-epic) the parent and child epics.

<!-- markdownlint-enable MD029 -->

### Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent groups. This model allows access to
nested groups if you have membership in one of its parents.

For more information, see
[subgroup memberships](group/subgroups/index.md#subgroup-membership).

## Users with Minimal Access **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40942) in GitLab 13.4.
> - Support for inviting users with Minimal Access role [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106438) in GitLab 15.9.

Users with the Minimal Access role do not:

- Count as licensed seats on self-managed Ultimate subscriptions or any GitLab.com subscriptions.
- Automatically have access to projects and subgroups in that root group.

Owners must explicitly add these users to the specific subgroups and
projects.

You can use the Minimal Access role to give the same member more than one role in a group:

1. Add the member to the root group with a Minimal Access role.
1. Invite the member as a direct member with a specific role in any subgroup or project in that group.

Because of an [outstanding issue](https://gitlab.com/gitlab-org/gitlab/-/issues/267996), when a user with the Minimal Access role:

- Signs in with standard web authentication, they receive a `404` error when accessing the parent group.
- Signs in with Group SSO, they receive a `404` error immediately because they are redirected to the parent group page.

To work around the issue, give these users the Guest role or higher to any project or subgroup within the parent group.

## Related topics

- [The GitLab principles behind permissions](https://about.gitlab.com/handbook/product/gitlab-the-product/#permissions-in-gitlab)
- [Members](project/members/index.md)
- Customize permissions on [protected branches](project/protected_branches.md)
- [LDAP user permissions](group/access_and_permissions.md#manage-group-memberships-via-ldap)
- [Value stream analytics permissions](group/value_stream_analytics/index.md#access-permissions-for-value-stream-analytics)
- [Project aliases](../user/project/import/index.md#project-aliases)
- [Auditor users](../administration/auditor_users.md)
- [Confidential issues](project/issues/confidential_issues.md)
- [Container Registry permissions](packages/container_registry/index.md#container-registry-visibility-permissions)
- [Release permissions](project/releases/index.md#release-permissions)

## Custom roles **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `customizable_roles`.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) in GitLab 15.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114524) in GitLab 15.10.

Custom roles allow group members who are assigned the Owner role to create roles
specific to the needs of their organization.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the custom roles feature, see [[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps).

### Create a custom role

To enable custom roles for your group, a group member with the Owner role:

1. Makes sure that there is at least one private project in this group or one of
   its subgroups, so that you can see the effect of giving a Guest a custom role.
1. Creates a personal access token with the API scope.
1. Uses [the API](../api/member_roles.md#add-a-member-role-to-a-group) to create the Guest+1 role for the root group.

### Associate a custom role with an existing group member

To associate a custom role with an existing group member, a group member with
the Owner role:

1. Invites a user to the root group or any subgroup or project in the root
   group's hierarchy as a Guest. At this point, this Guest user cannot see any
   code on the projects in the group or subgroup.
1. Optional. If the Owner does not know the `ID` of the Guest user receiving a custom
   role, finds that `ID` by making an [API request](../api/member_roles.md#list-all-member-roles-of-a-group).

1. Associates the member with the Guest+1 role using the [Group and Project Members API endpoint](../api/members.md#edit-a-member-of-a-group-or-project)

   ```shell
   # to update a project membership
   curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer $YOUR_ACCESS_TOKEN" --data '{"member_role_id": '$MEMBER_ROLE_ID', "access_level": 10}' "https://example.gitlab.com/api/v4/projects/$ID/members/$GUEST_USER_ID"

   # to update a group membership
   curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer $YOUR_ACCESS_TOKEN" --data '{"member_role_id": '$MEMBER_ROLE_ID', "access_level": 10}' "https://example.gitlab.com/api/v4/groups/$ID/members/$GUEST_USER_ID"
   ```

   Where:

   - `$ID`: The `ID` or [URL-encoded path of the project or group](../api/rest/index.md#namespaced-path-encoding) associated with the membership receiving the custom role.
   - `$MEMBER_ROLE_ID`: The `ID` of the member role created in the previous section.
   - `$GUEST_USER_ID`: The `ID` of the Guest user receiving a custom role.

   Now the Guest+1 user can view code on all projects associated with this membership.

### Remove a custom role from a group member

To remove a custom role from a group member, use the [Group and Project Members API endpoint](../api/members.md#edit-a-member-of-a-group-or-project)
and pass an empty `member_role_id` value.

```shell
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer $YOUR_ACCESS_TOKEN" --data '{"member_role_id": "", "access_level": 10}' "https://example.gitlab.com/api/v4/groups/$GROUP_PATH/members/$GUEST_USER_ID"
```

Now the user is a regular Guest.

### Remove a custom role

Removing a custom role also removes all members with that custom role from
the group. If you decide to delete a custom role, you must re-add any users with that custom
role to the group.

To remove a custom role from a group, a group member with
the Owner role:

1. Optional. If the Owner does not know the `ID` of a custom
   role, finds that `ID` by making an [API request](../api/member_roles.md#list-all-member-roles-of-a-group).
1. Uses [the API](../api/member_roles.md#remove-member-role-of-a-group) to delete the custom role.

### Known issues

- Additional permissions can only be applied to users with the Guest role.
- If a user with a custom role is shared with a group or project, their custom role is not transferred over with them. The user has the regular Guest role in the new group or project.
- You cannot use an [Auditor user](../administration/auditor_users.md) as a template for a custom role.
