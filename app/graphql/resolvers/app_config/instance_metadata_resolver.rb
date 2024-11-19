# frozen_string_literal: true

module Resolvers
  module AppConfig
    class InstanceMetadataResolver < BaseResolver
      type Types::AppConfig::InstanceMetadataType, null: false

      def resolve(**_args)
        ::AppConfig::InstanceMetadata.new
      end
    end
  end
end
