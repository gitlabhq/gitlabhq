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
              # It is still fine to save `::Ci::JobDefinition` objects even if the pipeline is not created due to some
              # reason because they can be used in the next pipeline creations.
              ::Gitlab::Ci::Pipeline::Create::JobDefinitionBuilder.new(pipeline, statuses).run

              with_build_hooks_via_chain do
                BulkInsertableAssociations.with_bulk_insert do
                  pipeline.save!
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

          def with_build_hooks_via_chain
            return yield unless Feature.enabled?(:ci_trigger_build_hooks_in_chain, project)

            Gitlab::SafeRequestStore[:ci_triggering_build_hooks_via_chain] = true
            yield
          ensure
            Gitlab::SafeRequestStore.delete(:ci_triggering_build_hooks_via_chain)
          end

          def statuses
            pipeline
              .stages
              .flat_map(&:statuses)
          end
          strong_memoize_attr :statuses
        end
      end
    end
  end
end
