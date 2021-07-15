# frozen_string_literal: true

module API
  module Entities
    class ProjectIntegration < Entities::ProjectIntegrationBasic
      # Expose serialized properties
      expose :properties do |integration, options|
        # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404

        attributes =
          if integration.data_fields_present?
            integration.data_fields.as_json.keys
          else
            integration.properties.keys
          end

        attributes &= integration.api_field_names

        attributes.each_with_object({}) do |attribute, hash|
          hash[attribute] = integration.public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
