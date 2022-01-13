# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            logger.instrument_with_sql(:pipeline_save) do
              BulkInsertableAssociations.with_bulk_insert do
                with_bulk_insert_tags do
                  pipeline.transaction do
                    pipeline.save!
                    CommitStatus.bulk_insert_tags!(statuses) if bulk_insert_tags?
                  end
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

          def bulk_insert_tags?
            strong_memoize(:bulk_insert_tags) do
              ::Feature.enabled?(:ci_bulk_insert_tags, project, default_enabled: :yaml)
            end
          end

          def with_bulk_insert_tags
            previous = Thread.current['ci_bulk_insert_tags']
            Thread.current['ci_bulk_insert_tags'] = bulk_insert_tags?
            yield
          ensure
            Thread.current['ci_bulk_insert_tags'] = previous
          end

          def statuses
            strong_memoize(:statuses) do
              pipeline
                .stages
                .flat_map(&:statuses)
                .select { |status| status.respond_to?(:tag_list) }
            end
          end
        end
      end
    end
  end
end
