# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            logger.instrument_once_with_sql(:pipeline_save) do
              BulkInsertableAssociations.with_bulk_insert do
                ::Ci::BulkInsertableTags.with_bulk_insert_tags do
                  pipeline.transaction do
                    pipeline.save!
                    Gitlab::Ci::Tags::BulkInsert.bulk_insert_tags!(statuses)
                  end
                end
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          rescue ActiveRecord::RecordNotUnique => e
            raise unless e.message.include?('iid')

            ::InternalId.flush_records!(project: project, usage: :ci_pipelines)
            error("Failed to persist the pipeline, please retry")
          end

          def break?
            !pipeline.persisted?
          end

          private

          def statuses
            strong_memoize(:statuses) do
              pipeline
                .stages
                .flat_map(&:statuses)
                .select { |status| status.respond_to?(:tag_list=) }
            end
          end
        end
      end
    end
  end
end
