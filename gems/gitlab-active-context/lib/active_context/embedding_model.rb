# frozen_string_literal: true

module ActiveContext
  class EmbeddingModel
    Error = Class.new(StandardError)

    attr_reader :field, :model_ref, :model_type, :dimensions, :llm_class, :llm_params

    def initialize(field:, model_ref:, model_type:, llm_class:, llm_params: {}, dimensions: nil)
      @field = field.to_sym
      @model_ref = model_ref
      @model_type = model_type.to_sym
      @dimensions = Integer(dimensions) if dimensions

      @llm_class = llm_class

      @llm_params = llm_params
      @llm_params[:dimensions] = @dimensions if @dimensions
    end

    def generate_embeddings(content, user: nil)
      validate_llm_params

      log_embeddings_generation do
        contents = content.is_a?(Array) ? content : [content].compact

        embedding_llm = validate_respond_to_execute(
          build_embedding_llm(contents, user)
        )
        embedding_llm.execute
      end
    end

    def model_key
      "#{model_type}__#{model_ref}"
    end

    private

    def build_embedding_llm(contents, user)
      llm_class.new(contents, user: user, **llm_params)
    rescue StandardError => e
      raise(Error, "Error initializing #{llm_class}: #{e.class} - #{e.message}")
    end

    def validate_respond_to_execute(embedding_llm)
      return embedding_llm if embedding_llm.respond_to?(:execute)

      raise(Error, "Instance of #{llm_class} does not respond to `execute`.")
    end

    def validate_llm_params
      return if llm_params[:dimensions].nil? || llm_params[:dimensions].positive?

      raise(Error, "`dimensions` parameter must be a whole number greater than `0`")
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
