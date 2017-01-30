module Gitlab
  module SidekiqStatus
    class ServerMiddleware
      def call(worker, job, queue)
        ret = yield

        SidekiqStatus.unset(job['jid'])

        ret
      end
    end
  end
end
