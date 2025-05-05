# frozen_string_literal: true

module ActiveContext
  class Embeddings
    def self.generate_embeddings(content, model: nil, primitive: 'semantic_search_issue', user: nil)
      embeddings = Gitlab::Llm::VertexAi::Embeddings::Text
        .new(content, user: user, tracking_context: { action: 'embedding' }, unit_primitive: primitive, model: model)
        .execute

      embeddings.all?(Array) ? embeddings : [embeddings]
    end
  end
end
