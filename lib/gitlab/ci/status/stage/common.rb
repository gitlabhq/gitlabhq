module Gitlab
  module Ci
    module Status
      module Stage
        module Common
          def has_details?
            true
          end

          def details_path
            namespace_project_pipeline_path(@subject.project.namespace,
                                            @subject.project,
                                            @subject,
                                            anchor: subject.name)
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
