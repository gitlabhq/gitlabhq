module Gitlab
  module SidekiqVersioning
    class Middleware
      def call(worker, job, queue)
        worker.job_version = job['version']

        if SidekiqVersioning.requeue_unsupported_job(worker, job, queue)
          job['do_not_unset_sidekiq_status'] = true

          return
        end

        yield
      end
    end
  end
end
