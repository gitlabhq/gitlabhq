---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Granular token authorization principles
---

Follow these rules when you add granular token authorization to an endpoint. For the syntax, see the
[REST API implementation guide](rest_api_implementation_guide.md) and the
[GraphQL implementation guide](graphql_implementation_guide.md).

## The token authorizes the API call

A granular token check applies to the resource named in the request path.

An operation might touch other resources too. The token check does not apply to those. The user
permission check handles them, because the request runs as the token owner.

For example, an issue move also touches the target project, but the token only authorizes the call
on the project in the request path.
