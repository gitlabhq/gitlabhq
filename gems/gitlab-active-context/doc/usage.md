# Usage

## Registering a queue

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

## Adding a new reference type

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

## Adding a new collection

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
