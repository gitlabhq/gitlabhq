---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab utilities
---

We have developed a number of utilities to help ease development:

## `MergeHash`

Refer to [`merge_hash.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/utils/merge_hash.rb):

- Deep merges an array of hashes:

  ```ruby
  Gitlab::Utils::MergeHash.merge(
    [{ hello: ["world"] },
     { hello: "Everyone" },
     { hello: { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] } },
      "Goodbye", "Hallo"]
  )
  ```

  Gives:

  ```ruby
  [
    {
      hello:
        [
          "world",
          "Everyone",
          { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] }
        ]
    },
    "Goodbye"
  ]
  ```

- Extracts all keys and values from a hash into an array:

  ```ruby
  Gitlab::Utils::MergeHash.crush(
    { hello: "world", this: { crushes: ["an entire", "hash"] } }
  )
  ```

  Gives:

  ```ruby
  [:hello, "world", :this, :crushes, "an entire", "hash"]
  ```

## `Override`

Refer to [`override.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/utils/override.rb):

- This utility can help you check if one method would override
  another or not. It is the same concept as Java's `@Override` annotation
  or Scala's `override` keyword. However, we only run this check when
  `ENV['STATIC_VERIFICATION']` is set to avoid production runtime overhead.
  This is useful for checking:

  - If you have typos in overriding methods.
  - If you renamed the overridden methods, which make the original override methods
    irrelevant.

    Here's a simple example:

    ```ruby
    class Base
      def execute
      end
    end

    class Derived < Base
      extend ::Gitlab::Utils::Override

      override :execute # Override check happens here
      def execute
      end
    end
    ```

    This also works on modules:

    ```ruby
    module Extension
      extend ::Gitlab::Utils::Override

      override :execute # Modules do not check this immediately
      def execute
      end
    end

    class Derived < Base
      prepend Extension # Override check happens here, not in the module
    end
    ```

    Note that the check only happens when either:

    - The overriding method is defined in a class, or:
    - The overriding method is defined in a module, and it's prepended to
      a class or a module.

    Because only a class or prepended module can actually override a method.
    Including or extending a module into another cannot override anything.

### Interactions with `ActiveSupport::Concern`, `prepend`, and `class_methods`

When you use `ActiveSupport::Concern` that includes class methods, you do not
get expected results because `ActiveSupport::Concern` doesn't work like a
regular Ruby module.

Since we already have `Prependable` as a patch for `ActiveSupport::Concern`
to enable `prepend`, it has consequences with how it would interact with
`override` and `class_methods`. As a workaround, `extend` `ClassMethods`
into the defining `Prependable` module.

This allows us to use `override` to verify `class_methods` used in the
context mentioned above. This workaround only applies when we run the
verification, not when running the application itself.

Here are example code blocks that demonstrate the effect of this workaround:
following codes:

```ruby
module Base
  extend ActiveSupport::Concern

  class_methods do
    def f
    end
  end
end

module Derived
  include Base
end

# Without the workaround
Base.f    # => NoMethodError
Derived.f # => nil

# With the workaround
Base.f    # => nil
Derived.f # => nil
```

## `StrongMemoize`

