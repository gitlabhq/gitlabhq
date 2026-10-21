# frozen_string_literal: true

module Banzai
  MissingConfigurationError = Class.new(StandardError)

  # Ports for everything the rendering pipeline needs from GitLab but cannot
  # derive on its own: URL building, reference resolution, feature flags and so
  # on. The monolith wires them in `config/initializers/0_banzai.rb`.
  #
  # Each input accepts a plain value or a callable, and callables are resolved
  # on every read rather than at boot, so a caller that stubs the underlying
  # monolith state still sees the stub. The reader passes its own arguments
  # through to the callable, so a port that needs an object, such as a URL
  # builder, is declared as `def url_builder(object)` and configured as
  # `->(object) { ... }`. Reading an input that was never set raises
  # `Banzai::MissingConfigurationError` naming the input.
  #
  # No input is declared yet. The filters extracted so far are self-contained;
  # ports arrive with the first filter that needs one.
  class Configuration
    private

    def resolve(name, value, *args)
      if value.nil?
        raise MissingConfigurationError,
          "`Banzai` input `#{name}` is not configured. Set it with " \
            "`Banzai.configure { |config| config.#{name} = ... }`."
      end

      value.respond_to?(:call) ? value.call(*args) : value
    end
  end
end
