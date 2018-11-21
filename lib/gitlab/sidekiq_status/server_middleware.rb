# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ServerMiddleware
      def call(worker, job, queue)
        ret = yield

        Gitlab::SidekiqStatus.unset(job['jid'])

        ret
      end
    end
  end
end
