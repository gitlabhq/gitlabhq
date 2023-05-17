# frozen_string_literal: true
module Packages
  module Npm
    class PackageFinder
      delegate :find_by_version, to: :execute
      delegate :last, to: :execute

      # /!\ CAUTION: don't use last_of_each_version: false with find_by_version. Ordering is not
      # guaranteed!
      def initialize(package_name, project: nil, namespace: nil, last_of_each_version: true)
        @package_name = package_name
        @project = project
        @namespace = namespace
        @last_of_each_version = last_of_each_version
      end

      def execute
        result = base.npm
                     .with_name(@package_name)
                     .installable

        return result unless @last_of_each_version

        if Feature.enabled?(:npm_allow_packages_in_multiple_projects)
          Packages::Package.id_in(result.last_of_each_version_ids)
        else
          result.last_of_each_version
        end
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
