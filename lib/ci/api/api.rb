module Ci
  module API
    class API < Grape::API
      include ::API::APIGuard
      version 'v1', using: :path

      rescue_from ActiveRecord::RecordNotFound do
        rack_response({ 'message' => '404 Not found' }.to_json, 404)
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
      mount ::Ci::API::Lint
    end
  end
end
