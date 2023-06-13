# frozen_string_literal: true

module Ci
  module PipelineProcessing
    class AtomicProcessingService
      class StatusCollection
        include Gitlab::Utils::StrongMemoize

        attr_reader :pipeline

        def initialize(pipeline)
          @pipeline = pipeline
          @stage_jobs = {}
          @prior_stage_jobs = {}
        end

        # This method updates internal status for given ID
        def set_job_status(id, status, lock_version)
          job = all_jobs_by_id[id]
          return unless job

          job[:status] = status
          job[:lock_version] = lock_version
        end

        # This methods gets composite status of all jobs
        def status_of_all
          status_for_array(all_jobs)
        end

        # This methods gets composite status for jobs at a given stage
        def status_of_stage(stage_position)
          strong_memoize("status_of_stage_#{stage_position}") do
            stage_jobs = all_jobs_grouped_by_stage_position[stage_position].to_a

            status_for_array(stage_jobs.flatten)
          end
        end

        # This methods gets composite status for jobs with given names
        def status_of_jobs(names)
          jobs = all_jobs_by_name.slice(*names)

          status_for_array(jobs.values, dag: true)
        end

        # This methods gets composite status for jobs before given stage
        def status_of_jobs_prior_to_stage(stage_position)
          strong_memoize("status_of_jobs_prior_to_stage_#{stage_position}") do
            stage_jobs = all_jobs_grouped_by_stage_position
              .select { |position, _| position < stage_position }

            status_for_array(stage_jobs.values.flatten)
          end
        end

        # This methods gets a list of jobs for a given stage
        def created_job_ids_in_stage(stage_position)
          all_jobs_grouped_by_stage_position[stage_position]
            .to_a
            .select { |job| job[:status] == 'created' }
            .map { |job| job[:id] }
        end

        # This method returns a list of all job, that are to be processed
        def processing_jobs
          all_jobs.lazy.reject { |job| job[:processed] }
        end

        # This method returns the names of jobs that have a stopped status
        def stopped_job_names
          all_jobs.select { |job| job[:status].in?(Ci::HasStatus::STOPPED_STATUSES) }.pluck(:name) # rubocop: disable CodeReuse/ActiveRecord
        end

        private

        # We use these columns to perform an efficient calculation of a status
        JOB_ATTRS = [
          :id, :name, :status, :allow_failure,
          :stage_idx, :processed, :lock_version
        ].freeze

        def status_for_array(jobs, dag: false)
          result = Gitlab::Ci::Status::Composite
            .new(jobs, dag: dag, project: pipeline.project)
            .status
          result || 'success'
        end

        def all_jobs_grouped_by_stage_position
          strong_memoize(:all_jobs_by_order) do
            all_jobs.group_by { |job| job[:stage_idx].to_i }
          end
        end

        def all_jobs_by_id
          strong_memoize(:all_jobs_by_id) do
            all_jobs.index_by { |row| row[:id] }
          end
        end

        def all_jobs_by_name
          strong_memoize(:jobs_by_name) do
            all_jobs.index_by { |row| row[:name] }
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def all_jobs
          # We fetch all relevant data in one go.
          #
          # This is more efficient than relying on PostgreSQL to calculate composite status for us
          #
          # Since we need to reprocess everything we can fetch all of them and do processing ourselves.
          strong_memoize(:all_jobs) do
            raw_jobs = pipeline
              .current_jobs
              .ordered_by_stage
              .pluck(*JOB_ATTRS)

            raw_jobs.map do |row|
              JOB_ATTRS.zip(row).to_h
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
