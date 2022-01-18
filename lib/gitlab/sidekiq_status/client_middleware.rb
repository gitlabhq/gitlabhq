# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ClientMiddleware
      def call(_, job, _, _)
        Gitlab::SidekiqStatus.set(job['jid'], job['status_expiration'])

        yield
      end
    end
  end
end
