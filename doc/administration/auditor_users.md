---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Auditor users **(PREMIUM SELF)**

Auditor users are given read-only access to all projects, groups, and other
resources on the GitLab instance.

## Overview

Auditor users are able to have both full access to their own resources
(including projects, groups, and snippets) and read-only access to _all_ other
resources, except the [Admin Area](../user/admin_area/index.md). These user
accounts are regular users who can be added to projects, create personal
snippets, and create milestones on their groups, while also having read-only
access to all projects on the server to which they haven't been explicitly
[given access](../user/permissions.md).

The `Auditor` access level is _not_ a read-only version of the `Admin` access level. Auditor users
can't access the project or group settings pages, or the Admin Area.

Assuming you have signed in as an Auditor user:

- For a project the Auditor is not member of, the Auditor should have
  read-only access. If the project is public or internal, they have the same
  access as users that aren't members of that project or group.
- For a project the Auditor owns, the Auditor should have full access to
  everything.
- For a project to which the Auditor is added as a member, the Auditor should
  have the same access as their given [permissions](../user/permissions.md).
  For example, if they were added as a Developer, they can push commits or
  comment on issues.
- The Auditor can't view the Admin Area, or perform any administration actions.

For more information about what an Auditor can or can't do, see the
[Permissions and restrictions of an Auditor user](#permissions-and-restrictions-of-an-auditor-user)
section.

## Use cases

The following use cases describe some situations where Auditor users could be
helpful:

- Your compliance department wants to run tests against the entire GitLab base
  to ensure users are complying with password, credit card, and other sensitive
  data policies. With Auditor users, this can be achieved very without having
  to give them user administration rights or using the API to add them to all projects.
- If particular users need visibility or access to most of all projects in
  your GitLab instance, instead of manually adding the user to all projects,
  you can create an Auditor user and then share the credentials with those users
  to which you want to grant access.

## Add an Auditor user

To create an Auditor user:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Create a new user or edit an existing one, and in the **Access** section
   select Auditor.
1. Select **Create user** or **Save changes** if you created a new user or
   edited an existing one respectively.

To revoke Auditor permissions from a user, make them a regular user by
following the previous steps.

Additionally users can be set as an Auditor using [SAML groups](../integration/saml.md#auditor-groups).

## Permissions and restrictions of an Auditor user

An Auditor user should be able to access all projects and groups of a GitLab
instance, with the following permissions and restrictions:

- Has read-only access to the API
- Can access projects that are:
  - Private
  - Public
  - Internal
- Can read all files in a repository
- Can read issues and MRs
- Can read project snippets
- Cannot be Administrator and Auditor at the same time
- Cannot access the Admin Area
- In a group or project they're not a member of:
  - Cannot access project settings
  - Cannot access group settings
  - Cannot commit to repository
  - Cannot create or comment on issues and MRs
  - Cannot create or modify files from the Web UI
  - Cannot merge a merge request
  - Cannot create project snippets
