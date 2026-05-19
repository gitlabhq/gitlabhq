---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Authentication and authorization glossary
description: Authentication, authorization, permissions, roles, and access control terminology.
---

This glossary defines terms related to authentication, authorization, and access control in GitLab.

## Identity and federation

External identity providers and protocols that establish and verify user identities across systems.
These terms describe how GitLab integrates with enterprise identity management systems to centralize
user authentication.

### Identity provider (IdP)

The service that manages your user identities, such as Okta or OneLogin.

### Service provider (SP)

An application that delegates authentication to an external identity provider. GitLab acts as a
service provider when configured for SAML or OIDC authentication.

### Single Sign-On (SSO)

An authentication method that allows users to access multiple applications with a single set of
credentials. With SSO, users authenticate once through an identity provider and gain access to
GitLab and other connected services without re-entering credentials.

### SAML

Security Assertion Markup Language, an XML-based protocol for exchanging authentication and
authorization data between identity providers and service providers. GitLab supports
[SAML authentication](../integration/saml.md) for enterprise single sign-on.

### LDAP

Lightweight Directory Access Protocol, a standard for accessing and maintaining directory
information services. GitLab integrates with [LDAP servers](../administration/auth/ldap/_index.md)
to authenticate users and synchronize account information.

### SCIM

System for Cross-domain Identity Management, a standard for automating user provisioning and
deprovisioning. GitLab supports [SCIM](../user/group/saml_sso/scim_setup.md) to synchronize user
lifecycle events from identity providers.

### OIDC (OpenID Connect)

An authentication layer built on OAuth 2.0 that provides identity verification. GitLab supports
[OIDC](../administration/auth/oidc.md) for authentication and acts as an OIDC provider for
external applications.

### OAuth

An authorization protocol for accessing GitLab resources on behalf of users without sharing
passwords. [OAuth](../integration/oauth_provider.md) supports third-party integrations and GitLab
as an identity provider.

### Assertion

A piece of information about a user identity, such as their name or role. Also known as a claim
or an attribute.

### Claim

Information about a user identity or attributes included in authentication tokens. Claims are used
in OAuth, OIDC, and JWT tokens to convey details like username, email, or group membership.

### Provisioning

The automated process of creating and configuring user accounts and access rights. You can use SCIM
or LDAP to synchronize users from external identity systems into GitLab.

### Assertion consumer service URL

The endpoint on GitLab where users are redirected after successfully authenticating with the
identity provider.

### Issuer

How GitLab identifies itself to an identity provider. Also known as a relying party trust
identifier.

### Certificate fingerprint

Confirms that SAML communications are secure by verifying that the server is signing
communications with the correct certificate. Also known as a certificate thumbprint.

## Authentication

Methods and credentials that verify a user identity before granting access to GitLab. Authentication
confirms who you are before granting access to the system. [Authentication methods](user_authentication.md)
include passwords, two-factor authentication, SSH keys, personal access tokens, and integration
with external identity providers.

### Passkey

A passwordless authentication method using cryptographic credentials stored on devices.
[Passkeys](passkeys.md) provide phishing-resistant authentication using biometrics or device PINs.

### Two-factor authentication (2FA)

An additional security layer that requires users to provide a second form of authentication
beyond their password. GitLab supports various [2FA methods](../user/profile/account/two_factor_authentication.md),
including authenticator apps and recovery codes.

### Session

A temporary authenticated state that persists after a user signs in to GitLab. Sessions persist
across requests until the session expires or is terminated.

### SSH keys

Cryptographic keys used for secure authentication when accessing Git repositories. [SSH keys](../user/ssh.md)
provide a secure alternative to password-based authentication for Git operations.

### Personal access token

A token that acts as an alternative to passwords for authentication when using the GitLab API
or Git over HTTPS. [Personal access tokens](../user/profile/personal_access_tokens.md) have defined
scopes that limit what actions they can perform.

### Group access token

A token scoped to a specific group for automated tasks in that group and any subgroups.
[Group access tokens](../user/group/settings/group_access_tokens.md) inherit the group permissions
and support API access and Git operations.

### Project access token

A token scoped to a specific project for automated tasks in that project.
[Project access tokens](../user/project/settings/project_access_tokens.md) are commonly used for
CI/CD pipelines and integrations that need project-specific access.

### Deploy token

A token with limited scopes for deployment automation.
[Deploy tokens](../user/project/deploy_tokens/_index.md) provide read-only or write access to
repositories and package registries without requiring a user account.

### JWT (JSON Web Token)

