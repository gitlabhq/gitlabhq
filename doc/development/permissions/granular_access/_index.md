---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Granular Access
---

This section covers development guidelines for granular access control mechanisms in GitLab.

## Granular Personal Access Tokens

To reduce the security impact of compromised Personal Access Tokens (PATs), granular or fine-grained PATs allow users to create tokens with fine-grained permissions limited to specific organizational boundaries (groups, projects, user, or instance-level). This enables users to follow the principle of least privilege by granting tokens only the permissions they need.

Granular PATs allow fine-grained access control through granular scopes that consist of a boundary and specific resource permissions. When authenticating API requests with a granular PAT, GitLab validates that the token's permissions include access to the requested resource at the specified boundary level.

- [GraphQL implementation guide](graphql_implementation_guide.md): Step-by-step guide for adding granular PAT authorization to GraphQL queries and mutations.
- [REST API implementation guide](rest_api_implementation_guide.md): Step-by-step guide for adding granular PAT authorization to REST API endpoints.
- [GraphQL architecture](graphql_architecture.md): Detailed explanation of how the GraphQL granular token authorization system works internally.
- [Permission definitions](permission_definitions.md): How to create permission definition YAML files using the `bin/permission` command.
- [Assignable permissions](assignable_permissions.md): How to create assignable permission YAML files and maintain them.

## Job tokens

- [Job token permission development guidelines](job_tokens.md): Guidance on requirements and contribution guidelines for job token permissions.
