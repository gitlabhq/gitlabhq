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

    desc 'GitLab | UsageData | Generate usage ping and send it to Versions Application'
    task generate_and_send: :environment do
      result = ServicePing::SubmitService.new.execute

      puts Gitlab::Json.pretty_generate(result.attributes)
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

      repository_includes = ci_template_includes_hash(:repository_source)
      auto_devops_jobs_includes = ci_template_includes_hash(:auto_devops_source, 'Jobs')
      auto_devops_security_includes = ci_template_includes_hash(:auto_devops_source, 'Security')
      all_includes = [
        *repository_includes,
        ci_template_event('p_ci_templates_implicit_auto_devops'),
        *auto_devops_jobs_includes,
        *auto_devops_security_includes
      ]

      File.write(Gitlab::UsageDataCounters::CiTemplateUniqueCounter::KNOWN_EVENTS_FILE_PATH, banner + YAML.dump(all_includes).gsub(/ *$/m, ''))
    end

    def ci_template_includes_hash(source, template_directory = nil)
      Gitlab::UsageDataCounters::CiTemplateUniqueCounter.ci_templates("lib/gitlab/ci/templates/#{template_directory}").map do |template|
        expanded_template_name = Gitlab::UsageDataCounters::CiTemplateUniqueCounter.expand_template_name("#{template_directory}/#{template}")
        event_name = Gitlab::UsageDataCounters::CiTemplateUniqueCounter.ci_template_event_name(expanded_template_name, source)

        ci_template_event(event_name)
      end
    end

    def ci_template_event(event_name)
      {
        'name' => event_name,
        'category' => 'ci_templates',
        'redis_slot' => Gitlab::UsageDataCounters::CiTemplateUniqueCounter::REDIS_SLOT,
        'aggregation' => 'weekly'
      }
    end
  end
end
