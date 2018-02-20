module Clusters
  module Applications
    class CheckIngressIpAddressService < BaseHelmService
      Error = Class.new(StandardError)

      LEASE_TIMEOUT = 3.seconds.to_i

      def execute
        return true if app.external_ip
        return true unless try_obtain_lease

        service = get_service

        if service.status.loadBalancer.ingress
          resolve_external_ip(service)
        else
          false
        end

      rescue KubeException => e
        raise Error, "#{e.class}: #{e.message}"
      end

      private

      def try_obtain_lease
        Gitlab::ExclusiveLease
          .new("check_ingress_ip_address_service:#{app.id}", timeout: LEASE_TIMEOUT)
          .try_obtain
      end

      def resolve_external_ip(service)
        app.update!(external_ip: service.status.loadBalancer.ingress[0].ip)
      end

      def get_service
        kubeclient.get_service('ingress-nginx-ingress-controller', Gitlab::Kubernetes::Helm::NAMESPACE)
      end
    end
  end
end
