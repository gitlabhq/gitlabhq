# frozen_string_literal: true

# Currently we register validator only for `dev` or `test` environment
Gitlab::Database::QueryAnalyzer.instance.tap do |query_analyzer|
  query_analyzer.hook!

  query_analyzer.all_analyzers.tap do |analyzers|
    analyzers.append(::Gitlab::Database::QueryAnalyzers::GitlabSchemasMetrics)
    analyzers.append(::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification)
    analyzers.append(::Gitlab::Database::QueryAnalyzers::Ci::PartitioningRoutingAnalyzer)
    analyzers.append(::Gitlab::Database::QueryAnalyzers::LogLargeInLists)

    if Gitlab.dev_or_test_env?
      analyzers.append(::Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection)
      analyzers.append(::Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch)
    end
  end
end

Gitlab::Application.configure do |config|
  config.middleware.use(Gitlab::Middleware::QueryAnalyzer)
end
