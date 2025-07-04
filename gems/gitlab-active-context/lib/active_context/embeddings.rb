# frozen_string_literal: true

module ActiveContext
  class Embeddings
    def self.generate_embeddings(_content, _unit_primitive:, _model: nil, _user: nil, _batch_size: nil)
      raise NoMethodError, "`generate_embeddings` must be defined by the child class"
    end
  end
end
