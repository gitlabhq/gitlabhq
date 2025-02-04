---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Permission development guidelines
---

There are multiple types of permissions across GitLab, and when implementing
anything that deals with permissions, all of them should be considered. For more information, see:

- [Predefined roles system](permissions/predefined_roles.md): a general overview about predefined roles, user types, feature specific permissions or permissions dependencies.
- [`DeclarativePolicy` framework](policies.md): introduction into `DeclarativePolicy` framework we use for authorization.
- [Naming and conventions](permissions/conventions.md): guidance on how to name new permissions and what should be included in policy classes.
- [Authorizations](permissions/authorizations.md): guidance on where to check permissions.
- [Custom roles](permissions/custom_roles.md): guidance on how to work on custom role, how to introduce a new ability for custom roles, how to refactor permissions.
