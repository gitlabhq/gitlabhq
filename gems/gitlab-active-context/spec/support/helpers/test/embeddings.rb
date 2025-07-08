# frozen_string_literal: true

module Test
  class Embeddings
    def self.generate_embeddings(_content, _unit_primitive:, _model: nil, _user: nil)
      [
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9]
      ]
    end
  end
end
