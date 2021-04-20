# frozen_string_literal: true

module Ci
  module PipelineProcessing
    class AtomicProcessingService
      class StatusCollection
        include Gitlab::Utils::StrongMemoize

        attr_reader :pipeline

        # We use these columns to perform an efficient
        # calculation of a status
        STATUSES_COLUMNS = [
          :id, :name, :status, :allow_failure,
          :stage_idx, :processed, :lock_version
        ].freeze

        def initialize(pipeline)
          @pipeline = pipeline
          @stage_statuses = {}
          @prior_stage_statuses = {}
        end

        # This method updates internal status for given ID
        def set_processable_status(id, status, lock_version)
          processable = all_statuses_by_id[id]
          return unless processable

          processable[:status] = status
          processable[:lock_version] = lock_version
        end

        # This methods gets composite status of all processables
        def status_of_all
          status_for_array(all_statuses, dag: false)
        end

        # This methods gets composite status for processables with given names
        def status_for_names(names, dag:)
          name_statuses = all_statuses_by_name.slice(*names)

          status_for_array(name_statuses.values, dag: dag)
        end

        # This methods gets composite status for processables before given stage
        def status_for_prior_stage_position(position)
          strong_memoize("status_for_prior_stage_position_#{position}") do
            stage_statuses = all_statuses_grouped_by_stage_position
              .select { |stage_position, _| stage_position < position }

            status_for_array(stage_statuses.values.flatten, dag: false)
          end
        end

        # This methods gets a list of processables for a given stage
        def created_processable_ids_for_stage_position(current_position)
          all_statuses_grouped_by_stage_position[current_position]
            .to_a
            .select { |processable| processable[:status] == 'created' }
            .map { |processable| processable[:id] }
        end

        # This methods gets composite status for processables at a given stage
        def status_for_stage_position(current_position)
          strong_memoize("status_for_stage_position_#{current_position}") do
            stage_statuses = all_statuses_grouped_by_stage_position[current_position].to_a

            status_for_array(stage_statuses.flatten, dag: false)
          end
        end

        # This method returns a list of all processable, that are to be processed
        def processing_processables
          all_statuses.lazy.reject { |status| status[:processed] }
        end

        private

        def status_for_array(statuses, dag:)
          result = Gitlab::Ci::Status::Composite
            .new(statuses, dag: dag, project: pipeline.project)
            .status
          result || 'success'
        end

        def all_statuses_grouped_by_stage_position
          strong_memoize(:all_statuses_by_order) do
            all_statuses.group_by { |status| status[:stage_idx].to_i }
          end
        end

        def all_statuses_by_id
          strong_memoize(:all_statuses_by_id) do
            all_statuses.to_h do |row|
              [row[:id], row]
            end
          end
        end

        def all_statuses_by_name
          strong_memoize(:statuses_by_name) do
            all_statuses.to_h do |row|
              [row[:name], row]
            end
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def all_statuses
          # We fetch all relevant data in one go.
          #
          # This is more efficient than relying
          # on PostgreSQL to calculate composite status
          # for us
          #
          # Since we need to reprocess everything
          # we can fetch all of them and do processing
          # ourselves.
          strong_memoize(:all_statuses) do
            raw_statuses = pipeline
              .statuses
              .latest
              .ordered_by_stage
              .pluck(*STATUSES_COLUMNS)

            raw_statuses.map do |row|
              STATUSES_COLUMNS.zip(row).to_h
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
