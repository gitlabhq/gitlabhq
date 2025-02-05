---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create an audit report by using GraphQL
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can create an audit report for a specific subset of users by using:

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Use GraphiQL

You can use GraphiQL to query information about a subset of users.

1. Open GraphiQL:
   - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
   - For GitLab Self-Managed, use: `https://gitlab.example.com/-/graphql-explorer`
1. Copy the following text and paste it in the left window.
   This query searches for a subset of users by username. Alternately, you can use their
   [Global ID](../../development/api_graphql_styleguide.md#global-ids).

   ```graphql
   {
     users(usernames: ["user1", "user2", "user3"]) {
       pageInfo {
         endCursor
         startCursor
         hasNextPage
       }
       nodes {
         id
         ...memberships
       }
     }
   }

   fragment membership on MemberInterface {
     createdAt
     updatedAt
     accessLevel {
       integerValue
       stringValue
     }
     createdBy {
       id
     }
   }

   fragment memberships on User {
     groupMemberships {
       nodes {
         ...membership
         group {
           id
           name
         }
       }
     }

     projectMemberships {
       nodes {
         ...membership
         project {
           id
           name
         }
       }
     }
   }
   ```

1. Select **Play**.

NOTE:
[The GraphQL API returns a GlobalID, rather than a standard ID](getting_started.md#queries-and-mutations).
It also expects a GlobalID as an input rather than a single integer.

This query returns the groups and projects that the user has been explicitly made a member of.

- Because GraphiQL uses the session token to authorize access to resources,
  the output is limited to the projects and groups accessible to the currently authenticated user.
- If you are signed in as an instance administrator, you have access to all resources.

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
