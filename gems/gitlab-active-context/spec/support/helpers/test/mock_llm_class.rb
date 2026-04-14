# frozen_string_literal: true

module Test
  class MockLlmClass
    MOCK_VECTORS = [1.0, 2.0, 3.0].freeze

    NIL_CONTENTS_ERROR_MESSAGE = 'The text content is empty.'

    def self.generate_embeddings(contents, model: nil, user: nil)
      new(contents, user: user, model: model).execute
    end

    def initialize(contents, model: nil, user: nil)
      @contents = contents
      @user = user
      @model = model
    end

    def execute
      # simulate error returned by vertex
      raise nil_contents_error if @contents.any?(&:nil?)

      Array.new(@contents.length, MOCK_VECTORS)
    end

    private

    def nil_contents_error
      StandardError.new(NIL_CONTENTS_ERROR_MESSAGE)
    end
  end
end
