# frozen_string_literal: true

module Packages
  module Npm
    class PackageFinder
      include ::Packages::FinderHelper

      delegate :last, to: :execute

      def initialize(project: nil, namespace: nil, params: {})
        @project = project
        @namespace = namespace
        @params = params
      end

      def execute
        return ::Packages::Package.none unless params[:package_name].present?

        packages = base.npm.installable
        packages = filter_by_exact_package_name(packages)
        filter_by_package_version(packages)
      end

      private

      attr_reader :project, :namespace, :params

      def base
        if project
          packages_for_project
        elsif namespace
          packages_for_namespace
        else
          ::Packages::Package.none
        end
      end

      def packages_for_project
        project.packages
      end

      def packages_for_namespace
        ::Packages::Package.for_projects(namespace.all_projects)
      end
    end
  end
end
