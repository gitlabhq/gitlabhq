module Ci
  module RoutesHelper
    class Base
      include Gitlab::Application.routes.url_helpers

      def default_url_options
        {
          host: Ci::Settings.gitlab_ci['host'],
          protocol: Ci::Settings.gitlab_ci['https'] ? "https" : "http",
          port: Ci::Settings.gitlab_ci['port']
        }
      end
    end

    def url_helpers
      @url_helpers ||= Ci::Base.new
    end

    def self.method_missing(method, *args, &block)
      @url_helpers ||= Ci::Base.new

      if @url_helpers.respond_to?(method)
        @url_helpers.send(method, *args, &block)
      else
        super method, *args, &block
      end
    end
  end
end
