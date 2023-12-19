# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class DestroyService
        include Gitlab::Allowable

        attr_reader :project, :current_user

        def initialize(project, user)
          @current_user = user
          @project = project
        end

        def execute(catalog_resource)
          raise Gitlab::Access::AccessDeniedError unless can?(current_user, :add_catalog_resource,
            project)

          catalog_resource.destroy!

          ServiceResponse.success(message: 'Catalog Resource destroyed')
        end
      end
    end
  end
end
