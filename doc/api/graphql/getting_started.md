# Getting started with GitLab GraphQL API

This guide demonstrates basic usage of GitLab's GraphQL API.

See the [GraphQL API StyleGuide](../../development/api_graphql_styleguide.md) for implementation details
aimed at developers who wish to work on developing the API itself.

## Running examples

The examples documented here can be run using:

- The command line.
- GraphiQL.

### Command line

You can run GraphQL queries in a `curl` request on the command line on your local machine.
A GraphQL request can be made as a `POST` request to `/api/graphql` with the query as the payload.
You can authorize your request by generating a [personal access token](../../user/profile/personal_access_tokens.md)
to use as a bearer token.

Example:

```sh
GRAPHQL_TOKEN=<your-token>
curl 'https://gitlab.com/api/graphql' --header "Authorization: Bearer $GRAPHQL_TOKEN" --header "Content-Type: application/json" --request POST --data "{\"query\": \"query {currentUser {name}}\"}"
```

### GraphiQL

GraphiQL (pronounced “graphical”) allows you to run queries directly against the server endpoint
with syntax highlighting and autocomplete. It also allows you to explore the schema and types.

The examples below:

- Can be run directly against GitLab 11.0 or later, though some of the types and fields
may not be supported in older versions.
- Will work against GitLab.com without any further setup. Make sure you are signed in and
navigate to the [GraphiQL Explorer](https://www.gitlab.com/-/graphql-explorer).

If you want to run the queries locally, or on a self-managed instance,
you will need to either:

- Create the `gitlab-org` group with a project called `graphql-sandbox` under it. Create
several issues within the project.
- Edit the queries to replace `gitlab-org/graphql-sandbox` with your own group and project.

Please refer to [running GraphiQL](index.md#graphiql) for more information.

NOTE: **Note:**
If you are running GitLab 11.0 to 12.0, enable the `graphql`
[feature flag](../features.md#set-or-create-a-feature).

## Queries and mutations

The GitLab GraphQL API can be used to perform:

- Queries for data retrieval.
- [Mutations](#mutations) for creating, updating, and deleting data.

NOTE: **Note:**
In the GitLab GraphQL API, `id` generally refers to a global ID,
which is an object identifier in the format of `gid://gitlab/Issue/123`.

[GitLab's GraphQL Schema](reference/index.md) outlines which objects and fields are
available for clients to query and their corresponding data types.

Example: Get only the names of all the projects the currently logged in user can access (up to a limit, more on that later)
in the group `gitlab-org`.

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

- the `edges { node { } }` syntax.
- the short form `nodes { }` syntax.

Underneath it all is a graph we are traversing, hence the name GraphQL.

Example: Get a project (only its name) and the titles of all its issues.

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
[GraphQL docs](https://graphql.org/learn/queries/)

### Authorization

Authorization uses the same engine as the GitLab application (and GitLab.com). So if you've signed in to GitLab
and use GraphiQL, all queries will be performed as you, the signed in user. For more information, see the
[GitLab API documentation](../README.md#authentication).

### Mutations

Mutations make changes to data. We can update, delete, or create new records. Mutations
generally use InputTypes and variables, neither of which appear here.

Mutations have:

- Inputs. For example, arguments, such as which emoji you'd like to award,
and to which object.
- Return statements. That is, what you'd like to get back when it's successful.
- Errors. Always ask for what went wrong, just in case.

#### Creation mutations

Example: Let's have some tea - add a `:tea:` reaction emoji to an issue.

```graphql
mutation {
  addAwardEmoji(input: { awardableId: "gid://gitlab/Issue/27039960",
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

Example: Add a comment to the issue (we're using the ID of the `GitLab.com` issue - but
if you're using a local instance, you'll need to get the ID of an issue you can write to).

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

When you see the result `id` of the note you created - take a note of it. Now let's edit it to sip faster!

```graphql
mutation {
  updateNote(input: { id: "gid://gitlab/Note/<note id>",
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

Let's delete the comment, since our tea is all gone.

```graphql
mutation {
  destroyNote(input: { id: "gid://gitlab/Note/<note id>" }) {
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
[GraphQL Docs](https://graphql.org/learn/queries/#mutations).

### Introspective queries

Clients can query the GraphQL endpoint for information about its own schema.
by making an [introspective query](https://graphql.org/learn/introspection/).

It is through an introspection query that the [GraphiQL Query Explorer](https://gitlab.com/-/graphql-explorer)
gets all of its knowledge about our GraphQL schema to do autocompletion and provide
its interactive `Docs` tab.

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

Example: Get all the fields associated with Issue.
`kind` tells us the enum value for the type, like `OBJECT`, `SCALAR` or `INTERFACE`.

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
[GraphQL docs](https://graphql.org/learn/introspection/)

## Sorting

Some of GitLab's GraphQL endpoints allow you to specify how you'd like a collection of
objects to be sorted. You can only sort by what the schema allows you to.

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

Pagination is a way of only asking for a subset of the records (say, the first 10).
If we want more of them, we can make another request for the next 10 from the server
(in the form of something like "please give me the next 10 records").

By default, GitLab's GraphQL API will return only the first 100 records of any collection.
This can be changed by using `first` or `last` arguments. Both arguments take a value,
so `first: 10` will return the first 10 records, and `last: 10` the last 10 records.

Example: Retrieve only the first 2 issues (slicing). The `cursor` field gives us a position from which
we can retrieve further records relative to that one.

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

Example: Retrieve the next 3. (The cursor value
`eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0`
could be different, but it's the `cursor` value returned for the second issue returned above.)

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

More on pagination and cursors:
[GraphQL docs](https://graphql.org/learn/pagination/)
