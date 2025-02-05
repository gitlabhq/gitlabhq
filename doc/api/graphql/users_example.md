---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Query users by using GraphQL
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can query a subset of users in a GitLab instance by using:

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Use GraphiQL

1. Open GraphiQL:
   - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
   - For GitLab Self-Managed, use: `https://gitlab.example.com/-/graphql-explorer`
1. Copy the following text and paste it in the left window.
   This query looks for a subset of users in a GitLab instance by username.
   Alternately, you can use their [Global ID](../../development/api_graphql_styleguide.md#global-ids).

   ```graphql
    {
      users(usernames: ["user1", "user3", "user4"]) {
        pageInfo {
          endCursor
          startCursor
          hasNextPage
        }
        nodes {
          id
          username,
          publicEmail
          location
          webUrl
          userPermissions {
            createSnippet
          }
        }
      }
    }
   ```

1. Select **Play**.

NOTE:
[The GraphQL API returns a GlobalID, rather than a standard ID](getting_started.md#queries-and-mutations).
It also expects a GlobalID as an input rather than a single integer.

This query returns the specified information for the three users with the listed username.

- Because GraphiQL uses the session token to authorize access to resources,
  the output is limited to the projects and groups accessible to the currently authenticated user.
- If you are signed in as an instance administrator, you have access to all resources.

### Show administrators only

If you are signed in as an administrator, you can show the matching administrators
on the instance by adding the `admins: true` parameter to the query.
Change the second line to:

```graphql
  users(usernames: ["user1", "user3", "user4"], admins: true) {
    ...
  }
```

Or you can get all of the administrators:

```graphql
  users(admins: true) {
    ...
  }
```

## Pagination and graph nodes

The query includes:

- [`pageInfo`](#pageinfo)
- [`nodes`](#nodes)

### `pageInfo`

This contains the data needed to implement pagination. GitLab uses cursor-based
[pagination](getting_started.md#pagination). For more information, see
[Pagination](https://graphql.org/learn/pagination/) in the GraphQL documentation.

### `nodes`

In a GraphQL query, `nodes` represents a collection of [`nodes` on a graph](https://en.wikipedia.org/wiki/Vertex_(graph_theory)).
In this case, the collection of nodes is a collection of `User` objects. For each one,
the output includes:

- The user's `id`.
- The `membership` fragment, which represents project or group membership that belongs
  to that user. Fragments are indicated by the `...memberships` notation.

## Related topics

- [GraphQL API reference](reference/_index.md)
- [GraphQL-specific entities, like fragments and interfaces](https://graphql.org/learn/)
