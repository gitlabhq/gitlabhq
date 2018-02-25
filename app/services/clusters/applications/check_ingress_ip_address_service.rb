module Clusters
  module Applications
    class CheckIngressIpAddressService < BaseHelmService
      include Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)

      LEASE_TIMEOUT = 15.seconds.to_i

      def execute
        return if app.external_ip
        return unless try_obtain_lease

        app.update!(external_ip: ingress_ip) if ingress_ip
      end

      private

      def try_obtain_lease
        Gitlab::ExclusiveLease
          .new("check_ingress_ip_address_service:#{app.id}", timeout: LEASE_TIMEOUT)
          .try_obtain
      end

      def ingress_ip
        service.status.loadBalancer.ingress&.first&.ip
      end

      def service
        strong_memoize(:ingress_service) do
          kubeclient.get_service('ingress-nginx-ingress-controller', Gitlab::Kubernetes::Helm::NAMESPACE)
        end
      end
    end
  end
end
