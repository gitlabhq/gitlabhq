# frozen_string_literal: true

module Gitlab
  module Routing
    extend ActiveSupport::Concern

    class LegacyRedirector
      # @params path_type [symbol] type of path to do "-" redirection
      # https://gitlab.com/gitlab-org/gitlab/-/issues/16854
      def initialize(path_type)
        @path_type = path_type
      end

      def call(_params, request)
        ensure_valid_uri!(request)

        # Only replace the last occurrence of `path`.
        #
        # `request.fullpath` includes the querystring
        new_path = request.path.sub(%r{/#{@path_type}(/*)(?!.*#{@path_type})}, "/-/#{@path_type}\\1")
        new_path = "#{new_path}?#{request.query_string}" if request.query_string.present?

        new_path
      end

      private

      def ensure_valid_uri!(request)
        URI.parse(request.path)
      rescue URI::InvalidURIError => e
        # If url is invalid, raise custom error,
        # which can be ignored by monitoring tools.
        raise ActionController::RoutingError, e.message
      end
    end

    mattr_accessor :_includers
    self._includers = []

    included do
      Gitlab::Routing.includes_helpers(self)

      include Gitlab::Routing.url_helpers
    end

    def self.includes_helpers(klass)
      self._includers << klass
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

    def self.redirect_legacy_paths(router, *paths)
      paths.each do |path|
        router.match "/#{path}(/*rest)",
          via: [:get, :post, :patch, :delete],
          to: router.redirect(LegacyRedirector.new(path)),
          as: "legacy_#{path}_redirect"
      end
    end
  end
end