A compact token format for securely transmitting information between parties. GitLab uses JWTs for
CI/CD job authentication, OAuth flows, and service-to-service communication.

### Impersonation

An administrative capability for authorized users to temporarily act as another user.
[Impersonation](../api/rest/authentication.md#impersonation-tokens) is sometimes used to troubleshoot
user-specific issues.

## User and account management

Account types and user categories that define different access levels and capabilities in GitLab.
These terms describe the various kinds of accounts that can interact with the system.

### User account

An individual account that represents a person accessing GitLab. User accounts can be assigned
various roles across different groups and projects.

### User types

The type assigned to a user account that implicitly grants a set of permissible actions. Types
include Regular, Auditor, and Administrator. Types are different from roles and permissions.

### Administrator users

A user type with the highest level of system access. Users with administrator access can configure
instance-wide settings, manage other users, and perform administrative tasks across all groups
and projects.

### Auditor users

A special user type with read-only access to all groups, projects, and administrative functions.
[Auditor users](../administration/auditor_users.md) cannot make changes but can view content for
compliance and security purposes.

### External users

Users designated as external to your organization who have restricted access to internal projects
and groups. [External users](../administration/external_users.md) can only access projects where
they have a direct membership.

### Service accounts

Non-human user accounts designed to perform automated actions, access data, or run scheduled
processes. [Service accounts](../user/profile/service_accounts.md) are commonly used in pipelines
or third-party integrations.

## Authorization and access control

Frameworks and processes that determine what authenticated users can do in GitLab. Authorization
evaluates permissions based on user identity, roles, and resource ownership.

### Access control

The practice of restricting access to resources based on authentication (verifying who a user is)
and authorization (determining what a user can do).

### Authorization

The process of determining what actions an authenticated user can perform in GitLab. Authorization
is based on the assigned user roles, permissions, and membership in groups and projects.

### RBAC (Role-Based Access Control)

An access control model where permissions are assigned through roles rather than directly to users.
In GitLab, users receive permissions based on their assigned role in a group or project.

### Policy

A set of authorization rules that determine what actions principals can perform on resources.
GitLab enforces access control decisions using the
[Declarative Policy framework](../development/policies.md).

## Permissions and roles

Building blocks that define what actions users can perform on resources. Permissions combine into
roles, which are assigned to users to grant specific capabilities.

### Permission

The [specific actions](../user/permissions.md) a user can perform on GitLab resources, like
creating issues, pushing code, or managing project settings.

### Roles

Sets of one or more permissions assigned to a user that define the actions they can perform in
groups and projects. Roles include both default roles and custom roles.

### Default roles

[Predefined roles](../user/permissions.md) available in every GitLab instance. Each role includes a
specific set of permissions. The following default roles are available:

- Minimal Access
- Guest
- Planner
- Reporter
- Security Manager
- Developer
- Maintainer
- Owner

### Custom roles

Roles that you create for your GitLab instance to meet your organizational needs. Each
[custom role](../user/custom_roles/_index.md) extends a default role with additional permissions.

### Scopes

The permissions available to a token or OAuth application at a specific organizational level.
GitLab uses scopes to determine the access granted to personal access tokens, group access tokens,
project access tokens, and OAuth applications.

## Organizational structure

Hierarchical containers and relationships that organize resources and control access. These
structures determine how permissions flow through groups, projects, and namespaces.

### Namespace

A container that organizes groups and projects in a hierarchical structure. Namespaces determine
resource paths and permission inheritance. Each user has a personal namespace, and groups provide
shared namespaces for teams.

### Group

A collection of related projects and users that enables efficient organization and permission
management. Groups can contain subgroups and inherit permissions from parent groups.

### Member

A user who has been granted access to a specific group or project. Members have an assigned role
that determines their permissions in that resource.

### Membership

The association between a user and a specific group or project that defines their access rights
in that resource. Users can have different memberships and roles across multiple groups and
projects.

### Boundaries

The organizational levels where permissions and policies can be applied:

- Instance: Applies to the entire GitLab instance.
- Group: Applies to a specific group, and any subgroups or projects.
- Project: Applies only to a single project.
- User: Applies to actions performed by or on behalf of a specific user.

### Inheritance

The automatic flow of permissions from parent groups to child groups and projects. Inheritance
simplifies access management by applying permissions granted at a higher level to all nested
subgroups and projects.

### Visibility

[Settings](../user/public_access.md) that control who can view and access your content:

- Public: Visible to everyone, including users without GitLab accounts.
- Internal: Visible to all authenticated GitLab users.
- Private: Visible to members only.
