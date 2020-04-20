# frozen_string_literal: true

module Clusters
  module Applications
    class Ingress < ApplicationRecord
      VERSION = '1.29.7'
      INGRESS_CONTAINER_NAME = 'nginx-ingress-controller'
      MODSECURITY_LOG_CONTAINER_NAME = 'modsecurity-log'
      MODSECURITY_MODE_LOGGING = "DetectionOnly"
      MODSECURITY_MODE_BLOCKING = "On"
      MODSECURITY_OWASP_RULES_FILE = "/etc/nginx/owasp-modsecurity-crs/nginx-modsecurity.conf"

      self.table_name = 'clusters_applications_ingress'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue

      default_value_for :ingress_type, :nginx
      default_value_for :modsecurity_enabled, true
      default_value_for :version, VERSION
      default_value_for :modsecurity_mode, :logging

      enum ingress_type: {
        nginx: 1
      }

      enum modsecurity_mode: { logging: 0, blocking: 1 }

      FETCH_IP_ADDRESS_DELAY = 30.seconds

      state_machine :status do
        after_transition any => [:installed] do |application|
          application.run_after_commit do
            ClusterWaitForIngressIpAddressWorker.perform_in(
              FETCH_IP_ADDRESS_DELAY, application.name, application.id)
          end
        end
      end

      def chart
        'stable/nginx-ingress'
      end

      def values
        content_values.to_yaml
      end

      def allowed_to_uninstall?
        external_ip_or_hostname? && !application_jupyter_installed?
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files
        )
      end

      def external_ip_or_hostname?
        external_ip.present? || external_hostname.present?
      end

      def schedule_status_update
        return unless installed?
        return if external_ip
        return if external_hostname

        ClusterWaitForIngressIpAddressWorker.perform_async(name, id)
      end

      def ingress_service
        cluster.kubeclient.get_service("ingress-#{INGRESS_CONTAINER_NAME}", Gitlab::Kubernetes::Helm::NAMESPACE)
      end

      private

      def specification
        return {} unless modsecurity_enabled

        {
          "controller" => {
            "config" => {
              "enable-modsecurity" => "true",
              "enable-owasp-modsecurity-crs" => "false",
              "modsecurity-snippet" => modsecurity_snippet_content,
              "modsecurity.conf" => modsecurity_config_content
            },
            "extraContainers" => [
              {
                "name" => MODSECURITY_LOG_CONTAINER_NAME,
                "image" => "busybox",
                "args" => [
                  "/bin/sh",
                  "-c",
                  "tail -f /var/log/modsec/audit.log"
                ],
                "volumeMounts" => [
                  {
                    "name" => "modsecurity-log-volume",
                    "mountPath" => "/var/log/modsec",
                    "readOnly" => true
                  }
                ],
                "livenessProbe" => {
                  "exec" => {
                    "command" => [
                      "ls",
                      "/var/log/modsec/audit.log"
                    ]
                  }
                }
              }
            ],
            "extraVolumeMounts" => [
              {
                "name" => "modsecurity-template-volume",
                "mountPath" => "/etc/nginx/modsecurity/modsecurity.conf",
                "subPath" => "modsecurity.conf"
              },
              {
                "name" => "modsecurity-log-volume",
                "mountPath" => "/var/log/modsec"
              }
            ],
            "extraVolumes" => [
              {
                "name" => "modsecurity-template-volume",
                "configMap" => {
                  "name" => "ingress-#{INGRESS_CONTAINER_NAME}",
                  "items" => [
                    {
                      "key" => "modsecurity.conf",
                      "path" => "modsecurity.conf"
                    }
                  ]
                }
              },
              {
                "name" => "modsecurity-log-volume",
                "emptyDir" => {}
              }
            ]
          }
        }
      end

      def modsecurity_config_content
        File.read(modsecurity_config_file_path)
      end

      def modsecurity_config_file_path
        Rails.root.join('vendor', 'ingress', 'modsecurity.conf')
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end

      def application_jupyter_installed?
        cluster.application_jupyter&.installed?
      end

      def modsecurity_snippet_content
        sec_rule_engine = logging? ? MODSECURITY_MODE_LOGGING : MODSECURITY_MODE_BLOCKING
        "SecRuleEngine #{sec_rule_engine}\nInclude #{MODSECURITY_OWASP_RULES_FILE}"
      end
    end
  end
end
