# frozen_string_literal: true

namespace :gitlab do
  namespace :usage_data do
    desc 'GitLab | UsageData | Generate raw SQLs for usage ping in YAML'
    task dump_sql_in_yaml: :environment do
      puts Gitlab::Usage::ServicePingReport.for(output: :metrics_queries).to_yaml
    end

    desc 'GitLab | UsageData | Generate raw SQLs for usage ping in JSON'
    task dump_sql_in_json: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::Usage::ServicePingReport.for(output: :metrics_queries))
    end

    desc 'GitLab | UsageData | Generate usage ping in JSON'
    task generate: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values))
    end

    desc 'GitLab | UsageData | Generate non SQL data for usage ping in JSON'
    task dump_non_sql_in_json: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::Usage::ServicePingReport.for(output: :non_sql_metrics_values))
    end

    desc 'GitLab | UsageData | Generate usage ping and send it to Versions Application'
    task generate_and_send: :environment do
      response = GitlabServicePingWorker.new.perform('triggered_from_cron' => false)

      puts response.body, response.code, response.message, response.headers.inspect
    end

    desc 'GitLab | UsageDataMetrics | Generate usage ping from metrics definition YAML files in JSON'
    task generate_from_yaml: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::UsageDataMetrics.uncached_data)
    end

    desc 'GitLab | UsageDataMetrics | Generate raw SQL metrics queries for RSpec'
    task generate_sql_metrics_queries: :environment do
      require 'active_support/testing/time_helpers'
      include ActiveSupport::Testing::TimeHelpers

      path = Rails.root.join('tmp', 'test')

      queries = travel_to(Time.utc(2021, 1, 1)) do
        Gitlab::Usage::ServicePingReport.for(output: :metrics_queries)
      end

      FileUtils.mkdir_p(path)
      File.write(File.join(path, 'sql_metrics_queries.json'), Gitlab::Json.pretty_generate(queries))
    end
  end
end
