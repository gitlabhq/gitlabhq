# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class BatchLoader
      def call(worker, job, queue)
        yield
      ensure
        ::BatchLoader::Executor.clear_current
      end
    end
  end
end
