module Gitlab
  module Routing
    extend ActiveSupport::Concern

    included do
      include Gitlab::Routing.url_helpers
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
