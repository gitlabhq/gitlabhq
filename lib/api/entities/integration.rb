# frozen_string_literal: true

module API
  module Entities
    class Integration < Entities::IntegrationBasic
      # Expose serialized properties
      expose :properties, documentation: { type: 'Hash', example: { "token" => "secr3t" } } do |integration, _|
        integration.api_field_names.index_with do |name|
          integration.public_send(name) # rubocop:disable GitlabSecurity/PublicSend -- we're exposing the fields that are allowed to be exposed
        end
      end
    end
  end
end
