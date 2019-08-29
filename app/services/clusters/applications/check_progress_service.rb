# frozen_string_literal: true

module Clusters
  module Applications
    class CheckProgressService < BaseHelmService
      def execute
        return unless operation_in_progress?

        case pod_phase
        when Gitlab::Kubernetes::Pod::SUCCEEDED
          on_success
        when Gitlab::Kubernetes::Pod::FAILED
          on_failed
        else
          check_timeout
        end
      rescue Kubeclient::HttpError => e
        log_error(e)

        app.make_errored!(_('Kubernetes error: %{error_code}') % { error_code: e.error_code })
      end

      private

      def operation_in_progress?
        raise NotImplementedError
      end

      def on_success
        raise NotImplementedError
      end

      def pod_name
        raise NotImplementedError
      end

      def on_failed
        app.make_errored!(_('Operation failed. Check pod logs for %{pod_name} for more details.') % { pod_name: pod_name })
      end

      def timed_out?
        raise NotImplementedError
      end

      def pod_phase
        helm_api.status(pod_name)
      end
    end
  end
end
