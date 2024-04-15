---
stage: Govern
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Permissions and roles

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When you add a user to a project or group, you assign them a role.
The role determines which actions they can take in GitLab.

If you add a user to both a project's group and the
project itself, the higher role is used.

GitLab [administrators](../administration/index.md) have all permissions.

## Roles

You can assign users a default role or a [custom role](custom_roles.md).

The available default roles are:

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

| Action                                                                                                                                                                                       | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------|----------|-----------|------------|-------|-------|
| [Analytics](analytics/index.md):<br>View [issue analytics](analytics/issue_analytics.md)                                                                                                     | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Analytics](analytics/index.md):<br>View [value stream analytics](group/value_stream_analytics/index.md)                                                                                     | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Analytics](analytics/index.md):<br>View [DORA metrics](analytics/ci_cd_analytics.md)                                                                                                        |       | ✓        | ✓         | ✓          | ✓     |       |
| [Analytics](analytics/index.md):<br>View [CI/CD analytics](analytics/ci_cd_analytics.md)                                                                                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| [Analytics](analytics/index.md):<br>View [code review analytics](analytics/code_review_analytics.md)                                                                                         |       | ✓        | ✓         | ✓          | ✓     |       |
| [Analytics](analytics/index.md):<br>View [merge request analytics](analytics/merge_request_analytics.md)                                                                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| [Analytics](analytics/index.md):<br>View [repository analytics](analytics/repository_analytics.md)                                                                                           |       | ✓        | ✓         | ✓          | ✓     |       |
| [Application security](application_security/index.md):<br>View licenses in [dependency list](application_security/dependency_list/index.md)                                                  |       |          | ✓         | ✓          | ✓     |       |
| [Application security](application_security/index.md):<br>Create and run [on-demand DAST scans](application_security/dast/on-demand_scan.md)                                                 |       |          | ✓         | ✓          | ✓     |       |
| [Application security](application_security/index.md):<br>View [dependency list](application_security/dependency_list/index.md)                                                              |       |          | ✓         | ✓          | ✓     |       |
| [Application security](application_security/index.md):<br>Create a [CVE ID Request](application_security/cve_id_request.md)                                                                  |       |          |           | ✓          | ✓     |       |
| [Application security](application_security/index.md):<br>Create or assign [security policy project](application_security/policies/index.md)                                                 |       |          |           |            | ✓     |       |
| [Application security](application_security/index.md):<br>Create, edit, delete [individual security policies](application_security/policies/index.md)                                        |       |          | ✓         | ✓          | ✓     |       |
| [Container Registry](packages/container_registry/index.md):<br>Create, edit, delete [cleanup policies](packages/container_registry/delete_container_registry_images.md#use-a-cleanup-policy) |       |          |           | ✓          | ✓     |       |
| [Container registry](packages/container_registry/index.md):<br>Push an image to the container registry                                                                                       |       |          | ✓         | ✓          | ✓     |       |
| [Container registry](packages/container_registry/index.md):<br>Pull an image from the container registry                                                                                     | ✓     | ✓        | ✓         | ✓          | ✓     | The ability to view the container registry and pull images is controlled by the [container registry's visibility permissions](packages/container_registry/index.md#container-registry-visibility-permissions). |
| [Container registry](packages/container_registry/index.md):<br>Remove a container registry image                                                                                             |       |          | ✓         | ✓          | ✓     |       |
| [GitLab agent for Kubernetes](clusters/agent/index.md):<br>View agents                                                                                                                       |       |          | ✓         | ✓          | ✓     |       |
| [GitLab agent for Kubernetes](clusters/agent/index.md):<br>Manage agents                                                                                                                     |       |          |           | ✓          | ✓     |       |
| [GitLab Pages](project/pages/index.md):<br>View Pages protected by [access control](project/pages/pages_access_control.md)                                                                   | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [GitLab Pages](project/pages/index.md):<br>Manage                                                                                                                                            |       |          |           | ✓          | ✓     |       |
| [GitLab Pages](project/pages/index.md):<br>Manage GitLab Pages domains and certificates                                                                                                      |       |          |           | ✓          | ✓     |       |
| [GitLab Pages](project/pages/index.md):<br>Remove GitLab Pages                                                                                                                               |       |          |           | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Assign an alert                                                                                                        | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Participate in on-call rotation                                                                                        | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>View [incident](../operations/incident_management/incidents.md)                                                        | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Change [alert status](../operations/incident_management/alerts.md#change-an-alerts-status)                             |       | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Change [incident severity](../operations/incident_management/manage_incidents.md#change-severity)                      |       | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Create [incident](../operations/incident_management/incidents.md)                                                      |       | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>View [alerts](../operations/incident_management/alerts.md)                                                             |       | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>View [escalation policies](../operations/incident_management/escalation_policies.md)                                   |       | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>View [on-call schedules](../operations/incident_management/oncall_schedules.md)                                        |       | ✓        | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Change [incident escalation status](../operations/incident_management/manage_incidents.md#change-status)               |       |          | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Change [incident escalation policy](../operations/incident_management/manage_incidents.md#change-escalation-policy)    |       |          | ✓         | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [on-call schedules](../operations/incident_management/oncall_schedules.md)                                      |       |          |           | ✓          | ✓     |       |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [escalation policies](../operations/incident_management/escalation_policies.md)                                 |       |          |           | ✓          | ✓     |       |
| [Issue boards](project/issue_board.md):<br>Create or delete lists                                                                                                                            |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issue boards](project/issue_board.md):<br>Move issues between lists                                                                                                                         |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Add Labels                                                                                                                                             | ✓     | ✓        | ✓         | ✓          | ✓     | Guest users can only set metadata (for example, labels, assignees, or milestones) when creating an issue. They cannot change the metadata on existing issues. |
| [Issues](project/issues/index.md):<br>Add to epic                                                                                                                                            |       | ✓        | ✓         | ✓          | ✓     | You must have permission to [view the epic](group/epics/manage_epics.md#who-can-view-an-epic). |
| [Issues](project/issues/index.md):<br>Assign                                                                                                                                                 | ✓     | ✓        | ✓         | ✓          | ✓     | Guest users can only set metadata (for example, labels, assignees, or milestones) when creating an issue. They cannot change the metadata on existing issues. |
| [Issues](project/issues/index.md):<br>Create                                                                                                                                                 | ✓     | ✓        | ✓         | ✓          | ✓     | Authors and assignees can modify the title and description even if they don't have the Reporter role. |
| [Issues](project/issues/index.md):<br>Create [confidential issues](project/issues/confidential_issues.md)                                                                                    | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>View [Design Management](project/issues/design_management.md) pages                                                                                    | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>View [related issues](project/issues/related_issues.md)                                                                                                | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Set [weight](project/issues/issue_weight.md)                                                                                                           |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Set metadata such as labels, milestones, or assignees when creating an issue                                                                           | ✓     | ✓        | ✓         | ✓          | ✓     | Guest users can only set metadata (for example, labels, assignees, or milestones) when creating an issue. They cannot change the metadata on existing issues. |
| [Issues](project/issues/index.md):<br>Edit metadata such labels, milestones, or assignees for an existing issue                                                                              |       | ✓        | ✓         | ✓          | ✓     | Guest users can only set metadata (for example, labels, assignees, or milestones) when creating an issue. They cannot change the metadata on existing issues. |
| [Issues](project/issues/index.md):<br>Set [parent epic](group/epics/manage_epics.md#add-an-existing-issue-to-an-epic)                                                                        |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>View [confidential issues](project/issues/confidential_issues.md)                                                                                      |       | ✓        | ✓         | ✓          | ✓     | Guest users can only view the [confidential issues](project/issues/confidential_issues.md) they created themselves or are assigned to. |
| [Issues](project/issues/index.md):<br>Close / reopen                                                                                                                                         |       | ✓        | ✓         | ✓          | ✓     | Authors and assignees can close and reopen issues even if they don't have the Reporter role. |
| [Issues](project/issues/index.md):<br>Lock threads                                                                                                                                           |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Manage [related issues](project/issues/related_issues.md)                                                                                              |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Manage tracker                                                                                                                                         |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Move issues                                                                                                                                            |       | ✓        | ✓         | ✓          | ✓     | Attached design files are moved together with the issue. |
| [Issues](project/issues/index.md):<br>Set issue [time tracking](project/time_tracking.md) estimate and time spent                                                                            |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Archive [Design Management](project/issues/design_management.md) files                                                                                 |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Upload [Design Management](project/issues/design_management.md) files                                                                                  |       | ✓        | ✓         | ✓          | ✓     |       |
| [Issues](project/issues/index.md):<br>Delete                                                                                                                                                 |       |          |           |            | ✓     |       |
| [License Scanning](compliance/license_scanning_of_cyclonedx_files/index.md):<br>View allowed and denied licenses                                                                             | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [License Scanning](compliance/license_scanning_of_cyclonedx_files/index.md):<br>View License Compliance reports                                                                              | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [License Scanning](compliance/license_scanning_of_cyclonedx_files/index.md):<br>View License list                                                                                            |       | ✓        | ✓         | ✓          | ✓     |       |
| [License approval policies](../user/compliance/license_approval_policies.md):<br>Manage license policy                                                                                       |       |          |           | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>View a merge request                                                                                                                   | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [Merge requests](project/merge_requests/index.md):<br>Assign reviewer                                                                                                                        |       |          | ✓         | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>View list                                                                                                                              |       | ✓        | ✓         | ✓          | ✓     | Members with the Guest role can view the list of MRs in public projects. Private projects restrict Guests from viewing MR lists. |
| [Merge requests](project/merge_requests/index.md):<br>Apply code change suggestions                                                                                                          |       |          | ✓         | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>Approve                                                                                                                                |       |          | ✓         | ✓          | ✓     | For information on eligible approvers for merge requests, see [Eligible approvers](project/merge_requests/approvals/rules.md#eligible-approvers). |
| [Merge requests](project/merge_requests/index.md):<br>Assign                                                                                                                                 |       |          | ✓         | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>Create                                                                                                                                 |       |          | ✓         | ✓          | ✓     | In projects that accept contributions from external members, users can create, edit, and close their own merge requests. |
| [Merge requests](project/merge_requests/index.md):<br>Add labels                                                                                                                             |       |          | ✓         | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>Lock threads                                                                                                                           |       |          | ✓         | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>Manage or accept                                                                                                                       |       |          | ✓         | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>[Resolve a thread](project/merge_requests/index.md#resolve-a-thread)                                                                   |       |          | ✓         | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>Manage [merge approval rules](project/merge_requests/approvals/settings.md) (project settings)                                         |       |          |           | ✓          | ✓     |       |
| [Merge requests](project/merge_requests/index.md):<br>Delete                                                                                                                                 |       |          |           |            | ✓     |       |
| [Objectives and key results](okrs.md):<br>Add a child OKR                                                                                                                                    | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Objectives and key results](okrs.md):<br>Add a linked item                                                                                                                                  | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Objectives and key results](okrs.md):<br>Create                                                                                                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Objectives and key results](okrs.md):<br>View                                                                                                                                               | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Objectives and key results](okrs.md):<br>Change confidentiality                                                                                                                             |       | ✓        | ✓         | ✓          | ✓     |       |
| [Objectives and key results](okrs.md):<br>Edit                                                                                                                                               |       | ✓        | ✓         | ✓          | ✓     |       |
| [Package registry](packages/index.md):<br>Pull a package                                                                                                                                     | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [Package registry](packages/index.md):<br>Publish a package                                                                                                                                  |       |          | ✓         | ✓          | ✓     |       |
| [Package registry](packages/index.md):<br>Delete a package                                                                                                                                   |       |          |           | ✓          | ✓     |       |
| [Package registry](packages/index.md):<br>Delete a file associated with a package                                                                                                            |       |          |           | ✓          | ✓     |       |
| [Project operations](../operations/index.md):<br>View [Error Tracking](../operations/error_tracking.md) list                                                                                 |       | ✓        | ✓         | ✓          | ✓     |       |
| [Project operations](../operations/index.md):<br>Manage [Feature flags](../operations/feature_flags.md)                                                                                      |       |          | ✓         | ✓          | ✓     |       |
| [Project operations](../operations/index.md):<br>Manage [Error Tracking](../operations/error_tracking.md)                                                                                    |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Download project                                                                                                                                            | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [Projects](project/index.md):<br>Leave comments                                                                                                                                              | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Reposition comments on images (posted by any user)                                                                                                          | ✓     | ✓        | ✓         | ✓          | ✓     | Applies only to comments on [Design Management](project/issues/design_management.md) designs. |
| [Projects](project/index.md):<br>View [Insights](project/insights/index.md)                                                                                                                  | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>View [releases](project/releases/index.md)                                                                                                                  | ✓     | ✓        | ✓         | ✓          | ✓     | Guest users can access GitLab [**Releases**](project/releases/index.md) for downloading assets but are not allowed to download the source code nor see [repository information like commits and release evidence](project/releases/index.md#view-a-release-and-download-assets). |
| [Projects](project/index.md):<br>View [Requirements](project/requirements/index.md)                                                                                                          | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>View [time tracking](project/time_tracking.md) reports                                                                                                      | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [Projects](project/index.md):<br>View [wiki](project/wiki/index.md) pages                                                                                                                    | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Create [snippets](snippets.md)                                                                                                                              |       | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Manage labels                                                                                                                                               |       | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>View [project traffic statistics](../api/project_statistics.md)                                                                                             |       | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Create, edit, delete [milestones](project/milestones/index.md).                                                                                             |       | ✓        | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Create, edit, delete [releases](project/releases/index.md)                                                                                                  |       |          | ✓         | ✓          | ✓     | If the [tag is protected](project/protected_tags.md), this depends on the access given to Developers and Maintainers. |
| [Projects](project/index.md):<br>Create, edit [wiki](project/wiki/index.md) pages                                                                                                            |       |          | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Enable [Review Apps](../ci/review_apps/index.md)                                                                                                            |       |          | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>View project [Audit Events](../administration/audit_event_reports.md)                                                                                              |       |          | ✓         | ✓          | ✓     | Users can only view events based on their individual actions. |
| [Projects](project/index.md):<br>Add [deploy keys](project/deploy_keys/index.md)                                                                                                             |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Add new [team members](project/members/index.md)                                                                                                            |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Manage [team members](project/members/index.md)                                                                                                             |       |          |           | ✓          | ✓     | Maintainers cannot create, demote, or remove Owners, and they cannot promote users to the Owner role. They also cannot approve Owner role access requests. |
| [Projects](project/index.md):<br>Change [project features visibility](public_access.md) level                                                                                                |       |          |           | ✓          | ✓     | A Maintainer or Owner can't change project features visibility level if [project visibility](public_access.md) is set to private. |
| [Projects](project/index.md):<br>Configure [webhooks](project/integrations/webhooks.md)                                                                                                      |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Delete [wiki](project/wiki/index.md) pages                                                                                                                  |       |          | ✓         | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Edit comments (posted by any user)                                                                                                                          |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Edit project badges                                                                                                                                         |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Edit project settings                                                                                                                                       |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>[Export project](project/settings/import_export.md)                                                                                                         |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Manage [project access tokens](project/settings/project_access_tokens.md)                                                                                   |       |          |           | ✓          | ✓     | For self-managed GitLab, project access tokens are available in all tiers. For GitLab.com, project access tokens are supported in the Premium and Ultimate tier (excluding [trial licenses](https://about.gitlab.com/free-trial/)). |
| [Projects](project/index.md):<br>Manage [Project Operations](../operations/index.md)                                                                                                         |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Rename project                                                                                                                                              |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Share (invite) projects with groups                                                                                                                         |       |          |           | ✓          | ✓     | When [Share Group Lock](group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups) is enabled the project can't be shared with other groups. It does not affect group with group sharing. |
| [Projects](project/index.md):<br>View 2FA status of members                                                                                                                                  |       |          |           | ✓          | ✓     |       |
| [Projects](project/index.md):<br>Assign project to a [compliance framework](project/working_with_projects.md#add-a-compliance-framework-to-a-project)                                        |       |          |           |            | ✓     |       |
| [Projects](project/index.md):<br>Archive project                                                                                                                                             |       |          |           |            | ✓     |       |
| [Projects](project/index.md):<br>Change project visibility level                                                                                                                             |       |          |           |            | ✓     |       |
| [Projects](project/index.md):<br>Delete project                                                                                                                                              |       |          |           |            | ✓     |       |
| [Projects](project/index.md):<br>Disable notification emails                                                                                                                                 |       |          |           |            | ✓     |       |
| [Projects](project/index.md):<br>Transfer project to another namespace                                                                                                                       |       |          |           |            | ✓     |       |
| [Projects](project/index.md): View [Usage Quotas](usage_quotas.md) page                                                                                                                      |       |          |           | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Pull project code                                                                                                                              | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [Repository](project/repository/index.md):<br>View project code                                                                                                                              | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. In GitLab 15.9 and later, users with the Guest role and an Ultimate license can view private repository content if an administrator (on self-managed or GitLab Dedicated) or group owner (on GitLab.com) gives those users permission. The administrator or group owner can create a [custom role](custom_roles.md) through the API or UI and assign that role to the users. |
| [Repository](project/repository/index.md):<br>View a commit status                                                                                                                           |       | ✓        | ✓         | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Add tags                                                                                                                                       |       |          | ✓         | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Create new branches                                                                                                                            |       |          | ✓         | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Create or update commit status                                                                                                                 |       |          | ✓         | ✓          | ✓     | If the [branch is protected](project/protected_branches.md), this depends on the access given to Developers and Maintainers. |
| [Repository](project/repository/index.md):<br>Force push to non-protected branches                                                                                                           |       |          | ✓         | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Push to non-protected branches                                                                                                                 |       |          | ✓         | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Remove non-protected branches                                                                                                                  |       |          | ✓         | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Rewrite or remove Git tags                                                                                                                     |       |          | ✓         | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Enable or disable branch protection                                                                                                            |       |          |           | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Enable or disable tag protection                                                                                                               |       |          |           | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Manage [push rules](project/repository/push_rules.md)                                                                                          |       |          |           | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Push to protected branches                                                                                                                     |       |          |           | ✓          | ✓     | If the [branch is protected](project/protected_branches.md), this depends on the access given to Developers and Maintainers. |
| [Repository](project/repository/index.md):<br>Turn on or off protected branch push for developers                                                                                            |       |          |           | ✓          | ✓     |       |
| [Repository](project/repository/index.md):<br>Remove fork relationship                                                                                                                       |       |          |           |            | ✓     |       |
| [Repository](project/repository/index.md):<br>Force push to protected branches                                                                                                               |       |          |           |            |       | Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [protected branches](project/protected_branches.md). |
| [Repository](project/repository/index.md):<br>Remove protected branches by using the UI or API                                                                                               |       |          |           | ✓          | ✓     |       |
| [Requirements Management](project/requirements/index.md):<br>Archive / reopen                                                                                                                |       | ✓        | ✓         | ✓          | ✓     | Authors and assignees can archive and re-open even if they don’t have the Reporter role. |
| [Requirements Management](project/requirements/index.md):<br>Create / edit                                                                                                                   |       | ✓        | ✓         | ✓          | ✓     |  Authors and assignees can modify the title and description even if they don’t have the Reporter role.|
| [Requirements Management](project/requirements/index.md):<br>Import / export                                                                                                                 |       | ✓        | ✓         | ✓          | ✓     |       |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Create issue from vulnerability finding                                                                           |       |          | ✓         | ✓          | ✓     |       |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Create vulnerability from vulnerability finding                                                                   |       |          | ✓         | ✓          | ✓     |       |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Dismiss vulnerability                                                                                             |       |          | ✓         | ✓          | ✓     | In GitLab 16.4 the ability for `Developers` to change the status of a vulnerability (`admin_vulnerability`) was [deprecated](../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role). The `admin_vulnerability` permission will be removed, by default, from all `Developer` roles in GitLab 17.0. |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Dismiss vulnerability finding                                                                                     |       |          | ✓         | ✓          | ✓     | In GitLab 16.4 the ability for `Developers` to change the status of a vulnerability (`admin_vulnerability`) was [deprecated](../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role). The `admin_vulnerability` permission will be removed, by default, from all `Developer` roles in GitLab 17.0. |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Resolve vulnerability                                                                                             |       |          | ✓         | ✓          | ✓     | In GitLab 16.4 the ability for `Developers` to change the status of a vulnerability (`admin_vulnerability`) was [deprecated](../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role). The `admin_vulnerability` permission will be removed, by default, from all `Developer` roles in GitLab 17.0. |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Revert vulnerability to detected state                                                                            |       |          | ✓         | ✓          | ✓     | In GitLab 16.4 the ability for `Developers` to change the status of a vulnerability (`admin_vulnerability`) was [deprecated](../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role). The `admin_vulnerability` permission will be removed, by default, from all `Developer` roles in GitLab 17.0. |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Use security dashboard                                                                                            |       |          | ✓         | ✓          | ✓     |       |
| [Security dashboard](application_security/security_dashboard/index.md):<br>View vulnerability                                                                                                |       |          | ✓         | ✓          | ✓     |       |
| [Security dashboard](application_security/security_dashboard/index.md):<br>View vulnerability findings in [dependency list](application_security/dependency_list/index.md)                   |       |          | ✓         | ✓          | ✓     |       |
| [Tasks](tasks.md):<br>Add a linked item                                                                                                                                                      | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| [Tasks](tasks.md):<br>Create                                                                                                                                                                 |       | ✓        | ✓         | ✓          | ✓     | Authors and assignees can modify the title and description even if they don't have the Reporter role. |
| [Tasks](tasks.md):<br>Edit                                                                                                                                                                   |       | ✓        | ✓         | ✓          | ✓     |       |
| [Tasks](tasks.md):<br>Remove from issue                                                                                                                                                      |       | ✓        | ✓         | ✓          | ✓     |       |
| [Tasks](tasks.md):<br>Delete                                                                                                                                                                 |       |          |           |            | ✓     | Authors of tasks can delete them even if they don't have the Owner role, but they have to have at least the Guest role for the project. |
| [Terraform](infrastructure/index.md):<br>Read Terraform state                                                                                                                                |       |          | ✓         | ✓          | ✓     |       |
| [Terraform](infrastructure/index.md):<br>Manage Terraform state                                                                                                                              |       |          |           | ✓          | ✓     |       |
| [Test cases](../ci/test_cases/index.md):<br>Archive                                                                                                                                          |       | ✓        | ✓         | ✓          | ✓     |       |
| [Test cases](../ci/test_cases/index.md):<br>Create                                                                                                                                           |       | ✓        | ✓         | ✓          | ✓     |       |
| [Test cases](../ci/test_cases/index.md):<br>Move                                                                                                                                             |       | ✓        | ✓         | ✓          | ✓     |       |
| [Test cases](../ci/test_cases/index.md):<br>Reopen                                                                                                                                           |       | ✓        | ✓         | ✓          | ✓     |       |

## GitLab CI/CD permissions

[GitLab CI/CD](../ci/index.md) permissions for some roles can be modified by these settings:

- [Public pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines):
  When set to public, gives access to certain CI/CD features to *Guest* project members.
- [Pipeline visibility](../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects):
  When set to **Everyone with Access**, gives access to certain CI/CD "view" features to *non-project* members.

| Action                                                                                                                         | Non-member | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|--------------------------------------------------------------------------------------------------------------------------------|------------|-------|----------|-----------|------------|-------|-------|
| See that artifacts exist                                                                                                       | ✓          | ✓     | ✓        | ✓         | ✓          | ✓     | Non-members and guests: Only if the project is public. |
| View a list of jobs                                                                                                            | ✓          | ✓     | ✓        | ✓         | ✓          | ✓     | Non-members: Only if the project is public and **Public pipelines** is enabled in **Project Settings > CI/CD**.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| View and download artifacts                                                                                                    | ✓          | ✓     | ✓        | ✓         | ✓          | ✓     | Non-members: Only if the project is public, **Public pipelines** is enabled in **Project Settings > CI/CD**, and [`artifacts:public: false`](../ci/yaml/index.md#artifactspublic) is not set on the job.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD** and `artifacts:public: false` is not set on the job.<br>Reporters: Only if `artifacts:public: false` is not set on the job. |
| View [environments](../ci/environments/index.md)                                                                               | ✓          | ✓     | ✓        | ✓         | ✓          | ✓     | Non-members and guests: Only if the project is public. |
| View job logs and job details page                                                                                             | ✓          | ✓     | ✓        | ✓         | ✓          | ✓     | Non-members: Only if the project is public and **Public pipelines** is enabled in **Project Settings > CI/CD**.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| View pipelines and pipeline details pages                                                                                      | ✓          | ✓     | ✓        | ✓         | ✓          | ✓     | Non-members: Only if the project is public and **Public pipelines** is enabled in **Project Settings > CI/CD**.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| View pipelines tab in MR                                                                                                       | ✓          | ✓     | ✓        | ✓         | ✓          | ✓     | Non-members and guests: Only if the project is public. |
| [View vulnerabilities in a pipeline](application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline) |            | ✓     | ✓        | ✓         | ✓          | ✓     | Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| Run deployment job for a protected environment                                                                                 |            |       | ✓        | ✓         | ✓          | ✓     | Reporters: Only if the user is [part of a group with access to the protected environment](../ci/environments/protected_environments.md#deployment-only-access-to-protected-environments).<br>Developers and maintainers: Only if the user is [allowed to deploy to the protected branch](../ci/environments/protected_environments.md#protecting-environments). |
| View and download project-level [Secure Files](../api/secure_files.md)                                                         |            |       |          | ✓         | ✓          | ✓     |       |
| Retry jobs                                                                                                                     |            |       |          | ✓         | ✓          | ✓     |       |
| Cancel jobs                                                                                                                    |            |       |          | ✓         | ✓          | ✓     | Cancellation permissions can be [restricted in the pipeline settings](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs). |
| Create new [environments](../ci/environments/index.md)                                                                         |            |       |          | ✓         | ✓          | ✓     |       |
| Delete job logs or job artifacts                                                                                               |            |       |          | ✓         | ✓          | ✓     | Developers: Only if the job was triggered by the user and runs for a non-protected branch. |
| Run CI/CD pipeline                                                                                                             |            |       |          | ✓         | ✓          | ✓     |       |
| Run CI/CD pipeline for a protected branch                                                                                      |            |       |          | ✓         | ✓          | ✓     | Developers and maintainers: Only if the user is [allowed to merge or push to the protected branch](../ci/pipelines/index.md#pipeline-security-on-protected-branches). |
| Stop [environments](../ci/environments/index.md)                                                                               |            |       |          | ✓         | ✓          | ✓     |       |
| View a job with [debug logging](../ci/variables/index.md#enable-debug-logging)                                                 |            |       |          | ✓         | ✓          | ✓     |       |
| Use pipeline editor                                                                                                            |            |       |          | ✓         | ✓          | ✓     |       |
| Run [interactive web terminals](../ci/interactive_web_terminal/index.md)                                                       |            |       |          | ✓         | ✓          | ✓     |       |
| Add project runners to project                                                                                                 |            |       |          |           | ✓          | ✓     |       |
| Clear runner caches manually                                                                                                   |            |       |          |           | ✓          | ✓     |       |
| Enable instance runners in project                                                                                               |            |       |          |           | ✓          | ✓     |       |
| Manage CI/CD settings                                                                                                          |            |       |          |           | ✓          | ✓     |       |
| Manage job triggers                                                                                                            |            |       |          |           | ✓          | ✓     |       |
| Manage project-level CI/CD variables                                                                                           |            |       |          |           | ✓          | ✓     |       |
| Manage project-level [Secure Files](../api/secure_files.md)                                                                    |            |       |          |           | ✓          | ✓     |       |
| Use [environment terminals](../ci/environments/index.md#web-terminals-deprecated)                                              |            |       |          |           | ✓          | ✓     |       |
| Delete pipelines                                                                                                               |            |       |          |           |            | ✓     |       |

### Job permissions

This table shows granted privileges for jobs triggered by specific types of users:

| Action                                       | Guest, Reporter | Developer | Maintainer | Administrator | Notes |
|----------------------------------------------|-----------------|-----------|------------|---------------|-------|
| Run CI job                                   |                 | ✓         | ✓          | ✓             |       |
| Clone source and LFS from current project    |                 | ✓         | ✓          | ✓             |       |
| Clone source and LFS from public projects    |                 | ✓         | ✓          | ✓             |       |
| Clone source and LFS from internal projects  |                 | ✓         | ✓          | ✓             | Developers and Maintainers: Only if the triggering user is not an external user. |
| Clone source and LFS from private projects   |                 | ✓         | ✓          | ✓             | Only if the triggering user is a member of the project. See also [Usage of private Docker images with `if-not-present` pull policy](https://docs.gitlab.com/runner/security/index.html#usage-of-private-docker-images-with-if-not-present-pull-policy). |
| Pull container images from current project   |                 | ✓         | ✓          | ✓             |       |
| Pull container images from public projects   |                 | ✓         | ✓          | ✓             |       |
| Pull container images from internal projects |                 | ✓         | ✓          | ✓             | Developers and Maintainers: Only if the triggering user is not an external user. |
| Pull container images from private projects  |                 | ✓         | ✓          | ✓             | Only if the triggering user is a member of the project. See also [Usage of private Docker images with `if-not-present` pull policy](https://docs.gitlab.com/runner/security/index.html#usage-of-private-docker-images-with-if-not-present-pull-policy). |
| Push container images to current project     |                 | ✓         | ✓          | ✓             |       |
| Push container images to other projects      |                 |           |            |               |       |
| Push source and LFS                          |                 |           |            |               |       |

## Group members permissions

Any user can remove themselves from a group, unless they are the last Owner of
the group.

The following table lists group permissions available for each role:

<!-- Keep this table sorted: first, by minimum role, then alphabetically. -->

| Action                                                                                  | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-----------------------------------------------------------------------------------------|-------|----------|-----------|------------|-------|-------|
| Add an issue to an [epic](group/epics/index.md)                                         | ✓     | ✓        | ✓         | ✓          | ✓     | You must have permission to [view the epic](group/epics/manage_epics.md#who-can-view-an-epic) and edit the issue. |
| Add/remove [child epics](group/epics/manage_epics.md#multi-level-child-epics)           | ✓     | ✓        | ✓         | ✓          | ✓     | You must have permission to [view](group/epics/manage_epics.md#who-can-view-an-epic) the parent and child epics. |
| Browse group                                                                            | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Pull a container image using the dependency proxy                                       | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Pull a container registry image                                                         | ✓     | ✓        | ✓         | ✓          | ✓     | Guests can only view events based on their individual actions. |
| View [group wiki](project/wiki/group.md) pages                                          | ✓     | ✓        | ✓         | ✓          | ✓     | Guests: In addition, if your group is public or internal, all users who can see the group can also see group wiki pages. |
| View [Insights](project/insights/index.md)                                              | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [Insights](project/insights/index.md) charts                                       | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [Issue analytics](analytics/issue_analytics.md)                                    | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View Contribution analytics                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View group [epic](group/epics/index.md)                                                 | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View value stream analytics                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Create/edit group [epic](group/epics/index.md)                                          |       | ✓        | ✓         | ✓          | ✓     |       |
| Create/edit/delete [epic boards](group/epics/epic_boards.md)                            |       | ✓        | ✓         | ✓          | ✓     |       |
| Create/edit/delete group milestones                                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| Create/edit/delete iterations                                                           |       | ✓        | ✓         | ✓          | ✓     |       |
| Manage group labels                                                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| Pull [packages](packages/index.md)                                                      |       | ✓        | ✓         | ✓          | ✓     |       |
| View [Group DevOps Adoption](group/devops_adoption/index.md)                            |       | ✓        | ✓         | ✓          | ✓     |       |
| View [Productivity analytics](analytics/productivity_analytics.md)                      |       | ✓        | ✓         | ✓          | ✓     |       |
| View metrics dashboard annotations                                                      |       | ✓        | ✓         | ✓          | ✓     |       |
| Publish [packages](packages/index.md)                                                   |       |          | ✓         | ✓          | ✓     |       |
| Remove a container registry image                                                       |       |          | ✓         | ✓          | ✓     |       |
| Create and edit [group wiki](project/wiki/group.md) pages                               |       |          | ✓         | ✓          | ✓     |       |
| Create project in group                                                                 |       |          | ✓         | ✓          | ✓     | Developers, Maintainers and Owners: Only if the project creation role is set at the [instance level](../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects) or the [group level](group/index.md#specify-who-can-add-projects-to-a-group).<br><br>Developers: Developers can push commits to the default branch of a new project only if the [default branch protection](group/manage.md#change-the-default-branch-protection-of-a-group) is set to "Partially protected" or "Not protected". |
| Create/edit/delete metrics dashboard annotations                                        |       |          | ✓         | ✓          | ✓     |       |
| Use [security dashboard](application_security/security_dashboard/index.md)              |       |          | ✓         | ✓          | ✓     |       |
| View group Audit Events                                                                 |       |          | ✓         | ✓          | ✓     | Developers and Maintainers can only view events based on their individual actions. |
| Delete [group wiki](project/wiki/group.md) pages                                        |       |          | ✓         | ✓          | ✓     |       |
| Create subgroup                                                                         |       |          |           | ✓          | ✓     | Maintainers: Only if users with the Maintainer role are [allowed to create subgroups](group/subgroups/index.md#change-who-can-create-subgroups). |
| Create/edit/delete [Maven and generic package duplicate settings](packages/generic_packages/index.md#do-not-allow-duplicate-generic-packages) |  |  |  | ✓ | ✓ |       |
| Create/edit/delete dependency proxy [cleanup policies](packages/dependency_proxy/reduce_dependency_proxy_storage.md#cleanup-policies)         |  |  |  | ✓ | ✓ |       |
| Delete [packages](packages/index.md)                                                    |       |          |           | ✓          | ✓     |       |
| Edit [epic](group/epics/index.md) comments (posted by any user)                         |       |          |           | ✓          | ✓     |       |
| Enable/disable a dependency proxy                                                       |       |          |           | ✓          | ✓     |       |
| Enable/disable package request forwarding                                               |       |          |           | ✓          | ✓     |       |
| Fork project into a group                                                               |       |          |           | ✓          | ✓     |       |
| Manage [group approval rules](project/merge_requests/approvals/settings.md) (group settings) |  |          |           | ✓          | ✓     |       |
| Manage [group push rules](group/access_and_permissions.md#group-push-rules)             |       |          |           | ✓          | ✓     |       |
| View group runners                                                                      |       |          |           | ✓          | ✓     |       |
| View/manage group-level Kubernetes cluster                                              |       |          |           | ✓          | ✓     |       |
| List group deploy tokens                                                                |       |          |           |            | ✓     |       |
| Change group visibility level                                                           |       |          |           |            | ✓     |       |
| Create and manage compliance frameworks                                                 |       |          |           |            | ✓     |       |
| Create/Delete group deploy tokens                                                       |       |          |           |            | ✓     |       |
| Delete group                                                                            |       |          |           |            | ✓     |       |
| Delete group [epic](group/epics/index.md)                                               |       |          |           |            | ✓     |       |
| Disable notification emails                                                             |       |          |           |            | ✓     |       |
| Edit [SAML SSO](group/saml_sso/index.md)                                                |       |          |           |            | ✓     | Does not apply to subgroups |
| Edit group settings                                                                     |       |          |           |            | ✓     |       |
| Configure project templates                                                             |       |          |           |            | ✓     |       |
| Filter members by 2FA status                                                            |       |          |           |            | ✓     |       |
| Manage [subscriptions, and purchase storage and compute minutes](../subscriptions/gitlab_com/index.md) |    |    |     |            | ✓     |       |
| Manage group level CI/CD variables                                                      |       |          |           |            | ✓     |       |
| Manage group members                                                                    |       |          |           |            | ✓     |       |
| Manage group runners                                                                    |       |          |           |            | ✓     |       |
| Manage group-level custom roles                                                         |       |          |           |            | ✓     |       |
| [Migrate groups](group/import/index.md)                                                 |       |          |           |            | ✓     |       |
| Purge the dependency proxy for a group                                                  |       |          |           |            | ✓     |       |
| Share (invite) groups with groups                                                       |       |          |           |            | ✓     |       |
| View [Billing](../subscriptions/gitlab_com/index.md#view-your-gitlabcom-subscription) |       |          |           |            | ✓     | Does not apply to subgroups |
| View 2FA status of members                                                              |       |          |           |            | ✓     |       |
| View group [Usage Quotas](usage_quotas.md) page                                         |       |          |           |            | ✓     | Does not apply to subgroups |

### Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent groups. This model allows access to
nested groups if you have membership in one of its parents.

For more information, see
[subgroup memberships](group/subgroups/index.md#subgroup-membership).

## Users with Minimal Access

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40942) in GitLab 13.4.
> - Support for inviting users with Minimal Access role [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106438) in GitLab 15.9.

Users with the Minimal Access role do not:

- Automatically have access to projects and subgroups in that root group.
- Count as licensed seats on self-managed Ultimate subscriptions or any GitLab.com subscriptions, provided the user has no other role anywhere in the instance or in the GitLab.com namespace.

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

- [Custom roles](custom_roles.md)
- [The GitLab principles behind permissions](https://handbook.gitlab.com/handbook/product/gitlab-the-product/#permissions-in-gitlab)
- [Members](project/members/index.md)
- Customize permissions on [protected branches](project/protected_branches.md)
- [LDAP user permissions](group/access_and_permissions.md#manage-group-memberships-via-ldap)
- [Value stream analytics permissions](group/value_stream_analytics/index.md#access-permissions-for-value-stream-analytics)
- [Project aliases](../user/project/working_with_projects.md#project-aliases)
- [Auditor users](../administration/auditor_users.md)
- [Confidential issues](project/issues/confidential_issues.md)
- [Container registry permissions](packages/container_registry/index.md#container-registry-visibility-permissions)
- [Release permissions](project/releases/index.md#release-permissions)
- [Read-only namespaces](../user/read_only_namespaces.md)
