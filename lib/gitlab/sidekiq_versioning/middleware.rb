# frozen_string_literal: true

module Gitlab
  module SidekiqVersioning
    class Middleware
      def call(worker, job, queue)
        worker.job_version = job['version']

        yield
      end
    end
  end
end
