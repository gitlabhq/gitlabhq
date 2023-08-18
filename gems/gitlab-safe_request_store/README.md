# Gitlab::SafeRequestStore

A safer abstraction of `RequestStore` that comes with [`request_store` gem](https://github.com/steveklabnik/request_store).

This gem works as a proxy to `RequestStore` allowing you to use the same interface even when the Request Store
is not active. In this case a `NullStore` is being used under the hood providing no-ops when the Request Store
is not active.

## Usage

When request store is active it works the same as `RequestStore`:

```ruby
Gitlab::SafeRequestStore.active? # => true
Gitlab::SafeRequestStore[:test] = 123
Gitlab::SafeRequestStore[:test] # =>  123
```

When request store is not active it does nothing:

```ruby
Gitlab::SafeRequestStore.active? # => false
Gitlab::SafeRequestStore[:test] = 123
Gitlab::SafeRequestStore[:test] # =>  nil
```

You can enforce the request store to temporarily be active using:

```ruby
Gitlab::SafeRequestStore.active? # => false

Gitlab::SafeRequestStore.ensure_request_store do
  Gitlab::SafeRequestStore.active? # => true
  # do something...
end

Gitlab::SafeRequestStore.active? # => false
```

## Development

Follow the GitLab [gems development guidelines](../../doc/development/gems.md).
