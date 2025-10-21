---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Roles and permissions
description: Understand the permissions and capabilities available to each user role in GitLab.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Roles define a user's permissions in a group or project.

Users with [administrator access](../administration/_index.md) have all permissions and can
perform any action.

## Roles

{{< history >}}

- Planner role [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/482733) in GitLab 17.7.

{{< /history >}}

When you add a user to a group or project, you assign them a role.
The role determines their permissions. Assign either a [default role](#default-roles)
or a [custom role](custom_roles/_index.md).

A user can have different roles for each group and project. Users always retain the
permissions for their highest role. For example, if a user has:

- The Maintainer role for a parent group
- The Developer role for a project in that group

The user inherits the permissions for their Maintainer role in the project.

To view assigned roles, go to the **Members** page for a
[group](group/_index.md#view-group-members) or
[project](project/members/_index.md#view-project-members).

### Default roles

The following default roles are available:

| Role           | Description |
| -------------- | ----------- |
| Minimal Access | View limited group information without access to projects. For more information, see [Users with Minimal Access](#users-with-minimal-access). |
| Guest          | View and comment on issues and epics. Cannot push code or access repository. This role applies to [private and internal projects](public_access.md) only. |
| Planner        | Create and manage issues, epics, milestones, and iterations. Focused on project planning and tracking without code access. |
| Reporter       | View code, create issues, and generate reports. Cannot push code or manage protected branches. |
| Developer      | Push code to non-protected branches, create merge requests, and run CI/CD pipelines. Cannot manage project settings. |
| Maintainer     | Manage branches, merge requests, CI/CD settings, and project members. Cannot delete the project. |
| Owner          | Full control over the project or group, including deletion and visibility settings. |

By default, all users can create top-level groups and change their usernames.
Users with [administrator access](../administration/user_settings.md) can change this behavior.

<!--
Sort these permissions according the following rules in order:
1. By minimum role.
2. By the object being accessed (for example, issue, security dashboard, or pipeline)
3. By the action: view, create, change, edit, manage, run, delete, all others
4. Alphabetically.

List only one action (for example, view, create, or delete) per line.
It's okay to list multiple related objects per line (for example, "View pipelines and pipeline details").
-->

## Group members permissions

Any user can remove themselves from a group, unless they are the only Owner of
the group.

The following table lists group permissions available for each role:

### Analytics group permissions

Group permission for [analytics](analytics/_index.md) features including value streams, product analytics, and insights:

| Action                                                             | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View [insights](project/insights/_index.md)                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [insights](project/insights/_index.md) charts                 |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [issue analytics](group/issues_analytics/_index.md)           |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View contribution analytics                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View value stream analytics                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [productivity analytics](analytics/productivity_analytics.md) |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [group DevOps adoption](group/devops_adoption/_index.md)      |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View metrics dashboard annotations                                 |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Manage metrics dashboard annotations                               |       |         |          |     ✓     |     ✓      |   ✓   |

### Application security group permissions

Group permissions for [Application Security](application_security/secure_your_application.md) features including dependency management, security analyzers, security policies, and vulnerability management.

| Action                                                                           | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| -------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View [dependency list](application_security/dependency_list/_index.md)           |       |         |          |     ✓     |     ✓      |   ✓   |
| View [vulnerability report](application_security/vulnerability_report/_index.md) |       |         |          |     ✓     |     ✓      |   ✓   |
| View [security dashboard](application_security/security_dashboard/_index.md)     |       |         |          |     ✓     |     ✓      |   ✓   |
| Create [security policy project](application_security/policies/_index.md)        |       |         |          |           |            |   ✓   |
| Assign [security policy project](application_security/policies/_index.md)        |       |         |          |           |            |   ✓   |

### CI/CD group permissions

Group permissions for [CI/CD](../ci/_index.md) features including runners, variables, and protected environments:

| Action                                | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View instance runner                  |   ✓   |    ✓    |     ✓    |    ✓      |     ✓      |   ✓   |
| View group runners                    |       |         |          |           |     ✓      |   ✓   |
| Manage group-level Kubernetes cluster |       |         |          |           |     ✓      |   ✓   |
| Manage group runners                  |       |         |          |           |            |   ✓   |
| Manage group level CI/CD variables    |       |         |          |           |            |   ✓   |
| Manage group protected environments   |       |         |          |           |            |   ✓   |

### Compliance group permissions

Group permissions for [compliance](compliance/_index.md) features including compliance center, audit events, compliance frameworks, and licenses.

| Action                                                                                 | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View [audit events](compliance/audit_events.md) <sup>1</sup>                           |       |         |          |     ✓     |     ✓      |   ✓   |
| View licenses in [dependency list](application_security/dependency_list/_index.md)     |       |         |          |     ✓     |     ✓      |   ✓   |
| View [compliance center](compliance/compliance_center/_index.md)                       |       |         |          |           |            |   ✓   |
| Manage [compliance frameworks](compliance/compliance_frameworks/_index.md)             |       |         |          |           |            |   ✓   |
| Assign [compliance frameworks](compliance/compliance_frameworks/_index.md) to projects |       |         |          |           |            |   ✓   |
| Manage [audit streams](compliance/audit_event_streaming.md)                            |       |         |          |           |            |   ✓   |

**Footnotes**

1. Users can view events based on their individual actions only. For more details, see the [prerequisites](compliance/audit_events.md#prerequisites).

### GitLab Duo group permissions

Group permissions for [GitLab Duo](gitlab_duo/_index.md):

| Action                                                                                                     | Non-member | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ---------------------------------------------------------------------------------------------------------- | :--------: | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Use GitLab Duo features <sup>1</sup>                                                                       |            |       |     ✓   |    ✓     |     ✓     |     ✓      |   ✓   |
| Configure [GitLab Duo feature availability](gitlab_duo/turn_on_off.md#for-a-group-or-subgroup)             |            |       |         |          |           |     ✓      |   ✓   |
| Configure [GitLab Duo Self Hosted](../administration/gitlab_duo_self_hosted/configure_duo_features.md)     |            |       |         |          |           |            |   ✓   |
| Enable [beta and experimental features](gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)  |            |       |         |          |           |            |   ✓   |
| Purchase [GitLab Duo seats](../subscriptions/subscription-add-ons.md#purchase-additional-gitlab-duo-seats) |            |       |         |          |           |            |   ✓   |

**Footnotes**

1. If the user has GitLab Duo Pro or Enterprise, the
   [user must be assigned a seat to gain access to that GitLab Duo add-on](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
   If the user has GitLab Duo Core, there are no other requirements.

### Groups group permissions

Group permissions for [group features](group/_index.md):

| Action                                                                                      | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Browse group                                                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) projects in group                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View group [audit events](compliance/audit_events.md) <sup>1</sup>                          |       |         |          |     ✓     |     ✓      |   ✓   |
| Create project in group <sup>2</sup>                                                        |       |         |          |     ✓     |     ✓      |   ✓   |
| Create subgroup <sup>3</sup>                                                                |       |         |          |           |     ✓      |   ✓   |
| Change custom settings for [project integrations](project/integrations/_index.md)           |       |         |          |           |            |   ✓   |
| Edit [epic](group/epics/_index.md) comments (posted by any user)                            |       |    ✓    |          |           |     ✓      |   ✓   |
| Fork project into a group                                                                   |       |         |          |           |     ✓      |   ✓   |
| View [Billing](../subscriptions/manage_subscription.md#view-subscription) <sup>4</sup>      |       |         |          |           |            |   ✓   |
| View group [Usage quotas](storage_usage_quotas.md) page <sup>4</sup>                        |       |         |          |           |            |   ✓   |
| [Migrate group](group/import/_index.md)                                                     |       |         |          |           |            |   ✓   |
| Archive group                                                                               |       |         |          |           |            |   ✓   |
| Delete group                                                                                |       |         |          |           |            |   ✓   |
| Transfer group                                                                              |       |         |          |           |            |   ✓   |
| Manage [subscriptions, storage, and compute minutes](../subscriptions/gitlab_com/_index.md) |       |         |          |           |            |   ✓   |
| Manage [group access tokens](group/settings/group_access_tokens.md)                         |       |         |          |           |            |   ✓   |
| Change group visibility level                                                               |       |         |          |           |            |   ✓   |
| Edit group settings                                                                         |       |         |          |           |            |   ✓   |
| Configure project templates                                                                 |       |         |          |           |            |   ✓   |
| Configure [SAML SSO](group/saml_sso/_index.md) <sup>4</sup>                                 |       |         |          |           |            |   ✓   |
| Disable notification emails                                                                 |       |         |          |           |            |   ✓   |
| Import [project](project/settings/import_export.md)                                         |       |         |          |           |     ✓      |   ✓   |

**Footnotes**

1. Developers and Maintainers can view events based on their individual actions only. For more
   information, see the [prerequisites](compliance/audit_events.md#prerequisites).
1. Developers, Maintainers and Owners: Only if the project creation role is set
   [for the instance](../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects)
    or [for the group](group/_index.md#specify-who-can-add-projects-to-a-group).
   <br>Developers: Developers can push commits to the default branch of a new project only
   if the [default branch protection](group/manage.md#change-the-default-branch-protection-of-a-group)
   is set to "Partially protected" or "Not protected".
1. Maintainers: Only if users with the Maintainer role [can create subgroups](group/subgroups/_index.md#change-who-can-create-subgroups).
1. Does not apply to subgroups.

### Project planning group permissions

| Action                                                                              | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ----------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View epic                                                                           |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) epics <sup>1</sup>                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add issues to an [epic](group/epics/_index.md) <sup>2</sup>                         |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add [child epics](group/epics/manage_epics.md#multi-level-child-epics) <sup>3</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add internal notes                                                                  |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create epics                                                                        |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Update epic details                                                                 |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Manage [epic boards](group/epics/epic_boards.md)                                    |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Delete epics                                                                        |       |    ✓    |          |           |            |   ✓   |

**Footnotes**

1. You must have permission to [view the epic](group/epics/manage_epics.md#who-can-view-an-epic).
1. You must have permission to [view the epic](group/epics/manage_epics.md#who-can-view-an-epic) and edit the issue.
1. You must have permission to [view](group/epics/manage_epics.md#who-can-view-an-epic) the parent and child epics.

Group permissions for [wikis](project/wiki/group.md):

| Action                                              | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| --------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View group wiki <sup>1</sup>                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) group wikis <sup>2</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create group wiki pages                             |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| Edit group wiki pages                               |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| Delete group wiki pages                             |       |    ✓    |          |     ✓     |     ✓      |   ✓   |

**Footnotes**

1. Guests: In addition, if your group is public or internal, all users who can see the group can also see group wiki pages.
1. Guests: In addition, if your group is public or internal, all users who can see the group can also search group wiki pages.

### Packages and registries group permissions

Group permissions for the [package and container registry](packages/_index.md):

| Action                                          | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ----------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Pull container registry images <sup>1</sup>     |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Pull container images with the dependency proxy |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Delete container registry images                |       |         |          |     ✓     |     ✓      |   ✓   |
| Configure a virtual registry                    |       |         |          |           |     ✓      |   ✓   |
| Pull an artifact from a virtual registry        |   ✓   |         |    ✓     |     ✓     |     ✓      |   ✓   |

**Footnotes**

1. Guests can only view events based on their individual actions.

Group permissions for [package registry](packages/_index.md):

| Action                                   | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ---------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Pull packages                            |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Publish packages                         |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete packages                          |       |         |          |           |     ✓      |   ✓   |
| Manage package settings                  |       |         |          |           |            |   ✓   |
| Manage dependency proxy cleanup policies |       |         |          |           |            |   ✓   |
| Enable dependency proxy                  |       |         |          |           |            |   ✓   |
| Disable dependency proxy                 |       |         |          |           |            |   ✓   |
| Purge the group dependency proxy         |       |         |          |           |            |   ✓   |
| Enable package request forwarding        |       |         |          |           |            |   ✓   |
| Disable package request forwarding       |       |         |          |           |            |   ✓   |

### Repository group permissions

Group permissions for [repository](project/repository/_index.md) features including merge requests, push rules, and deploy tokens.

| Action                                                                                 | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Manage [deploy tokens](project/deploy_tokens/_index.md)                                |       |         |          |           |            |   ✓   |
| Manage [merge request settings](group/manage.md#group-merge-request-approval-settings) |       |         |          |           |            |   ✓   |
| Manage [push rules](group/access_and_permissions.md#group-push-rules)                  |       |         |          |           |            |   ✓   |

### User management group permissions

Group permissions for user management:

| Action                          | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View 2FA status of members      |       |         |          |           |            |   ✓   |
| Filter members by 2FA status    |       |         |          |           |            |   ✓   |
| Manage group members            |       |         |          |           |            |   ✓   |
| Manage group-level custom roles |       |         |          |           |            |   ✓   |
| Share (invite) groups to groups |       |         |          |           |            |   ✓   |

### Workspace group permissions

Groups permissions for workspaces:

| Action                                                    | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| --------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View workspace cluster agents mapped to a group           |       |         |          |           |     ✓      |   ✓   |
| Map or unmap workspace cluster agents to and from a group |       |         |          |           |            |   ✓   |

## Project members permissions

A user's role determines what permissions they have on a project. The Owner role provides all permissions but is
available only:

- For group and project Owners.
- For Administrators.

Personal [namespace](namespace/_index.md) owners:

- Are displayed as having the Maintainer role on projects in the namespace, but have the same permissions as a user with the Owner role.
- For new projects in the namespace, are displayed as having the Owner role.

When you configure [protected branch settings](project/repository/branches/protection_rules.md),
selecting a role grants access to users with that role and all higher roles. For example, if you select
**Maintainers** in the protected branch settings, users with both the Maintainer and Owner roles
can perform the action.

For more information about how to manage project members, see
[members of a project](project/members/_index.md).

The following tables list the project permissions available for each role.

### Analytics

Project permissions for [analytics](analytics/_index.md) features including value streams, usage trends, product analytics, and insights.

| Action                                                                                     | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View [issue analytics](group/issues_analytics/_index.md)                                   |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [value stream analytics](group/value_stream_analytics/_index.md)                      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [CI/CD analytics](analytics/ci_cd_analytics.md)                                       |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [code review analytics](analytics/code_review_analytics.md)                           |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [DORA metrics](analytics/ci_cd_analytics.md)                                          |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [merge request analytics](analytics/merge_request_analytics.md)                       |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [repository analytics](analytics/repository_analytics.md)                             |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [Value Streams Dashboard](analytics/value_streams_dashboard.md)                       |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [GitLab Duo and SDLC trends](analytics/duo_and_sdlc_trends.md)                        |       |         |    ✓     |     ✓     |     ✓      |   ✓   |

### Application security

Project permissions for [application security](application_security/secure_your_application.md) features including dependency management, security analyzers, security policies, and vulnerability management.

| Action                                                                                                                              | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ----------------------------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View [dependency list](application_security/dependency_list/_index.md)                                                              |       |         |          |     ✓     |     ✓      |   ✓   |
| View licenses in [dependency list](application_security/dependency_list/_index.md)                                                  |       |         |          |     ✓     |     ✓      |   ✓   |
| View [security dashboard](application_security/security_dashboard/_index.md)                                                        |       |         |          |     ✓     |     ✓      |   ✓   |
| View [vulnerability report](application_security/vulnerability_report/_index.md)                                                    |       |         |          |     ✓     |     ✓      |   ✓   |
| Create [vulnerability manually](application_security/vulnerability_report/_index.md#manually-add-a-vulnerability)                   |       |         |          |           |     ✓      |   ✓   |
| Create [issue](application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability) from vulnerability finding |       |         |          |     ✓     |     ✓      |   ✓   |
| Create [on-demand DAST scans](application_security/dast/on-demand_scan.md)                                                          |       |         |          |     ✓     |     ✓      |   ✓   |
| Run [on-demand DAST scans](application_security/dast/on-demand_scan.md)                                                             |       |         |          |     ✓     |     ✓      |   ✓   |
| Create [individual security policies](application_security/policies/_index.md)                                                      |       |         |          |     ✓     |     ✓      |   ✓   |
| Change [individual security policies](application_security/policies/_index.md)                                                      |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete [individual security policies](application_security/policies/_index.md)                                                      |       |         |          |     ✓     |     ✓      |   ✓   |
| Create [CVE ID request](application_security/cve_id_request.md)                                                                     |       |         |          |           |     ✓      |   ✓   |
| Change vulnerability status <sup>1</sup>                                                                                            |       |         |          |           |     ✓      |   ✓   |
| Create [security policy project](application_security/policies/_index.md)                                                           |       |         |          |           |            |   ✓   |
| Assign [security policy project](application_security/policies/_index.md)                                                           |       |         |          |           |            |   ✓   |
| Manage [security configurations](application_security/detect/security_configuration.md)                                             |       |         |          |           |     ✓      |   ✓   |

**Footnotes**

1. The `admin_vulnerability` permission was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/412693) from the Developer role in GitLab 17.0.

### CI/CD

[GitLab CI/CD](../ci/_index.md) permissions for some roles can be modified by these settings:

- [Project-based pipeline visibility](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines):
  When set to public, gives access to certain CI/CD features to Guest project members.
- [Pipeline visibility](../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects):
  When set to **Everyone with Access**, gives access to certain CI/CD "view" features to non-project members.

Project Owners can perform any listed action, and can delete pipelines:

| Action                                                                                                      | Non-member | Guest | Planner | Reporter | Developer | Maintainer |
| ----------------------------------------------------------------------------------------------------------- | :--------: | :---: | :-----: | :------: | :-------: | :--------: |
| View instance runner                                                                                        |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View existing artifacts <sup>1</sup>                                                                        |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View list of jobs <sup>2</sup>                                                                              |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View artifacts <sup>3</sup>                                                                                 |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| Download artifacts <sup>3</sup>                                                                             |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View [environments](../ci/environments/_index.md) <sup>1</sup>                                              |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View job logs and job details page <sup>2</sup>                                                             |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View pipelines and pipeline details pages <sup>2</sup>                                                      |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View pipelines tab in MR <sup>1</sup>                                                                       |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| View [vulnerabilities in a pipeline](application_security/detect/security_scanning_results.md) <sup>4</sup> |            |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| Run deployment job for a protected environment <sup>5</sup>                                                 |            |       |         |    ✓     |     ✓     |     ✓      |
| View [agents for Kubernetes](clusters/agent/_index.md)                                                      |            |       |         |          |     ✓     |     ✓      |
| View project [Secure Files](../api/secure_files.md)                                                         |            |       |         |          |     ✓     |     ✓      |
| Download project [Secure Files](../api/secure_files.md)                                                     |            |       |         |          |     ✓     |     ✓      |
| View a job with [debug logging](../ci/variables/variables_troubleshooting.md#enable-debug-logging)          |            |       |         |          |     ✓     |     ✓      |
| Create [environments](../ci/environments/_index.md)                                                         |            |       |         |          |     ✓     |     ✓      |
| Delete [environments](../ci/environments/_index.md)                                                         |            |       |         |          |     ✓     |     ✓      |
| Stop [environments](../ci/environments/_index.md)                                                           |            |       |         |          |     ✓     |     ✓      |
| Run, rerun, or retry CI/CD pipeline or job                                                                  |            |       |         |          |     ✓     |     ✓      |
| Run, rerun, or retry CI/CD pipeline or job for a protected branch <sup>6</sup>                              |            |       |         |          |     ✓     |     ✓      |
| Delete job logs or job artifacts <sup>7</sup>                                                               |            |       |         |          |     ✓     |     ✓      |
| Enable [review apps](../ci/review_apps/_index.md)                                                           |            |       |         |          |     ✓     |     ✓      |
| Cancel jobs <sup>8</sup>                                                                                    |            |       |         |          |     ✓     |     ✓      |
| Read [Terraform](infrastructure/_index.md) state                                                            |            |       |         |          |     ✓     |     ✓      |
| Run [interactive web terminals](../ci/interactive_web_terminal/_index.md)                                   |            |       |         |          |     ✓     |     ✓      |
| Use pipeline editor                                                                                         |            |       |         |          |     ✓     |     ✓      |
| View project runners <sup>9</sup>                                                                           |            |       |         |          |           |     ✓      |
| Manage project runners <sup>9</sup>                                                                         |            |       |         |          |           |     ✓      |
| Delete project runners <sup>10</sup>                                                                        |            |       |         |          |           |     ✓      |
| Manage [agents for Kubernetes](clusters/agent/_index.md)                                                    |            |       |         |          |           |     ✓      |
| Manage CI/CD settings                                                                                       |            |       |         |          |           |     ✓      |
| Manage job triggers                                                                                         |            |       |         |          |           |     ✓      |
| Manage project CI/CD variables                                                                              |            |       |         |          |           |     ✓      |
| Manage project protected environments                                                                       |            |       |         |          |           |     ✓      |
| Manage project [Secure Files](../api/secure_files.md)                                                       |            |       |         |          |           |     ✓      |
| Manage [Terraform](infrastructure/_index.md) state                                                          |            |       |         |          |           |     ✓      |
| Add project runners to project <sup>11</sup>                                                                |            |       |         |          |           |     ✓      |
| Clear runner caches manually                                                                                |            |       |         |          |           |     ✓      |
| Enable instance runners in project                                                                          |            |       |         |          |           |     ✓      |
| Create pipeline schedules <sup>12</sup>                                                                     |            |       |         |          |     ✓     |     ✓      |
| Edit own pipeline schedules <sup>12</sup>                                                                   |            |       |         |          |     ✓     |     ✓      |
| Delete own pipeline schedules                                                                               |            |       |         |          |     ✓     |     ✓      |
| Run pipeline schedules manually <sup>13</sup>                                                               |            |       |         |          |     ✓     |     ✓      |
| Take ownership of pipeline schedules                                                                        |            |       |         |          |           |     ✓      |
| Delete others' pipeline schedules                                                                           |            |       |         |          |           |     ✓      |

**Footnotes**

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->

1. Non-members and guests: Only if the project is public.
2. Non-members: Only if the project is public and **Project-based pipeline visibility** is enabled.
   <br>Guests: Only if **Project-based pipeline visibility** is enabled.
3. Non-members: Only if the project is public, **Project-based pipeline visibility** is enabled,
   and [`artifacts:public: false`](../ci/yaml/_index.md#artifactspublic) is not set on the job.
   <br>Guests: Only if **Project-based pipeline visibility** is enabled and
   `artifacts:public: false` is not set on the job.<br>Reporters: Only if `artifacts:public: false`
   is not set on the job.
4. Guests: Only if **Project-based pipeline visibility** is enabled.
5. Reporters: Only if the user is [part of a group with access to the protected environment](../ci/environments/protected_environments.md#deployment-only-access-to-protected-environments).
   <br>Developers and maintainers: Only if the user is [allowed to deploy to the protected environment](../ci/environments/protected_environments.md#protecting-environments).
6. Developers and maintainers: Only if the user is [allowed to merge or push to the protected branch](../ci/pipelines/_index.md#pipeline-security-on-protected-branches).
7. Developers: Only if the job was triggered by the user and runs for a non-protected branch.
8. Cancellation permissions can be [restricted in the pipeline settings](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs).
9. Maintainers: Must have the Maintainer role for a project associated with the runner.
10. Maintainers: Must have the Maintainer role for [the owner project](../ci/runners/runners_scope.md#project-runner-ownership) (first project associated with runner).
11. Maintainers: Must have the Maintainer role for the project being added and for a project already associated with the runner.
12. Developers: Only for branches where the user has merge permissions.
    For protected branches, must have merge permissions for the target branch.
    For protected tags, the user must be allowed to create protected tags.
    These permission requirements apply when creating or editing schedules, and are checked dynamically as branch protection rules may change over time.
13. When running manually, the pipeline executes with the triggering user's permissions instead of the schedule owner's permissions.

<!-- markdownlint-enable MD029 -->

This table shows granted privileges for jobs triggered by specific roles.

Project Owners can do any listed action, but no users can push source and LFS together.
Guest users and members with the Reporter role cannot do any of these actions.

| Action                                                    | Developer | Maintainer |
| --------------------------------------------------------- | :-------: | :--------: |
| Clone source and LFS from current project                 |     ✓     |     ✓      |
| Clone source and LFS from public projects                 |     ✓     |     ✓      |
| Clone source and LFS from internal projects <sup>1</sup>  |     ✓     |     ✓      |
| Clone source and LFS from private projects <sup>2</sup>   |     ✓     |     ✓      |
| Pull container images from current project                |     ✓     |     ✓      |
| Pull container images from public projects                |     ✓     |     ✓      |
| Pull container images from internal projects <sup>1</sup> |     ✓     |     ✓      |
| Pull container images from private projects <sup>2</sup>  |     ✓     |     ✓      |
| Push container images to current project <sup>3</sup>     |     ✓     |     ✓      |

**Footnotes**

1. Developers and Maintainers: Only if the triggering user is not an external user.
1. Only if the triggering user is a member of the project. See also [Usage of private Docker images with `if-not-present` pull policy](https://docs.gitlab.com/runner/security/#usage-of-private-docker-images-with-if-not-present-pull-policy).
1. You cannot push container images to other projects.

### Compliance

Project permissions for [compliance](compliance/_index.md) features including compliance center, audit events, compliance frameworks, and licenses.

| Action                                                                                                          | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| --------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View [allowed and denied licenses in MR](compliance/license_scanning_of_cyclonedx_files/_index.md) <sup>1</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [audit events](compliance/audit_events.md) <sup>2</sup>                                                    |       |         |          |     ✓     |     ✓      |   ✓   |
| View licenses in [dependency list](application_security/dependency_list/_index.md)                              |       |         |          |     ✓     |     ✓      |   ✓   |
| Manage [audit streams](compliance/audit_event_streaming.md)                                                     |       |         |          |           |            |   ✓   |

**Footnotes**

1. On GitLab Self-Managed, users with the Guest role are able to perform this action only on public
   and internal projects (not on private projects). [External users](../administration/external_users.md)
   must have at least the Reporter role, even if the project is internal. Users with the Guest
   role on GitLab.com are able to perform this action only on public projects because internal
   visibility is not available.
1. Users can only view events based on their individual actions. For more details, see the [prerequisites](compliance/audit_events.md#prerequisites).

### GitLab Duo

Project permissions for [GitLab Duo](gitlab_duo/_index.md):

| Action                                                                               | Non-member | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------------------------ | :--------: | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Use GitLab Duo features <sup>1</sup>                                                 |            |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Configure [GitLab Duo feature availability](gitlab_duo/turn_on_off.md#for-a-project) |            |       |         |          |           |     ✓      |   ✓   |

**Footnotes**

1. Code Suggestions requires a [user being assigned a seat to gain access to a GitLab Duo add-on](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).

### Machine learning model registry and experiment

Project permissions for [model registry](project/ml/model_registry/_index.md) and [model experiments](project/ml/experiment_tracking/_index.md).

| Action                                                                          | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View [models and versions](project/ml/model_registry/_index.md) <sup>1</sup>    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [model experiments](project/ml/experiment_tracking/_index.md) <sup>2</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create models, versions, and artifacts <sup>3</sup>                             |       |         |          |     ✓     |     ✓      |   ✓   |
| Edit models, versions, and artifacts                                            |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete models, versions, and artifacts                                          |       |         |          |     ✓     |     ✓      |   ✓   |
| Create experiments and candidates                                               |       |         |          |     ✓     |     ✓      |   ✓   |
| Edit experiments and candidates                                                 |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete experiments and candidates                                               |       |         |          |     ✓     |     ✓      |   ✓   |

**Footnotes**

1. Non-members can only view models and versions in public projects with the **Everyone with access**
   visibility level. Non-members can't view internal projects, even if they're logged in.
1. Non-members can only view model experiments in public projects with the **Everyone with access**
   visibility level. Non-members can't view internal projects, even if they're logged in.
1. You can also upload and download artifacts with the package registry API, which uses
   a different set of permissions.

### Monitoring

Project permissions for monitoring including [error tracking](../operations/error_tracking.md) and [incident management](../operations/incident_management/_index.md):

| Action                                                                                                              | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View an [incident](../operations/incident_management/incidents.md)                                                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Assign an [incident management](../operations/incident_management/_index.md) alert                                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Participate in on-call rotation for [Incident Management](../operations/incident_management/_index.md)              |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [alerts](../operations/incident_management/alerts.md)                                                          |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [error tracking](../operations/error_tracking.md) list                                                         |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [escalation policies](../operations/incident_management/escalation_policies.md)                                |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [on-call schedules](../operations/incident_management/oncall_schedules.md)                                     |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Create [incident](../operations/incident_management/incidents.md)                                                   |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Change [alert status](../operations/incident_management/alerts.md#change-an-alerts-status)                          |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Change [incident severity](../operations/incident_management/manage_incidents.md#change-severity)                   |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Change [incident escalation status](../operations/incident_management/manage_incidents.md#change-status)            |       |         |          |     ✓     |     ✓      |   ✓   |
| Change [incident escalation policy](../operations/incident_management/manage_incidents.md#change-escalation-policy) |       |         |          |     ✓     |     ✓      |   ✓   |
| Manage [error tracking](../operations/error_tracking.md)                                                            |       |         |          |           |     ✓      |   ✓   |
| Manage [escalation policies](../operations/incident_management/escalation_policies.md)                              |       |         |          |           |     ✓      |   ✓   |
| Manage [on-call schedules](../operations/incident_management/oncall_schedules.md)                                   |       |         |          |           |     ✓      |   ✓   |

### Project planning

Project permissions for [issues](project/issues/_index.md):

| Action                                                                            | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| --------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View issues                                                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) issues and comments                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create issues                                                                     |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [confidential issues](project/issues/confidential_issues.md)                 |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) confidential issues and comments                       |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Edit issues, including metadata, item locking, and resolving threads <sup>1</sup> |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add internal notes                                                                |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Close and reopen issues <sup>2</sup>                                              |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Manage [design management](project/issues/design_management.md) files             |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Manage [issue boards](project/issue_board.md)                                     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Manage [milestones](project/milestones/_index.md)                                 |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) milestones                                             |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Archive or reopen [requirements](project/requirements/_index.md) <sup>3</sup>     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create or edit [requirements](project/requirements/_index.md) <sup>4</sup>        |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Import or export [requirements](project/requirements/_index.md)                   |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Archive [test cases](../ci/test_cases/_index.md)                                  |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create [test cases](../ci/test_cases/_index.md)                                   |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Move [test cases](../ci/test_cases/_index.md)                                     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Reopen [test cases](../ci/test_cases/_index.md)                                   |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Import](project/issues/csv_import.md) issues from a CSV file                     |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| [Export](project/issues/csv_export.md) issues to a CSV file                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Delete issues                                                                     |       |         |          |           |            |   ✓   |
| Manage [Feature flags](../operations/feature_flags.md)                            |       |         |          |     ✓     |     ✓      |   ✓   |

**Footnotes**

1. Metadata includes labels, assignees, milestones, epics, weight, confidentiality, time tracking,
   and more. Guest users can only set metadata when creating an issue. They cannot change the
   metadata on existing issues. Guest users can modify the title and description of issues that
   they authored or are assigned to.
1. Guest users can close and reopen issues that they authored or are assigned to.
1. Guest users can archive and reopen issues that they authored or are assigned to.
1. Guest users can modify the title and description that they authored or are assigned to.

Project permissions for [tasks](tasks.md):

| Action                                                                           | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| -------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View tasks                                                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) tasks                                                 |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create tasks                                                                     |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Edit tasks, including metadata, item locking, and resolving threads <sup>1</sup> |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add a linked item                                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Convert to another item type                                                     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Remove from issue                                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add internal note                                                                |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Delete tasks <sup>2</sup>                                                        |       |    ✓    |          |           |            |   ✓   |

**Footnotes**

1. Guest users can modify the title and description that they authored or are assigned to.
1. Users who don't have the Planner or Owner role can delete the tasks they authored.

Project permissions for [OKRs](okrs.md):

| Action                                                             | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View OKRs                                                          |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) OKRs                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create OKRs                                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Edit OKRs, including metadata, item locking, and resolving threads |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add a child OKR                                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add a linked item                                                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Convert to another item type                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Edit OKRs                                                          |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Change confidentiality in OKR                                      |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add internal note                                                  |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |

Project permissions for [wikis](project/wiki/_index.md):

| Action                           | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| -------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View wiki                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) wikis |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create wiki pages                |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| Edit wiki pages                  |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| Delete wiki pages                |       |    ✓    |          |     ✓     |     ✓      |   ✓   |

### Packages and registry

Project permissions for [container registry](packages/_index.md):

| Action                                                                                           | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ------------------------------------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Pull container registry images <sup>1</sup>                                                      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Push container registry images                                                                   |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete container registry images                                                                 |       |         |          |     ✓     |     ✓      |   ✓   |
| Manage cleanup policies                                                                          |       |         |          |           |     ✓      |   ✓   |
| Create [tag protection](packages/container_registry/protected_container_tags.md) rules           |       |         |          |           |     ✓      |   ✓   |
| Create [immutable tag protection](packages/container_registry/immutable_container_tags.md) rules |       |         |          |           |            |   ✓   |

**Footnotes**:

1. Viewing the container registry and pulling images is controlled by [container registry visibility permissions](packages/container_registry/_index.md#container-registry-visibility-permissions). The Guest role does not have viewing or pulling permissions in private projects.

Project permissions for [package registry](packages/_index.md):

| Action                                  | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| --------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Pull packages <sup>1</sup>              |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Publish packages                        |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete packages                         |       |         |          |           |     ✓      |   ✓   |
| Delete files associated with a package  |       |         |          |           |     ✓      |   ✓   |

**Footnotes**

1. On GitLab Self-Managed, users with the Guest role are able to perform this action only on public
   and internal projects (not on private projects). [External users](../administration/external_users.md)
   must be given explicit access (at least the **Reporter** role) even if the project is internal.
   Users with the Guest role on GitLab.com are only able to perform this action on public projects
   because internal visibility is not available.

### Projects

Project permissions for [project features](project/organize_work_with_projects.md):

| Action                                                                                 | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Download project <sup>1</sup>                                                          |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Leave comments                                                                         |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Reposition comments on images (posted by any user) <sup>2</sup>                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [insights](project/insights/_index.md)                                            |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [requirements](project/requirements/_index.md)                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [time tracking](project/time_tracking.md) reports <sup>1</sup>                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [snippets](snippets.md)                                                           |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) [snippets](snippets.md) and comments                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View [project traffic statistics](../api/project_statistics.md)                        |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Create [snippets](snippets.md)                                                         |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| View [releases](project/releases/_index.md) <sup>3</sup>                               |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Manage [releases](project/releases/_index.md) <sup>4</sup>                             |       |         |          |           |     ✓      |   ✓   |
| Configure [webhooks](project/integrations/webhooks.md)                                 |       |         |          |           |     ✓      |   ✓   |
| Manage [project access tokens](project/settings/project_access_tokens.md) <sup>5</sup> |       |         |          |           |     ✓      |   ✓   |
| [Export project](project/settings/import_export.md)                                    |       |         |          |           |     ✓      |   ✓   |
| Rename project                                                                         |       |         |          |           |     ✓      |   ✓   |
| Edit project badges                                                                    |       |         |          |           |     ✓      |   ✓   |
| Edit project settings                                                                  |       |         |          |           |     ✓      |   ✓   |
| Change [project features visibility](public_access.md) level <sup>6</sup>              |       |         |          |           |     ✓      |   ✓   |
| Change custom settings for [project integrations](project/integrations/_index.md)      |       |         |          |           |     ✓      |   ✓   |
| Edit comments posted by other users                                                    |       |         |          |           |     ✓      |   ✓   |
| Add [deploy keys](project/deploy_keys/_index.md)                                       |       |         |          |           |     ✓      |   ✓   |
| Manage [project operations](../operations/_index.md)                                   |       |         |          |           |     ✓      |   ✓   |
| View [Usage quotas](storage_usage_quotas.md) page                                      |       |         |          |           |     ✓      |   ✓   |
| Globally delete [snippets](snippets.md)                                                |       |         |          |           |     ✓      |   ✓   |
| Globally edit [snippets](snippets.md)                                                  |       |         |          |           |     ✓      |   ✓   |
| Archive project                                                                        |       |         |          |           |            |   ✓   |
| Change project visibility level                                                        |       |         |          |           |            |   ✓   |
| Delete project                                                                         |       |         |          |           |            |   ✓   |
| Disable notification emails                                                            |       |         |          |           |            |   ✓   |
| Transfer project                                                                       |       |         |          |           |            |   ✓   |

**Footnotes**

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->

1. On GitLab Self-Managed, users with the Guest role are able to perform this action only on
   public and internal projects (not on private projects). [External users](../administration/external_users.md)
   must be given explicit access (at least the **Reporter** role) even if the project is internal.
   Users with the Guest role on GitLab.com are only able to perform this action on public projects
   because internal visibility is not available.
2. Applies only to comments on [Design Management](project/issues/design_management.md) designs.
3. Guest users can access GitLab [**Releases**](project/releases/_index.md) for downloading
   assets but are not allowed to download the source code nor see
   [repository information like commits and release evidence](project/releases/_index.md#view-a-release-and-download-assets).
4. If the [tag is protected](project/protected_tags.md), this depends on the access given to
   Developers and Maintainers.
5. For GitLab Self-Managed, project access tokens are available in all tiers. For GitLab.com,
   project access tokens are supported in the Premium and Ultimate tier (excluding [trial licenses](https://about.gitlab.com/free-trial/)).
6. A Maintainer or Owner can't change project features visibility level if
   [project visibility](public_access.md) is set to private.

   <!-- markdownlint-enable MD029 -->

Project permissions for [GitLab Pages](project/pages/_index.md):

| Action                                                                                 | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View GitLab Pages protected by [access control](project/pages/pages_access_control.md) |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Manage GitLab Pages                                                                    |       |         |          |           |     ✓      |   ✓   |
| Manage GitLab Pages domain and certificates                                            |       |         |          |           |     ✓      |   ✓   |
| Remove GitLab Pages                                                                    |       |         |          |           |     ✓      |   ✓   |

### Repository

Project permissions for [repository](project/repository/_index.md) features including source code, branches, push rules, and more:

| Action                                                                | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| --------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View project code <sup>1</sup>                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) project code <sup>2</sup>                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) commits and comments <sup>3</sup>          |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Pull project code <sup>4</sup>                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| View commit status                                                    |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Create commit status <sup>5</sup>                                     |       |         |          |     ✓     |     ✓      |   ✓   |
| Update commit status <sup>5</sup>                                     |       |         |          |     ✓     |     ✓      |   ✓   |
| Create [Git tags](project/repository/tags/_index.md)                  |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete [Git tags](project/repository/tags/_index.md)                  |       |         |          |     ✓     |     ✓      |   ✓   |
| Create new [branches](project/repository/branches/_index.md)          |       |         |          |     ✓     |     ✓      |   ✓   |
| Push to non-protected branches                                        |       |         |          |     ✓     |     ✓      |   ✓   |
| Force push to non-protected branches                                  |       |         |          |     ✓     |     ✓      |   ✓   |
| Delete non-protected branches                                         |       |         |          |     ✓     |     ✓      |   ✓   |
| Manage [protected branches](project/repository/branches/protected.md) |       |         |          |           |     ✓      |   ✓   |
| Push to protected branches <sup>5</sup>                               |       |         |          |           |     ✓      |   ✓   |
| Delete protected branches                                             |       |         |          |           |     ✓      |   ✓   |
| Manage [protected tags](project/protected_tags.md)                    |       |         |          |           |     ✓      |   ✓   |
| Manage [push rules](project/repository/push_rules.md)                 |       |         |          |           |     ✓      |   ✓   |
| Remove fork relationship                                              |       |         |          |           |            |   ✓   |
| Force push to protected branches <sup>6</sup>                         |       |         |          |           |            |       |

**Footnotes**

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->

1. On GitLab Self-Managed, users with the Guest role are able to perform this action only on public
   and internal projects (not on private projects). [External users](../administration/external_users.md)
   must be given explicit access (at least the **Reporter** role) even if the project is internal.
   Users with the Guest role on GitLab.com are only able to perform this action on public projects because
   internal visibility is not available. In GitLab 15.9 and later, users with the Guest role and an
   Ultimate license can view private repository content if an administrator (on GitLab Self-Managed
   or GitLab Dedicated) or group owner (on GitLab.com) gives those users permission. The administrator
   or group owner can create a [custom role](custom_roles/_index.md) through the API or UI and assign
   that role to the users.
2. On GitLab Self-Managed, users with the Guest role are able to perform this action only on public
   and internal projects (not on private projects). [External users](../administration/external_users.md)
   must be given explicit access (at least the **Reporter** role) even if the project is internal. Users
   with the Guest role on GitLab.com are only able to perform this action on public projects because
   internal visibility is not available. In GitLab 15.9 and later, users with the Guest role and an
   Ultimate license can search private repository content if an administrator (on GitLab Self-Managed
   or GitLab Dedicated) or group owner (on GitLab.com) gives those users permission. The administrator
   or group owner can create a [custom role](custom_roles/_index.md) through the API or UI and assign
   that role to the users.
3. On GitLab Self-Managed, users with the Guest role are able to perform this action only on public
   and internal projects (not on private projects). [External users](../administration/external_users.md)
   must be given explicit access (at least the **Reporter** role) even if the project is internal. Users
   with the Guest role on GitLab.com are only able to perform this action on public projects because
   internal visibility is not available.
4. If the [branch is protected](project/repository/branches/protected.md), this depends on the
   access given to Developers and Maintainers.
5. On GitLab Self-Managed, users with the Guest role are able to perform this action only on public
   and internal projects (not on private projects). [External users](../administration/external_users.md)
   must be given explicit access (at least the **Reporter** role) even if the project is internal. Users
   with the Guest role on GitLab.com are only able to perform this action on public projects because
   internal visibility is not available. In GitLab 15.9 and later, users with the Guest role and an
   Ultimate license can view private repository content if an administrator (on GitLab Self-Managed
   or GitLab Dedicated) or group owner (on GitLab.com) gives those users permission. The administrator
   or group owner can create a [custom role](custom_roles/_index.md) through the API or UI and assign
   that role to the users.
6. Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [protected branches](project/repository/branches/protected.md#allow-force-push).

<!-- markdownlint-enable MD029 -->

### Merge requests

Project permissions for [merge requests](project/merge_requests/_index.md):

| Action                                                                                    | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ----------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [View](project/merge_requests/_index.md#view-merge-requests) a merge request <sup>1</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [Search](search/_index.md) merge requests and comments <sup>1</sup>                       |   ✓   |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [Approve](project/merge_requests/approvals/_index.md) merge requests <sup>2</sup>         |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Add internal note                                                                         |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Comment and add suggestions                                                               |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Create [snippets](snippets.md)                                                            |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| Create [merge request](project/merge_requests/creating_merge_requests.md) <sup>3</sup>    |       |         |          |     ✓     |     ✓      |   ✓   |
| Update merge request details <sup>4</sup>                                                 |       |         |          |     ✓     |     ✓      |   ✓   |
| Manage [merge request settings](project/merge_requests/approvals/settings.md)             |       |         |          |           |     ✓      |   ✓   |
| Manage [merge request approval rules](project/merge_requests/approvals/rules.md)          |       |         |          |           |     ✓      |   ✓   |
| Delete merge request                                                                      |       |         |          |           |            |   ✓   |

**Footnotes**

1. On GitLab Self-Managed, users with the Guest role are able to perform this action only on public
   and internal projects (not on private projects). [External users](../administration/external_users.md)
   must be given explicit access (at least the **Reporter** role) even if the project is internal. Users
   with the Guest role on GitLab.com are only able to perform this action on public projects because
   internal visibility is not available.
1. Approval from Planner and Reporter roles is available only if
   [enabled for the project](project/merge_requests/approvals/rules.md#enable-approval-permissions-for-additional-users).
1. In projects that accept contributions from external members, users can create, edit, and close their
   own merge requests. For **private** projects, this excludes the Guest role as those users
   [cannot clone private projects](public_access.md#private-projects-and-groups). For **internal**
   projects, includes users with read-only access to the project, as
   [they can clone internal projects](public_access.md#internal-projects-and-groups).
1. In projects that accept contributions from external members, users can create, edit, and close their
   own merge requests. They cannot edit some fields, like assignees, reviewers, labels, and milestones.

### User management

Project permissions for [user management](project/members/_index.md).

| Action                                                           | Guest | Planner | Reporter | Developer | Maintainer | Owner |
| ---------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| View 2FA status of members                                       |       |         |          |           |     ✓      |   ✓   |
| Manage [project members](project/members/_index.md) <sup>1</sup> |       |         |          |           |     ✓      |   ✓   |
| Share (invite) projects with groups <sup>2</sup>                 |       |         |          |           |     ✓      |   ✓   |

**Footnotes**

1. Maintainers cannot create, demote, or remove Owners, and they cannot promote users to the Owner role.
   They also cannot approve Owner role access requests.
1. When [Share Group Lock](project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)
   is enabled the project can't be shared with other groups. It does not affect group with group sharing.

## Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent groups. This model allows access to
nested groups if you have membership in one of its parents.

For more information, see
[subgroup memberships](group/subgroups/_index.md#subgroup-membership).

## Users with Minimal Access

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Support for inviting users with Minimal Access role [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106438) in GitLab 15.9.

{{< /history >}}

Users with the Minimal Access role do not:

- Automatically have access to projects and subgroups in that top-level group.
- Count as licensed seats on GitLab Self-Managed Ultimate subscriptions or any GitLab.com subscriptions, provided the user has no other role anywhere in the instance or in the GitLab.com namespace.

Owners must explicitly add these users to the specific subgroups and
projects.

You can use the Minimal Access role with [SAML SSO for GitLab.com groups](group/saml_sso/_index.md)
to control access to groups and projects in the group hierarchy. You can set the default role to
Minimal Access for members automatically added to the top-level group through SSO.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **SAML SSO**.
1. From the **Default membership role** dropdown list, select **Minimal Access**.
1. Select **Save changes**.

### Minimal access users receive 404 errors

Because of an [outstanding issue](https://gitlab.com/gitlab-org/gitlab/-/issues/267996), when a user with the Minimal Access role:

- Signs in with standard web authentication, they receive a `404` error when accessing the parent group.
- Signs in with Group SSO, they receive a `404` error immediately because they are redirected to the parent group page.

To work around the issue, give these users at least the Guest role to any project or subgroup in the parent group. Guest users consume a license seat in the Premium tier but do not in the Ultimate tier.

## Related topics

- [Protect your repository](project/repository/protect.md)
- [Custom roles](custom_roles/_index.md)
- [Members](project/members/_index.md)
- Customize permissions on [protected branches](project/repository/branches/protected.md)
- [LDAP user permissions](group/access_and_permissions.md#manage-group-memberships-with-ldap)
- [Value stream analytics permissions](group/value_stream_analytics/_index.md#access-permissions)
- [Project aliases](project/working_with_projects.md#project-aliases)
- [Auditor users](../administration/auditor_users.md)
- [Confidential issues](project/issues/confidential_issues.md)
- [Container registry permissions](packages/container_registry/_index.md#container-registry-visibility-permissions)
- [Release permissions](project/releases/_index.md#release-permissions)
- [Read-only namespaces](read_only_namespaces.md)
