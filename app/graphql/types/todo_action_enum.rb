# frozen_string_literal: true

module Types
  class TodoActionEnum < BaseEnum
    Todo.action_names.each do |value, action_name|
      value action_name.to_s, value: value, description: "Todo action name for #{action_name}."
    end
  end
end
