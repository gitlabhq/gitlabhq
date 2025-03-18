# frozen_string_literal: true

module ActiveContext
  class Embeddings
    def self.generate_embeddings(content)
      embeddings = Gitlab::Llm::VertexAi::Embeddings::Text
        .new(content, user: nil, tracking_context: { action: 'embedding' }, unit_primitive: 'semantic_search_issue')
        .execute

      embeddings.all?(Array) ? embeddings : [embeddings]
    end
  end
end
