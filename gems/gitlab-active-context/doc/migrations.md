# Migrations

Create a file in `ActiveContext::Config.migrations_path`.

## Migration to create a collection

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

## Migration to update a collection's metadata

Use the `update_collection_metadata` method to set metadata for a collection:

```ruby
update_collection_metadata(collection: collection, metadata: metadata)
```

### Updating `indexing_embedding_versions`

```ruby
# frozen_string_literal: true

class NAME < ActiveContext::Migration[1.0]
  milestone '%MILESTONE'

  def migrate!
    update_collection_metadata(collection: collection, metadata: metadata)
  end

  def metadata
    { indexing_embedding_versions: [1, 2] }
  end

  def collection
    Ai::Context::Collections::MergeRequest
  end
end
```

### Updating `search_embedding_version`

```ruby
# frozen_string_literal: true

class NAME < ActiveContext::Migration[1.0]
  milestone '%MILESTONE'

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
