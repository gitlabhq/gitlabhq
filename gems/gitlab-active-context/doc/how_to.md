# How to

## Set embedding model

Pre-requisite: the [collection](usage.md#adding-a-new-collection), [queue](usage.md#registering-a-queue) and [reference](usage.md#adding-a-new-reference-type) classes exist.

### Add target field

Either add the target field for storing embeddings on the migration to create collection or by adding a separate migration:

Set vector field as part of `create_collection` migration:

```ruby
# frozen_string_literal: true

class CreateMergeRequests < ActiveContext::Migration[1.0]
  milestone '18.0'

  def migrate!
    create_collection :merge_requests, number_of_partitions: 3 do |c|
      c.bigint :issue_id, index: true
      c.prefix :traversal_ids
      c.vector :embedding_1, dimensions: 768
    end
  end
end
```

*Separate migration helper coming soon.*

### Add MODELS hash to collection class

Add a hash entry on the collection class to indicate which target field and embedding model to select in the following format:

```ruby
MODELS = { 0 => { field: :embedding_1, model: 'textembedding-gecko@003' } }
```

### Set collection indexing_embedding_versions

Add a migration to set the `indexing_embedding_versions` to `[0]` for the collection. This will start indexing embeddings using `MODELS[0]`.

```ruby
# frozen_string_literal: true

class SetMergeRequestIndexEmbeddingVersionsTo0 < ActiveContext::Migration[1.0]
  milestone '18.0'

  def migrate!
    update_collection_metadata(collection: collection, metadata: metadata)
  end

  def metadata
    { indexing_embedding_versions: [0] }
  end

  def collection
    Ai::Context::Collections::MergeRequest
  end
end
```

### Add a migration to backfill target field

*Backfill migration helper coming soon.*

### Set collection search_embedding_version

Add a migration to set the `search_embedding_version` to `0` for the collection. This will allow knn searches to search on `:embedding_1` using the model in `MODELS[0]`.

```ruby
# frozen_string_literal: true

class SetMergeRequestSearchEmbeddingVersionTo0 < ActiveContext::Migration[1.0]
  milestone '18.0'

  def migrate!
    update_collection_metadata(collection: collection, metadata: metadata)
  end

  def metadata
    { search_embedding_version: 0 }
  end

  def collection
    Ai::Context::Collections::MergeRequest
  end
end
```

Once this migration is complete, a knn search can be performed as:

```ruby
query = ActiveContext::Query.knn(content: "a question", limit: 5)
Ai::Context::Collections::MergeRequest.search(query: query, user: user)
```

## Migrate from one embedding model to another

### Add new target field

Add a migration to add the new target field, e.g. `embedding_2`.

*Migration helper to add new field coming soon.*

### Update MODELS hash

Add an entry to the collection's `MODELS` hash for the new target field and model.

```ruby
MODELS = {
  0 => { field: :embedding_1, model: 'textembedding-gecko@003' },
  1 => { field: :embedding_2, model: 'text-embedding-005' }
}
```

### Set collection indexing_embedding_versions

Add a migration to set the `indexing_embedding_versions` to `[0, 1]` for the collection. This will now index embeddings for both fields.

```ruby
# frozen_string_literal: true

class SetMergeRequestIndexEmbeddingVersionsTo01 < ActiveContext::Migration[1.0]
  milestone '18.0'

  def migrate!
    update_collection_metadata(collection: collection, metadata: metadata)
  end

  def metadata
    { indexing_embedding_versions: [0, 1] }
  end

  def collection
    Ai::Context::Collections::MergeRequest
  end
end
```

### Add a migration to backfill target field

*Backfill migration helper coming soon.*

### Set collection search_embedding_version

Add a migration to set the `search_embedding_version` to `1` for the collection. This will allow knn searches to search on `:embedding_2` using the model in `MODELS[1]`.

```ruby
# frozen_string_literal: true

class SetMergeRequestSearchEmbeddingVersionTo1 < ActiveContext::Migration[1.0]
  milestone '18.0'

  def migrate!
    update_collection_metadata(collection: collection, metadata: metadata)
  end

  def metadata
    { search_embedding_version: 1 }
  end

  def collection
    Ai::Context::Collections::MergeRequest
  end
end
```

Searches done using `ActiveContext::Query.knn(content: "a question", limit: 5)` will now use the model in `MODELS[1]` and search over embeddings in the `:embedding_2` field.

### Set collection indexing_embedding_versions

Add a migration to set the `indexing_embedding_versions` to `[1]` for the collection. This will stop indexing embeddings for `MODELS[0]`.

```ruby
# frozen_string_literal: true

class SetMergeRequestIndexEmbeddingVersionsTo01 < ActiveContext::Migration[1.0]
  milestone '18.0'

  def migrate!
    update_collection_metadata(collection: collection, metadata: metadata)
  end

  def metadata
    { indexing_embedding_versions: [1] }
  end

  def collection
    Ai::Context::Collections::MergeRequest
  end
end
```

### Nullify old target field

*Migration helper to nullify field coming soon.*
