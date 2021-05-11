# frozen_string_literal: true

module Packages
  module Generic
    class PackageFinder
      def initialize(project)
        @project = project
      end

      def execute!(package_name, package_version)
        project
          .packages
          .generic
          .installable
          .by_name_and_version!(package_name, package_version)
      end

      private

      attr_reader :project
    end
  end
end
