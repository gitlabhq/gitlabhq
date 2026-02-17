---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Authentication and authorization glossary
description: Authentication, authorization, permissions, roles, and access control terminology.
---

This glossary defines terms related to authentication, authorization, and access control in GitLab.
Understanding these concepts helps you configure secure access and manage permissions effectively.

## Access control

The practice of restricting access to resources based on authentication (verifying the identity of users)
and authorization (determining what users can do).
Use access control to protect sensitive information and functionality.

## User account

An individual account that represents a person ([human user type](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/has_user_type.rb#L7)) accessing GitLab. User accounts can be assigned various roles across different groups and projects.

## Visibility

[Settings](../user/public_access.md) that control who can view and access your content:

- Public: Visible to everyone, including users without GitLab accounts
- Internal: Visible to all authenticated GitLab users
- Private: Restricted to members only

## User Types

The type you assign when you create a new user that implicitly grants a certain set of permissible actions. Types include Regular, Auditor, and Administrator. Types are different from roles and permissions.

## Administrator

A user type with the highest level of system access who can configure instance-wide settings, manage
other users, and perform administrative tasks across all groups and projects.

<!--For more information, see [administrator users](../auth/users_admin.md). -->
## Auditor

A special user type with read-only access to all groups, projects, and administrative functions.
Auditors cannot make changes but can view content for compliance and security purposes.

For more information, see [auditor users](../administration/auditor_users.md).

## External users

Users designated as external to your organization who have restricted access to internal projects
and groups. External users can only access projects where they have explicit membership.

For more information, see [external users](../administration/external_users.md).

## Authentication

The process of verifying a user's identity before granting access to GitLab. Authentication methods
include passwords, two-factor authentication, SSH keys, personal access tokens, and integration
with external identity providers.

For more information, see [user authentication](user_authentication.md).

## Service accounts

Non-human user accounts designed to perform automated actions, access data, or run scheduled
processes.

For more information, see [service accounts](../user/profile/service_accounts.md).

## SSH keys

Cryptographic keys used for secure authentication when accessing Git repositories. SSH keys
provide a secure alternative to password-based authentication for Git operations.

For more information, see [SSH keys](../user/ssh.md).

## Two-factor authentication (2FA)

An additional security layer that requires users to provide a second form of authentication
beyond their password. GitLab supports various 2FA methods including authenticator apps and
recovery codes.

For more information, see [two-factor authentication](../user/profile/account/two_factor_authentication.md).

## Group

A collection of related projects and users that enables efficient organization and permission
management. Groups can contain subgroups and inherit permissions from parent groups.

## Member

A user who has been granted access to a specific group or project. Members have an assigned role
that determines their permissions in that resource.

<!-- For more information, see [group and project membership](../auth/membership.md). -->
## Membership

The association between users and specific groups or projects that defines their access rights
in those resources. Users can have different memberships and roles across multiple groups
and projects.

## Authorization

The process of determining what actions an authenticated user can perform in GitLab.
Authorization is based on the user's assigned roles, permissions, and membership in groups
and projects.
Authorization decisions answer yes/no for a triplet of the form `(principal, permission, resource)` accounting for namespace membership and contextual data like attributes of the resource and/or actor. Internally, we use the [Declarative Policy framework](../development/policies.md) to implement authorization.

### Authorization Principal

Actors including human users, personal access tokens, composite identities, service accounts etc. that are used in an authorization triplet (mentioned above) to determine what action they can do a resource.

### Resource

Objects that you can manage or operate on in GitLab, including projects, groups, issues,
merge requests, snippets, pipelines, milestones etc.

### Feature Category

Resources belong to feature categories that are defined in our [monorepo](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/feature_categories.yml) to associate resources against feature domains owned by engineering teams within GitLab. 

## Permission

The specific actions a user can perform on GitLab resources like creating issues, pushing code, or managing project settings. These make up roles. 
Internally within GitLab engineering, they are called assignable permission groups and are defined as YAML definitions in our [monorepo](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/authz/permission_groups/assignable_permissions).

For more information, see [roles and permissions](../user/permissions.md).

### Raw permissions

The most atomic, granular permission that is not customer facing and are used to build up an assignable permission group (called "Permission" above). They are defined as YAML definitions in our [monorepo](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/authz/permissions).
Roles are built from assignable permission groups, which are built from raw permissions.

## Roles

Predefined (aka default) or custom sets of permissions assigned to users that determine what actions they can perform in groups and projects. Roles include both default roles and custom roles. Essentially, they are just containers of permissions.

For more information, see [roles and permissions](../user/permissions.md).

## Default roles

The predefined roles available in GitLab: Minimal Access, Guest, Planner, Reporter, Developer,
Maintainer, and Owner. Each role includes a specific set of permissions.

For more information, see [roles and permissions](../user/permissions.md).

## Custom roles

Customer-defined roles with specific permissions tailored to organizational needs. Use custom roles
to build on top of default roles (e.g. Guest, Reporter, Developer, Maintainer) and build your own access levels that don't match the default roles provided by GitLab. Permissions that are available to custom roles are defined as YAML definitions in our [monorepo](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/custom_abilities)

For more information, see [custom roles](../user/custom_roles/_index.md).

## Boundaries

The organizational levels where permissions and policies can be applied:

- Instance: Applies across the entire GitLab deployment
- Group: Applies to a specific group and its subgroups or projects
- Project: Applies only to a single project
- User: Applies to actions performed by or on behalf of a specific user

## Scopes

Scopes define what permissions are available to certain resources within a certain organizational level (boundary). It is fully qualified by resource permission and boundary. This is used to determine the access given to personal access tokens,
group access tokens, project access tokens, and OAuth applications.

## Inheritance

The automatic flow of permissions from parent groups to child groups and projects. Inheritance
simplifies access management by applying permissions granted at higher levels to all nested
content below.

## Personal access token

A token that acts as an alternative to passwords for authentication when using the GitLab API
or Git over HTTPS. Personal access tokens have defined scopes that limit what actions they
can perform.

For more information, see [personal access tokens](../user/profile/personal_access_tokens.md).