Refer to [`strong_memoize.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-utils/lib/gitlab/utils/strong_memoize.rb):

- Memoize the value even if it is `nil` or `false`.

  We often do `@value ||= compute`. However, this doesn't work well if
  `compute` might eventually give `nil` and you don't want to compute again.
  Instead you could use `defined?` to check if the value is set or not.
  It's tedious to write such pattern, and `StrongMemoize` would
  help you use such pattern.

  Instead of writing patterns like this:

  ```ruby
  class Find
    def result
      return @result if defined?(@result)

      @result = search
    end
  end
  ```

  You could write it like:

  ```ruby
  class Find
    include Gitlab::Utils::StrongMemoize

    def result
      search
    end
    strong_memoize_attr :result

    def enabled?
      Feature.enabled?(:some_feature)
    end
    strong_memoize_attr :enabled?
  end
  ```

  Using `strong_memoize_attr` on methods with parameters is not supported.
  It does not work when combined with [`override`](#override) and might memoize wrong results.

  Use `strong_memoize_with` instead.

  ```ruby
  # bad
  def expensive_method(arg)
    # ...
  end
  strong_memoize_attr :expensive_method

  # good
  def expensive_method(arg)
    strong_memoize_with(:expensive_method, arg) do
      # ...
    end
  end
  ```

  There's also `strong_memoize_with` to help memoize methods that take arguments.
  This should be used for methods that have a low number of possible values
  as arguments or with consistent repeating arguments in a loop.

  ```ruby
  class Find
    include Gitlab::Utils::StrongMemoize

    def result(basic: true)
      strong_memoize_with(:result, basic) do
        search(basic)
      end
    end
  end
  ```

- Clear memoization

  ```ruby
  class Find
    include Gitlab::Utils::StrongMemoize
  end

  Find.new.clear_memoization(:result)
  ```

## `RequestCache`

Refer to [`request_cache.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/cache/request_cache.rb).

This module provides a simple way to cache values in RequestStore,
and the cache key would be based on the class name, method name,
optionally customized instance level values, optionally customized
method level values, and optional method arguments.

A simple example that only uses the instance level customised values is:

```ruby
class UserAccess
  extend Gitlab::Cache::RequestCache

  request_cache_key do
    [user&.id, project&.id]
  end

  request_cache def can_push_to_branch?(ref)
    # ...
  end
end
```

This way, the result of `can_push_to_branch?` would be cached in
`RequestStore.store` based on the cache key. If `RequestStore` is not
currently active, then it would be stored in a hash, and saved in an
instance variable so the cache logic would be the same.

We can also set different strategies for different methods:

```ruby
class Commit
  extend Gitlab::Cache::RequestCache

  def author
    User.find_by_any_email(author_email)
  end
  request_cache(:author) { author_email }
end
```

## `ReactiveCaching`

Read the documentation on [`ReactiveCaching`](reactive_caching.md).

## `TokenAuthenticatable`

Read the documentation on [`TokenAuthenticatable`](token_authenticatable.md).

## `CircuitBreaker`

The `Gitlab::CircuitBreaker` can be wrapped around any class that needs to run code with circuit breaker protection. It provides a `run_with_circuit` method that wraps a code block with circuit breaker functionality, which helps prevent cascading failures and improves system resilience. For more information about the circuit breaker pattern, see:

- [What is Circuit breaker](https://martinfowler.com/bliki/CircuitBreaker.html).
- [The Hystrix documentation on CircuitBreaker](https://github.com/Netflix/Hystrix/wiki/How-it-Works#circuit-breaker).

### Use CircuitBreaker

To use the CircuitBreaker wrapper:

```ruby
class MyService
  def call_external_service
    Gitlab::CircuitBreaker.run_with_circuit('ServiceName') do
      # Code that interacts with external service goes here

      raise Gitlab::CircuitBreaker::InternalServerError # if there is an issue
    end
  end
end
```

The `call_external_service` method is an example method that interacts with an external service.
By wrapping the code that interacts with the external service with `run_with_circuit`, the method is executed within the circuit breaker.

The method should raise an `InternalServerError` error, which will be counted towards the error threshold if raised during the execution of the code block.
The circuit breaker tracks the number of errors and the rate of requests,
and opens the circuit if it reaches the configured error threshold or volume threshold.
If the circuit is open, subsequent requests fail fast without executing the code block, and the circuit breaker periodically allows a small number of requests through to test the service's availability before closing the circuit again.

### Configuration

You need to specify a service name for each unique circuit that is used as the cache key. This should be a `CamelCase` string which identifies the circuit.

The circuit breaker has defaults that can be overridden per circuit, for example:

```ruby
Gitlab::CircuitBreaker.run_with_circuit('ServiceName', options = { volume_threshold: 5 }) do
  ...
end
```

The defaults are:

- `exceptions`: `[Gitlab::CircuitBreaker::InternalServerError]`
- `error_threshold`: `50`
- `volume_threshold`: `10`
- `sleep_window`: `90`
- `time_window`: `60`
