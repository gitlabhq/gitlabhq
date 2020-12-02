---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GraphQL API style guide

This document outlines the style guide for GitLab's [GraphQL API](../api/graphql/index.md).

## How GitLab implements GraphQL

We use the [GraphQL Ruby gem](https://graphql-ruby.org/) written by [Robert Mosolgo](https://github.com/rmosolgo/).

All GraphQL queries are directed to a single endpoint
([`app/controllers/graphql_controller.rb#execute`](https://gitlab.com/gitlab-org/gitlab/blob/master/app%2Fcontrollers%2Fgraphql_controller.rb)),
which is exposed as an API endpoint at `/api/graphql`.

## Deep Dive

In March 2019, Nick Thomas hosted a Deep Dive (GitLab team members only: `https://gitlab.com/gitlab-org/create-stage/issues/1`)
on GitLab's [GraphQL API](../api/graphql/index.md) to share his domain specific knowledge
with anyone who may work in this part of the codebase in the future. You can find the
[recording on YouTube](https://www.youtube.com/watch?v=-9L_1MWrjkg), and the slides on
[Google Slides](https://docs.google.com/presentation/d/1qOTxpkTdHIp1CRjuTvO-aXg0_rUtzE3ETfLUdnBB5uQ/edit)
and in [PDF](https://gitlab.com/gitlab-org/create-stage/uploads/8e78ea7f326b2ef649e7d7d569c26d56/GraphQL_Deep_Dive__Create_.pdf).
Everything covered in this deep dive was accurate as of GitLab 11.9, and while specific
details may have changed since then, it should still serve as a good introduction.

## GraphiQL

GraphiQL is an interactive GraphQL API explorer where you can play around with existing queries.
You can access it in any GitLab environment on `https://<your-gitlab-site.com>/-/graphql-explorer`.
For example, the one for [GitLab.com](https://gitlab.com/-/graphql-explorer).

## Authentication

Authentication happens through the `GraphqlController`, right now this
uses the same authentication as the Rails application. So the session
can be shared.

It's also possible to add a `private_token` to the query string, or
add a `HTTP_PRIVATE_TOKEN` header.

## Global IDs

GitLab's GraphQL API uses Global IDs (i.e: `"gid://gitlab/MyObject/123"`)
and never database primary key IDs.

Global ID is [a convention](https://graphql.org/learn/global-object-identification/)
used for caching and fetching in client-side libraries.

See also:

- [Exposing Global IDs](#exposing-global-ids).
- [Mutation arguments](#object-identifier-arguments).

We have a custom scalar type (`Types::GlobalIDType`) which should be used as the
type of input and output arguments when the value is a `GlobalID`. The benefits
of using this type instead of `ID` are:

- it validates that the value is a `GlobalID`
- it parses it into a `GlobalID` before passing it to user code
- it can be parameterized on the type of the object (e.g.
  `GlobalIDType[Project]`) which offers even better validation and security.

Consider using this type for all new arguments and result types. Remember that
it is perfectly possible to parameterize this type with a concern or a
supertype, if you want to accept a wider range of objects (e.g.
`GlobalIDType[Issuable]` vs `GlobalIDType[Issue]`).

## Types

We use a code-first schema, and we declare what type everything is in Ruby.

For example, `app/graphql/types/issue_type.rb`:

```ruby
graphql_name 'Issue'

field :iid, GraphQL::ID_TYPE, null: true
field :title, GraphQL::STRING_TYPE, null: true

# we also have a method here that we've defined, that extends `field`
markdown_field :title_html, null: true
field :description, GraphQL::STRING_TYPE, null: true
markdown_field :description_html, null: true
```

We give each type a name (in this case `Issue`).

The `iid`, `title` and `description` are _scalar_ GraphQL types.
`iid` is a `GraphQL::ID_TYPE`, a special string type that signifies a unique ID.
`title` and `description` are regular `GraphQL::STRING_TYPE` types.

When exposing a model through the GraphQL API, we do so by creating a
new type in `app/graphql/types`. You can also declare custom GraphQL data types
for scalar data types (for example `TimeType`).

When exposing properties in a type, make sure to keep the logic inside
the definition as minimal as possible. Instead, consider moving any
logic into a presenter:

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
to become optional in the future, and very easy to calculate. An example would
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
- [GraphQL Best Practices Guide](https://graphql.org/learn/best-practices/#nullability)
- [Using nullability in GraphQL](https://www.apollographql.com/blog/using-nullability-in-graphql-2254f84c4ed7)

### Exposing Global IDs

In keeping with GitLab's use of [Global IDs](#global-ids), always convert
database primary key IDs into Global IDs when you expose them.

All fields named `id` are
[converted automatically](https://gitlab.com/gitlab-org/gitlab/-/blob/b0f56e7/app/graphql/types/base_object.rb#L11-14)
into the object's Global ID.

Fields that are not named `id` need to be manually converted. We can do this using
[`Gitlab::GlobalID.build`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/global_id.rb),
or by calling `#to_global_id` on an object that has mixed in the
`GlobalID::Identification` module.

Using an example from
[`Types::Notes::DiscussionType`](https://gitlab.com/gitlab-org/gitlab/-/blob/3c95bd9/app/graphql/types/notes/discussion_type.rb#L24-26):

```ruby
field :reply_id, GraphQL::ID_TYPE

def reply_id
  ::Gitlab::GlobalId.build(object, id: object.reply_id)
end
```

### Connection types

TIP: **Tip:**
For specifics on implementation, see [Pagination implementation](#pagination-implementation).

GraphQL uses [cursor based
pagination](https://graphql.org/learn/pagination/#pagination-and-edges)
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
key, in descending order. This is usually `id`, so we add `order(id: :desc)`
to the end of the relation. A primary key _must_ be available on the underlying table.

#### Shortcut fields

Sometimes it can seem easy to implement a "shortcut field", having the resolver return the first of a collection if no parameters are passed.
These "shortcut fields" are discouraged because they create maintenance overhead.
They need to be kept in sync with their canonical field, and deprecated or modified if their canonical field changes.
Use the functionality the framework provides unless there is a compelling reason to do otherwise.

For example, instead of `latest_pipeline`, use `pipelines(last: 1)`.

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
  present_using MergeRequestPresenter

  graphql_name 'MergeRequestPermissions'

  abilities :admin_merge_request, :update_merge_request, :create_note

  ability_field :resolve_note,
                description: 'Indicates the user can resolve discussions on the merge request'
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

Developers can add [feature flags](../development/feature_flags/index.md) to GraphQL
fields in the following ways:

- Add the `feature_flag` property to a field. This allows the field to be _hidden_
  from the GraphQL schema when the flag is disabled.
- Toggle the return value when resolving the field.

You can refer to these guidelines to decide which approach to use:

- If your field is experimental, and its name or type is subject to
  change, use the `feature_flag` property.
- If your field is stable and its definition doesn't change, even after the flag is
  removed, toggle the return value of the field instead. Note that
  [all fields should be nullable](#nullable-fields) anyway.

### `feature_flag` property

The `feature_flag` property allows you to toggle the field's
[visibility](https://graphql-ruby.org/authorization/visibility.html)
within the GraphQL schema. This removes the field from the schema
when the flag is disabled.

A description is [appended](https://gitlab.com/gitlab-org/gitlab/-/blob/497b556/app/graphql/types/base_field.rb#L44-53)
to the field indicating that it is behind a feature flag.

CAUTION: **Caution:**
If a client queries for the field when the feature flag is disabled, the query
fails. Consider this when toggling the visibility of the feature on or off on
production.

The `feature_flag` property does not allow the use of
[feature gates based on actors](../development/feature_flags/development.md).
This means that the feature flag cannot be toggled only for particular
projects, groups, or users, but instead can only be toggled globally for
everyone.

Example:

```ruby
field :test_field, type: GraphQL::STRING_TYPE,
      null: true,
      description: 'Some test field',
      feature_flag: :my_feature_flag
```

### Toggle the value of a field

This method of using feature flags for fields is to toggle the
return value of the field. This can be done in the resolver, in the
type, or even in a model method, depending on your preference and
situation.

When applying a feature flag to toggle the value of a field, the
`description` of the field must:

- State that the value of the field can be toggled by a feature flag.
- Name the feature flag.
- State what the field returns when the feature flag is disabled (or
  enabled, if more appropriate).

Example:

```ruby
field :foo, GraphQL::STRING_TYPE,
      null: true,
      description: 'Some test field. Will always return `null`' \
                   'if `my_feature_flag` feature flag is disabled'

def foo
  object.foo if Feature.enabled?(:my_feature_flag, object)
end
```

## Deprecating fields and enum values

GitLab's GraphQL API is versionless, which means we maintain backwards
compatibility with older versions of the API with every change. Rather
than removing a field or [enum value](#enums), we need to _deprecate_ it instead.
The deprecated parts of the schema can then be removed in a future release
in accordance with [GitLab's deprecation process](../api/graphql/index.md#deprecation-process).

Fields and enum values are deprecated using the `deprecated` property.
The value of the property is a `Hash` of:

- `reason` - Reason for the deprecation.
- `milestone` - Milestone that the field was deprecated.

Example:

```ruby
field :token, GraphQL::STRING_TYPE, null: true,
      deprecated: { reason: 'Login via token has been removed', milestone: '10.0' },
      description: 'Token for login'
```

The original `description` of the things being deprecated should be maintained,
and should _not_ be updated to mention the deprecation. Instead, the `reason`
is appended to the `description`.

### Deprecation reason style guide

Where the reason for deprecation is due to the field or enum value being
replaced, the `reason` must be:

```plaintext
Use `otherFieldName`
```

Example:

```ruby
field :designs, ::Types::DesignManagement::DesignCollectionType, null: true,
      deprecated: { reason: 'Use `designCollection`', milestone: '10.0' },
      description: 'The designs associated with this issue',
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

If the field is not being replaced by another field, a descriptive
deprecation `reason` should be given.

See also [Aliasing and deprecating mutations](#aliasing-and-deprecating-mutations).

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

    value 'RED', description: 'Drivers must stop'
    value 'YELLOW', description: 'Drivers must stop when it is safe to'
    value 'GREEN', description: 'Drivers can start or keep driving'
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

    value 'OPENED', value: 'opened', description: 'An open Epic'
    value 'CLOSED', value: 'closed', description: 'An closed Epic'
  end
end
```

Enum values can be deprecated using the
[`deprecated` keyword](#deprecating-fields-and-enum-values).

### Defining GraphQL enums dynamically from Rails enums

If your GraphQL enum is backed by a [Rails enum](creating_enums.md), then consider
using the Rails enum to dynamically define the GraphQL enum values. Doing so
binds the GraphQL enum values to the Rails enum definition, so if values are
ever added to the Rails enum then the GraphQL enum automatically reflects the change.

Example:

```ruby
module Types
  class IssuableSeverityEnum < BaseEnum
    graphql_name 'IssuableSeverity'
    description 'Incident severity'

    ::IssuableSeverity.severities.keys.each do |severity|
      value severity.upcase, value: severity, description: "#{severity.titleize} severity"
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

For example, given the following simple JSON data:

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
    field :title, GraphQL::STRING_TYPE, null: true, description: 'Title of the chart'
    field :data, [Types::ChartDatumType], null: true, description: 'Data of the chart'
  end
end

module Types
  class ChartDatumType < BaseObject
    field :x, GraphQL::INT_TYPE, null: true, description: 'X-axis value of the chart datum'
    field :y, GraphQL::INT_TYPE, null: true, description: 'Y-axis value of the chart datum'
  end
end
```

## Descriptions

All fields and arguments
[must have descriptions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16438).

A description of a field or argument is given using the `description:`
keyword. For example:

```ruby
field :id, GraphQL::ID_TYPE, description: 'ID of the resource'
```

Descriptions of fields and arguments are viewable to users through:

- The [GraphiQL explorer](#graphiql).
- The [static GraphQL API reference](../api/graphql/#reference).

### Description style guide

To ensure consistency, the following should be followed whenever adding or updating
descriptions:

- Mention the name of the resource in the description. Example:
  `'Labels of the issue'` (issue being the resource).
- Use `"{x} of the {y}"` where possible. Example: `'Title of the issue'`.
  Do not start descriptions with `The`.
- Descriptions of `GraphQL::BOOLEAN_TYPE` fields should answer the question: "What does
  this field do?". Example: `'Indicates project has a Git repository'`.
- Always include the word `"timestamp"` when describing an argument or
  field of type `Types::TimeType`. This lets the reader know that the
  format of the property is `Time`, rather than just `Date`.
- No `.` at end of strings.

Example:

```ruby
field :id, GraphQL::ID_TYPE, description: 'ID of the Issue'
field :confidential, GraphQL::BOOLEAN_TYPE, description: 'Indicates the issue is confidential'
field :closed_at, Types::TimeType, description: 'Timestamp of when the issue was closed'
```

### `copy_field_description` helper

Sometimes we want to ensure that two descriptions are always identical.
For example, to keep a type field description the same as a mutation argument
when they both represent the same property.

Instead of supplying a description, we can use the `copy_field_description` helper,
passing it the type, and field name to copy the description of.

Example:

```ruby
argument :title, GraphQL::STRING_TYPE,
          required: false,
          description: copy_field_description(Types::MergeRequestType, :title)
```

## Authorization

Authorizations can be applied to both types and fields using the same
abilities as in the Rails app.

If the:

- Currently authenticated user fails the authorization, the authorized
  resource is returned as `null`.
- Resource is part of a collection, the collection is filtered to
  exclude the objects that the user's authorization checks failed against.

Also see [authorizing resources in a mutation](#authorizing-resources).

TIP: **Tip:**
Try to load only what the currently authenticated user is allowed to
view with our existing finders first, without relying on authorization
to filter the records. This minimizes database queries and unnecessary
authorization checks of the loaded records.

### Type authorization

Authorize a type by passing an ability to the `authorize` method. All
fields with the same type is authorized by checking that the
currently authenticated user has the required ability.

For example, the following authorization ensures that the currently
authenticated user can only see projects that they have the
`read_project` ability for (so long as the project is returned in a
field that uses `Types::ProjectType`):

```ruby
module Types
  class ProjectType < BaseObject
    authorize :read_project
  end
end
```

You can also authorize against multiple abilities, in which case all of
the ability checks must pass.

For example, the following authorization ensures that the currently
authenticated user must have `read_project` and `another_ability`
abilities to see a project:

```ruby
module Types
  class ProjectType < BaseObject
    authorize [:read_project, :another_ability]
  end
end
```

### Field authorization

Fields can be authorized with the `authorize` option.

For example, the following authorization ensures that the currently
authenticated user must have the `owner_access` ability to see the
project:

```ruby
module Types
  class MyType < BaseObject
    field :project, Types::ProjectType, null: true, resolver: Resolvers::ProjectResolver, authorize: :owner_access
  end
end
```

Fields can also be authorized against multiple abilities, in which case
all of ability checks must pass. This requires explicitly
passing a block to `field`:

```ruby
module Types
  class MyType < BaseObject
    field :project, Types::ProjectType, null: true, resolver: Resolvers::ProjectResolver do
      authorize [:owner_access, :another_ability]
    end
  end
end
```

If the field's type already [has a particular
authorization](#type-authorization) then there is no need to add that
same authorization to the field.

### Type and Field authorizations together

Authorizations are cumulative, so where authorizations are defined on
a field, and also on the field's type, then the currently authenticated
user would need to pass all ability checks.

In the following simplified example the currently authenticated user
would need both `first_permission` and `second_permission` abilities in
order to see the author of the issue.

```ruby
class UserType
  authorize :first_permission
end
```

```ruby
class IssueType
  field :author, UserType, authorize: :second_permission
end
```

## Resolvers

We define how the application serves the response using _resolvers_
stored in the `app/graphql/resolvers` directory.
The resolver provides the actual implementation logic for retrieving
the objects in question.

To find objects to display in a field, we can add resolvers to
`app/graphql/resolvers`.

Arguments can be defined within the resolver in the same way as in a mutation.
See the [Mutation arguments](#object-identifier-arguments) section.

To limit the amount of queries performed, we can use [BatchLoader](graphql_guide/batchloader.md).

### Writing resolvers

Our code should aim to be thin declarative wrappers around finders and services. You can
repeat lists of arguments, or extract them to concerns. Composition is preferred over
inheritance in most cases. Treat resolvers like controllers: resolvers should be a DSL
that compose other application abstractions.

For example:

```ruby
class PostResolver < BaseResolver
  type Post.connection_type, null: true
  authorize :read_blog
  description 'Blog posts, optionally filtered by name'

  argument :name, [::GraphQL::STRING_TYPE], required: false, as: :slug

  alias_method :blog, :object

  def resolve(**args)
    PostFinder.new(blog, current_user, args).execute
  end
end
```

You should never re-use resolvers directly. Resolvers have a complex life-cycle, with
authorization, readiness and resolution orchestrated by the framework, and at
each stage lazy values can be returned to take advantage of batching
opportunities. Never instantiate a resolver or a mutation in application code.

Instead, the units of code reuse are much the same as in the rest of the
application:

- Finders in queries to look up data.
- Services in mutations to apply operations.
- Loaders (batch-aware finders) specific to queries.

Note that there is never any reason to use batching in a mutation. Mutations are
executed in series, so there are no batching opportunities. All values are
evaluated eagerly as soon as they are requested, so batching is unnecessary
overhead. If you are writing:

- A `Mutation`, feel free to lookup objects directly.
- A `Resolver` or methods on a `BaseObject`, then you want to allow for batching.

### Deriving resolvers (`BaseResolver.single` and `BaseResolver.last`)

For some simple use cases, we can derive resolvers from others.
The main use case for this is one resolver to find all items, and another to
find one specific one. For this, we supply convenience methods:

- `BaseResolver.single`, which constructs a new resolver that selects the first item.
- `BaseResolver.last`, with constructs a resolver that selects the last item.

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

  argument :name, [::GraphQL::STRING_TYPE], required: false

  when_single do
    argument :name, ::GraphQL::STRING_TYPE, required: true
  end

  def resolve(**args)
    JobsFinder.new(pipeline, current_user, args.compact).execute
  end
```

Here we have a simple resolver for getting pipeline jobs. The `name` argument is
optional when getting a list, but required when getting a single job.

If there are multiple arguments, and neither can be made required, we can use
the block to add a ready condition:

```ruby
class JobsResolver < BaseResolver
  alias_method :pipeline, :object

  type JobType.connection_type, null: true
  authorize :read_pipeline

  argument :name, [::GraphQL::STRING_TYPE], required: false
  argument :id, [::Types::GlobalIDType[::Job]],
           required: false,
           prepare: ->(ids, ctx) { ids.map(&:model_id) }

  when_single do
    argument :name, ::GraphQL::STRING_TYPE, required: false
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

field :jobs, resolver: JobsResolver, description: 'All jobs'
field :job, resolver: JobsResolver.single, description: 'A single job'
```

### Correct use of `Resolver#ready?`

Resolvers have two public API methods as part of the framework: `#ready?(**args)` and `#resolve(**args)`.
We can use `#ready?` to perform set-up, validation or early-return without invoking `#resolve`.

Good reasons to use `#ready?` include:

- validating mutually exclusive arguments (see [validating arguments](#validating-arguments))
- Returning `Relation.none` if we know before-hand that no results are possible
- Performing setup such as initializing instance variables (although consider lazily initialized methods for this)

Implementations of [`Resolver#ready?(**args)`](https://graphql-ruby.org/api-doc/1.10.9/GraphQL/Schema/Resolver#ready%3F-instance_method) should
return `(Boolean, early_return_data)` as follows:

```ruby
def ready?(**args)
  [false, 'have this instead']
end
```

For this reason, whenever you call a resolver (mainly in tests - as framework
abstractions Resolvers should not be considered re-usable, finders are to be
preferred), remember to call the `ready?` method and check the boolean flag
before calling `resolve`! An example can be seen in our [`GraphQLHelpers`](https://gitlab.com/gitlab-org/gitlab/-/blob/2d395f32d2efbb713f7bc861f96147a2a67e92f2/spec/support/helpers/graphql_helpers.rb#L20-27).

### Look-Ahead

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

The final thing that is needed is that every field that uses this resolver needs
to advertise the need for lookahead:

```ruby
  # in ParentType
  field :my_things, MyThingType.connection_type, null: true,
        extras: [:lookahead], # Necessary
        resolver: MyThingResolver,
        description: 'My things'
```

For an example of real world use, please
see [`ResolvesMergeRequests`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/resolvers/concerns/resolves_merge_requests.rb).

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

To avoid duplicated argument definitions, you can place these arguments in a reusable module (or
class, if the arguments are nested). Alternatively, you can consider to add a
[helper resolver method](https://gitlab.com/gitlab-org/gitlab/-/issues/258969).

### Metadata

When using resolvers, they can and should serve as the SSoT for field metadata.
All field options (apart from the field name) can be declared on the resolver.
These include:

- `type` (this is particularly important, and is planned to be mandatory)
- `extras`
- `description`

Example:

```ruby
module Resolvers
  MyResolver < BaseResolver
    type Types::MyType, null: true
    extras [:lookahead]
    description 'Retrieve a single MyType'
  end
end
```

### Pass a parent object into a child Presenter

Sometimes you need to access the resolved query parent in a child context to compute fields. Usually the parent is only
available in the `Resolver` class as `parent`.

To find the parent object in your `Presenter` class:

1. Add the parent object to the GraphQL `context` from within your resolver's `resolve` method:

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
           description: 'My field description'

     field :resolver_field, resolver: SomeTypeResolver

     # In SomeTypeResolver

     extras [:parent]
     type SomeType, null: true
     description 'My field description'
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

GitLab's service-oriented architecture means that most mutations call a Create, Delete, or Update
service, for example `UpdateMergeRequestService`.
For Update mutations, a you might want to only update one aspect of an object, and thus only need a
_fine-grained_ mutation, for example `MergeRequest::SetWip`.

It's acceptable to have both fine-grained mutations and coarse-grained mutations, but be aware
that too many fine-grained mutations can lead to organizational challenges in maintainability, code
comprehensibility, and testing.
Each mutation requires a new class, which can lead to technical debt.
It also means the schema becomes very big, and we want users to easily navigate our schema.
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

### Arguments

Arguments for a mutation are defined using `argument`.

Example:

```ruby
argument :my_arg, GraphQL::STRING_TYPE,
         required: true,
         description: "A description of the argument"
```

Each GraphQL `argument` defined is passed to the `#resolve` method
of a mutation as keyword arguments.

Example:

```ruby
def resolve(my_arg:)
  # Perform mutation ...
end
```

`graphql-ruby` wraps up arguments into an
[input type](https://graphql.org/learn/schema/#input-types).

For example, the
[`mergeRequestSetWip` mutation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/mutations/merge_requests/set_wip.rb)
defines these arguments (some
[through inheritance](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/mutations/merge_requests/base.rb)):

```ruby
argument :project_path, GraphQL::ID_TYPE,
         required: true,
         description: "The project the merge request to mutate is in"

argument :iid, GraphQL::STRING_TYPE,
         required: true,
         description: "The iid of the merge request to mutate"

argument :wip,
         GraphQL::BOOLEAN_TYPE,
         required: false,
         description: <<~DESC
                      Whether or not to set the merge request as a WIP.
                      If not passed, the value will be toggled.
                      DESC
```

These arguments automatically generate an input type called
`MergeRequestSetWipInput` with the 3 arguments we specified and the
`clientMutationId`.

### Object identifier arguments

In keeping with GitLab's use of [Global IDs](#global-ids), mutation
arguments should use Global IDs to identify an object and never database
primary key IDs.

Where an object has an `iid`, prefer to use the `full_path` or `group_path`
of its parent in combination with its `iid` as arguments to identify an
object rather than its `id`.

### Fields

In the most common situations, a mutation would return 2 fields:

- The resource being modified
- A list of errors explaining why the action could not be
  performed. If the mutation succeeded, this list would be empty.

By inheriting any new mutations from `Mutations::BaseMutation` the
`errors` field is automatically added. A `clientMutationId` field is
also added, this can be used by the client to identify the result of a
single mutation when multiple are performed within a single request.

### The `resolve` method

The `resolve` method receives the mutation's arguments as keyword arguments.
From here, we can call the service that modifies the resource.

The `resolve` method should then return a hash with the same field
names as defined on the mutation including an `errors` array. For example,
the `Mutations::MergeRequests::SetWip` defines a `merge_request`
field:

```ruby
field :merge_request,
      Types::MergeRequestType,
      null: true,
      description: "The merge request after mutation"
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
type that lives in `graphql/types/mutation_types`. The
`mount_mutation` helper method defines a field based on the
GraphQL-name of the mutation:

```ruby
module Types
  class MutationType < BaseObject
    include Gitlab::Graphql::MountMutation

    graphql_name "Mutation"

    mount_mutation Mutations::MergeRequests::SetWip
  end
end
```

Generates a field called `mergeRequestSetWip` that
`Mutations::MergeRequests::SetWip` to be resolved.

### Authorizing resources

To authorize resources inside a mutation, we first provide the required
 abilities on the mutation like this:

```ruby
module Mutations
  module MergeRequests
    class SetWip < Base
      graphql_name 'MergeRequestSetWip'

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
`Gitlab::Graphql::Errors::ResourceNotAvailable` error which is
correctly rendered to the clients.

### Errors in mutations

We encourage following the practice of [errors as
data](https://graphql-ruby.org/mutations/mutation_errors) for mutations, which
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

Consider an example mutation `doTheThing` that returns a response with
two fields: `errors: [String]`, and `thing: ThingType`. The specific nature of
the `thing` itself is irrelevant to these examples, as we are considering the
errors.

There are three states a mutation response can be in:

- [Success](#success)
- [Failure (relevant to the user)](#failure-relevant-to-the-user)
- [Failure (irrelevant to the user)](#failure-irrelevant-to-the-user)

#### Success

In the happy path, errors *may* be returned, along with the anticipated payload, but
if everything was successful, then `errors` should be an empty array, since
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

An error that affects the **user** occurred. We refer to these as _mutation errors_. In
this case there is typically no `thing` to return:

```javascript
{
  data: {
    doTheThing: {
      errors: ["you cannot touch the thing"],
      thing: null
    }
  }
}
```

Examples of this include:

- Model validation errors: the user may need to change the inputs.
- Permission errors: the user needs to know they cannot do this, they may need to request permission or sign in.
- Problems with application state that prevent the user's action, for example: merge conflicts, the resource was locked, and so on.

Ideally, we should prevent the user from getting this far, but if they do, they
need to be told what is wrong, so they understand the reason for the failure and
what they can do to achieve their intent, even if that is as simple as retrying the
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

This is the result of raising an error during the mutation. In our implementation,
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
tell them why, since they cannot have caused it, and nothing they can do
fixes it, although we may offer to retry the mutation.

#### Categorizing errors

When we write mutations, we need to be conscious about which of
these two categories an error state falls into (and communicate about this with
frontend developers to verify our assumptions). This means distinguishing the
needs of the _user_ from the needs of the _client_.

> _Never catch an error unless the user needs to know about it._

If the user does need to know about it, communicate with frontend developers
to make sure the error information we are passing back is useful.

See also the [frontend GraphQL guide](../development/fe_guide/graphql.md#handling-errors).

### Aliasing and deprecating mutations

The `#mount_aliased_mutation` helper allows us to alias a mutation as
another name within `MutationType`.

For example, to alias a mutation called `FooMutation` as `BarMutation`:

```ruby
mount_aliased_mutation 'BarMutation', Mutations::FooMutation
```

This allows us to rename a mutation and continue to support the old name,
when coupled with the [`deprecated`](#deprecating-fields-and-enum-values)
argument.

Example:

```ruby
mount_aliased_mutation 'UpdateFoo',
                        Mutations::Foo::Update,
                        deprecated: { reason: 'Use fooUpdate', milestone: '13.2' }
```

Deprecated mutations should be added to `Types::DeprecatedMutations` and
tested for within the unit test of `Types::MutationType`. The merge request
[!34798](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34798)
can be referred to as an example of this, including the method of testing
deprecated aliased mutations.

#### Deprecating EE mutations

EE mutations should follow the same process. For an example of the merge request
process, read [merge request !42588](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42588).

## Pagination implementation

To learn more, visit [GraphQL pagination](graphql_guide/pagination.md).

## Validating arguments

For validations of single arguments, use the
[`prepare` option](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/fields/arguments.md)
as normal.

Sometimes a mutation or resolver may accept a number of optional
arguments, but we still want to validate that at least one of the optional
arguments is provided. In this situation, consider using the `#ready?`
method within your mutation or resolver to provide the validation. The
`#ready?` method is called before any work is done within the
`#resolve` method.

Example:

```ruby
def ready?(**args)
  if args.values_at(:body, :position).compact.blank?
    raise Gitlab::Graphql::Errors::ArgumentError,
          'body or position arguments are required'
  end

  # Always remember to call `#super`
  super
end
```

In the future this may be able to be done using `InputUnions` if
[this RFC](https://github.com/graphql/graphql-spec/blob/master/rfcs/InputUnion.md)
is merged.

## GitLab's custom scalars

### `Types::TimeType`

[`Types::TimeType`](https://gitlab.com/gitlab-org/gitlab/blob/master/app%2Fgraphql%2Ftypes%2Ftime_type.rb)
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
field :created_at, Types::TimeType, null: true, description: 'Timestamp of when the issue was created'
```

## Testing

_full stack_ tests for a graphql query or mutation live in
`spec/requests/api/graphql`.

When adding a query, the `a working graphql query` shared example can
be used to test if the query renders valid results.

Using the `GraphqlHelpers#all_graphql_fields_for`-helper, a query
including all available fields can be constructed. This makes it easy
to add a test rendering all possible fields for a query.

If you're adding a field to a query that supports pagination and sorting,
visit [Testing](graphql_guide/pagination.md#testing) for details.

To test GraphQL mutation requests, `GraphqlHelpers` provides 2
helpers: `graphql_mutation` which takes the name of the mutation, and
a hash with the input for the mutation. This returns a struct with
a mutation query, and prepared variables.

This struct can then be passed to the `post_graphql_mutation` helper,
that posts the request with the correct parameters, like a GraphQL
client would do.

To access the response of a mutation, the `graphql_mutation_response`
helper is available.

Using these helpers, we can build specs like this:

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

- Avoid false positives:

  Authenticating a user with the `current_user:` argument for `post_graphql`
  generates more queries on the first request than on subsequent requests on that
  same user. If you are testing for N+1 queries using
  [QueryRecorder](query_recorder.md), use a **different** user for each request.

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
  in `app/graphql/types/ci/pipeline_type.rb` should live in
  `spec/requests/api/graphql/ci/pipeline_spec.rb` regardless of the query being
  used to fetch the pipeline data.

## Notes about Query flow and GraphQL infrastructure

GitLab's GraphQL infrastructure can be found in `lib/gitlab/graphql`.

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
evaluated based on how many objects are being returned. This is useful
for objects that are expensive (e.g. requiring Gitaly calls).

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
See the [schema reference](../api/graphql/reference/index.md) for details.

This generated GraphQL documentation needs to be updated when the schema changes.
For information on generating GraphQL documentation and schema files, see
[updating the schema documentation](rake_tasks.md#update-graphql-documentation-and-schema-definitions).

To help our readers, you should also add a new page to our [GraphQL API](../api/graphql/index.md) documentation.
For guidance, see the [GraphQL API](documentation/graphql_styleguide.md) page.

## Include a changelog entry

All client-facing changes **must** include a [changelog entry](changelog.md).
