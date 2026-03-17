# frozen_string_literal: true

module Types
  class EventActionEnum < BaseEnum
    graphql_name 'EventAction'
    description 'Event action'

    ::Event.actions.each_key do |target_type|
      value target_type.upcase, value: target_type, description: "#{target_type.titleize} action"
    end
  end
end
