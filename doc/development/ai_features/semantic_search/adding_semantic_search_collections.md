---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Adding Semantic Search Collections
---

## Overview

To support a new Semantic Search Collection type (for example, merge requests or documentation), you must extend Active Context framework components and add a new type of Embeddings AI Feature.

> [!note]
> For a complete example of how these components work together, see the Semantic Code Search implementation
> in `ee/lib/ai/active_context/` and the [code embeddings indexing pipeline](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-active-context/doc/code_embeddings_indexing_pipeline.md).
> For an overview of how references are processed, see [reference processing](active_context.md#reference-processing).

## Extend Active Context components

- **Collection** (`Ai::ActiveContext::Collections::<Type>`): Define the collection name, queue, reference class, and how to handle authorization
- **Reference** (`Ai::ActiveContext::References::<Type>`): Extend `ActiveContext::Reference` to track embeddings and define preprocessors for content and embedding generation
- **Query** (`Ai::ActiveContext::Queries::<Type>`): Implement query logic to search the vector store
- **Queue** (`Ai::ActiveContext::Queues::<Type>`): Define the queue for managing asynchronous processing
- **Workers**: Create workers for indexing, processing, and managing the lifecycle of the new semantic search type

### Queue

To add a queue:

1. Create a class in `ee/lib/ai/active_context/queues/` that includes `ActiveContext::Concerns::Queue`.
1. Define `number_of_shards`, and override any other [queue properties](active_context.md#queue-properties) you need.

   ```ruby
   module Ai
     module ActiveContext
       module Queues
         class MergeRequest
           include ::ActiveContext::Concerns::Queue

           class << self
             def number_of_shards
               2
             end

             def shard_limit
               500
             end
           end
         end
       end
     end
   end
   ```

1. Register the queue class in `config.queue_classes` in `config/initializers/active_context.rb`.

To check the registered queues, run:

```ruby
ActiveContext.queues     # One entry for each queue class
ActiveContext.raw_queues # One entry for each shard
```

### Reference

To add a reference, create a class in `ee/lib/ai/active_context/references/` that inherits from `ActiveContext::Reference`.

The class must define:

- `self.serialize_data(object)`: Class method that returns a hash of the values to serialize for the object.
- `init`: Reads the deserialized values from `serialized_args`.
- `serialized_attributes`: Returns the values to serialize, in the same order that `init` reads them.
- `identifier`: Returns a unique identifier for the reference.
- `operation`: Returns `:upsert`, `:update`, or `:delete`. For more information, see [operations](active_context.md#operations).
- `as_indexed_json` or `as_indexed_jsons`: Returns the document, or an array of documents, for the reference.

The class can also define:

- `unique_identifiers`: Values used to build a unique identifier for each document, for example `[identifier, branch_name]`.
  Defaults to `[identifier]`.
- `shared_attributes`: A hash merged into every document for the reference.

Declare the [preprocessors](active_context.md#preprocessors) with `add_preprocessor`.
Preprocessors run in the order they are declared.
Use `should_run` to run a preprocessor only when a condition is met.
For example:

```ruby
add_preprocessor :embeddings do |refs, queue_name: nil, **|
  apply_embeddings(refs: refs, queue_name: queue_name, content_method: :title_and_description)
end

add_preprocessor :extra_step, should_run: -> { some_condition? } do |refs, **|
  # ...
end

def title_and_description
  "Title: #{database_record.title}\n\nDescription: #{database_record.description}"
end
```

Use `apply_embeddings` with `content_field:` instead of `content_method:` when the content is already stored in the vector store.
For the full preprocessor chain used for code, see `Ai::ActiveContext::References::Code`.

### Collection

To add a collection, create a class in `ee/lib/ai/active_context/collections/` that includes `ActiveContext::Concerns::Collection`.

The class must define:

- `self.collection_name`: The name of the collection in the vector store.
- `self.queue`: The queue class for the collection's references.
- `self.reference_klass` or `self.reference_klasses`: The reference class or classes for an object.
- `self.routing(object)`: The routing value for an object, for example the root namespace ID.
- `self.embedding_model_factory`: The factory that builds embedding models, usually `Ai::ActiveContext::Embeddings::ModelFactory`.

For authorization, the collection must do one of the following:

- Define `self.ids_to_objects(ids)` to load the objects for search results.
  The default `redact_unauthorized_results!` uses these objects to check that the user can read each result.
- Override `self.redact_unauthorized_results!(result)`, as `Ai::ActiveContext::Collections::Code` does.

### Keeping documents in sync

To add or update documents in the vector store, track the objects with `track!`.
You can call `track!` from anywhere, such as a service, worker, or event subscriber:

```ruby
# Track one or more objects with the collection's default queue
Ai::ActiveContext::Collections::MergeRequest.track!(merge_request)
Ai::ActiveContext::Collections::MergeRequest.track!(project.merge_requests)

# Track with a specific collection or queue
ActiveContext.track!(merge_request, collection: Ai::ActiveContext::Collections::MergeRequest)
ActiveContext.track!(merge_request, collection: Ai::ActiveContext::Collections::MergeRequest, queue: Ai::ActiveContext::Queues::MergeRequest)
```

#### Sync with model callbacks

> [!note]
> No GitLab model uses `Syncable` yet.
> Semantic Code Search calls `track!` from its indexing services instead.

To track records from ActiveRecord callbacks, include `ActiveContext::Concerns::Syncable` in the model
and declare `sync_with_active_context`:

- `on`: The callback to use: `:create`, `:update`, or `:destroy`.
- `using`: A lambda that tracks the record.
- `condition`: Optional. A lambda that must return `true` for the record to be tracked.

The model must also define `syncable?`. Records are tracked only when `syncable?` returns `true`.

```ruby
include ::ActiveContext::Concerns::Syncable

sync_with_active_context on: :create, using: ->(record) { record.track_merge_request! }
sync_with_active_context on: :update,
  condition: -> { saved_change_to_title? || saved_change_to_description? },
  using: ->(record) { record.track_merge_request! }
sync_with_active_context on: :destroy, using: ->(record) { record.track_merge_request! }

def track_merge_request!
  Ai::ActiveContext::Collections::MergeRequest.track!(self)
end

def syncable?
  # Condition that determines whether to track the record
end
```

To keep documents up to date when an associated record changes, add the concern to the associated model.
For example, if merge request documents store the project visibility level:

```ruby
# In the Project model
include ::ActiveContext::Concerns::Syncable

sync_with_active_context on: :update,
  condition: -> { saved_change_to_visibility_level? },
  using: ->(project) { Ai::ActiveContext::Collections::MergeRequest.track!(project.merge_requests) }
```

## Add a new type of embeddings AI feature

Each Semantic Search Collection must have a corresponding Embeddings AI Feature. For example, Semantic Code Search has a corresponding `embeddings_code` feature.

**On AI Gateway**

1. Pick a key for the new Collection. For example, Semantic Code Search's corresponding AI Feature key is `embeddings_code`.
1. Add a new prompt template under `ai_gateway/prompts/definitions/<feature_key>/base/1.0.0.yml`.
   - Embeddings generation only requires a passthrough prompt, which means you do not need to add a prompt text to the YAML file.
   - See `ai_gateway/prompts/definitions/embeddings_code/base/1.0.0.yml` for reference.

   In the endpoint implementation, invoke embeddings generation through the Prompt Registry:

   ```python
   prompt = prompt_registry.get_on_behalf(
       user=current_user,
       prompt_id="<the new feature key>",
       model_metadata=model_metadata,
       internal_event_category=__name__,
   )
   result = await prompt.ainvoke(input=input)
   ```

   See `ai_gateway/api/v1/embeddings/code_embeddings.py` for reference.

1. Follow the guide for [Adding a new embedding model to the GitLab offering](_index.md#adding-a-new-embedding-model-to-the-gitlab-offering).
1. In the Model Selection [`unit_primitives.yml`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/model_selection/unit_primitives.yml), add a new feature setting entry under the key you selected. Set a new unit primitive for the feature.

**On Rails**

1. Add a new `Gitlab::Llm::Embeddings` class for the new Collection. See the `Gitlab::Llm::Embeddings::CodeEmbeddings` class for reference.
1. To make sure that embeddings generation can be invoked for the new Collection, update the `Gitlab::Llm::Embeddings::ModelDefinition`:
   1. Add the new embeddings feature as a constant, similar to `FEATURE_CODE_EMBEDDINGS`
   1. Add the unit primitive for the feature as a constant, similar to `UNIT_PRIMITIVE_GENERATE_EMBEDDINGS_CODEBASE`
   1. Add a factory method to create a `ModelDefinition` object for the feature. See `for_gitlab_provided_code_embeddings` for reference.
1. Optional. To support Self-hosted models for the new Collection:
   1. Add the new embeddings feature in `Ai::FeatureSetting::STABLE_FEATURES` or `Ai::FeatureSetting::FLAGGED_FEATURES`
   1. Add the new embeddings feature in `Ai::ModelSelection::FeaturesConfigurable::FEATURES`
   1. Add the new embeddings feature in `ee/lib/gitlab/ai/feature_settings/feature_metadata.yml`

### Choosing unit primitives

For what a unit primitive is, see the [glossary](../glossary.md#unit-primitive).

Create separate unit primitives for each collection, for example `semantic_search_merge_request` and `semantic_search_issue`, when:

- The features are in different product tiers.
- The features need different entitlements or more granular user permissions.
- You plan to package the features separately.
- You need to track usage separately for billing.

Use a single unit primitive, for example `semantic_search_issuable`, when:

- All features share the same entitlement level.
- You don't need tier-specific access control.
- You want to keep the implementation simple.
- The feature is still experimental.

Each additional unit primitive adds implementation effort.
For more information, see [unit primitives](../unit_primitives.md) and
[connect a new feature using Cloud Connector](../cloud_connector.md#tutorial-connect-a-new-feature-using-cloud-connector).
