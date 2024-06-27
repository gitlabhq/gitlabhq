# frozen_string_literal: true

module Packages
  module Conan
    class PackageFinder
      MAX_PACKAGES_COUNT = 500
      QUERY_SEPARATOR = '/'

      def initialize(current_user, params, project: nil)
        @current_user = current_user
        @name, @version = params[:query].to_s.split(QUERY_SEPARATOR)
        @project = project
      end

      def execute
        return ::Packages::Conan::Package.none unless name.present?

        packages
      end

      private

      attr_reader :current_user, :name, :project, :version

      def packages
        matching_packages = base
        .installable
        .preload_conan_metadatum
        .with_name_like(name)
        matching_packages = matching_packages.with_version(version) if version
        matching_packages.limit_recent(MAX_PACKAGES_COUNT)
      end

      def base
        ::Packages::Conan::Package.for_projects(project || projects_visible_to_current_user)
      end

      def projects_visible_to_current_user
        ::Project.public_or_visible_to_user(current_user, ::Gitlab::Access::REPORTER)
      end
    end
  end
end
