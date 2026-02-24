# frozen_string_literal: true

module Test
  class Embeddings
    # This is a mock class for testing purposes,
    # we will simply return an array of numbers without using the parameters
    def self.generate_embeddings(content, unit_primitive:, model: nil, user: nil, batch_size: nil) # rubocop: disable Lint/UnusedMethodArgument -- see above comment
      [
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9]
      ]
    end
  end
end
