# frozen_string_literal: true

module Types
  module EventableType
    include Types::BaseInterface

    field :events, Types::EventType.connection_type, null: true, description: 'List of events associated with the object.'
  end
end
