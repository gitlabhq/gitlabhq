module Gitlab
  module Ci
    module Queueing
      class RunnerQueue
        attr_reader :runner

        EnqueuedBuild = Struct.new(:project_id, :build_id, :project_queue_key, :build_queue_key)

        # This class uses two Redis lists:
        #
        # gitlab:ci:job_queue:runners:#{runner.id}:buckets:#{bucket_ranges}
        #   - to store a list of projects that contains jobs for given runner
        #   - this is balanced based on number of jobs for given project
        #   - the projects with high number of jobs are put into contention with other projects
        # gitlab:ci:job_queue:runners:#{runner.id}:projects:#{project_id}
        #   - to store a list of jobs for given runner and project
        #   - the list already filtered
        #
        # Bucket ranges:
        #   - this defines a number of jobs that project is trying to execute on given runner
        #     we put "projects with high usage" in exponential ranges

        BUCKET_RANGES = [1, 10, 50, inf]

        def initialize(runner)
          @runner = runner
        end

        def enqueue(build)
          with_redis do |redis|
            redis.rpush(queue_project_key(build.project_id), build_id)
            redis.rpush(queue_jobs_key(queue_job_bucket(build.project_id)), build.project_id)
          end
        end

        def dequeue
          with_redis do |redis|
            # We use circular list
            # Runner once job is picked it is gonna be removed from the list
            queue_jobs_keys.sample.each do |queue_key|
              # TODO: instead of pop, we could grab
              # a random index from that list it would make it spread more evenly
              project_id = redis.brpoplpush(queue_key, queue_key)
              next unless project_id

              build_id = redis.brpoplpush(queue_project_key(project), queue_project_key(project))
              next unless build_id

              return EnqueuedBuild.new(project_id, build_id, queue_key, queue_project_key(project))
            end
          end
        end

        def remove!(enqueued_job)
          with_redis do |redis|
            redis.lrem(enqueued_job.project_queue_key, 1, enqueued_job.project_id)
            redis.lrem(enqueued_job.build_queue_key, 1, enqueued_job.build_id)
          end
        end

        private

        def queue_job_bucket(project_id)
          builds = builds_for_project(project_id)

          bucket_index = BUCKET_RANGES.find_index do |range|
            builds < range
          end
        end

        def queue_jobs_keys
          @queue_jobs_keys ||= BUCKET_RANGES.count.times do |bucket|
            queue_jobs_key(bucket)
          end
        end

        def queue_project_key(project_id)
          "gitlab:ci:job_queue:runners:#{runner.id}:projects:#{project_id}"
        end

        def queue_jobs_key(bucket)
          "gitlab:ci:job_queue:runners:#{runner.id}:buckets:#{bucket}"
        end

        def builds_for_project(project)
          with_redis do |redis|
            redis.len(queue_project_key(project_id)) || 0
          end
        end

        def with_redis
          Gitlab::Redis::SharedState.with do |redis|
            yield(redis)
          end
        end
      end
    end
  end
end
