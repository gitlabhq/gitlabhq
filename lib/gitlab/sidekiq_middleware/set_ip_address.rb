# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class SetIpAddress
      def call(_worker_class, job, _queue)
        return yield if Feature.disabled?(:sidekiq_ip_address) # rubocop: disable Gitlab/FeatureFlagWithoutActor -- not applicable

        ::Gitlab::IpAddressState.with(job['meta.remote_ip']) do # rubocop: disable CodeReuse/ActiveRecord -- Non-AR
          yield
        end
      end
    end
  end
end
