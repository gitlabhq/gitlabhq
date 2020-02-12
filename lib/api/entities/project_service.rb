# frozen_string_literal: true

module API
  module Entities
    class ProjectService < Entities::ProjectServiceBasic
      # Expose serialized properties
      expose :properties do |service, options|
        # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
        if service.data_fields_present?
          service.data_fields.as_json.slice(*service.api_field_names)
        else
          service.properties.slice(*service.api_field_names)
        end
      end
    end
  end
end
