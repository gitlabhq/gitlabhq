# frozen_string_literal: true

module API
  module Entities
    class Package < Grape::Entity
      include ::API::Helpers::RelatedResourcesHelpers
      extend ::API::Entities::EntityHelpers

      expose :id
      expose :name
      expose :version
      expose :package_type

      expose :_links do
        expose :web_path do |package|
          if ::Gitlab.ee?
            ::Gitlab::Routing.url_helpers.project_package_path(package.project, package)
          end
        end

        expose :delete_api_path, if: can_destroy(:package, &:project) do |package|
          expose_url api_v4_projects_packages_path(package_id: package.id, id: package.project_id)
        end
      end

      expose :created_at
      expose :project_id, if: ->(_, opts) { opts[:group] }
      expose :project_path, if: ->(obj, opts) { opts[:group] && Ability.allowed?(opts[:user], :read_project, obj.project) }
      expose :tags

      expose :pipeline, if: ->(package) { package.build_info }, using: Package::Pipeline

      expose :versions, using: ::API::Entities::PackageVersion

      private

      def project_path
        object.project.full_path
      end
    end
  end
end
