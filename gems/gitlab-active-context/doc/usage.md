# Usage

## Creating a migration

Migrations are similiar to database migrations: they create collections, update schemas, run backfills, etc.

### Migration to create a collection

Create a file in `ActiveContext::Config.migrations_path`, e.g. `ee/db/active_context/migrate/20250311135734_create_merge_requests.rb`:

```ruby
# frozen_string_literal: true

class CreateMergeRequests < ActiveContext::Migration[1.0]
  milestone '17.9'

  def migrate!
    create_collection :merge_requests, number_of_partitions: 3 do |c|
      c.bigint :issue_id, index: true
      c.bigint :namespace_id, index: true
      c.prefix :traversal_ids
      c.vector :embeddings, dimensions: 768
    end
  end
end
```

A migration worker will apply migrations for the active connection. See [Migrations](how_it_works.md#migrations).

If you want to run the worker manually, execute:

```ruby
Ai::ActiveContext::MigrationWorker.new.perform
```

## Registering a queue

Queues keep track of items needing to be processed in bulk asynchronously. A queue definition has a unique key which registers queues based on the number of shards defined. Each shard creates a queue.

To create a new queue: add a file, extend `ActiveContext::Concerns::Queue` and define `number_of_shards`:

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

- `serialize_data`: defines a string representation of the reference object

Instance methods required:

- `init`: reads from `serialized_args`
- `as_indexed_json`: a hash containing the data representation of the object
- `operation`: determines the operation which can be one of `index`, `upsert` or `delete`
- `identifier`: unique identifier

Example for a reference reading from a database relation, with preloading and bulk embedding generation:

```ruby
# frozen_string_literal: true

module Ai
  module Context
    module References
      class MergeRequest < ::ActiveContext::Reference
        include ::ActiveContext::Preprocessors::Embeddings
        include ::ActiveContext::Preprocessors::Preload

        add_preprocessor :preload do |refs|
          preload(refs)
        end

        add_preprocessor :embeddings do |refs|
          bulk_embeddings(refs)
        end

        def self.embedding_content(ref)
          "title #{ref.database_record.title}\ndescription #{ref.database_record.description}"
        end

        def self.model_klass
          ::MergeRequest
        end

        def self.serialize_data(merge_request)
          { identifier: merge_request.id }
        end

        attr_accessor :identifier, :embedding
        attr_writer :database_record

        def init
          @identifier, _ = serialized_args
        end

        def serialized_attributes
          [identifier]
        end

        def as_indexed_json
          {
            id: identifier,
            issue_id: identifier,
            namespace_id: database_record.project.id,
            traversal_ids: database_record.project.elastic_namespace_ancestry,
            embeddings: embedding
          }
        end

        def model_klass
          self.class.model_klass
        end

        def database_record
          @database_record ||= model_klass.find_by_id(identifier)
        end

        def operation
          database_record ? :upsert : :delete
        end
      end
    end
  end
end
```

Example for code embeddings:

```ruby
# frozen_string_literal: true

module Ai
  module Context
    module References
      class CodeEmbeddings < ::ActiveContext::Reference
        include ::ActiveContext::Preprocessors::Embeddings

        add_preprocessor :bulk_embeddings do |refs|
          bulk_embeddings(refs)
        end

        def self.embedding_content(ref)
          ref.blob.data
        end

        attr_accessor :project_id, :identifier, :repository, :blob, :embedding

        def init
          @project_id, @identifier = serialized_args
          @repository = Project.find(project_id).repository
          @blob = Gitlab::Git::Blob.raw(repository, identifier)
        end

        def serialized_attributes
          [project_id, identifier]
        end

        def operation
          blob.data ? :upsert : :delete
        end

        def as_indexed_json
          {
            project_id: project_id,
            embeddings: embedding
          }
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
# frozen_string_literal: true

module Ai
  module Context
    module Collections
      class MergeRequest
        include ActiveContext::Concerns::Collection

        def self.collection_name
          'gitlab_active_context_merge_requests'
        end

        def self.queue
          Queues::MergeRequest
        end

        def self.reference_klass
          References::MergeRequest
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

The prefered method:

```ruby
Ai::Context::Collections::MergeRequest.track!(MergeRequest.first)
```

```ruby
Ai::Context::Collections::MergeRequest.track!(MergeRequest.take(10))
```

Passing a collection:

```ruby
ActiveContext.track!(MergeRequest.first, collection: Ai::Context::Collections::MergeRequest)
```

Passing a collection and queue:

```ruby
ActiveContext.track!(MergeRequest.first, collection: Ai::Context::Collections::MergeRequest, queue: Ai::Context::Queues::Default)
```

Building a reference:

```ruby
ref = Ai::Context::References::CodeEmbeddings.new(collection_id: collection.id, routing: project.root_ancestor.id, project_id: project.id, identifier: blob.id)
Ai::Context::Collections::CodeEmbeddings.track!(ref)
```

```ruby
ref = Ai::Context::References::CodeEmbeddings.new(collection_id: 24, routing: 24, project_id: 1, identifier: "9ab45314044d664a3b8ac1e05777411482bd0564")
Ai::Context::Collections::CodeEmbeddings.track!(ref)
```

Building a reference and passing a queue:

```ruby
ref = Ai::Context::References::MergeRequest.new(collection_id: collection.id, routing: project.root_ancestor.id, identifier: 1)
ActiveContext.track!(ref, queue: Ai::Context::Queues::MergeRequest)
```

To view all tracked references:

```ruby
ActiveContext::Queues.all_queued_items
```

Once references are tracked, they will be executed asyncronously. See [Async Processing](how_it_works.md#async-processing).

To execute all refs from all refs sync, run

```ruby
ActiveContext.execute_all_queues!
```

To clear a queue:

```ruby
Ai::Context::Queues::MergeRequest.clear_tracking!
```

## Performing a search

### Example: Find all documents in a project

```ruby
query = ActiveContext::Query.filter(project_id: 1).limit(1)

results = ActiveContext.adapter.search(collection: "gitlab_active_context_code_embeddings", query: query)

results.to_a
```

### Example: Find document closest to a given embedding

```ruby
target_embedding = ::ActiveContext::Embeddings.generate_embeddings("some text")

query = ActiveContext::Query.filter(project_id: 1).knn(target: "embeddings", vector: target_embedding, limit: 1)

result = ActiveContext.adapter.search(collection: "gitlab_active_context_code_embeddings", query: query)

result.to_a
```
