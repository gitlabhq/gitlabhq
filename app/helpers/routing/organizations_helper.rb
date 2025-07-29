# frozen_string_literal: true

module Routing
  module OrganizationsHelper
    extend ActiveSupport::Concern

    # Provides organization-aware url helpers by automatically switching between
    # organization-scoped routes (/o/:organization_path/...) and global routes
    # based on the current organization context.
    #
    # This class iterates through existing URL helpers and maps between global
    # and Organization helpers by matching helper names.
    class MappedHelpers
      ORGANIZATION_PATH_PATTERN = '/o/:organization_path'
      ORGANIZATION_PATH_REGEX = %r{(?<=^|_)organizations?_}
      PATH_SUFFIX = '_path'
      URL_SUFFIX = '_url'

      mattr_accessor :already_installed, default: false

      def self.install
        return if already_installed

        route_pairs = find_route_pairs
        override_module = build_override_module(route_pairs)
        Gitlab::Application.routes.url_helpers.prepend(override_module)

        self.already_installed = true
      end

      def self.find_route_pairs
        all_routes = Rails.application.routes.routes
        org_routes, global_routes = all_routes.partition { |route| organization_route?(route) }
        build_route_pairs(org_routes, global_routes)
      end

      # Route name represents an Organization route.
      def self.organization_route?(route)
        route.path.spec.to_s.include?(ORGANIZATION_PATH_PATTERN)
      end

      # Build a Hash of global route => Organization route names.
      def self.build_route_pairs(organization_routes, global_routes)
        org_route_names = organization_routes.map(&:name)
        global_route_names = global_routes.map(&:name)

        # Global route => Organization route
        org_route_names.each_with_object({}) do |org_route_name, route_pairs|
          global_route_name = extract_global_route_name(org_route_name)
          next unless global_route_names.include?(global_route_name)

          route_pairs[global_route_name] = org_route_name
        end
      end

      # Map organization named route to global route.
      def self.extract_global_route_name(org_route_name)
        return if org_route_name.nil?

        # Handle organization patterns with proper underscore preservation
        org_route_name.gsub(ORGANIZATION_PATH_REGEX, '')
      end

      # Build a module that overrides URL helpers with organization-aware versions
      def self.build_override_module(route_pairs)
        Module.new do
          route_pairs.each do |global_route, org_route|
            [PATH_SUFFIX, URL_SUFFIX].each do |suffix|
              method_name = "#{global_route}#{suffix}"
              org_method_name = "#{org_route}#{suffix}"

              define_method(method_name) do |*args, **kwargs|
                # rubocop:disable Gitlab/AvoidCurrentOrganization -- Current organization not available earlier.
                org_scoped_path = Current.organization_assigned &&
                  !Current.organization.nil? &&
                  Current.organization.scoped_paths?

                if org_scoped_path
                  # Call the Organization helper method
                  method(org_method_name).call(*args, organization_path: Current.organization.path, **kwargs)
                else
                  # Call the original helper method
                  super(*args, **kwargs)
                end
                # rubocop:enable Gitlab/AvoidCurrentOrganization
              end
            end
          end
        end
      end
    end

    included do
      Rails.application.config.after_routes_loaded do
        MappedHelpers.install
      end
    end
  end
end
