---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Run GraphQL API queries and mutations
description: "Guide to running GraphQL queries and mutations with examples."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This guide demonstrates basic usage of the GitLab GraphQL API.

## Running examples

The examples documented here can be run using:

- [GraphiQL](#graphiql).
- [Command line](#command-line).
- [Rails console](#rails-console).

### GraphiQL

GraphiQL (pronounced "graphical") allows you to run real GraphQL queries against the API interactively.
It makes exploring the schema easier by providing a UI with syntax highlighting and autocompletion.

For most people, using GraphiQL will be the easiest way to explore the GitLab GraphQL API.

You can either use GraphiQL:

- [On GitLab.com](https://gitlab.com/-/graphql-explorer).
- On GitLab Self-Managed on `https://<your-gitlab-site.com>/-/graphql-explorer`.

Sign in to GitLab first to authenticate the requests with your GitLab account.

To get started, refer to the [example queries and mutations](#queries-and-mutations).

### Command line

You can run GraphQL queries in a `curl` request on the command line on your
local computer. The requests `POST` to `/api/graphql`
with the query as the payload. You can authorize your request by generating a
[personal access token](../../user/profile/personal_access_tokens.md) to use as
a bearer token. Read more about [GraphQL Authentication](_index.md#authentication).

Example:

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

To nest strings in the query string,
wrap the data in single quotes or escape the strings with ` \\ `:

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"query": "query {project(fullPath: \"<group>/<subgroup>/<project>\") {jobs {nodes {id duration}}}}"}'
  # or "{\"query\": \"query {project(fullPath: \\\"<group>/<subgroup>/<project>\\\") {jobs {nodes {id duration}}}}\"}"
```

### Rails console

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GraphQL queries can be run in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session). For example, to search projects:

```ruby
current_user = User.find_by_id(1)
query = <<~EOQ
query securityGetProjects($search: String!) {
  projects(search: $search) {
    nodes {
      path
    }
  }
}
EOQ

variables = { "search": "gitlab" }

result = GitlabSchema.execute(query, variables: variables, context: { current_user: current_user })
result.to_h
```

## Queries and mutations

The GitLab GraphQL API can be used to perform:

- Queries for data retrieval.
- [Mutations](#mutations) for creating, updating, and deleting data.

> [!note]
> In the GitLab GraphQL API, `id` refers to a
> [Global ID](https://graphql.org/learn/global-object-identification/),
> which is an object identifier in the format of `"gid://gitlab/Issue/123"`.
> For more information, see [Global IDs](_index.md#global-ids).

[GitLab GraphQL Schema](reference/_index.md) outlines which objects and fields are
available for clients to query and their corresponding data types.

Example: Get only the names of all the projects the currently authenticated user can
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

Underneath it all is a graph you are traversing, hence the name GraphQL.

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

If you've signed in to GitLab and use [GraphiQL](#graphiql), all queries are performed as
you, the authenticated user. For more information, read about
[GraphQL Authentication](_index.md#authentication).

### Mutations

Mutations make changes to data. We can update, delete, or create new records.
Mutations generally use InputTypes and variables, neither of which appear here.

Mutations have:

- Inputs. For example, arguments, such as which emoji reaction you'd like to add,
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

Example: Add a comment to the issue. This example uses the ID of the
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

The requested note doesn't exist anymore, so the returned value for that field is `null`.

More about mutations:
[GraphQL Documentation](https://graphql.org/learn/queries/#mutations).

### Update project settings

You can update multiple project settings in a single GraphQL mutation.
This example is a workaround for [the major change](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement)
in `CI_JOB_TOKEN` scoping behavior.

```graphql
mutation DisableCI_JOB_TOKENscope {
  projectCiCdSettingsUpdate(input:{fullPath: "<namespace>/<project-name>", inboundJobTokenScopeEnabled: false}) {
    ciCdSettings {
      inboundJobTokenScopeEnabled
    }
    errors
  }
}
```

### Introspection queries

Clients can query the GraphQL endpoint for information about its schema
by making an [introspection query](https://graphql.org/learn/introspection/).

- In development and test environments, introspection queries execute against the live
  schema.
- In production environments, introspection queries return a static schema.
  - All introspection queries return the same static response, regardless of the request
    method or parameters.
  - The static schema is updated automatically to match the current schema.
  - Introspection queries return one of two static schema files:
    - `public/-/graphql/introspection_result.json`: Full schema, including deprecated
      fields.
    - `public/-/graphql/introspection_result_no_deprecated.json`: Schema without
      deprecated fields.

To request the schema, send the following in the request body:

```json
{
  "query": "{ __schema { types { name } } }"
}
```

To request the schema without deprecated fields, include `remove_deprecated: true` in the request body:

```json
{
  "query": "{ __schema { types { name } } }",
  "remove_deprecated": true
}
```

#### GraphiQL introspection queries

The [GraphiQL Query Explorer](#graphiql) uses an
introspection query to:

- Gain knowledge about the GitLab GraphQL schema.
- Do autocompletion.
- Provide its interactive `Docs` tab.

More about introspection:
[GraphQL documentation](https://graphql.org/learn/introspection/)

### Query complexity

The calculated [complexity score and limit](_index.md#maximum-query-complexity) for a query can be revealed to clients by
querying for `queryComplexity`.

```graphql
query {
  queryComplexity {
    score
    limit
  }

  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
  }
}
```

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
first ten. If you want more of them, you can make another request for the next
ten from the server in the form of something like `give me the next ten records`.

By default, the GitLab GraphQL API returns 100 records per page. To change this
behavior, use `first` or `last` arguments. Both arguments take a value, so
`first: 10` returns the first ten records, and `last: 10` the last ten records.
There is a limit on how many records are returned per page, which is generally
`100`.

Example: Retrieve only the first two issues (slicing). The `cursor` field gives
you a position from which you can retrieve further records relative to that one.

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

## File uploads

Some mutations accept file uploads as arguments. These mutations use the
[GraphQL multipart request specification](https://github.com/jaydenseric/graphql-multipart-request-spec),
which allows you to send files alongside your GraphQL operations using `multipart/form-data` requests.

Mutations that support file uploads have arguments of type `Upload`.
You can identify these mutations in the [GraphQL API reference](reference/_index.md)
by looking for arguments with the `Upload` scalar type.

File upload mutations cannot be run through [GraphiQL](#graphiql). You must use
a [command-line](#command-line) tool like `curl` or a compatible GraphQL client library.

A multipart upload request has three key parts:

- `operations`: A JSON string containing the GraphQL query and variables, with file
  values set to `null`.
- `map`: A JSON object that maps file keys to the variable paths in the operations.
- The file fields themselves, referenced by the keys used in `map`.

To upload a design to an issue using the `designManagementUpload` mutation:

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($files: [Upload!]!, $projectPath: ID!, $iid: ID!) { designManagementUpload(input: { projectPath: $projectPath, iid: $iid, files: $files }) { designs { filename } errors } }", "variables": {"files": [null], "projectPath": "<group>/<project>", "iid": "<issue-iid>"}}' \
  --form 'map={"0": ["variables.files.0"]}' \
  --form '0=@/path/to/your/design.png'
```

To import work items from a CSV file using the `workItemsCsvImport` mutation:

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($projectPath: ID!, $file: Upload!) { workItemsCsvImport(input: { projectPath: $projectPath, file: $file }) { message errors } }", "variables": {"projectPath": "<group>/<project>", "file": null}}' \
  --form 'map={"0": ["variables.file"]}' \
  --form '0=@/path/to/your/work-items.csv'
```

To upload multiple files in a single request, add additional entries to both the
`map` and the form fields:

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($files: [Upload!]!, $projectPath: ID!, $iid: ID!) { designManagementUpload(input: { projectPath: $projectPath, iid: $iid, files: $files }) { designs { filename } errors } }", "variables": {"files": [null, null], "projectPath": "<group>/<project>", "iid": "<issue-iid>"}}' \
  --form 'map={"0": ["variables.files.0"], "1": ["variables.files.1"]}' \
  --form '0=@/path/to/first-design.png' \
  --form '1=@/path/to/second-design.png'
```

## Changing the query URL

Sometimes, it is necessary to send GraphQL requests to a different URL. An example are the `GeoNode` queries, which only work against a secondary Geo site URL.

To change the URL of a GraphQL request in the GraphiQL explorer, set a custom header in the Header area of GraphiQL (bottom left area, right where Variables are):

```JSON
{
  "REQUEST_PATH": "<the URL to make the graphQL request against>"
}
```
