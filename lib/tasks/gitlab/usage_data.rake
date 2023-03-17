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

    desc 'GitLab | UsageDataMetrics | Generate known_events/ci_templates.yml based on template definitions'
    task generate_ci_template_events: :environment do
      banner = <<~BANNER
          # This file is generated automatically by
          #   bin/rake gitlab:usage_data:generate_ci_template_events
          #
          # Do not edit it manually!
      BANNER

      all_includes = explicit_template_includes + implicit_auto_devops_includes
      yaml = banner + YAML.dump(all_includes).gsub(/ *$/m, '')

      File.write(Gitlab::UsageDataCounters::CiTemplateUniqueCounter::KNOWN_EVENTS_FILE_PATH, yaml)
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

    # Events for templates included via YAML-less Auto-DevOps
    def implicit_auto_devops_includes
      Gitlab::UsageDataCounters::CiTemplateUniqueCounter
        .all_included_templates('Auto-DevOps.gitlab-ci.yml')
        .map { |template| implicit_auto_devops_event(template) }
        .uniq
        .sort_by { _1['name'] }
    end

    # Events for templates included in a .gitlab-ci.yml using include:template
    def explicit_template_includes
      Gitlab::UsageDataCounters::CiTemplateUniqueCounter.ci_templates("lib/gitlab/ci/templates/").each_with_object([]) do |template, result|
        expanded_template_name = Gitlab::UsageDataCounters::CiTemplateUniqueCounter.expand_template_name(template)
        next unless expanded_template_name # guard against templates unavailable on FOSS

        event_name = Gitlab::UsageDataCounters::CiTemplateUniqueCounter.ci_template_event_name(expanded_template_name, :repository_source)

        result << ci_template_event(event_name)
      end
    end

    def ci_template_event(event_name)
      {
        'name' => event_name,
        'aggregation' => 'weekly'
      }
    end

    def implicit_auto_devops_event(expanded_template_name)
      event_name = Gitlab::UsageDataCounters::CiTemplateUniqueCounter.ci_template_event_name(expanded_template_name, :auto_devops_source)
      ci_template_event(event_name)
    end
  end
end
