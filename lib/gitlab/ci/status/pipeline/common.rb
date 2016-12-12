module Gitlab
  module Ci
    module Status
      module Pipeline
        module Common
          def has_details?
            true
          end

          def details_path
            namespace_project_pipeline_path(@subject.project.namespace,
                                            @subject.project,
                                            @subject)
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
