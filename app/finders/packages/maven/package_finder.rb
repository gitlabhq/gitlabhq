# frozen_string_literal: true

module Packages
  module Maven
    class PackageFinder
      include ::Packages::FinderHelper
      include Gitlab::Utils::StrongMemoize

      def initialize(path, current_user, project: nil, group: nil, order_by_package_file: false)
        @path = path
        @current_user = current_user
        @project = project
        @group = group
        @order_by_package_file = order_by_package_file
      end

      def execute
        packages_with_path.last
      end

      def execute!
        packages_with_path.last!
      end

      private

      def base
        if @project
          packages_for_a_single_project
        elsif @group
          packages_for_multiple_projects
        else
          ::Packages::Package.none
        end
      end

      def packages_with_path
        matching_packages = base.only_maven_packages_with_path(@path, use_cte: @group.present?)
        matching_packages = matching_packages.order_by_package_file if @order_by_package_file

        matching_packages
      end

      # Produces a query that retrieves packages from a single project.
      def packages_for_a_single_project
        @project.packages
      end

      # Produces a query that retrieves packages from multiple projects that
      # the current user can view within a group.
      def packages_for_multiple_projects
        packages_visible_to_user(@current_user, within_group: @group)
      end

      # Returns the projects that the current user can view within a group.
      def projects_visible_to_current_user
        @group.all_projects
              .public_or_visible_to_user(@current_user)
      end
    end
  end
end
