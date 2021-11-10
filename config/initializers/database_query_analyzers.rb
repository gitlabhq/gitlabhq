# frozen_string_literal: true

# Currently we register validator only for `dev` or `test` environment
if Gitlab.dev_or_test_env? || Gitlab::Utils.to_boolean(ENV['GITLAB_ENABLE_QUERY_ANALYZERS'], default: false)
  Gitlab::Database::QueryAnalyzer.instance.hook!

  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::Middleware::QueryAnalyzer)
  end
end
