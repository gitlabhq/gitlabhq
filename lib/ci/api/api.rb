module Ci
  module API
    class API < Grape::API
      include ::API::APIGuard
      version 'v1', using: :path

      rescue_from ActiveRecord::RecordNotFound do
        rack_response({ 'message' => '404 Not found' }.to_json, 404)
      end

      # Retain 405 error rather than a 500 error for Grape 0.15.0+.
      # https://github.com/ruby-grape/grape/blob/a3a28f5b5dfbb2797442e006dbffd750b27f2a76/UPGRADING.md#changes-to-method-not-allowed-routes
      rescue_from Grape::Exceptions::MethodNotAllowed do |e|
        error! e.message, e.status, e.headers
      end

      rescue_from Grape::Exceptions::Base do |e|
        error! e.message, e.status, e.headers
      end

      rescue_from :all do |exception|
        handle_api_exception(exception)
      end

      content_type :txt,  'text/plain'
      content_type :json, 'application/json'
      format :json

      helpers ::SentryHelper
      helpers ::Ci::API::Helpers
      helpers ::API::Helpers
      helpers Gitlab::CurrentSettings

      mount ::Ci::API::Builds
      mount ::Ci::API::Runners
      mount ::Ci::API::Triggers
    end
  end
end
