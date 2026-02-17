# frozen_string_literal: true

module ActiveContext
  class EmbeddingModel
    LlmClassError = Class.new(StandardError)

    attr_reader :model_name, :field, :llm_class, :llm_params

    def initialize(model_name:, field:, llm_class:, llm_params:)
      @model_name = model_name
      @field = field

      @llm_class = llm_class
      @llm_params = llm_params
    end

    def generate_embeddings(content, unit_primitive: nil, user: nil)
      contents = content.is_a?(Array) ? content : [content].compact

      embedding_llm = validate_respond_to_execute(
        build_embedding_llm(contents, unit_primitive, user)
      )
      embedding_llm.execute
    end

    private

    def build_embedding_llm(contents, unit_primitive, user)
      llm_class.new(contents, unit_primitive: unit_primitive, user: user, **llm_params)
    rescue StandardError => e
      raise(LlmClassError, "Error initializing #{llm_class}: #{e.class} - #{e.message}")
    end

    def validate_respond_to_execute(embedding_llm)
      unless embedding_llm.respond_to?(:execute)
        raise(LlmClassError, "Instance of #{llm_class} does not respond to `execute`.")
      end

      embedding_llm
    end
  end
end
