# frozen_string_literal: true

module Gitlab
  module Middleware
    class RackMultipartTempfileFactory
      # Immediately unlink the created temporary file so we don't have to rely
      # on Rack::TempfileReaper catching this after the fact.
      FACTORY = ->(filename, content_type) do
        Rack::Multipart::Parser::TEMPFILE_FACTORY.call(filename, content_type).tap(&:unlink)
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        env[Rack::RACK_MULTIPART_TEMPFILE_FACTORY] = FACTORY

        @app.call(env)
      end
    end
  end
end
