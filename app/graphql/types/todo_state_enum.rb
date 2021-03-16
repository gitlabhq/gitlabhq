# frozen_string_literal: true

module Types
  class TodoStateEnum < BaseEnum
    value 'pending', description: "The state of the todo is pending."
    value 'done', description: "The state of the todo is done."
  end
end
