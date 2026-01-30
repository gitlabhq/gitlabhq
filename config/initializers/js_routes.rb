# frozen_string_literal: true

# We want the js-routes JavaScript utils but need to customize the output of the JavaScript path helpers.
# To force js-routes to generate the JavaScript utils but not the JavaScript path helpers
# we can pass a fake `Rails::Application` object with empty `named_routes`.
# We then customize the output of the JavaScript path helpers in `lib/gitlab/js_routes.rb`
# Proposal to expose a public method to directly generate the js-routes JavaScript utils
# https://github.com/railsware/js-routes/issues/339
# We can remove this workaround if that proposal is accepted
class JsRoutesEmptyRoutesApplication
  Routes = Struct.new(:named_routes)

  NamedRoutes = Struct.new do
    def to_h
      {}
    end
  end

  def routes
    Routes.new(NamedRoutes.new)
  end

  def reload_routes_unless_loaded; end

  def reload_routes!; end

  def is_a?(klass)
    klass == Rails::Application
  end
end

JsRoutes.setup do |c|
  c.application = -> do
    JsRoutesEmptyRoutesApplication.new
  end

  c.module_type = 'ESM'

  c.optional_definition_params = true

  c.camel_case = true

  # Set prefix to empty string so it doesn't default to `Rails.application.config.relative_url_root``
  # We configure `relative_url_root` on the frontend in `app/assets/javascripts/behaviors/configure_path_helpers.js`
  # Silence until warning is fixed in https://github.com/railsware/js-routes/issues/340
  JsRoutes::Utils.deprecator.silence do
    c.prefix = ''
  end

  # More options:
  # @see https://github.com/railsware/js-routes#available-options
end
