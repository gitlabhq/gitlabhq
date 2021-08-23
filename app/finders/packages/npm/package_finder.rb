# frozen_string_literal: true
module Packages
  module Npm
    class PackageFinder
      delegate :find_by_version, to: :execute
      delegate :last, to: :execute

      def initialize(package_name, project: nil, namespace: nil)
        @package_name = package_name
        @project = project
        @namespace = namespace
      end

      def execute
        results = base.npm
                      .with_name(@package_name)
                      .installable
                      .last_of_each_version

        unless Feature.enabled?(:npm_presenter_queries_tuning)
          results = results.preload_files
        end

        results
      end

      private

      def base
        if @project
          packages_for_project
        elsif @namespace
          packages_for_namespace
        else
          ::Packages::Package.none
        end
      end

      def packages_for_project
        @project.packages
      end

      def packages_for_namespace
        ::Packages::Package.for_projects(@namespace.all_projects)
      end
    end
  end
end
