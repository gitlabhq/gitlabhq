# Serializers

This is a documentation for classes located in `app/serializers` directory.

In GitLab, we use [grape-entities][grape-entity-project], accompanied by a
serializer, to convert a Ruby object to its JSON representation.

Serializers are typically used in controllers to build a JSON response
that is usually consumed by a frontend code.

## Why using a serializer is important?

Using serializers, instead of `to_json` method, has several benefits:

* it helps to prevent exposure of a sensitive data stored in the database
* it makes it easier to test what should and should not be exposed
* it makes it easier to reuse serialization entities that are building blocks
* it makes it easier to move complexity from controllers to easily testable
  classes
* it encourages hiding complexity behind intentions-revealing interfaces
* it makes it easier to take care about serialization performance concerns
* it makes it easier to reduce merge conflicts between CE -> EE
* it makes it easier to benefit from domain driven development techniques

## What is a serializer?

A serializer is a class that encapsulates all business rules for building a
JSON response using serialization entities.

It is designed to be testable and to support passing additional context from
the controller.

## What is a serialization entity?

Entities are lightweight structures that allow to represent domain models
in a consistent and abstracted way, and reuse them as building blocks to
create a payload.

Entities located in `app/serializers` are usually derived from a
[`Grape::Entity`][grape-entity-class] class.

Serialization entities that do require to have a knowledge about specific
elements of the request, need to mix `RequestAwareEntity` in.

A serialization entity usually maps a domain model class into its JSON
representation. It rarely happens that a serialization entity exists without
a corresponding domain model class. As an example, we have an `Issue` class and
a corresponding `IssueSerializer`.

Serialization entities are designed to reuse other serialization entities, which
is a convenient way to create a multi-level JSON representation of a piece of
a domain model you want to serialize.

See [documentation for Grape Entities][grape-entity-readme] for more details.

## How to implement a serializer?

### Base implementation

In order to effectively implement a serializer it is necessary to create a new
class in `app/serializers`. See existing serializers as an example.

A new serializer should inherit from a `BaseSerializer` class. It is necessary
to specify which serialization entity will be used to serialize a resource.

```ruby
class MyResourceSerializer < BaseSerializer
  entity MyResourceEntity
end
```

The example above shows how a most simple serializer can look like.

Given that the entity `MyResourceEntity` exists, you can now use
`MyResourceSerializer` in the controller by creating an instance of it, and
calling `MyResourceSerializer#represent(resource)` method.

Note that a `resource` can be either a single object, an array of objects or an
`ActiveRecord::Relation` object. A serialization entity should be smart enough
to accurately represent each of these.

It should not be necessary to use `Enumerable#map`, and it should be avoided
from the performance reasons.

### Choosing what gets serialized

It often happens that you might want to use the same serializer in many places,
but sometimes the intention is to only expose a small subset of object's
attributes in one place, and a different subset in another.

`BaseSerializer#represent(resource, opts = {})` method can take an additional
hash argument, `opts`, that defines what is going to be serialized.

`BaseSerializer` will pass these options to a serialization entity. See
how it is [documented in the upstream project][grape-entity-only].

With this approach you can extend the serializer to respond to methods that will
create a JSON response according to your needs.

```ruby
class PipelineSerializer < BaseSerializer
  entity Ci::PipelineEntity

  def represent_details(resource)
    represent(resource, only: [:details])
  end

  def represent_status(resource)
    represent(resource, only: [:status])
  end
end
```

It is possible to use `only` and `except` keywords. Both keywords do support
nested attributes, like `except: [:id, { user: [:id] }]`.

Passing `only` and `except` to the `represent` method from a controller is
possible, but it defies principles of encapsulation and testability, and it is
better to avoid it, and to add a specific method to the serializer instead.

### Reusing serialization entities from the API

Public API in GitLab is implemented using [Grape][grape-project].

Under the hood it also uses [`Grape::Entity`][grape-entity-class] classes.
This means that it is possible to reuse these classes to implement internal
serializers.

You can either use such entity directly:

```ruby
class MyResourceSerializer < BaseSerializer
  entity API::Entities::SomeEntity
end
```

Or derive a new serialization entity class from it:

```ruby
class MyEntity < API::Entities::SomeEntity
  include RequestAwareEntity

  unexpose :something
end
```

It might be a good idea to write specs for entities that do inherit from
the API, because when API payloads are changed / extended, it is easy to forget
about the impact on the internal API through a serializer that reuses API
entities.

It is usually safe to do that, because API entities rarely break backward
compatibility, but additional exposure may have a performance impact when API
gets extended significantly. Write tests that check if only necessary data is
exposed.

## How to write tests for a serializer?

Like every other class in the project, creating a serializer warrants writing
tests for it.

It is usually a good idea to test each public method in the serializer against
a valid payload. `BaseSerializer#represent` returns a hash, so it is possible
to use usual RSpec matchers like `include`.

Sometimes, when the payload is large, it makes sense to validate it entirely
using `match_response_schema` matcher along with a new fixture that can be
stored in `spec/fixtures/api/schemas/`. This matcher is using a `json-schema`
gem, which is quite flexible, see a [documentation][json-schema-gem] for it.

## How to use a serializer in a controller?

Once a new serializer is implemented, it is possible to use it in a controller.

