Dir["#{Rails.root}/lib/ci/api/*.rb"].each {|file| require file}

module Ci
  module API
    class API < Grape::API
      include APIGuard
      version 'v1', using: :path

      rescue_from ActiveRecord::RecordNotFound do
        rack_response({ 'message' => '404 Not found' }.to_json, 404)
      end

      rescue_from :all do |exception|
        # lifted from https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb#L60
        # why is this not wrapped in something reusable?
        trace = exception.backtrace

        message = "\n#{exception.class} (#{exception.message}):\n"
        message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
        message << "  " << trace.join("\n  ")

        API.logger.add Logger::FATAL, message
        rack_response({ 'message' => '500 Internal Server Error' }, 500)
      end

      format :json

      helpers Helpers
      helpers ::API::Helpers
      helpers Gitlab::CurrentSettings

      mount Builds
      mount Commits
      mount Runners
      mount Projects
      mount Triggers
    end
  end
end
