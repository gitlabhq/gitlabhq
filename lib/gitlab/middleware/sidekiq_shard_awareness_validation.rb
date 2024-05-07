# frozen_string_literal: true

module Gitlab
  module Middleware
    class SidekiqShardAwarenessValidation
      include Gitlab::Utils::StrongMemoize

      SIDEKIQ_WEB_UI_PATH = %r{^/admin/sidekiq}

      def initialize(app)
        @app = app
      end

      def call(env)
        path = env['PATH_INFO'].delete_prefix(relative_url)
        match_data = path.match(SIDEKIQ_WEB_UI_PATH)

        return @app.call(env) if match_data

        ::Gitlab::SidekiqSharding::Validator.enabled { @app.call(env) }
      end

      def relative_url
        File.join('', Gitlab.config.gitlab.relative_url_root).chomp('/')
      end
      strong_memoize_attr :relative_url
    end
  end
end
