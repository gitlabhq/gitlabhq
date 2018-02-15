module Clusters
  module Applications
    class CheckIngressIpAddressService < BaseHelmService
      LEASE_TIMEOUT = 3.seconds.to_i

      def execute(retries_remaining)
        return if app.external_ip
        return unless try_obtain_lease

        service = get_service

        if service.status.loadBalancer.ingress
          resolve_external_ip(service)
        else
          retry_if_necessary(retries_remaining)
        end

      rescue KubeException
        retry_if_necessary(retries_remaining)
      end

      private

      def try_obtain_lease
        Gitlab::ExclusiveLease
          .new("check_ingress_ip_address_service:#{app.id}", timeout: LEASE_TIMEOUT)
          .try_obtain
      end

      def resolve_external_ip(service)
        app.update!( external_ip: service.status.loadBalancer.ingress[0].ip)
      end

      def get_service
        kubeclient.get_service('ingress-nginx-ingress-controller', Gitlab::Kubernetes::Helm::NAMESPACE)
      end

      def retry_if_necessary(retries_remaining)
        if retries_remaining > 0
          ClusterWaitForIngressIpAddressWorker.perform_in(
            ClusterWaitForIngressIpAddressWorker::INTERVAL, app.name, app.id, retries_remaining - 1)
        end
      end
    end
  end
end
