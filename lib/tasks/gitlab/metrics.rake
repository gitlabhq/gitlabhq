# frozen_string_literal: true

namespace :metrics do
  desc "GitLab | Setup common metrics"
  task setup_common_metrics: :gitlab_environment do
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end
end
