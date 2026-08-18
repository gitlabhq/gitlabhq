# frozen_string_literal: true

# `Grape::Router::Route < Grape::Router::BaseRoute` reaches `settings` and
# `description` only through `delegate_missing_to :@options`, so both resolve via
# `method_missing` rather than being defined. `route.settings` and
# `route.respond_to?(:settings)` work, but `method_defined?(:settings)` is `false`.
#
# RSpec verifying doubles check `method_defined?` (not `respond_to?`), so without
# this patch every `instance_double(Grape::Router::Route, settings: ...)` raises
# `the Grape::Router::Route class does not implement the instance method:
# settings`.
#
# Defining the two attributes as real public methods over `options[...]` returns
# exactly what `delegate_missing_to` returns, so behaviour is unchanged, and it
# keeps them introspectable for callers that ask what the class implements.
#
# The guard makes this a no-op if a future Grape defines them for real, so it
# never shadows an upstream implementation.
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
