---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Get started with GitLab GraphQL API **(FREE)**

This guide demonstrates basic usage of the GitLab GraphQL API.

Read the [GraphQL API style guide](../../development/api_graphql_styleguide.md)
for implementation details aimed at developers who wish to work on developing
the API itself.

## Running examples

The examples documented here can be run using:

- The command line.
- GraphiQL.

### Command line

You can run GraphQL queries in a `curl` request on the command line on your
local computer. A GraphQL request can be made as a `POST` request to `/api/graphql`
with the query as the payload. You can authorize your request by generating a
[personal access token](../../user/profile/personal_access_tokens.md) to use as
a bearer token.

Example:

```shell
GRAPHQL_TOKEN=<your-token>
curl "https://gitlab.com/api/graphql" --header "Authorization: Bearer $GRAPHQL_TOKEN" \
     --header "Content-Type: application/json" --request POST \
     --data "{\"query\": \"query {currentUser {name}}\"}"
```

### GraphiQL

GraphiQL (pronounced "graphical") allows you to run queries directly against
the server endpoint with syntax highlighting and autocomplete. It also allows
you to explore the schema and types.

The examples below:

- Can be run directly against GitLab 11.0 or later, though some of the types
  and fields may not be supported in older versions.
- Works against GitLab.com without any further setup. Make sure you are signed
  in and navigate to the [GraphiQL Explorer](https://gitlab.com/-/graphql-explorer).

If you want to run the queries locally, or on a self-managed instance, you must
either:

- Create the `gitlab-org` group with a project called `graphql-sandbox` under
  it. Create several issues in the project.
- Edit the queries to replace `gitlab-org/graphql-sandbox` with your own group
  and project.

Refer to [running GraphiQL](index.md#graphiql) for more information.

NOTE:
If you are running GitLab 11.0 to 12.0, enable the `graphql`
[feature flag](../features.md#set-or-create-a-feature).

## Queries and mutations

The GitLab GraphQL API can be used to perform:

- Queries for data retrieval.
- [Mutations](#mutations) for creating, updating, and deleting data.

NOTE:
In the GitLab GraphQL API, `id` refers to a
[Global ID](https://graphql.org/learn/global-object-identification/),
which is an object identifier in the format of `"gid://gitlab/Issue/123"`.

[GitLab GraphQL Schema](reference/index.md) outlines which objects and fields are
available for clients to query and their corresponding data types.

Example: Get only the names of all the projects the currently logged in user can
access (up to a limit) in the group `gitlab-org`.

```graphql
query {
  group(fullPath: "gitlab-org") {
    id
    name
    projects {
      nodes {
        name
      }
    }
  }
}
```

Example: Get a specific project and the title of Issue #2.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issue(iid: "2") {
      title
    }
  }
}
```

### Graph traversal

When retrieving child nodes use:

- The `edges { node { } }` syntax.
- The short form `nodes { }` syntax.

Underneath it all is a graph we are traversing, hence the name GraphQL.

Example: Get the name of a project, and the titles of all its issues.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues {
      nodes {
        title
        description
      }
    }
  }
}
```

More about queries:
[GraphQL documentation](https://graphql.org/learn/queries/)

### Authorization

Authorization uses the same engine as the GitLab application (and GitLab.com).
If you've signed in to GitLab and use GraphiQL, all queries are performed as
you, the signed in user. For more information, read the
[GitLab API documentation](../index.md#authentication).

### Mutations

Mutations make changes to data. We can update, delete, or create new records.
Mutations generally use InputTypes and variables, neither of which appear here.

Mutations have:

- Inputs. For example, arguments, such as which emoji you'd like to award,
  and to which object.
- Return statements. That is, what you'd like to get back when it's successful.
- Errors. Always ask for what went wrong, just in case.

#### Creation mutations

Example: Let's have some tea - add a `:tea:` reaction emoji to an issue.

```graphql
mutation {
  awardEmojiAdd(input: { awardableId: "gid://gitlab/Issue/27039960",
      name: "tea"
    }) {
    awardEmoji {
      name
      description
      unicode
      emoji
      unicodeVersion
      user {
        name
      }
    }
    errors
  }
}
```

Example: Add a comment to the issue. In this example, we use the ID of the
`GitLab.com` issue. If you're using a local instance, you must get the ID of an
issue you can write to.

```graphql
mutation {
  createNote(input: { noteableId: "gid://gitlab/Issue/27039960",
      body: "*sips tea*"
    }) {
    note {
      id
      body
      discussion {
        id
      }
    }
    errors
  }
}
```

#### Update mutations

When you see the result `id` of the note you created, take a note of it. Let's
edit it to sip faster.

```graphql
mutation {
  updateNote(input: { id: "gid://gitlab/Note/<note ID>",
      body: "*SIPS TEA*"
    }) {
    note {
      id
      body
    }
    errors
  }
}
```

#### Deletion mutations

Let's delete the comment, because our tea is all gone.

```graphql
mutation {
  destroyNote(input: { id: "gid://gitlab/Note/<note ID>" }) {
    note {
      id
      body
    }
    errors
  }
}
```

You should get something like the following output:

```json
{
  "data": {
    "destroyNote": {
      "errors": [],
      "note": null
    }
  }
}
```

We've asked for the note details, but it doesn't exist anymore, so we get `null`.

More about mutations:
[GraphQL Documentation](https://graphql.org/learn/queries/#mutations).

### Introspective queries

Clients can query the GraphQL endpoint for information about its own schema.
by making an [introspective query](https://graphql.org/learn/introspection/).
The [GraphiQL Query Explorer](https://gitlab.com/-/graphql-explorer) uses an
introspection query to:

- Gain knowledge about our GraphQL schema.
- Do autocompletion.
- Provide its interactive `Docs` tab.

Example: Get all the type names in the schema.

```graphql
{
  __schema {
    types {
      name
    }
  }
}
```

Example: Get all the fields associated with Issue. `kind` tells us the enum
value for the type, like `OBJECT`, `SCALAR` or `INTERFACE`.

```graphql
query IssueTypes {
  __type(name: "Issue") {
    kind
    name
    fields {
      name
      description
      type {
        name
      }
    }
  }
}
```

More about introspection:
[GraphQL documentation](https://graphql.org/learn/introspection/)

## Sorting

Some of the GitLab GraphQL endpoints allow you to specify how to sort a
collection of objects. You can only sort by what the schema allows you to.

Example: Issues can be sorted by creation date:

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
   name
    issues(sort: created_asc) {
      nodes {
        title
        createdAt
      }
    }
  }
}
```

## Pagination

Pagination is a way of only asking for a subset of the records, such as the
first ten. If we want more of them, we can make another request for the next
ten from the server in the form of something like `please give me the next ten records`.

By default, the GitLab GraphQL API returns 100 records per page. To change this
behavior, use `first` or `last` arguments. Both arguments take a value, so
`first: 10` returns the first ten records, and `last: 10` the last ten records.
There is a limit on how many records are returned per page, which is generally
`100`.

Example: Retrieve only the first two issues (slicing). The `cursor` field gives
us a position from which we can retrieve further records relative to that one.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 2) {
      edges {
        node {
          title
        }
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

Example: Retrieve the next three. (The cursor value
`eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0`
could be different, but it's the `cursor` value returned for the second issue
returned above.)

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 3, after: "eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0") {
      edges {
        node {
          title
        }
        cursor
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

More about pagination and cursors:
[GraphQL documentation](https://graphql.org/learn/pagination/)
