# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      module Runner
        class RunnerFleetPipelineSeeder
          DEFAULT_JOB_COUNT = 400

          MAX_QUEUE_TIME_IN_SECONDS = 5.minutes.to_i
          PIPELINE_CREATION_RANGE_MIN_IN_SECONDS = 2.hours.to_i
          PIPELINE_CREATION_RANGE_MAX_IN_SECONDS = 30.days.to_i
          PIPELINE_START_RANGE_MAX_IN_SECONDS = 5.minutes.to_i
          PIPELINE_FINISH_RANGE_MAX_IN_SECONDS = 1.hour.to_i

          PROJECT_JOB_DISTRIBUTION = [
            { allocation: 70, job_count_default: 10 },
            { allocation: 15, job_count_default: 10 },
            { allocation: 15, job_count_default: 100 }
            # remaining jobs on 4th project
          ].freeze

          attr_reader :logger

          # Initializes the class
          #
          # @param [Gitlab::Logger] logger
          # @param [Integer] job_count the number of jobs to create across the runners
          # @param [Array<Hash>] projects_to_runners list of project IDs to respective runner IDs
          def initialize(logger = Gitlab::AppLogger, projects_to_runners:, job_count:)
            @logger = logger
            @projects_to_runners = projects_to_runners.map do |v|
              { project_id: v[:project_id], runners: ::Ci::Runner.id_in(v[:runner_ids]).to_a }
            end
            @job_count = job_count || DEFAULT_JOB_COUNT
          end

          def seed
            logger.info(message: 'Starting seed of runner fleet pipelines', job_count: @job_count)

            remaining_job_count = @job_count
            PROJECT_JOB_DISTRIBUTION.each_with_index do |d, index|
              remaining_job_count = create_pipelines_and_distribute_jobs(remaining_job_count, project_index: index, **d)
            end

            while remaining_job_count > 0
              remaining_job_count -= create_pipeline(
                job_count: remaining_job_count,
                **@projects_to_runners[PROJECT_JOB_DISTRIBUTION.length],
                status: random_pipeline_status
              )
            end

            logger.info(
              message: 'Completed seeding of runner fleet',
              job_count: @job_count - remaining_job_count
            )

            nil
          end

          private

          def create_pipelines_and_distribute_jobs(remaining_job_count, project_index:, allocation:, job_count_default:)
            max_jobs_per_pipeline = [1, @job_count / 3].max

            create_pipelines(
              remaining_job_count,
              **@projects_to_runners[project_index],
              total_jobs: @job_count * allocation / 100,
              pipeline_job_count: job_count_default.clamp(1, max_jobs_per_pipeline)
            )
          end

          def create_pipelines(remaining_job_count, project_id:, runners:, total_jobs:, pipeline_job_count:)
            pipeline_job_count = remaining_job_count if pipeline_job_count > remaining_job_count
            return 0 if pipeline_job_count == 0

            pipeline_count = [1, total_jobs / pipeline_job_count].max

            (1..pipeline_count).each do
              remaining_job_count -= create_pipeline(
                job_count: pipeline_job_count,
                project_id: project_id,
                runners: runners,
                status: random_pipeline_status
              )
            end

            remaining_job_count
          end

          def create_pipeline(job_count:, runners:, project_id:, status: 'success', **attrs)
            logger.info(message: 'Creating pipeline with builds on project',
              status: status, job_count: job_count, project_id: project_id, **attrs)

            raise ArgumentError('runners') unless runners
            raise ArgumentError('project_id') unless project_id

            sha = '00000000'
            if ::Ci::HasStatus::ALIVE_STATUSES.include?(status) || ::Ci::HasStatus::COMPLETED_STATUSES.include?(status)
              created_at = Random.rand(PIPELINE_CREATION_RANGE_MIN_IN_SECONDS..PIPELINE_CREATION_RANGE_MAX_IN_SECONDS)
                                 .seconds.ago

              if ::Ci::HasStatus::STARTED_STATUSES.include?(status) ||
                  ::Ci::HasStatus::COMPLETED_STATUSES.include?(status)
                started_at = created_at + Random.rand(1..PIPELINE_START_RANGE_MAX_IN_SECONDS)
                if ::Ci::HasStatus::COMPLETED_STATUSES.include?(status)
                  finished_at = started_at + Random.rand(1..PIPELINE_FINISH_RANGE_MAX_IN_SECONDS)
                end
              end
            end

            pipeline = ::Ci::Pipeline.new(
              project_id: project_id,
              ref: 'main',
              sha: sha,
              source: 'api',
              status: status,
              created_at: created_at,
              started_at: started_at,
              finished_at: finished_at,
              **attrs
            )
            pipeline.ensure_project_iid! # allocate an internal_id outside of pipeline creation transaction
            pipeline.save!

            if created_at.present?
              (1..job_count).each do |index|
                create_build(pipeline, runners.sample, job_status(pipeline.status, index, job_count), index)
              end
            end

            job_count
          end

          def create_build(pipeline, runner, job_status, index)
            started_at = pipeline.started_at
            finished_at = pipeline.finished_at

            max_job_duration = [MAX_QUEUE_TIME_IN_SECONDS, 5, 2].sample
            max_job_duration = (finished_at - started_at) if finished_at && max_job_duration > finished_at - started_at

            job_created_at = pipeline.created_at
            job_started_at = job_created_at + Random.rand(1..max_job_duration) if started_at
            if finished_at
              job_finished_at = Random.rand(job_started_at..finished_at)
            elsif job_status == 'running'
              job_finished_at = job_started_at + Random.rand((1 * 60)..PIPELINE_FINISH_RANGE_MAX_IN_SECONDS)
            end

            # Do not use the first 2 runner tags ('runner-fleet', "#{registration_prefix}runner").
            #  See Gitlab::Seeders::Ci::Runner::RunnerFleetSeeder#additional_runner_args
            tags = runner.tags.offset(2).sample(Random.rand(1..5)) # rubocop: disable CodeReuse/ActiveRecord

            build_attrs = {
              name: "Mock job #{index}",
              scheduling_type: 'dag',
              ref: 'main',
              status: job_status,
              pipeline_id: pipeline.id,
              runner_id: runner.id,
              project_id: pipeline.project_id,
              tag_list: tags,
              created_at: job_created_at,
              queued_at: job_created_at,
              started_at: job_started_at,
              finished_at: job_finished_at
            }
            logger.info(message: 'Creating build', **build_attrs)

            build = nil

            ::Ci::Build.transaction do
              build = ::Ci::Build.new(importing: true, **build_attrs).tap(&:save!)
              ::Ci::RunningBuild.upsert_build!(build) if build.running?
            end

            build&.trace&.set("Mock log...\nMock log... DONE!")
          end

          def random_pipeline_status
            if Random.rand(1..4) == 4
              %w[created pending canceled running].sample
            elsif Random.rand(1..3) == 1
              'success'
            else
              'failed'
            end
          end

          def job_status(pipeline_status, job_index, job_count)
            return pipeline_status if %w[created pending success].include?(pipeline_status)

            # Ensure that a failed/canceled pipeline has at least 1 failed/canceled job
            if job_index == job_count && ::Ci::HasStatus::PASSED_WITH_WARNINGS_STATUSES.include?(pipeline_status)
              return pipeline_status
            end

            possible_statuses = %w[failed success]
            possible_statuses << pipeline_status if %w[canceled running].include?(pipeline_status)

            possible_statuses.sample
          end
        end
      end
    end
  end
end
