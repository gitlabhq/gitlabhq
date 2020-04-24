# `ReactiveCaching`

> This doc refers to <https://gitlab.com/gitlab-org/gitlab/blob/master/app/models/concerns/reactive_caching.rb>.

The `ReactiveCaching` concern is used for fetching some data in the background and store it
in the Rails cache, keeping it up-to-date for as long as it is being requested. If the
data hasn't been requested for `reactive_cache_lifetime`, it will stop being refreshed,
and then be removed.

## Examples

```ruby
class Foo < ApplicationRecord
  include ReactiveCaching

  after_save :clear_reactive_cache!

  def calculate_reactive_cache(param1, param2)
    # Expensive operation here. The return value of this method is cached
  end

  def result
    # Any arguments can be passed to `with_reactive_cache`. `calculate_reactive_cache`
    # will be called with the same arguments.
    with_reactive_cache(param1, param2) do |data|
      # ...
    end
  end
end
```

In this example, the first time `#result` is called, it will return `nil`. However,
it will enqueue a background worker to call `#calculate_reactive_cache` and set an
initial cache lifetime of 10 min.

## How it works

The first time `#with_reactive_cache` is called, a background job is enqueued and
`with_reactive_cache` returns `nil`. The background job calls `#calculate_reactive_cache`
and stores its return value. It also re-enqueues the background job to run again after
`reactive_cache_refresh_interval`. Therefore, it will keep the stored value up to date.
Calculations never run concurrently.

Calling `#with_reactive_cache` while a value is cached will call the block given to
`#with_reactive_cache`, yielding the cached value. It will also extend the lifetime
of the cache by the `reactive_cache_lifetime` value.

Once the lifetime has expired, no more background jobs will be enqueued and calling
`#with_reactive_cache` will again return `nil` - starting the process all over again.

### 1 MB hard limit

