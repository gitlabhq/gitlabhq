# frozen_string_literal: true

module ActiveContext
  class Embeddings
    def self.generate_embeddings(content, unit_primitive:, model: nil, user: nil)
      action = 'embedding'
      embeddings = Gitlab::Llm::VertexAi::Embeddings::Text
        .new(content, user: user, tracking_context: { action: action }, unit_primitive: unit_primitive, model: model)
        .execute

      embeddings.all?(Array) ? embeddings : [embeddings]
    end
  end
end
