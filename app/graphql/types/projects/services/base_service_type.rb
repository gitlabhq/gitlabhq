# frozen_string_literal: true

module Types
  module Projects
    module Services
      class BaseServiceType < BaseObject
        graphql_name 'BaseService'

        implements(Types::Projects::ServiceType)

        authorize :admin_project
      end
    end
  end
end
