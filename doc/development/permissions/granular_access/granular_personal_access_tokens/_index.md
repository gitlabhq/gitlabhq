---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Granular Personal Access Tokens
---

To reduce the security impact of compromised Personal Access Tokens (PATs), granular or fine-grained PATs allow users to create tokens with fine-grained permissions limited to specific organizational boundaries (groups, projects, user, or instance-level). This enables users to follow the principle of least privilege by granting tokens only the permissions they need.

Granular PATs allow fine-grained access control through granular scopes that consist of a boundary and specific resource permissions. When authenticating API requests with a granular PAT, GitLab validates that the token's permissions include access to the requested resource at the specified boundary level.

- [REST API implementation guide](rest_api_implementation_guide.md): Step-by-step guide for adding granular PAT authorization to REST API endpoints.
- [GraphQL granular token authorization](graphql_granular_token_authorization.md): Step-by-step guide for adding granular PAT authorization to GraphQL queries and mutations.
