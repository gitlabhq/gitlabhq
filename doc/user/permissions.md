---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Permissions and roles

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

NOTE:
In GitLab 11.0, the Master role was renamed to Maintainer.

The Owner role is only available at the group or personal namespace level (and for instance administrators) and is inherited by its projects.
While Maintainer is the highest project-level role, some actions can only be performed by a personal namespace or group owner, or an instance administrator, who receives all permissions.
For more information, see [projects members documentation](project/members/index.md).

The following table lists project permissions available for each role:

| Action                                            | Guest   | Reporter   | Developer   |Maintainer| Owner  |
|---------------------------------------------------|---------|------------|-------------|----------|--------|
| Download project                                  | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| Leave comments                                    | ✓       | ✓          | ✓           | ✓        | ✓      |
| View allowed and denied licenses **(ULTIMATE)**   | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View License Compliance reports **(ULTIMATE)**    | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View Security reports **(ULTIMATE)**              | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| View Dependency list **(ULTIMATE)**               |         |            | ✓           | ✓        | ✓      |
| View License list **(ULTIMATE)**                  |         | ✓          | ✓           | ✓        | ✓      |
| View [Threats list](application_security/threat_monitoring/#threat-monitoring) **(ULTIMATE)** |         |            | ✓           | ✓        | ✓      |
| Create and run [on-demand DAST scans](application_security/dast/#on-demand-scans) |         |            | ✓           | ✓        | ✓      |
| View licenses in Dependency list **(ULTIMATE)**   | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View [Design Management](project/issues/design_management.md) pages | ✓   | ✓   | ✓    | ✓        | ✓      |
| View project code                                 | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| Pull project code                                 | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View GitLab Pages protected by [access control](project/pages/introduction.md#gitlab-pages-access-control) | ✓       | ✓          | ✓           | ✓        | ✓      |
| View wiki pages                                   | ✓       | ✓          | ✓           | ✓        | ✓      |
| See a list of jobs                                | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| See a job log                                     | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| See a job with [debug logging](../ci/variables/index.md#debug-logging) |         |            | ✓           | ✓        | ✓      |
| Download and browse job artifacts                 | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| Create confidential issue                         | ✓       | ✓          | ✓           | ✓        | ✓      |
| Create new issue                                  | ✓       | ✓          | ✓           | ✓        | ✓      |
| See linked issues                                 | ✓       | ✓          | ✓           | ✓        | ✓      |
| View [Releases](project/releases/index.md)        | ✓ (*6*) | ✓          | ✓           | ✓        | ✓      |
| View requirements **(ULTIMATE)**                  | ✓       | ✓          | ✓           | ✓        | ✓      |
| View Insights **(ULTIMATE)**                      | ✓       | ✓          | ✓           | ✓        | ✓      |
| View Issue analytics **(PREMIUM)**                | ✓       | ✓          | ✓           | ✓        | ✓      |
| View Merge Request analytics **(PREMIUM)**        | ✓       | ✓          | ✓           | ✓        | ✓      |
| View Value Stream analytics                       | ✓       | ✓          | ✓           | ✓        | ✓      |
| Manage user-starred metrics dashboards (*7*)      | ✓       | ✓          | ✓           | ✓        | ✓      |
| View confidential issues                          | (*2*)   | ✓          | ✓           | ✓        | ✓      |
| Assign issues                                     |         | ✓          | ✓           | ✓        | ✓      |
| Assign reviewers                                  |         | ✓          | ✓           | ✓        | ✓      |
| Label issues                                      |         | ✓          | ✓           | ✓        | ✓      |
| Set issue weight                                  |         | ✓          | ✓           | ✓        | ✓      |
| [Set issue estimate and record time spent](project/time_tracking.md) | | ✓ | ✓         | ✓        | ✓      |
| View a time tracking report                       | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| Lock issue threads                                |         | ✓          | ✓           | ✓        | ✓      |
| Manage issue tracker                              |         | ✓          | ✓           | ✓        | ✓      |
| Manage linked issues                              |         | ✓          | ✓           | ✓        | ✓      |
| Manage labels                                     |         | ✓          | ✓           | ✓        | ✓      |
| Create code snippets                              |         | ✓          | ✓           | ✓        | ✓      |
| See a commit status                               |         | ✓          | ✓           | ✓        | ✓      |
| See a container registry                          |         | ✓          | ✓           | ✓        | ✓      |
| See environments                                  |         | ✓          | ✓           | ✓        | ✓      |
| See [DORA metrics](analytics/ci_cd_analytics.md)  |         | ✓          | ✓           | ✓        | ✓      |
| See a list of merge requests                      |         | ✓          | ✓           | ✓        | ✓      |
| View CI/CD analytics                              |         | ✓          | ✓           | ✓        | ✓      |
| View Code Review analytics **(PREMIUM)**          |         | ✓          | ✓           | ✓        | ✓      |
| View Repository analytics                         |         | ✓          | ✓           | ✓        | ✓      |
| View Error Tracking list                          |         | ✓          | ✓           | ✓        | ✓      |
| View metrics dashboard annotations                |         | ✓          | ✓           | ✓        | ✓      |
| Archive/reopen requirements **(ULTIMATE)**        |         | ✓          | ✓           | ✓        | ✓      |
| Create/edit requirements **(ULTIMATE)**           |         | ✓          | ✓           | ✓        | ✓      |
| Import/export requirements **(ULTIMATE)**         |         | ✓          | ✓           | ✓        | ✓      |
| Create new [test case](../ci/test_cases/index.md) |         | ✓          | ✓           | ✓        | ✓      |
| Archive [test case](../ci/test_cases/index.md)    |         | ✓          | ✓           | ✓        | ✓      |
| Move [test case](../ci/test_cases/index.md)       |         | ✓          | ✓           | ✓        | ✓      |
| Reopen [test case](../ci/test_cases/index.md)     |         | ✓          | ✓           | ✓        | ✓      |
| Pull [packages](packages/index.md)                |         | ✓          | ✓           | ✓        | ✓      |
| View project statistics                           |         | ✓          | ✓           | ✓        | ✓      |
| Publish [packages](packages/index.md)             |         |            | ✓           | ✓        | ✓      |
| Create/edit/delete a Cleanup policy               |         |            | ✓           | ✓        | ✓      |
| Upload [Design Management](project/issues/design_management.md) files |  |  | ✓        | ✓        | ✓      |
| Create/edit/delete [releases](project/releases/index.md)|   |            | ✓ (*13*)    | ✓ (*13*) | ✓ (*13*) |
| Manage merge approval rules (project settings)    |         |            |             | ✓        | ✓      |
| Create new merge request                          |         |            | ✓           | ✓        | ✓      |
| Create new branches                               |         |            | ✓           | ✓        | ✓      |
| Push to non-protected branches                    |         |            | ✓           | ✓        | ✓      |
| Force push to non-protected branches              |         |            | ✓           | ✓        | ✓      |
| Remove non-protected branches                     |         |            | ✓           | ✓        | ✓      |
| Assign merge requests                             |         |            | ✓           | ✓        | ✓      |
| Label merge requests                              |         |            | ✓           | ✓        | ✓      |
| Lock merge request threads                        |         |            | ✓           | ✓        | ✓      |
| Approve merge requests (*9*)                      |         |            | ✓           | ✓        | ✓      |
| Manage/Accept merge requests                      |         |            | ✓           | ✓        | ✓      |
| Create new environments                           |         |            | ✓           | ✓        | ✓      |
| Stop environments                                 |         |            | ✓           | ✓        | ✓      |
| Enable Review Apps                                |         |            | ✓           | ✓        | ✓      |
| View Pods logs                                    |         |            | ✓           | ✓        | ✓      |
| Read Terraform state                              |         |            | ✓           | ✓        | ✓      |
| Add tags                                          |         |            | ✓           | ✓        | ✓      |
| Cancel and retry jobs                             |         |            | ✓           | ✓        | ✓      |
| Create or update commit status                    |         |            | ✓ (*5*)     | ✓        | ✓      |
| Update a container registry                       |         |            | ✓           | ✓        | ✓      |
| Remove a container registry image                 |         |            | ✓           | ✓        | ✓      |
| Create/edit/delete project milestones             |         |            | ✓           | ✓        | ✓      |
| Use security dashboard **(ULTIMATE)**             |         |            | ✓           | ✓        | ✓      |
| View vulnerability findings in Dependency list **(ULTIMATE)** |    |     | ✓           | ✓        | ✓      |
| Create issue from vulnerability finding **(ULTIMATE)** |    |            | ✓           | ✓        | ✓      |
| Dismiss vulnerability finding **(ULTIMATE)**      |         |            | ✓           | ✓        | ✓      |
| View vulnerability **(ULTIMATE)**                 |         |            | ✓           | ✓        | ✓      |
| Create vulnerability from vulnerability finding **(ULTIMATE)** |   |     | ✓           | ✓        | ✓      |
| Resolve vulnerability **(ULTIMATE)**              |         |            | ✓           | ✓        | ✓      |
| Dismiss vulnerability **(ULTIMATE)**              |         |            | ✓           | ✓        | ✓      |
| Revert vulnerability to detected state **(ULTIMATE)** |     |            | ✓           | ✓        | ✓      |
| Apply code change suggestions                     |         |            | ✓           | ✓        | ✓      |
| Create and edit wiki pages                        |         |            | ✓           | ✓        | ✓      |
| Rewrite/remove Git tags                           |         |            | ✓           | ✓        | ✓      |
| Manage Feature Flags **(PREMIUM)**                |         |            | ✓           | ✓        | ✓      |
| Create/edit/delete metrics dashboard annotations  |         |            | ✓           | ✓        | ✓      |
| Run CI/CD pipeline against a protected branch     |         |            | ✓ (*5*)     | ✓        | ✓      |
| Delete [packages](packages/index.md)              |         |            |             | ✓        | ✓      |
| Request a CVE ID **(FREE SAAS)**                  |         |            |             | ✓        | ✓      |
| Use environment terminals                         |         |            |             | ✓        | ✓      |
| Run Web IDE's Interactive Web Terminals **(ULTIMATE SELF)** |     |      |             | ✓        | ✓      |
| Add new team members                              |         |            |             | ✓        | ✓      |
| Enable/disable branch protection                  |         |            |             | ✓        | ✓      |
| Push to protected branches                        |         |            |             | ✓        | ✓      |
| Turn on/off protected branch push for developers  |         |            |             | ✓        | ✓      |
| Enable/disable tag protections                    |         |            |             | ✓        | ✓      |
| Edit project settings                             |         |            |             | ✓        | ✓      |
| Edit project badges                               |         |            |             | ✓        | ✓      |
| Export project                                    |         |            |             | ✓        | ✓      |
| Share (invite) projects with groups               |         |            |             | ✓ (*8*)  | ✓ (*8*)|
| Add deploy keys to project                        |         |            |             | ✓        | ✓      |
| Configure project hooks                           |         |            |             | ✓        | ✓      |
| Manage runners                                    |         |            |             | ✓        | ✓      |
| Manage job triggers                               |         |            |             | ✓        | ✓      |
| Manage CI/CD variables                            |         |            |             | ✓        | ✓      |
| Manage GitLab Pages                               |         |            |             | ✓        | ✓      |
| Manage GitLab Pages domains and certificates      |         |            |             | ✓        | ✓      |
| Remove GitLab Pages                               |         |            |             | ✓        | ✓      |
| Manage clusters                                   |         |            |             | ✓        | ✓      |
| Manage Project Operations                         |         |            |             | ✓        | ✓      |
| Manage Terraform state                            |         |            |             | ✓        | ✓      |
| Manage license policy **(ULTIMATE)**              |         |            |             | ✓        | ✓      |
| Manage security policy **(ULTIMATE)**             |         |            | ✓           | ✓        | ✓      |
| Create or assign security policy project **(ULTIMATE)**     |         |            |             |          | ✓      |
| Edit comments (posted by any user)                |         |            |             | ✓        | ✓      |
| Reposition comments on images (posted by any user)|✓ (*10*) | ✓ (*10*)   |  ✓ (*10*)   | ✓        | ✓      |
| Manage Error Tracking                             |         |            |             | ✓        | ✓      |
| Delete wiki pages                                 |         |            |             | ✓        | ✓      |
| View project Audit Events                         |         |            |  ✓ (*11*)   | ✓        | ✓      |
| Manage [push rules](../push_rules/push_rules.md)  |         |            |             | ✓        | ✓      |
| Manage [project access tokens](project/settings/project_access_tokens.md) **(FREE SELF)** **(PREMIUM SAAS)** (*12*) |         |            |             | ✓        | ✓      |
| View 2FA status of members                        |         |            |             | ✓        | ✓      |
| Switch visibility level                           |         |            |             |          | ✓      |
| Transfer project to another namespace             |         |            |             |          | ✓      |
| Rename project                                    |         |            |             |          | ✓      |
| Remove fork relationship                          |         |            |             |          | ✓      |
| Delete project                                    |         |            |             |          | ✓      |
| Archive project                                   |         |            |             |          | ✓      |
| Delete issues                                     |         |            |             |          | ✓      |
| Delete pipelines                                  |         |            |             |          | ✓      |
| Delete merge request                              |         |            |             |          | ✓      |
| Disable notification emails                       |         |            |             |          | ✓      |
| Administer project compliance frameworks          |         |            |             |          | ✓      |
| Force push to protected branches (*4*)            |         |            |             |          |        |
| Remove protected branches (*4*)                   |         |            |             |          |        |

1. Guest users are able to perform this action on public and internal projects, but not private projects. This doesn't apply to [external users](#external-users) where explicit access must be given even if the project is internal.
1. Guest users can only view the confidential issues they created themselves.
1. If **Public pipelines** is enabled in **Project Settings > CI/CD**.
1. Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [protected branches](project/protected_branches.md).
1. If the [branch is protected](project/protected_branches.md), this depends on the access Developers and Maintainers are given.
1. Guest users can access GitLab [**Releases**](project/releases/index.md) for downloading assets but are not allowed to download the source code nor see repository information like tags and commits.
1. Actions are limited only to records owned (referenced) by user.
1. When [Share Group Lock](group/index.md#prevent-a-project-from-being-shared-with-groups) is enabled the project can't be shared with other groups. It does not affect group with group sharing.
1. For information on eligible approvers for merge requests, see
   [Eligible approvers](project/merge_requests/approvals/rules.md#eligible-approvers).
1. Applies only to comments on [Design Management](project/issues/design_management.md) designs.
1. Users can only view events based on their individual actions.
1. Project access tokens are supported for self-managed instances on Free and above. They are also
   supported on GitLab SaaS Premium and above (excluding [trial licenses](https://about.gitlab.com/free-trial/)).
1. If the [tag is protected](#release-permissions-with-protected-tags), this depends on the access Developers and Maintainers are given.

## Project features permissions

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

### Value Stream Analytics permissions

Find the current permissions on the Value Stream Analytics dashboard, as described in
[related documentation](analytics/value_stream_analytics.md#permissions).

### Issue Board permissions

Find the current permissions for interacting with the Issue Board feature in the
[Issue Boards permissions page](project/issue_board.md#permissions).

### File Locking permissions **(PREMIUM)**

The user that locks a file or directory is the only one that can edit and push their changes back to the repository where the locked objects are located.

Read through the documentation on [permissions for File Locking](project/file_lock.md#permissions) to learn more.

### Confidential Issues permissions

Confidential issues can be accessed by users with reporter and higher permission levels,
as well as by guest users that create a confidential issue. To learn more,
read through the documentation on [permissions and access to confidential issues](project/issues/confidential_issues.md#permissions-and-access-to-confidential-issues).

## Group members permissions

NOTE:
In GitLab 11.0, the Master role was renamed to Maintainer.

Any user can remove themselves from a group, unless they are the last Owner of
the group.

The following table lists group permissions available for each role:

| Action                                                 | Guest | Reporter | Developer | Maintainer | Owner |
|--------------------------------------------------------|-------|----------|-----------|------------|-------|
| Browse group                                           | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group wiki pages **(PREMIUM)**                    | ✓ (6) | ✓        | ✓         | ✓          | ✓     |
| View Insights charts **(ULTIMATE)**                    | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group epic **(PREMIUM)**                          | ✓     | ✓        | ✓         | ✓          | ✓     |
| Create/edit group epic **(PREMIUM)**                   |       | ✓        | ✓         | ✓          | ✓     |
| Create/edit/delete epic boards **(PREMIUM)**           |       | ✓        | ✓         | ✓          | ✓     |
| Manage group labels                                    |       | ✓        | ✓         | ✓          | ✓     |
| See a container registry                               |       | ✓        | ✓         | ✓          | ✓     |
| Pull [packages](packages/index.md)                     |       | ✓        | ✓         | ✓          | ✓     |
| Publish [packages](packages/index.md)                  |       |          | ✓         | ✓          | ✓     |
| View metrics dashboard annotations                     |       | ✓        | ✓         | ✓          | ✓     |
| Create project in group                                |       |          | ✓ (3)(5)  | ✓ (3)      | ✓ (3) |
| Share (invite) groups with groups                      |       |          |           |            | ✓     |
| Create/edit/delete group milestones                    |       |          | ✓         | ✓          | ✓     |
| Create/edit/delete iterations                          |       |          | ✓         | ✓          | ✓     |
| Enable/disable a dependency proxy                      |       |          | ✓         | ✓          | ✓     |
| Create and edit group wiki pages **(PREMIUM)**         |       |          | ✓         | ✓          | ✓     |
| Use security dashboard **(ULTIMATE)**                  |       |          | ✓         | ✓          | ✓     |
| Create/edit/delete metrics dashboard annotations       |       |          | ✓         | ✓          | ✓     |
| View/manage group-level Kubernetes cluster             |       |          |           | ✓          | ✓     |
| Create subgroup                                        |       |          |           | ✓ (1)      | ✓     |
| Delete group wiki pages **(PREMIUM)**                  |       |          |           | ✓          | ✓     |
| Edit epic comments (posted by any user) **(ULTIMATE)** |       |          |           | ✓ (2)      | ✓ (2) |
| Edit group settings                                    |       |          |           |            | ✓     |
| Manage group level CI/CD variables                     |       |          |           |            | ✓     |
| List group deploy tokens                               |       |          |           | ✓          | ✓     |
| Create/Delete group deploy tokens                      |       |          |           |            | ✓     |
| Manage group members                                   |       |          |           |            | ✓     |
| Delete group                                           |       |          |           |            | ✓     |
| Delete group epic **(PREMIUM)**                        |       |          |           |            | ✓     |
| Edit SAML SSO Billing **(PREMIUM SAAS)**               | ✓     | ✓        | ✓         | ✓          | ✓ (4) |
| View group Audit Events                                |       |          | ✓ (7)     | ✓ (7)      | ✓     |
| Disable notification emails                            |       |          |           |            | ✓     |
| View Contribution analytics                            | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Group DevOps Adoption **(ULTIMATE)**              |       | ✓        | ✓         | ✓          | ✓     |
| View Insights **(ULTIMATE)**                           | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Issue analytics **(PREMIUM)**                     | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Productivity analytics **(PREMIUM)**              |       | ✓        | ✓         | ✓          | ✓     |
| View Value Stream analytics                            | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Billing **(FREE SAAS)**                           |       |          |           |            | ✓ (4) |
| View Usage Quotas **(FREE SAAS)**                      |       |          |           |            | ✓ (4) |
| Manage [group push rules](group/index.md#group-push-rules) **(PREMIUM)** |         |            |             | ✓        | ✓      |
| View 2FA status of members                             |       |          |           |            | ✓     |
| Filter members by 2FA status                           |       |          |           |            | ✓     |
| Administer project compliance frameworks               |       |          |           |            | ✓     |

1. Groups can be set to [allow either Owners or Owners and
  Maintainers to create subgroups](group/subgroups/index.md#creating-a-subgroup)
1. Introduced in GitLab 12.2.
1. Default project creation role can be changed at:
   - The [instance level](admin_area/settings/visibility_and_access_controls.md#default-project-creation-protection).
   - The [group level](group/index.md#specify-who-can-add-projects-to-a-group).
1. Does not apply to subgroups.
1. Developers can push commits to the default branch of a new project only if the [default branch protection](group/index.md#change-the-default-branch-protection-of-a-group) is set to "Partially protected" or "Not protected".
1. In addition, if your group is public or internal, all users who can see the group can also see group wiki pages.
1. Users can only view events based on their individual actions.

### Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent group(s). This model allows access to
nested groups if you have membership in one of its parents.

To learn more, read through the documentation on
[subgroups memberships](group/subgroups/index.md#membership).

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
[project's visibility and permissions settings](project/settings/index.md#sharing-and-permissions)
as well as the permission level of the user.

NOTE:
External users still count towards a license seat.

An administrator can flag a user as external by either of the following methods:

- [Through the API](../api/users.md#user-modification).
- Using the GitLab UI:
  1. On the top bar, select **Menu >** **{admin}** **Admin**.
  1. On the left sidebar, select **Overview > Users** to create a new user or edit an existing one.
     There, you can find the option to flag the user as external.

Additionally users can be set as external users using [SAML groups](../integration/saml.md#external-groups)
and [LDAP groups](../administration/auth/ldap/index.md#external-groups).

### Setting new users to external

By default, new users are not set as external users. This behavior can be changed
by an administrator:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
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
  NOT including `.ext@domain.com` as internal.

WARNING:
Be aware that this regex could lead to a
[regular expression denial of service (ReDoS) attack](https://en.wikipedia.org/wiki/ReDoS).

## Free Guest users **(ULTIMATE)**

When a user is given Guest permissions on a project, group, or both, and holds no
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
To prevent a guest user from creating projects, as an admin, you can edit the
user's profile to mark the user as [external](#external-users).
Beware though that even if a user is external, if they already have Reporter or
higher permissions in any project or group, they are **not** counted as a
free guest user.

## Auditor users **(PREMIUM SELF)**

>[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/998) in [GitLab Premium](https://about.gitlab.com/pricing/) 8.17.

Auditor users are given read-only access to all projects, groups, and other
resources on the GitLab instance.

An Auditor user should be able to access all projects and groups of a GitLab instance
with the permissions described on the documentation on [auditor users permissions](../administration/auditor_users.md#permissions-and-restrictions-of-an-auditor-user).

[Read more about Auditor users.](../administration/auditor_users.md)

## Users with minimal access **(PREMIUM)**

>[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40942) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.4.

Owners can add members with a "minimal access" role to a parent group. Such users don't
automatically have access to projects and subgroups underneath. To support such access, owners must explicitly add these "minimal access" users to the specific subgroups/projects.

Users with minimal access can list the group in the UI and through the API. However, they cannot see
details such as projects or subgroups. They do not have access to the group's page or list any of its subgroups or projects.

### Minimal access users take license seats

Users with even a "minimal access" role are counted against your number of license seats. This
requirement does not apply for [GitLab Ultimate](https://about.gitlab.com/pricing/)
subscriptions.

## Project features

Project features like wiki and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone
- Only team members: only team members will see even if your project is public or internal
- Everyone with access: everyone can see depending on your project visibility level
- Everyone: enabled for everyone (only available for GitLab Pages)

## GitLab CI/CD permissions

NOTE:
In GitLab 11.0, the Master role was renamed to Maintainer.

GitLab CI/CD permissions rely on the role the user has in GitLab. There are four
roles:

- Administrator
- Maintainer
- Developer
- Guest/Reporter

The Administrator role can perform any action on GitLab CI/CD in scope of the GitLab
instance and project.

| Action                                | Guest, Reporter | Developer   |Maintainer| Administrator |
|---------------------------------------|-----------------|-------------|----------|---------------|
| See commits and jobs                  | ✓               | ✓           | ✓        | ✓             |
| Retry or cancel job                   |                 | ✓           | ✓        | ✓             |
| Erase job artifacts and job logs      |                 | ✓ (*1*)     | ✓        | ✓             |
| Delete project                        |                 |             | ✓        | ✓             |
| Create project                        |                 |             | ✓        | ✓             |
| Change project configuration           |                 |             | ✓        | ✓             |
| Add specific runners                   |                 |             | ✓        | ✓             |
| Add shared runners                    |                 |             |          | ✓             |
| See events in the system              |                 |             |          | ✓             |
| Admin Area                            |                 |             |          | ✓             |

1. Only if the job was:
   - Triggered by the user
   - [In GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/35069) and later, run for a non-protected branch.

### Job permissions

NOTE:
In GitLab 11.0, the Master role was renamed to Maintainer.

This table shows granted privileges for jobs triggered by specific types of
users:

| Action                                      | Guest, Reporter | Developer   |Maintainer| Admin   |
|---------------------------------------------|-----------------|-------------|----------|---------|
| Run CI job                                  |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from current project   |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from public projects   |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from internal projects |                 | ✓ (*1*)     | ✓  (*1*) | ✓       |
| Clone source and LFS from private projects  |                 | ✓ (*2*)     | ✓  (*2*) | ✓ (*2*) |
| Pull container images from current project  |                 | ✓           | ✓        | ✓       |
| Pull container images from public projects  |                 | ✓           | ✓        | ✓       |
| Pull container images from internal projects|                 | ✓ (*1*)     | ✓  (*1*) | ✓       |
| Pull container images from private projects |                 | ✓ (*2*)     | ✓  (*2*) | ✓ (*2*) |
| Push container images to current project    |                 | ✓           | ✓        | ✓       |
| Push container images to other projects     |                 |             |          |         |
| Push source and LFS                         |                 |             |          |         |

1. Only if the user is not an external one
1. Only if the user is a member of the project

## Running pipelines on protected branches

The permission to merge or push to protected branches is used to define if a user can
run CI/CD pipelines and execute actions on jobs that are related to those branches.

See [Security on protected branches](../ci/pipelines/index.md#pipeline-security-on-protected-branches)
for details about the pipelines security model.

## Release permissions with protected tags

[The permission to create tags](project/protected_tags.md) is used to define if a user can
create, edit, and delete [Releases](project/releases/index.md).

See [Release permissions](project/releases/index.md#release-permissions)
for more information.

## LDAP users permissions

In GitLab 8.15 and later, LDAP user permissions can now be manually overridden by an admin user.
Read through the documentation on [LDAP users permissions](group/index.md#manage-group-memberships-via-ldap) to learn more.

## Project aliases

Project aliases can only be read, created and deleted by a GitLab administrator.
Read through the documentation on [Project aliases](../user/project/import/index.md#project-aliases) to learn more.
