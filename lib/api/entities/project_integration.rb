# frozen_string_literal: true

module API
  module Entities
    class ProjectIntegration < Entities::ProjectIntegrationBasic
      # Expose serialized properties
      expose :properties, documentation: { type: 'Hash', example: { "token" => "secr3t" } } do |integration, options|
        integration.api_field_names.index_with do |name|
          integration.public_send(name) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
