# GitLab Active Context

`ActiveContext` is a gem used for interfacing with vector stores like Elasticsearch, OpenSearch and Postgres with PGVector for storing and querying vectors.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Installation

TODO

## Usage

### Configuration

Add an initializer with the following options:

1. `enabled`: `true|false`. Defaults to `false`
1. `databases`: Hash containing database configuration options
1. `logger`: Logger. Defaults to `Logger.new($stdout)`

For example:

```ruby
ActiveContext.configure do |config|
  config.enabled = true
  config.logger = ::Gitlab::Elasticsearch::Logger.build

  config.databases = {
    es1: {
      adapter: 'elasticsearch',
      prefix: 'gitlab_active_context',
      options: ::Gitlab::CurrentSettings.elasticsearch_config
    }
  }
end
```

#### Elasticsearch Configuration Options

| Option | Description | Required | Default | Example |
|--------|-------------|----------|---------|---------|
| `url` | The URL of the Elasticsearch server | Yes | N/A | `'http://localhost:9200'` |
| `prefix` | The prefix for Elasticsearch indices | No | `'gitlab_active_context'` | `'my_custom_prefix'` |
| `client_request_timeout` | The timeout for client requests in seconds | No | N/A | `60` |
| `retry_on_failure` | The number of times to retry a failed request | No | `0` (no retries) | `3` |
| `debug` | Enable or disable debug logging | No | `false` | `true` |

### Registering a queue

Queues keep track of items needing to be processed in bulk asynchronously. A queue definition has a unique key which registers queues based on the number of shards defined. Each shard creates a queue.

To create a new queue: add a file, extend `ActiveContext::Concerns::Queue`, define `number_of_shards` and call `register!`:

```ruby
# frozen_string_literal: true

module Ai
  module Context
    module Queues
      class MergeRequest
        class << self
          def number_of_shards
            2
          end
        end

        include ActiveContext::Concerns::Queue
      end
    end
  end
end
```

To access the unique queues:

```ruby
ActiveContext.queues
=> #<Set: {"ai_context_queues:{merge_request}"}>
```

To view sharded queues:

```ruby
ActiveContext.raw_queues
=> ["ai_context_queues:{merge_request}:0", "ai_context_queues:{merge_request}:1"]
```

### Adding a new collection

A collection maps data to references and specifies a queue to track its references.

To add a new collection:

1. Create a new file in the appropriate directory
1. Define a class that `includes ActiveContext::Concerns::Collection`
1. Implement the `self.queue` class method to return the associated queue
1. Implement the `references` instance method to return the references for an object

Example:

```ruby
module Ai
  module Context
    module Collections
      class MergeRequest
        include ActiveContext::Concerns::Collection

        def self.queue
          Queues::MergeRequest
        end

        def references
          [Search::Elastic::References::Embedding.serialize(object)]
        end
      end
    end
  end
end
```

Adding references to the queue can be done a few ways:

```ruby
Ai::Context::Collections::MergeRequest.track!(MergeRequest.first)
```

```ruby
Ai::Context::Collections::MergeRequest.track!(MergeRequest.take(10))
```

```ruby
ActiveContext.track!(MergeRequest.first, collection: Ai::Context::Collections::MergeRequest)
```

```ruby
ActiveContext.track!(MergeRequest.first, collection: Ai::Context::Collections::MergeRequest, queue: Ai::Context::Queues::Default)
```

To view all tracked references:

```ruby
ActiveContext::Queues.all_queued_items
```

## Contributing

### Development guidelines

1. Avoid adding too many changes in the monolith, keep concerns in the gem
1. It's okay to reuse lib-type GitLab logic in the gem and stub it in specs. Avoid duplication this kind of logic into the code for long-term maintainability.
1. Avoid referencing application logic from the monolith in the gem
