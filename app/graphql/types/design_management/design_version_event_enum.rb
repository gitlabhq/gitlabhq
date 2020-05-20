# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignVersionEventEnum < BaseEnum
      graphql_name 'DesignVersionEvent'
      description 'Mutation event of a design within a version'

      NONE = 'NONE'

      value NONE, 'No change'

      ::DesignManagement::Action.events.keys.each do |event_name|
        value event_name.upcase, value: event_name, description: "A #{event_name} event"
      end
    end
  end
end
