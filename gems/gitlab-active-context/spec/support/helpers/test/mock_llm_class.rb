# frozen_string_literal: true

module Test
  class MockLlmClass
    DEFAULT_DIMENSIONS = 4
    NIL_CONTENTS_ERROR_MESSAGE = 'The text content is empty.'

    def self.mock_vectors(dimensions = DEFAULT_DIMENSIONS)
      (1..dimensions).map(&:to_f)
    end

    def initialize(contents, user: nil, root_namespace_id: nil, dimensions: nil, abc: nil)
      @contents = contents
      @user = user
      @root_namespace_id = root_namespace_id
      @dimensions = dimensions || DEFAULT_DIMENSIONS
      @abc = abc
    end

    def execute
      # simulate error returned by vertex
      raise nil_contents_error if @contents.any?(&:nil?)

      Array.new(@contents.length, self.class.mock_vectors(@dimensions))
    end

    private

    def nil_contents_error
      StandardError.new(NIL_CONTENTS_ERROR_MESSAGE)
    end
  end
end
