# frozen_string_literal: true

module Packages
  module Generic
    class PackageFinder
      def initialize(project)
        @project = project
      end

      def execute!(package_name, package_version)
        if Feature.enabled?(:generic_extract_generic_package_model, Feature.current_request)
          Packages::Generic::Package.for_projects(project)
            .installable
            .by_name_and_version!(package_name, package_version)
        else
          project
            .packages
            .generic
            .installable
            .by_name_and_version!(package_name, package_version)
        end
      end

      private

      attr_reader :project
    end
  end
end
