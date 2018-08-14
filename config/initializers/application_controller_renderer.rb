# Remove this `if` condition when upgraded to rails 5.0.
# The body must be kept.
if Gitlab.rails5?
  # Be sure to restart your server when you modify this file.

  # ActiveSupport::Reloader.to_prepare do
  #   ApplicationController.renderer.defaults.merge!(
  #     http_host: 'example.org',
  #     https: false
  #   )
  # end
end
