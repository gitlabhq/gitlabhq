# frozen_string_literal: true

# Currently we register validator only for `dev` or `test` environment
Gitlab::Database::QueryAnalyzer.instance.hook!
Gitlab::Database::QueryAnalyzer.instance.all_analyzers.append(::Gitlab::Database::QueryAnalyzers::GitlabSchemasMetrics)
Gitlab::Database::QueryAnalyzer.instance.all_analyzers.append(
  ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification
)

if Gitlab.dev_or_test_env?
  query_analyzer = ::Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection
  Gitlab::Database::QueryAnalyzer.instance.all_analyzers.append(query_analyzer)
end

Gitlab::Application.configure do |config|
  config.middleware.use(Gitlab::Middleware::QueryAnalyzer)
end
