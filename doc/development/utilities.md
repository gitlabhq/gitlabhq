# GitLab utilities

We have developed a number of utilities to help ease development:

## `MergeHash`

Refer to: <https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/utils/merge_hash.rb>:

- Deep merges an array of hashes:

  ``` ruby
  Gitlab::Utils::MergeHash.merge(
    [{ hello: ["world"] },
     { hello: "Everyone" },
     { hello: { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] } },
      "Goodbye", "Hallo"]
  )
  ```

  Gives:

  ``` ruby
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

  ``` ruby
  Gitlab::Utils::MergeHash.crush(
    { hello: "world", this: { crushes: ["an entire", "hash"] } }
  )
  ```

  Gives:

  ``` ruby
  [:hello, "world", :this, :crushes, "an entire", "hash"]
  ```

## `Override`

Refer to <https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/utils/override.rb>:

- This utility can help you check if one method would override
  another or not. It is the same concept as Java's `@Override` annotation
  or Scala's `override` keyword. However, you should only do this check when
  `ENV['STATIC_VERIFICATION']` is set to avoid production runtime overhead.
  This is useful for checking:

  - If you have typos in overriding methods.
  - If you renamed the overridden methods, which make the original override methods
    irrelevant.

    Here's a simple example:

    ``` ruby
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

    ``` ruby
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

## `StrongMemoize`

Refer to <https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/utils/strong_memoize.rb>:

- Memoize the value even if it is `nil` or `false`.

  We often do `@value ||= compute`. However, this doesn't work well if
  `compute` might eventually give `nil` and you don't want to compute again.
  Instead you could use `defined?` to check if the value is set or not.
  It's tedious to write such pattern, and `StrongMemoize` would
  help you use such pattern.

  Instead of writing patterns like this:

  ``` ruby
  class Find
    def result
      return @result if defined?(@result)

      @result = search
    end
  end
  ```

  You could write it like:

  ``` ruby
  class Find
    include Gitlab::Utils::StrongMemoize

    def result
      strong_memoize(:result) do
        search
      end
    end
  end
  ```

- Clear memoization

  ``` ruby
  class Find
    include Gitlab::Utils::StrongMemoize
  end

  Find.new.clear_memoization(:result)
  ```

## `RequestCache`

Refer to <https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/cache/request_cache.rb>.

This module provides a simple way to cache values in RequestStore,
and the cache key would be based on the class name, method name,
optionally customized instance level values, optionally customized
method level values, and optional method arguments.

A simple example that only uses the instance level customised values is:

``` ruby
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

``` ruby
class Commit
  extend Gitlab::Cache::RequestCache

  def author
    User.find_by_any_email(author_email)
  end
  request_cache(:author) { author_email }
end
```

## `ReactiveCaching`

The `ReactiveCaching` concern is used to fetch some data in the background and
store it in the Rails cache, keeping it up-to-date for as long as it is being
requested.  If the data hasn't been requested for `reactive_cache_lifetime`,
it will stop being refreshed, and then be removed.

Example of use:

```ruby
class Foo < ApplicationRecord
  include ReactiveCaching

  after_save :clear_reactive_cache!

  def calculate_reactive_cache
    # Expensive operation here. The return value of this method is cached
  end

  def result
    with_reactive_cache do |data|
      # ...
    end
  end
end
```

In this example, the first time `#result` is called, it will return `nil`.
However, it will enqueue a background worker to call `#calculate_reactive_cache`
and set an initial cache lifetime of ten minutes.

The background worker needs to find or generate the object on which
`with_reactive_cache` was called.
The default behaviour can be overridden by defining a custom
`reactive_cache_worker_finder`.
Otherwise, the background worker will use the class name and primary key to get
the object using the ActiveRecord `find_by` method.

```ruby
class Bar
  include ReactiveCaching

  self.reactive_cache_key = ->() { ["bar", "thing"] }
  self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

  def self.from_cache(var1, var2)
    # This method will be called by the background worker with "bar1" and
    # "bar2" as arguments.
    new(var1, var2)
  end

  def initialize(var1, var2)
    # ...
  end

  def calculate_reactive_cache
    # Expensive operation here. The return value of this method is cached
  end

  def result
    with_reactive_cache("bar1", "bar2") do |data|
      # ...
    end
  end
end
```

Each time the background job completes, it stores the return value of
`#calculate_reactive_cache`. It is also re-enqueued to run again after
`reactive_cache_refresh_interval`, therefore, it will keep the stored value up to date.
Calculations are never run concurrently.

Calling `#result` while a value is cached will call the block given to
`#with_reactive_cache`, yielding the cached value. It will also extend the
lifetime by the `reactive_cache_lifetime` value.

Once the lifetime has expired, no more background jobs will be enqueued and
calling `#result` will again return `nil` - starting the process all over
again.
