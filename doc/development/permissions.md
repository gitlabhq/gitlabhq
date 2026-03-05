---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Authorization development guidelines
---

Authorization controls what users are allowed to do in GitLab.
When implementing any feature that reads, creates, modifies, or deletes data,
you must consider how access is controlled and enforced consistently across all
entry points.

## Reviews

- [Adding a new permission](permissions/conventions.md): How to name new permissions and what to include in policy classes.
- [Authorization review guidelines](permissions/review_guidelines.md): A checklist for preparing a merge request that involve policy changes, permission definitions, and authorization logic for review.
- If you need [guidance on whether a new permission](permissions/conventions.md#introducing-new-permissions) is needed or which team to involve, contact the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authorization).

## Concepts

- [DeclarativePolicy framework](policies.md): Introduction to `DeclarativePolicy` framework used for authorization.
- [Default roles](permissions/predefined_roles.md): Overview of default roles, user types, and how abilities are assigned.
- [Custom roles](permissions/custom_roles.md): Guidance on how to work on custom role, how to introduce a new ability for custom roles, how to refactor permissions.
- [Roles and permissions matrix](../user/permissions.md): The full reference of what each role can do across GitLab features.
- [Glossary](../auth/auth_glossary.md): Definitions of key authentication and authorization terms used across GitLab.

## Where to check permissions

- [Where to check permissions](permissions/authorizations.md): Guidance on where to check permissions.
- [GraphQL authorization](graphql_guide/authorization.md): How to authorize types, resolvers, and fields in the GraphQL API.

## Token permissions

- [Job token guidelines](permissions/granular_access/job_tokens.md): Development guidelines for CI/CD job token permissions.
- [Granular Personal Access Tokens](permissions/granular_access/_index.md): Development guidelines for granular personal access tokens.

## Testing

- [Testing](permissions/testing_guidelines.md): Guidance for how to write specs for permission checks.
