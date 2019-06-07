# frozen_string_literal: true

module Clusters
  module Applications
    class CheckIngressIpAddressService < BaseHelmService
      include Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)

      LEASE_TIMEOUT = 15.seconds.to_i

      def execute
        return if app.external_ip
        return if app.external_hostname
        return unless try_obtain_lease

        app.external_ip = ingress_ip if ingress_ip
        app.external_hostname = ingress_hostname if ingress_hostname

        app.save! if app.changed?
      end

      private

      def try_obtain_lease
        Gitlab::ExclusiveLease
          .new("check_ingress_ip_address_service:#{app.id}", timeout: LEASE_TIMEOUT)
          .try_obtain
      end

      def ingress_ip
        ingress_service&.ip
      end

      def ingress_hostname
        ingress_service&.hostname
      end

      def ingress_service
        strong_memoize(:ingress_service) do
          app.ingress_service.status.loadBalancer.ingress&.first
        end
      end
    end
  end
end
