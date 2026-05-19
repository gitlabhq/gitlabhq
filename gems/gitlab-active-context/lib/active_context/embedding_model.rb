# frozen_string_literal: true

module ActiveContext
  class EmbeddingModel
    LlmClassError = Class.new(StandardError)

    attr_reader :field, :model_key, :llm_class, :llm_params

    def initialize(field:, model_key:, llm_class:, llm_params:)
      @field = field.to_sym
      @model_key = model_key

      @llm_class = llm_class
      @llm_params = llm_params
    end

    def generate_embeddings(content, user: nil)
      log_embeddings_generation do
        contents = content.is_a?(Array) ? content : [content].compact

        embedding_llm = validate_respond_to_execute(
          build_embedding_llm(contents, user)
        )
        embedding_llm.execute
      end
    end

    private

    def build_embedding_llm(contents, user)
      llm_class.new(contents, user: user, **llm_params)
    rescue StandardError => e
      raise(LlmClassError, "Error initializing #{llm_class}: #{e.class} - #{e.message}")
    end

    def validate_respond_to_execute(embedding_llm)
      unless embedding_llm.respond_to?(:execute)
        raise(LlmClassError, "Instance of #{llm_class} does not respond to `execute`.")
      end

      embedding_llm
    end

    def log_embeddings_generation
      ::ActiveContext::Logger.info(
        message: "generate embeddings",
        model: model_key,
        status: "start",
        class: self.class.name
      )

      embeddings = yield

      ::ActiveContext::Logger.info(
        message: "generate embeddings",
        model: model_key,
        status: "done",
        class: self.class.name
      )

      embeddings
    end
  end
end
