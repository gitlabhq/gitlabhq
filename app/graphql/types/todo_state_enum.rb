# frozen_string_literal: true

module Types
  class TodoStateEnum < BaseEnum
    value 'pending', description: "State of the todo is pending."
    value 'done', description: "State of the todo is done."
  end
end
