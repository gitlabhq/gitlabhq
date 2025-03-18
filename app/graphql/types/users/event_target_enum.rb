# frozen_string_literal: true

module Types
  module Users
    class EventTargetEnum < BaseEnum
      graphql_name 'EventTarget'
      description 'Event target'

      mock_filter = ::EventFilter.new('')
      mock_filter.filters.each do |target_type|
        value target_type.upcase, value: target_type, description: "#{target_type.titleize} events"
      end
    end
  end
end
