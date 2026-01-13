# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ServerMiddleware
      def call(_worker, job, _queue)
        yield
      ensure
        Gitlab::SidekiqStatus.unset(job['jid'])
      end
    end
  end
end
