module Gitlab
  module Ci
    module Status
      module Stage
        module Common
          def has_details?
            can?(user, :read_pipeline, subject.pipeline)
          end

          def details_path
            project_pipeline_path(subject.project, subject.pipeline, anchor: subject.name)
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
