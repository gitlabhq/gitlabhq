# frozen_string_literal: true

# mock embedding_model_selector class used in Test::Collections::Mock
module Test
  class MockEmbeddingModelSelector
    # This is for testing that the `for` method is being called with the expected params
    # We don't test how `model_metadata` is used,
    # as that logic is for the actual embedding_model_selector class
    def self.for(model_metadata, search: false)
      ::ActiveContext::EmbeddingModel.new(
        field: model_metadata[:field],
        model_ref: model_metadata[:model_ref],
        model_type: model_metadata[:model_type] || 'gitlab',
        llm_class: Test::MockLlmClass,
        llm_params: { model: model_metadata[:model_ref], search: search }
      )
    end
  end
end
