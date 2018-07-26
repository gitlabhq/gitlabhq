module Clusters
  module Applications
    class PrometheusUpdateService < BaseHelmService
      attr_accessor :project

      def initialize(app, project)
        super(app)
        @project = project
      end

      def execute
        app.make_updating!

        response = helm_api.get_config_map(app.get_command)
        config = extract_config(response)

        data =
          if has_alerts?
            generate_alert_manager(config)
          else
            reset_alert_manager(config)
          end

        helm_api.update(upgrade_command(data.to_yaml))

        ::ClusterWaitForAppUpdateWorker.perform_in(::ClusterWaitForAppUpdateWorker::INTERVAL, app.name, app.id)
      rescue ::Kubeclient::HttpError => ke
        app.make_update_errored!("Kubernetes error: #{ke.message}")
      rescue StandardError => e
        app.make_update_errored!(e.message)
      end

      private

      def reset_alert_manager(config)
        config = set_alert_manager_enabled(config, false)
        config.delete("alertmanagerFiles")
        config["serverFiles"]["alerts"] = {}

        config
      end

      def generate_alert_manager(config)
        config = set_alert_manager_enabled(config, true)
        config = set_alert_manager_files(config)

        set_alert_manager_groups(config)
      end

      def set_alert_manager_enabled(config, enabled)
        config["alertmanager"]["enabled"] = enabled

        config
      end

      def set_alert_manager_files(config)
        config["alertmanagerFiles"] = {
          "alertmanager.yml" => {
            "receivers" => alert_manager_receivers_params,
            "route" => alert_manager_route_params
          }
        }

        config
      end

      def set_alert_manager_groups(config)
        config["serverFiles"]["alerts"]["groups"] ||= []

        environments_with_alerts.each do |env_name, alerts|
          index = config["serverFiles"]["alerts"]["groups"].find_index do |group|
            group["name"] == env_name
          end

          if index
            config["serverFiles"]["alerts"]["groups"][index]["rules"] = alerts
          else
            config["serverFiles"]["alerts"]["groups"] << {
              "name" => env_name,
              "rules" => alerts
            }
          end
        end

        config
      end

      def alert_manager_receivers_params
        [
          {
            "name" => "gitlab",
            "webhook_configs" => [
              {
                "url" => notify_url,
                "send_resolved" => false
              }
            ]
          }
        ]
      end

      def alert_manager_route_params
        {
          "receiver" => "gitlab",
          "group_wait" => "30s",
          "group_interval" => "5m",
          "repeat_interval" => "4h"
        }
      end

      def notify_url
        ::Gitlab::Routing.url_helpers.notify_namespace_project_prometheus_alerts_url(
          namespace_id: project.namespace.path,
          project_id: project.path,
          format: :json
        )
      end

      def extract_config(response)
        YAML.safe_load(response.data.values)
      end

      def has_alerts?
        environments_with_alerts.values.flatten.any?
      end

      def environments_with_alerts
        @environments_with_alerts ||=
          environments.each_with_object({}) do |environment, hsh|
            name = rule_name(environment)
            hsh[name] = environment.prometheus_alerts.map(&:to_param)
          end
      end

      def rule_name(environment)
        "#{environment.name}.rules"
      end

      def environments
        project.environments_for_scope(cluster.environment_scope)
      end
    end
  end
end
