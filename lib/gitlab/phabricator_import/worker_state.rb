# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    class WorkerState
      def initialize(project_id)
        @project_id = project_id
      end

      def add_job
        redis.with do |r|
          r.pipelined do |pipe|
            pipe.incr(all_jobs_key)
            pipe.expire(all_jobs_key, timeout)
          end
        end
      end

      def remove_job
        redis.with do |r|
          r.decr(all_jobs_key)
        end
      end

      def running_count
        redis.with { |r| r.get(all_jobs_key) }.to_i
      end

      private

      attr_reader :project_id

      def redis
        Gitlab::Redis::SharedState
      end

      def all_jobs_key
        @all_jobs_key ||= "phabricator-import/jobs/project-#{project_id}/job-count"
      end

      def timeout
        # Make sure we get rid of all the information after a job is marked
        # as failed/succeeded
        StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION
      end
    end
  end
end
