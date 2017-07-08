module Gitlab
  module Routing
    extend ActiveSupport::Concern

    mattr_accessor :_includers
    self._includers = []

    included do
      Gitlab::Routing.includes_helpers(self)

      include Gitlab::Routing.url_helpers
    end

    def self.includes_helpers(klass)
      self._includers << klass
    end

    def self.add_helpers(mod)
      url_helpers.include mod
      url_helpers.extend mod

      GitlabRoutingHelper.include mod
      GitlabRoutingHelper.extend mod

      app_url_helpers = Gitlab::Application.routes.named_routes.url_helpers_module
      app_url_helpers.include mod
      app_url_helpers.extend mod

      _includers.each do |klass|
        klass.include mod
      end
    end

    # Returns the URL helpers Module.
    #
    # This method caches the output as Rails' "url_helpers" method creates an
    # anonymous module every time it's called.
    #
    # Returns a Module.
    def self.url_helpers
      @url_helpers ||= Gitlab::Application.routes.url_helpers
    end
  end
end
