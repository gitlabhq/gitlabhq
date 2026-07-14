---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Adding Semantic Search Collections
---

## Overview

To support a new Semantic Search Collection type (for example, merge requests or documentation), you must extend Active Context framework components and add a new type of Embeddings AI Feature.

> [!note]
> For detailed information on supporting a new Semantic Search Collection, see the [`gitlab-active-context` gem documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-active-context/doc/code_embeddings_indexing_pipeline.md) and refer to the Semantic Code Search implementation for a complete example of how these components work together.

## Extend Active Context components

- **Collection** (`Ai::ActiveContext::Collections::<Type>`): Define the collection name, queue, reference class, and how to handle authorization
- **Reference** (`Ai::ActiveContext::References::<Type>`): Extend `ActiveContext::Reference` to track embeddings and define preprocessors for content and embedding generation
- **Query** (`Ai::ActiveContext::Queries::<Type>`): Implement query logic to search the vector store
- **Queue** (`Ai::ActiveContext::Queues::<Type>`): Define the queue for managing asynchronous processing
- **Workers**: Create workers for indexing, processing, and managing the lifecycle of the new semantic search type

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
