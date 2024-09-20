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

A user's role determines what permissions they have on a project. The Owner role provides all permissions but is
available only:

- For group and project Owners.
- For Administrators.

Personal [namespace](namespace/index.md) owners:

- Are displayed as having the Maintainer role on projects in the namespace, but have the same permissions as a user with the Owner role.
- For new projects in the namespace, are displayed as having the Owner role.

For more information about how to manage project members, see
[members of a project](project/members/index.md).

The following tables list project permissions available for each role.

### Analytics

Project permissions for [analytics](../user/analytics/index.md) features including value streams, usage trends, product analytics, and insights.

| Action                                                                                                                                                   | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|----------------------------------------------------------------------------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View [issue analytics](group/issues_analytics/index.md)                                                                                                  | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [value stream analytics](group/value_stream_analytics/index.md)                                                                                     | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [Value Streams Dashboard & AI Impact analytics](analytics/value_streams_dashboard.md)                                                               |       | ✓        | ✓         | ✓          | ✓     |       |
| View [DORA metrics](analytics/ci_cd_analytics.md)                                                                                                        |       | ✓        | ✓         | ✓          | ✓     |       |
| View [CI/CD analytics](analytics/ci_cd_analytics.md)                                                                                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| View [code review analytics](analytics/code_review_analytics.md)                                                                                         |       | ✓        | ✓         | ✓          | ✓     |       |
| View [merge request analytics](analytics/merge_request_analytics.md)                                                                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| View [repository analytics](analytics/repository_analytics.md)                                                                                           |       | ✓        | ✓         | ✓          | ✓     |       |

### Application security

Project permissions for [application security](application_security/secure_your_application.md) features including dependency management, security analyzers, security policies, and vulnerability management.

