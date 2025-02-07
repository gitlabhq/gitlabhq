---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Backend GraphQL API guide
---

This document contains style and technical guidance for engineers implementing the backend of the [GitLab GraphQL API](../api/graphql/_index.md).

## Relation to REST API

See the [GraphQL and REST APIs section](api_styleguide.md#graphql-and-rest-apis).

## Versioning

The GraphQL API is [versionless](https://graphql.org/learn/best-practices/#versioning).

## Learning GraphQL at GitLab

Backend engineers who wish to learn GraphQL at GitLab should read this guide in conjunction with the
[guides for the GraphQL Ruby gem](https://graphql-ruby.org/guides).
Those guides teach you the features of the gem, and the information in it is generally not reproduced here.

To learn about the design and features of GraphQL itself read [the guide on `graphql.org`](https://graphql.org/learn/)
which is an accessible but shortened version of information in the [GraphQL spec](https://spec.graphql.org).

### Deep Dive

In March 2019, Nick Thomas hosted a Deep Dive (GitLab team members only: `https://gitlab.com/gitlab-org/create-stage/issues/1`)
on the GitLab [GraphQL API](../api/graphql/_index.md) to share domain-specific knowledge
with anyone who may work in this part of the codebase in the future. You can find the
<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[recording on YouTube](https://www.youtube.com/watch?v=-9L_1MWrjkg), and the slides on
[Google Slides](https://docs.google.com/presentation/d/1qOTxpkTdHIp1CRjuTvO-aXg0_rUtzE3ETfLUdnBB5uQ/edit)
and in [PDF](https://gitlab.com/gitlab-org/create-stage/uploads/8e78ea7f326b2ef649e7d7d569c26d56/GraphQL_Deep_Dive__Create_.pdf).
Specific details have changed since then, but it should still serve as a good introduction.

## How GitLab implements GraphQL

<!-- vale gitlab_base.Spelling = NO -->

We use the [GraphQL Ruby gem](https://graphql-ruby.org/) written by [Robert Mosolgo](https://github.com/rmosolgo/).
In addition, we have a subscription to [GraphQL Pro](https://graphql.pro/). For
details see [GraphQL Pro subscription](graphql_guide/graphql_pro.md).

<!-- vale gitlab_base.Spelling = YES -->

All GraphQL queries are directed to a single endpoint
([`app/controllers/graphql_controller.rb#execute`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app%2Fcontrollers%2Fgraphql_controller.rb)),
which is exposed as an API endpoint at `/api/graphql`.

## GraphiQL

GraphiQL is an interactive GraphQL API explorer where you can play around with existing queries.
You can access it in any GitLab environment on `https://<your-gitlab-site.com>/-/graphql-explorer`.
For example, the one for [GitLab.com](https://gitlab.com/-/graphql-explorer).

## Reviewing merge requests with GraphQL changes

The GraphQL framework has some specific gotchas to be aware of, and domain expertise is required to ensure they are satisfied.

If you are asked to review a merge request that modifies any GraphQL files or adds an endpoint, have a look at
[our GraphQL review guide](graphql_guide/reviewing.md).

## Reading GraphQL logs

See the [Reading GraphQL logs](graphql_guide/monitoring.md) guide for tips on how to inspect logs
of GraphQL requests and monitor the performance of your GraphQL queries.

## Authentication

Authentication happens through the `GraphqlController`, right now this
uses the same authentication as the Rails application. So the session
can be shared.

It's also possible to add a `private_token` to the query string, or
add a `HTTP_PRIVATE_TOKEN` header.

## Limits

Several limits apply to the GraphQL API and some of these can be overridden
by developers.

### Max page size

By default, [connections](#connection-types) can only return
at most a maximum number of records defined in
[`app/graphql/gitlab_schema.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/gitlab_schema.rb)
per page.

Developers can [specify a custom max page size](#page-size-limit) when defining
a connection.

### Max complexity

Complexity is explained [on our client-facing API page](../api/graphql/_index.md#maximum-query-complexity).

Fields default to adding `1` to a query's complexity score, but developers can
[specify a custom complexity](#field-complexity) when defining a field.

The complexity score of a query [can itself be queried for](../api/graphql/getting_started.md#query-complexity).

### Request timeout

Requests time out at 30 seconds.

### Limit maximum field call count

In some cases, you want to prevent the evaluation of a specific field on multiple parent nodes
because it results in an N+1 query problem and there is no optimal solution. This should be
considered an option of last resort, to be used only when methods such as
[lookahead to preload associations](#look-ahead), or [using batching](graphql_guide/batchloader.md)
have been considered.

For example:

```graphql
# This usage is expected.
query {
  project {
    environments
  }
}

# This usage is NOT expected.
# It results in N+1 query problem. EnvironmentsResolver can't use GraphQL batch loader in favor of GraphQL pagination.
query {
  projects {
    nodes {
      environments
    }
  }
}
```

To prevent this, you can use the `Gitlab::Graphql::Limit::FieldCallCount` extension on the field:

```ruby
# This allows maximum 1 call to the `environments` field. If the field is evaluated on more than one node,
# it raises an error.
field :environments do
        extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
      end
```

or you can apply the extension in a resolver class:

```ruby
module Resolvers
  class EnvironmentsResolver < BaseResolver
    extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
    # ...
  end
end
```

When you add this limit, make sure that the affected field's `description` is also updated accordingly. For example,

```ruby
field :environments,
      description: 'Environments of the project. This field can only be resolved for one project in any single request.'
```

## Breaking changes

The GitLab GraphQL API is [versionless](https://graphql.org/learn/best-practices/#versioning) which means
developers must familiarize themselves with our [Deprecation and Removal process](../api/graphql/_index.md#deprecation-and-removal-process).

Breaking changes are:

- Removing or renaming a field, argument, enum value, or mutation.
- Changing the type or type name of an argument. The type of an argument
  is declared by the client when [using variables](https://graphql.org/learn/queries/#variables),
  and a change would cause a query using the old type name to be rejected by the API.
- Changing the [_scalar type_](https://graphql.org/learn/schema/#scalar-types) of a field or enum
  value where it results in a change to how the value serializes to JSON.
  For example, a change from a JSON String to a JSON Number, or a change to how a String is formatted.
  A change to another [_object type_](https://graphql.org/learn/schema/#object-types-and-fields) can be
  allowed so long as all scalar type fields of the object continue to serialize in the same way.
- Raising the [complexity](#max-complexity) of a field or complexity multipliers in a resolver.
- Changing a field from being _not_ nullable (`null: false`) to nullable (`null: true`), as
  discussed in [Nullable fields](#nullable-fields).
- Changing an argument from being optional (`required: false`) to being required (`required: true`).
- Changing the [max page size](#page-size-limit) of a connection.
- Lowering the global limits for query complexity and depth.
- Anything else that can result in queries hitting a limit that previously was allowed.

See the [deprecating schema items](#deprecating-schema-items) section for how to deprecate items.

### Breaking change exemptions

See the
[GraphQL API breaking change exemptions documentation](../api/graphql/_index.md#breaking-change-exemptions).

## Global IDs

The GitLab GraphQL API uses Global IDs (i.e: `"gid://gitlab/MyObject/123"`)
and never database primary key IDs.

Global ID is [a convention](https://graphql.org/learn/global-object-identification/)
used for caching and fetching in client-side libraries.

See also:

- [Exposing Global IDs](#exposing-global-ids).
- [Mutation arguments](#object-identifier-arguments).
- [Deprecating Global IDs](#deprecate-global-ids).
- [Customer-facing Global ID documentation](../api/graphql/_index.md#global-ids).

We have a custom scalar type (`Types::GlobalIDType`) which should be used as the
type of input and output arguments when the value is a `GlobalID`. The benefits
of using this type instead of `ID` are:

- it validates that the value is a `GlobalID`
- it parses it into a `GlobalID` before passing it to user code
- it can be parameterized on the type of the object (for example,
  `GlobalIDType[Project]`) which offers even better validation and security.

Consider using this type for all new arguments and result types. Remember that
it is perfectly possible to parameterize this type with a concern or a
supertype, if you want to accept a wider range of objects (such as
`GlobalIDType[Issuable]` vs `GlobalIDType[Issue]`).

## Optimizations

By default, GraphQL tends to introduce N+1 problems unless you actively try to minimize them.

For stability and scalability, you must ensure that our queries do not suffer from N+1
performance issues.

The following are a list of tools to help you to optimize your GraphQL code:

- [Look ahead](#look-ahead) allows you to preload data based on which fields are selected in the query.
- [Batch loading](graphql_guide/batchloader.md) allows you batch database queries together to be executed in one statement.
- [`BatchModelLoader`](graphql_guide/batchloader.md#the-batchmodelloader) is the recommended way to lookup
  records by ID to leverage batch loading.
- [`before_connection_authorization`](#before_connection_authorization) allows you to address N+1 problems
  specific to [type authorization](#authorization) permission checks.
- [Limit maximum field call count](#limit-maximum-field-call-count) allows you to restrict how many times
  a field can return data where optimizations cannot be improved.

## How to see N+1 problems in development

N+1 problems can be discovered during development of a feature by:

- Tailing `development.log` while you execute GraphQL queries that return collections of data.
  [Bullet](profiling.md#bullet) may help.
- Observing the [performance bar](../administration/monitoring/performance/performance_bar.md) if
  executing queries in the GitLab UI.
- Adding a [request spec](#testing-tips-and-tricks) that asserts there are no (or limited) N+1
  problems with the feature.

## Fields

### Types

We use a code-first schema, and we declare what type everything is in Ruby.

For example, `app/graphql/types/project_type.rb`:

```ruby
graphql_name 'Project'

field :full_path, GraphQL::Types::ID, null: true
field :name, GraphQL::Types::String, null: true
```

We give each type a name (in this case `Project`).

The `full_path` and `name` are of _scalar_ GraphQL types.
`full_path` is a `GraphQL::Types::ID`
(see [when to use `GraphQL::Types::ID`](#when-to-use-graphqltypesid)).
`name` is a regular `GraphQL::Types::String` type.
You can also declare [custom GraphQL data types](#gitlab-custom-scalars)
for scalar data types (for example `TimeType`).

When exposing a model through the GraphQL API, we do so by creating a
new type in `app/graphql/types`.

When exposing properties in a type, make sure to keep the logic inside
the definition as minimal as possible. Instead, consider moving any
logic into a [presenter](reusing_abstractions.md#presenters):

```ruby
class Types::MergeRequestType < BaseObject
  present_using MergeRequestPresenter

  name 'MergeRequest'
end
```

An existing presenter could be used, but it is also possible to create
a new presenter specifically for GraphQL.

The presenter is initialized using the object resolved by a field, and
the context.

### Nullable fields

GraphQL allows fields to be "nullable" or "non-nullable". The former means
that `null` may be returned instead of a value of the specified type. **In
general**, you should prefer using nullable fields to non-nullable ones, for
the following reasons:

- It's common for data to switch from required to not-required, and back again
- Even when there is no prospect of a field becoming optional, it may not be **available** at query time
  - For instance, the `content` of a blob may need to be looked up from Gitaly
  - If the `content` is nullable, we can return a **partial** response, instead of failing the whole query
- Changing from a non-nullable field to a nullable field is difficult with a versionless schema

Non-nullable fields should only be used when a field is required, very unlikely
to become optional in the future, and straightforward to calculate. An example would
be `id` fields.

A non-nullable GraphQL schema field is an object type followed by the exclamation point (bang) `!`. Here's an example from the `gitlab_schema.graphql` file:

```graphql
  id: ProjectID!
```

Here's an example of a non-nullable GraphQL array:

```graphql

  errors: [String!]!
```

Further reading:

- [GraphQL Best Practices Guide](https://graphql.org/learn/best-practices/#nullability).
- GraphQL documentation on [Object types and fields](https://graphql.org/learn/schema/#object-types-and-fields).
- [Using nullability in GraphQL](https://www.apollographql.com/blog/using-nullability-in-graphql)

### Exposing Global IDs

In keeping with the GitLab use of [Global IDs](#global-ids), always convert
database primary key IDs into Global IDs when you expose them.

All fields named `id` are
[converted automatically](https://gitlab.com/gitlab-org/gitlab/-/blob/b0f56e7/app/graphql/types/base_object.rb#L11-14)
into the object's Global ID.

Fields that are not named `id` need to be manually converted. We can do this using
[`Gitlab::GlobalID.build`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/global_id.rb),
or by calling `#to_global_id` on an object that has mixed in the
`GlobalID::Identification` module.

Using an example from
[`Types::Notes::DiscussionType`](https://gitlab.com/gitlab-org/gitlab/-/blob/af48df44/app/graphql/types/notes/discussion_type.rb#L22-30):

```ruby
field :reply_id, Types::GlobalIDType[Discussion]

def reply_id
  Gitlab::GlobalId.build(object, id: object.reply_id)
end
```

### When to use `GraphQL::Types::ID`

When we use `GraphQL::Types::ID` the field becomes a GraphQL `ID` type, which is serialized as a JSON string.
However, `ID` has a special significance for clients. The [GraphQL spec](https://spec.graphql.org/October2021/#sec-ID) says:

> The ID scalar type represents a unique identifier, often used to refetch an object or as the key for a cache.

The GraphQL spec does not clarify what the scope should be for an `ID`'s uniqueness. At GitLab we have
decided that an `ID` must be at least unique by type name. Type name is the `graphql_name` of one our of `Types::` classes, for example `Project`, or `Issue`.

Following this:

- `Project.fullPath` should be an `ID` because there will be no other `Project` with that `fullPath` across the API, and the field is also an identifier.
- `Issue.iid` _should not_ be an `ID` because there can be many `Issue` types that have the same `iid` across the API.
  Treating it as an `ID` would be problematic if the client has a cache of `Issue`s from different projects.
- `Project.id` normally would qualify to be an `ID` because there can only be one `Project` with that ID value -
  except we use [Global ID types](#global-ids) instead of `ID` types for database ID values so we would type it as a Global ID instead.

This is summarized in the following table:

| Field purpose | Use `GraphQL::Types::ID`? |
|---------------|---------------------------|
| Full path | **{check-circle}** Yes |
| Database ID | **{dotted-circle}** No |
| IID | **{dotted-circle}** No |

### `markdown_field`

`markdown_field` is a helper method that wraps `field` and should always be used for
fields that return rendered Markdown.

This helper renders a model's Markdown field using the
existing `MarkupHelper` with the context of the GraphQL query
available to the helper.

Having the context available to the helper is needed for redacting
links to resources that the current user is not allowed to see.

Because rendering the HTML can cause queries, the complexity of a
these fields is raised by 5 above the default.

The Markdown field helper can be used as follows:

```ruby
markdown_field :note_html, null: false
```

This would generate a field that renders the Markdown field `note`
of the model. This could be overridden by adding the `method:`
argument.

```ruby
markdown_field :body_html, null: false, method: :note
```

The field is given this description by default:

> The GitLab Flavored Markdown rendering of `note`

This can be overridden by passing a `description:` argument.

### Connection types

NOTE:
For specifics on implementation, see [Pagination implementation](#pagination-implementation).

GraphQL uses [cursor based pagination](https://graphql.org/learn/pagination/#pagination-and-edges)
to expose collections of items. This provides the clients with a lot
of flexibility while also allowing the backend to use different
pagination models.

To expose a collection of resources we can use a connection type. This wraps the array with default pagination fields. For example a query for project-pipelines could look like this:

```graphql
query($project_path: ID!) {
  project(fullPath: $project_path) {
    pipelines(first: 2) {
      pageInfo {
        hasNextPage
        hasPreviousPage
      }
      edges {
        cursor
        node {
          id
          status
        }
      }
    }
  }
}
```

This would return the first 2 pipelines of a project and related
pagination information, ordered by descending ID. The returned data would
look like this:

```json
{
  "data": {
    "project": {
      "pipelines": {
        "pageInfo": {
          "hasNextPage": true,
          "hasPreviousPage": false
        },
        "edges": [
          {
            "cursor": "Nzc=",
            "node": {
              "id": "gid://gitlab/Pipeline/77",
              "status": "FAILED"
            }
          },
          {
            "cursor": "Njc=",
            "node": {
              "id": "gid://gitlab/Pipeline/67",
              "status": "FAILED"
            }
          }
        ]
      }
    }
  }
}
```

To get the next page, the cursor of the last known element could be
passed:

```graphql
query($project_path: ID!) {
  project(fullPath: $project_path) {
    pipelines(first: 2, after: "Njc=") {
      pageInfo {
        hasNextPage
        hasPreviousPage
      }
      edges {
        cursor
        node {
          id
          status
        }
      }
    }
  }
}
```

To ensure that we get consistent ordering, we append an ordering on the primary
key, in descending order. The primary key is usually `id`, so we add `order(id: :desc)`
to the end of the relation. A primary key _must_ be available on the underlying table.

#### Shortcut fields

Sometimes it can seem straightforward to implement a "shortcut field", having the resolver return the first of a collection if no parameters are passed.
These "shortcut fields" are discouraged because they create maintenance overhead.
They need to be kept in sync with their canonical field, and deprecated or modified if their canonical field changes.
Use the functionality the framework provides unless there is a compelling reason to do otherwise.

For example, instead of `latest_pipeline`, use `pipelines(last: 1)`.

#### Page size limit

By default, the API returns at most a maximum number of records defined in
[`app/graphql/gitlab_schema.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/gitlab_schema.rb)
per page in a connection and this is also the default number of records
returned per page if no limiting arguments (`first:` or `last:`) are provided by a client.

The `max_page_size` argument can be used to specify a different page size limit
for a connection.

WARNING:
It's better to change the frontend client, or product requirements, to not need large amounts of
records per page than it is to raise the `max_page_size`, as the default is set to ensure
the GraphQL API remains performant.

For example:

```ruby
field :tags,
  Types::ContainerRegistry::ContainerRepositoryTagType.connection_type,
  null: true,
  description: 'Tags of the container repository',
  max_page_size: 20
```

### Field complexity

The GitLab GraphQL API uses a _complexity_ score to limit performing overly complex queries.
Complexity is described in [our client documentation](../api/graphql/_index.md#maximum-query-complexity) on the topic.

Complexity limits are defined in [`app/graphql/gitlab_schema.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/gitlab_schema.rb).

By default, fields add `1` to a query's complexity score. This can be overridden by
[providing a custom `complexity`](https://graphql-ruby.org/queries/complexity_and_depth.html) value for a field.

Developers should specify higher complexity for fields that cause more _work_ to be performed
by the server to return data. Fields that represent data that can be returned
with little-to-no _work_, for example in most cases; `id` or `title`, can be given a complexity of `0`.

### `calls_gitaly`

Fields that have the potential to perform a [Gitaly](../administration/gitaly/_index.md) call when resolving _must_ be marked as
such by passing `calls_gitaly: true` to `field` when defining it.

For example:

```ruby
field :blob, type: Types::Snippets::BlobType,
      description: 'Snippet blob',
      null: false,
      calls_gitaly: true
```

This increments the [`complexity` score](#field-complexity) of the field by `1`.

If a resolver calls Gitaly, it can be annotated with
`BaseResolver.calls_gitaly!`. This passes `calls_gitaly: true` to any
field that uses this resolver.

For example:

```ruby
class BranchResolver < BaseResolver
  type ::Types::BranchType, null: true
  calls_gitaly!

  argument name: ::GraphQL::Types::String, required: true

  def resolve(name:)
    object.branch(name)
  end
end
```

Then when we use it, any field that uses `BranchResolver` has the correct
value for `calls_gitaly:`.

### Exposing permissions for a type

To expose permissions the current user has on a resource, you can call
the `expose_permissions` passing in a separate type representing the
permissions for the resource.

For example:

```ruby
module Types
  class MergeRequestType < BaseObject
    expose_permissions Types::MergeRequestPermissionsType
  end
end
```

The permission type inherits from `BasePermissionType` which includes
some helper methods, that allow exposing permissions as non-nullable
booleans:

```ruby
class MergeRequestPermissionsType < BasePermissionType
  graphql_name 'MergeRequestPermissions'

  present_using MergeRequestPresenter

  abilities :admin_merge_request, :update_merge_request, :create_note

  ability_field :resolve_note,
                description: 'Indicates the user can resolve discussions on the merge request.'
  permission_field :push_to_source_branch, method: :can_push_to_source_branch?
end
```

- **`permission_field`**: Acts the same as `graphql-ruby`'s
  `field` method but setting a default description and type and making
  them non-nullable. These options can still be overridden by adding
  them as arguments.
- **`ability_field`**: Expose an ability defined in our policies. This
  behaves the same way as `permission_field` and the same
  arguments can be overridden.
- **`abilities`**: Allows exposing several abilities defined in our
  policies at once. The fields for these must all be non-nullable
  booleans with a default description.

## Feature flags

You can implement [feature flags](feature_flags/_index.md) in GraphQL to toggle:

- The return value of a field.
- The behavior of an argument or mutation.

This can be done in a resolver, in the
type, or even in a model method, depending on your preference and
situation.

NOTE:
It's recommended that you also [mark the item as an experiment](#mark-schema-items-as-experiments) while it is behind a feature flag.
This signals to consumers of the public GraphQL API that the field is not
meant to be used yet.
You can also
[change or remove experimental items at any time](#breaking-change-exemptions) without needing to deprecate them. When the flag is removed, "release"
the schema item by removing its `experiment` property to make it public.

### Descriptions for feature-flagged items

When using a feature flag to toggle the value or behavior of a schema item, the
`description` of the item must:

- State that the value or behavior can be toggled by a feature flag.
- Name the feature flag.
- State what the field returns, or behavior is, when the feature flag is disabled (or
  enabled, if more appropriate).

### Examples of using feature flags

#### Feature-flagged field

A field value is toggled based on the feature flag state. A common use is to return `null` if the feature flag is disabled:

```ruby
field :foo, GraphQL::Types::String, null: true,
      experiment: { milestone: '10.0' },
      description: 'Some test field. Returns `null`' \
                   'if `my_feature_flag` feature flag is disabled.'

def foo
  object.foo if Feature.enabled?(:my_feature_flag, object)
end
```

#### Feature-flagged argument

An argument can be ignored, or have its value changed, based on the feature flag state.
A common use is to ignore the argument when a feature flag is disabled:

```ruby
argument :foo, type: GraphQL::Types::String, required: false,
         experiment: { milestone: '10.0' },
         description: 'Some test argument. Is ignored if ' \
                      '`my_feature_flag` feature flag is disabled.'

def resolve(args)
  args.delete(:foo) unless Feature.enabled?(:my_feature_flag, object)
  # ...
end
```

#### Feature-flagged mutation

A mutation that cannot be performed due to a feature flag state is handled as a
[non-recoverable mutation error](#failure-irrelevant-to-the-user). The error is returned at the top level:

```ruby
description 'Mutates an object. Does not mutate the object if ' \
            '`my_feature_flag` feature flag is disabled.'

def resolve(id: )
  object = authorized_find!(id: id)

  raise_resource_not_available_error! '`my_feature_flag` feature flag is disabled.' \
    if Feature.disabled?(:my_feature_flag, object)
  # ...
end
```

## Deprecating schema items

The GitLab GraphQL API is versionless, which means we maintain backwards
compatibility with older versions of the API with every change.

Rather than removing fields, arguments, [enum values](#enums), or [mutations](#mutations),
they must be _deprecated_ instead.

The deprecated parts of the schema can then be removed in a future release
in accordance with the [GitLab deprecation process](../api/graphql/_index.md#deprecation-and-removal-process).

To deprecate a schema item in GraphQL:

1. [Create a deprecation issue](#create-a-deprecation-issue) for the item.
1. [Mark the item as deprecated](#mark-the-item-as-deprecated) in the schema.

See also:

- [Aliasing and deprecating mutations](#aliasing-and-deprecating-mutations).
- [Marking schema items as experiments](#mark-schema-items-as-experiments).
- [How to filter Kibana for queries that used deprecated fields](graphql_guide/monitoring.md#queries-that-used-a-deprecated-field).

### Create a deprecation issue

Every GraphQL deprecation should have a deprecation issue created [using the `Deprecations` issue template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Deprecations) to track its deprecation and removal.

Apply these two labels to the deprecation issue:

- `~GraphQL`
- `~deprecation`

### Mark the item as deprecated

Fields, arguments, enum values, and mutations are deprecated using the `deprecated` property. The value of the property is a `Hash` of:

- `reason` - Reason for the deprecation.
- `milestone` - Milestone that the field was deprecated.

Example:

```ruby
field :token, GraphQL::Types::String, null: true,
      deprecated: { reason: 'Login via token has been removed', milestone: '10.0' },
      description: 'Token for login.'
```

The original `description` of the things being deprecated should be maintained,
and should _not_ be updated to mention the deprecation. Instead, the `reason`
is appended to the `description`.

#### Deprecation reason style guide

Where the reason for deprecation is due to the field, argument, or enum value being
replaced, the `reason` must indicate the replacement. For example, the
following is a `reason` for a replaced field:

```plaintext
Use `otherFieldName`
```

Examples:

```ruby
field :designs, ::Types::DesignManagement::DesignCollectionType, null: true,
      deprecated: { reason: 'Use `designCollection`', milestone: '10.0' },
      description: 'The designs associated with this issue.',
```

```ruby
module Types
  class TodoStateEnum < BaseEnum
    value 'pending', deprecated: { reason: 'Use PENDING', milestone: '10.0' }
    value 'done', deprecated: { reason: 'Use DONE', milestone: '10.0' }
    value 'PENDING', value: 'pending'
    value 'DONE', value: 'done'
  end
end
```

If the field, argument, or enum value being deprecated is not being replaced,
a descriptive deprecation `reason` should be given.

#### Deprecate Global IDs

We use the [`rails/globalid`](https://github.com/rails/globalid) gem to generate and parse
Global IDs, so as such they are coupled to model names. When we rename a
model, its Global ID changes.

If the Global ID is used as an _argument_ type anywhere in the schema, then the Global ID
change would typically constitute a breaking change.

To continue to support clients using the old Global ID argument, we add a deprecation
to `Gitlab::GlobalId::Deprecations`.

NOTE:
If the Global ID is _only_ [exposed as a field](#exposing-global-ids) then we do not need to
deprecate it. We consider the change to the way a Global ID is expressed in a field to be
backwards-compatible. We expect that clients don't parse these values: they are meant to
be treated as opaque tokens, and any structure in them is incidental and not to be relied on.

**Example scenario:**

This example scenario is based on this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62645).

A model named `PrometheusService` is to be renamed `Integrations::Prometheus`. The old model
name is used to create a Global ID type that is used as an argument for a mutation:

```ruby
# Mutations::UpdatePrometheus:

argument :id, Types::GlobalIDType[::PrometheusService],
              required: true,
              description: "The ID of the integration to mutate."
```

Clients call the mutation by passing a Global ID string that looks like
`"gid://gitlab/PrometheusService/1"`, named as `PrometheusServiceID`, as the `input.id` argument:

```graphql
mutation updatePrometheus($id: PrometheusServiceID!, $active: Boolean!) {
  prometheusIntegrationUpdate(input: { id: $id, active: $active }) {
    errors
    integration {
      active
    }
  }
}
```

We rename the model to `Integrations::Prometheus`, and then update the codebase with the new name.
When we come to update the mutation, we pass the renamed model to `Types::GlobalIDType[]`:

```ruby
# Mutations::UpdatePrometheus:

argument :id, Types::GlobalIDType[::Integrations::Prometheus],
              required: true,
              description: "The ID of the integration to mutate."
```

This would cause a breaking change to the mutation, as the API now rejects clients who
pass an `id` argument as `"gid://gitlab/PrometheusService/1"`, or that specify the argument
type as `PrometheusServiceID` in the query signature.

To allow clients to continue to interact with the mutation unchanged, edit the `DEPRECATIONS` constant in
`Gitlab::GlobalId::Deprecations` and add a new `Deprecation` to the array:

```ruby
DEPRECATIONS = [
  Gitlab::Graphql::DeprecationsBase::NameDeprecation.new(old_name: 'PrometheusService', new_name: 'Integrations::Prometheus', milestone: '14.0')
].freeze
```

Then follow our regular [deprecation process](../api/graphql/_index.md#deprecation-and-removal-process). To later remove
support for the former argument style, remove the `Deprecation`:

```ruby
DEPRECATIONS = [].freeze
```

During the deprecation period, the API accepts either of these formats for the argument value:

- `"gid://gitlab/PrometheusService/1"`
- `"gid://gitlab/Integrations::Prometheus/1"`

The API also accepts these types in the query signature for the argument:

- `PrometheusServiceID`
- `IntegrationsPrometheusID`

NOTE:
Although queries that use the old type (`PrometheusServiceID` in this example) are
considered valid and executable by the API, validator tools consider them to be invalid.
They are considered invalid because we are deprecating using a bespoke method outside of the
[`@deprecated` directive](https://spec.graphql.org/June2018/#sec--deprecated), so validators are not
aware of the support.

The documentation mentions that the old Global ID style is now deprecated.

## Mark schema items as experiments

You can mark GraphQL schema items (fields, arguments, enum values, and mutations) as
[experiments](../policy/development_stages_support.md#experiment).

An item marked as an experiment is
[exempt from the deprecation process](../api/graphql/_index.md#breaking-change-exemptions) and can be
removed at any time without notice. Mark an item as an experiment when it is subject to
change and not ready for public use.

NOTE:
Only mark new items as an experiment. Never mark existing items
as an experiment because they're already public.

To mark a schema item as an experiment, use the `experiment:` keyword.
You must provide the `milestone:` that introduced the experimental item.

For example:

```ruby
field :token, GraphQL::Types::String, null: true,
      experiment: { milestone: '10.0' },
      description: 'Token for login.'
```

Similarly, you can also mark an entire mutation as an experiment by updating where the mutation is mounted in `app/graphql/types/mutation_type.rb`:

```ruby
mount_mutation Mutations::Ci::JobArtifact::BulkDestroy, experiment: { milestone: '15.10' }
```

Experimental GraphQL items is a custom GitLab feature that leverages GraphQL deprecations. An experimental item
appears as deprecated in the GraphQL schema. Like all deprecated schema items, you can test an
experimental field in the [interactive GraphQL explorer](../api/graphql/_index.md#interactive-graphql-explorer) (GraphiQL).
However, be aware that the GraphiQL autocomplete editor doesn't suggest deprecated fields.

The item shows as `experiment` in our generated GraphQL documentation and its GraphQL schema description.

## Enums

GitLab GraphQL enums are defined in `app/graphql/types`. When defining new enums, the
following rules apply:

- Values must be uppercase.
- Class names must end with the string `Enum`.
- The `graphql_name` must not contain the string `Enum`.

For example:

```ruby
module Types
  class TrafficLightStateEnum < BaseEnum
    graphql_name 'TrafficLightState'
    description 'State of a traffic light'

    value 'RED', description: 'Drivers must stop.'
    value 'YELLOW', description: 'Drivers must stop when it is safe to.'
    value 'GREEN', description: 'Drivers can start or keep driving.'
  end
end
```

If the enum is used for a class property in Ruby that is not an uppercase string,
you can provide a `value:` option that adapts the uppercase value.

In the following example:

- GraphQL inputs of `OPENED` are converted to `'opened'`.
- Ruby values of `'opened'` are converted to `"OPENED"` in GraphQL responses.

```ruby
module Types
  class EpicStateEnum < BaseEnum
    graphql_name 'EpicState'
    description 'State of a GitLab epic'

    value 'OPENED', value: 'opened', description: 'An open Epic.'
    value 'CLOSED', value: 'closed', description: 'A closed Epic.'
  end
end
```

Enum values can be deprecated using the
[`deprecated` keyword](#deprecating-schema-items).

### Defining GraphQL enums dynamically from Rails enums

If your GraphQL enum is backed by a [Rails enum](database/creating_enums.md), then consider
using the Rails enum to dynamically define the GraphQL enum values. Doing so
binds the GraphQL enum values to the Rails enum definition, so if values are
ever added to the Rails enum then the GraphQL enum automatically reflects the change.

Example:

```ruby
module Types
  class IssuableSeverityEnum < BaseEnum
    graphql_name 'IssuableSeverity'
    description 'Incident severity'

    ::IssuableSeverity.severities.each_key do |severity|
      value severity.upcase, value: severity, description: "#{severity.titleize} severity."
    end
  end
end
```

## JSON

When data to be returned by GraphQL is stored as
[JSON](migration_style_guide.md#storing-json-in-database), we should continue to use
GraphQL types whenever possible. Avoid using the `GraphQL::Types::JSON` type unless
the JSON data returned is _truly_ unstructured.

If the structure of the JSON data varies, but is one of a set of known possible
structures, use a
[union](https://graphql-ruby.org/type_definitions/unions.html).
An example of the use of a union for this purpose is
[!30129](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30129).

Field names can be mapped to hash data keys using the `hash_key:` keyword if needed.

For example, given the following JSON data:

```json
{
  "title": "My chart",
  "data": [
    { "x": 0, "y": 1 },
    { "x": 1, "y": 1 },
    { "x": 2, "y": 2 }
  ]
}
```

We can use GraphQL types like this:

```ruby
module Types
  class ChartType < BaseObject
    field :title, GraphQL::Types::String, null: true, description: 'Title of the chart.'
    field :data, [Types::ChartDatumType], null: true, description: 'Data of the chart.'
  end
end

module Types
  class ChartDatumType < BaseObject
    field :x, GraphQL::Types::Int, null: true, description: 'X-axis value of the chart datum.'
    field :y, GraphQL::Types::Int, null: true, description: 'Y-axis value of the chart datum.'
  end
end
```

## Descriptions

All fields and arguments
[must have descriptions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16438).

A description of a field or argument is given using the `description:`
keyword. For example:

```ruby
field :id, GraphQL::Types::ID, description: 'ID of the issue.'
field :confidential, GraphQL::Types::Boolean, description: 'Indicates the issue is confidential.'
field :closed_at, Types::TimeType, description: 'Timestamp of when the issue was closed.'
```

You can view descriptions of fields and arguments in:

- The [GraphiQL explorer](#graphiql).
- The [static GraphQL API reference](../api/graphql/reference/_index.md).

### Description style guide

#### Language and punctuation

To describe fields and arguments, use `{x} of the {y}` where possible,
where `{x}` is the item you're describing, and `{y}` is the resource it applies to. For example:

```plaintext
ID of the issue.
```

```plaintext
Author of the epics.
```

For arguments that sort or search, start with the appropriate verb.
To indicate the specified values, for conciseness, you can use `this` instead of
`the given` or `the specified`. For example:

```plaintext
Sort issues by this criteria.
```

Do not start descriptions with `The` or `A`, for consistency and conciseness.

End all descriptions with a period (`.`).

#### Booleans

For a boolean field (`GraphQL::Types::Boolean`), start with a verb that describes
what it does. For example:

```plaintext
Indicates the issue is confidential.
```

If necessary, provide the default. For example:

```plaintext
Sets the issue to confidential. Default is false.
```

#### Sort enums

[Enums for sorting](#sort-arguments) should have the description `'Values for sorting {x}.'`. For example:

```plaintext
Values for sorting container repositories.
```

#### `Types::TimeType` field description

For `Types::TimeType` GraphQL fields, include the word `timestamp`. This lets
the reader know that the format of the property is `Time`, rather than just `Date`.

For example:

```ruby
field :closed_at, Types::TimeType, description: 'Timestamp of when the issue was closed.'
```

### `copy_field_description` helper

Sometimes we want to ensure that two descriptions are always identical.
For example, to keep a type field description the same as a mutation argument
when they both represent the same property.

Instead of supplying a description, we can use the `copy_field_description` helper,
passing it the type, and field name to copy the description of.

Example:

```ruby
argument :title, GraphQL::Types::String,
          required: false,
          description: copy_field_description(Types::MergeRequestType, :title)
```

### Documentation references

Sometimes we want to refer to external URLs in our descriptions. To make this
easier, and provide proper markup in the generated reference documentation, we
provide a `see` property on fields. For example:

```ruby
field :genus,
      type: GraphQL::Types::String,
      null: true,
      description: 'A taxonomic genus.'
      see: { 'Wikipedia page on genera' => 'https://wikipedia.org/wiki/Genus' }
```

This renders in our documentation as:

```markdown
A taxonomic genus. See: [Wikipedia page on genera](https://wikipedia.org/wiki/Genus)
```

Multiple documentation references can be provided. The syntax for this property
is a `HashMap` where the keys are textual descriptions, and the values are URLs.

### Subscription tier badges

If a field or argument is available to higher subscription tiers than the other fields,
add the [availability details inline](documentation/styleguide/availability_details.md#inline-availability-details).

For example:

```ruby
description: 'Full path of a custom template. Premium and Ultimate only.'
```

## Authorization

See: [GraphQL Authorization](graphql_guide/authorization.md)

## Resolvers

We define how the application serves the response using _resolvers_
stored in the `app/graphql/resolvers` directory.
The resolver provides the actual implementation logic for retrieving
the objects in question.

To find objects to display in a field, we can add resolvers to
`app/graphql/resolvers`.

Arguments can be defined in the resolver in the same way as in a mutation.
See the [Arguments](#arguments) section.

To limit the amount of queries performed, we can use [BatchLoader](graphql_guide/batchloader.md).

### Writing resolvers

Our code should aim to be thin declarative wrappers around finders and [services](reusing_abstractions.md#service-classes). You can
repeat lists of arguments, or extract them to concerns. Composition is preferred over
inheritance in most cases. Treat resolvers like controllers: resolvers should be a DSL
that compose other application abstractions.

For example:

```ruby
class PostResolver < BaseResolver
  type Post.connection_type, null: true
  authorize :read_blog
  description 'Blog posts, optionally filtered by name'

  argument :name, [::GraphQL::Types::String], required: false, as: :slug

  alias_method :blog, :object

  def resolve(**args)
    PostFinder.new(blog, current_user, args).execute
  end
end
```

While you can use the same resolver class in two different places,
such as in two different fields where the same object is exposed,
you should never re-use resolver objects directly. Resolvers have a complex lifecycle, with
authorization, readiness and resolution orchestrated by the framework, and at
each stage [lazy values](#laziness) can be returned to take advantage of batching
opportunities. Never instantiate a resolver or a mutation in application code.

Instead, the units of code reuse are much the same as in the rest of the
application:

- Finders in queries to look up data.
- Services in mutations to apply operations.
- Loaders (batch-aware finders) specific to queries.

There is never any reason to use batching in a mutation. Mutations are
executed in series, so there are no batching opportunities. All values are
evaluated eagerly as soon as they are requested, so batching is unnecessary
overhead. If you are writing:

- A `Mutation`, feel free to lookup objects directly.
- A `Resolver` or methods on a `BaseObject`, then you want to allow for batching.

### Error handling

Resolvers may raise errors, which are converted to top-level errors as
appropriate. All anticipated errors should be caught and transformed to an
appropriate GraphQL error (see
[`Gitlab::Graphql::Errors`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/graphql/errors.rb)).
Any uncaught errors are suppressed and the client receives the message
`Internal service error`.

The one special case is permission errors. In the REST API we return
`404 Not Found` for any resources that the user does not have permission to
access. The equivalent behavior in GraphQL is for us to return `null` for
all absent or unauthorized resources.
Query resolvers **should not raise errors for unauthorized resources**.

The rationale for this is that clients must not be able to distinguish between
the absence of a record and the presence of one they do not have access to. To
do so is a security vulnerability, because it leaks information we want to keep
hidden.

In most cases you don't need to worry about this - this is handled correctly by
the resolver field authorization we declare with the `authorize` DSL calls. If
you need to do something more custom however, remember, if you encounter an
object the `current_user` does not have access to when resolving a field, then
the entire field should resolve to `null`.

### Deriving resolvers

(including `BaseResolver.single` and `BaseResolver.last`)

For some use cases, we can derive resolvers from others.
The main use case for this is one resolver to find all items, and another to
find one specific one. For this, we supply convenience methods:

- `BaseResolver.single`, which constructs a new resolver that selects the first item.
- `BaseResolver.last`, which constructs a resolver that selects the last item.

The correct singular type is inferred from the collection type, so we don't have
to define the `type` here.

Before you make use of these methods, consider if it would be simpler to either:

- Write another resolver that defines its own arguments.
- Write a concern that abstracts out the query.

Using `BaseResolver.single` too freely is an anti-pattern. It can lead to
non-sensical fields, such as a `Project.mergeRequest` field that just returns
the first MR if no arguments are given. Whenever we derive a single resolver
from a collection resolver, it must have more restrictive arguments.

To make this possible, use the `when_single` block to customize the single
resolver. Every `when_single` block must:

- Define (or re-define) at least one argument.
- Make optional filters required.

For example, we can do this by redefining an existing optional argument,
changing its type and making it required:

```ruby
class JobsResolver < BaseResolver
  type JobType.connection_type, null: true
  authorize :read_pipeline

  argument :name, [::GraphQL::Types::String], required: false

  when_single do
    argument :name, ::GraphQL::Types::String, required: true
  end

  def resolve(**args)
    JobsFinder.new(pipeline, current_user, args.compact).execute
  end
```

Here we have a resolver for getting pipeline jobs. The `name` argument is
optional when getting a list, but required when getting a single job.

If there are multiple arguments, and neither can be made required, we can use
the block to add a ready condition:

```ruby
class JobsResolver < BaseResolver
  alias_method :pipeline, :object

  type JobType.connection_type, null: true
  authorize :read_pipeline

  argument :name, [::GraphQL::Types::String], required: false
  argument :id, [::Types::GlobalIDType[::Job]],
           required: false,
           prepare: ->(ids, ctx) { ids.map(&:model_id) }

  when_single do
    argument :name, ::GraphQL::Types::String, required: false
    argument :id, ::Types::GlobalIDType[::Job],
             required: false
             prepare: ->(id, ctx) { id.model_id }

    def ready?(**args)
      raise ::Gitlab::Graphql::Errors::ArgumentError, 'Only one argument may be provided' unless args.size == 1
    end
  end

  def resolve(**args)
    JobsFinder.new(pipeline, current_user, args.compact).execute
  end
```

Then we can use these resolver on fields:

```ruby
# In PipelineType

field :jobs, resolver: JobsResolver, description: 'All jobs.'
field :job, resolver: JobsResolver.single, description: 'A single job.'
```

### Optimizing Resolvers

#### Look-Ahead

The full query is known in advance during execution, which means we can make use
of [lookahead](https://graphql-ruby.org/queries/lookahead.html) to optimize our
queries, and batch load associations we know we need. Consider adding
lookahead support in your resolvers to avoid `N+1` performance issues.

To enable support for common lookahead use-cases (pre-loading associations when
child fields are requested), you can
include [`LooksAhead`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/resolvers/concerns/looks_ahead.rb). For example:

```ruby
# Assuming a model `MyThing` with attributes `[child_attribute, other_attribute, nested]`,
# where nested has an attribute named `included_attribute`.
class MyThingResolver < BaseResolver
  include LooksAhead

  # Rather than defining `resolve(**args)`, we implement: `resolve_with_lookahead(**args)`
  def resolve_with_lookahead(**args)
    apply_lookahead(MyThingFinder.new(current_user).execute)
  end

  # We list things that should always be preloaded:
  # For example, if child_attribute is always needed (during authorization
  # perhaps), then we can include it here.
  def unconditional_includes
    [:child_attribute]
  end

  # We list things that should be included if a certain field is selected:
  def preloads
    {
        field_one: [:other_attribute],
        field_two: [{ nested: [:included_attribute] }]
    }
  end
end
```

By default, fields defined in `#preloads` are preloaded if that field
is selected in the query. Occasionally, finer control may be
needed to avoid preloading too much or incorrect content.

Extending the above example, we might want to preload a different
association if certain fields are requested together. This can
be done by overriding `#filtered_preloads`:

```ruby
class MyThingResolver < BaseResolver
  # ...

  def filtered_preloads
    return [:alternate_attribute] if lookahead.selects?(:field_one) && lookahead.selects?(:field_two)

    super
  end
end
```

The `LooksAhead` concern also provides basic support for preloading associations based on nested GraphQL field
definitions. The [WorkItemsResolver](https://gitlab.com/gitlab-org/gitlab/-/blob/e824a7e39e08a83fb162db6851de147cf0bfe14a/app/graphql/resolvers/work_items_resolver.rb#L46)
is a good example for this. `nested_preloads` is another method you can define to return a hash, but unlike the
`preloads` method, the value for each hash key is another hash and not the list of associations to preload. So in
the previous example, you could override `nested_preloads` like this:

```ruby
class MyThingResolver < BaseResolver
  # ...

  def nested_preloads
    {
      root_field: {
        nested_field1: :association_to_preload,
        nested_field2: [:association1, :association2]
      }
    }
  end
end
```

For an example of real world use,
see [`ResolvesMergeRequests`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/resolvers/concerns/resolves_merge_requests.rb).

#### `before_connection_authorization`

A `before_connection_authorization` hook can help resolvers eliminate N+1 problems that originate from
[type authorization](graphql_guide/authorization.md#type-authorization) permission checks.

The `before_connection_authorization` method receives the resolved nodes and the current user. In
the block, use `ActiveRecord::Associations::Preloader` or a `Preloaders::` class to preload data
for the type authorization check.

Example:

```ruby
class LabelsResolver < BaseResolver
  before_connection_authorization do |labels, current_user|
    Preloaders::LabelsPreloader.new(labels, current_user).preload_all
  end
end
```

#### BatchLoading

See [GraphQL BatchLoader](graphql_guide/batchloader.md).

### Correct use of `Resolver#ready?`

Resolvers have two public API methods as part of the framework: `#ready?(**args)` and `#resolve(**args)`.
We can use `#ready?` to perform set-up or early-return without invoking `#resolve`.

Good reasons to use `#ready?` include:

- Returning `Relation.none` if we know before-hand that no results are possible.
- Performing setup such as initializing instance variables (although consider lazily initialized methods for this).

Implementations of [`Resolver#ready?(**args)`](https://graphql-ruby.org/api-doc/1.10.9/GraphQL/Schema/Resolver#ready%3F-instance_method) should
return `(Boolean, early_return_data)` as follows:

```ruby
def ready?(**args)
  [false, 'have this instead']
end
```

For this reason, whenever you call a resolver (mainly in tests because framework
abstractions Resolvers should not be considered re-usable, finders are to be
preferred), remember to call the `ready?` method and check the boolean flag
before calling `resolve`! An example can be seen in our [`GraphqlHelpers`](https://gitlab.com/gitlab-org/gitlab/-/blob/2d395f32d2efbb713f7bc861f96147a2a67e92f2/spec/support/helpers/graphql_helpers.rb#L20-27).

For validating arguments, [validators](https://graphql-ruby.org/fields/validation.html) are preferred over using `#ready?`.

### Negated arguments

Negated filters can filter some resources (for example, find all issues that
have the `bug` label, but don't have the `bug2` label assigned). The `not`
argument is the preferred syntax to pass negated arguments:

```graphql
issues(labelName: "bug", not: {labelName: "bug2"}) {
  nodes {
    id
    title
  }
}
```

You can use the `negated` helper from `Gitlab::Graphql::NegatableArguments` in your type or resolver.
For example:

```ruby
extend ::Gitlab::Graphql::NegatableArguments

negated do
  argument :labels, [GraphQL::STRING_TYPE],
            required: false,
            as: :label_name,
            description: 'Array of label names. All resolved merge requests will not have these labels.'
end
```

### Metadata

When using resolvers, they can and should serve as the SSoT for field metadata.
All field options (apart from the field name) can be declared on the resolver.
These include:

- `type` (required - all resolvers must include a type annotation)
- `extras`
- `description`
- Gitaly annotations (with `calls_gitaly!`)

Example:

```ruby
module Resolvers
  MyResolver < BaseResolver
    type Types::MyType, null: true
    extras [:lookahead]
    description 'Retrieve a single MyType'
    calls_gitaly!
  end
end
```

### Pass a parent object into a child Presenter

Sometimes you need to access the resolved query parent in a child context to compute fields. Usually the parent is only
available in the `Resolver` class as `parent`.

To find the parent object in your `Presenter` class:

1. Add the parent object to the GraphQL `context` from your resolver's `resolve` method:

   ```ruby
     def resolve(**args)
       context[:parent_object] = parent
     end
   ```

1. Declare that your resolver or fields require the `parent` field context. For example:

   ```ruby
     # in ChildType
     field :computed_field, SomeType, null: true,
           method: :my_computing_method,
           extras: [:parent], # Necessary
           description: 'My field description.'

     field :resolver_field, resolver: SomeTypeResolver

     # In SomeTypeResolver

     extras [:parent]
     type SomeType, null: true
     description 'My field description.'
   ```

1. Declare your field's method in your Presenter class and have it accept the `parent` keyword argument.
   This argument contains the parent **GraphQL context**, so you have to access the parent object with
   `parent[:parent_object]` or whatever key you used in your `Resolver`:

   ```ruby
     # in ChildPresenter
     def my_computing_method(parent:)
       # do something with `parent[:parent_object]` here
     end

     # In SomeTypeResolver

     def resolve(parent:)
       # ...
     end
   ```

For an example of real-world use, check [this MR that added `scopedPath` and `scopedUrl` to `IterationPresenter`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39543)

## Mutations

Mutations are used to change any stored values, or to trigger
actions. In the same way a GET-request should not modify data, we
cannot modify data in a regular GraphQL-query. We can however in a
mutation.

### Building Mutations

Mutations are stored in `app/graphql/mutations`, ideally grouped per
resources they are mutating, similar to our services. They should
inherit `Mutations::BaseMutation`. The fields defined on the mutation
are returned as the result of the mutation.

#### Update mutation granularity

The service-oriented architecture in GitLab means that most mutations call a Create, Delete, or Update
service, for example `UpdateMergeRequestService`.
For Update mutations, you might want to only update one aspect of an object, and thus only need a
_fine-grained_ mutation, for example `MergeRequest::SetDraft`.

It's acceptable to have both fine-grained mutations and coarse-grained mutations, but be aware
that too many fine-grained mutations can lead to organizational challenges in maintainability, code
comprehensibility, and testing.
Each mutation requires a new class, which can lead to technical debt.
It also means the schema becomes very big, which can make it difficult for users to navigate our schema.
As each new mutation also needs tests (including slower request integration tests), adding mutations
slows down the test suite.

To minimize changes:

- Use existing mutations, such as `MergeRequest::Update`, when available.
- Expose existing services as a coarse-grained mutation.

When a fine-grained mutation might be more appropriate:

- Modifying a property that requires specific permissions or other specialized logic.
- Exposing a state-machine-like transition (locking issues, merging MRs, closing epics, etc).
- Accepting nested properties (where we accept properties for a child object).
- The semantics of the mutation can be expressed clearly and concisely.

See [issue #233063](https://gitlab.com/gitlab-org/gitlab/-/issues/233063) for further context.

### Naming conventions

Each mutation must define a `graphql_name`, which is the name of the mutation in the GraphQL schema.

Example:

```ruby
class UserUpdateMutation < BaseMutation
  graphql_name 'UserUpdate'
end
```

Due to changes in the `1.13` version of the `graphql-ruby` gem, `graphql_name` should be the first
line of the class to ensure that type names are generated correctly. The `Graphql::GraphqlNamePosition` cop enforces this.
See [issue #27536](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27536#note_840245581) for further context.

Our GraphQL mutation names are historically inconsistent, but new mutation names should follow the
convention `'{Resource}{Action}'` or `'{Resource}{Action}{Attribute}'`.

Mutations that **create** new resources should use the verb `Create`.

Example:

- `CommitCreate`

Mutations that **update** data should use:

- The verb `Update`.
- A domain-specific verb like `Set`, `Add`, or `Toggle` if more appropriate.

Examples:

- `EpicTreeReorder`
- `IssueSetWeight`
- `IssueUpdate`
- `TodoMarkDone`

Mutations that **remove** data should use:

- The verb `Delete` rather than `Destroy`.
- A domain-specific verb like `Remove` if more appropriate.

Examples:

- `AwardEmojiRemove`
- `NoteDelete`

If you need advice for mutation naming, canvass the Slack `#graphql` channel for feedback.

### Fields

In the most common situations, a mutation would return 2 fields:

- The resource being modified
- A list of errors explaining why the action could not be
  performed. If the mutation succeeded, this list would be empty.

By inheriting any new mutations from `Mutations::BaseMutation` the
`errors` field is automatically added. A `clientMutationId` field is
also added, this can be used by the client to identify the result of a
single mutation when multiple are performed in a single request.

### The `resolve` method

Similar to [writing resolvers](#writing-resolvers), the `resolve` method of a mutation
should aim to be a thin declarative wrapper around a
[service](reusing_abstractions.md#service-classes).

The `resolve` method receives the mutation's arguments as keyword arguments.
From here, we can call the service that modifies the resource.

The `resolve` method should then return a hash with the same field
names as defined on the mutation including an `errors` array. For example,
the `Mutations::MergeRequests::SetDraft` defines a `merge_request`
field:

```ruby
field :merge_request,
      Types::MergeRequestType,
      null: true,
      description: "The merge request after mutation."
```

This means that the hash returned from `resolve` in this mutation
should look like this:

```ruby
{
  # The merge request modified, this will be wrapped in the type
  # defined on the field
  merge_request: merge_request,
  # An array of strings if the mutation failed after authorization.
  # The `errors_on_object` helper collects `errors.full_messages`
  errors: errors_on_object(merge_request)
}
```

### Mounting the mutation

To make the mutation available it must be defined on the mutation
type that is stored in `graphql/types/mutation_type`. The
`mount_mutation` helper method defines a field based on the
GraphQL-name of the mutation:

```ruby
module Types
  class MutationType < BaseObject
    graphql_name 'Mutation'

    include Gitlab::Graphql::MountMutation

    mount_mutation Mutations::MergeRequests::SetDraft
  end
end
```

Generates a field called `mergeRequestSetDraft` that
`Mutations::MergeRequests::SetDraft` to be resolved.

### Authorizing resources

To authorize resources inside a mutation, we first provide the required
 abilities on the mutation like this:

```ruby
module Mutations
  module MergeRequests
    class SetDraft < Base
      graphql_name 'MergeRequestSetDraft'

      authorize :update_merge_request
    end
  end
end
```

We can then call `authorize!` in the `resolve` method, passing in the resource we
want to validate the abilities for.

Alternatively, we can add a `find_object` method that loads the
object on the mutation. This would allow you to use the
`authorized_find!` helper method.

When a user is not allowed to perform the action, or an object is not
found, we should raise a
`Gitlab::Graphql::Errors::ResourceNotAvailable` by calling `raise_resource_not_available_error!`
from in the `resolve` method.

### Errors in mutations

We encourage following the practice of
[errors as data](https://graphql-ruby.org/mutations/mutation_errors) for mutations, which
distinguishes errors by who they are relevant to, defined by who can deal with
them.

Key points:

- All mutation responses have an `errors` field. This should be populated on
  failure, and may be populated on success.
- Consider who needs to see the error: the **user** or the **developer**.
- Clients should always request the `errors` field when performing mutations.
- Errors may be reported to users either at `$root.errors` (top-level error) or at
  `$root.data.mutationName.errors` (mutation errors). The location depends on what kind of error
  this is, and what information it holds.
- Mutation fields [must have `null: true`](https://graphql-ruby.org/mutations/mutation_errors#nullable-mutation-payload-fields)

Consider an example mutation `doTheThing` that returns a response with
two fields: `errors: [String]`, and `thing: ThingType`. The specific nature of
the `thing` itself is irrelevant to these examples, as we are considering the
errors.

The three states a mutation response can be in are:

- [Success](#success)
- [Failure (relevant to the user)](#failure-relevant-to-the-user)
- [Failure (irrelevant to the user)](#failure-irrelevant-to-the-user)

#### Success

In the happy path, errors *may* be returned, along with the anticipated payload, but
if everything was successful, then `errors` should be an empty array, because
there are no problems we need to inform the user of.

```javascript
{
  data: {
    doTheThing: {
      errors: [] // if successful, this array will generally be empty.
      thing: { .. }
    }
  }
}
```

#### Failure (relevant to the user)

An error that affects the **user** occurred. We refer to these as _mutation errors_.

In a _create_ mutation there is typically no `thing` to return.

In an _update_ mutation we return the current true state of `thing`. Developers may need to call `#reset` on the `thing` instance to ensure this happens.

```javascript
{
  data: {
    doTheThing: {
      errors: ["you cannot touch the thing"],
      thing: { .. }
    }
  }
}
```

Examples of this include:

- Model validation errors: the user may need to change the inputs.
- Permission errors: the user needs to know they cannot do this, they may need to request permission or sign in.
- Problems with the application state that prevent the user's action (for example, merge conflicts or a locked resource).

Ideally, we should prevent the user from getting this far, but if they do, they
need to be told what is wrong, so they understand the reason for the failure and
what they can do to achieve their intent. For example, they might only need to retry the
request.

It is possible to return *recoverable* errors alongside mutation data. For example, if
a user uploads 10 files and 3 of them fail and the rest succeed, the errors for the
failures can be made available to the user, alongside the information about
the successes.

#### Failure (irrelevant to the user)

One or more *non-recoverable* errors can be returned at the _top level_. These
are things over which the **user** has little to no control, and should mainly
be system or programming problems, that a **developer** needs to know about.
In this case there is no `data`:

```javascript
{
  errors: [
    {"message": "argument error: expected an integer, got null"},
  ]
}
```

This results from raising an error during the mutation. In our implementation,
the messages of argument errors and validation errors are returned to the client, and all other
`StandardError` instances are caught, logged and presented to the client with the message set to `"Internal server error"`.
See [`GraphqlController`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/graphql_controller.rb) for details.

These represent programming errors, such as:

- A GraphQL syntax error, where an `Int` was passed instead of a `String`, or a required argument was not present.
- Errors in our schema, such as being unable to provide a value for a non-nullable field.
- System errors: for example, a Git storage exception, or database unavailability.

The user should not be able to cause such errors in regular usage. This category
of errors should be treated as internal, and not shown to the user in specific
detail.

We need to inform the user when the mutation fails, but we do not need to
tell them why, because they cannot have caused it, and nothing they can do
fixes it, although we may offer to retry the mutation.

#### Categorizing errors

When we write mutations, we need to be conscious about which of
these two categories an error state falls into (and communicate about this with
frontend developers to verify our assumptions). This means distinguishing the
needs of the _user_ from the needs of the _client_.

> _Never catch an error unless the user needs to know about it._

If the user does need to know about it, communicate with frontend developers
to make sure the error information we are passing back is relevant and serves a purpose.

See also the [frontend GraphQL guide](fe_guide/graphql.md#handling-errors).

### Aliasing and deprecating mutations

The `#mount_aliased_mutation` helper allows us to alias a mutation as
another name in `MutationType`.

For example, to alias a mutation called `FooMutation` as `BarMutation`:

```ruby
mount_aliased_mutation 'BarMutation', Mutations::FooMutation
```

This allows us to rename a mutation and continue to support the old name,
when coupled with the [`deprecated`](#deprecating-schema-items)
argument.

Example:

```ruby
mount_aliased_mutation 'UpdateFoo',
                        Mutations::Foo::Update,
                        deprecated: { reason: 'Use fooUpdate', milestone: '13.2' }
```

Deprecated mutations should be added to `Types::DeprecatedMutations` and
tested for in the unit test of `Types::MutationType`. The merge request
[!34798](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34798)
can be referred to as an example of this, including the method of testing
deprecated aliased mutations.

#### Deprecating EE mutations

EE mutations should follow the same process. For an example of the merge request
process, read [merge request !42588](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42588).

## Subscriptions

We use subscriptions to push updates to clients. We use the [Action Cable implementation](https://graphql-ruby.org/subscriptions/action_cable_implementation)
to deliver the messages over websockets.

When a client subscribes to a subscription, we store their query in-memory in Puma workers. Then when the subscription is triggered,
the Puma workers execute the stored GraphQL queries and push the results to the clients.

NOTE:
We cannot test subscriptions using GraphiQL, because they require an Action Cable client, which GraphiQL does not support at the moment.

### Building subscriptions

All fields under `Types::SubscriptionType` are subscriptions that clients can subscribe to. These fields require a subscription class,
which is a descendant of `Subscriptions::BaseSubscription` and is stored under `app/graphql/subscriptions`.

The arguments required to subscribe and the fields that are returned are defined in the subscription class. Multiple fields can share
the same subscription class if they have the same arguments and return the same fields.

This class runs during the initial subscription request and subsequent updates. You can read more about this in the
[GraphQL Ruby guides](https://graphql-ruby.org/subscriptions/subscription_classes).

### Authorization

You should implement the `#authorized?` method of the subscription class so that the initial subscription and subsequent updates are authorized.

When a user is not authorized, you should call the `unauthorized!` helper so that execution is halted and the user is unsubscribed. Returning `false`
results in redaction of the response, but we leak information that some updates are happening. This leakage is due to a
[bug in the GraphQL gem](https://github.com/rmosolgo/graphql-ruby/issues/3390).

### Triggering subscriptions

Define a method under the `GraphqlTriggers` module to trigger a subscription. Do not call `GitlabSchema.subscriptions.trigger` directly in application
code so that we have a single source of truth and we do not trigger a subscription with different arguments and objects.

## Pagination implementation

For more information, see [GraphQL pagination](graphql_guide/pagination.md).

## Arguments

[Arguments](https://graphql-ruby.org/fields/arguments.html) for a resolver or mutation are defined using `argument`.

Example:

```ruby
argument :my_arg, GraphQL::Types::String,
         required: true,
         description: "A description of the argument."
```

### Nullability

Arguments can be marked as `required: true` which means the value must be present and not `null`.
If a required argument's value can be `null`, use the `required: :nullable` declaration.

Example:

```ruby
argument :due_date,
         Types::TimeType,
         required: :nullable,
         description: 'The desired due date for the issue. Due date is removed if null.'
```

In the above example, the `due_date` argument must be given, but unlike the GraphQL spec, the value can be `null`.
This allows 'unsetting' the due date in a single mutation rather than creating a new mutation for removing the due date.

```ruby
{ due_date: null } # => OK
{ due_date: "2025-01-10" } # => OK
{  } # => invalid (not given)
```

#### Nullability and required: false

If an argument is marked `required: false` the client is permitted to send `null` as a value.
Often this is undesirable.

If an argument is optional but `null` is not an allowed value, use validation to ensure that passing `null` returns an error:

```ruby
argument :name, GraphQL::Types::String,
         required: false,
         validates: { allow_null: false }
```

Alternatively, if you wish to allow `null` when it is not an allowed value, you can replace it with a default value:

```ruby
argument :name, GraphQL::Types::String,
         required: false,
         default_value: "No Name Provided",
         replace_null_with_default: true
```

See [Validation](https://graphql-ruby.org/fields/validation.html),
[Nullability](https://graphql-ruby.org/fields/arguments.html#nullability) and
[Default Values](https://graphql-ruby.org/fields/arguments.html#default-values) for more details.

### Mutually exclusive arguments

Arguments can be marked as mutually exclusive, ensuring that they are not provided at the same time.
When more than one of the listed arguments are given, a top-level error will be added.

Example:

```ruby
argument :user_id, GraphQL::Types::String, required: false
argument :username, GraphQL::Types::String, required: false

validates mutually_exclusive: [:user_id, :username]
```

When exactly one argument is required, you can use the `exactly_one_of` validator.

Example:

```ruby
argument :group_path, GraphQL::Types::String, required: false
argument :project_path, GraphQL::Types::String, required: false

validates exactly_one_of: [:group_path, :project_path]
```

### Keywords

Each GraphQL `argument` defined is passed to the `#resolve` method
of a mutation as keyword arguments.

Example:

```ruby
def resolve(my_arg:)
  # Perform mutation ...
end
```

### Input Types

`graphql-ruby` wraps up arguments into an
[input type](https://graphql.org/learn/schema/#input-types).

For example, the
[`mergeRequestSetDraft` mutation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/mutations/merge_requests/set_draft.rb)
defines these arguments (some
[through inheritance](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/mutations/merge_requests/base.rb)):

```ruby
argument :project_path, GraphQL::Types::ID,
         required: true,
         description: "Project the merge request belongs to."

argument :iid, GraphQL::Types::String,
         required: true,
         description: "IID of the merge request."

argument :draft,
         GraphQL::Types::Boolean,
         required: false,
         description: <<~DESC
           Whether or not to set the merge request as a draft.
         DESC
```

These arguments automatically generate an input type called
`MergeRequestSetDraftInput` with the 3 arguments we specified and the
`clientMutationId`.

### Object identifier arguments

Arguments that identify an object should be:

- [A full path](#full-path-object-identifier-arguments) or [an IID](#iid-object-identifier-arguments) if an object has either.
- [The object's Global ID](#global-id-object-identifier-arguments) for all other objects. Never use plain database primary key IDs.

#### Full path object identifier arguments

Historically we have been inconsistent with the naming of full path arguments, but prefer to name the argument:

- `project_path` for a project full path
- `group_path` for a group full path
- `namespace_path` for a namespace full path

Using an example from the
[`ciJobTokenScopeRemoveProject` mutation](https://gitlab.com/gitlab-org/gitlab/-/blob/c40d5637f965e724c496f3cd1392cd8e493237e2/app/graphql/mutations/ci/job_token_scope/remove_project.rb#L13-15):

```ruby
argument :project_path, GraphQL::Types::ID,
         required: true,
         description: 'Project the CI job token scope belongs to.'
```

#### IID object identifier arguments

Use the `iid` of an object in combination with its parent `project_path` or `group_path`. For example:

```ruby
argument :project_path, GraphQL::Types::ID,
         required: true,
         description: 'Project the issue belongs to.'

argument :iid, GraphQL::Types::String,
         required: true,
         description: 'IID of the issue.'
```

#### Global ID object identifier arguments

Using an example from the
[`discussionToggleResolve` mutation](https://gitlab.com/gitlab-org/gitlab/-/blob/3a9d20e72225dd82fe4e1a14e3dd1ffcd0fe81fa/app/graphql/mutations/discussions/toggle_resolve.rb#L10-13):

```ruby
argument :id, Types::GlobalIDType[Discussion],
         required: true,
         description: 'Global ID of the discussion.'
```

See also [Deprecate Global IDs](#deprecate-global-ids).

### Sort arguments

Sort arguments should use an [enum type](#enums) whenever possible to describe the set of available sorting values.

The enum can inherit from `Types::SortEnum` to inherit some common values.

The enum values should follow the format `{PROPERTY}_{DIRECTION}`. For example:

```plaintext
TITLE_ASC
```

Also see the [description style guide for sort enums](#sort-enums).

Example from [`ContainerRepositoriesResolver`](https://gitlab.com/gitlab-org/gitlab/-/blob/dad474605a06c8ed5404978b0a9bd187e9fded80/app/graphql/resolvers/container_repositories_resolver.rb#L13-16):

```ruby
# Types::ContainerRegistry::ContainerRepositorySortEnum:
module Types
  module ContainerRegistry
    class ContainerRepositorySortEnum < SortEnum
      graphql_name 'ContainerRepositorySort'
      description 'Values for sorting container repositories'

      value 'NAME_ASC', 'Name by ascending order.', value: :name_asc
      value 'NAME_DESC', 'Name by descending order.', value: :name_desc
    end
  end
end

# Resolvers::ContainerRepositoriesResolver:
argument :sort, Types::ContainerRegistry::ContainerRepositorySortEnum,
          description: 'Sort container repositories by this criteria.',
          required: false,
          default_value: :created_desc
```

## GitLab custom scalars

### `Types::TimeType`

[`Types::TimeType`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app%2Fgraphql%2Ftypes%2Ftime_type.rb)
must be used as the type for all fields and arguments that deal with Ruby
`Time` and `DateTime` objects.

The type is
[a custom scalar](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/type_definitions/scalars.md#custom-scalars)
that:

- Converts Ruby's `Time` and `DateTime` objects into standardized
  ISO-8601 formatted strings, when used as the type for our GraphQL fields.
- Converts ISO-8601 formatted time strings into Ruby `Time` objects,
  when used as the type for our GraphQL arguments.

This allows our GraphQL API to have a standardized way that it presents time
and handles time inputs.

Example:

```ruby
field :created_at, Types::TimeType, null: true, description: 'Timestamp of when the issue was created.'
```

### Global ID scalars

All of our [Global IDs](#global-ids) are custom scalars. They are
[dynamically created](https://gitlab.com/gitlab-org/gitlab/-/blob/45b3c596ef8b181bc893bd3b71613edf66064936/app/graphql/types/global_id_type.rb#L46)
from the abstract scalar class
[`Types::GlobalIDType`](https://gitlab.com/gitlab-org/gitlab/-/blob/45b3c596ef8b181bc893bd3b71613edf66064936/app/graphql/types/global_id_type.rb#L4).

## Testing

For testing mutations and resolvers, consider the unit of
test a full GraphQL request, not a call to a resolver. This allows us to
avoid tight coupling to the framework because such coupling makes
upgrades to dependencies much more difficult.

You should:

- Prefer request specs (either using the full API endpoint or going through
  `GitlabSchema.execute`) to unit specs for resolvers and mutations.
- Prefer `GraphqlHelpers#execute_query` and `GraphqlHelpers#run_with_clean_state` to
  `GraphqlHelpers#resolve` and `GraphqlHelpers#resolve_field`.

For example:

```ruby
# Good:
gql_query = %q(some query text...)
post_graphql(gql_query, current_user: current_user)
# or:
GitlabSchema.execute(gql_query, context: { current_user: current_user })

# Deprecated: avoid
resolve(described_class, obj: project, ctx: { current_user: current_user })
```

### Writing unit tests (deprecated)

WARNING:
Avoid writing unit tests if the same thing can be tested with
a full GraphQL request.

Before creating unit tests, review the following examples:

- [`spec/graphql/resolvers/users_resolver_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/graphql/resolvers/users_resolver_spec.rb)
- [`spec/graphql/mutations/issues/create_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/graphql/mutations/issues/create_spec.rb)

### Writing integration tests

Integration tests check the full stack for a GraphQL query or mutation and are stored in
`spec/requests/api/graphql`.

For speed, consider calling `GitlabSchema.execute` directly, or making use
of smaller test schemas that only contain the types under test.

However, full request integration tests that check if data is returned verify the following
additional items:

- The mutation is actually queryable in the schema (was mounted in `MutationType`).
- The data returned by a resolver or mutation correctly matches the
  [return types](https://graphql-ruby.org/fields/introduction.html#field-return-type) of
  the fields and resolves without errors.
- The arguments coerce correctly on input, and the fields serialize correctly
  on output.

Integration tests can also verify the following items, because they invoke the
full stack:

- An argument or scalar's validations apply correctly.
- Logic in a resolver or mutation's [`#ready?` method](#correct-use-of-resolverready) applies correctly.
- An [argument's `default_value`](https://graphql-ruby.org/fields/arguments.html) applies correctly.
- Objects resolve successfully, and there are no N+1 issues.

When adding a query, you can use the `a working graphql query that returns data` and
`a working graphql query that returns no data` shared examples to test if the query renders valid results.

You can construct a query including all available fields using the `GraphqlHelpers#all_graphql_fields_for`
helper. This makes it more straightforward to add a test rendering all possible fields for a query.

If you're adding a field to a query that supports pagination and sorting,
visit [Testing](graphql_guide/pagination.md#testing) for details.

To test GraphQL mutation requests, `GraphqlHelpers` provides two
helpers: `graphql_mutation` which takes the name of the mutation, and
a hash with the input for the mutation. This returns a struct with
a mutation query, and prepared variables.

You can then pass this struct to the `post_graphql_mutation` helper,
that posts the request with the correct parameters, like a GraphQL
client would do.

To access the response of a mutation, you can use the `graphql_mutation_response`
helper.

Using these helpers, you can build specs like this:

```ruby
let(:mutation) do
  graphql_mutation(
    :merge_request_set_wip,
    project_path: 'gitlab-org/gitlab-foss',
    iid: '1',
    wip: true
  )
end

it 'returns a successful response' do
   post_graphql_mutation(mutation, current_user: user)

   expect(response).to have_gitlab_http_status(:success)
   expect(graphql_mutation_response(:merge_request_set_wip)['errors']).to be_empty
end
```

### Testing tips and tricks

- Become familiar with the methods in the `GraphqlHelpers` support module.
  Many of these methods make writing GraphQL tests easier.

- Use traversal helpers like `GraphqlHelpers#graphql_data_at` and
  `GraphqlHelpers#graphql_dig_at` to access result fields. For example:

  ```ruby
  result = GitlabSchema.execute(query)

  mr_iid = graphql_dig_at(result.to_h, :data, :project, :merge_request, :iid)
  ```

- Use `GraphqlHelpers#a_graphql_entity_for` to match against results.
  For example:

  ```ruby
  post_graphql(some_query)

  # checks that it is a hash containing { id => global_id_of(issue) }
  expect(graphql_data_at(:project, :issues, :nodes))
    .to contain_exactly(a_graphql_entity_for(issue))

  # Additional fields can be passed, either as names of methods, or with values
  expect(graphql_data_at(:project, :issues, :nodes))
    .to contain_exactly(a_graphql_entity_for(issue, :iid, :title, created_at: some_time))
  ```

- Use `GraphqlHelpers#empty_schema` to create an empty schema, rather than creating
  one by hand. For example:

  ```ruby
  # good
  let(:schema) { empty_schema }

  # bad
  let(:query_type) { GraphQL::ObjectType.new }
  let(:schema) { GraphQL::Schema.define(query: query_type, mutation: nil)}
  ```

- Use `GraphqlHelpers#query_double(schema: nil)` of `double('query', schema: nil)`. For example:

  ```ruby
  # good
  let(:query) { query_double(schema: GitlabSchema) }

  # bad
  let(:query) { double('Query', schema: GitlabSchema) }
  ```

- Avoid false positives:

  Authenticating a user with the `current_user:` argument for `post_graphql`
  generates more queries on the first request than on subsequent requests on that
  same user. If you are testing for N+1 queries using
  [QueryRecorder](database/query_recorder.md), use a **different** user for each request.

  The below example shows how a test for avoiding N+1 queries should look:

  ```ruby
  RSpec.describe 'Query.project(fullPath).pipelines' do
    include GraphqlHelpers

    let(:project) { create(:project) }

    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                id
              }
            }
          }
        }
      )
    end

    it 'avoids N+1 queries' do
      first_user = create(:user)
      second_user = create(:user)
      create(:ci_pipeline, project: project)

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: first_user)
      end

      create(:ci_pipeline, project: project)

      expect do
        post_graphql(query, current_user: second_user)  # use a different user to avoid a false positive from authentication queries
      end.not_to exceed_query_limit(control_count)
    end
  end
  ```

- Mimic the folder structure of `app/graphql/types`:

  For example, tests for fields on `Types::Ci::PipelineType`
  in `app/graphql/types/ci/pipeline_type.rb` should be stored in
  `spec/requests/api/graphql/ci/pipeline_spec.rb` regardless of the query being
  used to fetch the pipeline data.

- When testing resolvers using `GraphqlHelpers#resolve`, arguments for the resolver can be handled two ways.

  1. 95% of the resolver specs use arguments that are Ruby objects, as opposed to when using the GraphQL API
     only strings and integers are used. This works fine in most cases.
  1. If your resolver takes arguments that use a `prepare` proc, such as a resolver that accepts time frame
     arguments (`TimeFrameArguments`), you must pass the `arg_style: :internal_prepared` parameter into
     the `resolve` method. This tells the code to convert the arguments into strings and integers and pass
     them through regular argument handling, ensuring that the `prepare` proc is called correctly.
     For example in [`iterations_resolver_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/graphql/resolvers/iterations_resolver_spec.rb):

     ```ruby
     def resolve_group_iterations(args = {}, obj = group, context = { current_user: current_user })
       resolve(described_class, obj: obj, args: args, ctx: context, arg_style: :internal_prepared)
     end
     ```

     One additional caveat is that if you are passing enums as a resolver argument, you must use the
     external representation of the enum, rather than the internal. For example:

     ```ruby
     # good
     resolve_group_iterations({ search: search, in: ['CADENCE_TITLE'] })

     # bad
     resolve_group_iterations({ search: search, in: [:cadence_title] })
     ```

  The use of `:internal_prepared` was added as a bridge for the
  [GraphQL gem](https://graphql-ruby.org) upgrade. Testing resolvers directly will
  [eventually be removed](https://gitlab.com/gitlab-org/gitlab/-/issues/363121),
  and writing unit tests for resolvers/mutations is
  [already deprecated](#writing-unit-tests-deprecated)

## Notes about Query flow and GraphQL infrastructure

The GitLab GraphQL infrastructure can be found in `lib/gitlab/graphql`.

[Instrumentation](https://graphql-ruby.org/queries/instrumentation.html) is functionality
that wraps around a query being executed. It is implemented as a module that uses the `Instrumentation` class.

Example: `Present`

```ruby
module Gitlab
  module Graphql
    module Present
      #... some code above...

      def self.use(schema_definition)
        schema_definition.instrument(:field, ::Gitlab::Graphql::Present::Instrumentation.new)
      end
    end
  end
end
```

A [Query Analyzer](https://graphql-ruby.org/queries/ast_analysis.html#analyzer-api) contains a series
of callbacks to validate queries before they are executed. Each field can pass through
the analyzer, and the final value is also available to you.

[Multiplex queries](https://graphql-ruby.org/queries/multiplex.html) enable
multiple queries to be sent in a single request. This reduces the number of requests sent to the server.
(there are custom Multiplex Query Analyzers and Multiplex Instrumentation provided by GraphQL Ruby).

### Query limits

Queries and mutations are limited by depth, complexity, and recursion
to protect server resources from overly ambitious or malicious queries.
These values can be set as defaults and overridden in specific queries as needed.
The complexity values can be set per object as well, and the final query complexity is
evaluated based on how many objects are being returned. This can be used
for objects that are expensive (such as requiring Gitaly calls).

For example, a conditional complexity method in a resolver:

```ruby
def self.resolver_complexity(args, child_complexity:)
  complexity = super
  complexity += 2 if args[:labelName]

  complexity
end
```

More about complexity:
[GraphQL Ruby documentation](https://graphql-ruby.org/queries/complexity_and_depth.html).

## Documentation and schema

Our schema is located at `app/graphql/gitlab_schema.rb`.
See the [schema reference](../api/graphql/reference/_index.md) for details.

This generated GraphQL documentation needs to be updated when the schema changes.
For information on generating GraphQL documentation and schema files, see
[updating the schema documentation](rake_tasks.md#update-graphql-documentation-and-schema-definitions).

To help our readers, you should also add a new page to our [GraphQL API](../api/graphql/_index.md) documentation.
For guidance, see the [GraphQL API](documentation/graphql_styleguide.md) page.

## Include a changelog entry

All client-facing changes **must** include a [changelog entry](changelog.md).

## Laziness

One important technique unique to GraphQL for managing performance is
using **lazy** values. Lazy values represent the promise of a result,
allowing their action to be run later, which enables batching of queries in
different parts of the query tree. The main example of lazy values in our code is
the [GraphQL BatchLoader](graphql_guide/batchloader.md).

To manage lazy values directly, read `Gitlab::Graphql::Lazy`, and in
particular `Gitlab::Graphql::Laziness`. This contains `#force` and
`#delay`, which help implement the basic operations of creation and
elimination of laziness, where needed.

For dealing with lazy values without forcing them, use
`Gitlab::Graphql::Lazy.with_value`.
