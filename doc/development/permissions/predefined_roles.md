---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Predefined system of user roles
---

## Instance

### User types

Each user can be one of the following types:

- Regular.
- External - access to groups and projects only if direct member.
- [Internal users](../../administration/internal_users.md) - system created.
- [Auditor](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/policies/ee/base_policy.rb#L9):
  - No access to projects or groups settings menu.
  - No access to **Admin** area.
  - Read-only access to everything else.
- [Administrator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/policies/base_policy.rb#L6) - read-write access.

See the [permissions page](../../user/permissions.md) for details on how each user type is used.

## Groups and Projects

### General permissions

Groups and projects can have the following visibility levels:

- public (`20`) - an entity is visible to everyone
- internal (`10`) - an entity is visible to authenticated users
- private (`0`) - an entity is visible only to the approved members of the entity

By default, subgroups can **not** have higher visibility levels.
For example, if you create a new private group, it cannot include a public subgroup.

The visibility level of a group can be changed only if all subgroups and
sub-projects have the same or lower visibility level. For example, a group can be set
to internal only if all subgroups and projects are internal or private.

WARNING:
If you migrate an existing group to a lower visibility level, that action does not migrate subgroups
in the same way. This is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22406).

Visibility levels can be found in the `Gitlab::VisibilityLevel` module.

### Feature specific permissions

Additionally, the following project features can have different visibility levels:

- Issues
- Repository
  - Merge request
  - Forks
  - Pipelines
- Analytics
- Requirements
- Security and compliance
- Wiki
- Snippets
- Pages
- Operations
- Metrics Dashboard

These features can be set to "Everyone with Access" or "Only Project Members".
They make sense only for public or internal projects because private projects
can be accessed only by project members by default.

### Members

Users can be members of multiple groups and projects. The following access
levels are available (defined in the
[`Gitlab::Access`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/access.rb)
module):

- No access (`0`)
- [Minimal access](../../user/permissions.md#users-with-minimal-access) (`5`)
- Guest (`10`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)

If a user is a member of both a project and the project parent groups, the
highest permission is the applied access level for the project.

If a user is a member of a project, but not the parent groups, they
can still view the groups and their entities (like epics).

Project membership (where the group membership is already taken into account)
is stored in the `project_authorizations` table.

NOTE:
Projects in personal namespaces have a maximum role of Owner.

#### Guest role

A user with the Guest role in GitLab can view project plans, blockers and other
progress indicators. While unable to modify data they have not created, Guests
can contribute to a project by creating and linking project work items. Guests
can also view high-level project information such as:

- Analytics.
- Incident information.
- Issues and epics.
- Licenses.

For more information, see [project member permissions](../../user/permissions.md#project-members-permissions).

### Confidential issues

[Confidential issues](../../user/project/issues/confidential_issues.md) can be accessed
only by project members who are at least
reporters (they can't be accessed by guests). Additionally they can be accessed
by their authors and assignees.

### Licensed features

Some features can be accessed only if the user has the correct license plan.

## Permission dependencies

Feature policies can be quite complex and consist of multiple rules.
Quite often, one permission can be based on another.

Designing good permissions means reusing existing permissions as much as possible
and making access to features granular.

In the case of a complex resource, it should be broken into smaller pieces of information
and each piece should be granted a different permission.

A good example in this case is the _Merge Request widget_ and the _Security reports_.
Depending on the visibility level of the _Pipelines_, the _Security reports_ are either visible
in the widget or not. So, the _Merge Request widget_, the _Pipelines_, and the _Security reports_,
have separate permissions. Moreover, the permissions for the _Merge Request widget_
and the _Pipelines_ are dependencies of the _Security reports_.

### Permission dependencies of Secure features

Secure features have complex permissions since these features are integrated
into different features like Merge Requests and CI flow.

 Here is a list of some permission dependencies.

| Activity level | Resource | Locations |Permission dependency|
|----------------|----------|-----------|-----|
| View | License information | Dependency list, License Compliance | Can view repository |
| View | Dependency information | Dependency list, License Compliance | Can view repository |
| View | Vulnerabilities information | Dependency list | Can view security findings |
| View | Black/Whitelisted licenses for the project | License Compliance, merge request  | Can view repository |
| View | Security findings | merge request, CI job page, Pipeline security tab | Can read the project and CI jobs |
| View | Vulnerability feedback | merge request | Can read security findings |
| View | Dependency List page | Project | Can access Dependency information |
| View | License Compliance page | Project | Can access License information|
