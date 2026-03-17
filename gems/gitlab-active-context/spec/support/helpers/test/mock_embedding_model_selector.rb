# frozen_string_literal: true

# mock embedding_model_selector class used in Test::Collections::Mock
module Test
  class MockEmbeddingModelSelector
    # This is for testing that the `for` method is being called with the expected params
    # We don't test how `model_metadata` is used,
    # as that logic is for the actual embedding_model_selector class
    def self.for(model_metadata)
      ::ActiveContext::EmbeddingModel.new(
        model_name: model_metadata[:model_ref],
        field: model_metadata[:field],
        llm_class: Test::MockLlmClass,
        llm_params: { model: model_metadata[:model_ref] }
      )
    end
  end
end
