# frozen_string_literal: true

module Packages
  module Maven
    class PackageFinder
      attr_reader :path, :current_user, :project, :group

      def initialize(path, current_user, project: nil, group: nil)
        @path = path
        @current_user = current_user
        @project = project
        @group = group
      end

      def execute
        packages_with_path.last
      end

      def execute!
        packages_with_path.last!
      end

      private

      def base
        if project
          packages_for_a_single_project
        elsif group
          packages_for_multiple_projects
        else
          ::Packages::Package.none
        end
      end

      def packages_with_path
        matching_packages = base.only_maven_packages_with_path(path)
        matching_packages = matching_packages.order_by_package_file if versionless_package?(matching_packages)

        matching_packages
      end

      def versionless_package?(matching_packages)
        return if matching_packages.empty?

        # if one matching package is versionless, they all are.
        matching_packages.first&.version.nil?
      end

      # Produces a query that retrieves packages from a single project.
      def packages_for_a_single_project
        project.packages
      end

      # Produces a query that retrieves packages from multiple projects that
      # the current user can view within a group.
      def packages_for_multiple_projects
        ::Packages::Package.for_projects(projects_visible_to_current_user)
      end

      # Returns the projects that the current user can view within a group.
      def projects_visible_to_current_user
        ::Project
          .in_namespace(group.self_and_descendants.select(:id))
          .public_or_visible_to_user(current_user)
      end
    end
  end
end
