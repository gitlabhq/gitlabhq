# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      module Runner
        class RunnerFleetPipelineSeeder
          DEFAULT_JOB_COUNT = 400

          MAX_QUEUE_TIME_IN_SECONDS = 5 * 60
          PIPELINE_CREATION_RANGE_MIN_IN_MINUTES = 120
          PIPELINE_CREATION_RANGE_MAX_IN_MINUTES = 30 * 24 * 60
          PIPELINE_START_RANGE_MAX_IN_MINUTES = 60 * 60
          PIPELINE_FINISH_RANGE_MAX_IN_MINUTES = 60

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
            @projects_to_runners = projects_to_runners
            @job_count = job_count || DEFAULT_JOB_COUNT
          end

          def seed
            logger.info(message: 'Starting seed of runner fleet pipelines', job_count: @job_count)

            remaining_job_count = @job_count
            PROJECT_JOB_DISTRIBUTION.each_with_index do |d, index|
              remaining_job_count = create_pipelines_and_distribute_jobs(remaining_job_count, project_index: index, **d)
            end

            if remaining_job_count > 0
              create_pipeline(
                job_count: remaining_job_count,
                **@projects_to_runners[PROJECT_JOB_DISTRIBUTION.length],
                status: Random.rand(1..100) < 40 ? 'failed' : 'success'
              )
              remaining_job_count = 0
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

          def create_pipelines(remaining_job_count, project_id:, runner_ids:, total_jobs:, pipeline_job_count:)
            pipeline_job_count = remaining_job_count if pipeline_job_count > remaining_job_count
            return 0 if pipeline_job_count == 0

            pipeline_count = [1, total_jobs / pipeline_job_count].max

            (1..pipeline_count).each do
              create_pipeline(
                job_count: pipeline_job_count,
                project_id: project_id,
                runner_ids: runner_ids,
                status: Random.rand(1..100) < 70 ? 'failed' : 'success'
              )
              remaining_job_count -= pipeline_job_count
            end

            remaining_job_count
          end

          def create_pipeline(job_count:, runner_ids:, project_id:, status: 'success', **attrs)
            logger.info(message: 'Creating pipeline with builds on project',
                        status: status, job_count: job_count, project_id: project_id, **attrs)

            raise ArgumentError('runner_ids') unless runner_ids
            raise ArgumentError('project_id') unless project_id

            sha = '00000000'
            created_at = Random.rand(PIPELINE_CREATION_RANGE_MIN_IN_MINUTES..PIPELINE_CREATION_RANGE_MAX_IN_MINUTES)
                               .minutes.ago
            started_at = created_at + Random.rand(1..PIPELINE_START_RANGE_MAX_IN_MINUTES).seconds
            finished_at = started_at + Random.rand(1..PIPELINE_FINISH_RANGE_MAX_IN_MINUTES).minutes

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

            (1..job_count).each do |index|
              create_build(pipeline, runner_ids.sample, job_status(pipeline.status, index, job_count), index)
            end

            pipeline
          end

          def create_build(pipeline, runner_id, job_status, index)
            started_at = pipeline.started_at
            finished_at = pipeline.finished_at
            max_job_duration = [MAX_QUEUE_TIME_IN_SECONDS, finished_at - started_at].min
            job_started_at = started_at + Random.rand(1..max_job_duration).seconds
            job_finished_at = Random.rand(job_started_at..finished_at)

            build_attrs = {
              name: "Fake job #{index}",
              scheduling_type: 'dag',
              ref: 'main',
              status: job_status,
              pipeline_id: pipeline.id,
              runner_id: runner_id,
              project_id: pipeline.project_id,
              created_at: started_at,
              queued_at: started_at,
              started_at: job_started_at,
              finished_at: job_finished_at
            }
            logger.info(message: 'Creating build', **build_attrs)

            ::Ci::Build.new(importing: true, **build_attrs).tap(&:save!)
          end

          def job_status(pipeline_status, job_index, job_count)
            return 'success' if pipeline_status == 'success'
            return 'failed' if job_index == job_count # Ensure that a failed pipeline has at least 1 failed job

            Random.rand(0..1) == 0 ? 'failed' : 'success'
          end
        end
      end
    end
  end
end
