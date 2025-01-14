# frozen_string_literal: true

module API
  module Entities
    class Package < Grape::Entity
      include ::API::Helpers::RelatedResourcesHelpers
      include ::Routing::PackagesHelper
      extend ::API::Entities::EntityHelpers

      EMPTY_PIPELINES = [].freeze

      expose :id, documentation: { type: 'integer', example: 1 }

      expose :name, documentation: { type: 'string', example: '@foo/bar' } do |package|
        if package.conan?
          package.conan_recipe
        else
          package.name
        end
      end

      expose :conan_package_name, if: ->(package) { package.conan? } do |package|
        package.name
      end

      expose :version, documentation: { type: 'string', example: '1.0.3' }
      expose :package_type, documentation: { type: 'string', example: 'npm' }
      expose :status, documentation: { type: 'string', example: 'default' }

      expose :_links do
        expose :web_path, if: ->(package) { package.detailed_info? } do |package|
          package_path(package)
        end

        expose :delete_api_path, if: can_destroy(:package, &:project) do |package|
          expose_url api_v4_projects_packages_path(package_id: package.id, id: package.project_id)
        end
      end

      expose :created_at, documentation: { type: 'dateTime', example: '2022-09-16T12:47:31.949Z' }
      expose :last_downloaded_at, documentation: { type: 'dateTime', example: '2022-09-19T11:32:35.169Z' }
      expose :project_id, documentation: { type: 'integer', example: 2 }, if: ->(_, opts) { opts[:group] }
      expose :project_path, documentation: { type: 'string', example: 'gitlab/foo/bar' }, if: ->(obj, opts) do
        opts[:group] && Ability.allowed?(opts[:user], :read_project, obj.project)
      end
      expose :tags

      expose :pipeline, if: ->(package) { package.last_build_info }, using: Package::Pipeline
      expose :pipelines, if: ->(package) { package.pipelines.present? }, using: Package::Pipeline do |_|
        EMPTY_PIPELINES
      end

      expose :versions, using: ::API::Entities::PackageVersion, unless: ->(_, opts) { opts[:collection] }

      private

      def project_path
        object.project.full_path
      end
    end
  end
end
