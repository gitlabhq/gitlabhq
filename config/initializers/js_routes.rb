# frozen_string_literal: true

JsRoutes.setup do |c|
  # For description of options see
  # https://github.com/railsware/js-routes#available-options
  c.module_type = 'ESM'

  c.camel_case = true

  # Set prefix to empty string so it doesn't default to `Rails.application.config.relative_url_root``
  # We configure `relative_url_root` on the frontend in `app/assets/javascripts/behaviors/configure_path_helpers.js`
  # Silence until warning is fixed in https://github.com/railsware/js-routes/issues/340
  JsRoutes::Utils.deprecator.silence do
    c.prefix = ''
  end
end
