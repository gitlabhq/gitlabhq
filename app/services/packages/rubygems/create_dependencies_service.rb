# frozen_string_literal: true

module Packages
  module Rubygems
    class CreateDependenciesService
      def initialize(package, gemspec)
        @package = package
        @gemspec = gemspec
      end

      def execute
        ::Packages::CreateDependencyService.new(package, dependencies).execute
      end

      private

      attr_reader :package, :gemspec

      def dependencies
        names_and_versions = gemspec.dependencies.to_h do |dependency|
          [dependency.name, dependency.requirement.to_s]
        end

        { 'dependencies' => names_and_versions }
      end
    end
  end
end
