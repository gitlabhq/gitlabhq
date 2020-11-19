# frozen_string_literal: true

module Clusters
  module Applications
    class Fluentd < ApplicationRecord
      VERSION = '2.4.0'
      CILIUM_CONTAINER_NAME = 'cilium-monitor'

      self.table_name = 'clusters_applications_fluentd'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION
      default_value_for :port, 514
      default_value_for :protocol, :tcp

      enum protocol: { tcp: 0, udp: 1 }

      validate :has_at_least_one_log_enabled?

      def chart
        'fluentd/fluentd'
      end

      def repository
        'https://gitlab-org.gitlab.io/cluster-integration/helm-stable-archive'
      end

      def install_command
        helm_command_module::InstallCommand.new(
          name: 'fluentd',
          repository: repository,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files
        )
      end

      def values
        content_values.to_yaml
      end

      private

      def has_at_least_one_log_enabled?
        if !waf_log_enabled && !cilium_log_enabled
          errors.add(:base, _("At least one logging option is required to be enabled"))
        end
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end

      def specification
        {
          "configMaps" => {
            "output.conf" => output_configuration_content,
            "general.conf" => general_configuration_content
          }
        }
      end

      def output_configuration_content
        <<~EOF
        <match kubernetes.**>
          @type remote_syslog
          @id out_kube_remote_syslog
          host #{host}
          port #{port}
          program fluentd
          hostname ${kubernetes_host}
          protocol #{protocol}
          packet_size 131072
          <buffer kubernetes_host>
          </buffer>
          <format>
            @type ltsv
          </format>
        </match>
        EOF
      end

      def general_configuration_content
        <<~EOF
        <match fluent.**>
          @type null
        </match>
        <source>
          @type http
          port 9880
          bind 0.0.0.0
        </source>
        <source>
          @type tail
          @id in_tail_container_logs
          path #{path_to_logs}
          pos_file /var/log/fluentd-containers.log.pos
          tag kubernetes.*
          read_from_head true
          <parse>
            @type json
            time_format %Y-%m-%dT%H:%M:%S.%NZ
          </parse>
        </source>
        EOF
      end

      def path_to_logs
        path = []
        path << "/var/log/containers/*#{Ingress::MODSECURITY_LOG_CONTAINER_NAME}*.log" if waf_log_enabled
        path << "/var/log/containers/*#{CILIUM_CONTAINER_NAME}*.log" if cilium_log_enabled
        path.join(',')
      end
    end
  end
end
