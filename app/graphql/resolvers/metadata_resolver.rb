# frozen_string_literal: true

module Resolvers
  class MetadataResolver < BaseResolver
    type Types::MetadataType, null: false

    def resolve(**args)
      ::InstanceMetadata.new
    end
  end
end
