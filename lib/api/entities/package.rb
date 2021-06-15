# frozen_string_literal: true

module API
  module Entities
    class Package < Grape::Entity
      include ::API::Helpers::RelatedResourcesHelpers
      extend ::API::Entities::EntityHelpers

      expose :id

      expose :name do |package|
        if package.conan?
          package.conan_recipe
        else
          package.name
        end
      end

      expose :conan_package_name, if: ->(package) { package.conan? } do |package|
        package.name
      end

      expose :version
      expose :package_type
      expose :status

      expose :_links do
        expose :web_path do |package, opts|
          if package.infrastructure_package?
            ::Gitlab::Routing.url_helpers.namespace_project_infrastructure_registry_path(opts[:namespace], package.project, package)
          else
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

      expose :pipeline, if: ->(package) { package.original_build_info }, using: Package::Pipeline
      expose :pipelines, if: ->(package) { package.pipelines.present? }, using: Package::Pipeline

      expose :versions, using: ::API::Entities::PackageVersion, unless: ->(_, opts) { opts[:collection] }

      private

      def project_path
        object.project.full_path
      end
    end
  end
end
