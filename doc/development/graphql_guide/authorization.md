---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GraphQL Authorization
---

Authorizations can be applied in these places:

- Types:
  - Objects (all classes descending from `::Types::BaseObject`)
  - Enums (all classes descending from `::Types::BaseEnum`)
- Resolvers:
  - Field resolvers (all classes descending from `::Types::BaseResolver`)
  - Mutations (all classes descending from `::Types::BaseMutation`)
- Fields (all fields declared using the `field` DSL method)

Authorizations cannot be specified for abstract types (interfaces and
unions). Abstract types delegate to their member types.
Basic built in scalars (such as integers) do not have authorizations.

Our authorization system uses the same [`DeclarativePolicy`](../policies.md)
system as throughout the rest of the application.

- For single values (such as `Query.project`), if the currently authenticated
  user fails the authorization, the field resolves to `null`.
- For collections (such as `Project.issues`), the collection is filtered to
  exclude the objects that the user's authorization checks failed against. This
  process of filtering (also known as _redaction_) happens after pagination, so
  some pages may be smaller than the requested page size, due to redacted
  objects being removed.

Also see [authorizing resources in a mutation](../api_graphql_styleguide.md#authorizing-resources).

NOTE:
The best practice is to load only what the currently authenticated user is allowed to
view with our existing finders first, without relying on authorization
to filter the records. This minimizes database queries and unnecessary
authorization checks of the loaded records. It also avoids situations,
such as short pages, which can expose the presence of confidential resources.

See [`authorization_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/graphql/features/authorization_spec.rb)
for examples of all the authorization schemes discussed here.

<!--
    NOTE: if you change this heading (or the location to this file), make sure to update
          the referenced link in rubocop/cop/graphql/authorize_types.rb
-->

## Type authorization

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

## Resolver authorization

Resolvers can have their own authorizations, which can be applied either to the
parent object or to the resolved values.

An example of a resolver that authorizes against the parent is
`Resolvers::BoardListsResolver`, which requires that the parent
satisfy `:read_list` before it runs.

An example which authorizes against the resolved resource is
`Resolvers::Ci::ConfigResolver`, which requires that the resolved value satisfy
`:read_pipeline`.

To authorize against the parent, the resolver must _opt in_ (because this
was not the default value initially), by declaring this with `authorizes_object!`:

```ruby
module Resolvers
  class MyResolver < BaseResolver
    authorizes_object!

    authorize :some_permission
  end
end
```

To authorize against the resolved value, the resolver must apply the
authorization at some point, typically by using `#authorized_find!(**args)`:

```ruby
module Resolvers
  class MyResolver < BaseResolver
    authorize :some_permission

    def resolve(**args)
      authorized_find!(**args) # calls find_object
    end

    def find_object(id:)
      MyThing.find(id)
    end
  end
end
```

Of the two approaches, authorizing the object is more efficient, because it
helps avoid unnecessary queries.

## Field authorization

Fields can be authorized with the `authorize` option.

Fields authorization is checked against the current object, and
authorization happens _before_ resolution, which means that
fields do not have access to the resolved resource. If you need to
apply an authorization check to a field, you probably want to add
authorization to the resolver, or ideally to the type.

For example, the following authorization ensures that the
authenticated user must have administrator level access to the project
to view the `secretName` field:

```ruby
module Types
  class ProjectType < BaseObject
    field :secret_name, ::GraphQL::Types::String, null: true, authorize: :owner_access
  end
end
```

In this example, we use field authorization (such as
`Ability.allowed?(current_user, :read_transactions, bank_account)`) to avoid
a more expensive query:

```ruby
module Types
  class BankAccountType < BaseObject
    field :transactions, ::Types::TransactionType.connection_type, null: true,
      authorize: :read_transactions
  end
end
```

Field authorization is recommended for:

- Scalar fields (strings, booleans, or numbers) that should have different levels
  of access controls to other fields.
- Object and collection fields where an access check can be applied to the
  parent to save the field resolution, and avoid individual policy checks
  on each resolved object.

Field authorization does not replace object level checks, unless the object
precisely matches the access level of the parent project. For example, issues
can be confidential, independent of the access level of the parent. Therefore,
we should not use field authorization for `Project.issue`.

You can also authorize fields against multiple abilities. Pass the abilities
as an array instead of as a single value:

```ruby
module Types
  class MyType < BaseObject
    field :hidden_field, ::GraphQL::Types::Int,
      null: true,
      authorize: [:owner_access, :another_ability]
  end
end
```

The field authorization on `MyType.hiddenField` implies the following tests:

```ruby
Ability.allowed?(current_user, :owner_access, object_of_my_type) &&
    Ability.allowed?(current_user, :another_ability, object_of_my_type)
```

## Type and Field authorizations together

Authorizations are cumulative. In other words, the currently authenticated
user may need to pass authorization requirements on both a field and a field's
type.

In the following simplified example the currently authenticated user
needs both `first_permission` on the user and `second_permission` on the
issue to see the author of the issue.

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

The combination of the object authorization on `UserType` and the field authorization on `IssueType.author` implies the following tests:

```ruby
Ability.allowed?(current_user, :second_permission, issue) &&
  Ability.allowed?(current_user, :first_permission, issue.author)
```

### Skip Type authorization for a given field

In some scenarios, a given field is resolved with a dedicated `resolver` and the resolver takes care of checking the
resolved objects' authorization.

In such cases, especially when the field resolves a collection of objects, we'd like to skip the `Type` level
authorization. Depending on the GraphQL query, having these overlapping authorization checks, can add significant overhead.

For such situations, we can specify which abilities should be skipped at `Type` level by specifying the list of abilities
through `skip_type_authorization` on a given field. This option cascades down to all descendant fields as well.

For a real-world example, see
[field :discussions, Types::Notes::DiscussionType](https://gitlab.com/gitlab-org/gitlab/-/blob/84721e500a9a95e22bfd1b34c228db0053b793fb/app/graphql/types/work_items/widgets/notes_type.rb#L24).

In that example, we have `DiscussionType` which specifies `authorize :read_note`. `Discussion` is composed of multiple `notes` of type `NoteType` and `NoteType` also specifies `authorize: :read_note`.
Some of these `notes` may be system notes and may have some specific metadata of type `SystemNoteMetadataType`.
`SystemNoteMetadataType` also specifies the `authorize: :read_note`. Each note can have emojis, which are authorized
with `read_emoji`, which is equivalent to `read_note` in this case.

To represent this in a GraphQL example, we'd have following types:

```ruby
class SomeType < BaseObject
  field :discussions, Types::Notes::DiscussionType.connection_type, null: true, resolver: SomeResolver
end

class DiscussionType < BaseObject
  authorize :read_note

  field :notes, Types::Notes::NoteType.connection_type, null: true
end

class NoteType < BaseObject
  authorize :read_note

  field :system_note_metadata, SystemNoteMetadataType
  field :award_emoji, AwardEmojiType
end

class SystemNoteMetadataType < BaseObject
  authorize :read_note
end

class AwardEmojiType < BaseObject
  authorize :read_emoji
end
```

And a query like:

```graphql
query {
  someType(identified: ID) {
    discussions {
      nodes {
        notes {
          nodes {
            award_emoji {
              name
            }
          }
        }
      }
    }
  }
}
```

Let's say the root object of type `SomeType` has 10 discussions. Each of the 10 discussions have 10 notes. And the first note of each discussion has one emoji.

In this case, we authorize the discussions in `SomeResolver`, that is 10 authorization calls.
Then when we represent each discussion with `DiscussionType`, we authorize each discussion object, again 10 calls. These
specific calls may be fine, as these would have been cached in the request store during resolver authorization because we are authorizing the same objects.
Next, we authorize each note for these 10 discussions, resulting in 10*10 = 100 authorization calls. And lastly for the
first note in each discussion, we would authorize one emoji, that is another 10 calls. So in total we have 130 authorization calls:

- 10 discussions authorized in resolver
- 10 (cached) discussions authorized through `DiscussionType`
- 100 notes authorized through `NoteType`
- 10 emoji authorized through `EmojiType`

We can reduce these 130 calls to just 10 calls by specifying the `skip_type_authorization` on the `discussions` field.
For that, `SomeType` definition changes to:

```ruby
class SomeType < BaseObject
  field :discussions, Types::Notes::DiscussionType.connection_type, null: true, resolver: SomeResolver,
        skip_type_authorization: [:read_note, :read_emoji]
end
```

NOTE:
We can optimize the authorization calls with `skip_type_authorization` in this case, because:

- We already authorize the discussions in `SomeResolver`
- Permissions to read one note or all notes are the same for a discussion
- Permission to read a note or read an emoji are equivalent
