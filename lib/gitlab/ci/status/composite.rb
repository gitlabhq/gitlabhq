# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Composite
        include Gitlab::Utils::StrongMemoize

        # This class accepts an array of arrays/hashes/or objects
        # `with_allow_failure` will be removed when deleting ci_remove_ensure_stage_service
        def initialize(all_jobs, with_allow_failure: true, dag: false, project: nil)
          unless all_jobs.respond_to?(:pluck)
            raise ArgumentError, "all_jobs needs to respond to `.pluck`"
          end

          @status_set = Set.new
          @status_key = 0
          @allow_failure_key = 1 if with_allow_failure
          @dag = dag
          @project = project

          consume_all_jobs(all_jobs)
        end

        # The status calculation is order dependent,
        # 1. In some cases we assume that that status is exact
        #    if the we only have given statues,
        # 2. In other cases we assume that status is of that type
        #    based on what statuses are no longer valid based on the
        #    data set that we have
        #
        # This method is used for three cases:
        # 1. When it is called for a stage or a pipeline (with `all_jobs` from all jobs in a stage or a pipeline),
        #    then, the returned status is assigned to the stage or pipeline.
        # 2. When it is called for a job (with `all_jobs` from all previous jobs or all needed jobs),
        #    then, the returned status is used to determine if the job is processed or not.
        # 3. When it is called for a group (of jobs that are related),
        #    then, the returned status is used to show the overall status of the group.
        # rubocop: disable Metrics/CyclomaticComplexity
        # rubocop: disable Metrics/PerceivedComplexity
        def status
          return if none?

          strong_memoize(:status) do
            if @dag && any_skipped_or_ignored?
              # The DAG job is skipped if one of the needs does not run at all.
              'skipped'
            elsif only_of?(:skipped, :ignored)
              'skipped'
            elsif only_of?(:success, :skipped, :success_with_warnings, :ignored)
              'success'
            elsif only_of?(:created, :success_with_warnings, :ignored)
              'created'
            elsif only_of?(:preparing, :success_with_warnings, :ignored)
              'preparing'
            elsif only_of?(:canceled, :success, :skipped, :success_with_warnings, :ignored)
              'canceled'
            elsif only_of?(:pending, :created, :skipped, :success_with_warnings, :ignored)
              'pending'
            elsif any_of?(:running, :pending)
              'running'
            elsif any_of?(:waiting_for_resource)
              'waiting_for_resource'
            elsif any_of?(:waiting_for_callback)
              'waiting_for_callback'
            elsif any_of?(:manual)
              'manual'
            elsif any_of?(:scheduled)
              'scheduled'
            elsif any_of?(:preparing)
              'preparing'
            elsif any_of?(:created)
              'running'
            elsif any_of?(:canceling)
              'canceling'
            else
              'failed'
            end
          end
        end
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/PerceivedComplexity

        def warnings?
          @status_set.include?(:success_with_warnings)
        end

        private

        def none?
          @status_set.empty?
        end

        def any_of?(*names)
          names.any? { |name| @status_set.include?(name) }
        end

        def only_of?(*names)
          matching = names.count { |name| @status_set.include?(name) }
          matching > 0 &&
            matching == @status_set.size
        end

        def any_skipped_or_ignored?
          any_of?(:skipped) || any_of?(:ignored)
        end

        def consume_all_jobs(all_jobs)
          columns = []
          columns[@status_key] = :status
          columns[@allow_failure_key] = :allow_failure if @allow_failure_key

          all_jobs
            .pluck(*columns) # rubocop: disable CodeReuse/ActiveRecord
            .each do |job_attrs|
              consume_job_status(Array.wrap(job_attrs))
            end
        end

        def consume_job_status(job_attrs)
          status_result =
            if success_with_warnings?(job_attrs)
              :success_with_warnings
            elsif ignored_status?(job_attrs)
              :ignored
            else
              job_attrs[@status_key].to_sym
            end

          @status_set.add(status_result)
        end

        def success_with_warnings?(job_attrs)
          @allow_failure_key &&
            job_attrs[@allow_failure_key] &&
            ::Ci::HasStatus::PASSED_WITH_WARNINGS_STATUSES.include?(job_attrs[@status_key])
        end

        def ignored_status?(job_attrs)
          @allow_failure_key &&
            job_attrs[@allow_failure_key] &&
            ::Ci::HasStatus::IGNORED_STATUSES.include?(job_attrs[@status_key])
        end
      end
    end
  end
end
