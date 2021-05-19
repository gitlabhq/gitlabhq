# frozen_string_literal: true

module Clusters
  module Applications
    class PrometheusConfigService
      def initialize(project, cluster, app)
        @project = project
        @cluster = cluster
        @app = app
      end

      def execute(config = {})
        if has_alerts?
          generate_alert_manager(config)
        else
          reset_alert_manager(config)
        end
      end

      private

      attr_reader :project, :cluster, :app

      def reset_alert_manager(config)
        config = set_alert_manager_enabled(config, false)
        config.delete('alertmanagerFiles')
        config['serverFiles'] ||= {}
        config['serverFiles']['alerts'] = {}

        config
      end

      def generate_alert_manager(config)
        config = set_alert_manager_enabled(config, true)
        config = set_alert_manager_files(config)

        set_alert_manager_groups(config)
      end

      def set_alert_manager_enabled(config, enabled)
        config['alertmanager'] ||= {}
        config['alertmanager']['enabled'] = enabled

        config
      end

      def set_alert_manager_files(config)
        config['alertmanagerFiles'] = {
          'alertmanager.yml' => {
            'receivers' => alert_manager_receivers_params,
            'route' => alert_manager_route_params
          }
        }

        config
      end

      def set_alert_manager_groups(config)
        config['serverFiles'] ||= {}
        config['serverFiles']['alerts'] ||= {}
        config['serverFiles']['alerts']['groups'] ||= []

        environments_with_alerts.each do |env_name, alerts|
          index = config['serverFiles']['alerts']['groups'].find_index do |group|
            group['name'] == env_name
          end

          if index
            config['serverFiles']['alerts']['groups'][index]['rules'] = alerts
          else
            config['serverFiles']['alerts']['groups'] << {
              'name' => env_name,
              'rules' => alerts
            }
          end
        end

        config
      end

      def alert_manager_receivers_params
        [
          {
            'name' => 'gitlab',
            'webhook_configs' => [
              {
                'url' => notify_url,
                'send_resolved' => true,
                'http_config' => {
                  'bearer_token' => alert_manager_token
                }
              }
            ]
          }
        ]
      end

      def alert_manager_token
        app.alert_manager_token
      end

      def alert_manager_route_params
        {
          'receiver' => 'gitlab',
          'group_wait' => '30s',
          'group_interval' => '5m',
          'repeat_interval' => '4h'
        }
      end

      def notify_url
        ::Gitlab::Routing.url_helpers
          .notify_project_prometheus_alerts_url(project, format: :json)
      end

      def has_alerts?
        environments_with_alerts.values.flatten(1).any?
      end

      def environments_with_alerts
        @environments_with_alerts ||=
          environments.each_with_object({}) do |environment, hash|
            name = rule_name(environment)
            hash[name] = alerts(environment)
          end
      end

      def rule_name(environment)
        "#{environment.name}.rules"
      end

      def alerts(environment)
        alerts = Projects::Prometheus::AlertsFinder
          .new(environment: environment)
          .execute

        alerts.map do |alert|
          hash = alert.to_param
          hash['expr'] = substitute_query_variables(hash['expr'], environment)
          hash
        end
      end

      def substitute_query_variables(query, environment)
        result = ::Prometheus::ProxyVariableSubstitutionService.new(environment, query: query).execute

        result[:params][:query]
      end

      def environments
        project.environments_for_scope(cluster.environment_scope)
      end
    end
  end
end
