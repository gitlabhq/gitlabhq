# frozen_string_literal: true

module Routing
  module OrganizationsHelper
    extend ActiveSupport::Concern

    # Provides organization-aware url helpers, switching between
    # organization-scoped routes (/o/:organization_path/...) and global ones.
    # See https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/contexts/.
    #
    # Wired up for every route pair sharing a name by convention (see
    # MappedHelpers.build_route_pairs) - this does not yet verify that a
    # pair actually resolves to the same controller/action.
    #
    # For a paired route, nesting is decided in order by:
    # 1. Current.data_context, if it resolves to Organization context -
    #    inescapable, see Gitlab::Current::DataContext.
    # 2. `foo_path(organization_path: ...)`, an explicit per-call override
    #    (including `nil`, to force the global path).
    # 3. The request itself: the URL's /o/:organization_path segment, or the
    #    X-GitLab-Organization-ID header that frontend API calls send (REST
    #    and GraphQL endpoints are never /o/-scoped themselves).
    class MappedHelpers
      ORGANIZATION_PATH_PATTERN = '/o/:organization_path'
      ORGANIZATION_PATH_REGEX = %r{(?<=^|_)organizations?_}
      PATH_SUFFIX = '_path'
      URL_SUFFIX = '_url'

      mattr_accessor :already_installed, default: false

      def self.install
        return if already_installed

        routes = Gitlab::Application.routes
        url_helpers = routes.url_helpers

        # Preserve original paths for use in specific circumstances.
        alias_unscoped(url_helpers, :root_url)
        alias_unscoped(url_helpers, :root_path)
        alias_unscoped(url_helpers, :group_canonical_url)
        alias_unscoped(url_helpers, :group_canonical_path)

        # Override URL helpers to be Organization context aware.
        route_pairs = find_route_pairs
        override_module = build_override_module(route_pairs)
        url_helpers.prepend(override_module)
        # The dispatch paths below are new and roll out gradually behind the
        # extended_organization_url_scoping derisk flag, checked per call (the
        # prepends themselves can't be flag-gated: they happen once at boot).
        gated_module = build_override_module(route_pairs, gated: true)
        # Module-level calls (Gitlab::Routing.url_helpers.foo_path) dispatch
        # through the singleton, where Rails `extend`s the raw helpers, so the
        # prepend above doesn't reach them - cover that path too.
        url_helpers.singleton_class.prepend(gated_module)
        # url_for and polymorphic_url delegate to Rails' internal proxy, which
        # includes only these inner modules (undocumented Rails internals; the
        # polymorphic examples in organizations_helper_spec.rb are the canary).
        named_routes = routes.named_routes
        named_routes.url_helpers_module.prepend(gated_module)
        named_routes.path_helpers_module.prepend(gated_module)

        self.already_installed = true
      end

      def self.alias_unscoped(url_helpers, existing_method)
        unscoped_method = "unscoped_#{existing_method}"
        return unless url_helpers.respond_to?(existing_method)

        url_helpers.alias_method(unscoped_method, existing_method)
        url_helpers.singleton_class.alias_method(unscoped_method, existing_method)
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

        org_route_names.each_with_object({}) do |org_route_name, route_pairs|
          global_route_name = extract_global_route_name(org_route_name)
          next unless global_route_names.include?(global_route_name)

          route_pairs[global_route_name] = org_route_name
        end
      end

      # Map organization named route to global route.
      def self.extract_global_route_name(org_route_name)
        return if org_route_name.nil?

        # Strip only the first `organization_` token (the `as: :organization`
        # scope prefix); `gsub` would also remove a legitimate `organization_`
        # in the global name, e.g. the admin `organization_dashboard`.
        org_route_name.sub(ORGANIZATION_PATH_REGEX, '')
      end

      # The organization_path to nest under, if any - see the class comment
      # above for the rule order. from_organization_params/from_headers, not
      # from_request: that one also infers an Organization from a group or
      # project's own namespace, which isn't what the request itself named.
      def self.scoped_path_for(kwargs)
        data_context = ::Current.data_context
        return data_context.context.path if data_context&.type == :organization

        return kwargs[:organization_path] if kwargs.key?(:organization_path)

        resolver = ::Current.organization_resolver
        return unless resolver

        (resolver.from_organization_params || header_organization(resolver))&.path
      end

      # Unlike a /o/ URL, the header is sent by all frontend API calls, also
      # for Organizations that never use scoped paths (e.g. the default
      # Organization) - it must not force scoping for those.
      def self.header_organization(resolver)
        return unless extended_scoping_enabled?

        organization = resolver.from_headers
        organization if organization&.scoped_paths?
      end

      # Feature.current_request keeps the flag state stable for a whole
      # request, so one response never mixes scoped and unscoped URLs.
      def self.extended_scoping_enabled?
        Feature.enabled?(:extended_organization_url_scoping, Feature.current_request)
      end

      # Build a module that overrides URL helpers with organization-aware
      # versions. With gated: true the organization branch additionally
      # requires the extended_organization_url_scoping flag - used for the
      # dispatch paths this flag derisks (module singleton, Rails' proxy).
      # The flag is only consulted after an organization context was found,
      # so boot-time helper calls never trigger a Feature lookup.
      def self.build_override_module(route_pairs, gated: false)
        Module.new do
          route_pairs.each do |global_route, org_route|
            [PATH_SUFFIX, URL_SUFFIX].each do |suffix|
              method_name = "#{global_route}#{suffix}"
              org_method_name = "#{org_route}#{suffix}"

              define_method(method_name) do |*args, **kwargs|
                # Handle Ruby 2.4+ keyword argument compatibility
                # If kwargs is empty but last arg is a hash, treat it as kwargs
                kwargs = args.pop if kwargs.empty? && args.last.is_a?(Hash) && !args.last.frozen?

                scoped_path = Routing::OrganizationsHelper::MappedHelpers.scoped_path_for(kwargs)

                if scoped_path.present?
                  if !gated || Routing::OrganizationsHelper::MappedHelpers.extended_scoping_enabled?
                    kwargs[:organization_path] = scoped_path
                    # Call the Organization helper method
                    return method(org_method_name).call(*args, **kwargs)
                  end

                  # Gate closed: drop an explicit organization_path, which the
                  # global route would render as a stray query param. When the
                  # path came from Current context only, `except` is a no-op.
                  kwargs = kwargs.except(:organization_path)
                end

                # Call the original helper method
                super(*args, **kwargs)
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
