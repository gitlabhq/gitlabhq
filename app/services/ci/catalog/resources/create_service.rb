# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class CreateService
        include Gitlab::Allowable

        attr_reader :project, :current_user

        def initialize(project, user)
          @current_user = user
          @project = project
        end

        def execute
          raise Gitlab::Access::AccessDeniedError unless can?(current_user, :add_catalog_resource, project)

          verified_namespace = Ci::Catalog::VerifiedNamespace.for_project(project)
          catalog_resource = Ci::Catalog::Resource.new(
            project: project, verification_level: verified_namespace&.verification_level || :unverified
          )

          if catalog_resource.valid?
            catalog_resource.save!
            ServiceResponse.success(payload: catalog_resource)
          else
            ServiceResponse.error(message: catalog_resource.errors.full_messages.join(', '))
          end
        end
      end
    end
  end
end
