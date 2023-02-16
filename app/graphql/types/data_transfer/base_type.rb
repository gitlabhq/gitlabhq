# frozen_string_literal: true

module Types
  module DataTransfer
    class BaseType < BaseObject
      authorize

      field :egress_nodes, type: Types::DataTransfer::EgressNodeType.connection_type,
        description: 'Data nodes.',
        null: true # disallow null once data_transfer_monitoring feature flag is rolled-out!
    end
  end
end
