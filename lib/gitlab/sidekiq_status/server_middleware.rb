module Gitlab
  module SidekiqStatus
    class ServerMiddleware
      def call(worker, job, queue)
        ret = yield

        Gitlab::SidekiqStatus.unset(job['jid']) unless job.delete('do_not_unset_sidekiq_status')

        ret
      end
    end
  end
end
