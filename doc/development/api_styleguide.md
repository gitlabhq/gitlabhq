# API styleguide

This styleguide recommends best practices for the API development.

## Declared params

> Grape allows you to access only the parameters that have been declared by your
`params` block. It filters out the params that have been passed, but are not
allowed.

– https://github.com/ruby-grape/grape#declared

### Exclude params from parent namespaces

> By default `declared(params) `includes parameters that were defined in all
parent namespaces.

– https://github.com/ruby-grape/grape#include-parent-namespaces

In most cases you will want to exclude params from the parent namespaces:

```ruby
declared(params, include_parent_namespaces: false)
```

### When to use `declared(params)`?

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

But we can use directly `params[key]` when we access single elements.

For instance:

```ruby
# good
Model.create(foo: params[:foo])
```

>**Note:**
Since you [should use Grape's DSL to declare params](doc_styleguide.md#method-description), [parameters validation and
coercion] comes for free!

[parameters validation and coercion]: https://github.com/ruby-grape/grape#parameter-validation-and-coercion
