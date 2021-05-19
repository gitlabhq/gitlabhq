# frozen_string_literal: true

module Packages
  module Go
    class PackageFinder
      delegate :exists?, to: :candidates

      def initialize(project, module_name, module_version)
        @project = project
        @module_name = module_name
        @module_version = module_version
      end

      def execute
        candidates.first
      end

      private

      def candidates
        @project
          .packages
          .golang
          .installable
          .with_name(@module_name)
          .with_version(@module_version)
      end
    end
  end
end
