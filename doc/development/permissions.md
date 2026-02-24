---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Permission development guidelines
---

There are multiple types of permissions across GitLab, and when implementing
anything that deals with permissions, all of them should be considered.

As a pre-requisite, familiarize yourself with our [glossary](../auth/auth_glossary.md) first.

For more information, see:

- [Authorization](permissions/authorizations.md): Guidance on where to check permissions.
- [Custom roles](permissions/custom_roles.md): Guidance on how to work on custom role, how to introduce a new ability for custom roles, how to refactor permissions.
- [`DeclarativePolicy` framework](policies.md): Introduction to `DeclarativePolicy` framework used for authorization.
- [Granular access](permissions/granular_access/_index.md): Development guidelines for granular access control, including job tokens and granular Personal Access Tokens.
- [Permissions conventions](permissions/conventions.md): Guidance on how to name new permissions and what should be included in policy classes.
- [Predefined system of user roles](permissions/predefined_roles.md): General overview about predefined roles, user types, feature specific permissions, and permissions dependencies.
