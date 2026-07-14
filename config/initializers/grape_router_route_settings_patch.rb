# frozen_string_literal: true

# Grape 2.0 `Grape::Router::Route` delegates `settings` (one of
# `Grape::Router::AttributeTranslator::ROUTE_ATTRIBUTES`) to its attribute
# translator, so `settings` is a *defined* instance method and
# `Grape::Router::Route.method_defined?(:settings)` is `true`.
#
# Grape 2.4 removed `AttributeTranslator`: `Route < Grape::Router::BaseRoute`
# reaches `settings` only through `delegate_missing_to :@options`. At runtime
# `route.settings` and `route.respond_to?(:settings)` still work, but
# `method_defined?(:settings)` is now `false`.
#
# RSpec verifying doubles check `method_defined?` (not `respond_to?`), so every
# `instance_double(Grape::Router::Route, settings: ...)` raises
# `the Grape::Router::Route class does not implement the instance method:
# settings` on Grape 2.4.
#
# This patch restores `settings` and `description` as real public methods,
# delegating to `options[:settings]` / `options[:description]` (equivalent to
# the 2.0 delegated accessors and the 2.4 `delegate_missing_to` result). The
# guard makes it a no-op on Grape 2.0 (which already defines these methods via
# AttributeTranslator), so it is safe in the dual-boot Gemfile/Gemfile.next
# setup.
if defined?(Grape::Router::Route) &&
    !Grape::Router::Route.method_defined?(:settings)
  module GrapeRouterRouteSettingsPatch
    def settings
      options[:settings]
    end

    def description
      options[:description]
    end
  end

  Grape::Router::Route.prepend(GrapeRouterRouteSettingsPatch)
end
