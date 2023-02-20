# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        module Common
          def label
            subject.description.presence || super
          end

          def has_details?
            !!details_path
          end

          def details_path
            return unless can?(user, :read_pipeline, downstream_pipeline)

            project_pipeline_path(downstream_project, downstream_pipeline)
          end

          def has_action?
            false
          end

          private

          def downstream_pipeline
            subject.downstream_pipeline
          end

          def downstream_project
            downstream_pipeline&.project
          end
        end
      end
    end
  end
end
