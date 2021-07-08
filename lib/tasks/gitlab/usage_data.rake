# frozen_string_literal: true

namespace :gitlab do
  namespace :usage_data do
    desc 'GitLab | UsageData | Generate raw SQLs for usage ping in YAML'
    task dump_sql_in_yaml: :environment do
      puts Gitlab::UsageDataQueries.uncached_data.to_yaml
    end

    desc 'GitLab | UsageData | Generate raw SQLs for usage ping in JSON'
    task dump_sql_in_json: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::UsageDataQueries.uncached_data)
    end

    desc 'GitLab | UsageData | Generate usage ping in JSON'
    task generate: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::UsageData.uncached_data)
    end

    desc 'GitLab | UsageData | Generate usage ping and send it to Versions Application'
    task generate_and_send: :environment do
      result = ServicePing::SubmitService.new.execute

      puts Gitlab::Json.pretty_generate(result.attributes)
    end

    desc 'GitLab | UsageData | Generate metrics dictionary'
    task generate_metrics_dictionary: :environment do
      items = Gitlab::Usage::MetricDefinition.definitions
      Gitlab::Usage::Docs::Renderer.new(items).write
    end

    desc 'GitLab | UsageDataMetrics | Generate usage ping from metrics definition YAML files in JSON'
    task generate_from_yaml: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::UsageDataMetrics.uncached_data)
    end
  end
end
