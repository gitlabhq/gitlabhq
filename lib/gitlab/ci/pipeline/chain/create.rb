# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            logger.instrument(:pipeline_save) do
              BulkInsertableAssociations.with_bulk_insert do
                tags = extract_tag_list_by_status

                pipeline.transaction do
                  pipeline.save!
                  CommitStatus.bulk_insert_tags!(statuses, tags) if bulk_insert_tags?
                end
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          end

          def break?
            !pipeline.persisted?
          end

          private

          def statuses
            strong_memoize(:statuses) do
              pipeline.stages.flat_map(&:statuses)
            end
          end

          # We call `job.tag_list=` to assign tags to the jobs from the
          # Chain::Seed step which uses the `@tag_list` instance variable to
          # store them on the record. We remove them here because we want to
          # bulk insert them, otherwise they would be inserted and assigned one
          # by one with callbacks. We must use `remove_instance_variable`
          # because having the instance variable defined would still run the callbacks
          def extract_tag_list_by_status
            return {} unless bulk_insert_tags?

            statuses.each.with_object({}) do |job, acc|
              tag_list = job.clear_memoization(:tag_list)
              next unless tag_list

              acc[job.name] = tag_list
            end
          end

          def bulk_insert_tags?
            strong_memoize(:bulk_insert_tags) do
              ::Feature.enabled?(:ci_bulk_insert_tags, project, default_enabled: :yaml)
            end
          end
        end
      end
    end
  end
end
