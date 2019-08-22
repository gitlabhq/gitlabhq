# API styleguide

This styleguide recommends best practices for API development.

## Instance variables

Please do not use instance variables, there is no need for them (we don't need
to access them as we do in Rails views), local variables are fine.

## Entities

Always use an [Entity] to present the endpoint's payload.

## Methods and parameters description

Every method must be described using the [Grape DSL](https://github.com/ruby-grape/grape#describing-methods)
(see <https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/api/environments.rb>
for a good example):

- `desc` for the method summary. You should pass it a block for additional
  details such as:
  - The GitLab version when the endpoint was added
  - If the endpoint is deprecated, and if so, when will it be removed

- `params` for the method params. This acts as description,
  [validation, and coercion of the parameters]

A good example is as follows:

```ruby
desc 'Get all broadcast messages' do
  detail 'This feature was introduced in GitLab 8.12.'
  success Entities::BroadcastMessage
end
params do
  optional :page,     type: Integer, desc: 'Current page number'
  optional :per_page, type: Integer, desc: 'Number of messages per page'
end
get do
  messages = BroadcastMessage.all

  present paginate(messages), with: Entities::BroadcastMessage
end
```

## Declared params

> Grape allows you to access only the parameters that have been declared by your
`params` block. It filters out the params that have been passed, but are not
allowed.

– <https://github.com/ruby-grape/grape#declared>

### Exclude params from parent namespaces

> By default `declared(params)`includes parameters that were defined in all
parent namespaces.

– <https://github.com/ruby-grape/grape#include-parent-namespaces>

In most cases you will want to exclude params from the parent namespaces:

```ruby
declared(params, include_parent_namespaces: false)
```

### When to use `declared(params)`

You should always use `declared(params)` when you pass the params hash as
arguments to a method call.

For instance:

```ruby
# bad
User.create(params) # imagine the user submitted `admin=1`... :)

# good
User.create(declared(params, include_parent_namespaces: false).to_h)
```

>**Note:**
`declared(params)` return a `Hashie::Mash` object, on which you will have to
call `.to_h`.

But we can use `params[key]` directly when we access single elements.

For instance:

```ruby
# good
Model.create(foo: params[:foo])
```

[Entity]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/api/entities.rb
[validation, and coercion of the parameters]: https://github.com/ruby-grape/grape#parameter-validation-and-coercion
