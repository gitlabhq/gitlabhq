module Gitlab
  module Ci
    module Status
      module Build
        module Common
          def has_details?
            true
          end

          def details_path
            namespace_project_build_path(@subject.project.namespace,
                                         @subject.project,
                                         @subject.pipeline)
          end
        end
      end
    end
  end
end