`ReactiveCaching` has a 1 megabyte default limit. [This value is configurable](#selfreactive_cache_worker_finder).

If the data we're trying to cache has over 1 megabyte, it will not be cached and a handled `ReactiveCaching::ExceededReactiveCacheLimit` will be notified on Sentry.

## When to use

- If we need to make a request to an external API (for example, requests to the k8s API).
It is not advisable to keep the application server worker blocked for the duration of
the external request.
- If a model needs to perform a lot of database calls or other time consuming
calculations.

## How to use

### In models and services

The ReactiveCaching concern can be used in models as well as `project_services`
(`app/models/project_services`).

1. Include the concern in your model or service.

   When including in a model:

   ```ruby
   include ReactiveCaching
   ```

   or when including in a `project_service`:

   ```ruby
   include ReactiveService
   ```

1. Implement the `calculate_reactive_cache` method in your model/service.
1. Call `with_reactive_cache` in your model/service where the cached value is needed.
1. If the `calculate_reactive_cache` method above submits requests to external services
(e.g. Prometheus, K8s), make sure to change the
[`reactive_cache_work_type` accordingly](#selfreactive_cache_work_type).

### In controllers

Controller endpoints that call a model or service method that uses `ReactiveCaching` should
not wait until the background worker completes.

- An API that calls a model or service method that uses `ReactiveCaching` should return
`202 accepted` when the cache is being calculated (when `#with_reactive_cache` returns `nil`).
- It should also
[set the polling interval header](fe_guide/performance.md#realtime-components) with
`Gitlab::PollingInterval.set_header`.
- The consumer of the API is expected to poll the API.
- You can also consider implementing [ETag caching](polling.md) to reduce the server
load caused by polling.

### Methods to implement in a model or service

These are methods that should be implemented in the model/service that includes `ReactiveCaching`.

#### `#calculate_reactive_cache` (required)

- This method must be implemented. Its return value will be cached.
- It will be called by `ReactiveCaching` when it needs to populate the cache.
- Any arguments passed to `with_reactive_cache` will also be passed to `calculate_reactive_cache`.

#### `#reactive_cache_updated` (optional)

- This method can be implemented if needed.
- It is called by the `ReactiveCaching` concern whenever the cache is updated.
If the cache is being refreshed and the new cache value is the same as the old cache
value, this method will not be called. It is only called if a new value is stored in
the cache.
- It can be used to perform an action whenever the cache is updated.

### Methods called by a model or service

These are methods provided by `ReactiveCaching` and should be called in
the model/service.

#### `#with_reactive_cache` (required)

- `with_reactive_cache` must be called where the result of `calculate_reactive_cache`
is required.
- A block can be given to `with_reactive_cache`. `with_reactive_cache` can also take
any number of arguments. Any arguments passed to `with_reactive_cache` will be
passed to `calculate_reactive_cache`. The arguments passed to `with_reactive_cache`
will be appended to the cache key name.
- If `with_reactive_cache` is called when the result has already been cached, the
block will be called, yielding the cached value and the return value of the block
will be returned by `with_reactive_cache`. It will also reset the timeout of the
cache to the `reactive_cache_lifetime` value.
- If the result has not been cached as yet, `with_reactive_cache` will return nil.
It will also enqueue a background job, which will call `calculate_reactive_cache`
and cache the result.
- Once the background job has completed and the result is cached, the next call
to `with_reactive_cache` will pick up the cached value.
- In the example below, `data` is the cached value which is yielded to the block
given to `with_reactive_cache`.

  ```ruby
  class Foo < ApplicationRecord
    include ReactiveCaching

    def calculate_reactive_cache(param1, param2)
      # Expensive operation here. The return value of this method is cached
    end

    def result
      with_reactive_cache(param1, param2) do |data|
        # ...
      end
    end
  end
  ```

#### `#clear_reactive_cache!` (optional)

- This method can be called when the cache needs to be expired/cleared. For example,
it can be called in an `after_save` callback in a model so that the cache is
cleared after the model is modified.
- This method should be called with the same parameters that are passed to
`with_reactive_cache` because the parameters are part of the cache key.

#### `#without_reactive_cache` (optional)

- This is a convenience method that can be used for debugging purposes.
- This method calls `calculate_reactive_cache` in the current process instead of
in a background worker.

### Configurable options

There are some `class_attribute` options which can be tweaked.

#### `self.reactive_cache_key`

- The value of this attribute is the prefix to the `data` and `alive` cache key names.
The parameters passed to `with_reactive_cache` form the rest of the cache key names.
- By default, this key uses the model's name and the ID of the record.

  ```ruby
  self.reactive_cache_key = -> (record) { [model_name.singular, record.id] }
  ```

- The `data` and `alive` cache keys in this case will be `"ExampleModel:1:arg1:arg2"`
and `"ExampleModel:1:arg1:arg2:alive"` respectively, where `ExampleModel` is the
name of the model, `1` is the ID of the record, `arg1` and `arg2` are parameters
passed to `with_reactive_cache`.
- If you're including this concern in a service instead, you will need to override
the default by adding the following to your service:

  ```ruby
  self.reactive_cache_key = ->(service) { [service.class.model_name.singular, service.project_id] }
  ```

  If your reactive_cache_key is exactly like the above, you can use the existing
  `ReactiveService` concern instead.

#### `self.reactive_cache_lease_timeout`

- `ReactiveCaching` uses `Gitlab::ExclusiveLease` to ensure that the cache calculation
is never run concurrently by multiple workers.
- This attribute is the timeout for the `Gitlab::ExclusiveLease`.
- It defaults to 2 minutes, but can be overridden if a different timeout is required.

```ruby
self.reactive_cache_lease_timeout = 2.minutes
```

#### `self.reactive_cache_refresh_interval`

- This is the interval at which the cache is refreshed.
- It defaults to 1 minute.

```ruby
self.reactive_cache_lease_timeout = 1.minute
```

#### `self.reactive_cache_lifetime`

- This is the duration after which the cache will be cleared if there are no requests.
- The default is 10 minutes. If there are no requests for this cache value for 10 minutes,
the cache will expire.
- If the cache value is requested before it expires, the timeout of the cache will
be reset to `reactive_cache_lifetime`.

```ruby
self.reactive_cache_lifetime = 10.minutes
```

#### `self.reactive_cache_hard_limit`

- This is the maximum data size that `ReactiveCaching` allows to be cached.
- The default is 1 megabyte. Data that goes over this value will not be cached
and will silently raise `ReactiveCaching::ExceededReactiveCacheLimit` on Sentry.

```ruby
self.reactive_cache_hard_limit = 5.megabytes
```

#### `self.reactive_cache_work_type`

- This is the type of work performed by the `calculate_reactive_cache` method. Based on this attribute,
it's able to pick the right worker to process the caching job. Make sure to
set it as `:external_dependency` if the work performs any external request
(e.g. Kubernetes, Sentry).

#### `self.reactive_cache_worker_finder`

- This is the method used by the background worker to find or generate the object on
which `calculate_reactive_cache` can be called.
- By default it uses the model primary key to find the object:

  ```ruby
  self.reactive_cache_worker_finder = ->(id, *_args) do
    find_by(primary_key => id)
  end
  ```

- The default behavior can be overridden by defining a custom `reactive_cache_worker_finder`.

  ```ruby
  class Foo < ApplicationRecord
    include ReactiveCaching

    self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

    def self.from_cache(var1, var2)
      # This method will be called by the background worker with "bar1" and
      # "bar2" as arguments.
      new(var1, var2)
    end

    def initialize(var1, var2)
      # ...
    end

    def calculate_reactive_cache(var1, var2)
      # Expensive operation here. The return value of this method is cached
    end

    def result
      with_reactive_cache("bar1", "bar2") do |data|
        # ...
      end
    end
  end
  ```

  - In this example, the primary key ID will be passed to `reactive_cache_worker_finder`
  along with the parameters passed to `with_reactive_cache`.
  - The custom `reactive_cache_worker_finder` calls `.from_cache` with the parameters
  passed to `with_reactive_cache`.
