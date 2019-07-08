---
description: 'Understand and explore the user permission levels in GitLab, and what features each of them grants you access to.'
---

# Permissions

Users have different abilities depending on the access level they have in a
particular group or project. If a user is both in a group's project and the
project itself, the highest permission level is used.

On public and internal projects the Guest role is not enforced. All users will
be able to create issues, leave comments, and clone or download the project code.

When a member leaves a team's project, all the assigned [Issues](project/issues/index.md) and [Merge Requests](project/merge_requests/index.md)
will be unassigned automatically.

GitLab [administrators](../administration/index.md) receive all permissions.

To add or import a user, you can follow the
[project members documentation](project/members/index.md).

For information on eligible approvers for Merge Requests, see
[Eligible approvers](project/merge_requests/merge_request_approvals.md#eligible-approvers).

## Principles behind permissions

See our [product handbook on permissions](https://about.gitlab.com/handbook/product#permissions-in-gitlab)

## Instance-wide user permissions

By default, users can create top-level groups and change their
usernames. A GitLab administrator can configure the GitLab instance to
[modify this behavior](../administration/user_settings.md).

## Project members permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

The following table depicts the various user permission levels in a project.

| Action                                            | Guest   | Reporter   | Developer   |Maintainer| Owner  |
|---------------------------------------------------|---------|------------|-------------|----------|--------|
| Download project                                  | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| Leave comments                                    | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View Insights charts **(ULTIMATE)**               | ✓       | ✓          | ✓           | ✓        | ✓      |
| View approved/blacklisted licenses **(ULTIMATE)** | ✓       | ✓          | ✓           | ✓        | ✓      |
| View license management reports **(ULTIMATE)**    | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View Security reports **(ULTIMATE)**              | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View [Design Management](project/issues/design_management.md) pages **(PREMIUM)** | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View project code                                 | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| Pull project code                                 | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View GitLab Pages protected by [access control](project/pages/introduction.md#gitlab-pages-access-control-core-only) | ✓       | ✓          | ✓           | ✓        | ✓      |
| View wiki pages                                   | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| See a list of jobs                                | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| See a job log                                     | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| Download and browse job artifacts                 | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| Create new issue                                  | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| See related issues                                | ✓       | ✓          | ✓           | ✓        | ✓      |
| Create confidential issue                         | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View confidential issues                          | (*2*)   | ✓          | ✓           | ✓        | ✓      |
| Assign issues                                     |         | ✓          | ✓           | ✓        | ✓      |
| Label issues                                      |         | ✓          | ✓           | ✓        | ✓      |
| Lock issue threads                                |         | ✓          | ✓           | ✓        | ✓      |
| Manage issue tracker                              |         | ✓          | ✓           | ✓        | ✓      |
| Manage related issues **(STARTER)**               |         | ✓          | ✓           | ✓        | ✓      |
| Create issue from vulnerability **(ULTIMATE)**    |         | ✓          | ✓           | ✓        | ✓      |
| Manage labels                                     |         | ✓          | ✓           | ✓        | ✓      |
| Create code snippets                              |         | ✓          | ✓           | ✓        | ✓      |
| See a commit status                               |         | ✓          | ✓           | ✓        | ✓      |
| See a container registry                          |         | ✓          | ✓           | ✓        | ✓      |
| See environments                                  |         | ✓          | ✓           | ✓        | ✓      |
| See a list of merge requests                      |         | ✓          | ✓           | ✓        | ✓      |
| View project statistics                           |         | ✓          | ✓           | ✓        | ✓      |
| View Error Tracking list                          |         | ✓          | ✓           | ✓        | ✓      |
| Pull from [Maven repository](project/packages/maven_repository.md) or [NPM registry](project/packages/npm_registry.md) **(PREMIUM)** |         | ✓          | ✓           | ✓        | ✓      |
| Publish to [Maven repository](project/packages/maven_repository.md) or [NPM registry](project/packages/npm_registry.md) **(PREMIUM)** |         |            | ✓           | ✓        | ✓      ||
| Upload [Design Management](project/issues/design_management.md) files **(PREMIUM)** |         |            | ✓           | ✓        | ✓      |
| Create new branches                               |         |            | ✓           | ✓        | ✓      |
| Push to non-protected branches                    |         |            | ✓           | ✓        | ✓      |
| Force push to non-protected branches              |         |            | ✓           | ✓        | ✓      |
| Remove non-protected branches                     |         |            | ✓           | ✓        | ✓      |
| Create new merge request                          |         |            | ✓           | ✓        | ✓      |
| Assign merge requests                             |         |            | ✓           | ✓        | ✓      |
| Label merge requests                              |         |            | ✓           | ✓        | ✓      |
| Lock merge request threads                        |         |            | ✓           | ✓        | ✓      |
| Manage/Accept merge requests                      |         |            | ✓           | ✓        | ✓      |
| Create new environments                           |         |            | ✓           | ✓        | ✓      |
| Stop environments                                 |         |            | ✓           | ✓        | ✓      |
| Add tags                                          |         |            | ✓           | ✓        | ✓      |
| Cancel and retry jobs                             |         |            | ✓           | ✓        | ✓      |
| Create or update commit status                    |         |            | ✓           | ✓        | ✓      |
| Update a container registry                       |         |            | ✓           | ✓        | ✓      |
| Remove a container registry image                 |         |            | ✓           | ✓        | ✓      |
| Create/edit/delete project milestones             |         |            | ✓           | ✓        | ✓      |
| Use security dashboard **(ULTIMATE)**             |         |            | ✓           | ✓        | ✓      |
| Dismiss vulnerability **(ULTIMATE)**              |         |            | ✓           | ✓        | ✓      |
| Apply code change suggestions                     |         |            | ✓           | ✓        | ✓      |
| Create and edit wiki pages                        |         |            | ✓           | ✓        | ✓      |
| Rewrite/remove Git tags                           |         |            | ✓           | ✓        | ✓      |
| Use environment terminals                         |         |            |             | ✓        | ✓      |
| Run Web IDE's Interactive Web Terminals **(ULTIMATE ONLY)** |     |      |             | ✓        | ✓      |
| Add new team members                              |         |            |             | ✓        | ✓      |
| Enable/disable branch protection                  |         |            |             | ✓        | ✓      |
| Push to protected branches                        |         |            |             | ✓        | ✓      |
| Turn on/off protected branch push for devs        |         |            |             | ✓        | ✓      |
| Enable/disable tag protections                    |         |            |             | ✓        | ✓      |
| Edit project                                      |         |            |             | ✓        | ✓      |
| Add deploy keys to project                        |         |            |             | ✓        | ✓      |
| Configure project hooks                           |         |            |             | ✓        | ✓      |
| Manage Runners                                    |         |            |             | ✓        | ✓      |
| Manage job triggers                               |         |            |             | ✓        | ✓      |
| Manage variables                                  |         |            |             | ✓        | ✓      |
| Manage GitLab Pages                               |         |            |             | ✓        | ✓      |
| Manage GitLab Pages domains and certificates      |         |            |             | ✓        | ✓      |
| Remove GitLab Pages                               |         |            |             | ✓        | ✓      |
| Manage clusters                                   |         |            |             | ✓        | ✓      |
| Manage license policy **(ULTIMATE)**              |         |            |             | ✓        | ✓      |
| Edit comments (posted by any user)                |         |            |             | ✓        | ✓      |
| Manage Error Tracking                             |         |            |             | ✓        | ✓      |
| Delete wiki pages                                 |         |            |             | ✓        | ✓      |
| View project Audit Events                         |         |            |             | ✓        | ✓      |
| Switch visibility level                           |         |            |             |          | ✓      |
| Transfer project to another namespace             |         |            |             |          | ✓      |
| Remove project                                    |         |            |             |          | ✓      |
| Delete issues                                     |         |            |             |          | ✓      |
| Force push to protected branches (*4*)            |         |            |             |          |        |
| Remove protected branches (*4*)                   |         |            |             |          |        |

- (*1*): All users are able to perform this action on public and internal projects, but not private projects.
- (*2*): Guest users can only view the confidential issues they created themselves
- (*3*): If **Public pipelines** is enabled in **Project Settings > CI/CD**
- (*4*): Not allowed for Guest, Reporter, Developer, Maintainer, or Owner

## Project features permissions

### Wiki and issues

Project features like wiki and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone
- Only team members: only team members will see even if your project is public or internal
- Everyone with access: everyone can see depending on your project visibility level
- Everyone: enabled for everyone (only available for GitLab Pages)

### Protected branches

To prevent people from messing with history or pushing code without
review, we've created protected branches. Read through the documentation on
[protected branches](project/protected_branches.md)
to learn more.

Additionally, you can allow or forbid users with Maintainer and/or
Developer permissions to push to a protected branch. Read through the documentation on
[Allowed to Merge and Allowed to Push settings](project/protected_branches.md#using-the-allowed-to-merge-and-allowed-to-push-settings)
to learn more.

### Cycle Analytics permissions

Find the current permissions on the Cycle Analytics dashboard on
the [documentation on Cycle Analytics permissions](project/cycle_analytics.md#permissions).

### Issue Board permissions

Developers and users with higher permission level can use all
the functionality of the Issue Board, that is create/delete lists
and drag issues around. Read though the
[documentation on Issue Boards permissions](project/issue_board.md#permissions)
to learn more.

### File Locking permissions **(PREMIUM)**

The user that locks a file or directory is the only one that can edit and push their changes back to the repository where the locked objects are located.

Read through the documentation on [permissions for File Locking](project/file_lock.md#permissions-on-file-locking) to learn more.

### Confidential Issues permissions

Confidential issues can be accessed by reporters and higher permission levels,
as well as by guest users that create a confidential issue. To learn more,
read through the documentation on [permissions and access to confidential issues](project/issues/confidential_issues.md#permissions-and-access-to-confidential-issues).

### Releases permissions

[Project Releases](project/releases/index.md) can be read by project
members with Reporter, Developer, Maintainer, and Owner permissions.
Guest users can access Release pages for downloading assets but
are not allowed to download the source code nor see repository
information such as tags and commits.

Releases can be created, updated, or deleted via [Releases APIs](../api/releases/index.md)
by project Developers, Maintainers, and Owners.

## Group members permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

Any user can remove themselves from a group, unless they are the last Owner of
the group. The following table depicts the various user permission levels in a
group.

| Action                                          | Guest | Reporter | Developer | Maintainer | Owner |
|-------------------------------------------------|-------|----------|-----------|------------|-------|
| Browse group                                    | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Insights charts **(ULTIMATE)**             | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group epic **(ULTIMATE)**                  | ✓     | ✓        | ✓         | ✓          | ✓     |
| Create/edit group epic **(ULTIMATE)**           |       | ✓        | ✓         | ✓          | ✓     |
| Manage group labels                             |       | ✓        | ✓         | ✓          | ✓     |
| Create project in group                         |       |          | ✓         | ✓          | ✓     |
| Create/edit/delete group milestones             |       |          | ✓         | ✓          | ✓     |
| Enable/disable a dependency proxy **(PREMIUM)** |       |          | ✓         | ✓          | ✓     |
| Edit group                                      |       |          |           |            | ✓     |
| Create subgroup                                 |       |          |           |            | ✓     |
| Manage group members                            |       |          |           |            | ✓     |
| Remove group                                    |       |          |           |            | ✓     |
| Delete group epic **(ULTIMATE)**                |       |          |           |            | ✓     |
| View group Audit Events                         |       |          |           |            | ✓     |

### Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent group. This model allows access to
nested groups if you have membership in one of its parents.

To learn more, read through the documentation on
[subgroups memberships](group/subgroups/index.md#membership).

## External users permissions

In cases where it is desired that a user has access only to some internal or
private projects, there is the option of creating **External Users**. This
feature may be useful when for example a contractor is working on a given
project and should only have access to that project.

External users can only access projects to which they are explicitly granted
access, thus hiding all other internal or private ones from them. Access can be
granted by adding the user as member to the project or group.

They will, like usual users, receive a role in the project or group with all
the abilities that are mentioned in the table above. They cannot however create
groups or projects, and they have the same access as logged out users in all
other cases.

An administrator can flag a user as external [through the API](../api/users.md)
or by checking the checkbox on the admin panel. As an administrator, navigate
to **Admin > Users** to create a new user or edit an existing one. There, you
will find the option to flag the user as external.

By default new users are not set as external users. This behavior can be changed
by an administrator under **Admin > Application Settings**.

### Default internal users

The "Internal users" field allows specifying an e-mail address regex pattern to identify default internal users.

New users whose email address matches the regex pattern will be set to internal by default rather than an external collaborator.

The regex pattern format is Ruby, but it needs to be convertible to JavaScript, and the ignore case flag will be set, e.g. "/regex pattern/i".

Here are some examples:

- Use `\.internal@domain\.com$` to mark email addresses ending with ".internal@domain.com" internal.
- Use `^(?:(?!\.ext@domain\.com).)*$\r?` to mark users with email addresses NOT including .ext@domain.com internal.

Please be aware that this regex could lead to a DOS attack, [see](https://en.wikipedia.org/wiki/ReDoS?) ReDos on Wikipedia.

## Auditor users **(PREMIUM ONLY)**

>[Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/998) in [GitLab Premium](https://about.gitlab.com/pricing/) 8.17.

Auditor users are given read-only access to all projects, groups, and other
resources on the GitLab instance.

An Auditor user should be able to access all projects and groups of a GitLab instance
with the permissions described on the documentation on [auditor users permissions](../administration/auditor_users.md#permissions-and-restrictions-of-an-auditor-user).

[Read more about Auditor users.](../administration/auditor_users.md)

## Project features

Project features like wiki and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone
- Only team members: only team members will see even if your project is public or internal
- Everyone with access: everyone can see depending on your project visibility level
- Everyone: enabled for everyone (only available for GitLab Pages)

## GitLab CI/CD permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

GitLab CI/CD permissions rely on the role the user has in GitLab. There are four
permission levels in total:

- admin
- maintainer
- developer
- guest/reporter

The admin user can perform any action on GitLab CI/CD in scope of the GitLab
instance and project. In addition, all admins can use the admin interface under
`/admin/runners`.

| Action                                | Guest, Reporter | Developer   |Maintainer| Admin  |
|---------------------------------------|-----------------|-------------|----------|--------|
| See commits and jobs                  | ✓               | ✓           | ✓        | ✓      |
| Retry or cancel job                   |                 | ✓           | ✓        | ✓      |
| Erase job artifacts and trace         |                 | ✓ (*1*)     | ✓        | ✓      |
| Remove project                        |                 |             | ✓        | ✓      |
| Create project                        |                 |             | ✓        | ✓      |
| Change project configuration          |                 |             | ✓        | ✓      |
| Add specific runners                  |                 |             | ✓        | ✓      |
| Add shared runners                    |                 |             |          | ✓      |
| See events in the system              |                 |             |          | ✓      |
| Admin interface                       |                 |             |          | ✓      |

- *1*: Only if the job was triggered by the user

### Job permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

>**Note:**
GitLab 8.12 has a completely redesigned job permissions system.
Read all about the [new model and its implications](project/new_ci_build_permissions_model.md).

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

- *1*: Only if the user is not an external one
- *2*: Only if the user is a member of the project

### New CI job permissions model

GitLab 8.12 has a completely redesigned job permissions system. To learn more,
read through the documentation on the [new CI/CD permissions model](project/new_ci_build_permissions_model.md#new-ci-job-permissions-model).

## Running pipelines on protected branches

The permission to merge or push to protected branches is used to define if a user can
run CI/CD pipelines and execute actions on jobs that are related to those branches.

See [Security on protected branches](../ci/pipelines.md#security-on-protected-branches)
for details about the pipelines security model.

## LDAP users permissions

Since GitLab 8.15, LDAP user permissions can now be manually overridden by an admin user.
Read through the documentation on [LDAP users permissions](../administration/auth/how_to_configure_ldap_gitlab_ee/index.html) to learn more.

## Project aliases

Project aliases can only be read, created and deleted by a GitLab administrator.
Read through the documentation on [Project aliases](../user/project/index.md#project-aliases-premium-only) to learn more.
