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

## Access level

The permission level you assign when you create a new user. Access levels include Regular,
Auditor, and Administrator. Access levels are different from roles and permissions.

## Administrator

A user with the highest level of system access who can configure instance-wide settings, manage
other users, and perform administrative tasks across all groups and projects.

<!--For more information, see [administrator users](../auth/users_admin.md). -->
## Auditor

A special user type with read-only access to all groups, projects, and administrative functions.
Auditors cannot make changes but can view content for compliance and security purposes.

For more information, see [auditor users](../administration/auditor_users.md).

## Authentication

The process of verifying a user's identity before granting access to GitLab. Authentication methods
include passwords, two-factor authentication, SSH keys, personal access tokens, and integration
with external identity providers.

For more information, see [user authentication](user_authentication.md).

## Authorization

The process of determining what actions an authenticated user can perform in GitLab.
Authorization is based on the user's assigned roles, permissions, and membership in groups
and projects.

## Boundaries

The organizational levels where permissions and policies can be applied:

- Instance: Applies across the entire GitLab deployment
- Group: Applies to a specific group and its subgroups or projects
- Project: Applies only to a single project
- User: Applies to actions performed by or on behalf of a specific user

## Custom roles

User-defined roles with specific permissions tailored to organizational needs. Use custom roles
to create permission sets that don't match the default roles provided by GitLab.

For more information, see [custom roles](../user/custom_roles/_index.md).

## Default roles

The predefined roles available in GitLab: Minimal Access, Guest, Planner, Reporter, Developer,
Maintainer, and Owner. Each role includes a specific set of permissions.

For more information, see [roles and permissions](../user/permissions.md).

## External users

Users designated as external to your organization who have restricted access to internal projects
and groups. External users can only access projects where they have explicit membership.

For more information, see [external users](../administration/external_users.md).

## Group

A collection of related projects and users that enables efficient organization and permission
management. Groups can contain subgroups and inherit permissions from parent groups.

## Inheritance

The automatic flow of permissions from parent groups to child groups and projects. Inheritance
simplifies access management by applying permissions granted at higher levels to all nested
content below.

## Member

A user who has been granted access to a specific group or project. Members have an assigned role
that determines their permissions in that resource.

<!-- For more information, see [group and project membership](../auth/membership.md). -->
## Membership

The association between users and specific groups or projects that defines their access rights
in those resources. Users can have different memberships and roles across multiple groups
and projects.

## Permissions

The specific actions a user can perform on GitLab resources. Permissions are combined into roles
and include actions like creating issues, pushing code, or managing project settings.

For more information, see [roles and permissions](../user/permissions.md).

## Personal access token

A token that acts as an alternative to passwords for authentication when using the GitLab API
or Git over HTTPS. Personal access tokens have defined scopes that limit what actions they
can perform.

For more information, see [personal access tokens](../user/profile/personal_access_tokens.md).

## Resources

Objects that you can manage or operate on in GitLab, including projects, groups, issues,
merge requests, snippets, pipelines, and milestones.

## Roles

Predefined or custom sets of permissions assigned to users that determine what actions they can
perform in groups and projects. Roles include both default roles and custom roles.

For more information, see [roles and permissions](../user/permissions.md).

## Scopes

Broad boundaries that define what resources and permissions are available to personal access tokens,
group access tokens, project access tokens, and OAuth applications.

Scopes can include any combination of resources, permissions, or both, depending on the type of
token or where the scope is applied. For example, personal access tokens only include permissions,
while job tokens include both permissions and resources.

## Service accounts

Non-human user accounts designed to perform automated actions, access data, or run scheduled
processes. Service accounts typically use tokens for authentication instead of passwords.

## SSH keys

Cryptographic keys used for secure authentication when accessing Git repositories. SSH keys
provide a secure alternative to password-based authentication for Git operations.

For more information, see [SSH keys](../user/ssh.md).

## Two-factor authentication (2FA)

An additional security layer that requires users to provide a second form of authentication
beyond their password. GitLab supports various 2FA methods including authenticator apps and
recovery codes.

For more information, see [two-factor authentication](../user/profile/account/two_factor_authentication.md).

## User account

An individual account that represents a person accessing GitLab. User accounts have access levels
and can be assigned various roles across different groups and projects.

## Visibility

Settings that control who can view and access your content:

- Public: Visible to everyone, including users without GitLab accounts
- Internal: Visible to all authenticated GitLab users
- Private: Restricted to members only
