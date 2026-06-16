# frozen_string_literal: true

module Test
  class MockLlmClass
    DEFAULT_DIMENSIONS = 4
    NIL_CONTENTS_ERROR_MESSAGE = 'The text content is empty.'

    def self.generate_embeddings(contents, model: nil, user: nil, dimensions: nil, abc: nil)
      new(contents, user: user, model: model, dimensions: dimensions, abc: abc).execute
    end

    def initialize(contents, user: nil, dimensions: nil, abc: nil)
      @contents = contents
      @user = user
      @dimensions = dimensions || DEFAULT_DIMENSIONS
      @abc = abc
    end

    def execute
      # simulate error returned by vertex
      raise nil_contents_error if @contents.any?(&:nil?)

      Array.new(@contents.length, mock_vectors)
    end

    private

    def mock_vectors
      (1..@dimensions).map(&:to_f)
    end

    def nil_contents_error
      StandardError.new(NIL_CONTENTS_ERROR_MESSAGE)
    end
  end
end
