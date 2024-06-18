# frozen_string_literal: true

module Packages
  module Conan
    class PackageFinder
      MAX_PACKAGES_COUNT = 500

      def initialize(current_user, params, project: nil)
        @current_user = current_user
        @query = params[:query]
        @project = project
      end

      def execute
        return ::Packages::Conan::Package.none unless query

        packages
      end

      private

      attr_reader :current_user, :query, :project

      def packages
        base
          .installable
          .preload_conan_metadatum
          .with_name_like(query)
          .limit_recent(MAX_PACKAGES_COUNT)
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
