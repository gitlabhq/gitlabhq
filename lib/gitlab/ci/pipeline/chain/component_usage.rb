# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class ComponentUsage < Chain::Base
          include Gitlab::Utils::StrongMemoize

          def perform!
            return if included_components.empty?

            enqueue_tracking_job
          end

          def break?
            false
          end

          private

          def enqueue_tracking_job
            serialized_components = included_components.map do |component_hash|
              {
                'project_id' => component_hash[:project].id,
                'sha' => component_hash[:sha],
                'name' => component_hash[:name]
              }
            end

            ::Ci::Catalog::Resources::TrackComponentUsageWorker.perform_async(
              project.id,
              current_user&.id,
              serialized_components
            )
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
          end

          def included_components
            command.yaml_processor_result.included_components
          end
          strong_memoize_attr :included_components
        end
      end
    end
  end
end
