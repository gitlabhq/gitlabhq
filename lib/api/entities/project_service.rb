# frozen_string_literal: true

module API
  module Entities
    class ProjectService < Entities::ProjectServiceBasic
      # Expose serialized properties
      expose :properties do |service, options|
        # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404

        attributes =
          if service.data_fields_present?
            service.data_fields.as_json.keys
          else
            service.properties.keys
          end

        attributes &= service.api_field_names

        attributes.each_with_object({}) do |attribute, hash|
          hash[attribute] = service.public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
