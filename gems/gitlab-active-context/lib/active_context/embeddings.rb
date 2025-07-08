# frozen_string_literal: true

module ActiveContext
  class Embeddings
    EmbeddingsClassError = Class.new(StandardError)

    class << self
      def generate_embeddings(content, version: {}, unit_primitive: nil, user: nil, batch_size: nil)
        klass = embeddings_class(version)

        contents = content.is_a?(Array) ? content : [content].compact

        klass.generate_embeddings(
          contents,
          model: version[:model],
          unit_primitive: unit_primitive,
          user: user,
          batch_size: batch_size
        )
      rescue ArgumentError => e
        raise(
          EmbeddingsClassError,
          "`#{klass}.generate_embeddings` does not have the correct parameters: #{e.message}"
        )
      end

      def embeddings_class(embeddings_version)
        klass = embeddings_version[:class]
        field = embeddings_version[:field]

        raise EmbeddingsClassError, "No `class` specified for model version `#{field}`." if klass.nil?

        unless klass.respond_to?(:generate_embeddings)
          raise(
            EmbeddingsClassError,
            "Specified class for model version `#{field}` must have a `generate_embeddings` class method."
          )
        end

        klass
      end
    end
  end
end
