# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class VersionsFinder
        include Gitlab::Utils::StrongMemoize

        def initialize(catalog_resources, current_user, params = {})
          # The catalog resources should already have their project association preloaded
          @catalog_resources = Array.wrap(catalog_resources)
          @current_user = current_user
          @params = params
        end

        def execute
          return Ci::Catalog::Resources::Version.none if authorized_catalog_resources.empty?

          versions = params[:latest] ? get_latest_versions : get_versions
          versions = versions.preloaded
          sort(versions)
        end

        private

        DEFAULT_SORT = :released_at_desc

        attr_reader :catalog_resources, :current_user, :params

        def get_versions
          Ci::Catalog::Resources::Version.for_catalog_resources(authorized_catalog_resources)
        end

        def get_latest_versions
          Ci::Catalog::Resources::Version.latest_for_catalog_resources(authorized_catalog_resources)
        end

        def authorized_catalog_resources
          # Preload project authorizations to avoid N+1 queries
          projects = catalog_resources.map(&:project)
          ActiveRecord::Associations::Preloader.new(records: projects, associations: :project_feature).call
          Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute

          catalog_resources.select { |resource| authorized?(resource.project) }
        end
        strong_memoize_attr :authorized_catalog_resources

        def sort(versions)
          versions.order_by(params[:sort] || DEFAULT_SORT)
        end

        def authorized?(project)
          Ability.allowed?(current_user, :read_release, project)
        end
      end
    end
  end
end
