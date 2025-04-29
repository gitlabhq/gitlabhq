# Usage

## Creating a migration

Migrations are similiar to database migrations: they create collections, update schemas, run backfills, etc.

See [migrations](migrations.md) for more details.

A migration worker applies migrations for the active connection. See [Migrations](how_it_works.md#migrations).

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
- `as_indexed_json` or `as_indexed_jsons`: a hash or array of hashes containing the data representation of the object
- `operation`: determines the operation which can be one of `upsert`, `update` or `delete`. See [operation types](#operation-types) for more details.
- `identifier`: unique identifier

Optional methods:
- `unique_identifiers`: array of identifiers to build a unique identifier for every document. For example, `[identifier, branch_name]`. Defaults to `[identifier]`

### Preprocessors

Existing preprocessors are

1. `Preload`: preloads from the database to prevent N+1 queries
1. `Chunking`: splits content into chunks and assigns them to `ref.documents`
1. `Embeddings`: generates embeddings for every document in bulk

#### Preload

Requires `model_klass` and `model_klass` to define `preload_indexing_data`.

```ruby
add_preprocessor :preload do |refs|
  preload(refs)
end
```

#### Chunking

Requires passing `chunker` instance, `chunk_on` method to define the content to chunk on and the `field` to assign the content to.

```ruby
add_preprocessor :chunking do |refs|
  chunker = Chunkers::BySize.new(chunk_size: 1000, overlap: 20)
  chunk(refs: refs, chunker: chunker, chunk_on: :title_and_description, field: :content)
end

def title_and_description
  "Title: #{database_record.title}\n\nDescription: #{database_record.description}"
end
```

Chunkers use the `::ActiveContext::Concerns::Chunker` concern and should define a `chunks` method. The only existing chunker is `BySize`.

#### Embeddings

Generates embeddings either by specifying a content method or by specifying a content field on existing documents.

When documents with a populated content field already exists:

```ruby
add_preprocessor :embeddings do |refs|
  apply_embeddings(refs: refs, target_field: :embedding, content_field: :content)
end
```

When the ref doesn't have existing documents:

```ruby
add_preprocessor :embeddings do |refs|
  apply_embeddings(refs: refs, target_field: :embedding, content_field: :title_and_description)
end

def title_and_description
  "Title: #{database_record.title}\n\nDescription: #{database_record.description}"
end
```

### Operation types

#### `upsert`

Creates or updates documents, handling cases where a single reference has less documents than before by performing a delete cleanup operation.

The document content can be full or partial json.

#### `update`

Updates documents that already exist.

The document content can be full or partial json.

#### `delete`

Deletes all documents belonging to a reference.

### Examples

Example for a reference reading from a database relation, with preloading and bulk embedding generation:

```ruby
# frozen_string_literal: true

module Ai
  module Context
    module References
      class MergeRequest < ::ActiveContext::Reference
        add_preprocessor :preload do |refs|
          preload(refs)
        end

        add_preprocessor :embeddings do |refs|
          apply_embeddings(refs: refs, target_field: :embeddings, content_method: :title_and_description)
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

        def title_and_description
          "Title: #{database_record.title}\n\nDescription: #{database_record.description}"
        end

        def shared_attributes
          {
            iid: database_record.iid,
            namespace_id: database_record.project.id,
            traversal_ids: database_record.project.elastic_namespace_ancestry
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
        add_preprocessor :chunk_full_file_by_size do |refs|
          chunker = Chunkers::BySize.new
          chunk(refs: refs, chunker: chunker, chunk_on: :blob_content)
        end

        attr_accessor :project_id, :identifier, :repository, :blob

        def init
          @project_id, @identifier = serialized_args
          @repository = Project.find(project_id).repository
          @blob = Gitlab::Git::Blob.raw(repository, identifier)
        end

        def serialized_attributes
          [project_id, identifier]
        end

        def blob_content
          blob.data
        end

        def operation
          blob.data ? :upsert : :delete
        end

        def shared_attributes
          {
            project_id: project_id
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
1. Implement the `self.ids_to_objects(ids)` class method to convert ids into objects for redaction.

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

        def self.ids_to_objects(ids)
          ::MergeRequest.id_in(ids)
        end
      end
    end
  end
end
```

## Adding documents to the vector store

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

## Synchronising data

The [`track!`](#adding-documents-to-the-vector-store) method adds documents to the vector stores and can be called from anywhere: a service, a callback, event, etc.

The `::ActiveContext::Concerns::Syncable` concern can be added to ActiveRecord models to update a collection on callbacks.

For example, we can add the concern to the MergeRequest model to track merge request refs on create, update and destroy:

```ruby
include ::ActiveContext::Concerns::Syncable

sync_with_active_context on: :create, using: ->(record) { record.track_merge_request! }

sync_with_active_context on: :update, condition: -> { (saved_change_to_title? || saved_change_to_description?) }, using: ->(record) { record.track_merge_request! }

sync_with_active_context on: :destroy, using: ->(record) { record.track_merge_request! }

def track_merge_request!
  Ai::Context::Collections::MergeRequest.track!(self)
end

def syncable?
  # some condition to determine whether to track an MR record
end
```

We can also keep merge requests up to date if an associated record is updated using the same approach. Say a merge request document contains `project.visibility_level`, we can add the following to the projects model to update its associated merge requests:

```ruby
include ::ActiveContext::Concerns::Syncable

sync_with_active_context on: :update,
  condition: -> { saved_change_to_visibility_level? },
  using: ->(project) { Ai::Context::Collections::MergeRequest.track!(project.merge_requests) }

def syncable?
  # some condition to determine whether or not the project is being indexed
end
```

## Performing a search

### Example: Find all documents in a project

```ruby
query = ActiveContext::Query.filter(project_id: 1).limit(1)

results = Ai::Context::Collections::MergeRequest.search(user: current_user, query: query)

results.to_a
```

### Example: Find document closest to a given embedding

```ruby
target_embedding = ::ActiveContext::Embeddings.generate_embeddings("some text")

query = ActiveContext::Query.filter(project_id: 1).knn(target: "embeddings", vector: target_embedding, limit: 1)

results = Ai::Context::Collections::MergeRequest.search(user: current_user, query: query)

results.to_a
```
