# GitLab Active Context

`ActiveContext` is a gem used for interfacing with vector stores like Elasticsearch, OpenSearch and Postgres with PGVector for storing and querying vectors.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Installation

TODO

## How it works

### Async processing

A cron worker triggers a Sidekiq job for every queue in `ActiveContext.raw_queues` every minute. For each of the jobs, it fetches a set amount of references from the queue, processes them and removes them from the queue. The job will re-enqueue itself every second until there are no more references to process in the queue.

Async processing depends on the following configuration values:
  
  1. `indexing_enabled`: processing exits early if this is false. Recommended to set to:

      ```ruby
      config.indexing_enabled = Gitlab::CurrentSettings.elasticsearch_indexing? &&
        Search::ClusterHealthCheck::Elastic.healthy? &&
        !Elastic::IndexingControl.non_cached_pause_indexing?
      ```

  1. `re_enqueue_indexing_workers`: whether or not to re-enqueue workers until there are no more references to process. Increases indexing throughput when set to `true`. Recommended to set to:

      ```ruby
      config.re_enqueue_indexing_workers = Gitlab::CurrentSettings.elasticsearch_requeue_workers?
      ```

## Usage

### Configuration

Add an initializer with the following options:

1. `enabled`: `true|false`. Defaults to `false`
1. `databases`: Hash containing database configuration options
1. `indexing_enabled`: `true|false`. Defaults to `false`
1. `re_enqueue_indexing_workers`: `true|false`. Defaults to `false`
1. `logger`: Logger. Defaults to `Logger.new($stdout)`

For example:

```ruby
ActiveContext.configure do |config|
  config.enabled = true
  config.logger = ::Gitlab::Elasticsearch::Logger.build

  config.databases = {
    es1: {
      adapter: 'ActiveContext::Databases::Elasticsearch::Adapter',
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
| `max_bulk_size_bytes` | Maximum size before forcing a bulk operation in megabytes | No | `10.megabytes` | `5242880` | 

### Scheduling a cron worker for async processing

Create a file which includes the `BulkAsyncProcess` concern and other worker-specific concerns:

```ruby
# frozen_string_literal: true

module Ai
  module Context
    class BulkProcessWorker
      include ActiveContext::Concerns::BulkAsyncProcess
      include ::ApplicationWorker
      include ::CronjobQueue
      include Search::Worker
      include Gitlab::ExclusiveLeaseHelpers
      prepend ::Geo::SkipSecondary

      idempotent!
      worker_resource_boundary :cpu
      urgency :low
      data_consistency :sticky
      loggable_arguments 0, 1
    end
  end
end
```

Schedule the worker on a cron schedule in `config/initializers/1_settings.rb`.

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
=> [#<Ai::Context::Queues::MergeRequest:0x0000000177cdf460 @shard=0>,
 #<Ai::Context::Queues::MergeRequest:0x0000000177cdf370 @shard=1>]
```

### Adding a new reference type

Create a class under `lib/active_context/references/` and inherit from the `Reference` class and define the following methods:

Class methods required:

- `serialize(object, routing)`: defines a string representation of the reference object
- `preload_refs` (optional): preload database records to prevent N+1 issues

Instance methods required:

- `serialize`: defines a string representation of the reference object
- `as_indexed_json`: a hash containing the data representation of the object
- `operation`: determines the operation which can be one of `index`, `upsert` or `delete`
- `partition_name`: name of the table or index
- `identifier`: unique identifier
- `routing` (optional)

Example:

```ruby
# frozen_string_literal: true

module Ai
  module Context
    module References
      class MergeRequest < ::ActiveContext::Reference
        def self.serialize(record)
          new(record.id).serialize
        end

        attr_reader :identifier

        def initialize(identifier)
          @identifier = identifier.to_i
        end

        def serialize
          self.class.join_delimited([identifier].compact)
        end

        def as_indexed_json
          {
            id: identifier
          }
        end

        def operation
          :index
        end

        def partition_name
          'ai_context_merge_requests'
        end
      end
    end
  end
end
```

### Adding a new collection

A collection maps data to references and specifies a queue to track its references.

To add a new collection:

1. Create a new file in the appropriate directory
1. Define a class that `includes ActiveContext::Concerns::Collection`
1. Implement the `self.queue` class method to return the associated queue
1. Implement the `self.reference_klass` or `self.reference_klasses` class method to return the references for an object
1. Implement the `self.routing(object)` class method to determine how an object should be routed

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

        def self.reference_klasses
          [
            References::Embedding,
            References::MergeRequest
          ]
        end

        def self.routing(object)
          object.project.root_ancestor.id
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

```ruby
ActiveContext.track!(Ai::Context::References::MergeRequest.new(1), queue: Ai::Context::Queues::MergeRequest)
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
