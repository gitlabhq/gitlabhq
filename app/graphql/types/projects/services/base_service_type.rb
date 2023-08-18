# frozen_string_literal: true

module Types
  module Projects
    module Services
      # TODO: Remove in 17.0, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108418
      class BaseServiceType < BaseObject
        graphql_name 'BaseService'

        implements Types::Projects::ServiceType

        authorize :admin_project
      end
    end
  end
end
