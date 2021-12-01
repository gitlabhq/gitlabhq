# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ClientMiddleware
      def call(_, job, _, _)
        status_expiration = job['status_expiration'] || Gitlab::SidekiqStatus::DEFAULT_EXPIRATION
        value = job['status_expiration'] ? 2 : Gitlab::SidekiqStatus::DEFAULT_VALUE

        Gitlab::SidekiqStatus.set(job['jid'], status_expiration, value: value)
        yield
      end
    end
  end
end
