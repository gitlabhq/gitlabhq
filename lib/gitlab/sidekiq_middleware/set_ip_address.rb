# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class SetIpAddress
      def call(_worker_class, job, _queue)
        return yield unless job.key?('ip_address_state')

        ::Gitlab::IpAddressState.with(job['ip_address_state']) do # rubocop: disable CodeReuse/ActiveRecord -- Non-AR
          yield
        end
      end
    end
  end
end
