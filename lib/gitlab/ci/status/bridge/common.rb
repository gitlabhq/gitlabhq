# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        module Common
          def label
            subject.description
          end

          def has_details?
            !!details_path
          end

          def details_path
            return unless can?(user, :read_pipeline, downstream_pipeline)

            if Feature.enabled?(:ci_retry_downstream_pipeline, subject.project, default_enabled: :yaml)
              project_job_path(subject.project, subject)
            else
              project_pipeline_path(downstream_project, downstream_pipeline)
            end
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
