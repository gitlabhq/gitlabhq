# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ClientMiddleware
      def call(_, job, _, _)
        status_expiration = job['status_expiration'] || Gitlab::SidekiqStatus::DEFAULT_EXPIRATION

        Gitlab::SidekiqStatus.set(job['jid'], status_expiration)
        yield
      end
    end
  end
end
