# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Pipeline
        module Common
          def has_details?
            can?(user, :read_pipeline, subject)
          end

          def details_path
            project_pipeline_path(subject.project, subject)
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