| Action                                                                                                                             | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|------------------------------------------------------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View licenses in [dependency list](application_security/dependency_list/index.md)                                                  |       |          |     ✓     |     ✓      |   ✓   |       |
| View [dependency list](application_security/dependency_list/index.md)                                                              |       |          |     ✓     |     ✓      |   ✓   |       |
| View [vulnerability report](application_security/vulnerability_report/index.md)                                                    |       |          |     ✓     |     ✓      |   ✓   |       |
| View [security dashboard](application_security/security_dashboard/index.md)                                                        |       |          |     ✓     |     ✓      |   ✓   |       |
| [Create issue](application_security/vulnerabilities/index.md#create-a-gitlab-issue-for-a-vulnerability) from vulnerability finding |       |          |     ✓     |     ✓      |   ✓   |       |
| Manually [create a vulnerability](application_security/vulnerability_report/index.md#manually-add-a-vulnerability)                 |       |          |     ✓     |     ✓      |   ✓   |       |
| Create and run [on-demand DAST scans](application_security/dast/on-demand_scan.md)                                                 |       |          |     ✓     |     ✓      |   ✓   |       |
| Create, edit, delete [individual security policies](application_security/policies/index.md)                                        |       |          |     ✓     |     ✓      |   ✓   |       |
| Create a [CVE ID Request](application_security/cve_id_request.md)                                                                  |       |          |           |     ✓      |   ✓   |       |
| Change vulnerability status                                                                                                        |       |          |           |     ✓      |   ✓   | The `admin_vulnerability` permission was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/412693) from the Developer role in GitLab 17.0. |
| Create or assign [security policy project](application_security/policies/index.md)                                                 |       |          |           |            |   ✓   |       |
| Manage [security configurations](application_security/configuration/index.md)                                                      |       |          |           |            |   ✓   |       |

### CI/CD

[GitLab CI/CD](../ci/index.md) permissions for some roles can be modified by these settings:

- [Public pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines):
  When set to public, gives access to certain CI/CD features to *Guest* project members.
- [Pipeline visibility](../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects):
  When set to **Everyone with Access**, gives access to certain CI/CD "view" features to *non-project* members.

Project Owners can perform any listed action, and can delete pipelines:

| Action                                                                                                                         | Non-member | Guest | Reporter | Developer | Maintainer | Notes |
|--------------------------------------------------------------------------------------------------------------------------------|:----------:|:-----:|:--------:|:---------:|:----------:|-------|
| See that artifacts exist                                                                                                       |     ✓      |   ✓   |    ✓     |     ✓     |     ✓      | Non-members and guests: Only if the project is public. |
| View a list of jobs                                                                                                            |     ✓      |   ✓   |    ✓     |     ✓     |     ✓      | Non-members: Only if the project is public and **Public pipelines** is enabled in **Project Settings > CI/CD**.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| View and download artifacts                                                                                                    |     ✓      |   ✓   |    ✓     |     ✓     |     ✓      | Non-members: Only if the project is public, **Public pipelines** is enabled in **Project Settings > CI/CD**, and [`artifacts:public: false`](../ci/yaml/index.md#artifactspublic) is not set on the job.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD** and `artifacts:public: false` is not set on the job.<br>Reporters: Only if `artifacts:public: false` is not set on the job. |
| View [environments](../ci/environments/index.md)                                                                               |     ✓      |   ✓   |    ✓     |     ✓     |     ✓      | Non-members and guests: Only if the project is public. |
| View job logs and job details page                                                                                             |     ✓      |   ✓   |    ✓     |     ✓     |     ✓      | Non-members: Only if the project is public and **Public pipelines** is enabled in **Project Settings > CI/CD**.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| View pipelines and pipeline details pages                                                                                      |     ✓      |   ✓   |    ✓     |     ✓     |     ✓      | Non-members: Only if the project is public and **Public pipelines** is enabled in **Project Settings > CI/CD**.<br>Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| View pipelines tab in MR                                                                                                       |     ✓      |   ✓   |    ✓     |     ✓     |     ✓      | Non-members and guests: Only if the project is public. |
| [View vulnerabilities in a pipeline](application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline) |            |   ✓   |    ✓     |     ✓     |     ✓      | Guests: Only if **Public pipelines** is enabled in **Project Settings > CI/CD**. |
| Run deployment job for a protected environment                                                                                 |            |       |    ✓     |     ✓     |     ✓      | Reporters: Only if the user is [part of a group with access to the protected environment](../ci/environments/protected_environments.md#deployment-only-access-to-protected-environments).<br>Developers and maintainers: Only if the user is [allowed to deploy to the protected branch](../ci/environments/protected_environments.md#protecting-environments). |
| View and download project [Secure Files](../api/secure_files.md)                                                               |            |       |          |     ✓     |     ✓      |       |
| Retry jobs                                                                                                                     |            |       |          |     ✓     |     ✓      |       |
| Cancel jobs                                                                                                                    |            |       |          |     ✓     |     ✓      | Cancellation permissions can be [restricted in the pipeline settings](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs). |
| Create new [environments](../ci/environments/index.md)                                                                         |            |       |          |     ✓     |     ✓      |       |
| Enable [review apps](../ci/review_apps/index.md)                                                                                                            |       |          |          | ✓          | ✓     |       |
| Delete job logs or job artifacts                                                                                               |            |       |          |     ✓     |     ✓      | Developers: Only if the job was triggered by the user and runs for a non-protected branch. |
| Run CI/CD pipeline                                                                                                             |            |       |          |     ✓     |     ✓      |       |
| Run CI/CD job                                                                                                                  |            |       |          |     ✓     |     ✓      |       |
| Run CI/CD pipeline for a protected branch                                                                                      |            |       |          |     ✓     |     ✓      | Developers and maintainers: Only if the user is [allowed to merge or push to the protected branch](../ci/pipelines/index.md#pipeline-security-on-protected-branches). |
| Stop [environments](../ci/environments/index.md)                                                                               |            |       |          |     ✓     |     ✓      |       |
| Delete [environments](../ci/environments/index.md)                                                                             |            |       |          |     ✓     |     ✓      |       |
| View a job with [debug logging](../ci/variables/index.md#enable-debug-logging)                                                 |            |       |          |     ✓     |     ✓      |       |
| Use pipeline editor                                                                                                            |            |       |          |     ✓     |     ✓      |       |
| Run [interactive web terminals](../ci/interactive_web_terminal/index.md)                                                       |            |       |          |     ✓     |     ✓      |       |
| Add project runners to project                                                                                                 |            |       |          |           |     ✓      |       |
| Clear runner caches manually                                                                                                   |            |       |          |           |     ✓      |       |
| Enable instance runners in project                                                                                             |            |       |          |           |     ✓      |       |
| Manage CI/CD settings                                                                                                          |            |       |          |           |     ✓      |       |
| Manage job triggers                                                                                                            |            |       |          |           |     ✓      |       |
| Manage project CI/CD variables                                                                                                 |            |       |          |           |     ✓      |       |
| Manage project [Secure Files](../api/secure_files.md)                                                                          |            |       |          |           |     ✓      |       |
| View [agents for Kubernetes](clusters/agent/index.md)                                                                          |            |       | ✓        |     ✓     |     ✓      |       |
| Manage [agents for Kubernetes](clusters/agent/index.md)                                                                        |            |       |          |     ✓     |     ✓      |       |
| Read [Terraform](infrastructure/index.md) state                                                                                |            |       | ✓        |     ✓     |     ✓      |       |
| Manage [Terraform](infrastructure/index.md) state                                                                              |            |       |          |     ✓     |     ✓      |       |

This table shows granted privileges for jobs triggered by specific roles.

Project Owners can do any listed action, but no users can push source and LFS together.
Guest users and members with the Reporter role cannot do any of these actions.

| Action                                       | Developer | Maintainer | Notes |
|----------------------------------------------|:---------:|:----------:|-------|
| Clone source and LFS from current project    |     ✓     |     ✓      |       |
| Clone source and LFS from public projects    |     ✓     |     ✓      |       |
| Clone source and LFS from internal projects  |     ✓     |     ✓      | Developers and Maintainers: Only if the triggering user is not an external user. |
| Clone source and LFS from private projects   |     ✓     |     ✓      | Only if the triggering user is a member of the project. See also [Usage of private Docker images with `if-not-present` pull policy](https://docs.gitlab.com/runner/security/index.html#usage-of-private-docker-images-with-if-not-present-pull-policy). |
| Pull container images from current project   |     ✓     |     ✓      |       |
| Pull container images from public projects   |     ✓     |     ✓      |       |
| Pull container images from internal projects |     ✓     |     ✓      | Developers and Maintainers: Only if the triggering user is not an external user. |
| Pull container images from private projects  |     ✓     |     ✓      | Only if the triggering user is a member of the project. See also [Usage of private Docker images with `if-not-present` pull policy](https://docs.gitlab.com/runner/security/index.html#usage-of-private-docker-images-with-if-not-present-pull-policy). |
| Push container images to current project     |     ✓     |     ✓      | You cannot push container images to other projects. |

### Compliance

Project permissions for [compliance](compliance/index.md) features including compliance center, audit events, compliance frameworks, and licenses.

| Action                                                                                            | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View [allowed and denied licenses in MR](compliance/license_scanning_of_cyclonedx_files/index.md) |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be have at least the Reporter role, even if the project is internal. Users with the Guest role on GitLab.com are able to perform this action only on public projects because internal visibility is not available. |
| View [audit events](../administration/audit_event_reports.md)                                     |       |          |     ✓     |     ✓      |   ✓   | Users can only view events based on their individual actions. |
| View licenses in [dependency list](application_security/dependency_list/index.md)                 |       |          |     ✓     |     ✓      |   ✓   |       |
| Manage [audit streams](compliance/audit_event_streaming.md)                                       |       |          |           |            |   ✓   |       |

### Machine learning model registry and experiment

Project permissions for [model registry](project/ml/model_registry/index.md) and [model experiments](project/ml/experiment_tracking/index.md).

| Action                                                                                            | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View [models and versions](project/ml/model_registry/index.md)                                    |       |     ✓    |     ✓     |     ✓      |   ✓   |       |
| Create, edit, and delete models, versions, and artifacts                                          |       |          |     ✓     |     ✓      |   ✓   |       |
| View [model experiments](project/ml/experiment_tracking/index.md)                                 |       |     ✓    |     ✓     |     ✓      |   ✓   |       |
| Create, edit, and delete experiments, candidates etc                                              |       |          |     ✓     |     ✓      |   ✓   |       |

### Monitoring

Project permissions for monitoring including [error tracking](../operations/error_tracking.md) and [incident management](../operations/incident_management/index.md):

| Action                                                                                                              | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------------------------------------------------------------------------------------|-:-:---|-:-:------|-:-:-------|-:-:--------|-:-:---|-------|
| View [error tracking](../operations/error_tracking.md) list                                                         |       | ✓        | ✓         | ✓          | ✓     |       |
| Manage [error tracking](../operations/error_tracking.md)                                                            |       |          |           | ✓          | ✓     |       |
| Assign an [incident management](../operations/incident_management/index.md) alert                                   | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Participate in on-call rotation [Incident Management](../operations/incident_management/index.md)                   | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View an [incident](../operations/incident_management/incidents.md)                                                  | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Change [alert status](../operations/incident_management/alerts.md#change-an-alerts-status)                          |       | ✓        | ✓         | ✓          | ✓     |       |
| Change [incident severity](../operations/incident_management/manage_incidents.md#change-severity)                   |       | ✓        | ✓         | ✓          | ✓     |       |
| Create [incident](../operations/incident_management/incidents.md)                                                   |       | ✓        | ✓         | ✓          | ✓     |       |
| View [alerts](../operations/incident_management/alerts.md)                                                          |       | ✓        | ✓         | ✓          | ✓     |       |
| View [escalation policies](../operations/incident_management/escalation_policies.md)                                |       | ✓        | ✓         | ✓          | ✓     |       |
| View [on-call schedules](../operations/incident_management/oncall_schedules.md)                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| Change [incident escalation status](../operations/incident_management/manage_incidents.md#change-status)            |       |          | ✓         | ✓          | ✓     |       |
| Change [incident escalation policy](../operations/incident_management/manage_incidents.md#change-escalation-policy) |       |          | ✓         | ✓          | ✓     |       |
| Manage [on-call schedules](../operations/incident_management/oncall_schedules.md)                                   |       |          |           | ✓          | ✓     |       |
| Manage [escalation policies](../operations/incident_management/escalation_policies.md)                              |       |          |           | ✓          | ✓     |       |

### Project planning

Project permissions for [issues](project/issues/index.md):

| Action                                                                | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-----------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View issues                                                           |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Create issues                                                         |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | Authors and assignees can modify the title and description even if they don't have the Reporter role. |
| View [confidential issues](project/issues/confidential_issues.md)     |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Update metadata on issues                                             |       |    ✓     |     ✓     |     ✓      |   ✓   | Metadata includes labels, assignees, milestones, epics, weight, confidentiality, time tracking, and more.<br /><br />Guest users can only set metadata when creating an issue. They cannot change the metadata on existing issues. |
| Close / reopen issues                                                 |       |    ✓     |     ✓     |     ✓      |   ✓   | Authors and assignees can close and reopen issues even if they don't have the Reporter role. |
| Manage [design management](project/issues/design_management.md) files |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Manage [issue boards](project/issue_board.md)                         |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Manage [milestones](project/milestones/index.md)                      |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Delete issues                                                         |       |          |           |            |   ✓   |       |
| Manage [Feature flags](../operations/feature_flags.md)                |       |          | ✓         | ✓          | ✓     |       |
| Archive or reopen [requirements](project/requirements/index.md)       |       | ✓        | ✓         | ✓          | ✓     | Authors and assignees can archive and re-open even if they don't have the Reporter role. |
| Create or edit [requirements](project/requirements/index.md)          |       | ✓        | ✓         | ✓          | ✓     | Authors and assignees can modify the title and description even if they don't have the Reporter role.|
| Import or export [requirements](project/requirements/index.md)        |       | ✓        | ✓         | ✓          | ✓     |       |
| Archive [test cases](../ci/test_cases/index.md)                       |       | ✓        | ✓         | ✓          | ✓     |       |
| Create [test cases](../ci/test_cases/index.md)                        |       | ✓        | ✓         | ✓          | ✓     |       |
| Move [test cases](../ci/test_cases/index.md)                          |       | ✓        | ✓         | ✓          | ✓     |       |
| Reopen [test cases](../ci/test_cases/index.md)                        |       | ✓        | ✓         | ✓          | ✓     |       |

Project permissions for [tasks](tasks.md):

| Action            | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View tasks        |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Create tasks      |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | Guest users can create tasks for issues they authored. Authors and assignees can modify the title and description even if they don't have the Reporter role. |
| Add a linked item |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Edit tasks        |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Remove from issue |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Delete tasks      |       |          |           |            |   ✓   | Authors of tasks can delete them even if they don't have the Owner role. |

Project permissions for [OKRs](okrs.md):

| Action                        | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View OKRs                     |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Create OKRs                   |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Add a child OKR               |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Add a linked item             |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Edit OKRs                     |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Change confidentiality in OKR |       |    ✓     |     ✓     |     ✓      |   ✓   |       |

Project permissions for [wikis](project/wiki/index.md):

| Action                     | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|----------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View wiki                  |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Create and edit wiki pages |       |          |     ✓     |     ✓      |   ✓   |       |
| Delete wiki pages          |       |          |     ✓     |     ✓      |   ✓   |       |

### Packages and registry

Project permissions for [container registry](../user/packages/index.md):

| Action                                    | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Pull an image from the container registry |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | The ability to view the container registry and pull images is controlled by the [container registry's visibility permissions](packages/container_registry/index.md#container-registry-visibility-permissions). |
| Push an image to the container registry   |       |          |     ✓     |     ✓      |   ✓   |       |
| Delete a container registry image         |       |          |     ✓     |     ✓      |   ✓   |       |
| Manage cleanup policies                   |       |          |           |     ✓      |   ✓   |       |

Project permissions for [package registry](../user/packages/index.md):

| Action                                  | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-----------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Pull a package                          |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| Publish a package                       |       |          |     ✓     |     ✓      |   ✓   |       |
| Delete a package                        |       |          |           |     ✓      |   ✓   |       |
| Delete a file associated with a package |       |          |           |     ✓      |   ✓   |       |

### Projects

Project permissions for [project features](project/organize_work_with_projects.md):

| Action                                                                    | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Download project                                                          |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| Leave comments                                                            |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| View [releases](project/releases/index.md)                                |       |          |     ✓     |     ✓      |   ✓   | Guest users can access GitLab [**Releases**](project/releases/index.md) for downloading assets but are not allowed to download the source code nor see [repository information like commits and release evidence](project/releases/index.md#view-a-release-and-download-assets). |
| Manage [releases](project/releases/index.md)                              |       |          |           |     ✓      |   ✓   | If the [tag is protected](project/protected_tags.md), this depends on the access given to Developers and Maintainers. |
| Configure [webhooks](project/integrations/webhooks.md)                    |       |          |           |     ✓      |   ✓   |       |
| Manage [project access tokens](project/settings/project_access_tokens.md) |       |          |           |     ✓      |   ✓   | For self-managed GitLab, project access tokens are available in all tiers. For GitLab.com, project access tokens are supported in the Premium and Ultimate tier (excluding [trial licenses](https://about.gitlab.com/free-trial/)). |
| [Export project](project/settings/import_export.md)                       |       |          |           |     ✓      |   ✓   |       |
| Rename project                                                            |       |          |           |     ✓      |   ✓   |       |
| Edit project badges                                                       |       |          |           |     ✓      |   ✓   |       |
| Edit project settings                                                     |       |          |           |     ✓      |   ✓   |       |
| Change [project features visibility](public_access.md) level              |       |          |           |     ✓      |   ✓   | A Maintainer or Owner can't change project features visibility level if [project visibility](public_access.md) is set to private. |
| Edit comments (posted by any user)                                        |       |          |           |     ✓      |   ✓   |       |
| Archive project                                                           |       |          |           |            |   ✓   |       |
| Change project visibility level                                           |       |          |           |            |   ✓   |       |
| Delete project                                                            |       |          |           |            |   ✓   |       |
| Disable notification emails                                               |       |          |           |            |   ✓   |       |
| Transfer project                                                          |       |          |           |            |   ✓   |       |
| Reposition comments on images (posted by any user)                        | ✓     | ✓        | ✓         | ✓          | ✓     | Applies only to comments on [Design Management](project/issues/design_management.md) designs. |
| View [Insights](project/insights/index.md)                                | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [Requirements](project/requirements/index.md)                        | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [time tracking](project/time_tracking.md) reports                                                                                                      | ✓     | ✓        | ✓         | ✓          | ✓     | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| View [project traffic statistics](../api/project_statistics.md)                                                                                             |       | ✓        | ✓         | ✓          | ✓     |       |
| Add [deploy keys](project/deploy_keys/index.md)                                                                                                             |       |          |           | ✓          | ✓     |       |
| Manage [Project Operations](../operations/index.md)                                                                                                         |       |          |           | ✓          | ✓     |       |
| View [Usage Quotas](usage_quotas.md) page                                                                                                                   |       |          |           | ✓          | ✓     |       |
| View [snippets](snippets.md)                                                                                                                                | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Create [snippets](snippets.md)                                                                                                                              |       | ✓        | ✓         | ✓          | ✓     |       |
| Globally delete [snippets](snippets.md)                                                                                                                     |       |          |           |  ✓         | ✓     |       |
| Globally edit [snippets](snippets.md)                                                                                                                       |       |          |           |  ✓         | ✓     |       |

Project permissions for [GitLab Pages](project/pages/index.md):

| Action                                                                    | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View GitLab Pages protected by [access control](project/pages/pages_access_control.md)        | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Manage GitLab Pages                                                       |       |          |           | ✓          | ✓     |       |
| Manage GitLab Pages domain and certificates                               |       |          |           | ✓          | ✓     |       |
| Remove GitLab Pages                                                       |       |          |           | ✓          | ✓     |       |

### Repository

Project permissions for [repository](project/repository/index.md) features including source code, branches, push rules, and more:

| Action                                                         | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|----------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View project code                                              |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. In GitLab 15.9 and later, users with the Guest role and an Ultimate license can view private repository content if an administrator (on self-managed or GitLab Dedicated) or group owner (on GitLab.com) gives those users permission. The administrator or group owner can create a [custom role](custom_roles.md) through the API or UI and assign that role to the users. |
| Pull project code                                              |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| View a commit status                                           |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Create or update commit status                                 |       |          |     ✓     |     ✓      |   ✓   | If the [branch is protected](project/repository/branches/protected.md), this depends on the access given to Developers and Maintainers. |
| Create and delete [Git tags](project/repository/tags/index.md) |       |          |     ✓     |     ✓      |   ✓   |       |
| Create new [branches](project/repository/branches/index.md)    |       |          |     ✓     |     ✓      |   ✓   |       |
| Force push to non-protected branches                           |       |          |     ✓     |     ✓      |   ✓   |       |
| Push to non-protected branches                                 |       |          |     ✓     |     ✓      |   ✓   |       |
| Delete non-protected branches                                  |       |          |     ✓     |     ✓      |   ✓   |       |
| Manage [protected branches](project/repository/branches/protected.md)     |       |          |           |     ✓      |   ✓   |       |
| Delete protected branches                                      |       |          |           |     ✓      |   ✓   |       |
| Manage [protected tags](project/protected_tags.md)             |       |          |           |     ✓      |   ✓   |       |
| Manage [push rules](project/repository/push_rules.md)          |       |          |           |     ✓      |   ✓   |       |
| Push to protected branches                                     |       |          |           |     ✓      |   ✓   | If the [branch is protected](project/repository/branches/protected.md), this depends on the access given to Developers and Maintainers. |
| Remove fork relationship                                       |       |          |           |            |   ✓   |       |
| Force push to protected branches                               |       |          |           |            |       | Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [protected branches](project/repository/branches/protected.md#allow-force-push-on-a-protected-branch). |

Project permissions for [merge requests](project/merge_requests/index.md):

| Action                                                                                                       | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|--------------------------------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| [View](project/merge_requests/index.md#view-merge-requests) a merge request                                  |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | On self-managed GitLab instances, users with the Guest role are able to perform this action only on public and internal projects (not on private projects). [External users](../administration/external_users.md) must be given explicit access (at least the **Reporter** role) even if the project is internal. Users with the Guest role on GitLab.com are only able to perform this action on public projects because internal visibility is not available. |
| [Create](project/merge_requests/creating_merge_requests.md) a merge request                                  |       |          |     ✓     |     ✓      |   ✓   | In projects that accept contributions from external members, users can create, edit, and close their own merge requests. For **private** projects, this excludes the Guest role as those users [cannot clone private projects](public_access.md#private-projects-and-groups). For **internal** projects, includes users with read-only access to the project, as [they can clone internal projects](public_access.md#internal-projects-and-groups). |
| Update a merge request including assign, review, Code Suggestions, approve, labels, lock and resolve threads |       |          |     ✓     |     ✓      |   ✓   | For information on eligible approvers for merge requests, see [Eligible approvers](project/merge_requests/approvals/rules.md#eligible-approvers). |
| Manage [merge request settings](project/merge_requests/approvals/settings.md)                                |       |          |           |     ✓      |   ✓   |       |
| Manage [merge request approval rules](project/merge_requests/approvals/rules.md)                             |       |          |           |     ✓      |   ✓   |       |
| Delete merge request                                                                                         |       |          |           |            |   ✓   |       |
| Create [snippets](snippets.md)                                                                               |       | ✓        | ✓         | ✓          | ✓     |       |

### User management

Project permissions for [user management](project/members/index.md).

| Action                                          | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Manage [team members](project/members/index.md) |       |          |           |     ✓      |   ✓   | Maintainers cannot create, demote, or remove Owners, and they cannot promote users to the Owner role. They also cannot approve Owner role access requests. |
| Share (invite) projects with groups             |       |          |           |     ✓      |   ✓   | When [Share Group Lock](project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups) is enabled the project can't be shared with other groups. It does not affect group with group sharing. |
| View 2FA status of members                      |       |          |           |     ✓      |   ✓   |       |

### GitLab Duo

Project permissions for [GitLab Duo](gitlab_duo/index.md):

| Action                                                                                                      | Non-member | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------------------------------------------------------------------------------------------------|------------|-------|----------|-----------|------------|-------|-------|
| <br>Configure [Duo feature availability](gitlab_duo/turn_on_off.md#turn-off-for-a-project)                        |            |       |          |           | ✓           | ✓     |      |
| <br>Use Duo features                                                                                        |            | ✓     | ✓        | ✓         | ✓          | ✓     | Code Suggestions requires a [user being assigned a seat to gain access to a Duo add-on](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).     |

## Group members permissions

Any user can remove themselves from a group, unless they are the only Owner of
the group.

The following table lists group permissions available for each role:

### Analytics group permissions

Group permission for [analytics](../user/analytics/index.md) features including value streams, product analytics, and insights:

| Action                                | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View [Insights](project/insights/index.md)                                              | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [Insights](project/insights/index.md) charts                                       | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [Issue analytics](group/issues_analytics/index.md)                                 | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View Contribution analytics                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View value stream analytics                                                             | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| View [Productivity analytics](analytics/productivity_analytics.md)                      |       | ✓        | ✓         | ✓          | ✓     |       |
| View [Group DevOps Adoption](group/devops_adoption/index.md)                            |       | ✓        | ✓         | ✓          | ✓     |       |
| View metrics dashboard annotations                                                      |       | ✓        | ✓         | ✓          | ✓     |       |
| Create/edit/delete metrics dashboard annotations                                        |       |          | ✓         | ✓          | ✓     |       |

### Application security group permissions

Group permissions for [Application Security](application_security/secure_your_application.md) features including dependency management, security analyzers, security policies, and vulnerability management.

| Action                                                                             | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View [dependency list](application_security/dependency_list/index.md)              |       |          |     ✓     |     ✓      |   ✓   |       |
| View [vulnerability report](application_security/vulnerability_report/index.md)    |       |          |     ✓     |     ✓      |   ✓   |       |
| View [security dashboard](application_security/security_dashboard/index.md)        |       |          |     ✓     |     ✓      |   ✓   |       |
| Create or assign [security policy project](application_security/policies/index.md) |       |          |           |            |   ✓   |       |

### CI/CD group permissions

Group permissions for [CI/CD](../ci/index.md) features including runners, variables, and protected environments:

| Action                                | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Manage group-level Kubernetes cluster |       |          |           |     ✓      |   ✓   |       |
| View group runners                    |       |          |           |     ✓      |   ✓   |       |
| Manage group runners                  |       |          |           |            |   ✓   |       |
| Manage group level CI/CD variables    |       |          |           |            |   ✓   |       |
| Manage group protected environments   |       |          |           |            |   ✓   |       |

### Compliance group permissions

Group permissions for [compliance](compliance/index.md) features including compliance center, audit events, compliance frameworks, and licenses.

| Action                                                                                | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View [audit events](../administration/audit_event_reports.md)                         |       |          |     ✓     |     ✓      |   ✓   | Users can view only events based on their individual actions. |
| View licenses in the [dependency list](application_security/dependency_list/index.md) |       |          |     ✓     |     ✓      |   ✓   |       |
| Manage [audit streams](compliance/audit_event_streaming.md)                           |       |          |           |            |   ✓   |       |
| View the [compliance center](compliance/compliance_center/index.md)                   |       |          |           |            |   ✓   |       |
| Manage [compliance frameworks](group/compliance_frameworks.md)                        |       |          |           |            |   ✓   |       |
| Assign [compliance frameworks](group/compliance_frameworks.md) to projects            |       |          |           |            |   ✓   |       |

### GitLab Duo group permissions

Group permissions for [GitLab Duo](../user/gitlab_duo/index.md):

| Action                                                                                                      | Non-member | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------------------------------------------------------------------------------------------------|------------|-------|----------|-----------|------------|-------|-------|
| <br>Purchase [Duo seats](../subscriptions/subscription-add-ons.md#purchase-additional-gitlab-duo-seats) |            |       |          |           |            | ✓     |       |
| <br>Configure [Duo feature availability](gitlab_duo/turn_on_off.md#turn-off-for-a-group)                          |            |       |          |           | ✓         | ✓     |       |
| <br>Configure [self-hosted models](../administration/self_hosted_models/configure_duo_features.md)          |            |       |          |           |            | ✓     |       |
| <br>Enable [beta and experimental features](gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)   |            |       |          |           |            | ✓     |       |
| <br>Use Duo features                                                                                        |            |       | ✓        | ✓         | ✓          | ✓     | Requires [user being assigned a seat to gain access to a Duo add-on](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).     |

### Groups group permissions

Group permissions for [group features](../user/group/index.md):

| Action                                                                                     | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|--------------------------------------------------------------------------------------------|-------|----------|-----------|------------|-------|-------|
| Browse group                                                                               | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Create project in group                                                                    |       |          | ✓         | ✓          | ✓     | Developers, Maintainers and Owners: Only if the project creation role is set at the [instance level](../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects) or the [group level](group/index.md#specify-who-can-add-projects-to-a-group).<br><br>Developers: Developers can push commits to the default branch of a new project only if the [default branch protection](group/manage.md#change-the-default-branch-protection-of-a-group) is set to "Partially protected" or "Not protected". |
| Create subgroup                                                                            |       |          |           | ✓          | ✓     | Maintainers: Only if users with the Maintainer role [can create subgroups](group/subgroups/index.md#change-who-can-create-subgroups). |
| Edit [epic](group/epics/index.md) comments (posted by any user)                            |       |          |           | ✓          | ✓     |       |
| Fork project into a group                                                                  |       |          |           | ✓          | ✓     |       |
| View [Billing](../subscriptions/gitlab_com/index.md#view-your-gitlabcom-subscription)      |       |          |           |            | ✓     | Does not apply to subgroups |
| View group [Usage Quotas](usage_quotas.md) page                                            |       |          |           |            | ✓     | Does not apply to subgroups |
| Manage [subscriptions, storage, and compute minutes](../subscriptions/gitlab_com/index.md) |       |          |           |            | ✓     |       |
| Edit group settings                                                                        |       |          |           |            | ✓     |       |
| Disable notification emails                                                                |       |          |           |            | ✓     |       |
| Configure project templates                                                                |       |          |           |            | ✓     |       |
| Change group visibility level                                                              |       |          |           |            | ✓     |       |
| Manage [group access tokens](group/settings/group_access_tokens.md)                        |       |          |           |            | ✓     |       |
| Configure [SAML SSO](group/saml_sso/index.md)                                              |       |          |           |            | ✓     | Does not apply to subgroups |
| [Migrate groups](group/import/index.md)                                                    |       |          |           |            | ✓     |       |
| Delete group                                                                               |       |          |           |            | ✓     |       |
| View group audit events                                                                    |       |          | ✓         | ✓          | ✓     | Developers and Maintainers can only view events based on their individual actions. |

### Project planning group permissions

Group permissions for project planning features including iterations, milestones, and labels:

| Action                  | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Manage group labels     |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Manage group milestones |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Manage iterations       |       |    ✓     |     ✓     |     ✓      |   ✓   |       |

Group permisisons for [epics](group/epics/index.md):

| Action                                                                        | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|:------------------------------------------------------------------------------|:------|:---------|:----------|:-----------|:------|:------|
| View epic                                                                     | ✓     | ✓        | ✓         | ✓          | ✓     |       |
| Add an issue to an [epic](group/epics/index.md)                               | ✓     | ✓        | ✓         | ✓          | ✓     | You must have permission to [view the epic](group/epics/manage_epics.md#who-can-view-an-epic) and edit the issue. |
| Add/remove [child epics](group/epics/manage_epics.md#multi-level-child-epics) | ✓     | ✓        | ✓         | ✓          | ✓     | You must have permission to [view](group/epics/manage_epics.md#who-can-view-an-epic) the parent and child epics. |
| Create epic                                                                   |       | ✓        | ✓         | ✓          | ✓     |       |
| Edit epic                                                                     |       | ✓        | ✓         | ✓          | ✓     |       |
| Manage [epic boards](group/epics/epic_boards.md)                              |       | ✓        | ✓         | ✓          | ✓     |       |
| Delete epic                                                                   |       |          |           |            | ✓     |       |

Group permissions for [wikis](project/wiki/group.md):

| Action                           | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|----------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| View group wiki                  |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | Guests: In addition, if your group is public or internal, all users who can see the group can also see group wiki pages. |
| Create and edit group wiki pages |       |          |     ✓     |     ✓      |   ✓   |       |
| Delete group wiki pages          |       |          |     ✓     |     ✓      |   ✓   |       |

### Packages and registries group permissions

Group permissions for [container registry](../user/packages/index.md):

| Action                                            | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|---------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Pull a container registry image                   |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   | Guests can only view events based on their individual actions. |
| Pull a container image using the dependency proxy |   ✓   |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Delete a container registry image                 |       |          |     ✓     |     ✓      |   ✓   |       |

Group permissions for [package registry](../user/packages/index.md):

| Action                                    | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Pull packages                             |       |    ✓     |     ✓     |     ✓      |   ✓   |       |
| Publish packages                          |       |          |     ✓     |     ✓      |   ✓   |       |
| Delete packages                           |       |          |           |     ✓      |   ✓   |       |
| Manage package settings                   |       |          |           |            |   ✓   |       |
| Manage dependency proxy cleanup policies  |       |          |           |            |   ✓   |       |
| Purge the dependency proxy for a group    |       |          |           |            |   ✓   |       |
| Enable/disable a dependency proxy         |       |          |           |            |   ✓   |       |
| Enable/disable package request forwarding |       |          |           |            |   ✓   |       |

### Repository group permissions

Group permissions for [repository](project/repository/index.md) features including merge requests, push rules, and deploy tokens.

| Action                                                                                 | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|----------------------------------------------------------------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Manage [merge request settings](group/manage.md#group-merge-request-approval-settings) |       |          |           |            |   ✓   |       |
| Manage [push rules](group/access_and_permissions.md#group-push-rules)                  |       |          |           |            |   ✓   |       |
| Manage [deploy tokens](project/deploy_tokens/index.md)                                 |       |          |           |            |   ✓   |       |

### User management group permissions

Group permissions for user management:

| Action                            | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-----------------------------------|:-----:|:--------:|:---------:|:----------:|:-----:|-------|
| Manage group members              |       |          |           |            |   ✓   |       |
| View 2FA status of members        |       |          |           |            |   ✓   |       |
| Filter members by 2FA status      |       |          |           |            |   ✓   |       |
| Share (invite) groups with groups |       |          |           |            |   ✓   |       |
| Manage group-level custom roles   |       |          |           |            |   ✓   |       |

### Workspace group permissions

Groups permissions for workspaces:

| Action                                                                                  | Guest | Reporter | Developer | Maintainer | Owner | Notes |
|-----------------------------------------------------------------------------------------|-------|----------|-----------|------------|-------|-------|
| Map or unmap workspace cluster agents to and from a group                               |       |          |           |            | ✓     |       |
| View workspace cluster agents mapped to a group                                         |       |          |           | ✓          | ✓     |       |

## Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent groups. This model allows access to
nested groups if you have membership in one of its parents.

For more information, see
[subgroup memberships](group/subgroups/index.md#subgroup-membership).

## Users with Minimal Access

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Support for inviting users with Minimal Access role [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106438) in GitLab 15.9.

Users with the Minimal Access role do not:

- Automatically have access to projects and subgroups in that root group.
- Count as licensed seats on self-managed Ultimate subscriptions or any GitLab.com subscriptions, provided the user has no other role anywhere in the instance or in the GitLab.com namespace.

Owners must explicitly add these users to the specific subgroups and
projects.

You can use the Minimal Access role with [SAML SSO for GitLab.com groups](group/saml_sso/index.md)
to control access to groups and projects in the group hierarchy. You can set the default role to
Minimal Access for members automatically added to the root group through SSO.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. From the **Default membership role** dropdown list, select **Minimal Access**.
1. Select **Save changes**.

### Minimal access users receive 404 errors

Because of an [outstanding issue](https://gitlab.com/gitlab-org/gitlab/-/issues/267996), when a user with the Minimal Access role:

- Signs in with standard web authentication, they receive a `404` error when accessing the parent group.
- Signs in with Group SSO, they receive a `404` error immediately because they are redirected to the parent group page.

To work around the issue, give these users the Guest role or higher to any project or subgroup in the parent group. Guest users consume a license seat in the Premium tier but do not in the Ultimate tier.

## Related topics

- [Custom roles](custom_roles.md)
- [The GitLab principles behind permissions](https://handbook.gitlab.com/handbook/product/gitlab-the-product/#permissions-in-gitlab)
- [Members](project/members/index.md)
- Customize permissions on [protected branches](project/repository/branches/protected.md)
- [LDAP user permissions](group/access_and_permissions.md#manage-group-memberships-via-ldap)
- [Value stream analytics permissions](group/value_stream_analytics/index.md#access-permissions-for-value-stream-analytics)
- [Project aliases](../user/project/working_with_projects.md#project-aliases)
- [Auditor users](../administration/auditor_users.md)
- [Confidential issues](project/issues/confidential_issues.md)
- [Container registry permissions](packages/container_registry/index.md#container-registry-visibility-permissions)
- [Release permissions](project/releases/index.md#release-permissions)
- [Read-only namespaces](../user/read_only_namespaces.md)