Create an instance of the serializer and render the response.

```ruby
def index
  format.json do
    render json: MyResourceSerializer
      .new(current_user: @current_user)
      .represent_details(@project.resources)
  end
end
```

If it is necessary to include additional information in the payload, it is
possible to extend what is going to be rendered, the usual way:

```ruby
def index
  format.json do
    render json: {
      resources: MyResourceSerializer
        .new(current_user: @current_user)
        .represent_details(@project.resources),
      count: @project.resources.count
    }
  end
end
```

Note that in these examples an additional context is being passed to the
serializer (`current_user: @current_user`).

## How to pass an additional context from the controller?

It is possible to pass an additional context from a controller to a
serializer and each serialization entity that is used in the process.

Serialization entities that do require an additional context have
`RequestAwareEntity` concern mixed in. This piece of the code exposes a method
called `request` in every serialization entity that is instantiated during
serialization.

An object returned by this method is an instance of `EntityRequest`, which
behaves like an `OpenStruct` object, with the difference that it will raise
an error if an unknown method is called.

In other words, in the previous example, `request` method will return an
instance of `EntityRequest` that responds to `current_user` method. It will be
available in every serialization entity instantiated by `MyResourceSerializer`.

`EntityRequest` is a workaround for [#20045][issue-20045] and is meant to be
refactored soon. Please avoid passing an additional context that is not
required by a serialization entity.

At the moment, the context that is passed to entities most often is
`current_user` and `project`.

## How is this related to using presenters?

Payload created by a serializer is usually a representation of the backed code,
combined with the current request data. Therefore, technically, serializers
are presenters that create payload consumed by a frontend code, usually Vue
components.

In GitLab, it is possible to use [presenters][presenters-readme], but
`BaseSerializer` still needs to learn how to use it, see [#30898][issue-30898].

It is possible to use presenters when serializer is used to represent only
a single object. It is not supported when  `ActiveRecord::Relation` is being
serialized.

```ruby
MyObjectSerializer.new.represent(object.present)
```

## Best practices

1. Do not invoke a serializer from within a serialization entity.

    If you need to use a serializer from within a serialization entity, it is
    possible that you are missing a class for an important domain concept.

    Consider creating a new domain class and a corresponding serialization
    entity for it.

1. Use only one approach to switch behavior of the serializer.

    It is possible to use a few approaches to switch a behavior of the
    serializer. Most common are using a [Fluent Interface][fluent-interface]
    and creating a separate `represent_something` methods.

    Whatever you choose, it might be better to use only one approach at a time.

1. Do not forget about creating specs for serialization entities.

    Writing tests for the serializer indeed does cover testing a behavior of
    serialization entities that the serializer instantiates. However it might
    be a good idea to write separate tests for entities as well, because these
    are meant to be reused in different serializers, and a serializer can
    change a behavior of a serialization entity.

1. Use `ActiveRecord::Relation` where possible

    Using an `ActiveRecord::Relation` might help from the performance perspective.

1. Be diligent about passing an additional context from the controller.

    Using `EntityRequest` and `RequestAwareEntity` is a workaround for the lack
    of high-level mechanism. It is meant to be refactored, and current
    implementation is error prone. Imagine the situation that one serialization
    entity requires `request.user` attribute, but the second one wants
    `request.current_user`. When it happens that these two entities are used in
    the same serialization request, you might need to pass both parameters to
    the serializer, which is not a perfect situation.

    When in doubt, pass only `current_user` and `project` if these are required.

1. Keep performance concerns in mind

    Using a serializer incorrectly can have significant impact on the
    performance.

    Because serializers are technically presenters, it is often necessary
    to calculate, for example, paths to various controller-actions.
    Since using URL helpers usually involve passing `project` and `namespace`
    adding `includes(project: :namespace)` in the serializer, can help to avoid
    N+1 queries.

    Also, try to avoid using `Enumerable#map` or other methods that will
    execute a database query eagerly.

1. Avoid passing `only` and `except` from the controller.
1. Write tests checking for N+1 queries.
1. Write controller tests for actions / formats using serializers.
1. Write tests that check if only necessary data is exposed.
1. Write tests that check if no sensitive data is exposed.

## Future

* [Next iteration of serializers][issue-27569]

[grape-project]: http://www.ruby-grape.org
[grape-entity-project]: https://github.com/ruby-grape/grape-entity
[grape-entity-readme]: https://github.com/ruby-grape/grape-entity/blob/master/README.md
[grape-entity-class]: https://github.com/ruby-grape/grape-entity/blob/master/lib/grape_entity/entity.rb
[grape-entity-only]: https://github.com/ruby-grape/grape-entity/blob/master/README.md#returning-only-the-fields-you-want
[presenters-readme]: https://gitlab.com/gitlab-org/gitlab-foss/blob/master/app/presenters/README.md
[fluent-interface]: https://en.wikipedia.org/wiki/Fluent_interface
[json-schema-gem]: https://github.com/ruby-json-schema/json-schema
[issue-20045]: https://gitlab.com/gitlab-org/gitlab-foss/issues/20045
[issue-30898]: https://gitlab.com/gitlab-org/gitlab-foss/issues/30898
[issue-27569]: https://gitlab.com/gitlab-org/gitlab-foss/issues/27569
