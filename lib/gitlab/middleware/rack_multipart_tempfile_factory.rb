# frozen_string_literal: true

module Gitlab
  module Middleware
    class RackMultipartTempfileFactory
      # Immediately unlink the created temporary file so we don't have to rely
      # on Rack::TempfileReaper catching this after the fact.
      FACTORY = lambda do |filename, content_type|
        Rack::Multipart::Parser::TEMPFILE_FACTORY.call(filename, content_type).tap(&:unlink)
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        if ENV['GITLAB_TEMPFILE_IMMEDIATE_UNLINK'] == '1'
          env[Rack::RACK_MULTIPART_TEMPFILE_FACTORY] = FACTORY
        end

        @app.call(env)
      end
    end
  end
end
