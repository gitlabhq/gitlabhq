# frozen_string_literal: true

module Clusters
  module Applications
    class Ingress < ActiveRecord::Base
      VERSION = '0.23.0'.freeze

      self.table_name = 'clusters_applications_ingress'

      WILDCARD_DNS_DOMAIN = 'nip.io'.freeze

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue

      default_value_for :ingress_type, :nginx
      default_value_for :version, VERSION

      enum ingress_type: {
        nginx: 1
      }

      FETCH_IP_ADDRESS_DELAY = 30.seconds

      state_machine :status do
        before_transition any => [:installed] do |application|
          application.run_after_commit do
            ClusterWaitForIngressIpAddressWorker.perform_in(
              FETCH_IP_ADDRESS_DELAY, application.name, application.id)
          end
        end
      end

      def default_domain
        "#{external_ip}.#{WILDCARD_DNS_DOMAIN}" if external_ip
      end

      def chart
        'stable/nginx-ingress'
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          chart: chart,
          files: files
        )
      end

      def schedule_status_update
        return unless installed?
        return if external_ip

        ClusterWaitForIngressIpAddressWorker.perform_async(name, id)
      end
    end
  end
end
