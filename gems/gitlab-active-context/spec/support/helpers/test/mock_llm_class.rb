# frozen_string_literal: true

module Test
  class MockLlmClass
    def initialize(contents, unit_primitive:, user:, model:)
      @contents = contents
      @unit_primitive = unit_primitive
      @user = user
      @model = model
    end

    def execute
      [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]
    end
  end
end
