module Ci
  module RoutesHelper
    class Base
      include Gitlab::Application.routes.url_helpers

      def default_url_options
        {
          host: Settings.gitlab['host'],
          protocol: Settings.gitlab['https'] ? "https" : "http",
          port: Settings.gitlab['port']
        }
      end
    end

    def url_helpers
      @url_helpers ||= Base.new
    end

    def self.method_missing(method, *args, &block)
      @url_helpers ||= Base.new

      if @url_helpers.respond_to?(method)
        @url_helpers.send(method, *args, &block)
      else
        super method, *args, &block
      end
    end
  end
end
