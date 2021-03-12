# frozen_string_literal: true

module Packages
  module Rubygems
    class DependencyResolverService < BaseService
      include Gitlab::Utils::StrongMemoize

      DEFAULT_PLATFORM = 'ruby'

      def execute
        return ServiceResponse.error(message: "forbidden", http_status: :forbidden) unless Ability.allowed?(current_user, :read_package, project)
        return ServiceResponse.error(message: "#{gem_name} not found", http_status: :not_found) if packages.empty?

        payload = packages.map do |package|
          dependencies = package.dependency_links.map do |link|
            [link.dependency.name, link.dependency.version_pattern]
          end

          {
            name: gem_name,
            number: package.version,
            platform: DEFAULT_PLATFORM,
            dependencies: dependencies
          }
        end

        ServiceResponse.success(payload: payload)
      end

      private

      def packages
        strong_memoize(:packages) do
          project.packages.with_name(gem_name)
        end
      end

      def gem_name
        params[:gem_name]
      end
    end
  end
end
